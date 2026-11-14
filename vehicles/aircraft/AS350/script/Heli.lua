#version 2
#include "script/include/player.lua"
#include "common.lua"
#include "Inputs.lua"
#include "Control.lua"
#include "PointControl.lua"
#include "Damage.lua"
#include "Weapons.lua"
#include "AI.lua"
#include "Config.lua"
#include "../../../../lib/Settings.lua"
#include "../../../../npcs/Blood/Blood.lua"
#include "AI_Gore.lua"
#include "HeliV2.lua"
#include "HeliPilot.lua"
-- AS350 helicopter (Mors Longa), v2 port 2026-11-13 (hand-written; original: git 9dde6dd vehicles/aircraft/AS350/script/Heli.lua).
--
-- Server: flight (the original's PID autopilot for the enemy AI and the "Take a ride" autopilot; HeliPilot.lua's
-- mouse-aim model for a player pilot, user decision 2026-11-13), damage, fuel, doors, rotors, AI, weapons
-- (bullets, rockets), player damage. Clients: engine/rotor sounds, smoke, alarm, muzzle flashes and tracers, the
-- pilot's camera and HUD, the prompts. The helicopter is a <vehicle> (add_seats.py WRAP_VEHICLE): the player in the
-- pilot (driver) seat flies it; the original's dashboard interaction and its per-frame player teleport are gone.
-- The original's setup/PID-tuning tools (Debug.lua, Graph.lua, UiFunctions.lua, UiSettings.lua) are not included
-- (developer tools, off in the original: debug setup mode 0). Doors.lua: Heli.lua's own versions (below) won there.
-- v2 overrides of functions from the included original files: HeliV2.lua.

--------------------------------------------------------------------------------------------------- server

function server.init()
    Init_Settings()
    MainSettingsConfig()
    PowerConfig()
    SetupOptions()
    -- (v2) the PID-tuning options (UiSettings.lua / UiFunctions.lua, not included) as v1 left them: all 0, so the
    -- crash spiral (Damage.lua ManageGoingDown: 10^Val[...]) scales by 1 (in-game 2026-11-13: "attempt to index
    -- global 'Val'" once the helicopter went down)
    PFactor, IFactor, DFactor, RangeFactor = 1, 2, 3, 4
    Val = { 0, 0, 0, 0 }

    Heli = FindBody("Heli")
    -- "parked" variants (spawn menu, heli_variants.py): no enemy AI, stays landed until boarded
    if HasTag(Heli, "parked") then IsHostile = false end
    HeliVehicle = GetBodyVehicle(Heli)
    MRotor = FindBody("rotor")
    SRotor = FindBody("s_rotor")
    SRotorJoint = FindJoint("s_rotor")
    MRotorJoint = FindJoint("MainRotor")
    AllBodies = FindBodies("")
    -- (v2) InternalVars -> MainRotorDragInit reads these before WorldVariables sets them (v1 passed nil)
    HeliTr = GetBodyTransform(Heli)
    RotorPos = GetBodyTransform(MRotor).pos
    TargetSelectionMode = false -- (v2) WorldXcontrol read it (nil) before InitPointControl set it
    InternalVars()

    LocalSideRotorPos = Vec(0,0,0)
    WorldVariables()
    LocalSideRotorPos = TransformToLocalPoint(HeliTr,SideRotorPos)

    IsFlying = false
    IsEngineOn = false

    if QuickStartControl then IsHostile = false end
    InitAI()
    if IsHostile then QuickStartRide = true end
    initControl()
    InitGun()
    InitDamage()
    InitPointControl()
    InitDoors()
    HeliV2_InitDoorEntry()

    if QuickStartRide then
        StartUpTime = StartUpTime*0.1
        StartRide()
        QuickStartRide = false
    end

    InitTimeUp = false
    InitTime = 0

    ai_gore_init(Heli)
    HeliPilot_ServerInit()
    HeliV2_SyncShared()
end

function server.tick(dt)
    if TooDamaged then
        SetTag(Heli, "dead")
    end

    HeliV2_UpdatePilot()

    for key, shell in ipairs(heliprojectileHandler.shells) do
        if shell.active then
            ProjectileOperations(shell)
        end
    end

    if InitTimeUp == false then
        InitTime = InitTime + dt
        if InitTime>10 then
            InitDoors()
            InitTimeUp = true
        end
    end

    HeliV2_RideInteractions()
    HeliV2_DoorEntry(dt)
    TargetSelectionInputs()

    GunImputs()
    RocketImputs()

    HeliV2_SyncShared()
end

function server.update(dt)
    WorldVariables()
    ManageStartup()
    CheckDamage()
    ManageDamageEffects(dt)

    if IsFlying then
        if DetailedControl and PilotId ~= 0 then
            HeliPilot_Flight(dt) -- player pilot: mouse-aim model (HeliPilot.lua)
        else
            MoveForward()
            MoveSideways()
            LeanForward()
            LeanSideways()

            ManageYaw()
            ManageCollective()

            XControlFunctions()

            ManageLanding()
        end
    end

    ManageDoors()
    MainRotorDrag()

    ManageGun()

    RunOutOfPower()

    ManageAIUpdates(dt)
end

--- Aim of the pilot's client (sent every tick): the look direction and the point under the crosshair.
function server.heliAim(playerId, dir, point)
    if playerId == PilotId and PilotId ~= 0 then
        PilotLook = dir
        PilotAimPoint = point
    end
end

function GetRotorSpeed(Joint,LastPos)
    local a = GetJointMovement(Joint)
    local v = a - LastPos
    local v2 = a-LastPos + 360
    if math.abs(v2)<v then v = v2 end
    local v2 = a-LastPos - 360
    if math.abs(v2)<v then v = v2 end
    LastPos = a
    v = math.abs(v)
    return v,a
end

-- (v2) without the original's last part (the "internal" trigger moved onto the cabin and the camera tested
-- against it, for the inside/outside engine sound): the clients do that test themselves (HeliV2_ClientInside).
function WorldVariables()
	HeliTr = GetBodyTransform(Heli)
    HeliCoM = TransformToParentPoint(HeliTr,GetBodyCenterOfMass(Heli))

	RotorPos = GetBodyTransform(MRotor).pos
    SideRotorPos = GetBodyTransform(SRotor).pos
    HeliVel = GetBodyVelocity(Heli)

    Axes[Forward] = TransformToParentVec(HeliTr,Vec(0,0,1))
    Axes[Upward] = TransformToParentVec(HeliTr,Vec(0,1,0))
    Axes[Right] = TransformToParentVec(HeliTr,Vec(1,0,0))

    PointF = VecAdd(HeliTr.pos,VecScale(Axes[Forward],PointDistanceForAngles))
    PointB = VecAdd(HeliTr.pos,VecScale(Axes[Forward],-PointDistanceForAngles))
    PointR = VecAdd(HeliTr.pos,VecScale(Axes[Right],PointDistanceForAngles))
    PointL = VecAdd(HeliTr.pos,VecScale(Axes[Right],-PointDistanceForAngles))
    PointU = VecAdd(HeliTr.pos,VecScale(Axes[Upward],PointDistanceForAngles))
    PointD = VecAdd(HeliTr.pos,VecScale(Axes[Upward],-PointDistanceForAngles))

    HeliYawTr = TransformCopy(HeliTr)
    local v = TransformToParentVec(HeliTr,Vec(0,0,-1))
    local q = QuatLookAt(Vec(0,0,0),v)
    HeliYawTr.rot = q

    MRotSpeed,MRotSpeedHelper = GetRotorSpeed(MRotorJoint,MRotSpeedHelper)
    local helirot = GetBodyAngularVelocity(Heli)[2]*180/math.pi/60
    MRotSpeedFraction = ((MRotSpeed+helirot)/MaxRotorSpeed_Def)^2
    if IsHostile then
        if AIWarmedUp == false then
            MRotSpeedFraction = MRotSpeedFraction+1-AIStartupTime/AIStartWaitTime
        end
    end

    SRotSpeed,SRotSpeedHelper = GetRotorSpeed(SRotorJoint,SRotSpeedHelper)
    SRotSpeedFraction = (SRotSpeed/MaxSRotorSpeed_Def)^2

    CurrentHeight = HeliTr.pos[2]

    WorldXcontrol()
end

function Startup()
    if Fuelamount == 0 then return end
    if TooDamaged then return end
    CheckBrokenLiftOff()

	IsFlying = true
    IsEngineOn = true

    Starting = true
    ShutOff = false
    StartTimer = StartUpTime*60
    AdjustCruisingAltitude(true)

    if BrokenLiftoffAttempt then return end
    for i=1,#InternalLights do
        SetLightEnabled(InternalLights[i], true)
    end
end

function ManageStartup()
    if Starting == false then return end
    StartTimer = StartTimer - 1
    if StartTimer<1 then
        Starting = false
        StartUpTime = StartUpTimeDefault
        return
    end
    local f = 1-StartTimer/60/StartUpTime
    SetJointMotor(MRotorJoint, MaxRotorSpeed*f,MaxMRotorRotationForce*f)
    SetJointMotor(SRotorJoint, MaxSRotorSpeed*f,MaxSRotorRotationForce*2)
end

-- (v2) player p took the pilot seat (v1: interacted with the dashboard; the camera and the player's tool were set
-- here, now the pilot's client has its own camera and a seated player holds no tool).
function TakeControl(p)
    if IsFlying == false then Startup() end
    DetailedControl = true
    PilotId = p
    PilotLook, PilotAimPoint = nil, nil
    IsHostile = false
    TargetSelectionMode = false -- the pilot takes over from a "Take a ride" autopilot
    Commander = 0

    RocketCooldownMaxLong = RocketCooldownMaxLongPlayer
    RocketCooldownMaxShort = RocketCooldownMaxShortPlayer
    HeliPilot_Reset()
end

function InternalVars()
    LastMove = 0

    Axes = {}
    Forward = 1
    Upward = 2
    Right = 3

    Axes[Forward] = Vec(0,0,0)
    Axes[Upward] = Vec(0,0,0)
    Axes[Right] = Vec(0,0,0)

    PointDistanceForAngles = 2
    --moving
    MoveForwardLastP = 0
    MoveRightLastP = 0
    MoveRightI = 0
    MoveForwardI = 0

    RightLeanOffset = 0
    ForwardLeanOffset = 0

    --leaning
    LeanForwardI = 0
    LeanRightI = 0
    --yaw
    YawVector = Vec(0,0,-1)
    YawLastP = 0
    YawI = 0
    DefaultYawForce = -173
    YawForce = DefaultYawForce

    --Main Rotor
    RotorForce = RotorForceConfig
    DefaultCollective = 0
    Collective = DefaultCollective
    CollectiveLastP = 0
    CollectiveI = 0

    --other
    MRotSpeedHelper = 0
    MRotSpeed = 0

    SRotSpeed = 0
    SRotSpeedHelper = 0

    Starting = false
    StartTimer = 0
    StartUpTimeDefault = 15
    StartUpTime = StartUpTimeDefault
    MaxRotorSpeed_Def = 15
    MaxSRotorSpeed_Def = MaxRotorSpeed_Def*4
    MaxRotorSpeed = MaxRotorSpeed_Def
    MaxSRotorSpeed = MaxSRotorSpeed_Def

    --landing
    LandingTimer = 0
    LandingTime = 1
    ShutOff = false
    ShutOffTimer = 0
    ShutOffTime = StartUpTime

    -- (v2) the player flying it (0: none) and the player who started a "Take a ride" (0: none)
    PilotId = 0
    Commander = 0

    MainRotorDragInit()
end

function CheckLanding(Coll, Min)
    if ShutOff then return end
    if Starting then return end
    if IsFlying == false then return end
    if IsHostile then
        if AIWarmedUp == false then
            LandingTimer = 0
            return
        end
    end

    local IsTouching = false
    IsTouching = math.abs(HeliVel[2])<0.06 and  Coll < -Min
    if IsTouching then
        LandingTimer = LandingTimer+1/60
    else
        LandingTimer = 0
    end

    if LandingTimer > LandingTime then
        ShutOff = true
        ShutOffTimer = ShutOffTime*60
    end
end

-- (v2) the pilot left the seat (or control was lost). The original's autopilot takes over and holds the
-- helicopter where it is: its collective starts at the hover value and its heading at the current one (v1 kept the
-- values from before the player flew, and the helicopter dropped or turned back first).
function StopControl()
    local wasPiloted = PilotId ~= 0 and DetailedControl
    DetailedControl = false
    EnableGun = false
    EnableRocket = false
    TriggerHeld = false
    RocketTriggerHeld = false
    AimTarget = nil
    PilotId = 0

	C_VerticalInput = none
	C_PitchInput = none
	C_SideInput  = none

    CollectiveOffset = 0
	MoveForwardOffset = 0
	MoveSideOffset = 0

    if wasPiloted then HeliPilot_HandOver() end
end

function ManageLanding()
    if ShutOff == false then return end

    ShutOffTimer = ShutOffTimer - 1
    if ShutOffTimer<1 then
        ShutOff = false
        IsFlying = false
        IsEngineOn = false
        StopControl()
        TargetSelectionMode = false
        Commander = 0
        SetJointMotor(MRotorJoint, 0,MaxMRotorRotationForce)
        SetJointMotor(SRotorJoint, 0,MaxSRotorRotationForce*5)
    end
    local f = ShutOffTimer/60/ShutOffTime
    SetJointMotor(MRotorJoint, MaxRotorSpeed*f,MaxMRotorRotationForce*f)
    SetJointMotor(SRotorJoint, MaxSRotorSpeed*f,MaxSRotorRotationForce*f)

    --cancelled landing (v2: Shift of the player riding; v1: of the one player)
    if Commander ~= 0 and InputDown(C_UpButton, Commander) then
        Startup()
        ShutOff = false
        StartTimer = StartUpTime*60*(1-f)
    end
end

function InitDoors()
    local sps = FindShapes("doorcollider")
    for i = 1,#sps,1 do
        SetShapeCollisionFilter(sps[i],8,255-8)
    end
    SlidingDoorJoints = FindJoints("slidingdoor")
    FrontDoorJoints = FindJoints("frontdoor")
    EngineDoorJoints = FindJoints("enginedoor")
    CargoJoints = FindJoints("cargo")
    TopDoorJoints = FindJoints("topdoor")

    sps = FindShapes("enginedoor")
    sps[#sps+1] = FindShape("engine")
    for i = 1,#sps,1 do
        SetShapeCollisionFilter(sps[i],16,255-16)
    end
end

function ManageDoors()
    if DetailedControl == false then
        ManageDoorJoints(SlidingDoorJoints,0,1.1,1,70,0.05)
        ManageDoorJoints(FrontDoorJoints,0,100,2,30,12)
    else
        --don't keep door open when player is pilot also close harder
        ManageDoorJoints(SlidingDoorJoints,0,1.1*2,2,70*4,0.05+1.1)
        ManageDoorJoints(FrontDoorJoints,0,200,2,30*4,11)
    end

    ManageDoorJoints(EngineDoorJoints,0,75,2,70,8)
    ManageDoorJoints(CargoJoints,0,1000,2,20,8)
    ManageDoorJoints(TopDoorJoints,0,75,2,20,8)
end

function ManageDoorJoints(Joints,Closed,Open,CloseSpeed,CloseForce,mindist)
    local CPos = 0
    local dist = 0
    local dist2 = 0

    for i = 1,#Joints,1 do
        CPos = GetJointMovement(Joints[i])
        dist = math.abs(CPos-Closed)
        dist2 = math.abs(CPos-Open)
        if dist<mindist then
            SetJointMotorTarget(Joints[i], Closed, CloseSpeed*(dist)/mindist, CloseForce)

        elseif dist2<mindist then
            SetJointMotorTarget(Joints[i], Open, CloseSpeed*(dist)/mindist, CloseForce)
        else
            SetJointMotor(Joints[i], 0, 0)
        end
    end
end

--------------------------------------------------------------------------------------------------- client

function client.init()
    Init_Settings()
    Heli = FindBody("Heli")
    MRotor = FindBody("rotor")
    HeliVehicle = GetBodyVehicle(Heli)
    AllBodies = FindBodies("")
    damage = 0.15 -- smoke colour (the original's bullet damage value, reused by smoke())
    InitSounds()
    InitUi()
    HeliV2_ClientInit()
    HeliPilot_ClientInit()
end

function client.update(dt)
    if not IsHandleValid(Heli) then return end
    HeliV2_ClientState()
    HeliV2_ClientEffects()
end

function client.tick(dt)
    if not IsHandleValid(Heli) then return end
    HeliV2_ClientState()
    HeliV2_ClientShells()
    HeliPilot_ClientTick(dt)
    HeliV2_ClientInside()
    PlaySounds()
end

function client.draw()
    if not IsHandleValid(Heli) then return end
    HeliPilot_ClientDraw()
    ControlPrompts()
    HeliV2_ClientOutline()
end

--ideally there would be more variations of engine start
--ideally int / ext and type (run / start) shoudl be variables for an array
-- (v2) client: sounds and the cabin trigger / alarm / smoke locations
function InitSounds()
	Sound_External = LoadLoop("MOD/vehicles/aircraft/AS350/snd/external.ogg")
	Sound_Internal = LoadLoop("MOD/vehicles/aircraft/AS350/snd/internal.ogg")
	Sound_Critical = LoadLoop("MOD/vehicles/aircraft/AS350/snd/critical_alarm.ogg")

    Sound_Crash_In = LoadSound("MOD/vehicles/aircraft/AS350/snd/experimental.ogg")
	Sound_Crash_Out = LoadSound("MOD/vehicles/aircraft/AS350/snd/heli_crash_out.ogg")

	-- (v2) the "internal" trigger's place in body Heli, from the XML (pos 0.0 1.1 -0.1): v1 read it from the trigger
	-- at start; the trigger does not move with the body (v1 moved it every frame), so a player joining later would
	-- read a stale place
	InternalTrigLocalTr = Transform(Vec(0.0, 1.1, -0.1))
	CriticalLocalTr = GetLocationLocalTransform("critical",Heli)
	SmokePosLocal = GetLocationLocalTransform("smoke",Heli)

    Sound_EXT_engine_run = LoadLoop("MOD/vehicles/aircraft/AS350/snd/EXT_AS350_engine_running.ogg")
    Sound_EXT_rotor_run = LoadLoop("MOD/vehicles/aircraft/AS350/snd/EXT_AS350_rotor_running.ogg")
    Sound_EXT_engine_start = LoadLoop("MOD/vehicles/aircraft/AS350/snd/EXT_AS350_engine_start.ogg")
    EngineStartTimeEXT = 24*60-1
    EngineStartCounterEXT = 0

    Sound_INT_engine_run = LoadLoop("MOD/vehicles/aircraft/AS350/snd/INT_AS350_engine_running.ogg")
    Sound_INT_rotor_run = LoadLoop("MOD/vehicles/aircraft/AS350/snd/INT_AS350_rotor_running.ogg")
    Sound_INT_engine_start = LoadLoop("MOD/vehicles/aircraft/AS350/snd/INT_AS350_engine_start.ogg")
    EngineStartTimeINT = 2751
    EngineStartCounterINT = 0

    EngineVolume_Default = 1
    EngineVolume = EngineVolume_Default

    Sound_INT_vibration = LoadLoop("MOD/vehicles/aircraft/AS350/snd/INT_AS350_cabin_vibrations.ogg")
end

-- (v2) client, from the server's state (HeliV2_ClientState). The start sounds play from the start of the engine
-- (v1: the counters were reset in Startup on the one machine).
function PlaySounds()
    if IsCrashed then return end
    local smokePos = TransformToParentPoint(HeliTr, LocalPoint(SmokePosLocal))

    if IsEngineOn and not WasEngineOn then
        EngineStartCounterEXT = 0
        EngineStartCounterINT = 0
        EngineVolume = EngineVolume_Default
    end
    WasEngineOn = IsEngineOn

    --cabin vibration
    if TotalDamage>0.02 then
        PlayLoop(Sound_INT_vibration,smokePos,MapValues(TotalDamage,0.02,0.15,1,2)*MRotSpeedFraction*0.33)
    end

    --engine
    if EngineHealth > 0.5 and IsEngineOn then
        local startEXT = EngineStartCounterEXT<EngineStartTimeEXT
        local startINT = EngineStartCounterINT<EngineStartTimeINT
        if startEXT then EngineStartCounterEXT = EngineStartCounterEXT + 1 end
        if startINT then EngineStartCounterINT = EngineStartCounterINT + 1 end
        if IsHostile then
            startINT = false
            startEXT = false
        end

        local hf = (EngineHealth-0.5)/(1-0.5)
        local INT_volume = 0
        local EXT_volume = 0
        local INT_Sound = 0
        local EXT_Sound = 0

        if startINT then
            INT_Sound = Sound_INT_engine_start
        else
            INT_Sound = Sound_INT_engine_run
        end

        if startEXT then
            EXT_Sound = Sound_EXT_engine_start
        else
            EXT_Sound = Sound_EXT_engine_run
        end

        if ShutOff then
            EngineVolume = EngineVolume*(1-0.003)
        end

        if Inside then
            INT_volume = hf*EngineVolume*0.5
            EXT_volume = 0
        else
            INT_volume = 0
            EXT_volume = hf*EngineVolume
        end

        PlayLoop(INT_Sound,smokePos,INT_volume*40)
        PlayLoop(EXT_Sound,smokePos,EXT_volume*40)

    else
        EngineStartCounterEXT = 0
        EngineStartCounterINT = 0
    end

    local rotorvol = 5
    if RotorGone==false and MRotSpeedFraction>0.01 then
        if Inside then
            PlayLoop(Sound_INT_rotor_run,GetBodyTransform(MRotor).pos,MRotSpeedFraction*rotorvol*2*100)
        else
            PlayLoop(Sound_EXT_rotor_run ,GetBodyTransform(MRotor).pos,MRotSpeedFraction*rotorvol*100)
        end
    end
end

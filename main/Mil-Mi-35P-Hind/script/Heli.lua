
--[[
#include "Inputs.lua"
#include "Control.lua"
#include "common.lua"
#include "Debug.lua"
#include "Graph.lua"
#include "UiSettings.lua"
#include "UiFunctions.lua"
#include "PointControl.lua"
#include "Damage.lua"
#include "Weapons.lua"
#include "AI.lua"
#include "Config.lua"
#include "../../../Settings.lua"
]]




function init()
    MainSettingsConfig()
    PowerConfig()

    SetupOptions()
    RunSetupInInitConfigUpdate()

    Heli = FindBody("Heli")
    MRotor = FindBody("rotor")
    SRotor = FindBody("s_rotor")
    SRotorJoint = FindJoint("s_rotor")
    MRotorJoint = FindJoint("MainRotor")
    AllBodies = FindBodies("")
    InternalVars()

    LocalSideRotorPos = Vec(0,0,0)
    WorldVariables()
    LocalSideRotorPos = TransformToLocalPoint(HeliTr,SideRotorPos)

    IsFlying = false
    IsEngineOn = false
    Near = false

    if QuickStartControl then IsHostile = false end
    InitAI()
    if IsHostile then QuickStartRide = true end
    initControl()
    InitGun()
    InitDamage()
    InitPointControl()

    InitSounds()

    if QuickStartControl then
        StartUpTime = StartUpTime*0.1
        TakeControl()
        QuickStartControl = false
        MaxMRotorRotationForce = MaxMRotorRotationForce*10
    end
    if QuickStartRide then
        StartUpTime = StartUpTime*0.1
        StartRide()
        QuickStartRide = false
        MaxSRotorRotationForce = MaxSRotorRotationForce*10
    end

    initGraph()
    InitialiseOptions()

    
    

    InitUi()

    Init_Settings()

    InitTimeUp = false
    InitTime = 0

    ai_gore_init()

    RunSetupInInit()
end




function tick(dt)

    if TooDamaged then
        SetTag(Heli, "dead")
    end

    if ThirdPersonView then ManageCamera(dt) end
    for key, shell in ipairs(heliprojectileHandler.shells) do
        if shell.active then
            ProjectileOperations(shell)
        end
    end
    
    if InitTimeUp == false then
        InitTime = InitTime + dt
        if InitTime>10 then
            InitTimeUp = true
        end
    end
   
    ManageControlPanelInteractions(dt)
    
    ControlInputs()
    TargetSelectionInputs()

    PlaySounds()
    GunImputs()
    RocketImputs()

    --TestingButtons()
    RunSetupTick(dt)
end

function update(dt)
    --DebugWatch("gun", IsGunBroken)
    WorldVariables()
    ManageStartup()
    CheckDamage()
    ManageDamageEffects(dt)

    if DetailedControl then
        DetailedControlOffsets()
    end
    
    if IsFlying then
        MoveForward()
        MoveSideways()
        LeanForward()
        LeanSideways()

        ManageYaw()
        ManageCollective()

        XControlFunctions()

        ManageLanding()
    end

    CalculateMainRotorDragForce()    
    ApplyYawForce()

    ManageGun()

    CheckIfNear()
    RunOutOfPower()

    ManageAIUpdates(dt)
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

function WorldVariables()
	HeliTr = GetBodyTransform(Heli)
    HeliCoM = TransformToParentPoint(HeliTr,GetBodyCenterOfMass(Heli))

    --DebugLine(HeliCoM,HeliTr.pos,1,0,0)

	RotorPos = GetBodyTransform(MRotor).pos
    SideRotorPos = GetBodyTransform(SRotor).pos
    HeliVel = GetBodyVelocity(Heli)

    Axes[Forward] = TransformToParentVec(HeliTr,Vec(0,0,1))
    Axes[Upward] = TransformToParentVec(HeliTr,Vec(0,1,0))
    Axes[Right] = TransformToParentVec(HeliTr,Vec(1,0,0))

    --ShowAxes()
    PointF = VecAdd(HeliTr.pos,VecScale(Axes[Forward],PointDistanceForAngles))
    PointB = VecAdd(HeliTr.pos,VecScale(Axes[Forward],-PointDistanceForAngles))
    PointR = VecAdd(HeliTr.pos,VecScale(Axes[Right],PointDistanceForAngles))
    PointL = VecAdd(HeliTr.pos,VecScale(Axes[Right],-PointDistanceForAngles))
    PointU = VecAdd(HeliTr.pos,VecScale(Axes[Up],PointDistanceForAngles))
    PointD = VecAdd(HeliTr.pos,VecScale(Axes[Up],-PointDistanceForAngles))

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




    --YawDebug()

    CurrentHeight = HeliTr.pos[2]

    WorldXcontrol()

    SetTriggerTransform(InternalTrig,HeliTr)
	Inside = IsPointInTriggerGlobal(InternalTrig, InternalTrigLocalTr, GetCameraTransform().pos, Heli)
end

function Startup()
    if Fuelamount == 0 then return end
    if TooDamaged then return end
    CheckBrokenLiftOff()

	IsFlying = true
    IsEngineOn = true
    EngineStartCounterEXT = 0
    EngineStartCounterINT = 0
    EngineVolume = EngineVolume_Default

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

function TakeControl()
    if IsFlying == false then Startup() end
    DetailedControl = true
    ThirdPersonView = true
    PlayerPosInVehicle = TransformToLocalPoint(HeliTr,GetPlayerTransform().pos)
    CamLocalPos = PlayerPosInVehicle
    local q = QuatLookAt(Vec(0,0,0),QuatRotateVec(HeliTr.rot,Vec(0,-0.3,-1))) 
    local t = GetCameraTransform()
    t.rot = q
    SetCameraTransform(t,true)

	ToolName = GetString("game.player.tool")
    SetString("game.player.tool", "")
    IsHostile = false

    RocketCooldownMaxLong = RocketCooldownMaxLongPlayer
    RocketCooldownMaxShort = RocketCooldownMaxShortPlayer
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

    ApplyYawForceInit()
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

function StopControl()
    DetailedControl = false
    ThirdPersonView = false
    EnableGun = false
    EnableRocket = false
    TriggerHeld = false
    RocketTriggerHeld = false

	C_VerticalInput = none
	C_PitchInput = none
	C_SideInput  = none

    CollectiveOffset = 0
	MoveForwardOffset = 0
	MoveSideOffset = 0

    SetString("game.player.tool", ToolName)					
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
        SetJointMotor(MRotorJoint, 0,MaxMRotorRotationForce)
        SetJointMotor(SRotorJoint, 0,MaxSRotorRotationForce*5)
    end
    local f = ShutOffTimer/60/ShutOffTime
    SetJointMotor(MRotorJoint, MaxRotorSpeed*f,MaxMRotorRotationForce*f)
    SetJointMotor(SRotorJoint, MaxSRotorSpeed*f,MaxSRotorRotationForce*f)

    --cancelled landing
    if InputDown(C_UpButton) then
        Startup()
        ShutOff = false 
        StartTimer = StartUpTime*60*(1-f)
    end
end

--ideally there would be more variations of engine start
--ideally int / ext and type (run / start) shoudl be variables for an array
function InitSounds()
	Sound_External = LoadLoop("MOD/main/Mil-Mi-35P-Hind/snd/external.ogg")
	Sound_Internal = LoadLoop("MOD/main/Mil-Mi-35P-Hind/snd/internal.ogg")
	Sound_Critical = LoadLoop("MOD/main/Mil-Mi-35P-Hind/snd/critical_alarm.ogg")

    Sound_Crash_In = LoadSound("MOD/main/Mil-Mi-35P-Hind/snd/experimental.ogg")
	Sound_Crash_Out = LoadSound("MOD/main/Mil-Mi-35P-Hind/snd/heli_crash_out.ogg")

	InternalTrig = FindTrigger("internal")
	InternalTrigLocalTr = GetTriggerLocalTransform("internal",Heli)
	CriticalLocalTr = GetLocationLocalTransform("critical",Heli)


    Sound_EXT_engine_run = LoadLoop("MOD/main/Mil-Mi-35P-Hind/snd/EXT_AS350_engine_running.ogg")
    Sound_EXT_rotor_run = LoadLoop("MOD/main/Mil-Mi-35P-Hind/snd/EXT_AS350_rotor_running.ogg")
    Sound_EXT_engine_start = LoadLoop("MOD/main/Mil-Mi-35P-Hind/snd/EXT_AS350_engine_start.ogg")
    EngineStartTimeEXT = 24*60-1
    EngineStartCounterEXT = 0

    Sound_INT_engine_run = LoadLoop("MOD/main/Mil-Mi-35P-Hind/snd/INT_AS350_engine_running.ogg")
    Sound_INT_rotor_run = LoadLoop("MOD/main/Mil-Mi-35P-Hind/snd/INT_AS350_rotor_running.ogg")
    Sound_INT_engine_start = LoadLoop("MOD/main/Mil-Mi-35P-Hind/snd/INT_AS350_engine_start.ogg")
    EngineStartTimeINT = 2751
    EngineStartCounterINT = 0

    EngineVolume_Default = 1

    Sound_INT_vibration = LoadLoop("MOD/main/Mil-Mi-35P-Hind/snd/INT_AS350_cabin_vibrations.ogg")
end

function PlaySounds()
    if IsCrashed then return end

    --cabin vibration
    if TotalDamage>0.02 then
        PlayLoop(Sound_INT_vibration,TransformToParentPoint(HeliTr,SmokePosLocal),MapValues(TotalDamage,0.02,0.15,1,2)*MRotSpeedFraction*0.33)
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

        PlayLoop(INT_Sound,TransformToParentPoint(HeliTr,SmokePosLocal),INT_volume*40)
        PlayLoop(EXT_Sound,TransformToParentPoint(HeliTr,SmokePosLocal),EXT_volume*40)

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



function draw()
    if CurrentSetupMode == "PID adjustment" then
        DebugPIDAdjustment()
    end

    ControlPrompts()
end

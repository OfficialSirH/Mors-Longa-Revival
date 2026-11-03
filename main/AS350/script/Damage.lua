



function InitDamage()
    Pilot = FindShape("PilotTorso")
    PilotDead = Pilot== 0
    HasPilot = not PilotDead


    MRotorStartingVoxels = GetBodyVoxels(MRotor)
    SRotorStartingVoxels = GetBodyVoxels(SRotor)

    MRotorHealth = 1
    SRotorHealth = 1

    RotorGone = false
    SRotorGone = false

    Engine = FindShape("engine")
    EngineStartingVoxels = GetShapeVoxelCount(Engine)
    EngineHealth = 1

    Tail = FindShape("tail")
    TailStartingVoxels = GetShapeVoxelCount(Tail)
    TailHealth = 1
    LostYawControl = false

    MRotorJoint = FindJoint("MainRotor")
    MRotorShaft = FindShape("MShaft")
    SRotorJoint = FindJoint("s_rotor")
    SRotorShaft = FindShape("RearShaft")

    SmokePosLocal = GetLocationLocalTransform("smoke",Heli)
    EngineSmoking = false

    MRotorBody = Heli
    SRotorBody = Heli

    MRotorSlowFactor = 0
    SRotorSlowFactor = 0

    StartingConsoleVoxels = GetConsoleIntegrity(0)
    ConsoleBroken = false
    HeliStartingVoxels = GetBodyVoxels(Heli)
    TooDamaged = false
    BrokenLiftoffAttempt = false
    BrokenLiftOffTimeUp = false
	BrokenLiftOffTimer = 0
    IsCrashed = false
    InternalLights = FindLights("internal")
    CrashAltitude = GetBodyTransform(Heli).pos[2]+4
    PlayedCrashSound = false
    InitFuel()
    LightsOutTimer = 0
    LightsOutTime = 30*60
    
    WeAreGoingDown = false
    GoingDownFactor = 0
    GDYaw = 0
    GDSide = 0
    GDFrw = 0
    VerticalError = 0 --a positive number here means it will be going down
    RunningVerticalError = 0 --a slowly increasing vertical error making sure an out of control heli will eventually crash, rather than reach higher
    ForwardLeanOffsetError = 0
    RightLeanOffsetError = 0

    TotalDamage = 0
    HeliMass = GetBodyMass(Heli)
    HeliStartingMass = HeliMass
    HeliMassLoss = 0
    IsGunBroken = GunBody==0
    GunSize = GetBodyIntegrity(GunBody,0)
    RocketLauncher = FindShape("rocket")
    IsRocketBroken = RocketLauncher == 0
    RocketSize = GetShapeIntegrity(RocketLauncher,0)

    SensorRPM = FindShape("RPMSensor")
    SensorAltitude = FindShape("altitude")
    SensorAirSpeed = FindShape("airspeed")
    IsSensorDamagedRPM = false
    IsSensorDamagedAltitude = false
    IsSensorDamagedSpeed = false

    if DisableWeapons then
        IsRocketBroken = true
        IsGunBroken = true
    end
end

function IsShapeDamaged(sp)
    retval = false
    if IsHandleValid(sp) then
        retval = true
    else
        retval = IsShapeBroken(sp)
    end
    return retval
end

function InitFuel()
    FuelCapacity = 540
	Fuelamount = FuelCapacity
    local flightminutes = 30
    FuelUseFactor = FuelCapacity/(flightminutes*60)/60
	FuelLeak = 0
    StartingFuelIntegrity = GetFuelIntegrity(0)
end

function IsBodyConnected(b1,b2,joint)
    local result = true
    if IsHandleValid(b1) == false then result = false end
    if IsHandleValid(b2) == false then result = false end
    if IsHandleValid(joint) == false then result = false end
    if result then
        result = b2 == GetShapeBody(GetJointOtherShape(joint,GetBodyShapes(b1)[1]))
    end
    return result
end

function GetBodyIntegrity(body, StartingVoxels)
    local sps = GetBodyShapes(body)
    local totalVoxels = 0
    for i = 1,#sps,1 do
        totalVoxels = totalVoxels + GetShapeVoxelCount(sps[i])
    end

    if StartingVoxels == 0 then 
        return totalVoxels
    else
        return totalVoxels/StartingVoxels
    end
end

function GetShapeIntegrity(sp, StartingVoxels)
    local totalVoxels = GetShapeVoxelCount(sp)

    if StartingVoxels == 0 then 
        return totalVoxels
    else
        return totalVoxels/StartingVoxels
    end
end

function GetFuelIntegrity(StartingVoxels)
    local fs = FindShapes("fuel")
    local totalVoxels = 0
    for i = 1,#fs,1 do
        totalVoxels = totalVoxels + GetShapeVoxelCount(fs[i])
    end

    if StartingVoxels == 0 then 
        return totalVoxels
    else
        return totalVoxels/StartingVoxels
    end
end

function Shake(damage)
    if damage < 0.02 then return end
    if RotorGone then return end

    local shakeforce = math.cos(GetJointMovement(MRotorJoint)*math.pi/180)
    local v = TransformToParentVec(HeliTr,Vec(1,0,0))
    local ShakeStrength = 2500*(1-HeliMassLoss)*MapValues(damage,0.02,0.15,1,2)


    v = VecScale(v,shakeforce*MRotSpeedFraction*MRotorHealth*ShakeStrength)
    --DebugCross(HeliCoM,1,0,0)

    ApplyBodyImpulse(Heli,HeliCoM,v)

    --[[
    DebugWatch("heli", Heli)
    DebugWatch("CoM", VecStr(HeliCoM))
    DebugWatch("v", VecStr(v))
    DebugWatch("shakeforce", shakeforce)
    DebugWatch("MRotSpeedFraction", MRotSpeedFraction)
    DebugWatch("MRotorHealth", MRotorHealth)
    DebugWatch("HeliMassLoss", HeliMassLoss)
]]
end

function RunOutOfPower()
    if Fuelamount>0 and EngineHealth>0.5 then return end
    if LightsOutTimer > LightsOutTime then return end

    LightsOutTimer = LightsOutTimer + 1

    if LightsOutTimer > LightsOutTime then
        for i=1,#InternalLights,1 do
            SetLightEnabled(InternalLights[i], false)
        end
    end
end

function ManageFuel()
    if Fuelamount == 0 then return end
    Fuelamount = Fuelamount - FuelLeak - MRotSpeedFraction*FuelUseFactor
    if Fuelamount<0 then Fuelamount = 0 end
    if Fuelamount == 0 then
        

    end
    --DebugPrint(Fuelamount)
end

function CheckBrokenLiftOff()
    if HasPilot == false or TooDamaged or ConsoleBroken then
        BrokenLiftoffAttempt = true
    end
end

function ManageDamageEffects(dt)
    ManageBrokenStartup(dt)
    ManageEngineSmoke()
    CriticalAlert()
    ManageCrash()

    ManageFuel()
    InitialiseGoingDown()
    ManageGoingDown()

    Shake(TotalDamage)
    ManageSensorDamage()
end

function ManageBrokenStartup(dt)
	if BrokenLiftoffAttempt then
		BrokenLiftOffTimer = BrokenLiftOffTimer + dt
		if BrokenLiftOffTimer > 5 then
			BrokenLiftOffTimeUp = true
		end
	end
end

function GetConsoleIntegrity(StartingVoxels)
    local totalVoxels = 0
    totalVoxels = totalVoxels + GetShapeVoxelCount(FindShape("panel_left"))
    totalVoxels = totalVoxels + GetShapeVoxelCount(FindShape("panel_right"))
    totalVoxels = totalVoxels + GetShapeVoxelCount(FindShape("panel_top"))
    totalVoxels = totalVoxels + GetShapeVoxelCount(FindShape("panel_bottom"))

    if StartingVoxels == 0 then 
        return totalVoxels
    else
        return totalVoxels/StartingVoxels
    end
end

function GetBodyVoxels(bd)
    local sps = GetBodyShapes(bd)
    local result = 0
    for i = 1,#sps,1 do
        result = result + GetShapeVoxelCount(sps[i])
    end
    return result
end

function PilotDeathActions()
    local sps = FindShapes("PilotHead")
    for i= 1,#sps,1 do
        RemoveTag(sps[i],"PilotHead")
    end
    TargetSelectionMode = false
end

function CheckDamage()
    if SRotorSlowFactor>0 then
    if IsFlying then
    if SRotorGone == false then
        if SRotSpeedFraction<0.08 and MRotSpeedFraction>0.5 then 
            SRotorGone = true
            SetJointMotor(SRotorJoint, 0,0)
        end
    end
    end
    end

    if GetBool("game.break") then
        MRotorBody = GetShapeBody(GetJointOtherShape(MRotorJoint,MRotorShaft))
        SRotorBody = GetShapeBody(GetJointOtherShape(SRotorJoint,GetBodyShapes(SRotor)[1]))

        if PilotDead == false then
            if IsHandleValid(Pilot) == false then
                PilotDead = true
            elseif HasTag(Pilot, "dead") then
                PilotDead = true
            end
            if PilotDead then PilotDeathActions() end
        end

        MRotorHealth = GetBodyVoxels(MRotor) / MRotorStartingVoxels
        SRotorHealth = GetBodyVoxels(SRotor) / SRotorStartingVoxels

        HeliMass = GetBodyMass(Heli)
        HeliMassLoss = (HeliStartingMass-HeliMass)/HeliStartingMass

        EngineHealth = GetShapeVoxelCount(Engine) / EngineStartingVoxels
        if EngineHealth < 0.93 then
            EngineSmoking = true
        end

        if IsFlying then
            if EngineHealth~= 1 then
                local s =  MaxRotorSpeed_Def * EngineHealth
                if MaxRotorSpeed > s then MaxRotorSpeed = s end
                s = MaxSRotorSpeed_Def * EngineHealth
                if MaxSRotorSpeed>s then MaxSRotorSpeed =s end
                SetJointMotor(MRotorJoint, MaxRotorSpeed,MaxMRotorRotationForce)
                if SRotorGone == false then
                    SetJointMotor(SRotorJoint, MaxSRotorSpeed,MaxSRotorRotationForce)
                end
            end
        end

        if IsGunBroken == false then
            if IsBodyConnected(GunBody,Heli,GunHinge) == false then
                IsGunBroken = true
                
            else
                IsGunBroken = GetBodyIntegrity(GunBody, GunSize)<0.8
            end
        end 

        if IsRocketBroken == false then
            if GetShapeBody(RocketLauncher) ~= Heli then
                IsRocketBroken = true
            else
                IsRocketBroken = GetShapeIntegrity(RocketLauncher, RocketSize)<0.7
            end
        end 

        if RotorGone == false then
            if MRotorHealth < 0.5 or MRotorBody~=Heli  then 
                RotorGone = true 
                SetJointMotor(MRotorJoint, 0,0)
            end
        end
        if SRotorGone == false then
            if SRotorHealth < 0.5 or SRotorBody~=Heli then 
                SRotorGone = true
                SetJointMotor(SRotorJoint, 0,0)
            end
        end
        

        TailHealth = GetShapeVoxelCount(Tail) / TailStartingVoxels
        if TailHealth<0.85 then
            LostYawControl = true
        end

        if GetConsoleIntegrity(StartingConsoleVoxels) < 0.5 then
            TooDamaged = true
            ConsoleBroken = true
            LostControl()
        end

        TotalDamage = 1-GetBodyVoxels(Heli)/HeliStartingVoxels

        if TotalDamage>0.15 then
            TooDamaged = true
        end

        FuelLeak = (1-GetFuelIntegrity(StartingFuelIntegrity))*FuelUseFactor*10


        if IsSensorDamagedRPM == false then
            IsSensorDamagedRPM = IsShapeDamaged(SensorRPM)
            if IsSensorDamagedRPM then PeriodNS1 = math.random(80,100) end
        end
        if IsSensorDamagedAltitude == false then
            IsSensorDamagedAltitude = IsShapeDamaged(SensorAltitude)
            if IsSensorDamagedAltitude then PeriodNS2 = math.random(80,100) end
        end
        if IsSensorDamagedSpeed == false then
            IsSensorDamagedSpeed = IsShapeDamaged(SensorAirSpeed)
            if IsSensorDamagedSpeed then  PeriodNS3 = math.random(80,100) end
        end
    end

    MRotorSlowFactor = 0
    SRotorSlowFactor = 0
    if SRotorGone  then
        MRotorSlowFactor = MRotorSlowFactor + 0.0001
    end
    if EngineHealth<0.75 or Fuelamount== 0 then
        MRotorSlowFactor = MRotorSlowFactor + 0.0006
        SRotorSlowFactor = SRotorSlowFactor + 0.0006
    elseif IsShapeBroken(SRotorShaft) then
        SRotorSlowFactor = SRotorSlowFactor + 0.0008
    end


    if IsFlying then
        if MRotorSlowFactor>0 and MaxRotorSpeed>0 then
            MaxRotorSpeed = MaxRotorSpeed*(1-MRotorSlowFactor)
            if MaxRotorSpeed < MaxRotorSpeed_Def*0.005 then MaxRotorSpeed = 0 end
            SetJointMotor(MRotorJoint, MaxRotorSpeed,MaxMRotorRotationForce)
        end

        if SRotorGone == false then
        if SRotorSlowFactor>0 and MaxSRotorSpeed>0 then
            MaxSRotorSpeed = MaxSRotorSpeed*(1-SRotorSlowFactor)
            if MaxSRotorSpeed < MaxSRotorSpeed_Def*0.005 then MaxSRotorSpeed = 0 end
            SetJointMotor(SRotorJoint, MaxSRotorSpeed,MaxSRotorRotationForce)
        end
        end
    end


    if PilotDead then
        HasPilot = DetailedControl
    end

    -- if IsFlying == false then
    --     EngineSmoking = false
    -- end
    -- if EngineHealth<0.5 then
    --     EngineSmoking = false
    -- end


    if LightBroken == false then
        if IsHandleValid(searchLight) == false then
            LightBroken = true
        else
            if IsShapeBroken(GetBodyShapes(searchLight)[1]) then
                LightBroken = true
            end
        end

    end
end

function ManageEngineSmoke()
    if EngineSmoking then

        local p = TransformToParentPoint(HeliTr,SmokePosLocal)

        if EngineSmokeCounter == nil then EngineSmokeCounter = 0 end
        EngineSmokeCounter = EngineSmokeCounter + 1

        local dmgfrac = (1-EngineHealth)/0.5
        local smokewait = 0*dmgfrac+10*(1-dmgfrac)

        -- if EngineSmokeCounter >smokewait*(1+0.3*math.random(-100,100)/100) then
            -- EngineSmokeCounter = 0
            smoke(p, MRotSpeedFraction*MRotorHealth)
        -- end

    end
end

function smoke(particlepos,DownForce)
    local ForceFactor = 20
    ParticleType("smoke")
    ParticleColor(damage, damage, damage)
    ParticleEmissive(0)
    ParticleRadius(1*(1+0.3*math.random(-100,100)/100), 0.5*(1+0.3*math.random(-100,100)/100))
    ParticleAlpha(1000,0)
    ParticleCollide(1)
    ParticleDrag(0.6)
    ParticleGravity(5-DownForce*ForceFactor,10-DownForce*ForceFactor)
    ParticleStretch(1)
    SpawnParticle(particlepos, Vec(math.random(-1,1), math.random(-1,1), math.random(-1,1)),4)
    ParticleReset()
end



function MainRotorDragInit()
    local c= TransformToLocalPoint(HeliTr,RotorPos)
    RotorImpulseLocal = {}
    RotorImpulseLocal[1] = VecAdd(c,Vec(0,-0.3,1))
    RotorImpulseLocal[2] = VecAdd(c,Vec(0,-0.3,-1))
    RotationForce = 0
    
    RotationForceIncrease = MaxMRotorRotationForce/(60*5)
end

function MainRotorDrag()
    if RotorGone then return end
    if SRotorGone == false then return end
    RotationForce = RotationForce+RotationForceIncrease
    local i = MaxMRotorRotationForce*MRotSpeedFraction*MRotorHealth
    
    ApplyBodyImpulse(Heli,TransformToParentVec(HeliTr,RotorImpulseLocal[1]),VecScale(Axes[Right],-i) )
    ApplyBodyImpulse(Heli,TransformToParentVec(HeliTr,RotorImpulseLocal[2]),VecScale(Axes[Right],i) )
end

function LostControl()
	RemoveTag(FindShape("panel_left"), "interact")
	RemoveTag(FindShape("panel_right"), "interact")
	RemoveTag(FindShape("panel_top"), "interact")
	RemoveTag(FindShape("panel_bottom"), "interact")

	DetailedControl = false
	TargetSelectionMode = false
end


function CriticalAlert()
    if IsFlying == false then return end
    if ConsoleBroken then return end
    if BrokenLiftOffTimeUp then return end

    if HasPilot == false or TooDamaged or RotorGone or SRotorGone then
        PlayLoop(Sound_Critical,TransformToParentTransform(HeliTr,CriticalLocalTr).pos,1)
        for i=1,#InternalLights do
            SetLightColor(InternalLights[i], 1, 0, 0)
        end
    end

end


--how do I decide if it reached ground finally?
--check if slowing is needed
function ManageCrash()
    
    if BrokenLiftoffAttempt or TooDamaged then
        
        if GetBodyTransform(Heli).pos[2] < CrashAltitude or IsHandleValid(Heli)==false then
            RotorGone = true
            IsCrashed = true
            IsFlying = false
        end
    end

    if IsCrashed == false then return end

    LostControl()

    if IsHandleValid(Heli) == false then PlayedCrashSound = true end

    if not PlayedCrashSound and not brokenliftoffattempt then
        PlayedCrashSound = true
        if Inside then
            PlaySound(Sound_Crash_In, HeliCoM)
        else
            PlaySound(Sound_Crash_Out, HeliCoM)
        end
    end
end


function InitialiseGoingDown()
    --Spiralling out of control when there's too much damage, but still has some rotor to keep in air
    local damage = false
            
    if Fuelamount > 0 then
        if RotorGone==false and HasPilot == false and RotorGone==false and not BrokenLiftoffAttempt then
            damage = true
        end
    end

    if damage then
        if WeAreGoingDown == false then
            WeAreGoingDown = true
            PilotDeathActions()

            --Yaw (rotating sideways)
            GoingDownSpiralOffset = math.random(5,120)/100 --speed of spiralling in one direction (at 1 it can't turn back)
            if math.random(0,1) == 1 then GoingDownSpiralOffset = -GoingDownSpiralOffset end
            GoingDownSpiralForce = math.random(6,50)/60 --strength of spiralling
            SpiralPeriod = math.random(100,230)

            GoingDownSideForce1 =  math.random(-100,100)/10
            GoingDownSideForce2 = math.random(-100,100)/10

            GoingDownSideBias1 = math.random(-20,20)/100
            GoingDownSideBias2 = math.random(-20,20)/100
            SidePeriod1 = math.random(100,150)
            SidePeriod2 = math.random(100,150)
   

            GoingDownVerticalForce = math.random(10,100)/10
            GoingDownVerticalBias = math.random(-30,10)/100
            GoingDownVerticalPeriod = math.random(100,150)
            RunningVerticalError =0
            RunningVerticalErrorIncrease = 50/60/60/100

            GoingDownFactor = 0.1
            if HasPilot == false and ConsoleBroken then 
                GoingDownFactor = 1
            end
            SetValue("GoingDownFactor",1.5,"cosine",10)

        end
    else
        WeAreGoingDown = false
    end
end

function ManageSensorDamage()
    if IsSensorDamagedRPM then
        NS1Timer,NS1Last,NS1Next,NoiseAmountNS1 = Noise(NS1Timer,NS1Last,NS1Next,PeriodNS1)
    end
    if IsSensorDamagedAltitude then
        NS2Timer,NS2Last,NS2Next,NoiseAmountNS2 = Noise(NS2Timer,NS2Last,NS2Next,PeriodNS2)
    end
    if IsSensorDamagedSpeed then
        NS3Timer,NS3Last,NS3Next,NoiseAmountNS3 = Noise(NS3Timer,NS3Last,NS3Next,PeriodNS3)
    end
end


function ManageGoingDown()
    
	if IsCrashed or Fuelamount == 0 then
		WeAreGoingDown = false
        GDYaw = 0
        GDSide = 0
        GDFrw = 0
        VerticalError = 0
	end
    if WeAreGoingDown == false then return end

    --yaw
    local F = GoingDownSpiralForce
    local Offset = GoingDownSpiralOffset
    local Period = SpiralPeriod
	N1Timer,N1Last,N1Next,NoiseAmount = Noise(N1Timer,N1Last,N1Next,Period)
	NoiseAmount = (NoiseAmount+Offset)*F*GoingDownFactor
	YawVector = QuatRotateVec(QuatEuler(0,NoiseAmount,0),YawVector)


    --sideways
    F = GoingDownSideForce1
    Offset = GoingDownSideBias1
    Period = SidePeriod1

	N2Timer,N2Last,N2Next,NoiseAmount = Noise(N2Timer,N2Last,N2Next,Period)
    NoiseAmount = (NoiseAmount+Offset)*F*GoingDownFactor

    F = GoingDownSideForce2
    Offset = GoingDownSideBias2
    Period = SidePeriod2

	N3Timer,N3Last,N3Next,NoiseAmount2 = Noise(N3Timer,N3Last,N3Next,Period)
	NoiseAmount2 = (NoiseAmount2+Offset)*F*GoingDownFactor
    
    ForwardLeanOffsetError = NoiseAmount
    RightLeanOffsetError = NoiseAmount2


    F = GoingDownVerticalForce * 10^Val[PFactor]
    Offset = GoingDownVerticalBias * 10^Val[IFactor]
    Period = GoingDownVerticalPeriod * 10^Val[DFactor]

    --[[
    F = F * 10^Val[PFactor]
    Offset = Offset * 10^Val[IFactor]
    Period = Period * 10^Val[DFactor]
    --Range = Range * 10^Val[RangeFactor]
    DebugPrint("Force:" .. FormatNo(F,2) .. " Offset:" .. FormatNo(Offset*100,2) .. " Period:" .. FormatNo(Period,2))
    ]]

	--up / down
	N4Timer,N4Last,N4Next,NoiseAmount = Noise(N4Timer,N4Last,N4Next,60)
    RunningVerticalError =RunningVerticalError+RunningVerticalErrorIncrease
    NoiseAmount = NoiseAmount + RunningVerticalError

    NoiseAmount = (NoiseAmount+Offset)*F*GoingDownFactor
    VerticalError = NoiseAmount
    --GraphVal = VerticalError
end



function InitPointControl()
    target = Vec(0,0,0)
    TargetSelectionMode = false
    PilotShapes = FindShapes("PilotHead")
    if IsHostile == false then
    for i = 1,#PilotShapes,1 do
        SetTag(PilotShapes[i],"interact","Take a ride")
    end
    end
    MinHeightOffset = 10 --fly at least this much above the target (unless target is in air)

    Landing = false
    TravelHeightReached = false
    targetacquired = false
	targetreached = false
    CruisingAltitude = 0

    CruisingLastP = 0
    CruisingI = 0

    HeightChange = 1.5

    localTarget = Vec(0,0,0)
    PointTargetDist = 0


    TowardLastP = 0
    TowardI = 0
    TowardRightLastP = 0
    TowardRightI = 0

    LandingSpeed = 1 --m/s

    MoveWithoutYaw = false
    MinYawRange = 10
end

function StartRide()
    TargetSelectionMode = true
    if IsFlying == false then Startup() end
    MoveForwardOffset = 0
	MoveSideOffset = 0
    CollectiveOffset = 0
end

function FlyToTarget(tgt,NoTurn,ReachAltitde)
    target = tgt --world pos to move to, it will fly a bit above the target assuming target is on ground
    --NoTurn: means flying without turning toward the target for flying, good when aiming at something
    --default behavior if nil: don't turn when there's a target to aim at
    if NoTurn == nil then
        MoveWithoutYaw = AimTarget ~= nil
    else
        MoveWithoutYaw = NoTurn
    end
    --ReachAltitde: if true or nil it will go straight up to the final cruising height before moving forward, otherwise moves forward straight
    if ReachAltitde == nil then ReachAltitde = true end

    targetacquired = true
    targetreached = false

    Landing = false
    TravelHeightReached = not ReachAltitde
    AdjustCruisingAltitude(false)
end

function GetTargetFromCamDir()
    local target,hit = GetAimPos(200,2)
    --if pointing at the sky, go in that direction without changing height
    if hit == false then
        target[2] = HeliTr.pos[2] - MinHeightOffset
    end
    return target
end

function TargetSelectionInputs()
    if TargetSelectionMode == false then return end
    if IsHostile then return end
    if IsFlying then
		if InputPressed("X") then
			QueryRejectSelf()
            target = GetTargetFromCamDir()

            FlyToTarget(target,nil,nil)
		end

        if InputPressed("Z") then
            TravelHeightReached = true
        end

		if InputPressed("C") then
			Landing = true
		end

        if InputPressed("ctrl") and TargetSelectionMode then
			CruisingAltitude = CruisingAltitude - HeightChange
		end
		if InputPressed("shift") and TargetSelectionMode then
			CruisingAltitude = CruisingAltitude + HeightChange
			Landing = false
		end
	end
end

function AdjustCruisingAltitude(starting)
	local MinHeight = -1000
	
	if starting then 
		WorldVariables()
		MinHeight = CurrentHeight+ MinHeightOffset 
	else
		if target[2]+MinHeightOffset>MinHeight then MinHeight = target[2]+MinHeightOffset end
	end

	if MinHeight>CruisingAltitude then
		CruisingAltitude = MinHeight
	end
end

--P is positive when going up
function KeepCruisingHeight()
    local P = CruisingAltitude - CurrentHeight
    local D = (P-CruisingLastP)*60
    CruisingLastP = P
    local I = CruisingI + P
    if math.abs(P)>0.5 then
        I = 0
    end
    CruisingI = I

    local PConst = 5
    local IConst = 0.001
    local DConst = 0.1
    local Range = 3.5


    local C = math.clamp(PConst*(P+IConst*I+DConst*D),-Range,Range)
    CollectiveOffset = C

    if math.abs(P) < 0.3 then
        TravelHeightReached = true
    end
end

function WorldXcontrol()
    if TargetSelectionMode == false then return end
    if targetacquired == false then return end
    localTarget = TransformToLocalPoint(HeliTr,target)
    localTarget[2] = 0
    PointTargetDist = VecLength(localTarget)
end

function XControlFunctions()
    if TargetSelectionMode == false then return end
    if Starting then return end
    KeepCruisingHeight()
    AutoLanding()
    if TravelHeightReached == false then return end
    if targetacquired == false then return end
    TurnTowardTarget()
    GoTowardTarget()

    TargetReached()
    
end

function TargetReached()
    if PointTargetDist>2 then return end
    targetacquired = false
    MoveForwardOffset = 0
    MoveSideOffset = 0
end

function TurnTowardTarget()
    if MoveWithoutYaw then return end
    if PointTargetDist<MinYawRange then return end
    local t = VecCopy(target)
    t[2] = HeliTr.pos[2]
    local q = QuatLookAt(HeliTr.pos,t)
    YawVector = QuatRotateVec(q,Vec(0,0,1))
end

function TurnTowardAimTarget()
    if AimTarget == nil then return end
    if DetailedControl then return end
    local t = VecCopy(AimTarget)
    local correction = TransformToParentVec(HeliTr,Vec(1.2,0,0)) -- stupid way of correcting for heli bias in aiming
    

    t[2] = HeliTr.pos[2]
    local q = Quat()
    if EnableGun then
        q = QuatLookAt(GunTr.pos,t)
        t = VecAdd(t,correction)
    else
        q = QuatLookAt(HeliTr.pos,t)
    end
    
    YawVector = QuatRotateVec(q,Vec(0,0,1))
end

function GoTowardTarget()
    offsetlimit = 30
    local f = 1
    local MaxYawDiff = 0.3
    if math.abs(YawDifference)>MaxYawDiff then
        f =0
    else
        f = (1-math.abs(YawDifference)/MaxYawDiff)
    end
    if MoveWithoutYaw then f= 1 end

    local P = localTarget[3]
    local D = (P-TowardLastP)*60
    TowardLastP = P
    P = math.clamp(P,-offsetlimit,offsetlimit)
    local I = TowardI + P
    if math.abs(P)>0.5 then
        I = 0
    end
    TowardI = I

    local PConst = 0.4
    local IConst = 0.0001
    local DConst = 0.3
    local Range = 20

    local C = math.clamp(PConst*(P+IConst*I+DConst*D),-Range,Range)
    MoveForwardOffset = C*f

    ------------------------------------------------------------------------
    if MoveWithoutYaw == false then
    offsetlimit = offsetlimit /4
    end
    P = localTarget[1]
    
    D = (P-TowardRightLastP)*60
    TowardRightLastP = P
    P = math.clamp(P,-offsetlimit,offsetlimit)
    I = TowardRightI + P
    if math.abs(P)>0.5 then
        I = 0
    end
    TowardRightI = I

    if MoveWithoutYaw == false then
        PConst = 0.056
        IConst = 0.001
        DConst = 0.06
    end

    C = math.clamp(PConst*(P+IConst*I+DConst*D),-Range,Range)
    MoveSideOffset = C*f

end

function AutoLanding()
    if Landing == false then return end
    if targetacquired then return end
    CruisingAltitude = CruisingAltitude - LandingSpeed/60
end
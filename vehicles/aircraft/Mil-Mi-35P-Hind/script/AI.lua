#include "AI_Gore.lua"

function InitAI()

	--Delete the searchlight as I couldn't get it to work properly
    if IsHostile then StopControl() end

	DummyTimer = 0

	TargetVisible = false
	TargetDetected = false
	DetectionCounter = 0
	DetectionCounterMax = 5
	
	PlayerPos = {}
	TargetLostTime = 5*60 --how quickly to lose target
	TargetAcquiredTime = 45 --how quickly to recognise visible target

	DetectionMeter = 0

	LostTarget = false --true when AI just lost sight of player
	TargetDist2D = 0

	TargetVec = Vec(0,0,0)
	LastSeenPos = VecAdd(GetPlayerTransform().pos,Vec(rndFloat(-15,15),1,rndFloat(-15,15)))

	ExpectedPos = Vec(0,0,0)
	AIAction = ""
	AIActionShoot = ""

	AIStartupTime = 0
	AIWarmedUp = false
	AILastMove = ""

	AIAltitude = 18
	AICruisingAltitude = 0
	InitTargetDistances()

	IsAiming = false

	MovingInRange = 0
	Closer = 1
	Further = 2

	AIRocketReady = false
	AIRocketWaitTimer = 0
	PlayerFirstSeen = false

	AIStartWaitTime = 5

	WorldVariables()

	local hit, dist, normal, shape = QueryRaycast(HeliTr.pos, Vec(0,-1,0), 50)
	if hit then
		AICruisingAltitude = CurrentHeight+AIAltitude - dist
	else
		AICruisingAltitude = CurrentHeight
	end

	CruisingAltitude = AICruisingAltitude
end

function InitTargetDistances()
	IdealRange = 35
	IdealMin = 21
	IdealMax = 50

	TargetMin = 25
	TargetMax = 75
end


function AIWaitForStartup(dt)
	AIStartupTime = AIStartupTime+dt
	if AIStartupTime>AIStartWaitTime or CruisingAltitude-CurrentHeight<1 then 
		AIWarmedUp = true 
		CruisingAltitude = AICruisingAltitude
	end
end

--The AI heli won't start immediately shooting the player with rockets it will 
--first only use the gun to avoid "wasting ammo" and being too unfair
--it also won't start the counter until foudn the player, but will switch quicker if the player has a vehicle
function AIWaitForRockets(dt)
	if PlayerFirstSeen == false then return end
	if AIRocketReady == false then
		AIRocketWaitTimer = AIRocketWaitTimer+dt
		PlayerVehicle = QueryRejectVehiclePlus()
		if PlayerVehicle~= 0 then
			AIRocketWaitTimer = AIRocketWaitTimer+dt*2
		end

		if AIRocketWaitTimer>120 then AIRocketReady = true end
	end
end

function GetTargetPos()
	if TargetVisible then
		ExpectedPos = PlayerPos
		LastSeenPos = PlayerPos
	else
		ExpectedPos = LastSeenPos
	end

end

function ManageAIUpdates(dt)

	ai_gore_tick()
	if not IncludeNPCs then PlayerPos = VecAdd(GetPlayerTransform().pos, Vec(0, 1, 0)) end


    if IsHostile == false then return end
	if HasPilot == false then return end

	if AIWarmedUp == false then
		AIWaitForStartup(dt)
		return
	end

	CruisingAltitude = AICruisingAltitude

	TargetCheck()
	GetTargetPos()

	--MoveAndShootShowCase(dt)

	--main decisions
	EnableGun = false
	EnableRocket = false
	
	if targetreached then AILastMove = "" end
	AIActionShoot = ""
	if TargetDetected then
		
		if AILastMove == "Random Investigation" or AILastMove == "Last Seen" then 
			TargetReached()
		end


		IsAiming = TargetDist2D>TargetMin and TargetDist2D<TargetMax
		if PointTargetDist<7 then IsAiming = true end
		if IsAiming then
			AimAndShootPlayer()
		else
			AimTarget = nil
		end

		MoveInRange()
	else

		if LostTarget then
			InvestigateLastSeenPos()
		else
			InvestigateRandomly()
		end

	end
	

	--DebugWatch("Action: ", AIAction.. " " .. AIActionShoot)
	--DebugWatch("move: ", AILastMove)
end

function InvestigateLastSeenPos()
	if targetacquired  then return end
	LostTarget = false
	AimTarget = LastSeenPos
	TurnTowardAimTarget()
	local dir = VecSub(LastSeenPos,HeliTr.pos)
	local l = VecLength(dir)
	dir = VecScale(dir, 10/l)
	
	local tgt = VecAdd(LastSeenPos,dir)
	tgt = VecAdd(tgt,Vec(rndFloat(-10,10),0,rndFloat(-10,10)))
	tgt[2] = HeliTr.pos[2]-MinHeightOffset
	
	FlyToTarget(tgt,nil,nil)
	AIAction = "Investigate last seen"
	AILastMove = "Last Seen"
end

function AimAndShootPlayer()
	AimTarget = ExpectedPos
	TurnTowardAimTarget()
	EnableGun = true
	TriggerHeld = TargetMiss<0.07
	AIActionShoot = "Shoot"

	if TargetVisible and TargetDetected then
		if LeanForwardAmount<0.4 then
			if math.abs(GunPitch)<30 and TargetMiss<0.06 then
				EnableRocket = true
			end
		end
	end

	if math.abs(GunPitch)<20 then
	RocketTriggerHeld = TargetMiss<0.03
	end
end

function MoveInRange()
	if AimTarget == nil then return end
	local reached = false
	if TargetDist2D<IdealMin then
		MovingInRange = Further
		AIAction = "Move further"
		AILastMove = "Move further"
	end
	if TargetDist2D>IdealMax then
		MovingInRange = Closer
		AIAction = "Move closer"
		AILastMove = "Move closer"
	end

	reached = MovingInRange == Closer and TargetDist2D<IdealRange
	if MovingInRange == Further and TargetDist2D>IdealRange then reached = true end
	if reached then
		MovingInRange = 0
		AIAction = "got in range"
		AILastMove = "got in range"
	end

	if MovingInRange == 0 then return end

	--if targetacquired  then return end
	local predicttime = 0.5
	local tgtpred = VecAdd(AimTarget,VecScale(GetPlayerVelocity(),predicttime))
	local helipos = VecAdd(HeliTr.pos,VecScale(HeliVel,predicttime))


	TargetVec = VecSub(tgtpred,helipos)
	local dir = Vec2D(TargetVec)
	TargetDist2D = VecLength(dir)
	dir = VecNormalize(dir)

	local tgt = VecAdd(helipos, VecScale(dir,TargetDist2D-IdealRange))

	tgt[2] = HeliTr.pos[2]-MinHeightOffset

	FlyToTarget(tgt,nil,nil)


end

function InvestigateRandomly()
	EnableGun = false
	if targetacquired then return end
		AIAction = "Investigating randomly"
		local tgt = VecAdd(ExpectedPos,Vec(rndFloat(-50,50),0,rndFloat(-50,50)))
		tgt[2] = HeliTr.pos[2]-MinHeightOffset
		AimTarget = nil
		FlyToTarget(tgt,nil,nil)
		AILastMove = "Random Investigation"
end



function MoveAndShootShowCase(dt)
	DummyTimer = DummyTimer + dt

	if DummyTimer>2 then
		TargetReached()
		if DummyTimer>1*60+60 then DummyTimer = 0

		else
			if DummyTimer>1*8 then
				AimTarget = PlayerPos
				TurnTowardAimTarget()
				EnableGun = true
				TriggerHeld = TargetMiss<0.07
			else
				EnableGun = false
				if targetacquired == false then
					local tgt =  VecAdd(PlayerPos,Vec(rndFloat(-20,20),0,rndFloat(-20,20)))
					tgt[2] = HeliTr.pos[2]-MinHeightOffset
					AimTarget = nil
					FlyToTarget(tgt,nil,nil)
				end
			end
		end
	end
end


function rndFloat(mi, ma)
	return mi + (ma-mi)*(math.random(0, 1000000)/1000000.0)
end

function getDistanceToPlayer()
	local playerPos = GetPlayerTransform().pos
    playerPos[2] = playerPos[2] + 0.9 -- get center
	return VecLength(VecSub(playerPos, HeliTr.pos))
end

function NoCheckFrame()
	local nocheck = false
	DetectionCounter = DetectionCounter + 1
	if DetectionCounter > DetectionCounterMax then
		DetectionCounter = 0
		nocheck = false
	else
		nocheck = true
	end
	return nocheck
end

function TargetCheck()


	if NoCheckFrame() then return end

	--actual detection
	local SourcePos = HeliTr.pos
	TargetVisible = false

	QueryRejectSelf()
	TargetVec = VecSub(PlayerPos,SourcePos)
	local TargetDir = VecNormalize(TargetVec)
	local TargetDistance = VecLength(TargetVec)

	TargetDist2D = VecLength(Vec2D(TargetVec))

	--do not count being inside a vehicle as hiding
	PlayerVehicle = QueryRejectVehiclePlus()
	QueryRejectSelf()
	local hit, dist, normal, shape = QueryRaycast(PlayerPos, VecScale(TargetDir,-1), TargetDistance*1.2, 0, 1)

	if hit then
		if dist> TargetDistance-0.5 then 
			TargetVisible = true
		end
	else
		TargetVisible = true
	end

	if SelectedTarget.type == TargetTypes.torso then
		TargetVisible = true
	end


	local Visibility = 0
	if TargetVisible then
		Visibility = 1
		--take care of factors affecting visibility (it can go down from 1 to lower)

		local environmentalvisibility = 1
		if GetBool("level.IsSandstorm") then environmentalvisibility = environmentalvisibility*0.5 end
		if GetString("level.dayphase") == "Night" then environmentalvisibility = environmentalvisibility*0.66 end
		Visibility = Visibility*environmentalvisibility

		local FarDist = 50
		if TargetDistance>FarDist then
			Visibility = Visibility*FarDist/TargetDistance
		end

		local FacingAway =VecFacingDifference(Axes[Forward],VecScale(TargetDir,-1),Axes[Right],Axes[Upward])
		FacingAway = MapValues(math.abs(FacingAway),0.3,0.75,0,0.3)
		Visibility = Visibility*(1-FacingAway)
		
		if PlayerVehicle~=0 then Visibility = Visibility*1.6 end
		
		local v = VecLength(GetPlayerVelocity())
		v = MapValues(v,0.5,7,0,0.6)
		Visibility = Visibility*(1+v)
	end

	if TargetVisible then
		
		DetectionMeter = DetectionMeter + 1/TargetAcquiredTime *DetectionCounterMax*Visibility
	else
		DetectionMeter = DetectionMeter - 1/TargetLostTime *DetectionCounterMax
	end
	
	DetectionMeter = math.clamp(DetectionMeter, 0, 1)
	--change in detection state
	if DetectionMeter == 0 and TargetDetected then
		TargetDetected = false
		LostTarget = true
		AIAction = "Lost Target"
	elseif DetectionMeter == 1 and TargetDetected == false then
		TargetDetected = true
		AIAction = "Found target"
		TargetReached()
		PlayerFirstSeen = true
	end

	--DebugWatch("Detection" , DetectionMeter)
end

function MapValues(CurrentVal, MinIn, MaxIn, MinOut, MaxOut)
	local MappedOut = 0
	if CurrentVal<MinIn then
		MappedOut = MinOut
	elseif CurrentVal>MaxIn then
		MappedOut = MaxOut
	else
		MappedOut = MinOut + (CurrentVal-MinIn)/(MaxIn-MinIn)
	end

	return MappedOut
end
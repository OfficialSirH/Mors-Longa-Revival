




--separate thing didn't quite work, need separate PID for height difference it can quickly increase one decrease another based on height difference
--keep the difference value and slowly update


--weird how the rotor keeps slowing down forever
--maybe the acceleration is not meant to be constantly added, maybe it was meant to be a constant P controller just done wrong

--maybe some mini game with shooting the other one maybe some tactical stuff like the battle with simplified view


--[[
#include "Debug.lua"
#include "Graph.lua"
#include "UiFunctions.lua"
#include "UiSettings.lua"
]]

function init()
	--constants
	DefaultMaxHeight = 10
	CruisingAltitude = DefaultMaxHeight
	
	Heli = FindBody("Heli")
	StartingAltitude = GetBodyTransform(Heli).pos[2]
	helistartmass = GetBodyMass(Heli)
	RotorBodies = FindBodies("rot")
	
	insnd = LoadSound("MOD/main/Boeing_CH47-C/snd/experimental.ogg")
	outsnd = LoadSound("MOD/main/Boeing_CH47-C/snd/heli_crash_out.ogg")
	
	Front = 1
	Back = 2
	HeightPoint = {}
	RotorPos = {}
	HeliTr = Transform()
	Current2DLocalpos = Vec()
	LocalRotorPos = {}
	RotorPosOnHeli = {}
	RotorPosOnHeliLower = {}
	for i =1,2,1 do
		LocalRotorPos[i] = Vec()
	end
	WorldVariables()
	Current2Dpos = VecLerp(RotorPos[Front],RotorPos[Back],0.5)
	
	Current2DLocalpos = TransformToLocalPoint(HeliTr,Current2Dpos)
	LocalRotorPos = {}
	for i =1,2,1 do
		LocalRotorPos[i] = TransformToLocalPoint(HeliTr,RotorPos[i])
	end
	Desired2DPos = Current2Dpos

	AllBodies = FindBodies("")
	Sound_External = LoadLoop("MOD/main/Boeing_CH47-C/snd/external.ogg")
	Sound_Internal = LoadLoop("MOD/main/Boeing_CH47-C/snd/internal.ogg")
	Sound_Critical = LoadLoop("MOD/main/Boeing_CH47-C/snd/critical_alarm.ogg")
	InternalTrig = FindTrigger("internal")
	InternalTrigLocalTr = GetTriggerLocalTransform("internal",Heli)
	CriticalLocalTr = GetLocationLocalTransform("critical",Heli)

	--Ramp
	RampButton = FindShape("ramp_button")
	SetTag(RampButton, "interact", "toggle ramp")
	IsRampClosed = true
	RampJoints = FindJoints("ramp")
	RampTimeOut = 0.3
	RampMotorSpeed = 0
	RampInteractTimer = RampTimeOut+1

	--Control
	MainPanel = FindShape("panel_liftoff")
	TargetSelectPanel = FindShape("take_control")
	ThirdPersonPanel = FindShape("display_r1")
	DetailedControlPanel = FindShape("display_l1")
	PanelCooldownTimer = 100
	TargetTolerance = 15
	target = Vec(0,0,0)
	TargetSelectionMode = false
	targetreached = true
	ThirdPersonView = false
	Landing = false
	HeightChange = 2
	LandingSpeed = 1 --m/s
	TravelHeightReached = false
	DetailedControl = false
	WaitForCruisingAltitude = true

	WeAreGoingDown = false



	--rotor
	RotorJoints = FindJoints("engine")

	startrotormass = {}
	for i = 1,2,1 do
		startrotormass[i] = GetBodyMass(RotorBodies[i])
	end
	--DebugPrint(VecStr(GetBodyCenterOfMass(RotorBodies[1])))

	RotorSpeed = 0
	RotorSpeedLimit = 30
	MaxRotorSpeed = RotorSpeedLimit
	VerticalPredictionSeconds = 6 --checks how far from the ideal height will be this many seconds in the future so the keeping of height is more stable
	VertAcceleration = 0.01

	RotorHealth = {}
	for i = 1,#RotorBodies,1 do
		RotorHealth[i] = 1
	end
	--Forward offset for keeping the nose straight, increasing strenght of front rotor by adding a power as % of max rotor speed
	ForwardOffset = 0
	ForwardOffsetAcceleration = 0.1/60
	ForwardOffsetPredictionAmount = 1

	BoosterFraction = 0

	--flying
	IsFlying = false
	MinHeightOffset = 10 --fly at least this much above the target (unless target is in air)

	--damage
	interactrange = 3

	EnableTrigger = false
	RemainingRotorVoxels = 9099990
	Console = FindShape("Console") --thing containing control surfaces
	SwitchOffPrompts = false

	BrokenLiftOffTimeUp = false
	BrokenLiftOffTimer = 0
	FuelCapacity = 3900
	Fuelamount = FuelCapacity
	FuelLeak = 0
	pilot = FindBody("Pilot")
	local tr = GetBodyTransform(pilot)
	tr.pos = VecAdd(tr.pos,TransformToParentVec(HeliTr,Vec(0,0,0.3)))
	Pilot1LocalTr = TransformToLocalTransform(HeliTr,tr)
	local tr = GetBodyTransform(pilot2)
	tr.pos = VecAdd(tr.pos,TransformToParentVec(HeliTr,Vec(0,0,0.3)))
	Pilot2LocalTr = TransformToLocalTransform(HeliTr,tr)
	pilot2 = FindBody("Pilot2")
	Pilot1Dead = pilot ==0	
	Pilot2Dead = pilot2==0	
	
	HeadLights = FindLights("headlight")
	for i = 1,#HeadLights,1 do
		SetLightEnabled(HeadLights[i],false)
	end

	FuelIntegrity = 0

	fuelline = FindShape("fuelline")
	SFuelIntegrity = 0
	Fuel = FindShapes("fuel")
	for i=1,#Fuel do
		SFuelIntegrity = SFuelIntegrity + GetShapeVoxelCount(Fuel[i]) 
	end
	Nullify = 1 --goes up to 4 when fuel line is broken increasing the amount of smoke
	SConsoleIntegrity = GetShapeVoxelCount(Console)
	damage = 0
	divam = 1.2
	allowedfordamage = helistartmass/divam
	realslow = 1
	brokenliftoffattempt = false


	--other
	BoosterPower = 28
	QuickStart = false --for testing it starts quickly without warmup

	impulsepos = Vec(5,5,0)
	imp = Vec(190, 0, 0)

	InitCamera()

	if QuickStart then
		RotorSpeed = MaxRotorSpeed*0.75
		IsFlying = true
		TargetSelectionMode = true
	end

	InitialiseControl()

	initGraph()

	ShowOptions = false
	InitialiseOptions()



	PilotView_loc_1p = TransformToLocalPoint(GetBodyTransform(Heli),  GetLocationTransform(FindLocation("Pilot_View_1p")).pos)
	PilotView_loc_3p = TransformToLocalPoint(GetBodyTransform(Heli),  GetLocationTransform(FindLocation("Pilot_View_3p")).pos)

	RollStabiliserBroken = false
	RollStabiliserBreakChance = 0.2

	InitRopes()

	ShowControlCounter = 0
	ShowControlTime = 15
	ControlFadeTime = 1.5
end

function InitRopes()
	--position
	RopeDown = 0.5
	Ropeforward = 1.4
	RopeBackward = 4.7
	RopeSide = 1.8
	--camera
	RopeLookDownDefault = 2
	RopeLookDown = RopeLookDownDefault
	RopeCamOut = 1.1
	RopeCamDown = 0.4
	--rope
	RopeLength = 5
	RopeStrength = 4000
	RopeMaxStretch = 0.02

	--internal
	RopeCount = 4
	RopeNo = 0 --if 0 rope camera is not enabled otherwise one of the others

	RopeAttaching = false
	RopeSwitching = false

	Ropes = {}

	RopePosLoc = {}
	RopeShapes = {}
	RopesDetached = false
	RopeCamPosLoc = {}
	RopePosLoc[1] = Vec(RopeSide,-RopeDown, -Ropeforward)
	RopePosLoc[2] = Vec(-RopeSide,-RopeDown, -Ropeforward)
	RopePosLoc[3] = Vec(-RopeSide,-RopeDown, RopeBackward)
	RopePosLoc[4] = Vec(RopeSide,-RopeDown, RopeBackward)
	for i= 1,RopeCount,1 do
		RopeCamPosLoc[i] = VecScale(RopePosLoc[i], 1+RopeCamOut)
		RopeCamPosLoc[i][2] = RopePosLoc[i][2]-RopeCamDown
		Ropes[i] = 0
	end


end

function RollStabiliser()
	if RollStabiliserBroken then return end
	if RotorHealth[1]==0 or RotorHealth[2]==0 then return end

	local pr = TransformToParentPoint(HeliTr,Vec(1.5,1.5,1))
	local pl = TransformToParentPoint(HeliTr,Vec(-1.5,1.5,1))

	local d = pl[2]-pr[2]
	local v = GetBodyVelocityAtPos(Heli,pl)[2]-GetBodyVelocityAtPos(Heli,pr)[2]
	

	local pvel = d+2*v --positive when rolling right
	local a = pvel*5000

	
	ApplyBodyImpulse(Heli,pr,Vec(0,a,0))
	ApplyBodyImpulse(Heli,pl,Vec(0,-a,0))

end

function InitCamera()
	cameraX = 0
	cameraY = 0
	zoom = 10
	DesiredZoom = 10
	ZoomIncVel = 0

	PlayerCamDir = TransformCopy(GetCameraTransform()).rot
	Is1PZoom = false
	CamLocalPos = TransformToLocalPoint(HeliTr,GetCameraTransform().pos)
end

function SidewaysForce(factor)
	if targetacquired and not targetreached then return end
	if WeAreGoingDown then return end

	--DebugWatch("sideways force", x)
	local sideoffset = VecSub(Desired2DPos,Current2Dpos)
	local MinDist = 0
	local MaxDist = 2	
	local MaxSideSpeed = 1
	local v = GetBodyVelocity(Heli)
	local Sideimp = Vec(0,0,0)
	if factor == nil then factor = 1 end
	local MaxImpulse = 3000*factor
	sideoffset = VecSub(sideoffset,VecScale(v,6))

	for axis = 1,3,2 do
		if math.abs(sideoffset[axis]) > MinDist then
			local f = (math.abs(sideoffset[axis]) - MinDist) / (MaxDist - MinDist)
			if sideoffset[axis]<0 then f = -f end
			if f>1 then f = 1 end
			Sideimp[axis] = f*MaxImpulse
		end
	end

	for i = Front,Back,1 do
		if RotorHealth[i] > 0 then
			ApplyBodyImpulse(RotorBodies[i],RotorPosOnHeli[i],Sideimp)
		end
	end

	--DebugPrint(VecStr(imp))
	--RotorPos[Front],RotorPos[Back]
end

function LostControl()
	RemoveTag(MainPanel, "interact")
	RemoveTag(TargetSelectPanel, "interact")
	--RemoveTag(ThirdPersonPanel, "interact")
	RemoveTag(DetailedControlPanel, "interact")
	DetailedControl = false
	TargetSelectionMode = false
	RopeNo = 0

end

function QueryRejectSelf()
	for i= 1,#AllBodies,1 do
		QueryRejectBody(AllBodies[i])
	end
end

function WorldVariables()
	HeliTr = GetBodyTransform(Heli)
	HeightPoint[Front] = TransformToParentPoint(GetBodyTransform(Heli),Vec(0,0,-7))
	HeightPoint[Back]  = TransformToParentPoint(GetBodyTransform(Heli),Vec(0,0,7))
	RotorPos[Front] = GetBodyTransform(RotorBodies[Front]).pos
	RotorPos[Back] =  GetBodyTransform(RotorBodies[Back]).pos
	Current2Dpos = TransformToParentPoint(HeliTr,Current2DLocalpos)

	CurrentHeight = VecLerp(HeightPoint[Front],HeightPoint[Back],0.5)[2]

	local PosDiff = VecSub(Current2Dpos,Last2DPos)
	if math.abs(PosDiff[1])>2 or math.abs(PosDiff[3])>2 then
		--probably teleported, adjust the desired position
		Desired2DPos = VecAdd(Desired2DPos,PosDiff)
	end

	for i = 1,2,1 do
		RotorPosOnHeli[i] = TransformToParentPoint(HeliTr,LocalRotorPos[i])
		RotorPosOnHeliLower[i] = TransformToParentPoint(HeliTr,VecAdd(LocalRotorPos[i],Vec(0,-1.3,0)))
	end

	Last2DPos = Current2Dpos
end

function tick(dt)
	InteractRamp(dt)
	ManageControlPanelInteractions(dt)
end

function InteractRamp()
	local b = false
	b = GetPlayerInteractShape() == RampButton and InputPressed("interact") and RampInteractTimer > RampTimeOut
	if b == false then
		if TargetSelectionMode or DetailedControl then
			b = InputPressed("r")
		end
	end

	if b  then
		RampInteractTimer = 0
		RampMotorSpeed = 0.4
		if  IsRampClosed then
			IsRampClosed = false
		else
			IsRampClosed = true
		end
	end
end


function MoveRamp(dt)
	if RampInteractTimer<RampTimeOut*2 then
		RampInteractTimer = RampInteractTimer + dt 
	end
	
	if RampMotorSpeed>0.001 then
		RampMotorSpeed = RampMotorSpeed / 1.008 --slow down the movement of the joint, eventually stops
	else
		RampMotorSpeed = 0
	end
	if not IsRampClosed then
		for i=1,#RampJoints do
			SetJointMotor(RampJoints[i], -RampMotorSpeed)
		end
	end
	if IsRampClosed then
		for i=1,#RampJoints do
			SetJointMotor(RampJoints[i], RampMotorSpeed)
		end
	end
end


function AdjustCruisingAltitude(starting)

	local MinHeight = -1000
	
	if starting then 
		WorldVariables()
		MinHeight = CurrentHeight
		MinHeight = MinHeight + MinHeightOffset 
	else
		if target[2]+MinHeightOffset>MinHeight then MinHeight = target[2]+MinHeightOffset end
	end

	if MinHeight>CruisingAltitude then
		CruisingAltitude = MinHeight
	end
end

function Startup()
	IsFlying = true
	RotorSpeed = 0.005*RotorSpeedLimit
	SetValue("RotorSpeed",0.3*RotorSpeedLimit,"cosine",3)
	for i = 1,#HeadLights,1 do
		SetLightEnabled(HeadLights[i],true)
	end
	MaxRotorSpeed = RotorSpeedLimit*0.66
	if QuickStart == false then
		SetValue("MaxRotorSpeed",RotorSpeedLimit,"cosine",15) --engine slowly warms up to max power
	else
		MaxRotorSpeed = RotorSpeedLimit
	end

	if pilotdead or damagedenough or consolefucked then
		brokenliftoffattempt = true
	end
end

function ManageControlPanelInteractions(dt)
	if IsPanelOnCooldown then
		PanelCooldownTimer = PanelCooldownTimer + dt
		if PanelCooldownTimer > 1 then
			IsPanelOnCooldown = false
			PanelCooldownTimer = 0
		end
	end

	if GetPlayerInteractShape() == MainPanel and InputPressed("interact") and not IsFlying and not pilotdead and not damagedenough and not consolefucked then
		IsPanelOnCooldown = true
		Desired2DPos = Current2Dpos
		AdjustCruisingAltitude(true)
		Startup()
	end

	if GetPlayerInteractShape() == TargetSelectPanel and InputPressed("interact") and not IsPanelOnCooldown and not TargetSelectionMode then
		TargetSelectionMode = true
		IsPanelOnCooldown = true
		ShowControlCounter = ShowControlTime*60
	end
	if GetPlayerInteractShape() == TargetSelectPanel and InputPressed("interact") and not IsPanelOnCooldown and TargetSelectionMode then
		TargetSelectionMode = false
		IsPanelOnCooldown = true
	end

	if GetPlayerInteractShape() == DetailedControlPanel and InputPressed("interact") and not IsPanelOnCooldown then
		DetailedControl = true
		ShowControlCounter = ShowControlTime*60
		IsPanelOnCooldown = true
		TargetSelectionMode = false
		targetreached = true
		Landing = false
		MaxRotorSpeed = MaxRotorSpeed*1.2
		if IsFlying == false then
			Startup()
		end

		PlayerPosInVehicle = TransformToLocalTransform(GetBodyTransform(Heli),GetPlayerTransform())
		ThirdPersonView = true
		InitCamera()
		
	end

	
	if ThirdPersonView then
		if DetailedControl == false then
			if InputPressed("interact") then 
				ThirdPersonView = false
			end
			if InputPressed("up") then 
				ThirdPersonView = false
			end
			if InputPressed("down") then 
				ThirdPersonView = false
			end
			if DesiredZoom == 0 then ThirdPersonView = false end
		end

		if Near== false then  ThirdPersonView = false end --if thrown out of cockpit, then back to first person
	else
		if GetPlayerInteractShape() == ThirdPersonPanel and ThirdPersonView == false then
			if InputPressed("interact") then
			ThirdPersonView = true
			InitCamera()
			end
		end
	end


	if IsFlying then
		if InputPressed("X") and TargetSelectionMode then
			QueryRejectSelf()
			targetacquired = true
			targetreached = false
			local hit =false
			target,hit = GetAimPos(200)
			if hit == false then
				target[2] = HeightPoint[Front][2] - MinHeightOffset
			end
			
			Landing = false
			TravelHeightReached = false
			WaitForCruisingAltitude = true
			AdjustCruisingAltitude(false)
		end
		if TargetSelectionMode then
			if InputPressed("Z") then
				WaitForCruisingAltitude = false
			end

		end
		if InputPressed("C") and TargetSelectionMode then
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


	ControlInputs()

	if RopeNo ~= 0 then
		local p, hit, distance,shape = GetAimPos()

		local r = TransformToParentPoint(HeliTr,RopePosLoc[RopeNo])
		local l = VecLength(VecSub(p,r))

	
		

		ManageCamera(RopeCamPosLoc[RopeNo],VecAdd(RopePosLoc[RopeNo],Vec(0,-RopeLookDown,0)),0)
		local tolerance = 0.1
		local excess = 0
		local linecol = 0.75

		excess = (l-RopeLength)/RopeLength
		if excess<tolerance then
			--(1-(RopeLength*(1+excess)-l)/excess)
			DrawLine(r, p, linecol, linecol, linecol, 0.5)
			if RopeAttaching then
				RopesDetached = false
				RopeShapes[RopeNo] = shape
				if Ropes[RopeNo] ~=0 then
					Delete(Ropes[RopeNo])
					Ropes[RopeNo] = 0
				end 

				local slack =  RopeLength-VecLength(VecSub(p,r))
				str = [[
					<rope pos="$x1 $y1 $z1" rot="0.0 0.0 0.0" slack="$slack" strength="100" maxstretch="1" color="0.34 0.34 0.34">
						<location pos="0.0 0.0 0.0" rot="0.0 0.0 0.0"/>
						<location pos="$x2 $y2 $z2" rot="0.0 0.0 0.0"/>
					</rope>]]
					str = str:gsub("$x1", r[1])
					str = str:gsub("$y1", r[2])
					str = str:gsub("$z1", r[3])

					str = str:gsub("$x2", p[1]-r[1])
					str = str:gsub("$y2", p[2]-r[2])
					str = str:gsub("$z2", p[3]-r[3])

					str = str:gsub("$slack", slack)
					Ropes[RopeNo] = Spawn(str, Transform(),false, true)[1]
				

					RopeLookDown = r[2]-p[2]
			end
	
			
		else
			DrawLine(r, p,linecol, linecol, linecol, 0.2)
		end
	else
		if RopeAttaching then
			
			for i = 1,RopeCount,1 do
				if RopesDetached == false then
					--DetachJointFromShape(Ropes[i],GetJointOtherShape(Ropes[i],RopeShapes[i]))
					DetachJointFromShape(Ropes[i],RopeShapes[i])
					RopesDetached = true
				else
					Delete(Ropes[i])
					Ropes[i] = 0
				end
			end

		end
		if ThirdPersonView then
			ManageCamera()
			
		end
	end
	RopeAttaching = false	
	



	if InputPressed("m") then
		ShowOptions =not ShowOptions
	end

	--Rope controls
	if DetailedControl then
		if InputPressed("lmb") then RopeAttaching = true end
		if InputPressed("rmb") then RopeSwitching = true end
	else
		RopeAttaching = false
		RopeSwitching = false
		RopeNo = 0
	end

	if RopeSwitching then
		if RopeNo == 0 then
			RopeLookDown = RopeLookDownDefault
		end
		
		RopeNo = RopeNo+1
		if RopeNo>RopeCount then RopeNo = 1 end
		RopeSwitching = false
	end

	if RopeNo ~= 0 then
		if InputPressed("interact") then
			RopeNo = 0
		end
	end

end




function InitialiseControl()
	--maybe the acceleration slowly fills up? No, the accelration is constant, it's the rotor speed that fills up slowly, then goes toward 0 velocity, slower when very close
	--it was 10 at default, has a max, slowly changes
	--maybe store the default value somewhere? of the rotorspeed
	incr = 1
	decr = -1
	none = 0
	
	--up / down
	C_VertAcceleration = 12/100
	C_UpButton = "shift"
	C_DownButton = "ctrl"
	C_VerticalInput = none
	C_MinRotorSpeed = 10
	C_VertaccHelper = 0

	--Forward / Backward
	C_PitchAcceleration= 20/1000
	C_ForwardButton = "up"
	C_BackwardButton = "down"
	C_PitchInput = none
	C_LastPitchInput = none
	C_PitchOffset = 0
	C_MaxPitch = 1.3
	
	C_MaxForwardForce = 30/10000
	C_MaxForwardForceSecondWarmUp = 4
	C_MaxForwardForceStartingPc = 0.35
	C_ForwardForce = C_MaxForwardForceStartingPc*C_MaxForwardForce
	C_ForwardForceInc = C_MaxForwardForce*(1-C_MaxForwardForceStartingPc)/C_MaxForwardForceSecondWarmUp/60
	--Yaw

	C_YawRightButton = "right"
	C_YawLeftButton = "left"
	C_YawInput = none
	C_CurrentYaw = 0
	C_MaxYaw = 35
	C_YawAccHelper = 0

	--Sideways
	C_GoRightButton = "right"
	C_GoLeftButton = "left"
	C_SideModifierButton = "jump"
	C_SideInput = none
	C_CurrentSide = 0
	C_MaxSide = 12
	C_SideAccHelper = 0

	--start with a simple thing like only the rotor up /down. when held it increases the offset, then it goes back slowly
	--how is the going back working? trying to get to 0 velocity with some acceleration, perhaps the same as the normal.
	--acceleration downward was quicker than upward in game

	--RealAcceleration = (Disttoheight-v[2]*VerticalPredictionSeconds) * VertAcceleration
	--VertAcceleration = 0.01
end

function ControlInputs()
	if DetailedControl == false then return end
	local StopControl = false
	if InputPressed("interact") and not IsPanelOnCooldown and RopeNo ==0 then
		if GetPlayerInteractShape() == 0 or GetPlayerInteractShape() == DetailedControlPanel then
			StopControl = true
		end
	end
	if GetPlayerHealth() == 0 then StopControl = true end
	if StopControl then
		DetailedControl = false
		MaxRotorSpeed = MaxRotorSpeed/1.2
		Desired2DPos = Current2Dpos
		CruisingAltitude = CurrentHeight-StartingAltitude
		return
	end

	local CamTr = GetCameraTransform()
	local q = CamTr.rot
	local t = TransformToParentTransform(HeliTr,PlayerPosInVehicle)
	
	--cancel the headbob
	--[[
	local pitchvec = TransformToParentVec(CamTr,Vec(-1,0,0))
	if InputDown("up") or InputPressed("up") then
		q = QuatRotateQuat(QuatAxisAngle(pitchvec,-2.865),q)
	end]]
	t.rot = q
	SetPlayerTransform(t,true)


	C_VerticalInput = none
	if  InputDown(C_UpButton) then C_VerticalInput = incr end
	if  InputDown(C_DownButton) then C_VerticalInput = decr end

	C_PitchInput = none
	if  InputDown(C_ForwardButton) then C_PitchInput = incr end
	if  InputDown(C_BackwardButton) then C_PitchInput = decr end

	C_YawInput  = none
	if  InputDown(C_YawLeftButton) then C_YawInput = incr end
	if  InputDown(C_YawRightButton ) then C_YawInput = decr end

	C_SideInput = none
	if InputDown(C_SideModifierButton) then
		C_SideInput = C_YawInput
		C_YawInput = none
	end

end

function YawInputResponse()
	if IsFlying == false then return end
	if DetailedControl == false then return end

	local v = GetBodyAngularVelocity(Heli)
	--check height at front and back otherwise nose can get quite low

	local pvel = 0
	local a = 0
	local currentYawAcceleration = 0
	a = (v[2]-C_YawAccHelper)*60

	if C_YawInput  == none then
		C_CurrentYaw = 0
		pvel = v[2]+0.5*a --returning to normal in half a second (in practice it's like 3 seconds, but it's the relative weight of acceleration and speed)
		currentYawAcceleration = -pvel/math.abs(pvel) * C_MaxYaw 
		if currentYawAcceleration>0 then
			currentYawAcceleration = math.clamp(currentYawAcceleration,0.005*C_MaxYaw,C_MaxYaw)
		else
			currentYawAcceleration = math.clamp(currentYawAcceleration,-C_MaxYaw,-0.005*C_MaxYaw)
		end
	else
		C_CurrentYaw = C_CurrentYaw+0.5
		C_CurrentYaw = math.clamp(C_CurrentYaw,0,C_MaxYaw)
		currentYawAcceleration = C_CurrentYaw *C_YawInput 
	end
	C_YawAccHelper =v[2]

	local angularimp = Vec(-currentYawAcceleration*700,0,0)

	if RotorHealth[1]>0 then
	ApplyBodyImpulse(RotorBodies[1],RotorPosOnHeli[1],TransformToParentVec(HeliTr,angularimp)) end
	if RotorHealth[2]>0 then
	ApplyBodyImpulse(RotorBodies[2],RotorPosOnHeli[2],TransformToParentVec(HeliTr,VecScale(angularimp,-1))) end

	--DebugWatch("curr ", v[2])
	--DebugWatch("a  ", a)
	--DebugWatch("pvel ", pvel)
	--DebugWatch("result  ", currentYawAcceleration)
	
end

function SidewaysInputResponse()
	if IsFlying == false then return end
	if DetailedControl == false then return end

	local v = -TransformToLocalVec(HeliTr,GetBodyVelocity(Heli))[1]
	--check height at front and back otherwise nose can get quite low

	local pvel = 0
	local a = 0
	local currentAcceleration = 0
	a = (v-C_SideAccHelper)*60

	if C_SideInput  == none then
		C_CurrentSide = 0
		pvel = v+0.5*a --returning to normal in half a second (in practice it's like 3 seconds, but it's the relative weight of acceleration and speed)
		currentAcceleration = -pvel/math.abs(pvel) * C_MaxSide 
		if currentAcceleration>0 then
			currentAcceleration = math.clamp(currentAcceleration,0.005*C_MaxSide,C_MaxSide)
		else
			currentAcceleration = math.clamp(currentAcceleration,-C_MaxSide,-0.005*C_MaxSide)
		end
	else
		C_CurrentSide = C_CurrentSide+0.5
		C_CurrentSide = math.clamp(C_CurrentSide,0,C_MaxSide)
		currentAcceleration = C_CurrentSide *C_SideInput 
	end
	C_SideAccHelper =v

	local angularimp = Vec(-currentAcceleration*700,0,0)

	
	if RotorHealth[1]>0 then 
	ApplyBodyImpulse(RotorBodies[1],RotorPosOnHeli[1],TransformToParentVec(HeliTr,angularimp)) end
	if RotorHealth[1]>0 then 
	ApplyBodyImpulse(RotorBodies[2],RotorPosOnHeli[2],TransformToParentVec(HeliTr,angularimp)) end

	--[[
	DebugWatch("curr ", v)
	DebugWatch("a  ", a)
	DebugWatch("pvel ", pvel)
	DebugWatch("result  ", currentAcceleration)
	]]
end

--visual rotation and upward force are linked
function ManageRotor()

	--for i=1,#RotorJoints do
	SetJointMotor(RotorJoints[1], -RotorSpeed)
	SetJointMotor(RotorJoints[2], RotorSpeed)


	if IsFlying then
		local v = GetBodyVelocity(Heli)
		--check height at front and back otherwise nose can get quite low

		if DetailedControl == false then
			Disttoheight = StartingAltitude + CruisingAltitude - CurrentHeight
			
			RealAcceleration = (Disttoheight-v[2]*VerticalPredictionSeconds) * VertAcceleration
			if math.abs(Disttoheight)<1.5 then TravelHeightReached = true end
			--start and stop more slowly than how it can react mid flight
			local Warmupfactor =RotorSpeed/ MaxRotorSpeed
			local min = 0.07
			if Warmupfactor<min then Warmupfactor = min end
			if Warmupfactor>0.5 then Warmupfactor = 1 end
			if RotorSpeed < MaxRotorSpeed*0.5 then
				RealAcceleration = RealAcceleration*Warmupfactor
			end
		else
			if C_VerticalInput == none then
				local a = (v[2]-C_VertaccHelper)*60
				local pvel = v[2]+0.5*a --returning to normal in half a second (in practice it's like 3 seconds, but it's the relative weight of acceleration and speed)
				RealAcceleration = -pvel/math.abs(pvel) * C_VertAcceleration
				if math.abs(pvel)<0.008 then --avoids everything shaking from minor changes
					RealAcceleration = 0
				end
			else
				RealAcceleration = C_VertAcceleration*C_VerticalInput
				if RealAcceleration<0 and RotorSpeed<C_MinRotorSpeed and v[2]<-1 then
					RealAcceleration = 0
				end
			end
			C_VertaccHelper =v[2]
		end


	end

	if not pilotdead and not damagedenough and RemainingRotorVoxels > 4000 then
		RotorSpeed = RotorSpeed + RealAcceleration
	end

	if RotorSpeed > MaxRotorSpeed then
		RotorSpeed = MaxRotorSpeed
	end
	if RotorSpeed<0 then
		RotorSpeed = 0
		if RealAcceleration<0 then
			IsFlying = false
			CruisingAltitude = DefaultMaxHeight
			Landing = false
			TargetSelectionMode = false
			RotorSpeed = 0
			DetailedControl = false
			
		end
	end

	--DebugWatch("Dist2: ", Disttoheight)
	--DebugWatch("Rotor: ", RotorSpeed)

	--rotate helicopter when one is missing
	if not crashed and not brokenliftoffattempt then
		Rotspeed = GetBodyAngularVelocity(Heli)
		if not damagedenough and not pilotdead and not brokenliftoffattempt and IsFlying then
			for i=1,3 do
				if Rotspeed[i] < 0 or Rotspeed[i] > 0 then
					Rotspeed[i] = Rotspeed[i] / 1.05
				end
				SetBodyAngularVelocity(Heli, Rotspeed)
			end
		end
	end

	if Landing then
		if not targetacquired or targetreached then
			CruisingAltitude = CruisingAltitude-LandingSpeed/60
		end
	end
end

function CalculateForwardOffset()
	--HeightPoint[Front][2]
	--HeightPoint[Back][2]
	--positive offset when leaning forward

	
	CurrentLeaning = HeightPoint[Front][2]-HeightPoint[Back][2] - 1.24 --- 1.24 --0.55 is naturally stable originally,0.615 after adding all kinds of things with controls
	local v = VecSub( GetBodyVelocityAtPos(Heli,HeightPoint[Front]),GetBodyVelocityAtPos(Heli,HeightPoint[Back]))
	local LeaningAcceleration =0

	
	if DetailedControl  then
		if C_PitchInput ~= none then
			C_PitchOffset = C_PitchOffset + C_PitchAcceleration*C_PitchInput
			if math.abs(C_PitchOffset)>C_MaxPitch then
				C_PitchOffset = C_MaxPitch * C_PitchOffset/math.abs(C_PitchOffset)
				
			end
		else
			local forwardv = -TransformToLocalVec(HeliTr,GetBodyVelocity(Heli))[3]
			--should go down slowly in the future
			--add some braking force when not pressing any button
			C_PitchOffset = -forwardv*0.12

		end
	else
		C_PitchOffset = 0
	end

	local BoosterLeaningOffset = BoosterFraction*1.2
	LeaningAcceleration  = -(CurrentLeaning+C_PitchOffset+BoosterLeaningOffset+v[2]*ForwardOffsetPredictionAmount) * ForwardOffsetAcceleration
	

	local Warmupfactor =RotorSpeed/ MaxRotorSpeed
	local min = 0.07
	if Warmupfactor<min then Warmupfactor = min end
	if Warmupfactor>0.5 then Warmupfactor = 1 end
	if RotorSpeed < MaxRotorSpeed*0.5 then
		LeaningAcceleration = LeaningAcceleration*Warmupfactor
	end

	ForwardOffset = ForwardOffset + LeaningAcceleration

	if DetailedControl then
		if C_PitchInput == none then
			C_ForwardForce = C_ForwardForce-C_ForwardForceInc
		else
			if C_LastPitchInput ~= -C_PitchInput then
				C_ForwardForce = C_ForwardForce+C_ForwardForceInc
			else
				C_ForwardForce = C_MaxForwardForceStartingPc*C_MaxForwardForce
			end
		end
		C_ForwardForce = math.clamp(C_ForwardForce,C_MaxForwardForceStartingPc*C_MaxForwardForce,C_MaxForwardForce)
		C_LastPitchInput = C_PitchInput

		local imp = TransformToParentVec(HeliTr,Vec(0,0,CurrentLeaning*C_ForwardForce*RotorSpeed))



		for i = Front,Back,1 do
			local v = GetBodyVelocity(Heli)
			SetBodyVelocity(Heli,VecAdd(v,imp))
		end
	end

	--[[
	DebugWatch("leaning ", CurrentLeaning)
	DebugWatch("offset  ", ForwardOffset)
	DebugWatch("Prediction ", v[2]*ForwardOffsetPredictionAmount)
	DebugWatch("rotor  ", RotorSpeed)
	]]
end

function CheckRotorDamageAndApplyThrust()

	RemainingRotorVoxels = 0
	if not crashed and not brokenliftoffattempt then
		for i=1,#RotorBodies do
			if RotorHealth[i] >0 then
				rot = RotorBodies[i]
				RemainingRotorVoxels = RemainingRotorVoxels + GetBodyMass(rot)
				RotorHealth[i] = GetBodyMass(rot) / startrotormass[i]
				if RotorHealth[i]>0.5 then
					local RotorTr = GetBodyTransform(rot)
					disttoheli = VecLength(VecSub(RotorTr.pos, HeliTr.pos))
					if disttoheli > 10 then
						RemainingRotorVoxels = 0
						RotorHealth[i] = 0
					end


					--thrust
					
					CalculateForwardOffset()


					if RotorHealth[i]>0 then
						local offset = ForwardOffset
						if i ==2 then offset = -offset end
						local trVec = Vec(0,(RotorSpeed+offset*MaxRotorSpeed)*RotorHealth[i],0)
						local trVel = TransformToParentPoint(RotorTr, trVec)
						local velSub = VecSub(trVel, RotorTr.pos)
			
						SetBodyVelocity(rot, velSub)
					end
				end
			end
		end
	end
end


function CheckPilotDamage()
	ConsoleIntegrity = GetShapeVoxelCount(Console)

	ConsoleTrans = GetShapeWorldTransform(Console)
	PTrans = GetPlayerTransform()
	Disttoconsole = VecLength(VecSub(ConsoleTrans.pos, PTrans.pos))

	if Disttoconsole < interactrange then
		Near = true
	else
		Near = false
	end

	if ConsoleIntegrity < SConsoleIntegrity/1.1 then
		damagedenough = true
		consolefucked = true
		LostControl()
	end

	if Pilot1Dead == false then
		if HasTag(pilot, "dead") then Pilot1Dead = true end
		if HasTag(pilot, "Pilot") == false then Pilot1Dead = true end
		if IsHandleValid(pilot) == false then Pilot1Dead = true end


		ConstrainPosition(pilot, Heli, GetBodyTransform(pilot).pos, TransformToParentTransform(HeliTr,Pilot1LocalTr).pos, 3, 300)
	end
	if Pilot2Dead == false then
		if HasTag(pilot2, "dead") then Pilot2Dead = true end
		if HasTag(pilot2, "Pilot2") == false then Pilot2Dead = true end
		if IsHandleValid(pilot2) == false then Pilot2Dead = true end
		ConstrainPosition(pilot2, Heli, GetBodyTransform(pilot).pos, TransformToParentTransform(HeliTr,Pilot2LocalTr).pos, 3, 300)
	end


	if Pilot1Dead and Pilot2Dead then
		pilotdead = true
	else
		pilotdead = false
	end
	if Near and TargetSelectionMode or DetailedControl then
		pilotdead = false
	end

	currentmass = GetBodyMass(Heli)
	if currentmass < helistartmass/1.1 then
		damagedenough = true
	end
end

function CheckDamage()
	if IsFlying == false then return end
	if currentmass < helistartmass/1.01 then
		lightdamage = true
	end
	dmg = currentmass - allowedfordamage
	damage = dmg / 90000
end

function ManageDamage()

	if crashed then
		RotorSpeed = RotorSpeed / 1.005
		if RotorSpeed<MaxRotorSpeed*0.001 then RotorSpeed = 0 end
	end

	if IsFlying == false then return end
	if lightdamage  and Fuelamount > 0 then
		particleplaces = FindShapes("smoker")
		for i=1,#particleplaces do
			smoker = particleplaces[i]
			particlepos = GetShapeWorldTransform(smoker)
			smoke(particlepos)
		end
	end

	if Fuelamount == 0 then
		MaxRotorSpeed = MaxRotorSpeed*(1-0.0005)
		if RotorSpeed<0.001*RotorSpeedLimit then RotorSpeed = 0 end
	end
end

function FollowTarget()
	BoosterFraction = 0
	if TravelHeightReached == false and WaitForCruisingAltitude then return end
	
	disttotarget = VecLength(VecSub(HeliTr.pos, target))
	calmer = 1.002
	if disttotarget < TargetTolerance then
		targetreached = true
		HeliVel = GetBodyVelocity(Heli)
		V1 = HeliVel[1] / calmer
		V3 = HeliVel[3] / calmer
		if not brokenliftoffattempt then
			SetBodyVelocity(Heli, Vec(V1, HeliVel[2], V3))
		end
		BoosterFraction = 0
	end

	if targetacquired and not targetreached and not pilotdead and not damagedenough and RemainingRotorVoxels > 4000 and not brokenliftoffattempt then
		local approachspeed = 0.03
		local smoothspeed = 0.03

		local ttr = HeliTr
		local currentavel = GetBodyAngularVelocity(Heli)

		local targetrot = QuatLookAt(ttr.pos, target)

		local ltargetrot = TransformToLocalTransform(ttr, Transform(Vec(), targetrot))
		x,y,z = GetQuatEuler(ltargetrot)
		--z = z + 90
		--ltargetrot = QuatEuler(x,y,z)
		local targetavel = VecScale(Vec(GetQuatEuler(ltargetrot.rot)), approachspeed)
		local diff = VecSub(targetavel, currentavel)
		local stab = 0.01
		if xx < 0 then
			xx = xx * -1
		end
		stab = xx/480
		diff[1] = 0 --math.max(math.min(diff[1], smoothspeed), -smoothspeed)
		diff[2] = math.max(math.min(diff[2], smoothspeed), -smoothspeed)
		diff[3] = 0 --math.max(math.min(diff[3], smoothspeed), -smoothspeed)
		
		if RotorSpeed>MaxRotorSpeed*0.6 then
		SetBodyAngularVelocity(Heli, VecAdd(currentavel, diff))
		end
		
		boosters = FindBodies("Booster")
		for i=1,#boosters do
			Booster = boosters[i]
			if not IsBodyBroken(Booster) then
				local sbtz = GetBodyTransform(Booster)

				local d = math.abs(targetavel[2])
				if d>1.5 then
					BoosterFraction = 0
				else
					BoosterFraction = 1.5-d
				end
				
				if BoosterFraction>0 then
					
					--sidways force does that
					--local predpos = VecAdd(HeliTr.pos,VecScale(GetBodyVelocity(Heli),4))
					--PredDiff = VecSub(predpos, target)
					--SidewaysForce(5)
					

					Desired2DPos = target

					local trVecz = Vec(0,0, BoosterPower*BoosterFraction)
					local trVelz = TransformToParentPoint(sbtz, trVecz)
					local velSubz = VecSub(trVelz, sbtz.pos)
					--velSubz[2] = velSubz[2]/3
					local currentVelocity = GetBodyVelocity(Booster)
					VelAdd = VecAdd(currentVelocity, velSubz)
					SetBodyVelocity(Booster, VelAdd)
				end
			end
		end
	end
end


function AdjustToSideWhileBoosting()
	if BoosterFraction == 0 then return end
	if WeAreGoingDown then return end

	local diffvec = TransformToLocalPoint(HeliTr,target)
	local vvec = TransformToLocalVec(HeliTr,GetBodyVelocity(Heli))
	local diff = diffvec[1]
	local v = vvec[1]

	local AdjustingForce = 0

	local PredSeconds = 1
	local MaxImpulse = 5000
	local ImpulseFactor = 50

	local CorrectedDiff = diff+v*PredSeconds
	AdjustingForce = CorrectedDiff*ImpulseFactor
	if AdjustingForce > MaxImpulse then AdjustingForce = MaxImpulse end
	local imp = TransformToParentVec(HeliTr,Vec(AdjustingForce,0,0))

	for i = Front,Back,1 do
		if RotorHealth[i] > 0 then
			ApplyBodyImpulse(RotorBodies[i],RotorPosOnHeli[i],imp)
		end
	end

	--DebugBoosedSidewaysMovement(diff,v,CorrectedDiff,AdjustingForce)
end

function update(dt)
	WorldVariables()
	xx, yy, zz = GetQuatEuler(HeliTr.rot)

	RollStabiliser()


	MoveRamp(dt)

	ManageDamage()

	CheckPilotDamage()

	CheckDamage()


	if brokenliftoffattempt then
		BrokenLiftOffTimer = BrokenLiftOffTimer + dt
		if BrokenLiftOffTimer > 5 then
			BrokenLiftOffTimeUp = true
		end
	end

	if IsFlying then

		CheckRotorDamageAndApplyThrust()

		FollowTarget()

		if DetailedControl == false then
			SidewaysForce()
		end

		AdjustToSideWhileBoosting()

		lights = FindLights("reglight")
		for i=1,#lights do
			light = lights[i]
			if damagedenough or pilotdead or RemainingRotorVoxels < 4000 or brokenliftoffattempt then
				if Fuelamount > 0 then
					if not BrokenLiftOffTimeUp then
						SetLightColor(light, 1, 0, 0)
						SetLightIntensity(light, 5)
					else
						SetLightEnabled(light, false)
					end
				else
					SetLightEnabled(light, false)
				end
			else
				SetLightColor(light, 1, 1, 1)
			end
		end

		if IsShapeBroken(fuelline) then
			Nullify = 4
		end
		

		if not consolefucked then
			if pilotdead or damagedenough or RemainingRotorVoxels < 4000 or brokenliftoffattempt then
				if not BrokenLiftOffTimeUp then
					PlayLoop(Sound_Critical,TransformToParentTransform(HeliTr,CriticalLocalTr).pos,1)
				end
			end
		end
		
		Fuel = FindShapes("fuel")
		FuelIntegrity = 0
		for i=1,#Fuel do
			FuelIntegrity = FuelIntegrity + GetShapeVoxelCount(Fuel[i]) 
		end
		FuelLeak = FuelIntegrity/200 - SFuelIntegrity/200
		Fuelamount = Fuelamount + FuelLeak * Nullify
		if Fuelamount < 0 then
			Fuelamount = 0
		end

		if RemainingRotorVoxels > 3000 and not brokenliftoffattempt then
			SetTriggerTransform(InternalTrig,HeliTr)

			inside = IsPointInTriggerGlobal(InternalTrig, InternalTrigLocalTr, GetCameraTransform().pos, Heli)

			for i = 1, #RotorBodies,1 do
			if RotorHealth[i] > 0 then
				if inside then
					PlayLoop(Sound_Internal,GetBodyTransform(RotorBodies[i]).pos,RotorSpeed/MaxRotorSpeed*5)
				else
					PlayLoop(Sound_External,GetBodyTransform(RotorBodies[i]).pos,RotorSpeed/MaxRotorSpeed*5)
				end
			end
			end
		end


		--DebugPrint(VecStr((GetTriggerTransform(InternalTrig).pos)))
		--DebugPrint(VecStr((GetTriggerTransform(ExternalTrig).pos)))

		if brokenliftoffattempt or damagedenough and GetBodyTransform(Heli).pos[2] < StartingAltitude + 4 then
			RemainingRotorVoxels = 0
			crashed = true
			LostControl()
			realslow = 1.002
			if not plaid and not brokenliftoffattempt then
				plaid = true
				if inside then
					PlaySound(insnd, HeliTr.pos)
				else
					PlaySound(outsnd, HeliTr.pos)
				end
			end

		end


		--Spiralling out of control when there's too much damage, but still has some rotor to keep in air
		local b = false
		
		if Fuelamount > 0 then
			if RemainingRotorVoxels > 3000 and pilotdead or damagedenough and RemainingRotorVoxels > 3000 and not brokenliftoffattempt then
				b = true
			end
		end

		if b then
			if WeAreGoingDown == false then
				WeAreGoingDown = true
				GoingDownSpiralOffset = math.random(2,15)/100 --speed of spiralling
				if math.random(0,1) == 1 then GoingDownSpiralOffset = -GoingDownSpiralOffset end
				GoingDownSpiralForce = math.random(5,40)

				GoingDownSideForce1 = math.random(50,600)*10
				GoingDownSideForce2 = math.random(50,600)*10

				GoingDownSideBias1 = math.random(-3,3)/100
				GoingDownSideBias2 = math.random(-3,3)/100

				GoingDownVerticalAcc = VertAcceleration*0.5 -- math.random(10,20)/1000
				GoingDownVerticalBias = math.random(-3,1)/300 -- math.random(-100,-5)/1000

				ForwardOffsetOffset = math.random(-3,3)/100
				ForwarOffsetGoingDownFactor = math.random(-50,50)/1000
				GoingDownFactor = 0.1
				SetValue("GoingDownFactor",1.5,"cosine",10)

				if math.random(0,100)<RollStabiliserBreakChance*100 then
					RollStabiliserBroken = true
				end
			end
		else
			WeAreGoingDown = false
		end

		ManageRotor()
		YawInputResponse()
		SidewaysInputResponse()
		if WeAreGoingDown then
			Uncontrollable()
		end
	end -- IsFlying
end

function Uncontrollable()
	if crashed or Fuelamount == 0 then
		WeAreGoingDown = false
	end
	--pitch
	N5Timer,N5Last,N5Next,NoiseAmount = Noise(N5Timer,N5Last,N5Next,600)
	ForwardOffset = ForwardOffset + (NoiseAmount+ForwardOffsetOffset) * ForwarOffsetGoingDownFactor*GoingDownFactor

	--yaw
	N1Timer,N1Last,N1Next,NoiseAmount = Noise(N1Timer,N1Last,N1Next,120)
	NoiseAmount = (NoiseAmount+GoingDownSpiralOffset)*GoingDownSpiralForce*GoingDownFactor
	local angularimp = Vec(-NoiseAmount*700,0,0)
	if RotorHealth[1]>0 then
	ApplyBodyImpulse(RotorBodies[1],RotorPosOnHeli[1],TransformToParentVec(HeliTr,angularimp)) end
	if RotorHealth[2]>0 then
	ApplyBodyImpulse(RotorBodies[2],RotorPosOnHeli[2],TransformToParentVec(HeliTr,VecScale(angularimp,-1))) end
	
	--sideways
	N2Timer,N2Last,N2Next,NoiseAmount = Noise(N2Timer,N2Last,N2Next,120)
	N3Timer,N3Last,N3Next,NoiseAmount2 = Noise(N3Timer,N3Last,N3Next,120)
	NoiseAmount = (NoiseAmount+GoingDownSideBias1)*GoingDownFactor
	NoiseAmount2 = (NoiseAmount2+GoingDownSideBias2)*GoingDownFactor
	imp = Vec(NoiseAmount*GoingDownSideForce1, 0, NoiseAmount2*GoingDownSideForce2)
	ApplyBodyImpulse(Heli,VecLerp(RotorPosOnHeli[1],RotorPosOnHeli[2],0.5),imp)
	
	--up / down
	N4Timer,N4Last,N4Next,NoiseAmount = Noise(N4Timer,N4Last,N4Next,60)
	--CruisingAltitude = CruisingAltitude + (NoiseAmount+GoingDownVerticalBias)*GoingDownVerticalAcc*GoingDownFactor
	--DebugPrint(NoiseAmount .. " " .. GoingDownVerticalBias)

end


function smoke(particlepos)
    ParticleType("smoke")
    ParticleColor(damage, damage, damage)
    ParticleEmissive(0)
    ParticleRadius(0.2, 0.5)
    ParticleAlpha(1000,0)
    ParticleCollide(1)
    ParticleDrag(0.6)
    ParticleGravity(5,10)
    ParticleStretch(1)
    SpawnParticle(particlepos.pos, Vec(math.random(-1,1), math.random(-1,1), math.random(-1,1)),4)
    ParticleReset()
end

function GetAimPos(MaxDist)
    local ct = GetCameraTransform()
    local forwardPos = TransformToParentPoint(ct, Vec(0, 0, -150))
    local direction = VecSub(forwardPos, ct.pos)
    local distance = VecLength(direction)
    local direction = VecNormalize(direction)
    QueryRejectBody(sb)
	if  MaxDist==nil then
		MaxDist = 1000
	end 
    local hit, hitDistance,normal,shape = QueryRaycast(ct.pos, direction, MaxDist)
    if hit then
        distance = hitDistance
	else
        distance = MaxDist
    end
	forwardPos = TransformToParentPoint(ct, Vec(0, 0, -distance))
    return forwardPos, hit, distance,shape
end

function draw()
	--GraphValue(HeightPoint[Front][2]-10, 2)
	--GraphValue(GetBodyVelocity(Heli)[2], 1)

	--NgTimer,NgLast,NgNext,NoiseAmount = Noise(NgTimer,NgLast,NgNext,60)
	--GraphValue(NoiseAmount, 2)

	if SwitchOffPrompts then return end
	if ShowOptions then
		UiMakeInteractive()
		DrawOptions("center","",1, 1)
	end

	if crashed then return end

	if Near then
    	UiPush()
      	UiAlign("center middle")
      	UiTranslate(900, 200)
      	UiFont("bold.ttf", 30)
      	UiColor(1 - Fuelamount/FuelCapacity,0, 0)
      	UiText("Fuel:  "..math.floor(Fuelamount))
      	UiTranslate(0, 25)
      	UiFont("bold.ttf", 30)


		if TargetSelectionMode == false and DetailedControl == false then
			UiColor(1,0,0)
			UiText("helicopter isnt currently controlled, interact with dashboard")
		else
			if ShowControlCounter>0 then
				UiAlign("left bottom")
				local rowheight = 26
				ShowControlCounter = ShowControlCounter-1
				local col = ShowControlCounter/ControlFadeTime/60
				UiColorFilter(1, 1, 0,col)
				UiTranslate(-900+20, -200+UiHeight())
				if TargetSelectionMode then
					UiTranslate(0, -rowheight*5)
					UiColor(0,1,0)
					UiText("Press X to select helicopter destination")
					UiTranslate(0, rowheight)
					UiText("Press Z to go immediately before reaching cruising altitude")
					UiTranslate(0, rowheight)
					UiText("Tap Shift/Ctrl to adjust the cruising altitude")
					UiTranslate(0, rowheight)
					UiText("Press C to Auto land (after reached destination)")
					UiTranslate(0, rowheight)
					UiText("R: open close the ramp")
				  else
					UiTranslate(0, -rowheight*8)
					UiColor(0,1,0)
					UiText("W/S forward / backward")
					UiTranslate(0, rowheight)
					UiText("Shift / Ctrl up or down (increase rotor speed)")
					UiTranslate(0, rowheight)
					UiText("A/D: yaw left right")
					UiTranslate(0, rowheight)
					UiText("A/D while holding space: move left to right slowly")
					UiTranslate(0, rowheight)
					UiText("E: Disable control then third person camera, or rope selection")
					UiTranslate(0, rowheight)
					UiText("Right click: select rope to attach")
					UiTranslate(0, rowheight)
					UiText("Left click: attach rope, or release / delete existing")
					UiTranslate(0, rowheight)
					UiText("R: open close the ramp")
				  end
			end
			
		end


    	UiPop()
    end
end


function ManageCamera(SetPos,SetLook,SetZoom)
    ZoomLimit = 20
	ZoomLimitDown = 5
    zoomIncrease = -InputValue("mousewheel") * 1.5

	CamLerpSpeed = 0.06

    --DebugPrint(zoom)
    --DebugPrint(zoomIncrease)
    if zoomIncrease~= 0 then
		DesiredZoom = DesiredZoom + zoomIncrease

		--dead region to first person
		if zoomIncrease>0 then
			if DesiredZoom<ZoomLimitDown then DesiredZoom = ZoomLimitDown end
		else
			if DesiredZoom<ZoomLimitDown then DesiredZoom = 0 end
		end

		DesiredZoom = math.clamp(DesiredZoom, 0, 20)
    end

	Is1PZoom = DesiredZoom == 0
	local DesiredLocalPos = Vec()

    if DesiredZoom == 0 then
		DesiredLocalPos = PilotView_loc_1p
        
    else
		DesiredLocalPos = PilotView_loc_3p
        
    end

	if SetPos~=nil then
		DesiredLocalPos = SetPos
	end

	local RotCam = true
	if VecLength(VecSub(DesiredLocalPos,CamLocalPos)) > 0.2 then
		CamLocalPos = VecLerp(CamLocalPos,DesiredLocalPos,CamLerpSpeed)
		if SetLook then
			RotCam = false
			PlayerCamDir = QuatSlerp(PlayerCamDir,QuatLookAt(TransformToParentPoint(HeliTr,DesiredLocalPos),TransformToParentPoint(HeliTr,SetLook)),CamLerpSpeed)
		end
	else
		CamLocalPos = DesiredLocalPos
	end
	PilotView = TransformToParentPoint(HeliTr,CamLocalPos)




	if PilotView == nil then
		PilotView = GetCameraTransform.pos
	end

	ZoomIncVel = (DesiredZoom-zoom)*0.08
	if math.abs(ZoomIncVel) < 0.005 then
		zoom = DesiredZoom
		ZoomIncVel = 0
	end

	zoom = zoom + ZoomIncVel

	if SetZoom~=nil then
		zoom = SetZoom
	end

	--final control
	if RotCam then
		MouseSensitivity = 5
		PlayerCamDir = QuatRotateQuat(QuatEuler(0,-InputValue("mousedx")*MouseSensitivity/100,0),PlayerCamDir)
		local q = QuatAxisAngle(QuatRotateVec(PlayerCamDir,(Vec(-1,0,0))),InputValue("mousedy")*MouseSensitivity/100)
		PlayerCamDir = QuatRotateQuat(q,PlayerCamDir)
	end

    CameraPos = VecAdd(PilotView,QuatRotateVec(PlayerCamDir, Vec(0,0,zoom)))
    SetCameraTransform(Transform(CameraPos,PlayerCamDir))


	--DebugWatch("zoom",zoom)
	--DebugWatch("DesiredZoom",DesiredZoom)
	--DebugWatch("ZoomIncVel",ZoomIncVel)
	
    return PilotView
end


--Constrain value between min max
function math.clamp(val, lower, upper)
	if lower == nil then lower = val - 1 end
	if upper == nil then upper = val + 1 end

    if lower > upper then lower, upper = upper, lower end -- swap if boundaries supplied the wrong way
    return math.max(lower, math.min(upper, val))
end

function GetTriggerLocalTransform(tr_tag,ParentBody)
    local tr_handle = FindTrigger(tr_tag)
    local_tr = TransformToLocalTransform(GetBodyTransform(ParentBody),  GetTriggerTransform(tr_handle))
    return local_tr
end

function IsPointInTriggerGlobal(TriggerHandle, TriggerLocaltr, PointToCheck, ParentBody)
	SetTriggerTransform(TriggerHandle, TransformToParentTransform(GetBodyTransform(ParentBody),TriggerLocaltr))
	return IsPointInTrigger(TriggerHandle,PointToCheck)

end


function GetLocationLocalTransform(loc_tag,ParentBody)
    local loc_handle = FindLocation(loc_tag)
    local_tr = TransformToLocalPoint(GetBodyTransform(ParentBody),  GetLocationTransform(loc_handle).pos)
    return local_tr
    --getting back
    --Pos = TransformToParentPoint(GetBodyTransform(ParentBody),local_tr)
end

--similar to perlin noise
function Noise(Timer,Last,Next,Period)
	local factor = 3
	local Levels = 3
	local Result = 0
	Vals = {}


	if Last == nil then
		Last = {}
		Timer = {}
		Next = {}
		for s = 1,Levels,1 do
			Next[s] = math.random(-1000,1000)/1000
			Timer[s] = 0
			Last[s] = 0
		end
	end

	local maxval = 0
	for s = 1,Levels,1 do
		local f = factor^(s-1)
		local p = Period/f
		if Timer[s] <= 0 then
			Last[s] = Next[s]
			Next[s] = math.random(-1000,1000)/1000
			Timer[s] = p

			Vals[s] = Last[s]

		else
			Vals[s] = Last[s]*Timer[s]/p + Next[s]*(1-Timer[s]/p)

			Timer[s] = Timer[s]-1
		end

		Vals[s] = Vals[s]/f
		--DebugPrint(Vals[s] .. " " .. s .. " " .. f .. " " .. Last[s] .. " " .. Next[s] .. " " .. Timer[s]/p)
		Result = Result + Vals[s] 
		maxval = maxval+1/f
	end
	Result = Result/maxval --normalise to -1 to 1

	return Timer,Last,Next,Result
end
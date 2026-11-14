function initControl()
    ControlPanel = FindShape("panel_left")
    SetTag(ControlPanel,"interact", "Control")
    DetailedControl = false
    ThirdPersonView = false

    InitCamera()
    InitialiseControl()

    PanelCooldownTimer = 0

	ControlWarmUpSeconds = 3
	ControlStartPower = 0.3
	ControlPowerCollective = 0
	ControlPowerSide = 0
	ControlPowerForward = 0

	ToolName = ""
	ToolDisabled = false
end


function ManageControlPanelInteractions(dt)
	if IsPanelOnCooldown then
		PanelCooldownTimer = PanelCooldownTimer + dt
		if PanelCooldownTimer > 1 then
			IsPanelOnCooldown = false
			PanelCooldownTimer = 0
		end
	end

	if InputPressed("interact") then
		if TargetSelectionMode then
			TargetSelectionMode = false
			ThirdPersonView = false
		else
			if DetailedControl then
				DetailedControl = false
				ThirdPersonView = false
			else
				if ThirdPersonView then
					ThirdPersonView = false
				end 
				if ConsoleBroken == false then
					if GetPlayerInteractShape() == ControlPanel then
						IsPanelOnCooldown = true
						TakeControl()
						ShowControlCounter = ShowControlTime*60
					end
					
					for i = 1,#PilotShapes,1 do
						if GetPlayerInteractShape() ==PilotShapes[i] then
							StartRide()
							ShowControlCounter = ShowControlTime*60
						end
					end

				end
			end
		end
	end

	

end


function ControlInputs()
	if DetailedControl == false then return end

	local Stop = false
	if InputPressed("interact") and not IsPanelOnCooldown then
		Stop = true
	end
	if GetPlayerHealth() == 0 then Stop = true end


	local CamTr = GetCameraTransform()
	local q = CamTr.rot
	local t = Transform()
	if Stop then 
		t.pos = TransformToParentPoint(HeliTr,PlayerPosInVehicle)
		SetPlayerVelocity(Vec(0,0,0))
	else
		t.pos = TransformToParentPoint(HeliTr,VecAdd(PilotView_loc_1p,Vec(0,-1.8,0)))
		SetPlayerVelocity(HeliVel)
	end
	--cancel the headbob
	--[[
	local pitchvec = TransformToParentVec(CamTr,Vec(-1,0,0))
	if InputDown("up") or InputPressed("up") then
		q = QuatRotateQuat(QuatAxisAngle(pitchvec,-2.865),q)
	end]]
	t.rot = q
	SetPlayerTransform(t,true)

	if Stop then
		StopControl()
		return
	end

	C_VerticalInput = none
	if  InputDown(C_UpButton) then C_VerticalInput = incr end
	if  InputDown(C_DownButton) then C_VerticalInput = decr end

	C_PitchInput = none
	if  InputDown(C_ForwardButton) then C_PitchInput = incr end
	if  InputDown(C_BackwardButton) then C_PitchInput = decr end

	--[[
	C_YawInput  = none
	if  InputDown(C_YawLeftButton) then C_YawInput = incr end
	if  InputDown(C_YawRightButton ) then C_YawInput = decr end]]
	
	C_SideInput  = none
	if  InputDown(C_GoRightButton) then C_SideInput = incr end
	if  InputDown(C_GoLeftButton ) then C_SideInput = decr end

end

function AdjustControlParameters(Input,Power,MaxPower,Integral)
	local Offset = 0

	if Input ~=none then 
		Integral = 0 
		if Power<1 then
		Power = Power + (1-ControlStartPower)/(ControlWarmUpSeconds*60) end
		if Power<ControlStartPower then Power = ControlStartPower end
		Offset = Input*MaxPower*Power
	else
		if Power>0 then
		Power = Power - (1-ControlStartPower)/(ControlWarmUpSeconds*60) end
	end
	return Offset,Power,Integral
end

function DetailedControlOffsets()
	CollectiveOffset,ControlPowerCollective,CollectiveI = AdjustControlParameters(C_VerticalInput,ControlPowerCollective,10,CollectiveI)
	MoveForwardOffset,ControlPowerForward,MoveForwardI = AdjustControlParameters(C_PitchInput,ControlPowerForward,15,MoveForwardI)
	MoveSideOffset,ControlPowerSide,MoveRightI = AdjustControlParameters(C_SideInput,ControlPowerSide,-15,MoveRightI)


	local tr = TransformCopy(GetCameraTransform())
	local v = TransformToParentVec(tr,Vec(0,0,-1))
	v[2] = 0
	local q = QuatLookAt(Vec(0,0,0),v)
	tr.rot = q
	YawVector = TransformToParentVec(tr,Vec(0,0,1))
end


function ManageCamera(dt,SetPos,SetLook,SetZoom)
    ZoomLimit = 20
	ZoomLimitDown = 8
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
        if GunTimer>0 then
			DesiredLocalPos = VecAdd(DesiredLocalPos,Vec(2*GunTimer,0,0))
		end
		if RocketTimer>0 then
			DesiredLocalPos = VecAdd(DesiredLocalPos,Vec(-2*RocketTimer,0,0))
		end
    end

	if SetPos~=nil then
		DesiredLocalPos = SetPos
	end

	local RotCam = true
	if VecLength(VecSub(DesiredLocalPos,CamLocalPos)) > 0.2 then
		CamLocalPos = VecLerp(CamLocalPos,DesiredLocalPos,CamLerpSpeed)
		if SetLook then
			RotCam = false
			PlayerCamRot = QuatSlerp(PlayerCamRot,QuatLookAt(TransformToParentPoint(HeliTr,DesiredLocalPos),TransformToParentPoint(HeliTr,SetLook)),CamLerpSpeed)
		end
	else
		CamLocalPos = DesiredLocalPos
	end
	local tr = NextFrameTransform(Heli,dt)
	
	PilotView = TransformToParentPoint(tr,CamLocalPos)

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
	if ShowOptions then RotCam = false end
	if RotCam then
		MouseSensitivity = 5
		PlayerCamRot = QuatRotateQuat(QuatEuler(0,-InputValue("mousedx")*MouseSensitivity/100,0),PlayerCamRot)
		local q = QuatAxisAngle(QuatRotateVec(PlayerCamRot,(Vec(-1,0,0))),InputValue("mousedy")*MouseSensitivity/100)
		PlayerCamRot = QuatRotateQuat(q,PlayerCamRot)
	end

	if zoom > 0 then
    	CameraPos = VecAdd(PilotView,QuatRotateVec(PlayerCamRot, Vec(0,0,zoom)))
	else
		CameraPos = PilotView
	end
    SetCameraTransform(Transform(CameraPos,PlayerCamRot))


	--DebugWatch("zoom",zoom)
	--DebugWatch("DesiredZoom",DesiredZoom)
	--DebugWatch("ZoomIncVel",ZoomIncVel)
	
    return PilotView
end

function NextFrameTransform(body, dt)
	local trOld = GetBodyTransform(body)
	local v = VecScale(GetBodyVelocity(body),dt)
	local a = VecScale(GetBodyAngularVelocity(body),dt*180/math.pi)
	local trNew = TransformCopy(trOld)
	trNew.pos = VecAdd(trNew.pos,v)
	trNew.rot = QuatRotateQuat(QuatEuler(a[1],a[2],a[3]),trNew.rot) 
	return trNew
end

function InitCamera()
	cameraX = 0
	cameraY = 0
	zoom = 10
	DesiredZoom = 10
	ZoomIncVel = 0

	PlayerCamRot = TransformCopy(GetCameraTransform()).rot
	Is1PZoom = false
	CamLocalPos = TransformToLocalPoint(HeliTr,GetCameraTransform().pos)


	PilotView_loc_1p = TransformToLocalPoint(HeliTr,  GetLocationTransform(FindLocation("Pilot_View_1p")).pos)
	PilotView_loc_3p = TransformToLocalPoint(HeliTr,  GetLocationTransform(FindLocation("Pilot_View_3p")).pos)
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

	--Forward / Backward
	C_PitchAcceleration= 20/1000
	C_ForwardButton = "up"
	C_BackwardButton = "down"
	C_PitchInput = none
	C_LastPitchInput = none
	
	--Yaw

	C_YawRightButton = "right"
	C_YawLeftButton = "left"
	C_YawInput = none

	--Sideways
	C_GoRightButton = "right"
	C_GoLeftButton = "left"
	C_SideInput = none

	--start with a simple thing like only the rotor up /down. when held it increases the offset, then it goes back slowly
	--how is the going back working? trying to get to 0 velocity with some acceleration, perhaps the same as the normal.
	--acceleration downward was quicker than upward in game

	--RealAcceleration = (Disttoheight-v[2]*VerticalPredictionSeconds) * VertAcceleration
	--VertAcceleration = 0.01
end

function CheckIfNear()
	local interactrange = 3
	local Disttoconsole = VecLength(VecSub(GetShapeWorldTransform(ControlPanel).pos, GetPlayerTransform().pos))
	Near = Disttoconsole < interactrange
end

function ControlPrompts()
	if SwitchOffPrompts then return end
	if IsCrashed then return end

	UiPush()
	UiAlign("center top")
	UiTranslate(900, 20)
	UiFont("bold.ttf", 30)
	UiColor(1 - Fuelamount/FuelCapacity,0, 0)
	if Near then
		UiText("Fuel:  "..math.floor(Fuelamount))
	end
	UiTranslate(0, 25)
	UiFont("bold.ttf", 30)

	if TargetSelectionMode == false and DetailedControl == false then
		if Near then 
			UiColor(1,0,0)
			UiText("helicopter isnt currently controlled, interact with dashboard")
		end
	else
		if ShowControlCounter>0 then
			UiAlign("left bottom")
			local rowheight = 26
			ShowControlCounter = ShowControlCounter-1
			local col = ShowControlCounter/ControlFadeTime/60
			UiColorFilter(1, 1, 0,col)
			UiTranslate(-900+20, UiHeight()-300) -- 245 puts it above the Ui for Mors Longa
			if TargetSelectionMode then
				UiTranslate(0, -rowheight*(4+2))
				UiColor(0,1,0)
				UiText("Press X to select helicopter destination")
				UiTranslate(0, rowheight)
				UiText("Press Z to go immediately before reaching cruising altitude")
				UiTranslate(0, rowheight)
				UiText("Tap Shift/Ctrl to adjust the cruising altitude")
				UiTranslate(0, rowheight)
				UiText("Press C to Auto land (after reached destination)")
			else
				UiTranslate(0, -rowheight*(7+2))
				UiColor(0,1,0)
				UiText("W/S forward / backward")
				UiTranslate(0, rowheight)
				UiText("Shift / Ctrl hold to go up or down (increase collective)")
				UiTranslate(0, rowheight)
				UiText("A/D: move left right")
				UiTranslate(0, rowheight)
				UiText("Mouse: yaw left / right")
				UiTranslate(0, rowheight)
				UiText("E: Disable control / exit")
				UiTranslate(0, rowheight)
				UiText("Left click: shoot machine gun")
				UiTranslate(0, rowheight)
				UiText("Right click: shoot rocket")
			end
		end
		
	end


	UiPop()
end


function InitUi()
	ShowControlCounter = 0
	ShowControlTime = 15
	ControlFadeTime = 1.5
end
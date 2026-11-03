#include "../../Settings.lua"

function init()
	Init_Settings()
	mouseXtotal = 0
	mouseYtotal = 0
	turn = 0
	drive = 0
	brake = false
end
function tick(dt)

	if GetPlayerVehicle() ~= 0 and not Driving then
		RegisteredVehicle = GetPlayerVehicle()
		Driving = true
		cycled = false
		mouseYtotal = 0
		mouseXtotal = 0
	end

	if GetPlayerVehicle() == 0 and not Driving then
		RegisteredVehicle = 0
	end

	if RegisteredVehicle ~= 0 and not IsHandleValid(RegisteredVehicle) then
		RegisteredVehicle = 0
		Driving = false
	end

	if Driving then
		if not HasTag(RegisteredVehicle, "cfg") and GetPlayerVehicle() ~= 0 then
			--SetCameraTransform(Transform(GetPlayerTransform().pos))
		end

		if GetPlayerHealth() <= 0 or InputPressed("interact") and cycled and not KeybindDown(Settings.keybinds.vehicles.drive_by_shooting) then
			RemoveTag(GetVehicleBody(RegisteredVehicle), "bounded")
			RegisteredVehicle = 0
			Driving = false
		end
		cycled = true

		if KeybindDown(Settings.keybinds.vehicles.drive_by_shooting) and not HasTag(RegisteredVehicle, "cfg") and not HasTag(RegisteredVehicle, "planeVehicle") then
			local drive = InputValue("up") - InputValue("down")
			local turn = InputValue("left") - InputValue("right")
			local brake = InputDown("Space")
			if (tonumber(GetTagValue(RegisteredVehicle, "fuelLevel")) or 0) > 0 then
				DriveVehicle(RegisteredVehicle, drive, turn, brake)
			end
			SetTag(RegisteredVehicle, "drive", drive)
			SetTag(RegisteredVehicle, "turn", turn)
			SetTag(RegisteredVehicle, "brake", brake and 1 or 0)
			SetInt('FuelScript.vehicleToDraw',RegisteredVehicle)

			SetPlayerVehicle(0)
			mouseYtotal = 0
			mouseXtotal = 0
			local driverPos = GetVehicleDriverPos(RegisteredVehicle)
			local t = GetVehicleTransform(RegisteredVehicle)
			local CurrentPlayerTrans = GetPlayerTransform(true)
			local driverWorldPos = TransformToParentPoint(t, VecAdd(driverPos, Vec(-1.5,-1.2,0)))
			local upVec = QuatRotateVec(QuatRotateQuat(t.rot, QuatEuler(0,0,30)), Vec(0,1))
			if driverPos[1] > 0 then
				driverWorldPos = TransformToParentPoint(t, VecAdd(driverPos, Vec(1.5,-1.2,0)))
				upVec = QuatRotateVec(QuatRotateQuat(t.rot, QuatEuler(0,0,-30)), Vec(0,1))
			end


			local dirVec = QuatRotateVec(CurrentPlayerTrans.rot, Vec(0,0,-1))
			local driverWorldQuat = UMF_VecToQuatLookAt(dirVec, upVec)
			SetPlayerTransform(Transform(driverWorldPos,driverWorldQuat),true)
		else
			SetPlayerVehicle(RegisteredVehicle)
		end
		--SetBool("level.map_moved", true)

		if Settings.game.forced_1st_person_driving.value then
			if not HasTag(RegisteredVehicle, "cfg") and GetPlayerVehicle() ~= 0 then
				mouseupdate(dt)
			end
		end

	end
end

function mouseupdate(dt)
	cameraRotationSpeed = 5
	camtrans = GetCameraTransform()
	local x,y,z = GetQuatEuler(camtrans.rot)
	local mouseX = InputValue("mousedx")
	local mouseY = InputValue("mousedy")
	VehicleTrans = GetVehicleTransform(GetPlayerVehicle())
	local cameraY = y
	local cameraX = x
	local vehicleX, vehicleY, vehicleZ = GetQuatEuler(VehicleTrans.rot)
	mouseXtotal = mouseXtotal + mouseX
	mouseYtotal = mouseYtotal + mouseY
	SetCameraTransform(Transform(GetPlayerTransform().pos, QuatEuler(vehicleX - mouseYtotal/13,vehicleY - mouseXtotal/13,0)))
end
function TransformToParentQuat(pT,q)
	return TransformToParentTransform(pT,Transform(Vec(),q)).rot
end
function TransformToLocalQuat(pT,q)
	return TransformToLocalTransform(pT,Transform(Vec(),q)).rot
end

-- This UMF_VecToQuatLookAt function is copied from Teardown UMF by Thomasims
-- Link: https://github.com/Thomasims/TeardownUMF

function UMF_VecToQuatLookAt(vec, up)
	local forward = VecScale(vec, -1 / VecLength(vec))
	local right = VecNormalize(VecCross(up or Vec(0, 1, 0), forward))
	local up = VecCross(forward, right)

	local m00, m01, m02 = right[1], right[2], right[3]
	local m10, m11, m12 = up[1], up[2], up[3]
	local m20, m21, m22 = forward[1], forward[2], forward[3]

	if m22 < 0 then
	  if m00 > m11 then
		local t = 1 + m00 - m11 - m22
		local t2 = 0.5 / math.sqrt(t)
		return Quat(t2 * t, t2 * (m01 + m10), t2 * (m20 + m02), t2 * (m12 - m21))
	  else
		local t = 1 - m00 + m11 - m22
		local t2 = 0.5 / math.sqrt(t)
		return Quat(t2 * (m01 + m10), t2 * t, t2 * (m12 + m21), t2 * (m20 - m02))
	  end
	else
	  if m00 < -m11 then
		local t = 1 - m00 - m11 + m22
		local t2 = 0.5 / math.sqrt(t)
		return Quat(t2 * (m20 + m02), t2 * (m12 + m21), t2 * t, t2 * (m01 - m10))
	  else
		local t = 1 + m00 + m11 + m22
		local t2 = 0.5 / math.sqrt(t)
		return Quat(t2 * (m12 - m21), t2 * (m20 - m02), t2 * (m01 - m10), t2 * t)
	  end
	end
  end
  function handleCommand(cmd) HandleQuickload(cmd) end
  function HandleQuickload(cmd)
	  for _, word in ipairs(splitString(cmd, " ")) do
		  if word == "quickload" then
			  Init_Settings()
		  end
		  break
	  end
  end
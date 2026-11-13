#version 2
#include "script/include/player.lua"
-- (v2) SERVER: extra "drive" joints (Cadillac sedans) spin from the DRIVER's throttle (up/down); a wrecked vehicle
-- releases them. v1 read the host's input whenever the host was in the vehicle. Hand-converted 2026-11-09.

function server.init()
	driveJoints = FindJoints("drive")
	v = FindVehicle()
end

-- the player driving v (passengers ride in the same vehicle but must not drive it), or nil
function VehicleDriver(vehicle)
	if vehicle == 0 then return nil end
	for p in Players() do
		if IsPlayerVehicleDriver(vehicle, p) then return p end
	end
	return nil
end

function server.tick(dt)
	if GetVehicleHealth(v) == 0 then
		for i, driveJoint in pairs(driveJoints) do
			SetJointMotor(driveJoint, 0, 0)
		end
		return
	end
	local drive = 0
	local p = VehicleDriver(v)
	if p then
		drive = -10 - math.max(InputValue("up", p) * 40, InputValue("down", p) * 20)
	end
	for i, driveJoint in pairs(driveJoints) do
		SetJointMotor(driveJoint, drive, 100)
	end
end

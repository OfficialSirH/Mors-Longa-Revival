#version 2
#include "script/include/player.lua"
-- (v2) SERVER: "drive" joints (LeBoat propeller) turn from the DRIVER's throttle, speed factor = the joint's
-- "drive" tag value; a wrecked vehicle releases them. v1 read the host's input. Hand-converted 2026-11-09.

function server.init()
	driveJoints = FindJoints("drive")
	v = FindVehicle()
end

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
		drive = InputValue("up", p) - InputValue("down", p)
	end
	for i, driveJoint in pairs(driveJoints) do
		SetJointMotor(driveJoint, drive * (tonumber(GetTagValue(driveJoint, 'drive')) or 1), 100)
	end
end

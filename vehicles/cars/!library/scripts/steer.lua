#version 2
#include "script/include/player.lua"
-- (v2) SERVER: the "steer" shape's joint (Cadillac, minivan steering wheel) follows the DRIVER's left/right
-- input; the shape's "steer" tag value scales it. v1 read the host's input. Hand-converted 2026-11-09.

function server.init()
	local shape = FindShape('steer')
	steerJoint = GetShapeJoints(shape)[1]
	scale = tonumber(GetTagValue(shape, 'steer'))
	v = GetBodyVehicle(GetShapeBody(shape))
end

function VehicleDriver(vehicle)
	if vehicle == 0 then return nil end
	for p in Players() do
		if IsPlayerVehicleDriver(vehicle, p) then return p end
	end
	return nil
end

function server.tick(dt)
	local steer = 0
	local p = VehicleDriver(v)
	if p then
		steer = InputValue("right", p) - InputValue("left", p)
	end
	SetJointMotorTarget(steerJoint, 30 * scale * steer, math.pi / 6 / .4 * scale)
end

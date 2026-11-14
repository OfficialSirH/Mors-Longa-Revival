#version 2
#include "script/include/player.lua"
-- (v2) SERVER: while any player is in this script's vehicle (driver or passenger), its "door"-tagged joints are
-- motored shut; otherwise they swing freely (motor strength 0). v1 checked GetPlayerVehicle() (the host only in MP).
-- Hand-converted 2026-11-09 (no converter: 16 lines). Vehicles whose hinges carry no "door" tag (the insurgent chase
-- cars) are unaffected, as in v1.

function server.init()
	Vehicle = FindVehicle("Door")
	doors = FindJoints("door")
end

local function anyPlayerInside()
	if Vehicle == 0 then return false end -- (v2) v1 compared 0 too: no vehicle = "inside" whenever on foot
	for p in Players() do
		if GetPlayerVehicle(p) == Vehicle then return true end
	end
	return false
end

function server.tick(dt)
	local inside = anyPlayerInside()
	for i = 1, #doors do
		if inside then
			SetJointMotorTarget(doors[i], 0, 3)
		else
			SetJointMotorTarget(doors[i], 90, 0, 0)
		end
	end
end

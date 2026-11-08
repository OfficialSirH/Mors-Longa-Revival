#version 2
#include "script/include/player.lua"
-- (v2) SERVER: "actionToggle" shapes (semi trucks: Modified, Special, flathead Mod) get a "Toggle Action" prompt;
-- interacting deploys / retracts their "toggle_joint" joints. Any player can toggle (v1: the host only); while a
-- player is in the vehicle (driver or passenger, as v1's GetPlayerVehicle()) deployed joints retract.
-- Hand-converted 2026-11-09.

function server.init()
	shapes = FindShapes('actionToggle')
	vehicle = FindVehicle()
	for i, shape in pairs(shapes) do
		SetTag(shape, 'interact', "Toggle Action")
		local joints = GetShapeJoints(shape)
		for i, joint in pairs(joints) do
			if HasTag(joint, 'toggle_joint') then
				local min, max = GetJointLimits(joint)
				SetJointMotorTarget(joint, min, 3)
			end
		end
	end
end

local function toggle(shape)
	local joints = GetShapeJoints(shape)
	for i, joint in pairs(joints) do
		if HasTag(joint, 'toggle_joint') then
			local min, max = GetJointLimits(joint)
			if GetTagValue(joint, 'toggle_joint') == "deploied" then
				SetJointMotorTarget(joint, min, 3)
				SetTag(joint, 'toggle_joint', "")
			else
				SetJointMotorTarget(joint, max, 3)
				SetTag(joint, 'toggle_joint', "deploied")
			end
		end
	end
end

local function anyPlayerInside()
	if vehicle == 0 then return false end
	for p in Players() do
		if GetPlayerVehicle(p) == vehicle then return true end
	end
	return false
end

function server.tick(dt)
	for p in Players() do
		if InputPressed('interact', p) then
			local s = GetPlayerInteractShape(p)
			for i, shape in pairs(shapes) do
				if s == shape then toggle(shape) end
			end
		end
	end
	if anyPlayerInside() then
		for i, shape in pairs(shapes) do
			local joints = GetShapeJoints(shape)
			for i, joint in pairs(joints) do
				if HasTag(joint, 'toggle_joint') and GetTagValue(joint, 'toggle_joint') == "deploied" then
					local min, max = GetJointLimits(joint)
					SetJointMotorTarget(joint, min, 3)
					SetTag(joint, 'toggle_joint', "")
				end
			end
		end
	end
end

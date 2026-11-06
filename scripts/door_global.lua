#version 2
#include "script/include/player.lua"
-- (v2) server: per player, open/close the "door" joints of the vehicle they enter/leave
function server.init()
	lastPlayerVehicles = {}
end
function server.tick()
	for p in Players() do
		DoorUpdate(p)
	end
end
function DoorUpdate(p)
	local lastPlayerVehicle = lastPlayerVehicles[p] or 0
	local pV = GetPlayerVehicle(p)
	if pV ~= lastPlayerVehicle then
		if HasTag(lastPlayerVehicle,"Door") then
			local jBs = GetJointedBodies(GetVehicleBody(lastPlayerVehicle))
			for i,jB in ipairs(jBs)do
				local dJs=GetBodyJoints(jB)
				for i,dJ in ipairs(dJs) do
					if HasTag(dJ,"door")then SetJointMotor(dJ, 0, 0)end
				end
			end
		end
		if HasTag(pV,"Door") then
			local jBs = GetJointedBodies(GetVehicleBody(pV))
			for i,jB in ipairs(jBs)do
				local dJs=GetBodyJoints(jB)
				for i,dJ in ipairs(dJs) do
					if HasTag(dJ,"door")then SetJointMotor(dJ, 3)end
				end
			end
		end
		lastPlayerVehicles[p] = pV
	end
end

function GetBodyJoints(b)
	local js={}
	for _,s in ipairs(GetBodyShapes(b))do
		for __,sj in ipairs(GetShapeJoints(s))do
			js[#js+1]=sj
		end
	end
	return js
end
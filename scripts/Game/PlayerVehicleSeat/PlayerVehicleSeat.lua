--[[
#include ../../TDSU/tdsu.lua
]]

local player_body_tag = "PlayerVehicleBody"

function init()
	PlayerBody = 0
	UPDATE = 1
end
function spawnPlayerRagdoll()

	local file = nil
	if GetString("savegame.mod.difficulty") == "hardcore" then
		file = "MOD/scripts/Game/PlayerVehicleSeat/player_um.xml"
	else
		file = "MOD/scripts/Game/PlayerVehicleSeat/player.xml"
	end

	if HasFile(file)then
		Delete(PlayerBody)
		local entities = Spawn(file, Transform(Vec(0,-10,0)))
		for i, entity in ipairs(entities) do
			local entityType = GetEntityType(entity)
			if entityType == "body" then
				if HasTag(entity, player_body_tag) then
					PlayerBody = entity
					SetTag(PlayerBody, "unbreakable")
				end
			elseif entityType == "shape" then
				SetShapeCollisionFilter(entity, 0, 0) -- Disable collisions.
				SetTag(entity, "unbreakable")
			elseif entityType == "joint" then
				-- Delete(entity)
			end
		end
		--[[ if #entities >= 1 then
			print("New vehicle player model spawned... " .. GetTime())
		end ]]
	elseif IsTickInterval(UPDATE, 1) then
		print("Vehicle player model not found... " .. GetTime())
	end

end
function update()
	if not IsHandleValid(PlayerBody) then
		spawnPlayerRagdoll()
	end
	SetBodyTransform(PlayerBody, Vec(0,-10,0))
	SetBodyVelocity(PlayerBody, Vec(0,0,0))
	SetBodyAngularVelocity(PlayerBody,Vec(0,0,0))

	local v = GetPlayerVehicle()

	if v ~= 0 then

		local vBody = GetVehicleBody(v)
		local vTr = GetVehicleTransform(v)

		local driverPos = TransformToParentPoint(vTr, GetVehicleDriverPos(v))

		-- DebugCross(driverPos, 1,0,0, 1)
		-- DrawBodyOutline(PlayerBody, 1,1,1, 1)

		local camDist = VecLength(VecSub(GetCameraTransform().pos, driverPos))
		if camDist > 1 then
			SetBodyTransform(PlayerBody, Transform(driverPos,vTr.rot))
			
			SetBodyVelocity(PlayerBody, GetBodyVelocityAtPos(vBody,driverPos))
			SetBodyAngularVelocity(PlayerBody,GetBodyAngularVelocity(vBody))
		end
	else
		SetBodyTransform(PlayerBody, Transform(Vec(0,-1000, 0)))
	end

	UPDATE = UPDATE + 1
end

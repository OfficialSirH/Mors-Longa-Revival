#version 2
#include "script/include/player.lua"
-- (v2) server: spawns random vehicles at generated road locations.
--[[
#include "../scripts/TDSU/tdsu.lua"
]]


local disable_spawning = "savegame.mod.procedural.disable.spawn_vehicles"



function server.init()

	DebugSpawnAll = false --##
	DebugSpawnGoodCondition = false


	differentVehicles={
		["S"]=14,
		["M"]=25,
		["wg"]=46,
		["wb"]=34,
		["f"]=44,
	}
	-- special 3 is not complete u retard

	chanceform = 4
	chanceforwg = 10
	chanceforwb = 18
	chanceforspecial = 20
	chanceforf = 100

	if GetBool('level.RND.vehicle')then
		DebugWatch('RND vehicle',"DUPLICATED!")
	else
		SetBool('level.RND.vehicle',true)
	end

end
function server.tick()

	if GetBool(disable_spawning) then
		return
	end

	local Locations = FindLocations("RandomVehicle",true)

	local multiplier = GetInt("level.difficultycoef")*5
	for i=1,#Locations do
		local Location = Locations[i]

		local chance = tonumber(GetTagValue(Location, "Chance"))or 50
		chance=chance*2
		if DebugSpawnAll or (math.random(0,100) <= chance) then
			local Type = GetTagValue(Location, "Type")

			local locTrans = GetLocationTransform(Location)
			local posRnd = tonumber(GetTagValue(Location, "Loc"))or 0
			local rotRnd = tonumber(GetTagValue(Location, "Rot"))or 0
			local rotation = tonumber(GetTagValue(Location, "rotation"))or 0
			local rndPos = VecAdd(locTrans.pos,Vec(randomFloat(-posRnd,posRnd), 0, randomFloat(-posRnd,posRnd)))
			local rndRot = QuatRotateQuat(locTrans.rot,QuatEuler(0, rotation + randomFloat(-rotRnd,rotRnd), 0))
			local RandomizedTransform=Transform(rndPos, rndRot)

			if DebugSpawnGoodCondition then
				SpawnRandomVehicle(Type,locTrans)
			else
				SpawnRandomVehicle(Type,RandomizedTransform)
			end

		end
		--RemoveTag(Location, "RandomVehicle")
		Delete(Location)
	end
end

function SpawnRandomVehicle(Type,t)
	if Type == "" then
		local generatetype = math.random(1,100)
		if generatetype <= chanceform then
			Type = "M"
		elseif DebugSpawnGoodCondition or generatetype <= chanceforwg then
			Type = "wg"
		elseif generatetype <= chanceforwb then
			Type = "wb"
		elseif generatetype <= chanceforspecial then
			Type = "S"
		elseif generatetype <= chanceforf then
			Type = "f"
		end
	end
	local whichone = Type..math.random(1,differentVehicles[Type])
	local xml = "MOD/prefabs/spawnables/vehicles/Vehicle" .. whichone ..".xml"
	local spawnEntities = Spawn(xml, t)

	-- Store spawn xml at vehicle handle number in registry.
	for _, e in ipairs(spawnEntities) do
		if GetEntityType(e) == "vehicle" then
			local entityBakedXMLPath = GetTagValue(e, "path")
			if entityBakedXMLPath~=""then
				if HasFile(entityBakedXMLPath)then
					SetString("level.spawnedVehicles." .. e, entityBakedXMLPath)
				else
					print("Vehicle path tag skill issue detacted in: "..xml)
					SetString("level.spawnedVehicles." .. e, xml)
					SetTag(e, "path", xml)
				end
			else
				--print("Vehicle path tag missing in: "..xml)
				SetString("level.spawnedVehicles." .. e, xml)
				SetTag(e, "path", xml)
			end
			break
		end
	end

	SetSpawnedEntityTags(spawnEntities)
end

function randomFloat(min,max)
	min = tonumber(min) or 0
	max = tonumber(max) or 1
	return math.random()*(max-min)+min
end

function SetSpawnedEntityTags(prefab)
    if prefab ~= nil then
        for _, e in ipairs(prefab) do

            if GetEntityType(e) == "body" then -- global body

                for _, shape in ipairs(GetBodyShapes(e)) do  -- All shapes of every body.
                    SetTag(shape, "procgen_delete")
                end

                if e ~= GetWorldBody() then
                    SetTag(e, "procgen_delete")
                end

            else

                SetTag(e, "procgen_delete") -- Everything else gets the tag.

            end

        end
    end
end
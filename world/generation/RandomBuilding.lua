#version 2
DL_LABEL = "RandomBuilding"  -- crash breadcrumbs (lib/DeleteLog.lua)
#include "../../lib/DeleteLog.lua"
#include "script/include/player.lua"
#include "SpawnSlot.lua"
#include "../../ui/BuildingProbe.lua"
-- (v2) server: spawns random buildings at generated road locations.
--[[
#include "EnemySpawnsProcessor.lua"
#include "../../lib/Settings.lua"
#include "../../lib/TDSU/tdsu.lua"
]]


local disable_spawning = "savegame.mod.procedural.disable.spawn_buildings"


function server.init()

	Init_Settings()


	differentBuildings = {
		Civillian   = 11, -- 12 is wip
		CivSpecial  = 1,
		Special     = 3,
	}
	differentBuildings[""] = differentBuildings["Civillian"]


	differentRoadBlocks = {
		[""] = 5,
	}
	chanceforspecial = 3
	chanceforCivS = 5

	differentblocks = 9

	buildings_warehouses = {
		cultist   = "MOD/prefabs/spawnables/buildings/warehouse_cultist.xml",
		normal    = "MOD/prefabs/spawnables/buildings/warehouse_normal.xml",
		taken     = "MOD/prefabs/spawnables/buildings/warehouse_taken.xml", --civ
	}
	WarehouseSpawnIntervalDist = 3000 -- meters

	if GetBool('level.RND.building') then
		DebugWatch('RND building', "DUPLICATED!")
	else
		SetBool('level.RND.building', true)
	end

	DistanceProgressed = GetFloat("savegame.mod.distanceProgressed")
	LastSpawnedWarehouseDist = GetFloat("savegame.mod.LastSpawnedWarehouseDist")
	DayPhase = GetString("level.dayphase")

end

function server.tick()
	if GetBool("level.segment.loading") then return end -- (2026-11-14) a segment's parts are still spawning (GenerateRoad QueueDecor)

	DistanceProgressed = GetFloat("savegame.mod.distanceProgressed")
	LastSpawnedWarehouseDist = GetFloat("savegame.mod.LastSpawnedWarehouseDist")
	DayPhase = GetString("level.dayphase")


	if GetBool(disable_spawning) then
		return
	end

	-- if InputPressed("lmb") then --#
    --     beep()
    --     local entities = Spawn("MOD/prefabs/spawnables/buildings/constructionCivillian" .. math.random(1, 11) .. ".xml", Transform(GetCrosshairWorldPos()))
	-- 	ManageDetailDeleting(entities)
    -- end

	-- for index, value in ipairs(FindShapes("detail", true)) do --#
	-- 	DrawShapeOutline(value, 1,0,1, 1)
	-- end

	-- (2026-11-14) BigRoadBlock: global, the building markers may be handled in a later frame (SpawnSlot.lua)
	local multiplier = GetInt("level.difficultycoef")

	local roadBlockLocations = FindLocations("RandomRoadblock", true)
	if #roadBlockLocations > 0 then
		for i=1,#roadBlockLocations do
			if not SpawnSlotFree() then return end -- (2026-11-14) one spawn per frame (SpawnSlot.lua)
			local roadBlockLocation = roadBlockLocations[i]

			local chance = tonumber(GetTagValue(roadBlockLocation, "chance"))or 50
			if math.random(0,100) <= chance then
				local Type = GetTagValue(buildingLocation, "type")
				Type = Type~=""and Type or GetTagValue(buildingLocation, "Type")

				local locTrans = GetLocationTransform(roadBlockLocation)
				--local posRnd = 9
				local posRnd = 0
				local rotRnd = tonumber(GetTagValue(roadBlockLocation, "Rot")) or 0
				local rotation = tonumber(GetTagValue(roadBlockLocation, "rotation"))or 0
				local rndPos = VecAdd(locTrans.pos,Vec(randomFloat(-posRnd,posRnd), 0, randomFloat(-posRnd,posRnd)))
				local rndRot = QuatRotateQuat(locTrans.rot,QuatEuler(0, rotation + randomFloat(-rotRnd,rotRnd), 0))
				local RandomizedTransform=Transform(rndPos, rndRot)

				local entities, sapwnedXML = SpawnRandomBlock(Type, RandomizedTransform)
				SetSpawnedEntitiesBodyNotActive(entities)
				ManageDetailDeleting(entities)
				BuildingProbe_Record(entities, sapwnedXML) -- (2026-11-16) debug building sync readout (ui/BuildingProbe.lua)
				if sapwnedXML == "MOD/prefabs/spawnables/roadblocks/roadblock3.xml" then
					BigRoadBlock = true
				end
			end
			Delete(roadBlockLocation)
		end
	end

	local buildingLocations = FindLocations("RandomBuilding",true)
	for i=1,#buildingLocations do
		if not BigRoadBlock then
			if not SpawnSlotFree() then return end -- (2026-11-14) one spawn per frame (SpawnSlot.lua)
			local buildingLocation = buildingLocations[i]

			local chance = tonumber(GetTagValue(buildingLocation, "chance")) or 50
			if math.random(0,100) <= chance then
				local Type = GetTagValue(buildingLocation, "type")
				Type = Type~=""and Type or GetTagValue(buildingLocation, "Type")

				local locTrans = GetLocationTransform(buildingLocation)
				local posRnd = 9
				local rotRnd = 0
				local rotation = tonumber(GetTagValue(buildingLocation, "rotation")) or 0
				local rndPos = VecAdd(locTrans.pos,Vec(randomFloat(-posRnd,posRnd), 0, randomFloat(-posRnd,posRnd)))
				local rndRot = QuatRotateQuat(locTrans.rot,QuatEuler(0, rotation + randomFloat(-rotRnd,rotRnd), 0))
				local RandomizedTransform=Transform(rndPos, rndRot)

				local entities, sapwnedXML = SpawnRandomBuilding(Type, RandomizedTransform)
				SetSpawnedEntitiesBodyNotActive(entities)
			end
			Delete(buildingLocation)
		else
			Delete(buildingLocations[i])
		end
	end
	BigRoadBlock = false -- every building marker handled

end



function SpawnRandomBlock(Type, t)
	if Type == "" then
		local generates = math.random(1,100)
	end
	local whichone = math.random(1, differentRoadBlocks[Type])
	local roadBlockXML = "MOD/prefabs/spawnables/roadblocks/roadblock" .. Type .. whichone ..".xml"
	local entities = Spawn(roadBlockXML, t, true)
	SetString("level.debug.what.roadblock", roadBlockXML)
	SetFloat("level.debug.spawned.roadblock", GetTime()) TakeSpawnSlot() -- (2026-11-14) readout; SpawnSlot.lua

	ProcessEnemySpawns(entities)
	return entities, roadBlockXML
end


function SpawnRandomBuilding(Type, t)

	if Type == "" then
		local generates = math.random(1,100)
		if generates <= chanceforspecial then
			Type = "Special"
		elseif generates <= chanceforCivS then
			Type = "CivSpecial"
		else
			Type = "Civillian"
		end
	end
	local whichone = math.random(1,differentBuildings[Type])
	local buildingXML = "MOD/prefabs/spawnables/buildings/construction" .. Type .. whichone ..".xml"

	-- yup we're doing this the dumb way for now. --todo do it the smart way.
	if DistanceProgressed >= LastSpawnedWarehouseDist + WarehouseSpawnIntervalDist then

		t.rot = QuatRotateQuat(t.rot, QuatEuler(0,-90,0))
		SetFloat("savegame.mod.LastSpawnedWarehouseDist", DistanceProgressed)

		if DayPhase == "Night" then
			buildingXML = buildings_warehouses.cultist
		elseif math.random() < 0.5 then
			buildingXML = buildings_warehouses.normal
		else
			buildingXML = buildings_warehouses.taken --todo adapt this to faction territory when that is implemented.
		end

	end

	local entities = Spawn(buildingXML, t, true)
	SetString("level.debug.what.building", buildingXML)
	SetFloat("level.debug.spawned.building", GetTime()) TakeSpawnSlot() -- (2026-11-14) readout; SpawnSlot.lua

	-- (2026-11-17) option "Reduce Number of Objects": v1 read Settings.performance.spawn_less_objects (always nil),
	-- so the option never did anything for buildings (original-mod bug, same line in 9dde6dd); now its real path.
	local less = Settings.performance.physical and Settings.performance.physical.spawn_less_objects
	if less and less.value then
		for index, e in ipairs(entities) do
			if HasTag(e, "detail") then
				-- print("Deleted detail shape")
				Delete(e)
			end
		end
	end

	ProcessEnemySpawns(entities)
	BuildingProbe_Record(entities, buildingXML) -- (2026-11-16) debug building sync readout (ui/BuildingProbe.lua)


	return entities, buildingXML

end


function SetSpawnedEntitiesBodyNotActive(spawnEntities)
	for i,entity in pairs(spawnEntities)do
		if GetEntityType(entity) == "body" then
			if HasTag(entity,"awake")then
				SetBodyActive(entity, true)
			else
				SetBodyActive(entity, false)
			end
		end
	end
end



-- Check and delete shapes tagged "veg" after spawning a road segement.
function ManageDetailDeleting(entities)

	-- if Settings.performance.physical.spawn_less_objects.value then

		-- local deletes = 0

		for _, ent in ipairs(entities) do

			if HasTag(ent, "detail") then

				-- deletes = deletes + 1
				Delete(ent)

			end

		end

		-- local ents = #entities
		-- print(ents, deletes, ents - deletes)

	-- end

end

function randomFloat(min,max)
	min = tonumber(min) or 0
	max = tonumber(max) or 1
	return math.random()*(max-min)+min
end

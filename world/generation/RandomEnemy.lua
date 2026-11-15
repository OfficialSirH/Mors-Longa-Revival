#version 2
#include "script/include/player.lua"
#include "SpawnSlot.lua"
-- (v2) server: spawns NPCs at generated locations.
#include "../../lib/TDSU/tdsu.lua"

local disable_spawning = "savegame.mod.procedural.disable.spawn_enemies"

local bossPrefabs = {
	bosses = {
		civ 	= "MOD/prefabs/BossInsurgent.xml",
		mil 	= "MOD/prefabs/BossMilitary.xml",
		cult 	= "MOD/prefabs/BossCultist.xml",
	}
}

-- SafeStartDist = 200
SafeStartDist = -1

Poses = {}
torsos = {}

function server.init()

	EnemySpawnsPerBuildingPhases = {
		{ dist = 0, spawnCount = 2 },
		{ dist = math.random(500, 1500), spawnCount = 3 },
		{ dist = math.random(1500, 3500), spawnCount = 4 },
		{ dist = math.random(3500, 5000), spawnCount = 5 },
		{ dist = math.random(5000, 6500), spawnCount = 6 },
		{ dist = math.random(7500, 100000), spawnCount = 8 },
	}

	-- Insurgents
	differentcivRagdolls = 10

	-- AAF
	differentmilRagdolls = 5
	differentmilOfficerRagdolls = 3
	differentmilnightRagdolls = 1

	-- Cultists
	differentcultRagdolls = 4

	-- UM
	differentumRagdolls = 2
	differentpurRagdolls = 2
	differentumOfficerRagdolls = 2

	differentSecurityRagdolls = 6

	differentVIPRagdolls = 3
	differentcivspecRagdolls = 1

	Type = ""
	if GetBool('level.RND.enemy') then
		DebugWatch('RND enemy', "DUPLICATED!")
	else
		SetBool('level.RND.enemy', true)
	end

	maxenemies = 14

end

function server.tick()
	if GetBool("level.segment.loading") then return end -- (2026-11-14) a segment's parts are still spawning (GenerateRoad QueueDecor)

	if GetBool(disable_spawning) then
		return
	end

	if GetString("savegame.mod.difficulty") == "peaceful" then
		return
	end

	SandStorm = GetBool("level.IsSandstorm")

	ManageEnemySpawnsPerBuilding()

	DayPhase = GetString("level.dayphase")

	local Locations = FindLocations("RandomRagdoll", true)
	-- local multiplier = GetInt("level.difficultycoef")
	-- --multiplier = 100
	for i = 1, #Locations do
		if not SpawnSlotFree() then return end -- (2026-11-14) one spawn per frame (SpawnSlot.lua)

		local Location = Locations[1]

		Type = string.lower(GetTagValue(Location, "Type"))

		-- print("Type:", Type)

		local LocationTrans = GetLocationTransform(Location)
		local LocRnd = 1
		local RotRnd = 180
		RandomizedPosition = Vec(
			LocationTrans.pos[1] + math.random(-LocRnd, LocRnd) / 100,
			LocationTrans.pos[2],
			LocationTrans.pos[3] + math.random(-LocRnd, LocRnd) / 100)
		local rotX, rotY, rotZ = GetQuatEuler(LocationTrans.rot)
		RandomizedRotation = QuatEuler(rotX, rotY + math.random(-RotRnd, RotRnd), rotZ)


		Torsos = {}
		local torsos = FindBodies("Torso", true)
		for _, torso in ipairs(torsos) do
			if not HasTag(torso, "dead") then
			 table.insert(Torsos, torso)
			end
		end


		if #Torsos < maxenemies then

			local tags = {}

			local pos = { title = "", pos = LocationTrans.pos }
			if HasTag(Location, "cover") then
				pos.title = pos.title .. " cover"
				table.insert(tags, "cover")
			end
			if HasTag(Location, "ranged") then
				pos.title = pos.title .. " ranged"
				table.insert(tags, "ranged")
			end
			if HasTag(Location, "stationary") then
				pos.title = pos.title .. " stationary"
				table.insert(tags, "stationary")
			end
			if HasTag(Location, "outside") then
				pos.title = pos.title .. " outside"
				table.insert(tags, "outside")
			end
			if HasTag(Location, "nogrenades") then
				pos.title = pos.title .. " nogrenades"
				table.insert(tags, "nogrenades")
			end
			if HasTag(Location, "tutorial") then
				pos.title = pos.title .. " tutorial"
				table.insert(tags, "tutorial")
			end

			table.insert(Poses, pos)


			if GetFloat("savegame.mod.distanceProgressed") > SafeStartDist then
				SpawnRandomRagdoll(Location, tags)
			end

		end

		Delete(Location)


	end
end

function SpawnRandomRagdoll(location, tags)

	local tr = GetLocationTransform(location)

	local whichone


	if Type == "civ" or Type == "cult" then

		if DayPhase == "Night" then
			whichone = "cult/Ragdollcult" .. math.random(1, differentcultRagdolls) -- INSURGENTS
		else
			whichone = "civilian/Ragdollciv" .. math.random(1, differentcivRagdolls) -- CULTISTS
		end

	elseif Type == "mil" then -- AAF MILITARY

		if not SandStorm then
			if math.random() < 0.2 then
				whichone = "millitary/Ragdollmilofficer" .. math.random(1, differentmilOfficerRagdolls)
			else
				whichone = "millitary/Ragdollmil" .. math.random(1, differentmilRagdolls)
			end
		elseif SandStorm then
			whichone = "millitary/Ragdollmilsand" .. math.random(1, differentmilRagdolls)
		elseif Type == "mil" and DayPhase == "Night" then
			whichone = "millitary/Ragdollmilnight" .. math.random(1, differentmilnightRagdolls)
		end

	elseif Type == "um" then -- UNITED MATES

		if math.random() < 0.1 then
			whichone = "um/Ragdollumofficer" .. math.random(1, differentumOfficerRagdolls)
		elseif math.random() < 0.2 then
			whichone = "um/Ragdollum" .. math.random(1, differentpurRagdolls)
		else
			whichone = "um/Ragdollum" .. math.random(1, differentumRagdolls)
		end

	elseif Type == "security" then -- SECURITY

		whichone = "security/Ragdollsecurity" .. math.random(1, differentSecurityRagdolls)

	elseif Type == "vip" then -- VIP

		whichone = "vip/RagdollVIP" .. math.random(1, differentVIPRagdolls)

	else

		print("Enemy type not found: " .. Type or "type not found" .. ", skipping enemy with tags: "..table.concat(tags, ","))
		return

	end


	-- concatenate tags into string, then split it later back into a table.
	local torsoInt = GetInt("level.torsoInt")
	local tagDataString = table.concat(tags, ",")
	SetString("level.torsoData." .. torsoInt, tagDataString)
	SetString("level.torsoTeam." .. torsoInt, Type)



	local distanceProgressed = GetFloat("savegame.mod.distanceProgressed")

	Dist_spawning = Dist_spawning or 500 -- Spawn first boss at 1000.
	if distanceProgressed > Dist_spawning + 500 then -- Trigger boss spawn every 500m.

		Dist_spawning = distanceProgressed
		SpawnBoss = TableContainsValue(GetTableKeys(bossPrefabs.bosses), Type) -- Check if valid boss.

		if Type == "civ" and DayPhase ~= "Night" then
			SpawnBoss = false
		end

	else
		SpawnBoss = false
	end

	-- Spawn npc.
	local entities
	if SpawnBoss then
		entities = Spawn(bossPrefabs.bosses[Type], tr)
		SetString("level.debug.what.enemy", tostring(bossPrefabs.bosses[Type]))
		SetFloat("level.debug.spawned.enemy", GetTime()) TakeSpawnSlot() -- (2026-11-14) readout; SpawnSlot.lua
		SpawnBoss = false
		print("Spawned boss ", Type)
	elseif whichone then
		entities = Spawn("MOD/prefabs/spawnables/enemies/" .. whichone .. ".xml", tr)
		SetString("level.debug.what.enemy", tostring(whichone))
		SetFloat("level.debug.spawned.enemy", GetTime()) TakeSpawnSlot() -- (2026-11-14) readout; SpawnSlot.lua
	end


	-- NPC script will use torsoInt to for the next npc id.
	if entities then

		for _, entity in ipairs(entities) do
			if GetEntityType(entity) == "body" and HasTag(entity, "Torso") then
				SetTag(entity, "spawn_team", Type)
				break
			end
		end

		SetInt("level.torsoInt", torsoInt + 1)

	end

end

function ManageEnemySpawnsPerBuilding()

	local distanceProgressed = GetFloat("savegame.mod.distanceProgressed")
	local maxSpawnsPerBuidling = GetInt("level.spawning.maxSpawnsPerBuidling")

	-- Set spawn count if within range.
	for i = 1, #EnemySpawnsPerBuildingPhases - 1 do

		local phase = EnemySpawnsPerBuildingPhases[i]
		local nextPhase = EnemySpawnsPerBuildingPhases[i + 1]

		if distanceProgressed >= phase.dist and distanceProgressed < nextPhase.dist then

			SetInt("level.spawning.maxSpawnsPerBuidling", phase.spawnCount)
			return

		end

	end

	-- Default enemies if none in range(max enemies)
	SetInt("level.spawning.maxSpawnsPerBuidling", EnemySpawnsPerBuildingPhases[#EnemySpawnsPerBuildingPhases].spawnCount)

end

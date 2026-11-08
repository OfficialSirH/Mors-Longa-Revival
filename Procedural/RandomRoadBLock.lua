#include "EnemySpawnsProcessor.lua"

local disable_spawning = "savegame.mod.procedural.disable.spawn_roadblocks"


function init()
	differentblocks = 9
	if GetBool('level.RND.roadblock')then
		DebugWatch('RND roadblock',"DUPLICATED!")
	else
		SetBool('level.RND.roadblock',true)
	end
end

function tick()

	if GetBool(disable_spawning) then
		return
	end

	local Locations = FindLocations("RandomRoadblock", true)

	local multiplier = GetInt("level.difficultycoef")
	for i=1,#Locations do
		local Location = Locations[i]

		local chance = tonumber(GetTagValue(Location, "chance"))or 50
		if math.random(0,50) <= chance then

			local locTrans = GetLocationTransform(Location)
			--local LocRnd = 9
			local LocRnd = 0
			--local RotRnd = tonumber(GetTagValue(Location, "Rot")) or 0
			local rotation = tonumber(GetTagValue(Location, "rotation"))or 0
			RandomizedPosition = Vec(locTrans.pos[1] + math.random()*LocRnd, locTrans.pos[2] , locTrans.pos[3] + math.random()*LocRnd)
			local rotX,rotY,rotZ = GetQuatEuler(locTrans.rot)
			RandomizedRotation = QuatEuler(rotX, rotation, rotZ)
			if GetString("savegame.mod.difficulty") ~= "nightmare" then
			--SpawnRandomBlock()
			end
		end
		Delete(Location)
	end
end

function SpawnRandomBlock()
	--local generates = math.random(0,100)
	local whichone = math.random(1, differentblocks)
	local entities = Spawn("MOD/prefabs/spawnables/roadblocks/roadblock" .. whichone ..".xml", Transform(RandomizedPosition, RandomizedRotation), true)

	ProcessEnemySpawns(entities)
end

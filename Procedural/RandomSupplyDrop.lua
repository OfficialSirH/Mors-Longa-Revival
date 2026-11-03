
#include "EnemySpawnsProcessor.lua"

function init()
	differentdrops = 1
	if GetBool('level.RND.supplydrop')then
		DebugWatch('RND supplydrop',"DUPLICATED!")
	else
		SetBool('level.RND.supplydrop',true)
	end
end

function tick()
	local Locations = FindLocations("RandomSupplyDrop", true)

	local multiplier = GetInt("level.difficultycoef")
	for i=1,#Locations do
		local Location = Locations[i]

		local chance = tonumber(GetTagValue(Location, "chance"))or 50
		if math.random(0,200) <= chance then

			local locTrans = GetLocationTransform(Location)
			--local LocRnd = 9
			local LocRnd = 0
			--local RotRnd = tonumber(GetTagValue(Location, "Rot")) or 0
			local rotation = tonumber(GetTagValue(Location, "rotation"))or 0
			RandomizedPosition = Vec(locTrans.pos[1] + math.random()*LocRnd, locTrans.pos[2] , locTrans.pos[3] + math.random()*LocRnd)
			local rotX,rotY,rotZ = GetQuatEuler(locTrans.rot)
			RandomizedRotation = QuatEuler(rotX, rotation, rotZ)

			SpawnRandomDrop()
		end
		Delete(Location)
	end
end

function SpawnRandomDrop()
	--local generates = math.random(0,100)
	local whichone = math.random(1, differentdrops)
	local entities = Spawn("MOD/prefabs/spawnables/supplydrops/drop" .. whichone ..".xml", Transform(RandomizedPosition), true)

	ProcessEnemySpawns(entities)
end

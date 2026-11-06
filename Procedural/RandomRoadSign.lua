#version 2
#include "script/include/player.lua"
-- (v2) server: spawns random road signs.
function server.init()
	differentblocks = 6
	if GetBool('level.RND.roadsign')then
		DebugWatch('RND roadsign',"DUPLICATED!")
	else
		SetBool('level.RND.roadsign',true)
	end
end
function server.tick()
	local Locations = FindLocations("RandomRoadSign", true)

	--local multiplier = GetInt("level.difficultycoef")
	for i=1,#Locations do
		local Location = Locations[i]

		local chance = 42
		if math.random(0,100) <= chance then

			local locTrans = GetLocationTransform(Location)
			local LocRnd = 0
			--local RotRnd = tonumber(GetTagValue(Location, "Rot")) or 0
			local rotation = GetTagValue(Location, "Rot")or 0
			--DebugPrint(GetTagValue(Location, "Rot"))
			RandomizedPosition = Vec(locTrans.pos[1], locTrans.pos[2], locTrans.pos[3])
			local rotX,rotY,rotZ = GetQuatEuler(locTrans.rot)
			RandomizedRotation = QuatEuler(rotX, rotation, rotZ)
			SpawnRandomSign()
		end
		Delete(Location)
	end
end

function SpawnRandomSign()
	--local generates = math.random(0,100)
	local whichone = math.random(1,differentblocks)

	Spawn("MOD/prefabs/spawnables/roadsigns/roadsign" .. whichone ..".xml", Transform(RandomizedPosition, RandomizedRotation), true, true)
	--Spawn("MOD/prefabs/Vehicle1.xml", Transform(locTrans.pos))
end
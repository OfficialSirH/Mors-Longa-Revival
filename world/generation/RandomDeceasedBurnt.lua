#version 2
#include "script/include/player.lua"
#include "SpawnSlot.lua"
-- (v2) server: spawns random corpses.
function server.init()
	differentdeceased = 3
	if GetBool('level.RND.deceased')then
		DebugWatch('RND deceased',"DUPLICATED!")
	else
		SetBool('level.RND.deceased',true)
	end
end
function server.tick()
	if GetBool("level.segment.loading") then return end -- (2026-11-14) a segment's parts are still spawning (GenerateRoad QueueDecor)
	local Locations = FindLocations("RandomDeceasedBurnt",true)

	for i=1,#Locations do
		if not SpawnSlotFree() then return end -- (2026-11-14) one spawn per frame (SpawnSlot.lua)
		local Location = Locations[i]

		local chance = 55
		if math.random(0,100) <= chance then
			local locTrans = GetLocationTransform(Location)
			local LocRnd = 900
			local RotRnd = 180
			RandomizedPosition = Vec(locTrans.pos[1] + math.random(-LocRnd, LocRnd)/100, locTrans.pos[2] , locTrans.pos[3] + math.random(-LocRnd, LocRnd)/100)
			local rotX,rotY,rotZ = GetQuatEuler(locTrans.rot)
			RandomizedRotation = QuatEuler(rotX, rotY + math.random(-RotRnd, RotRnd), rotZ)

			SpawnRandomDeceased()
		end
		Delete(Location)
	end
end

function SpawnRandomDeceased()
	local whichone = math.random(1,differentdeceased)
	Spawn("MOD/prefabs/spawnables/deceased/DeceasedBurnt" .. whichone ..".xml", Transform(RandomizedPosition, RandomizedRotation))
	SetFloat("level.debug.spawned.burnt", GetTime()) TakeSpawnSlot() -- (2026-11-14) readout; SpawnSlot.lua
	--Spawn("MOD/prefabs/Vehicle1.xml", Transform(locTrans.pos))
end
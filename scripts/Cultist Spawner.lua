#version 2
#include "script/include/player.lua"
-- (v2) server. Uses the host's position for now (Phase 3: pick a player).
-- (v2 fix, user OK'd) original compared the function itself (GetPlayerVehicle without ()), so no ambush ever happened.
function server.init()
	AmbushTime = math.random(5*60,27*60)+math.random()
	AmbushFaction = nil
	AmbushFactions = {"cult","insurgent"}
	TimeWithoutAmbush = 0
	AmbushFactionSoldiers = {
		cult = {
			"MOD/prefabs/spawnables/enemies/cult/Ragdollcult1.xml",
			"MOD/prefabs/spawnables/enemies/cult/Ragdollcult2.xml",
			"MOD/prefabs/spawnables/enemies/cult/Ragdollcult3.xml",
			"MOD/prefabs/spawnables/enemies/cult/Ragdollcult4.xml",
		},
		insurgent = {
			"MOD/prefabs/spawnables/enemies/civilian/Ragdollciv1.xml",
			"MOD/prefabs/spawnables/enemies/civilian/Ragdollciv2.xml",
			"MOD/prefabs/spawnables/enemies/civilian/Ragdollciv3.xml",
			"MOD/prefabs/spawnables/enemies/civilian/Ragdollciv4.xml",
			"MOD/prefabs/spawnables/enemies/civilian/Ragdollciv5.xml",
			"MOD/prefabs/spawnables/enemies/civilian/Ragdollciv6.xml",
			"MOD/prefabs/spawnables/enemies/civilian/Ragdollciv7.xml",
			"MOD/prefabs/spawnables/enemies/civilian/Ragdollciv8.xml",
			"MOD/prefabs/spawnables/enemies/civilian/Ragdollciv9.xml",
		},
	
	
	}

end

function server.tick(dt)
	AmbushTime = AmbushTime - dt
	local number = math.random()
	if AmbushTime < 0 and GetPlayerVehicle() == 0 and (number <= 0.5 or TimeWithoutAmbush >= 3) then
		TimeWithoutAmbush = 0
		if GetString("level.dayphase") == "Night" then
			AmbushFaction = AmbushFactions[1]
		else
			AmbushFaction = AmbushFactions[2]
		end
		for i=1,math.random(3,7) do 
			local PlayerTransform = GetPlayerTransform()
			local pos = VecAdd(PlayerTransform.pos, Vec(RandNumber(20,90),100,RandNumber(20,90)))
			local hit, dist, normal, shape = QueryRaycast(pos, Vec(0,-1,0),130)
			if hit then
				local SpawnPos = VecAdd(pos, Vec(0,-dist,0))
				--DebugPrint(SpawnPos[2])
				if SpawnPos[2] < 5 and SpawnPos[2] > -1 then
					local amount = #AmbushFactionSoldiers[AmbushFaction]
					--DebugPrint(amount)
					Spawn(AmbushFactionSoldiers[AmbushFaction][math.random(1,amount)], Transform(SpawnPos))
				end
			end
		end
		AmbushTime = math.random(14*60,32*60)+math.random()
	elseif AmbushTime < 0 and GetPlayerVehicle() == 0 and number > 0.5 then
		AmbushTime = math.random(3*60,7*60)+math.random()
		TimeWithoutAmbush= TimeWithoutAmbush + 1
	end

end

function RandNumber(Min,Max)
	if math.random() < 0.5 then
		return math.random(-Max,-Min)
	else
		return math.random(Min,Max)
	end
end

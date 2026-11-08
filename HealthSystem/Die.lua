#version 2
#include "script/include/player.lua"
-- (v2) server: spawns the death ragdoll. Reads the v1 health system's registry flag, host only for now
-- (per-player health is Phase 2).
function server.init()
	restart = true
	dead = false
	FakeDead = false
	restart2 = true
	secretfeatureon = true
	--deadeded = LoadSound("MOD/deathsnd.ogg")
	ragdoll = GetString("savegame.mod.difficulty")
end
function server.tick()
	--DebugPrint("massive")
	playerhealth = GetPlayerHealth()
	--DebugPrint("Chosen: "..ragdoll)
	-- (v2) the flag is cleared by AdvancedHealthScript.lua itself now (client pulse for the inventory)
	if GetBool("health.status.dead") then
		dead = true
	else
		dead = false
		restart = true
	end
	-- (v2, Phase 2) the death ragdoll is now spawned by AdvancedHealthScript.lua (server.healthDied) for the player
	-- who died; this script only saw the host and would spawn a second ragdoll in single-player.
	if dead and restart then
		restart = false
	end
	if secretfeatureon then
		--[[ cycled = false
		if InputPressed("L") and not cycled and not FakeDead and restart2 then
			FakeDead = true
			cycled = true
		end

		if InputPressed("L") and not cycled and FakeDead and not restart2 then
			FakeDead = false
			cycled = true
			x,y,z = GetQuatEuler(GetPlayerTransform().rot)
			--SetPlayerTransform(Transform(Vec(0,1000,0), QuatEuler(x,y,z)), true)
			restart2 = true
		end ]]

		if FakeDead and restart2 then
			pltrans = GetPlayerTransform()
			x,y,z = GetQuatEuler(pltrans.rot)
			y = y + 180
			pltrans.rot = QuatEuler(x,y,z)
			pltrans.pos = Vec(pltrans.pos[1],pltrans.pos[2] + 1,pltrans.pos[3])
			Spawn("MOD/scientist2.xml", pltrans)
			restart2 = false
			--DebugPrint("spawning")
			restart2 = false
		end
	end
end

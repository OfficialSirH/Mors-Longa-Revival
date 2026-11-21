#version 2
DL_LABEL = "mine"  -- crash breadcrumbs (lib/DeleteLog.lua)
#include "../lib/DeleteLog.lua"
#include "script/include/player.lua"
-- (v2) server: mines go off when any player is within 1 m; explosion sounds on every client
function server.init()
	mines = FindBodies("mine", true)
end

function client.init()
	sound={}
	sound.mineExp = LoadSound("MOD/assets/snd/Explosions/explo_mine_0.ogg")
	sound.mineDirt = LoadSound("MOD/assets/snd/Explosions/Shared/Debris/expl_debris_dirt_0.ogg")
	sound.mineSand = LoadSound("MOD/assets/snd/Explosions/Shared/Debris/expl_debris_sand_0.ogg")
end

function server.tick(dt)
	if GetBool("level.roadgen") then
		mines = FindBodies("mine", true)
	end
	
	for i = #mines, 1, -1 do
		local mine = mines[i]
		local minePos = GetBodyTransform(mine).pos
		local dist = math.huge
		for p in Players() do
			dist = math.min(dist, VecLength(VecSub(GetPlayerTransform(p).pos, minePos)))
		end
		if dist < 1 then
			local size = tonumber(GetTagValue(mine, "size"))or .1
			Explosion(minePos, size)
				
			ClientCall(0, "client.mineSounds", minePos)
			RemoveTag(mine, "mine")
			table.remove(mines, i)
		end
	end
end

function client.mineSounds(minePos)
	PlaySound(sound.mineExp, minePos, 10)
	PlaySound(sound.mineDirt, minePos, 3)
	PlaySound(sound.mineSand, minePos, 3)
end




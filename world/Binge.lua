#version 2
DL_LABEL = "Binge"  -- crash breadcrumbs (lib/DeleteLog.lua)
#include "../lib/DeleteLog.lua"
#include "script/include/player.lua"
-- (v2) server: shrine; any player can pray (interact); its 2D sounds play on every client.
function server.init()
	Shrine = FindShape("Shrine")
	AUGH = LoadSound("MOD/assets/snd/Enemies/Boss/Binge.ogg")
	Gurenya = LoadSound("MOD/assets/snd/Enemies/Boss/NecoArc.ogg")
	timer = 0
	prayed = false
end
function server.tick(dt)
	if IsShapeBroken(Shrine) then
		if not played then
			ClientCall(0, "client.bingeSound", "MOD/assets/snd/Enemies/Boss/Binge.ogg") -- (v2) 2D sound for everyone
			played = true
			prayed = true
		end
		timer = timer + dt
		if timer > 10 then
			ShrineTrans = GetShapeWorldTransform(Shrine)
			if not spawned then
			Spawn("MOD/prefabs/other/BossBingus.xml",Transform(VecAdd(ShrineTrans.pos,Vec(0,2,0))))
			spawned = true
			end
		end
	end
	local prayer = nil -- (v2) any player
	for p in Players() do
		if InputPressed("interact", p) and GetPlayerInteractShape(p) == Shrine then prayer = p end
	end
	if prayer and not prayed then
		ClientCall(0, "client.bingeSound", "MOD/assets/snd/Enemies/Boss/NecoArc.ogg")
		prayed = true
		ShrineTrans = GetShapeWorldTransform(Shrine)
		Spawn("MOD/prefabs/spawns/loots/GiftFromGod.xml",Transform(VecAdd(ShrineTrans.pos,Vec(0,2,0))))
	end
end

function client.bingeSound(path)
	PlaySound(LoadSound(path))
end

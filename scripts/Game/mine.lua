function init()
	mines = FindBodies("mine", true)
	sound={}
	sound.mineExp = LoadSound("MOD/snd/Explosions/explo_mine_0.ogg")
	sound.mineDirt = LoadSound("MOD/snd/Explosions/Shared/Debris/expl_debris_dirt_0.ogg")
	sound.mineSand = LoadSound("MOD/snd/Explosions/Shared/Debris/expl_debris_sand_0.ogg")
end

function tick(dt)
	if GetBool("level.roadgen") then
		mines = FindBodies("mine", true)
	end
	
	local playerPos = GetPlayerTransform().pos
	for i = #mines, 1, -1 do
		local mine = mines[i]
		local minePos = GetBodyTransform(mine).pos
		local dist = VecLength(VecSub(playerPos, minePos))
		if dist < 1 then
			local size = tonumber(GetTagValue(mine, "size"))or .1
			Explosion(minePos, size)
				
			PlaySound(sound.mineExp, minePos, 10)
			PlaySound(sound.mineDirt, minePos, 3)
			PlaySound(sound.mineSand, minePos, 3)
			RemoveTag(mine, "mine")
			table.remove(mines, i)
		end
	end
end




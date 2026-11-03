function init()
	restart = true
	dead = false
	FakeDead = false
	restart2 = true
	secretfeatureon = true
	--deadeded = LoadSound("MOD/deathsnd.ogg")
	ragdoll = GetString("savegame.mod.difficulty")
end
function tick()
	--DebugPrint("massive")
	playerhealth = GetPlayerHealth()
	--DebugPrint("Chosen: "..ragdoll)
	if GetBool("health.status.dead") then
		dead = true
		SetBool("health.status.dead", false)
	else
		dead = false
		restart = true
	end
	if dead and restart then
		--PlaySound(deadeded)
		pltrans = GetPlayerTransform()
		x,y,z = GetQuatEuler(pltrans.rot)
		y = y
		pltrans.rot = QuatEuler(x,y,z)
		pltrans.pos = Vec(pltrans.pos[1],pltrans.pos[2] + 1,pltrans.pos[3])
		Spawn("MOD/HealthSystem/prefab/"..ragdoll..".xml", pltrans)
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

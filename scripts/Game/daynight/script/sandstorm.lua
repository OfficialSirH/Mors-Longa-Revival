-- (v2) server: storm state, fog/wind/snow (SetEnvironmentProperty is server-only). Client: initSandstormSounds/tickSandstormSounds.
function initSandstorm()

	f1, f2, f3, f4 = GetEnvironmentProperty("fogParams")
	windstr1, windstr2, windstr3 = GetEnvironmentProperty("wind")
	targetfog = { 0, 10, 1, 0 };
	nf1 = f1
	nf2 = f2
	nf3 = f3
	nf4 = f4
	sandstorm = false
	schance = 100000
	chance = schance
	eschance = 55000
	echance = eschance
	times = 0
end

function tickSandstorm()

	--[[ if InputPressed('m') then
		sandstorm = not sandstorm
		echance = eschance
		chance = schance
	end ]]

	--DebugPrint("workin")
	if not sandstorm then
		generatestorm = math.random(0, chance)
		chance = chance - 1
		if generatestorm == 1 then
			sandstorm = true and GetBool("savegame.mod.config.daynight.sandstorms")
			echance = eschance
		end
	else
		generatestorm = math.random(0, echance)
		echance = echance - 1
		if generatestorm == 1 then
			sandstorm = false
			chance = schance
		end
	end

	-- sandstorm = true --##
	-- for index, value in ipairs(GetEnvironmentProperty("fogParams")) do
	-- 	DebugWatch("fog" .. index, value)
	-- end

	SetBool("level.IsSandstorm", sandstorm, true) -- (v2) synced: clients play the storm sound
	local sandstormOverride = GetBool("savegame.mod.config.daynight.run_sandstorm")

	if sandstorm or sandstormOverride then

		if nf2 > targetfog[2] then
			add = (targetfog[2] - nf2) / 20
			nf2 = nf2 + add
		end
		if nf3 < targetfog[3] then
			add = (targetfog[3] - nf3) / 20
			nf3 = nf3 + add
		end
		SetEnvironmentProperty("fogParams", nf1, nf2, nf3, 0)
		SetEnvironmentProperty("snowamount", 1)
		fogColor = Vec(GetEnvironmentProperty("fogColor"))
		fogColor[1]=fogColor[1]*3
		fogColor[2]=fogColor[2]*2.5
		if VecLength(fogColor)>1 then
			fogColor = VecNormalize(fogColor)
		end
		SetEnvironmentProperty("fogColor", fogColor[1],fogColor[2],fogColor[3])

		if not setnewstorm then
			times = times + 1
			a = math.random(-100, 100)
			b = -1
			c = math.random(-100, 100)
			SetEnvironmentProperty("wind", a, b, c)
			SetEnvironmentProperty("snowdir", a, b, c)
			setnewstorm = true

		else

			if nf2 < f2 then
				add = (f2 - nf2) / 50
				nf2 = nf2 + add
			end
			if nf3 > f3 then
				add = (f3 - nf3) / 50
				nf3 = nf3 + add
			end

			SetEnvironmentProperty("fogParams", nf1, nf2, nf3, 0)
			SetEnvironmentProperty("snowamount", 0)
			SetEnvironmentProperty("wind", 0, 0, 0)
			SetEnvironmentProperty("snowdir", 0, 0, 0)
			setnewstorm = false

		end

	end
end

-- (v2) client: storm sound at the local player's camera
function initSandstormSounds()
	wind = LoadLoop("MOD/snd/World/Shared/Ambience/Exterior/Wind.ogg")
	sandhit = LoadLoop("MOD/snd/World/Shared/AmbientSpots/Hail.ogg")
end

function tickSandstormSounds()
	if GetBool("level.IsSandstorm") or GetBool("savegame.mod.config.daynight.run_sandstorm") then
		if GetPlayerVehicle() == 0 then
			PlayLoop(wind, GetPlayerCameraTransform().pos, 5)
		else
			PlayLoop(sandhit, GetPlayerCameraTransform().pos, 5)
			PlayLoop(wind, GetPlayerCameraTransform().pos, 0.4)
		end
	end
end

function TryEndSandStorm(totTick)
	if sandstorm then
		for _ = 1, totTick do
			generatestorm = math.random(0, echance)
			echance = echance - 1
			if generatestorm == 1 then
				sandstorm = false
				chance = schance
				return
			end
		end
	else
		return
	end
end
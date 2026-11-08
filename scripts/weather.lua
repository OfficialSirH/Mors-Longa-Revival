function init()
f1, f2, f3, f4 = GetEnvironmentProperty("fogParams")
windstr1, windstr2, windstr3 = GetEnvironmentProperty("wind")
targetfog = {0, 10, 0.99, 0};
nf1 = f1
nf2 = f2
nf3 = f3
nf4 = f4
sandstorm = false
wind = LoadLoop("MOD/snd/World/Shared/Ambience/Exterior/Wind.ogg")
sandhit = LoadLoop("MOD/snd/World/Shared/AmbientSpots/Hail.ogg")
schance = 100000
chance = schance
eschance = 55000
echance = eschance
times = 0
end
function tick()
	--DebugPrint("workin")
	if not sandstorm then
		generatestorm = math.random(0,chance)
		--DebugPrint(generatestorm)
		chance = chance - 1
		if generatestorm == 1 then
			sandstorm = true
		end
	end
	if sandstorm then

		generatestorm = math.random(0,echance)
		--DebugPrint(generatestorm)
		echance = echance - 1
		--DebugPrint(echance)
		if generatestorm == 1 then
			sandstorm = false
		end

		chance = schance
		if GetPlayerVehicle() == 0 then
		PlayLoop(wind, GetPlayerCameraTransform().pos, 5)
		end
		if GetPlayerVehicle() ~= 0 then
			PlayLoop(sandhit, GetPlayerCameraTransform().pos, 5)
			PlayLoop(wind, GetPlayerCameraTransform().pos, 0.4)
		end
		if nf2 > targetfog[2] then
			add = (targetfog[2] - nf2)/20
			nf2 = nf2 + add
		end
		if nf3 < targetfog[3] then
			add = (targetfog[3] - nf3)/20
			nf3 = nf3 + add
		end
		SetEnvironmentProperty("fogParams", nf1, nf2, nf3, 0)
		SetEnvironmentProperty("snowamount", 1)
		if not setnewstorm then
			times = times + 1
		a = math.random(-100,100)
		b = -1
		c = math.random(-100,100)
		SetEnvironmentProperty("wind", a, b, c )
		SetEnvironmentProperty("snowdir", a, b, c)
		setnewstorm = true
		end
	else
		echance = eschance
		if nf2 < f2 then
			add = (f2 - nf2)/50
			nf2 = nf2 + add
		end
		if nf3 > f3 then
			add = (f3 - nf3)/50
			nf3 = nf3 + add
		end
		SetEnvironmentProperty("fogParams", nf1, nf2, nf3, 0)
		SetEnvironmentProperty("snowamount", 0)
		SetEnvironmentProperty("wind", windstr1, windstr2, windstr3)
		--SetEnvironmentProperty("snowdir", a, b, c)
		setnewstorm = false
	end
	--[[ cycled = false
	if not cycled then
		if InputPressed("L") and sandstorm and not cycled then
			sandstorm = false
			cycled = true
		end
		if InputPressed("L") and not sandstorm and not cycled then
			sandstorm = true
			cycled = true
		end
	end ]]
	--DebugPrint("Times the storm has happened: "..times)
end
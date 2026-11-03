function init()
Wave = 0
Killed = 0
FilePath = ("MOD/prefabs/spawnables/Waves/")
Start = false
done = false
Light = FindLight("spawn")
SpawnPos = GetLightTransform(Light)
NextWaveTime = 5
NewWave = true
Waves = {
	{"UMWave", 3},
	{"DevWave", 1},
	{"MCWave", 3},
	}
AmountWaveTypes = #Waves	
SetInt("savegame.mod.player.money", 500)
SetBool("level.horde.enabled", true)
SetBool("savegame.mod.inventory.init", true)
alivetime = 0

end

function tick(dt)
	SetInt("savegame.mod.player.current.wave", Wave)
	SetInt("savegame.mod.player.current.wave.time", NextWaveTime)
	if not Start then
		NextWaveTime = NextWaveTime - dt
		if NextWaveTime < 0 then
			Start = true
		end
	end
	Money = GetInt("savegame.mod.player.money")
	Torsos = FindBodies("Torso", true)
	Loots = FindBodies("Loot", true)
	for i=1,#Loots do 
		RemoveTag(Loots[i], "Loot")
		RemoveTag(Loots[i], "interact")
	end
	if Start then 
		alivetime = alivetime + dt
		if alivetime > 20 and #Torsos <= 2 then
			for i=1,#Torsos do 
				DrawBodyOutline(Torsos[i], 0, 1, 0, 1)
				if alivetime > 20.5 then
					alivetime = math.random(15,19)
				end
			end
		end
		if NewWave then
			Wave = Wave + 1
			NewWave = false
			WhatWave = math.random(1,AmountWaveTypes)
			WaveParts = Waves[WhatWave][2]
			CurrentPart = WaveParts
			NextWaveTime = 10
			done = false
			SetBool("level.horde.ongoing.enabled", true)
		end
		DebugPrint(CurrentPart)
		DebugPrint(#Torsos)
		DebugPrint(NextWaveTime)
		if #Torsos <= 1 and CurrentPart > 0 then
			Spawn("MOD/prefabs/spawnables/Waves/" .. Waves[WhatWave][1] .. "_".. CurrentPart ..".xml", SpawnPos)
			CurrentPart = CurrentPart - 1
			alivetime = 0
		end
		
		if #Torsos == 0 and CurrentPart == 0 then
			if not done then
				SetInt("savegame.mod.player.money", Money + 100 * Wave)
				SetBool("inventory.refreshshop", true)
				SetBool("level.horde.ongoing.enabled", true)
				done = true
			end
			NextWaveTime = NextWaveTime - dt
			if NextWaveTime < 0 then
				NewWave = true
			end
		end
			
	
	end
			
			
	for i=1,#Torsos do 
		if HasTag(Torsos[i], "dead") then 
			Killed = Killed + 1
			RemoveTag(Torsos[i], "Torso")
		end
	end

end

function draw()





end

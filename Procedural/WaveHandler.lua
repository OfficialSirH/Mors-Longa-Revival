#version 2
#include "script/include/player.lua"
-- (v2) horde waves (server); wave UI, outlines and prize money on every client.
function server.init()
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
SetBool("level.horde.enabled", true)
-- (v2) start money and the inventory reset are per player: client.init below
HordeOngoing = false
alivetime = 0

end

function HordeTick(dt) -- (v2) called by server.tick
	HordeOutline = {} -- (v2) wave UI values go to the clients: HordePublish
	if not Start then
		NextWaveTime = NextWaveTime - dt
		if NextWaveTime < 0 then
			Start = true
		end
	end
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
				HordeOutline[#HordeOutline + 1] = Torsos[i] -- (v2) outlined by every client (client.tick)
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
			HordeOngoing = true
		end
		-- (v2) removed v1 leftover DebugPrint(CurrentPart / #Torsos / NextWaveTime): printed on screen every frame
		if #Torsos <= 1 and CurrentPart > 0 then
			Spawn("MOD/prefabs/spawnables/Waves/" .. Waves[WhatWave][1] .. "_".. CurrentPart ..".xml", SpawnPos)
			CurrentPart = CurrentPart - 1
			alivetime = 0
		end
		
		if #Torsos == 0 and CurrentPart == 0 then
			if not done then
				ClientCall(0, "client.hordeReward", 100 * Wave) -- (v2) every player's own money
				-- (v2 fix) v1 set "ongoing" to true here too, so the countdown to the next wave never showed
				HordeOngoing = false
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

-- (v2) server: run the wave logic, then publish what the clients show (only when it changed)
function server.tick(dt)
	HordeTick(dt)
	HordePublish()
end

function HordePublish()
	local outline = HordeOutline or {}
	local time = math.max(0, math.floor(NextWaveTime))
	local sig = Wave .. "/" .. time .. "/" .. tostring(HordeOngoing) .. "/" .. table.concat(outline, ",")
	if sig ~= HordeSig then
		HordeSig = sig
		shared.horde = { wave = Wave, time = time, ongoing = HordeOngoing and true or false, outline = outline }
	end
end

-- (v2) client: every player starts the horde with 500 money and a fresh inventory (v1: the host's savegame only)
function client.init()
	SetInt("savegame.mod.player.money", 500)
	SetBool("savegame.mod.inventory.init", true)
	SetBool("level.horde.enabled", true)
end

-- (v2) the health overlay (UiHealthOverlay_Draw.lua) reads the wave UI from these local keys, as in v1
function client.tick(dt)
	local h = shared.horde
	if not h then return end
	SetInt("savegame.mod.player.current.wave", h.wave or 0)
	SetInt("savegame.mod.player.current.wave.time", h.time or 0)
	SetBool("level.horde.ongoing.enabled", h.ongoing and true or false)
	for _, torso in ipairs(h.outline or {}) do
		if IsHandleValid(torso) then DrawBodyOutline(torso, 0, 1, 0, 1) end
	end
end

-- (v2) wave cleared: the prize goes to every player's own money; the shop refreshes
function client.hordeReward(amount)
	SetInt("savegame.mod.player.money", GetInt("savegame.mod.player.money") + amount)
	SetBool("inventory.refreshshop", true)
end

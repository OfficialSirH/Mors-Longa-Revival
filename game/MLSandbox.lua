#version 2
-- (Mors Longa Revival, 2026-11-14) The engine's data/script/sandbox.lua (Teardown 2.2.0), loaded by the game levels
-- instead of it, with ONE change: it doesn't enable every tool for every player in multiplayer (see server.tick).
-- Everything else (player spawn / respawn, name tags, damage indicators, death fade, weather menu, map markers,
-- unlimited ammo, level.sandbox / level.spawn keys) is the engine's code, unchanged.

#include "script/mp/lib/mp.lua"
#include "script/weather.lua"
#include "script/toolutilities.lua"
#include "script/include/player.lua"

dieFade = 0
respawnFadeInTime = 4

deadTime = {}

pUnlimited = GetBoolParam("unlimited", true)
pWeather = GetBoolParam("weather", true)
pSpawn = GetBoolParam("spawn", true)

function isGlobalGameModeEnabled()
	local gameModeId = GetString("game.gamemode")
	if gameModeId ~= "" then
		-- Global gamemodes references script
		return GetString("gamemodes."..gameModeId..".path")
	end
	return false
end

sandboxEnabled = false
function enableSandbox()
	SetBool("level.sandbox", true, true)
	SetBool("level.unlimitedammo", pUnlimited, true)
	SetBool("level.spawn", pSpawn, true)
	SetBool("level.creative", pSpawn, true)
	if IsMultiplayer() then
		setupToolsUpgradedFully()
	end

	sandboxEnabled = true
end

function disableSandbox()
	SetBool("level.sandbox", false, true)
	SetBool("level.unlimitedammo", false, true)
	SetBool("level.spawn", false, true)
	SetBool("level.creative", false, true)

	sandboxEnabled = false
end

function canRunSandbox()
	return not isGlobalGameModeEnabled() and not GetBool("level.campaign") and not GetBool("level.sandbox.disabled")
end

function server.init()
	hudInit(true)
	spawnInit()
	spawnSetRespawnTime(respawnFadeInTime)
	
	if canRunSandbox() then
		enableSandbox()
	end
end

function server.tick(dt)
	
	if sandboxEnabled and not canRunSandbox() then
		disableSandbox()
	elseif not sandboxEnabled and canRunSandbox() then
		enableSandbox()
	end

	if not sandboxEnabled then
		return
	end

	for p in PlayersRemoved() do
		deadTime[p] = nil
	end
	
	spawnTick(dt)
	
	--Unlimited ammo
	local tools = ListKeys("game.tool")
	for i=1,#tools do

		-- (Mors Longa) the engine's copy also does SetToolEnabled(tools[i], true, p) here in multiplayer, which
		-- turned every vanilla tool on for every player each tick; which tools a player has is the inventory's
		-- job (player/inventory.lua server.tick). Ammo as in the engine's copy (single-player and multiplayer).
		for p in Players() do
			SetToolAmmo(tools[i], 9999, p)
		end
	end
end

function client.init()
	initWeather()
end

function client.tick(dt)
	
	if not GetBool("level.sandbox") then return end

	hudTick(dt)
	
	if GetPlayerHealth() == 0 then
		if dieFade == 0 then
			SetValue("dieFade", 1, "linear", respawnFadeInTime)
		end
	else
		if dieFade == 1 then
			SetValue("dieFade", 0, "linear", 1)
		end
	end
	
	if IsPlayerHost() then
		tickWeather()
	end
end

function client.draw(dt)
	
	if not GetBool("level.sandbox") then return end
	
	hudDrawPlayerWorldMarkers(GetAllPlayers(), false)
	hudDrawDamageIndicators(dt)
	
	if dieFade > 0 then
		UiColor(0,0,0, dieFade)
		UiRect(UiWidth(), UiHeight())
	end
	
	if IsPlayerHost() then
		drawWeather(function (weather)
			ServerCall("server.setWeather", weather)
		end)
	end

	for p in Players() do
		if not IsPlayerLocal(p) and GetPlayerHealth(p) > 0 then
			local characterId = GetPlayerCharacter(p)
			local imagePath = GetString("characters."..characterId..".preview")
			AddMapMarker(p, "player", GetPlayerName(p), "loc@UI_TEXT_PLAYERS", true, "", GetPlayerTransform(p).pos, Vec(1,1,1), imagePath, "hud/party-member_map-marker.png")
		end
	end
end

function server.setWeather(env)	
	if not GetBool("level.sandbox") then return end
	setWeather(env)
end

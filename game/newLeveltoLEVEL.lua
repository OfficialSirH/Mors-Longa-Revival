#version 2
#include "script/include/player.lua"
#include "perkTable.lua"
-- (v2) server: registry hand-over from the previous level
-- (v2, MP 2026-11-14) level.* keys are written with the sync flag: without it only the host's registry had the
-- game rules (level.gamerule.*), so on a remote player's machine god / armored / no hunger / keep inventory /
-- permadeath read as off. The run's id and difficulty are published too (see client.tick).
function server.init()
	recursiveKeyTransfer("savegame.mod.newLevel", "level", true)
	recursiveKeyTransfer("savegame.mod.newLevel", "savegame.mod.lastLevel", false)
	ClearKey("savegame.mod.newLevel")
	-- A run started before run ids existed gets one now (the host's own reset was done by the main menu).
	if GetString("savegame.mod.runid") == "" then
		SetString("savegame.mod.runid", NewRunId())
	end
	SetString("level.runid", GetString("savegame.mod.runid"), true)
	SetString("level.difficulty", GetString("savegame.mod.difficulty"), true)
	SetBool("level.runresetmoney", GetBool("savegame.mod.runresetmoney"), true)
	HostPublished = {}
	HostPublishTimer = 0
	PublishHostState()
end
function recursiveKeyTransfer(originParent, targetParent, sync)
	local list = ListKeys(originParent)
	for i,key in pairs(list) do
		SetString(targetParent.."."..key,GetString(originParent.."."..key), sync)
		recursiveKeyTransfer(originParent.."."..key, targetParent.."."..key, sync)
	end
end

-- (v2, MP 2026-11-14, user's decisions) Perks are the host's for everyone, and the debug menu is the host's only
-- (lib/Config.lua), so its settings that each machine reads for itself are the host's for everyone too.
-- The server publishes the host's values (synced level.host.*, on change, twice a second); every other machine
-- copies them into its own savegame, where all the existing code reads them (health perks, perk list, guns' infinite
-- ammo, hunger / thirst, god mode, place tool materials). Perks the host doesn't have are cleared (-1).
HOST_SETTINGS = {
	{ key = "savegame.mod.unlimitedammo", name = "unlimitedammo" },
	{ key = "savegame.mod.infiniteMaterials", name = "infiniteMaterials" },
	{ key = "savegame.mod.config.game.inf_hunger", name = "inf_hunger" },
	{ key = "savegame.mod.config.game.inf_thirst", name = "inf_thirst" },
	{ key = "savegame.mod.config.game.god", name = "god" },
}

function PublishHostState()
	for i = 1, #PERKORDER do
		local perk = PERKORDER[i]
		local key = "savegame.mod.perks." .. perk
		local v = HasKey(key) and GetInt(key) or -1
		if HostPublished["perk." .. perk] ~= v then
			HostPublished["perk." .. perk] = v
			SetInt("level.host.perks." .. perk, v, true)
		end
	end
	for _, s in ipairs(HOST_SETTINGS) do
		local v = GetBool(s.key)
		if HostPublished[s.name] ~= v then
			HostPublished[s.name] = v
			SetBool("level.host.cfg." .. s.name, v, true)
		end
	end
end

function server.tick(dt)
	HostPublishTimer = HostPublishTimer - dt
	if HostPublishTimer <= 0 then
		HostPublishTimer = 0.5
		PublishHostState()
	end
end

function MirrorHostState()
	for i = 1, #PERKORDER do
		local perk = PERKORDER[i]
		local src = "level.host.perks." .. perk
		if HasKey(src) then
			local v = GetInt(src)
			local key = "savegame.mod.perks." .. perk
			if v < 0 then
				if HasKey(key) then ClearKey(key) end
			elseif not HasKey(key) or GetInt(key) ~= v then
				SetInt(key, v)
			end
		end
	end
	for _, s in ipairs(HOST_SETTINGS) do
		local src = "level.host.cfg." .. s.name
		if HasKey(src) and GetBool(s.key) ~= GetBool(src) then
			SetBool(s.key, GetBool(src))
		end
	end
end

-- (v2, MP 2026-11-14) A new run for a remote player. The main menu resets the run in the host's savegame only
-- (inventory.init -> starter loadout, full hunger/thirst; bounty board). Each other player keeps their own
-- savegame (inventory, money), so when they first see a run id they haven't played, they get the same per-player
-- reset here. Money: reset when the host's was (Hardcore "Try Again"), kept on "New Save" as the host's is. The
-- host's difficulty is mirrored into their savegame every level (health, NPC and hunger rules read it on each
-- machine); perks and the debug-menu settings above every tick.
function client.tick()
	if IsPlayerHost(GetLocalPlayer()) then return end
	MirrorHostState()
	if RunChecked then return end
	local run = GetString("level.runid")
	if run == "" then return end   -- not synced yet
	RunChecked = true
	local difficulty = GetString("level.difficulty")
	if difficulty ~= "" then SetString("savegame.mod.difficulty", difficulty) end
	if GetString("savegame.mod.myrun") ~= run then
		SetString("savegame.mod.myrun", run)
		StartOwnRun()
	end
end

-- The per-player part of the main menu's new-game reset (menu_select_difficulty.lua playCharacter). Perks are the
-- host's (MirrorHostState).
function StartOwnRun()
	SetBool("savegame.mod.inventory.init", true)
	if GetBool("level.runresetmoney") then SetInt("savegame.mod.player.money", 0) end
	for i = 1, 4 do
		SetBool("savegame.mod.bountyboard."..i, false)
	end
	SetBool("savegame.mod.bountyboard.cultist", false)
	SetBool("savegame.mod.bountyboard.military", false)
	SetBool("savegame.mod.bountyboard.insurgent", false)
end

-- Same form as the main menu's new-run id (menu_main.lua "Try Again", menu_select_difficulty.lua playCharacter).
function NewRunId()
	return string.format("%d-%d", math.floor(GetTime() * 1000) % 1000000000, math.random(100000, 999999))
end

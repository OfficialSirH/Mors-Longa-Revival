#version 2
#include "script/include/player.lua"
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
end
function recursiveKeyTransfer(originParent, targetParent, sync)
	local list = ListKeys(originParent)
	for i,key in pairs(list) do
		SetString(targetParent.."."..key,GetString(originParent.."."..key), sync)
		recursiveKeyTransfer(originParent.."."..key, targetParent.."."..key, sync)
	end
end

-- (v2, MP 2026-11-14) A new run for a remote player. The main menu resets the run in the host's savegame only
-- (inventory.init -> starter loadout, full hunger/thirst; perks; bounty board). Each other player keeps their own
-- savegame (inventory, money, perks), so when they first see a run id they haven't played, they get the same
-- per-player reset here. Money: reset when the host's was (Hardcore "Try Again"), kept on "New Save" as the
-- host's is. The host's difficulty is mirrored
-- into their savegame every level (health, NPC and hunger rules read it on each machine).
function client.tick()
	if RunChecked then return end
	local run = GetString("level.runid")
	if run == "" then return end   -- not synced yet
	RunChecked = true
	if IsPlayerHost(GetLocalPlayer()) then return end
	local difficulty = GetString("level.difficulty")
	if difficulty ~= "" then SetString("savegame.mod.difficulty", difficulty) end
	if GetString("savegame.mod.myrun") ~= run then
		SetString("savegame.mod.myrun", run)
		StartOwnRun()
	end
end

-- The per-player part of the main menu's new-game reset (menu_select_difficulty.lua playCharacter).
function StartOwnRun()
	SetBool("savegame.mod.inventory.init", true)
	if GetBool("level.runresetmoney") then SetInt("savegame.mod.player.money", 0) end
	for i = 1, 4 do
		SetBool("savegame.mod.bountyboard."..i, false)
	end
	SetBool("savegame.mod.bountyboard.cultist", false)
	SetBool("savegame.mod.bountyboard.military", false)
	SetBool("savegame.mod.bountyboard.insurgent", false)
	for _, perk in ipairs(ListKeys("savegame.mod.perks")) do
		SetInt("savegame.mod.perks."..perk, 0)
	end
end

-- Same form as the main menu's new-run id (menu_main.lua "Try Again", menu_select_difficulty.lua playCharacter).
function NewRunId()
	return string.format("%d-%d", math.floor(GetTime() * 1000) % 1000000000, math.random(100000, 999999))
end

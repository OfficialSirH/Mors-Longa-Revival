#version 2
DL_LABEL = "Gamerule"  -- crash breadcrumbs (lib/DeleteLog.lua)
#include "../lib/DeleteLog.lua"
#include "script/include/player.lua"
--[[
#include "../lib/Config.lua"
#include "perkTable.lua"
]]


-- (v2) server: savegame bookkeeping, permadeath restart (StartLevel is server-only).
-- (2026-11-14, user) In co-op the run ends (Hardcore / permadeath) when ANY player dies, not only the host.
function server.init()

	init_config()

	permadeath = GetBool("level.gamerule.permadeath")
	peaceful = GetString("savegame.mod.difficulty") == "peaceful"
	armorbuff = GetBool("savegame.mod.armorbbuff")

	respawntim = 0
	SeenAlive = {}        -- players seen with health > 0 this level (a player who just joined can read 0)
	PermadeathWiped = false
	if GetBool("savegame.mod.bountyboard.initialized") == false then
		SetInt("savegame.mod.bountyboard.Military", 0)
		SetInt("savegame.mod.bountyboard.bingus", 0)
		SetInt("savegame.mod.bountyboard.Insurgent", 0)
		SetInt("savegame.mod.bountyboard.Cultist", 0)

		SetInt("savegame.mod.bountyboard.BossCultistC", 0)
		SetInt("savegame.mod.bountyboard.BossMilitaryC", 0)
		SetInt("savegame.mod.bountyboard.BossInsurgentC", 0)
		SetInt("savegame.mod.bountyboard.BossUnisC", 0)
		SetInt("savegame.mod.bountyboard.BossDuoC", 0)
		SetInt("savegame.mod.bountyboard.BossTriaC", 0)
		SetInt("savegame.mod.bountyboard.BossQuattuorC", 0)

		SetBool("savegame.mod.bountyboard.initialized", true)
	end

	SetBool("savegame.mod.bountyboard.BossCultist", false)
	SetBool("savegame.mod.bountyboard.BossMilitary", false)
	SetBool("savegame.mod.bountyboard.BossInsurgent", false)
	SetBool("savegame.mod.bountyboard.BossUnis", false)
	SetBool("savegame.mod.bountyboard.BossDuo", false)
	SetBool("savegame.mod.bountyboard.BossTria", false)
	SetBool("savegame.mod.bountyboard.BossQuattuor", false)

	SetInt("level.distancetraveled",0)
end
function server.tick(dt)
	--wDebugPrint("Distance traveled: "..GetInt("level.distancetraveled"))
	--DebugPrint("fuelthief perk level: "..GetInt("savegame.mod.perks.fuelthief"))
	if permadeath and (PermadeathWiped or AnyPlayerDied()) then   -- latched: a respawn doesn't cancel the restart
		if not PermadeathWiped then
			PermadeathWiped = true
			for i=1,#PERKORDER do
				local perk=PERKORDER[i]
				if HasKey("savegame.mod.perks."..perk)then
					SetInt("savegame.mod.perks."..perk, 0)
				end
			end

			SetInt("savegame.mod.player.money", 0)
			ClearKey("savegame.mod.parkingSpot")
			ClientCall(0, "client.permadeathWipe")   -- every other player's money is in their own savegame
		end

		if respawntim > 2 then
			config.game.try_again.deaths = config.game.try_again.deaths + 1 -- Used to display try again button.
			config.game.try_again.menu_count = config.game.try_again.deaths

			StartLevel("","MOD/main.xml")
		end

		respawntim = respawntim + dt
	end
	--DebugPrint(GetBool("savegame.mod.bountyboard.BossUnis"))
end

-- (2026-11-14) any player who was alive this level is dead now
function AnyPlayerDied()
	local died = false
	for p in Players() do
		if GetPlayerHealth(p) > 0 then
			SeenAlive[p] = true
		elseif SeenAlive[p] then
			died = true
		end
	end
	for p in PlayersRemoved() do SeenAlive[p] = nil end
	return died
end

-- the run is over: like the host's money above, each player's own money (perks are the host's, wiped above)
function client.permadeathWipe()
	SetInt("savegame.mod.player.money", 0)
end
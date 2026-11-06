#version 2
#include "script/include/player.lua"
--[[
#include "../Config.lua"
#include "perkTable.lua"
]]


-- (v2) server: savegame bookkeeping, permadeath restart (StartLevel is server-only). Host health for now.
function server.init()

	init_config()

	permadeath = GetBool("level.gamerule.permadeath")
	peaceful = GetString("savegame.mod.difficulty") == "peaceful"
	armorbuff = GetBool("savegame.mod.armorbbuff")

	respawntim = 0
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
	if permadeath and GetPlayerHealth() == 0 then
		for i=1,#PERKORDER do
			local perk=PERKORDER[i]
			if HasKey("savegame.mod.perks."..perk)then
				SetInt("savegame.mod.perks."..perk, 0)
			end
		end

		SetInt("savegame.mod.player.money", 0)
		ClearKey("savegame.mod.parkingSpot")

		if respawntim > 2 then
			config.game.try_again.deaths = config.game.try_again.deaths + 1 -- Used to display try again button.
			config.game.try_again.menu_count = config.game.try_again.deaths

			StartLevel("","MOD/main.xml")
		end

		respawntim = respawntim + dt
	end
	--DebugPrint(GetBool("savegame.mod.bountyboard.BossUnis"))
end
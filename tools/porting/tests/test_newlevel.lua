-- Mock test for scripts/newLeveltoLEVEL.lua (MP fixes 2026-11-14): game rules synced, a remote player's own new
-- run (starter loadout via inventory.init, perks, bounty board), the host's difficulty mirrored.
-- Run from the repo root with Lua 5.1: lua5.1 tools/porting/tests/test_newlevel.lua
dofile("tools/porting/tests/mockengine.lua")

local function check(cond, msg) if not cond then error("FAIL: " .. msg, 2) end print("ok  " .. msg) end

local PATH = "scripts/newLeveltoLEVEL.lua"

-- one machine: its own registry; SetString/SetBool record the sync flag
local function machine(localPlayer)
	local env = MockEngine.load(PATH, { preload = MockEngine.includes(PATH) })
	env.PLAYERS[2] = { pos = {0,0,0}, health = 1 }
	env.ORDER = { 1, 2 }
	env.LOCAL = localPlayer
	env.synced = {}
	for _, t in ipairs({"String", "Bool", "Int", "Float"}) do
		env["Set" .. t] = function(k, v, sync) env.R[k] = v if sync then env.synced[k] = v end end
	end
	env.def("HasKey", function(k) return env.R[k] ~= nil end)
	env.def("ClearKey", function(k) for key in pairs(env.R) do if key == k or key:sub(1, #k + 1) == k .. "." then env.R[key] = nil end end end)
	env.def("ListKeys", function(parent)
		local seen, out = {}, {}
		for key in pairs(env.R) do
			if key:sub(1, #parent + 1) == parent .. "." then
				local child = key:sub(#parent + 2):match("^[^.]+")
				if child and not seen[child] then seen[child] = true out[#out + 1] = child end
			end
		end
		table.sort(out)
		return out
	end)
	return env
end

-- the engine syncs these to every client
local function sync(from, to)
	for k, v in pairs(from.synced) do to.R[k] = v end
end

-- 1. host: the menu set a new run; the level hands the rules over with sync and publishes the run
local host = machine(1)
host.R["savegame.mod.newLevel.gamerule.keepinv"] = "1"
host.R["savegame.mod.newLevel.gamerule.nhat"] = "1"
host.R["savegame.mod.difficulty"] = "peaceful"
host.R["savegame.mod.runid"] = "111-222"
host.side = "server"
host.server.init()
check(host.synced["level.gamerule.keepinv"] == "1" and host.synced["level.gamerule.nhat"] == "1",
	"server: level.gamerule.* written with the sync flag")
check(host.R["savegame.mod.lastLevel.gamerule.keepinv"] == "1" and host.synced["savegame.mod.lastLevel.gamerule.keepinv"] == nil,
	"server: savegame.mod.lastLevel copy kept, not synced")
check(host.R["savegame.mod.newLevel.gamerule.keepinv"] == nil, "server: savegame.mod.newLevel cleared")
check(host.synced["level.runid"] == "111-222" and host.synced["level.difficulty"] == "peaceful",
	"server: run id and difficulty published (synced)")
check(next(host.violations) == nil, "server: no client-only calls")

-- 2. a remote player with an old savegame of their own (last run's inventory, perks, bounty, hard difficulty)
local client = machine(2)
client.R["savegame.mod.difficulty"] = "hardcore"
client.R["savegame.mod.perks.medic"] = 3
client.R["savegame.mod.bountyboard.cultist"] = true
client.R["savegame.mod.player.money"] = 500
client.side = "client"
client.client.tick()
check(client.R["savegame.mod.inventory.init"] == nil, "client: nothing before the run id has synced")
sync(host, client)
client.client.tick()
check(client.R["savegame.mod.inventory.init"] == true, "client: new run -> inventory.init (starter loadout, full vitals)")
check(client.R["savegame.mod.perks.medic"] == 0 and client.R["savegame.mod.bountyboard.cultist"] == false,
	"client: own perks and bounty board reset")
check(client.R["savegame.mod.player.money"] == 500, "client: money kept (as the host's on New Save)")
-- Hardcore "Try Again": the host's money was reset, so the other players' is too
local host3 = machine(1)
host3.R["savegame.mod.runid"] = "333-444"
host3.R["savegame.mod.runresetmoney"] = true
host3.side = "server"
host3.server.init()
local client3 = machine(2)
client3.R["savegame.mod.player.money"] = 500
sync(host3, client3)
client3.side = "client"
client3.client.tick()
check(client3.R["savegame.mod.player.money"] == 0, "client: money reset on Try Again (as the host's)")
check(client.R["savegame.mod.difficulty"] == "peaceful", "client: host's difficulty mirrored")
check(client.R["savegame.mod.myrun"] == "111-222", "client: run remembered")
check(next(client.violations) == nil, "client: no server-only calls")

-- 3. next level of the same run (or Continue): no second reset
local client2 = machine(2)
for k, v in pairs(client.R) do client2.R[k] = v end
client2.R["savegame.mod.inventory.init"] = false   -- the inventory consumed it
client2.R["savegame.mod.perks.medic"] = 1          -- earned during the run
sync(host, client2)
client2.side = "client"
client2.client.tick()
check(client2.R["savegame.mod.inventory.init"] == false and client2.R["savegame.mod.perks.medic"] == 1,
	"client: same run again -> keeps inventory and perks")

-- 4. the host's own client never resets itself (the main menu did that)
host.side = "client"
host.R["savegame.mod.perks.medic"] = 2
host.client.tick()
check(host.R["savegame.mod.inventory.init"] == nil and host.R["savegame.mod.perks.medic"] == 2,
	"host client: no reset from the run id")

-- 5. an old host save without a run id gets one
local old = machine(1)
old.side = "server"
old.server.init()
check(old.R["savegame.mod.runid"] ~= "" and old.R["savegame.mod.runid"] ~= nil and old.synced["level.runid"] == old.R["savegame.mod.runid"],
	"server: run id created for a save without one")

print("all newLeveltoLEVEL tests passed")

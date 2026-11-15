-- Mock tests for the MP fixes of 2026-11-14 (second round): perk pickups raise the host's perk (perks are the host's
-- for everyone), fuel-sale money goes to the selling player, the cultist ambush picks a player on foot, server
-- bullets fall with gravity.
-- Run from the repo root with Lua 5.1: lua5.1 tools/porting/tests/test_mpleads.lua
dofile("tools/porting/tests/mockengine.lua")

local function check(cond, msg) if not cond then error("FAIL: " .. msg, 2) end print("ok  " .. msg) end
local function twoPlayers(env)
	env.PLAYERS[2] = { pos = {50, 0, 0}, health = 1 }
	env.ORDER = { 1, 2 }
end

-- 1. perk pickup (player/inventory.lua)
do
	local PATH = "player/inventory.lua"
	local server = MockEngine.load(PATH, { preload = MockEngine.includes(PATH) })
	twoPlayers(server)
	server.side = "server"
	local deleted = {}
	server.def("IsHandleValid", function(h) return h ~= 0 end)
	server.def("HasTag", function(h, t) return t == "PerkObject" end)
	server.def("GetTagValue", function(h, t) if t == "PerkObject" then return "ricochet" end return "Ricochet perk" end)
	server.def("Delete", function(h) deleted[#deleted + 1] = h end)
	server.R["savegame.mod.perks.ricochet"] = 2
	server.server.invTake(2, 77)
	local call = server.sent[#server.sent]
	check(server.R["savegame.mod.perks.ricochet"] == 3 and deleted[1] == 77, "pickup by player 2 raises the host's perk")
	check(call.to == 2 and call.fn == "client.invTaken" and call.args[4] == 2 and call.args[5] == false,
		"the picker gets the notice (level before, not maxed)")
	server.R["savegame.mod.perks.ricochet"] = server.PERKTABLE.ricochet.perkMaxLevel or 10
	server.server.invTake(2, 78)
	call = server.sent[#server.sent]
	check(call.args[5] == true and server.R["savegame.mod.perks.ricochet"] == (server.PERKTABLE.ricochet.perkMaxLevel or 10),
		"a maxed perk stays at its maximum")

	local client = MockEngine.load(PATH, { preload = MockEngine.includes(PATH) })
	client.side = "client"
	client.LOCAL = 2
	client.SOUNDS = client.SOUNDS or {}
	client.R["savegame.mod.player.money"] = 100
	client.R["savegame.mod.perks.ricochet"] = 1
	client.client.invTaken("PerkObject", "ricochet", "Ricochet perk", 1, false)
	check(client.R["savegame.mod.perks.ricochet"] == 1 and client.R["savegame.mod.player.money"] == 100,
		"picker's machine: no perk write of its own (the host's value is mirrored), no money")
	check(#client.perkPickupQue == 1 and client.perkPickupQue[1].perkLevel == 1, "picker's machine: pickup notice queued")
	client.client.invTaken("PerkObject", "ricochet", "Ricochet perk", 10, true)
	check(client.R["savegame.mod.player.money"] == 600, "maxed perk: the picker gets $500")
	check(next(server.violations) == nil and next(client.violations) == nil, "inventory: no wrong-side calls")
end

-- 2. fuel-sale money (vehicles/Fuel.lua)
do
	local PATH = "vehicles/Fuel.lua"
	local env = MockEngine.load(PATH, { preload = MockEngine.includes(PATH) })
	twoPlayers(env)
	env.side = "server"
	local tags = { [10] = { fuelLevel = "50", fuelLevelMAX = "100" }, [20] = { fuelLevel = "0", fuelLevelMAX = "100", sell = "" } }
	env.def("GetTagValue", function(h, t) return (tags[h] or {})[t] or "" end)
	env.def("HasTag", function(h, t) return (tags[h] or {})[t] ~= nil end)
	env.def("SetTag", function(h, t, v) tags[h] = tags[h] or {} tags[h][t] = tostring(v) end)
	env.FuelMoney = {}
	env.R["savegame.mod.player.money"] = 1000   -- the host's
	for i = 1, 3 do env.refuel(10, 20, nil, 2) end
	env.FlushFuelMoney()
	local calls = {}
	for _, s in ipairs(env.sent) do if s.fn == "client.fuelMoney" then calls[#calls + 1] = s end end
	check(#calls == 1 and calls[1].to == 2 and calls[1].args[1] == 9, "selling 0.3 fuel: $9 to the seller (player 2)")
	check(env.R["savegame.mod.player.money"] == 1000, "the host's money untouched")
	env.sent = {}
	env.FlushFuelMoney()
	check(#env.sent == 0, "nothing more to send")
	env.side = "client"
	env.R["savegame.mod.player.money"] = 5
	env.client.fuelMoney(9)
	check(env.R["savegame.mod.player.money"] == 14, "seller's machine adds it to their own money")
end

-- 3. cultist ambush target (npcs/Cultist Spawner.lua)
do
	local PATH = "npcs/Cultist Spawner.lua"
	local env = MockEngine.load(PATH, { preload = MockEngine.includes(PATH) })
	twoPlayers(env)
	env.side = "server"
	local inVehicle = { [1] = 5, [2] = 0 }
	env.def("GetPlayerVehicle", function(p) return inVehicle[p] or 0 end)
	check(env.AmbushTarget() == 2, "host driving, player 2 on foot: the ambush comes for player 2")
	inVehicle[2] = 6
	check(env.AmbushTarget() == nil, "everybody in a vehicle: no ambush yet")
	inVehicle[1] = 0
	env.PLAYERS[1].health = 0
	check(env.AmbushTarget() == nil, "a dead player on foot is not a target")
end

-- 4. server bullets fall (weapons/guns/gunnet.lua)
do
	local env = MockEngine.load("weapons/guns/gunnet.lua", {})
	env.side = "server"
	env.GunNet_ServerInit()
	check(env.gravity and env.gravity[2] == -10, "server: bullet gravity (0, -10, 0)")
end

-- 5. permadeath (game/Gamerule.lua): any player's death ends the run (user, 2026-11-14)
do
	local PATH = "game/Gamerule.lua"
	local env = MockEngine.load(PATH, { preload = MockEngine.includes(PATH) })
	twoPlayers(env)
	env.side = "server"
	env.R["level.gamerule.permadeath"] = true
	env.def("init_config", function() env.config = { game = { try_again = { deaths = 0, menu_count = 0 } } } end)
	env.def("HasKey", function(k) return env.R[k] ~= nil end)
	env.def("ClearKey", function(k) env.R[k] = nil end)
	env.server.init()
	env.PLAYERS[2].health = 0   -- player 2 hasn't spawned yet when the level starts
	env.server.tick(1/60)
	check(not env.calls.StartLevel and not env.PermadeathWiped, "a player not yet seen alive doesn't end the run")
	env.PLAYERS[2].health = 1
	env.server.tick(1/60)
	env.R["savegame.mod.perks.ricochet"] = 3
	env.R["savegame.mod.player.money"] = 700
	env.PLAYERS[2].health = 0   -- player 2 (not the host) dies
	env.server.tick(1/60)
	local wipe = 0
	for _, s in ipairs(env.sent) do if s.fn == "client.permadeathWipe" and s.to == 0 then wipe = wipe + 1 end end
	check(env.R["savegame.mod.perks.ricochet"] == 0 and env.R["savegame.mod.player.money"] == 0 and wipe == 1,
		"a non-host's death: host's perks / money wiped, every player told to wipe their money")
	env.PLAYERS[2].health = 1   -- respawned before the restart
	for i = 1, 200 do env.server.tick(1/60) end
	check(env.calls.StartLevel and env.calls.StartLevel >= 1, "the restart happens anyway (back to the main menu)")
	wipe = 0
	for _, s in ipairs(env.sent) do if s.fn == "client.permadeathWipe" then wipe = wipe + 1 end end
	check(wipe == 1, "wiped once")
	env.side = "client"
	env.R["savegame.mod.player.money"] = 250
	env.client.permadeathWipe()
	check(env.R["savegame.mod.player.money"] == 0, "each machine wipes its own money")
end

print("all MP lead tests passed")

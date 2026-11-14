-- Mock test for Phase 3 batch B (shop area + supply plane). Run from the repo root with Lua 5.1:
--   lua5.1 tools/porting/tests/test_shop.lua
dofile("tools/porting/tests/mockengine.lua")

local function check(cond, msg) if not cond then error("FAIL: " .. msg, 2) end print("ok  " .. msg) end
local function twoPlayers(env, p1, p2)
	env.PLAYERS = { [1] = { pos = p1, health = 1 }, [2] = { pos = p2, health = 1 } }
	env.ORDER = { 1, 2 }
end
-- deliver ServerCalls / ClientCalls recorded in env.sent (client side runs as env.LOCAL)
local function pump(env)
	local msgs = env.sent
	env.sent = {}
	for _, m in ipairs(msgs) do
		local fn = assert(loadstring("return " .. m.fn))
		setfenv(fn, env)
		local side = env.side
		env.side = (m.to == "server") and "server" or "client"
		fn()(unpack(m.args))
		env.side = side
	end
end

------------------------------------------------------------------ cultist warehouse, supply plane
local env = MockEngine.load("world/WarehouseScript_Cultist.lua")
twoPlayers(env, {100,0,0}, {5,0,0})
env.def("IsPointInTrigger", function(t, pos) return pos[1] == 5 end)
env.def("FindLocations", function() return {1} end)
env.server.init()
env.server.tick(1/60)
check(env.Triggered and (env.calls.Spawn or 0) >= 2 and next(env.violations) == nil, "cultist warehouse: player 2 triggers the ambush")
local spawns = env.calls.Spawn
env.server.tick(1/60)
check(env.calls.Spawn == spawns, "cultist warehouse: once")

env = MockEngine.load("world/AC130.lua")
twoPlayers(env, {1000,0,0}, {100,0,0})
env.server.init()
for i = 1, 600 do env.server.tick(1/60) end
check((env.calls.Spawn or 0) >= 1 and next(env.violations) == nil, "supply plane: drops crates for the nearest player (player 2, 100 m)")

------------------------------------------------------------------ safe zone outlines (client)
env = MockEngine.load("game/SafeZone.lua", { preload = { "lib/TDSU/util_vec.lua" } })
env.def("FindBodies", function() return {3} end)
env.def("GetTagValue", function() return "bed" end)
env.def("IsHandleValid", function() return true end)
env.server.init()
check(env.R["level.safezoneLoadCount"] == 1, "safe zone: server counts the load")
env.side = "client"
env.client.init() env.client.tick()
check((env.calls.DrawBodyOutline or 0) == 1 and next(env.violations) == nil and env.server.tick == nil, "safe zone: outlines on the client")

------------------------------------------------------------------ perk machine
env = MockEngine.load("game/PerkMachine.lua", { preload = {} })
twoPlayers(env, {0,0,0}, {1,0,0})
env.def("FindBody", function() return 50 end)
env.def("FindShape", function(tag) return ({ screen = 51, machine = 52, lever = 53 })[tag] or 0 end)
env.def("IsHandleValid", function() return true end)
env.def("GetJointLimits", function() return 0, 1 end)
local interact = {} -- [player] = shape pressed this frame
env.def("InputPressed", function(k, p) p = (p and p ~= 0) and p or env.LOCAL return k == "interact" and interact[p] ~= nil end)
env.def("GetPlayerInteractShape", function(p) p = (p and p ~= 0) and p or env.LOCAL return interact[p] or 0 end)
env.server.init() env.server.tick(1/60)
env.side = "client" env.client.init() env.side = "server"
local function clientFrame(p)
	env.LOCAL = p env.side = "client" env.client.tick(1/60) env.side = "server"
end
-- player 2 buys one perk
env.R["savegame.mod.player.money"] = 600
interact[2] = 51 clientFrame(2) interact[2] = nil
check(env.R["savegame.mod.player.money"] == 100 and env.sent[1].fn == "server.perkBuy", "perk: client pays $500 and asks the server")
pump(env)
for i = 1, 70 do env.server.tick(1/60) end
check((env.calls.Spawn or 0) == 1 and env.totalPerkBought == 1, "perk: server prints one perk")
-- lever by player 2, then a supercharged purchase of the remaining 9
interact[2] = 53 env.server.tick(1/60) interact[2] = nil
check(env.supercharge == true and env.shared.perk.supercharge == true, "perk: player 2 flips the lever (supercharge)")
env.R["savegame.mod.player.money"] = 5000
interact[2] = 51 clientFrame(2) interact[2] = nil
check(env.R["savegame.mod.player.money"] == 500 and env.sent[1].args[2] == 9, "perk: supercharge pays all 9 remaining up front")
pump(env)
for i = 1, 60 * 10 do env.server.tick(1/60) end
check(env.totalPerkBought == 10 and env.terminatePerkMachine and next(env.violations) == nil, "perk: all 10 printed, machine done")
-- a purchase while busy is refunded
env = MockEngine.load("game/PerkMachine.lua")
env.def("FindBody", function() return 50 end)
env.def("IsHandleValid", function() return true end)
env.server.init()
env.printing = true
env.R["savegame.mod.player.money"] = 0
env.server.perkBuy(1, 1, 500)
pump(env)
check(env.R["savegame.mod.player.money"] == 500, "perk: busy machine refunds the buyer")

------------------------------------------------------------------ garage (parking spot)
env = MockEngine.load("game/ParkingSpot.lua", { preload = { "lib/TDSU/compat.lua", "lib/TDSU/util_table.lua", "lib/TDSU/util_lua.lua", "lib/TDSU/util_td.lua", "lib/TDSU/util_math.lua", "lib/TDSU/util_vec.lua", "lib/TDSU/util_quat.lua", "lib/Automatic.lua" } })
twoPlayers(env, {0,0,0}, {2,0,0})
env.Init_Settings = function() env.Settings = { keybinds = { inventory = { toggle_inv = "i" } } } end
env.KeybindPressed = function() return false end
local VEH = { [70] = {5,0,0}, [71] = {6,0,0} } -- 70 compatible (spawned by the map), 71 not
env.def("FindVehicles", function() return {70, 71} end)
env.def("FindTrigger", function() return 9 end)
env.def("FindBody", function() return 10 end)
env.def("IsHandleValid", function(h) return h ~= 0 end)
env.def("GetVehicleCenterOfMassPos", function(v) return VEH[v] or {999,0,0} end)
env.def("IsPointInTrigger", function(t, pos) return pos[1] < 10 end)
env.def("GetTriggerTransform", function() return env.Transform({0,0,0}) end)
env.def("GetTriggerBounds", function() return {0,0,-5}, {10,5,5} end)
env.def("GetBodyBounds", function() return {4,0,-1}, {6,2,1} end)
env.def("GetLocationTransform", function() return env.Transform({2,3,0}) end)
env.def("VecLerp", function(a, b, f) return {a[1]+(b[1]-a[1])*f, a[2]+(b[2]-a[2])*f, a[3]+(b[3]-a[3])*f} end)
env.def("GetTagValue", function(h, t) if h == 70 and t == "path" then return "MOD/v.xml" end return "" end)
env.def("GetPlayerVehicle", function(p) if p == 2 then return 70 end if p == 1 then return 71 end return 0 end)
env.server.init()
for i = 1, 3 do env.T = env.T + 1.2 env.server.tick() end
local g = env.shared.garage
check(g and g.stop == "" and #g.saved == 1 and g.saved[1].vehicle == 70, "garage: player 2's compatible vehicle is saved (1 spot)")
check(#g.incompatible == 1 and g.incompatible[1] == 71, "garage: host's incompatible vehicle listed for the error icon")
check(next(env.violations) == nil, "garage: server does no client-only calls")
-- client draws from shared
env.side = "client" env.LOCAL = 2
env.client.init() env.client.tick(1/60) env.client.draw(1/60)
check(next(env.violations) == nil and env.SavedVehicles_SpotsUnlocked == 1, "garage: client draws from shared.garage")
-- buying a spot: player 2 pays, server adds it; a stale second request is refunded
env.side = "server"
env.R["savegame.mod.player.money"] = 3000
env.server.garageBuySpot(2, 1, 3000)
check(env.R["savegame.mod.parkingSpot.maxSpots"] == 2, "garage: server adds the bought spot")
env.server.garageBuySpot(2, 1, 5000)
pump(env)
check(env.R["savegame.mod.player.money"] == 8000, "garage: stale purchase refunded")
-- everyone 200 m past: disabled
env.PLAYERS[1].pos, env.PLAYERS[2].pos = {300,0,0}, {250,0,0}
env.server.tick() env.server.tick()
check(env.Stopped and env.shared.garage.stop ~= "", "garage: disabled once every player is 200 m past")

print("all shop tests passed")

-- Mock test for the debug auto-travel (ui/ConfigMenu.lua server.configTravel / TickTravel).
-- Run from the repo root with Lua 5.1: lua5.1 tools/porting/tests/test_travel.lua
dofile("tools/porting/tests/mockengine.lua")
local function check(cond, msg) if not cond then error("FAIL: " .. msg, 2) end print("ok  " .. msg) end

local env = MockEngine.load("ui/ConfigMenu.lua")
env.PLAYERS[1].pos = {0, 4, 3}
env.def("IsPlayerValid", function() return true end)
local road = true
env.def("QueryRaycast", function(o, d, dist)
	if o[2] < 10 then return true, 3 - 0 end -- ground probe at start: ground 3 m below (pos + 3 up)
	return road, 20
end)
local vehicle = 7
env.def("GetPlayerVehicle", function() return vehicle end)
env.def("SetPlayerVehicle", function(v) vehicle = v end)
env.def("SetPlayerTransform", function(t, p) env.PLAYERS[p].pos = {t.pos[1], t.pos[2], t.pos[3]} end)
-- distance counter follows x like GenerateRoad (start x = 0)
local function syncDistance() env.R["savegame.mod.distanceProgressed"] = env.PLAYERS[1].pos[1] + env.shiftedAway end
env.shiftedAway = 0
syncDistance()

env.server.configTravel(1, 1000)
check(vehicle == 0, "leaves the vehicle")
check(math.abs(env.Travel.y - (4 + 2.5)) < 1e-6 and env.Travel.z == 3, "hovers 2.5 m above the ground, same lane")
for i = 1, 60 do env.T = env.T + 1/60 env.server.tick(1/60) syncDistance() end
check(math.abs(env.PLAYERS[1].pos[1] - 40) < 1e-6, "moves 40 m in one second")
road = false
local x = env.PLAYERS[1].pos[1]
for i = 1, 30 do env.T = env.T + 1/60 env.server.tick(1/60) end
check(env.PLAYERS[1].pos[1] == x and env.shared.travel.waiting, "waits while there is no road ahead")
road = true
-- world shift: GenerateRoad moves the player back 200 m and bumps level.world_shifts
env.PLAYERS[1].pos[1] = env.PLAYERS[1].pos[1] - 200 env.shiftedAway = env.shiftedAway + 200
env.R["level.world_shifts"] = 1
local shifted = env.PLAYERS[1].pos[1]
env.T = env.T + 1/60 env.server.tick(1/60) env.T = env.T + 1/60 env.server.tick(1/60) env.T = env.T + 1/60 env.server.tick(1/60)
check(env.PLAYERS[1].pos[1] == shifted, "pauses 3 ticks after a world shift (never writes a pre-shift position)")
env.T = env.T + 1/60 env.server.tick(1/60)
check(env.PLAYERS[1].pos[1] > shifted, "continues after the pause")
for i = 1, 60 * 30 do env.T = env.T + 1/60 env.server.tick(1/60) syncDistance() if not env.Travel then break end end
check(env.Travel == nil and env.shared.travel == nil and env.R["savegame.mod.distanceProgressed"] >= 1000, "stops at start + 1 km")
env.server.configTravel(1, 5000) env.server.configTravel(1, 0)
check(env.Travel == nil, "Stop cancels")
check(next(env.violations) == nil, "server only")
print("all travel tests passed")

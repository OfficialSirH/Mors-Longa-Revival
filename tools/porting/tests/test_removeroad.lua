-- Mock test: Procedural/RemoveRoad.lua and WaterMover.lua must never delete because no players were found
-- (2026-11-07: a fresh game showed no world and an invisible gun). Run from the repo root with Lua 5.1:
--   lua5.1 tools/porting/tests/test_removeroad.lua
dofile("tools/porting/tests/mockengine.lua")
local function check(cond, msg) if not cond then error("FAIL: " .. msg, 2) end print("ok  " .. msg) end

local function setup(players)
	local env = MockEngine.load("Procedural/RemoveRoad.lua")
	env.PLAYERS, env.ORDER = {}, {}
	for i, x in ipairs(players) do env.PLAYERS[i] = { pos = {x, 0, 0}, health = 1 } env.ORDER[i] = i end
	local deleted = {}
	env.def("GetBool", function(k) return k == "level.roadgen" end)
	env.def("FindShapes", function() return {101, 102} end)   -- 101 at x = -1000 (far behind), 102 at x = 0
	env.def("FindBodies", function() return {} end)
	env.def("FindTriggers", function() return {} end)
	env.def("FindJoints", function() return {} end)
	env.def("HasTag", function() return false end)
	env.def("GetShapeWorldTransform", function(s) return env.Transform({ s == 101 and -1000 or 0, 0, 0 }) end)
	env.def("Delete", function(h) deleted[#deleted + 1] = h end)
	env.server.init()
	env.server.update()
	return deleted
end

check(#setup({}) == 0, "RemoveRoad: no players → deletes nothing (v1-port bug: deleted the whole level)")
local d = setup({0})
check(#d == 1 and d[1] == 101, "RemoveRoad: player at x=0 → deletes only the shape 1000 m behind")
d = setup({0, -900})
check(#d == 0, "RemoveRoad: a straggler at x=-900 keeps that area")

-- level.roadgen is a one-frame pulse: a pulse between two throttled passes must still trigger the next pass
do
	local env = MockEngine.load("Procedural/RemoveRoad.lua")
	env.PLAYERS, env.ORDER = { { pos = {0, 0, 0}, health = 1 } }, { 1 }
	local pulse, deleted = false, {}
	env.def("GetBool", function(k) return k == "level.roadgen" and pulse end)
	env.def("FindShapes", function() return {101} end)
	env.def("HasTag", function() return false end)
	env.def("GetShapeWorldTransform", function() return env.Transform({ -1000, 0, 0 }) end)
	env.def("Delete", function(h) deleted[#deleted + 1] = h end)
	env.server.init()
	env.T = 0 env.server.update()
	check(#deleted == 0, "pulse: no pass without a new segment")
	pulse = true env.T = 0.1 env.server.update() pulse = false  -- segment spawned between passes
	env.T = 0.3 env.server.update()
	check(#deleted == 1, "pulse: remembered and cleaned up on the next pass")
	env.T = 0.6 env.server.update()
	check(#deleted == 1, "pulse: only once per segment")
end

print("all removeroad tests passed")

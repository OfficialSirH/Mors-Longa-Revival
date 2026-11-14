-- Mock test for the per-player tool list in script/inventory.lua server.tick (MP fix 2026-11-14): in multiplayer
-- the engine's sandbox.lua enables every registered tool for every player each tick; the inventory must switch the
-- ones a player may not have back off every tick, not only when its wish changes.
-- Run from the repo root with Lua 5.1: lua5.1 tools/porting/tests/test_invtools.lua
dofile("tools/porting/tests/mockengine.lua")

local function check(cond, msg) if not cond then error("FAIL: " .. msg, 2) end print("ok  " .. msg) end

local PATH = "script/inventory.lua"
local env = MockEngine.load(PATH, { preload = MockEngine.includes(PATH) })
env.PLAYERS[2] = { pos = {0,0,0}, health = 1 }
env.ORDER = { 1, 2 }
env.side = "server"

local enabled = {}   -- [player][tool]
local function sandboxTick()   -- what data/script/sandbox.lua does in multiplayer, every tick
	for _, p in ipairs(env.ORDER) do
		enabled[p] = enabled[p] or {}
		for _, id in ipairs({ "sledge", "spraycan", "blowtorch", "AK74" }) do enabled[p][id] = true end
	end
end
env.def("ListKeys", function(k) if k == "game.tool" then return { "sledge", "spraycan", "blowtorch", "AK74" } end return {} end)
env.def("IsToolEnabled", function(id, p) return (enabled[p] or {})[id] == true end)
env.def("SetToolEnabled", function(id, on, p) enabled[p] = enabled[p] or {} enabled[p][id] = on end)
env.def("GetBool", function(k) return false end)
env.def("SetPlayerTool", function() end)

env.server.init()
env.Settings = env.Settings or {}
env.Settings.game = env.Settings.game or {}
env.Settings.game.enable_tools = { value = false }
env.server.invTools(2, { AK74 = true })   -- player 2's inventory holds an AK74

for frame = 1, 3 do
	sandboxTick()
	env.server.tick(1/60)
	check(not enabled[1].sledge and not enabled[2].sledge and not enabled[2].spraycan and not enabled[2].blowtorch,
		"frame " .. frame .. ": vanilla tools off for both players after sandbox re-enabled them")
	check(enabled[2].AK74 and not enabled[1].AK74, "frame " .. frame .. ": the AK74 only for the player who has it")
	check(enabled[1].extinguisher and enabled[2].extinguisher, "frame " .. frame .. ": always-allowed tools on")
end

env.Settings.game.enable_tools.value = true
sandboxTick()
env.server.tick(1/60)
check(enabled[1].sledge and enabled[2].blowtorch, "'enable all tools' setting: vanilla tools stay on")
check(next(env.violations) == nil, "server: no client-only calls")
print("all inventory tool tests passed")

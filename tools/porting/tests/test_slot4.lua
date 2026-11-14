-- Mock test for key 4 (player/inventory.lua InvCycleSlot4, 2026-11-14): it cycles the enabled tools the bar shows in
-- slot 4 (game.tool.<id>.group = 4) in the bar's order, the Extinguisher included.
-- Run from the repo root with Lua 5.1: lua5.1 tools/porting/tests/test_slot4.lua
dofile("tools/porting/tests/mockengine.lua")

local function check(cond, msg) if not cond then error("FAIL: " .. msg, 2) end print("ok  " .. msg) end

local env = MockEngine.load("player/inventory.lua", { preload = MockEngine.includes("player/inventory.lua") })
env.side = "client"
local held, pressed = "gun-ak74", false
local enabled = { placer = true, welder = true, extinguisher = true, ["gun-ak74"] = true, sledge = false }
env.R["game.tool.placer.group"], env.R["game.tool.placer.index"] = 4, 1
env.R["game.tool.welder.group"], env.R["game.tool.welder.index"] = 4, 2
env.R["game.tool.extinguisher.group"], env.R["game.tool.extinguisher.index"] = 4, 3
env.R["game.tool.gun-ak74.group"] = 1
env.R["game.tool.sledge.group"] = 4
env.def("ListKeys", function(k) if k == "game.tool" then return { "sledge", "extinguisher", "welder", "placer", "gun-ak74" } end return {} end)
env.def("IsToolEnabled", function(id) return enabled[id] == true end)
env.def("GetPlayerTool", function() return held end)
env.def("InputPressed", function(k) return k == "4" and pressed end)

local function press()
	pressed = true
	env.InvToolSelect = nil
	env.InvCycleSlot4()
	pressed = false
	return env.InvToolSelect
end
local function frames(n) for i = 1, n do env.T = env.T + 1/60 env.InvCycleSlot4() end end

frames(2)
check(press() == "placer", "from the gun: first slot-4 tool (Place Tool)")
env.T = env.T + 0.2
check(press() == "welder", "again: Welding Tool (even before the server confirmed the switch)")
env.T = env.T + 0.2
check(press() == "extinguisher", "again: Extinguisher")
env.T = env.T + 0.2
check(press() == "placer", "again: back to the Place Tool")
-- the engine already switched to the Welding Tool when its own key 4 ran; later we hold it
held = "welder"
env.T = env.T + 3
frames(2)
check(press() == "extinguisher", "holding the Welding Tool: next is the Extinguisher")
enabled.extinguisher = false
held = "welder"
env.T = env.T + 3
frames(2)
check(press() == "placer", "a disabled tool is skipped; the disabled sledge never appears")
env.InvToolSelect = nil
frames(1)
check(env.InvToolSelect == nil, "no switch without a key press")
print("all slot 4 tests passed")

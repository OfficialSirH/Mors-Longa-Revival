-- Mock test for player/inventory.lua SaveInventory's write cache (2026-11-15, performance): it runs every frame (as in
-- the original) but writes a slot's registry keys only when the slot changed, and rewrites everything once a second.
-- Run from the repo root with Lua 5.1: lua5.1 tools/porting/tests/test_invsave.lua
dofile("tools/porting/tests/mockengine.lua")
local function check(cond, msg) if not cond then error("FAIL: " .. msg, 2) end print("ok  " .. msg) end

local env = MockEngine.load("player/inventory.lua", { preload = MockEngine.includes("player/inventory.lua") })
local writes, reg, T = 0, {}, 0
env.def("SetString", function(k, v) writes = writes + 1 reg[k] = v end)
env.def("SetInt", function(k, v) writes = writes + 1 reg[k] = v end)
env.def("ClearKey", function(k) writes = writes + 1 reg[k] = nil end)
env.def("GetTime", function() return T end)
env.GetDimensions = function(item) if item == "" then return 0, 0 end return 1, 1 end

local function grid(rows, cols)
	local g = {}
	for i = 1, rows do g[i] = {} for j = 1, cols do g[i][j] = { "" , rotation = 0 } end end
	return g
end
env.backpack, env.stash, env.guns, env.armor = grid(8, 15), grid(8, 15), grid(1, 4), grid(1, 3)
env.backpack[1][1] = { "ammo-9mm_1_30", rotation = 0 }

env.SaveInventory()
local first = writes
check(first > 240 and reg["inventory.backpack.1_1.item"] == "ammo-9mm_1_30", "first save writes every slot")
writes = 0
env.SaveInventory()
check(writes == 0, "next frame, nothing changed: no registry writes (v1: ~500 per frame)")
env.backpack[2][3] = { "food-apple", rotation = 1 }
env.SaveInventory()
check(writes > 0 and writes <= 4 and reg["inventory.backpack.2_3.item"] == "food-apple"
	and reg["savegame.mod.inventory.backpack.2_3.rotation"] == 1, "one slot changed: only its keys (and the weight)")
writes = 0
reg["inventory.backpack.1_1.item"] = "changed elsewhere"
T = 1.5
env.SaveInventory()
check(writes >= first and reg["inventory.backpack.1_1.item"] == "ammo-9mm_1_30", "once a second: everything rewritten (corrects keys changed elsewhere)")
-- GetDimensions: worked out once per item string (it only depends on the string), same results
local env2 = MockEngine.load("player/inventory.lua", { preload = MockEngine.includes("player/inventory.lua") })
local calls = 0
local realSplit = env2.Split
env2.Split = function(...) calls = calls + 1 return realSplit(...) end
local w1, h1 = env2.GetDimensions("gun-ak74_x_x")
local before = calls
local w2, h2 = env2.GetDimensions("gun-ak74_x_x")
check(w1 == w2 and h1 == h2 and calls == before, "GetDimensions: second call for the same item does no string splitting")
local uw, uh = env2.GetDimensionsUncached("food-apple")
local cw, ch = env2.GetDimensions("food-apple")
check(uw == cw and uh == ch, "cached result = uncached result")
print("all inventory save tests passed")

-- Mock test (2026-11-15): the starter kit pick is seeded per run and per player (player/inventory.lua InvSeedRandom)
-- Run from the repo root with Lua 5.1: lua5.1 tools/porting/tests/test_kitseed.lua
local function check(cond, msg) if not cond then error("FAIL: " .. msg, 2) end print("ok  " .. msg) end
local src = io.open("player/inventory.lua", "rb"):read("*a"):gsub("\r", "")
local a = src:find("function InvSeedRandom")
local b = src:find("\nfunction PlaceItemFromXML")
assert(loadstring(src:sub(a, b)))()
check(src:find("InvSeedRandom%(%) %-%- %(2026%-11%-15%) see InvSeedRandom\n%s*local Config = Loadouts"), "seeded right before the kit pick")
local REG, me, now = {}, 1, 0
function GetString(k) return REG[k] or "" end
function GetLocalPlayer() return me end
function GetTime() return now end
local function kit() InvSeedRandom() math.random(1, 4) return math.random(1, 6) end -- config, then the kit (6 kits)
local seen, same = {}, true
for run = 1, 40 do
	REG["savegame.mod.runid"] = (123456 + run * 7919) .. "-" .. (400000 + run)
	local k = kit()
	seen[k] = true
end
local n = 0 for _ in pairs(seen) do n = n + 1 end
check(n >= 5, "40 new games: " .. n .. " of 6 kits picked")
REG["savegame.mod.runid"] = "5551-777777"
local k1 = kit() local again = kit()
check(k1 == again, "same run, player and time: same kit (deterministic)")
local differ = false
for p = 2, 4 do me = p if kit() ~= k1 then differ = true end end
check(differ, "other players in the same run can get other kits")
print("kit seed tests passed")

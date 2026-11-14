-- Mock test for checkUnlimitedBulletsValid (script/gunfunctions.lua, 2026-11-14): the fake "Infinite" magazine
-- holds exactly one bullet, and one left over while Infinite Ammo is off is emptied (PP19.lua:475 concat error).
-- Run from the repo root with Lua 5.1: lua5.1 tools/porting/tests/test_infinitemag.lua
dofile("tools/porting/tests/mockengine.lua")

local function check(cond, msg) if not cond then error("FAIL: " .. msg, 2) end print("ok  " .. msg) end

local env = MockEngine.load("script/gunfunctions.lua", { preload = MockEngine.includes("script/gunfunctions.lua") })
env.side = "client"
env.def("GetInt", function(k) if k == "inventory.curprimary" then return 1 end return env.R[k] or 0 end)
local KEY = "inventory.guns.1.item"
-- gun-pp19 item: fields 3 mag id, 4 mag name, 5 rounds, 6 capacity, 10 bullet list
local function item(t) return table.concat(t, "_") end

-- 1. Infinite Ammo on, magazine empty: fake magazine with exactly one bullet
env.R[KEY] = item({ "gun-pp19", "x", "mag0-ak-9x19", "Simonov-9-Mag", "0", "30", "a", "b", "c", "FMJ-FMJ-AP" })
env.unlimitedammo, env.ammo, env.bullettable = true, 0, { "FMJ", "FMJ", "AP" }
env.checkUnlimitedBulletsValid()
local f = env.Split(env.R[KEY], "_")
check(env.ammo == 1 and #env.bullettable == 1 and env.bullettable[1] == "AP", "fake magazine: 1 round, 1 bullet")
check(f[4] == "Infinite" and f[5] == "1" and f[10] == "AP", "fake magazine saved with a one-bullet list")
-- the gun's own shot + write-back (PP19 FireRound with Infinite Ammo off) no longer hits a hole
env.unlimitedammo = false
env.bullettable[env.ammo] = nil
check(pcall(table.concat, env.bullettable, "-"), "a shot from it leaves a list table.concat accepts")

-- 2. the v1 leftover (1 round, a longer bullet list) with Infinite Ammo off: emptied
env.R[KEY] = item({ "gun-pp19", "x", "", "Infinite", "1", "1", "a", "b", "c", "FMJ-FMJ-AP" })
env.unlimitedammo, env.ammo, env.bullettable = false, 1, { "FMJ", "FMJ", "AP" }
env.checkUnlimitedBulletsValid()
f = env.Split(env.R[KEY], "_")
check(env.ammo == 0 and #env.bullettable == 0, "leftover fake magazine: gun unloaded")
check(f[4] == "Unloaded" and f[5] == "0" and f[6] == "0" and f[10] == "", "leftover fake magazine: saved empty")

-- 3. an ordinary magazine is never touched while Infinite Ammo is off
local normal = item({ "gun-pp19", "x", "mag0-ak-9x19", "Simonov-9-Mag", "12", "30", "a", "b", "c", "FMJ-FMJ" })
env.R[KEY] = normal
env.ammo = 12
env.checkUnlimitedBulletsValid()
check(env.R[KEY] == normal and env.ammo == 12, "ordinary magazine untouched")

-- 4. an item without a bullet list (RPG) keeps its fields
env.R[KEY] = item({ "gun-rpg", "x", "", "Rocket", "0", "1" })
env.unlimitedammo, env.ammo = true, 0
env.checkUnlimitedBulletsValid()
f = env.Split(env.R[KEY], "_")
check(#f == 6, "no bullet-list field added to an item without one")
print("all infinite magazine tests passed")

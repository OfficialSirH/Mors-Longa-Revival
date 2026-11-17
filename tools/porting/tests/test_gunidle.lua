-- Mock test for the idle-gun shortcuts in weapons/guns/gunfunctions.lua (2026-11-17, performance): the projectile /
-- grenade slot scan stops once nothing is in flight and resumes when a shot advances shellNum; GunInInventory reads
-- the registry once per frame per gun. Run from the repo root with Lua 5.1: lua5.1 tools/porting/tests/test_gunidle.lua

local src = io.open("weapons/guns/gunfunctions.lua", "rb"):read("*a"):gsub("\r", "")
-- the two pieces under test: stepShells + WeaponBackgroundTick, and the GunInInventory cache + reader
local a = src:find("local function stepShells", 1, true)
local b = src:find("\nend\n", src:find("function WeaponBackgroundTick", 1, true), true) + 4
local c = src:find("local invCheck = {}", 1, true)
local d = src:find("\nend\n", src:find("function GunInInventory_Read", 1, true), true) + 4
assert(a and b and c and d, "pieces not found")
local chunk = src:sub(a, b) .. "\n" .. src:sub(c, d)

local T = 0
function GetTime() return T end
local REG, reads = {}, 0
function GetString(k) reads = reads + 1 return REG[k] or "" end
local ops = 0
function ProjectileOperations(shell) ops = ops + 1 shell.life = shell.life - 1 if shell.life <= 0 then shell.active = false end end
function GrenadeOperations(shell) ops = ops + 1 end
assert(loadstring(chunk, "gunfunctions pieces"))()

local function check(cond, msg) if not cond then error("FAIL: " .. msg, 2) end print("ok  " .. msg) end

projectileHandler = { shellNum = 1, shells = {} }
grenadeHandler = { shellNum = 1, shells = {} }
for i = 1, 200 do projectileHandler.shells[i] = { active = false } end
ammo, shootTimer = 1, 0

-- idle: one scan, then skipped
local scans = 0
WeaponBackgroundTick(1 / 60)
check(projectileHandler.idleScan == 1, "nothing in flight: scan marked idle at shellNum 1")
-- count reads of the shells table to see whether it is scanned
local real = projectileHandler.shells
projectileHandler.shells = setmetatable({}, { __index = function(_, k) scans = scans + 1 return real[k] end,
	__len = function() return #real end })
-- (Lua 5.1 ignores __len on tables; ipairs goes through __index, which is enough to count)
for _ = 1, 10 do WeaponBackgroundTick(1 / 60) end
check(scans == 0, "idle: no slot scanned on the next 10 frames")
projectileHandler.shells = real

-- a shot: slot filled, shellNum advanced -> scanned until it ends
projectileHandler.shells[1] = { active = true, life = 3 }
projectileHandler.shellNum = 2
ops = 0
WeaponBackgroundTick(1 / 60)
check(ops == 1 and projectileHandler.idleScan == nil, "after a shot: scanned, the shell stepped, not idle")
WeaponBackgroundTick(1 / 60)
WeaponBackgroundTick(1 / 60)
check(ops == 3 and not projectileHandler.shells[1].active, "shell stepped every frame until it ended")
check(projectileHandler.idleScan == 2, "idle again once it ended")
WeaponBackgroundTick(1 / 60)
check(ops == 3, "no stepping after it ended")

-- inventory check: one registry pass per frame per gun, fresh on the next frame
REG["inventory.guns.2.item"] = "gun-m870_x"
reads = 0
check(GunInInventory("gun-m870") == true, "gun in slot 2 found")
local first = reads
check(GunInInventory("gun-m870") == true and reads == first, "second ask in the same frame: no registry read")
REG["inventory.guns.2.item"] = ""
check(GunInInventory("gun-m870") == true, "same frame: the frame's answer")
T = T + 1 / 60
check(GunInInventory("gun-m870") == false, "next frame: read again (gun gone)")
check(GunInInventory("gun-ak47") == false, "another gun id has its own answer")

print("all gun idle tests passed")

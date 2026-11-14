-- Mock test for Phase 3 batch A (small world-prop scripts). Run from the repo root with Lua 5.1:
--   lua5.1 tools/porting/tests/test_props.lua
dofile("tools/porting/tests/mockengine.lua")

local function check(cond, msg) if not cond then error("FAIL: " .. msg, 2) end print("ok  " .. msg) end
local function run(env, n)
	if env.server.init then env.server.init() end
	for i = 1, n or 60 do
		env.T = env.T + 1/60
		if env.server.update then env.server.update(1/60) end
		if env.server.tick then env.server.tick(1/60) end
	end
end
local function twoPlayers(env, p2pos)
	env.PLAYERS = { [1] = { pos = {100,0,0}, health = 1 }, [2] = { pos = p2pos, health = 1 } }
	env.ORDER = { 1, 2 }
end

-- plain world scripts: run without errors or client-only calls
for _, f in ipairs({ "world/Debri.lua", "world/parachute.lua", "world/engineprops.lua", "world/simplerotate.lua",
                     "vehicles/aircraft/heliCrashSmoke.lua" }) do
	local env = MockEngine.load(f)
	run(env, 30)
	check(next(env.violations) == nil and env.client.tick == nil, f .. ": server only, no client-only calls")
end
local env = MockEngine.load("world/parachute.lua")
run(env, 10)
check(not env.calls.DebugPrint, "parachute: no DebugPrint spam")

-- warehouse roof: any player inside the trigger
env = MockEngine.load("world/WarehouseCollapse.lua")
twoPlayers(env, {5,0,0})
env.def("IsPointInTrigger", function(t, pos) return pos[1] == 5 end)
run(env, 2)
check(env.Triggered == true, "warehouse: player 2 (not the host) triggers the collapse roll")

-- sleeping NPC: wakes for player 2 standing close
env = MockEngine.load("npcs/GoreNPCs/scripts/other/SleepingRagdoll.lua")
twoPlayers(env, {2,0,0})
env.def("FindBody", function() return 5 end)
env.def("GetTagValue", function() return "MOD/prefabs/x" end)
env.def("GetBodyTransform", function() return env.Transform({0,0,0}) end)
env.def("InputDown", function() return false end)
run(env, 400)
check((env.calls.Spawn or 0) == 1 and next(env.violations) == nil, "sleeping NPC: wakes (spawns the awake NPC) once for player 2")
env = MockEngine.load("npcs/GoreNPCs/scripts/other/SleepingRagdoll.lua")
twoPlayers(env, {2,0,0})
env.def("FindBody", function() return 5 end)
env.def("GetTagValue", function() return "MOD/prefabs/x" end)
env.def("GetBodyTransform", function() return env.Transform({0,0,0}) end)
env.def("InputDown", function(k, p) return k == "crouch" and p == 2 end)
run(env, 400)
check((env.calls.Spawn or 0) == 0, "sleeping NPC: stays asleep while the close player crouches")

-- shop trader: looks at the nearest player; killing it halves the nearest player's money
env = MockEngine.load("npcs/GoreNPCs/scripts/other/StandingRagdoll.lua")
twoPlayers(env, {3,0,0})
env.def("FindShapes", function(tag) if tag == "bodypart" then return {9} end return {} end)
env.def("FindBody", function() return 7 end)
env.def("GetBodyTransform", function() return env.Transform({0,0,0}) end)
local broken = false
env.def("IsShapeBroken", function() return broken end)
run(env, 5)
check(next(env.violations) == nil and (env.calls.ConstrainOrientation or 0) > 0, "trader: head follows the nearest player on the server")
broken = true
env.server.tick(1/60)
check(#env.sent == 1 and env.sent[1].to == 2 and env.sent[1].fn == "client.halveMoney", "trader killed: nearest player (2) loses money")
env.side = "client" env.LOCAL = 2 env.R["savegame.mod.player.money"] = 100
env.client.halveMoney(2)
check(env.R["savegame.mod.player.money"] == 50, "client.halveMoney halves the local savegame money")
env.LOCAL = 1 env.R["savegame.mod.player.money"] = 100
env.client.halveMoney(2)
check(env.R["savegame.mod.player.money"] == 100, "other players keep their money")

-- shrine: player 2 prays
env = MockEngine.load("world/Binge.lua")
twoPlayers(env, {3,0,0})
env.def("FindShape", function() return 4 end)
env.def("IsShapeBroken", function() return false end)
env.def("InputPressed", function(k, p) return k == "interact" and p == 2 end)
env.def("GetPlayerInteractShape", function(p) return p == 2 and 4 or 0 end)
run(env, 3)
check((env.calls.Spawn or 0) == 1 and env.sent[1] and env.sent[1].to == 0 and env.sent[1].fn == "client.bingeSound",
	"shrine: player 2 prays once, gift spawned, sound on every client")

-- death camera (client only)
env = MockEngine.load("player/HealthSystem/launchragdoll.lua")
env.side = "client"
env.def("FindBody", function() return 8 end)
env.def("GetBodyTransform", function() return env.Transform({0,1,0}) end)
env.PLAYERS[1].health = 0
env.client.init()
env.client.tick(1/60) env.client.tick(1/60)
check((env.calls.SetCameraTransform or 0) >= 1 and next(env.violations) == nil and env.server.tick == nil, "death camera: own ragdoll followed on the client")
env.PLAYERS[1].health = 1
env.client.tick(1/60)
local n = env.calls.SetCameraTransform
env.client.tick(1/60)
check(env.calls.SetCameraTransform == n, "death camera: stops when alive again")
env = MockEngine.load("player/HealthSystem/launchragdoll.lua")
env.side = "client"
env.def("FindBody", function() return 8 end)
env.def("GetBodyTransform", function() return env.Transform({30,1,0}) end) -- someone else's ragdoll, 30 m away
env.PLAYERS[1].health = 0
env.client.init()
for i = 1, 5 do env.client.tick(1/60) end
check(not env.calls.SetCameraTransform, "death camera: another player's ragdoll is ignored")

-- RPG rocket (server): fuse arms when ANY player is within 1.2 m, explodes once on impact
env = MockEngine.load("weapons/guns/grenade.lua")
twoPlayers(env, {1,0,0}) -- host at 100 m, player 2 at 1 m
env.def("FindShape", function() return 20 end)
env.def("GetShapeBody", function() return 21 end)
env.def("GetBodyVelocity", function() return {60,0,0} end)
env.def("HasKey", function() return false end)
local hitNow = false
env.def("QueryRaycast", function() return hitNow, 0.5, {0,1,0}, 22 end)
env.server.init()
for i = 1, 10 do env.server.tick(1/60) end
check(env.warhead_primed == true and next(env.violations) == nil, "rocket: fuse armed near player 2 (not the host), server only")
check(not env.calls.Explosion, "rocket: no explosion before impact")
hitNow = true
env.server.tick(1/60) env.server.tick(1/60)
check(env.calls.Explosion == 1 and env.exploded and (env.calls.Delete or 0) >= 1, "rocket: explodes once on impact and removes itself")

-- close range (2026-11-07): wall 1.5 m ahead; physics bounces the rocket back before v1's 0.05 s start-up
env = MockEngine.load("weapons/guns/grenade.lua")
twoPlayers(env, {-50,0,0})
env.def("FindShape", function() return 20 end)
env.def("GetShapeBody", function() return 21 end)
env.def("HasKey", function() return false end)
local rpos, rvel = {0,0,0}, {120,0,0}
env.def("GetBodyTransform", function() return env.Transform(env.VecCopy(rpos)) end)
env.def("GetShapeWorldTransform", function() return env.Transform(env.VecCopy(rpos)) end)
env.def("GetBodyVelocity", function() return env.VecCopy(rvel) end)
env.def("QueryRaycast", function(o, d, len) -- wall plane at x = 1.5
	if d[1] > 0 and o[1] < 1.5 and o[1] + d[1] * len >= 1.5 then return true, (1.5 - o[1]) / d[1], {-1,0,0}, 22 end
	return false, 0
end)
local boomPos
env.def("Explosion", function(pos) boomPos = pos end)
env.server.init()
env.server.tick(1/60)                       -- launch: rocket at x = 0, 120 m/s
check(not env.calls.Explosion, "rocket close range: nothing on the first tick")
rpos, rvel = {1.2,0,0}, {-20,0,0}           -- physics: hit the wall and bounced back
env.server.tick(1/60)
check(env.calls.Explosion == 1 and env.exploded, "rocket close range: bounced off a wall 1.5 m away -> explodes (v1 did not)")
check(boomPos and math.abs(boomPos[1] - 1.5) < 1e-6, "rocket close range: explodes at the wall, not where it bounced to")

-- loaded rocket type (2026-11-07): RPG.lua reports it right before the spawn; read once, then cleared
env = MockEngine.load("weapons/guns/grenade.lua")
env.def("HasKey", function() return false end)
env.R["level.rpg.next_rocket"] = "rocket3"
env.server.init()
check(env.weapon.explosionSize == 2 and env.R["level.rpg.next_rocket"] == "", "rocket type: the loaded PG-7VA (rocket3) applies, key cleared")
env = MockEngine.load("weapons/guns/grenade.lua")
env.def("HasKey", function() return false end)
env.server.init()
check(math.abs(env.weapon.explosionSize - 0.6) < 1e-9, "rocket type: without a report (NPC rockets) the default PG-7V")

-- npc blast damage (2026-11-07): the shield (bosses) absorbs first, the rest hurts health (v1: shield only)
local function blast(shield, strength, dist)
	local e = MockEngine.load("npcs/GoreNPCs/scripts/components/goreai_health.lua")
	e.config = { goreai = { invincible = false } }
	e.AabbGetBodyCenterPos = function() return {0,0,0} end
	e.AabbGetBodyCenterBottomPos = e.AabbGetBodyCenterPos
	e.VecDist = function(a, b) return e.VecLength(e.VecSub(a, b)) end
	e.clamp = function(v, a, b) return math.max(a, math.min(b, v)) end
	e.def("QueryClosestFire", function() return false end)
	e.TimerRunTime = function() end e.TimerConsumed = function() return false end e.TimerCreateSeconds = function() return {} end
	e.GoreAI_ResolvePlayer = function() return 1 end
	e.Explosions = { { pos = {dist,0,0}, strength = strength } }
	local npc = { Torso = 5, bodyparts = {}, shield = { value = shield, max = shield, tags = { pdamage = "a.", pdamage_npc = "b." } },
		health_damage_taken = 0, health_damage_taken_total = 0 }
	e.npc_process_shield(npc)
	return npc
end
local npc = blast(0, 0.6, 0)
check(math.abs(npc.health_damage_taken_total - 120) < 1e-6, "npc blast: ordinary npc, direct PG-7V hit -> 120 health damage (v1: 0)")
npc = blast(90, 0.6, 0)
check(npc.shield.value == 0 and math.abs(npc.health_damage_taken_total - 30) < 1e-6, "npc blast: boss shield 90 absorbs first, 30 to health")
npc = blast(0, 0.6, 20)
check(npc.health_damage_taken_total == 0, "npc blast: beyond 15 m no damage")

-- vehicle / helicopter crew ragdolls (batch D, 2026-11-07): server only; a broken body part -> full ragdoll, once
for _, f in ipairs({ "npcs/GoreRagdolls2/scripts/fakegore.lua", "vehicles/aircraft/AS350/Gore Ragdolls 2/scripts/fakegore.lua",
                     "vehicles/aircraft/Mil-Mi-35P-Hind/Gore Ragdolls 2/scripts/fakegore.lua" }) do
	local e = MockEngine.load(f)
	local broken = false
	e.def("FindShape", function() return 31 end)
	e.def("FindShapes", function(tag) if tag == "bodypart" then return { 31, 32 } end return { 31, 32, 33 } end)
	e.def("IsHandleValid", function(h) return h == 31 end)
	e.def("IsShapeBroken", function(s) return broken and s == 32 end)
	e.def("GetTagValue", function() return "Soldier5Sitting" end)
	local spawned
	e.def("Spawn", function(path) spawned = path return {} end)
	run(e, 400)
	check(not spawned and next(e.violations) == nil and e.client.tick == nil, f .. ": crew sits (server only)")
	broken = true
	e.server.tick(1/60) e.server.tick(1/60)
	check(e.calls.Spawn == 1 and spawned:match("Sitters/Soldier5Sitting%.xml$") and (e.calls.Delete or 0) >= 3,
		f .. ": broken body part -> sitter removed, full ragdoll spawned once")
end

-- missing bullet type (2026-11-07, seen with unlimited ammo on): FireRound used gunperks[perk]["nil"] -> error per shot
do
	local e = MockEngine.load("weapons/guns/gunperks.lua")
	for perk, typ in pairs(e.GunPerkDefaultType) do
		check(e.gunperks[perk] and e.gunperks[perk][typ] ~= nil, "gun perks: default round " .. perk .. " " .. typ .. " exists")
	end
	check(e.GunPerkFor("762x51", "nil") == e.gunperks["762x51"]["HP"], "gun perks: round without a type fires as the calibre default (7.62x51 HP)")
	check(e.GunPerkFor("762x51", "FMJ") == e.gunperks["762x51"]["FMJ"], "gun perks: a known type is used as before")
end

-- npc death with a gun that has no loot info (2026-11-07, horde strips "Loot" tags): v1 errored in math.random
local function die(loot)
	local e = MockEngine.load("npcs/GoreNPCs/scripts/components/goreai_health.lua")
	local tags = { Loot = loot }
	e.def("GetTagValue", function(h, t) return tags[t] or "" end)
	e.def("SetTag", function(h, t, v) if h == 40 then tags[t] = v end end)
	e.def("GetBodyShapes", function() return {} end)
	e.Settings = { game = { blood_and_gore = { value = false } } }
	e.TimerConsumed = function() return true end
	e.GoreAI_ClientCall = function() end
	e.GetRandomArrayValue = function() return 0 end
	local npc = { Torso = 5, Head = 6, AllBodies = {}, Gun = { body = 40, ammo_path = "x.xml" },
		voice = { playTimestamp = -1 }, ai = { teams = { team = "mil" }, sitting = {} }, boss = {} }
	e.TableRemoveUniqueValue = function() end
	e.LootsPath = "MOD/items/Loots/"
	local ok, err = pcall(e.npc_die, npc)
	return ok, err, tags.Loot
end
local ok, err = die(nil)
check(ok, "npc death: gun without loot info (horde) does not error" .. (ok and "" or (": " .. tostring(err))))
local ok2, err2, loot = die("gun-ak74_x_mag_name_30_30")
local n = tonumber((loot or ""):match("^[^_]*_[^_]*_[^_]*_[^_]*_(%d+)_30$") or "")
check(ok2 and n and n >= 0 and n <= 30, "npc death: dropped gun's ammo still randomized (0-30)" .. (ok2 and "" or (": " .. tostring(err2))))

print("all props tests passed")

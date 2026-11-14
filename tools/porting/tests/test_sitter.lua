-- Mock test: crew sitter ragdoll (vehicles/aircraft/AS350/Gore Ragdolls 2/scripts/gorefunctions.lua) and the minivan's
-- vehicles/cars/minivan1/autobreakRemover.lua, both v2 since 2026-11-13.
-- Run from the repo root with Lua 5.1:  lua5.1 tools/porting/tests/test_sitter.lua
dofile("tools/porting/tests/mockengine.lua")

local function check(cond, msg) if not cond then error("FAIL: " .. msg, 2) end print("ok  " .. msg) end

local PATH = "vehicles/aircraft/AS350/Gore Ragdolls 2/scripts/gorefunctions.lua"
local e = MockEngine.load(PATH, { preload = MockEngine.includes(PATH) })
e.PLAYERS = { [1] = { pos = { 0, 0, 0 }, health = 1 }, [2] = { pos = { 2, 0, 0 }, health = 1 } }
e.ORDER = { 1, 2 }
local S = { MASS = { [10] = 20, [11] = 5 }, BROKEN = {}, PRESSED = { [1] = {}, [2] = {} }, SPAWN = {}, TAGS = {} }
e.def("FindBody", function(n) return n == "Torso" and 10 or 11 end)
e.def("FindBodies", function(t) return t == "bodypart" and { 10, 11 } or { 10, 11 } end)
e.def("GetBodyMass", function(b) return S.MASS[b] or 5 end)
e.def("IsBodyBroken", function(b) return S.BROKEN[b] == true end)
e.def("HasTag", function(h, t) return (h == 10 and t == "Torso") or (h == 11 and t == "LLLEG") end)
e.def("SetTag", function(h, t, v) S.TAGS[#S.TAGS + 1] = { h, t } end)
e.def("IsJointBroken", function() return false end)
e.def("IsPointInWater", function() return false end)
e.def("HasFile", function() return false end) -- the original's gore paths do not exist
e.def("Spawn", function(p) S.SPAWN[#S.SPAWN + 1] = p return {} end)
e.def("InputPressed", function(k, p) return p and S.PRESSED[p] and S.PRESSED[p][k] or false end)
e.def("GetPlayerCameraTransform", function(p) return e.Transform(p == 2 and e.Vec(0, 0, 1) or e.Vec(50, 0, 0)) end)
e.def("QueryRaycast", function() return true, 0.5 end)
e.def("GetBodyTransform", function() return e.Transform(e.Vec(0, 0, 0)) end)
e.def("GetQuatEuler", function() return 0, 0, 0 end)
e.QuatEuler = function() return e.Quat() end
e.R["savegame.mod.gore_kill"] = "k"

e.server.init()
check(#S.SPAWN == 0, "init: the original's missing UI / FX prefabs are not spawned (HasFile)")
e.server.update(1 / 60)
check(next(e.violations) == nil, "no client-only calls on the server")

-- the leg loses voxels: it bleeds, and the clients get its intensity
S.BROKEN[11], S.MASS[11] = true, 3
e.server.update(1 / 60)
check((e.shared["bl11"] or 0) > 0 and (e.shared["bl10"] or 0) == 0, "broken leg bleeds: intensity shared for that part only")

-- P from player 2, aiming at the torso (within 3 m): sits; player 1 aims elsewhere: nothing
S.PRESSED[1].P = true
e.server.update(1 / 60)
S.PRESSED[1].P = false
check(not e.sitting, "player 1's P, aiming 50 m away: no change")
S.PRESSED[2].P = true
e.server.update(1 / 60)
S.PRESSED[2].P = false
check(e.sitting == true, "player 2's P aiming at it: sits (v1: only the one player)")

-- kill key twice (any player): stops; bleeding cleared for the clients
S.PRESSED[2].k = true
e.server.update(1 / 60)
check(e.shared.warn == true, "kill key once: warning shared")
S.PRESSED[2].k = false
e.server.update(1 / 60)
S.PRESSED[1].k = true
e.server.update(1 / 60)
S.PRESSED[1].k = false
check(e.entirelystop == true and e.shared.warn == false, "kill key again: ragdoll script stops")
check(e.shared["bl11"] == 0, "stopped: no more bleeding on the clients")

-- client: particles for a bleeding part, UI drawn, no server-only calls
e.side = "client"
e.client.init()
e.shared["bl11"] = 10
e.calls.SpawnParticle = 0
e.client.update(1 / 60)
check((e.calls.SpawnParticle or 0) > 0, "client: bleeding particles")
e.client.tick(1 / 60)
e.client.draw(1 / 60)
check(next(e.violations) == nil, "no server-only calls on the client")

-- minivan helper
local M = "vehicles/cars/minivan1/autobreakRemover.lua"
local m = MockEngine.load(M)
local removed = 0
m.def("FindBodies", function() return { 1, 2 } end)
m.def("RemoveTag", function(b, t) if t == "autobreak" then removed = removed + 1 end end)
m.server.init()
m.server.tick(1 / 60)
check(removed == 2 and next(m.violations) == nil, "minivan: autobreak tags removed on the server")
print("all sitter tests passed")

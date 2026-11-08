-- Mock test for Vehicles/bus/jet.lua (JetBus jet: Shift boost, throttle bar).
-- Run from the repo root with Lua 5.1:  lua5.1 tools/porting/tests/test_jet.lua
dofile("tools/porting/tests/mockengine.lua")

local function check(cond, msg) if not cond then error("FAIL: " .. msg, 2) end print("ok  " .. msg) end
local PATH = "Vehicles/bus/jet.lua"

local env = MockEngine.load(PATH, { preload = MockEngine.includes(PATH) })
env.side = "server"
env.PLAYERS = { [1] = { pos = { 0, 0, 0 }, health = 1 }, [2] = { pos = { 5, 0, 0 }, health = 1 } }
env.ORDER = { 1, 2 }
local S = { VEH = {}, DRV = {}, DOWN = { [1] = {}, [2] = {} }, IMPULSE = 0 }
env.def("FindVehicle", function() return 9 end)
env.def("FindShape", function(tag) return tag == "jet" and 30 or 0 end)
env.def("FindJoint", function() return 31 end)
env.def("FindTrigger", function() return 32 end)
env.def("GetTriggerTransform", function() return env.Transform({ 0, 0, 0 }) end)
env.def("GetShapeVoxelCount", function() return 1000 end)
env.def("GetShapeWorldTransform", function() return env.Transform({ 0, 0, 0 }) end)
env.def("GetShapeBounds", function() return { 0, 0, 0 }, { 2, 2, 2 } end)
env.def("GetVehicleHealth", function() return 1 end)
env.def("GetPlayerVehicle", function(p) return S.VEH[p] or 0 end)
env.def("IsPlayerVehicleDriver", function(v, p) return S.VEH[p] == v and S.DRV[p] == true end)
env.def("InputDown", function(name, p) assert(p and p ~= 0, "InputDown without player id") return S.DOWN[p][name] or false end)
env.def("ApplyBodyImpulse", function(b, pos, imp) S.IMPULSE = S.IMPULSE + 1 end)
env.def("IsBodyBroken", function() return false end)
env.def("GetJointOtherShape", function() return 33 end)

env.server.init()
check(env.lastJetHealth == 1, "init: jet health known from the start")

-- passenger 1 holds Shift, nobody drives: jet off
S.VEH[1] = 9
S.DOWN[1].shift = true
env.server.tick(1 / 60)
check(env.jetTargetThrottle == 0, "a passenger's Shift does not boost (no driver: jet off)")

-- player 2 (not the host) drives: idle, then Shift = full target
S.VEH[2], S.DRV[2] = 9, true
env.server.tick(1 / 60)
check(env.jetTargetThrottle == 0.1, "driver without Shift: idle 0.1")
S.DOWN[2].shift = true
for i = 1, 60 do env.server.tick(1 / 60) end
check(env.jetTargetThrottle == 1 and env.jetThrottle > 0.1, "player 2's Shift: target 1, throttle ramping up")
check(env.shared.jetThrottle == env.jetThrottle and env.shared.jetTarget == 1, "throttle shared for the clients' bar")
env.server.update(1 / 60)
check(S.IMPULSE == 1, "server.update pushes the bus")
check(next(env.violations) == nil, "no client-only calls on the server")

-- client: bar drawn for a player in the bus, from shared values
env.side = "client"
local RECTS = 0
env.def("UiRect", function() RECTS = RECTS + 1 end)
env.def("GetPlayerVehicle", function() return 9 end)
env.client.init()
env.client.draw(1 / 60)
check(RECTS == 2, "client: throttle bar drawn (current + target marks)")
check(next(env.violations) == nil, "no server-only calls on the client")
print("all jet tests passed")

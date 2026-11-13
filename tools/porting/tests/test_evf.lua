-- Mock test for the GAZ-24 scripts: EVF.lua (doors / hood / trunk latches, steering wheel, door beep), lampa.lua
-- (interior light switch), radio_car2.lua (militia siren switch), policelightsF.lua (police lights).
-- Run from the repo root with Lua 5.1:  lua5.1 tools/porting/tests/test_evf.lua
dofile("tools/porting/tests/mockengine.lua")

local function check(cond, msg) if not cond then error("FAIL: " .. msg, 2) end print("ok  " .. msg) end

local env = MockEngine.load("Vehicles/GAZ-24 (1968)/EVF.lua", { preload = MockEngine.includes("Vehicles/GAZ-24 (1968)/EVF.lua") })
env.side = "server"
env.PLAYERS = { [1] = { pos = { 0, 0, 0 }, health = 1 }, [2] = { pos = { 5, 0, 0 }, health = 1 } }
env.ORDER = { 1, 2 }
-- shapes: door 11 (joint 21), hood 17 (joint 27), trunk 18 (joint 28), steer 19 (joint 29); vehicle 9
local S = { VEH = {}, DRV = {}, DOWN = { [1] = {}, [2] = {} }, GRAB = {}, MOVE = { [21] = 0.3, [27] = 0, [28] = 0 },
	MOTOR = {}, TARGET = {}, LOOPS = 0, SOUNDS = 0 }
env.def("GetBoolParam", function(name) return name == "doornotification" end)
env.def("GetStringParam", function() return "" end)
env.def("FindShapes", function(tag) return tag == "door" and { 11 } or {} end)
env.def("FindShape", function(tag) return ({ hood = 17, trunk = 18, steer = 19 })[tag] or 0 end)
env.def("FindVehicle", function(tag) return tag == "vehicle" and 9 or 0 end)
env.def("IsHandleValid", function(h) return h ~= nil and h ~= 0 end)
env.def("GetShapeJoints", function(s) return ({ [11] = { 21 }, [17] = { 27 }, [18] = { 28 }, [19] = { 29 } })[s] or {} end)
env.def("GetShapeBody", function(s) return s + 100 end)
env.def("IsJointBroken", function() return false end)
env.def("GetJointMovement", function(j) return S.MOVE[j] or 0 end)
env.def("GetJointLimits", function() return 0, 80 end)
env.def("GetShapeWorldTransform", function() return env.Transform({ 0, 0, 0 }) end)
env.def("GetVehicleTransform", function() return env.Transform({ 0, 0, 0 }) end)
env.def("GetPlayerGrabShape", function(p) assert(p, "grab without player id") return S.GRAB[p] or 0 end)
env.def("GetPlayerGrabBody", function(p) assert(p, "grab without player id") return 0 end)
env.def("GetPlayerVehicle", function(p) return S.VEH[p] or 0 end)
env.def("IsPlayerVehicleDriver", function(v, p) return S.VEH[p] == v and S.DRV[p] == true end)
STEER = 0
env.def("GetVehicleSteering", function() return STEER end)
env.def("InputDown", function(name, p) assert(p and p ~= 0, "InputDown without player id") return S.DOWN[p][name] or false end)
env.def("SetJointMotor", function(j, vel, str) S.MOTOR[j] = { vel, str } end)
env.def("SetJointMotorTarget", function(j, target) S.TARGET[j] = target end)
env.def("PlaySound", function() S.SOUNDS = S.SOUNDS + 1 end)
env.def("PlayLoop", function() S.LOOPS = S.LOOPS + 1 end)

env.server.init()
check(env.d1 == 11 and env.d1_j == 21 and env.steer_j == 29, "init: door, its joint and the steering joint found")

-- player 2 (not the host) holds the door: motor released
S.GRAB[2] = 11
env.server.update(1 / 60)
check(S.MOTOR[21] and S.MOTOR[21][2] == 0, "door: player 2 grabbing it releases the latch motor")
-- let go and nearly shut: latched
S.GRAB[2] = nil
S.MOVE[21] = 0.02
env.server.update(1 / 60)
check(S.TARGET[21] == 0, "door: let go and nearly shut = latched (target 0)")

-- steering: passenger 1 presses left (ignored), driver 2 presses right
S.VEH[1], S.VEH[2], S.DRV[2] = 9, 9, true
S.DOWN[1].left = true
env.server.update(1 / 60)
check(S.TARGET[29] == 0, "steering: a passenger's left is ignored")
-- the wheel follows GetVehicleSteering x 180 (the hands' rotation); "left" turns it positive as in v1
STEER = 0
S.DOWN[2].left = true
STEER = 0.5 -- this engine build: steering positive for left
env.server.update(1 / 60)
check(S.TARGET[29] == 90, "steering: the non-host driver's left turns the wheel +steering x 180 (0.5 -> 90)")
S.DOWN[2].left = false
STEER = -0.25
env.server.update(1 / 60)
check(S.TARGET[29] == -45, "steering: after calibration, right (-0.25) -> -45")
S.VEH[2], S.DRV[2] = nil, nil
S.VEH[1] = nil
env.server.update(1 / 60)
check(S.TARGET[29] == 0, "steering: empty car = wheel centred")

-- door beep: a door marked open and someone (a passenger) inside
env.played[1].open = true
S.VEH[1] = 9
local before = S.LOOPS
env.server.update(1 / 60)
check(S.LOOPS > before, "beep: door open with a player inside plays the loop")
check(next(env.violations) == nil, "no client-only calls on the server")

-- the GAZ-24's other scripts: interior light switch, militia siren switch, police lights
local function gaz(file)
	local e = MockEngine.load("Vehicles/GAZ-24 (1968)/" .. file, { preload = MockEngine.includes("Vehicles/GAZ-24 (1968)/" .. file) })
	e.side = "server"
	e.PLAYERS = { [1] = { pos = { 0, 0, 0 }, health = 1 }, [2] = { pos = { 5, 0, 0 }, health = 1 } }
	e.ORDER = { 1, 2 }
	local G = { TAG = {}, PRESS = { [1] = {}, [2] = {} }, AIM = {}, VEH = {}, EMIT = {}, SND = {} }
	e.def("SetTag", function(h, tag, v) G.TAG[h] = G.TAG[h] or {} G.TAG[h][tag] = v end)
	e.def("GetTagValue", function(h, tag) return G.TAG[h] and G.TAG[h][tag] or "" end)
	e.def("InputPressed", function(name, pl) assert(pl and pl ~= 0, "InputPressed without player id") return G.PRESS[pl][name] or false end)
	e.def("GetPlayerInteractShape", function(pl) return G.AIM[pl] or 0 end)
	e.def("GetPlayerVehicle", function(pl) return G.VEH[pl] or 0 end)
	e.def("GetShapeWorldTransform", function() return e.Transform({ 1, 2, 3 }) end)
	e.def("PlaySound", function(snd, pos) G.SND[#G.SND + 1] = pos end)
	e.def("SetShapeEmissiveScale", function(s, v) G.EMIT[s] = v end)
	return e, G
end

local e, G = gaz("lampa.lua")
local LIGHT = nil
e.def("FindShape", function(tag) return tag == "switch" and 40 or 0 end)
e.def("FindLight", function(tag) return tag == "lamp" and 41 or 0 end)
e.def("SetLightEnabled", function(l, on) LIGHT = on end)
e.server.init()
G.AIM[2], G.PRESS[2].interact = 40, true
e.server.tick(1 / 60)
check(LIGHT == true and G.TAG[40].interact == "Turn off", "light switch: player 2 turns the interior light on")
check(G.SND[1] ~= nil, "light switch: the click plays at the switch (has a position)")
check(next(e.violations) == nil, "light switch: no client-only calls on the server")

e, G = gaz("radio_car2.lua")
e.def("FindShape", function(tag) return tag == "radio" and 50 or 0 end)
e.def("IsShapeBroken", function() return false end)
local LOOPS = 0
e.def("PlayLoop", function() LOOPS = LOOPS + 1 end)
e.server.init()
G.AIM[2], G.PRESS[2].interact = 50, true
e.server.tick(1 / 60)
check(G.EMIT[50] == 1 and LOOPS == 1, "siren switch: player 2 switches it on, the loop plays")
check(next(e.violations) == nil, "siren switch: no client-only calls on the server")

e, G = gaz("policelightsF.lua")
e.def("FindShapes", function(tag) return tag == "blink" and { 60 } or {} end)
e.def("FindVehicle", function() return 9 end)
e.server.init()
G.TAG[60] = { blink = "10" }
G.PRESS[1].f = true -- on foot: ignored
e.server.tick(1 / 60)
check(e.pLights == false, "police lights: F on foot does nothing")
G.PRESS[1].f, G.VEH[2], G.PRESS[2].f = false, 9, true -- player 2 in the car
e.server.tick(1 / 60)
check(e.pLights == true and G.EMIT[60] ~= nil, "police lights: player 2 in the car toggles them on")
check(next(e.violations) == nil, "police lights: no client-only calls on the server")
print("all GAZ-24 script tests passed")

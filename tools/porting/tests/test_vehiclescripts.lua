-- Mock test for the small vehicle scripts in Vehicles/!library/scripts: drive, drivetrain, steer (driver input
-- only) and toggleAction (any player toggles). dash.lua is a <screen> script: those stay v1 (TECHNICAL_REFERENCE §3).
-- Run from the repo root with Lua 5.1:  lua5.1 tools/porting/tests/test_vehiclescripts.lua
dofile("tools/porting/tests/mockengine.lua")

local function check(cond, msg) if not cond then error("FAIL: " .. msg, 2) end print("ok  " .. msg) end
local DIR = "Vehicles/!library/scripts/"

-- two players: 1 = host, 2 = client. VEH[p] = vehicle, DRV[p] = true when driving it, KEYS[p][input] = value
local function setup(file)
	local env = MockEngine.load(DIR .. file)
	env.side = "server"
	env.PLAYERS = { [1] = { pos = { 0, 0, 0 }, health = 1 }, [2] = { pos = { 5, 0, 0 }, health = 1 } }
	env.ORDER = { 1, 2 }
	local S = { VEH = {}, DRV = {}, KEYS = { [1] = {}, [2] = {} }, PRESSED = { [1] = {}, [2] = {} }, MOTOR = {}, TARGET = {} }
	env.def("FindVehicle", function() return 9 end)
	env.def("GetVehicleHealth", function() return 1 end)
	env.def("GetPlayerVehicle", function(p) return S.VEH[p] or 0 end)
	env.def("IsPlayerVehicleDriver", function(v, p) return S.VEH[p] == v and S.DRV[p] == true end)
	env.def("InputValue", function(name, p) assert(p and p ~= 0, "InputValue without a player id") return S.KEYS[p][name] or 0 end)
	env.def("InputPressed", function(name, p) assert(p and p ~= 0, "InputPressed without a player id") return S.PRESSED[p][name] or false end)
	env.def("SetJointMotor", function(j, vel, str) S.MOTOR[j] = { vel, str } end)
	env.def("SetJointMotorTarget", function(j, target, speed) S.TARGET[j] = target end)
	env.def("GetTagValue", function(h, tag) return S.TAGS and S.TAGS[h] and S.TAGS[h][tag] or "" end)
	return env, S
end

-- drive.lua: player 1 is a passenger pressing "up", player 2 drives pressing "down"
local env, S = setup("drive.lua")
env.def("FindJoints", function(tag) return tag == "drive" and { 51 } or {} end)
env.server.init()
S.VEH[1], S.VEH[2], S.DRV[2] = 9, 9, true
S.KEYS[1].up = 1
S.KEYS[2].down = 1
env.server.tick(1 / 60)
check(S.MOTOR[51][1] == -10 - 20, "drive: the non-host DRIVER's 'down' drives (-30), the passenger's 'up' is ignored")
S.DRV[2] = false
env.server.tick(1 / 60)
check(S.MOTOR[51][1] == 0, "drive: nobody driving = joints stopped (0, as v1)")
check(next(env.violations) == nil, "drive: no client-only calls on the server")

-- drivetrain.lua: joint tag drive=2 scales the throttle
env, S = setup("drivetrain.lua")
env.def("FindJoints", function(tag) return tag == "drive" and { 61 } or {} end)
S.TAGS = { [61] = { drive = "2" } }
env.server.init()
S.VEH[2], S.DRV[2] = 9, true
S.KEYS[2].up = 1
env.server.tick(1 / 60)
check(S.MOTOR[61][1] == 2, "drivetrain: driver throttle x the joint's drive tag (2)")

-- steer.lua: the driver's 'right' turns the wheel joint
env, S = setup("steer.lua")
env.def("FindShape", function(tag) return tag == "steer" and 70 or 0 end)
env.def("GetShapeJoints", function() return { 71 } end)
env.def("GetShapeBody", function() return 72 end)
env.def("GetBodyVehicle", function() return 9 end)
S.TAGS = { [70] = { steer = "1" } }
env.server.init()
S.VEH[1] = 9 -- passenger
S.KEYS[1].left = 1
env.server.tick(1 / 60)
check(S.TARGET[71] == 0, "steer: a passenger's input does not steer")
S.VEH[2], S.DRV[2] = 9, true
S.KEYS[2].right = 1
env.server.tick(1 / 60)
check(S.TARGET[71] == 30, "steer: the non-host driver steers (30 x scale)")

-- toggleAction.lua: player 2 (on foot) toggles; anyone in the truck retracts
env, S = setup("toggleAction.lua")
local TAG = {}
env.def("FindShapes", function(tag) return tag == "actionToggle" and { 80 } or {} end)
env.def("GetShapeJoints", function() return { 81 } end)
env.def("HasTag", function(h, tag) return h == 81 and tag == "toggle_joint" end)
env.def("GetJointLimits", function() return 0, 90 end)
env.def("SetTag", function(h, tag, val) TAG[h] = TAG[h] or {} TAG[h][tag] = val end)
env.def("GetTagValue", function(h, tag) return TAG[h] and TAG[h][tag] or "" end)
env.def("GetPlayerInteractShape", function(p) return p == 2 and 80 or 0 end)
env.server.init()
check(TAG[80].interact == "Toggle Action" and S.TARGET[81] == 0, "toggleAction: prompt set, joint starts retracted")
S.PRESSED[2].interact = true
env.server.tick(1 / 60)
check(S.TARGET[81] == 90 and TAG[81].toggle_joint == "deploied", "toggleAction: player 2 (not the host) deploys it")
S.PRESSED[2].interact = false
S.VEH[1] = 9
env.server.tick(1 / 60)
check(S.TARGET[81] == 0 and TAG[81].toggle_joint == "", "toggleAction: a player in the truck retracts it")
check(next(env.violations) == nil, "toggleAction: no client-only calls on the server")

print("all vehicle script tests passed")

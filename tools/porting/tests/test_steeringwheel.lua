-- Mock test for vehicles/SteeringWheel.lua (steering wheels that turn with the vehicle's steering).
-- Run from the repo root with Lua 5.1:  lua5.1 tools/porting/tests/test_steeringwheel.lua
dofile("tools/porting/tests/mockengine.lua")

local function check(cond, msg) if not cond then error("FAIL: " .. msg, 2) end print("ok  " .. msg) end
local PATH = "vehicles/SteeringWheel.lua"

local env = MockEngine.load(PATH)
env.side = "server"
local STEER, SET, AXIS = 0, {}, {}
local SIZE = { 18, 3, 18 }
env.def("GetFloatParam", function(name, default) return default end)
env.def("FindShapes", function(tag) return tag == "steer" and { 31 } or {} end)
env.def("GetShapeSize", function() return SIZE[1], SIZE[2], SIZE[3], 0.025 end)
env.def("GetShapeLocalTransform", function() return env.Transform({ 1, 2, 3 }) end)
env.def("GetShapeBounds", function() return { 10, 10, 10 }, { 12, 14, 16 } end) -- world centre (11, 12, 13)
env.def("GetBodyTransform", function() return env.Transform({ 10, 10, 10 }) end)  -- body origin
env.def("GetShapeBody", function() return 7 end)
env.def("GetBodyVehicle", function(b) return b == 7 and 9 or 0 end)
env.def("IsHandleValid", function(h) return h ~= nil and h ~= 0 end)
env.def("GetVehicleSteering", function(v) return v == 9 and STEER or 0 end)
env.def("QuatRotateVec", function(q, v) return env.VecCopy(v) end) -- identity rotations in this mock
env.def("QuatRotateQuat", function(a, b) return b end)
env.def("QuatAxisAngle", function(axis, deg) AXIS[#AXIS + 1] = { axis, deg } return { 0, 0, 0, 1 } end)
env.def("SetShapeLocalTransform", function(s, t) SET[#SET + 1] = { s, t } end)

env.server.init()
local w = env.Wheels[1]
check(#env.Wheels == 1 and w.vehicle == 9, "finds the steer shape and its vehicle")
check(w.axis[1] == 0 and w.axis[2] == 1 and w.axis[3] == 0, "axis = thinnest voxel dimension (y for 18x3x18)")
check(w.pivot[1] == 1 and w.pivot[2] == 2 and w.pivot[3] == 3, "pivot = bounding-box centre in body space")

env.server.tick(1 / 60)
check(#SET == 0, "straight ahead: shape left alone")

STEER = 0.5
env.server.tick(1 / 60)
check(#SET == 1 and SET[1][1] == 31, "steering: shape transform set")
check(AXIS[#AXIS][2] == 90 and AXIS[#AXIS][1][2] == 1, "turned 90 degrees (0.5 x 180) about the column axis")

env.server.tick(1 / 60)
check(#SET == 1, "same steering: no repeated update")

STEER = 0
env.server.tick(1 / 60)
check(#SET == 2 and AXIS[#AXIS][2] == 0, "back to centre when steering returns to 0 (driver left)")

SIZE = { 2, 9, 9 }
env.server.init()
check(env.Wheels[1].axis[1] == 1, "a wheel modelled thin along x turns about x")
check(next(env.violations) == nil, "server: no client-only calls")

print("all steering wheel tests passed")

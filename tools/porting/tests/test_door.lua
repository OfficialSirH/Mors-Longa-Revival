-- Mock test for Vehicles/!library/scripts/door.lua (vehicle doors shut while a player is inside).
-- Run from the repo root with Lua 5.1:  lua5.1 tools/porting/tests/test_door.lua
dofile("tools/porting/tests/mockengine.lua")

local function check(cond, msg) if not cond then error("FAIL: " .. msg, 2) end print("ok  " .. msg) end
local PATH = "Vehicles/!library/scripts/door.lua"

local function run(vehicle, joints)
	local env = MockEngine.load(PATH)
	env.side = "server"
	env.PLAYERS = { [1] = { pos = { 0, 0, 0 }, health = 1 }, [2] = { pos = { 5, 0, 0 }, health = 1 } }
	env.ORDER = { 1, 2 }
	local IN, SET = {}, {}
	env.def("FindVehicle", function(tag) return tag == "Door" and vehicle or 0 end)
	env.def("FindJoints", function(tag) return tag == "door" and joints or {} end)
	env.def("GetPlayerVehicle", function(p) return IN[p] or 0 end)
	env.def("SetJointMotorTarget", function(j, target, speed, strength) SET[#SET + 1] = { j, target, speed, strength } end)
	env.server.init()
	return env, IN, SET
end

-- nobody inside: doors released (strength 0)
local env, IN, SET = run(9, { 41, 42 })
env.server.tick(1 / 60)
check(#SET == 2 and SET[1][2] == 90 and SET[1][4] == 0, "empty vehicle: both doors free (target 90, strength 0)")

-- the second (non-host) player gets in: doors shut
for k in pairs(SET) do SET[k] = nil end
IN[2] = 9
env.server.tick(1 / 60)
check(#SET == 2 and SET[1][2] == 0 and SET[1][3] == 3 and SET[2][2] == 0, "player 2 inside: both doors motored shut")

-- a player in another vehicle does not count
for k in pairs(SET) do SET[k] = nil end
IN[2] = 77
env.server.tick(1 / 60)
check(SET[1][2] == 90, "player in a different vehicle: doors free")
check(next(env.violations) == nil, "no client-only calls on the server")

-- no vehicle found: never 'inside' (v1 compared 0 with a player on foot)
env, IN, SET = run(0, { 41 })
env.server.tick(1 / 60)
check(SET[1][2] == 90, "no Door vehicle: doors stay free with players on foot")

-- no door joints (chase cars): nothing to do
env, IN, SET = run(9, {})
IN[1] = 9
env.server.tick(1 / 60)
check(#SET == 0, "no door joints: no joint calls")
print("all door tests passed")

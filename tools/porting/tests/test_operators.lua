-- Mock-engine smoke test for the v2 enemy/convoy car scripts (Phase 3). Run from the repo root with Lua 5.1:
--   lua5.1 tools/porting/tests/test_operators.lua
-- Every API function from Teardown's script_defs.lua is stubbed (returns 0); a few are given behaviour.
-- Runs server.init + 120 ticks/updates per script with two players and checks: the car drives toward the
-- NEAREST player, no client-only function is called on the server, and queueRemoval makes the script idle.

local DEFS = "C:/Program Files (x86)/Steam/steamapps/common/Teardown/data/script_defs.lua"
local CLIENT_ONLY = {}
for n in ("InputClear InputResetOnTransition SetPlayerCharacter SetPlayerCameraOffsetTransform SetToolHandPoseLocalTransform " ..
	"SetToolTransform SetToolAllowedZoom SetToolTransformOverride SetToolOffset SetPlayerRigTags SetSoundLoopUser PlaySoundForUser " ..
	"AddMapMarker SelectedMapMarker GetCameraTransform SetCameraTransform RequestFirstPerson RequestThirdPerson " ..
	"SetCameraOffsetTransform AttachCameraTo SetPivotClipBody ShakeCamera SetCameraFov SetCameraDof DisableMotionBlur " ..
	"SetLowHealthBlurThreshold"):gmatch("%S+") do CLIENT_ONLY[n] = true end

local apiNames = {}
for line in io.lines(DEFS) do
	local n = line:match("^function ([A-Z][%w_]*)%(")
	if n then apiNames[#apiNames + 1] = n end
end
assert(#apiNames > 500, "script_defs.lua not found or unreadable")

local function check(cond, msg) if not cond then error("FAIL: " .. msg, 2) end print("ok  " .. msg) end

local function run(path)
	local env = {}
	setmetatable(env, { __index = _G })
	local called, clientViolations, drives = {}, {}, {}
	local inServer = false
	for _, n in ipairs(apiNames) do
		-- functions that return lists (FindShapes, GetBodyShapes, GetJointedBodies, ...) get an empty list
		local list = n:match("s$") and (n:match("^Find") or n:match("^Get")) and not n:match("Pos$")
		env[n] = function(...)
			called[n] = (called[n] or 0) + 1
			if inServer and CLIENT_ONLY[n] then clientViolations[n] = true end
			if list then return {} end
			return 0
		end
	end
	-- math / engine basics
	env.Vec = function(x,y,z) return {x or 0,y or 0,z or 0} end
	env.VecCopy = function(v) return {v[1],v[2],v[3]} end
	env.VecAdd = function(a,b) return {a[1]+b[1],a[2]+b[2],a[3]+b[3]} end
	env.VecSub = function(a,b) return {a[1]-b[1],a[2]-b[2],a[3]-b[3]} end
	env.VecScale = function(a,s) return {a[1]*s,a[2]*s,a[3]*s} end
	env.VecLength = function(a) return math.sqrt(a[1]^2+a[2]^2+a[3]^2) end
	env.VecNormalize = function(a) local l = env.VecLength(a) return l > 0 and env.VecScale(a, 1/l) or a end
	env.Quat = function() return {0,0,0,1} end
	env.QuatLookAt = env.Quat
	env.Transform = function(p, r) return { pos = p or env.Vec(), rot = r or env.Quat() } end
	env.TransformToParentPoint = function(t, p) return env.VecAdd(t.pos, p) end
	env.GetTime = function() return 0 end
	env.GetTimeStep = function() return 1/60 end
	-- world: car at x=0 heading +x, players at x=+20 (z=-5, nearest) and x=+60
	local PLAYERS = { [1] = { pos = {60,0,0} }, [2] = { pos = {20,0,-5} } }
	env.Players = function() local ids, i = {1, 2}, 0 return function() i = i + 1 return ids[i] end end
	env.GetPlayerTransform = function(p) local pl = PLAYERS[p] or PLAYERS[1] return env.Transform(env.VecCopy(pl.pos)) end
	env.GetPlayerCameraTransform = env.GetPlayerTransform
	env.GetPlayerHealth = function() return 1 end
	env.GetPlayerVehicle = function() return 0 end
	env.GetPlayerCount = function() return 2 end
	env.FindVehicle = function() return 5 end
	env.FindBody = function() return 6 end
	env.GetVehicleBody = function() return 6 end
	env.GetVehicleHealth = function() return 1 end
	env.GetVehicleTransform = function() return env.Transform({0,0,0}) end
	env.GetBodyTransform = function() return env.Transform({0,0,0}) end
	env.GetBodyVelocity = function() return {5,0,0} end
	env.FindShapes = function(tag) if tag == "TORSO" or tag == "TORSOD" then return {11} end return {} end
	env.FindJoints = function() return {} end
	env.FindBodies = function() return {} end
	env.QueryRaycast = function() return false, 0 end
	env.HasTag = function() return false end
	env.GetTagValue = function() return "" end
	env.GetBool = function() return false end
	env.GetLocationTransform = function() return env.Transform({100,0,0}) end
	env.DriveVehicle = function(v, drive, steer, brake) drives[#drives + 1] = { drive, steer } end
	env.server, env.client = {}, {}
	env.TableShuffleInPlace = function(tb) return tb end -- TDSU (included in-game)

	local src = io.open(path, "rb"):read("*a"):gsub("\r", "")
	-- inline the includes this test needs (Teardown's preprocessor does this in-game)
	local function inline(rel)
		return (io.open("scripts/" .. rel, "rb"):read("*a"):gsub("\r", ""))
	end
	-- Teardown processes #include lines even inside a --[[ ]] block at the top of a file; unwrap that block here
	src = src:gsub("\n%-%-%[%[\n(#include[^%]]-)\n%]%]\n", "\n%1\n")
	src = src:gsub('#include "masterScriptRemoverAPI.lua"', function() return inline("masterScriptRemoverAPI.lua") end)
	src = src:gsub('#include "vehicleOperatorCoop.lua"', function() return inline("vehicleOperatorCoop.lua") end)
	src = src:gsub("([^\n]*)", function(l) if l:match("^%s*#") then return "" end return l end)
	local chunk = assert(loadstring(src, path))
	setfenv(chunk, env)
	chunk()

	inServer = true
	env.server.init()
	for i = 1, 120 do env.server.update(1/60) env.server.tick(1/60) end
	inServer = false
	return env, called, clientViolations, drives
end

for _, f in ipairs({ "scripts/chaseOperator.lua", "scripts/chaseOperatorTransport.lua",
                     "scripts/ConvoyOperations.lua", "scripts/ConvoyOperatorTransport.lua" }) do
	local env, called, violations, drives = run(f)
	check(next(violations) == nil, f .. ": no client-only calls on the server")
	check((called.PauseMenuButton or 0) == 0, f .. ": no pause-menu removal trick")
	if f:find("chase") then
		check(env.goalPos and env.goalPos[1] == 20 and env.goalPos[3] == -5, f .. ": goal = nearest player (+1 m up)")
		check(#drives > 0, f .. ": drives (DriveVehicle on the server)")
	end
	env.queueRemoval()
	local before = #drives
	env.server.tick(1/60) env.server.update(1/60)
	check(#drives == before and env.OpFinished, f .. ": idle after queueRemoval")
end
print("all operator tests passed")

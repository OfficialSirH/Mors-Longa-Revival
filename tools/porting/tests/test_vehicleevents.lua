-- Mock test for the debug-menu vehicle events (world/generation/RandomVehicleEnemy.lua HandleDebugVehicleEvent).
-- Run from the repo root with Lua 5.1: lua5.1 tools/porting/tests/test_vehicleevents.lua

local DEFS = "C:/Program Files (x86)/Steam/steamapps/common/Teardown/data/script_defs.lua"
local env = setmetatable({}, { __index = _G })
for line in io.lines(DEFS) do
	local n = line:match("^function ([A-Z][%w_]*)%(")
	if n then env[n] = function() return 0 end end
end
local R, spawned = {}, {}
env.Vec = function(x,y,z) return {x or 0,y or 0,z or 0} end
env.Quat = function() return {0,0,0,1} end
env.QuatEuler = env.Quat
env.Transform = function(p, r) return { pos = p, rot = r } end
env.GetString = function(k) return R[k] or "" end
env.SetString = function(k, v) R[k] = v end
env.GetFloat = function(k) return R[k] or 0 end
env.SetFloat = function(k, v) R[k] = v end
env.GetBool = function(k) return R[k] or false end
env.SetBool = function(k, v) R[k] = v end
env.GetInt = function() return 0 end
env.GetTime = function() return 0 end -- < 1: the timed events do not run, only the debug request
env.FindLocations = function() return {} end
env.Spawn = function(xml, t) spawned[#spawned + 1] = { xml = xml, pos = t.pos } return {} end
env.Init_Settings = function() env.Settings = { game = { enemy_helicopter = { value = false } } } end
env.RandomSpreadPercent = function(x) return x end
env.TimerCreateSeconds = function(s) return { time = s, rpm = s } end
env.server, env.client = {}, {}

local src = io.open("world/generation/RandomVehicleEnemy.lua", "rb"):read("*a"):gsub("\r", "")
src = src:gsub("([^\n]*)", function(l) if l:match("^%s*#") then return "" end return l end)
local chunk = assert(loadstring(src, "RandomVehicleEnemy.lua"))
setfenv(chunk, env)
chunk()
env.server.init()

local function check(cond, msg) if not cond then error("FAIL: " .. msg, 2) end print("ok  " .. msg) end
local function request(name, pos)
	spawned = {}
	R["level.debug.vehicle_event"] = name
	if pos then R["level.debug.vehicle_event_x"], R["level.debug.vehicle_event_y"], R["level.debug.vehicle_event_z"] = pos[1], pos[2], pos[3] end
	env.server.tick(1/60)
	return spawned
end

check(#request("civ") == 1 and spawned[1].xml:find("enemy vehicles/VehicleD%d"), "civ: hostile car (VehicleD#)")
check(#request("aaf") == 1 and spawned[1].xml:find("VehicleAAF[12]"), "aaf: military vehicle at 0 m (distance check skipped)")
check(#request("refugee") == 1 and spawned[1].xml:find("VehicleC%d"), "refugee: convoy vehicle")
check(#request("heli") == 1 and spawned[1].xml:find("AS350"), "heli: spawns with the helicopter setting off")
check(#request("roadblock", {12, 3, 4}) == 1 and spawned[1].pos[1] == 12 and spawned[1].pos[3] == 4, "roadblock: at the given position")
check(R["level.debug.vehicle_event"] == "" and #request("") == 0, "request runs once, then cleared")
R["savegame.mod.difficulty"] = "peaceful" R["savegame.mod.procedural.disable.spawn_roadblocks"] = true
check(#request("civ") == 1, "works with spawning disabled")
print("all vehicle event tests passed")

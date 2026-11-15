-- Mock test for the debug "shift probe" (ui/ShiftProbe.lua, 2026-11-15): what a machine sees at a world shift.
-- Run from the repo root with Lua 5.1: lua5.1 tools/porting/tests/test_shiftprobe.lua
local function check(cond, msg) if not cond then error("FAIL: " .. msg, 2) end print("ok  " .. msg) end

function Vec(x, y, z) return { x or 0, y or 0, z or 0 } end
function VecLength(a) return math.sqrt(a[1]^2 + a[2]^2 + a[3]^2) end
REG = { ["level.debug.shiftprobe"] = true, ["level.world_shifts"] = 0 }
function GetBool(k) return REG[k] == true end
function GetInt(k) return REG[k] or 0 end
function GetString(k) return REG[k] or "" end
function SetBool(k, v, sync) REG[k] = v SYNCED = sync end
T = 0
function GetTime() return T end
function GetLocalPlayer() return 2 end
function IsPlayerHost(p) return p == 1 end
-- bodies: 1-3 static, 4-5 dynamic, 6 npc torso, 7 vehicle body
B = {}
for i = 1, 7 do B[i] = { x = i, vx = 0 } end
B[7].vx = 10
local kinds = { "static", "static", "static", "dynamic", "dynamic", "npc", "vehicle" }
function QueryAabbBodies() return { 1, 2, 3, 4, 5, 6, 7 } end
function HasTag(h, t) return t == "Torso" and h == 6 end
function GetBodyVehicle(h) return h == 7 and 3 or 0 end
function IsBodyDynamic(h) return h >= 4 end
function IsHandleValid(h) return B[h] ~= nil end
function GetBodyTransform(h) return { pos = { B[h].x, 0, 0 } } end
function GetBodyVelocity(h) return { B[h].vx, 0, 0 } end
PL = { x = 0.5, vx = 10 }
function GetPlayerTransform() return { pos = { PL.x, 0, 0 } } end
function GetPlayerVelocity() return { PL.vx, 0, 0 } end

local f = io.open("ui/ShiftProbe.lua", "rb"):read("*a")
assert(loadstring(f, "ShiftProbe.lua"))()

-- server publishes the host toggle, synced, once per change
REG["savegame.mod.debug.shiftprobe"] = true REG["level.debug.shiftprobe"] = nil
ShiftProbe_ServerTick()
check(REG["level.debug.shiftprobe"] == true and SYNCED == true, "host toggle published to every machine (synced)")

local dt = 1 / 60
local function frame(fn)
	T = T + dt
	B[7].x = B[7].x + B[7].vx * dt
	PL.x = PL.x + PL.vx * dt
	if fn then fn() end
	ShiftProbe_ClientTick()
end
for i = 1, 10 do frame() end
check(#SP.sample == 7 and not SP.rec, "watching 7 bodies, nothing recorded before a shift")

-- shift arrives in stages: frame 1 static + me + car, frame 3 the counter and the dynamic bodies, frame 5 the npc
frame(function() for i = 1, 3 do B[i].x = B[i].x - 200 end B[7].x = B[7].x - 200 PL.x = PL.x - 200 end)
check(SP.rec ~= nil and SP.rec.counterAt == nil, "a body jump starts the recording before the counter arrives")
frame()
frame(function() REG["level.world_shifts"] = 1 B[4].x = B[4].x - 200 B[5].x = B[5].x - 120 end) -- 5 on the way
frame(function() B[5].x = B[5].x - 80 end)
frame(function() B[6].x = B[6].x - 200 end)
-- the car is knocked 5 m sideways along x after it arrived
frame(function() B[7].x = B[7].x + 5 end)
for i = 1, SHIFT_PROBE_FRAMES do frame(function() B[7].vx = B[7].vx + 3 * dt end) end -- car accelerates 3 m/s2
local r = SP.report
check(r and SP.rec == nil, "report after " .. SHIFT_PROBE_FRAMES .. " frames")
for _, l in ipairs(r) do print("    " .. l) end
check(r[1]:find("client", 1, true) and r[1]:find("7 bodies") and r[1]:find("counter %+50 ms") and r[1]:find("first body moved %+17 ms"),
	"header: client, 7 bodies, counter 2 frames after the first moved body")
check(r[1]:find("last old %+67 ms"), "last body still at the old place 4 frames in (npc)")
check(r[2]:find("1 bodies, worst snap 5.0 m"), "the knocked car counts as off: a 5 m snap")
check(r[4]:find("0/0/3   2/0/0   1/0/0   0/0/1   new   0", 1, true), "first frame: static, car and me moved, the rest old")
local knocked = false
for _, l in ipairs(r) do if l:find("0/0/1   new   1$") then knocked = true end end
check(knocked, "the frame the car is knocked shows 1 off")
local lastLine = r[#r]
check(not lastLine:find("1000"), "no repeated line for an unchanged frame (wide time stamps)")
local between = false
for _, l in ipairs(r) do if l:find("1/1/0", 1, true) or l:find("0/1/1", 1, true) then between = true end end
check(between, "a body sliding through shows as between")
check(#r <= 19, "report is at most 19 lines")

-- off: everything cleared
REG["level.debug.shiftprobe"] = false
frame()
check(SP.report == nil and #SP.sample == 0, "probe off clears the readout")
print("shift probe tests passed")

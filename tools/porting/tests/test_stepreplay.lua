-- Mock test for npcs/GoreNPCs/scripts/systems/goreai_stepreplay.lua (2026-11-17): the frame's first physics step runs
-- the npc code and records its Constrain* calls, the frame's other steps replay them (the body's own current point /
-- rotation refreshed), the skipped steps' time goes into the next full run, the navigation interval is 4x per second
-- of game time. Run from the repo root with Lua 5.1: lua5.1 tools/porting/tests/test_stepreplay.lua

local REG = {}
function SetString() end
function GetBool(k) return REG[k] == true end
local T = 0
function GetTime() return T end
UPDATE = 0
function IsTickInterval(tick, s) return tick % (60 * s) == 0 end
local BODY = { [1] = { pos = { 0, 1, 0 }, rot = { 0, 0, 0, 1 } } }
function GetBodyTransform(b) return { pos = { BODY[b].pos[1], BODY[b].pos[2], BODY[b].pos[3] }, rot = BODY[b].rot } end
local calls = {}
function ConstrainPosition(a, b, pa, pb, v, f) calls[#calls + 1] = { "pos", a, pa[2], pb[2] } end
function ConstrainOrientation(a, b, ra, rb, v, f) calls[#calls + 1] = { "rot", a } end
function ConstrainVelocity(a, b, p, d, v, mn, mx) calls[#calls + 1] = { "vel", a, v } end
function ConstrainAngularVelocity(a, b, d, v, mn, mx) calls[#calls + 1] = { "ang", a, v } end

local src = io.open("npcs/GoreNPCs/scripts/systems/goreai_stepreplay.lua", "rb"):read("*a"):gsub("\r", "")
assert(loadstring(src, "goreai_stepreplay.lua"))()

local function check(cond, msg) if not cond then error("FAIL: " .. msg, 2) end print("ok  " .. msg) end

-- a "full run" of one npc: two holds, one with the body's own current point
local function fullRun(npc, frame)
	StepReplayList = {}
	npc.replay = StepReplayList
	npc.replayFrame = frame
	ConstrainPosition(1, 0, GetBodyTransform(1).pos, { 0, 2, 0 }, 8, 100)   -- own point: refreshed on replay
	ConstrainVelocity(1, 0, { 0, 0, 0 }, { 0, 1, 0 }, 3, 0, 50)
	StepReplayList = nil
end

local npc = {}
-- frame 1, step 1: full run
check(StepReplayBegin(1 / 60, 1) == true and GoreFrameDt == 1 / 60, "first step of a frame: full run, 1/60 s")
fullRun(npc, 1)
check(#calls == 2 and #npc.replay == 2, "holds applied and recorded")
-- frame 1, step 2: replay, body moved meanwhile
BODY[1].pos = { 0, 1.5, 0 }
check(StepReplayBegin(1 / 60, 1) == false, "second step of the same frame: replay")
StepReplayApply(npc.replay)
check(#calls == 4 and calls[3][1] == "pos" and calls[3][3] == 1.5 and calls[3][4] == 2, "replayed position hold uses the body's current point")
check(calls[4][1] == "vel" and calls[4][3] == 3, "replayed velocity hold unchanged")
-- frame 1, step 3: replay again
check(StepReplayBegin(1 / 60, 1) == false, "third step: replay")
-- frame 2: the two skipped steps' time is added to the full run
check(StepReplayBegin(1 / 60, 2) == true and math.abs(GoreFrameDt - 3 / 60) < 1e-9, "next frame: full run covers 3 steps (skipped time carried)")
check(StepReplayBegin(1 / 60, 3) == true and math.abs(GoreFrameDt - 1 / 60) < 1e-9, "a frame with one step: 1/60 again")
-- calls outside a recording are not recorded
StepReplayList = nil
local before = #npc.replay
ConstrainVelocity(1, 0, { 0, 0, 0 }, { 0, 1, 0 }, 1, 0, 1)
check(#npc.replay == before, "Constrain* outside a full run is not recorded")
-- navigation interval: 4x per second of game time, on full runs
local hits = 0
T = 9 / 30 StepReplayBegin(1 / 60, 9)   -- prime the clock (not counted)
for f = 10, 69 do
	T = f / 30   -- 30 FPS: 2 s of game time
	if StepReplayBegin(1 / 60, f) and GoreNavInterval then hits = hits + 1 end
	StepReplayBegin(1 / 60, f)   -- the frame's second step
end
check(hits == 8, "navigation interval 4x per second at 30 FPS (" .. hits .. " in 2 s)")
-- off switch: every step is a full run with its own dt
REG["level.goreai.no_step_replay"] = true
check(StepReplayBegin(1 / 60, 99) == true and StepReplayBegin(1 / 60, 99) == true and GoreFrameDt == 1 / 60, "switch off: every step runs fully")

print("all stepreplay tests passed")

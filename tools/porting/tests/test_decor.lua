-- Mock test for the segment queue in world/generation/GenerateRoad.lua (2026-11-14): a segment's heavy content as
-- pieces (tools/porting/segment_pieces.py, SegmentPieces.lua) spawned from the frame after the segment within a
-- per-frame box-cell budget, then its roadside decor (split_decor.py, DecorParts.lua) one part per frame; waiting
-- entries follow a world shift; decor skipped when switched off or on Nightmare; level.segment.loading set while
-- entries wait; option "Low Detail Rocks" picks the rock pieces' low-detail elements. Also SpawnSlot.lua.
-- Run from the repo root with Lua 5.1: lua5.1 tools/porting/tests/test_decor.lua

function Vec(x,y,z) return {x or 0,y or 0,z or 0} end
function VecCopy(v) return {v[1],v[2],v[3]} end
function Quat() return {0,0,0,1} end
function Transform(p,r) return {pos=p or Vec(), rot=r or Quat()} end
R = {}
function GetBool(k) return R[k] == true end
function SetBool(k, v) R[k] = v end
function GetString(k) return R[k] or "" end
function SetString() end
function GetInt(k) return R[k] or 0 end
function SetInt(k, v) R[k] = v end
function SetFloat(k, v) R[k] = v end
function GetTime() return 0 end
function GetWorldBody() return 1 end      -- (2026-11-16) the shift re-sync's once-a-second record
function GetBodyShapes() return {} end
function DebugPrint() end
function GetEntityType() return "shape" end
function HasTag() return false end
spawned = {}
function Spawn(xml, t) spawned[#spawned + 1] = { xml = xml, pos = VecCopy(t.pos) } return {} end
server, client = {}, {}

for _, f in ipairs({ "world/generation/DecorParts.lua", "world/generation/SegmentPieces.lua",
		"world/generation/GenerateRoad.lua", "world/generation/SpawnSlot.lua" }) do
	local src = io.open(f, "rb"):read("*a"):gsub("\r", "")
	src = src:gsub("([^\n]*)", function(l) if l:match("^%s*#") then return "" end return l end)
	assert(loadstring(src, f))()
end

local function check(cond, msg) if not cond then error("FAIL: " .. msg, 2) end print("ok  " .. msg) end
local function frames(n) for i = 1, n do server.tick(1/60) end end

-- every file a piece or decor part names exists
local missing = 0
-- original-mod references to files that were never shipped (RoadSegmentF: 226 in 9dde6dd; the engine skips them)
local KNOWN_MISSING = { "^Voxel/probs/" }
local function files_exist(s)
	for f in s:gmatch('file="MOD/([^"]+)"') do
		local known = false
		for _, k in ipairs(KNOWN_MISSING) do if f:find(k) then known = true end end
		local h = io.open(f, "rb")
		if h then h:close() elseif not known then missing = missing + 1 print("missing " .. f) end
	end
end
for _, h in ipairs(SEGMENT_PIECE_HEADS) do files_exist(h) end
local npieces = 0
for seg, list in pairs(SEGMENT_PIECES) do
	for _, p in ipairs(list) do
		npieces = npieces + 1
		files_exist(p[2])
		if p[4] then files_exist(p[4]) end
		assert(SEGMENT_PIECE_HEADS[p[1]] and SEGMENT_PIECE_TAILS[p[1]], "piece without head")
	end
end
for _, parts in pairs(DECOR_PARTS) do
	for _, p in ipairs(parts) do
		local h = io.open(p:gsub("^MOD/", ""), "rb")
		if h then h:close() else missing = missing + 1 end
	end
end
check(missing == 0 and npieces > 1000, "every piece / decor file exists (" .. npieces .. " pieces)")

local pieces1 = SEGMENT_PIECES["RoadSegment1"]
check(#pieces1 > 0 and #DECOR_PARTS["RoadSegment1"] == 2 and DECOR_PARTS["RoadSegmentF"] == nil, "RoadSegment1 has pieces and 2 decor parts")

-- budget: each frame spawns pieces up to PieceBudget() cells (at least one)
local budget = PieceBudget()
check(budget == 250000, "default budget 250k cells")
QueueDecor("RoadSegment1", Transform(Vec(150, 0, 0)))
check(#spawned == 0 and R["level.segment.loading"] == true, "nothing spawned in the segment's own frame; segment loading")
local i, frame, ok, first = 1, 0, true, nil
while #spawned < #pieces1 and frame < 5000 do
	local before = #spawned
	frames(1)
	frame = frame + 1
	local cost = 0
	for k = before + 1, #spawned do cost = cost + pieces1[k][3] end
	if #spawned - before > 1 and cost > budget then ok = false end
	if #spawned == before then ok = false end
	first = first or spawned[1]
end
check(ok, "every frame spawns >= 1 piece and stays within the budget (" .. frame .. " frames)")
check(first.pos[1] == 150 and first.xml:find("^<prefab") ~= nil, "pieces spawn at the segment as full prefab xml")
frames(1)
check(spawned[#pieces1 + 1].xml:find("RoadSegment1_left"), "then the decor")
frames(1)
check(#spawned == #pieces1 + 2 and R["level.segment.loading"] == false and R["level.debug.parts_waiting"] == 0, "all in: segment loaded")

-- a world shift while entries wait
spawned = {}
QueueDecor("RoadSegment2", Transform(Vec(150, 0, 0)))
ShiftDecorQueue(200)
frames(1)
check(spawned[1].pos[1] == -50, "a waiting piece moves with the world shift")
frames(2000)

-- decor switch / nightmare
spawned = {}
R["savegame.mod.procedural.disable.spawn_decor"] = true
QueueDecor("RoadSegment3", Transform(Vec(0, 0, 0)))
frames(2000)
local anyDecor = false
for _, s in ipairs(spawned) do if s.xml:find("/decor/") then anyDecor = true end end
check(#spawned == #SEGMENT_PIECES["RoadSegment3"] and not anyDecor, "decor switch off: pieces only")
R["savegame.mod.procedural.disable.spawn_decor"] = false
R["savegame.mod.difficulty"] = "nightmare"
spawned = {}
QueueDecor("RoadSegment3", Transform(Vec(0, 0, 0)))
frames(2000)
anyDecor = false
for _, s in ipairs(spawned) do if s.xml:find("/decor/") then anyDecor = true end end
check(not anyDecor, "nightmare (all veg deleted anyway): no decor")
R["savegame.mod.difficulty"] = "normal"
spawned = {}
check(SEGMENT_PIECES["RoadSegmentNone"] == nil and DECOR_PARTS["RoadSegmentNone"] == nil, "test name has no entries")
QueueDecor("RoadSegmentNone", Transform(Vec(0, 0, 0)))
frames(3)
check(#spawned == 0 and not R["level.segment.loading"], "a segment without pieces queues nothing")
-- (2026-11-15) QueueSegment: all static pieces, then the segment file (with v1's after-spawn work), then the decor
FindLocations = function() return {} end
GetTagValue = function() return "" end
local registered, enemies = 0, nil
RegisterSegmentScripts = function() registered = registered + 1 end
ProcessEnemySpawns = function(e, override) enemies = override or "none" end
SetFloat = function(k, v) R[k] = v end
spawned = {}
QueueSegment("RoadSegment1", Transform(Vec(0, 0, 0)), { override = 6 })
frames(3000)
local fileAt, lastPiece, firstDecor
for k, s in ipairs(spawned) do
	if s.xml == "MOD/prefabs/spawnables/roadsegments/RoadSegment1.xml" then fileAt = k
	elseif s.xml:find("/decor/") then firstDecor = firstDecor or k
	else lastPiece = k end
end
check(fileAt and fileAt == #SEGMENT_PIECES["RoadSegment1"] + 1 and lastPiece < fileAt and firstDecor > fileAt,
	"segment: all its static pieces, then its file, then its decor")
check(registered == 1 and enemies == 6 and RoadgenPending == true, "the file's turn: scripts registered, enemies with the override, pulse pending")
R["savegame.mod.difficulty"] = "nightmare"
spawned = {}
QueueSegment("RoadSegment2", Transform(Vec(0, 0, 0)))
frames(3000)
check(#spawned == #SEGMENT_PIECES["RoadSegment2"] + 1, "Nightmare: the pieces and the file (fix: v1 port spawned only the file), no decor")
R["savegame.mod.difficulty"] = "normal"

-- (2026-11-15 fix) a deleted PuzzlePiece trigger is still listed until the end of the frame (server.update runs 2-3
-- times per frame below 60 FPS): it must not queue its segment again
local listed, validT = { 501 }, { [501] = true }
FindTriggers = function() return listed end
IsHandleValid = function(h) return validT[h] == true end
local first = UnusedPuzzlePieces()
check(#first == 1, "a new trigger is offered")
UsedPuzzlePieces[501] = true            -- the segment was queued, the trigger deleted (end of frame not reached)
check(#UnusedPuzzlePieces() == 0, "same frame, trigger still listed: not offered again (no duplicate segment)")
validT[501] = nil listed = {}
UnusedPuzzlePieces()
check(UsedPuzzlePieces[501] == nil, "once really gone it is forgotten (its handle may be reused)")
listed, validT = { 501 }, { [501] = true }
check(#UnusedPuzzlePieces() == 1, "a new trigger with a reused handle is offered")

-- option "Low Detail Rocks"
local rockIdx
for k, p in ipairs(SEGMENT_PIECES["RoadSegment4"]) do if p[4] then rockIdx = k break end end
check(rockIdx ~= nil, "RoadSegment4 has rock pieces with a low-detail version")
local function spawnSegment4()
	spawned = {}
	QueueDecor("RoadSegment4", Transform(Vec(0, 0, 0)))
	frames(3000)
	return spawned[rockIdx].xml
end
check(spawnSegment4():find("pieces/rock1_%d%d%.vox"), "no settings: original rock pieces")
Settings = { performance = { visual = { low_detail_rocks = { value = true } } } }
local xml = spawnSegment4()
check(xml:find("pieces/rock1_low_%d%d%.vox") and xml:find('scale="'), "option on: low-detail pieces at twice the scale")
Settings.performance.visual.low_detail_rocks.value = false
check(spawnSegment4():find("pieces/rock1_%d%d%.vox"), "option off: original rock pieces")

-- budget setting from the debug menu
R["savegame.mod.debug.piece_budget"] = 1000000
check(PieceBudget() == 1000000, "debug menu budget is used")
R["savegame.mod.debug.piece_budget"] = nil

-- SpawnSlot: one spawn per frame across spawners; free when there is no frame counter
R["level.frame"] = nil
check(SpawnSlotFree(), "no frame counter: slot free")
R["level.frame"] = 7
check(SpawnSlotFree(), "new frame: slot free")
TakeSpawnSlot()
check(not SpawnSlotFree(), "slot taken this frame")
R["level.frame"] = 8
check(SpawnSlotFree(), "next frame: free again")

-- (2026-11-17) option "Segment Loading Pace": spawns only every Nth frame, pieces and spawners share the slot
check(SpawnGap() == 1, "no pace option: every frame")
Settings.performance.physical = { spawn_pace = { value = 3 } }
check(SpawnGap() == 3, "pace 3")
Settings.performance.physical.spawn_pace.value = 40
check(SpawnGap() == SPAWN_GAP_MAX, "pace clamped to the maximum")
Settings.performance.physical.spawn_pace.value = 3
R["level.spawn.slot"] = nil
spawned = {}
QueueDecor("RoadSegment4", Transform(Vec(0, 0, 0)))
local spawnFrames = {}
for i = 1, 60 do
	local before = #spawned
	server.tick(1/60)
	if #spawned > before then spawnFrames[#spawnFrames + 1] = R["level.frame"] end
end
local spaced = #spawnFrames >= 2
for i = 2, #spawnFrames do if spawnFrames[i] - spawnFrames[i - 1] < 3 then spaced = false end end
check(R["level.spawn.gap"] == 3 and spaced, "pace 3: pieces spawn at least 3 frames apart (" .. #spawnFrames .. " spawn frames)")
R["level.spawn.slot"] = R["level.frame"]
R["level.frame"] = R["level.frame"] + 2
check(not SpawnSlotFree(), "pace 3: a spawner waits 2 frames after a spawn")
R["level.frame"] = R["level.frame"] + 1
check(SpawnSlotFree(), "pace 3: free on the 3rd frame")
Settings.performance.physical.spawn_pace.value = 1
server.tick(1/60)
check(R["level.spawn.gap"] == 1, "back to 1: every frame again")
print("all segment piece tests passed")

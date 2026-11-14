-- Mock-engine test for world/generation/GenerateRoad.lua co-op parts (Phase 3): run from the repo root with Lua 5.1:
--   lua5.1 tools/porting/tests/test_generateroad.lua
-- Covers the generation player (furthest living), straggler teleport (on foot / in a vehicle), and the
-- distance counter never going down.

function Vec(x,y,z) return {x or 0,y or 0,z or 0} end
function VecAdd(a,b) return {a[1]+b[1],a[2]+b[2],a[3]+b[3]} end
function Quat() return {0,0,0,1} end
function Transform(p,r) return {pos=p or Vec(), rot=r or Quat()} end
function clamp(v, a, b) return math.max(a, math.min(b, v)) end
function GetTime() return 0 end
function GetBool() return false end
function DebugPrint() end
function SetString() end
server, client = {}, {}

PLAYERS = {}
ORDER = {}
function Players() local i = 0 return function() i = i + 1 return ORDER[i] end end
function GetPlayerTransform(p) return Transform({PLAYERS[p].pos[1], PLAYERS[p].pos[2], PLAYERS[p].pos[3]}) end
function GetPlayerHealth(p) return PLAYERS[p].health end
function GetPlayerVehicle(p) return PLAYERS[p].vehicle or 0 end
function SetPlayerTransform(t, p) PLAYERS[p].pos = t.pos PLAYERS[p].teleported = true end
function SetPlayerVelocity() end
function QueryRaycast(from, dir, dist) return true, 30 end -- ground 30 m below the ray start
BODIES = {}
function GetVehicleBody(v) return v + 1000 end
function GetBodyTransform(b) return Transform(BODIES[b] or Vec()) end
function SetBodyTransform(b, t) BODIES[b] = t.pos end
function SetBodyVelocity() end
function SetBodyAngularVelocity() end
function IsMultiplayer() return #ORDER > 1 end
function IsHandleValid(h) return h ~= 0 end

local src = io.open("world/generation/GenerateRoad.lua", "rb"):read("*a"):gsub("\r", "")
src = src:gsub("([^\n]*)", function(l) if l:match("^%s*#") then return "" end return l end)
assert(loadstring(src, "GenerateRoad.lua"))()

local function check(cond, msg) if not cond then error("FAIL: " .. msg, 2) end print("ok  " .. msg) end

-- leader choice
PLAYERS = { [1] = { pos = Vec(10,0,0), health = 1 }, [2] = { pos = Vec(50,0,0), health = 1 }, [3] = { pos = Vec(90,0,0), health = 0 } }
ORDER = {1, 2, 3}
check(GetGenerationPlayer() == 2, "furthest LIVING player leads (dead player 3 is further)")
check(GetGenerationPlayerPos()[1] == 50, "generation pos = leader pos")
PLAYERS[1].health, PLAYERS[2].health = 0, 0
check(GetGenerationPlayer() == 3, "all dead: furthest player")
PLAYERS[1].health, PLAYERS[2].health = 1, 1

-- stragglers
PLAYERS = { [1] = { pos = Vec(0,0,0), health = 1 }, [2] = { pos = Vec(200,5,0), health = 1 },
            [3] = { pos = Vec(-10,0,0), health = 1, vehicle = 7 }, [4] = { pos = Vec(120,0,0), health = 1 } }
ORDER = {1, 2, 3, 4}
BODIES[1007] = Vec(-10,0,0)
TeleportStragglers(1)
check(not PLAYERS[1].teleported, "no teleport before 3 s")
TeleportStragglers(1) TeleportStragglers(1)
check(PLAYERS[1].teleported and PLAYERS[1].pos[1] == 192, "on foot: moved 8 m behind the leader after 3 s")
check(math.abs(PLAYERS[1].pos[2] - 5.5) < 1e-6, "placed on the ground (raycast) + 0.5 m")
check(BODIES[1007][1] == 192 and BODIES[1007][3] ~= PLAYERS[1].pos[3], "in vehicle: vehicle moved, next to the other straggler")
check(not PLAYERS[4].teleported, "player 80 m behind is not a straggler")
PLAYERS[1].teleported = nil
PLAYERS[1].pos = Vec(0,0,0) TeleportStragglers(1) PLAYERS[1].pos = Vec(195,0,0) TeleportStragglers(1)
PLAYERS[1].pos = Vec(0,0,0) TeleportStragglers(1) TeleportStragglers(1)
check(not PLAYERS[1].teleported, "timer resets when the player catches up")
PLAYERS[1].health = 0 TeleportStragglers(5)
check(not PLAYERS[1].teleported, "dead players are not teleported")

-- distance counter never goes down when the leader changes
PLAYERS = { [1] = { pos = Vec(0,0,0), health = 1 }, [2] = { pos = Vec(100,0,0), health = 1 } }
ORDER = {1, 2}
point = 1
function GetLocationTransform() return Transform(Vec(10000,0,0)) end
function SetFloat() end function SetBool() end function GetBool() return false end
local INTS = {} function SetInt(k, v) INTS[k] = v end function GetInt(k) return INTS[k] or 0 end
function ternary(c, a, b) if c then return a end return b end
PlayerZStart, Returns, DistanceProgressed = 0, 0, 0
ReturnToShadowVolume()
check(DistanceProgressed == 100, "distance follows the leader")
PLAYERS[2].health = 0 -- leader dies, player 1 (x = 0) leads now
ReturnToShadowVolume()
check(DistanceProgressed == 100, "distance does not drop when the leader changes")

-- world shift: the frame of the shift still reads the unshifted position (stale), which v1 tolerated
PLAYERS = { [1] = { pos = Vec(150,0,0), health = 1 } } ORDER = {1}
PlayerZStart, Returns, DistanceProgressed, DistanceSkipFrames = 0, 0, 150, 0
function GetLocationTransform() return Transform(Vec(300,0,0)) end -- 150 m to the point: shift now
local realSet = SetPlayerTransform
function SetPlayerTransform(t, p) end -- position not applied yet this frame (stale read)
function GetPlayerTransformWithPitch(p) return GetPlayerTransform(p) end
function SetPlayerTransformWithPitch() end
function FindBodies() return {} end function FindTriggers() return {} end
function GetPlayerVelocity() return Vec() end function SetBodyTransform() end
ReturnToShadowVolume()
check(DistanceProgressed == 150, "shift frame with a stale position: no +200 jump")
check(INTS["level.world_shifts"] == 1, "world shift counter published (for movers)")
PLAYERS[1].pos = Vec(-50,0,0) -- shift applied
function GetLocationTransform() return Transform(Vec(10000,0,0)) end
ReturnToShadowVolume() ReturnToShadowVolume()
PLAYERS[1].pos = Vec(-40,0,0)
ReturnToShadowVolume()
check(DistanceProgressed == 160, "after the shift the counter keeps counting continuously (+10 m)")

-- segment scripts are deleted once every world object of their segment is gone (2026-11-07 perf)
do
	local types = { [1] = "script", [2] = "script", [3] = "body", [4] = "shape", [5] = "location" }
	local valid = { [1] = true, [2] = true, [3] = true, [4] = true, [5] = true }
	local deleted = {}
	function GetEntityType(e) return types[e] end
	function IsHandleValid(e) return valid[e] end
	function Delete(e) deleted[#deleted + 1] = e valid[e] = false end
	SegmentGroups, SegmentGroupsNext = {}, 0
	RegisterSegmentScripts({1, 2, 3, 4, 5})
	RegisterSegmentScripts({5}) -- no scripts: not tracked
	check(#SegmentGroups == 1, "segment scripts: one group registered")
	valid[3] = false
	TickSegmentScripts()
	check(#deleted == 0, "segment scripts: kept while a shape of the segment exists")
	valid[4] = false SegmentGroupsNext = 0
	TickSegmentScripts()
	check(#deleted == 2 and #SegmentGroups == 0, "segment scripts: both deleted once the segment's bodies/shapes are gone")
end

print("all generateroad tests passed")

-- Mock test for the debug "building sync readout" (ui/BuildingProbe.lua, 2026-11-16).
-- Run from the repo root with Lua 5.1:  lua5.1 tools/porting/tests/test_buildprobe.lua
dofile("tools/porting/tests/mockengine.lua")

local function check(cond, msg) if not cond then error("FAIL: " .. msg, 2) end print("ok  " .. msg) end

local env = MockEngine.load("ui/BuildingProbe.lua")
env.PLAYERS = { [1] = { pos = { 0, 0, 0 }, health = 1 } }
env.ORDER = { 1 }
-- spawn A: body 50 with shapes 51 (small) and 52 (big); spawn B: a loose shape 61 (no body)
local TYPES = { [50] = "body", [51] = "shape", [52] = "shape", [61] = "shape", [70] = "location" }
local VOX = { [51] = 10, [52] = 900, [61] = 300 }
local POS = { [52] = { 30, 0, 0 }, [61] = { 80, 0, 0 } }
local BODY = { [51] = 50, [52] = 50, [61] = 0 }
local valid = { [50] = true, [51] = true, [52] = true, [61] = true, [70] = true }
env.def("IsHandleValid", function(h) return valid[h] == true end)
env.def("GetEntityType", function(h) return TYPES[h] end)
env.def("GetShapeVoxelCount", function(h) return VOX[h] or 0 end)
env.def("GetShapeWorldTransform", function(h) return env.Transform(env.VecCopy(POS[h] or { 0, 0, 0 })) end)
env.def("GetShapeBody", function(h) return BODY[h] or 0 end)
env.def("GetBodyShapes", function(b) return b == 50 and { 51, 52 } or {} end)
env.def("FindShapes", function() return { 51, 52, 61 } end)
env.def("IsBodyActive", function() return false end)
env.def("GetAllPlayers", function() return { 1 } end)
env.def("GetToolBody", function() return 0 end)
env.def("HasTag", function() return false end)
env.inputs = {}
env.def("InputDown", function(k) return env.inputs[k] == true end)
env.def("InputPressed", function(k) return env.inputs[k] == true end)

-- server (host): two spawns recorded, the largest shape of each
env.side = "server"
env.T = 10
env.BuildingProbe_Record({ 70, 50, 51, 52 }, "MOD/prefabs/spawnables/buildings/constructionCivillian7.xml")
env.T = 12
env.BuildingProbe_Record({ 61 }, "MOD/prefabs/spawnables/roadblocks/roadblock3.xml")
local list = env.R[env.BUILD_PROBE_LIST]
check(list == "52,constructionCivillian7,10.0;61,roadblock3,12.0", "largest shape and prefab name recorded: " .. tostring(list))
for i = 1, 10 do valid[100 + i] = true TYPES[100 + i] = "shape" env.BuildingProbe_Record({ 100 + i }, "x/b" .. i .. ".xml") end
local n = select(2, env.R[env.BUILD_PROBE_LIST]:gsub(";", "")) + 1
check(n == env.BUILD_PROBE_COUNT and env.R[env.BUILD_PROBE_LIST]:find("^103,"), "only the last 8 kept")
env.R[env.BUILD_PROBE_LIST] = list

env.T = 20
env.BuildingProbe_ServerTick()
check(env.R["level.debug.buildprobe"] == nil and env.R["level.debug.buildprobe_on"] == false, "off: nothing published")
env.R["savegame.mod.debug.buildprobe"] = true
env.BuildingProbe_ServerTick()
local s = env.R["level.debug.buildprobe"]
check(env.R["level.debug.buildprobe_on"] == true, "toggle published to every machine")
check(s == "20.0|3|52,constructionCivillian7,10.0,30.00,0.00,0.00,900,2;61,roadblock3,12.0,80.00,0.00,0.00,300,0",
	"current place, voxels and body shapes published: " .. tostring(s))
valid[52] = false
env.T = 21
env.BuildingProbe_ServerTick()
check(env.R["level.debug.buildprobe"]:find("52,constructionCivillian7,10.0,gone"), "deleted on the server: gone")
valid[52] = true
env.R["level.debug.buildprobe"] = s

-- a client: the building's shape left 200 m behind, the roadblock's shape missing
env.side = "client"
POS[52] = { 230, 0, 0 }
valid[61] = false
env.def("FindShapes", function() return { 51, 52 } end)
env.BuildingProbe_ClientTick()
local L = env.BP.lines
check(L[1]:find("server has 3 shapes") and L[1]:find("this machine 2"), "header: " .. L[1])
check(L[2]:find("#52 constructionCivillian7, 10 s ago") and L[2]:find("apart 200.00 m") and L[2]:find("voxels 900 / server 900")
	and L[2]:find("body shapes 2 / 2") and L[2]:find("asleep"), L[2])
check(L[3]:find("#61 roadblock3") and L[3]:find("NO SUCH SHAPE HERE") and L[3]:find("80 m from you"), L[3])
-- aim check (Ctrl+J): the server's ray hits road piece 52 (here 200 m away) then 61 (missing here); this machine hits 51
local rayHits, rej = {}, {}
env.def("QueryRejectShapes", function(list) rej = list end)
env.def("QueryRaycast", function()
	for _, hd in ipairs(rayHits) do
		local skip = false
		for _, r in ipairs(rej) do if r == hd[1] then skip = true end end
		if not skip then return true, hd[2], { 0, 1, 0 }, hd[1] end
	end
	return false, 0
end)
env.def("IsBodyDynamic", function() return false end)
env.def("GetCameraTransform", function() return env.Transform(env.Vec(0, 2, 0)) end)
env.def("QuatRotateVec", function(q, v) return env.VecCopy(v) end)
env.def("GetLocalPlayer", function() return 2 end)
env.inputs = { ctrl = true, j = true }
rayHits = { { 51, 4.0 } }
env.BuildingProbe_ClientTick()
check(env.sent[#env.sent].fn == "server.buildProbeAim" and env.sent[#env.sent].args[4] == 1, "Ctrl+J asks the server (request 1)")
L = env.BP.lines
check(L[#L - 1]:find("this machine hits #51 at 4.0 m") and L[#L]:find("waiting"), L[#L - 1] .. " / " .. L[#L])
env.side = "server"
rayHits = { { 52, 6.5 }, { 61, 9.0 } }
POS[52] = { 30, 0, 0 }
valid[61] = true
env.server.buildProbeAim(2, env.Vec(0, 2, 0), env.Vec(0, 0, -1), 1)
check(env.R["level.debug.buildprobe.aim.2"] == "1|52,6.5,50,static,900,30.00,0.00,0.00;61,9.0,0,static,300,80.00,0.00,0.00",
	"server answer: " .. tostring(env.R["level.debug.buildprobe.aim.2"]))
env.side = "client"
POS[52] = { 230, 0, 0 }
valid[61] = false
env.inputs = {}
rayHits = { { 51, 4.0 } }
env.BuildingProbe_ClientTick()
L = env.BP.lines
local n = #L
check(L[n - 1]:find("server hits #52 at 6.5 m") and L[n - 1]:find("static") and L[n - 1]:find("apart 200.00 m"), L[n - 1])
check(L[n]:find("server hits #61 at 9.0 m") and L[n]:find("NOT HERE"), L[n])
-- level scan: the server counts static shapes per 20 m cell; this machine has #52 200 m away and no #61
env.side = "server"
POS[52] = { 30, 0, 0 }
valid[61] = true
env.def("FindShapes", function() return { 51, 52, 61 } end)
env.BP.nextCells = 0
env.BuildingProbe_ServerTick()
local cells = env.R["level.debug.buildprobe.cells"]
check(cells:find("1,0,1,900") and cells:find("4,0,1,300") and cells:find("0,0,1,10"), "server cells: " .. cells)
env.side = "client"
POS[52] = { 230, 0, 0 }
valid[61] = false
env.def("FindShapes", function() return { 51, 52 } end)
local nsent = #env.sent
env.BuildingProbe_ClientTick()
L = env.BP.lines
local i0
for i, l in ipairs(L) do if l:find("^Level scan") then i0 = i end end
check(i0 and L[i0]:find("3 of 3 cells differ"), "scan header: " .. tostring(i0 and L[i0]))
check(L[i0 + 1]:find("x 13..33 z %-7..13: server 1 shapes / 900 voxels, here 0 / 0"), "worst cell first: " .. L[i0 + 1])
local ask = env.sent[#env.sent]
check(#env.sent == nsent + 1 and ask.fn == "server.buildProbeCell" and ask.args[2] == 1 and ask.args[3] == 0,
	"asks the server about the worst cell")
env.side = "server"
POS[52] = { 30, 0, 0 }
valid[61] = true
env.def("FindShapes", function() return { 51, 52, 61 } end)
env.server.buildProbeCell(2, 1, 0, ask.args[4])
check(env.R["level.debug.buildprobe.cell.2"] == ask.args[4] .. "|1,0|52,30.00,0.00,0.00,900", "cell answer: "
	.. tostring(env.R["level.debug.buildprobe.cell.2"]))
env.side = "client"
POS[52] = { 230, 0, 0 }
valid[61] = false
env.def("FindShapes", function() return { 51, 52 } end)
env.BuildingProbe_ClientTick()
L = env.BP.lines
local found
for i, l in ipairs(L) do if l:find("cell 1,0, server's 1 largest shapes: 0 not here, 1 elsewhere here") then found = i end end
check(found and L[found + 1]:find("#52 at 30,0,0, 900 voxels: here apart 200.0 m"), "cell detail: " .. tostring(found and L[found + 1]))
-- a player's held tool (body 50 here) is left out of the count
env.def("GetToolBody", function() return 50 end)
local c = env.BuildingProbe_Cells()
check(c["1,0"] == nil and c["0,0"] == nil, "held tool shapes not counted")
env.def("GetToolBody", function() return 0 end)
for k in pairs(env.violations) do error("FAIL: wrong-side call " .. k) end
print("all building probe tests passed")

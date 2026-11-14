-- Mock test for other players' guns (weapons/guns/gunnet.lua, MP 2026-11-14): the holder's machine sends its tool parts'
-- local transforms (changes only, all of them on a tool change / every 2 s), the other machines apply them to that
-- player's tool body with the first-person arms hidden.
-- Run from the repo root with Lua 5.1: lua5.1 tools/porting/tests/test_gunparts.lua
dofile("tools/porting/tests/mockengine.lua")

local function check(cond, msg) if not cond then error("FAIL: " .. msg, 2) end print("ok  " .. msg) end

local PATH = "weapons/guns/gunnet.lua"

-- a machine with two players; shape handles: tool body of player p = 100*p, its shapes 100*p + i
local function machine(localPlayer)
	local env = MockEngine.load(PATH, {})
	env.PLAYERS[2] = { pos = {0,0,0}, health = 1 }
	env.ORDER = { 1, 2 }
	env.LOCAL = localPlayer
	env.side = "client"
	env.local_t = {}   -- [shape] = transform
	env.tags = {}
	env.tool = { [1] = "gun-ak74", [2] = "gun-ak74" }
	env.def("IsPlayerLocal", function(p) return p == env.LOCAL end)
	env.def("GetPlayerTool", function(p) return env.tool[(p and p ~= 0) and p or env.LOCAL] end)
	env.def("GetToolBody", function(p) return 100 * ((p and p ~= 0) and p or env.LOCAL) end)
	env.def("GetBodyShapes", function(b) local s = {} for i = 1, 12 do s[i] = b + i end return s end)
	env.def("GetShapeLocalTransform", function(s) return env.local_t[s] or env.Transform(env.Vec(0, 0, 0)) end)
	env.def("SetShapeLocalTransform", function(s, t) env.local_t[s] = t end)
	env.def("SetTag", function(s, tag) env.tags[s] = tag end)
	env.Quat = function(x, y, z, w) return { x or 0, y or 0, z or 0, w or 1 } end
	return env
end

local holder, viewer = machine(1), machine(2)
-- the AK74 script on the holder: its tool body is the held one; parts placed by the gun script; arms = parts 11, 12
holder.body = 100
holder.hand1, holder.arm1 = 111, 112
for i = 1, 12 do holder.local_t[100 + i] = holder.Transform(holder.Vec(i * 0.1, 0, -i * 0.01)) end
-- the viewer still has player 1's raw prefab: parts in their lanes
for i = 1, 12 do viewer.local_t[100 + i] = viewer.Transform(viewer.Vec(24 * i, 0, 0)) end

local function relay()
	-- what server.gunParts broadcast reaches the viewer's copy of the script
	local calls = {}
	for _, s in ipairs(holder.sent) do if s.fn == "server.gunParts" then calls[#calls + 1] = s.args end end
	holder.sent = {}
	for _, args in ipairs(calls) do viewer.client.gunParts(unpack(args)) end
	return #calls
end

holder.client.render(1/60)
check(relay() == 1, "holder: first frame sends a full snapshot")
viewer.client.render(1/60)
local p5 = viewer.local_t[105]
check(math.abs(p5.pos[1] - 0.5) < 1e-3 and math.abs(p5.pos[3] + 0.05) < 1e-3, "viewer: player 1's part moved out of its lane")
check(viewer.tags[111] == "invisible" and viewer.tags[112] == "invisible" and viewer.tags[105] == nil,
	"viewer: first-person arm parts hidden, gun parts shown")
check(viewer.local_t[205] == nil, "viewer: its own tool untouched")

holder.T = 0.05
holder.client.render(1/60)
check(relay() == 0, "holder: nothing changed -> nothing sent")
holder.local_t[103] = holder.Transform(holder.Vec(9, 9, 9))   -- e.g. the magazine dropped during a reload
holder.client.render(1/60)
check(relay() == 0, "holder: change inside the rate limit waits")
holder.T = 0.2
holder.client.render(1/60)
local n = #holder.sent
local args = holder.sent[1] and holder.sent[1].args
check(n == 1 and not args[3] and args[4]:match("^3=") and not args[4]:match(";"), "holder: only the changed part sent")
relay()
viewer.client.render(1/60)
check(math.abs(viewer.local_t[103].pos[1] - 9) < 1e-3, "viewer: the change applied")

holder.tool[1] = "gun-mp5"
holder.T = 0.25
holder.client.render(1/60)
check(holder.sent[1] and holder.sent[1].args[2] == "gun-mp5" and holder.sent[1].args[3] == true,
	"holder: tool change -> full snapshot at once")
relay()
viewer.tool[1] = "gun-mp5"
viewer.local_t[101] = viewer.Transform(viewer.Vec(24, 0, 0))
viewer.client.render(1/60)
check(math.abs(viewer.local_t[101].pos[1] - 0.1) < 1e-3, "viewer: new gun's parts applied")
viewer.tool[1] = "sledge"
viewer.local_t[101] = viewer.Transform(viewer.Vec(24, 0, 0))
viewer.client.render(1/60)
check(viewer.local_t[101].pos[1] == 24, "viewer: player switched to another tool -> nothing applied")

holder.body = 999   -- this gun script's tool is not the held one
holder.T = 5
holder.client.render(1/60)
check(#holder.sent == 0, "holder: a gun script whose tool isn't held sends nothing")
check(next(holder.violations) == nil and next(viewer.violations) == nil, "no wrong-side calls")
print("all gun part tests passed")

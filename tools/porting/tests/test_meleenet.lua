-- Mock test for other players' melee swings (weapons/melee/Melee_Functions.lua, 2026-11-15): the swinging client
-- queues "swing" + "fx", the server forwards them to every client, another machine plays the sounds, spawns the
-- particles and poses that player's weapon (rest, swing) with the engine's per-player tool pose calls. Uses
-- Crowbar.lua (all eight melee scripts have the same three hooks).
-- Run from the repo root with Lua 5.1:  lua5.1 tools/porting/tests/test_meleenet.lua
dofile("tools/porting/tests/mockengine.lua")

local function check(cond, msg) if not cond then error("FAIL: " .. msg, 2) end print("ok  " .. msg) end
local PATH = "weapons/melee/Crowbar.lua"

local function load(localPlayer)
	local env = MockEngine.load(PATH, { inline = { "Melee_Functions.lua" }, inlineDir = "weapons/melee/" })
	env.PLAYERS = { [1] = { pos = { 0, 0, 0 }, health = 1 }, [2] = { pos = { 7, 0, 3 }, health = 1 } }
	env.ORDER = { 1, 2 }
	env.LOCAL = localPlayer
	env.def("IsPlayerLocal", function(p) return p == env.LOCAL end)
	env.def("HasFile", function() return false end)
	env.def("LoadSound", function(p) return p end)
	env.def("IsHandleValid", function(h) return h ~= 0 end)
	env.QuatEuler = function(x, y, z) return { x, y, z, "euler" } end
	env.TransformToParentTransform = function(t, l) return { pos = env.VecAdd(t.pos, l.pos), rot = { t.rot, l.rot } } end
	env.side = "client"
	env.client.init()
	return env
end

-- 1) the swinging player's machine (player 2): a left-click swing that hits something
local A = load(2)
local pressed = true
A.def("InputPressed", function(k) if k == "usetool" and pressed then pressed = false return true end return false end)
A.def("GetPlayerTool", function() return "melee-Crowbar" end)
A.def("GetPlayerCanUseTool", function() return true end)
A.def("GetToolBody", function() return 77 end)
local rays = 0
A.def("QueryRaycast", function() rays = rays + 1 return rays == 8, 0.5, A.Vec(0, 0, 1), 900 end)
A.def("QueryAabbShapes", function() return { 900 } end)
A.def("GetShapeMaterialAtPosition", function() return "wood", 0.6, 0.4, 0.2, 1 end)
A.def("GetShapeBody", function() return 901 end)
A.def("HasTag", function() return false end) -- not an NPC
local ticks = 0
repeat A.client.tick(1 / 60) ticks = ticks + 1 until A.smashTimer == 0 or ticks > 200
check(ticks >= 23 and ticks <= 26, "the crowbar lands after ~0.4 s (" .. ticks .. " ticks)")
A.client.postUpdate()
local call = A.sent[#A.sent]
check(call and call.to == "server" and call.fn == "server.meleeOps", "one ServerCall with the frame's melee ops")
local ops, kinds = call.args[1], {}
for _, op in ipairs(ops) do kinds[op.t] = op end
check(kinds.swing and kinds.swing.dur == 0.4 and kinds.swing.spin == false, "swing op: chop, lands after 0.4 s")
check(kinds.fx and kinds.fx.hit == true and #kinds.fx.holes == 1, "fx op: a hit, one hit point")
check(kinds.fx.r == 0.6 and kinds.fx.g == 0.4 and kinds.fx.b == 0.2, "fx op: the hit material's colour")
check(kinds.hole ~= nil, "the hole still goes to the server as before")

-- 2) the server forwards swing + fx to every client, and still makes the hole
local S = load(1)
S.side = "server"
S.sent = {}
S.server.meleeOps(ops, 2)
check(S.calls.MakeHole == 1, "server: MakeHole as before")
local fwd = S.sent[1]
check(fwd and fwd.to == 0 and fwd.fn == "client.meleeRemoteOps" and fwd.args[1] == 2, "server: ClientCall(0) for player 2")
check(#fwd.args[2] == 2, "server: forwards only swing + fx (" .. #fwd.args[2] .. " ops)")

-- 3) another machine (player 1) holding nothing itself; player 2 holds the crowbar
local B = load(1)
B.def("GetPlayerTool", function(p) return p == 2 and "melee-Crowbar" or "none" end)
local POSE, HANDS = {}, {}
B.def("SetToolTransformOverride", function(t, p) POSE[p] = t end)
B.def("SetToolHandPoseLocalTransform", function(r, l, p) HANDS[p] = { r, l } end)
local sounds = {}
B.def("PlaySound", function(snd, pos) sounds[#sounds + 1] = { snd, pos } end)
B.client.tick(1 / 60)
local grip = B.MELEE_GRIPS["melee-Crowbar"].r
check(POSE[2] and POSE[2].rot[1] == 60 and POSE[1] == nil, "resting: player 2's crowbar posed at 60 deg, own tool left alone")
check(math.abs(POSE[2].pos[1] + grip[1] - B.MELEE_HAND[1]) < 1e-9 and math.abs(POSE[2].pos[3] + grip[3] - B.MELEE_HAND[3]) < 1e-9,
	"resting: the grip point sits in the right hand")
check(HANDS[2] and HANDS[2][1].pos[3] == grip[3] and HANDS[2][2] == nil, "one-handed: right hand on the grip, left hand free")
B.client.meleeRemoteOps(2, { fwd.args[2][1] }) -- the swing arrives first
B.client.tick(0.1)
local first = POSE[2].rot[1]
check(first > 60, "swing: raised over the shoulder first (" .. first .. " deg)")
B.client.tick(0.2)
check(POSE[2].rot[1] < first and POSE[2].pos[3] < -0.3 - grip[3], "swing: chops down, arm forward (" .. POSE[2].rot[1] .. " deg)")
B.client.meleeRemoteOps(2, { fwd.args[2][2] }) -- the landing
check(#sounds == 2 and sounds[1][2][1] == 7, "swing + hit sound at player 2's position")
check(B.calls.SpawnParticle == 10, "10 particles at the hit point")
B.client.tick(0.2)
check(POSE[2].rot[1] == 60 and next(B.MeleeNet.remote) == nil, "back to the resting pose once the swing is over")

-- player 2 switches tool mid-swing: entry dropped, no more posing
B.client.meleeRemoteOps(2, { fwd.args[2][1] })
B.client.tick(0.1)
B.def("GetPlayerTool", function() return "none" end)
POSE[2] = nil
B.client.tick(0.1)
check(POSE[2] == nil and next(B.MeleeNet.remote) == nil, "tool switched mid-swing: dropped, not posed")

-- two-handed weapons put the left hand on the handle too
local C = load(1)
C.Tool_Id = "melee-FireAxe"
C.def("GetPlayerTool", function(p) return p == 2 and "melee-FireAxe" or "none" end)
local H, CP = {}, {}
C.def("SetToolHandPoseLocalTransform", function(r, l, p) H[p] = { r, l } end)
C.def("SetToolTransformOverride", function(tr, p) CP[p] = tr end)
local rolled
C.QuatRotateQuat = function(a, b) rolled = a return { a, b } end
C.MeleeNet_RemoteTick(1 / 60)
check(H[2] and H[2][2] and H[2][2].pos[3] > H[2][1].pos[3], "two-handed (Fire Axe): left hand at the end, right further up")
check(rolled and rolled[3] == C.MELEE_REST_ROLL_2H and math.abs(CP[2].pos[1] - C.MELEE_HAND_2H[1]) < 1e-9,
	"two-handed rest: across the chest (rolled " .. tostring(rolled and rolled[3]) .. " deg, right hand at x " .. C.MELEE_HAND_2H[1] .. ")")
for id, g in pairs(C.MELEE_GRIPS) do
	check(g.r[1] == 0 and (not g.l or g.l[1] == 0), id .. ": grips on the handle's centre line")
end

-- crouching: the weapon follows player 2's animated shoulder down (the override frame stays at standing eye height)
local D = load(1)
D.def("GetPlayerTool", function(p) return p == 2 and "melee-Crowbar" or "none" end)
local DP = {}
D.def("SetToolTransformOverride", function(tr, p) DP[p] = tr end)
D.def("GetPlayerAnimator", function(p) return p == 2 and 55 or 0 end)
D.def("GetAnimatorTransform", function() return D.Transform(D.Vec(7, 0, 3)) end)
D.def("GetBoneBindPoseTransform", function() return D.Transform(D.Vec(0.2, 1.45, 0)) end)
D.def("GetBoneWorldTransform", function() return D.Transform(D.Vec(7.2, 0.95, 2.9)) end) -- shoulder 0.5 m lower, 0.1 forward
D.MeleeNet_RemoteTick(1 / 60)
check(DP[2] and math.abs(DP[2].pos[2] - (D.MELEE_HAND[2] - 0.5 - grip[2])) < 1e-9
	and math.abs(DP[2].pos[3] - (D.MELEE_HAND[3] - 0.1 - grip[3])) < 1e-9,
	"crouching: weapon 0.5 m lower and 0.1 m forward with the shoulder")

-- the swinging machine ignores its own forwarded ops
local before = A.calls.PlaySound or 0
A.client.meleeRemoteOps(2, fwd.args[2])
check((A.calls.PlaySound or 0) == before and next(A.MeleeNet.remote) == nil, "own swing ignored when it comes back")

for _, e in ipairs({ A, B, C }) do
	for n in pairs(e.violations) do error("FAIL: server-only call on a client: " .. n) end
end
print("all melee net tests passed")

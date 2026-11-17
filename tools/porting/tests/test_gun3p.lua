-- Mock test for third-person guns (weapons/guns/gunnet.lua "Third-person guns", 2026-11-15): every machine builds
-- a small local copy of another player's held gun (and of its own in third person), hides the oversized tool and
-- the first-person arms, poses the copy from the tool parts each frame, and puts the character's hands on the
-- first-person fake hands' grip points. If the copy can't be built, nothing is hidden.
-- Run from the repo root with Lua 5.1: lua5.1 tools/porting/tests/test_gun3p.lua
dofile("tools/porting/tests/mockengine.lua")

local function check(cond, msg) if not cond then error("FAIL: " .. msg, 2) end print("ok  " .. msg) end
local function near(a, b) return math.abs(a - b) < 1e-6 end

local PATH = "weapons/guns/gunnet.lua"

-- a machine with two players; tool body of player p = 100*p, its shapes 100*p + i (12 parts)
local function machine(localPlayer)
	local env = MockEngine.load(PATH, {})
	env.PLAYERS[2] = { pos = {5,0,0}, health = 1 }
	env.ORDER = { 1, 2 }
	env.LOCAL = localPlayer
	env.side = "client"
	env.local_t, env.tags, env.types, env.valid = {}, {}, {}, {}
	env.tool = { [1] = "gun-akm", [2] = "gun-akm" }
	env.spawnOk = true
	env.def("IsPlayerLocal", function(p) return p == env.LOCAL end)
	env.def("GetPlayerTool", function(p) return env.tool[(p and p ~= 0) and p or env.LOCAL] end)
	env.def("GetToolBody", function(p) return 100 * ((p and p ~= 0) and p or env.LOCAL) end)
	env.def("GetBodyShapes", function(b) local s = {} for i = 1, 12 do s[i] = b + i end return s end)
	env.def("GetShapeLocalTransform", function(s) return env.local_t[s] or env.Transform(env.Vec(0, 0, 0)) end)
	env.def("SetShapeLocalTransform", function(s, t) env.local_t[s] = t end)
	env.def("SetTag", function(s, tag) env.tags[s] = env.tags[s] or {} env.tags[s][tag] = true end)
	env.def("RemoveTag", function(s, tag) if env.tags[s] then env.tags[s][tag] = nil end end)
	env.sizes = {}
	env.def("GetShapeSize", function(s) local z = env.sizes[s] or 10 return 10, 10, z, 0.1 end)
	env.def("GetEntityType", function(e) return env.types[e] end)
	env.def("IsHandleValid", function(h) return env.valid[h] == true or (h >= 100 and h < 300) end)
	env.def("Delete", function(h) env.valid[h] = nil env.deleted = (env.deleted or 0) + 1 end)
	env.spawned = 0
	env.def("Spawn", function(xml)
		if not env.spawnOk then return {} end
		env.spawned = env.spawned + 1
		env.spawnXml = xml
		local base = 1000 * env.spawned
		local out = { base }
		env.types[base], env.valid[base] = "body", true
		for i = 1, select(2, xml:gsub("<vox ", "")) do
			out[#out + 1] = base + i
			env.types[base + i], env.valid[base + i] = "shape", true
		end
		return out
	end)
	env.copied = {}
	env.def("CopyShapeContent", function(src, dst) env.copied[dst] = src end)
	env.POSE, env.HANDS = {}, {}
	env.def("SetToolTransformOverride", function(t, p) env.POSE[p] = t end)
	env.def("SetToolHandPoseLocalTransform", function(r, l, p) env.HANDS[p] = { r, l } end)
	env.def("SetBodyTransform", function(b, t) env.bodyT = env.bodyT or {} env.bodyT[b] = t end)
	env.QuatRotateVec = function(q, v) return env.VecCopy(v) end   -- rotations ignored in this mock
	env.QuatRotateQuat = function(a, b) return b end
	env.QuatSlerp = function(a, b, k) return b end
	env.QuatAxisAngle = function() return { 0, 0, 0, 1 } end
	env.Quat = function(x, y, z, w) return { x or 0, y or 0, z or 0, w or 1 } end
	env.inputs = {}
	env.def("InputDown", function(k, p) return env.inputs[k] == true end)
	env.def("GetPlayerEyeTransform", function(p)
		local t = env.GetPlayerTransform(p) t.pos[2] = t.pos[2] + 1.7 return t end)   -- standing
	return env
end

local function hidden(env, s) return env.tags[s] and env.tags[s].invisible end

local holder, viewer = machine(1), machine(2)
-- the gun script on the holder: parts placed; hand1 = 111 (handguard, further forward), hand2 = 110 (grip), arm1 = 112
holder.body = 100
holder.hand1, holder.hand2, holder.arm1 = 111, 110, 112
for i = 1, 12 do holder.local_t[100 + i] = holder.Transform(holder.Vec(0.2, -0.5, -0.1 * i)) end
holder.local_t[105] = holder.Transform(holder.Vec(0, -200, 0))   -- a part parked away (hideTrans)
holder.local_t[104] = holder.Transform(holder.Vec(1.2, -0.2, 22.4))   -- never moved by the script (MC308's stick)
holder.local_t[106] = holder.Transform(holder.Vec(0.2, -0.5, -5.0))   -- a 4 m tube: its corner outside the box, its centre inside (RPG-7)
for i = 1, 12 do viewer.local_t[100 + i] = viewer.Transform(viewer.Vec(24 * i, 0, 0)) end
viewer.sizes[106] = 40

local function relay()
	local n = 0
	for _, s in ipairs(holder.sent) do
		if s.fn == "server.gunParts" then viewer.client.gunParts(unpack(s.args)) n = n + 1 end
	end
	holder.sent = {}
	return n
end

holder.client.render(1/60)
check(relay() == 1, "holder: parts sent")
check(holder.spawned == 0, "holder in first person: no copy of its own gun")
check(viewer.client.gunRemoteParts[1].grip[1] == 11 and viewer.client.gunRemoteParts[1].grip[2] == 10,
	"the hand parts' indices travel with the parts (hand1 11, hand2 10)")

viewer.client.render(1/60)
local c = viewer.client.gun3p[1]
check(c and c.body == 1000 and #c.shapes == 12, "viewer: a local copy of player 1's gun, one part per tool part")
check(viewer.spawnXml:match('scale="0%.4000"') and viewer.spawnXml:match('collide="false"'),
	"copy parts at 0.4 of the tool's voxel size, no collision")
check(viewer.copied[1003] == 103 and viewer.copied[1012] == 112, "voxels copied part by part")
local allHidden = true
for i = 1, 12 do if not hidden(viewer, 100 + i) then allHidden = false end end
check(allHidden, "viewer: the oversized tool hidden")
local p3 = viewer.local_t[1003]
check(near(p3.pos[1], 0.08) and near(p3.pos[3], -0.12) and not hidden(viewer, 1003), "copy part 3 at 0.4 x its tool position")
check(hidden(viewer, 1011) and hidden(viewer, 1012), "first-person hand / arm not copied")
check(hidden(viewer, 1005), "parked part hidden in the copy")
check(hidden(viewer, 1004), "part left behind the first-person camera hidden in the copy")
check(not hidden(viewer, 1006), "a long part whose corner is outside the box but its centre inside is shown (RPG-7 tube)")
check(viewer.spawnXml:match('dynamic="true"') and viewer.calls.SetBodyGravityScale == 1 and viewer.calls.SetBodyVelocity == 1,
	"copy body dynamic without gravity, held still each frame")
local gripR = viewer.Vec(0.2, -0.5, -1.0)   -- part 10 = hand2: nearer the stock than part 11
local tool = viewer.POSE[1]
local run, act, rh = viewer.GUN3P_POSE.run.pos, viewer.GUN3P_POSE.action.pos, viewer.GUN3P_RH_POS
check(near(c.pose.pos[1], run[1]) and near(c.pose.pos[3], run[3]), "idle: the engine rifle's low 'run' pose")
check(tool and near(tool.pos[3] + gripR[3] * 0.4, run[3] + rh[3]) and near(tool.pos[1] + gripR[1] * 0.4, run[1] + rh[1]),
	"the gun's own grip lands where the rifle pose has its grip (right hand)")
local hands = viewer.HANDS[1]
check(hands and near(hands[1].pos[3], -1.0 * 0.4) and hands[2] and near(hands[2].pos[3], -1.1 * 0.4),
	"hands: right on the grip (hand2), left on the handguard (hand1)")
check(viewer.bodyT[1000] ~= nil, "the copy follows the player")
check(viewer.spawned == 1 and viewer.POSE[2] == nil, "viewer: its own first-person gun left alone")

viewer.POSE[1] = nil
viewer.Gun3P_Pose()
local src = io.open(PATH):read("*a")
check(viewer.POSE[1] == tool and src:match("function GunNet_ClientTick%(dt%).-Gun3P_Pose%(%)"),
	"the pose is re-issued from client.tick (GunNet_ClientTick)")

viewer.client.render(1/60)
check(viewer.spawned == 1, "the copy is kept frame to frame")

-- player 1 shoots (seen through client.gunRemoteFire): shouldered 'action' pose, blending at the engine's rate
viewer.client.gun3pFired[1] = viewer.T
viewer.client.render(1/60)
check(near(c.pose.pos[2], (run[2] + act[2]) / 2), "a shot: half way to the 'action' pose in one frame (rate 60)")
for _ = 1, 30 do viewer.client.render(1/60) end
check(near(c.pose.pos[2], act[2]) and near(c.pose.pos[3], act[3]), "shouldered while in action")
viewer.T = 3
for _ = 1, 60 do viewer.client.render(1/60) end
check(near(c.pose.pos[2], run[2]), "2 s after the last shot: back to the low pose")
viewer.inputs.grab = true
for _ = 1, 30 do viewer.client.render(1/60) end
check(near(c.pose.pos[2], act[2]), "aiming (right mouse): shouldered")
viewer.inputs.grab = nil
viewer.T = viewer.T + 0.2
for _ = 1, 120 do viewer.client.render(1/60) end
check(near(c.pose.pos[2], run[2]), "let go of aim: back to the low pose after 0.15 s (not the engine's 2 s)")

-- a scope overlay drawn (by the gun script's client.draw) keeps the view in first person while it shows
viewer.Gun3P_ScopeOverlay()
viewer.Gun3P_ScopeTick()
check(viewer.calls.RequestFirstPerson == 1, "scope overlay: first person requested")
viewer.T = viewer.T + 0.2
viewer.Gun3P_ScopeTick()
check(viewer.calls.RequestFirstPerson == 1, "overlay gone: no more requests (the engine returns to third person)")

-- player 1 switches to another tool: the copy goes
viewer.tool[1] = "sledge"
viewer.client.render(1/60)
check(viewer.client.gun3p[1] == nil and viewer.valid[1000] == nil, "player switched tool: copy deleted")

-- player 1 takes the RPG-7: the copy is scaled so its longest part (part 6, 40 voxels = 4 m) is GUN3P_TOOL's length,
-- and while aiming the tube's axis point goes to the shouldered pose
holder.tool[1], viewer.tool[1] = "gun-rpg", "gun-rpg"
holder.T = holder.T + 3
holder.client.render(1/60)
relay()
viewer.inputs.grab = nil
viewer.client.render(1/60)
local r = viewer.client.gun3p[1]
local spec = viewer.GUN3P_TOOL["gun-rpg"]
check(r and not r.failed and near(r.scale, spec.length / 4.0), "RPG copy scaled to " .. spec.length .. " m long (scale " .. tostring(r and r.scale) .. ")")
check(viewer.spawnXml:match('scale="0%.2500"'), "RPG copy parts at that scale")
viewer.inputs.grab = true
for _ = 1, 120 do viewer.client.render(1/60) end
local tp, ax, ap = viewer.POSE[1].pos, spec.axis, spec.action.pos
check(near(tp[2] + ax[2] * r.scale, ap[2]) and near(tp[3] + ax[3] * r.scale, ap[3]) and near(tp[1] + ax[1] * r.scale, ap[1]),
	"RPG aimed: the tube's axis on the shoulder (the RPG's own action pose)")
viewer.inputs.grab = nil
viewer.T = viewer.T + 3
for _ = 1, 120 do viewer.client.render(1/60) end
check(near(r.pose.pos[2], run[2]), "RPG not aimed: the rifles' low pose")
viewer.tool[1] = "sledge"
viewer.client.render(1/60)
holder.tool[1] = "gun-akm"

-- the holder in third person: its own gun copied, its tool hidden; back to first person restores it
holder.R["game.thirdperson"] = true
holder.client.render(1/60)
check(holder.client.gun3p[1] and holder.spawned == 1 and hidden(holder, 103), "holder in third person: own gun copied, tool hidden")
check(hidden(holder, 1011), "holder in third person: fake hands not copied")
check(holder.POSE[1] == nil and holder.HANDS[1] and holder.HANDS[1][1] and holder.HANDS[1][2],
	"holder in third person: the gun script keeps placing its tool (no override), hands set in its frame")
holder.R["game.thirdperson"] = false
holder.client.render(1/60)
check(holder.client.gun3p[1] == nil and not hidden(holder, 103), "back to first person: copy deleted, tool shown")

-- a machine where the copy can't be built keeps the old look
local other = machine(2)
other.spawnOk = false
holder.client.gunPartsFull = 0
holder.T = 10
holder.client.render(1/60)
for _, s in ipairs(holder.sent) do if s.fn == "server.gunParts" then other.client.gunParts(unpack(s.args)) end end
holder.sent = {}
other.client.render(1/60)
check(other.client.gun3p[1] and other.client.gun3p[1].failed and not hidden(other, 103), "copy failed: tool not hidden")
other.client.render(1/60)
check(other.spawned == 0, "copy failed: not retried every frame")

for _, e in ipairs({ holder, viewer, other }) do
	for n in pairs(e.violations) do error("FAIL: wrong-side call " .. n) end
end
print("all third-person gun tests passed")

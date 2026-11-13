-- Mock test for the AS350 helicopter v2 port (main/AS350/script/Heli.lua + HeliV2.lua + HeliPilot.lua, rocket.lua).
-- Run from the repo root with Lua 5.1:  lua5.1 tools/porting/tests/test_heli.lua
dofile("tools/porting/tests/mockengine.lua")

local function check(cond, msg) if not cond then error("FAIL: " .. msg, 2) end print("ok  " .. msg) end
local PATH = "main/AS350/script/Heli.lua"

-- real quaternions (x, y, z, w); Teardown's QuatEuler applies Y, then Z, then X (as profile_avf_foliage.lua)
local function qmul(a, b)
	return { a[4]*b[1] + a[1]*b[4] + a[2]*b[3] - a[3]*b[2], a[4]*b[2] - a[1]*b[3] + a[2]*b[4] + a[3]*b[1],
		a[4]*b[3] + a[1]*b[2] - a[2]*b[1] + a[3]*b[4], a[4]*b[4] - a[1]*b[1] - a[2]*b[2] - a[3]*b[3] }
end
local function qaxis(ax, ay, az, deg)
	local h = math.rad(deg) / 2
	local s = math.sin(h)
	return { ax * s, ay * s, az * s, math.cos(h) }
end
local function qrot(q, v)
	local p = qmul(qmul(q, { v[1], v[2], v[3], 0 }), { -q[1], -q[2], -q[3], q[4] })
	return { p[1], p[2], p[3] }
end

local function newHeli(tags)
	local e = MockEngine.load(PATH, { preload = MockEngine.includes(PATH) })
	e.QuatEuler = function(x, y, z) return qmul(qmul(qaxis(0, 1, 0, y or 0), qaxis(0, 0, 1, z or 0)), qaxis(1, 0, 0, x or 0)) end
	e.QuatRotateVec = function(q, v) return qrot(q, v) end
	e.QuatRotateQuat = function(a, b) return qmul(a, b) end
	e.TransformCopy = function(t) return e.Transform(e.VecCopy(t.pos), { t.rot[1], t.rot[2], t.rot[3], t.rot[4] }) end
	e.QuatLookAt = function() return e.Quat() end
	e.QuatSlerp = function(a) return a end
	e.PLAYERS = { [1] = { pos = { 0, 0, 30 }, health = 1 }, [2] = { pos = { 5, 0, 30 }, health = 1 } }
	e.ORDER = { 1, 2 }
	local S = { VEH = {}, DRV = {}, DOWN = { [1] = {}, [2] = {} }, PRESSED = { [1] = {}, [2] = {} }, IMP = {},
		ANG = nil, DRIVE = {}, TAGS = {}, INTERACT = {}, JOINT = {} }
	e.S = S
	local BODIES = { Heli = 10, rotor = 11, s_rotor = 12, gun = 13, rocket = 14 }
	e.def("FindBody", function(n) return BODIES[n] or 0 end)
	e.def("FindBodies", function() return { 10, 11, 12, 13 } end)
	e.def("FindShape", function(n) return ({ PilotTorso = 30, engine = 31, tail = 32, panel_left = 33, rocket = 34 })[n] or 35 end)
	e.def("FindShapes", function(n) return n == "PilotHead" and { 40, 41 } or {} end)
	e.def("FindJoints", function(n) return n == "frontdoor" and { 80 } or {} end)
	e.def("GetJointShapes", function(j) return j == 80 and { 81, 110 } or {} end)
	e.def("GetShapeWorldTransform", function(s) return e.Transform(s == 81 and e.Vec(1, 20, 0) or e.Vec(0, 20, 0)) end)
	e.def("SetPlayerVehicle", function(v, p) S.VEH[p] = v end)
	S.TOOL = { [1] = "gun-ak74", [2] = "gun-tt33" }
	e.def("GetPlayerTool", function(p) return S.TOOL[p] or "" end)
	e.def("SetPlayerTool", function(t, p) S.TOOL[p] = t end)
	e.def("FindJoint", function(n) return ({ s_rotor = 50, MainRotor = 51, gun = 52 })[n] or 53 end)
	e.def("FindTriggers", function(tag)
		if tag ~= "hitbox" then return {} end
		return { 60, 61, 62, 63, 64, 65, 70, 71, 72, 73, 74, 75 }
	end)
	local LIMB = { "HEAD", "LARM", "LLEG", "RARM", "RLEG", "TORSO" }
	e.def("GetTagValue", function(h, t)
		if t == "hitbox" and h >= 60 and h <= 75 then return LIMB[(h % 10) + 1] end
		if t == "hitbox_player" and h >= 70 then return "2" end
		if t == "team" then return "mil" end
		return ""
	end)
	e.def("HasTag", function(h, t)
		if t == "hitbox_player" then return h >= 70 and h <= 75 end
		if t == "parked" then return h == 10 and tags.parked == true end
		return false
	end)
	e.def("SetTag", function(h, t, v) S.TAGS[#S.TAGS + 1] = { h, t, v } end)
	e.def("GetBodyVehicle", function(b) return b == 10 and 9 or 0 end)
	e.def("GetBodyMass", function(b) return b == 10 and 1500 or 100 end)
	e.def("GetJointedBodies", function(b) return b == 10 and { 11, 12, 13, 20 } or {} end)
	e.def("GetShapeVoxelCount", function(s) return s == 41 and 50 or 1000 end)
	e.def("GetBodyShapes", function(b) return { b + 100 } end)
	e.def("GetJointOtherShape", function() return 111 end)
	e.def("GetShapeBody", function(s) if s == 81 then return 20 end return s == 111 and 10 or (s >= 100 and s - 100 or 10) end)
	e.def("IsHandleValid", function(h) return h ~= 0 end)
	e.def("IsShapeBroken", function() return false end)
	e.def("IsJointBroken", function() return false end)
	e.def("QueryRaycast", function() return false, 0, e.Vec(), 0 end)
	e.def("QueryClosestPoint", function() return false end)
	e.def("GetJointMovement", function(j) S.JOINT[j] = ((S.JOINT[j] or 0) + (S.SPIN or 0)) % 360 return S.JOINT[j] end)
	e.def("GetBodyTransform", function() return e.Transform(e.Vec(0, 20, 0)) end)
	e.def("GetPlayerVehicle", function(p) return S.VEH[p] or 0 end)
	e.def("IsPlayerVehicleDriver", function(v, p) return S.VEH[p] == v and S.DRV[p] == true end)
	e.def("InputDown", function(n, p) return (p and S.DOWN[p] and S.DOWN[p][n]) or false end)
	e.def("InputPressed", function(n, p) return (p and S.PRESSED[p] and S.PRESSED[p][n]) or false end)
	e.def("GetPlayerInteractShape", function(p) return S.INTERACT[p] or 0 end)
	e.def("DriveVehicle", function(v, d, s, hb) S.DRIVE[#S.DRIVE + 1] = { v, d, s, hb } end)
	e.def("ApplyBodyImpulse", function(b, pos, imp) S.IMP[#S.IMP + 1] = { b = b, imp = imp } end)
	e.def("SetBodyAngularVelocity", function(b, w) S.ANG = w end)
	e.def("GetBodyAngularVelocity", function() return e.Vec() end)
	e.def("ListKeys", function() return {} end)
	e.def("GetLocationTransform", function() return e.Transform(e.Vec(0, 22, 0)) end)
	return e, S
end

local function ticks(e, n)
	for i = 1, n do e.server.tick(1 / 60) e.server.update(1 / 60) end
end

-------------------------------------------------------------------------------- hostile helicopter, nobody aboard
local e, S = newHeli({})
e.HELI_DEBUG = true -- (the readout is off in the game; on here to check it reaches the client)
e.server.init()
check(e.HeliVehicle == 9, "server.init: the helicopter's vehicle (GetBodyVehicle of body Heli)")
check(e.IsHostile == true and e.TargetSelectionMode == true, "enemy heli: hostile, starts its ride autopilot (QuickStartRide)")
ticks(e, 30)
check(next(e.violations) == nil, "no client-only calls on the server (AI flying)")
check(e.shared.hePilot == 0 and e.shared.heHostile == true and e.shared.heEngineOn == true, "shared state for the clients")
check(e.TargetPlayer == 1 or e.TargetPlayer == 2, "AI target: one of the players (v1: the one player)")

-------------------------------------------------------------------------------- player 2 takes the pilot seat
S.VEH[2], S.DRV[2] = 9, true
S.DRIVE = {}
ticks(e, 1)
check(e.PilotId == 2 and e.DetailedControl and e.IsHostile == false, "driver seat = pilot: control taken, no longer hostile")
check(e.shared.hePilot == 2, "pilot shared with the clients")
check(#S.DRIVE >= 1 and S.DRIVE[1][1] == 9 and S.DRIVE[1][2] == 0 and S.DRIVE[1][3] == 0, "drive input held at 0 while seated")
check(S.TOOL[2] == "" and S.TOOL[1] == "gun-ak74", "pilot's hands empty while flying (no lean-out on RMB); others keep theirs")

e.server.heliAim(1, e.Vec(1, 0, 0), e.Vec(10, 0, 0))
check(e.PilotLook == nil, "aim of a player who is not the pilot ignored")
e.server.heliAim(2, e.Vec(1, 0, 0), e.Vec(30, 20, 0))
check(e.PilotLook[1] == 1 and e.PilotAimPoint[1] == 30, "pilot's aim stored")

-- rotor at speed: 15 degrees per update = MaxRotorSpeed_Def
S.SPIN = 15
S.DOWN[2].up = true
S.IMP = {}
ticks(e, 2)
local lift = 0
for _, i in ipairs(S.IMP) do if i.b == 10 and i.imp[2] > lift then lift = i.imp[2] end end
check(lift > 1800 * 10 / 60, "W: lift above the weight (climb)")
check(S.ANG and S.ANG[2] > 0, "view to the left (+x): the helicopter turns that way (+y)")
e.server.heliAim(2, e.Vec(0, -0.5, 0.866), e.Vec(0, 0, 30))
ticks(e, 1)
check(S.ANG[1] > 0, "view 30 degrees down: nose down (rotation about +x)")
S.DOWN[2].up = false
S.DOWN[2].down = true
S.IMP = {}
ticks(e, 1)
local l2 = 0
for _, i in ipairs(S.IMP) do if i.b == 10 and i.imp[2] > l2 then l2 = i.imp[2] end end
check(l2 < 1800 * 10 / 60, "S: lift below the weight (descend)")
check(e.shared.heDbg_lean ~= nil and e.shared.heDbg_rotor ~= nil, "test readout values shared with the pilot's client")
S.DOWN[2].down = false

-- gun: left mouse past the start-up time, then shots reach the clients
ticks(e, 600) -- InitTimeUp (10 s)
e.sent = {}
S.DOWN[2].lmb = true
ticks(e, 60)
local shots = 0
for _, c in ipairs(e.sent) do if c.fn == "client.heliShot" then shots = shots + 1 end end
check(e.EnableGun and shots > 0, "left mouse: the gun fires, each shot sent to the clients (" .. shots .. ")")
-- shots go at the crosshair point (gun at (0, 20, 0) facing +z in the mock; point 4 m to the side at 40 m)
e.server.heliAim(2, e.Vec(0, 0, 1), e.Vec(4, 20, 40.6))
e.sent = {}
ticks(e, 240)
local sx, n = 0, 0
for _, c in ipairs(e.sent) do if c.fn == "client.heliShot" then sx, n = sx + c.args[2][1], n + 1 end end
check(n > 0 and sx / n > 0.07, "player's shots lean toward the crosshair point (mean x " .. (n > 0 and sx / n or 0) .. ", barrel: 0)")
S.DOWN[2].lmb = false
check(next(e.violations) == nil, "no client-only calls on the server (player flying)")

-- a bullet next to player 2 damages player 2 (its own hitboxes), not the host
S.TAGS = {}
e.def("QueryRaycast", function() return true, 0.5, e.Vec(0, 1, 0), 35 end)
e.def("GetShapeMaterialAtPosition", function() return "dirt", 0.5, 0.4, 0.3, 1 end)
local hits2, hits1 = 0, 0
for i = 1, 400 do
	local sh = { active = true, pos = e.Vec(5, 1.3, 30), momentum = 5, predictedBulletVelocity = e.Vec(0, -850, 0) }
	e.ProjectileOperations(sh)
end
for _, t in ipairs(S.TAGS) do
	if t[2] == "QueriedDamage" then if t[1] >= 70 then hits2 = hits2 + 1 else hits1 = hits1 + 1 end end
end
check(hits2 > 0 and hits1 == 0, "bullet beside player 2: player 2's hitboxes (" .. hits2 .. "), none of the host's")
e.def("QueryRaycast", function() return false, 0, e.Vec(), 0 end)

-- pilot leaves: control back to the autopilot, which holds the hover
S.VEH[2] = nil
ticks(e, 1)
check(e.PilotId == 0 and not e.DetailedControl and e.shared.hePilot == 0, "pilot left: control released")
check(S.TOOL[2] == "gun-tt33", "pilot left: their gun back")
check(e.Collective > 0 and e.Collective <= 1.8, "autopilot collective starts at the hover value (" .. e.Collective .. ")")

-- the AI pilot is dead and nobody flies: the crash spiral (in-game 2026-11-13: "attempt to index global 'Val'")
e.PilotDead = true
ticks(e, 30)
check(e.WeAreGoingDown == true, "pilot dead, nobody flying: going down (crash spiral runs without the tuning options)")

-------------------------------------------------------------------------------- parked helicopter: "Take a ride"
local p, PS = newHeli({ parked = true })
p.server.init()
check(p.IsHostile == false and p.TargetSelectionMode == false and p.IsFlying == false, "parked: not hostile, on the ground, engine off")
local rideTags, doorTag = {}, nil
for _, t in ipairs(PS.TAGS) do
	if t[2] == "interact" and t[3] == "Take a ride" then rideTags[#rideTags + 1] = t[1] end
	if t[2] == "interact" and t[1] == 81 then doorTag = t[3] end
end
check(#rideTags == 1 and rideTags[1] == 40, "\"Take a ride\" on one shape only (the largest head shape)")
check(doorTag == "Fly helicopter", "pilot-side front door: \"Fly helicopter\" prompt")
PS.INTERACT[1] = 81
PS.PRESSED[1].interact = true
ticks(p, 1)
check(PS.VEH[1] == 9, "E on the door: into the helicopter")
ticks(p, 1)
PS.VEH[1] = nil -- the same E press got the player out (engine)
ticks(p, 1)
check(PS.VEH[1] == nil, "the E that leaves the helicopter does not get the player back in")
PS.PRESSED[1].interact = false
PS.INTERACT[1] = nil
ticks(p, 1)
PS.INTERACT[2] = 40 -- player 2 looks at the pilot's head
PS.PRESSED[2].interact = true
ticks(p, 1)
PS.PRESSED[2].interact = false
check(p.TargetSelectionMode and p.Commander == 2 and p.shared.heCommander == 2, "player 2 uses the pilot: ride started, player 2 commands")
PS.PRESSED[1].interact = true
ticks(p, 1)
PS.PRESSED[1].interact = false
check(p.TargetSelectionMode and p.Commander == 2, "another player's E does not end player 2's ride")
PS.PRESSED[2].interact = true
ticks(p, 1)
PS.PRESSED[2].interact = false
check(not p.TargetSelectionMode and p.Commander == 0, "player 2's E ends the ride")
check(next(p.violations) == nil, "no client-only calls on the server (ride)")

-------------------------------------------------------------------------------- client of the pilot
local c, CS = newHeli({})
c.side = "client"
c.LOCAL = 2
local CAM
c.def("SetCameraTransform", function(t) CAM = t end)
c.client.init()
c.shared.hePilot = 2
c.shared.heEngineOn = true
c.shared.heRot = 1
c.client.tick(1 / 60)
c.client.update(1 / 60)
c.client.draw()
check(CAM ~= nil, "pilot's client sets the camera")
local aim
for _, m in ipairs(c.sent) do if m.fn == "server.heliAim" then aim = m end end
check(aim and aim.args[1] == 2 and aim.args[2] and aim.args[3], "pilot's client sends look and aim point")
check(math.abs(c.VecLength(aim.args[2]) - 1) < 1e-6, "look direction is a unit vector")
c.client.heliShot(c.Vec(0, 20, 1), c.Vec(0, 0, 1), c.Vec(0, 20, 1.6))
check(#c.ClientShells == 1, "a shot: one tracer to draw")
c.client.tick(1 / 60)
check((c.calls.DrawLine or 0) > 0, "tracer drawn")
c.client.heliCrash()
check(next(c.violations) == nil, "no server-only calls on the client")
c.LOCAL = 1
c.client.tick(1 / 60)
c.client.draw()
check(not c.PilotIsLocal, "another player's client: no pilot camera")

-------------------------------------------------------------------------------- rocket
local R = "main/AS350/script/rocket.lua"
local r = MockEngine.load(R, { preload = MockEngine.includes(R) })
r.PLAYERS = { [1] = { pos = { 0, 0, 0 }, health = 1 }, [2] = { pos = { 0, 0, 50 }, health = 1 } }
r.ORDER = { 1, 2 }
r.def("FindBody", function() return 5 end)
r.def("FindShape", function() return 6 end)
r.def("GetBodyMass", function() return 291 end)
r.def("IsShapeBroken", function() return false end)
r.def("IsHandleValid", function() return true end)
r.def("QueryClosestPoint", function() return false end)
r.def("QueryRaycast", function() return false, 0, r.Vec(), 0 end)
r.def("GetBodyTransform", function() return r.Transform(r.Vec(0, 10, 25)) end)
r.def("QuatRotateVec", function(q, v) return r.VecCopy(v) end)
r.def("HasKey", function() return false end)
r.server.init()
check(r.shared.active == true, "rocket: flying")
for i = 1, 120 do r.server.update(1 / 60) end
check((r.calls.Explosion or 0) == 1 and r.shared.active == false, "rocket: explodes once (auto-detonation)")
check(next(r.violations) == nil, "rocket: no client-only calls on the server")
r.side = "client"
r.shared.active = true
r.client.init()
r.client.update(1 / 60)
check((r.calls.PlayLoop or 0) == 1 and (r.calls.SpawnParticle or 0) > 0, "rocket client: sound and trail")
check(next(r.violations) == nil, "rocket: no server-only calls on the client")
print("all heli tests passed")

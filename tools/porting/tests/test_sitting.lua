-- Mock test for NPC seating on the vehicles' passenger seat rigs (npcs/GoreNPCs/scripts/systems/goreai_sitting.lua),
-- loaded through the real goreai_main.lua include chain. Run from the repo root with Lua 5.1:
--   lua5.1 tools/porting/tests/test_sitting.lua
dofile("tools/porting/tests/mockengine.lua")

local function check(cond, msg) if not cond then error("FAIL: " .. msg, 2) end print("ok  " .. msg) end
local MAIN = "npcs/GoreNPCs/scripts/goreai_main.lua"

-- real rotation math (the mock engine's transforms ignore rotation)
local function qmul(a, b)
	return { a[4]*b[1] + a[1]*b[4] + a[2]*b[3] - a[3]*b[2], a[4]*b[2] - a[1]*b[3] + a[2]*b[4] + a[3]*b[1],
		a[4]*b[3] + a[1]*b[2] - a[2]*b[1] + a[3]*b[4], a[4]*b[4] - a[1]*b[1] - a[2]*b[2] - a[3]*b[3] }
end
local function qconj(q) return { -q[1], -q[2], -q[3], q[4] } end
local function qrot(q, v) local r = qmul(qmul(q, { v[1], v[2], v[3], 0 }), qconj(q)) return { r[1], r[2], r[3] } end
local function qaxis(ax, deg) local h = math.rad(deg) / 2 local s = math.sin(h)
	return { ax[1]*s, ax[2]*s, ax[3]*s, math.cos(h) } end
local function real_math(e)
	e.QuatRotateVec = qrot
	e.QuatRotateQuat = qmul
	e.QuatEuler = function(x, y, z) return qmul(qmul(qaxis({0,1,0}, y or 0), qaxis({0,0,1}, z or 0)), qaxis({1,0,0}, x or 0)) end
	e.QuatDeltaVectors = function(a, b)
		a, b = e.VecNormalize(a), e.VecNormalize(b)
		local c = { a[2]*b[3]-a[3]*b[2], a[3]*b[1]-a[1]*b[3], a[1]*b[2]-a[2]*b[1] }
		local q = { c[1], c[2], c[3], 1 + e.VecDot(a, b) }
		local l = math.sqrt(q[1]^2 + q[2]^2 + q[3]^2 + q[4]^2) return { q[1]/l, q[2]/l, q[3]/l, q[4]/l }
	end
	e.QuatSlerp = function(a, b, t)
		local d = a[1]*b[1] + a[2]*b[2] + a[3]*b[3] + a[4]*b[4]
		if d < 0 then b = { -b[1], -b[2], -b[3], -b[4] } d = -d end
		if d > 0.9995 then local r = {} for i = 1, 4 do r[i] = a[i] + (b[i]-a[i])*t end
			local l = math.sqrt(r[1]^2+r[2]^2+r[3]^2+r[4]^2) return { r[1]/l, r[2]/l, r[3]/l, r[4]/l } end
		local th = math.acos(d) local s = math.sin(th)
		local wa, wb = math.sin((1-t)*th)/s, math.sin(t*th)/s
		return { a[1]*wa+b[1]*wb, a[2]*wa+b[2]*wb, a[3]*wa+b[3]*wb, a[4]*wa+b[4]*wb }
	end
	e.TransformToParentPoint = function(t, p) return e.VecAdd(t.pos, qrot(t.rot, p)) end
	e.TransformToParentVec = function(t, v) return qrot(t.rot, v) end
	e.TransformToLocalVec = function(t, v) return qrot(qconj(t.rot), v) end
	e.TransformToParentTransform = function(t, l) return e.Transform(e.TransformToParentPoint(t, l.pos), qmul(t.rot, l.rot)) end
	e.TransformToLocalTransform = function(t, w)
		return e.Transform(qrot(qconj(t.rot), e.VecSub(w.pos, t.pos)), qmul(qconj(t.rot), w.rot)) end
end
local function near(a, b, tol) for i = 1, 3 do if math.abs(a[i] - b[i]) > (tol or 0.011) then return false end end return true end

local V = 500
local SORT = { [601] = 0, [602] = 1, [603] = 2, [604] = 3, [605] = 4 } -- 605: a "floor" rig (cargo floor)

local function load(side)
	local env = MockEngine.load(MAIN, { preload = MockEngine.includes(MAIN) })
	env.side = side
	real_math(env)
	env.PLAYERS = { [1] = { pos = {0,0,0}, health = 1 }, [2] = { pos = {5,0,0}, health = 1 } }
	env.ORDER = { 1, 2 }
	env.RIGS = {}      -- [player] = rig the player sits in
	env.GONE = {}      -- rigs that no longer exist
	env.def("IsHandleValid", function(h) return h ~= nil and h ~= 0 end)
	env.def("GetEntityChildren", function(h, tag, rec, typ)
		if h == V and typ == "rig" then return { 603, 601, 605, 604, 602 } end
		return {}
	end)
	env.def("HasTag", function(h, tag) return (tag == "driver" and h == 601) or (tag == "floor" and h == 605) end)
	env.def("GetTagValue", function(h, tag) return tag == "sort" and tostring(SORT[h]) or "" end)
	env.def("GetRigLocationWorldTransform", function(r, name)
		if SORT[r] and not env.GONE[r] and name == "seat" then return env.Transform({ r, 1, 0 }) end
		return nil
	end)
	env.def("GetPlayerRig", function(p) return env.RIGS[p] or 0 end)
	env.def("GetBodyTransform", function(b) return env.Transform({ b, 0, 0 }) end)
	env.def("AabbGetBodyCenterPos", function() return env.Vec() end)
	env.def("truncateToGround", function() return nil end)
	env.def("GetVehicleDimensions", function() return 2, 2, 4 end)
	env.def("GetBodyVelocity", function() return env.Vec() end)
	env.def("PlaySound", function() end)
	env.Sounds = { seat = { 1 } }
	env.moved = {}
	env.def("npc_move_to_pos", function(npc, pos) env.moved[npc.id] = pos end)
	return env
end

local function npc(id, seat)
	return {
		id = id, isFriendly = true, dead = false, Head = id + 1, AllShapes = {}, AllBodies = {},
		ai = { sitting = { isSitting = seat ~= nil, sitLight = seat or 0, sitVehicle = seat and V or 0,
			sitBody = seat and 77 or 0 }, stun = { velocity = 5, duration = 0 } },
	}
end

------------------------------------------------------------------ 1. seats of a vehicle
local srv = load("server")
local seats = srv.get_vehicle_seats(V)
check(#seats == 3 and seats[1] == 602 and seats[2] == 603 and seats[3] == 604,
	"passenger rigs only (driver and floor rigs excluded), in sort order")
check(#srv.get_vehicle_seats(0) == 0, "no vehicle: no seats")

------------------------------------------------------------------ 2. players come first
srv.RIGS[2] = 603
local empty = srv.get_vehicle_empty_seats(V)
check(#empty == 2 and empty[1] == 602 and empty[2] == 604, "a seat a player sits in is not offered to NPCs")

------------------------------------------------------------------ 3. player takes an NPC's seat -> NPC moves over
srv.NPCs = { a = npc(10, 603) }
srv.tick_sitting()
check(srv.NPCs.a.ai.sitting.isSitting and srv.NPCs.a.ai.sitting.sitLight == 602,
	"NPC in the seat player 2 took moves to the first free seat")
check(srv.shared.goreSeats["602"] and not srv.shared.goreSeats["603"] and srv.shared.goreSeatsShow,
	"shared.goreSeats lists the NPC seat; icons shown while a friendly NPC exists")

------------------------------------------------------------------ 4. no free seat left -> NPC gets out
srv.RIGS[1] = 602
srv.NPCs.b = npc(20, 604)
srv.tick_sitting()
local a = srv.NPCs.a.ai.sitting
check(not a.isSitting and a.sitLight == 0 and srv.moved[10] ~= nil, "no free seat: the NPC gets out next to the car")
check(srv.NPCs.b.ai.sitting.sitLight == 604 and srv.shared.goreSeats["604"] and not srv.shared.goreSeats["602"],
	"the other NPC keeps its seat; shared state follows")

------------------------------------------------------------------ 5. seat deleted -> NPC gets out
srv.RIGS = {}
srv.GONE[604] = true
srv.tick_sitting()
check(not srv.NPCs.b.ai.sitting.isSitting, "seat no longer exists: the NPC gets out")
srv.GONE = {}

------------------------------------------------------------------ 6. sit pose
local ID = { 0, 0, 0, 1 }
local LOCS = {}
srv.def("GetRigWorldTransform", function(r) return srv.Transform({ 0, 0, 0 }, ID) end)
srv.def("GetRigLocationWorldTransform", function(r, name)
	if srv.GONE[r] then return nil end
	local l = LOCS[name]
	return l and srv.Transform(l[1], l[2]) or nil
end)
local n = npc(30, 602)

-- upright seat (Humvee, UAZ, GAZ rear, SUV: checked in-game): head 0.65 above and 0.1 behind the seat point
LOCS = { seat = { { 0.7, 1.2, -0.45 }, ID } }
local h = srv.npc_sitting_head_transform(n)
check(near(h.pos, { 0.7, 1.85, -0.35 }, 1e-6), "upright seat: head 0.65 m above and 0.1 m behind the seat point")
check(srv.npc_sitting_pose(n) == srv.RagdollPoses.sit, "upright seat: the plain sit pose")

-- numbers below from Blender (blender_vehicle.py merc/npc_head/npc_pose on the real vehicles)
local function lean_of(t) return math.deg(math.acos(math.min(1, qrot(t.rot, { 0, 1, 0 })[2]))) end
local GAZ_SEAT = { { 0.53, 0.59, -0.29 }, srv.QuatEuler(55, 0, 0) }
local GAZ_FEET = { { 0.38, 0.4, -0.75 }, { 0.68, 0.4, -0.75 } }

-- GAZ-24 front passenger (seat rot x 55, our ik_head 0.8 up / 0.15 back): the player's head is IK'd there, nearly
-- upright, so the NPC sits upright as checked in-game
LOCS = { seat = GAZ_SEAT, ik_head = { { 0.53, 1.39, -0.14 }, ID },
	ik_foot_l = { GAZ_FEET[1], ID }, ik_foot_r = { GAZ_FEET[2], ID } }
h = srv.npc_sitting_head_transform(n)
check(lean_of(h) < 1, "tilted seat with ik_head (GAZ-24 55): NPC upright like the player's IK'd spine")
check(near(h.pos, { 0.53, 1.27, -0.19 }), "GAZ-24: head where Blender puts it (0.53, 1.27, -0.19)")

-- sports car passenger (official rig: seat rot x 80, ik_head 0.55 up / 0.325 back): leans ~27 deg toward ik_head;
-- hips at floor level, so the legs tilt forward to the foot points (feet on the floor, 0.41)
LOCS = { seat = { { 0.35, 0.4, -0.5 }, srv.QuatEuler(80, 0, 0) }, ik_head = { { 0.35, 0.95, -0.175 }, ID },
	ik_foot_l = { { 0.25, 0.4, -1.15 }, ID }, ik_foot_r = { { 0.55, 0.4, -1.15 }, ID } }
h = srv.npc_sitting_head_transform(n)
check(math.abs(lean_of(h) - 26.6) < 0.2, "sports car: NPC leans 26.6 deg toward ik_head")
check(near(h.pos, { 0.35, 0.99, -0.13 }), "sports car: head where Blender puts it (0.35, 0.99, -0.13)")
local pose = srv.npc_sitting_pose(n)
local foot = srv.TransformToParentTransform(h, pose.RRLEG).pos
check(near(foot, { 0.5, 0.41, -0.97 }), "sports car: legs stay with the vehicle, feet toward ik_foot (0.5, 0.41, -0.97)")
check(pose.Torso == srv.RagdollPoses.sit.Torso, "sports car: upper body keeps the sit pose")

-- tilted seat without ik_head: the player's whole body leans with the eased seat rotation, so does the NPC
LOCS = { seat = GAZ_SEAT, ik_foot_l = { GAZ_FEET[1], ID }, ik_foot_r = { GAZ_FEET[2], ID } }
h = srv.npc_sitting_head_transform(n)
check(math.abs(lean_of(h) - 36.9) < 0.2, "tilted seat, no ik_head: NPC leans like the player (55 -> 36.9 deg)")
check(near(h.pos, { 0.53, 1.08, 0.18 }), "no ik_head: head where Blender puts it (0.53, 1.08, 0.18)")
srv.GONE[602] = true
check(srv.npc_sitting_head_transform(n).pos[1] == 31, "seat gone: pose falls back to the NPC's own head")
check(next(srv.violations) == nil, "server: no client-only calls")

------------------------------------------------------------------ 7. client icons
local cli = load("client")
cli.LOCAL = 2
cli.RIGS[1] = 602                       -- player 1 sits in seat 1
cli.shared.goreSeats = { ["604"] = true } -- an NPC sits in seat 3
cli.shared.goreSeatsShow = true
cli.def("IsInfrontOfCamera", function() return true end)
local red, green = 0, 0
cli.def("UiColor", function(r, g, b, al)
	if r == 1 and g == 0 and b == 0 then red = red + 1 elseif r == 0 and g == 1 and b == 0 then green = green + 1 end
end)
cli.draw_vehicle_empty_seats(V)
check(red == 2 and green == 1, "icons: 2 taken (player + NPC) red, 1 free green")
red, green = 0, 0
cli.shared.goreSeatsShow = false
cli.draw_vehicle_empty_seats(V)
check(red + green == 0, "no friendly NPCs: no icons")
check(next(cli.violations) == nil, "client: no server-only calls")

print("all sitting tests passed")

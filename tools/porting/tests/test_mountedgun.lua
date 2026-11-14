-- Mock test for vehicles/MountedGun.lua through a vehicle config (vehicles/avf/prefabs/technicals/technical_dshk.lua).
-- Run from the repo root with Lua 5.1:  lua5.1 tools/porting/tests/test_mountedgun.lua
dofile("tools/porting/tests/mockengine.lua")

local function check(cond, msg) if not cond then error("FAIL: " .. msg, 2) end print("ok  " .. msg) end
local PATH = "vehicles/avf/prefabs/technicals/technical_dshk.lua"

local env = MockEngine.load(PATH, { preload = MockEngine.includes(PATH) })
env.side = "server"
env.PLAYERS = { [1] = { pos = { 0, 0, 0 }, health = 1 }, [2] = { pos = { 5, 0, 0 }, health = 1 } }
env.ORDER = { 1, 2 }
-- vehicle 9; turret shape 20 (body 120), gun shape 21 (body 121); joints 31 (yaw) / 32 (pitch); rig 40; emitter 50
local TAGS = { [20] = "turret", [21] = "gun", [31] = "turretJoint", [32] = "gunJoint" }
local S = { VEH = {}, RIG = {}, MOVE = { [31] = 0, [32] = 0 }, MOTOR = {}, TARGET = {} }
env.def("FindVehicle", function(tag) return tag == "cfg" and 9 or 0 end)
env.def("FindShapes", function(tag) return tag == "component" and { 20, 21 } or tag == "mainCannon" and { 21 } or {} end)
env.def("FindJoints", function(tag) return tag == "component" and { 31, 32 } or {} end)
env.def("GetTagValue", function(h, tag) return tag == "component" and TAGS[h] or "" end)
env.def("FindRig", function(tag) return tag == "gunner" and 40 or 0 end)
env.def("FindLocation", function(tag) return tag == "mainCannon_emitter" and 50 or 0 end)
env.def("GetLocationTransform", function() return env.Transform({ 0, 0, -1 }) end) -- 1 m ahead of the gun centre
env.def("GetShapeBounds", function() return { -0.1, -0.1, -0.5 }, { 0.1, 0.1, 0.5 } end) -- centre (0,0,0)
-- gun model: 2 x 2 x 10 voxels of 0.1 m, identity transform: long axis z, centre (0.1, 0.1, 0.5)
env.def("GetShapeSize", function() return 2, 2, 10, 0.1 end)
env.def("GetShapeWorldTransform", function() return env.Transform({ 0, 0, 0 }) end)
local RIGLOC = {}
env.def("GetRigLocationWorldTransform", function(r, n) return env.Transform({ 0, 0, 1 }) end)
env.def("SetRigLocationWorldTransform", function(r, n, t) RIGLOC[n] = t end)
env.def("GetShapeBody", function(s) return s + 100 end)
env.def("GetBodyTransform", function() return env.Transform({ 0, 0, 0 }) end) -- identity: barrel -> -z
env.def("IsShapeBroken", function() return false end)
env.def("IsJointBroken", function() return false end) -- (the stub returns 0, which Lua counts as true)
env.def("GetPlayerVehicle", function(p) return S.VEH[p] or 0 end)
env.def("GetPlayerRig", function(p) return S.RIG[p] or 0 end)
env.def("GetJointMovement", function(j) return S.MOVE[j] end)
env.def("SetJointMotor", function(j, v) S.MOTOR[j] = v end)
env.def("SetJointMotorTarget", function(j, target) S.TARGET[j] = target end)
env.def("TransformToParentVec", function(t, v) return env.VecCopy(v) end)
env.def("TransformToParentPoint", function(t, v) return env.VecCopy(v) end)
env.def("TransformToLocalPoint", function(t, v) return env.VecCopy(v) end)

env.server.init()
local function near(a, b) return math.abs(a - b) < 1e-6 end
check(env.shared.mgFz == -1 and env.shared.mgFx == 0 and env.shared.mgFy == 0 and near(env.shared.mgMz, -0.05),
	"barrel = the model's long axis toward the emitter: forward -z, muzzle at its end (z -0.05), shared")
-- the van PKM case: emitter 0.45 m below the barrel and barely in front of the centre: still level, still -z
env.def("GetLocationTransform", function() return env.Transform({ 0.1, -0.35, 0.4 }) end)
env.MG_MeasureBarrel()
check(env.shared.mgFz == -1 and env.shared.mgFy == 0, "emitter below the barrel: barrel still level")
env.def("GetLocationTransform", function() return env.Transform({ 0, 0, -1 }) end)
env.MG_MeasureBarrel()
check(env.MG.pose and env.MG.pose.hands.ik_hand_l and env.MG.pose.feet.ik_foot_r, "gunner pose measured (stand, feet, hands)")
do -- the Hummer's M2: a separate, longer barrel shape (22) beside the receiver (21): camera / sight centred on it
	env.def("GetBodyShapes", function() return { 21, 22 } end)
	env.def("GetShapeWorldTransform", function(sh) return env.Transform(sh == 22 and { -0.4, 0, -1 } or { 0, 0, 0 }) end)
	env.def("GetShapeSize", function(sh) if sh == 22 then return 1, 1, 12, 0.1 end return 2, 2, 10, 0.1 end)
	env.def("TransformToParentPoint", function(t, v) return { v[1] + t.pos[1], v[2] + t.pos[2], v[3] + t.pos[3] } end)
	env.MG_MeasureBarrel()
	env.def("TransformToParentPoint", function(t, v) return env.VecCopy(v) end)
	check(near(env.shared.mgCx, -0.35) and near(env.shared.mgSx, -0.35) and near(env.shared.mgSy, 0.3),
		"separate barrel shape: centred on the barrel (x -0.35), sight above the tallest shape (y 0.3)")
	env.def("GetBodyShapes", function() return {} end)
	env.def("GetShapeWorldTransform", function() return env.Transform({ 0, 0, 0 }) end)
	env.def("GetShapeSize", function() return 2, 2, 10, 0.1 end)
	env.MG_MeasureBarrel()
end
check(env.shared.mgAmmo == 50 and env.shared.mgMags == 20, "ammo from the AVF config (DShK: 50 rounds, 20 belts)")

-- nobody on the gun: joints held
env.server.tick(1 / 60)
check(S.TARGET[31] == 0 and S.TARGET[32] == 0, "unmanned: joints held where they are")

-- player 2 (not the host, on foot) presses interact on the gun: on the gunner place, NOT in the vehicle
local TAGSET, TOOL, MOVED = {}, { [1] = "gun-ak74", [2] = "gun-ak74" }, {}
env.def("SetTag", function(h, k, v) TAGSET[h] = v end)
env.def("RemoveTag", function(h, k) TAGSET[h] = nil end)
local PRESS, AIMED = { [2] = true }, { [2] = 21 }
env.def("InputPressed", function(k, p) assert(p and p ~= 0) return k == "interact" and PRESS[p] or false end)
env.def("GetPlayerInteractShape", function(p) return AIMED[p] or 0 end)
env.def("SetPlayerVehicle", function(v, p) S.VEH[p] = v ~= 0 and v or nil end)
env.def("SetPlayerRig", function(r, p) S.RIG[p] = r end)
env.def("GetPlayerHealth", function(p) return env.PLAYERS[p].health end)
env.def("GetPlayerTool", function(p) return TOOL[p] end)
env.def("SetPlayerTool", function(id, p) TOOL[p] = id end)
env.def("GetVehicleTransform", function() return env.Transform({ 0, 0, 0 }) end)
env.def("GetVehicleBody", function() return 109 end)
env.def("GetVehiclePassengerCount", function() return 0, 2, false end)
env.def("GetRigWorldTransform", function() return env.Transform({ 5, 0, 0 }) end)
env.def("GetPlayerTransform", function(p) return env.Transform(env.PLAYERS[p].pos) end)
env.def("SetPlayerTransform", function(t, p) MOVED[p] = t.pos; env.PLAYERS[p].pos = t.pos end)
env.def("SetPlayerVelocity", function() end)
env.def("GetBodyVelocityAtPos", function() return { 0, 0, 0 } end)
env.def("TransformToLocalTransform", function(a, b) return b end)
env.def("TransformToParentTransform", function(a, b) return b end)
env.server.init()
check(TAGSET[21] == "Use mounted gun" and env.shared.mgGunner == 0, "the gun's prompt reads 'Use mounted gun', nobody on it")
env.PLAYERS[2].pos = { 9, 0, 0 }
env.server.tick(1 / 60) -- records where player 2 stands (PRESS is already down: mounts on this tick)
check(env.shared.mgGunner == 2 and S.RIG[2] == 40 and S.VEH[2] == nil, "interact: player 2 on the gunner rig, not in the vehicle")
check(TAGSET[21] == nil and TOOL[2] == "gun-ak74", "manned: prompt removed")
PRESS[2] = false
S.RIG[2] = nil
env.server.tick(1 / 60)
check(S.RIG[2] == 40 and TOOL[2] == "", "every tick: rig set again, hand tool put away")
check(RIGLOC.stand and RIGLOC.ik_hand_l and RIGLOC.ik_foot_l, "every tick: stand, feet and hands follow the turret / gun")
check(MOVED[2] and MOVED[2][1] == 0 and MOVED[2][3] == 1, "rig did not hold the player: moved onto the stand location (turret-relative)")
-- the place is taken: player 1 cannot mount
PRESS[1], AIMED[1] = true, 21
env.server.tick(1 / 60)
check(env.shared.mgGunner == 2 and S.RIG[1] == nil, "gunner place taken: a second player is not moved onto it")
PRESS[1] = false
-- interact again: off the gun, back where they stood, tool back; then on again
PRESS[2] = true
env.server.tick(1 / 60)
check(env.shared.mgGunner == 0 and TOOL[2] == "gun-ak74" and TAGSET[21] == "Use mounted gun", "interact again: off the gun, tool and prompt back")
check(MOVED[2][1] == 9, "put back where they stood before")
PRESS[2] = false
S.RIG[2] = nil -- (mock) the engine clears the rig after SetPlayerRig stops
env.server.tick(1 / 60)
-- the engine seated player 1 on the gun place (real seats full or destroyed) while the gun is free: on the gun from
-- that seat, and still on it on the next ticks (in-game: taken out, then dropped for "in a vehicle", every tick)
S.VEH[1], S.RIG[1] = 9, 40
env.server.tick(1 / 60)
check(S.VEH[1] == 9 and env.shared.mgGunner == 1, "seated on the gun place by the engine: on the gun, left in that seat")
env.server.tick(1 / 60)
env.server.tick(1 / 60)
check(env.shared.mgGunner == 1 and S.VEH[1] == 9, "...and still on the gun on the next ticks (no loop)")
-- (a destroyed / broken-off gun: see the end, MG_Retire)
PRESS[1] = true
env.server.tick(1 / 60)
check(env.shared.mgGunner == 0, "interact in that seat: off the gun, not put straight back on (still seated this tick)")
PRESS[1] = false
env.server.tick(1 / 60)
check(env.shared.mgGunner == 0, "...nor on the next tick, while the engine still has them in the seat")
AIMED[1], S.RIG[1], S.VEH[1] = 0, nil, nil
env.server.tick(1 / 60)
check(env.shared.mgGunner == 0 and env.MG.noRemount[1] == nil, "player 1 off the gun and out of the seat")
-- the engine took the key press as "enter vehicle": the player is already seated when the script sees it
PRESS[2], AIMED[2], S.VEH[2] = true, 0, 9
env.server.tick(1 / 60)
check(env.shared.mgGunner == 2 and S.VEH[2] == nil, "engine seated the player on the same press: taken out, on the gun")
PRESS[2], AIMED[2] = false, 21
-- a driver pressing interact (getting out) while the gun is free is not grabbed
S.VEH[1] = 9
env.server.tick(1 / 60)
env.server.mgAmmo(2, 50, 20)
-- player 2 aims 30 deg to the right (+x)
local a = math.rad(30)
env.server.mgAim(2, { math.sin(a), 0, -math.cos(a) })
S.TARGET[31] = nil
env.server.tick(1 / 60)
check(S.MOTOR[31] == 0.5, "first aim: the yaw joint is probed (direction not known yet)")
-- the probe turned the joint +5 and the barrel's heading +5 (mock: heading = yaw joint movement), while the
-- gunner moved the mouse further right (error 30 -> 40): the barrel decides, not the error
env.MG_BarrelAngles = function() return S.MOVE[31], S.MOVE[32] end
S.MOVE[31] = 5
env.server.mgAim(2, { math.sin(math.rad(40)), 0, -math.cos(math.rad(40)) })
env.server.tick(1 / 60)
check(env.MG.yawJoint.sign == 1, "probe: +movement turned the barrel +, mouse moving meanwhile -> sign +1")
env.server.mgAim(2, { math.sin(math.rad(25)), 0, -math.cos(math.rad(25)) })
env.server.tick(1 / 60)
check(S.TARGET[31] and math.abs(S.TARGET[31] - (5 + 25)) < 0.01, "aiming: yaw target = movement + error (30)")
-- the host's own aim is ignored (not the gunner)
env.server.mgAim(1, { -1, 0, 0 })
env.server.tick(1 / 60)
check(math.abs(S.TARGET[31] - 30) < 0.01, "a non-gunner's aim message is ignored")
-- ammo reports only from the gunner
env.server.mgAmmo(1, 3, 3)
check(env.shared.mgAmmo == 50, "ammo report from a non-gunner ignored")
env.server.mgAmmo(2, 49, 20)
check(env.shared.mgAmmo == 49, "ammo report from the gunner kept for the next gunner")
check(next(env.violations) == nil, "no client-only calls on the server")

-- client side: the local player is the gunner and holds the left mouse button
env.side = "client"
env.LOCAL = 2
local DOWN, PRESSED = {}, {}
env.def("InputDown", function(k) return DOWN[k] or false end)
env.def("InputPressed", function(k) return PRESSED[k] or false end)
env.def("GetPlayerCameraTransform", function() return env.Transform({ 0, 1, 1 }) end) -- looking along -z
local CAM
local MOUSE = { camerax = 0, cameray = 0 }
env.def("InputValue", function(k) return MOUSE[k] or 0 end)
env.def("GetQuatEuler", function() return 0, 0, 0 end)
local FOV
env.def("SetCameraTransform", function(t, fov) CAM, FOV = t, fov end)
env.def("QueryRaycast", function() return false, 0 end)
env.def("GetLocalPlayer", function() return 2 end)
env.def("UiWorldToPixel", function() return 100, 100, 5 end)
local serverMG = env.MG -- (one mock state for both sides: client.init replaces MG)
env.client.init()
env.client.tick(1 / 60)
check(env.MG.ammo == 49 and env.MG.mags == 20, "new gunner picks up the shared ammo")
local aims = 0
for _, s in ipairs(env.sent) do if s.fn == "server.mgAim" then aims = aims + 1 end end
check(aims >= 1, "the gunner's client sends its aim to the server")
check(CAM and near(CAM.pos[1], 0.1) and near(CAM.pos[2], 0.8) and near(CAM.pos[3], 2.7),
	"gunner camera: 0.7 m above and 2.2 m behind the barrel's centre (0.1, 0.1, 0.5), along the look")
MOUSE.camerax, MOUSE.cameray = math.rad(10), math.rad(-5)
env.client.tick(1 / 60)
MOUSE.camerax, MOUSE.cameray = 0, 0
check(math.abs(env.MG.look.yaw - 350) < 1e-6 and math.abs(env.MG.look.pitch - 5) < 1e-6,
	"the camera turns by the mouse itself (not the player's look, which the gunner's body turning would move)")
-- sight view: right mouse held -> eye over the rear half of the barrel, 0.1 above the model's top; wheel zooms
-- (model 2x2x10 voxels, centre (0.1,0.1,0.5), barrel -z: rear half point z = 0.5 + 0.25, top = 0.1 above centre)
DOWN.rmb = true
env.client.tick(1 / 60)
check(CAM and near(CAM.pos[1], 0.1) and near(CAM.pos[2], 0.3) and near(CAM.pos[3], 0.75) and FOV == 70,
	"right mouse: sight view over the rear of the barrel, FOV 70")
-- a wall 0.5 m back from the muzzle toward the eye: the eye moves to 0.1 in front of it (0.4 from the muzzle)
env.def("QueryRaycast", function(o, d, len) if len and len > 0.6 and len < 1 then return true, 0.5 end return false, 0 end)
env.client.tick(1 / 60)
do
	local m = { 0.1, 0.1, -0.05 }
	local e = { 0.1, 0.3, 0.75 }
	local v = { e[1] - m[1], e[2] - m[2], e[3] - m[3] }
	local l = math.sqrt(v[1] ^ 2 + v[2] ^ 2 + v[3] ^ 2)
	check(near(CAM.pos[3], m[3] + v[3] * 0.4 / l) and near(CAM.pos[2], m[2] + v[2] * 0.4 / l),
		"sight view: a wall between muzzle and eye -> eye just in front of it")
end
env.def("QueryRaycast", function() return false, 0 end)
MOUSE.mousewheel = 1
env.client.tick(1 / 60)
MOUSE.mousewheel = 0
check(FOV == 35, "mouse wheel up while sighted: zoom 2 (FOV 35)")
DOWN.rmb = false
env.client.tick(1 / 60)
check(FOV == nil and near(CAM.pos[3], 2.7), "released: back to the view behind the gun")
env.sent = {}
DOWN.lmb = true
env.client.tick(1 / 60)
local fired, ammo
for _, s in ipairs(env.sent) do
	if s.fn == "server.gunFire" then fired = s.args end
	if s.fn == "server.mgAmmo" then ammo = s.args end
end
check(fired and fired[1] == 2 and fired[2].pos[3] < -0.1 and fired[2].predictedBulletVelocity[3] < 0,
	"left mouse: a round goes out through gunnet (owner 2, from the muzzle, along the barrel)")
check(ammo and ammo[2] == 48, "ammo counted down and reported")
env.sent = {}
env.client.tick(1 / 60)
local again = false
for _, s in ipairs(env.sent) do if s.fn == "server.gunFire" then again = true end end
check(not again, "fire rate: no second round within 60/RPM s")
-- reload with R
DOWN.lmb = false
PRESSED.r = true
env.client.tick(1 / 60)
PRESSED.r = false
check(env.MG.reloadTimer > 0, "R starts a reload")
for i = 1, 300 do env.client.tick(1 / 60) end
check(env.MG.ammo == 50 and env.MG.mags == 19, "reload done: full belt, one belt used")
env.client.draw(1 / 60)
check(next(env.violations) == nil, "no server-only calls on the client")
-- the gun breaks off (its turret joint breaks): the gunner gets off, a player the engine seated on the gun place is
-- taken out, the rig is deleted (no seat there any more), the gun is no longer offered
env.side = "server"
env.MG = serverMG
local DELETED, BROKEN = {}, {}
env.def("Delete", function(h) DELETED[h] = true end)
env.def("IsJointBroken", function(j) return BROKEN[j] or false end)
env.server.tick(1 / 60)
check(env.MG.rig == 40 and env.shared.mgGunner == 2, "intact: still manned")
-- a damaged gun / turret (IsShapeBroken: any voxel lost) is still usable; most of the gun's voxels gone retires it
env.def("IsShapeBroken", function() return true end)
local VOX = env.MG.gunVoxels0 or 0
env.server.tick(1 / 60)
check(env.MG.rig == 40 and env.shared.mgGunner == 2, "gun / turret merely damaged (IsShapeBroken): still manned")
S.VEH[1], S.RIG[1] = 9, 40 -- (as if the engine had seated player 1 there)
BROKEN[31] = true
env.server.tick(1 / 60)
check(env.shared.mgGunner == 0 and DELETED[40] and env.MG.rig == 0 and S.VEH[1] == nil and TAGSET[21] == nil,
	"gun broken off: gunner off, seated player out, gun place deleted, no prompt")
env.server.tick(1 / 60)
check(next(env.violations) == nil, "retired: server keeps running quietly")
print("all mounted gun tests passed")

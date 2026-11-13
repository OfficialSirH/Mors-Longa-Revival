-- Mock test for the cannon path of scripts/MountedGun.lua + scripts/avf (AVF's shells, ported) through the
-- ZU-23-2 config (avf/prefabs/technicals/ZSU-23-2.lua). Run from the repo root with Lua 5.1:
--   lua5.1 tools/porting/tests/test_avf_cannon.lua
dofile("tools/porting/tests/mockengine.lua")

local function check(cond, msg) if not cond then error("FAIL: " .. msg, 2) end print("ok  " .. msg) end
local PATH = "avf/prefabs/technicals/ZSU-23-2.lua"

local env = MockEngine.load(PATH, { preload = MockEngine.includes(PATH) })
env.side = "server"
env.PLAYERS = { [1] = { pos = { 0, 0, 0 }, health = 1 }, [2] = { pos = { 50, 0, 0 }, health = 1 } }
env.ORDER = { 1, 2 }
-- vehicle 9 (body 109); turret shape 20, gun shape 21; joints 31 / 32; rig 40; emitter 50
local TAGS = { [20] = "turret", [21] = "gun", [31] = "turretJoint", [32] = "gunJoint" }
env.def("FindVehicle", function(tag) return tag == "cfg" and 9 or 0 end)
env.def("FindShapes", function(tag) return tag == "component" and { 20, 21 } or tag == "mainCannon" and { 21 } or {} end)
env.def("FindJoints", function(tag) return tag == "component" and { 31, 32 } or {} end)
env.def("GetTagValue", function(h, tag)
	if tag == "weaponType" then return h == 21 and "customcannon" or "" end -- the XML tag on the gun (AVF's weapon type)
	return tag == "component" and TAGS[h] or ""
end)
env.def("FindRig", function(tag) return tag == "gunner" and 40 or 0 end)
env.def("FindLocation", function(tag) return tag == "mainCannon_emitter" and 50 or 0 end)
-- two emitters (ZU-23-2: twin barrels), 0.3 m apart, the first also gives the barrel direction (-z)
env.def("FindLocations", function(tag) return tag == "mainCannon_emitter" and { 50, 51 } or {} end)
env.def("GetLocationTransform", function(h) return env.Transform({ h == 51 and 0.15 or -0.15, 0, -1 }) end)
env.def("GetShapeSize", function() return 2, 2, 10, 0.1 end)
env.def("GetShapeWorldTransform", function() return env.Transform({ 0, 0, 0 }) end)
env.def("GetShapeBody", function(s) return s + 100 end)
env.def("GetVehicleBody", function() return 109 end)
env.def("GetBodyTransform", function() return env.Transform({ 0, 0, 0 }) end)
env.def("GetVehicleTransform", function() return env.Transform({ 0, 0, 0 }) end)
env.def("TransformToParentVec", function(t, v) return env.VecCopy(v) end)
env.def("TransformToParentPoint", function(t, v) return env.VecAdd(t.pos, v) end)
env.def("TransformToLocalPoint", function(t, v) return env.VecSub(v, t.pos) end)
env.def("IsShapeBroken", function() return false end)
env.def("TransformCopy", function(t) return env.Transform(env.VecCopy(t.pos), t.rot) end)
env.def("IsJointBroken", function() return false end)
env.def("HasFile", function() return true end)
env.def("GetTimeStep", function() return 1 / 60 end)
env.def("GetBodyVelocity", function() return { 0, 0, 0 } end)
env.def("GetWindVelocity", function() return { 0, 0, 0 } end)
local HOLES, EXPLOSIONS = {}, 0
env.def("MakeHole", function(pos, a, b, c) HOLES[#HOLES + 1] = { pos = pos, r = a } return 1 end)
env.def("Explosion", function() EXPLOSIONS = EXPLOSIONS + 1 end)
-- the world: nothing until a solid block of metal from 30 m ahead on (z <= -30); a thin wall would be shot
-- through (a shell with penetration left flies on, as in AVF)
local WALL = -30
env.def("QueryRaycast", function(o, d, len)
	if o[3] <= WALL then return true, 0, { 0, 0, 1 }, 77 end
	if d[3] < 0 and o[3] + d[3] * len <= WALL then
		local dist = (o[3] - WALL) / -d[3]
		return true, dist, { 0, 0, 1 }, 77
	end
	return false, 0, { 0, 0, 0 }, 0
end)
env.def("GetShapeMaterialAtPosition", function() return "metal", 0.5, 0.5, 0.5 end)
env.def("QueryAabbBodies", function() return {} end)
env.def("HasTag", function() return false end)

env.server.init()
check(env.MG.cannon == true, "ZU-23-2 config: cannon mode (weaponType cannon)")
check(#env.MG.types == 2 and env.MG.types[1].name == "B_23mm_AA" and env.MG.types[2].name == "B_23mm_AA_AP",
	"magazines from the config: HE (B_23mm_AA) and AP (B_23mm_AA_AP)")
local he, ap = env.MG.types[1].CfgAmmo, env.MG.types[2].CfgAmmo
check(he.payload == "HE" and ap.payload == "AP" and he.velocity == 220 and ap.maxPenDepth == 0.5,
	"config overrides on AVF's shell types (payload, velocity, maxPenDepth)")
local mod = math.log(23) / 10 * .75
check(math.abs(he.bulletdamage[1] - mod * 1.3) < 1e-9 and he.penModifier == 1 and ap.penModifier == 0.3,
	"AVF's loadShells derivations: bulletdamage from calibre, penModifier by payload")
check(env.MG.capacity == 100 and env.MG.magazines == 10 and env.shared.mgAmmo2 == 200 and env.shared.mgMags2 == 10,
	"per type rounds / magazines: HE 100 x 10 in the MG keys, AP 200 x 10 in mgAmmo2 / mgMags2")
check(#env.projectileHandler.shells == env.AVF_SHELL_SLOTS, "shell slots set up")
check(he.shellWidth == 0.1 and env.munitions.customShell.shellWidth == 0.5 and he.launcher == "cannon",
	"base shell = customcannon's customShell (as AVF), config values on top")
check(env.MG_AmmoLabel(1) == "23 mm HE" and env.MG_AmmoLabel(2) == "23 mm AP", "HUD names: 23 mm HE / 23 mm AP")

-- player 1 mans the gun (as the machine gun test: interact on the gun shape)
env.def("InputPressed", function(k, p) return k == "interact" and p == 1 end)
env.def("GetPlayerInteractShape", function(p) return p == 1 and 21 or 0 end)
env.def("GetPlayerHealth", function(p) return env.PLAYERS[p].health end)
env.server.tick(1 / 60)
check(env.shared.mgGunner == 1, "player 1 on the ZU-23-2")
env.def("InputPressed", function() return false end)

-- a non-gunner's fire request is ignored; the gunner's fires an HE shell from the muzzle
env.sent = {}
env.server.mgCannonFire(2, 1, false)
check(#env.sent == 0, "fire request from a non-gunner ignored")
env.server.mgCannonFire(1, 1, true)
local shell = env.projectileHandler.shells[1]
check(shell.active and shell.shellType == he and shell.ownerPlayer == 1 and shell.tracer == true,
	"gunner fires: AVF shell active, HE type, owner, tracer")
check(math.abs(shell.point1[1] - (-0.15)) < 1e-6, "twin barrels: first shell from barrel 1 (x -0.15)")
check(shell.rejectBodies and shell.rejectBodies[1] == 121 and shell.rejectBodies[2] == 120,
	"shells skip the gun's and the turret's own bodies (BMP-1: its barrel pieces are other shapes)")
local bt = env.retrieve_first_barrel_coord(shell.originGun_data)
check(bt and math.abs(bt.pos[3] - env.MG_Muzzle()[3]) < 1e-6, "guided missiles get the gun's barrel line (at the muzzle)")
check(shell.predictedBulletVelocity[3] < -219 and shell.originVehicle == 109 and shell.originGun == 21,
	"shell flies along the barrel (-z) at the config velocity; own vehicle and gun not hit")
local spawned, flash
for _, s in ipairs(env.sent) do
	if s.fn == "client.avfShell" and s.to == 0 then spawned = s end
	if s.fn == "client.mgFireFx" and s.to == 0 then flash = s end
end
check(spawned and spawned.args[3] == 1 and spawned.args[4] == true and flash, "every client told: shell to draw, muzzle flash / sound")

-- flight: gravity, then the wall 30 m ahead (~0.14 s at 220 m/s): penetration check, HE payload
env.sent = {}
for i = 1, 30 do env.server.tick(1 / 60) end
check(not shell.active, "shell ended at the wall")
check(#HOLES > 0, "world damage on impact (MakeHole) on the server")
local fx = {}
for _, s in ipairs(env.sent) do if s.fn == "client.avfFx" then fx[s.args[1]] = (fx[s.args[1]] or 0) + 1 end end
check(fx.impact and fx.sound, "impact effect and explosion sound sent to every client")
local drawn = 0
for _, n in ipairs({ "DrawSprite", "SpawnParticle", "PlaySound", "PointLight", "ParticleReset" }) do drawn = drawn + (env.calls[n] or 0) end
check(drawn == 0, "no drawing / particles / sounds on the server")
check(next(env.violations) == nil, "no client-only calls on the server")

-- AP: penetrates further (maxPenDepth 0.5 vs 0.1), no HE payload explosion sound
env.sent = {}
local holesBefore = #HOLES
env.server.mgCannonFire(1, 2, false)
check(math.abs(env.projectileHandler.shells[2].point1[1] - 0.15) < 1e-6, "twin barrels: next shell from barrel 2 (x 0.15)")
for i = 1, 30 do env.server.tick(1 / 60) end
check(#HOLES > holesBefore, "AP shell also damages the wall")

-- player damage: AVF's amounts below the whole health do nothing (original: health reset to 1 every tick),
-- a lethal amount kills through the torso hitbox
local TORSO = { tags = { hitbox = "TORSO", hitbox_player = "2" } }
env.def("FindTriggers", function() return { 300 } end)
env.def("HasTag", function(h, t) return h == 300 and TORSO.tags[t] ~= nil end)
env.def("GetTagValue", function(h, t) if h == 300 then return TORSO.tags[t] or "" end return t == "component" and TAGS[h] or "" end)
local SET = {}
env.def("SetTag", function(h, t, v) SET[h] = { t, v } end)
env.AVF_HurtPlayer(2, 0.6)
check(SET[300] == nil, "AVF damage 0.6 (< whole health): no effect, as in the original")
env.AVF_HurtPlayer(2, 1.2)
check(SET[300] and SET[300][1] == "QueriedDamage" and SET[300][2] == 10000, "AVF damage >= 1: lethal through player 2's torso hitbox")

-- clients: draw the events and the shell
env.side = "client"
env.LOCAL = 1
env.def("GetLocalPlayer", function() return 1 end)
env.def("GetQuatEuler", function() return 0, 0, 0 end)
env.def("InputValue", function() return 0 end)
env.def("InputDown", function() return false end)
env.def("GetShapeBounds", function() return { -0.1, -0.1, -0.5 }, { 0.1, 0.1, 0.5 } end)
env.def("QueryRaycast", function() return false, 0 end)
env.client.init()
check(env.AVF_AMMO[1].sprite ~= nil and #env.explosion_sounds == 7, "client: shell sprites and explosion sounds loaded")
env.client.avfShell({ 0, 0, 0 }, { 0, 0, -220 }, 1, true, 109, 77)
env.client.avfShellSync(77, { 1, 2, 3 }, { 0, 0, -60 })
check(env.AVF_DRAWN[1].pos[1] == 1 and env.AVF_DRAWN[1].vel[3] == -60, "guided missile: client takes the server's position update")
env.client.avfShellSync(env.AVF_DRAWN[1] and env.AVF_DRAWN[1].id or -1, { 1, 2, 3 }, { 0, 0, -60 })
env.client.tick(1 / 60)
check(#env.AVF_DRAWN == 1 and env.AVF_DRAWN[1].pos[3] < 3 and (env.calls.DrawSprite or 0) > 0, "client draws the shell in flight")
env.client.avfFx("impact", 0.3, { 0, 0, -30 }, 77)
env.client.avfFx("pen", 0.3, { 0, 0, -30 }, { 0, 0, -200 })
env.client.avfFx("explosion", { 0, 0, -30 }, 1.2)
env.client.avfFx("particle", "smoke", { 0, 0, -30 }, { 0, 1, 0 }, 0.5, 2)
env.client.avfFx("sound", { 0, 0, -30 }, 10)
env.client.update(1 / 60)
env.client.tick(1 / 60)
check((env.calls.SpawnParticle or 0) > 0 and (env.calls.PlaySound or 0) > 0, "client: impact / penetration / explosion / particle / sound effects run")
env.client.mgFireFx({ 0, 0, 0 }, { 0, 0, -1 })
-- one-round magazines (BMP-1 73 mm, RPM 6.5): reload by themselves within the firing cycle, ready right after
local held = false
env.def("InputDown", function(k) return k == "lmb" and held end)
env.MG.capacity, env.MG.ammo, env.MG.mags, env.MG.shotTimer, env.MG.reloadTimer = 1, 1, 5, 0, 0
env.MG.weapons[1].rpm = 6.5 -- (the weapon in use carries its rate)
env.sent = {}
held = true
env.client.tick(1 / 60)
held = false
local fires = function() local n = 0 for _, c in ipairs(env.sent) do if c.fn == "server.mgCannonFire" then n = n + 1 end end return n end
check(fires() == 1 and env.MG.ammo == 0 and math.abs(env.MG.reloadTimer - 60 / 6.5) < 1e-6,
	"one-round magazine: fired, reload started by itself, lasting the firing cycle (60 / RPM)")
for i = 1, math.ceil(60 / 6.5 * 60) + 2 do env.client.tick(1 / 60) end
check(env.MG.ammo == 1 and env.MG.mags == 4 and env.MG.shotTimer == 0, "after the cycle: loaded, ready")
held = true
env.client.tick(1 / 60)
check(fires() == 2, "fires again on the next press")
held = false
check(next(env.violations) == nil, "no server-only calls on the client")
-- the BMP configs load in cannon mode with their own shell names and AVF's customcannon base
for _, c in ipairs({ { "avf/prefabs/bmp/BMP-2.lua", "3UBR8 APDS", "3UOF8 HEI", 30 }, { "avf/prefabs/bmp/BMP-1.lua", "PG15V-HEAT", "PG15V-HE", 73 } }) do
	local e = MockEngine.load(c[1], { preload = MockEngine.includes(c[1]) })
	e.side = "server"
	e.PLAYERS, e.ORDER = {}, {}
	e.def("FindShapes", function(tag) return tag == "component" and { 20, 21 } or tag == "mainCannon" and { 21 } or {} end)
	e.def("GetTagValue", function(h, tag)
		if tag == "weaponType" then return h == 21 and "customcannon" or "" end
		return tag == "component" and TAGS[h] or ""
	end)
	e.def("HasFile", function() return true end)
	e.def("GetShapeSize", function() return 2, 2, 10, 0.1 end)
	e.def("FindVehicle", function() return 9 end)
	e.def("IsJointBroken", function() return false end)
	e.server.init()
	check(e.MG.cannon and #e.MG.types == 2 and e.MG_AmmoLabel(1) == c[2] and e.MG_AmmoLabel(2) == c[3]
		and e.MG.types[1].CfgAmmo.caliber == c[4], c[1] .. ": cannon, HUD names " .. c[2] .. " / " .. c[3])
end
-- a seated gunner (ZU-23-2 / BMPs: rig with a "seat", no "stand"): the prompt is on the turret / mount, not the gun
do
	local e = MockEngine.load(PATH, { preload = MockEngine.includes(PATH) })
	e.side = "server"
	e.PLAYERS, e.ORDER = {}, {}
	e.def("FindVehicle", function() return 9 end)
	e.def("FindShapes", function(tag) return tag == "component" and { 20, 21 } or tag == "mainCannon" and { 21 } or {} end)
	e.def("GetTagValue", function(h, tag) return tag == "component" and TAGS[h] or "" end)
	e.def("FindRig", function() return 40 end)
	e.def("GetShapeSize", function() return 2, 2, 10, 0.1 end)
	e.def("GetShapeBody", function(sh) return sh + 100 end)
	e.def("HasFile", function() return true end)
	e.def("IsJointBroken", function() return false end)
	e.def("GetRigLocationWorldTransform", function(r, n) if n == "stand" then return nil end return e.Transform({ 0, 0, 0 }) end)
	local TAG = {}
	e.def("SetTag", function(h, k, v) TAG[h] = v end)
	e.def("RemoveTag", function(h, k) TAG[h] = "removed" end)
	e.server.init()
	check(e.MG.pose.anchor == "seat" and e.MG.useShape == 20 and TAG[20] == "Use mounted gun" and TAG[21] == "removed",
		"seated gunner: 'Use mounted gun' on the turret / mount, AVF's tag off the gun")
end
-- tanks: the driver fires while the gunner place is empty (MountedGunDriverFires, T-34 config); a gunner takes over
do
	local T34 = "avf/prefabs/T-34/T-34-85.lua"
	local e = MockEngine.load(T34, { preload = MockEngine.includes(T34) })
	e.side = "server"
	e.PLAYERS = { [1] = { pos = { 0, 0, 0 }, health = 1 }, [2] = { pos = { 0, 0, 0 }, health = 1 } }
	e.ORDER = { 1, 2 }
	local VEH, DRIVER = { [2] = 9 }, { [2] = true }
	e.def("FindVehicle", function() return 9 end)
	e.def("FindShapes", function(tag) return tag == "component" and { 20, 21 } or tag == "mainCannon" and { 21 } or {} end)
	e.def("FindJoints", function(tag) return tag == "component" and { 31, 32 } or {} end)
	e.def("GetTagValue", function(h, tag)
		if tag == "weaponType" then return h == 21 and "customcannon" or "" end
		return tag == "component" and TAGS[h] or ""
	end)
	e.def("FindRig", function() return 40 end)
	e.def("GetShapeSize", function() return 2, 2, 10, 0.1 end)
	e.def("GetShapeBody", function(sh) return sh + 100 end)
	e.def("HasFile", function() return true end)
	e.def("IsShapeBroken", function() return false end)
	e.def("IsJointBroken", function() return false end)
	e.def("GetPlayerHealth", function(pl) return 1 end)
	e.def("GetPlayerVehicle", function(pl) return VEH[pl] or 0 end)
	e.def("IsPlayerVehicleDriver", function(v, pl) return v == 9 and DRIVER[pl] or false end)
	e.def("InputPressed", function() return false end)
	e.def("GetVehicleTransform", function() return e.Transform({ 0, 0, 0 }) end)
	e.def("GetBodyTransform", function() return e.Transform({ 0, 0, 0 }) end)
	e.def("QueryRaycast", function() return false, 0, { 0, 0, 0 }, 0 end) -- (the stub returns 0: a "hit" in Lua)
	e.def("GetWindVelocity", function() return { 0, 0, 0 } end)
	e.server.init()
	check(e.MG.cannon and e.MountedGunDriverFires == true, "T-34: cannon from the gun's customcannon tag (config has no weaponType), driver fallback on")
	e.server.tick(1 / 60)
	check(e.MG.driverId == 2 and e.shared.mgDriver == 2 and e.MG_Operator() == 2, "nobody on the gunner place: the driver (player 2) works the gun")
	e.sent = {}
	e.server.mgCannonFire(2, 1, false)
	local fired = false
	for _, c in ipairs(e.sent) do if c.fn == "client.mgFireFx" then fired = true end end
	check(fired, "the driver's fire request is accepted")
	e.server.mgCannonFire(1, 1, false)
	check(#e.sent == 2, "...a non-operator's is not")
	-- player 1 takes the gunner place: the driver no longer works the gun
	e.MG.gunnerId, e.shared.mgGunner = 1, 1
	e.server.tick(1 / 60)
	check(e.MG.driverId == nil and e.shared.mgDriver == 0 and e.MG_Operator() == 1, "a gunner on the gunner place takes over from the driver")
	-- the driver's client aims with the vehicle camera (no camera takeover)
	e.MG.gunnerId, e.shared.mgGunner = nil, 0
	e.server.tick(1 / 60)
	e.side = "client"
	e.def("GetLocalPlayer", function() return 2 end)
	e.def("GetCameraTransform", function() return e.Transform({ 0, 2, 3 }) end)
	e.def("QueryRaycast", function() return false, 0 end)
	e.def("InputDown", function() return false end)
	e.def("InputValue", function() return 0 end)
	e.def("GetQuatEuler", function() return 0, 0, 0 end)
	e.def("GetPlayerCameraTransform", function() return e.Transform({ 0, 2, 3 }) end)
	local PRESSED, RMB_DOWN, WHEEL = {}, false, 0
	e.def("InputPressed", function(k) return PRESSED[k] or false end)
	e.def("InputDown", function(k) return k == "rmb" and RMB_DOWN end)
	e.def("InputValue", function(k) return k == "mousewheel" and WHEEL or 0 end)
	e.def("GetBool", function() return false end)
	e.client.init()
	local function aims() local n = 0 for _, c in ipairs(e.sent) do if c.fn == "server.mgAim" and c.args[2] then n = n + 1 end end return n end
	local function released() for _, c in ipairs(e.sent) do if c.fn == "server.mgAim" and c.args[2] == nil then return true end end return false end
	e.sent = {}
	e.client.tick(1 / 60)
	check(e.MG.view == "vehicle" and aims() == 0 and (e.calls.SetCameraTransform or 0) == 0,
		"driver starts in the vehicle view: the game's camera, turret not aimed")
	WHEEL = 1 -- the wheel belongs to the game's own camera zoom here
	e.client.tick(1 / 60)
	WHEEL = 0
	check(e.MG.view == "vehicle", "wheel in the vehicle view: no view change (the game's first-person zoom)")
	local fx, fy, fz = e.shared.mgFx, e.shared.mgFy, e.shared.mgFz
	e.shared.mgFx, e.shared.mgFy, e.shared.mgFz = -1, 0, 0 -- the turret points left (-x) while driving
	PRESSED.v = true
	e.client.tick(1 / 60)
	PRESSED.v = false
	check(e.MG.view == "gun" and (e.calls.SetCameraTransform or 0) > 0 and aims() > 0, "V: gun view, aiming")
	check(math.abs(e.MG.look.yaw - 90) < 1e-6 and math.abs(e.MG.look.pitch) < 1e-6, "gun view starts looking along the barrel (yaw 90 = -x)")
	e.shared.mgFx, e.shared.mgFy, e.shared.mgFz = fx, fy, fz
	e.client.tick(1 / 60)
	check(e.MG.view == "gun", "...and it stays there")
	RMB_DOWN, WHEEL = true, -1
	e.client.tick(1 / 60)
	RMB_DOWN, WHEEL = false, 0
	check(e.MG.view == "gun", "wheel with RMB held zooms the sight, no view change")
	e.sent = {}
	PRESSED.v = true
	e.client.tick(1 / 60)
	PRESSED.v = false
	check(e.MG.view == "vehicle" and released(), "V again: vehicle view, turret released to hold")
	PRESSED.rmb, RMB_DOWN = true, true
	e.client.tick(1 / 60)
	PRESSED.rmb = false
	e.client.tick(1 / 60)
	check(e.MG.view == "gun", "RMB from the vehicle view: aims (gun view) while held")
	e.sent = {}
	RMB_DOWN = false
	e.client.tick(1 / 60)
	check(e.MG.view == "vehicle" and released(), "RMB released: straight back to the vehicle view")
	-- looking straight down in the gun view: aim keeps the camera's heading, pitch at most -60
	PRESSED.v = true
	e.client.tick(1 / 60)
	PRESSED.v = false
	e.MG.look = { pitch = -89, yaw = 90 }
	e.def("QueryRaycast", function() return true, 1, { 0, 1, 0 }, 0 end) -- the ground right below the camera
	e.sent = {}
	e.client.tick(1 / 60)
	local last
	for _, c in ipairs(e.sent) do if c.fn == "server.mgAim" and c.args[2] then last = c.args[2] end end
	check(last and math.abs(last[2] - math.sin(math.rad(-60))) < 1e-6 and last[1] < -0.4,
		"looking straight down: aim has the camera's heading (yaw 90 = -x) and pitch -60")
	check(next(e.violations) == nil, "driver fallback: no wrong-side calls")
end
-- Katyusha (phase 3): a rocket config fires AVF's shells; three launch rails (one above the others) get offsets
-- across the barrel line, height included; AVF asset paths map to our copies; clients draw exhaust + flight sound
do
	local K = "avf/prefabs/ZIS-151/katyusha.lua"
	local e = MockEngine.load(K, { preload = MockEngine.includes(K) })
	e.side = "server"
	e.PLAYERS, e.ORDER = {}, {}
	e.def("FindVehicle", function() return 9 end)
	e.def("FindShapes", function(tag) return tag == "component" and { 20, 21 } or tag == "mainCannon" and { 21 } or {} end)
	e.def("GetTagValue", function(h, tag)
		if tag == "weaponType" then return h == 21 and "customcannon" or "" end
		return tag == "component" and TAGS[h] or ""
	end)
	e.def("GetShapeSize", function() return 2, 2, 10, 0.1 end)
	e.def("GetShapeWorldTransform", function() return e.Transform({ 0, 0, 0 }) end)
	e.def("TransformToParentPoint", function(t, v) return e.VecAdd(t.pos, v) end)
	e.def("TransformToLocalPoint", function(t, v) return e.VecSub(v, t.pos) end)
	e.def("TransformToParentVec", function(t, v) return e.VecCopy(v) end)
	e.def("TransformToLocalVec", function(t, v) return e.VecCopy(v) end)
	e.def("GetVehicleTransform", function() return e.Transform({ 0, 0, 0 }) end)
	e.def("GetBodyTransform", function() return e.Transform({ 0, 0, 0 }) end)
	e.def("HasFile", function() return true end)
	e.def("IsJointBroken", function() return false end)
	-- three rails at the barrel's front: x -0.2 / 0.2 at the barrel's height (y 0.1), one 0.5 higher
	local RAIL = { [50] = { -0.2, 0.1, -1 }, [51] = { 0.2, 0.1, -1 }, [52] = { 0.2, 0.6, -1 } }
	e.def("FindLocation", function() return 50 end)
	e.def("FindLocations", function() return { 50, 51, 52 } end)
	e.def("GetLocationTransform", function(h) return e.Transform(RAIL[h]) end)
	e.server.init()
	check(e.MG.cannon and #e.MG.types == 1 and e.MG_AmmoLabel(1) == "132mm rocket HE", "Katyusha: rocket config fires AVF's shells (132mm rocket HE)")
	local c = e.MG.types[1].CfgAmmo
	check(c.launcher == "rocket" and c.shellSpriteName == "MOD/avf/assets/gfx/rocketModel2.png"
		and c.flightLoop == "MOD/avf/assets/sounds/rocketFlightLoop0", "AVF asset paths mapped to MOD/avf/assets/")
	check(e.shared.mgBarrels == 3 and math.abs(e.shared.mgB3y - 0.5) < 1e-6 and math.abs(e.shared.mgB1x - (-0.3)) < 1e-6,
		"three rails: offsets across the barrel line, height included (rail 3 is 0.5 higher)")
	e.side = "client"
	e.def("QueryRaycast", function() return false, 0 end)
	e.def("TransformCopy", function(t) return e.Transform(e.VecCopy(t.pos), t.rot) end)
	e.client.init()
	check(e.AVF_AMMO[1].flightLoopSound ~= nil, "client: rocket flight loop loaded")
	e.client.avfShell({ 0, 0, 0 }, { 0, 0, -87 }, 1, false, 109, 5)
	local before = e.calls.SpawnParticle or 0
	e.client.tick(1 / 60)
	check((e.calls.SpawnParticle or 0) > before and (e.calls.PlayLoop or 0) > 0, "client draws the rocket's exhaust and plays its flight sound")
end
-- WMIK MILAN: own config table (MountedGunConfig), gun / emitter tags main_MILAN / main_MILAN_emitter, guided missile
do
	local W = "avf/prefabs/technicals/Offroad_WMIK.lua"
	local e = MockEngine.load(W, { preload = MockEngine.includes(W) })
	e.side = "server"
	e.PLAYERS, e.ORDER = {}, {}
	local asked = {}
	e.def("FindVehicle", function() return 9 end)
	e.def("FindShapes", function(tag) asked[tag] = true return tag == "component" and { 20, 21 } or tag == "main_MILAN" and { 21 } or {} end)
	e.def("FindLocation", function(tag) asked[tag] = true return 0 end)
	e.def("GetTagValue", function(h, tag)
		if tag == "weaponType" then return h == 21 and "customcannon" or "" end
		return tag == "component" and TAGS[h] or ""
	end)
	e.def("GetShapeSize", function() return 2, 2, 10, 0.1 end)
	e.def("HasFile", function() return true end)
	e.def("IsJointBroken", function() return false end)
	e.server.init()
	local c = e.MG.types and e.MG.types[1] and e.MG.types[1].CfgAmmo
	check(e.MG.gun == 21 and asked.main_MILAN and asked.main_MILAN_emitter, "WMIK: gun / muzzle found by their main_MILAN tags")
	check(e.MG.cannon and c.launcher == "guided" and c.payload == "HEAT" and c.caliber == 115 and e.MG_AmmoLabel(1) == "MILAN ATGM"
		and e.MG.capacity == 1 and e.MountedGunDriverFires == nil, "WMIK: MILAN = guided HEAT missile, one per load, gunner only")
end
-- GMG offroad (2026-11-13): own config, gun / emitter tags GMG / GMG_emitter, AVF grenade shell, automatic
do
	local W = "avf/prefabs/technicals/Offroad_armed.lua"
	local e = MockEngine.load(W, { preload = MockEngine.includes(W) })
	e.side = "server"
	e.PLAYERS, e.ORDER = {}, {}
	local asked = {}
	e.def("FindVehicle", function() return 9 end)
	e.def("FindShapes", function(tag) asked[tag] = true return tag == "component" and { 20 } or tag == "GMG" and { 21 } or {} end)
	e.def("FindLocation", function(tag) asked[tag] = true return 0 end)
	-- the real gun shape has no component=gun (tags "GMG RHA=80 group=primary interact=mountedGun"; in-game 2026-11-13)
	e.def("GetTagValue", function(h, tag) return tag == "component" and h ~= 21 and TAGS[h] or "" end)
	e.def("FindShape", function(tag) return tag == "GMG" and 21 or 0 end)
	e.def("FindRig", function(tag) return tag == "gunner" and 40 or 0 end)
	local prompt = {}
	e.def("SetTag", function(h, k, v) if k == "interact" then prompt[h] = v end end)
	e.def("GetShapeSize", function() return 2, 2, 10, 0.1 end)
	e.def("HasFile", function() return true end)
	e.def("IsJointBroken", function() return false end)
	e.server.init()
	local c = e.MG.types and e.MG.types[1] and e.MG.types[1].CfgAmmo
	check(e.MG.gun == 21 and asked.GMG and asked.GMG_emitter, "GMG offroad: gun / muzzle found by their GMG tags")
	check(prompt[21] == "Use mounted gun", "GMG offroad: AVF's mountedGun prompt replaced by \"Use mounted gun\"")
	check(e.MG.cannon and c and c.payload == "HE" and c.velocity == 120 and e.MG_AmmoLabel(1) == "HE grenade"
		and e.MG.capacity == 60 and e.MountedGunDriverFires == nil, "GMG offroad: AVF grenade (HE, 120 m/s), 60 per belt, gunner only")
	-- the gunner passes through the offroad's own shapes while on the gun (roof crossbar at the waist, in-game bobbing)
	local filt, mask = {}, {}
	e.def("GetVehicleBodies", function() return { 50 } end)
	e.def("GetVehicleBody", function() return 50 end)
	e.def("GetShapeBody", function(sh) return sh + 100 end)
	e.def("GetBodyShapes", function(b) return { b * 10 } end)
	e.def("GetShapeCollisionFilter", function(sh) return 1, 255 end)
	e.def("SetShapeCollisionFilter", function(sh, l, m) filt[sh] = { l, m } end)
	e.def("GetPlayerParam", function(k, p) return 255 end)
	e.def("SetPlayerParam", function(k, v, p) mask[p] = v end)
	e.def("IsHandleValid", function() return true end)
	e.MG_HoldCollision(1, true)
	check(e.MountedGunHoldGunner and filt[500] and filt[500][1] == 128 and filt[500][2] == 127 and filt[1210] and filt[1210][1] == 128 and mask[1] == 127,
		"GMG offroad: on the gun the gunner passes through the vehicle's and gun's shapes (layer 128 left out of their mask)")
	e.MG_HoldCollision(1, false)
	check(filt[500][1] == 1 and filt[500][2] == 255 and filt[1210][1] == 1 and mask[1] == 255, "GMG offroad: stepping off restores both")
end
-- SPG-9 technical (2026-11-13): mainCannon config, weapon type rocket, PG-9 / OG-9 on F
do
	local W = "avf/prefabs/technicals/technical_spg9.lua"
	local e = MockEngine.load(W, { preload = MockEngine.includes(W) })
	e.side = "server"
	e.PLAYERS, e.ORDER = {}, {}
	e.def("FindVehicle", function() return 9 end)
	e.def("FindShapes", function(tag) return tag == "component" and { 20, 21 } or tag == "mainCannon" and { 21 } or {} end)
	e.def("GetTagValue", function(h, tag)
		if tag == "weaponType" then return h == 21 and "customcannon" or "" end
		return tag == "component" and TAGS[h] or ""
	end)
	e.def("GetShapeSize", function() return 2, 2, 10, 0.1 end)
	e.def("HasFile", function() return true end)
	e.def("IsJointBroken", function() return false end)
	e.server.init()
	local t1 = e.MG.types[1] and e.MG.types[1].CfgAmmo
	local t2 = e.MG.types[2] and e.MG.types[2].CfgAmmo
	check(e.MG.cannon and #e.MG.types == 2 and t1.payload == "HEAT" and t1.launcher == "rocket" and t2.payload == "HE"
		and e.MG.capacity == 1 and e.MountedGunDriverFires == nil, "SPG-9: rocket gun, PG-9 HEAT / OG-9 HE, one per load, gunner only")
end
-- Kornet / AGS-30 tripods (simple_avf_tank.lua, 2026-11-13): no config of their own: weapon, magazines and sound from
-- AVF's weapon type named by the gun's weaponType tag; "GMGun" (AGS-30) fires AVF grenades; the player in it fires
for _, case in ipairs({ { tag = "9M133", payload = "HEAT", cap = 1, snd = "atgm00" },
		{ tag = "AGS30", payload = "HE", cap = 60, snd = "grenade_mg/single_shot_01" } }) do
	local W = "avf/scripts/simple_avf_tank.lua"
	local e = MockEngine.load(W, { preload = MockEngine.includes(W) })
	e.side = "server"
	e.PLAYERS, e.ORDER = {}, {}
	e.def("FindVehicle", function() return 9 end)
	e.def("FindShapes", function(tag) return tag == "component" and { 20, 21 } or tag == "mainCannon" and { 21 } or {} end)
	e.def("GetTagValue", function(h, tag)
		if tag == "weaponType" then return h == 21 and case.tag or "" end
		return tag == "component" and TAGS[h] or ""
	end)
	e.def("GetShapeSize", function() return 2, 2, 10, 0.1 end)
	e.def("HasFile", function() return true end)
	e.def("IsJointBroken", function() return false end)
	local removed = {}
	e.def("FindRig", function() return 0 end)
	e.def("RemoveTag", function(h, k) removed[h] = k end)
	e.server.init()
	local c = e.MG.types and e.MG.types[1] and e.MG.types[1].CfgAmmo
	check(e.MG.cannon and c and c.payload == case.payload and e.MG.capacity == case.cap
		and e.MG.sound == "MOD/avf/assets/sounds/" .. case.snd .. ".ogg" and e.MountedGunDriverFires == true,
		case.tag .. " tripod: AVF's weapon type (" .. case.payload .. ", " .. case.cap .. " per load, its own sound), player in it fires")
	check(removed[21] == "interact", case.tag .. " tripod: AVF's \"mountedGun\" prompt removed (no gunner place)")
	-- as placed in play (add_seats.py EMPLACEMENTS, user 2026-11-13): a plain object, no <vehicle>, a standing gunner
	-- place; the base is the chassis shape's body; only the gun carries a prompt
	local g = MockEngine.load(W, { preload = MockEngine.includes(W) })
	g.side = "server"
	g.PLAYERS, g.ORDER = { [1] = { pos = { 0, 0, 0 }, health = 1 } }, { 1 }
	for _, k in ipairs({ "GetShapeSize", "HasFile", "IsJointBroken" }) do g.def(k, e[k]) end
	g.def("FindVehicle", function() return 0 end)
	g.def("FindShapes", function(tag) return tag == "component" and { 20, 21, 22 } or tag == "mainCannon" and { 21 } or {} end)
	g.def("GetTagValue", function(h, tag)
		if tag == "weaponType" then return h == 21 and case.tag or "" end
		if tag == "component" then return h == 22 and "chassis" or TAGS[h] or "" end
		return ""
	end)
	g.def("GetShapeBody", function(sh) return sh + 100 end)
	local prompt = {}
	g.def("FindRig", function(tag) return tag == "gunner" and 40 or 0 end)
	g.def("SetTag", function(h, k, v) if k == "interact" then prompt[h] = v end end)
	g.def("RemoveTag", function(h, k) if k == "interact" then prompt[h] = nil end end)
	g.def("GetBodyShapes", function(b) return { b * 10 } end)
	g.server.init()
	local others = 0
	for h in pairs(prompt) do if h ~= 21 then others = others + 1 end end
	check(g.MountedGunHoldGunner == true, case.tag .. " tripod: the gunner passes through it while on the gun (AGS-30 gunner was pushed off the place)")
	check(prompt[21] == "Use mounted gun" and others == 0 and g.MG.rig == 40 and g.MG_BaseBody() == 122,
		case.tag .. " tripod (no vehicle): base = chassis body, one prompt \"Use mounted gun\" on the gun")
	local rejected = {}
	g.def("QueryRejectBody", function(b) rejected[b] = true end)
	g.MG_QueryRejectOwn()
	check(rejected[122] and rejected[121] and rejected[120], case.tag .. " tripod (no vehicle): aim / camera rays skip its base, gun and turret")
	g.def("GetPlayerVehicle", function() return 0 end)
	g.def("IsPlayerVehicleDriver", function() return true end)
	g.MG_UpdateDriver()
	check(g.shared.mgDriver == 0 and g.MG.driverId == nil, case.tag .. " tripod (no vehicle): a player on foot is not taken for its driver")
end
-- coax MG as weapon 2 (BMP-2: coax=COAXMG on the gun, config mainCannon.coax): fires from the coax emitter along
-- the main barrel; X switches weapon, F stays within the weapon
do
	local B = "avf/prefabs/bmp/BMP-2.lua"
	local e = MockEngine.load(B, { preload = MockEngine.includes(B) })
	e.side = "server"
	e.PLAYERS, e.ORDER = { [1] = { pos = { 0, 0, 0 }, health = 1 } }, { 1 }
	e.def("FindVehicle", function() return 9 end)
	e.def("FindShapes", function(tag) return tag == "component" and { 20, 21 } or tag == "mainCannon" and { 21 } or {} end)
	e.def("GetTagValue", function(h, tag)
		if h == 21 and tag == "weaponType" then return "customcannon" end
		if h == 21 and tag == "coax" then return "COAXMG" end
		return tag == "component" and TAGS[h] or ""
	end)
	e.def("FindRig", function() return 40 end)
	e.def("FindLocation", function(tag) return tag == "mainCannon_coax_emitter" and 60 or 0 end)
	e.def("GetLocationTransform", function(h) return e.Transform(h == 60 and { 0.3, 0, -0.5 } or { 0, 0, -1 }) end)
	e.def("TransformToParentPoint", function(t, v) return e.VecAdd(t.pos, v) end)
	e.def("TransformToLocalPoint", function(t, v) return e.VecSub(v, t.pos) end)
	e.def("GetShapeSize", function() return 2, 2, 10, 0.1 end)
	e.def("GetShapeBody", function(sh) return sh + 100 end)
	e.def("HasFile", function() return true end)
	e.def("IsJointBroken", function() return false end)
	e.def("IsShapeBroken", function() return false end)
	e.def("GetPlayerHealth", function() return 1 end)
	e.def("GetPlayerVehicle", function() return 0 end)
	e.def("GetBodyVelocity", function() return { 0, 0, 0 } end)
	e.server.init()
	local nMain = 0
	for _, m in ipairs(e.MG.types) do if m.weapon == 1 then nMain = nMain + 1 end end
	check(#e.MG.weapons == 2 and e.MG.weapons[2].coax and e.MG.weapons[2].name == "PKT 7.62 Coax" and nMain == 2
		and e.MG.types[3].weapon == 2 and e.MG_AmmoLabel(3) == "7.62mm", "BMP-2: coax PKT as weapon 2 (its 7.62mm ammo after the 2 main types)")
	e.MG.gunnerId, e.shared.mgGunner = 1, 1
	e.sent = {}
	e.server.mgCannonFire(1, 3, false)
	local shell = e.projectileHandler.shells[1]
	check(shell.active and shell.shellType == e.MG.types[3].CfgAmmo and math.abs(shell.point1[1] - 0.3) < 1e-6
		and math.abs(shell.point1[3] - (-0.5)) < 1e-6, "coax round fires from the coax emitter")
	local fx
	for _, c in ipairs(e.sent) do if c.fn == "client.mgFireFx" then fx = c end end
	check(fx and fx.args[3] == 2, "every client plays the coax's own sound (weapon 2)")
	-- client: X switches to the coax and back to the remembered main type; F stays within the weapon
	e.side = "client"
	local PRESSED = {}
	e.def("GetLocalPlayer", function() return 1 end)
	e.def("InputPressed", function(k) return PRESSED[k] or false end)
	e.def("InputDown", function() return false end)
	e.def("InputValue", function() return 0 end)
	e.def("GetQuatEuler", function() return 0, 0, 0 end)
	e.def("QueryRaycast", function() return false, 0 end)
	e.client.init()
	e.client.tick(1 / 60)
	PRESSED.f = true e.client.tick(1 / 60) PRESSED.f = false
	check(e.MG.type == 2, "F: next main-gun ammo (type 2)")
	PRESSED.x = true e.client.tick(1 / 60) PRESSED.x = false
	check(e.MG.type == 3 and e.MG_CurWeapon().coax and e.MG.capacity == e.MG.types[3].magazineCapacity, "X: coax MG, its own magazine")
	PRESSED.f = true e.client.tick(1 / 60) PRESSED.f = false
	check(e.MG.type == 3, "F on the coax (one ammo type): stays")
	PRESSED.x = true e.client.tick(1 / 60) PRESSED.x = false
	check(e.MG.type == 2, "X again: back to the main gun on the ammo type it had (type 2)")
	-- back in with the main gun empty: it reloads by itself; X during that reload goes to the coax, which fires
	e.shared.mgAmmo2, e.shared.mgMags2 = 0, 5
	e.MG.wasGunner = false
	e.client.tick(1 / 60)
	check(e.MG.type == 2 and e.MG.ammo == 0 and e.MG.reloadTimer > 0, "empty main gun when taking the gun: reloads by itself")
	PRESSED.x = true e.client.tick(1 / 60) PRESSED.x = false
	check(e.MG.type == 3 and e.MG.reloadTimer == 0 and e.MG.shotTimer == 0, "X during that reload: coax MG, ready")
	local DOWN = true
	e.def("InputDown", function(k) return k == "lmb" and DOWN end)
	e.sent = {}
	e.client.tick(1 / 60)
	DOWN = false
	local fired, aim = false, nil
	for _, c in ipairs(e.sent) do
		if c.fn == "server.mgCannonFire" and c.args[2] == 3 then fired = true end
		if c.fn == "server.mgAim" then aim = c.args[2] end
	end
	check(fired, "...and fires at once")
	-- the aim is taken from the coax muzzle (x 0.3): aiming at a point straight ahead of the camera (x 0) the
	-- direction leans left by the offset, so the coax line meets the target
	check(aim and aim[1] < 0, "aim from the coax muzzle: the turret puts the coax's line on the target")
end

-- BMP-2 Kornet launcher as weapon 3: its own gun shape (tag 9m133m2, body 122), missile from its front end along the
-- main gun's line, guided; X cycles main -> coax -> launcher; shells skip the launcher's body too
do
	local B = "avf/prefabs/bmp/BMP-2.lua"
	local e = MockEngine.load(B, { preload = MockEngine.includes(B) })
	e.side = "server"
	e.PLAYERS, e.ORDER = { [1] = { pos = { 0, 0, 0 }, health = 1 } }, { 1 }
	local LTAGS = { [21] = { component = "gun", weaponType = "customcannon", coax = "COAXMG" },
		[22] = { component = "gun", weaponType = "customcannon" }, [20] = { component = "turret" } }
	e.def("FindVehicle", function() return 9 end)
	e.def("FindShapes", function(tag)
		if tag == "component" then return { 20, 21, 22 } end
		if tag == "mainCannon" then return { 21 } end
		if tag == "9m133m2" then return { 22 } end
		return {}
	end)
	e.def("GetTagValue", function(h, tag) return LTAGS[h] and LTAGS[h][tag] or "" end)
	e.def("FindRig", function() return 40 end)
	e.def("GetShapeSize", function(sh) if sh == 22 then return 2, 2, 6, 0.1 end return 2, 2, 10, 0.1 end)
	e.def("GetShapeWorldTransform", function(sh) return e.Transform(sh == 22 and { 1, 1, 0 } or { 0, 0, 0 }) end)
	e.def("TransformToParentPoint", function(t, v) return e.VecAdd(t.pos, v) end)
	e.def("TransformToLocalPoint", function(t, v) return e.VecSub(v, t.pos) end)
	e.def("GetShapeBody", function(sh) return sh + 100 end)
	e.def("GetBodyTransform", function() return e.Transform({ 0, 0, 0 }) end)
	e.def("HasFile", function() return true end)
	e.def("IsJointBroken", function() return false end)
	e.def("GetBodyVelocity", function() return { 0, 0, 0 } end)
	e.server.init()
	local w3 = e.MG.weapons[3]
	check(#e.MG.weapons == 3 and w3.launcher == 22 and w3.name == "M133 Kornet" and e.MG.types[#e.MG.types].weapon == 3
		and e.MG.types[#e.MG.types].CfgAmmo.launcher == "guided", "BMP-2: Kornet launcher as weapon 3 (guided)")
	e.MG.gunnerId, e.shared.mgGunner = 1, 1
	e.server.mgCannonFire(1, #e.MG.types, false)
	local shell = e.projectileHandler.shells[1]
	-- launcher box: corner (1, 1, 0), 0.2 x 0.2 x 0.6 -> centre (1.1, 1.1, 0.3); along the main barrel (-z): front at
	-- z 0, muzzle 0.1 further
	check(shell.active and math.abs(shell.point1[1] - 1.1) < 1e-6 and math.abs(shell.point1[3] - (-0.1)) < 1e-6,
		"missile leaves the launcher's front end")
	local skips = {}
	for _, b in ipairs(shell.rejectBodies) do skips[b] = true end
	check(skips[121] and skips[120] and skips[122], "shells skip the gun's, turret's and launcher's bodies")
	-- launcher top: y 1 + 0.2 = 1.2; barrel centre y 0.1 -> the camera clears 1.1 above the barrel centre
	check(math.abs(e.shared.mgTopUp - 1.1) < 1e-6, "camera height also clears the launcher")
end

-- every #include line of the converted configs resolves, also ones inside Lua comments: Teardown handles include
-- lines before Lua sees the comment (in-game 2026-11-13: the WMIK config's commented-out include of a missing file
-- kept the whole script from loading)
do
	local DATA = "C:/Program Files (x86)/Steam/steamapps/common/Teardown/data/"
	local configs = {
		"avf/prefabs/technicals/technical_dshk.lua", "avf/prefabs/Weaponised vehicles/Van PKM.lua",
		"avf/prefabs/Weaponised vehicles/Willys Jeep 50 Cal.lua", "avf/prefabs/technicals/ZSU-23-2.lua",
		"avf/prefabs/bmp/BMP-1.lua", "avf/prefabs/bmp/BMP-2.lua", "avf/prefabs/bmp/2A70.lua",
		"avf/prefabs/T-34/T-34-85.lua", "avf/prefabs/T-54 55/T-54.lua", "avf/prefabs/T-54 55/T-55.lua",
		"avf/prefabs/M-51 Super Sherman/M-51 SUPER SHERMAN.lua", "avf/prefabs/t72_desert/t72b.lua",
		"avf/prefabs/ZIS-151/katyusha.lua", "avf/prefabs/technicals/Offroad_WMIK.lua",
		"avf/prefabs/t72_desert/t72A.lua", "avf/prefabs/technicals/Offroad_armed.lua", "avf/prefabs/technicals/technical_spg9.lua", "avf/scripts/simple_avf_tank.lua",
	}
	local function exists(path) local f = io.open(path, "r") if f then f:close() return true end return false end
	local bad = {}
	for _, cfg in ipairs(configs) do
		local dir = cfg:match("^(.*)/[^/]*$")
		for line in io.lines(cfg) do
			local inc = line:match('^%s*#include%s*"([^"]+)"')
			if inc then
				local ok = exists(DATA .. inc) or exists(dir .. "/" .. inc)
				if not ok then bad[#bad + 1] = cfg .. " -> " .. inc end
			end
		end
	end
	check(#bad == 0, "every #include line of the converted configs resolves" .. (#bad > 0 and (": " .. table.concat(bad, "; ")) or ""))
end
print("all AVF cannon tests passed")
-- AVF body pushes are capped (AVF_Impulse, 2026-11-13): the AGS-30's gun weighs ~1e-7 kg; a full push on it meant
-- absurd speeds (the game froze for a while when its tripod was shot, in-game)
do
	local W = "avf/scripts/simple_avf_tank.lua"
	local e = MockEngine.load(W, { preload = MockEngine.includes(W) })
	local got = {}
	e.def("GetBodyMass", function(b) return b == 1 and 1e-7 or 1000 end)
	e.def("ApplyBodyImpulse", function(b, p, imp) got[b] = e.VecLength(imp) end)
	e.AVF_Impulse(1, e.Vec(0, 0, 0), e.Vec(0, 50, 0))
	e.AVF_Impulse(2, e.Vec(0, 0, 0), e.Vec(0, 50, 0))
	check(got[1] and got[1] / 1e-7 <= 30.001, "AVF push on a ~weightless body: speed change capped at 30 m/s")
	check(got[2] and math.abs(got[2] - 50) < 1e-9, "AVF push on a heavy body: unchanged")
end

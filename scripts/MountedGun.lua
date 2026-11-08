-- MountedGun.lua (Mors Longa Revival, Phase 4) - our v2 replacement for the external AVF mod's mounted guns.
-- Library: included by a vehicle's AVF config file (e.g. avf/prefabs/technicals/technical_dshk.lua), which starts
-- with "#version 2", includes script/include/player.lua and this file, and keeps its AVF table
-- vehicleParts.guns.mainCannon (name, RPM, reload, magazineCapacity, magazines[1].magazineCount, barrels[1],
-- dispersion). The config also sets MountedGunCalibre (a gunperks.lua calibre, e.g. "127x99") and MountedGunSound.
--
-- Parts (AVF tags in the vehicle XML): turret shape "component=turret" on joint "component=turretJoint" (yaw),
-- gun shape "mainCannon component=gun" on joint "component=gunJoint" (pitch). Barrel = the gun model's longest
-- non-upright axis, pointing to the "mainCannon_emitter" side; muzzle = its end (MG_MeasureBarrel).
-- Both are measured once by the server in gun-body space and shared (a late joiner's guns may already be turned).
-- (AVF's barrels[1] offsets are in a shape-corner frame: they pointed the wrong way here.) Gunner: the rig tagged "gunner"
-- (a standing place under the vehicle's body, added by tools/porting/patches/add_seats.py; not a vehicle seat).
--
-- Network (co-op, gunner trusted like the hand guns, TECHNICAL_REFERENCE §5/§7):
--   gunner's client: aim point from its camera -> server.mgAim; fires the rounds through gunnet.lua (GunNet_Fire:
--     server = world effects and NPC damage, every client = tracer / sound), ammo and reload, HUD.
--   server: turns the turret / gun joints toward the aim, holds them when nobody mans the gun, keeps the ammo in
--     shared.mgAmmo / shared.mgMags (flat keys: nested shared tables are unverified in MP) for the next gunner.
-- Aim errors use world vectors: yaw about the turret body's up axis, pitch = elevation difference. The direction
-- each joint turns is learned the first time it moves (no API reads a joint's axis).

#include "../script/gunfunctions.lua"
#include "../script/gunperks.lua"
#include "../script/gunnet.lua"
#include "avf/AVF_Glue.lua"

MG_AIM_SPEED = 2.0        -- joint motor speed while aiming (rad/s)
MG_HOLD_STRENGTH = 5000   -- motor strength (aiming and holding)
MG_SIGHT_UP = 0.1         -- sight view: eye this far above the gun model's top
MG_SIGHT_FOV = 70         -- sight view field of view at zoom 1 (degrees)
MG_ZOOM_MAX = 4           -- mouse wheel zoom steps 1..MG_ZOOM_MAX (FOV / zoom)

-- ---------------------------------------------------------------- parts (server and client)

local function findTagged(list, value)
	for _, h in ipairs(list or {}) do
		if GetTagValue(h, "component") == value then return h end
	end
	return 0
end

--- The vehicle's body, or an emplacement's base body (no vehicle).
function MG_BaseBody()
	if MG.vehicle ~= 0 then return GetVehicleBody(MG.vehicle) end
	return MG.baseBody or 0
end

--- The vehicle's / base body's transform.
function MG_BaseT()
	if MG.vehicle ~= 0 then return GetVehicleTransform(MG.vehicle) end
	return GetBodyTransform(MG_BaseBody())
end

--- Rays ignore the vehicle / the emplacement (its base, gun, turret and launchers: as a vehicle those were all vehicle
--- bodies; with only the base skipped, the aim and camera rays could hit the tripod's own gun).
function MG_QueryRejectOwn()
	if MG.vehicle ~= 0 then QueryRejectVehicle(MG.vehicle) return end
	QueryRejectBody(MG_BaseBody())
	for _, b in ipairs(MG_OwnBodies()) do QueryRejectBody(b) end
end

function MG_FindParts()
	-- the gun's config: the AVF table's mainCannon, or the vehicle config's own MountedGunConfig (WMIK MILAN,
	-- 2026-11-13: its AVF config was disabled in the original); MountedGunGunTag / MountedGunEmitterTag name the
	-- gun shape / muzzle locations when they are not "mainCannon" / "mainCannon_emitter"
	local cfg = MountedGunConfig or (vehicleParts and vehicleParts.guns and vehicleParts.guns.mainCannon) or {}
	MG = {
		cfg = cfg,
		vehicle = FindVehicle("cfg"),
		turret = findTagged(FindShapes("component"), "turret"),
		gun = findTagged(FindShapes(MountedGunGunTag or "mainCannon"), "gun"),
		turretJoint = findTagged(FindJoints("component"), "turretJoint"),
		gunJoint = findTagged(FindJoints("component"), "gunJoint"),
		rig = FindRig("gunner"),
		capacity = (cfg.magazines and cfg.magazines[1] and cfg.magazines[1].magazineCapacity) or cfg.magazineCapacity or 100,
		rpm = cfg.RPM or 400,
		reload = cfg.reload or 4,
		dispersion = cfg.dispersion or 6,
		calibre = MountedGunCalibre or "127x99",
		sound = MountedGunSound or "MOD/snd/Weapons/m107/m107_0.ogg",
	}
	-- the joints attached to the gun / turret shapes themselves (2026-11-12, BMPs: the BMP-2's missile launcher is
	-- also tagged component=gun with its own gunJoint, so the first tagged joint could be the launcher's)
	local function ownJoint(shape, value, fallback)
		if shape == 0 then return fallback end
		for _, j in ipairs(GetShapeJoints(shape) or {}) do
			if GetTagValue(j, "component") == value then return j end
		end
		return fallback
	end
	-- no shape tagged component=turret (BMP-3: "compnent=turret", original-mod typo): the turret is the shape the
	-- turret joint turns, i.e. the one of its shapes that is not on the vehicle's body
	if MG.turret == 0 and MG.turretJoint ~= 0 then
		local vb = MG_BaseBody()
		for _, s in ipairs(GetJointShapes(MG.turretJoint) or {}) do
			if GetShapeBody(s) ~= vb then MG.turret = s end
		end
	end
	-- a gun named by MountedGunGunTag may lack component=gun (GMG offroad: tags "GMG ... interact=mountedGun"
	-- only; in-game 2026-11-13 the gun was not found and AVF's "mountedGun" prompt stayed): the first shape with that tag
	if MG.gun == 0 and MountedGunGunTag then MG.gun = FindShape(MountedGunGunTag) end
	-- no <vehicle> (gun emplacements: the Kornet / AGS-30 tripods, 2026-11-13, user: only the "Use mounted gun" prompt;
	-- as vehicles the game showed its own "Enter vehicle" on every part): the base is the body of the shape tagged
	-- component=chassis (else the turret's body)
	if MG.vehicle == 0 then
		local ch = findTagged(FindShapes("component"), "chassis")
		MG.baseBody = ch ~= 0 and GetShapeBody(ch) or (MG.turret ~= 0 and GetShapeBody(MG.turret) or 0)
	end
	MG.gunJoint = ownJoint(MG.gun, "gunJoint", MG.gunJoint)
	MG.turretJoint = ownJoint(MG.turret, "turretJoint", MG.turretJoint)
	if not HasFile(MG.sound) then -- (2026-11-12: the van PKM's path was wrong and it fired silently)
		DebugPrint("MountedGun: sound " .. MG.sound .. " not found, using the default")
		MG.sound = "MOD/snd/Weapons/m107/m107_0.ogg"
	end
	local mags = cfg.magazines and cfg.magazines[1] or {}
	MG.magazines = mags.magazineCount or 5
	-- cannons (phase 2, 2026-11-12): AVF's own shells (scripts/avf), one entry per magazine type of the config;
	-- F switches type (AVF's key). MG.capacity / MG.magazines are those of the type in use.
	-- AVF: the gun shape's XML tag weaponType (e.g. customcannon) picks the weapon type whose defaults the config
	-- overrides; a config without its own weaponType (T-34, T-54/55, Sherman) is a cannon if that type is one
	local tag = MG.gun ~= 0 and GetTagValue(MG.gun, "weaponType") or ""
	local wdef = weapons[tag] or {}
	-- MG.cannon = fires AVF's shells (scripts/avf): cannons, and (phase 3, 2026-11-13) rockets / missiles
	local wtype = cfg.weaponType or wdef.weaponType
	-- (2026-11-13) "GMGun" = AVF's grenade machine guns (AGS-30, MK-19): AVF grenade shells too
	MG.cannon = wtype == "cannon" or wtype == "rocket" or wtype == "atgm" or wtype == "GMGun"
	if MG.cannon then
		MG.rpm = cfg.RPM or wdef.RPM or MG.rpm
		MG.reload = cfg.reload or wdef.reload or MG.reload
		MG.dispersion = cfg.dispersion or wdef.dispersion or MG.dispersion
		-- a config without magazines of its own (simple_avf_tank.lua: the Kornet / AGS-30 tripods, whose gun is
		-- only AVF's weapon type from the XML tag) uses that weapon type's magazines
		MG.types = AVF_BuildMagazines(cfg.magazines and cfg or wdef, tag)
		-- no MountedGunSound (simple_avf_tank.lua serves two turrets): the weapon's own AVF sound, as the coax
		if not MountedGunSound then
			local s = cfg.soundFile or wdef.soundFile
			s = s and AVF_AssetPath(s)
			if s and not s:find("%.ogg$") then s = s .. ".ogg" end
			if s and HasFile(s) then MG.sound = s end
		end
		for _, m in ipairs(MG.types) do m.weapon = 1 end
		-- weapons (2026-11-13): 1 = the main gun; 2 = the coax MG (config mainCannon.coax, weapon type from the gun's
		-- XML tag coax=..., as AVF's loadShells(gun, coax)), fired along the main gun's line from the
		-- "mainCannon_coax_emitter" location. X switches weapon, F the ammo type within it.
		MG.weapons = { { name = cfg.name, rpm = MG.rpm, reload = MG.reload, sound = MG.sound } }
		local coaxTag = MG.gun ~= 0 and GetTagValue(MG.gun, "coax") or ""
		-- the config's coax table, or (BMP-3, T-72: none) AVF's weapon type alone, as AVF did
		local cdef = weapons[coaxTag]
		local ccfg = (type(cfg.coax) == "table" and cfg.coax.magazines) and cfg.coax or cdef
		if coaxTag ~= "" and ccfg and ccfg.magazines then
			cdef = cdef or {}
			local sound = ccfg.soundFile or cdef.soundFile
			sound = sound and AVF_AssetPath(sound)
			if sound and not sound:find("%.ogg$") then sound = sound .. ".ogg" end
			if not (sound and HasFile(sound)) then sound = "MOD/snd/Weapons/ak/ak_0.ogg" end
			MG.weapons[2] = { name = ccfg.name or cdef.name, rpm = ccfg.RPM or cdef.RPM or 600,
				reload = ccfg.reload or cdef.reload or 4, sound = sound, coax = true }
			for _, m in ipairs(AVF_BuildMagazines(ccfg, coaxTag)) do
				m.weapon = 2
				MG.types[#MG.types + 1] = m
			end
		end
		-- launchers (2026-11-13, BMP ATGMs): other entries of the AVF table whose key tags a gun shape of their own
		-- (BMP-2 "9m133m2", BMP-1 "9M133"), next on X. Fired from the launcher's front end along the main gun's line
		-- (guided missiles ride that line); the launcher's own elevation joint is only held still.
		if vehicleParts and vehicleParts.guns and not MountedGunConfig then
			for key, gcfg in pairs(vehicleParts.guns) do
				if key ~= "mainCannon" and type(gcfg) == "table" and gcfg.magazines then
					local shape = findTagged(FindShapes(key), "gun")
					if shape ~= 0 then
						local ltag = GetTagValue(shape, "weaponType")
						local ldef = weapons[ltag] or {}
						local sound = gcfg.soundFile and AVF_AssetPath(gcfg.soundFile)
						if sound and not sound:find("%.ogg$") then sound = sound .. ".ogg" end
						if not (sound and HasFile(sound)) then sound = MG.sound end
						local w = #MG.weapons + 1
						MG.weapons[w] = { name = gcfg.name or key, rpm = gcfg.RPM or ldef.RPM or 5,
							reload = gcfg.reload or ldef.reload or 4, sound = sound, launcher = shape, key = key }
						for _, m in ipairs(AVF_BuildMagazines(gcfg, ltag)) do
							m.weapon = w
							MG.types[#MG.types + 1] = m
						end
					end
				end
			end
		end
		AVF_AMMO = {}
		for i, m in ipairs(MG.types) do AVF_AMMO[i] = m.CfgAmmo end
		if #MG.types == 0 then
			MG.cannon = false
		else
			MG.capacity, MG.magazines = MG.types[1].magazineCapacity, MG.types[1].magazineCount
		end
	end
end

-- HUD names of ammo types (user, 2026-11-12: AVF showed its internal names such as "B_23mm_AA"): a config
-- magazine's own displayName, else "<calibre> mm <payload>"
MG_PAYLOAD_NAMES = { HE = "HE", AP = "AP", APHE = "APHE", HEAT = "HEAT", ["HEAT-MP"] = "HEAT-MP", HESH = "HESH",
	kinetic = "APFSDS", APSDF = "APFSDS", incendiary = "incendiary", ["HE-I"] = "HE-I", smoke = "smoke" }

function MG_AmmoLabel(t)
	local m = MG.types[t]
	if m.displayName then return m.displayName end
	-- configs that name their shells like real designations ("3UBR8 APDS", "PG15V-HEAT") keep them; AVF's internal
	-- style ("B_23mm_AA": underscores) gets "<calibre> mm <payload>"
	if m.name and not m.name:find("_") then return (m.name:gsub("%s+$", "")) end
	local c = m.CfgAmmo
	return (c.caliber or "?") .. " mm " .. (MG_PAYLOAD_NAMES[c.payload] or c.payload or m.name)
end

--- Shared keys of an ammo type's rounds / magazines (type 1: the machine guns' keys; flat keys, see header).
function MG_AmmoKeys(t)
	if not t or t == 1 then return "mgAmmo", "mgMags" end
	return "mgAmmo" .. t, "mgMags" .. t
end

--- Server, at spawn (rest pose): muzzle and barrel direction in gun-body space, shared for the clients.
-- Barrel = the gun model's longest axis that is not upright (the shape's own box, GetShapeSize); it points to the
-- side where the "mainCannon_emitter" location is (no emitter: the vehicle's front, -z). Muzzle = the end of that
-- axis. (2026-11-12: centre -> emitter was used before; the van PKM's emitter sits 0.45 m below the barrel and
-- barely in front of the gun's centre, so the barrel read as pointing down and the gun aimed high.)
-- (2026-11-12) All shapes of the gun's body count: the one with the longest non-upright axis is the barrel (the
-- Hummer's M2 has its barrel as a separate shape beside the receiver; centred on the receiver, the camera and
-- hands sat off to one side, in-game). Sight and camera are centred on that barrel; the sight's height clears the
-- tallest shape. MountedGunSightAt (vehicle config, 0 = rear .. 1 = front of the barrel shape, default 0.25).
local function shapeBox(s)
	local st = GetShapeWorldTransform(s)
	local sx, sy, sz, scale = GetShapeSize(s)
	local half = Vec(sx * scale / 2, sy * scale / 2, sz * scale / 2)
	return st, half, TransformToParentPoint(st, half)
end

function MG_MeasureBarrel()
	local gt = GetBodyTransform(GetShapeBody(MG.gun))
	local up = TransformToParentVec(MG_BaseT(), Vec(0, 1, 0))
	local shapes = GetBodyShapes(GetShapeBody(MG.gun))
	if #shapes == 0 then shapes = { MG.gun } end
	local best, bestLen, centreW
	local topW = -math.huge
	for _, s in ipairs(shapes) do
		local st, half, c = shapeBox(s)
		local reach = 0
		for i = 1, 3 do
			local e = Vec(0, 0, 0)
			e[i] = 1
			local axis = TransformToParentVec(st, e)
			reach = reach + math.abs(VecDot(axis, up)) * half[i]
			if math.abs(VecDot(axis, up)) < 0.7 and (not bestLen or half[i] > bestLen) then
				best, bestLen, centreW = axis, half[i], c
			end
		end
		topW = math.max(topW, VecDot(c, up) + reach)
	end
	if not best then
		local st, half, c = shapeBox(MG.gun)
		best, bestLen, centreW = TransformToParentVec(st, Vec(0, 0, -1)), 0.5, c
	end
	local loc = FindLocation(MountedGunEmitterTag or "mainCannon_emitter")
	local towards = loc ~= 0 and VecSub(GetLocationTransform(loc).pos, centreW)
		or TransformToParentVec(MG_BaseT(), Vec(0, 0, -1))
	if VecDot(best, towards) < 0 then best = VecScale(best, -1) end
	local fwd = TransformToLocalVec(gt, best)
	-- muzzle: on the barrel line, at the front-most point of any of the gun's shapes (2026-11-12, BMP-1: thin barrel
	-- pieces reach 0.95 m past the 1.8 m gun model; a muzzle at the model's end sat inside them and the first shell
	-- hit its own barrel)
	local front = bestLen
	for _, s in ipairs(shapes) do
		local st, half = shapeBox(s)
		for cx = 0, 1 do for cy = 0, 1 do for cz = 0, 1 do
			local corner = TransformToParentPoint(st, Vec(cx * 2 * half[1], cy * 2 * half[2], cz * 2 * half[3]))
			front = math.max(front, VecDot(VecSub(corner, centreW), best))
		end end end
	end
	local muzzle = TransformToLocalPoint(gt, VecAdd(centreW, VecScale(best, front + 0.05)))
	shared.mgMx, shared.mgMy, shared.mgMz = muzzle[1], muzzle[2], muzzle[3]
	shared.mgFx, shared.mgFy, shared.mgFz = fwd[1], fwd[2], fwd[3]
	local c = TransformToLocalPoint(gt, centreW)
	shared.mgCx, shared.mgCy, shared.mgCz = c[1], c[2], c[3]
	-- several barrels (ZU-23-2: two "mainCannon_emitter" locations, AVF fired them in turn): each barrel's offset
	-- from the barrel line, gun-body space, flat shared keys mgB<k>x/y/z; one emitter or none: no offset. Two: only
	-- sideways (the van PKM's emitter showed AVF's heights can be off); three or more (a launcher's grid of rails,
	-- Katyusha: 33, 2026-11-13): sideways and up/down, i.e. everything across the barrel line
	local emitters = FindLocations(MountedGunEmitterTag or "mainCannon_emitter")
	shared.mgBarrels = #emitters >= 2 and #emitters or 1
	if #emitters >= 2 then
		local side = VecNormalize(VecCross(best, up))
		local across = VecNormalize(VecCross(side, best))
		for k, e in ipairs(emitters) do
			local rel = VecSub(GetLocationTransform(e).pos, centreW)
			local off = VecScale(side, VecDot(rel, side))
			if #emitters >= 3 then off = VecAdd(off, VecScale(across, VecDot(rel, across))) end
			local o = TransformToLocalVec(gt, off)
			shared["mgB" .. k .. "x"], shared["mgB" .. k .. "y"], shared["mgB" .. k .. "z"] = o[1], o[2], o[3]
		end
	end
	-- sight view eye: above the barrel at MountedGunSightAt, MG_SIGHT_UP over the tallest shape (AVF's config
	-- "sight" offsets are copy-pasted between guns, not used)
	shared.mgTopUp = topW - VecDot(centreW, up) -- tallest part's top above the barrel centre (camera height)
	local coaxLoc = FindLocation("mainCannon_coax_emitter")
	if coaxLoc ~= 0 then
		local c2 = TransformToLocalPoint(gt, GetLocationTransform(coaxLoc).pos)
		shared.mgCoaxX, shared.mgCoaxY, shared.mgCoaxZ = c2[1], c2[2], c2[3]
	end
	local at = MountedGunSightAt or 0.25
	local onAxis = VecAdd(centreW, VecScale(best, bestLen * (2 * at - 1)))
	local sight = TransformToLocalPoint(gt, VecAdd(onAxis, VecScale(up, topW + MG_SIGHT_UP - VecDot(onAxis, up))))
	shared.mgSx, shared.mgSy, shared.mgSz = sight[1], sight[2], sight[3]
end

--- The barrel shape's centre (world).
function MG_BarrelCentre()
	local gt = GetBodyTransform(GetShapeBody(MG.gun))
	return TransformToParentPoint(gt, Vec(shared.mgCx or 0, shared.mgCy or 0, shared.mgCz or 0))
end

--- The sight view's eye position (world).
function MG_Sight()
	local gt = GetBodyTransform(GetShapeBody(MG.gun))
	return TransformToParentPoint(gt, Vec(shared.mgSx or 0, shared.mgSy or 0.2, shared.mgSz or 0))
end

--- The gun's muzzle position and barrel direction (world); barrel k of a multi-barrel gun (default: the middle).
function MG_Muzzle(k)
	local gt = GetBodyTransform(GetShapeBody(MG.gun))
	local m = Vec(shared.mgMx or 0, shared.mgMy or 0, shared.mgMz or -1)
	if k and shared["mgB" .. k .. "x"] then
		m = VecAdd(m, Vec(shared["mgB" .. k .. "x"], shared["mgB" .. k .. "y"], shared["mgB" .. k .. "z"]))
	end
	local f = Vec(shared.mgFx or 0, shared.mgFy or 0, shared.mgFz or -1)
	return TransformToParentPoint(gt, m), TransformToParentVec(gt, f)
end

--- The coax MG's muzzle (world; along the main barrel), or the main muzzle when the gun has none.
function MG_CoaxMuzzle()
	local m, f = MG_Muzzle()
	if not shared.mgCoaxX then return m, f end
	local gt = GetBodyTransform(GetShapeBody(MG.gun))
	return TransformToParentPoint(gt, Vec(shared.mgCoaxX, shared.mgCoaxY, shared.mgCoaxZ)), f
end

--- Server, at spawn: each launcher's muzzle = the front of its shape along the main barrel's direction, on the
--- line through its centre, in the launcher body's space (shared mgL<w>x/y/z).
function MG_MeasureLaunchers()
	local _, f = MG_Muzzle()
	for w, wp in ipairs(MG.weapons or {}) do
		if wp.launcher then
			local st, half, c = shapeBox(wp.launcher)
			local front = 0
			for cx = 0, 1 do for cy = 0, 1 do for cz = 0, 1 do
				local corner = TransformToParentPoint(st, Vec(cx * 2 * half[1], cy * 2 * half[2], cz * 2 * half[3]))
				front = math.max(front, VecDot(VecSub(corner, c), f))
			end end end
			-- the camera also clears the launcher (in-game 2026-11-13: the BMP-2's Kornet launcher blocked the view
			-- ahead): shared.mgTopUp = the highest point of the gun's shapes and launchers above the barrel centre
			local up = TransformToParentVec(MG_BaseT(), Vec(0, 1, 0))
			local base = VecDot(MG_BarrelCentre(), up)
			for cx = 0, 1 do for cy = 0, 1 do for cz = 0, 1 do
				local corner = TransformToParentPoint(st, Vec(cx * 2 * half[1], cy * 2 * half[2], cz * 2 * half[3]))
				shared.mgTopUp = math.max(shared.mgTopUp or 0, VecDot(corner, up) - base)
			end end end
			local lt = GetBodyTransform(GetShapeBody(wp.launcher))
			local m = TransformToLocalPoint(lt, VecAdd(c, VecScale(f, front + 0.1)))
			shared["mgL" .. w .. "x"], shared["mgL" .. w .. "y"], shared["mgL" .. w .. "z"] = m[1], m[2], m[3]
			wp.holdJoint = { joint = 0 }
			for _, j in ipairs(GetShapeJoints(wp.launcher) or {}) do
				if GetTagValue(j, "component") == "gunJoint" then wp.holdJoint.joint = j end
			end
		end
	end
end

--- A launcher's muzzle (world), along the main barrel.
function MG_LauncherMuzzle(w)
	local _, f = MG_Muzzle()
	local wp = MG.weapons[w]
	if not (wp and wp.launcher and shared["mgL" .. w .. "x"]) then return MG_Muzzle() end
	local lt = GetBodyTransform(GetShapeBody(wp.launcher))
	return TransformToParentPoint(lt, Vec(shared["mgL" .. w .. "x"], shared["mgL" .. w .. "y"], shared["mgL" .. w .. "z"])), f
end

--- The muzzle and barrel direction of the weapon in use (coax MG: its own muzzle, along the main barrel).
function MG_CurMuzzle()
	if MG.cannon and MG.weapons and MG.types[MG.type or 1] then
		local w = MG.types[MG.type or 1].weapon or 1
		local wp = MG.weapons[w]
		if wp and wp.coax then return MG_CoaxMuzzle() end
		if wp and wp.launcher then return MG_LauncherMuzzle(w) end
	end
	return MG_Muzzle()
end

--- The barrel as AVF's guns had it: a transform at the muzzle whose local -y points along the barrel (guided
--- missiles ride this line, AVF_Glue retrieve_first_barrel_coord).
function MG_BarrelTransform()
	local m, f = MG_Muzzle()
	return Transform(m, QuatRotateQuat(QuatLookAt(m, VecAdd(m, f)), QuatEuler(90, 0, 0)))
end

--- The player manning this gun, or nil (server: MG.gunner; clients: shared.mgGunner, 0 = nobody).
function MG_Gunner()
	local g = shared.mgGunner or 0
	if g == 0 then return nil end
	return g
end

-- ---------------------------------------------------------------- server

local function wrap180(a)
	while a > 180 do a = a - 360 end
	while a < -180 do a = a + 360 end
	return a
end

local function clamp1(x) return math.max(-1, math.min(1, x)) end

--- Aim errors (degrees) for a world direction: yaw about the turret's up axis, pitch = elevation difference.
function MG_AimErrors(dir)
	local _, f = MG_Muzzle()
	local up = TransformToParentVec(GetBodyTransform(GetShapeBody(MG.turret)), Vec(0, 1, 0))
	local flat = VecNormalize(VecSub(f, VecScale(up, VecDot(f, up))))
	local right = VecCross(flat, up)
	local yaw = wrap180(math.deg(math.atan2(VecDot(dir, right), VecDot(dir, flat))))
	local pitch = math.deg(math.asin(clamp1(VecDot(dir, up))) - math.asin(clamp1(VecDot(f, up))))
	return yaw, pitch
end

--- The barrel's own angles (degrees): heading in the vehicle body's frame (positive = the yaw error's "right"),
--- elevation about the turret's up axis. The probe below learns each joint's direction from these.
function MG_BarrelAngles()
	local _, f = MG_Muzzle()
	local up = TransformToParentVec(GetBodyTransform(GetShapeBody(MG.turret)), Vec(0, 1, 0))
	local fwd0 = TransformToParentVec(GetBodyTransform(MG_BaseBody()), Vec(0, 0, -1))
	local right0 = VecCross(fwd0, up)
	return math.deg(math.atan2(VecDot(f, right0), VecDot(f, fwd0))), math.deg(math.asin(clamp1(VecDot(f, up))))
end

-- One joint driven toward an error angle. sign = how joint movement maps to the barrel's angle (learned by a
-- probe: nudge the joint, watch the barrel). (2026-11-12: the probe watched the aim error instead; mouse movement
-- during the probe could flip it, and the Hummer's gun then ran away from the aim to its limits, in-game.)
local function driveJoint(j, err, angle)
	if j.joint == 0 then return end
	local m = GetJointMovement(j.joint)
	if not j.sign then
		if not j.probe then
			if math.abs(err) < 1 then SetJointMotor(j.joint, 0, MG_HOLD_STRENGTH) return end
			j.probe = { m = m, a = angle, t = 0 }
			SetJointMotor(j.joint, 0.5, MG_HOLD_STRENGTH)
			return
		end
		j.probe.t = j.probe.t + 1
		local dm, da = m - j.probe.m, wrap180(angle - j.probe.a)
		if math.abs(dm) > 0.5 and math.abs(da) > 0.25 then
			j.sign = (dm * da > 0) and 1 or -1 -- movement up turns the barrel toward +error: target = movement + error
			j.probe = nil
		elseif j.probe.t > 30 then
			j.probe = nil -- did not move (limit / blocked): try again later
			SetJointMotor(j.joint, 0, MG_HOLD_STRENGTH)
		else
			SetJointMotor(j.joint, 0.5 * (j.probe.t % 20 < 10 and 1 or -1), MG_HOLD_STRENGTH)
		end
		return
	end
	-- the target stays inside the joint's limits: pushing past a limit made the gun shake there (in-game
	-- 2026-11-13, tanks aiming down below their depression limit)
	local target = m + j.sign * err
	local lo, hi = GetJointLimits(j.joint)
	if lo and hi and hi > lo then target = math.max(lo, math.min(hi, target)) end
	SetJointMotorTarget(j.joint, target, MG_AIM_SPEED, MG_HOLD_STRENGTH)
	j.hold = nil
end

local function holdJoint(j)
	if j.joint == 0 then return end
	j.hold = j.hold or GetJointMovement(j.joint)
	SetJointMotorTarget(j.joint, j.hold, MG_AIM_SPEED, MG_HOLD_STRENGTH)
end

--- The "Use mounted gun" prompt on (gun free) / off (manned, retired).
function MG_Prompt(on)
	if on then SetTag(MG.useShape, "interact", "Use mounted gun") else RemoveTag(MG.useShape, "interact") end
end

--- The player aims at the gun's prompt (this tick, or one tick earlier: last).
local function aimsAtGun(p, last)
	return GetPlayerInteractShape(p) == MG.useShape or last.shape == MG.useShape
end

function server.init()
	GunNet_ServerInit()
	ProjectileHandlerInit()
	MG_FindParts()
	if MG.gun ~= 0 then MG_MeasureBarrel() end
	if MG.gun ~= 0 then MG_MeasureLaunchers() end
	if MG.gun ~= 0 and MG.rig ~= 0 and MG.turret ~= 0 then MG_MeasureRig() end
	if MG.gun ~= 0 then MG_MeasureAttach() end
	MG.yawJoint = { joint = MG.turretJoint }
	MG.pitchJoint = { joint = MG.gunJoint }
	MG.aim = {}
	shared.mgAmmo, shared.mgMags = MG.capacity, MG.magazines
	if MG.cannon then
		AVF_ServerInit()
		for t = 2, #MG.types do
			local ka, km = MG_AmmoKeys(t)
			shared[ka], shared[km] = MG.types[t].magazineCapacity, MG.types[t].magazineCount
		end
	end
	shared.mgGunner = 0
	shared.mgDriver = 0
	-- the shape whose prompt puts you on the gun: the gun itself for a standing gunner; the turret / mount for a seated
	-- one (2026-11-12, ZU-23-2: the game shows a prompt at the tagged shape's centre, which was out on the barrel).
	-- AVF's own tag on the gun (prompt "mountedGun") is replaced / removed.
	MG.useShape = MG.gun
	if MG.pose and MG.pose.anchor == "seat" and MG.turret ~= 0 then
		MG.useShape = MG.turret
		if MG.gun ~= 0 then RemoveTag(MG.gun, "interact") end
	end
	if MG.useShape ~= 0 and MG.rig ~= 0 then MG_Prompt(true) end
	-- no gunner place (tripods, Katyusha, ...): AVF's "mountedGun" prompt did nothing without AVF (in-game 2026-11-13,
	-- Kornet / AGS-30 tripods): removed; the gun is fired from the vehicle's seat
	if MG.rig == 0 and MG.gun ~= 0 then RemoveTag(MG.gun, "interact") end
end

-- The gunner's place is NOT a vehicle seat (user, 2026-11-12; in-game tests 1-2: as a passenger rig of the vehicle,
-- "Use mounted gun" always ended in the driver's seat). It works like the game's own turret
-- (data/level/carib/script/turret.lua): a rig under the vehicle's body (tags "gunner relative_parent"), the player
-- stays on foot and the server calls SetPlayerRig every tick while they man the gun. Interact again = step off
-- (back to where they stood, relative to the vehicle). The hand tool is put away while on the gun ("" = no tool,
-- as inventory.lua's InvSetTool) and given back afterwards.
-- MountedGunHoldGunner (GMG offroad, in-game 2026-11-13: the gunner bobbed up and down, pulled back 33 times; its
-- roof has a crossbar across the ring hole at the gunner's waist, 0.1 m in front of the place, the hole behind it is
-- 0.3 m deep): while on the gun the player does not collide with the vehicle's own shapes (its shapes go to
-- collision layer MG_HOLD_LAYER, the gunner's CollisionMask leaves that layer out) and is held at the place every
-- tick. Other players still collide with them (their mask is unchanged). Also the tripods (in-game 2026-11-13: the AGS-30's
-- gunner, whose place is right behind the gun, was pushed 0.25 m off it; held: 0).
MG_HOLD_LAYER = 128
MG_PIN_DIST = 0.5 -- if the rig does not hold the player (drift from the rig beyond this), the script moves them back
MG_PIN_DIST_SEATED = 1.2 -- seated (ZU-23-2): the player's position may sit below the seat point (unverified)

local function vehicleT() return MG_BaseT() end

--- MountedGunHoldGunner: the gunner p passes through the vehicle's own shapes (on = true) or no longer (on = false).
function MG_HoldCollision(p, on)
	if not MountedGunHoldGunner then return end
	if on then
		MG.held = {}
		local bodies = { MG_BaseBody() }
		for _, b in ipairs(MG.vehicle ~= 0 and GetVehicleBodies(MG.vehicle) or {}) do bodies[#bodies + 1] = b end
		for _, b in ipairs(MG_OwnBodies()) do bodies[#bodies + 1] = b end
		for _, b in ipairs(bodies) do
			for _, sh in ipairs(GetBodyShapes(b) or {}) do
				if not MG.held[sh] then
					local layer, mask = GetShapeCollisionFilter(sh)
					MG.held[sh] = { layer, mask }
					-- MG_HOLD_LAYER also left out of their own mask: the held parts do not collide with each other
					-- while manned, still with the world
					SetShapeCollisionFilter(sh, MG_HOLD_LAYER, mask >= MG_HOLD_LAYER and mask - MG_HOLD_LAYER or mask)
				end
			end
		end
		MG.heldMask = GetPlayerParam("CollisionMask", p)
		SetPlayerParam("CollisionMask", 255 - MG_HOLD_LAYER, p)
	elseif MG.held then
		for sh, f in pairs(MG.held) do
			if IsHandleValid(sh) then SetShapeCollisionFilter(sh, f[1], f[2]) end
		end
		MG.held = nil
		if p then SetPlayerParam("CollisionMask", MG.heldMask or 255, p) end
	end
end

-- The gunner's body turns with the gun (user, 2026-11-12: standing still looked awkward). Measured at spawn (rest
-- pose): the "stand" location relative to the turret body, turned to face the barrel (the Humvee's faced away); the
-- feet relative to it; the hands relative to the gun body. Every tick while manned the locations are set again from
-- the turret / gun bodies (SetRigLocationWorldTransform). Server only (in SP the same machine; MP sync unverified).
MG_FEET = { "ik_foot_l", "ik_foot_r" }
MG_HANDS = { "ik_hand_l", "ik_hand_r" }

function MG_MeasureRig()
	local turretT = GetBodyTransform(GetShapeBody(MG.turret))
	local gunT = GetBodyTransform(GetShapeBody(MG.gun))
	-- anchor: "stand" (standing gunner) or "seat" (seated on the gun's mount, ZU-23-2: add_seats.py gunner_seated)
	local anchor = "stand"
	local stand = GetRigLocationWorldTransform(MG.rig, "stand")
	if not stand then
		anchor, stand = "seat", GetRigLocationWorldTransform(MG.rig, "seat")
	end
	if not stand then return end
	local _, f = MG_Muzzle()
	local up = TransformToParentVec(turretT, Vec(0, 1, 0))
	local flat = VecNormalize(VecSub(f, VecScale(up, VecDot(f, up))))
	local facing = Transform(stand.pos, QuatLookAt(stand.pos, VecAdd(stand.pos, flat)))
	MG.pose = { anchor = anchor, stand = TransformToLocalTransform(turretT, facing), feet = {}, hands = {}, seatHands = {} }
	if anchor == "seat" then
		-- seated: hands stay on the knees (relative to the seat, like the feet), the mount turns them with it
		for _, name in ipairs(MG_HANDS) do
			local t = GetRigLocationWorldTransform(MG.rig, name)
			if t then MG.pose.seatHands[name] = TransformToLocalTransform(stand, t) end
		end
	end
	for _, n in ipairs(MG_FEET) do
		local t = GetRigLocationWorldTransform(MG.rig, n)
		if t then MG.pose.feet[n] = TransformToLocalTransform(stand, t) end
	end
	-- hands: their midpoint moved sideways onto the barrel's line (2026-11-12: on the Hummer they sat beside the
	-- grips, in-game; the layout's grip points were estimates)
	local hands, mid, n = {}, Vec(0, 0, 0), 0
	for _, name in ipairs(anchor == "stand" and MG_HANDS or {}) do
		local t = GetRigLocationWorldTransform(MG.rig, name)
		if t then hands[name] = t; mid = VecAdd(mid, t.pos); n = n + 1 end
	end
	local shift = Vec(0, 0, 0)
	-- MountedGunKeepGrip: the layout's grip as laid (AGS-30, in-game 2026-11-13: its ammo box widens the gun model
	-- 0.6 m to one side, the "barrel line" from the model's box sat 0.2 m beside the tube and the hands with it)
	if n > 0 and not MountedGunKeepGrip then
		mid = VecScale(mid, 1 / n)
		local right = VecNormalize(VecCross(flat, up))
		shift = VecScale(right, -VecDot(VecSub(mid, MG_BarrelCentre()), right))
	end
	for name, t in pairs(hands) do
		MG.pose.hands[name] = TransformToLocalTransform(gunT, Transform(VecAdd(t.pos, shift), t.rot))
	end
end

--- The stand location's world transform now (turret-relative), or nil.
function MG_StandWorld()
	if not MG.pose then return nil end
	return TransformToParentTransform(GetBodyTransform(GetShapeBody(MG.turret)), MG.pose.stand)
end

function MG_PoseGunner()
	local stand = MG_StandWorld()
	if not stand then return end
	SetRigLocationWorldTransform(MG.rig, MG.pose.anchor, stand)
	for n, l in pairs(MG.pose.feet) do SetRigLocationWorldTransform(MG.rig, n, TransformToParentTransform(stand, l)) end
	for n, l in pairs(MG.pose.seatHands) do SetRigLocationWorldTransform(MG.rig, n, TransformToParentTransform(stand, l)) end
	local gunT = GetBodyTransform(GetShapeBody(MG.gun))
	for n, l in pairs(MG.pose.hands) do SetRigLocationWorldTransform(MG.rig, n, TransformToParentTransform(gunT, l)) end
end

function MG_Dismount(teleport)
	local g = MG.gunnerId
	if not g then return end
	MG_HoldCollision(g, false)
	if teleport and MG.exit then
		SetPlayerTransform(TransformToParentTransform(vehicleT(), MG.exit), g)
	end
	if MG.prevTool then SetPlayerTool(MG.prevTool, g) end
	MG_Prompt(true)
	MG.gunnerId, MG.exit, MG.prevTool = nil, nil, nil
	MG.aim[g] = nil
	shared.mgGunner = 0
end

--- Seated by the engine on the gun place (the rig counts as the vehicle's last seat). That counts as manning the
--- gun: in-game 2026-11-12, with the other seats destroyed the engine kept the player in that seat, and taking them
--- out (SetPlayerVehicle 0) and then dropping them off the gun for "being in a vehicle" looped every tick.
local function onGunSeat(p)
	return MG.vehicle ~= 0 and GetPlayerVehicle(p) == MG.vehicle and GetPlayerRig(p) == MG.rig
end

--- The gun can be manned (MG_GunUnusable / MG_GunUsable below).
-- (2026-11-13, BMP-3: the turret "randomly" stopped turning) Was: any IsShapeBroken (true once a shape lost any
-- voxel: a stray hit on the gun or turret retired it for good) and the barrel's distance from the vehicle origin
-- (a long barrel on a turret away from the origin reaches further when turned). Now: the gun keeps at least
-- MG_MIN_GUN_VOXELS of its voxels, its joints hold, the gun stays near its turret and the turret near the vehicle
-- (distances measured at spawn + MG_DETACH_SLACK; both stay the same while turning).
MG_MIN_GUN_VOXELS = 0.25
MG_DETACH_SLACK = 1.0

local function bodyCentre(shape)
	local mi, ma = GetShapeBounds(shape)
	return VecLerp(mi, ma, 0.5)
end

function MG_MeasureAttach()
	MG.gunVoxels0 = GetShapeVoxelCount(MG.gun)
	if MG.turret ~= 0 then
		MG.gunToTurret = VecLength(VecSub(bodyCentre(MG.gun), bodyCentre(MG.turret))) + MG_DETACH_SLACK
		MG.turretToVehicle = VecLength(VecSub(bodyCentre(MG.turret), vehicleT().pos)) + MG_DETACH_SLACK
	end
end

--- Why the gun can no longer be used (a short reason), or nil while it can.
function MG_GunUnusable()
	if MG.gun == 0 then return "no gun" end
	if MG.gunVoxels0 and MG.gunVoxels0 > 0 and GetShapeVoxelCount(MG.gun) < MG.gunVoxels0 * MG_MIN_GUN_VOXELS then
		return "gun destroyed"
	end
	if MG.turretJoint ~= 0 and IsJointBroken(MG.turretJoint) then return "turret joint broken" end
	if MG.gunJoint ~= 0 and IsJointBroken(MG.gunJoint) then return "gun joint broken" end
	if MG.gunToTurret and VecLength(VecSub(bodyCentre(MG.gun), bodyCentre(MG.turret))) > MG.gunToTurret then
		return "gun off its turret"
	end
	if MG.turretToVehicle and VecLength(VecSub(bodyCentre(MG.turret), vehicleT().pos)) > MG.turretToVehicle then
		return "turret off the vehicle"
	end
	return nil
end

function MG_GunUsable()
	return MG_GunUnusable() == nil
end

--- Destroyed or broken off (in-game 2026-11-12: a gun lying on the ground could still be manned, and with the
--- seats destroyed the engine kept seating players on the gun place, also after the gun was gone): the gunner
--- gets off, anyone the engine seated there is taken out, and the gun place's rig is deleted, so the engine has
--- no seat there any more. Once, for good.
function MG_Retire(reason)
	shared.mgRetired = true
	MG_Dismount(true)
	for p in Players() do
		if onGunSeat(p) then SetPlayerVehicle(0, p) end
	end
	MG_Prompt(false)
	Delete(MG.rig)
	MG.rig = 0
end

function MG_UpdateGunner()
	if MG.gun == 0 or MG.rig == 0 then return end
	local why = MG_GunUnusable()
	if why then MG_Retire(why) return end
	MG.last = MG.last or {}
	local g = MG.gunnerId
	if g then
		local here = false
		for p in Players() do if p == g then here = true end end
		if not here then
			MG_HoldCollision(nil, false)
			MG.gunnerId, MG.exit, MG.prevTool = nil, nil, nil
			shared.mgGunner = 0
			MG_Prompt(true)
		elseif GetPlayerHealth(g) <= 0 or (GetPlayerVehicle(g) ~= 0 and not onGunSeat(g)) then
			MG_Dismount(false) -- died, or got into a vehicle (other than the engine's seat on the gun place)
		elseif InputPressed("interact", g) then
			MG_Dismount(true)
		else
			MG_PoseGunner()
			SetPlayerRig(MG.rig, g)
			if GetPlayerTool(g) ~= "" then SetPlayerTool("", g) end
			local rt = MG_StandWorld() or GetRigWorldTransform(MG.rig)
			local pt = GetPlayerTransform(g)
			local pin = (MG.pose and MG.pose.anchor == "seat") and MG_PIN_DIST_SEATED or MG_PIN_DIST
			if rt and MountedGunHoldGunner then
				SetPlayerTransform(Transform(rt.pos, pt.rot), g)
				SetPlayerVelocity(GetBodyVelocityAtPos(MG_BaseBody(), rt.pos), g)
			elseif rt and VecLength(VecSub(pt.pos, rt.pos)) > pin then
				SetPlayerTransform(Transform(rt.pos, pt.rot), g)
				SetPlayerVelocity(GetBodyVelocityAtPos(MG_BaseBody(), rt.pos), g)
			end
		end
	end
	-- The engine still counts the rig as a seat of the vehicle (in-game 2026-11-12: the "Enter vehicle" prompt moved to
	-- it; now sort=99, after every real seat). Anyone it seats there (real seats full or destroyed) mans the gun if it
	-- is free and intact, staying in that seat (onGunSeat); otherwise they just stay seated. Taking them out of the
	-- seat made the engine reseat them every tick (in-game 2026-11-12, twice).
	-- A player who just stepped off from that seat is left alone until the engine has let them out of it.
	MG.noRemount = MG.noRemount or {}
	if g and not MG.gunnerId then MG.noRemount[g] = true end
	for p in Players() do
		if MG.noRemount[p] and not onGunSeat(p) then MG.noRemount[p] = nil end
		if not MG.gunnerId and not MG.noRemount[p] and onGunSeat(p) then
			MG.last[p] = { veh = 0, shape = MG.useShape, t = TransformToLocalTransform(vehicleT(), GetPlayerTransform(p)) }
			MG.forceMount = p
		end
	end
	if not g then
		for p in Players() do
			local last = MG.last[p] or {}
			-- the engine may take the same key press as "enter the vehicle" (the gun is part of it): the shape under
			-- the crosshair one tick earlier counts too, and a player it has just seated is taken out again
			if MG.forceMount == p or InputPressed("interact", p) and (MG.vehicle == 0 or last.veh ~= MG.vehicle) and GetPlayerHealth(p) > 0
				and aimsAtGun(p, last) then
				MG.forceMount = nil
				if GetPlayerVehicle(p) ~= 0 and not onGunSeat(p) then SetPlayerVehicle(0, p) end
				MG.gunnerId = p
				MG.exit = last.t or TransformToLocalTransform(vehicleT(), GetPlayerTransform(p))
				MG.prevTool = GetPlayerTool(p)
				shared.mgGunner = p
				MG_Prompt(false)
				MG_HoldCollision(p, true)
				SetPlayerRig(MG.rig, p)
				break
			end
		end
	end
	for p in Players() do
		local l = MG.last[p] or {}
		l.veh = GetPlayerVehicle(p)
		l.shape = GetPlayerInteractShape(p)
		if l.veh == 0 and p ~= MG.gunnerId then l.t = TransformToLocalTransform(vehicleT(), GetPlayerTransform(p)) end
		MG.last[p] = l
	end
end

-- Driver fallback (tanks, user 2026-11-13: "gunner, driver fallback"; config MountedGunDriverFires = true): while
-- nobody mans the gunner place, the player driving the vehicle aims with the vehicle camera and fires, as AVF had
-- it; a gunner on the gunner place takes over. shared.mgDriver = that driver (0 = none).
function MG_UpdateDriver()
	local d = nil
	if MountedGunDriverFires and not MG.gunnerId and MG.gun ~= 0 and MG_GunUsable() then
		for p in Players() do
			if MG.vehicle ~= 0 and GetPlayerVehicle(p) == MG.vehicle and IsPlayerVehicleDriver(MG.vehicle, p) and GetPlayerHealth(p) > 0 then d = p end
		end
	end
	if d ~= MG.driverId and MG.driverId then MG.aim[MG.driverId] = nil end
	MG.driverId = d
	shared.mgDriver = d or 0
end

--- Who works the gun now: the gunner, else the driver (driver fallback), else nil.
function MG_Operator()
	return MG.gunnerId or MG.driverId
end

--- The gunner's client: the world direction it wants the barrel to point (from the muzzle to its aim point).
function server.mgAim(playerId, dir)
	MG.aim[playerId] = dir
end

--- The gunner's client: ammo after a shot / reload, kept for the next gunner.
function server.mgAmmo(playerId, ammo, mags, t)
	if MG_Operator() == playerId then
		local ka, km = MG_AmmoKeys(t)
		shared[ka], shared[km] = ammo, mags
	end
end

--- The bodies of the gun, the turret and the launchers: shells skip them.
function MG_OwnBodies()
	local list = { GetShapeBody(MG.gun) }
	if MG.turret ~= 0 then list[#list + 1] = GetShapeBody(MG.turret) end
	for _, wp in ipairs(MG.weapons or {}) do
		if wp.launcher then list[#list + 1] = GetShapeBody(wp.launcher) end
	end
	return list
end

--- Cannons: the gunner's client fired one round of ammo type t (rate and ammo are counted there, trusted as the
--- hand guns are); the server fires AVF's shell from the muzzle along the barrel and tells every client.
function server.mgCannonFire(playerId, t, tracer)
	if not MG.cannon or MG_Operator() ~= playerId or not MG.types[t] or not MG_GunUsable() then return end
	local w = MG.types[t].weapon or 1
	local muzzle, fwd
	if MG.weapons[w] and MG.weapons[w].coax then
		muzzle, fwd = MG_CoaxMuzzle()
	elseif MG.weapons[w] and MG.weapons[w].launcher then
		muzzle, fwd = MG_LauncherMuzzle(w)
	else
		MG.barrel = ((MG.barrel or 0) % (shared.mgBarrels or 1)) + 1 -- barrels in turn
		muzzle, fwd = MG_Muzzle(MG.barrel)
	end
	AVF_PushShell(MG.types[t].CfgAmmo, muzzle, fwd, {
		owner = playerId, body = MG_BaseBody(), gun = MG.gun, rpm = MG.weapons[w].rpm,
		dispersion = MG.dispersion or 1, tracer = tracer, ammo = t,
		reject = MG_OwnBodies(),
		barrel = MG_BarrelTransform })
	ClientCall(0, "client.mgFireFx", muzzle, fwd, w)
end

function server.tick(dt)
	GunNet_ServerTick(dt)
	if MG.cannon then AVF_ServerTick(dt) end -- shells in flight keep flying when the gun is gone
	if MG.gun == 0 then return end
	MG_UpdateGunner()
	MG_UpdateDriver()
	-- retired, or a gun without a gunner place (still worked by the driver fallback, e.g. T-72 variants without a rig)
	if shared.mgRetired or not MG_GunUsable() or (MG.rig == 0 and not MG.driverId) then return end
	local p = MG_Operator()
	local dir = p and MG.aim[p]
	if dir then
		local yaw, pitch = MG_AimErrors(dir)
		local heading, elevation = MG_BarrelAngles()
		driveJoint(MG.yawJoint, yaw, heading)
		driveJoint(MG.pitchJoint, pitch, elevation)
	else
		holdJoint(MG.yawJoint)
		holdJoint(MG.pitchJoint)
	end
	for _, wp in ipairs(MG.weapons or {}) do
		if wp.holdJoint then holdJoint(wp.holdJoint) end -- launchers: held still
	end
end

-- ---------------------------------------------------------------- client

function client.init()
	ProjectileHandlerInit()
	GunFunctions_LoadSounds()
	MG_FindParts()
	MG.shotTimer, MG.reloadTimer, MG.wasGunner = 0, 0, false
	MG.snd = LoadSound(MG.sound)
	MG.weaponSnd = {}
	for w, wp in ipairs(MG.weapons or {}) do MG.weaponSnd[w] = LoadSound(wp.sound) end
	MG.sndReloadOut = LoadSound("MOD/snd/Weapons/m107/m107_magout.ogg")
	MG.sndReloadIn = LoadSound("MOD/snd/Weapons/m107/m107_magin.ogg")
	MG.sndDry = LoadSound("MOD/snd/Weapons/Shared/dryfire.ogg")
	MG.type = 1
	if MG.cannon then AVF_ClientInit() end
end

--- Cannons: every client, when the server fired a shell (sound, muzzle flash; the gunner's camera shakes).
function client.mgFireFx(muzzle, fwd, w)
	PlaySound((w and MG.weaponSnd and MG.weaponSnd[w]) or MG.snd, muzzle, 1.0)
	ParticleReset()
	ParticleType("plain")
	ParticleColor(1, 0.7, 0.4)
	ParticleRadius(0.3)
	ParticleEmissive(5, 0)
	SpawnParticle(VecAdd(muzzle, VecScale(fwd, 0.2)), VecScale(fwd, 4), 0.05)
	local me = GetLocalPlayer()
	if shared.mgGunner == me or ((shared.mgGunner or 0) == 0 and shared.mgDriver == me) then ShakeCamera(0.3) end
end

function client.update(dt)
	if MG.cannon then AVF_ClientUpdate(dt) end
end

--- Cannons: switch to ammo type t (its rounds / magazines from the shared state).
--- The weapon in use: its name, rpm, reload, sound (machine guns: the gun's own values).
function MG_CurWeapon()
	local w = MG.cannon and MG.types[MG.type or 1] and MG.types[MG.type or 1].weapon or 1
	return (MG.weapons and MG.weapons[w]) or { name = MG.cfg.name, rpm = MG.rpm, reload = MG.reload, sound = MG.sound }
end

local function selectType(t)
	MG.type = t
	local ka, km = MG_AmmoKeys(t)
	MG.capacity = MG.types[t].magazineCapacity
	MG.ammo, MG.mags = shared[ka] or MG.capacity, shared[km] or MG.types[t].magazineCount
	MG.reloadTimer, MG.shotTimer = 0, 0 -- (the previous weapon's cycle does not hold this one)
	-- an empty magazine reloads by itself (as after a shot; in-game 2026-11-13: back in the tank the cannon sat at
	-- 0 / 1 until clicked)
	if MG.ammo == 0 and MG.mags > 0 then
		local wp = MG_CurWeapon()
		MG.reloadTimer = (MG.capacity == 1) and (60 / wp.rpm) or wp.reload
	end
end

local function localIsGunner()
	return (shared.mgGunner or 0) ~= 0 and shared.mgGunner == GetLocalPlayer()
end

--- This client's part on the gun: "gunner" (on the gunner place), "driver" (driver fallback), or nil.
local function localRole()
	local me = GetLocalPlayer()
	if (shared.mgGunner or 0) ~= 0 then return shared.mgGunner == me and "gunner" or nil end
	if (shared.mgDriver or 0) ~= 0 and shared.mgDriver == me then return "driver" end
	return nil
end

-- Gunner camera (in-game 2026-11-12: from the player's own first-person eye the gun blocked the view, the Humvee
-- gunner faced away from the gun, the van's window blocked it). Like the game's own turret (turret.lua:
-- SetCameraTransform from client.tick), but the camera only follows the gun's position: its rotation stays the
-- player's look (mouse), the gun turns toward that, so the two never chase each other. Above and behind the gun,
-- pulled in when something is behind it.
MG_CAM_BACK = 2.2 -- m behind the gun's centre, along the look direction
MG_CAM_UP = 0.7   -- m above it (world up)
MG_CAM_ABOVE_TOP = 0.5 -- ...and at least this far above the gun's tallest part (shared.mgTopUp)

-- The look is the script's own (pitch/yaw from the mouse, InputValue camerax/cameray in radians, as
-- creativemode.lua and AVF): turning the gunner's body with the gun turns the player's own look, and with that
-- the camera jumped and was pulled back up (in-game 2026-11-12). Starts from the player's look when they mount.
--- The gun camera's look (pitch / yaw, degrees) along the barrel as it points now: the driver's gun view starts
--- there (in-game 2026-11-13: it started straight ahead while the turret pointed elsewhere).
function MG_LookAlongBarrel()
	local _, f = MG_Muzzle()
	return { pitch = math.deg(math.asin(math.max(-1, math.min(1, f[2])))), yaw = math.deg(math.atan2(-f[1], -f[3])) % 360 }
end

function MG_UpdateLook(sens)
	if not MG.look then
		local px, py = GetQuatEuler(GetPlayerCameraTransform().rot)
		MG.look = { pitch = px, yaw = py }
	end
	MG.look.pitch = math.max(-85, math.min(85, MG.look.pitch - math.deg(InputValue("cameray")) * sens))
	MG.look.yaw = (MG.look.yaw - math.deg(InputValue("camerax")) * sens) % 360
	return QuatEuler(MG.look.pitch, MG.look.yaw, 0)
end

-- Sight view (user, 2026-11-12, after AVF's "sniper mode"): hold right mouse to look from just above the rear of
-- the barrel (MG_Sight, measured from the gun model), mouse wheel zooms (FOV / 1..MG_ZOOM_MAX, mouse slower by the
-- same factor), released: the view above and behind the gun. The zoom is kept until the gunner gets off.
--- Returns the camera transform and its FOV (nil = the default).
function MG_GunnerCamera()
	MG.zoom = MG.zoom or 1
	local sighted = InputDown("rmb")
	if sighted then
		local w = InputValue("mousewheel")
		if w > 0 then MG.zoom = math.min(MG_ZOOM_MAX, MG.zoom + 1) elseif w < 0 then MG.zoom = math.max(1, MG.zoom - 1) end
	end
	local look = MG_UpdateLook(sighted and 1 / MG.zoom or 1)
	if sighted then
		-- (in-game 2026-11-12: in the van the eye sat inside, behind the window frame, which covered half the view)
		-- anything but the gun between the muzzle and the eye: the eye moves forward, just in front of it
		local eye, muzzle = MG_Sight(), MG_Muzzle()
		local toEye = VecSub(eye, muzzle)
		local len = VecLength(toEye)
		if len > 0.01 then
			-- only the gun itself is ignored: the turret counts (2026-11-13, T-34: the eye sat inside the turret lid)
			QueryRejectBody(GetShapeBody(MG.gun))
			local hit, dist = QueryRaycast(muzzle, VecScale(toEye, 1 / len), len)
			if hit then eye = VecAdd(muzzle, VecScale(toEye, math.max(0, dist - 0.1) / len)) end
		end
		return Transform(eye, look), MG_SIGHT_FOV / MG.zoom
	end
	-- above the gun's tallest part too (2026-11-13, M-51 Sherman: the scope on top of the gun blocked the view)
	local pivot = VecAdd(MG_BarrelCentre(), Vec(0, math.max(MG_CAM_UP, (shared.mgTopUp or 0) + MG_CAM_ABOVE_TOP), 0))
	local back = TransformToParentVec(Transform(Vec(), look), Vec(0, 0, 1))
	local d = MG_CAM_BACK
	MG_QueryRejectOwn()
	local hit, dist = QueryRaycast(pivot, back, d)
	if hit then d = math.max(0, dist - 0.2) end
	return Transform(VecAdd(pivot, VecScale(back, d)), look)
end

MG_MIN_AIM_DIST = 8 -- m: aim points closer to the muzzle than this aim along the look direction instead
MG_AIM_PITCH_MAX = 60 -- deg: that look-direction aim keeps its pitch within this (straight down has no heading)
MG_VIEW_KEY = "v" -- driver (fallback): switch between the driving view and the gun view
MG_WEAPON_KEY = "x" -- next weapon (main gun / coax MG); the hand guns that read X are put away on a mounted gun

local function fireRound()
	local muzzle, fwd = MG_Muzzle()
	local perk = GunPerkFor(MG.calibre, nil)
	local s = MG.dispersion
	local shell = {
		armor = { perk.lvl1armor, perk.lvl2armor, perk.lvl3armor, perk.lvl4armor, perk.lvl5armor },
		damage = perk.damage, pdamage = perk.pdamage, explosive = perk.explosive, tracer = true,
		velocity = perk.velocity, maxmomentum = perk.maxMomentum, momentum = perk.maxMomentum, bloodamount = 30,
		pos = VecAdd(muzzle, VecScale(fwd, 0.1)), factor = 1,
		predictedBulletVelocity = VecAdd(VecScale(fwd, perk.velocity),
			Vec((math.random() - 0.5) * s, (math.random() - 0.5) * s, (math.random() - 0.5) * s)),
	}
	GunNet_Fire(shell, MG.sound, 1.0)
	PlaySound(MG.snd, muzzle, 1.0)
	ParticleReset()
	ParticleType("plain")
	ParticleColor(1, 0.7, 0.4)
	ParticleRadius(0.15)
	ParticleEmissive(5, 0)
	SpawnParticle(VecAdd(muzzle, VecScale(fwd, 0.2)), VecScale(fwd, 4), 0.05)
	ShakeCamera(0.15)
end

function client.tick(dt)
	GunNet_ClientTick(dt)
	if MG.cannon then AVF_ClientTick(dt) end -- every client draws the shells in flight
	if MG.gun == 0 then return end
	local role = localRole()
	local gunner = role ~= nil -- works the gun (gunner or driver fallback)
	if gunner and not MG.wasGunner then
		if MG.cannon then
			selectType(MG.type or 1) -- (starts the reload of an empty magazine)
		else
			MG.ammo, MG.mags = shared.mgAmmo or MG.capacity, shared.mgMags or MG.magazines
			MG.reloadTimer = 0
		end
	end
	if not role then MG.look, MG.zoom = nil, nil end -- next time: start from the player's look, zoom 1
	if role ~= "driver" then MG.view = nil elseif not MG.view then MG.view = "vehicle" end
	MG.wasGunner = gunner
	if not gunner or shared.mgRetired then return end

	-- driver (fallback) views (user, 2026-11-13): "vehicle" = the game's own driving camera (its wheel zoom as
	-- usual; turret held, no firing) and "gun" = the gun camera. V switches (MG_VIEW_KEY); RMB from the vehicle view
	-- aims (sight) only while held and goes back on release. The wheel never switches views (first version: wheel
	-- in / out, which clashed with the game's own first-person zoom). The gunner always has the gun camera.
	if role == "driver" then
		local toVehicle = false
		if MG.view == "vehicle" and InputPressed(MG_VIEW_KEY) then
			MG.view, MG.look, MG.zoom, MG.holdAim = "gun", MG_LookAlongBarrel(), nil, false
		elseif MG.view == "vehicle" and InputPressed("rmb") then
			MG.view, MG.look, MG.zoom, MG.holdAim = "gun", MG_LookAlongBarrel(), nil, true
		elseif MG.view == "gun" and (InputPressed(MG_VIEW_KEY) or (MG.holdAim and not InputDown("rmb"))) then
			toVehicle = true
		end
		if toVehicle then
			MG.view, MG.holdAim = "vehicle", false
			ServerCall("server.mgAim", GetLocalPlayer(), nil) -- turret holds
		end
	end
	local aiming = role == "gunner" or MG.view == "gun"
	-- the current weapon's muzzle: aiming from it puts that weapon's line on the target (in-game 2026-11-13: the
	-- coax MGs, offset from the main gun, hit beside the crosshair)
	local muzzle = MG_CurMuzzle()

	-- camera, then aim: the point under its centre, as a direction from the muzzle. Gunner and driver (gun view)
	-- get the gun camera (in-game 2026-11-13: aiming with the vehicle's own orbit camera could not aim up and the
	-- turret wobbled as the camera swung)
	if aiming then
		local ct, fov = MG_GunnerCamera()
		SetCameraTransform(ct, fov)
		local look = TransformToParentVec(ct, Vec(0, 0, -1))
		MG_QueryRejectOwn()
		local hit, dist = QueryRaycast(ct.pos, look, 500)
		local target = VecAdd(ct.pos, VecScale(look, hit and dist or 500))
		local dir = VecSub(target, muzzle)
		-- a point close to (or behind) the muzzle (looking down at the ground near the vehicle): aim along the
		-- look instead; its direction from the muzzle swung around with small camera moves and the turret wobbled
		-- (in-game 2026-11-13, tanks looking down)
		if VecLength(dir) < MG_MIN_AIM_DIST or VecDot(VecNormalize(dir), look) < 0.5 then
			-- along the look, but with the camera's own heading and the pitch kept within MG_AIM_PITCH_MAX: looking
			-- (nearly) straight down has no heading of its own, and the turret wobbled there (in-game 2026-11-13)
			local yaw = math.rad(MG.look and MG.look.yaw or 0)
			local pitch = math.rad(math.max(-MG_AIM_PITCH_MAX, math.min(MG_AIM_PITCH_MAX, MG.look and MG.look.pitch or 0)))
			dir = Vec(-math.sin(yaw) * math.cos(pitch), math.sin(pitch), -math.cos(yaw) * math.cos(pitch))
		end
		ServerCall("server.mgAim", GetLocalPlayer(), VecNormalize(dir))
	end

	-- F / X work during a reload too (in-game 2026-11-13: X waited for the main gun's reload); switching cancels it
	if aiming then
		-- cannons: F = next ammo type (AVF's key; the type's own magazine, reload starts over)
		if MG.cannon and InputPressed("f") then
			local w = MG.types[MG.type].weapon
			local t = MG.type
			repeat t = t % #MG.types + 1 until MG.types[t].weapon == w
			if t ~= MG.type then selectType(t) return end
		end
		-- X: next weapon (main gun / coax MG; AVF used R, which is reload here), on its remembered ammo type
		if MG.cannon and #MG.weapons > 1 and InputPressed(MG_WEAPON_KEY) then
			MG.lastType = MG.lastType or {}
			local w = MG.types[MG.type].weapon
			MG.lastType[w] = MG.type
			local nw = w % #MG.weapons + 1
			local t = MG.lastType[nw]
			if not t then for i, m in ipairs(MG.types) do if m.weapon == nw then t = i break end end end
			selectType(t)
			return
		end
	end

	-- reload
	MG.shotTimer = math.max(0, MG.shotTimer - dt)
	if MG.reloadTimer > 0 then
		MG.reloadTimer = MG.reloadTimer - dt
		if MG.reloadTimer <= 0 then
			MG.ammo, MG.mags = MG.capacity, MG.mags - 1
			if MG.cannon then MG.shotTimer = 0 end -- (AVF: timeToFire = 0 when the reload ends)
			PlaySound(MG.sndReloadIn, muzzle, 0.8)
			ServerCall("server.mgAmmo", GetLocalPlayer(), MG.ammo, MG.mags, MG.type)
		end
		return
	end
	if not aiming then return end -- driver in the vehicle view: drives only (reloads keep running above)
	if (InputPressed("r") or (MG.ammo == 0 and InputPressed("lmb"))) and MG.ammo < MG.capacity and MG.mags > 0 then
		MG.reloadTimer = MG_CurWeapon().reload
		PlaySound(MG.sndReloadOut, muzzle, 0.8)
		return
	end

	-- fire
	if InputDown("lmb") and MG.shotTimer <= 0 then
		if MG.ammo > 0 then
			if MG.cannon then
				local cfg = MG.types[MG.type].CfgAmmo
				local tracer = cfg.tracer and cfg.tracer > 0 and MG.ammo % cfg.tracer == 0 -- (AVF: every n-th round)
				ServerCall("server.mgCannonFire", GetLocalPlayer(), MG.type, tracer and true or false)
			else
				fireRound()
			end
			MG.ammo = MG.ammo - 1
			MG.shotTimer = 60 / MG_CurWeapon().rpm
			ServerCall("server.mgAmmo", GetLocalPlayer(), MG.ammo, MG.mags, MG.type)
			-- cannons reload by themselves when the magazine is empty, as AVF (reloadGun): a one-round magazine
			-- (BMP-1's 73 mm) within the rest of the firing cycle (60 / RPM), others in the gun's reload time;
			-- ready right after (in-game 2026-11-12: the BMP-1 needed many clicks: empty-click reload, then the cycle)
			if MG.cannon and MG.ammo == 0 and MG.mags > 0 then
				MG.reloadTimer = (MG.capacity == 1) and MG.shotTimer or MG_CurWeapon().reload
				PlaySound(MG.sndReloadOut, muzzle, 0.8)
			end
		elseif InputPressed("lmb") then
			PlaySound(MG.sndDry, muzzle, 0.8)
		end
	end
end

function client.draw(dt)
	if MG.gun == 0 or not localRole() then return end
	-- crosshair where the barrel points
	local muzzle, fwd = MG_CurMuzzle() -- the current weapon's line (coax MG: its own muzzle)
	MG_QueryRejectOwn()
	local hit, dist = QueryRaycast(muzzle, fwd, 500)
	local x, y, dist2 = UiWorldToPixel(VecAdd(muzzle, VecScale(fwd, hit and dist or 500)))
	if dist2 > 0 then
		UiPush()
			UiTranslate(x, y)
			UiAlign("center middle")
			UiColor(1, 1, 1, 0.9)
			UiRect(14, 2)
			UiRect(2, 14)
		UiPop()
	end
	-- ammo. In a vehicle (driver fallback, or the engine's seat on the gun place) the game draws its vehicle panel at
	-- the bottom centre: the weapon panel goes to the bottom right there (in-game 2026-11-13: they overlapped)
	UiPush()
		if GetPlayerVehicle() ~= 0 then
			-- in the driving view the game's own driving-controls panel is bottom right too (in-game 2026-11-13): sit
			-- above it (hud.lua sums its hint panels' heights into game.hud.hintH every frame)
			local hints = (localRole() == "driver" and MG.view ~= "gun") and GetInt("game.hud.hintH") or 0
			UiTranslate(UiWidth() - 40, UiHeight() - 70 - (hints > 0 and hints + 30 or 0))
			UiAlign("right")
		else
			UiTranslate(UiCenter(), UiHeight() - 70)
			UiAlign("center")
		end
		UiFont("bold.ttf", 26)
		UiTextOutline(0, 0, 0, 1, 0.1)
		UiColor(1, 1, 1)
		UiText(string.upper(MG_CurWeapon().name or MG.cfg.name or "MOUNTED GUN"))
		UiPush()
			UiTranslate(0, 24)
			UiFont("regular.ttf", 18)
			UiColor(1, 1, 1, 0.7)
			-- V only for a driver working the gun alone (no use with a gunner, or on the gun place)
			local v = localRole() == "driver" and ("   " .. string.upper(MG_VIEW_KEY) .. ": " .. (MG.view == "gun" and "driving view" or "gun view")) or ""
			if localRole() == "driver" and MG.view ~= "gun" then
				UiText("RMB: aim (hold)" .. v)
			else
				local f, x = "", ""
				if MG.cannon then
					local w, n = MG.types[MG.type].weapon, 0
					for _, m in ipairs(MG.types) do if m.weapon == w then n = n + 1 end end
					if n > 1 then f = "   F: ammo" end
					if #MG.weapons > 1 then x = "   " .. string.upper(MG_WEAPON_KEY) .. ": weapon" end
				end
				UiText("RMB: sight   Wheel: zoom   R: reload" .. f .. x .. v)
			end
		UiPop()
		UiTranslate(0, -28)
		if MG.reloadTimer > 0 then
			UiText("RELOADING")
		else
			UiText(MG.ammo .. " / " .. MG.capacity .. "   [" .. MG.mags .. "]")
		end
		if MG.cannon then
			UiTranslate(0, -28)
			UiFont("regular.ttf", 20)
			UiText(MG_AmmoLabel(MG.type))
		end
	UiPop()
end

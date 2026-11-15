-- AVF_Glue.lua (Mors Longa Revival, Phase 4 step 3, cannons) - hand-written v2 glue around the generated
-- AVF_Shells.lua (AVF by elboydo, Workshop 2400346027: credit, see tools/porting/history/avf_base/README.md).
-- Included by vehicles/MountedGun.lua. Design: docs/VEHICLES.md "AVF shells".
--
-- Server: AVF_ServerInit / AVF_ServerTick run AVF's shells; AVF_PushShell fires one (AVF's pushProjectile);
--   world effects and damage happen here; visuals go to every client as events (client.avfFx / client.avfShell).
-- Clients: AVF_ClientInit / AVF_ClientTick / AVF_ClientUpdate draw the events and the shells in flight.
-- Magazines: AVF_BuildMagazines(gunConfig) = AVF's loadShells, reading the vehicle config table directly
--   (v1: vehicles/avf/scripts/avf_custom.lua copied it onto "@magazine<i>_<field>" tags that loadShells read).

#include "AVF_Shells.lua"

AVF_SHELL_SLOTS = 256 -- shells / spall fragments in flight per gun (AVF: 1050 for all vehicles together)
maxDist = 500         -- AVF global
artilleryHandler = { shells = {} } -- artillery: phase 3

-- ------------------------------------------------------------------ magazines (both sides, same result)

local GUN_LEVEL = { name = true, magazineCapacity = true, magazineCount = true }

--- AVF asset paths ("MOD/gfx/...", "MOD/sounds/...": AVF's folder) -> our copies under MOD/avf/assets/.
function AVF_AssetPath(path)
	path = path:gsub("^MOD/gfx/", "MOD/vehicles/avf/assets/gfx/"):gsub("^MOD/sounds/", "MOD/vehicles/avf/assets/sounds/")
	return path
end

--- AVF's loadShells for one gun config table (vehicleParts.guns.<x>): a list of
--- { name, magazineCapacity, magazineCount, CfgAmmo }. As AVF (addGun + loadShells): every magazine's CfgAmmo
--- starts from the shell type of the first magazine of the gun's weapon type (the gun shape's XML tag weaponType,
--- e.g. customcannon -> "customShell"), then the config's values override it. Without a known weapon type: the
--- magazine's own name if it is one of AVF's shell types.
function AVF_BuildMagazines(gun, weaponTag)
	local list = {}
	local wt = weapons[weaponTag or ""]
	local baseName = wt and wt.magazines and wt.magazines[1] and wt.magazines[1].name
	for i, mag in ipairs(gun.magazines or {}) do
		local base = munitions[baseName or ""] or munitions[mag.name]
		if not base then
			DebugPrint("AVF: no base shell type for " .. tostring(mag.name) .. " (weapon type " .. tostring(weaponTag) .. ")")
			base = {}
		end
		local m = { name = mag.name, displayName = mag.displayName, magazineCapacity = mag.magazineCapacity or 1,
			magazineCount = mag.magazineCount or 1 }
		m.CfgAmmo = deepcopy(base)
		for key in pairs(AmmoOverrides) do
			if mag[key] ~= nil and not GUN_LEVEL[key] then m.CfgAmmo[key] = mag[key] end
		end
		m.CfgAmmo.name = m.CfgAmmo.name or mag.name
		m.CfgAmmo.caliber = m.CfgAmmo.caliber or gun.caliber or 20
		local modifier = math.log(m.CfgAmmo.caliber) / 10 * .75
		if m.CfgAmmo.payload == "kinetic" then modifier = modifier * .75 end
		m.CfgAmmo.bulletdamage = { [1] = modifier * 1.3, [2] = modifier * 1, [3] = modifier * 0.5 }
		m.CfgAmmo.penModifier = penetrationModifiers[m.CfgAmmo.payload] or 1
		if m.CfgAmmo.RHAe then
			local rhae = get_penetration_table_by_payload(m.CfgAmmo.payload)['hardmetal']
			m.CfgAmmo.maxPenDepth = rhae * (m.CfgAmmo.RHAe * globalConfig.RHAe_2_vox)
		end
		if m.CfgAmmo.hit and m.CfgAmmo.hit == 3 then m.CfgAmmo.bulletdamage[3] = m.CfgAmmo.bulletdamage[3] * .5 end
		m.CfgAmmo.maxPenDepth = m.CfgAmmo.maxPenDepth or 0
		-- AVF's asset paths point into AVF's own folder: our copies are under MOD/avf/assets/ (2026-11-13)
		for _, k in ipairs({ "shellSpriteName", "shellSpriteRearName", "flightLoop" }) do
			if type(m.CfgAmmo[k]) == "string" then m.CfgAmmo[k] = AVF_AssetPath(m.CfgAmmo[k]) end
		end
		m.CfgAmmo.timeToLive = m.CfgAmmo.timeToLive or 7
		list[i] = m
	end
	return list
end

-- ------------------------------------------------------------------ server

function AVF_ServerInit()
	for i = 1, AVF_SHELL_SLOTS do
		projectileHandler.shells[i] = deepcopy(projectileHandler.defaultShell)
		spallHandler.shells[i] = deepcopy(projectileHandler.defaultShell)
	end
end

AVF_SYNC_INTERVAL = 0.1 -- s between position updates of guided missiles to the clients (the server steers them)

function AVF_ServerTick(dt)
	projectileTick(dt)
	spallingTick(dt)
	for _, s in ipairs(projectileHandler.shells) do
		if s.active and s.shellType and s.shellType.launcher == "guided" and s.netId then
			s.syncT = (s.syncT or 0) + dt
			if s.syncT >= AVF_SYNC_INTERVAL then
				s.syncT = 0
				ClientCall(0, "client.avfShellSync", s.netId, s.point1, s.predictedBulletVelocity)
			end
		end
	end
end

--- AVF's pushProjectile. opt = { owner = player, body = vehicle body (not hit by its own shells), gun = gun shape,
--- reject = more bodies its shells skip (gun, turret), barrel = function returning the gun's barrel transform
--- (local -y = along the barrel, AVF's frame; guided missiles ride it), rpm, dispersion, tracer = bool,
--- ammo = magazine index (clients look the shell type up by it) }.
function AVF_PushShell(cfg, pos, dir, opt)
	local h = projectileHandler
	h.shells[h.shellNum] = deepcopy(h.defaultShell)
	local s = h.shells[h.shellNum]
	s.active = true
	s.shellType = cfg -- (AVF: the gun's own CfgAmmo, shared, not a copy)
	s.munition_armed = true
	local point1 = VecAdd(pos, VecScale(GetBodyVelocity(opt.body), GetTimeStep()))
	s.cannonLoc = Transform(point1, QuatLookAt(point1, VecAdd(point1, dir)))
	s.point1 = point1
	s.lastPos = point1
	s.predictedBulletVelocity = VecScale(VecNormalize(dir), cfg.velocity)
	s.originVehicle = opt.body
	s.originPos = Transform(pos)
	s.originGun = opt.gun
	s.mainShell = true -- (v2) the shell itself, not a spall / shrapnel fragment (AVF_ShellPaint)
	s.rejectBodies = opt.reject
	s.originGun_data = { barrel = opt.barrel }
	AVF_NET_ID = (AVF_NET_ID or 0) + 1
	s.netId = AVF_NET_ID
	s.timeToLive = cfg.timeToLive
	s.gun_RPM = opt.rpm
	s.dispersion = opt.dispersion or 1
	s.tracer = opt.tracer
	s.ownerPlayer = opt.owner
	s.distance_travelled = 0
	s.optimum_distance = cfg.optimum_distance or 100
	s.pen_dist_coef = 1
	s.penDepth = cfg.maxPenDepth
	if globalConfig.penCheck >= cfg.maxPenDepth then
		s.maxChecks = 1
	else
		s.maxChecks = cfg.maxPenDepth / globalConfig.penCheck
	end
	h.shellNum = (h.shellNum % #h.shells) + 1
	ClientCall(0, "client.avfShell", point1, s.predictedBulletVelocity, opt.ammo or 1, opt.tracer and true or false, opt.body, s.netId)
end

--- The torso hitbox of player p (PlayerHitboxes.lua: the host has the level's own set, others a tagged set).
local function torsoHitbox(p)
	for _, t in ipairs(FindTriggers("hitbox", true)) do
		if GetTagValue(t, "hitbox") == "TORSO" then
			if HasTag(t, "hitbox_player") then
				if tonumber(GetTagValue(t, "hitbox_player")) == p then return t end
			elseif IsPlayerHost(p) then
				return t
			end
		end
	end
	return 0
end

--- AVF's player damage (fraction of the engine health). The original mod reset the engine health to 1 every
--- tick, so only an amount >= 1 had an effect: it killed. Same here, through the torso hitbox (as the health
--- script's own instant kill: QueriedDamage 10000).
function AVF_HurtPlayer(p, amount)
	if amount < 1 or GetPlayerHealth(p) <= 0 then return end
	local t = torsoHitbox(p)
	if t ~= 0 then SetTag(t, "QueriedDamage", 10000) end
end

--- AVF's inflict_player_damage for every player (AVF: the local one): a player straight ahead of the shell within
--- this tick's travel, in line of sight, is hit. Returns true and the hit point for the first one.
function AVF_InflictPlayerDamage(projectile, point2)
	local t = Transform(projectile.point1, QuatLookAt(projectile.point1, point2))
	local p0 = VecCopy(t.pos)
	local d = VecNormalize(VecSub(point2, projectile.point1))
	local hurt_dist = VecLength(VecSub(projectile.point1, point2))
	for p in Players() do
		local player_pos = VecLerp(GetPlayerTransform(p).pos, GetPlayerCameraTransform(p).pos, 0.8)
		local toPlayer = VecSub(player_pos, t.pos)
		local distToPlayer = VecLength(toPlayer)
		local distScale = clamp(1.0 - distToPlayer / hurt_dist, 0.0, 1.0)
		if distScale > 0 then
			toPlayer = VecNormalize(toPlayer)
			if VecDot(d, toPlayer) > 0.95 then
				local hit = QueryRaycast(p0, toPlayer, distToPlayer)
				if not hit then
					distScale = VecDot(d, toPlayer)
					AVF_HurtPlayer(p, 0.035 * projectile.shellType.bulletdamage[1] * (distScale * 2) * projectile.shellType.caliber)
					return true, player_pos
				end
			end
		end
	end
	return false, nil
end

-- Holes along a penetration path (converter edit in getProjectilePenetration, 2026-11-13: lag with the BMP-2's
-- APDS): AVF made one at every step (dozens of nearly identical overlapping holes per round). A spot closer than
-- AVF_PATH_SPACING x the current radius to the last hole made is skipped, its paint too; a radius <= 0 makes no hole
-- (as AVF's MakeHole with it) and leaves the last hole as it is.
AVF_PATH_SPACING = 0.5

--- MakeHole for AVF's code: a hole with a radius <= 0 (or no position) carves nothing, so no engine call (2026-11-13,
--- rocks: an HE shell's shrapnel made ~47 such calls each).
--- Every paint of AVF's code (converter); one place to change it (2026-11-13 performance work).
function AVF_Paint(pos, r, kind)
	Paint(pos, r, kind)
end

--- Spall allowed: the penetration went through a material that throws spall (AVF_HARD).
function AVF_SpallAllowed()
	return AVF_PATH_HARD
end

function AVF_Hole(pos, r1, r2, r3)
	if not pos or not r1 or r1 <= 0 then return end
	MakeHole(pos, r1, r2, r3)
end

--- The two tiny scorch paints at the start of AVF's penetration check: the shell itself only, not its spall /
--- shrapnel fragments (~94 paints per HE shell on rock; AVF_PushShell marks the shell).
function AVF_ShellPaint(shell, pos)
	if shell and shell.mainShell then AVF_Paint(pos, 0.1, "explosion") end
end

-- Materials that throw spall (converter edit in pushSpalling): a penetration through none of these throws no spall
-- fragments. 2026-11-13 foliage lag: soft materials dropped; then freezes at a rock pile (in-game test switches:
-- "No Spall" removed the freezes, "No Shell Holes" too: the fragments cut holes in huge rock shapes): rock and
-- masonry dropped too. Metal only: armour and vehicles, where spall hurts the crew.
AVF_HARD = { metal = true, hardmetal = true, heavymetal = true }
AVF_PATH_HARD = false
local pathLast, pathSkipped = nil, false
function AVF_PathReset() pathLast, pathSkipped = nil, false end
function AVF_PathHole(pos, r1, r2, r3)
	pathSkipped = false
	-- AVF's loop steps by iteration_coef, which is fractional on a non-penetrating hit (7.5): damagePoints[8.5] etc.
	-- are nil, and AVF passed them on to MakeHole / Paint (engine behaviour with a nil position unknown): skipped
	if not pos then pathSkipped = true return end
	if r1 and r1 > 0 and pathLast and VecLength(VecSub(pos, pathLast)) < AVF_PATH_SPACING * r1 then
		pathSkipped = true
		return
	end
	MakeHole(pos, r1, r2, r3)
	if r1 and r1 > 0 then pathLast = VecCopy(pos) end
end
function AVF_PathPaint(pos, r, kind)
	if not pathSkipped then AVF_Paint(pos, r, kind) end
end

-- visuals inside the simulation -> events for every client (ClientCall 0)
function AVF_NoFx() end
function AVF_Log() end
function AVF_FxParticle(kind, pos, vel, radius, life)
	ClientCall(0, "client.avfFx", "particle", kind, pos, vel, radius, life)
end
function AVF_FxExplosionSound(pos, volume)
	ClientCall(0, "client.avfFx", "sound", pos, volume)
end
function AVF_FxImpact(projectile, pos, shape)
	ClientCall(0, "client.avfFx", "impact", projectile.shellType.bulletdamage[1], pos, shape)
end
function AVF_FxPenetrator(projectile, pos)
	ClientCall(0, "client.avfFx", "pen", projectile.shellType.bulletdamage[1], pos, projectile.predictedBulletVelocity)
end
--- AVF's body pushes (shell impact, explosion shockwave): cut so the body's speed changes by at most
--- AVF_MAX_PUSH_DV m/s. AVF scaled them down only for heavy bodies; the AGS-30's gun weighs ~1e-7 kg (density 1e-12
--- in the original XML), so a shockwave of strength ~10 meant ~1e8 m/s (in-game 2026-11-13: shooting the tripod
--- froze the game for a while; cause assumed).
AVF_MAX_PUSH_DV = 30
function AVF_Impulse(body, pos, imp)
	local mass = tonumber(GetBodyMass(body))
	local len = VecLength(imp)
	if not mass or mass <= 0 or len <= 0 then return end -- (static / no body: nothing to push)
	if len / mass > AVF_MAX_PUSH_DV then imp = VecScale(imp, AVF_MAX_PUSH_DV * mass / len) end
	ApplyBodyImpulse(body, pos, imp)
end
function AVF_FxExplosion(pos, strength)
	explosionController:shockwave(pos, strength) -- pushes bodies: world effect, server
	ClientCall(0, "client.avfFx", "explosion", pos, strength)
end

-- guided / cluster shells: phase 3 (launchers). Until then such a shell just flies ballistic / ends.
function homing_missile_computations() end
--- AVF: the gun's barrel transform (local -y along the barrel); guided (beam-riding) missiles steer toward the
--- point on this line at their own distance (2026-11-12: a stub here sent the BMP-3's 3UBK10-3 off course).
function retrieve_first_barrel_coord(gunData)
	if gunData and gunData.barrel then return gunData.barrel() end
	return Transform()
end
function initClusterBomblets() end

-- ------------------------------------------------------------------ clients

AVF_AMMO = {}   -- [magazine index] = CfgAmmo (set by MountedGun from AVF_BuildMagazines)
AVF_DRAWN = {}  -- shells in flight drawn here: { pos, vel, ttl, cfg, tracer, body }

function AVF_ClientInit()
	explosion_sounds = {}
	for i = 1, 7 do explosion_sounds[i] = LoadSound("MOD/vehicles/avf/assets/sounds/explosion/ExplosionDistant0" .. i .. ".ogg") end
	for _, cfg in pairs(AVF_AMMO) do
		cfg.sprite = LoadSprite(cfg.shellSpriteName or "MOD/vehicles/avf/assets/gfx/shellModel2.png")
		cfg.spriteRear = LoadSprite(cfg.shellSpriteRearName or "MOD/vehicles/avf/assets/gfx/shellRear2.png")
		if cfg.flightLoop then
			local path = cfg.flightLoop:find("%.ogg$") and cfg.flightLoop or (cfg.flightLoop .. ".ogg")
			if HasFile(path) then cfg.flightLoopSound = LoadLoop(path) end
		end
	end
end

--- AVF used the v1 particle call SpawnParticle(type, pos, vel, radius, life); 2.x takes (pos, vel, life) after
--- Particle* settings. Approximation: "fire" = emissive orange, "darksmoke" = dark smoke, else grey smoke.
function AVF_LegacyParticle(kind, pos, vel, radius, life)
	ParticleReset()
	if kind == "fire" then
		ParticleType("plain")
		ParticleColor(1, 0.6, 0.3, 0.6, 0.2, 0.1)
		ParticleEmissive(4, 0)
		ParticleAlpha(1, 0)
	elseif kind == "darksmoke" then
		ParticleType("smoke")
		ParticleColor(0.15, 0.15, 0.15)
	else
		ParticleType("smoke")
		ParticleColor(0.6, 0.6, 0.6)
	end
	ParticleRadius(radius or 0.5)
	SpawnParticle(pos, vel, life or 1)
end

function client.avfFx(kind, a, b, c, d, e)
	if kind == "particle" then
		AVF_LegacyParticle(a, b, c, d, e)
	elseif kind == "sound" then
		if explosion_sounds and #explosion_sounds > 0 then
			PlaySound(explosion_sounds[math.random(1, #explosion_sounds)], a, b)
		end
	elseif kind == "impact" then
		impactEffect({ shellType = { bulletdamage = { a } } }, b, c)
	elseif kind == "pen" then
		explosive_penetrator_effect({ shellType = { bulletdamage = { a } }, predictedBulletVelocity = c }, b)
	elseif kind == "explosion" then
		explosionController:pushExplosion(a, b)
	end
end

function client.avfShell(pos, vel, ammo, tracer, body, id)
	local cfg = AVF_AMMO[ammo]
	if not cfg then return end
	AVF_DRAWN[#AVF_DRAWN + 1] = { pos = pos, vel = vel, ttl = cfg.timeToLive or 7, cfg = cfg, tracer = tracer, body = body, id = id }
end

--- Guided missiles: the server's position / velocity (it steers them; drawn shells only know gravity).
function client.avfShellSync(id, pos, vel)
	for _, s in ipairs(AVF_DRAWN) do
		if s.id == id then s.pos, s.vel = pos, vel return end
	end
end

--- Moves and draws the shells (AVF's projectileOperations drawing, client side): gravity as the server's, no
--- random dispersion (drawn path may differ slightly); a drawn shell ends where it hits something.
function AVF_ClientTick(dt)
	explosionController:tick(dt)
	local keep = {}
	for _, s in ipairs(AVF_DRAWN) do
		local g = VecScale(globalConfig.gravity, s.cfg.gravityCoef or 1)
		s.vel = VecAdd(s.vel, VecScale(g, dt))
		local p2 = VecAdd(s.pos, VecScale(s.vel, dt))
		if s.body then QueryRejectBody(s.body) end
		local d = VecSub(p2, s.pos)
		local hit = QueryRaycast(s.pos, VecNormalize(d), VecLength(d))
		s.ttl = s.ttl - dt
		if not hit and s.ttl > 0 then
			local cfg = s.cfg
			local h, w = cfg.shellHeight or 0.7, cfg.shellWidth or 0.1
			local r, gg, b = cfg.r or 0.5, cfg.g or 0.5, cfg.b or 0.5
			if s.tracer then
				h, w = h * (cfg.tracerL or 1), w * (cfg.tracerW or 1)
				r, gg, b = cfg.tracerR or 1, cfg.tracerG or 1, cfg.tracerB or 1
			end
			local loc = Transform(p2, QuatRotateQuat(QuatLookAt(p2, s.pos), QuatEuler(0, 90, 90)))
			if cfg.sprite then
				DrawSprite(cfg.sprite, loc, w, h, r, gg, b, 1, false, false)
				local alt = TransformCopy(loc)
				alt.rot = QuatRotateQuat(alt.rot, QuatEuler(0, 90, 0))
				DrawSprite(cfg.sprite, alt, w, h, r, gg, b, 1, false, false)
			end
			-- rockets / missiles: exhaust and flight sound, drawn here (AVF's projectileOperations exhaust block,
			-- particles approximated: fire + smoke for rockets, dark smoke for guided missiles, a light)
			if cfg.launcher == "rocket" or cfg.launcher == "guided" then
				local back = VecScale(VecNormalize(s.vel), -2)
				local coef = math.log(cfg.caliber or 100) / 4
				if cfg.launcher == "rocket" then
					AVF_LegacyParticle("fire", p2, back, 1.1 * coef * 0.3, 0.15)
					AVF_LegacyParticle("smoke", p2, back, 1.2 * coef * 0.3, 0.3)
					PointLight(p2, 0.8, 0.8, 0.5, 3 * coef)
				else
					AVF_LegacyParticle("darksmoke", p2, back, 0.5 * coef * 0.3, 0.15)
				end
				if cfg.flightLoopSound then PlayLoop(cfg.flightLoopSound, p2, 20) end
			end
			s.pos = p2
			keep[#keep + 1] = s
		end
	end
	AVF_DRAWN = keep
end

function AVF_ClientUpdate(dt)
	explosionController:update(dt)
end

#include "../scripts/TDSU/compat.lua"
#include "table.lua"
#include "../scripts/Game/Blood/Blood.lua"
#include "../Settings.lua"
#include "../Automatic.lua"
#include "../scripts/TDSU/tdsu.lua"



Init_Settings()

-- Impact sounds are loaded on first use: v2 scripts may not call engine
-- functions such as LoadSound while the file is loading (before init).
local gunImpactSoundsLoaded = false
-- (v2, Phase 2) gun scripts are static now (always loaded): a gun only runs its tool logic / HUD while it is in one
-- of this player's inventory slots. v1 deleted the script when the gun left its slot; without this the HUD read the
-- wrong slot's data for the few frames until the server switched the tool away.
function GunInInventory(id)
	for i = 1, 4 do
		local item = GetString("inventory.guns." .. i .. ".item")
		if item == id or item:sub(1, #id + 1) == id .. "_" then return true end
	end
	return false
end

function GunFunctions_LoadSounds()
	if gunImpactSoundsLoaded then return end
	gunImpactSoundsLoaded = true
	dirtimpact = LoadSound("MOD/snd/Projectiles/Impacts/materials/blt_imp_dirt_0.ogg")
	foliageimpact = LoadSound("MOD/snd/Projectiles/Impacts/materials/blt_imp_foliage_0.ogg")
	glassimpact = LoadSound("MOD/snd/Projectiles/Impacts/materials/blt_imp_glass_auto_0.ogg")
	gravelimpact = LoadSound("MOD/snd/Projectiles/Impacts/materials/blt_imp_gravel_0.ogg")
	masonryimpact = LoadSound("MOD/snd/Projectiles/Impacts/materials/blt_imp_masonry_0.ogg")
	softmetalimpact = LoadSound("MOD/snd/Projectiles/Impacts/materials/blt_imp_metal_auto_0.ogg")
	hardmetalimpact = LoadSound("MOD/snd/Projectiles/Impacts/materials/blt_imp_metal_thick_0.ogg")
	woodimpact = LoadSound("MOD/snd/Projectiles/Impacts/materials/blt_imp_wood_0.ogg")
	ricochetsound = LoadSound("MOD/snd/Projectiles/Impacts/Ricochets/blt_ricco_0.ogg")
end
Done = nil
FlashLight = nil
------SHOOTING OPERATIONS AND FUNCTIONS------


function WeaponTick(dt)

	-- -- Debug hit pos
	-- local toolTr = GetBodyTransform(GetToolBody())
	-- local h, p = RaycastFromTransform(toolTr, 500)
	-- if h then DrawDot(p, 0.25, 0.25, 1,0,0, 1, false) end

	--Weapon Recenter--
	do
		TimeSinceShoot = TimeSinceShoot + dt
		if InputDown("usetool") or InputPressed("usetool") then TimeSinceShoot = 0 end

		local recenterRate = AutoMap(math.random(), 0, 1, 0.04, 0.09)

		if not ironsight and TimeSinceShoot > 0.5 and VecLength(GetPlayerVelocity()) < 0.5 then
			if swingx2 > 0 then
				swingx2 = swingx2 - swingx2 * recenterRate
			elseif swingx2 < 0 then
				swingx2 = swingx2 - swingx2 * recenterRate
			end
			if swingy2 > 0 then
				swingy2 = swingy2 - swingy2 * recenterRate
			elseif swingy2 < 0 then
				swingy2 = swingy2 - swingy2 * recenterRate
			end
		end
	end
	do 
		if reloading then
			SetBool("inventory.reloading", true)
		else
			SetBool("inventory.reloading", false)
		end
	end
end

function WeaponBackgroundTick(dt)
	for key, shell in ipairs(projectileHandler.shells) do
		if shell.active then
			ProjectileOperations(shell)
		end
	end
	for key, shell in ipairs(grenadeHandler.shells) do
		if shell.active then
			GrenadeOperations(shell)
		end
	end
	if shootTimer > 0 or ammo == 0 then
		shootTimer = shootTimer - dt
	end
end


function AnimationInit()
	ADSx = 0
	ADSy = 0
	ADSz = 0
	ADSrotx = 0
	ADSroty = 0
	ADSrotz = 0
	ADSx0 = 0
	ADSy0 = 0
	ADSz0 = 0
	ADSrotx0 = 0
	ADSroty0 = 0
	ADSrotz0 = 0
	ADSdelta = {0,0,0,0,0,0}
	ADSfov = 0
	RELx = 0
	RELy = 0
	RELz = 0
	RELrotx = 0
	RELroty = 0
	RELrotz = 0
	SELx = 0
	SELy = 0
	SELz = 0
	SELrotx = 0
	SELroty = 0
	SELrotz = 0
	INSx = 0
	INSy = 0
	INSz = 0
	INSrotx = 0
	INSroty = 0
	INSrotz = 0
	RECx = 0
	RECy = 0
	RECz = 0
	RECrotx = 0
	RECroty = 0
	RECrotz = 0
	RECx0 = 0
	RECy0 = 0
	RECz0 = 0
	RECrotx0 = 0
	RECroty0 = 0
	RECrotz0 = 0
	RECdelta = {0,0,0,0,0,0}
	crouchoffset = 0


end

function WeaponInit()
	TimeSinceShoot = 0


end
function ProjectileHandlerInit()
	projectileHandler = {
	shellNum = 1,
	shells = {},
	defaultShell = {active = false}
	}
	grenadeHandler = {
		shellNum = 1,
		shells = {},
		defaultShell = {active = false}
	}
	for i=1,200 do
		projectileHandler.shells[i] = deepcopy(projectileHandler.defaultShell)
	end
	gravity = Vec(0,-10,0)
end

function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else
        copy = orig
    end
    return copy
end

function GetAimPos()
	local ct = GetCameraTransform()
	local forwardPos = TransformToParentPoint(ct, Vec(0, 0, -100))
    local direction = VecSub(forwardPos, ct.pos)
    local distance = VecLength(direction)
	local direction = VecNormalize(direction)
	QueryRejectBody(GetToolBody())
	local hit, hitDistance = QueryRaycast(ct.pos, direction, distance)
	if hit then
		forwardPos = TransformToParentPoint(ct, Vec(0, 0, -hitDistance))
		distance = hitDistance
	end
	return forwardPos, hit, distance
end

-- Raycast for gun projectiles that ignores weapon models. In v2 a tool prefab is
-- a real body in the world, so a bullet starting inside the gun would otherwise
-- hit (and MakeHole) the gun itself. Tool prefab parts carry the tag
-- "ml_toolpart" (tools/porting/make_tool_prefab.py); v1 tools have no such tag.
-- Query filters reset after every query, so they are re-applied each attempt.
function GunRaycast(origin, dir, maxDist, toolBody, bulletShape)
	local skip = {}
	for _ = 1, 8 do
		if toolBody and toolBody ~= 0 then QueryRejectBody(toolBody) end
		if bulletShape then QueryRejectBody(bulletShape) end
		if #skip > 0 then QueryRejectShapes(skip) end
		local hit, dist, normal, shape = QueryRaycast(origin, dir, maxDist)
		if not (hit and HasTag(shape, "ml_toolpart")) then
			return hit, dist, normal, shape
		end
		skip[#skip + 1] = shape
	end
	return false, 0, Vec(0, 0, 0), 0
end

function ProjectileOperations(projectile)

	-- v2: this simulation runs on the server for world effects (doFx = false)
	-- and on clients for visuals/sound (doWorld = false); see gunnet.lua.
	-- v1 scripts leave both flags unset, so everything runs as before.
	local doWorld = projectile.doWorld ~= false
	local doFx = projectile.doFx ~= false
	if doFx then GunFunctions_LoadSounds() end
	local function noop() end
	local PlaySound = doFx and PlaySound or noop
	local SpawnParticle = doFx and SpawnParticle or noop
	local PointLight = doFx and PointLight or noop
	local DrawLine = doFx and DrawLine or noop
	local MakeHole = doWorld and MakeHole or noop
	local Explosion = doWorld and Explosion or noop
	local SpawnFire = doWorld and SpawnFire or noop
	local ApplyBodyImpulse = doWorld and ApplyBodyImpulse or noop
	local Blood_Pop = doWorld and Blood_Pop or noop
	local SetFloat = doWorld and SetFloat or noop
	local toolBody = projectile.owner and GetToolBody(projectile.owner) or GetToolBody()

	local lvl1armor = projectile.armor[1] or 1
	local lvl2armor = projectile.armor[2] or 1
	local lvl3armor = projectile.armor[3] or 1
	local lvl4armor = projectile.armor[4] or 1
	local lvl5armor = projectile.armor[5] or 1
	local damage = projectile.damage or 1
	local pdamage = projectile.pdamage or 1
	local explosive = projectile.explosive or false
	local incendiary = projectile.incendiary or false
	local tracer = projectile.tracer or false
	local velocity = projectile.velocity or 1222222
	local bloodamount = projectile.bloodamount or 30
	local maxMomentum = projectile.maxmomentum or 30
	local BulletShape = projectile.BulletShape or nil
	

	local drag = Drag or 0.1 * 1.7
	projectile.predictedBulletVelocity = VecScale(projectile.predictedBulletVelocity, (1-drag*GetTimeStep()*VecLength(projectile.predictedBulletVelocity)/velocity))
	projectile.predictedBulletVelocity = VecAdd(projectile.predictedBulletVelocity, (VecScale(gravity, GetTimeStep())))
	local point2 = VecAdd(projectile.pos, VecScale(projectile.predictedBulletVelocity, GetTimeStep()))
	local dir = VecNormalize(VecSub(point2, projectile.pos))
	local factor = projectile.factor or barrelFactordamage or 1
	local didHitNpc = false
	local hit, dist, normal, shape = GunRaycast(projectile.pos, dir, VecLength(VecSub(point2, projectile.pos)), toolBody, BulletShape)
	if hit then
		hitPos = VecAdd(projectile.pos, VecScale(VecNormalize(VecSub(point2, projectile.pos)), dist))
		point2 = hitPos
		if tracer then DrawLine(projectile.pos, point2, 0.9, 0.8, 0.6, 0.8) end
		local mat, r, g, b, a = GetShapeMaterialAtPosition(shape, hitPos)


		-- NPC DAMAGE START
		local damage_from_player_gun = pdamage
		local hitBody = GetShapeBody(shape) -- raycast hit shape
		if (HasTag(hitBody, "bodypart") or HasTag(hitBody, "Head")) and mat ~= "metal" and mat ~= "heavymetal" and mat ~= "hardmetal" and projectile.momentum > 0 then
			Blood_Pop(hitPos, 20, 10, hitBody)
			--PaintRGBA(hitPos, 0.3, 0.2,0.025, 0.025, 1, 0.8)
			--Blood_Sides(hitBody)
		end
		if mat == "glass" then
			--GlassHandler(shape, hitPos)
		end

		if (HasTag(hitBody, "gore_id") or HasTag(shape, "jaw") or HasTag(HitBody, "bodypart")) and not projectile.hit_npc then
	
			local path_damage = "level.goreai.body_damage_player." .. hitBody
			local damage = GetFloat(path_damage) + damage_from_player_gun
			SetFloat(path_damage, damage) -- Specific damage to each body by handle.

			SetFloat("level.goreai.body_damage_player_x", hitPos[1])
			SetFloat("level.goreai.body_damage_player_y", hitPos[2])
			SetFloat("level.goreai.body_damage_player_z", hitPos[3])

			SetFloat("level.goreai.body_damage_player_vel_x", projectile.predictedBulletVelocity[1])
			SetFloat("level.goreai.body_damage_player_vel_y", projectile.predictedBulletVelocity[2])
			SetFloat("level.goreai.body_damage_player_vel_z", projectile.predictedBulletVelocity[3])
			if doWorld then SetInt("level.goreai.body_damage_player_owner", projectile.owner or 0) end -- (v2 goreai) shooter, for hitmarkers/kills

			projectile.hit_npc = true

			didHitNpc = true

		end
		-- NPC DAMAGE START


		if HasTag(hitBody, "Head") then
			PlaySound(LoadSound("MOD/snd/Projectiles/Impacts/bullet_flesh_plr_head_0.ogg"), hitPos, 0.8)
		elseif HasTag(hitBody, "bodypart") then
			PlaySound(LoadSound("MOD/snd/Projectiles/Impacts/blt_imp_flesh_kill_head_accent_0.ogg"), hitPos, 0.8)
		end


		if mat == "metal" or mat == "heavymetal" or mat == "hardmetal" then
			bounceangle = 5*projectile.momentum
		else
			bounceangle = 3*projectile.momentum
		end

		if VecLength(VecSub(projectile.pos, hitPos)) < 0.04 then
			projectile.active = false
			projectile.momentum = 0
		end
		
		if HasTag(shape, "bone") then 
			projectile.momentum = projectile.momentum/2
		end
		--[[print(lvl1armor)
		print(lvl2armor)
		print(lvl3armor)
		print(lvl4armor)
		print(lvl5armor)--]]

		-- print("")
		-- print(mat)
		-- print("")
	
		local RHA = 0
		if HasTag(shape, "RHA") then
			RHA = GetTagValue(shape, "RHA") or 0
		end
		projectile.momentum = projectile.momentum - RHA/4

		local hitangle = math.acos(VecDot(projectile.predictedBulletVelocity, normal)/VecLength(projectile.predictedBulletVelocity))*57.3-90
		if hitangle < bounceangle and math.random(0, 100)/100 > (hitangle/bounceangle)^2 then
			PlaySound(ricochetsound, projectile.pos, 0.4)
			local dot = VecDot(normal, projectile.predictedBulletVelocity)
			projectile.predictedBulletVelocity = VecSub(projectile.predictedBulletVelocity, VecScale(normal, dot*(1+math.random(1,10)/10)))
		else
			if not didHitNpc then	
				ApplyBodyImpulse(GetShapeBody(shape), hitPos, VecScale(projectile.predictedBulletVelocity, projectile.momentum/10))
			else 
				ApplyBodyImpulse(GetShapeBody(shape), hitPos, VecScale(projectile.predictedBulletVelocity, projectile.momentum/50))
			end


			if (HasTag(GetShapeBody(shape), "gore_id") or HasTag(GetShapeBody(shape), "bodypart"))  and Settings.game.blood_and_gore.value then -- NPC hit
				ParticleReset()
				ParticleType("plain")
				ParticleTile(6)
				ParticleSticky(0, 0)
				ParticleRadius(RandomSpreadPercent25(0.03), 0.01)
				ParticleAlpha(1, 0)
				ParticleEmissive(0.2)
				ParticleColor(0.7, 0.1, 0.1, 0.7, 0, 0)
				ParticleGravity(-10, -10)
				ParticleCollide()
				for i = 1, math.random(10, math.max(10,10*maxMomentum)) do
					SpawnParticle(
						hitPos,
						Vec((math.random(-100,100)/100)*5,(math.random(-100,100)/100)*5,
						(math.random(-100,100)/100)*5), math.random(10,25)/20)
				end
			end
		
			if mat == "glass" then
				if math.random() > 0.65 then MakeHole(hitPos, 0.75) end
				projectile.momentum = projectile.momentum - 0.2
				PlaySound(glassimpact, hitPos, 0.5)
				--GlassHandler(shape,hitpos)
				
			elseif mat == "metal" or mat == "heavymetal" or mat == "hardmetal" then
				--DebugPrint("pp")
				--RayCompute(hitPos,dir,dist,normal,shape,3,factor*2,"sphere",true)
				SpawnParticle("smoke", hitPos, Vec(0, 1.0+math.random(1,10)*0.1, 0), damage, 1)
				ParticleReset()
				ParticleType("plain")
				ParticleTile(6)
				ParticleSticky(0, 0)
				ParticleRadius(0.01, 0.01)
				ParticleAlpha(1, 0)
				ParticleEmissive(10, 10)
				ParticleColor(1, 0.75, 0.25, 1, 0.25, 0.25)
				ParticleGravity(-10, -10)
				for i = 1, math.random(10, math.max(10,10*maxMomentum)) do
					SpawnParticle(
						hitPos,
						Vec((math.random(-100,100)/100)*5,(math.random(-100,100)/100)*5,
						(math.random(-100,100)/100)*5), math.random(10,25)/20)
				end
				PointLight(hitPos, 1, 0.75, 0.25, 0.25)
				if mat == "hardmetal" then
					projectile.momentum = projectile.momentum - 2
				else
					projectile.momentum = projectile.momentum - 1
				end
				if mat == "hardmetal" and math.random() > lvl5armor^(maxMomentum/projectile.momentum) then --lvl5armor^(1/projectile.momentum)
					projectile.momentum = 0
					PlaySound(hardmetalimpact, hitPos, 0.5)
					-- print("hitlvl5")
				elseif mat == "metal" and math.random() > lvl3armor^(maxMomentum/projectile.momentum) then
					projectile.momentum = 0
					PlaySound(hardmetalimpact, hitPos, 0.5)
					-- print("hitlvl3")
				else
					PlaySound(softmetalimpact, hitPos, 0.5)
				end
			else
				ParticleReset()
				ParticleType("plain")
				ParticleTile(6)
				ParticleSticky(0.1)
				ParticleRadius(0.05, 0)
				ParticleAlpha(a)
				ParticleEmissive(0, 0)
				ParticleColor(r, g, b, r, g, b)
				ParticleGravity(-10, -10)
				for i = 1, math.random(10, math.max(10,10*maxMomentum)) do
					ParticleRadius(math.random()/50+0.025, 0)
					SpawnParticle(hitPos, Vec((math.random(-100,100)/100)*5,(math.random(-100,100)/100)*5, (math.random(-100,100)/100)*5), math.random(10,25)/10)
				end
				for i = 1, math.random(1,5) do
					ParticleTile(3)
					ParticleRadius(0.35, 0.5)
					ParticleAlpha(a, 0)
					ParticleGravity(-3, -3)
					ParticleDrag(0.5)
					SpawnParticle(hitPos, Vec((math.random(-100,100)/100),(math.random(-100,100)/100)*2, (math.random(-100,100)/100)), math.random(10,25)/10)
				end
				if mat == "hardmasonry" then
					if math.random() > lvl4armor^(maxMomentum/projectile.momentum) then projectile.momentum = 0 end
					PlaySound(masonryimpact, hitPos, 0.5)
					projectile.momentum = projectile.momentum - 0.8
					-- print("hitlvl4")
				elseif mat == "concrete" then
					if math.random() > lvl2armor^(maxMomentum/projectile.momentum) then projectile.momentum = 0 end
					PlaySound(softmetalimpact, hitPos, 0.5)
					projectile.momentum = projectile.momentum - 0.5
					-- print("hitlvl2")
				elseif mat == "masonry" then
					if math.random() > lvl1armor^(maxMomentum/projectile.momentum) then  projectile.momentum = 0 end
					PlaySound(masonryimpact, hitPos, 0.5)
					projectile.momentum = projectile.momentum - 0.6
					-- print("hitlvl1")
				elseif mat == "grass" then
					PlaySound(foliageimpact, hitPos, 0.5)
					projectile.momentum = projectile.momentum - 0.6
				elseif mat == "wood" then
					PlaySound(woodimpact, hitPos, 0.5)
					projectile.momentum = projectile.momentum - 0.4
				elseif mat == "dirt" then
					PlaySound(dirtimpact, hitPos, 0.5)
					projectile.momentum = projectile.momentum - 0.4
				else
					PlaySound(gravelimpact, hitPos, 0.5)
					projectile.momentum = projectile.momentum - 0.5
				end
			end

			
			if projectile.momentum > 0 and projectile.active then
			--	local projDontBreakNpc = didHitNpc and math.random() < 10000
				--if projDontBreakNpc then factor = 0 end -- dont always break npc voxels
				if didHitNpc then
					
					MakeHole(hitPos, damage*factor,0,0)
				else
					--DebugPrint("ji321o3j")
					MakeHole(hitPos, damage*factor, damage*0.85*factor, damage*0.7*factor)
				end
				--Paint(hitPos, factor/5, "explosion")
				if explosive then
					Explosion(hitPos,0.5)
					projectile.active = false
				end		
				if incendiary then
					SpawnFire(hitPos)
				end
				
			end

			if HasTag(shape, "unbreakable") or HasTag(GetShapeBody(shape), "unbreakable") or mat == "heavymetal" or mat == "rock" then
               --Paint(hitPos, factor/5, "explosion")
				projectile.momentum = 0
                projectile.active = false
            end
		end
	else
		point2 = VecAdd(projectile.pos, VecScale(projectile.predictedBulletVelocity, GetTimeStep()))
		if tracer then DrawLine(projectile.pos, point2, 0.9, 0.8, 0.7, 0.8) end
		if BulletShape then SetBodyTransform(BulletShape, Transform(point2, GetBodyTransform(BulletShape).rot)) end
	end

	if projectile.momentum < 0.1 or projectile.pos[2] < -50 then
		projectile.active = false
	end

	
	if not projectile.active and BulletShape then
		local allshapes = GetBodyShapes(BulletShape)
		for i=1,#allshapes do 
			Delete(allshapes[i])
		end	
		Delete(BulletShape)
	end
	projectile.pos = VecLerp(projectile.pos, point2, 0.5)
	
end

function ShootNewDontCallYet(Cartridge, BulletType)
	local perktable = gunperks[Cartridge][BulletType]
	local damage = perktable["damage"]
	local pdamage = perktable["pdamage"]
	local explosive = perktable["explosive"]
	local tracer = perktable["tracer"]
	local velocity = perktable["velocity"]
	local maxMomentum = perktable["maxMomentum"]

	local lvl5armor = perktable["lvl5armor"]
	local lvl4armor = perktable["lvl4armor"]
	local lvl3armor = perktable["lvl3armor"]
	local lvl2armor = perktable["lvl2armor"]
	local lvl1armor = perktable["lvl1armor"]
	
	local pelletSpread = perktable["pelletSpread"] or nil
	local pelletAmount = perktable["pelletAmount"] or 1
	if shootTimer > 0 or ammo == 0 then
		return
	end

	PlaySound(casingsound,GetPlayerTransform().pos,0.6) 
	ShakeCamera(0.5)

	aimpos, hit, distance = GetAimPos()

	local gt = GetBodyTransform(GetToolBody())
	local fwdpos = TransformToParentPoint(gt, Vec(0.275, -0.6, -100))
	local gunpos = TransformToParentPoint(gt, Vec(0.275, -0.6, -1.2))
	dir = VecNormalize(VecSub(fwdpos, gunpos))

	local ironsightFactor = 1
	if not ironsight then
		ironsightFactor = 2.5
	end
	local Shape = Spawn("MOD/script/bullet.xml", gt)
	DebugPrint(Shape)
	local maxSpread = InputDown("crouch") and 2 or 3
	if ironsight then maxSpread = maxSpread / 3 end
	local factor = stockFactor*laserFactor*muzzleFactor*gripfactorx*barrelFactorx*ironsightFactor
	rnd1, rnd2, rnd3, rnd4, rnd5, rnd6 = rnd1+(math.random()-0.5)*factor*recoilWander, rnd2+(math.random()-0.5)*factor*recoilWander, rnd3+(math.random()-0.5)*factor*recoilWander/4, (math.random()-0.5)*factor*recoilHorizontal, (math.random()-0.5)*factor*recoilHorizontal, (math.random()-0.5)*factor*recoilHorizontal/4

	if not ironsight then
		accuracyFactor = 4
	end
	if recoilAngle < recoilMax then
		recoilAngle = recoilAngle + recoilFactor*muzzleFactor*gripfactory*barrelFactory
	end
	
	projectileHandler.shells[projectileHandler.shellNum] = deepcopy(projectileHandler.defaultShell)
	loadedShell = projectileHandler.shells[projectileHandler.shellNum] 
	loadedShell.armor = {lvl1armor,lvl2armor,lvl3armor,lvl4armor,lvl5armor}
	loadedShell.damage = damage
	loadedShell.pdamage = pdamage
	loadedShell.explosive = explosive
	loadedShell.tracer = tracer
	loadedShell.velocity = velocity
	loadedShell.maxmomentum = maxMomentum
	loadedShell.bloodamount = bloodamount
	loadedShell.active = true
	loadedShell.pos = gunpos
	loadedShell.momentum = maxMomentum
	loadedShell.predictedBulletVelocity = VecScale(dir, velocity*barrelFactory)
	loadedShell.BulletShape = Shape[1]
	
	projectileHandler.shellNum = (projectileHandler.shellNum%#projectileHandler.shells) + 1

	loadedShell.predictedBulletVelocity = VecAdd(loadedShell.predictedBulletVelocity, Vec((math.random()-0.5)*accuracyFactor*2, (math.random()-0.5)*accuracyFactor*2, (math.random()-0.5)*accuracyFactor*2))

	local barrelend = barrellength + muzzlelength
	SpawnParticle("smoke", TransformToParentPoint(GetBodyTransform(GetToolBody()), Vec(0.25, -0.55, -2.4-barrelend*4/3)), VecAdd(VecScale(dir, 2), GetPlayerVelocity()), 0.2, 0.3)
	ParticleType("plain")
	ParticleTile(5)
	ParticleColor(1, 0.6, 0.4, 1, 0.3, 0.2)
	ParticleRadius(0.2)
	ParticleEmissive(5, 1)
	SpawnParticle(TransformToParentPoint(GetBodyTransform(GetToolBody()), Vec(0.25, -0.55, -2.4-barrelend*4/3)), VecAdd(VecScale(dir, 4), GetPlayerVelocity()), shotDelay/2, 0.3)
	ParticleReset()
	ParticleType("plain")
	ParticleTile(6)
	ParticleSticky(0, 0)
	ParticleRadius(0.0075, 0.0075)
	ParticleAlpha(1, 0)
	ParticleEmissive(10, 10)
	ParticleColor(1, 0.75, 0.25, 1, 0.25, 0.25)
	ParticleGravity(-10)
	ParticleCollide(0)
	for i = 1, math.random(8, 16) do
		SpawnParticle(TransformToParentPoint(GetBodyTransform(GetToolBody()), Vec(0.25, -0.6, -2.4-barrelend*4/3)), VecAdd(VecAdd(VecScale(dir, 25), GetPlayerVelocity()), Vec((math.random(-100,100)/100)*4,(math.random(-100,100)/100)*4, (math.random(-100,100)/100)*4)), shotDelay)
	end
	if muzzle == "muzzle1" then
		PlaySound(suppressedgunsound, GetPlayerTransform().pos, 0.75, false)
	elseif muzzle == "muzzle2" then
		PlaySound(gunsound, GetPlayerTransform().pos, 0.75, false)
	else
		PlaySound(gunsound, GetPlayerTransform().pos, 0.65, false)
	end

	if not unlimitedammo then
		bullettable[ammo] = nil
		ammo = ammo - 1
		if realistic then
			magtable2[curmagslot][2] = ammo
			magtable2[curmagslot][5] = table.concat(bullettable,"-")
			if inventoryenabled then
				name = "Unloaded"
				maxammo = 0
				id = mag
				if id == "mag0-ak-545" then name, maxammo = "6L23", 30
				elseif id == "mag1-ak-545" then name, maxammo = "6L26", 45
				elseif id == "mag2-ak-545" then name, maxammo = "Simonov-77", 77
				elseif id == "mag3-ak-545" then name, maxammo = "Simonov-95", 95
				elseif id == "mag4-ak-545" then name, maxammo = "6L31", 60
				end
				local guninfo = Split(GetString("inventory.guns."..GetInt("inventory.curprimary")..".item"), "_")
				guninfo[3] = mag
				guninfo[4] = name
				guninfo[5] = ammo
				guninfo[6] = maxammo
				guninfo[10] = table.concat(bullettable,"-")
				SetString("inventory.guns."..GetInt("inventory.curprimary")..".item", IDBuilder(guninfo))
				SetBool("inventory.update", true)
			end
		end
	end

	if selectfire == 1 then
		shootTimer = shotDelay
		recoilTimer = shotDelay
		recoilTimer2 = shotDelay*2
		lightTimer = shotDelay/2
		spreadTimer = spreadTimer + 1.25
	else
		shootTimer = 0
		recoilTimer = shotDelay
		recoilTimer2 = shotDelay*2
		lightTimer = shotDelay/2
		spreadTimer = spreadTimer + 1.25
	end

	if spentcasingsoption then
		SpentCasing()
	end

	local jamrate = 1/300
	if dustcover == "removed" then jamrate = 1/200 end
	if realistic and math.random() < jamrate and ammo > 0 and not inventoryenabled then
		jammed = true
		PlaySound(dryfiresound, GetPlayerTransform().pos, 1, false)
	end
	
	local playerVelLen = GetPlayerVelocity()
	local prot = QuatToEuler(GetPlayerTransform(true).rot)
	local ppos = GetPlayerTransform().pos
	local camrot = QuatToEuler(GetPlayerCameraTransform().rot)
	local ppos2 = Transform()
	ppos2.rot = QuatEuler(prot[1], camrot[2], camrot[3])
	ppos2.rot = QuatRotateQuat(ppos2.rot, QuatEuler(recoilFactor*muzzleFactor*gripfactory*barrelFactory*3-rnd4/4, -rnd5/4, -rnd6/4))
	ppos2.pos = ppos
	--SetPlayerTransform(ppos2, true)
	--SetPlayerVelocity(pvel)
end


function GrenadeOperations(projectile)
	local doWorld = projectile.doWorld ~= false
	local doFx = projectile.doFx ~= false
	local toolBody = projectile.owner and GetToolBody(projectile.owner) or GetToolBody()
	projectile.predictedBulletVelocity = VecAdd(projectile.predictedBulletVelocity, (VecScale(gravity, GetTimeStep())))
	local point2 = VecAdd(projectile.pos, VecScale(projectile.predictedBulletVelocity, GetTimeStep()))
	local dir = VecNormalize(VecSub(point2, projectile.pos))
	local hit, dist, normal, shape = GunRaycast(projectile.pos, dir, VecLength(VecSub(point2, projectile.pos)), toolBody)
	if hit then
		hitPos = VecAdd(projectile.pos, VecScale(VecNormalize(VecSub(point2, projectile.pos)), dist))
		if doWorld then Explosion(hitPos, 1) end
	else
		point2 = VecAdd(projectile.pos, VecScale(projectile.predictedBulletVelocity, GetTimeStep()))
		if doFx then DrawLine(projectile.pos, point2) end
	end
	
	if hit then
		projectile.active = false
	end

	projectile.pos = point2
end

------ANIMATIONS------

function ADS(bool, fov, fovTime, x, y, z, rotx, roty, rotz)
	local adsFactor = 1+fovTime

	local dt = GetTimeStep()*1.5
	if grip == grip2 then
		dt = dt*1.25
	end
	local deltacoeff = 0.81

	if x > ADSx then 
		ADSx = ADSx + dt*math.abs((x-ADSx))/adsFactor + ADSdelta[1]*deltacoeff
	elseif x < ADSx then
		ADSx = ADSx - dt*math.abs((x-ADSx))/adsFactor + ADSdelta[1]*deltacoeff
	end
	if y > ADSy then 
		ADSy = ADSy + dt*math.abs((y-ADSy))/adsFactor + ADSdelta[2]*deltacoeff
	elseif y < ADSy then
		ADSy = ADSy - dt*math.abs((y-ADSy))/adsFactor + ADSdelta[2]*deltacoeff
	end
	if z > ADSz then 
		ADSz = ADSz + dt*math.abs((z-ADSz))/adsFactor + ADSdelta[3]*deltacoeff
	elseif z < ADSz then
		ADSz = ADSz - dt*math.abs((z-ADSz))/adsFactor + ADSdelta[3]*deltacoeff
	end
	if rotx > ADSrotx then 
		ADSrotx = ADSrotx + dt*math.abs((rotx-ADSrotx))/adsFactor + ADSdelta[4]*deltacoeff
	elseif rotx < ADSrotx then
		ADSrotx = ADSrotx - dt*math.abs((rotx-ADSrotx))/adsFactor + ADSdelta[4]*deltacoeff
	end
	if roty > ADSroty then 
		ADSroty = ADSroty + dt*math.abs((roty-ADSroty))/adsFactor + ADSdelta[5]*deltacoeff
	elseif roty < ADSroty then
		ADSroty = ADSroty - dt*math.abs((roty-ADSroty))/adsFactor + ADSdelta[5]*deltacoeff
	end
	if rotz > ADSrotz then 
		ADSrotz = ADSrotz + dt*math.abs((rotz-ADSrotz))/adsFactor + ADSdelta[6]*deltacoeff
	elseif rotz < ADSrotz then
		ADSrotz = ADSrotz - dt*math.abs((rotz-ADSrotz))/adsFactor + ADSdelta[6]*deltacoeff
	end
	if fov > ADSfov then 
		ADSfov = ADSfov + dt*math.abs((fov-ADSfov))*2.5
	elseif fov < ADSfov then
		ADSfov = ADSfov - dt*math.abs((fov-ADSfov))*2.5
	end

	local ADSvec = Vec(ADSx, ADSy, ADSz)
	ADSdelta[1] = ADSx - ADSx0
	ADSx0 = ADSx
	ADSdelta[2] = ADSy - ADSy0
	ADSy0 = ADSy
	ADSdelta[3] = ADSz - ADSz0
	ADSz0 = ADSz
	ADSdelta[4] = ADSrotx - ADSrotx0
	ADSrotx0 = ADSrotx
	ADSdelta[5] = ADSroty - ADSroty0
	ADSroty0 = ADSroty
	ADSdelta[6] = ADSrotz - ADSrotz0
	ADSrotz0 = ADSrotz

	local offset = Transform(ADSvec, QuatEuler(ADSrotx, ADSroty, ADSrotz))
	SetCameraFov(GetInt("options.gfx.fov")-ADSfov+recoilTimer*5)

	return offset
end

function SEL(bool, x, y, z, rotx, roty, rotz)
	local dt = GetTimeStep()*12

	if x > SELx then 
		SELx = SELx + dt*math.abs((x-SELx))
	elseif x < SELx then
		SELx = SELx - dt*math.abs((x-SELx))
	end
	if y > SELy then 
		SELy = SELy + dt*math.abs((y-SELy))
	elseif y < SELy then
		SELy = SELy - dt*math.abs((y-SELy))
	end
	if z > SELz then 
		SELz = SELz + dt*math.abs((z-SELz))
	elseif z < SELz then
		SELz = SELz - dt*math.abs((z-SELz))
	end
	if rotx > SELrotx then 
		SELrotx = SELrotx + dt*math.abs((rotx-SELrotx))
	elseif rotx < SELrotx then
		SELrotx = SELrotx - dt*math.abs((rotx-SELrotx))
	end
	if roty > SELroty then
		SELroty = SELroty + dt*math.abs((roty-SELroty))
	elseif rotx < SELroty then
		SELroty = SELroty - dt*math.abs((roty-SELroty))
	end
	if rotz > SELrotz then
		SELrotz = SELrotz + dt*math.abs((rotz-SELrotz))
	elseif rotz < SELrotz then
		SELrotz = SELrotz - dt*math.abs((rotz-SELrotz))
	end

	local SELvec = Vec(SELx, SELy, SELz)

	local offset = Transform(Vec(0, 0, 0), QuatEuler(SELrotx, SELroty, SELrotz))
	offset.pos = VecAdd(offset.pos, SELvec)

	return offset
end

function INS(bool, x, y, z, rotx, roty, rotz)
	local dt = GetTimeStep()*12

	if x > INSx then 
		INSx = INSx + dt*math.abs((x-INSx))
	elseif x < INSx then
		INSx = INSx - dt*math.abs((x-INSx))
	end
	if y > INSy then 
		INSy = INSy + dt*math.abs((y-INSy))
	elseif y < INSy then
		INSy = INSy - dt*math.abs((y-INSy))
	end
	if z > INSz then 
		INSz = INSz + dt*math.abs((z-INSz))
	elseif z < INSz then
		INSz = INSz - dt*math.abs((z-INSz))
	end
	if rotx > INSrotx then 
		INSrotx = INSrotx + dt*math.abs((rotx-INSrotx))
	elseif rotx < INSrotx then
		INSrotx = INSrotx - dt*math.abs((rotx-INSrotx))
	end
	if roty > INSroty then 
		INSroty = INSroty + dt*math.abs((roty-INSroty))
	elseif rotx < INSroty then
		INSroty = INSroty - dt*math.abs((roty-INSroty))
	end
	if rotz > INSrotz then 
		INSrotz = INSrotz + dt*math.abs((rotz-INSrotz))
	elseif rotz < INSrotx then
		INSrotz = INSrotz - dt*math.abs((rotz-INSrotz))
	end

	local INSvec = Vec(INSx, INSy, INSz)

	local offset = Transform(Vec(0, 0, 0), QuatEuler(INSrotx, INSroty, INSrotz))
	offset.pos = VecAdd(offset.pos, INSvec)

	return offset
end

function REC(bool, x, y, z, rotx, roty, rotz)
	local dt = GetTimeStep()*12

	if x > RECx then 
		RECx = RECx + dt*math.abs((x-RECx)) + RECdelta[1]*0.7
	elseif x < RECx then
		RECx = RECx - dt*math.abs((x-RECx)) + RECdelta[1]*0.7
	end
	if y > RECy then 
		RECy = RECy + dt*math.abs((y-RECy)) + RECdelta[2]*0.7
	elseif y < RECy then
		RECy = RECy - dt*math.abs((y-RECy)) + RECdelta[2]*0.7
	end
	if z > RECz then 
		RECz = RECz + dt*math.abs((z-RECz)) + RECdelta[3]*0.7
	elseif z < RECz then
		RECz = RECz - dt*math.abs((z-RECz)) + RECdelta[3]*0.7
	end
	if rotx > RECrotx then 
		RECrotx = RECrotx + dt*math.abs((rotx-RECrotx)) + RECdelta[4]*0.7
	elseif rotx < RECrotx then
		RECrotx = RECrotx - dt*math.abs((rotx-RECrotx)) + RECdelta[4]*0.7
	end
	if roty > RECroty then 
		RECroty = RECroty + dt*math.abs((roty-RECroty)) + RECdelta[5]*0.7
	elseif roty < RECroty then
		RECroty = RECroty - dt*math.abs((roty-RECroty)) + RECdelta[5]*0.7
	end
	if rotz > RECrotz then 
		RECrotz = RECrotz + dt*math.abs((rotz-RECrotz)) + RECdelta[6]*0.7
	elseif rotz < RECrotz then
		RECrotz = RECrotz - dt*math.abs((rotz-RECrotz)) + RECdelta[6]*0.7
	end

	local RECvec = Vec(RECx, RECy, RECz)
	RECdelta[1] = RECx - RECx0
	RECx0 = RECx
	RECdelta[2] = RECy - RECy0
	RECy0 = RECy
	RECdelta[3] = RECz - RECz0
	RECz0 = RECz
	RECdelta[4] = RECrotx - RECrotx0
	RECrotx0 = RECrotx
	RECdelta[5] = RECroty - RECroty0
	RECroty0 = RECroty
	RECdelta[6] = RECrotz - RECrotz0
	RECrotz0 = RECrotz

	local offset = Transform(Vec(0, 0, 0), QuatEuler(RECrotx, RECroty, RECrotz))
	offset.pos = VecAdd(offset.pos, RECvec)

	return offset
end

function ADSImpulse(x,y,z,rx,ry,rz)
	ADSdelta[1]=ADSdelta[1]+x
	ADSdelta[2]=ADSdelta[2]+y
	ADSdelta[3]=ADSdelta[3]+z
	ADSdelta[4]=ADSdelta[4]+rx
	ADSdelta[5]=ADSdelta[5]+ry
	ADSdelta[6]=ADSdelta[6]+rz
end

------UI AND MISC FUNCTIONS------

function QuatToEuler(quat)
	local euler={}
	local x,y,z=GetQuatEuler(quat)
	euler[1]=x
	euler[2]=y
	euler[3]=z
	return euler
end

function CheckAmmo(magslot)
	local checkammo =  magtable2[magslot][2]
	local maxammo = magtable2[magslot][3]
	local percentage = checkammo/maxammo
	if percentage >= 1 then
		checkammotext = "Full"
	elseif percentage > 0.8 then
		checkammotext = "Nearly Full"
	elseif percentage > 0.6 then
		checkammotext = "Just Over Half Full"
	elseif percentage > 0.4 then
		checkammotext = "About Half Full"
	elseif percentage > 0.2 then
		checkammotext = "Just Under Half Full"
	elseif percentage > 0 then
		checkammotext = "Nearly Empty"
	else
		checkammotext = "Empty"
	end
	return checkammotext
end

function drawHint(info)
	if info[5] < 0.1 then
		return
	end
	UiPush()
		UiTranslate(info[1],info[2])
		local maxW=0
		UiFont("bold.ttf",20)
		maxW=UiGetTextSize(info[8][1])
		local row=1
		UiFont("regular.ttf",15)
		for i=2,#info[8] do
			maxW=math.max(UiGetTextSize(info[8][i]),maxW)
			row=i
		end
		UiTranslate(-((info[3]+maxW+40)/2+10)*info[6],-((info[4]+(10+row*20)+12)/2+10)*info[7])
		UiColor(0,0,0,info[5]*.5)
		UiTranslate(-15, -35)
		UiImageBox("ui/common/box-solid-6.png",40+maxW,20+row*20,6,6)
		UiColor(1,1,1,info[5])
		UiImageBox("ui/common/box-outline-6.png",40+maxW,20+row*20,6,6)
		UiTranslate(15, 35)
		UiTranslate(0,(row-1)*-10)
		UiFont("bold.ttf",20)
		UiText(info[8][1])
		UiFont("regular.ttf",15)
		for i=2,row do
			UiTranslate(0,20)
			UiText(info[8][i])
		end
	UiPop()
end

function AttachmentButton(itemType,itemID,wantHint,location,Description,W,H)
	local clicked=false
	UiPush()
		local item=GetString("savegame.mod."..itemType)
		if item==itemID then
			UiColor(.5,1,.5,.5)
		else
			UiColor(0,0,0,.5)
		end
		local w,h=UiGetImageSize("MOD/img/icon/"..itemID..".png")
		local ww=W or w+12
		local wh=H or h+12
		UiImageBox("ui/common/box-solid-6.png",ww,wh,6,6)
		UiColor(1,1,1)
		UiImageBox("ui/common/box-outline-6.png",ww,wh,6,6)
		if UiImageButton("MOD/img/icon/"..itemID..".png")then
			clicked=true
			PlaySound(uiselect, GetPlayerTransform().pos, 1)
			if item == itemID then
				SetString("savegame.mod."..itemType, "")
			else
				SetString("savegame.mod."..itemType, itemID)
			end
		end
		if wantHint then
			hoverindex=hoverindex+1
			local hover,x,y=hovering(ww,wh,hoverindex)
			if hover > 0 then
				hint=true
				info={location[1],location[2],ww,wh,hover,x,y,Description}
			else
				hint=hint or false
			end
		end
	UiPop()
	return clicked,ww,wh
end

function MagButton(itemType,itemID,wantHint,location,Description,W,H)
	local clicked=false
	UiPush()
		local item=itemType
		if item==itemID then
			UiColor(.5,1,.5,.5)
		else
			UiColor(0,0,0,.5)
		end
		local curmagslot0=GetString("savegame.mod.mslot"..itemID)
		if inventoryenabled then
			curmagslot0=magtable2[itemID][1]
		end
		local w,h=UiGetImageSize("MOD/img/icon/"..curmagslot0..".png")
		local ww=W or w+12
		local wh=H or h+12
		UiImageBox("ui/common/box-solid-6.png",ww,wh,6,6)
		UiColor(1,1,1)
		UiImageBox("ui/common/box-outline-6.png",ww,wh,6,6)
		if UiImageButton("MOD/img/icon/"..curmagslot0..".png")then
			clicked=true
			PlaySound(uiselect, GetPlayerTransform().pos, 1)
			nextmagslot = itemID
		end
		if wantHint then
			hoverindex=hoverindex+1
			local hover,x,y=hovering(ww,wh,hoverindex)
			if hover > 0 then
				hint=true
				info={location[1],location[2],ww,wh,hover,x,y,Description}
			else
				hint=hint or false
			end
		end
	UiPop()
	return clicked,ww,wh
end

function AttachmentGroup(itemType,itemID,location,Description,order,W,H)
	local clicked=false
	UiPush()
		UiAlign("center middle")
		local itemSelected = GetString("savegame.mod."..itemID)
		if itemSelected == "" then
			itemSelected = "none"
		end
		local w,h=UiGetImageSize("MOD/img/icon/"..itemSelected..".png")
		local ww=W or w+12
		local wh=H or h+12

		x,y,dist=UiWorldToPixel(location)
		UiTranslate(x,y)
		if dist<0 then UiPop() return end
		
		local item=GetString("savegame.mod."..itemType)
		if item==itemID then
			UiColor(.5,1,.5,.5)
		else
			UiColor(0,0,0,.5)
		end
		UiImageBox("ui/common/box-solid-shadow-50.png",120,120,6,6)

		local ppos=GetPlayerTransform(GetToolBody())
		order = 1-order
		location2 = TransformToParentPoint(ppos, Vec(optionsx*3+math.sin(order*math.pi*1.5-math.pi*1.66)*3, 1-math.cos(order*math.pi*1.5-math.pi*1.66)*2, -5))
		DebugLine(location, location2, 1, 1, 1, 1)
		x2,y2=UiWorldToPixel(location2)
		UiTranslate(x2,y2)
		UiImageBox("ui/common/box-solid-6.png",ww,wh,6,6)
		UiColor(1,1,1)
		UiImageBox("ui/common/box-outline-6.png",ww,wh,6,6)
		if UiImageButton("MOD/img/icon/"..itemSelected..".png",ww,wh)then
			clicked=true
			PlaySound(uiselect, GetPlayerTransform().pos, 1)
			if item == itemID then
				SetString("savegame.mod."..itemType, "")
			else
				SetString("savegame.mod."..itemType, itemID)
			end
		end
	UiPop()
	return location2
end

function KeybindButton(keybind)
	local clicked=false
	UiPush()
		if keybind==GetString("savegame.mod.currentkey") then
			UiColor(.5,1,.5,.5)
			keys = {"q","w","e","r","t","y","u","i","o","p","a","s","d","f","g","h","j","k","l","z","x","c","v","b","n","m","[","]",";",",","."}
			for i = 1,#keys do
				if InputPressed(keys[i]) then
					SetString("savegame.mod."..keybind, keys[i])
					SetString("savegame.mod.currentkey", "")
				end
			end
		else
			UiColor(0,0,0,.5)
		end
		local w,h=UiGetTextSize(keybind..": a")
		local ww=W or w+12
		local wh=40
		UiImageBox("ui/common/box-solid-6.png",ww,wh,6,6)
		UiColor(1,1,1)
		UiImageBox("ui/common/box-outline-6.png",ww,wh,6,6)
		if UiTextButton(keybind..": "..string.upper(GetString("savegame.mod."..keybind)))then
			clicked=true
			PlaySound(uiselect, GetPlayerTransform().pos, 1)
			SetString("savegame.mod.currentkey", keybind)
		end
	UiPop()
	return clicked,ww,wh
end

function placeItem(grabinfo, i, j)
	local item, parent, w, h, origx, origy = grabinfo[1][1], grabinfo[1][2], grabinfo[1][3], grabinfo[1][4], grabinfo[2], grabinfo[3]
	local collision = false

	if i+w-1 > #slots or j-h+1 <= 0 then
		if origx>=w and origy>=h then
			slots[origx][origy] = {item, {origx, origy}, w, h}
		end
		return
	end

	for a = 1, w do
		for b = 1, h do
			if (origx+a-1)>0 and (origy-b+1)>0 then
				slots[origx+a-1][origy-b+1][2] = {0, 0}
				slots[origx+a-1][origy-b+1][3], slots[origx+a-1][origy-b+1][4]= 1, 1
			end
		end
	end

	for a = 1, w do
		for b = 1, h do
			if slots[i+a-1][j-b+1][2][1] ~= 0 then collision = true end
		end
	end
	if not collision then
		slots[i][j] = {item, {i, j}, w, h}
		for a = 1, w do
			for b = 1, h do
				slots[i+a-1][j-b+1][2][1] = {i, j}

			end
		end
	elseif collision and origx == 0 then
		return
	else
		slots[origx][origy] = {item, {origx, origy}, w, h}
		for a = 1, w do
			for b = 1, h do
				slots[origx+a-1][origy-b+1][2][1] = {origx, origy}
			end
		end
	end
end

function clearItem(grabinfo)
	local item, parent, w, h, origx, origy = grabinfo[1][1], grabinfo[1][2], grabinfo[1][3], grabinfo[1][4], grabinfo[2], grabinfo[3]

	for a = 1, w do
		for b = 1, h do
			if (origx+a-1)>0 and (origy-b+1)>0 then
				slots[origx+a-1][origy-b+1][2] = {0, 0}
				slots[origx+a-1][origy-b+1][3], slots[origx+a-1][origy-b+1][4]= 1, 1
			end
		end
	end
end

function MagButton2(mag, w, h)
	UiPush()
		UiImageBox("ui/common/box-solid-6.png", 60*w, 60*h, 6, 6)
		UiColor(1,1,1)
		UiImageBox("ui/common/box-outline-6.png", 60*w, 60*h, 6, 6)
		UiImageBox("MOD/img/icon/"..mag..".png", 60*w, 60*h)
		UiTranslate(30*(w-1), 30*(h-2))
		local inside2 = UiIsMouseInRect(60*w-1, 60*h-1)
		UiTranslate(-30*(w-1), -30*(h-2))
		if inside2 and InputPressed("usetool") then
			grabbed = {{mag, {0, 0}, w, h}, 0, 0}
		end
	UiPop()
end

function hovering(w,h,index)
	local dt=GetTimeStep()
	if UiIsMouseInRect(w,h)then
		local x,y=UiGetMousePos()
		x=x/(w/2)
		y=y/(h/2)
		local scale=math.max(math.abs(x),math.abs(y))
		if scale ~= 0 then
			inside[index][3]=(x/scale)*.1+inside[index][3]*.9
			inside[index][4]=(y/scale)*.1+inside[index][4]*.9
		end

		if inside[index][1]>=1 then
			inside[index][2]=math.min(1,inside[index][2]+dt*2)
		else
			inside[index][1]=math.min(1,inside[index][1]+dt*2)
		end
	else
		inside[index][1]=math.max(0,inside[index][1]-dt*4)
		inside[index][2]=math.max(0,inside[index][2]-dt*4)
	end
	return inside[index][2],inside[index][3],inside[index][4]
end

function optionsSlider(current, min, max, incri)
    UiPush()
        UiTranslate(0, -8)
        local steps = incri or 1
        local value = (current - min) / (max - min)
        local width = 100
	UiTranslate(width, 0)
        UiRect(width, 3)
	UiTranslate(-width, 0)
        UiAlign("center middle")
        value = UiSlider("ui/common/dot.png", "x", value*width, 0, width)/width
        value = math.floor((value*(max-min)+min)/steps+0.5)*steps
    UiPop()
    return value
end

------SIGHT RENDERING------
function drawHoloSight(cond,sightcenter,tolerance,reticle,size,altreticle)
	if not cond then return end
	if altreticle == nil then altreticle = reticle end
	if cond then
		local gt = GetBodyTransform(GetToolBody())
		local gunpos = TransformToParentPoint(gt, sightcenter)
		local fwdpos = TransformToParentVec(gt, Vec(0, 0, -1))
		QueryRejectBody(GetToolBody())
		local hit, dist = QueryRaycast(gunpos, fwdpos, 500, 0, true)
		local hitpoint = VecAdd(gunpos, VecScale(fwdpos, dist))

		-- not for drawing sight, rather getting dist between sight center and edge
		local camtrans = GetPlayerCameraTransform()
		local sightdist = VecLength(VecSub(camtrans.pos, gunpos))
		local holopoint = VecAdd(camtrans.pos, VecScale(VecNormalize(VecSub(camtrans.pos, hitpoint)), -sightdist))

		if VecLength(VecSub(TransformToParentPoint(gt, sightcenter), holopoint)) < tolerance then -- when walking, this calc will lag behind and sometimes cut off the reticle when it shouldn't
			UiPush()
				UiAlign("center middle")
				UiColor(1,1,1,0.5)
				local x, y = UiWorldToPixel(hitpoint)
				UiTranslate(x,y)
				local fov = (GetInt("options.gfx.fov")-ADSfov)/120
				local w, h = math.ceil((size/fov)*UiWidth()/1920), math.ceil((size/fov)*UiWidth()/1920)
				if altaim then
					UiImageBox(altreticle, w, h)
				else
					UiImageBox(reticle, w, h)
				end
			UiPop()
		end
	end
end

function LoadTool(body, prefab)
	local tbS = GetBodyShapes(body)
	for i=1,#tbS do Delete(tbS[i]) end

	local baseTransform = Transform()
	local entities = Spawn(prefab, baseTransform)
	--DebugPrint(#entities)
	local BodyTrans = GetBodyTransform(entities[66])
	--DebugPrint(BodyTrans)
 	for i=1,#entities do 
		--DebugPrint(i)
		SetShapeBody(entities[i], body, TransformToLocalTransform(baseTransform, GetShapeWorldTransform(entities[i])))
	end
	
end

function round(number, decimals)
    local power = 10^decimals
    return math.floor(number * power) / power
end

function math.clamp(n, low, high) return math.min(math.max(n, low), high) end

function Split(s, delimiter)
    local result = {};
    -- (v2 fix) gun scripts read fields of whatever gun is in the primary slot at init;
    -- a missing field (e.g. RPG / empty slot has no field 10) used to crash client.init.
    if s == nil then return result end
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result;
end
function IDBuilder(t)
	local ID=""
    for _,s in ipairs(t)do
		ID=ID..s.."_"
    end
    return ID:sub(1,#ID-1)
end

function handleCommand(cmd) HandleQuickload(cmd) end
function HandleQuickload(cmd)
	for _, word in ipairs(splitString(cmd, " ")) do
		if word == "quickload" then
			Init_Settings()
		end
		break
	end
end
------SIDES------
function Laser(Active,Pos, Shape, Color)
	local movementoffset = {0,0,0}
	if InputDown("d") and not InputDown("shift") then movementoffset[1] = 0.05 
	elseif InputDown("a") and not InputDown("shift") then movementoffset[1] = -0.05
	elseif InputDown("w") and InputDown("shift") then movementoffset[1] = 0.08
	else 
	
	end
	if #Color == 4 then 
	CV = {Color[1],Color[2],Color[3],Color[4]} 
	else 
	CV = Guns.SidePresets.Laser[Color] end
	local GT = GetBodyTransform(GetToolBody())
	local GunPos = TransformToParentPoint(GT, VecAdd(Pos,movementoffset))
	local FWDPos = TransformToParentVec(GT, Vec(0, 0, -1))
	QueryRejectBody(GetToolBody())
	local hit, dist = QueryRaycast(GunPos, FWDPos, 500, 0, true)
	local HitPoint = VecAdd(GunPos, VecScale(FWDPos, dist))
	if Active and Color ~= "IR" then
		SetShapeEmissiveScale(Shape, 1)
		PointLight(HitPoint, CV[1], CV[2], CV[3], CV[4]/math.random(1,2))
		PointLight(GunPos, CV[1], CV[2], CV[3], CV[4]/8/math.random(1,2))
		DrawLine(GunPos, HitPoint, CV[1], CV[2], CV[3], CV[4]/math.random(1,2))
		laserFactor = 0.9
	elseif Active and Color == "IR" and GetBool("inventory.nvg.enabled") then
		SetShapeEmissiveScale(Shape, 1)
		PointLight(HitPoint, CV[1], CV[2], CV[3], CV[4]/math.random(1,2))
		PointLight(GunPos, CV[1], CV[2], CV[3], CV[4]/8/math.random(1,2))
		DrawLine(GunPos, HitPoint, CV[1], CV[2], CV[3], CV[4]/math.random(1,2))
		laserFactor = 0.9
	else
		SetShapeEmissiveScale(side1, 0)
		laserFactor = 1
	end
end

function FlashLight(Active,Pos, Shape, Color)
	if #Color == 4 then CV = {Color[1],Color[2],Color[3],Color[4]} else CV = Guns.SidePresets.FlashLight[Color] end
	local GT = GetBodyTransform(GetToolBody())
	local GunPos = TransformToParentPoint(GT, Pos)
	local FWDPos = TransformToParentVec(GT, Vec(0, 0, -1))
	QueryRejectBody(GetToolBody())
	local hit, dist = QueryRaycast(GunPos, FWDPos, 40, 0, true)
	if Active then
		SetShapeEmissiveScale(Shape, 1)
		PointLight(GunPos, CV[1]/2, CV[2]/2, CV[3]/2, CV[4]/2)
		for i=1,dist*5 do
			local hitpoint = VecAdd(GunPos, VecScale(FWDPos, i/5))
			local b = 0.1
			PointLight(hitpoint, CV[1], CV[2], CV[3], CV[4]/1000*(i^2))
		end
	else
		SetShapeEmissiveScale(Shape, 0)
	end
end


-- (v2 note 2026-11-07) Original-mod behaviour: an EMPTY gun with unlimited ammo turned on gets 1 round in a 1-round
-- "Infinite" mag, but no bullet type for it (bullettable / item field 10 stay empty). FireRound then looked up type
-- "nil" and errored on every shot; GunPerkFor (gunperks.lua) now fires such a round as the calibre's default.
function checkUnlimitedBulletsValid()
	if unlimitedammo and ammo == 0 then
		name = "Infinite"
		local guninfo = Split(GetString("inventory.guns."..GetInt("inventory.curprimary")..".item"), "_")
		guninfo[3] = ""
		guninfo[4] = name
		guninfo[5] = 1
		guninfo[6] = 1
		SetString("inventory.guns."..GetInt("inventory.curprimary")..".item", IDBuilder(guninfo))
		SetBool("inventory.update", true)
		ammo = 1
	end
end

Grenades = {}

function throw_grenade(spawnPos, targetPos, vel, fuse_time, explosion_size)

	-- Spawn grenade
	local grenadeXML = "MOD/main/GoreRagdolls2/prefab/npc_grenade.xml"
	local spawnedGrenade = Spawn(grenadeXML, Transform(spawnPos))

	-- Create grenade object
	local grenade = create_gGrenade(fuse_time or 2.5, explosion_size or 1)
	grenade.body = spawnedGrenade[1]
	grenade.shape = GetBodyShapes(grenade.body)[1]
	grenade.active = true

	-- Add grenade object to Grenades list.
	table.insert(Grenades, grenade)

	-- Set throw target position.
	local throwTargetPos = targetPos
	if GetPlayerVehicle(GoreP) ~= 0 then -- (v2 goreai) target player
		throwTargetPos = VecAdd(throwTargetPos, GetBodyVelocity(GetVehicleBody(GetPlayerVehicle(GoreP))))
	end

	-- Set grenade velocity.
	local throwVel = VecScale(DirLookAt(spawnPos, throwTargetPos), vel or 2)
	throwVel[2] = throwVel[2] * RandomSpreadPercent25(2.5)
	throwVel = VecScale(throwVel, 1) --todo Add greanade throw spread
	throwVel = VecAdd(throwVel, VecRandom(1))
	SetBodyVelocity(grenade.body, throwVel)
	SetTag(grenade.body, "interact", "Throw Back")

  -- Frag throw sound.
	PlaySound(LoadSound("MOD/snd/Weapons/Handheld/Grenade/frag_throw.ogg"), spawnPos, 1)

  grenade.lastvel = throwVel

end

function create_gGrenade(fuse_time, explosion_size)

	local grenade = {}

	grenade.active = false

	grenade.time = fuse_time or 2
	grenade.time_def = fuse_time or 2

	grenade.throwTime = GetTime()
	grenade.beepIncrement = grenade.time_def/8

	grenade.explosion_size = explosion_size or 0

	grenade.landed = false
	grenade.lastvel = Vec()

	return grenade

end

--- Runs the timers and explosions for all existing grenades.
function tick_grenades()

	local removeGrenades = {}

	for index, grenade in ipairs(Grenades) do -- for each grenade

		if not IsHandleValid(grenade.shape) then

			table.insert(removeGrenades, index)

		else

			local grenadePos = AabbGetBodyCenterPos(grenade.body)
			if grenade.active then -- run valid grenade

				local curvel = GetBodyVelocity(grenade.body)
				local impulse = VecLength(VecSub(grenade.lastvel, curvel))
				if impulse > 1 and grenade.landed then
					PlaySound(LoadSound("MOD/snd/Weapons/Handheld/Grenade/rattle_dirt_0.ogg"), grenadePos, 4)
				elseif impulse > 1 then
					PlaySound(LoadSound("MOD/snd/Weapons/Handheld/Grenade/bounce_dirt_0.ogg"), grenadePos, 4)
					grenade.landed = true
				end
				grenade.lastvel = curvel

				for _, p in ipairs(GorePlayerIds) do -- (v2) any player can throw it back
					if GetPlayerInteractBody(p) == grenade.body and InputPressed("interact", p) then
						local throwVel = VecScale(VecNormalize(VecSub(grenadePos,GetPlayerTransform(p).pos)), 15)
						SetBodyVelocity(grenade.body, throwVel)
					end
				end

				-- Check if grenade should blow up.
				grenade.time = grenade.time - GetTimeStep()
				if grenade.time <= 0 or IsShapeBroken(grenade.shape) then

					PlaySound(Sounds.GrenadeExplosion, grenadePos, 2)
					Explosion(grenadePos, grenade.explosion_size)

					spalling_push_shrapnel(Transform(grenadePos))

					PlaySound(LoadSound("MOD/snd/Explosions/frag_sand_0.ogg"), grenadePos, 8)
					PlaySound(LoadSound("MOD/snd/Explosions/Shared/Debris/expl_debris_dirt_0.ogg"), grenadePos, 3)
					PlaySound(LoadSound("MOD/snd/Explosions/Shared/Debris/expl_debris_sand_0.ogg"), grenadePos, 3)

					RemoveTag(grenade.body, "interact")
          Delete(grenade.body)

					table.insert(removeGrenades, index)
				end

			end

		end

	end

	-- Safely remove grenade object
	for _, grenade_index in ipairs(removeGrenades) do
		table.remove(Grenades, grenade_index)
	end

end

function npc_check_grenade_throwing(npc)

	local throwPos = AabbGetBodyCenterTopPos(npc.Head)

	local g = npc.ai.thinking.grenades
	g.throwDist = VecDist(npc.ai.shootPos, npc.torsoTr.pos)
	g.withinRange = g.throwDist < g.throwRange.max and g.throwDist > g.throwRange.min

	if config.goreai.throw_grenades and g.enabled then

		if g.withinRange then
			g.throwTime = g.throwTime - GetTimeStep()
		else
			-- g.throwTime = g.throwTime - (GetTimeStep())
		end


		if g.throwTime <= 0 then

			if g.withinRange then

				if npc.ai.thinking.attacking.canShootAimPos then

					local throwTr = Transform(throwPos, QuatLookAt(throwPos, npc.ai.shootPos))

					RejectAllShapes(npc.AllShapes)
					RejectAllBodies(npc.AllBodies)
					local hit = RaycastFromTransform(throwTr, g.throwDist/2, 0.5)
					if hit then -- Check halfway between throw pos and target (avoid throwing at a wall.)

						g.throwTime = math.random(g.recheckTimeRange.min, g.recheckTimeRange.max)

					else --Throw grenade

						throw_grenade(throwPos, npc.ai.shootPos, g.throwDist + 0.75, g.time_def, g.config.explosion_size)
						g.throwTime = math.random(g.throwTimeRange.min, g.throwTimeRange.max)

						local faction = npc.ai.teams.team
						-- PlaySound(LoadSound("MOD/snd/npc/npc_callout_grenadeout_"..faction.."_0.ogg"), spawnPos, 1)

					end

				end

			else -- Full reset if time <= 0 and out of range (prevents instantly throwing nade once in range)

				g.throwTime = math.random(g.throwTimeRange.min, g.throwTimeRange.max)

			end

		end


	end

end

--todo Add grenade hud indicator (around edges))




-- AVF Spalling
function tick_spalling(dt)
  -- DebugWatch("shells",#spallHandler.shells  )
  for key,shell in ipairs( spallHandler.shells  )do
    if(shell.active)then
      if(shell.timeToLive > 0) then
        if(shell.shrapnel) then
          spalling_shrapnel_operations(shell,dt)

        else
          spallingOperations(shell,dt)
        end
        shell.timeToLive = shell.timeToLive - dt
      else
        shell.active = false
        active_spall  = active_spall -1
      end
    end
end
end
function spalling_push_shrapnel(spallingLoc)
  local munition_pos = GetShapeWorldTransform(munition)
  -- DebugWatch("spalling loc ori",spallingLoc)
  -- DebugWatch("last vel dir",last_vel_dir)
  spallingLoc.rot = QuatLookAt(spallingLoc.pos,VecAdd(spallingLoc.pos,last_vel_dir))
  local launch_dir = TransformCopy(spallingLoc)
  local cone = 1 * math.sin(weapon.cone)
  -- DebugWatch("cone",cone)
  local spallValue = weapon.spall_value
  -- DebugWatch("spall quant_1",spallValue)
  if(weapon.explosionSize) then
    spallValue = spallValue *  weapon.explosionSize
  end
  -- DebugWatch("spall quant",spallValue)
  local spallQuant = math.random(spallValue,spallValue*3)

  -- DebugWatch("spalling loc",spallingLoc)

  total_spall = spallQuant
  active_spall = active_spall+total_spall
  for i=1, spallQuant do
    local x = rnd(-cone,cone)
    local y = rnd(-cone,cone)
    local z = rnd(2,6)
    local jet_vel = Vec(x,y,z)

    jet_vel  =  VecNormalize(VecSub(launch_dir.pos,TransformToParentPoint(launch_dir, jet_vel)))
    -- DebugWatch("jet_vel",jet_vel)

    local spallingSizeCoef = math.random(1,4)/10
    local spallPos = TransformCopy(spallingLoc)
    local direction = rndVec(math.random(1,spallValue))
    local point1 = spallPos.pos
    spallHandler.shells[#spallHandler.shells+1] = DeepCopy(spallHandler.defaultShell)
    local currentSpall        = spallHandler.shells[#spallHandler.shells]
    currentSpall.active       = true
    currentSpall.shellType = {}
    currentSpall.cannonLoc    = spallPos
    currentSpall.point1       = point1
    if weapon.sphere then
      currentSpall.predictedBulletVelocity = VecScale(Vec(math.random()-.5,math.random()-.5,math.random()-.5),rnd(weapon.jet_vel*.7,weapon.jet_vel*1.3))
    else
      currentSpall.predictedBulletVelocity = VecScale(jet_vel,rnd(weapon.jet_vel*.7,weapon.jet_vel*1.3)) --rndVec(math.random() * 200)
    end
    currentSpall.initial_vel = VecCopy(currentSpall.predictedBulletVelocity)
    currentSpall.shrapnel = true
    currentSpall.originPos    = spallPos
    currentSpall.maxTimeToLive = (3 *(spallingSizeCoef+0.2))*(math.random(50,100)/100)
    currentSpall.timeToLive   = currentSpall.maxTimeToLive
    currentSpall.dispersion     = 10
    currentSpall.shellType.bulletdamage = {}
    currentSpall.shellType.bulletdamage[1] = rnd(0.7,1.1) * spallingSizeCoef * weapon.shrapnel_damage_low
    currentSpall.shellType.bulletdamage[2] = rnd(0.7,1.1) * spallingSizeCoef * weapon.shrapnel_damage_med
    currentSpall.shellType.bulletdamage[3] = rnd(0.7,1.1) * spallingSizeCoef * weapon.shrapnel_damage_hi
    currentSpall.shellType.caliber = (weapon.shrapnel_size * spallingSizeCoef)*0.3
    currentSpall.shellType.shellWidth = math.min(math.random(), 0.1)
    currentSpall.shellType.shellHeight = math.min(math.random(),0.1)
    currentSpall.penDepth = 0.1

    currentSpall.shellType.r = 2 + (math.random(0,5)/5)
    currentSpall.shellType.g = 1.7 + (math.random(0,5)/10)
    currentSpall.shellType.b = 1 + (math.random(0,10)/10)


    spallHandler.shellNum = (spallHandler.shellNum%#spallHandler.shells) +1

  end

end
function spalling_shrapnel_operations(projectile,dt)
  spalling_sprite = spalling_sprite or LoadSprite("MOD/img/spalling.png")
    projectile.cannonLoc.pos = projectile.point1
    local shellHeight = projectile.shellType.shellHeight
    local shellWidth = projectile.shellType.shellWidth
    -- local spallDecay =  math.random()* (currentSpall.maxTimeToLive / currentSpall.timeToLive )
    local spallDecay = math.random()
    local r = projectile.shellType.r * spallDecay
    local g = projectile.shellType.g * spallDecay
    local b = projectile.shellType.b * spallDecay


    --- sprite drawing
    DrawSprite(spalling_sprite, projectile.cannonLoc,projectile.shellType.shellWidth,shellHeight , r, g, b, 1, 0, false)
    local altloc = TransformCopy(projectile.cannonLoc)
    altloc.rot = QuatRotateQuat(altloc.rot,QuatEuler(0, 90,0))
    DrawSprite(spalling_sprite, altloc, projectile.shellType.shellWidth, shellHeight, r, g, b, 1, 0, false)
    altloc.rot = QuatRotateQuat(projectile.cannonLoc.rot,QuatEuler(90, 0,0))
    DrawSprite(spalling_sprite, altloc, projectile.shellType.shellWidth, projectile.shellType.shellWidth, r, g, b, 1, 0, false)


    projectile.predictedBulletVelocity = VecScale(projectile.predictedBulletVelocity,0.9)

    local dispersion = Vec(math.random(-1,1)*projectile.dispersion,math.random(-1,1)*projectile.dispersion,math.random(-1,1)*projectile.dispersion)
    if(projectile.shellType.dispersionCoef) then
      dispersion=VecScale(dispersion,dispersionCoef)
    end
    projectile.predictedBulletVelocity = VecAdd(projectile.predictedBulletVelocity,(VecScale(dispersion,dt)))

      projectile.predictedBulletVelocity = VecAdd(projectile.predictedBulletVelocity,(VecScale(globalConfig.gravity,dt)))

    local point2 = VecAdd(projectile.point1,VecScale(projectile.predictedBulletVelocity,dt))
    QueryRequire("physical")
    local hit, dist1,norm1,shape1 = QueryRaycast(projectile.point1, VecNormalize(VecSub(point2,projectile.point1)),VecLength(VecSub(point2,projectile.point1)))

    projectile.cannonLoc.rot = QuatRotateQuat(QuatLookAt(point2,projectile.point1),QuatEuler(00, 90, 90))



      local hit_player =  inflict_player_damage(projectile,point2)

      if(hit or hit_player)then
        hitPos = VecAdd(projectile.point1, VecScale(VecNormalize(VecSub(point2,projectile.point1)),dist1))
        projectile.point1 = hitPos
         spalling_pop_spalling(projectile,shape1)

      else
        projectile.point1 = point2
      end

end
function spalling_pop_spalling(shell,hitTarget)


    local holeModifier = math.random(-15,15)/100
    local fireChance = math.random(0,100)/100
    local firethreshold = 0.96
    if(fireChance>firethreshold)then
      SpawnFire(shell.point1)
    end
    if shell.shellType.hit and shell.shellType.hit <3 then
      shell.shellType.bulletdamage = VecScale(shell.shellType.bulletdamage,
                                        VecLength(shell.predictedBulletVelocity)/VecLength(shell.initial_vel))
      if(shell.shellType.hit ==1)then
        MakeHole(shell.point1,shell.shellType.bulletdamage[1]*1.4)
      else
        MakeHole(shell.point1,shell.shellType.bulletdamage[1]*1.4,shell.shellType.bulletdamage[2]*1.2)
      end

    else
      MakeHole(shell.point1,shell.shellType.bulletdamage[1]*1.4,shell.shellType.bulletdamage[2]*1.2, shell.shellType.bulletdamage[3]*1.2)
    end
    Paint(shell.point1, shell.shellType.bulletdamage[1]*1.8, "explosion")

    shell.active = false
    active_spall  = active_spall -1
    for key,val in ipairs( shell ) do
      val = nil

    end
    shell = DeepCopy(spallHandler.defaultShell)

end


function rnd(mi, ma)
  return math.random()*(ma-mi)+mi
end
function rndVec(length)
  local v = VecNormalize(Vec(math.random(-100,100), math.random(-100,100), math.random(-100,100)))
  return VecScale(v, length)
end
function inflict_player_damage(projectile,point2)
  local t= Transform(projectile.point1,QuatLookAt(point2,projectile.point1))
  local p = TransformToParentPoint(t, Vec(0, 0, 1))
  local p2 = TransformToParentPoint(t, Vec(0, 0, 2))

  local d = VecNormalize(VecSub(projectile.point1,point2))

  hurt_dist = VecLength(VecSub(projectile.point1,point2))
  --Hurt player
  local player_cam_pos = GetPlayerCameraTransform(GoreP).pos
  local player_pos = GetPlayerTransform(GoreP).pos

  player_pos = VecLerp(player_pos,player_cam_pos,0.5)
  local toPlayer = VecSub(player_pos, t.pos)
  local distToPlayer = VecLength(toPlayer)
  local distScale = clamp(1.0 - distToPlayer / hurt_dist, 0.0, 1.0)
  -- DebugWatch("test",distScale)
  if distScale > 0 then
    -- DebugWatch("dist scale",distScale)
    toPlayer = VecNormalize(toPlayer)
    -- DebugWatch("dot to player",VecDot(d, toPlayer))
      -- DebugWatch("distToPlayer",distToPlayer)
    if VecDot(d, toPlayer) > 0.9 or distToPlayer < 1 then
      -- DebugWatch("player dist scale",distScale)
      -- DebugWatch("distToPlayer",distToPlayer)
      local hit = QueryRaycast(p, toPlayer, distToPlayer)
      if not hit or distToPlayer < 0.7 then
        -- DebugWatch("player would be hit",distToPlayer)
        -- SetPlayerHealth(GetPlayerHealth() - 0.035 * (projectile.shellType.bulletdamage[1] * (distScale*2)*25)*math.log(VecLength(projectile.predictedBulletVelocity)))
        return true
      end
    end
  end
  return false
end

do

  globalConfig = {
    gravity = Vec(0,-9.8,0)
  }

  weapon = {
    weaponName         = "grenade",
      munitionType      = "explosive",
      explosionSize     = 0.5,
      fuze_time         = 5,
      fuze_sensitivity = 6,
      reliability       = .25, -- (percentage deviation from expected explosion time)
      shrapnel_damage_low =  1,
      shrapnel_damage_med =  0.2,
      shrapnel_damage_hi =   0,
      shrapnel_size     = 0.05,
      spall_value = 150,
      jet_vel = 150,
      cone = 0.7,
      sphere = true,
      speed_limit = 295/2
  }

  spallHandler = {
      shellNum = 1,
      shells = {

      },
    defaultShell = {active=false, velocity=nil, direction =nil, currentPos=nil, timeLaunched=nil},
    velocity = 200,
    gravity = Vec(0,-10,0),
    shellWidth = 0.3,
    shellHeight = 0.3,
  }

  active_spall=0
  spalling_sprite = nil -- (v2) no API calls at load time; loaded in spalling_shrapnel_operations

end

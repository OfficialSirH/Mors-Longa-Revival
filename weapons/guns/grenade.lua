#version 2
DL_LABEL = "grenade"  -- crash breadcrumbs (lib/DeleteLog.lua)
#include "../../lib/DeleteLog.lua"
#include "script/include/player.lua"
-- (v2) server: RPG-7 rocket (player RPG and NPC RPGs): thrust, fuse, explosion, fire; proximity fuse for ANY player.
globalConfig = {
  gravity = Vec(0, -9, 0)
}

weapon = {
  weaponName          = "grenade",
  munitionType        = "explosive",
  explosionSize       = 0.5*2,
  fuze_time           = 5,
  fuze_sensitivity    = 6,
  reliability         = .25, -- (percentage deviation from expected explosion time)
  shrapnel_damage_low = 1,
  shrapnel_damage_med = 0.7,
  shrapnel_damage_hi  = 0.4,
  shrapnel_size       = 0.05,
  spall_value         = 69,
  jet_vel             = 150,
  cone                = 0.7,
  sphere              = false,
  speed_limit         = 295 / 3
}
weapon_OG7V = { -- anti personnel
  weaponName          = "grenade",
  munitionType        = "explosive",
  explosionSize       = 0.5*2,
  fuze_time           = 5,
  fuze_sensitivity    = 6,
  reliability         = .25, -- (percentage deviation from expected explosion time)
  shrapnel_damage_low = 1,
  shrapnel_damage_med = 0.3,
  shrapnel_damage_hi  = 0,
  shrapnel_size       = 0.05,
  spall_value         = 850,
  jet_vel             = 250,
  cone                = 1,
  sphere              = true,
  speed_limit         = 400 / 3
}
weapon_PG7VA = { -- anti personnel
  weaponName          = "grenade",
  munitionType        = "explosive",
  explosionSize       = 1*2,
  fuze_time           = 5,
  fuze_sensitivity    = 6,
  reliability         = .25, -- (percentage deviation from expected explosion time)
  shrapnel_damage_low = 1,
  shrapnel_damage_med = 0.3,
  shrapnel_damage_hi  = 0,
  shrapnel_size       = 0.05,
  spall_value         = 1150,
  jet_vel             = 300,
  cone                = 1,
  sphere              = true,
  speed_limit         = 170 / 3
}
weapon_PG7V = { -- high explosive anti tank
  weaponName          = "grenade",
  munitionType        = "explosive",
  explosionSize       = 0.3*2,
  fuze_time           = 5,
  fuze_sensitivity    = 6,
  reliability         = .25, -- (percentage deviation from expected explosion time)
  shrapnel_damage_low = 1,
  shrapnel_damage_med = 0.6,
  shrapnel_damage_hi  = 0.3,
  shrapnel_size       = 0.05,
  spall_value         = 40,
  jet_vel             = 100,
  cone                = 1,
  sphere              = false,
  speed_limit         = 300 / 3
}
weapon_PG7VT = { -- high explosive tandem anti tank
  weaponName          = "grenade",
  munitionType        = "explosive",
  explosionSize       = 0.5*2,
  fuze_time           = 5,
  fuze_sensitivity    = 6,
  reliability         = .25, -- (percentage deviation from expected explosion time)
  shrapnel_damage_low = 1,
  shrapnel_damage_med = 0.9,
  shrapnel_damage_hi  = 0.5,
  shrapnel_size       = 0.1,
  spall_value         = 80,
  jet_vel             = 150,
  cone                = 0.7,
  sphere              = false,
  speed_limit         = 200 / 3
}


spallHandler =
{
  shellNum = 1,
  shells = {

  },
  defaultShell = { active = false, velocity = nil, direction = nil, currentPos = nil, timeLaunched = nil },
  velocity = 200,
  gravity = Vec(0, -10, 0),
  shellWidth = 0.3,
  shellHeight = 0.3,
}


boom_pos = nil

warhead_primed = false

--[[
[1] = "Standard",
[2] = "Realistic",
[3] = "OP",


]]

function server.init()
  rpg_type = GetString("savegame.mod.rpg_type")

  if not HasKey("savegame.mod.rpg_type") then
     rpg_type = "rocket0"
     --SetString("savegame.mod.rpg_type",rpg_type)
  end
  -- (v2 fix) v1 never set rpg_type, so every rocket was the PG-7V; the player's RPG now reports the loaded rocket
  -- just before spawning it (server.rpgNextRocket). Read once and cleared, so NPC rockets keep the default.
  if GetString("level.rpg.next_rocket") ~= "" then
     rpg_type = GetString("level.rpg.next_rocket")
     SetString("level.rpg.next_rocket", "")
  end
  weapon = deepcopy(weapon_PG7V)
  if (rpg_type == "rocket0") then
     weapon = deepcopy(weapon_PG7V)
  elseif (rpg_type == "rocket1") then
     weapon = deepcopy(weapon_OG7V)
  elseif (rpg_type == "rocket2") then
     weapon = deepcopy(weapon_PG7VT)
  elseif (rpg_type == "rocket3") then
     weapon = deepcopy(weapon_PG7VA)
  end
  munition        = FindShape(weapon.weaponName)
  body            = GetShapeBody(munition)
  shapes          = FindShapes("")
  -- DebugWatch("body vel at init",VecLength(GetBodyVelocity(body)))

  last_vel_dir    = GetBodyVelocity(body)
  last_vel        = VecLength(GetBodyVelocity(body))
  fuze            = weapon.fuze_time + rnd(-weapon.fuze_time * weapon.reliability, weapon.fuze_time * weapon.reliability)
  added_cook_time = false

  exploded        = false
  explosion_sound = LoadSound("MOD/assets/snd/Weapons/Handheld/Grenade/grenade_explosion.ogg")
  spalling_sprite = LoadSprite("MOD/assets/img/spalling.png")
  primetimer      = 0
  explosionfactor = 1

  active_spall = 0
  total_spall = 0
end

function rnd(mi, ma)
  return math.random() * (ma - mi) + mi
end

function rndVec(length)
  local v = VecNormalize(Vec(math.random(-100, 100), math.random(-100, 100), math.random(-100, 100)))
  return VecScale(v, length)
end

function server.tick(dt)

  if exploded or primetimer > 10 then
    return
  end

  -- if(boom_pos~=nil) then
  --   DebugCross(boom_pos)
  -- end
  -- DebugWatch("active spall ",active_spall)
  -- DebugWatch("total spall ",total_spall)

  -- DebugWatch("body vel in flight",VecLength(GetBodyVelocity(body)))
  primetimer = primetimer + dt
  if primetimer > 0.05 then primed = true end

  if not exploded and primed then
     local calibreCoef = 1
     local exaust_pos = TransformToParentPoint(GetShapeWorldTransform(munition), Vec(0.075, -0.5, 0))
     local exaust_vec = VecSub(GetShapeWorldTransform(munition).pos,
     TransformToParentPoint(GetShapeWorldTransform(munition), Vec(0, 2, 0)))
     SpawnParticle("fire", exaust_pos, exaust_vec, 2 * calibreCoef, .15)
     SpawnParticle("smoke", exaust_pos, exaust_vec, 2 * calibreCoef, .3)
     ParticleReset()
     ParticleType("plain")
     ParticleTile(14)
     ParticleSticky(0, 0)
     ParticleRadius(0.05, 0.001)
     ParticleAlpha(1, 0)
     ParticleEmissive(10, 10)
     ParticleColor(1, 0.75, 0.25, 1, 0.25, 0.25)
     ParticleGravity(-1)
     ParticleCollide(0)
     for i = 1, math.random(8, 16) do
        SpawnParticle(exaust_pos, VecAdd(exaust_vec, VecScale(Vec(math.random() - 0.5, math.random() - 0.5,
        math.random() - 0.5), 4)), math.random() * 0.8)
     end
     PointLight(exaust_pos, 1, 0.7, 0.4, math.random(1 * calibreCoef, 15 * calibreCoef))
     local munition_body = GetShapeBody(munition)
     local speed_limit = weapon.speed_limit
     if (VecLength(GetBodyVelocity(munition_body)) < speed_limit) then
        local nose_pos = GetBodyCenterOfMass(GetShapeBody(munition))                                          --TransformToParentPoint(GetShapeWorldTransform(munition),Vec(0,0.8,0.3))
        local munition_centre = Transform(nose_pos, QuatCopy(GetShapeWorldTransform(munition).rot))
        local thrust_vec = VecSub(munition_centre.pos, TransformToParentPoint(munition_centre, Vec(0, -100, 0))) --VecSub(GetShapeWorldTransform(munition).pos, TransformToParentPoint(GetShapeWorldTransform(munition),Vec(00,-10, 0)))
        SetBodyVelocity(munition_body, VecAdd(GetBodyVelocity(munition_body), VecScale(thrust_vec, dt)))
     else
        local body_vel = GetBodyVelocity(munition_body)
        SetBodyVelocity(munition_body, VecScale(body_vel, speed_limit / VecLength(body_vel)))
     end
     -- DebugWatch("MUNITION VEL",VecLength(GetBodyVelocity(munition_body)))
     --ApplyBodyImpulse(GetShapeBody(munition),nose_pos,VecScale(thrust_vec,80*dt))
     -- local pos = GetShapeWorldTransform(munition)
     -- local calibreCoef = 10
     -- ParticleReset()
     -- ParticleType("smoke")
     -- ParticleColor(0.7, 0.6, 0.5)
     -- --Spawn particle at world origo with upwards velocity and a lifetime of ten seconds
     -- SpawnParticle(Vec(0, 0, 0), Vec(0, 1, 0), 10.0)
     -- PointLight(pos, 0.8, 0.8, 0.5, math.random(1*calibreCoef,15*calibreCoef))

     if NearestPlayerDist(GetShapeWorldTransform(munition).pos, 0.5) < 1.2 and primed then -- (v2) any player
        fuze = -1
        explosionfactor = explosionfactor * 2
     end

     if (warhead_primed) then

        for index, shape in ipairs(shapes) do QueryRejectShape(shape) end
        QueryRejectBody(body)
        local hit, dist1, norm1, shape1 = QueryRaycast(
          GetBodyTransform(body).pos,
          VecNormalize(GetBodyVelocity(body)),
          VecLength(GetBodyVelocity(body)) * GetTimeStep(),
          0.2)
        if ForceImpact then hit = true end -- (v2 fix) see RocketImpactTick

        if hit then
           local pos = GetShapeWorldTransform(munition).pos
           local explode_pos = TransformToParentPoint(GetShapeWorldTransform(munition), Vec(0, weapon.explosionSize * .7,
           0.3))
           -- (v2 fix) found by the impact ray: explode where it hit (the rocket may have bounced / turned since)
           if ForceImpact and ImpactPos then explode_pos = ImpactPos end
           Explosion(explode_pos, weapon.explosionSize * explosionfactor)
           PlaySound(explosion_sound, pos, 50)
           local shrapnel_pos = TransformToParentPoint(GetShapeWorldTransform(munition), Vec(0, 1.4, 0))
           boom_pos = shrapnel_pos
         --   spalling_push_shrapnel(Transform(shrapnel_pos))
           EmitFire(5, Transform(shrapnel_pos, QuatLookAt(explode_pos, shrapnel_pos)), math.max(0.2, 0.3 * 1.5), 1)

           for i = 1, math.random(20, 30) do
              ParticleReset()
              ParticleType("smoke")
              ParticleTile(0)
              ParticleSticky(0, 0)
              ParticleRadius(math.random(3, 10), math.random(5, 15))
              ParticleAlpha(1, 0.5)
              ParticleEmissive(0)
              ParticleColor(0.15, 0.15, 0.15, 0.35, 0.35, 0.35)
              ParticleGravity(-0.5)
              ParticleCollide(0)


              local rdmVec = VecScale(Vec(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5), math.random(5, 15))
              -- local particleVel = VecAdd(VecScale(VecNormalize(exaust_vec), math.random(1, 10)), rdmVec)

              SpawnParticle(VecAdd(explode_pos, Vec(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5)),rdmVec,10)
           end

           exploded = true
           Delete(body)
        end
     else
        if VecLength(GetBodyVelocity(body)) > 10 and fuze_triggered(GetBodyVelocity(body)) then
           warhead_primed = true
           last_vel_dir = GetBodyVelocity(body)
           last_vel = VecLength(GetBodyVelocity(body))
        end
     end
   end
  if (active_spall > 0) then
     tick_spalling(dt)
  end
end



function fuze_triggered(t_vel)
  vel = VecLength(t_vel)
  -- DebugWatch("last vel",last_vel)

  -- DebugWatch("test vel",vel)
  if math.abs(1 - (last_vel / vel)) / GetTimeStep() > weapon.fuze_sensitivity then
     return true
  elseif NearestPlayerDist(GetShapeWorldTransform(munition).pos, 0) < 1.2 then -- (v2) any player
     explosionfactor = 2
     return true
  else
     last_vel_dir = t_vel
     last_vel = vel
     return false
  end
end

function spalling_push_shrapnel(spallingLoc)
  local munition_pos = GetShapeWorldTransform(munition)
  -- DebugWatch("spalling loc ori",spallingLoc)
  -- DebugWatch("last vel dir",last_vel_dir)
  spallingLoc.rot = QuatLookAt(spallingLoc.pos, VecAdd(spallingLoc.pos, last_vel_dir))
  local launch_dir = TransformCopy(spallingLoc)
  local cone = 1 * math.sin(weapon.cone)
  -- DebugWatch("cone",cone)
  local spallValue = weapon.spall_value
  -- DebugWatch("spall quant_1",spallValue)
  if (weapon.explosionSize) then
     spallValue = spallValue * weapon.explosionSize
  end
  -- DebugWatch("spall quant",spallValue)
  local spallQuant = math.random(spallValue, spallValue * 3)

  -- DebugWatch("spalling loc",spallingLoc)

  total_spall = spallQuant
  active_spall = total_spall
  for i = 1, spallQuant do
     local x                                     = rnd(-cone, cone)
     local y                                     = rnd(-cone, cone)
     local z                                     = rnd(2, 6)
     local jet_vel                               = Vec(x, y, z)

     jet_vel                                     = VecNormalize(VecSub(launch_dir.pos,
     TransformToParentPoint(launch_dir, jet_vel)))
     -- DebugWatch("jet_vel",jet_vel)

     local spallingSizeCoef                      = math.random(1, 4) / 10
     local spallPos                              = TransformCopy(spallingLoc)
     local direction                             = rndVec(math.random(1, spallValue))
     local point1                                = spallPos.pos
     spallHandler.shells[#spallHandler.shells + 1] = deepcopy(spallHandler.defaultShell)
     local currentSpall                          = spallHandler.shells[#spallHandler.shells]
     currentSpall.active                         = true
     currentSpall.shellType                      = {}
     currentSpall.cannonLoc                      = spallPos
     currentSpall.point1                         = point1
     if weapon.sphere then
        currentSpall.predictedBulletVelocity = VecScale(Vec(math.random() - .5, math.random() - .5, math.random() - .5),
        rnd(weapon.jet_vel * .7, weapon.jet_vel * 1.3))
     else
        currentSpall.predictedBulletVelocity = VecScale(jet_vel, rnd(weapon.jet_vel * .7, weapon.jet_vel * 1.3)) --rndVec(math.random() * 200)
     end
     currentSpall.initial_vel               = VecCopy(currentSpall.predictedBulletVelocity)
     currentSpall.shrapnel                  = true
     currentSpall.originPos                 = spallPos
     currentSpall.maxTimeToLive             = (3 * (spallingSizeCoef + 0.2)) * (math.random(50, 100) / 100)
     currentSpall.timeToLive                = currentSpall.maxTimeToLive
     currentSpall.dispersion                = 10
     currentSpall.shellType.bulletdamage    = {}
     currentSpall.shellType.bulletdamage[1] = rnd(0.7, 1.1) * spallingSizeCoef * weapon.shrapnel_damage_low
     currentSpall.shellType.bulletdamage[2] = rnd(0.7, 1.1) * spallingSizeCoef * weapon.shrapnel_damage_med
     currentSpall.shellType.bulletdamage[3] = rnd(0.7, 1.1) * spallingSizeCoef * weapon.shrapnel_damage_hi
     currentSpall.shellType.caliber         = (weapon.shrapnel_size * spallingSizeCoef) * 0.3
     currentSpall.shellType.shellWidth      = math.min(math.random(), 0.1)
     currentSpall.shellType.shellHeight     = math.min(math.random(), 0.1)
     currentSpall.penDepth                  = 0.1
     currentSpall.hit                       = math.ceil(rnd(0,3))

     currentSpall.shellType.r               = 2 + (math.random(0, 5) / 5)
     currentSpall.shellType.g               = 1.7 + (math.random(0, 5) / 10)
     currentSpall.shellType.b               = 1 + (math.random(0, 10) / 10)


     spallHandler.shellNum = (spallHandler.shellNum % #spallHandler.shells) + 1
  end
end

function spalling_shrapnel_operations(projectile, dt)
  projectile.cannonLoc.pos = projectile.point1
  local shellHeight = projectile.shellType.shellHeight
  local shellWidth = projectile.shellType.shellWidth
  -- local spallDecay =  math.random()* (currentSpall.maxTimeToLive / currentSpall.timeToLive )
  local spallDecay = math.random()
  local r = projectile.shellType.r * spallDecay
  local g = projectile.shellType.g * spallDecay
  local b = projectile.shellType.b * spallDecay


  --- sprite drawing
  DrawSprite(spalling_sprite, projectile.cannonLoc, projectile.shellType.shellWidth, shellHeight, r, g, b, 1, 0, false)
  local altloc = TransformCopy(projectile.cannonLoc)
  altloc.rot = QuatRotateQuat(altloc.rot, QuatEuler(0, 90, 0))
  DrawSprite(spalling_sprite, altloc, projectile.shellType.shellWidth, shellHeight, r, g, b, 1, 0, false)
  altloc.rot = QuatRotateQuat(projectile.cannonLoc.rot, QuatEuler(90, 0, 0))
  DrawSprite(spalling_sprite, altloc, projectile.shellType.shellWidth, projectile.shellType.shellWidth, r, g, b, 1, 0,
  false)


  projectile.predictedBulletVelocity = VecScale(projectile.predictedBulletVelocity, 0.9)

  local dispersion = Vec(math.random(-1, 1) * projectile.dispersion, math.random(-1, 1) * projectile.dispersion,
  math.random(-1, 1) * projectile.dispersion)
  if (projectile.shellType.dispersionCoef) then
     dispersion = VecScale(dispersion, dispersionCoef)
  end
  projectile.predictedBulletVelocity = VecAdd(projectile.predictedBulletVelocity, (VecScale(dispersion, dt)))

  projectile.predictedBulletVelocity = VecAdd(projectile.predictedBulletVelocity, (VecScale(globalConfig.gravity, dt)))

  local point2 = VecAdd(projectile.point1, VecScale(projectile.predictedBulletVelocity, dt))
  local hit, dist1, norm1, shape1 = QueryRaycast(GetBodyTransform(body).pos, VecNormalize(GetBodyVelocity(body)),
  VecLength(GetBodyVelocity(body)), 0.3)


  projectile.cannonLoc.rot = QuatRotateQuat(QuatLookAt(point2, projectile.point1), QuatEuler(00, 90, 90))

  local hit_player = inflict_player_damage(projectile, point2)

  if (hit or hit_player) then
     hitPos = VecAdd(projectile.point1, VecScale(VecNormalize(VecSub(point2, projectile.point1)), dist1))
     projectile.point1 = hitPos
     spalling_pop_spalling(projectile, shape1)
  else
     projectile.point1 = point2
  end
end

function spalling_pop_spalling(shell, hitTarget)
  local holeModifier = math.random(-15, 15) / 100
  local fireChance = math.random(0, 100) / 100
  local firethreshold = 0.96

  shell.shellType.hit = math.ceil(rnd(0,3))

  if (fireChance > firethreshold) then
     SpawnFire(shell.point1)
  end
  if shell.shellType.hit and shell.shellType.hit < 3 then
     shell.shellType.bulletdamage = VecScale(shell.shellType.bulletdamage,
     VecLength(shell.predictedBulletVelocity) / VecLength(shell.initial_vel))
     if (shell.shellType.hit == 1) then
        MakeHole(shell.point1, shell.shellType.bulletdamage[1] * 1.4)
     else
        MakeHole(shell.point1, shell.shellType.bulletdamage[1] * 1.4, shell.shellType.bulletdamage[2] * 1.2)
     end
  else
     MakeHole(shell.point1, shell.shellType.bulletdamage[1] * 1.4, shell.shellType.bulletdamage[2] * 1.2,
     shell.shellType.bulletdamage[3] * 1.2)
  end
  Paint(shell.point1, shell.shellType.bulletdamage[1] * 1.8, "explosion")

  shell.active = false
  active_spall = active_spall - 1
  for key, val in ipairs(spallHandler.shells) do
   --print("weapons/guns/grenade.lua: "..key)
     val = nil
  end
  shell = deepcopy(spallHandler.defaultShell)
end

function tick_spalling(dt)
  -- DebugWatch("shells",#spallHandler.shells  )
  for key, shell in ipairs(spallHandler.shells) do
     if (shell.active) then
        if (shell.timeToLive > 0) then
           if (shell.shrapnel) then
               spalling_shrapnel_operations(shell,dt)
           else
              -- spallingOperations(shell,dt)
           end
           shell.timeToLive = shell.timeToLive - dt
        else
           shell.active = false
           active_spall = active_spall - 1
        end
     end
  end
end

--fire effects

function EmitFire(strength, t, amount, force)
  local p = t.pos
  local d = TransformToParentVec(t, Vec((math.random() - 0.5) / 10, (math.random() - 0.5) / 10, -4 - math.random()))
  local amount = 2
  local life_time = math.random() / 2

  -- print("Emitfirepos (1):"..p[1])
  -- print("Emitfirepos (2):"..p[2])
  -- print("Emitfirepos (3):"..p[3])
  -- print(strength)
  -- print(amount)
  -- print(force)

  ParticleReset()
  ParticleTile(5)
  ParticleColor(1, 1, 0.5, 1, 0, 0)
  ParticleRadius(0.1 * amount, 1 * amount)
  ParticleEmissive(10, 0)
  ParticleDrag(0.1)
  ParticleCollide(0, 1, "constant", 0.6)
  ParticleGravity(math.random() * 1)
  PointLight(p, 1, 0.8, 0.2, 2 * amount)
  for i = 1, 10 do
     SpawnParticle(p, VecScale(d, 12 * force), 0.5 * (life_time * 3))
  end

  ParticleReset()
  ParticleTile(0)
  ParticleColor(1, 1, 0.5, 1, 0, 0)
  ParticleRadius(0.1 * amount, 1 * amount)
  ParticleEmissive(10, 0)
  ParticleDrag(0.1)
  ParticleCollide(0, 1, "constant", 0.6)
  ParticleGravity(math.random() * 1)
  PointLight(p, 1, 0.8, 0.2, 2 * amount)
  for i = 1, 10 do
     SpawnParticle(p, VecScale(Vec(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5), math.random() * 4),
     math.random() * 0.3)
  end

  ParticleReset()
  ParticleTile(4)
  ParticleColor(1, 1, 0.5, 1, 0, 0)
  ParticleAlpha(0.5, 0)
  ParticleRadius(0.025, 0.025)
  ParticleEmissive(10, 0)
  ParticleDrag(0.1)
  ParticleCollide(0, 1, "constant", 0.6)
  ParticleGravity(math.random() * 1)
  PointLight(p, 1, 0.8, 0.2, 2 * amount)
  for i = 1, 40 do
     SpawnParticle(p, VecScale(Vec(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5), math.random() * 30),
     math.random() * 3)
  end
  ParticleTile(1)
  for i = 1, 30 do
     SpawnParticle(p, VecScale(d, 40 * force), math.random() * 2)
  end

  ParticleReset()
  ParticleTile(0)
  ParticleColor(1, 1, 0.5, 1, 0, 0)
  ParticleRadius(0.5, 2)
  ParticleEmissive(10, 0)
  ParticleDrag(0.1)
  ParticleCollide(0, 1, "constant", 0.6)
  ParticleGravity(math.random() * 1)
  PointLight(p, 1, 0.8, 0.2, 2 * amount)
  for i = 1, 5 do
     SpawnParticle(p, VecScale(Vec(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5), math.random()),
     math.random())
  end


  if amount > 0.0 then
     --Hurt player
     local toPlayer = VecSub(GetPlayerCameraTransform().pos, t.pos)
     local distToPlayer = VecLength(toPlayer)
     local distScale = clamp(1.0 - distToPlayer / 5.0, 0.0, 1.0)
     -- DebugWatch("dist scale",distScale)
     if distScale > 0 then
        toPlayer = VecNormalize(toPlayer)
        -- DebugWatch("toplayer ",toPlayer)

        -- DebugWatch("d",d)
        -- DebugWatch("dot prod",VecDot(d, toPlayer))
        if VecDot(d, toPlayer) > 0.8 or distToPlayer < 0.5 then
           local hit = QueryRaycast(p, toPlayer, distToPlayer)
           if not hit or distToPlayer < 0.5 then
              -- SetPlayerHealth(GetPlayerHealth() - 0.015 * strength * amount * distScale)
           end
        end
     end
  end
end

function inflict_player_damage(projectile, point2)
  -- local t= Transform(projectile.point1,QuatLookAt(point2,projectile.point1))
  -- local p = TransformToParentPoint(t, Vec(0, 0, 1))
  -- local p2 = TransformToParentPoint(t, Vec(0, 0, 2))

  -- local d = VecNormalize(VecSub(projectile.point1,point2))

  -- hurt_dist = VecLength(VecSub(projectile.point1,point2))
  -- --Hurt player
  -- local player_cam_pos = GetPlayerCameraTransform().pos
  -- local player_pos = GetPlayerTransform().pos

  -- player_pos = VecLerp(player_pos,player_cam_pos,0.5)
  -- local toPlayer = VecSub(player_pos, t.pos)
  -- local distToPlayer = VecLength(toPlayer)
  -- local distScale = clamp(1.0 - distToPlayer / hurt_dist, 0.0, 1.0)
  -- -- DebugWatch("test",distScale)
  -- if distScale > 0 then
  --   -- DebugWatch("dist scale",distScale)
  --   toPlayer = VecNormalize(toPlayer)
  --   -- DebugWatch("dot to player",VecDot(d, toPlayer))
  --     -- DebugWatch("distToPlayer",distToPlayer)
  --   if VecDot(d, toPlayer) > 0.9 or distToPlayer < 1 then
  --     -- DebugWatch("player dist scale",distScale)
  --     -- DebugWatch("distToPlayer",distToPlayer)
  --     local hit = QueryRaycast(p, toPlayer, distToPlayer)
  --     if not hit or distToPlayer < 0.7 then
  --       -- DebugWatch("player would be hit",distToPlayer)
  --       -- SetPlayerHealth(GetPlayerHealth() - 0.035 * (projectile.shellType.bulletdamage[1] * (distScale*2)*25)*math.log(VecLength(projectile.predictedBulletVelocity)))
  --       return true
  --     end
  --   end
  -- end
  -- return false
end

-- (v2) distance from pos to the nearest player (feet + up metres)
function NearestPlayerDist(pos, up)
  local d = math.huge
  for p in Players() do
    d = math.min(d, VecLength(VecSub(VecAdd(GetPlayerTransform(p).pos, Vec(0, up or 0, 0)), pos)))
  end
  return d
end

function clamp(val, lower, upper)
  if lower > upper then lower, upper = upper, lower end   -- swap if boundaries supplied the wrong way
  return math.max(lower, math.min(upper, val))
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
  else   -- number, string, boolean, etc
     copy = orig
  end
  return copy
end

-- (v2 fix 2026-11-07) Close-range / low-FPS impacts. v1 started all rocket logic 0.05 s after spawn (~6 m at
-- 120 m/s) and then only looked one physics step ahead of the rocket, once per frame. A target closer than that was
-- hit and the rocket had bounced off before any check ran; at low FPS it could also skip past thin targets. Here,
-- every tick, a ray from the previous position along the previous flight direction (as far as the rocket could have
-- flown) finds what it ran into, even if physics already bounced it back; that arms the warhead and detonates.
local RocketTickV1 = server.tick
function server.tick(dt)
  if not exploded and body and IsHandleValid(body) then
    if RocketLastPos and RocketLastSpeed > 10 then
      for index, shape in ipairs(shapes) do QueryRejectShape(shape) end
      QueryRejectBody(body)
      local hit, dist, normal, shape = QueryRaycast(RocketLastPos, RocketLastDir,
        RocketLastSpeed * math.max(dt, GetTimeStep()) * 1.2 + 0.3, 0.2)
      if hit then
        ForceImpact = true
        primed = true
        warhead_primed = true
        ImpactPos = VecAdd(RocketLastPos, VecScale(RocketLastDir, dist))
        ImpactShape = shape
      end
    end
  end
  RocketTickV1(dt)
  if not exploded and body and IsHandleValid(body) then
    local v = GetBodyVelocity(body)
    RocketLastPos, RocketLastSpeed = GetBodyTransform(body).pos, VecLength(v)
    RocketLastDir = RocketLastSpeed > 0 and VecScale(v, 1 / RocketLastSpeed) or Vec(0, 0, 1)
  end
end

NPC_Guns = {} -- All gun objects.



function init_gun_data()

    Reg_GunIds = "level.npcs.gunIDs."

    -- GunAccuracies = {
    --     [GUN_CLASSES.sniper] = 1
    -- }

end


--- Create a gun object from an existing spawned gun body in the scene. This funtion does not require an npc.
function npc_gun_create(npc, Gun_Prefab, gunBody, entities)

    -- Gun ID
    local id = GetInt(Reg_GunIds) + 1
    SetInt(Reg_GunIds, id)


    -- Gun object
    local gun = { id = id }


    --> entities
        local gunShapes = GetBodyShapes(gunBody)
        local barrel    = ExtractEntityByTag(gunShapes, "barrel")
        local handle    = ExtractEntityByTag(entities, "handle")


    --> properties
        local hasLight  = ternary(npc.nvg, FindLight("gunlight"))
        local isRPG     = Gun_Prefab.class == GUN_CLASSES.rpg


    --> shooting
        local damage      = clamp(tonumber(GetTagValue(barrel, "damage")), 3, math.huge)
        local velocity    = 300 -- Backup/default value.
        local rpm         = (tonumber(GetTagValue(barrel, "firerate")) or 0.5) / 0.016666666666667
        local gunToolId   = GetTagValue(barrel, "gun")
        local roundSize   = tonumber(GetTagValue(barrel, "roundsize"))
        local spread      = 0.02
        local range       = tonumber(GetTagValue(barrel, "range"))

        -- Set velocity.
        if     isRPG            then velocity = 100
        elseif roundSize == 1   then velocity = 310
        elseif roundSize == 2   then velocity = 800
        elseif roundSize >  2   then velocity = 750
        else                         velocity = 500
        end


    --> magazine
        local capacity  = tonumber(GetTagValue(npc.barrel, "magsize"))
        local rounds    = capacity


    --> timers
        local timer_reload  = TimerCreate(3, true)
        local timer_shoot   = TimerCreateRPM(rpm, true)



    gun.entities = {
        barrel  = barrel, -- shape
        body    = gunBody, -- A gun should be in a single body.
        lights  = { handle = handle, }, -- handle is a light entity used as a relative position, not for illumination.
        shapes  = gunShapes,
    }

    gun.properties = {
        limb     = nil,
        owner    = npc, -- NPC which owns the gun. Owner is set when given to an npc or set to nil if it has been dropped.
        sprite   = nil, -- Projectile sprite. Generic line the length of the velocity is used if none set.
        class    = Gun_Prefab.class,
        hasLight = hasLight,
    }

    gun.shooting = {
        damage      = damage,
        holeSize    = 0.1,
        rpm         = rpm,
        spread      = spread,
        velocity    = velocity,
        range       = range,
    }

    gun.magazine = {
        rounds      = rounds,
        capacity    = capacity,
    }

    gun.timers = {
        reload  = timer_reload,
        shoot   = timer_shoot,
    }

    gun.sounds = {
        shots = {
            close   = { LoadSound("MOD/assets/snd/" .. GetTagValue(npc.barrel, "gun") .. ".ogg") },
            far     = { LoadSound("MOD/assets/snd/" .. GetTagValue(npc.barrel, "gun") .. "dist.ogg") },
        },
        reload = nil,
    }

    gun.status = {
        isReloading = false,
        isShooting  = false,
        isShotReady = false,
    }


    SetTag(gunBody, "unbreakable")
    SetTag(gunBody, "nocull")
    SetTag(gunBody, "gore_id")
    -- table.insert(npc.AllBodies, gunBody) --todo move to npc init


    return gun

end
--- Manage a specific gun. NPCs can have multiple guns. They can dual wield or have a sling + holster.
function npc_gun_operate(npc, gun)

    local gunTr = GetBodyTransform(gun.body)

    -- Shoot conditions.
    local isMagEmpty    = gun.magazine.rounds <= 0
    local isShooting    = npc.ai.shooting
    local canShoot      = npc.ai.thinking.attacking.canShootAimPos and not isMagEmpty
    local shouldShoot   = canShoot and isShooting
    gun.status.isShotReady = TimerConsumed(gun.timers.shoot)


    -- Initiate reload.
    if isMagEmpty and not gun.status.isReloading then
        npc_gun_reload_initiate(npc, gun)
    end


    if gun.status.isReloading then -- Reload gun on a timer.

        TimerRunTime(gun.timers.reload)
        if TimerConsumed(gun.timers.reload) then
            npc_gun_reload(npc, gun)
        end

    else -- Shoot gun

        if shouldShoot then npc_gun_shoot(gun, gunTr) end
        TimerRunTime(gun.timers.shoot)

    end

end


--- Manage the automatic shooting of the gun. Returns the state of the gun.
function npc_gun_fire()
end
--- Decides which projectiles to create.
function npc_gun_shoot(npc, gun, gunTr)

    local isShotgun = gun.properties.class == GUN_CLASSES.shotgun
    local isRPG     = gun.properties.class == GUN_CLASSES.rpg


    if isShotgun then -- Multiple bullets per shot.

        npc_shoot(npc, NPC_AIM_SPREAD_SHOTGUN, 6)

    elseif isRPG then -- Custom RPG projectile.

        -- rpgTr = TransformCopy(gunTr)
        -- rpgTr.pos = TransformToParentPoint(gunTr, Vec(0,-0.3, ternary(math.random() < 0.05, -3, 3))) --egg rpg npc goes flying
        -- rpgTr.rot = QuatLookAt(gunTr.pos, TransformToParentPoint(gunTr, Vec(0,0,1)))
        -- local xml = "MOD/prefabs/grenade.xml"
        -- local entities = Spawn(xml, rpgTr)
        -- local norm = VecNormalize(fwdDir)
        -- local vel = VecScale(norm,ternary(IsHardcore, 100, 60))
        -- for i=1, #entities do
        --     if GetEntityType(entities[i]) == "body" then
        --         SetBodyVelocity(entities[i], vel)
        --     end
        -- end

    else -- 1 bullet per shot.

        npc_shoot(npc)

    end

    gun.magazine.rounds = gun.magazine.rounds - 1

end
--- Creates the shot projectile.
function npc_gun_shoot_bullet(npc, gun, gunTr)


    -- -- Distance based accuracy
    -- for i = 1, bullets or 1 do

    --     local shot_spread = 0
    --     -- spread = spread*(1+npc.gunMovement*5) --decrease accuracy due to gun movement
    --     if DistanceProgressed > 0 then
    --         local distProgressed = clamp(DistanceProgressed, 1, DistanceProgressed)
    --         local spread_dist = distProgressed / NPC_DIST_BASED_ACCURACY

    --         -- spread = 1 - clamp(spread_dist, 0, 0.5) -- Increase accuracy as distance progresses.
    --         local disttoplayer = VecLength(VecSub(GetPlayerTransform().pos, gunTr.pos))
    --         shot_spread = 1 + disttoplayer/100
    --     end

    -- end


    local fwdDir = TransformToParentVec(gunTr, Vec(0,0,-1))

    fwdDir[1] = fwdDir[1] + ((math.random() - 0.5) * npc.Accuracy)
    fwdDir[2] = fwdDir[2] + ((math.random() - 0.5) * npc.Accuracy)
    fwdDir[3] = fwdDir[3] + ((math.random() - 0.5) * npc.Accuracy)
    fwdDir = VecAdd(fwdDir, VecScale(Vec(math.random()-0.5,math.random()-0.5,math.random()-0.5), spread))


    --todo remove projectilehandler
    -- npc.projectileHandler.shells[npc.projectileHandler.shellNum] = DeepCopy(npc.projectileHandler.defaultShell)
    -- local shell = npc.projectileHandler.shells[npc.projectileHandler.shellNum]
    -- shell.active                   = true
    -- shell.time                     = 0
    -- shell.pos                      = gunTr.pos
    -- shell.momentum                 = npc.maxMomentum
    -- shell.predictedBulletVelocity  = VecScale(fwdDir, npc.velocity)
    -- npc.projectileHandler.shellNum = (npc.projectileHandler.shellNum % #npc.projectileHandler.shells) + 1



    projectile_create(
        gunTr,
        Projectiles,
        ProjectilePresets.bullets.standard,
        npc.AllBodies)



    -- --todo Supressed guns have no particles.
    -- ParticleReset()
    -- ParticleColor(1, 0.6, 0.4, 0.1, 0.1, 0.1, "linear", 0, 0.5)
    -- ParticleEmissive(2, 0, "linear", 0, 0.5)
    -- ParticleRadius(0.02)
    -- ParticleCollide(1)
    -- ParticleAlpha(1.0, 0.0)
    -- ParticleCollide(1)
    -- ParticleGravity(-4)
    -- ParticleStretch(1)
    -- ParticleDrag(0)
    -- for i = 1, 4 do
    --     SpawnParticle(gunTr.pos, Vec(math.random(-2, 2), math.random(-2, 2), math.random(-2, 2)), 1 )
    -- end
    -- PointLight(gunTr.pos, 1, 0.35, 0.1, math.random(10, 15))

    -- PlaySound(npc.sounds.gunshot, gunTr.pos, 2)
    -- local disttoplayer = VecLength(VecSub(GetPlayerTransform().pos, gunTr.pos))
    -- if disttoplayer > 4 then
    --     PlaySound(npc.sounds.DistGunShot, GetPlayerTransform().pos, disttoplayer/10)
    -- end

end


--- Fill the actual magazine.
function npc_gun_reload(npc, gun)
    gun.magazine.rounds     = gun.magazine.capacity
    gun.status.isReloading  = false
end
--- Set the condition to reload.
function npc_gun_reload_initiate(npc, gun)
    gun.magazine.rounds     = 0
    gun.status.isReloading  = true
    TimerResetTime(gun.timers.reload)
end


--- Give an existing gun to an npc by associating it to a specific limb.
function npc_gun_give(npc, gun, limb)

    for _, shape in ipairs(gun.entities.shapes) do SetShapeCollisionFilter(shape, 0) end
    SetTag(gun.entities.body, "interact")

end
--- Transfer a gun from an npc to another npc.
function npc_gun_transfer(npc, gun, to_npc, to_limb)
    --todo
end


--- Dissasociate a gun from an npc. This does not delete the gun entity.
function npc_gun_drop(npc, gun)

    for _, shape in ipairs(gun.entities.shapes) do SetShapeCollisionFilter(shape, 1) end
    RemoveTag(gun.entities.body, "interact")

end
--- Deletes the gun object but keeps the entity in the scene.
function npc_gun_remove(npc, gun)
end
--- Deletes the gun entity in the scene.
function npc_gun_delete(npc, gun)
    Delete(gun.entities.body)
end


--- Completely dissasociate a gun from an npc.
function npc_gun_clear_associations()
end

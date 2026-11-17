NPC_HIT_CHANCE = 1
NPC_AIM_SWAY_MULT = 1.5 -- Aim sway intensity.
NPC_AIM_SWAY_SPEED = 0.3 -- How often the aim sway changes to a new offset vec.
NPC_AIM_SWAY_CENTER_FOCUS = 0.3 -- How often the aim sway centers. Helps with consistency.

-- Use what's inbetween min and max as the new dist range. Prevents extreme flailing around of gun.
NPC_AIM_SWAY_DIST_MIN = 5 -- Clamp the lower part of the full range.
NPC_AIM_SWAY_DIST_MAX = 70 -- Clamp the upper part of the full range. --todo use for smgs vs snipers


-- (2026-11-15, user OK) NPC gun sounds are "MOD/assets/snd/<gun tag>.ogg" / "<gun tag>dist.ogg". For the tags
-- g17 (pistols, 79 gun prefabs) and m4 (MK36 rifles, 31) those files never existed, so those NPCs shot silently
-- (original-mod bug). These point them at the mod's own sounds; m4 has no distant sound (stays as before).
GOREAI_GUN_SHOT = {
    g17 = "MOD/assets/snd/Weapons/g17/g17.ogg",
    m4  = "MOD/assets/snd/Weapons/m4a1/m4a1_0.ogg",
}
GOREAI_GUN_DIST = {
    g17 = "MOD/assets/snd/Weapons/g17/g17dist.ogg",
}

NPC_AIM_SPREAD_SHOTGUN = 0.2 -- Shotgun barrel spread.
NPC_TARGET_HIT_DIST = 1.3 -- Dist from aimpos to shootPosOffset. Checks if bullet will hit near player.
NPC_AIM_MIN_ALIGN = 0.4 -- Linked to npc.aim.torso

NPC_SNIPER_FLASH_TIME = 0.2 -- Flash just before the shot it taken, based on the gun shoot timer.
NPC_SNIPER_FLASH_CHANCE = 1/6 -- Don't show the flash for every shot.


-- Scale gun sway amount based on distance. Gets very hard late game.
NPC_DIST_BASED_ACCURACY_RANGE = {
    { 3000,     1.00 },
    { 5000,     0.98 },
    { 10000,    0.96 },
    { 15000,    0.93 },
    { 20000,    0.89 },
    { 30000,    0.85 },
}
NPC_DIST_BASED_ACCURACY_SCALE = 1 -- Npcs get more accurate based on distance travelled.



Debug_hitPositions_shapes = {}


function tick_combat()

    for index, range in ipairs(NPC_DIST_BASED_ACCURACY_RANGE) do
        if DistanceProgressed < range[1] then
            NPC_DIST_BASED_ACCURACY_SCALE = range[2]
            break
        end
    end

    if DistanceProgressed > NPC_DIST_BASED_ACCURACY_RANGE[#NPC_DIST_BASED_ACCURACY_RANGE][1] then
        NPC_DIST_BASED_ACCURACY_SCALE = NPC_DIST_BASED_ACCURACY_RANGE[#NPC_DIST_BASED_ACCURACY_RANGE][2]
    end

end

function npc_init_gun(npc)
    npc_init_gun_entity(npc)
    npc_init_projectile_system(npc)
    npc_init_weapon_properties(npc)
end

function npc_init_weapon_properties(npc)

    -- Projectile
        npc.damage = 0.15
        npc.velocity = 50

        local rs=tonumber(GetTagValue(npc.barrel, "roundsize"))or 2
        local gun=GetTagValue(npc.barrel, "gun")
        if gun=="rpg"then
            npc.velocity = 65
        elseif rs==1 then
            npc.velocity = 310
            npc.mat_holes = { 0.15, 0.15, 0}
        elseif rs==2 then
            npc.velocity = 900
            npc.mat_holes = { 0.15, 0.15, 0}
        elseif rs>2 then
            npc.velocity = 850
            npc.mat_holes = { 0.2, 0.15, 0 }
        end
        npc.maxMomentum = 1.2
        if rs==2 then
            npc.maxMomentum = 3
        elseif rs>2 then
            npc.maxMomentum = 5
        end
        npc.gravity = Vec(0, 0, 0)

        if not GetString("savegame.mod.difficulty") ~= "hardcore" then
            npc.velocity = npc.velocity / 2
        end


    -- Reloading
        npc.ShootTimer = 0
        npc.ShootTimMax = 0.5
        npc.reloadtim = 0
        npc.reloading = false
        npc.maxreloadtim = RandomSpreadPercent25(1.5)
        npc.BulletsShot = 0
        npc.oldbulletsshot = 0


    -- Barrel shape tags:
        npc.barrel = npc.BarrelShape
        npc.MagSize = tonumber(GetTagValue(npc.barrel, "magsize"))
        npc.burstsize = math.random(1, math.ceil(npc.MagSize/2))
        npc.maxrange = tonumber(GetTagValue(npc.barrel, "range"))
        npc.pdamage = clamp(tonumber(GetTagValue(npc.barrel, "damage")), 3, math.huge)
        npc.roundsize = rs
        npc.firerate = tonumber(GetTagValue(npc.barrel, "firerate")) or 0.1


        npc.exp = tonumber(GetTagValue(npc.barrel, "exp"))
        npc.expgrav = tonumber(GetTagValue(npc.barrel, "expgrav"))
        for i=1, 150 do
            npc.projectileHandler.shells[i] = DeepCopy(npc.projectileHandler.defaultShell)
        end
        -- npc.stealth = ternary(HasTag(npc.barrel, "stealth"), true, false)


        if npc.exp then
            npc.rpg = true
            npc.gravity = Vec(0, -npc.expgrav, 0)
            npc.maxreloadtim = RandomSpreadPercent25(7)
        end


    -- Shotgun
        npc.shotgun = HasTag(npc.barrel, "shotgun")
        if npc.shotgun then
            npc.firerate = 0.0
            npc.magsize = 1
            npc.maxreloadtim = 2
        end

    -- Snipers
        if npc.Gun.class == GUN_CLASSES.sniper then
            npc.magsize = 1
            npc.maxreloadtim = 2.5
            npc.burstsize = 1
        end


    -- Weapon sounds
        npc.sounds = {}
        npc.sounds.rpghit = LoadSound("MOD/assets/snd/rpghit.ogg")
        npc.sounds.rpghitdist = LoadSound("MOD/assets/snd/rpghitdist.ogg")
        local gunTag = GetTagValue(npc.barrel, "gun")
        local shotPath = GOREAI_GUN_SHOT[gunTag] or ("MOD/assets/snd/"..gunTag..".ogg")
        local distPath = GOREAI_GUN_DIST[gunTag] or ("MOD/assets/snd/"..gunTag.."dist.ogg")
        npc.sounds.gunshot = LoadSound(shotPath)
        npc.sounds.rpgGunshot = LoadSound(distPath)
        npc.sounds.DistGunShot = LoadSound(distPath)
        -- npc.shoot = LoadSound("MOD/assets/snd/"..GetTagValue(npc.barrel, "gun")..".ogg")


    -- NPC shooting properties
        -- npc.Accuracy = 0.075/(npc.roundsize^0.6)
        -- if GetString("savegame.mod.difficulty") == "hardcore" then
        --     npc.Accuracy = npc.Accuracy*0.75
        -- end
        npc.AimForHead = 0
        npc.ReactionTim = 2
        npc.Maxreactiontim = npc.ReactionTim
        npc.MaxChanceForHeadshot = 10


        -- if GetString("savegame.mod.difficulty") == "normal" then
        --     npc.Accuracy = npc.Accuracy * 2
        --     npc.pdamage = npc.pdamage * 0.5
        -- elseif GetString("savegame.mod.difficulty") == "hardcore" then
        --     npc.Accuracy = npc.Accuracy * 3
        --     npc.pdamage = npc.pdamage * 1
        -- end
        -- if GetString("savegame.mod.difficulty") == "normal" then
            -- npc.Accuracy = 0.15
        -- elseif GetString("savegame.mod.difficulty") == "hardcore" then
            npc.Accuracy = 0.03
        -- end


    -- Held gun
        npc.Loot = GetShapeBody(npc.barrel)
        npc.enemyweapontag = GetTagValue(npc.Loot, "interact")
        RemoveTag(npc.Loot, "interact")


    -- Head
        npc.HCheck = 0 --?
        npc.HS = LoadSound("MOD/assets/snd/headshot.ogg") --?


    -- Night vision
        if HasTag(npc.barrel, "nvg") then
            npc.nvg = true
        else
            npc.nvg = false
            npc.Light = FindLight("gunlight")
        end

end

function npc_init_projectile_system(npc)

    npc.projectileHandler = {
        shellNum = 1,
        shells = {},
        defaultShell = {active = false}
    }

    npc.casing = {
        amount = 1,
        shells = {},
        defaultShell = {
            active = false,
            time = 0,
            grenadeTimer = 0,
            boomTimer = 0,
            bounces = 0,
            pos = Vec(0,0,0),
            type = "casing",
            crot = 0
        }
    }

end

function npc_init_gun_entity(npc)

    -- Declare gun variables.
    npc.BarrelShape = nil


    local class = GetRandomArrayValue(GetRandomArrayValue({GUN_PREFABS, GunClassUnlocks})) -- Get a gun class that is unlocked based on distance.
    if npc.ai.spawnTags.ranged then -- Select specific classes based on spawn tags.
        class = GetRandomArrayValue({ GUN_CLASSES.sniper, GUN_CLASSES.sniper, GUN_CLASSES.sniper, GUN_CLASSES.rpg })
    elseif npc.ai.spawnTags.outside then
        class = GetRandomArrayValue({ GUN_CLASSES.smg,GUN_CLASSES.smg,GUN_CLASSES.smg, GUN_CLASSES.shotgun })
    end
    class = DeepCopy(class)


    local factions = nil
    if npc.ai.teams then
        if npc.ai.teams.team ~= NPC_TEAMS.none then
            factions = GUN_FACTIONS[npc.ai.teams.team] -- Select faction based gun.
        end
    end
    if factions then -- Npcs with no team = random gun.

        --[[
            Attribute example:
            local attributes = {
                class   = GUN_CLASSES.smg,
                faction = { GUN_FACTIONS.um, GUN_FACTIONS.mil },
            }
        ]]

        local attributes = {
            class   = class,
            faction = factions,
        }

        -- If no faction specified, a random faction is automatically selected.
        npc.Gun = get_random_gun_prefab(attributes)

        if not npc.Gun then -- Last resort = random faction.
            npc.Gun = get_random_gun_prefab({
                class = GetRandomArrayValue({ GUN_CLASSES.smg, GUN_CLASSES.pistol }),
                faction = factions })
            -- print("NPC", "No specified gun prefab found. Spawning faction appropriate pistol, smg or rifle...")
        end

    end


    --> Tutorial npc spawns with pistol only.
    if npc.ai.spawnTags.tutorial then
        npc.Gun = get_random_gun_prefab({
            class = GUN_CLASSES.pistol,
            faction = GUN_FACTIONS.civ
        })
    end


    --> Increased rpg spawns if player is in an AVF vehicle.
    local isPlayerInAvf = HasTag(GetPlayerVehicle(GoreP), "cfg") and math.random() < 1/13
    local spawnRPG = isPlayerInAvf or npc.ai.spawnTags.rpg
    if spawnRPG then
        npc.Gun = get_random_gun_prefab({ faction = GUN_FACTIONS.civ, class = GUN_CLASSES.rpg })
    end


    --> Boss npc = override gun.
    if npc.boss.isBoss then npc.Gun = npc.boss.boss_preset.gun end


    if not npc.Gun then
        npc.Gun = DeepCopy(GetRandomPairsValue(GUN_PREFABS))
        print("ERROR", "No gun prefab found. Spawning random ass gun.")
    end


    --> Override
    -- npc.Gun = get_random_gun_prefab({ faction = GUN_FACTIONS.civ, class = GUN_CLASSES.rpg }) --#
    -- npc.Gun = get_random_gun_prefab({ faction = GUN_FACTIONS.mil, class = GUN_CLASSES.rifle }) --#


    --> Spawn Gun
    local entities = Spawn(LootsPath .. npc.Gun.gun_path, Transform(npc.torsoPos))
    for index, entity in ipairs(entities) do
        if GetEntityType(entity) == "body" then
            npc.Gun.body = entity
            break
        end
    end
    if not npc.Gun.body or npc.Gun.body == 0 then
        print("NPCs", "ERROR: selected gun " .. npc.Gun.gun_path .. " entity invalid.")
    end

    for _, shape in ipairs(GetBodyShapes(npc.Gun.body)) do

        SetShapeCollisionFilter(shape, 4, 255-4)

        local lights = GetShapeLights(shape)
        for _, light in ipairs(lights) do
            if HasTag(light, "handle") then
                npc.Gun.handle = light
            end
        end

        if HasTag(shape, "barrel") then
            npc.BarrelShape = shape
            npc.shotDelay = tonumber(GetTagValue(npc.barrel, "firerate"))
        else
            npc.shotDelay = 1
        end

    end

    npc.hands = {}
    local hand_bodies = { left = npc.L_ARM, right = npc.R_ARM }

    for key, body in pairs(hand_bodies) do

        local armShape = GetBodyShapes(body)[1]
        local armTr = GetShapeWorldTransform(armShape)
        local handPos = AabbGetShapeCenterBottomPos(armShape)
        SetShapeCollisionFilter(armShape, 4, 255-4)

        npc.hands[key] = {
            body = body,
            shape = armShape,
            body_local_pos = TransformToLocalPoint(armTr, handPos)
        }

    end


    local handleTr = ternary(npc.Gun.handle, GetLightTransform(npc.Gun.handle), GetBodyTransform(npc.Gun.body))
    local gunTr = GetBodyTransform(npc.Gun.body)
    gunTr.pos = VecAdd(gunTr.pos,  VecSub(gunTr.pos, handleTr.pos))
    gunTr.pos = VecAdd(gunTr.pos, Vec(0,0,0))


    -- Adjust for handle
    SetBodyTransform(npc.Gun.body, gunTr)

    SetTag(npc.Gun.body, "unbreakable")
    SetTag(npc.Gun.body, "nocull")
    SetTag(npc.Gun.body, "gore_id")

    table.insert(npc.AllBodies, npc.Gun.body)

    npc.Gun = DeepCopy(npc.Gun) --todo find out why npc.Gun is being shared (probabl has to do with get_random_gun_prefab)

end

function npc_init_gun_sway(npc)

    npc.aim = {
        torso = 0,
        gun = 0,
    }

    npc.recoil = 0

    npc.sway = {
        vec   = Vec(),
        tr    = Transform(),
        sos   = {
            x = AutoCreateSOS(0, 0.93, 0.94, 0.17),
            y = AutoCreateSOS(0, 0.93, 0.94, 0.17),
            z = AutoCreateSOS(0, 0.93, 0.94, 0.17),
        },
        timer = TimerCreateSeconds(0.5),
        mult = 1
    }

    if NPC_TEAMS[npc.ai.teams.team] == NPC_TEAMS.mil or NPC_TEAMS[npc.ai.teams.team] == NPC_TEAMS.um then
        npc.sway.mult = 0.8
    end

end


function npc_manage_gun(npc, dt)
    if npc.Gun then

        -- if VecDist(npc.torsoPos, GetBodyTransform(npc.Gun.body).pos) < 10 and GetTime() then

            SetTag(npc.Gun.body, "unbreakable")
            npc_manage_shooting(npc, dt)

        --     Delete(npc.Gun.body)
        --     npc_init_gun(npc)
        --     print("npc has no gun/wrong npc using it. resetting npc gun.")

        -- elseif not IsHandleValid(npc.Gun.body) then

        --     Delete(npc.Gun.body)
        --     npc_init_gun(npc)
        --     print("npc gun entity does not exist. resetting npc gun.")

        -- end

    end
end

function npc_hold_gun(npc) --- Constrain npc gun position to hand

    local handleTr = GetLightTransform(npc.Gun.handle)
    -- (2026-11-17, performance) removed an unused gunTr (GetBodyTransform + VecAdd + VecSub per update)

    ConstrainPosition(npc.Gun.body, 0, handleTr.pos, npc_get_hand_pos(npc.hands.right))

end

function npc_release_gun(npc)
    --todo completely wipe gun stuff from npc so a new one can be spawned.

    if npc.Gun then

        for _, shape in ipairs(GetBodyShapes(npc.Gun.body)) do

            SetShapeCollisionFilter(shape, 1, 255)

            local lights = GetShapeLights(shape)
            for _, light in ipairs(lights) do
                if HasTag(light, "handle") then
                    npc.Gun.handle = light
                end
            end

            if HasTag(shape, "barrel") then
                npc.BarrelShape = shape
            end

        end
		SetTag(npc.Gun.body, "interact", npc.enemyweapontag)
	end
end

function npc_point_gun(npc)

    if npc.Gun then
        if not IsHandleValid(npc.Gun.body) then
            return
        end
    else
        return
    end

    -- (2026-11-17, performance) the torso transform read once (was 3x in the same step); unused l_armTr removed
    local r_armTr           = GetBodyTransform(npc.R_ARM)
    local r_upper_armTr     = GetBodyTransform(npc.RR_ARM)
    local gunTr             = GetBodyTransform(npc.Gun.body)
    local torsoTr           = GetBodyTransform(npc.Torso)
    local torsoFwdPos       = TransformToParentPoint(torsoTr, Vec(0, 0, -100))

    local shoulderPos               = TransformToParentPoint(torsoTr, Vec(0.3, 0.6, 0.1))
    local hipPos                    = TransformToParentPoint(torsoTr, Vec(0.3, 0, -0.2))
    local rightHandShootAlignedPos  = VecAdd(VecScale(DirLookAt(shoulderPos, npc.ai.shootPosOffset), 0.5), shoulderPos)


    if GetBool("savegame.mod.config.goreai.draw_combat") then
        DrawDot(shoulderPos,              1/15, 1/15, 1,1,1,1, false)
        DrawDot(hipPos,                   1/15, 1/15, 1,1,0,1, false)
        DrawDot(rightHandShootAlignedPos, 1/15, 1/15, 0,1,0,1, false)
    end


    local align = nil
    if npc.aim then
        if npc.aim.torso then
            align = npc.aim.torso
        end
    end


    -- Process sway pos.
    local shootPos = VecCopy(npc.ai.shootPos) --todo make orbit start at zero and scale up
    local dist = math.log(clamp(VecDist(gunTr.pos, shootPos), 0, math.huge))
    if align then

        align = clamp(dist, Controls.distmin.value, Controls.distmax.value) / (clamp(align, 0.4, 1)) ^ 1.5

        local swayVec = Vec(npc.sway.sos.x.value, npc.sway.sos.y.value, npc.sway.sos.z.value)

        -- running means more sway.
        if npc.running then
            swayVec = VecScale(swayVec, clamp(VecLength(GetBodyVelocity(npc.Torso)), 1, 2))
        end

        if npc.ai.targeting.target then
            if npc.ai.targeting.target.type ~= TargetTypes.player then

                if GetPlayerVehicle(GoreP) == 0 then
                    -- player velocity offset
                    local velScale = AutoMap(VecLength(GetPlayerVelocity(GoreP)), 0, 4, 1, 1.2)
                    swayVec = VecScale(swayVec, velScale)
                end

            end
        end


        -- close range sway reduction
        local dist = VecDist(npc.ai.shootPos, gunTr.pos)
        if dist < 20 then
            local distScale = AutoMap(dist, 5, 20, 0.4, 1)
            swayVec = VecScale(swayVec, distScale)
        end

        if npc.ai.teams.team == NPC_TEAMS.civ.title then
            swayVec = VecScale(swayVec, 1.2)
        end

        swayVec = VecScale(swayVec, NPC_DIST_BASED_ACCURACY_SCALE)

        -- if npc.Gun.class == GUN_CLASSES.rpg then
        --     swayVec = VecScale(swayVec, 0.5)
        -- end

        shootPos = VecAdd(npc.ai.shootPos, swayVec)
        npc.ai.shootPosOffset = shootPos

    end


    if IsControllerNPC(npc) or npc.ai.thinking.attacking.canShootAimPos then

        ConstrainOrientation(npc.Gun.body, 0, gunTr.rot, QuatLookAt(npc.ai.shootPosOffset, gunTr.pos), 10) --! fix gun xml orientation.
        -- ConstrainAngularVelocity(npc.Gun.body, 0, QuatLookAt(npc.ai.shootPosOffset, gunTr.pos), 1) --! fix gun xml orientation.

        ConstrainOrientation(npc.R_ARM, 0, r_armTr.rot, QuatLookAt(r_armTr.pos, rightHandShootAlignedPos))
        -- ConstrainAngularVelocity(npc.R_ARM, 0, QuatLookAt(r_armTr.pos, rightHandShootAlignedPos), 1)

        ConstrainOrientation(npc.RR_ARM, 0, r_upper_armTr.rot, QuatLookAt(r_upper_armTr.pos, rightHandShootAlignedPos), 10)
        -- ConstrainAngularVelocity(npc.RR_ARM, 0, QuatLookAt(r_upper_armTr.pos, rightHandShootAlignedPos), 1)

        ConstrainPosition(npc.R_ARM, npc.Torso, r_armTr.pos, rightHandShootAlignedPos, 3 * npc.proficiency)

    else

        ConstrainOrientation(npc.Gun.body, 0, gunTr.rot, QuatLookAt(torsoFwdPos, gunTr.pos), 10)
        -- ConstrainAngularVelocity(npc.Gun.body, 0, QuatLookAt(torsoFwdPos, gunTr.pos), 1)

        ConstrainOrientation(npc.R_ARM, 0, r_armTr.rot, npc.torsoTr.rot, 10)
        ConstrainPosition(npc.R_ARM, npc.Torso, r_armTr.pos, hipPos, 10)

    end

end



function npc_manage_shooting(npc, dt, override_shoot)

    local gunTr = GetBodyTransform(npc.Gun.body)
    local shootPos = TransformToParentPoint(gunTr, Vec(0,0,1))

    -- DrawDot(shootPos, 0.2, 0.2, 1,1,0, 1)

    if npc.reloading then
        npc.reloadtim = npc.reloadtim + GetTimeStep()
        if npc.reloadtim > npc.maxreloadtim then
            npc.reloading = false
            npc.reloadtim = 0
            npc.BulletsShot = 0
        end
    end

    local BurstSize = math.random(1, math.random(3, math.random(4,7)))

    -- local BurstSize = math.random(1, clamp(npc.MagSize/3, 1, 10))
    -- if npc.Gun then
    --     if npc.Gun.class == GUN_CLASSES.rifle then
    --         BurstSize = clamp(math.ceil(BurstSize / 2), 1, math.huge)
    --     end
    -- end

    if override_shoot then BurstSize = npc.MagSize end

    -- Sniper shoots 1 bullet at a time.
    if npc.Gun then
        if npc.Gun.class == GUN_CLASSES.sniper then
            BurstSize = 1
        end
    end

    RandomReload = RandomReload or BurstSize
    if not IsControllerNPC(npc) and npc.BulletsShot > RandomReload then
        npc.reloading = true
        RandomReload = nil
    end

    if override_shoot or (npc.ai.thinking.attacking.canShootAimPos and npc.ai.shooting) then

        local canShoot = npc.ai.shooting
            and npc.ai.config.attack
            and not npc.reloading
            and not npc.ai.thinking.attacking.blocked
            and npc.ShootTimer > npc.firerate
            and npc.aim.torso > NPC_AIM_MIN_ALIGN

        if override_shoot then
            canShoot = not npc.reloading and npc.ShootTimer > npc.firerate
        end

        if canShoot then

            local safeDist = VecDist(npc.ai.aimPos, npc.ai.shootPosOffset)
            local mult = 1 + (VecDist(npc.ai.torsoPos, npc.ai.aimPos)/100)

            local hitchance = Controls.hitchance.value
            if GoreAI_PlayerHealth(GoreP) < 175 then -- (v2 goreai) target player's limb health (v1: level.player.health)
                hitchance = hitchance / 2
            end

            if npc.ai.targeting.target then -- Reduce hit chance for players.
                if npc.ai.targeting.target.type ~= TargetTypes.player then
                    hitchance = hitchance * 3
                end
            end

            local willHitTarget = safeDist < NPC_TARGET_HIT_DIST
            local shouldHitTarget = willHitTarget and math.random() < hitchance
            local rareShot = math.random() < 0.1


            if override_shoot or (not willHitTarget or shouldHitTarget or rareShot) then

                if not npc.shotgun then
                    npc_shoot(npc)
                else
                    npc_shoot(npc, NPC_AIM_SPREAD_SHOTGUN, 6)
                end

                npc.BulletsShot = npc.BulletsShot + 1
                if (npc.BulletsShot or 0) >= npc.MagSize then npc.reloading = true end
                npc.ShootTimer = 0

                npc.recoil = npc.recoil + npc.maxMomentum/10

            end

        end
    end

    npc.range = npc.maxrange
    if DayPhase == "Night" and not npc.nvg then
        npc.range = npc.maxrange / 2
    end
    -- hey there, you, scrolling through the dumpster fire code. how was your day?


    npc.recoil = clamp(npc.recoil - GetTimeStep(), 0, npc.maxMomentum)


    -- -- and math.random() < NPC_SNIPER_FLASH_CHANCE
    -- DebugWatchNPC(npc, "shoot timer", npc.ShootTimer)
    -- DebugWatchNPC(npc, "shoot timer max", npc.ShootTimMax)
    -- if npc.ShootTimer + 0.5 > npc.ShootTimMax then
    --     print("flash", npc.id, sfnTime())
    -- end


    npc.ShootTimer = npc.ShootTimer + GetTimeStep()

end

function npc_shoot(npc, spread, bullet_count)

    local x,y,z       = GetShapeSize(npc.Gun.body)
    local gunTr       = GetBodyTransform(npc.Gun.body)
    local fwdDir      = DirLookAt(gunTr.pos, TransformToParentPoint(gunTr, Vec(0,0,1))) --! reverse dir
    local shootPos    = TransformToParentPoint(gunTr, Vec(0,0,1))

    -- DrawDot(shootPos, 0.2, 0.2, 1,1,0,1, false)

    -- if npc.Gun then
    --     -- if npc.Gun.class == GUN_CLASSES.sniper then
    --     --     print("flashies")
    --     -- end
    -- else
    --     print("no gun?")
    -- end


    for i = 1, bullet_count or 1 do
        if npc.rpg then
            rpgTr = TransformCopy(gunTr)
            rpgTr.pos = TransformToParentPoint(gunTr, Vec(0,-0.3, ternary(math.random() < 0.05, -3, 3))) --egg rpg npc goes flying
            rpgTr.rot = QuatLookAt(gunTr.pos, TransformToParentPoint(gunTr, Vec(0,0,1)))
            local xml = "MOD/prefabs/grenade.xml"
            local entities = Spawn(xml, rpgTr)
            local norm = VecNormalize(fwdDir)
            local vel = VecScale(norm,ternary(IsHardcore, 100, 60))
            for i=1, #entities do
                if GetEntityType(entities[i]) == "body" then
                    SetBodyVelocity(entities[i], vel)
                end
            end
        else
            if not npc.stealth then
                ParticleColor(1, 0.6, 0.4, 0.1, 0.1, 0.1, "linear", 0, 0.5)
                ParticleEmissive(2, 0, "linear", 0, 0.5)
                ParticleRadius(0.02)
                ParticleCollide(1)
                ParticleAlpha(1.0, 0.0)
                ParticleCollide(1)
                ParticleGravity(-4)
                ParticleStretch(1)
                ParticleDrag(0)
                for i = 1, 4 do
                    SpawnParticle(
                        shootPos,
                        Vec(math.random(-2, 2), math.random(-2, 2), math.random(-2, 2)),
                        1
                    )
                end
                ParticleReset()

                PointLight(shootPos, 1, 0.35, 0.1, math.random(10, 15))
            end

            -- for i = 1, bullets or 1 do

                -- local shot_spread = 0
                -- -- spread = spread*(1+npc.gunMovement*5) --decrease accuracy due to gun movement
                -- if DistanceProgressed > 0 then
                --     local distProgressed = clamp(DistanceProgressed, 1, DistanceProgressed)
                --     local spread_dist = distProgressed / NPC_DIST_BASED_ACCURACY

                --     -- spread = 1 - clamp(spread_dist, 0, 0.5) -- Increase accuracy as distance progresses.
                --     local disttoplayer = VecLength(VecSub(GetPlayerTransform().pos, gunTr.pos))
                --     shot_spread = 1 + disttoplayer/100
                -- end

                fwdDir[1] = fwdDir[1] + ((math.random() - 0.5) * npc.Accuracy)
                fwdDir[2] = fwdDir[2] + ((math.random() - 0.5) * npc.Accuracy)
                fwdDir[3] = fwdDir[3] + ((math.random() - 0.5) * npc.Accuracy)
                fwdDir = VecAdd(fwdDir, VecScale(Vec(math.random()-0.5,math.random()-0.5,math.random()-0.5), spread))

                npc.projectileHandler.shells[npc.projectileHandler.shellNum] = DeepCopy(npc.projectileHandler.defaultShell)
                local shell = npc.projectileHandler.shells[npc.projectileHandler.shellNum]
                shell.active = true
                shell.time = 0
                shell.pos = shootPos
                shell.momentum = npc.maxMomentum
                shell.predictedBulletVelocity = VecScale(fwdDir, npc.velocity)
                npc.projectileHandler.shellNum = (npc.projectileHandler.shellNum % #npc.projectileHandler.shells) + 1

            -- end
        end
    end

    -- Distant reverb shot sounds.Fades between medium and long reverb.
    if npc.Gun then

        -- (v2 goreai) the distant-shot layer plays at every player's position (v1: the one player);
        -- the medium/far layers use the nearest player's distance.
        local disttoplayer = math.huge
        for _, p in ipairs(GorePlayerIds) do
            local camPos = GorePlayers[p].pos
            local d = VecDist(camPos, gunTr.pos) + 1
            disttoplayer = math.min(disttoplayer, d)
            PlaySound(npc.sounds.DistGunShot, camPos, AutoMap(d, 10, 30, 0, 40))
        end
        if disttoplayer == math.huge then disttoplayer = 1 end

        PlaySound(npc.sounds.gunshot, gunTr.pos, 3)

        PlaySound(GetRandomArrayValue(Sounds.guns[npc.Gun.class].med), gunTr.pos, AutoMap(disttoplayer, 0, 60, 0, 30))
        PlaySound(GetRandomArrayValue(Sounds.guns[npc.Gun.class].far), gunTr.pos, AutoMap(disttoplayer, 40, 100, 0, 100))

    end

end

function npc_projectile_operations(npc, projectile)

    if projectile.time < ternary(not npc.rpg, 4, 10) then
        projectile.time = projectile.time + GetTimeStep()
    else
        projectile.active = false
        return
    end

    local dir = VecNormalize(projectile.predictedBulletVelocity)
    local queryDist = npc.velocity * GetTimeStep()
    local projectileNextPos = VecAdd(projectile.pos, VecScale(dir, queryDist))


    RejectAllBodies(npc.AllBodies)
    if npc.Gun then QueryRejectBody(npc.Gun.body) end
    local hit, dist, normal, shape = QueryRaycast(projectile.pos, dir, queryDist, 0.1)


    local point2 = VecAdd(projectile.pos, VecScale(dir, queryDist))
    -- (v2 goreai) v1 measured the miss distance to the one player; now to every player (Ranges[p]).
    local Ranges = {}
    for _, p in ipairs(GorePlayerIds) do
        local pl = GorePlayers[p]
        local Player = pl.vehicle == 0 and VecAdd(pl.pos, Vec(0, 1, 0)) or VecCopy(pl.pos)
        local Relative = VecSub(Player, point2)
        local Lookback = VecScale(VecNormalize(VecSub(point2,projectile.pos)), VecDot(Relative, VecNormalize(VecSub(point2,projectile.pos))))
        Ranges[p] = VecLength(VecSub(Player, VecAdd(point2, Lookback)))
    end

    local RHA = 0
    if HasTag(shape, "RHA") then
        RHA = GetTagValue(shape, "RHA") or 0
    end
    projectile.momentum = projectile.momentum - RHA/4

    for _, p in ipairs(GorePlayerIds) do
        if not npc.rpg and Ranges[p] < (GorePlayers[p].vehicle == 0 and .5 or .3) and projectile.momentum ~= 0 then
            projectile.momentum = 0
            PlaySound(npc.sounds.rpgGunshot, GorePlayers[p].pos, npc.disttoplayer / 10)
        end
    end

    if npc.rpg and GetTagValue(npc.barrel, "gun") ~= "vgo" then
        npc_smoke()
        obog = projectile.pos
    end

    -- DebugPrint(VecLength(Range))
    passtype="pistol_"
    crackrange=20
    -- if npc.roundsize==2 then
    --     passtype="rifle_"
    --     crackrange=30
    -- elseif npc.roundsize>2 then
    --     passtype="sniper_"
    --     crackrange=40
    -- end
    projectile.playedb_p = projectile.playedb_p or {} -- (v2 goreai) fly-by played, per player
    for _, p in ipairs(GorePlayerIds) do
        local Range, ppos = Ranges[p], GorePlayers[p].pos
        if not projectile.playedb_p[p] and not npc.rpg and projectile.momentum ~= 0 then
            if Range < crackrange/2 then
                PlaySound(LoadSound("MOD/assets/snd/Projectiles/Flybys/"..passtype.."0.ogg"), ppos, (crackrange/2-Range)*2/crackrange)
                projectile.playedb_p[p] = true
            end
            if Range < crackrange and npc.roundsize>1 then
                PlaySound(LoadSound("MOD/assets/snd/Projectiles/Flybys/pistol_0.ogg"), ppos, (crackrange-Range)/crackrange)
                projectile.playedb_p[p] = true
            end
        end
    end

    if npc.BulletsShot > npc.oldbulletsshot then
        for _, p in ipairs(GorePlayerIds) do
            local pl = GorePlayers[p]
            PlaySound(npc.sounds.DistGunShot, pl.pos, 10/(VecDist(npc.torsoPos or pl.aimPos, pl.aimPos) + 1))
        end
        npc.oldbulletsshot = npc.BulletsShot
        projectile.playedb_p = {}
    end

    local hitPos = nil
    if hit then

        projectile.active = false

        hitPos = VecAdd(projectile.pos, VecScale(dir, dist))

        -- debug hit positions
        table.insert(Debug_hitPositions_shapes, {
            hitPos    = hitPos,
            sourcePos = projectile.pos,
            time = GetTime(),
        })

        --todo Create function: apply_npc_damage(path, damage, type)
        local damage_from_player_gun = npc.pdamage
        local hitBody = GetShapeBody(shape) -- raycast hit shape
        if HasTag(hitBody, "gore_id") and not projectile.hit_npc then
            local path_damage = "level.goreai.body_damage_npc." .. hitBody
            local damage = tonumber(GetFloat(path_damage)) + damage_from_player_gun
            SetFloat(path_damage, damage) -- Specific damage to each body by handle.
            SetBool("level.goreai.damage_pending", true) -- (2026-11-15) npcs read body damage only when a hit is pending (goreai_health.lua)
            Blood_Pop(hitPos, 5, 7)
            projectile.hit_npc = true
        end

       -- if not npc.stealth then
         --   DrawLine(projectile.pos, point2, 0.9, 0.8, 0.7, 0.8)
       -- end
        local mat, r, g, b, a = GetShapeMaterialAtPosition(shape, hitPos)

        if mat == "metal" or mat == "heavymetal" or mat == "hardmetal" then
            bounceangle = 6*npc.roundsize
            if mat == "hardmetal" or mat == "heavymetal"  then
                PlaySound(Sounds.hardmetalimpact, projectile.pos, Vol)
            else
                PlaySound(Sounds.softmetalimpact, projectile.pos, Vol)
            end
        else
            bounceangle = 3*npc.roundsize
            if mat == "masonry" or mat == "brick" then
                PlaySound(Sounds.masonryimpact, projectile.pos, Vol)
            elseif mat == "concrete" then
                PlaySound(Sounds.gravelimpact, projectile.pos, Vol)
            elseif mat == "glass" then
                PlaySound(Sounds.glassimpact, projectile.pos, Vol)
            elseif mat == "plastic" or mat == "dirt" then
                PlaySound(Sounds.dirtimpact, projectile.pos, Vol)
            elseif mat == "wood" then
                PlaySound(Sounds.woodimpact, projectile.pos, Vol)
            elseif mat == "grass" then
                PlaySound(Sounds.foliageimpact, projectile.pos, Vol)
            else
                PlaySound(Sounds.gravelimpact, projectile.pos, Vol)
            end
        end

        if VecLength(VecSub(projectile.pos, hitPos)) < 0.04 and projectile.momentum < npc.maxMomentum then
            projectile.active = false
            projectile.momentum = 0
        end

        local hitangle = math.acos(VecDot(projectile.predictedBulletVelocity, normal) / VecLength(projectile.predictedBulletVelocity))*57.3-90
        if hitangle < bounceangle and math.random(0, 100) / 100 > (hitangle / bounceangle) ^ 2 and not npc.rpg then
            -- PlaySound(Sounds.ricochetsound, projectile.pos, 0.4)
            local dot = VecDot(normal, projectile.predictedBulletVelocity)
            projectile.predictedBulletVelocity =
            VecSub(projectile.predictedBulletVelocity, VecScale(normal, dot * (1 + math.random(1, 10) / 10)))
        else
            ApplyBodyImpulse(GetShapeBody(shape),hitPos,VecScale(VecNormalize(projectile.predictedBulletVelocity), queryDist / 200))

            if mat == "glass" and math.random() > 0.65 then
                if npc.rpg then
                    Explosion(hitPos, npc.exp)
                    --PlaySound(rpghit, hitPos)
                end
                MakeHole(hitPos, 0.1)
                projectile.momentum = projectile.momentum - 0.2
            elseif mat == "metal" or mat == "heavymetal" or mat == "hardmetal" then
                SpawnParticle("smoke", hitPos, Vec(0, 1.0 + math.random(1, 10) * 0.1, 0), npc.damage, 1)
                ParticleReset()
                ParticleType("plain")
                ParticleTile(6)
                ParticleSticky(0, 0)
                ParticleRadius(0.1, 0.01)
                ParticleAlpha(1, 0)
                ParticleEmissive(10, 10)
                ParticleColor(1, 0.75, 0.25, 1, 0.25, 0.25)
                ParticleGravity(-10, -10)
                for i = 1, math.random(10, 10 * npc.maxMomentum) do
                    SpawnParticle(
                        hitPos,
                        Vec(
                            (math.random(-100, 100) / 100) * 5,
                            (math.random(-100, 100) / 100) * 5,
                            (math.random(-100, 100) / 100) * 5
                        ),
                        math.random(10, 25) / 20
                    )
                end
                PointLight(hitPos, 1, 0.75, 0.25, 0.25)
                projectile.momentum = projectile.momentum - 1
            else
                ParticleReset()
                ParticleType("plain")
                ParticleTile(6)
                ParticleSticky(0, 0)
                ParticleRadius(0.05, 0.05)
                ParticleAlpha(a, 0)
                ParticleEmissive(0, 0)
                ParticleColor(r, g, b, r, g, b)
                ParticleGravity(-10, -10)
                for i = 1, math.random(10, 10 * npc.maxMomentum) do
                    SpawnParticle(
                        hitPos,
                        Vec(
                            (math.random(-100, 100) / 100) * 5,
                            (math.random(-100, 100) / 100) * 5,
                            (math.random(-100, 100) / 100) * 5
                        ),
                        math.random(10, 25) / 20
                    )
                    if mat == "dirt" then
                        ParticleTile(1)
                        ParticleRadius(0.5, 0.1)
                        SpawnParticle(
                            hitPos,
                            Vec(
                                (math.random(-100, 100) / 100),
                                (math.random(-100, 100) / 100) * 5,
                                (math.random(-100, 100) / 100)
                            ),
                            math.random(10, 25) / 20
                        )
                    end
                end
                projectile.momentum = projectile.momentum - 0.5
            end

            local factor = 1

            if npc.rpg then
                Explosion(hitPos, npc.exp)
                PlaySound(npc.sounds.rpghit, hitPos)
                projectile.active = false
                for _, p in ipairs(GorePlayerIds) do -- (v2 goreai) distant blast layer for every player
                    local camPos = GetPlayerCameraTransform(p).pos
                    distfromhittoplayer = VecLength(VecSub(camPos, hitPos))
                    PlaySound(npc.sounds.rpghitdist, camPos, distfromhittoplayer / 10)
                end
            end

            if math.random() < 0.5 then
                MakeHole(hitPos, npc.mat_holes[1], npc.mat_holes[2], npc.mat_holes[3])
            end

            if HasTag(shape, "unbreakable") or HasTag(GetShapeBody(shape), "unbreakable") or mat == "heavymetal" or mat == "rock" or mat == "" then
                projectile.momentum = 0
                projectile.active = false
            end
        end

    elseif not hit and projectile.active and not projectile.hitPlayer then  -- Check is projectile hit player.
      -- (v2 goreai) every player whose aim point is ahead of the bullet (v1: the one player)
      for _, hitP in ipairs(GorePlayerIds) do
        if not projectile.hitPlayer and VecDot(dir, DirLookAt(projectile.pos, GorePlayers[hitP].aimPos)) > 0.5 then

        -- if VecDist(projectile.pos, PlayerPos) < queryDist * 2 then

            for _, trigger in pairs(GoreAI_Hitboxes(hitP)) do -- Check each hitbox when projectile close enough

                local min, max = GetTriggerBounds(trigger)

                -- local intersection = LineIntersectsAABB(projectile.pos, VecAdd(projectile.pos, VecScale(VecNormalize(projectile.predictedBulletVelocity), npc.velocity)), min, max)
                local intersection = LineIntersectsAABB(projectile.pos, VecAdd(projectile.pos, VecScale(dir, queryDist)), min, max)
                if intersection then -- proj intersected hitbox

                    -- -- -- print("hit hitbox")

                    -- -- -- Backup hit check () -- todo fix this got damn projectile system.
                    -- local didHitShape, dist = QueryRaycast(projectile.pos, dir, npc.velocity, 0.1)
                    -- local hitPos = VecAdd(projectile.pos, VecScale(dir, dist))

                    -- -- -- print("hitAnything", intersection[1], intersection[2], intersection[3])

                    -- local distToHitbox = VecDist(projectile.pos, intersection)
                    -- local distToShapeHitPos = VecDist(projectile.pos, hitPos)

                    -- -- print("distToHitbox", distToHitbox)
                    -- -- print("distToShapeHitPos", distToShapeHitPos)

                    -- if distToHitbox < distToShapeHitPos then

                        if GetBool("level.healthScriptSpawned") then
                            SetTag(trigger, "QueriedDamage", npc.pdamage)
                        else
                            SetPlayerHealth(GetPlayerHealth(hitP) - (npc.pdamage/100), hitP)
                        end

                        -- debug hit positions
                        table.insert(Debug_hitPositions_shapes, {
                            hitPos    = intersection,
                            sourcePos = projectile.pos,
                            time = GetTime(),
                        })

                        projectile.hitPlayer = true
                        projectile.active    = false

                    -- end

                    -- print()

                    break -- Only hit one hitbox.

                end

            end
        -- end
        end
      end

        --point2 = VecAdd(projectile.pos, VecScale(projectile.predictedBulletVelocity, GetTimeStep()))
        -- if not npc.stealth then
        --     DrawLine(projectile.pos, point2, 0.9, 0.8, 0.7, 0.8)
        -- end

    end

    -- if projectile.momentum < 0.1 or projectile.pos[2] < 0 or VecLength(VecSub(point2, projectile.pos)) < 0.01 then
    --     projectile.active = false
    -- end

    if projectile.active then
        local endPos = ternary(hitPos, hitPos, projectileNextPos)
        DrawLine(projectile.pos, endPos, 0.9, 0.8, 0.7, 0.8)
    end

    projectile.pos = projectileNextPos

end

function create_aim_alignment(title, body, value, last_tr, min, max, rate)
    return {
        title = title,
        body  = body,
        value = value,
        last_tr  = last_tr,
        min   = min,
        max   = max,
        rate  = rate,
    }
end

function npc_process_aim_sway(npc, scale)

    scale = scale or 1

    TimerRunTime(npc.sway.timer)
    if TimerConsumed(npc.sway.timer) then

        TimerResetTime(npc.sway.timer)
        npc.sway.timer.time = RandomSpreadPercent25(npc.sway.timer.time)

        npc.sway.vec = VecRandom(scale)
        npc.sway.vec[2] = npc.sway.vec[2] * 0.7
        npc.sway.vec[3] = 0

        -- Randomly scale and shorten the timer.
        if math.random() < 0.1 then
            npc.sway.vec = VecScale(npc.sway.vec, math.random())
            npc.sway.timer.time = npc.sway.timer.time * 1.5
        end

        local sniper = false
        -- if npc.Gun then
        --     if math.random() < 0.5 and npc.Gun.class == GUN_CLASSES.sniper then
        --         sniper = true
        --     end
        -- end

        if math.random() < NPC_AIM_SWAY_CENTER_FOCUS or sniper then -- Center aim consistency.
            npc.sway.vec = Vec()
        end

        npc.sway.vec = QuatRotateVec(npc.sway.tr.rot, npc.sway.vec)

        local distToTarget = VecDist(npc.torsoPos, npc.ai.shootPos)
        local distScaled = clamp(distToTarget, 1, 70)/50
        -- DebugWatch("dist", distScaled)

        local velScaled = 0
        if npc.ai.targeting.target then
            if npc.ai.targeting.target.type == TargetTypes.player then
                if GetPlayerVehicle(GoreP) ~= 0 then
                    velScaled = VecLength(GetBodyVelocity(GetVehicleBody(GetPlayerVehicle(GoreP))))
                    velScaled = velScaled / 10
                end
            end
        end

        npc.sway.vec = VecScale(npc.sway.vec, (1 + distScaled + velScaled) * config.goreai.weapon_sway / npc.proficiency)

        if distToTarget < 20 then
            npc.sway.vec = VecScale(npc.sway.vec, 1 - (1 / distToTarget))
        end

    end

    AutoSOSUpdate(npc.sway.sos.x, npc.sway.vec[1], Controls.t.value)
    AutoSOSUpdate(npc.sway.sos.y, npc.sway.vec[2], Controls.t.value)
    AutoSOSUpdate(npc.sway.sos.z, npc.sway.vec[3], Controls.t.value)

end


function draw_combat_details()

    local w = 500
    local h = 30
    local h2 = h*2
    local sp = h + 10

    local diff_max = 1

    local npc_name = "WHO DIS NPC?"
    if SelectedNPC then

        npc_name =  NPC_TEAMS[SelectedNPC.ai.teams.team].name
        if SelectedNPC.boss.isBoss then npc_name = npc_name .. " BOSS" end

        -- UI Controls
        if ViewCam then
            UiPush()
            UiPush()

                UiFont("bold.ttf", h)
                UiAlign("center bottom")
                UiTextShadow(0,0,0, 1, 0.1, 0.1)
                UiTranslate(UiCenter(), UiHeight() - 200)
                UiColor(1,1,1,1)

                UiColor(unpack(NPC_TEAMS[SelectedNPC.ai.teams.team].color))
                UiText(npc_name)

                UiTranslate(0, sp)
                UiText(SelectedNPC.gun_prefab_path)

                UiTranslate(0, sp)
                Text_Debug_Item("AMMO", (SelectedNPC.MagSize or 1) - (SelectedNPC.BulletsShot or 1) .. "/" ..  (SelectedNPC.MagSize or 1))


                UiColor(1,1,1,1)
                UiTranslate(0, sp)
                if GetTime() < 3 and not ViewCam then
                    UiText("Press 'C' to spectate npcs.")
                end

                if ViewCam then
                    UiPush() Text_Debug_Item("Cam View", GetString("level.goreai.camera_mode")) UiPop()
                    UiTranslate(0, sp)
                    UiText("Press 'C' to stop spectating npcs.")
                    UiTranslate(0, sp)
                    UiText("Press V to change camera mode.")
                end

            UiPop()
        UiPop()
        end

    end

    -- UI
    for key, npc in pairs(NPCs) do
        UiPush()

            UiTranslate(UiWidth() - w, 0)

            -- (v2 fix) lookPos/shootPos can be nil (seen in-game: Automatic.lua:308 'index local v');
            -- these values only feed the commented-out debug UI below.
            if npc.Gun and npc.ai.targeting.target and npc.ai.lookPos and npc.ai.shootPos then

                local gun_tr = GetBodyTransform(npc.Gun.body)

                local torso_align = 100 - QuatDiff(npc.torsoTr.rot, QuatLookAt(npc.torsoTr.pos, AutoVecSubsituteY(npc.ai.lookPos, npc.torsoTr.pos[2])))
                torso_align = torso_align/100
                local gun_align = QuatDiff(gun_tr.rot, QuatLookAt(gun_tr.pos, npc.ai.shootPos))
                gun_align = gun_align/100


                -- if npc == SelectedNPC then

                --     ShowControls = ShowControls or false
                --     if InputPressed("c") then ShowControls = not ShowControls end
                --     if ShowControls then UiMakeInteractive() end

                --     UiTranslate(0, 100)

                --     UiColor(0, 0, 0, 0.9)
                --     UiRect(w, UiMiddle() * 1.5)

                --     UiColor(0, 0, 0, 0)

                --     UiProgressBarTitled("Health: " .. string_pad(sfn(npc.health), 6), npc.health/100, diff_max, w, h, 0, 1, 0, 1, 0)
                --     UiTranslate(0, sp)

                --     if npc.shield.max > 0 then
                --         UiProgressBarTitled("Shield: " .. string_pad(sfn(npc.shield.value), 6), npc.shield.value/100, diff_max, w, h, 0, 0, 1, 1, 0)
                --     else
                --         UiProgressBarTitled("-- NO SHIELD --", 0, 1, w, h, 0, 0, 0, 0)
                --     end

                --         UiTranslate(0, h2)
                --         UiProgressBarTitled("Torso to Target Alignment: " .. string_pad(sfn(torso_align), 6), torso_align, diff_max, w, h, 0.5,0.5,0.5, 1, 1)

                --         UiTranslate(0, sp)
                --         UiProgressBarTitled("Torso to Target ROC: " .. string_pad(sfn(npc.aim.torso), 6), npc.aim.torso, diff_max, w, h, 0.5,0.5,0.5, 1, 1)

                --         UiTranslate(0, h)

                --         UiTranslate(0, sp)
                --         UiProgressBarTitled("Gun to Target Alignment: " .. string_pad(sfn(gun_align), 6), gun_align, diff_max, w, h, 0.5,0.5,0.5, 1, 1)

                --         UiTranslate(0, sp)
                --         UiProgressBarTitled("Gun to Target ROC: " .. string_pad(sfn(npc.aim.gun), 6), npc.aim.gun, diff_max, w, h, 0.5,0.5,0.5, 1, 1)

                --     UiTranslate(0, h2)

                --     UiPush()

                --         AutoContainer(w, h * 2)

                --         draw_settings_range(Controls.hitchance, 22, w - 10, 50, 2,2)      UiTranslate(0, h2)
                --         draw_settings_range(Controls.gunsway, 22, w - 10, 50, 2,2)        UiTranslate(0, h2)
                --         draw_settings_range(Controls.gunsway_speed, 22, w - 10, 50, 2,2)  UiTranslate(0, h2)
                --         draw_settings_range(Controls.distmin, 22, w - 10, 50, 2,2)        UiTranslate(0, h2)
                --         draw_settings_range(Controls.distmax, 22, w - 10, 50, 2,2)        UiTranslate(0, h2)

                --         UiTranslate(0, h)

                --         draw_settings_range(Controls.f, 22, w - 10, 50, 2,2) UiTranslate(0, h2)
                --         draw_settings_range(Controls.r, 22, w - 10, 50, 2,2) UiTranslate(0, h2)
                --         draw_settings_range(Controls.d, 22, w - 10, 50, 2,2) UiTranslate(0, h2)
                --         draw_settings_range(Controls.t, 22, w - 10, 50, 2,2) UiTranslate(0, h2)

                --         UiTranslate(0, h)

                --         if AutoButton("Reset Torso Alignment") then
                --             for key, npc in pairs(NPCs) do
                --                 npc.aim.torso = 0
                --             end
                --         end

                --     UiPop()

                -- end

                -- (v2 goreai) the npc.aim update moved to tick_npc_aim_alignment (server); draw runs on the client

            end

        UiPop()
    end

end

--- (v2 goreai) Server, once per tick (v1 did this in draw_combat_details, once per frame): how well each npc's torso
--- and gun face their target. npc_manage_shooting only fires when npc.aim.torso > NPC_AIM_MIN_ALIGN.
--- Also clears the debug hit list, which v1 cleared in debug_npcs (draw).
function tick_npc_aim_alignment()
    for key, npc in pairs(NPCs) do
        -- (2026-11-17, performance) not for dead npcs: only npc_point_gun / npc_manage_shooting read npc.aim (living
        -- npcs); with 16 dead npcs this loop made 1.4 MB/s of garbage (QuatLookAt / QuatDiff tables)
        if not npc.dead and npc.Gun and npc.aim and npc.torsoTr and npc.ai.targeting.target and npc.ai.lookPos and npc.ai.shootPos then
            local gun_tr = GetBodyTransform(npc.Gun.body)
            local torso_align = 100 - QuatDiff(npc.torsoTr.rot, QuatLookAt(npc.torsoTr.pos, AutoVecSubsituteY(npc.ai.lookPos, npc.torsoTr.pos[2])))
            torso_align = torso_align/100
            local gun_align = QuatDiff(gun_tr.rot, QuatLookAt(gun_tr.pos, npc.ai.shootPos))
            gun_align = gun_align/100
            local dec = 0.2
            local inc = 0.008
            npc.aim.torso = lerp(npc.aim.torso, torso_align, ternary(npc.aim.torso < torso_align, inc, dec))
            npc.aim.gun = lerp(npc.aim.gun, gun_align, ternary(npc.aim.gun < gun_align, inc, dec))
        end
    end
    if not config.goreai.draw_projectile_impacts or #Debug_hitPositions_shapes > 200 then
        Debug_hitPositions_shapes = {}
    end
end

function draw_combat()
    UiPush()

        -- UiTranslate(0, 400)

        -- local h = 100
        -- local sp = h + 20
        -- AutoGraphDraw("orbit x", 600, h) UiTranslate(0, sp)
        -- AutoGraphDraw("orbit y", 600, h) UiTranslate(0, sp)
        -- AutoGraphDraw("orbit z", 600, h) UiTranslate(0, sp)

    UiPop()
end

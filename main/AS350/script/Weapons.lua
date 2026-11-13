--// Tess's stuff
heliprojectileHandler = {
    shellNum = 1,
    shells = {},
    defaultShell = {active = false}
}
--//

function InitGun()
    GunBody = FindBody("gun")
    RocketBody = FindBody("rocket")
    GunHinge = FindJoint("gun")
    AimTarget = nil
    GunPitch = 0
    AimTargetLocal = Vec(0,0,0)
    
    SetJointMotorTarget(GunHinge,0,5)
    GunTimer = 0 --goes 0 to 1
    RocketTimer = 0
    GunStartupTime = 0.5
    RocketStartupTime = 1
    GunSwitchOffTime = 3
    RocketSwitchOffTime = 3
    EnableGun = false
    LastFrameGunEnabled = false
    EnableRocket = false
    TriggerHeld = false
    RocketTriggerHeld = false
    GunTr = Transform()
    GunShotCooldown = 0
    GunShotCoolDownMax = 6
    
    RocketCooldownMaxLongAI = 60*30
    RocketCooldownMaxShortAI = 60*3
    RocketCooldownMaxLongPlayer = 60*5
    RocketCooldownMaxShortPlayer = 60*1

    if IsHostile then
        RocketCooldownMaxLong = RocketCooldownMaxLongAI
        RocketCooldownMaxShort = RocketCooldownMaxShortAI
    else
        RocketCooldownMaxLong = RocketCooldownMaxLongPlayer
        RocketCooldownMaxShort = RocketCooldownMaxShortPlayer
    end

    RocketCooldownMax = RocketCooldownMaxShort
    RocketCooldown = RocketCooldownMax
    DummyRocket1 = 0
    DummyRocket2 = 0
    ReloadRocket()


    ShootSound = LoadSound("chopper-shoot0.ogg")
    AimSpread = 0.03 --0.03 for vanilla chopper, but there's some natural inaccuracy anyway
     --these are related to angular difference between target and where it's aiming based on in accuracy in a 1 long vector
     --These are used to correct for an inherent inaccuracy in the aiming of the gun, basically it's cheating rather than fixing aiming
    AlwaysHitSpread =0.01 --once this close aim directly at target (not considering leading)
    GetCloserSpread = 0.03 --once this close startadjusting the aim toward the target

    RocketLocalTr = GetLocationLocalTransform("rocket",Heli)
    RocketLocalTr2 = GetLocationLocalTransform("rocket2",Heli)

    TargetMiss = 0 -- a measure of how far away from the target the gun is pointing. at 0.02 and below will hit, at 1 it's very far

    --// Tess's stuff
    gravity = Vec(0, -10, 0)
    velocity = 850
    drag = 1.7
    maxMomentum = 5
    tracer = true
    
    lvl5armor = 0.2
    lvl4armor = 0.5
    lvl3armor = 0.85
    lvl2armor = 1
    lvl1armor = 1

    for i=1, 100 do
        heliprojectileHandler.shells[i] = deepcopy(heliprojectileHandler.defaultShell)
    end

    damage = 0.15
    pdamage = 18
    playerDamage = 5
    --//
end

function ManageGun()
    if InitTimeUp == false then return end
    if IsRocketBroken == false then
    ReloadRocket()
    end


    if AimTarget == nil then return end
    if IsCrashed then return end
    if HasPilot==false then return end

    if IsGunBroken == false then
        GunTr = GetBodyTransform(GunBody)
        AimGun()
        ShootGun()
    end

    if IsRocketBroken == false then
        ShootRocket()
    end
    LastFrameGunEnabled = EnableGun
end

function ReloadRocket()
    if RocketCooldown > 0 then 
        RocketCooldown = RocketCooldown-1 
    end
    local RocetStartTr = {}
    if RocketCooldownMax == RocketCooldownMaxLong then return end
    if DummyRocket1 == 0 then
        if RocketCooldown<30 then
            RocetStartTr = TransformToParentTransform(HeliTr,RocketLocalTr)
            DummyRocket1 = Spawn("MOD/main/AS350/rocket_small_dummy.xml",RocetStartTr)[1]
            SetBodyVelocity(DummyRocket1,HeliVel)
        end
    end
    if DummyRocket2 == 0 then
        if RocketCooldown<1 then
            RocetStartTr = TransformToParentTransform(HeliTr,RocketLocalTr2)
            DummyRocket2 = Spawn("MOD/main/AS350/rocket_small_dummy.xml",RocetStartTr)[1]
            SetBodyVelocity(DummyRocket2,HeliVel)
        end
    end
end

function AimGun()
    AimTargetLocal = TransformToLocalPoint(HeliTr, AimTarget)
    GunPitch = math.atan(AimTargetLocal[2]/AimTargetLocal[3])*180/math.pi
    GunPitch = math.clamp(GunPitch,-37,15)
    SetJointMotorTarget(GunHinge,GunPitch,90)
end


function RocketImputs()
    if DetailedControl == false then return end
    --RocketTriggerHeld = KeybindDown(Settings.keybinds.player.aim_down_sight)
    RocketTriggerHeld = InputDown("rmb")
    if IsRocketBroken then RocketTriggerHeld = false end

    if RocketTriggerHeld then
        if RocketTimer<1 then
            RocketTimer = RocketTimer + 1/(RocketStartupTime*60)
            EnableRocket = false
        else
            EnableRocket = true
        end
    else
        if EnableRocket==false then
            if RocketTimer>0 then
                RocketTimer = 0
            end
        else
            if RocketTimer ~= 0 then
                RocketTimer = RocketTimer - 1/(RocketSwitchOffTime*60)
                if RocketTimer<0 then
                    RocketTimer =0
                    EnableRocket = false
                    AimTarget = nil
                end
            end
        end
    end

    --if RocketTimer>0.4 then
    if EnableRocket then
        QueryRejectSelf() --I don't understand why it doesn't work
        local target,hit = GetAimPosOffset(200,zoom+2,3) -- don't understand how this doesn't work either
        AimTarget = target
        --DebugCross(AimTarget,1,0,0)
    end


end

function ShootRocket()
    if RocketCooldown > 0 then 
        return
    end

    if EnableRocket == false then return end
    if RocketTriggerHeld == false then return end

    RocketCooldown = RocketCooldownMax

    local RocetStartTr = {}
    if RocketCooldownMax == RocketCooldownMaxLong then
        RocketCooldownMax = RocketCooldownMaxShort
        RocetStartTr = TransformToParentTransform(HeliTr,RocketLocalTr2)
        Delete(DummyRocket2)
        DummyRocket2 = 0
    else
        RocketCooldownMax = RocketCooldownMaxLong
        RocetStartTr = TransformToParentTransform(HeliTr,RocketLocalTr)
        Delete(DummyRocket1)
        DummyRocket1 = 0
    end

    local Dir = QuatRotateVec(PlayerCamRot,Vec(1,0,0))

    --RocetStartTr.rot = QuatRotateQuat(QuatAxisAngle(Dir,3),PlayerCamRot)

    if AimTarget ~=nil then
        for i2 = 1,3,1 do
            SetFloat("level.RocketTarget" .. i2, AimTarget[i2])
        end
    end
    
    --Spawn("MOD/genzero_tank/rocket_cam.xml",tr)
    Spawn("MOD/main/AS350/rocket_small.xml",RocetStartTr)
end

function GunImputs()
    if DetailedControl == false then return end
    --TriggerHeld = KeybindDown(Settings.keybinds.player.shoot)
    TriggerHeld = InputDown("usetool")
    if IsGunBroken then TriggerHeld = false end

    if TriggerHeld then
        if GunTimer<1 then
            GunTimer = GunTimer + 1/(GunStartupTime*60)
        else
            EnableGun = true
        end
    else
        if EnableGun==false then
            if GunTimer>0 then
                GunTimer = 0
            end
        else
            if Guntimer ~= 0 then
                GunTimer = GunTimer - 1/(GunSwitchOffTime*60)
                if GunTimer<0 then
                    GunTimer =0
                    EnableGun = false
                    AimTarget = nil
                    SetJointMotorTarget(GunHinge,0,5)
                end
            end
        end
    end

    if EnableGun then
        local Dir = QuatRotateVec(PlayerCamRot,Vec(1,0,0))
        local q = QuatRotateQuat(QuatAxisAngle(Dir,-10),PlayerCamRot) --aiming felt a bit weird, it was aminig too high, but still a bit weird after the fix
        --as the source of aim is the not the same as the camera
        AimTarget = VecAdd(GunTr.pos,QuatRotateVec(q, Vec(0,0,-4)))
    end
end

--// Tess's stuff
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

function ShootGun()
    
    if GunShotCooldown > 0 then 
        GunShotCooldown = GunShotCooldown-1 
        return
    end
    
    if EnableGun == false then return end

    --direction of target regardless of gunfacing
    local tdir = TransformToLocalVec(GunTr,VecSub(AimTarget,GunTr.pos))

    local spread1 = LogisticRandom(AimSpread*1.5)
    local spread2 = LogisticRandom(AimSpread*1.5)

    tdir = VecScale(tdir,1/tdir[3])
    local tdirwitherror = tdir
    tdirwitherror[1] = tdirwitherror[1]+spread1
    tdirwitherror[2] = tdirwitherror[2]+spread2

    local d = math.abs(tdirwitherror[2]) --d is a measure of how close the gun is to aim at the target
    --0 exactly aiming there, 1 at least 90deg away
    if math.abs(tdirwitherror[1])>d then d = math.abs(tdirwitherror[1]) end
    TargetMiss = d

    if LastFrameGunEnabled == false then return end 
    if TriggerHeld == false then return end
    GunShotCooldown = GunShotCoolDownMax
    
    local m1 = 0.01
    local m2 = 0.03

    local dir = {}
    dir = Vec(0,0,1)
    if d<m1 then
        dir = tdir
    elseif d>m2 then
        dir = Vec(0,0,1)
    else
        dir = VecLerp(tdir,Vec(0,0,1),(d-m1)/(m2-m1))
    end
    dir[1] = dir[1]+spread1
    dir[2] = dir[2]+spread2

    dir = TransformToParentVec(GunTr,dir) 

    heliprojectileHandler.shells[heliprojectileHandler.shellNum] = deepcopy(heliprojectileHandler.defaultShell)
    loadedShell = heliprojectileHandler.shells[heliprojectileHandler.shellNum] 
    loadedShell.active = true
    loadedShell.pos = TransformToParentPoint(GunTr, Vec(0, 0, 0.6))
    loadedShell.momentum = maxMomentum
    loadedShell.predictedBulletVelocity = VecScale(dir, velocity)
    heliprojectileHandler.shellNum = (heliprojectileHandler.shellNum%#heliprojectileHandler.shells) + 1

    local barrelend = TransformToParentPoint(GunTr, Vec(0, 0, 0))

    SpawnParticle("smoke", barrelend, VecScale(dir, 0.02), 0.3, 0.3)
    ParticleReset()
    ParticleType("plain")
    ParticleTile(5)
    ParticleColor(1, 0.6, 0.4, 1, 0.3, 0.2)
    ParticleRadius(0.1)
    ParticleEmissive(5, 1)
    SpawnParticle("smoke", barrelend, VecScale(dir, 0.02), 0.3, 0.3)
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
        SpawnParticle(barrelend, VecAdd(VecScale(dir, 25), Vec((math.random(-100,100)/100)*4,(math.random(-100,100)/100)*4, (math.random(-100,100)/100)*4)), 0.1)
    end
    PointLight(barrelend, 1, 0.75, 0.25, 1)

    -- Shoot(GunTr.pos,dir,0,0.3)
    PlaySound(ShootSound, GunTr.pos, 25)
    -- DamageInMorsLonga(GunTr.pos,dir,AimTarget)
end

function ProjectileOperations(projectile)
    projectile.predictedBulletVelocity = VecScale(projectile.predictedBulletVelocity, (1-drag*GetTimeStep()*VecLength(projectile.predictedBulletVelocity)/velocity))
    projectile.predictedBulletVelocity = VecAdd(projectile.predictedBulletVelocity, (VecScale(gravity, GetTimeStep())))
    local point2 = VecAdd(projectile.pos, VecScale(projectile.predictedBulletVelocity, GetTimeStep()))
    local dir = VecNormalize(VecSub(point2, projectile.pos))
    local hit, dist, normal, shape = QueryRaycast(projectile.pos, dir, VecLength(VecSub(point2, projectile.pos)))

    if hit then
        hitPos = VecAdd(projectile.pos, VecScale(VecNormalize(VecSub(point2, projectile.pos)), dist))
        point2 = hitPos
        if tracer then DrawLine(projectile.pos, point2, 0.9, 0.8, 0.6, 0.8) end
        local mat, r, g, b, a = GetShapeMaterialAtPosition(shape, hitPos)


        -- NPC DAMAGE START
        local damage_from_player_gun = pdamage
        local hitBody = GetShapeBody(shape) -- raycast hit shape
        if HasTag(hitBody, "gore_id") and not projectile.hit_npc then
            local path_damage = "level.goreai.body_damage_npc." .. hitBody
            local damage = tonumber(GetFloat(path_damage)) + damage_from_player_gun
            SetFloat(path_damage, damage) -- Specific damage to each body by handle.
            Blood_Pop(hitPos, 5, 7)
            projectile.hit_npc = true
        end
        -- NPC DAMAGE END


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
            ApplyBodyImpulse(GetShapeBody(shape), hitPos, VecScale(projectile.predictedBulletVelocity, projectile.momentum/10))


            if HasTag(GetShapeBody(shape), "gore_id") and Settings.game.blood_and_gore.value then -- NPC hit

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
            elseif mat == "metal" or mat == "heavymetal" or mat == "hardmetal" then
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

            local Player = Vec()
            if GetPlayerVehicle() == 0 then
                Player = VecAdd(GetPlayerTransform().pos, Vec(0, 1, 0))
            else
                Player = VecAdd(GetPlayerTransform().pos, Vec(0, -0.4, 0))
            end
            local Relative = VecSub(Player, point2)
            local Lookback = VecScale(VecNormalize(VecSub(point2,projectile.pos)), VecDot(Relative, VecNormalize(VecSub(point2,projectile.pos))))
            local Range = VecSub(Player, VecAdd(point2, Lookback))

            if VecLength(Range) < .5 and projectile.momentum ~= 0 then
                local r = math.random(0,100)/100
                local headshot = r>0.99

                Hitboxes = FindTriggers("hitbox",true)
                local i = math.random(2,#Hitboxes)
                local ishead = GetTagValue(Hitboxes[i], "hitbox") == "HEAD"
                if ishead == headshot then
                    SetTag(Hitboxes[i], "QueriedDamage", playerDamage)
                    -- SetTag(Hitboxes[i], "S", 2)
                elseif headshot then
                    i = 1
                    SetTag(Hitboxes[i], "QueriedDamage", playerDamage)
                    -- SetTag(Hitboxes[i], "S", 2)
                end
            end

            if projectile.momentum > 0 then
                MakeHole(hitPos, damage, damage*0.85, damage*0.7)
                -- if explosive and perk == "127x99" then
                --     Explosion(hitPos,0.5)
                --     projectile.active = false
                -- end
                -- if perk == "127x99" and GetInt("savegame.mod.perks.127x99") == 3 then
                --     SpawnFire(hitPos)
                -- end
            end

            if HasTag(shape, "unbreakable") or HasTag(GetShapeBody(shape), "unbreakable") or mat == "heavymetal" or mat == "rock" then
                projectile.momentum = 0
                projectile.active = false
            end 
        end
    else
        point2 = VecAdd(projectile.pos, VecScale(projectile.predictedBulletVelocity, GetTimeStep()))
        if tracer then DrawLine(projectile.pos, point2, 0.9, 0.8, 0.7, 0.8) end
    end

    if projectile.momentum < 0.1 or projectile.pos[2] < -50 then
        projectile.active = false
    end

    projectile.pos = point2
end

-- function tick(dt)
--     for key, shell in ipairs(heliprojectileHandler.shells) do
--         if shell.active then
--             ProjectileOperations(shell)
--         end
--     end
-- end
--//

function TestingBits()
    AimTarget = Vec(5,5,5)

    if InputPressed("k") then
        GunPitch = -100
    end
    if InputPressed("L") then
        GunPitch = -0
    end
end
Turrets = {}


function initTurret()

    local entity_id = 'turret_id'

    local turretGun = FindBodies('turretGun', true)
    local turretBase = FindBodies('turretBase', true)
    local turretArm = FindBodies('turretArm', true)
    local gunH = FindJoints('gunH', true)
    local gunV = FindJoints('gunV', true)
    local shootLocations = FindLocations('shootLocation', true)
    local headLocations = FindLocations('headLocation', true)

    -- Find turret parts based on their ids.
    local turretCount = GetInt('level.turretCount')
    for i = 1, turretCount do

        -- dbpc('')

        local turret = {}

        turret.turretGun = matchEntityId(turretGun, 'turretGun', entity_id, i)
        turret.turretBase = matchEntityId(turretBase, 'turretBase', entity_id, i)
        turret.turretArm = matchEntityId(turretArm, 'turretArm', entity_id, i)
        turret.gunH = matchEntityId(gunH, 'gunH', entity_id, i)
        turret.gunV = matchEntityId(gunV, 'gunV', entity_id, i)
        turret.shootLocation = matchEntityId(shootLocations, 'shootLocation', entity_id, i)
        turret.headLocation = matchEntityId(headLocations, 'headLocation', entity_id, i)

        turret.camera = {} -- Variables used by manageCamera()
        turret.camera.xy = {UiCenter(), UiMiddle()} -- crosshair pixel pos.
        turret.camera.X = 0
        turret.camera.Y = 0
        turret.camera.zoom = 2
        turret.turret_ironSights = true

        turret.shooting = {}
        turret.shooting.timer = {time = 0, rpm = 500}
        turret.shooting.ammo = 300
        turret.shooting.spread = 0.9 -- degrees of spread.

        turret.shootRelPos = TransformToLocalPoint(
            GetBodyTransform(turret.turretGun),
            GetLocationTransform(turret.shootLocation).pos) -- Local offset position to shoot location (barrel tip)

        turret.headRelPos = TransformToLocalPoint(
            GetBodyTransform(turret.turretGun),
            GetLocationTransform(turret.headLocation).pos)


        turret.tr = GetBodyTransform(turret.turretGun)
        turret.isUsingTurret = false


        table.insert(Turrets, turret)

    end

    -- dbpc('\nturrets intialized')

end

function runTurrets()

    for key, turret in pairs(Turrets) do
        runTurret(turret)
    end

end

function runTurret(turret)

    turret.tr = GetBodyTransform(turret.turretGun)

    turretEnterExit(turret)

    if turret.isUsingTurret then

        DrawBodyOutline(turret.turretGun, 1,1,1, 1)

        if InputPressed('rmb') then
            turret.turret_ironSights = not turret.turret_ironSights
        end

        if turret.turret_ironSights then
            local cameraRot = manageCameraHead(turret, turret.turretBase)
            turretRotateHead(turret, cameraRot)
        else
            manageCamera(turret, turret.turretBase, false)
            turretRotate(turret)
        end

        turretShoot(turret)

    else
        turretIdle(turret)
    end

    TimerRunTime(turret.shooting.timer)

    -- dbw('linearRamp()',  math.deg(linearRamp(5)) * math.pi * 2)

    dbdd(getTurretShootTr(turret).pos, 0.25,0.25, 1,1,0, 1, true)

end

function drawTurrets()

    for key, turret in pairs(Turrets) do

        UiFont('regular.ttf', 32)
        UiColor(1,1,1)

        turret.camera.xy = {UiCenter(), UiMiddle()}

        if turret.isUsingTurret then

            -- Display crosshair.
            do UiPush()
                UiAlign('center middle')
                UiTranslate(turret.camera.xy[1], turret.camera.xy[2])
                UiImageBox('ui/hud/crosshair-ring.png', 25,25, 4,4)
            UiPop() end

            -- Display ammo count.
            do UiPush()
                UiAlign('center middle')
                UiTranslate(UiCenter(), UiHeight() - 200)
                if turret.shooting.ammo <= 0 then
                    UiColor(1,0,0)
                end
                UiText('Ammo: ' .. turret.shooting.ammo)
            UiPop() end

        end

    end

end


function turretShoot(turret)

    if turret.shooting.timer.time <= 0 then

        if InputDown('lmb') and turret.shooting.ammo >= 1 then

            local pos = getTurretShootTr(turret).pos
            local dir = QuatToDir(turret.tr.rot)
            dir = VecAdd(dir, VecRdm(math.rad(turret.shooting.spread))) -- Apply spread.

            Shoot(pos, dir)
            turret.shooting.ammo = turret.shooting.ammo - 1

            PlaySound(LoadSound("MOD/snd/turretShot.ogg"), turret.tr.pos, 1)

            TimerResetTime(turret.shooting.timer)
        end

    end

    if InputPressed('lmb') and turret.shooting.ammo <= 0 then -- Play click sound when out of ammo.
        PlaySound(LoadSound("MOD/assets/snd/Weapons/Shared/dryfire.ogg"), turret.tr.pos, 1)
    end

    dbw('shooting.timer.time', turret.shooting.timer.time)

end

function turretRotate(turret)

    local scale = 10

    local exitTr = Transform(TransformToParentPoint(turret.tr, Vec(0,0,2)), turret.tr.rot)
    SetPlayerTransform(exitTr) -- Lock player position behing the turret gun.

    local crosshairPos = getCrosshairWorldPos()
    dbdd(crosshairPos, 0.2, 0.2, 1,0,0, 1, false)

    local turretShootTr = TransformToLocalPoint(getTurretShootTr(turret), crosshairPos)
    local relPos = VecScale(VecNormalize(turretShootTr), scale)

    local rotateH = relPos[1]
    local rotateV = relPos[2]

    local strength = 4000

    SetJointMotor(turret.gunH, rotateH, strength)
    SetJointMotor(turret.gunV, rotateV, strength)

end


function turretRotateHead(turret, cameraRot)

    local scale = 10

    local exitTr = Transform(TransformToParentPoint(turret.tr, Vec(0,0,2)), turret.tr.rot)
    SetPlayerTransform(exitTr) -- Lock player position behing the turret gun.

    QueryRejectBody(turret.turretGun)
    local crosshairPos = getCrosshairWorldPos()
    dbdd(crosshairPos, 0.2, 0.2, 1,0,0, 1, false)

    -- diff between turret rot and cam rot
    local turretDir = QuatToDir(turret.tr.rot)
    local camDir = QuatToDir(cameraRot)
    local dirDiff = VecNormalize(VecSub(turretDir, camDir))
    local ang = math.atan(dirDiff[1], dirDiff[3]) * scale

    local x,y,z = GetQuatEuler(cameraRot)
    local euler = Vec(x,y,z)

    local x,y,z = GetQuatEuler(turretDir)
    local turretEuler = Vec(x,y,z)

    local eulerDiff = euler[2] - turretEuler[2]

    dbw('ang', ang)
    -- dbw('dirDiff', dirDiff)
    -- dbw('camDir', camDir)
    dbw('turret.camera.X', turret.camera.X)
    dbw('EULER turretEuler[2]', (math.deg(math.tan(math.rad(turretEuler[2]))))/2)
    -- dbw('EULER eulerDiff', eulerDiff)


    local relPos = VecScale(VecNormalize(dirDiff), scale)
    local rotateH = ang
    -- local rotateH = relPos[3]
    local rotateV = -relPos[2]
    local strength = 100

    SetJointMotor(turret.gunH, rotateH, strength)
    SetJointMotor(turret.gunV, rotateV, strength)

    for i = 1, 2 do
        local c = Vec(0,0,0)
        c[i] = 1
        dbl(turret.tr.pos, VecAdd(turret.tr.pos, VecScale(c, camDir[i])), c[1], c[2], c[3], 1)
    end
    dbl(turret.tr.pos, VecAdd(turret.tr.pos, VecScale(Vec(0,0,1), camDir[3])), 0,0,1, 1)
    dbl(turret.tr.pos, VecAdd(turret.tr.pos, Vec(camDir[1], 0, camDir[3])), 1,1,1, 1)
    dbl(turret.tr.pos, VecAdd(turret.tr.pos, turretDir), 1,1,0, 1)

end

-- function turretRotateHead(turret, cameraRot)

--     local scale = 10

--     local exitTr = Transform(TransformToParentPoint(turret.tr, Vec(0,0,2)), turret.tr.rot)
--     SetPlayerTransform(exitTr) -- Lock player position behing the turret gun.

--     QueryRejectBody(turret.turretGun)
--     local crosshairPos = getCrosshairWorldPos()
--     dbdd(crosshairPos, 0.2, 0.2, 1,0,0, 1, false)

--     -- diff between turret rot and cam rot
--     local turretDir = QuatToDir(turret.tr.rot)
--     local camDir = QuatToDir(cameraRot)
--     camDir[3] = -camDir[3]
--     local dirDiff = VecSub(turretDir, camDir)

--     turretDir[2] = 0
--     dbl(turret.tr.pos, VecAdd(turret.tr.pos, turretDir), 1,1,0, 1)

--     local ang = math.atan(dirDiff[1], dirDiff[3]) * 10

--     local relPos = VecScale(VecNormalize(dirDiff), 10)
--     local rotateH = ang
--     local rotateV = -relPos[2]
--     local strength = 500

--     SetJointMotor(turret.gunH, rotateH, strength)
--     SetJointMotor(turret.gunV, rotateV, strength)


--     dbw('ang', ang)

--     for i = 1, 2 do
--         local c = Vec(0,0,0)
--         c[i] = 1
--         dbl(turret.tr.pos, VecAdd(turret.tr.pos, VecScale(c, camDir[i])), c[1], c[2], c[3], 1)
--     end
--     dbl(turret.tr.pos, VecAdd(turret.tr.pos, VecScale(Vec(0,0,1), -camDir[3])), 0,0,1, 1)

--     dbl(turret.tr.pos, VecAdd(turret.tr.pos, Vec(camDir[1], 0, -camDir[3])), 1,1,1, 1)

-- end

function turretIdle(turret)
    SetJointMotor(turret.gunH, 0, 0)
    SetJointMotor(turret.gunV, 0, 0)
end

function turretEnterExit(turret)

    if InputPressed('interact') then

        if turret.isUsingTurret then

            turret.isUsingTurret = false -- Exit turret.

            local exitTr = Transform(TransformToParentPoint(turret.tr, Vec(0,0,2)), turret.tr.rot)
            SetPlayerTransform(exitTr)

        elseif GetPlayerInteractBody() == turret.turretGun then

            turret.isUsingTurret = true -- Enter turret.

        end

    end

end

function getTurretShootTr(turret)
    local tr = GetBodyTransform(turret.turretGun)
    tr.pos = TransformToParentPoint(turret.tr, turret.shootRelPos)
    return tr
end

function getTurretHeadTr(turret)
    local tr = GetBodyTransform(turret.turretGun)
    tr.pos = TransformToParentPoint(turret.tr, turret.headRelPos)
    return tr
end


function manageCamera(turret, body)

    local mx, my = InputValue("mousedx"), InputValue("mousedy")

    turret.camera.X = turret.camera.X - mx / 10
    turret.camera.Y = turret.camera.Y - my / 10
    turret.camera.Y = clamp(turret.camera.Y, -75, 75)

    local cameraRot = QuatEuler(turret.camera.Y, turret.camera.X, 0)
    local cameraT = Transform(VecAdd(GetBodyTransform(body).pos, 5), cameraRot)

    turret.camera.zoom = turret.camera.zoom - InputValue("mousewheel") * 0.5
    turret.camera.zoom = clamp(turret.camera.zoom, 2, 5)

    local cameraPos = TransformToParentPoint(cameraT, Vec(0, 3, turret.camera.zoom))
    local camera = Transform(VecLerp(cameraPos, GetCameraTransform().pos, 0.5), cameraRot)

    SetCameraTransform(camera)

end

function manageCameraHead(turret, body)

    local headPos = getTurretHeadTr(turret).pos

    local mx, my = -InputValue("mousedx"), InputValue("mousedy")

    turret.camera.X = turret.camera.X - mx / 10
    turret.camera.X = turret.camera.X

    turret.camera.Y = turret.camera.Y - my / 10
    turret.camera.Y = clamp(turret.camera.Y, -75, 75)

    local cameraRot = QuatEuler(turret.camera.Y, turret.camera.X, 0)
    local cameraT = Transform(headPos, cameraRot)

    -- turret.camera.zoom = turret.camera.zoom - InputValue("mousewheel") * 0.5
    -- turret.camera.zoom = clamp(turret.camera.zoom, 0, 0)
    -- local cameraPos = TransformToParentPoint(cameraT, Vec(0, 0, -turret.camera.zoom))

    -- local cameraTr = Transform(cameraPos, turret.tr.rot)
    local cameraTr = Transform(cameraT.pos, turret.tr.rot)

    SetCameraTransform(cameraTr)

    return cameraRot

end

function matchEntityId(entities, tag, tagId, tagValue)

    for key, entity in pairs(entities) do

        if HasTag(entity, tag) and GetTagValue(entity, tagId) == tostring(tagValue) then
            -- dbpc('Matched: ' .. entity .. ' >> ' .. tag .. ' >> ' .. tagValue)
            return entity
        end

    end

    -- dbpc('Entities done matching.')

end

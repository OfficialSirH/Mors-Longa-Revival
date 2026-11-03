-- Endless Battle Map
SpawnerMaxNPCs = 8
SpawnTimer = TimerCreateSeconds(1/2)
HeliSpawnTimer = TimerCreateSeconds(5, true)

ShouldSpawnHeli = true


-- SpawnerNPCs = {
--     "BossCultist.xml",
--     "BossInsurgent.xml",
--     "BossMilitary.xml",
--     "civilian/Ragdollciv1.xml",
--     "civilian/Ragdollciv2.xml",
--     "cult/Ragdollcult1.xml",
--     "cult/Ragdollcult2.xml",
--     "millitary/Ragdollmil1.xml",
--     -- "millitary/Ragdollmilofficer1.xml",
--     "um/Ragdollpur1.xml",
--     "um/Ragdollum1.xml",
--     "um/Ragdollum1.xml",
--     "um/Ragdollum1.xml",
-- }

SpawnerNPCs_MOD = {
    "MOD/prefabs/spawnables/enemies/civilian/Ragdollciv1.xml",
    "MOD/prefabs/spawnables/enemies/civilian/Ragdollciv2.xml",
    "MOD/prefabs/spawnables/enemies/civilian/Ragdollciv3.xml",

    "MOD/prefabs/spawnables/enemies/military/Ragdollmil1.xml",
    "MOD/prefabs/spawnables/enemies/military/Ragdollmil2.xml",
    "MOD/prefabs/spawnables/enemies/military/Ragdollmil3.xml",

    "MOD/prefabs/spawnables/enemies/cult/Ragdollcult1.xml",
    "MOD/prefabs/spawnables/enemies/cult/Ragdollcult2.xml",
    "MOD/prefabs/spawnables/enemies/cult/Ragdollcult3.xml",

    "MOD/prefabs/spawnables/enemies/um/Ragdollum1.xml",
    "MOD/prefabs/spawnables/enemies/um/Ragdollum2.xml",
    "MOD/prefabs/spawnables/enemies/um/Ragdollpur1.xml",
}

SpawnHelis = {
    -- "MOD/main/AS350/AS350_MILITARY.xml",
    "MOD/main/AS350/AS350_CIV.xml"
}

CameraModes = {
    index = 1,
    cameras = { "eyes", "target", "orbit", "gun",  }
}

function tick_spawners()

    if IsGoreMap and GetTableSize(NPCs) >= 1 then

        NpcCamera = NpcCamera or camera_create(0,0,0)

        if GetTableSize(NPCs) > 2 then
            local keys = GetTableKeys(NPCs)
            local team = NPCs[keys[1]].ai.teams.team
            local allsame = true
            for i = 1, #keys do
                local npc = NPCs[keys[i]]
                if npc.ai.teams.team ~= team then
                    allsame = false
                    break
                end
            end

            -- DebugWatch("NPC teams", table.concat(keys, ", "))

            if allsame then
                for i = 1, SpawnerMaxNPCs/2 do
                    npc_mark_for_removal(NPCs[keys[i]])
                end
            end
        end



        ViewCam        = ViewCam
        CamBody        = CamBody
        SelectedNPC    = SelectedNPC
        EnemyView      = EnemyView
        NpcZoomInTimer = NpcZoomInTimer or TimerCreateSeconds(0.5)
        CamTr          = CamTr or Transform()
        LastCamTr      = LastCamTr or Transform()

        if InputPressed("v") then
            ViewCam = not ViewCam
            SetBool("level.ViewCam", ViewCam)
        end

        if InputPressed("b") then
            CameraModes.index = GetTableNextIndex(CameraModes.cameras, CameraModes.index)
            TimerResetTime(NpcZoomInTimer)
        end
        TimerRunTime(NpcZoomInTimer)



        if not CamBody then
            find_new_camera_npc()
        elseif SelectedNPC then
            if SelectedNPC.deadTime >= 1 then
                find_new_camera_npc()
            end
        end


        -- DebugWatch("CamBody", CamBody)

        if ViewCam then

            local camera_mode = CameraModes.cameras[CameraModes.index]
            SetString("level.goreai.camera_mode", CameraModes.cameras[CameraModes.index])

            DrawBodyOutline(CamBody, 1,1,1, 1)

            if camera_mode == "target" or SelectedNPC.dead then

                local pos = AabbGetBodyCenterPos(CamBody)
                local enemyPos = SelectedNPC.ai.shootPos

                local lookRot = QuatLookAt(pos, enemyPos)
                local lookTr = Transform(pos, lookRot)

                pos = TransformToParentPoint(lookTr, Vec(0,2,clamp(VecDist(pos, enemyPos)/2, 5, 30)))
                -- pos[2] = clamp(VecDist(pos, enemyPos)/3, 3, 15)

                lookRot = QuatLookAt(pos, VecAvg(pos, enemyPos))

                CamTr.pos = VecAvg(LastCamTr.pos, pos)
                CamTr.rot = QuatSlerp(
                    lookRot,
                    LastCamTr.rot,
                    0.25)

                if SelectedNPC.dead then
                    CamTr.rot = QuatLookAt(pos, GetBodyTransform(SelectedNPC.Torso).pos)
                end

                SetCameraTransform(CamTr)

                LastCamTr.pos = VecAvg(CamTr.pos, LastCamTr.pos)
                LastCamTr.rot = QuatSlerp(CamTr.rot, LastCamTr.rot, 0.25)

            elseif camera_mode == "orbit" then

                local pos = AabbGetBodyCenterPos(CamBody)
                camera_manage(NpcCamera, pos, 0)

            elseif camera_mode == "gun" then

                local tr = GetBodyTransform(SelectedNPC.Gun.body)
                SetCameraTransform(Transform(TransformToParentPoint(tr, Vec(0,0,2)), QuatRotateQuat(tr.rot, QuatEuler(0,180,0))))

                local hit, pos = RaycastFromTransform(tr.pos, QuatRotateQuat(tr.rot, QuatEuler(0,180,0)))
                if hit then
                    DrawDot(pos, 1/2, 1/2, 1,1,1, 1)
                    PointLight(pos, 1, 1, 1, 1)
                end

                DrawDot(TransformToParentPoint(tr, Vec(0,0,1)), 1/10, 1/10, 1,1,1, 1, true)

            elseif camera_mode == "eyes" then

                if TimerConsumed(NpcZoomInTimer) then
                    local tr = GetBodyTransform(SelectedNPC.Torso)
                    SetCameraTransform(Transform(TransformToParentPoint(tr, Vec(0,0.6,-0.3)), QuatRotateQuat(tr.rot, QuatEuler(-20,0,0))))
                else
                    local tr = GetBodyTransform(SelectedNPC.Head)
                    SetCameraTransform(Transform(TransformToParentPoint(tr,
                        Vec(0,TimerGetProgress(NpcZoomInTimer)*4,-TimerGetProgress(NpcZoomInTimer) * 8)),
                        QuatRotateQuat(tr.rot, QuatEuler(0,180,0))))
                end

            end

        end

        local torsos = FindBodies("Torso", true)
        Torsos = {}
        for index, torso in ipairs(torsos) do
            if not HasTag(torso, "dead") then
                table.insert(Torsos, torso)
            end
        end

        TimerRunTime(SpawnTimer)
        if #Torsos <= SpawnerMaxNPCs and TimerConsumed(SpawnTimer) then
            TimerResetTime(SpawnTimer)

            local hit, pos = RaycastFromTransform(Transform(Vec(0,50,0), QuatLookAt(Vec(0,0,0), Vec(0,-1,0))))
            Spawn(GetRandomArrayValue(SpawnerNPCs_MOD), Transform(AutoVecSubsituteY(VecRandom(30), 0)))

        end

        TimerRunTime(HeliSpawnTimer)
        if ShouldSpawnHeli and TimerConsumed(HeliSpawnTimer) then
            TimerResetTime(HeliSpawnTimer)

            Helis = FindBodies("Heli", true)

            for index, heli in ipairs(Helis) do

                local reg = "level.deadHelis." .. heli

                if HasTag(heli, "dead") then
                    SetFloat(reg, GetFloat(reg) + GetTimeStep())
                end

                if GetFloat(reg) > 10 then
                    Delete(heli)
                end

                --DebugWatch("heli dead", GetFloat(reg))
                print("heli removed " .. sfnTime()) --##
            end

            if #Helis == 0 then
                local tr = Transform(VecRandom(60))
                tr.pos[2] = 40
                local xml_heli = GetRandomArrayValue(SpawnHelis)
                Spawn(xml_heli, tr)
                print("heli spawned " .. sfnTime()) --##
            end

        end

        -- Check if all npcs are same team, then thanos snap em.
        if  #Torsos >= 3 and #Torsos == SpawnerMaxNPCs then

            -- Sort npc teams
            local teams = {}
            for _, torso in ipairs(Torsos) do

                local team = GetTagValue(torso, "spawn_team")

                if not teams[team] then
                    teams[team] = {}
                end

                table.insert(teams[team], torso)

            end

            -- Check highest team count.
            local greatestTeam = { team = "-", team_torsos = {} }
            for team, team_torsos in pairs(teams) do

                if math.max(#greatestTeam.team_torsos, #team_torsos) == #team_torsos then
                    greatestTeam.team_torsos = team_torsos
                    greatestTeam.team = team
                end

            end

            if #greatestTeam.team_torsos == SpawnerMaxNPCs then
                for i=1, #greatestTeam.team_torsos - 2 do
                    Explosion(AabbGetBodyCenterPos(greatestTeam.team_torsos[i]), 0.5)
                end
            end

        end


    end

end

function find_new_camera_npc()

    for _, body in pairs(FindBodies("Torso", true)) do
        if not HasTag(body, "dead") then

            for _, _npc in pairs(NPCs) do
                if _npc.Torso == body then

                    SelectedNPC = _npc
                    CamBody = body
                    TimerResetTime(NpcZoomInTimer)
                    return

                end
            end

        end
    end

end

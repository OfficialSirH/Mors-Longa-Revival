function npc_init_melee(npc)

    npc.isMelee = false

    npc.melee = {
        timer = TimerCreateSeconds(0.5, true),
        swing_time = 0,
        punch_dist = 3,
        punch_damage = 4,
        -- weapons = {}
    }

    if npc.boss.isBoss then
        if npc.boss.boss_preset.id == BossPresets.cultist.id then

            npc.isMelee = true

            npc.melee.punch_damage = 6

            npc.melee.sound_swing = LoadSound("MOD/snd/Weapons/Melee/swing0.ogg")

            if npc.Gun then
                Delete(npc.Gun.body)
                npc.Gun = nil
            end

            npc_melee_assign_weapons(npc,
                "MOD/GoreNPCs/prefabs/weapons/cultist_melee.xml",
                "MOD/GoreNPCs/prefabs/weapons/cultist_melee.xml")

        end
    end

end


---Gives the npc melee weapons similar to the way they are assigned guns.
---@param npc table
---@param left_xml string left hand prefab.
---@param right_xml string right hand prefab.
function npc_melee_assign_weapons(npc, left_xml, right_xml)

    npc.melee.weapons = {}

    if HasFile(left_xml) then
        local entities = Spawn(left_xml, Transform(), false, false)
        for _, e in ipairs(entities) do
            if GetEntityType(e) == "body" then

                RemoveTag(e, "interact")
                SetTag(e, "unbreakable")
                SetBodyDynamic(e, true)

                for _, shape in ipairs(GetBodyShapes(e)) do
                    SetShapeCollisionFilter(shape, 0, 0)
                end

                npc.melee.weapons.left = e
                table.insert(npc.AllBodies, e)

                break

            end
        end
        npc.melee.weapons_left_tip = ExtractEntityByTag(entities, "melee_tip")
    else
        print("melee weapon file not found: ", left_xml)
    end

    if HasFile(right_xml) then
        local entities = Spawn(right_xml, Transform(), false, false)
        for _, e in ipairs(entities) do
            if GetEntityType(e) == "body" then

                RemoveTag(e, "interact")
                SetTag(e, "unbreakable")
                SetBodyDynamic(e, true)

                for _, shape in ipairs(GetBodyShapes(e)) do
                    SetShapeCollisionFilter(shape, 0, 0)
                end

                npc.melee.weapons.right = e
                table.insert(npc.AllBodies, e)

                break

            end
        end
        npc.melee.weapons_right_tip = ExtractEntityByTag(entities, "melee_tip")
    else
        print("melee weapon file not found: ", right_xml)
    end

end


function npc_melee_manage_punch_attack(npc, dist)

    DebugCross(GetLightTransform(npc.melee.weapons_left_tip).pos, 1,0,0, 1)
    DebugCross(GetLightTransform(npc.melee.weapons_right_tip).pos, 1,0,0, 1)


    TimerRunTime(npc.melee.timer)
    if TimerConsumed(npc.melee.timer) then

        TimerResetTime(npc.melee.timer)
        npc.melee.timer.time = npc.melee.timer.time + (math.random()/2)
        npc.melee.swing_time = GetTime()

        PlaySound(npc.melee.sound_swing, npc.torsoPos, 2)

        if npc.ai.targeting.target and npc.ai.thinking.attacking.canShootAimPos and npc.ai.thinking.can_see then

            if npc.ai.targeting.target.type == TargetTypes.player then

                SetTag(GetRandomPairsValue(PlayerHitboxes), "QueriedDamage", RandomSpreadPercent25(npc.melee.punch_damage))
                SetFloat("level.advhealth.addShock", tonumber(GetString("level.advhealth.addShock")) + 1)
                SetPlayerVelocity(VecAdd(GetPlayerVelocity(), VecScale(VecNormalize(VecSub(PlayerPos, npc.torsoPos)), RandomSpreadPercent25(math.random(5,8)))))

            elseif npc.ai.targeting.target.type == TargetTypes.torso then

                if npc.melee.weapons then

                    if npc.melee.weapons.left then
                        local holePos = GetLightTransform(npc.melee.weapons_left_tip).pos
                        DebugCross(holePos, 1,0,0, 1)
                        MakeHole(holePos, 1)
                    end

                    if npc.melee.weapons.right then
                        local holePos = GetLightTransform(npc.melee.weapons_right_tip).pos
                        DebugCross(holePos, 1,0,0, 1)
                        MakeHole(holePos, 1)
                    end

                end

            end

        end

    end

end

function npc_melee_hold_weapons(npc)

    if npc.melee.weapons then

        if npc.melee.weapons.left then

            local l_armTr = GetBodyTransform(npc.L_ARM)

            ConstrainPosition(npc.melee.weapons.left, npc.Torso, GetBodyTransform(npc.melee.weapons.left).pos, npc_get_hand_pos(npc.hands.left))
            ConstrainOrientation(npc.melee.weapons.left, npc.Torso, GetBodyTransform(npc.melee.weapons.left).rot, l_armTr.rot)

            -- DebugLine(GetBodyTransform(npc.melee.weapons.left).pos, npc.torsoTr.pos, 1,0,0, 1)
            -- DrawBodyOutline(npc.melee.weapons.left, 1,0,0,1)
            -- DebugCross(GetBodyTransform(npc.melee.weapons.left).pos, 1, 1, 0, 1)

        end

        if npc.melee.weapons.right then

            local r_armTr = GetBodyTransform(npc.R_ARM)

            ConstrainPosition(npc.melee.weapons.right, 0, GetBodyTransform(npc.melee.weapons.right).pos, npc_get_hand_pos(npc.hands.right))
            ConstrainOrientation(npc.melee.weapons.right, 0, GetBodyTransform(npc.melee.weapons.right).rot, r_armTr.rot)

            -- DebugLine(GetBodyTransform(npc.melee.weapons.right).pos, npc.torsoTr.pos, 1,0,0, 1)
            -- DrawBodyOutline(npc.melee.weapons.right, 1,0,0,1)
            -- DebugCross(GetBodyTransform(npc.melee.weapons.right).pos, 1, 1, 0, 1)

        end

    end

end

---@param npc table
---@param use_left_hand boolean
---@param use_right_hand boolean
---@param uppercut boolean Whether the npc punches up or down.
function npc_melee_manage_punch_animation(npc, use_left_hand, use_right_hand, uppercut)

    local l_armTr           = GetBodyTransform(npc.L_ARM)
    local r_armTr           = GetBodyTransform(npc.R_ARM)

    local l_hipPos          = TransformToParentPoint(GetBodyTransform(npc.Torso), Vec(-0.45, 0, -0.3))
    local r_hipPos          = TransformToParentPoint(GetBodyTransform(npc.Torso), Vec(0.45, 0, -0.3))

    local l_shoulderPos     = TransformToParentPoint(GetBodyTransform(npc.Torso), Vec(-0.45, 0.6, -0.5))
    local r_shoulderPos     = TransformToParentPoint(GetBodyTransform(npc.Torso), Vec(0.45, 0.6, -0.5))

    -- DebugCross(l_shoulderPos, 1,1,0, 1)
    -- DebugCross(r_shoulderPos, 1,1,0, 1)

    -- DebugCross(l_hipPos, 1,0,1, 1)
    -- DebugCross(r_hipPos, 1,0,1, 1)

    -- DebugWatchNPC(npc, "npc.melee.swing_time", npc.melee.swing_time)

    -- Direction to swing.
    local swingUp = ternary(uppercut,
        GetTime() - npc.melee.swing_time < 0.5,
        GetTime() - npc.melee.swing_time > 0.5)

    if swingUp then
        if use_left_hand then ConstrainPosition(npc.L_ARM, npc.Torso, l_armTr.pos, l_shoulderPos, 5) end
        if use_right_hand then ConstrainPosition(npc.R_ARM, npc.Torso, r_armTr.pos, r_shoulderPos, 5) end
    else
        if use_left_hand then ConstrainPosition(npc.L_ARM, npc.Torso, l_armTr.pos, l_hipPos, 10) end
        if use_right_hand then ConstrainPosition(npc.R_ARM, npc.Torso, r_armTr.pos, r_hipPos, 10) end
    end

end

function npc_release_melee_weapons(npc)
    if npc.melee.weapons then
        for _, shape in ipairs(GetBodyShapes(npc.melee.weapons)) do
            SetShapeCollisionFilter(shape, 1, 1)
        end
    end
end

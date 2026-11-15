function npc_get_mass(npc)
	local m = 0
	for _, body in ipairs(npc.bodyparts) do
		m = m + GetBodyMass(body)
	end
	return m
end

function npc_get_voxels(npc)
	local v = 0
	for _, body in ipairs(npc.bodyparts) do
		for _, shape in ipairs(GetBodyShapes(body)) do
			v = v + GetShapeVoxelCount(shape)
		end
	end
	return v
end

function npc_smoke()
	--spawn sparks
	ParticleReset()
	ParticleType("smoke")
	ParticleColor(0.3, 0.3, 0.3)
	ParticleRadius(0.2, 0.4)
	ParticleAlpha(1, 0)
	ParticleCollide(1)
	ParticleGravity(-1)
	ParticleSticky(0)
	ParticleDrag(0.5)
	ParticleStretch(1)
	SpawnParticle(obog, Vec(0, 0, 0), 3)
	ParticleReset()
end

function tick_timers()
	Sound_Timers.hitmarker.time = Sound_Timers.hitmarker.time - GetTimeStep()
	UI_Timers.hitmarker.time = UI_Timers.hitmarker.time - GetTimeStep()
end

-- Check if the torso is facing the target within an specified angle range.
function npc_is_angle_valid(npc)
	-- Check if npc facing aim pos.
	local ang_torsoToPlayer = DirLookAt(npc.torsoTr.pos, npc.ai.aimPos)
	local ang_torsoToFwd = TransformToParentVec(npc.torsoTr, Vec(0,0,-1))
	return VecAngle(ang_torsoToPlayer, ang_torsoToFwd) < npc.ai.thinking.attacking.minAimAngle
end

BountyBoardPaths = {

	mil = "savegame.mod.bountyboard.Military",
	civ = "savegame.mod.bountyboard.Insurgent",
	cult = "savegame.mod.bountyboard.Cultist",
	um = "savegame.mod.bountyboard.UM",

	boss_civ = "savegame.mod.bountyboard.BossInsurgentC",
	boss_mil = "savegame.mod.bountyboard.BossMilitaryC",
	boss_cult = "savegame.mod.bountyboard.BossCultistC",

	-- savegame.mod.bountyboard.BossUnisC
	-- savegame.mod.bountyboard.BossDuoC
	-- savegame.mod.bountyboard.BossTriaC
	-- savegame.mod.bountyboard.BossQuattuorC
	-- savegame.mod.bountyboard.bingus
}


	-- ---@param body number Body of the limb.
-- ---@param fn_rel_pos table Function that finds the relative position of the pos on the body.
-- ---@param mass_death_percentage number NPC will die if limb loses this % of mass compared to start mass.
-- ---@return table
-- function npc_CreateLimb(body, fn_rel_pos, mass_death_percentage)
--     return {
--         body = body,
--         -- mass = --todo Add new mass system to npcs
--         relative_pos = TransformToLocalPoint(GetBodyTransform(body), fn_rel_pos(body))
--     }
-- end

-- ---Object which tracks the changes in mass of a body.
-- ---@param body any
-- ---@param mass_death any
-- ---@return table
-- function Mass_Create(body, mass_death)
--     local mass = GetBodyMass(body)
--     return {
--         mass_start = mass,
--         mass_death = mass_death,
--         mass       = mass,
--         mass_last  = mass,
--     }
-- end


function npc_process_stun(npc)

	if GetTime() - npc.spawn_time < 0.5 then
		return
	end

	local isNpcStunned = VecLength(GetBodyVelocity(npc.Torso)) > npc.ai.stun.velocity

	if not isNpcStunned then

		npc.ai.shooting = config.goreai.shoot
		npc.ai.moving = config.goreai.movement
		npc.ai.timers.reposition.rpm = 60 / GetFloat("savegame.mod.config.goreai.reposition_timer")

	end

	if npc.ai.stun.duration > 0 then
		for _, foot in ipairs(npc.feet) do
			for _, shape in ipairs(GetBodyShapes(foot.body)) do
				SetShapeCollisionFilter(shape, 4, 255-4)
			end
		end
	else
		for _, foot in ipairs(npc.feet) do
			for _, shape in ipairs(GetBodyShapes(foot.body)) do
				SetShapeCollisionFilter(shape, 0, 0)
			end
		end
	end

end


--- Keeps the npc's mouth closed. Can be modified to make npcs look like they're talking.
function npc_constrain_jaw(npc)
    if npc.Jaw then

		local headTr = GetBodyTransform(npc.Head)
        local jawTr = GetBodyTransform(npc.Jaw)
        local targetTr = TransformToParentTransform(headTr, npc.limbInitTransforms.Jaw)

        ConstrainPosition(npc.Jaw, npc.Head, jawTr.pos, targetTr.pos)
        ConstrainOrientation(npc.Jaw, npc.Head, jawTr.rot, targetTr.rot)

    end
end


function npc_constrain_head_towards_pos(npc, pos, opt_max_angle)

	local headTr = GetBodyTransform(npc.Head)
	opt_max_angle = opt_max_angle or 45

    if QuatAngle(headTr.pos, pos) < opt_max_angle then
        ConstrainOrientation(npc.Head, 0, headTr.rot, QuatLookAt(headTr.pos, pos), 3)
	else
        ConstrainOrientation(npc.Head, 0, headTr.rot, npc.torsoTr.rot, math.random() + 3)
    end

end

function npc_constrain_head_towards_target(npc)
	npc_constrain_head_towards_pos(npc, npc.ai.aimPos)
end


function npc_add_stun(npc, stunAmount)
	npc.ai.stun.duration = clamp(npc.ai.stun.duration + stunAmount, -1, npc.ai.stun.max)
end

function npc_clear_stun(npc)
	npc.ai.stun.duration = 0
end

-- Makes the npc more sloppy while taking damage (prevents constant stone wall, unfliching, terminator nerves of steel)
function npc_calculate_proficiency(npc, override)

	-- local override = 0.2
	-- if override then
	-- 	npc.proficiency = override
	-- 	return
	-- end

	local hitStrengthMult = math.random(10,25)/200

	if npc.ai.teams.team == NPC_TEAMS.mil.title
	or npc.ai.teams.team == NPC_TEAMS.um.title 
	or npc.isJuggernaut
    then
		hitStrengthMult = 0
	end

	local hitStrength = npc.health_damage_taken * hitStrengthMult
	npc.proficiency = npc.proficiency - hitStrength

	local recoveryMult = 0.25
	if npc.proficiency < 1 then
		npc.proficiency = clamp(npc.proficiency + (GetTimeStep() * recoveryMult), 0.1, 1)
	end

	-- DebugWatch("npc.proficiency", npc.proficiency)
	-- DebugWatch("hitStrengthMult", hitStrengthMult)

	if npc.ai.stun.duration > 0 then
		return
	elseif npc.proficiency < 0.2 then
		npc_add_stun(npc, 0.2)
	end

end

function npc_swap_helmet(npc)

	local helmets = {
		"MOD/npcs/GoreNPCs/prefabs/extras/helmet_civ_atlyn.xml",
		"MOD/npcs/GoreNPCs/prefabs/extras/helmet_mil.xml",
		"MOD/npcs/GoreNPCs/prefabs/extras/helmet_um.xml",
	}

	for index, shape in ipairs(npc.helmet) do
		Delete(shape)
	end

    local entities = Spawn(GetRandomArrayValue(helmets), GetBodyTransform(npc.Head))
    for _, shape in ipairs(entities) do
        SetShapeBody(shape, npc.Head)
		SetShapeCollisionFilter(shape, 4, 255-4)
    end

	npc.helmet = entities

end





-- Reduce distances at night and sandstorm.
function npc_process_vision(npc, Dists)

    if IsSandstorm then

        --> There were no defined fog distances in sandstorm.lua so I just worked them out manually.
        Dists.attack = 25
        Dists.hunt = 45
        Dists.idle = 50

    else

        if (DayPhase == "Night" and not npc.nvg) then
            npc.ai.vision.lerp_amount = clamp(npc.ai.vision.lerp_amount + npc.ai.vision.lerp_rate*GetTimeStep(), 0, 1)
        else
            npc.ai.vision.lerp_amount = clamp(npc.ai.vision.lerp_amount - npc.ai.vision.lerp_rate*GetTimeStep(), 0, 1)
        end

        -- Apply vision scaling.
        for key, dist in pairs(Dists) do Dists[key] = Lerp(dist, dist/4,  npc.ai.vision.lerp_amount) end

    end

end


SEE_INTERVAL = 0.2 -- (2026-11-15) seconds between an npc's line-of-sight raycasts to its target

function npc_process_distances(npc, Dists, targetDist)

    -- Process NPC distance states.
    if targetDist < Dists.attack then

        npc.ai.thinking.states.dist = "ATTACK"
        -- (2026-11-15, performance, user OK) v1 read the interval with GetFloat("savegame.mod.config.goreai.see_timer"),
        -- a key that is never written (the 0.5 default lives in the config table only): 0, so every npc raycast its
        -- line of sight every tick (~500 engine calls per frame). Now SEE_INTERVAL (5 checks per second).
        npc.ai.timers.check_see_player.rpm = SEE_INTERVAL -- see timer
        npc_process_see_target(npc)

    elseif targetDist < Dists.hunt then

        npc.ai.thinking.states.dist = "HUNT"
        npc.ai.timers.check_see_player.rpm = SEE_INTERVAL -- see timer (v1 meant 5x the attack interval; see above)
        npc_process_see_target(npc)

    else

        npc.ai.thinking.states.dist = "IDLE"

    end

end


function npc_process_spawn_tags(npc)

    if npc_has_spawn_tags(npc) then

        if not npc.ai.spawnTags.outside then
            npc.ai.thinking.positioning.aggressive = config.goreai.aggressive
        end

        if not npc.ai.spawnTags.outside or NpcTeamsEnabled then
            npc.ai.thinking.positioning.aggressive = true
        end

        npc.ai.spawnTags.outside = ternary(npc.ai.thinking.positioning.aggressive, true, false)

        npc.ai.grenades.enabled = not npc.ai.spawnTags.nogrenades

    else

        npc.ai.thinking.positioning.aggressive = config.goreai.aggressive

    end

end

-- Raycast to check if anything blocks the npc's line of sight to the position.
function npc_check_if_can_see_target(npc, opt_pos)

    local lookSource = AabbGetBodyCenterPos(npc.Head)
    local lookTarget = opt_pos or VecCopy(npc.ai.aimPos)
    local lookTr = Transform(lookSource, QuatLookAt(lookSource, npc.ai.aimPos))

    local playerIsTarget = npc.ai.targeting.target.type == TargetTypes.player

    if npc.ai.targeting.target then

        if npc.ai.targeting.target.body then
            QueryRejectBody(npc.ai.targeting.target.body) -- Reject target body
        end

        if playerIsTarget then

            local headPos = VecAdd(PlayerPos, VecRandom(0.25))
            headPos[2] = headPos[2] + (math.random(-1, 1) * 0.6)

            lookTr = Transform(lookSource, QuatLookAt(lookSource, headPos))
            lookTarget = headPos

            if GetPlayerVehicle(GoreP) ~= 0 then QueryRejectVehicle(GetPlayerVehicle(GoreP)) end

        end

    end

    if npc.ai.sitting.isSitting then QueryRejectVehicle(GetPlayerVehicle(GoreP)) end
    RejectAllBodies(NPC_Bodies)
    RejectAllBodies(npc.AllBodies)
    RejectAllShapes(npc.AllShapes)
    for _, p in ipairs(GorePlayerIds) do -- (v2 goreai) every player's grabbed body and tool
        QueryRejectBody(GetPlayerGrabBody(p))
        QueryRejectBody(GetToolBody(p))
    end
    local hit, pos, shape, body = RaycastFromTransform(lookTr, VecDist(lookSource, lookTarget), nil, nil, nil, true, true)

    -- if config.goreai.draw_combat then
    --    DebugRay(lookTr, VecDist(lookSource, lookTarget), 1,1,0, 1)
    -- end

    return not hit

end

--- Check if npc can see player.
function npc_process_see_target(npc, opt_pos)

    TimerRunTime(npc.ai.timers.check_see_player)

    if TimerConsumed(npc.ai.timers.check_see_player) then
        TimerResetTime(npc.ai.timers.check_see_player)

        if npc.ai.targeting.target then

            local seen = npc_check_if_can_see_target(npc, opt_pos)

            npc.ai.thinking.can_see = seen

            if seen then npc.ai.thinking.seen_last_timestamp = GetTime() end

        end

    end

    npc.ai.thinking.seen_last = GetTime() - npc.ai.thinking.seen_last_timestamp

    npc.ai.thinking.seen_time = clamp(npc.ai.thinking.seen_time + ternary(npc.ai.thinking.can_see, GetTimeStep(), -GetTimeStep()), 0, 2)

end


--- Check if npc is blocked by a friendly or explosive is in the way.
function npc_process_attack_blocked(npc)

    if npc.ai.thinking.seen_last > 0.5 then

        -- if npc.ShouldCheckBlocked then

            npc.ai.thinking.attacking.blocked = npc_aiming_at_friendly(npc, npc.ai.thinking.attacking.friendly_fire_angle)
                -- or npc_GetGunBlockedByObject(npc) -- Process friendly fire
            -- npc.ai.thinking.attacking.blocked = npc_GetExplosivesInLineOfSight(npc, npc.Torso, npc.ai.thinking.attacking.friendly_fire_angle) -- Process friendly fire

            npc.ai.thinking.states.shoot = ternary(npc.ai.thinking.attacking.blocked, "Blocked by homie/explosive", "Blasting fools")
            npc.ai.thinking.states.shoot = ternary(npc.reloading, "Reloading", npc.ai.thinking.states.shoot)

        -- end

    end

end

---Check if the angle between Torsos
---@param Torso number
---@param maxAngle number
---@return boolean blocked Line of sight is blocked
function npc_aiming_at_friendly(npc, maxAngle)

    for index, otherNpc in pairs(NPCs) do

        local otherTorso = otherNpc.Torso

        if otherTorso ~= npc.Torso then

            if not otherNpc.dead then

                local otherTorsoTr = GetBodyTransform(otherNpc.Torso)

                local GunFwdDir = TransformToParentVec(GetBodyTransform(npc.Gun.body), Vec(0,0,-1))
                local GunToTorsoDir = DirLookAt(GetBodyTransform(npc.Gun.body).pos, npc.torsoPos)

                local blocked =
                    VecDist(npc.torsoPos, otherTorsoTr.pos) < npc.ai.thinking.attacking.friendly_fire_dist -- Close enough to matter.
                    and VecDist(npc.ai.aimPos, otherTorsoTr.pos) < VecDist(npc.ai.aimPos, npc.torsoPos)
                    and VecDist(npc.torsoPos, GunToTorsoDir.pos) < 1 -- Not closer to one another.
                    and VecAngle(GunFwdDir, GunToTorsoDir) < maxAngle

                if NpcTeamsEnabled then
                    blocked = blocked and npc.ai.teams.team ~= otherNpc.ai.teams.team
                end

                if blocked then

                    if ShouldDrawDebug then
                        DrawLine(npc.torsoPos, otherTorsoTr.pos, 1, 1, 0, 1)
                        DrawBodyOutline(otherTorso, 1, 0, 0, 1)
                    end

                    return true

                end

            end

        end

    end

    return false

end

function npc_GetGunBlockedByObject(npc)

    -- if npc.Gun and TICK % (30 + (math.random(15, 30))) == 0 then

        -- print(sfnTime())

        npc.Gun.shootTr = GetBodyTransform(npc.Gun.body)
        npc.Gun.shootTr.rot = QuatRotateQuat(npc.Gun.shootTr.rot, QuatEuler(0, 180, 0))
        npc.Gun.shootTr.pos = TransformToParentPoint(npc.Gun.shootTr, Vec(0,0,-1))
        DebugRay(npc.Gun.shootTr, 1, 1,1,1,1)

        RejectAllBodies(NPC_Bodies)
        local hit = RaycastFromTransform(npc.Gun.shootTr, 5)
        return hit

    -- end

end

function npc_aiming_at_explosive(npc, Torso, maxAngle)

    for index, exp in ipairs(AllExplosiveShapes) do

        local expTr = GetShapeWorldTransform(exp)

        local TorsoToPlayer = DirLookAt(npc.ai.aimPos, expTr.pos)
        local expToTorso = DirLookAt(npc.ai.aimPos, npc.torsoTr.pos)
        local angle = VecAngle(TorsoToPlayer, expToTorso)

        local blocked =
            angle < maxAngle
            and VecDist(npc.torsoTr.pos, expTr.pos) < 15 -- Close enough to matter.

        if blocked then

            if ShouldDrawDebug then
                DrawLine(npc.torsoTr.pos, expTr.pos, 1, 1, 0, 1)
                DrawShapeOutline(Torso, 1, 1, 0, 1)
                DrawShapeOutline(exp, 1, 0, 0, 1)
            end

            return true

        end

    end

    return false

end

-- (2026-11-15, NPC performance) v1 re-tagged every bone of every npc each tick. Now an npc's bones are tagged when
-- it first appears or the setting changes (npc.bonesSetting): the same tags, set once.
function tick_bones()

    local setting = config.goreai.unbreakable_bones

    if setting == 0 then

        for _, npc in pairs(NPCs) do
            if npc.bones and npc.bonesSetting ~= setting then
                npc.bonesSetting = setting
                if #npc.bones >= 1 then
                    for _, s in ipairs(npc.bones) do
                        if HasTag(s, "bone") then RemoveTag(s, "unbreakable") end
                    end
                end
            end
        end
        -- config.goreai.unbreakable_bones = 0
        -- print("bones set to: unbreakable")

    elseif setting == 2 then

        for _, npc in pairs(NPCs) do
            if npc.bones and npc.bonesSetting ~= setting then
                npc.bonesSetting = setting
                if #npc.bones >= 1 then
                    for _, s in ipairs(npc.bones) do
                        if HasTag(s, "bone") then SetTag(s, "unbreakable") end
                    end
                end
            end
        end
        -- config.goreai.unbreakable_bones = 2
        -- print("bones set to: breakable")

    end

end

function npc_shoot_target(npc)
    npc.ai.config.attack = true
    npc.ai.lookPos = VecCopy(npc.ai.shootPos)
end

function npc_stop_attacking(npc)
    npc.ai.config.attack = false
end


---@param npc table npc
---@param pos table World pos to stand at.
function npc_move_to_pos(npc, pos, opt_zero_vel)

    local groundPos = truncateToGround(pos, npc.AllBodies) or Vec(0,0,0)

    for _, b in ipairs(npc.AllBodies) do

        SetBodyTransform(b, Transform(groundPos))

        if opt_zero_vel then
            SetBodyVelocity(b, Vec(0,0,0))
        end

    end

    SetBodyTransform(b, GetBodyTransform(b).pos)

end
TargetTypes = {
    player  = "player",
    torso   = "torso",
    vehicle = "vehicle",
}


function npc_init_targeting(npc)
    npc.ai.targeting = {
        target = nil,
        recheck_timer = TimerCreateSeconds(2 + math.random()),
        target_history = {},
        target_history_max = 5
    }
end


--- Choose when to switch targets. --todo Improve target prioritization.
function npc_process_targetting(npc)

    TimerRunTime(npc.ai.targeting.recheck_timer) -- Check for new target randomly. Helps to keep enemies relevant.

    if VecDist(npc.torsoPos, npc.ai.aimPos) > npc.ai.thinking.distances.attack/2 then
        TimerRunTime(npc.ai.targeting.recheck_timer) -- check more frequently.
    end


    if npc.ai.thinking.seen_last > 5 then
        TimerRunTime(npc.ai.targeting.recheck_timer)
    end

    if VecDist(npc.torsoPos, PlayerPos) < npc.ai.thinking.distances.attack/2 then
        TimerRunTime(npc.ai.targeting.recheck_timer)
    end


    if not npc.ai.targeting.target then --> Find a target if npc does not have one.

        npc_find_random_enemy(npc, IncludePlayer)

    elseif not npc.ai.targeting.target.isAlive then --> Find a new target if the current one is dead.

        npc_find_random_enemy(npc, IncludePlayer)

    elseif TimerConsumed(npc.ai.targeting.recheck_timer) or npc.took_damage then --> Target timer has been consumed.

        TimerResetTime(npc.ai.targeting.recheck_timer)
        npc_find_random_enemy(npc, IncludePlayer)

    else --> Manage the target based on its type.

        if npc.ai.targeting.target.type == TargetTypes.player then npc_manage_target_player(npc)
        elseif npc.ai.targeting.target.type == TargetTypes.torso then npc_manage_target_torso(npc)
        elseif npc.ai.targeting.target.type == TargetTypes.vehicle then npc_manage_target_vehicle(npc)
        end

        npc.ai.targeting.target.distToTarget = VecDist(npc.ai.aimPos, npc.torsoPos)

    end

end

--- Finds the most appropriate enemy based on threat level and distance.
function npc_find_random_enemy(npc, include_player)

    -- print("Checked for new target", sfnTime())

    -- Find a random heli enemy if one exists
    local selectedHeli = nil
    -- (2026-11-15, NPC performance) v1 searched the whole level for "Heli" bodies once per call (per npc); once
    -- per tick is the same list (goreai_main.lua clears GoreHelisTick each tick)
    if not GoreHelisTick then GoreHelisTick = FindBodies("Heli", true) end
    local helis = GoreHelisTick
    if #helis >= 1 then
        for index, body in ipairs(helis) do
            if not HasTag(body, "dead") and npc.ai.teams.team ~= GetTagValue(body, "team") then
                selectedHeli = body
            end
        end
    end

    -- Check all npcs distances to player.
    local closestEnemyTorso = { torso = nil, minDist = math.huge }
    for index, other_npc in pairs(NPCs) do
        if npc ~= other_npc and not other_npc.dead then -- Check if not same npc.
            if (npc.ai.teams.team ~= other_npc.ai.teams.team) then -- Check if different team.
                local dist = VecDist(GetBodyTransform(npc.Torso).pos, GetBodyTransform(other_npc.Torso).pos)
                if dist < closestEnemyTorso.minDist and dist < npc.ai.thinking.distances.hunt then
                    closestEnemyTorso.torso = other_npc.Torso
                    closestEnemyTorso.minDist = dist
                end
            end
        end
    end

    -- Randomly choose player as target if close to npc.
    if include_player and not npc.isFriendly then

        local isPlayerBesideEnemy = VecDist(GetPlayerTransform(GoreP).pos, npc.torsoPos) < 10
        local isPlayerCloseToEnemy = VecDist(GetPlayerTransform(GoreP).pos, npc.torsoPos) < closestEnemyTorso.minDist*2

        if isPlayerBesideEnemy then
            npc.ai.targeting.target = create_teams_target(TargetTypes.player)
        elseif math.random() < RandomSpreadPercent50(0.5) and isPlayerCloseToEnemy then
            npc.ai.targeting.target = create_teams_target(TargetTypes.player)
        elseif closestEnemyTorso.torso then
            npc.ai.targeting.target = create_teams_target(TargetTypes.torso, closestEnemyTorso.torso)
        end

        if selectedHeli then
            if VecDist(GetBodyTransform(selectedHeli).pos) < 50 and math.random() < 0.5 then
                npc.ai.targeting.target = create_teams_target(TargetTypes.torso, selectedHeli)
            end
        end

    else

        npc.ai.targeting.target = create_teams_target(TargetTypes.torso, closestEnemyTorso.torso)

        if selectedHeli then
            if VecDist(GetBodyTransform(selectedHeli).pos) < 50 and math.random() < 0.6 then
                npc.ai.targeting.target = create_teams_target(TargetTypes.torso, selectedHeli)
            end
        end

    end

    if selectedHeli then
        if npc.Gun then
            if npc.Gun.class == GUN_CLASSES.rpg then -- RPG npcs always target helis
                npc.ai.targeting.target = create_teams_target(TargetTypes.torso, selectedHeli)
            end
        end
    
    end

    -- if currentTarget and currentTarget.type == TargetTypes.torso then -- Manage target history.
    --     while #npc.ai.targeting.target_history > npc.ai.targeting.target_history_max do
    --         table.remove(npc.ai.targeting.target_history, 1) -- trim oldest targets.
    --     end
    -- end

end

-- function npc_target_history_add(npc, target)
--     -- TableInsertUnique(npc.ai.targeting.target_history, target)
--     -- table.insert(npc.ai.targeting.target_history, target) -- transfer last target to history if new target exists.
-- end



function npc_process_target(npc)

    if NpcTeamsEnabled then --> Choose targets based on team.

        npc_process_targetting(npc)

    else --> Always attack the player if teams disabled.

        npc.ai.targeting.target = create_teams_target(TargetTypes.player)
        npc_manage_target_player(npc)

    end

end

--- A new target object is created each time an npc switches targets.
function create_teams_target(type, body)

    local target = {
        type    = type,
        isAlive = true,
        body    = body,
    }

    if type ~= TargetTypes.player and (body == 0 or body == nil) then
        return nil
    else
        return target
    end

end

--- Used to target the player only.
function npc_manage_target_player(npc)

    npc.ai.targeting.target.isAlive = GetPlayerHealth(GoreP) > 0 -- (v2 goreai) GoreP = this npc's target player
    npc.ai.aimPos = PlayerPos

    if npc.Gun then
        if npc.ai.thinking.seen_time > 0.5 then
            -- if GetPlayerVehicle() == 0 then
            npc.ai.shootPos = GoreAI_PlayerTrackingPos(PlayerPos, GetBodyTransform(npc.Gun.body).pos, npc.velocity)
            -- else
                -- npc.ai.shootPos = GetVehicleTrackingPos(GetPlayerVehicle(), GetBodyTransform(npc.Gun.body).pos, npc.velocity)
            -- end
        end
    end

end

--- (v2) TDSU GetPlayerTrackingPos with the context player's velocity (it used the host's).
function GoreAI_PlayerTrackingPos(playerPos, source_pos, vel_len)
    local scale = VecDist(source_pos, playerPos) / vel_len
    return VecAdd(playerPos, VecScale(GetPlayerVelocity(GoreP), scale))
end

--- Used for targetting other npc torsos.
function npc_manage_target_torso(npc)

    npc.ai.targeting.target.isAlive = not HasTag(npc.ai.targeting.target.body, "dead") or not IsHandleValid(npc.ai.targeting.target.body)

    npc.ai.aimPos = AabbGetBodyCenterPos(npc.ai.targeting.target.body)
    if npc.Gun then
        if npc.ai.thinking.seen_time > 0.5 then
            npc.ai.shootPos = GetBodyTrackingPos(npc.ai.targeting.target.body, GetBodyTransform(npc.Gun.body).pos, npc.velocity)
        end
    end

end

-- Used for vehicle npcs like cars, tanks and helicopters.
function npc_manage_target_vehicle(npc)

    local vehicle = GetBodyVehicle(npc.ai.targeting.target.body)

    -- npc.ai.targeting.target.isAlive = not HasTag(vehicle, "dead")
    npc.ai.targeting.target.isAlive = GetVehicleHealth(vehicle) > 0.25

    -- npc.ai.aimPos = TransformToParentPoint(GetVehicleTransform(vehicle), GetBodyCenterOfMass(GetVehicleBody(vehicle)))

    npc.ai.aimPos = GetVehicleTransform(vehicle).pos
    if npc.Gun then
        if npc.ai.thinking.seen_time > 0.5 then
            npc.ai.shootPos = GetVehicleTrackingPos(vehicle, GetBodyTransform(npc.Gun.body).pos, npc.velocity)
        end
    end

end

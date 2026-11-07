function npc_process_thinking(npc, dt)

    if MapMoved then
        return
    end

    local Dists = DeepCopy(npc.ai.thinking.distances)

    local targetDist = math.huge
    if npc.ai.targeting.target then
        targetDist = VecDist(npc.torsoPos, npc.ai.aimPos)
    end

    npc_process_vision(npc, Dists)
    npc_process_distances(npc, Dists, targetDist)

    -- local aggressive = false
    -- if npc.Gun then
    --     aggressive = npc.Gun.class == GUN_CLASSES.shotgun or npc.Gun.class == GUN_CLASSES.smg
    --     npc_process_attack_blocked(npc) --todo switch blocked and can_see to run raycasts less often.
    -- end

    if npc.Gun then
        npc_process_attack_blocked(npc) --todo switch blocked and can_see to run raycasts less often.
    end


    -- local aggressive = npc.ai.thinking.positioning.aggressive
    -- local runAndShoot = npc.ai.thinking.positioning.runAndShoot
    local runAndShoot = true
    local pathBusy = npc.navigation.GetPathState == "busy"

    npc_process_spawn_tags(npc)

    npc.ai.thinking.attacking.canShootAimPos = npc_is_angle_valid(npc)
    npc.melee.swing_time = npc.melee.swing_time or 0

    local isFacingTarget = npc.ai.thinking.attacking.canShootAimPos

    local bypass_friendly_processing = false


    if npc.isMelee then -- NPCs solely dedicated to melee behavior. Regular npcs will melee with their free hand.

        npc_melee_manage_punch_animation(npc, true, true, false)

        if #npc.nav.path <= 0 then

            if VecDist(npc.torsoTr.pos, npc.ai.aimPos) < 1 then

                npc.ai.thinking.state = "In Position"

                npc_melee_manage_punch_attack(npc)
                npc_stand_still(npc)

            elseif VecDist(npc.torsoTr.pos, npc.ai.aimPos) < 3 then

                npc_melee_manage_punch_attack(npc)
                npc.run = true
                npc.running = true
                npc.ai.moving = true

            elseif not pathBusy and IsTickInterval(UPDATE, 0.25) then -- npc needs to navigate.

                npc.ai.thinking.state = "Needs to navigate"
                npc_reposition_normal(npc, npc.ai.aimPos)

            end

            headTurnTowards(npc, npc.ai.aimPos)
            robotTurnTowards(npc, npc.ai.aimPos)
            npc_turn_towards(npc, npc.ai.aimPos)


        elseif #npc.nav.path > 0 then

            if VecDist(npc.nav.path[#npc.nav.path], npc.ai.aimPos) < 1 then

                npc_melee_manage_punch_attack(npc)
                npc_run_to_target_pos(npc)

                headTurnTowards(npc, npc.ai.aimPos)
                robotTurnTowards(npc, npc.ai.aimPos)
                npc_turn_towards(npc, npc.ai.aimPos)

            elseif VecDist(npc.nav.path[#npc.nav.path], npc.ai.aimPos) > 5 then

                npc.nav.path = {}
                TimerResetTime(npc.melee.timer)

            else

                npc.ai.thinking.state = "Running to nav pos"
                npc_run_to_target_pos(npc)
                TimerResetTime(npc.melee.timer)

            end

        end

    else

        local isMovingAway = #npc.nav.path >= 1 and VecDist(npc.nav.target, PlayerPos) > 10
        local isStandingFar = #npc.nav.path <= 0 and VecDist(npc.torsoPos, PlayerPos) > 10
        local isMovingCloser = #npc.nav.path >= 1 and VecDist(npc.nav.target, PlayerPos)

        if npc.isFriendly and IncludePlayer then

            -- DebugWatch("npc.ai.sitting.isSitting", npc.ai.sitting.isSitting)
            -- DebugWatch("npc.ai.sitting.sitVehicle", npc.ai.sitting.sitVehicle)
            -- DebugWatch("npc.ai.sitting.sitBody", npc.ai.sitting.sitBody)
            -- DebugWatch("npc.ai.sitting.sitLight", npc.ai.sitting.sitLight)
            -- DebugWatch("npc.ai.sitting.sitTr", npc.ai.sitting.sitTr)

            -- DebugWatchNPC(npc, "sitLight", npc.ai.sitting.sitLight)
            -- DebugWatch("SeatsTaken", SeatsTaken)

            -- Have npc enter seats.
            if GetPlayerVehicle(GoreP) ~= 0 then -- (v2 goreai) the target player (friendlies follow the nearest)

                if IsSeatingEnabled then
                    npc_sitting_process(npc)
                end

            else

                -- Exit vehicle when player is not in a vehicle.
                if npc.ai.sitting.isSitting then npc_sitting_exit_vehicle(npc) end

                -- Keep npc close to player on foot.
                if VecDist(npc.torsoPos, PlayerPos) > 15 and targetDist > 50 then -- Move towards player

                    bypass_friendly_processing = true

                    if isMovingAway or isStandingFar then -- Move to player if far away

                        local posOffset = AutoVecSubsituteY(VecRandom(10), 0)
                        local posNearPlayer = VecAdd(posOffset, PlayerPos)

                        npc_set_navigation_point(npc, posNearPlayer)

                    elseif isMovingCloser then

                        npc_run_to_target_pos(npc)

                        if npc.ai.thinking.can_see and npc.ai.thinking.attacking.canShootAimPos then -- Will run and shoot if player is in line of sight.
                            npc_shoot_target(npc)
                        else
                            npc_stop_attacking(npc)
                        end
                    end

                end
            end



            -- if config.db and npc.ai.sitting.isSitting then
            --     local exit_pos = get_vehicle_exit_pos(npc.ai.sitting.sitVehicle, GetLightTransform(npc.ai.sitting.sitLight).pos)
            --     DebugLine(npc.torsoPos, exit_pos, 1,1,1, 1)
            --     DrawDot(exit_pos, 0.25, 0.25, 1,0,1, 1)
            -- end

        end

        if not bypass_friendly_processing then

            -- Process stationary AI
            if npc.ai.thinking.takingCover or npc.ai.spawnTags.stationary then
                -- Stationary npcs do not move, ever. cover npcs move only when the player is close enough, then become regular npcs.

                if targetDist < Dists.hunt then

                    npc.ai.thinking.state = "Cover fire / stationary fire"

                    npc_turn_towards(npc, npc.ai.aimPos)
                    npc_stand_still(npc)

                    if npc.ai.thinking.can_see then
                        npc_shoot_target(npc)
                    else
                        npc_stop_attacking(npc)
                    end

                    if targetDist < npc.ai.thinking.coverDist or npc.took_damage or (npc.ai.thinking.seen_time > 0.1 and targetDist < npc.ai.thinking.coverDist * 3) then
                        npc.ai.thinking.takingCover = false -- Stop taking cover and become a regular npc.
                    end

                else

                    TimerRunTime(npc.ai.thinking.coverTimer)
                    npc_stop_attacking(npc)

                end

            else -- Process regular AI

                if targetDist <= Dists.attack then -- Attack dist

                    if #npc.nav.path <= 0 then -- npc is at nav pos and does not need to navigate.

                        if npc.ai.thinking.seen_last < 3 then

                            npc.ai.thinking.state = "In Position"

                            npc_shoot_target(npc)

                            npc_strafing_check(npc)
                            TimerRunTime(npc.ai.strafing.timer_move)
                            if npc.ai.strafing.side ~= "none" and targetDist < 50 then
                                npc_strafing_process(npc)
                                npc.nav.target = VecCopy(npc.torsoPos)
                                -- npc.ai.navPos = npc.torsoPos
                            else
                                npc_stand_still(npc)
                            end

                            npc_turn_towards(npc, npc.ai.shootPos)

                            TimerRunTime(npc.ai.timers.reposition)
                            npc_check_if_should_reposition(npc)

                        elseif not pathBusy then -- npc needs to navigate.

                            npc.ai.thinking.state = "Can't See"

                            local cantSeeTarget = npc.ai.thinking.seen_last > npc.ai.thinking.cant_see_time_nav or not npc_is_in_position(npc)
                            -- local gunBlocked = npc.ai.thinking.attacking.blocked
                            local validQueryInterval = GetTime() - npc.navigation.lastNavigationTime > 2

                            -- if (cantSeeTarget or gunBlocked) and validQueryInterval then
                            if cantSeeTarget and validQueryInterval then
                                npc.navigation.lastNavigationTime = GetTime()
                                npc.ai.thinking.cant_see_time_nav = 1 + (math.random() * 2)
                                npc_reposition_normal(npc, npc.ai.aimPos, math.random(5,15))
                            end

                        end

                        if npc.ai.targeting.target then
                            npc_turn_towards(npc, npc.ai.shootPos)
                        end

                    elseif #npc.nav.path >= 1 then -- Agro with navigation points remaining.

                        npc.ai.thinking.state = "Aggressive Navigating"

                        if isFacingTarget and npc.ai.thinking.can_see then
                            npc_shoot_target(npc)
                        else
                            npc_stop_attacking(npc)
                        end

                        if isFacingTarget then
                            npc_run_to_target_pos(npc)
                        elseif npc.ai.thinking.seen_time >= 1 then
                            npc_clear_navigation(npc)
                        end

                    elseif npc.nav.GetPathState == "fail" then

                        npc.ai.thinking.state = "Stuck"

                        TimerRunTime(npc.ai.timers.reposition)
                        npc_check_if_should_reposition(npc)

                        npc_stop_attacking(npc)

                    else

                        npc.ai.thinking.state = "Just standing here tbh idek anymore"

                        npc_stand_still(npc)
                        npc_stop_attacking(npc)

                    end

                elseif targetDist <= Dists.hunt then -- Idle dist

                    npc.ai.thinking.state = "Aggressive Navigating"

                    if runAndShoot and npc.ai.thinking.can_see then -- Will run and shoot if player is in line of sight.
                        npc_shoot_target(npc)
                    else
                        npc_stop_attacking(npc)
                    end

                    --todo Redo timers becaues they suck.
                    -- Stop and shoot while approaching player, then continue path and repeat.
                    TimerRunTime(npc.ai.timers.agro_nav) -- Time until npc should stop and shoot.
                    if TimerConsumed(npc.ai.timers.agro_nav) and npc.ai.thinking.can_see then -- Activate stop and shoot if can see player.

                        npc.ai.thinking.states.shoot = "Pausing to light that ass up"

                        -- npc pauses to shoot before going back to navigating along path.
                        npc_shoot_target(npc)
                        npc_stand_still(npc)

                        TimerRunTime(npc.ai.timers.agro_shoot)
                        if TimerConsumed(npc.ai.timers.agro_shoot) then -- Finished shooting.

                            TimerResetTime(npc.ai.timers.agro_nav) -- Reset stand and shoot.
                            TimerResetTime(npc.ai.timers.agro_shoot) -- Reset stand and shoot.

                        end

                    else
                        npc_run_to_target_pos(npc)
                    end

                else -- Idle dist
                    npc_stand_idle(npc) -- Do nothing
                end

            end

        end

        --todo fix underlying bug
        if VecDist(npc.torsoPos, npc.nav.target) > 100 then
            npc_clear_navigation(npc)
            npc.nav.target = VecCopy(npc.torsoPos)
            npc.ai.navPos = VecCopy(npc.torsoPos)
        end

        if npc.ai.thinking.can_see then
            npc_constrain_head_towards_target(npc)
        end

        if npc.ai.targeting.target then

            npc_check_grenade_throwing(npc)

            if VecDist(npc.torsoPos, npc.ai.aimPos) < npc.melee.punch_dist and npc.ai.thinking.attacking.canShootAimPos then
                npc_melee_manage_punch_attack(npc)
                npc_melee_manage_punch_animation(npc, true, false, true)
            end

        else
            npc_stop_attacking(npc)
            npc_turn_towards(npc, npc.ai.aimPos)
        end

    end


    -- npc_process_friendlies_thinking(npc)


    -- if npc.took_damage then
    --     npc_clear_navigation(npc)
    --     npc_find_random_enemy(npc)
    -- end

    -- if npc.ai.thinking.attacking.blocked or (npc.running and not aggressive) then
    --     npc_stop_attacking(npc)
    -- end


    if not config.goreai.movement then
        npc_stand_idle(npc)
    end

end

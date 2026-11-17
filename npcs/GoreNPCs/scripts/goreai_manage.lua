#include "../../../ui/MainMenu/menu_settings.lua"


--- Run the tick() callback functions for all npcs.
function tick_npcs(dt)

    -- (2026-11-15) a hit reported since the last tick? (goreai_health.lua npc_process_shield) Taken and cleared HERE,
    -- before the npcs, so a hit written later in this tick (npc bullets, other scripts) is read on the next one.
    DamagePending = GetBool("level.goreai.damage_pending")
    if DamagePending then SetBool("level.goreai.damage_pending", false) end

    local aliveNPCs = {}
    local deadNPCs = {}

    local npcGuns = {}

    for _, npc in pairs(NPCs) do

        if npc.restDead then

            -- (2026-11-17, performance) a dead npc past its 3 s window (npc_rest_dead_tick)
            npc_rest_dead_tick(npc, deadNPCs)

        elseif npc_is_valid(npc) then

            npc.torsoTr      = GetBodyTransform(npc.Torso)
            npc.torsoPos     = AabbGetBodyCenterPos(npc.Torso)
            GoreAI_SetContext(npc) -- (v2 goreai) GoreP / PlayerPos = this npc's target player
            npc.disttoplayer = VecDist(npc.torsoPos, npc.ai.aimPos)

            npc.headshot     = false

            -- (2026-11-15, NPC performance) v1 recounted mass and voxels of every body / shape of every npc each
            -- tick. Mass is read nowhere after init (goreai_init.lua): no recount. Voxels feed only the health of
            -- LIVING npcs (goreai_health.lua: damage = voxels lost since last tick): counted for those only.
            npc.mass_last    = npc.mass
            npc.voxels_last    = npc.voxels
            -- (2026-11-15, user OK) and only every 3rd tick per npc (staggered): voxel loss between counts adds up and is
            -- applied at the next count (up to 2 ticks later); GYMP recounts every 10th update
            npc.voxelTick = (npc.voxelTick or ((tonumber(npc.id) or 0) % 3)) + 1
            if not npc.dead and (npc.voxels == nil or npc.voxelTick % 3 == 0) then
                npc.voxels         = npc_get_voxels(npc)
            end


            if not npc.dead then

                table.insert(aliveNPCs, npc)

                -- Health and Shield
                npc_process_health(npc)
                npc_process_shield(npc)

                -- Thinking
                if not IsControllerNPC(npc) and config.goreai.thinkingEnabled then
                    npc_process_stun(npc)
                    npc_process_aim_sway(npc, Controls.gunsway.value * npc.sway.mult)
                    npc_process_target(npc)
                    npc_manage_gun(npc)
                elseif IsControllerNPC(npc) then
                    npc_process_aim_sway(npc, 0)
                end

                -- (v2 goreai) npc_point_gun / npc_hold_gun (constraints) run in update_npcs: Constrain* in tick
                -- crashed the v2 engine.

                if npc.boss then
                    if npc.boss.isBoss then
                        if npc.boss.boss_preset.id == BossPresets.bingus.id then
                            npc_boss_bingus_tick(npc)
                        elseif npc.boss.boss_preset.id == BossPresets.cultist.id then
                            npc_boss_cult_tick(npc)
                        end
                    end
                end

            else -- NPC is dead

                if not npc.died then -- Only runs on the first tick of npc death.
                    npc.died = true
                    npc_die(npc)
                    npc_release_gun(npc)
                    npc_release_melee_weapons(npc)
                end

                table.insert(deadNPCs, npc)

                if npc.deadTime > 3 then -- Uninstantiate.
                    npc_mark_for_removal(npc)
                    if IsGoreMap then npc_delete_entities(npc) else npc.restDead = true end
                end

                npc.deadTime = npc.deadTime + GetTimeStep()

            end

            SetLightEnabled(npc.Light, DayPhase == "Night")

        end

        if config.db and false then -- (v2) debug: GetCrosshairWorldPos needs the camera (client only)
            if InputPressed("n") then
                npc_navigationClear(npc)
                npc_navigationSetTarget(npc, GetCrosshairWorldPos(), 3)
                beep()
            end
        end


        npc.health_damage_taken = 0 -- reset each tick

        -- if InputPressed("l") then
        --     npc_swap_helmet(npc)
        --     beep()
        -- end

        for key, shell in ipairs(npc.projectileHandler.shells) do
            if shell.active then
                npc_projectile_operations(npc, shell)
            end
        end

    end

    API_npcs_alive(aliveNPCs)
    API_npcs_dead(deadNPCs)

end


--- (2026-11-17, performance, user OK) A dead npc stays in NPCs until RemoveRoad deletes its torso behind the players
--- (tick_cleanup_leaks). Measured: each one still cost ~0.09 ms per frame in tick (all body parts checked twice per
--- tick, transform / bounds, the target-player pick with its raycasts, the light). Once past its 3 s dead window it
--- takes this path instead: same results for everything that reads it (in the deadNPCs list, torsoTr / torsoPos kept
--- current, deadTime, marked for removal, light follows day / night), but the full body-part check runs once a
--- second (the torso every tick), no target player is picked (nothing reads it for a dead npc) and the light is
--- only written when day / night changes. update_npcs_full's dead branch (killcam, loot tag) is unchanged.
function npc_rest_dead_tick(npc, deadNPCs)
    local now = GetTime()
    if not IsHandleValid(npc.Torso) then
        npc.isValid = false
    elseif now >= (npc.restCheckAt or 0) then
        npc.restCheckAt = now + 1
        -- position too only once a second: every reader of torsoTr / torsoPos works on its own (living) npc, and
        -- control of an npc ends 3 s after its death (goreai_controller.lua); per tick it was most of this path's
        -- garbage (~680 kB/s with 16 dead npcs)
        if npc_is_valid(npc) then
            npc.torsoTr  = GetBodyTransform(npc.Torso)
            npc.torsoPos = AabbGetBodyCenterPos(npc.Torso)
        end
        -- a dead npc no longer shoots: free its 150 projectile records once none is in flight (heap the garbage
        -- collector walks on every cycle)
        if not npc.restShellsFreed then
            local active = false
            for _, shell in ipairs(npc.projectileHandler.shells) do
                if shell.active then active = true break end
            end
            if not active then
                npc.projectileHandler.shells = {}
                npc.restShellsFreed = true
            end
        end
    end
    if npc.isValid then
        npc.headshot = false
        table.insert(deadNPCs, npc)
        npc_mark_for_removal(npc)
        npc.deadTime = npc.deadTime + GetTimeStep()
        local night = DayPhase == "Night"
        if npc.restLight ~= night then
            npc.restLight = night
            SetLightEnabled(npc.Light, night)
        end
    end
    npc.health_damage_taken = 0
    for _, shell in ipairs(npc.projectileHandler.shells) do
        if shell.active then npc_projectile_operations(npc, shell) end
    end
end


--- Run the update() callback functions for all npcs.
function update_npcs(dt)

    -- (2026-11-17) the frame's first physics step runs everything, the others re-apply its holds (goreai_stepreplay.lua)
    local frame = ConfigMemoGen
    if not StepReplayBegin(dt, frame) then
        for index, npc in pairs(NPCs) do
            if npc.isValid and not npc.dead and npc.replayFrame == frame and npc.replay then
                StepReplayApply(npc.replay)
            end
        end
        return
    end
    dt = GoreFrameDt
    local realTimeStep = GetTimeStep
    GetTimeStep = function() return GoreFrameDt end   -- per-step timers advance by the time this run covers
    local probe = GoreAlloc and GoreAlloc.stopped and collectgarbage("count") -- (2026-11-17, DEBUG) goreai_skip.lua
    local ok, err = pcall(update_npcs_full, dt, frame)
    if probe then GoreAllocFull = (GoreAllocFull or 0) + collectgarbage("count") - probe if not ok then GoreAllocErr = err end end
    GetTimeStep = realTimeStep
    StepReplayList = nil
    if not ok then error(err, 0) end
end

function update_npcs_full(dt, frame)

    for index, npc in pairs(NPCs) do

        if npc.isValid then

            GoreAI_SetContext(npc)

            StepReplayList = nil
            if not npc.dead then
                StepReplayList = {}
                npc.replay = StepReplayList
                npc.replayFrame = frame

                npc.HT = GetBodyTransform(npc.Head)

                local totalVel = VecLength(GetBodyVelocity(npc.Torso))
                if totalVel > npc.ai.stun.velocity then
                    npc_add_stun(npc, npc.ai.stun.duration_def + math.random())
                end

                npc_add_stun(npc,  -GetTimeStep()) -- Reduce stun over time.
                if not npc.ai.sitting.isSitting and npc.ai.stun.duration > 0 then

                    npc.ai.thinking.state = "Stunned " .. sfn(npc.ai.stun.duration)
                    npc_stop_attacking(npc)

                else

                    if not IsControllerNPC(npc) and config.goreai.thinkingEnabled then
                        npc_process_thinking(npc, dt)
                        npc_navigation_update(npc, dt)
                    else
                        npc_clear_navigation(npc)
                        npc.nav.path = {}
                    end

                    npc_constrain_head_towards_target(npc)
                    npc_constrain_jaw(npc)

                    if npc.ai.sitting.isSitting then
                        npc_pose_ragdoll(npc, npc_sitting_head_transform(npc), npc_sitting_pose(npc), npc.ai.sitting.sitBody) -- (v2 goreai) seat rig
                    else
                        npc_robot_update(npc, dt)
                        npc_run_assist(npc)
                    end

                end

                npc_melee_hold_weapons(npc)

                if npc.Gun and IsHandleValid(npc.Gun.body) then -- (v2 goreai) moved here from tick_npcs
                    npc_point_gun(npc)
                    npc_hold_gun(npc)
                end

            else

                set_lock_cam(npc) -- (v2) the killer's client checks its own killcam setting

                -- (2026-11-17, performance) only the killcam reads npc.HT and it reads the head itself now
                -- (goreai_killcam.lua): a settled dead npc skips the per-step transform
                if not npc.restDead then npc.HT = GetBodyTransform(npc.Head) end
                SetTag(npc.Loot, "interact", npc.enemyweapontag)

            end

        end

    end

end


function draw_npcs()
    if GetBool("level.deleteNPCs") or not IsGoreMap then
        return
    end
end

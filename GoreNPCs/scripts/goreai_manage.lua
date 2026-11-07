#include "../../scripts/UI/MainMenu/menu_settings.lua"


--- Run the tick() callback functions for all npcs.
function tick_npcs(dt)

    local aliveNPCs = {}
    local deadNPCs = {}

    local npcGuns = {}

    for _, npc in pairs(NPCs) do

        if npc_is_valid(npc) then

            npc.torsoTr      = GetBodyTransform(npc.Torso)
            npc.torsoPos     = AabbGetBodyCenterPos(npc.Torso)
            GoreAI_SetContext(npc) -- (v2 goreai) GoreP / PlayerPos = this npc's target player
            npc.disttoplayer = VecDist(npc.torsoPos, npc.ai.aimPos)

            npc.headshot     = false

            npc.mass_last    = npc.mass
            npc.mass         = npc_get_mass(npc)

            npc.voxels_last    = npc.voxels
            npc.voxels         = npc_get_voxels(npc)


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
                    if IsGoreMap then npc_delete_entities(npc) end
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


--- Run the update() callback functions for all npcs.
function update_npcs(dt)

    for index, npc in pairs(NPCs) do

        if npc.isValid then

            GoreAI_SetContext(npc)

            if not npc.dead then

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
                        npc_pose_ragdoll(npc, GetLightTransform(npc.ai.sitting.sitLight), RagdollPoses.sit, npc.ai.sitting.sitBody)
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

                npc.HT = GetBodyTransform(npc.Head)
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

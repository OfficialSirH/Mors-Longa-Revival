--- Query global npc data before processing npcs.
function tick_npcs_info()
    for key, npc in pairs(NPCs) do
        if npc_is_valid(npc) then
            if NPC_TEAMS[npc.ai.teams.team] == PlayerTeam then
                FriendliesCount = FriendliesCount + 1
                npc.isFriendly = true
            else
                npc.isFriendly = false
            end
        end
    end
end

function npc_process_friendlies_thinking(npc)

    -- local playerDist = VecDist(PlayerPos, npc.torsoPos)

    -- Look at player when nearby
    -- if npc.ai.targeting.target == nil and playerDist < 10 then
    --     npc_constrain_head_towards_pos(npc, PlayerPos)
    -- end

    -- -- Move to player if far away
    -- if npc.nav.path >= 1 then
    --     if VecDist(npc.ai.navPos, PlayerPos > 10) then
    --         npc_clear_navigation(npc)
    --         npc_reposition_normal(npc, PlayerPos, 5)
    --     end
    -- end

end

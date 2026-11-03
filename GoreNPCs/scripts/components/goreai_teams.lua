----------------------------------------------------------------
--
----------------------------------------------------------------

NPC_SPAWNERS = {}

NPC_TEAMS = {
    um      = { name = "United Mates",      title = "um",       ids = { "um", "pur" },  color = UiColors.blue },
    mil     = { name = "Alashyan Military", title = "mil",      ids = { "mil" },        color = UiColors.green },
    civ     = { name = "Insurgents",        title = "civ",      ids = { "civ" },        color = UiColors.yellow },
    cult    = { name = "Cultists",          title = "cult",     ids = { "cult" },       color = UiColors.red },
    merc    = { name = "Mercenary",         title = "merc",     ids = { "merc" },       color = UiColors.purple },
    none    = { name = "No Team",           title = "none",     ids = { "none" },       color = UiColors.grey },
}


PlayerTeam = NPC_TEAMS.merc
IncludePlayer = nil



function npc_init_teams(npc)

    npc.ai.teams = {
        active = NpcTeamsEnabled,
    }

    local spawn_team = GetTagValue(npc.Torso, "spawn_team") -- Team set at spawn.

    if spawn_team == nil or spawn_team == "" then

        npc.ai.teams.team = "none"
        SetTag(npc.Torso, "team", spawn_team)

    else

        npc.ai.teams.team = spawn_team
        SetTag(npc.Torso, "team", spawn_team)

    end

    -- Assign an initial target to the npc.
    npc.ai.targeting.target = npc_find_random_enemy(npc, false)

end

function tick_teams()

    if GetBool("level.goreai.resetTeams") then
        for index, npc in pairs(NPCs) do
            npc_find_random_enemy(npc, IncludePlayer)
            -- print("Reset enemy targets...")
        end
        SetBool("level.goreai.resetTeams", false) -- Reset delete check.
    end

end

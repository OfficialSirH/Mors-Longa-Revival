NPCS_API = {
    npcs_alive = "level.goreai.api.npcs.alive",
    npcs_dead = "level.goreai.api.npcs.dead",
    npcs_dead_id = "level.goreai.api.npcs.dead_id",
}

function API_npcs_alive(npcs)
    ClearKey(NPCS_API.npcs_alive)
    for index, npc in ipairs(npcs) do
        SetInt(NPCS_API.npcs_alive .. "." .. index, npc.Torso)
    end
end

function API_npcs_dead(npcs)
    ClearKey(NPCS_API.npcs_dead)
    for index, npc in ipairs(npcs) do
        SetInt(NPCS_API.npcs_dead .. "." .. index, npc.Torso)
        SetBool(NPCS_API.npcs_dead_id .. "." .. npc.id, true)
    end
end
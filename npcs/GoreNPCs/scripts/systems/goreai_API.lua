NPCS_API = {
    npcs_alive = "level.goreai.api.npcs.alive",
    npcs_dead = "level.goreai.api.npcs.dead",
    npcs_dead_id = "level.goreai.api.npcs.dead_id",
}

-- (v2 goreai) The torso lists are read by clients too (weapons/guns/Thermals.lua), so they are written with the
-- registry sync flag, and only when they change. Entries past the new end are set to 0 (clients may keep
-- keys the server cleared; readers skip 0) and then cleared.
local API_written = {}

local function API_write_torsos(base, npcs)
    local torsos = {}
    for index, npc in ipairs(npcs) do torsos[index] = npc.Torso end
    local sig = table.concat(torsos, ",")
    local last = API_written[base]
    if last and last.sig == sig then return end
    if not last then ClearKey(base) end
    for index, torso in ipairs(torsos) do
        SetInt(base .. "." .. index, torso, true)
    end
    for index = #torsos + 1, (last and last.count or 0) do
        SetInt(base .. "." .. index, 0, true)
        ClearKey(base .. "." .. index)
    end
    API_written[base] = { sig = sig, count = #torsos }
end

function API_npcs_alive(npcs)
    API_write_torsos(NPCS_API.npcs_alive, npcs)
end

function API_npcs_dead(npcs)
    API_write_torsos(NPCS_API.npcs_dead, npcs)
    for index, npc in ipairs(npcs) do
        SetBool(NPCS_API.npcs_dead_id .. "." .. npc.id, true)
    end
end
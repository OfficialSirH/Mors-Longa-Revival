-- (2026-11-15, NPC performance research, DEBUG ONLY) The NPC manager's hooks for lib/CallProfiler.lua: debug menu
-- "NPC call profile" (savegame.mod.debug.npcprofile, host). Counts every engine call of goreai_main (server) and
-- attributes it to the innermost NPC function below; the report goes to this script's clients in shared.npcProfile.

-- (2026-11-15, performance, NOT debug) `config` (lib/Config.lua) is a registry-backed table: every field read is a
-- HasKey + Get (HasKey was the 3rd most called engine function of the NPC manager, ~460 per frame with 8 npcs). The
-- values only change when the debug menu (another script) writes them, so here each field is read from the registry
-- once per frame (ConfigMemoGen, bumped in server.tick / client.tick) and reused for the rest of that frame; writes
-- go straight through. Nested tables (config.goreai, ...) are wrapped the same way.
ConfigMemoGen = 0
function MemoConfig(st)
    local values, gens, nested = {}, {}, {}
    return setmetatable({}, {
        __index = function(_, k)
            local n = nested[k]
            if n then return n end
            if gens[k] == ConfigMemoGen then return values[k] end
            local v = st[k]
            if type(v) == "table" then
                n = MemoConfig(v)
                nested[k] = n
                return n
            end
            values[k], gens[k] = v, ConfigMemoGen
            return v
        end,
        __newindex = function(_, k, v)
            st[k] = v
            values[k], gens[k] = v, ConfigMemoGen
        end,
    })
end

local function npcFunction(k)
    return k:match("^npc_") or k:match("^tick_") or k:match("^update_") or k:match("^robot") or k:match("^feet")
        or k:match("^hover") or k:match("Update$") or k:match("^GoreAI_") or k:match("^API_") or k:match("^navigation")
        or k:match("^Auto") or k:match("^process_") or k:match("^truncate") or k:match("^Reject")
end

function GoreProfile_Tick()
    local on = GetBool("savegame.mod.debug.npcprofile")
    local alive = 0
    if on then for _, npc in pairs(NPCs) do if not npc.dead then alive = alive + 1 end end end
    local report = CallProfile_Tick(on, npcFunction, math.max(1, alive))
    if not on then shared.npcProfile = nil
    elseif report then shared.npcProfile = report end
end

function GoreProfile_Draw()
    if not IsPlayerHost(GetLocalPlayer()) then return end
    CallProfile_DrawReport(shared.npcProfile, UiWidth() - 640, 110, "NPC manager (goreai_main, server)")
end

--- Delete dead npcs after a specified amount of time since its death.
function tick_deleting()

    if GetBool("level.deleteNPCs") then

        for index, npc in pairs(NPCs) do
            npc_delete_entities(npc)
            npc_mark_for_removal(npc)
        end

        NPCs = {}
        NPC_Torsos = {}

        -- elseif NpcTeamsEnabled and config.goreai.endless_battle then

        --     for index, npc in pairs(NPCs) do

        --         -- DrawBodyOutline(npc.Torso, 1,0,0, 1/2)

        --         SetTag(npc.Torso, "dead")

        --         if npc.deadTime > 3 then
        --             npc_Delete(npc)
        --             table.remove(NPC_Torsos, npc.Torso)
        --             table.remove(NPCs, index)
        --         end

        --     end

        -- end

        SetBool("level.deleteNPCs", false) -- Reset delete check.

        for index, npc in ipairs(NPCS_TO_DELETE) do
            NPCs[npc.id] = nil
        end
        NPCS_TO_DELETE = {}

    end
end

--- Find uninitialized npc bodies in the scene, construct their object and references, then set them as initialized.
function tick_spawning()
    local torsos = FindBodies("Torso", true)
    for key, torso in pairs(torsos) do
        if not HasTag(torso, "npc_initialized") and not HasTag(torso, "dead") and not HasTag(torso, "dead_player") then

            local id = GetTagValue(torso, "gore_id")
            local npc = npc_create(id)

            if npc then
                NPCs[id] = npc
                NPC_Torsos[npc.Torso] = npc
            end

            SetTag(torso, "npc_initialized")

        end
    end
end

function npc_has_spawn_tags(npc) return #npc.ai.spawnTags >= 1 end

--- Delete the bodies and shapes of the npc.
function npc_delete_entities(npc)
	for index, body in ipairs(npc.AllBodies) do
        if body ~= GetWorldBody() then Delete(body) end
	end
end

--- Remove an npc from the NPCs table.
function npc_mark_for_removal(npc, del_entities)
    if del_entities then npc_delete_entities(npc) end
    table.insert(NPCS_TO_DELETE, npc)
end

--- Check if npc is valid and can be run.
function npc_is_valid(npc)
    npc.isValid = IsHandleValid(npc.Torso) and config.goreai.isEnabled
    for _, body in ipairs(npc.bodyparts) do
        if not IsHandleValid(body) then
            npc.isValid = false break
        end
    end
    return npc.isValid
end

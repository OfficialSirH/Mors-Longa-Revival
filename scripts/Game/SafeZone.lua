#version 2
#include "../../scripts/TDSU/tdsu.lua"
-- (v2) Safe zone (shop segment). Server: counts loaded safe zones (level.safezoneLoadCount, read by ParkingSpot.lua's
-- server part). Client: the coloured outlines on the perk machine / bed / stash (they fade with camera distance).

Safezone_Tag = "safezone" -- Add this tag to the body of each interactable (tags="safezone=perk")


function server.init()
    SetInt("level.safezoneLoadCount", GetInt("level.safezoneLoadCount") + 1)
end

function client.init()

    InteractablesObjects = {}

    Interactables = {
        perk  = { color = Vec(0.8, 0.2, 0.8) },
        bed   = { color = Vec(0.8, 0.8, 0.8) },
        stash = { color = Vec(0.8, 0.8, 0.2) }}

    for index, body in ipairs(FindBodies(Safezone_Tag)) do
        CreateInteractable(body)
    end

end

function client.tick()

    for index, interactable in ipairs(InteractablesObjects) do

        if interactable.data and IsHandleValid(interactable.body) then -- (v2) skip unknown safezone types / removed bodies

            local tr = GetBodyTransform(interactable.body)
            local a = 30 - (VecDist(GetCameraTransform().pos, tr.pos))

            DrawBodyOutline(
                interactable.body,
                interactable.data.color[1],
                interactable.data.color[2],
                interactable.data.color[3],
                a)

        end

    end

end

function CreateInteractable(body)

    local tag_value = GetTagValue(body, Safezone_Tag)

    local interactable = {
        body      = body,
        id        = tag_value,
        data      = Interactables[tag_value] }

        table.insert(InteractablesObjects, interactable)

end

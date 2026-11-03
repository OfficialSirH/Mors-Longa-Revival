#include "../../scripts/TDSU/tdsu.lua"

Safezone_Tag = "safezone" -- Add this tag to the body of each interactable (tags="safezone=perk")


function init()

    InteractablesObjects = {}

    Interactables = {
        perk  = { color = Vec(0.8, 0.2, 0.8) },
        bed   = { color = Vec(0.8, 0.8, 0.8) },
        stash = { color = Vec(0.8, 0.8, 0.2) }}

    for index, body in ipairs(FindBodies(Safezone_Tag)) do
        CreateInteractable(body)
    end

    SetInt("level.safezoneLoadCount", GetInt("level.safezoneLoadCount") + 1)

end

function tick()

    for index, interactable in ipairs(InteractablesObjects) do

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

function CreateInteractable(body)

    local tag_value = GetTagValue(body, Safezone_Tag)

    local interactable = {
        body      = body,
        id        = tag_value,
        data      = Interactables[tag_value] }

        table.insert(InteractablesObjects, interactable)

end
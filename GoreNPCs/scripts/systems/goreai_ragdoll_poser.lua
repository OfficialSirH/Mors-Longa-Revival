---comments
---@param npc table
---@param tr table Transform to place head at.
---@param ragdoll_pose table Table of limb positions.
---@param movingBody number (optional) Body to stay relative to (usually a vehicle).
function npc_pose_ragdoll(npc, tr, ragdoll_pose, movingBody)

    local vehicleVel = Vec()
    if movingBody then
        vehicleVel = VecScale(GetBodyVelocity(movingBody), 1 / 30)
    end

    local sittingHead_pos = VecAdd(tr.pos, vehicleVel) -- Vehicle driver pos.

    for index, s in ipairs(npc.AllShapes) do SetShapeCollisionFilter(s, 0, 0) end

    if npc.Gun then
        for index, s in ipairs(GetBodyShapes(npc.Gun.body)) do
            SetShapeCollisionFilter(s, 0, 0)
        end
    end

    -- Position the ragdoll
    for index, key in ipairs({
        "Head",
        "Torso",
        "LARM",
        "LLARM",
        "LLEG",
        "LLLEG",
        "RARM",
        "RLEG",
        "RRARM",
        "RRLEG",
    }) do

        local body = npc[key]
        local bodyTr   = GetBodyTransform(npc[key])
        local driverTr = TransformToParentTransform(Transform(sittingHead_pos, tr.rot), ragdoll_pose[key])

        ConstrainPosition(body, 0, bodyTr.pos, driverTr.pos)
        ConstrainOrientation(body, 0, bodyTr.rot, driverTr.rot)

        -- DebugCross(bodyTr.pos, 1,0,0, 1)

    end

end

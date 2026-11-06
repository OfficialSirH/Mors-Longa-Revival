local sc = 1

MeleeWeapons = {
    ["melee-BaseballBat"]  = { damage = 12 * sc, holesize = 0.1, title = "BaseballBat"},
    ["melee-CombatKnife"]  = { damage = 10 * sc, holesize = 0.2, title = "CombatKnife"},
    ["melee-Crowbar"]      = { damage = 15 * sc, holesize = 0.3, title = "Crowbar"},
    ["melee-DamnedScythe"] = { damage = 20 * sc, holesize = 0.3, title = "DamnedScythe"},
    ["melee-FireAxe"]      = { damage = 35 * sc, holesize = 0.5, title = "FireAxe"},
    ["melee-Katana"]       = { damage = 25 * sc, holesize = 0.4, title = "Katana"},
    ["melee-Pipe"]         = { damage = 15 * sc, holesize = 0.1, title = "Pipe"},
    ["melee-Tomahawk"]     = { damage = 10 * sc, holesize = 0.2, title = "Tomahawk"},
}

function Apply_NPC_Damage_Player(hit_shape, hit_pos, tool_id)

    -- NPC DAMAGE START
    local damage_from_player = MeleeWeapons[tool_id].damage
    local hitBody = GetShapeBody(hit_shape) -- raycast hit shape
    if HasTag(hitBody, "gore_id") then

        -- DebugPrint("hit " .. damage_from_player)

        -- Send damage data to npcs script.
        -- (v2) the registry write that hands damage to the NPC script happens on the server.
        MeleeNet_Queue({ t = "npc", body = hitBody, pos = hit_pos, damage = damage_from_player })

        -- Break voxels.
        MeleeNet_MakeHole(hit_pos, MeleeWeapons[tool_id].holesize)

    end
    -- NPC DAMAGE START

end


-----------------------------------------------------------------------------------------
-- (v2) Melee networking (Mors Longa Revival)
--
-- The client that holds the melee weapon runs input, animation, raycasts, sounds and
-- particles as before. World effects are server-only in v2, so they are queued during
-- the frame and sent to the server in one ServerCall from client.postUpdate():
--   hole   = MakeHole(pos, r0, r1, r2)      (merged per position, largest radii kept)
--   impulse= ApplyBodyImpulse(body, pos, v) (summed per body)
--   npc    = GoreNPCs damage hand-off via the registry (level.goreai.body_damage_player.*)
-- Each melee script includes this file, so each script gets its own server.meleeOps.
-----------------------------------------------------------------------------------------

MeleeNet = { ops = {}, holes = {}, impulses = {} }

function MeleeNet_Queue(op)
    MeleeNet.ops[#MeleeNet.ops + 1] = op
end

function MeleeNet_MakeHole(pos, r0, r1, r2)
    r0, r1, r2 = r0 or 0, r1 or 0, r2 or 0
    local key = string.format("%.2f %.2f %.2f", pos[1], pos[2], pos[3])
    local h = MeleeNet.holes[key]
    if h then
        h.r0, h.r1, h.r2 = math.max(h.r0, r0), math.max(h.r1, r1), math.max(h.r2, r2)
    else
        h = { t = "hole", pos = VecCopy(pos), r0 = r0, r1 = r1, r2 = r2 }
        MeleeNet.holes[key] = h
        MeleeNet_Queue(h)
    end
    return 0 -- v1 MakeHole returned the voxel count; no caller uses it on this path
end

function MeleeNet_Impulse(body, pos, impulse)
    local i = MeleeNet.impulses[body]
    if i then
        i.imp = VecAdd(i.imp, impulse)
    else
        i = { t = "impulse", body = body, pos = VecCopy(pos), imp = VecCopy(impulse) }
        MeleeNet.impulses[body] = i
        MeleeNet_Queue(i)
    end
end

function client.postUpdate()
    if #MeleeNet.ops > 0 then
        ServerCall("server.meleeOps", MeleeNet.ops)
        MeleeNet.ops, MeleeNet.holes, MeleeNet.impulses = {}, {}, {}
    end
end

function server.meleeOps(ops)
    for i = 1, #ops do
        local op = ops[i]
        if op.t == "hole" then
            MakeHole(op.pos, op.r0, op.r1, op.r2)
        elseif op.t == "impulse" then
            if op.body ~= 0 and IsHandleValid(op.body) then ApplyBodyImpulse(op.body, op.pos, op.imp) end
        elseif op.t == "npc" then
            local path_damage = "level.goreai.body_damage_player." .. op.body
            SetFloat(path_damage, GetFloat(path_damage) + op.damage) -- Specific damage to each body by handle.
            SetFloat("level.goreai.body_damage_player_x", op.pos[1])
            SetFloat("level.goreai.body_damage_player_y", op.pos[2])
            SetFloat("level.goreai.body_damage_player_z", op.pos[3])
        end
    end
end

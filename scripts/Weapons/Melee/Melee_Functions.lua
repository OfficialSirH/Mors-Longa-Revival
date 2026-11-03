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
        local path_damage = "level.goreai.body_damage_player." .. hitBody
        local damage = GetFloat(path_damage) + damage_from_player
        SetFloat(path_damage, damage) -- Specific damage to each body by handle.

        SetFloat("level.goreai.body_damage_player_x", hit_pos[1])
        SetFloat("level.goreai.body_damage_player_y", hit_pos[2])
        SetFloat("level.goreai.body_damage_player_z", hit_pos[3])

        -- Break voxels.
        MakeHole(hit_pos, MeleeWeapons[tool_id].holesize)

    end
    -- NPC DAMAGE START

end

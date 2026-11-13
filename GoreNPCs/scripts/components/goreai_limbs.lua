--[[

    --todo

    > Scenerios:
        - Shoot npc left hand off, drops gun, picks it up with other hand.
        - Hold shield with left hand and pistol/baton with other.
        - Duel wield guns.
        - Sniper swaps to shotgun when enemy is close.

]]


function init_limbs()

    --- Chooses the correct relative position of the limb to use as hand pos, foot pos, chest pos, etc...
    LimbMapping = {
        center = AabbGetBodyCenterPos,
        bottom = AabbGetBodyCenterBottomPos,
    }

end

function npc_limbs_init(npc)

    npc.limbs = {

        head = { -- Use npc_GetHeadBodies(npc) to get all head bodies.

            skull = npc_limb_create(npc.Head,  LimbMapping.center),
            jaw   = npc_limb_create(npc.Jaw,   LimbMapping.center),

            eyes  = {
                left  = npc_limb_create(npc.Jaw,   LimbMapping.center),
                right = npc_limb_create(npc.Jaw,   LimbMapping.center),
            },

        },

        torso = npc_limb_create(npc.Torso, LimbMapping.center),

        -- arms = {
        --     left  = npc_limb_create(npc.L_ARM , LimbMapping.bottom),
        --     right = npc_limb_create(npc.R_ARM , LimbMapping.bottom),
        -- },

        hands = {
            left  = npc_limb_create(npc.L_ARM, LimbMapping.bottom),
            right = npc_limb_create(npc.R_ARM, LimbMapping.bottom),
        },

        legs = {
            left  = npc_limb_create(npc.RLEG, LimbMapping.bottom),
            right = npc_limb_create(npc.LLEG, LimbMapping.bottom),
        },

        feet = {
            left  = npc_limb_create(npc.RRLEG, LimbMapping.bottom),
            right = npc_limb_create(npc.LLLEG, LimbMapping.bottom),
        },

    }

end

function npc_get_head_bodies(npc)
    return {
        npc.limbs.head.skull.body,
        npc.limbs.head.jaw.body,
        npc.limbs.eyes.left.body,
        npc.limbs.eyes.right.body,
    }
end

function npc_limb_get_end_pos(limb)

end


---@param body number Body of the limb.
---@param fn_rel_pos function Function that finds the relative position of the pos on the body.
---@param mass_death_percentage number NPC will die if limb loses this % of mass compared to start mass.
---@return table
function npc_limb_create(body, fn_rel_pos, mass_death_percentage)
    return {
        body = body,
        mass = mass_create(body, mass_death_percentage), --todo Add new mass system to npcs
        relative_pos = TransformToLocalPoint(GetBodyTransform(body), fn_rel_pos(body))
    }
end

---Object which tracks the changes in mass of a body.
---@param body any
---@param mass_death any
---@return table
function mass_create(body, mass_death)
    local mass = GetBodyMass(body)
    return {
        mass_start = mass,
        mass_last  = mass,
        mass       = mass,
        mass_death = mass_death,
    }
end


-- function npc_EvaluateMass(mass_object)
-- end

-- function EvaluateLimbs()
-- end

-- function npc_limb_evaluate(npc, limb)

-- end

function npc_get_hand_pos(npc_hand)
    local armShape = GetBodyShapes(npc_hand.body)[1]
    local armTr = GetShapeWorldTransform(armShape)
    return TransformToParentPoint(armTr, npc_hand.body_local_pos)
end


--- Run all init functions to construct an npc.
function npc_init(npc)

    -- Life
    npc.deadTime        = 0 -- How long the npc has been dead.
    npc.canSeePlayer    = false
    npc.bounty_complete = false

    npc.spawn_time = GetTime()

    npc.mass_death = 0.7 -- Percentage compared to mass_start to die.
    npc.mass_start = npc_get_mass(npc)
    npc.mass_last  = npc_get_mass(npc)
    npc.mass       = npc_get_mass(npc)

    npc.voxels_death = 0.7 -- Percentage compared to voxels_start to die.
    npc.voxels_start = npc_get_voxels(npc)
    npc.voxels_last  = npc_get_voxels(npc)
    npc.voxels       = npc_get_voxels(npc)

    npc.proficiency = 1

    npc.isJuggernaut = HasTag(npc.Torso, "juggernaut")


    npc_init_limbs(npc)
    npc_init_ai(npc)
    npc_init_targeting(npc)
	npc_init_spawnTags(npc)
    npc_init_teams(npc)
    npc_init_health(npc)
    npc_init_boss(npc)
    npc_init_gun(npc)
    npc_init_gun_sway(npc)
    npc_init_melee(npc)
    npc_controller_init(npc)
    npc_init_robot(npc)
    npc_init_navigation(npc)
    npc_init_voice(npc)

    if npc.ai.teams.team == NPC_TEAMS.civ.title then
        npc.robot.speedScale = npc.robot.speedScale * 1.35
    end

    npc.distToGround = VecDist(GetBodyTransform(npc.Torso), AabbGetBodyCenterBottomPos(npc.RRLEG))

    npc_clear_navigation(npc)

    for index, value in ipairs(npc.AllShapes) do SetTag(value, "nocull") end

end

--- Create the AI data for the npc.
function npc_init_ai(npc)

    npc.ai = {

        spawnTime = GetTime(),

        aimPos = Vec(), -- World position of the npc's target.
        navPos = Vec(), -- The destination the npc will attempt to navigate to.
        lookPos = Vec(), -- The position the npc will face towards.
        shootPos = Vec(), -- Where the npc should shoot towards (checks torso first angle).
        shootPosOffset = Vec(), -- Where the npc should shoot towards (checks torso first angle).
        lastSeenPos = Vec(),

        shooting = false,
        moving = true,

        vision = {
            lerp_amount = 0,
            lerp_rate = 30, --time take for visibility to drop fully in seconds
        },

        stun = {
            velocity = 9, -- total vel for npc to become stunned.
            duration_def = 2.5,
            duration = 0,
            max = 5,
        },

        config = {
            peaceful = false, -- Disable pew pew
            hunt = true, -- Seek and hunt the player
            attack = true, -- Engage the enemy
            friendly_fire = false,
            see_ignore = false,
        },

        strafing = {
            timer_move = TimerCreateSeconds(0.75),
            timer_check = TimerCreateSeconds(1.5),
            side = "none",
            sides = { left = "left", right = "right", none = "" },
            raycast_dist = 3,
            speed = 3.5
        },

        sitting = {
            isSitting = false,
            sitVehicle = 0,
            sitBody = 0,
            sitLight = 0, --- The light entity in the vehicle to place the head relative to the vehicle transform.
            sitTr = Transform(),
        },

        thinking = {

            state = "",

            states = {
                shoot = "",
                dist = ""
            },

            can_see = false,
            seen_last = 100,
            seen_last_timestamp = 0,
            seen_time = 0,
            cant_see_time_nav = 1 + (math.random() * 2),

            distances = {
                idle = 400,
                hunt = 250, -- Move towards and attack
                attack = 150, -- Stand still and attack
            },

            attacking = {
                canShootAimPos = false,
                blocked = false,
                friendly_fire_angle = 5,
                friendly_fire_dist = 50,
                minAimAngle = 45,
            },

            takingCover = false,
            coverDist = math.random(10, 20),
            coverTimer = TimerCreateSeconds(math.random(10,20)),

            positioning = {
                minDist = 1, -- ai must be this close to target position to be considered in position
                aggressive = false,
                runAndShoot = true,
                stopAndShoot = true,
            },

            aggression = {
                pauseDurationRange = { 3, 5 },
            },

            grenades = {

                enabled = true,
                throwRange 		 	   = { min = math.random(10,15), max = math.random(30, 35) },
                withinRange = false,

                throwTime 			   = math.random(math.random(5,7), math.random(8,13)), -- initial throw time
                throwTimeRange   	   = { min = 20, max = 60 },
                recheckTimeRange 	   = { min = 2,  max = 5 },

                config = {
                    time = 3,
                    explosion_size = 1.5
                }

            }

        },

        timers = {
            -- reposition = TimerCreateSeconds(GetFloat("savegame.mod.config.goreai.reposition_timer") + math.random()),
            reposition = TimerCreateSeconds(2),
            reposition_attack = TimerCreateSeconds(RandomSpreadPercent25(6)),
            check_see_player = TimerCreateSeconds(GetFloat("savegame.mod.config.goreai.see_timer") + math.random()),
            agro_shoot = TimerCreateSeconds(RandomSpreadPercent25(6)),
            agro_nav = TimerCreateSeconds(RandomSpreadPercent25(10)),
        },

    }

end

---Create references for body part objects.
function npc_init_limbs(npc)

    npc.hands = {}
    local hand_bodies = { left = npc.L_ARM, right = npc.R_ARM }

    for key, body in pairs(hand_bodies) do

        local armShape = GetBodyShapes(body)[1]
        local armTr = GetShapeWorldTransform(armShape)
        local handPos = AabbGetShapeCenterBottomPos(armShape)
        SetShapeCollisionFilter(armShape, 1)

        npc.hands[key] = {
            body = body,
            shape = armShape,
            body_local_pos = TransformToLocalPoint(armTr, handPos)
        }

    end


    --todo Replace old limb system.
    -- --- Chooses the correct relative position of the limb to use as hand pos, foot pos, chest pos, etc...
    -- local limb_mapping = {
    --     center = AabbGetBodyCenterPos,
    --     bottom = AabbGetBodyCenterBottomPos,
    -- }
    -- npc.limbs = {

    --     head = { -- Use npc_GetHeadBodies(npc) to get all head bodies.

    --         skull = npc_CreateLimb(npc.Head,  limb_mapping.center),
    --         jaw   = npc_CreateLimb(npc.Jaw,   limb_mapping.center),

    --         eyes  = {
    --             left  = npc_CreateLimb(npc.Jaw,   limb_mapping.center),
    --             right = npc_CreateLimb(npc.Jaw,   limb_mapping.center),
    --         },

    --     },

    --     torso = npc_CreateLimb(npc.Torso, limb_mapping.center),

    --     arms = {
    --         left  = npc_CreateLimb(body, limb_mapping.bottom),
    --         right = npc_CreateLimb(body, limb_mapping.bottom),
    --     },

    --     hands = {
    --         left  = npc_CreateLimb(body, limb_mapping.bottom),
    --         right = npc_CreateLimb(body, limb_mapping.bottom),
    --     },

    --     legs = {
    --         left  = npc_CreateLimb(body, limb_mapping.bottom),
    --         right = npc_CreateLimb(body, limb_mapping.bottom),
    --     },

    --     feet = {
    --         left  = npc_CreateLimb(body, limb_mapping.bottom),
    --         right = npc_CreateLimb(body, limb_mapping.bottom),
    --     },

    -- }

end

--- Used for location entity based spawning to set spawn types. Spawn tags can be added manually through script.
function npc_init_spawnTags(npc)

	local torsoInt = GetInt("level.torsoInt") -1
	local tagDataString = GetString("level.torsoData." .. torsoInt)
	local tags = AutoSplit(tagDataString, ",")

    npc.ai.spawnTags_string = tagDataString
    npc.ai.spawnTags = {
        cover 		= false,
        ranged 		= false,
        stationary 	= false,
        outside		= false,
        nogrenades  = false,
        tutorial    = false
    }

    for _, tag in ipairs(tags) do
        npc.ai.spawnTags[tag] = true
    end

    npc.ai.thinking.takingCover = npc.ai.spawnTags.cover

end

function npc_init_eyes(npc)
    for _, shape in ipairs(npc.AllShapes) do
        for _, joint in ipairs(GetShapeJoints(shape)) do
            local body                            = GetShapeBody(shape)
            if HasTag(joint, "eye") and body ~= npc.Head then
                if not TableContainsValue(npc.Eyes, body) then
                    table.insert(npc.Eyes, body)
                end
                RemoveTag(body, "unbreakable")
            end
        end
    end
end

--todo Reorganize npc
--[[

    Systems
        Cross-script data
            NPC data
                torsos
                teams
        Scene
        Config menu
        Body parts
        Animation
        NPC Controller
        Debug


    general
        initializing
        spawning
        deleting
        blood


    npc
        weapon
            guns
            grenades

        entities
            AllBodies, AllShapes, AllJoints...

        movement

        health
            hp
            shield
            damage
                player


        limbs

]]

--[[

    Core NPC actions

        Physics
            Face towards
            Run forward
            Dynamic Accuracy

        Thinking
            Target
                Attack
                Approach
                New Target
            See
            Vision Distance
            Aggression
                Get near target while attacking.

]]

HealthScriptXML = '<script file="MOD/HealthSystem/AdvancedHealthScript.lua"><trigger tags="hitbox=HEAD QueriedDamage=0" pos="0.0 1.4 0.05" type="box" size=".3 .3 .3"/><trigger tags="hitbox=LARM QueriedDamage=0" pos="0.35 0.6 0.0" type="box" size=".2 .7 .2"/><trigger tags="hitbox=LLEG QueriedDamage=0 LLEG" pos="0.15 0.0 0.0" type="box" size=".2 .7 .2"/><trigger tags="hitbox=RARM QueriedDamage=0" pos="-0.35 0.6 0.0" type="box" size=".2 .7 .2"/><trigger tags="hitbox=RLEG QueriedDamage=0 RLEG" pos="-0.15 0.0 0.0" type="box" size=".2 .7 .2"/><trigger tags="hitbox=TORSO QueriedDamage=0 TORSO" pos="0.0 0.8 0.0" type="box" size=".5 .6 .3"/></script>'
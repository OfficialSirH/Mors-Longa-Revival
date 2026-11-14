#include "../../../../lib/TDSU/tdsu.lua"

IncludeNPCs = true

NPC_TEAMS = {
    um      = { name = "United Mates",      title = "um",       ids = { "um", "pur" },  color = UiColors.blue },
    mil     = { name = "Alashyan Military", title = "mil",      ids = { "mil" },        color = UiColors.green },
    civ     = { name = "Insurgents",        title = "civ",      ids = { "civ" },        color = UiColors.yellow },
    cult    = { name = "Cultists",          title = "cult",     ids = { "cult" },       color = UiColors.red },
    none    = { name = "No Team",           title = "none",     ids = { "none" },       color = UiColors.grey },
}

TargetTypes = {
    player  = "player",
    torso   = "torso",
    vehicle = "vehicle",
}


function ai_gore_init()

    Team                = NPC_TEAMS.mil
    SelectedTarget      = { type = nil, entity = nil }
    CheckTargetTimer    = TimerCreateSeconds(1)

end

function ai_gore_tick()

    -- Find random valid target
    TimerRunTime(CheckTargetTimer)
    if TimerConsumed(CheckTargetTimer) then
        TimerResetTime(CheckTargetTimer)

        -- Find valid target
        local valid_enemies = {}
        for index, _ in ipairs(ListKeys("level.goreai.api.npcs.alive")) do

            local torso = GetInt("level.goreai.api.npcs.alive" .. "." .. index)
            local team = GetTagValue(torso, "team")

            if team ~= Team then
                table.insert(valid_enemies, torso)
            end

        end

        -- Check if current target still valid.
        if not TableContainsValue(valid_enemies, SelectedTarget.body) then
            -- Set target object
            if #valid_enemies >= 1 then
                SelectedTarget = {
                    type = TargetTypes.torso,
                    body = valid_enemies[GetRandomIndex(valid_enemies)],
                }
            else
                SelectedTarget = {
                    type = TargetTypes.player,
                    body = nil,
                }
            end
        end

    end

    -- Set target position
    if SelectedTarget.type == TargetTypes.torso then
        PlayerPos = AabbGetBodyCenterPos(SelectedTarget.body) -- Aim for npc torso.
    -- elseif SelectedTarget.type == TargetTypes.player then
        -- PlayerPos = getplayer -- Attack the player as usual.
    end

    DebugWatch("enemy type", SelectedTarget.type)
    DebugLine(PlayerPos, AabbGetBodyCenterPos(Heli), 1,0,0, 0.5)

end

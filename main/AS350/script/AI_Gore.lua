#include "../../../scripts/TDSU/tdsu.lua"


DebugMode = false


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


function ai_gore_init(heliBody)

    Team                        = GetTagValue(heliBody, "team")
    CheckTargetTimer            = TimerCreateSeconds(1)
    ShootRocketsAtPlayer_Dist   = 10000 -- when the heli starts shooting rockets at the player when not in a vehicle.

    IncludeNPCs                 = true
    SelectedTarget              = { type = nil, body = nil }
    PlayerChangeTargetTimer     = GetTime()

end

function ai_gore_tick()

    DistanceProgressed = GetFloat("savegame.mod.distanceProgressed")

    -- Find valid target
    ValidTargets = {}
    for index, _ in ipairs(ListKeys("level.goreai.api.npcs.alive")) do
        local torso = GetInt("level.goreai.api.npcs.alive" .. "." .. index)
        local team = GetTagValue(torso, "spawn_team")
        if team ~= Team then table.insert(ValidTargets, torso) end
    end


    -- Check if current target still valid.
    local isTargetAlive       = SelectedTarget.type == TargetTypes.torso and (TableContainsValue(ValidTargets, SelectedTarget.body))

    local givePlayerABreak    = SelectedTarget.type == TargetTypes.player and GetTime() - PlayerChangeTargetTimer > 0

    local shouldForgetTarget   = SelectedTarget.type == TargetTypes.torso and not isTargetAlive or givePlayerABreak


    -- Clear targets.
    if GetBool("level.goreai.resetTeams") then
        isTargetAlive     = false
        givePlayerABreak  = true
        shouldForgetTarget = true
        PlayerChangeTargetTimer = 0
    end


    -- Find random valid target
    TimerRunTime(CheckTargetTimer)
    if TimerConsumed(CheckTargetTimer) or GetBool("level.goreai.resetTeams") then
        TimerResetTime(CheckTargetTimer)

        if #ValidTargets >= 1 and shouldForgetTarget then

            SelectedTarget = {
                type = TargetTypes.torso,
                body = ValidTargets[GetRandomIndex(ValidTargets)],
            }

        elseif #ValidTargets == 0 then

            SelectedTarget = {
                type = TargetTypes.player,
                body = nil,
            }

        elseif not isTargetAlive and math.random() < 1/#ValidTargets then

            SelectedTarget = {
                type = TargetTypes.player,
                body = 0,
            }

        end

    end


    -- Set target position
    if SelectedTarget.type == TargetTypes.torso then
        PlayerPos = AabbGetBodyCenterPos(SelectedTarget.body) -- Aim for npc torso.
        PlayerChangeTargetTimer = GetTime() + RandomSpreadPercent25(15)
    elseif SelectedTarget.type == TargetTypes.player then
        PlayerPos = VecAdd(GetPlayerTransform().pos, Vec(0,1,0)) -- Attack the player as usual.
    else
        PlayerChangeTargetTimer = GetTime() + RandomSpreadPercent25(15)
    end


    if DebugMode then
        DebugWatch("isTargetAlive", tostring(isTargetAlive))
        DebugWatch("givePlayerABreak", tostring(givePlayerABreak))
        DebugWatch("shouldForgetTorso", tostring(shouldForgetTarget))
        DebugWatch("TotalDamage", TotalDamage)
        DebugWatch("EngineHealth", EngineHealth)
        DebugWatch("Valid target count", #ValidTargets)
        DebugWatch("Targets", table.concat(ValidTargets, ", "))
        DebugWatch("Target", SelectedTarget.body)
        DebugWatch("Target type", SelectedTarget.type)
        DebugWatch("PlayerChangeTargetTimer", PlayerChangeTargetTimer - GetTime())
        DebugWatch("TargetVisible", TargetVisible)
        DebugWatch("shouldForgetTorso", shouldForgetTarget)
    end

    if GetBool("savegame.mod.config.goreai.outlines") then
        local c = NPC_TEAMS[Team].color
        UiColor(c[1],c[2],c[3], 1)
        DrawBodyOutline(Heli, c[1],c[2],c[3], 1/2)
    end

    if GetBool("savegame.mod.config.goreai.draw_combat") then
        DebugLine(PlayerPos, AabbGetBodyCenterPos(Heli), 1,0,0, 0.25)
    end

end

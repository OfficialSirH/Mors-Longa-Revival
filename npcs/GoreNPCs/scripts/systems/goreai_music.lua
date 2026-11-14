local CombatMusicVolumeMax = 0.6
local CombatMusicVolume = 0
CombatMusicPath = "level.goreai.combat_music." -- Used to activate each condition in CombatMusicTriggers
local FadeSeconds = 10 -- How long it takes for a layer to fade in or out.


function init_music()

    CombatMusicLoops = {
        create_music_loop_object("MOD/assets/snd/Music/Combat/MUS_theyarehere_combat_layer01.ogg"),
        create_music_loop_object("MOD/assets/snd/Music/Combat/MUS_theyarehere_combat_layer02.ogg"),
        create_music_loop_object("MOD/assets/snd/Music/Combat/MUS_theyarehere_combat_layer03.ogg"),
        create_music_loop_object("MOD/assets/snd/Music/Combat/MUS_theyarehere_combat_layer04.ogg"),
    }

    CombatMusicTriggers = {
        -- nightTime       = create_music_loop_condition({ 3 },        10 ),
        -- enemyNearby     = create_music_loop_condition({ 1 },        10 ),
        -- drivingFast     = create_music_loop_condition({ 2 },        10 ),
        -- lowHealth       = create_music_loop_condition({ 2 },        5 ),
        fucked          = create_music_loop_condition({ 4 },  5 ),
    }

end


function tick_music()

    if not Settings.game.combat_music.value or not GetBool("level.healthScriptSpawned") then
        return
    end

    music_process_triggers()

    -- Find music layer conditions that have been triggered in the registry.
    local layersToPlay = {}
    for key, condition in pairs(CombatMusicTriggers) do
        if GetBool(CombatMusicPath .. key) then
            for _, layerIndex in ipairs(condition.layers) do
                TableInsertUnique(layersToPlay, layerIndex) --todo optimize
            end
        end
    end


    local musicPlaying = false
    for i = 1, #CombatMusicLoops do
        local loop = CombatMusicLoops[i]
        if loop.volume > 0 then
            musicPlaying = true
            break
        end
    end

    -- Play layers only if
    if #layersToPlay >= 1 then

        for i = 1, #CombatMusicLoops do

            local loop = CombatMusicLoops[i]
            local override = (InputDown("f" .. i))

            if TableContainsValue(layersToPlay, i) or override then
                adjust_combat_loop_volume(loop, 1) -- Fade out volume at a constant rate.
                PlayLoop(loop.loop, GetCameraTransform().pos, loop.volume) -- Play valid music layers loudly.
            else
                adjust_combat_loop_volume(loop, -1) -- Fade out volume at a constant rate.
                PlayLoop(loop.loop, GetCameraTransform().pos, 1/100) -- Play all other music layers very quietly so they stay in sync.
            end

        end

    elseif musicPlaying then

        for i = 1, #CombatMusicLoops do

            local loop = CombatMusicLoops[i]

            if loop.volume > 0 then
                PlayLoop(loop.loop, GetCameraTransform().pos, loop.volume) -- Play valid music layers loudly.
                adjust_combat_loop_volume(loop, -1) -- Fade out volume at a constant rate.
            else
                PlayLoop(loop.loop, GetCameraTransform().pos, 1/100) -- Play all other music layers very quietly so they stay in sync.
                adjust_combat_loop_volume(loop, -1) -- Fade out volume at a constant rate.
            end

        end

    end


    -- if config.db then
        -- for index, loop in ipairs(CombatMusicLoops) do
        --     DebugWatch("Combat music layer " .. index, "vol: " .. sfn(loop.volume) .. ", override: " .. ternary(InputDown("f" .. index), tostring(true), tostring(false)))
        -- end
    -- end


    -- Reset all bool conditions to false for the next tick.
    for key, condition in pairs(CombatMusicTriggers) do SetBool(CombatMusicPath .. key, false) end

end


function music_process_triggers()

    -- --> Driving fast
    -- local v     = GetPlayerVehicle()
    -- local b     = GetVehicleBody(v)
    -- local t     = GetVehicleTransform(v)
    -- local vel   = TransformToLocalVec(t, GetBodyVelocity(b))
    -- local speed = -vel[3]
    -- if speed > 10 then SetBool(CombatMusicPath .. "drivingFast", true) end

    if GetFloat("level.player.health") < 150 then
        SetBool(CombatMusicPath .. "fucked", true)
    end

end


function create_music_loop_object(loop, fadeTime)
    return {
        loop     = LoadLoop(loop),
        fadeTime = fadeTime,
        volume   = 0,
    }
end


function create_music_loop_condition(layers, fadeTime)
    return {
        layers   = layers,
        state    = false,
        fadeTime = fadeTime,
    }
end


function adjust_combat_loop_volume(loop, value)
    local addTime = clamp(GetTimeStep() / FadeSeconds * CombatMusicVolumeMax, 0, 1)
    if     value > 0 then loop.volume = clamp(loop.volume + addTime, 0, CombatMusicVolumeMax)
    elseif value < 0 then loop.volume = clamp(loop.volume - addTime, 0, CombatMusicVolumeMax) end
end

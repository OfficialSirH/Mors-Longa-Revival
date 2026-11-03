Sound_Timers = {
    hitmarker = TimerCreateSeconds(1/10, true)
}

-- Holds table of sounds to play each tick.
Hitmarker_Sounds = {}


function init_sounds()

    Sounds = {}

    init_gun_dist_sounds()

    -- Sounds.ImpWood              = LoadSound("MOD/snd/Impact/Impact_wood.ogg")
    -- Sounds.ImpMetal             = LoadSound("MOD/snd/Impact/Impact_metal.ogg")
    -- Sounds.ImpGlass             = LoadSound("MOD/snd/Impact/Impact_glass.ogg")
    -- Sounds.ImpDirt              = LoadSound("MOD/snd/Impact/Impact_dirt.ogg")
    -- Sounds.ImpStone             = LoadSound("MOD/snd/Impact/Impact_stone.ogg")
    Sounds.GrenadeBeep          = LoadSound("MOD/snd/Weapons/Handheld/Grenade/Grenade_beep.ogg")
    Sounds.GrenadeExplosion     = LoadSound("MOD/snd/Weapons/Handheld/Grenade/grenade_explosion2.ogg")
    Sounds.hitmarker  		    = LoadSound("MOD/snd/Projectiles/Impacts/HitIndicator/hitmarker.ogg")
    Sounds.hitmarker_headshot1  = LoadSound("MOD/snd/Projectiles/Impacts/HitIndicator/hitmarker_headshot1.ogg")
    Sounds.hitmarker_headshot2  = LoadSound("MOD/snd/Projectiles/Impacts/HitIndicator/hitmarker_headshot2.ogg")

    Sounds.dirtimpact = LoadSound("MOD/snd/Projectiles/Impacts/materials/blt_imp_dirt_0.ogg")
    Sounds.foliageimpact = LoadSound("MOD/snd/Projectiles/Impacts/materials/blt_imp_foliage_0.ogg")
    Sounds.glassimpact = LoadSound("MOD/snd/Projectiles/Impacts/materials/blt_imp_glass_auto_0.ogg")
    Sounds.gravelimpact = LoadSound("MOD/snd/Projectiles/Impacts/materials/blt_imp_gravel_0.ogg")
    Sounds.masonryimpact = LoadSound("MOD/snd/Projectiles/Impacts/materials/blt_imp_masonry_0.ogg")
    Sounds.softmetalimpact = LoadSound("MOD/snd/Projectiles/Impacts/materials/blt_imp_metal_auto_0.ogg")
    Sounds.hardmetalimpact = LoadSound("MOD/snd/Projectiles/Impacts/materials/blt_imp_metal_thick_0.ogg")
    Sounds.woodimpact = LoadSound("MOD/snd/Projectiles/Impacts/materials/blt_imp_wood_0.ogg")
    Sounds.ricochetsound = LoadSound("MOD/snd/Projectiles/Impacts/Ricochets/blt_ricco_0.ogg")

    Sounds.seat = {}
    for i = 1, 5 do
        table.insert(Sounds.seat, LoadSound("MOD/GoreNPCs/snd/vehicle_seats/seat_enter_" .. tostring(i) .. ".ogg"))
    end

    Sounds.voice_sets = {
        ar = {
            death = CreateSoundSet("MOD/GoreNPCs/snd/voice/ar/death/death_", 11),
            hard = CreateSoundSet("MOD/GoreNPCs/snd/voice/ar/hard/hard_", 20),
            hit = CreateSoundSet("MOD/GoreNPCs/snd/voice/ar/hit/hit_", 35),
        },
        en = {
            death = CreateSoundSet("MOD/GoreNPCs/snd/voice/en/death/death_", 12),
            hard = CreateSoundSet("MOD/GoreNPCs/snd/voice/en/hard/hard_", 12),
            hit = CreateSoundSet("MOD/GoreNPCs/snd/voice/en/hit/hit_", 23),
        },
    }


    Loops = {}
    Loops.blood_pouring1 = LoadLoop("MOD/GoreNPCs/snd/loop_blood_pouring1.ogg")
    Loops.blood_pouring2 = LoadLoop("MOD/GoreNPCs/snd/loop_blood_pouring2.ogg")

end

function tick_sounds()

    if Settings.game.hitmarker and GetString("savegame.mod.difficulty") ~= "hardcore" then
        for index, sound in ipairs(Hitmarker_Sounds) do
            PlaySound(sound.sound, GetCameraTransform().pos, sound.vol)
        end
    end

    Hitmarker_Sounds = {}

end

function init_gun_dist_sounds()


    -- med and far blend based on distance to player.
    Sounds.guns = {
        pistol = {
            med = {
                LoadSound("MOD/GoreNPCs/snd/gun_dist_sounds/pistol_dist_med_1.ogg"),
                LoadSound("MOD/GoreNPCs/snd/gun_dist_sounds/pistol_dist_med_2.ogg"),
                LoadSound("MOD/GoreNPCs/snd/gun_dist_sounds/pistol_dist_med_3.ogg"),
                LoadSound("MOD/GoreNPCs/snd/gun_dist_sounds/pistol_dist_med_4.ogg"),
                LoadSound("MOD/GoreNPCs/snd/gun_dist_sounds/pistol_dist_med_5.ogg"),
                LoadSound("MOD/GoreNPCs/snd/gun_dist_sounds/pistol_dist_med_6.ogg"),
            },
            far = {
                LoadSound("MOD/GoreNPCs/snd/gun_dist_sounds/pistol_dist_far_1.ogg"),
                LoadSound("MOD/GoreNPCs/snd/gun_dist_sounds/pistol_dist_far_2.ogg"),
                LoadSound("MOD/GoreNPCs/snd/gun_dist_sounds/pistol_dist_far_3.ogg"),
                LoadSound("MOD/GoreNPCs/snd/gun_dist_sounds/pistol_dist_far_4.ogg"),
                LoadSound("MOD/GoreNPCs/snd/gun_dist_sounds/pistol_dist_far_5.ogg"),
                LoadSound("MOD/GoreNPCs/snd/gun_dist_sounds/pistol_dist_far_6.ogg"),
            }
        },
        smg = {
            med = {
                LoadSound("MOD/GoreNPCs/snd/gun_dist_sounds/pistol_dist_med_1.ogg"),
                LoadSound("MOD/GoreNPCs/snd/gun_dist_sounds/pistol_dist_med_2.ogg"),
                LoadSound("MOD/GoreNPCs/snd/gun_dist_sounds/pistol_dist_med_3.ogg"),
                LoadSound("MOD/GoreNPCs/snd/gun_dist_sounds/pistol_dist_med_4.ogg"),
                LoadSound("MOD/GoreNPCs/snd/gun_dist_sounds/pistol_dist_med_5.ogg"),
                LoadSound("MOD/GoreNPCs/snd/gun_dist_sounds/pistol_dist_med_6.ogg"),
            },
            far = {
                LoadSound("MOD/GoreNPCs/snd/gun_dist_sounds/pistol_dist_far_1.ogg"),
                LoadSound("MOD/GoreNPCs/snd/gun_dist_sounds/pistol_dist_far_2.ogg"),
                LoadSound("MOD/GoreNPCs/snd/gun_dist_sounds/pistol_dist_far_3.ogg"),
                LoadSound("MOD/GoreNPCs/snd/gun_dist_sounds/pistol_dist_far_4.ogg"),
                LoadSound("MOD/GoreNPCs/snd/gun_dist_sounds/pistol_dist_far_5.ogg"),
                LoadSound("MOD/GoreNPCs/snd/gun_dist_sounds/pistol_dist_far_6.ogg"),
            }
        },
        shotgun = {
            med = {
                LoadSound("MOD/GoreNPCs/snd/gun_dist_sounds/shotgun_dist_med_1.ogg"),
                LoadSound("MOD/GoreNPCs/snd/gun_dist_sounds/shotgun_dist_med_2.ogg"),
                LoadSound("MOD/GoreNPCs/snd/gun_dist_sounds/shotgun_dist_med_3.ogg"),
                LoadSound("MOD/GoreNPCs/snd/gun_dist_sounds/shotgun_dist_med_4.ogg"),
                LoadSound("MOD/GoreNPCs/snd/gun_dist_sounds/shotgun_dist_med_5.ogg"),
                LoadSound("MOD/GoreNPCs/snd/gun_dist_sounds/shotgun_dist_med_6.ogg"),
            },
            far = {
                LoadSound("MOD/GoreNPCs/snd/gun_dist_sounds/shotgun_dist_far_1.ogg"),
                LoadSound("MOD/GoreNPCs/snd/gun_dist_sounds/shotgun_dist_far_2.ogg"),
                LoadSound("MOD/GoreNPCs/snd/gun_dist_sounds/shotgun_dist_far_3.ogg"),
                LoadSound("MOD/GoreNPCs/snd/gun_dist_sounds/shotgun_dist_far_4.ogg"),
                LoadSound("MOD/GoreNPCs/snd/gun_dist_sounds/shotgun_dist_far_5.ogg"),
                LoadSound("MOD/GoreNPCs/snd/gun_dist_sounds/shotgun_dist_far_6.ogg"),
            }
        },
        rpg = {
            med = {
                LoadSound(""),
            },
            far = {
                LoadSound(""),
            }
        },
        rifle = {
            med = {
                LoadSound("MOD/GoreNPCs/snd/gun_dist_sounds/rifle_dist_far_1.ogg"),
                LoadSound("MOD/GoreNPCs/snd/gun_dist_sounds/rifle_dist_far_2.ogg"),
                LoadSound("MOD/GoreNPCs/snd/gun_dist_sounds/rifle_dist_far_3.ogg"),
                LoadSound("MOD/GoreNPCs/snd/gun_dist_sounds/rifle_dist_far_4.ogg"),
                LoadSound("MOD/GoreNPCs/snd/gun_dist_sounds/rifle_dist_far_5.ogg"),
                LoadSound("MOD/GoreNPCs/snd/gun_dist_sounds/rifle_dist_far_6.ogg"),
            },
            far = {
                LoadSound("MOD/GoreNPCs/snd/gun_dist_sounds/rifle_dist_far_1.ogg"),
                LoadSound("MOD/GoreNPCs/snd/gun_dist_sounds/rifle_dist_far_2.ogg"),
                LoadSound("MOD/GoreNPCs/snd/gun_dist_sounds/rifle_dist_far_3.ogg"),
                LoadSound("MOD/GoreNPCs/snd/gun_dist_sounds/rifle_dist_far_4.ogg"),
                LoadSound("MOD/GoreNPCs/snd/gun_dist_sounds/rifle_dist_far_5.ogg"),
                LoadSound("MOD/GoreNPCs/snd/gun_dist_sounds/rifle_dist_far_6.ogg"),
            }
        },
        sniper = {
            med = {
                LoadSound("MOD/GoreNPCs/snd/gun_dist_sounds/sniper_dist_med_1.ogg"),
                LoadSound("MOD/GoreNPCs/snd/gun_dist_sounds/sniper_dist_med_2.ogg"),
                LoadSound("MOD/GoreNPCs/snd/gun_dist_sounds/sniper_dist_med_3.ogg"),
                LoadSound("MOD/GoreNPCs/snd/gun_dist_sounds/sniper_dist_med_4.ogg"),
                LoadSound("MOD/GoreNPCs/snd/gun_dist_sounds/sniper_dist_med_5.ogg"),
                LoadSound("MOD/GoreNPCs/snd/gun_dist_sounds/sniper_dist_med_6.ogg"),
            },
            far = {
                LoadSound("MOD/GoreNPCs/snd/gun_dist_sounds/sniper_dist_far_1.ogg"),
                LoadSound("MOD/GoreNPCs/snd/gun_dist_sounds/sniper_dist_far_2.ogg"),
                LoadSound("MOD/GoreNPCs/snd/gun_dist_sounds/sniper_dist_far_3.ogg"),
                LoadSound("MOD/GoreNPCs/snd/gun_dist_sounds/sniper_dist_far_4.ogg"),
                LoadSound("MOD/GoreNPCs/snd/gun_dist_sounds/sniper_dist_far_5.ogg"),
                LoadSound("MOD/GoreNPCs/snd/gun_dist_sounds/sniper_dist_far_6.ogg"),
            }
        },
    }

end

function CreateSoundSet(path, count)
    local s = {}
    for i = 1, count do
        table.insert(s, LoadSound(path .. i .. ".ogg"))
    end
    return s
end

function npc_init_voice(npc)

    npc.voice = {
        playTimestamp = 0,
        playIntervalRange = { 1, 3 },
        playedLastTime = 0,
        pitch = 1,
        lastSoundPlayed = nil,
    }

    if npc.ai.teams.team == NPC_TEAMS.civ.title then
        npc.voice.sounds = Sounds.voice_sets.ar
        npc.voice.pitch = rnd(0.95, 1.1)
    else
        npc.voice.sounds = Sounds.voice_sets.en
        npc.voice.pitch = rnd(0.875, 1.0)
    end

end

---Play sound within valid time.
---@param npc any
---@param sounds any
---@param pos any
---@param vol any
function npc_voice_play_timed(npc, sounds, pos, vol)

    if GetTime() >= npc.voice.playTimestamp then
        local s = GetRandomArrayValue(sounds)
        PlaySound(s, pos, vol, nil, npc.voice.pitch)
        npc.voice.lastSoundPlayed = s
        npc.voice.playTimestamp = GetTime() + (rnd(npc.voice.playIntervalRange[1], npc.voice.playIntervalRange[2]))
    end

end

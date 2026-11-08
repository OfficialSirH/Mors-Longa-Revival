function init_bosses()
    BossPresets = {

        insurgent = {
            id              = "insurgent",
            title           = "Insurgent",
            mass_death      = 0.4,
            shield          = 90,
            health_max      = 150,
            gun = {
                gun_path = "Gun Medvedev SNIPER SUPPRESSED.xml",
                ammo_path = "Ammo 7.62x54R.xml",
                class = GUN_CLASSES.sniper,
                faction = GUN_FACTIONS.civ,
                tech = GUN_TECHS.low
            }
        },

        mil = {
            id              = "mil",
            title           = "Military",
            mass_death      = 0.4,
            shield          = 140,
            health_max      = 200,
            gun = {
                gun_path = "Gun N4A1 MILITARY1.xml",
                ammo_path = "Ammo 5.56.xml",
                class = GUN_CLASSES.rifle,
                faction = GUN_FACTIONS.um,
                tech = GUN_TECHS.mid
            }
        },

        cultist = {
            id              = "cultist",
            title           = "Cultist",
            mass_death      = 0.4,
            shield          = 250,
            health_max      = 300,
            gun = {
                gun_path = "Gun N870 MILITARY3.xml",
                ammo_path = "Ammo 12GA.xml",
                class = GUN_CLASSES.shotgun,
                faction = GUN_FACTIONS.um,
                tech = GUN_TECHS.high
            }
        },

        bingus = {
            id              = "bingus",
            title           = "Bingus",
            mass_death      = 0.5,
            shield          = 200,
            health_max      = 250,
            gun = {
                gun_path = "Gun N16.xml",
                ammo_path = "Ammo 5.56.xml",
                class = GUN_CLASSES.rifle,
                faction = GUN_FACTIONS.mil,
                tech = GUN_TECHS.mid
            }
        },

    }

    bossBingusMusic = LoadLoop("MOD/snd/Music/Combat/MUS_Boss_Bingus.ogg")
    bossCultistLoop = LoadLoop("MOD/snd/Enemies/Boss/Boss_Cultist_Call.ogg")
end


---Check whether to turn an npc into a boss.
function npc_init_boss(npc)

    if HasTag(npc.Torso, "boss") then

        local boss_id = GetTagValue(npc.Torso, "boss")
        npc_bosses_convert_to_boss(npc, boss_id)
        -- print("created boss: ", boss_id)

    else

        npc.boss = {}
        npc.boss.isBoss         = false

    end

end

function npc_bosses_convert_to_boss(npc, boss_id)

    local boss_preset = BossPresets[boss_id]

    npc.boss = {}
    npc.boss.isBoss         = true
    npc.boss.boss_preset    = DeepCopy(boss_preset)
    npc.boss.mass_death     = boss_preset.mass_death
    npc.health_max = boss_preset.health_max

    npc_init_health(npc, boss_preset.shield, boss_preset.shield)

end

function npc_boss_bingus_tick(npc)
    PlayLoop(bossBingusMusic, npc.torsoTr.pos, 20)
end

function npc_boss_cult_tick(npc)
    PlayLoop(bossCultistLoop, GetBodyTransform(npc.Head).pos, 10)
end

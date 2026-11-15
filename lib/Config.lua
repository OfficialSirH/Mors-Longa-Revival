--[[
#include "TDSU/tdsu.lua"
#include "Automatic.lua"
#include "Settings.lua"
#include "../ui/menu_update_log_data.lua"
]]


-- (v2) Config.lua is a library (many scripts include it). The level-script callbacks below are called from
-- ui/ConfigMenu.lua (client) under new names, so they no longer leak into every including script.
function ConfigMenu_Init()

    Init_Settings()
    init_update_log_data()

    -- MOD_VERSION = "1.3.1" -- 2023 July 21 - Last commit 899df63db14de6201efa27c1000452daf46bb1a9 (Update goreai_prefabs.lua by Waffle)
    MOD_VERSION = UpdateLogItems[1][1].version

    print("\n================================================================")
    print("MORS LONGA", MOD_VERSION)
    print("================================================================\n")

    FontSize = 24
    MarginH  = 34

    ShowDebugMod = false -- toggle ui screen drawing.
    DebugMode = GetBool("level.debugmode") -- Decides whether to use debug variables or game variables.
    NPCSpawningMode = false

    init_config()

    DayPhases = {
        "Morning",
        "Noon",
        "Evening",
        "Night",
    }

    SetInt("savegame.mod.messagesShown", GetInt("savegame.mod.messagesShown") + 1)

    SetBool("level.configScriptSpawned", true)

end

function init_config()

    config = util.structured_table("savegame.mod.config",
    {
        db = { "boolean" , false},

        map = {
            spawnTileContent      = { "boolean" , true},
            showLocationSpawnTags = { "boolean" , false},
        },

        daynight = {
            runTime                 = { "boolean" , true},
            override_weather        = { "boolean" , true},
            override_sun_brightness = { "boolean" , false},
            sun_brightness          = { "number" , 0},
            sandstorms              = { "boolean" , true},
            run_sandstorm           = { "boolean" , false},
        },

        tools = {
            registry_watcher = { "boolean" , false},
        },

        game = {
            draw_bounds   = { "boolean" , false},
            god           = { "boolean" , false},
            heal          = { "boolean" , false},
            enable_tools  = { "boolean" , false},
            draw_hitboxes = { "boolean" , false},
            try_again     = {
                show       = { "boolean" , false},
                deaths     = { "number" , 0},
                menu_count = { "number" , 1},      -- deaths > = menu_count = show play again button.
            },
            inf_hunger        = { "boolean" , false},
            inf_thirst        = { "boolean" , false},
            inf_fuel          = { "boolean" , false},
        },

        performance_options = {
            cull_all_shapes              = { "boolean" , true }, -- Remove nocull tag from all shapes to reduce distant rendering.
            disable_return_shadow_volume = { "boolean" , true }, -- Do not maintain shadow volume
            delete_extra_objects         = { "boolean" , true }, -- Delete shapes and bodies with the "delete" tag
        },

        goreai = {

            aggressive                = { "boolean" , true  },
            pos_dot                   = { "boolean" , false },
            draw_combat               = { "boolean" , false },
            draw_bones                = { "boolean" , false },
            draw_projectile_impacts   = { "boolean" , false },
            outlines                  = { "boolean" , false },
            healthbar_debug           = { "boolean" , false },
            draw_debug                = { "boolean" , false },
            accuracy                  = { "boolean" , true  },
            isEnabled                 = { "boolean" , true  },
            thinkingEnabled           = { "boolean" , true  },
            movement                  = { "boolean" , true  },
            thinking                  = { "boolean" , true  },
            turning                   = { "boolean" , true  },
            reposition                = { "boolean" , true  },
            reposition_timer          = { "number"  , 3     },
            see_timer                 = { "number"  , 0.5   },
            weapon_sway               = { "number"  , 1     },
            shoot                     = { "boolean" , true  },
            text_debug                = { "boolean" , false },
            throw_grenades            = { "boolean" , true  },
            teams_enabled             = { "boolean" , true  },
            team_battles              = { "boolean" , true  },
            teamsIncludePlayer        = { "boolean" , true  },
            endless_battle            = { "boolean" , false },
            dist_gun_unlocks          = { "boolean" , true  },
            debug_ui                  = { "boolean" , false },
            invincible                = { "boolean" , false },
            unbreakable_bones         = { "number" , 0 }, -- 0:off, 1:must set on, 2:on, 3:must set off
            dont_clear_nav            = { "boolean" , false },
        },

    })

end


function ConfigMenu_Tick()

    -- (2026-11-14, user) the debug menu is the host's only; the settings in it that each machine reads (infinite
    -- ammo, no hunger / thirst, god mode, placetool materials) are copied from the host to everyone
    -- (game/newLeveltoLEVEL.lua MirrorHostState)
    if not IsPlayerHost(GetLocalPlayer()) then
        ShowDebugMod = false
        return
    end
    if InputPressed("backspace") then
        ShowDebugMod = not ShowDebugMod
    end

    if ShowDebugMod and KeybindPressed(Settings.keybinds.inventory.toggle_inv) then
        ShowDebugMod = false
    end

    -- Torsos = 0
	-- for index, torso in ipairs(FindBodies("Torso", true)) do
	-- 	if not HasTag(torso, "dead") then
	-- Torsos = Torsos + 1
	-- 	end
	-- end
    -- dbw("Torsos", Torsos)


    -- Voxels = 0
	-- for index, shape in ipairs(FindShapes("", true)) do
    -- Voxels = Voxels + GetShapeVoxelCount(shape)
    -- end
    -- dbw("Voxels", sfnCommas(Voxels))

    if config.db then
        DebugLine(Vec(0,0,0), Vec(0,10,0), 1,1,1, 1)
        DrawDot(Vec(0,0,0), 1,1, 1,1,1, 1, false)
    end

end

function ConfigMenu_Draw()

    UiFont("regular.ttf", 20)

    -- Top right corner.
    UiPush()
        UiColor(0,0,0, 1)
        UiTextShadow(0.5,0.5,0.5, 1, 0.05)

        margin(UiWidth() - 10, 10)
        UiFont("regular.ttf", 24)
        UiAlign("right top")
        UiText(MOD_VERSION)
        margin(0, 26)
        if not GetBool("level.inventory.open") and not GetBool("level.parkingSpot.garageUiShowing")
                and IsPlayerHost(GetLocalPlayer()) then   -- (2026-11-14) host only
            UiText("Press BACKSPACE to open debug menu.")
        end
        -- margin(0, 26)
        -- UiText("Press ALT + V to open loot spawn menu.")
    UiPop()

    UiPush()
        if ShowDebugMod then
            margin(0, 0)
            drawConfigUi()
        end
    UiPop()



    -- if GetInt("savegame.mod.messagesShown") < = 3 then
        -- UiPush()
        -- local GameTime = GetTime()
        --     if GameTime > 0 and GameTime < 3 then
        --         DrawMessage("This mod is still being developed.")
        --         margin(0, -50)
        --         DrawMessage("Thanks for playing Mors Longa.")
        --     -- elseif GameTime > 3 and GameTime < 8 then
        --     --     DrawMessage("It will improve the gameplay greatly.")
        --     --     margin(0, -40)
        --     --     DrawMessage("We are working on a new spawning and progression system.")
        --     elseif GameTime > 3 and GameTime < 8 then
        --         DrawMessage("Disable all mods for the best intended experience.")
        --     end
        -- UiPop()
    -- end

end



function drawConfigUi()

    local panels = 3
    UI_PANEL_W = (UiWidth()/3) * 0.9
    UI_PANEL_H = UiHeight()

    UiMakeInteractive()
    UiTranslate(UI_PANEL_W/panels/2)

    -- Container mod
    UiPush()
        AutoContainer(UI_PANEL_W, UI_PANEL_H, 2, false, true)
        DrawConfigUi_mod()
    UiPop()

    -- Container gore npcs
    margin(UI_PANEL_W , 0)
    UiPush()
        AutoContainer(UI_PANEL_W, UI_PANEL_H, 2, false, true)
        DrawConfigUi_goreai()
    UiPop()

    -- Container spawning
    margin(UI_PANEL_W , 0)
    UiPush()
        AutoContainer(UI_PANEL_W, UI_PANEL_H, 2, false, true)
        DrawConfigUi_spawn()
    UiPop()

end

function DrawMessage(str)
    UiPush()
        UiAlign("center middle")
        UiFont("bold.ttf", 36)
        UiTextShadow(0,0,0, 1, 0.5,0.1)
        UiColor(1,1,1, Oscillate(1.5)/2 + 1/2)
        margin(UiCenter(), UiMiddle()-50)
        AutoText(str)
    UiPop()
end

function DrawConfigUi_mod()

    AutoText("Mod Debug")
    margin(0, MarginH)

    margin(MarginH, 0)

    -- ToggleButton
    if AutoToggleButton(config.db, "Debug Mode", FontSize, 2, 2, true, 0) then
        config.db = not config.db
    end
    margin(0, MarginH)
    margin(0, MarginH)


    UiPush()

        margin(200, 0)

        -- Button
        if AutoButton("Give $10,000", FontSize, 2, 2, true, 0) then
            SetInt("savegame.mod.player.money", GetInt("savegame.mod.player.money") + 10000)
        end
        margin(0, MarginH)

        -- Button
        if AutoButton("Reset Money", FontSize, 2, 2, true, 0) then
            SetInt("savegame.mod.player.money", 0)
        end
        margin(0, MarginH)

        -- Button
        if AutoButton("Reset Parking Spot", FontSize, 2, 2, true, 0) then
            ClearKey("savegame.mod.parkingSpot")
        end
        margin(0, MarginH)

    UiPop()


    -- Button
    if AutoButton("Reset savegame", FontSize, 2, 2, true, 0) then
        ClearKey("savegame.mod")
    end
    margin(0, MarginH)

    -- Button
    if AutoButton("Reset perks", FontSize, 2, 2, true, 0) then
        ClearKey("savegame.mod.perks")
    end
    margin(0, MarginH)

    -- Button
    if AutoButton("Reset NPCs", FontSize, 2, 2, true, 0) then
        ClearKey("savegame.mod.config.goreai")
    end
    margin(0, MarginH)

    -- Button
    if AutoButton("Reset Distance Progress", FontSize, 2, 2, true, 0) then
        SetBool("level.reset_distanceProgressed", true)
    end
    margin(0, MarginH)

    -- ToggleButton
    if AutoToggleButton(GetBool("savegame.mod.infiniteMaterials"), "Infinite Placetool Materials", FontSize, 2, 2, true, 0) then
        SetBool("savegame.mod.infiniteMaterials", not GetBool("savegame.mod.infiniteMaterials"))
    end
    margin(0, MarginH)
    margin(0, MarginH)


    UiPush()

        -- ToggleButton
        if AutoToggleButton(GetString("savegame.mod.difficulty") == "normal", "Normal", FontSize, 2, 2, true, 0) then
            SetString("savegame.mod.difficulty", "normal")
        end
        margin(150, 0)

        -- ToggleButton
        if AutoToggleButton(GetString("savegame.mod.difficulty") == "hardcore", "Hardcore", FontSize, 2, 2, true, 0) then
            SetString("savegame.mod.difficulty", "hardcore")
        end
        margin(0, MarginH)

    UiPop()

    margin(0, MarginH)
    margin(0, MarginH)


    UiPush()

        margin(200, 0)

        -- ToggleButton
        if AutoToggleButton(GetBool("savegame.mod.unlimitedammo"), "Infinite Ammo", FontSize, 2, 2, true, 0) then
            SetBool("savegame.mod.unlimitedammo", not GetBool("savegame.mod.unlimitedammo"))
        end
        margin(0, MarginH)

        -- ToggleButton
        if AutoToggleButton(config.game.inf_fuel, "Infinite Fuel", FontSize, 2, 2, true, 0) then
            config.game.inf_fuel = not config.game.inf_fuel
        end
        margin(0, MarginH)

        -- ToggleButton
        if AutoToggleButton(config.game.inf_hunger, "No Hunger", FontSize, 2, 2, true, 0) then
            config.game.inf_hunger = not config.game.inf_hunger
        end
        margin(0, MarginH)

        -- ToggleButton
        if AutoToggleButton(config.game.inf_thirst, "No Thirst", FontSize, 2, 2, true, 0) then
            config.game.inf_thirst = not config.game.inf_thirst
        end
        margin(0, MarginH)

    UiPop()

    -- ToggleButton
    if AutoToggleButton(config.game.god, "God Mode", FontSize, 2, 2, true, 0) then
        config.game.god = not config.game.god
    end
    margin(0, MarginH)

    -- Button
    if AutoButton("Heal", FontSize, 2, 2, true, 0) then
        SetBool("savegame.mod.config.game.heal", true)
    end
    margin(0, MarginH)

    -- Button
    if AutoButton("Die", FontSize, 2, 2, true, 0) then
        SetBool("savegame.mod.config.game.die", true)
    end
    margin(0, MarginH)
    margin(0, MarginH)
    margin(0, MarginH)




    -- ToggleButton
    if AutoToggleButton(config.game.draw_hitboxes, "Show Player Hitboxes", FontSize, 2, 2, true, 0) then
        config.game.draw_hitboxes = not config.game.draw_hitboxes
    end
    margin(0, MarginH)

    -- ToggleButton
    if AutoToggleButton(config.game.draw_bounds, "Show Map Boundaries", FontSize, 2, 2, true, 0) then
        config.game.draw_bounds = not config.game.draw_bounds
    end
    margin(0, MarginH)
    margin(0, MarginH)



    if AutoToggleButton(config.daynight.runTime,"Run Time", FontSize, 2, 2, true, 0) then
        config.daynight.runTime = not config.daynight.runTime
    end

    margin(0, MarginH)


    UiPush()
        if AutoButton("Morning", FontSize, 2, 2, true, 0) then
            SetString("level.daynight.updateDayPhase", "Morning")
        end
        margin(MarginH*4, 0)
        if AutoButton("Noon", FontSize, 2, 2, true, 0) then
            SetString("level.daynight.updateDayPhase", "Noon")
        end
    UiPop()
    margin(0, MarginH)

    UiPush()
        if AutoButton("Evening", FontSize, 2, 2, true, 0) then
            SetString("level.daynight.updateDayPhase", "Evening")
        end
        margin(MarginH*4, 0)
        if AutoButton("Night", FontSize, 2, 2, true, 0) then
            SetString("level.daynight.updateDayPhase", "Night")
        end
    UiPop()
    margin(0, MarginH)
    margin(0, MarginH)




    -- ToggleButton
    if AutoToggleButton(config.daynight.override_weather, "Keep Overriding Weather", FontSize, 2, 2, true, 0) then
        config.daynight.override_weather = not config.daynight.override_weather
    end
    margin(0, MarginH)


    -- ToggleButton
    if AutoToggleButton(config.daynight.sandstorms, "Sandstorms", FontSize, 2, 2, true, 0) then
        config.daynight.sandstorms = not config.daynight.sandstorms
    end
    UiPush()
    if config.daynight.sandstorms then
        margin(MarginH*5, 0)
        -- ToggleButton
        if AutoToggleButton(config.daynight.run_sandstorm, "Run Sandstorm", FontSize, 2, 2, true, 0) then
            config.daynight.run_sandstorm = not config.daynight.run_sandstorm
        end
    else
        config.daynight.run_sandstorm = false
    end
    UiPop()
    margin(0, MarginH)
    margin(0, MarginH)


    -- ToggleButton
    if AutoToggleButton(config.daynight.override_sun_brightness, "Manual Sun Brightness", FontSize, 2, 2, true, 0) then
        config.daynight.override_sun_brightness = not config.daynight.override_sun_brightness
    end
    margin(0, MarginH)

    if config.daynight.override_sun_brightness then
        -- Slider
        margin(-MarginH, 10)
        AutoText("Sun Brightness: " .. sfn(config.daynight.sun_brightness))
        margin(0, MarginH)
        config.daynight.sun_brightness = AutoSlider(config.daynight.sun_brightness, 0, 10, 1/10, 0, 0, 0)
        margin(0, MarginH)
    end
    margin(0, MarginH)

    -- (2026-11-14) Performance tests: one piece of a road segment's work per button (ui/ConfigMenu.lua
    -- server.perfTest), two per row (the other columns are full)
    margin(-MarginH, 0)
    AutoText("Performance tests (40 m above you)")
    margin(MarginH, MarginH)
    local tests = {
        { "npcs10", "10 NPCs ahead" }, { "probe", "probe ground (aim)" },
        { "delete", "delete test spawns" },
        { "activity", GetBool("savegame.mod.debug.activity") and "spawn activity: ON" or "spawn activity: off" },
        { "budget", "piece budget: " .. math.floor((GetInt("savegame.mod.debug.piece_budget") > 0
            and GetInt("savegame.mod.debug.piece_budget") or 250000) / 1000) .. "k" },
        { "ahead", "generate ahead: " .. (GetInt("savegame.mod.debug.gen_ahead") > 0
            and GetInt("savegame.mod.debug.gen_ahead") or 300) .. " m" },
        { "npcprofile", GetBool("savegame.mod.debug.npcprofile") and "NPC call profile: ON" or "NPC call profile: off" },
        { "invprofile", GetBool("savegame.mod.debug.invprofile") and "inventory call profile: ON" or "inventory call profile: off" },
        { "shiftprobe", GetBool("savegame.mod.debug.shiftprobe") and "shift probe (all players): ON" or "shift probe (all players): off" },
    }
    for i = 1, #tests, 2 do
        UiPush()
            for j = i, math.min(i + 1, #tests) do
                if AutoButton(tests[j][2], FontSize, 2, 2, true, 0) then
                    if tests[j][1] == "probe" then
                        -- (2026-11-14) every layer along the line of sight (ui/ConfigMenu.lua server.probeGround)
                        local ct = GetPlayerCameraTransform()
                        ServerCall("server.probeGround", ct.pos, TransformToParentVec(ct, Vec(0, 0, -1)))
                    elseif tests[j][1] == "npcprofile" or tests[j][1] == "invprofile" or tests[j][1] == "shiftprobe" then
                        -- (2026-11-15) shiftprobe: what each machine sees at a world shift (ui/ShiftProbe.lua)
                        -- (2026-11-15) call-count profilers (lib/CallProfiler.lua): NPC manager / inventory
                        local key = "savegame.mod.debug." .. tests[j][1]
                        SetBool(key, not GetBool(key))
                    elseif tests[j][1] == "ahead" then
                        -- (2026-11-15) how far ahead a segment is queued (GenerateRoad; default 300, v1 200)
                        local cur = GetInt("savegame.mod.debug.gen_ahead")
                        if cur <= 0 then cur = 300 end
                        SetInt("savegame.mod.debug.gen_ahead", cur == 300 and 200 or cur + 50)
                    elseif tests[j][1] == "budget" then
                        -- (2026-11-14) box cells of segment pieces spawned per frame (GenerateRoad PieceBudget)
                        local steps, cur = { 100000, 250000, 500000, 1000000 }, GetInt("savegame.mod.debug.piece_budget")
                        if cur <= 0 then cur = 250000 end
                        local nxt = steps[1]
                        for k = 1, #steps do if steps[k] == cur then nxt = steps[k % #steps + 1] end end
                        SetInt("savegame.mod.debug.piece_budget", nxt)
                    elseif tests[j][1] == "activity" then
                        -- (2026-11-14) on-screen list of recent spawns (ui/ConfigMenu.lua TickActivity / DrawActivity)
                        SetBool("savegame.mod.debug.activity", not GetBool("savegame.mod.debug.activity"))
                    elseif tests[j][1] == "delete" then
                        ServerCall("server.perfTestDelete")
                    else
                        ServerCall("server.perfTest", GetLocalPlayer(), tests[j][1])
                    end
                end
                margin(UI_PANEL_W * 0.42, 0)
            end
        UiPop()
        margin(0, MarginH)
    end

end

function DrawConfigUi_goreai()

    UiPush()

        UiTranslate(UI_PANEL_W/2, 0)
        AutoText("Gore NPCs Debug")
        margin(MarginH, MarginH)

        -- ToggleButton
        if AutoToggleButton(config.goreai.pos_dot, "debug_position", FontSize, 2, 2, true, 0) then
            config.goreai.pos_dot = not config.goreai.pos_dot
        end
        margin(0, MarginH)

        -- ToggleButton
        if AutoToggleButton(config.goreai.outlines, "debug_outlines", FontSize, 2, 2, true, 0) then
            config.goreai.outlines = not config.goreai.outlines
        end
        margin(0, MarginH)

        -- ToggleButton
        if AutoToggleButton(config.goreai.healthbar_debug, "debug_healthbar", FontSize, 2, 2, true, 0) then
            config.goreai.healthbar_debug = not config.goreai.healthbar_debug
        end
        margin(0, MarginH)

        -- ToggleButton
        if AutoToggleButton(config.goreai.text_debug, "debug_text", FontSize, 2, 2, true, 0) then
            config.goreai.text_debug = not config.goreai.text_debug
        end
        margin(0, MarginH)

        -- ToggleButton
        if AutoToggleButton(config.goreai.draw_debug, "debug_navigation", FontSize, 2, 2, true, 0) then
            config.goreai.draw_debug = not config.goreai.draw_debug
        end
        margin(0, MarginH)

        -- ToggleButton
        if AutoToggleButton(config.goreai.draw_combat, "debug_combat", FontSize, 2, 2, true, 0) then
            config.goreai.draw_combat = not config.goreai.draw_combat
        end
        margin(0, MarginH)

        -- ToggleButton
        if AutoToggleButton(config.goreai.draw_projectile_impacts, "draw_bullet_hits", FontSize, 2, 2, true, 0) then
            config.goreai.draw_projectile_impacts = not config.goreai.draw_projectile_impacts
        end
        margin(0, MarginH)

        -- ToggleButton
        if AutoToggleButton(config.goreai.draw_bones, "draw_bones", FontSize, 2, 2, true, 0) then
            config.goreai.draw_bones = not config.goreai.draw_bones
        end
    UiPop()

    AutoText("Gore NPCs")
    margin(MarginH, MarginH)

    -- ToggleButton
    if AutoToggleButton(config.goreai.isEnabled, "Script enabled", FontSize, 2, 2, true, 0) then
        config.goreai.isEnabled = not config.goreai.isEnabled
    end
    margin(0, MarginH)

    -- Button
    if AutoButton("Delete All NPCs", FontSize, 2, 2, true, 0) then
        SetBool("level.deleteNPCs", true)
    end
    margin(0, MarginH)
    margin(0, MarginH)

    -- ToggleButton
    if AutoToggleButton(config.goreai.teams_enabled, "Teams Enabled", FontSize, 2, 2, true, 0) then
        config.goreai.teams_enabled = not config.goreai.teams_enabled
    end
    margin(0, MarginH)

    -- ToggleButton
    if AutoToggleButton(config.goreai.teamsIncludePlayer, "Include Player as Target", FontSize, 2, 2, true, 0) then
        config.goreai.teamsIncludePlayer = not config.goreai.teamsIncludePlayer
    end
    margin(0, MarginH)

    -- Button
    if AutoButton("Reset NPC targets", FontSize, 2, 2, true, 0) then
        SetBool("level.goreai.resetTeams", true)
    end
    margin(0, MarginH)

    -- ToggleButton
    if AutoToggleButton(config.goreai.dist_gun_unlocks, "Distance Based NPC Guns", FontSize, 2, 2, true, 0) then
        config.goreai.dist_gun_unlocks = not config.goreai.dist_gun_unlocks
    end
    margin(0, MarginH)

    -- ToggleButton
    if AutoToggleButton(config.goreai.invincible, "Invincible NPCs", FontSize, 2, 2, true, 0) then
        config.goreai.invincible = not config.goreai.invincible
    end
    margin(0, MarginH)

    -- ToggleButton
    if AutoToggleButton(config.goreai.unbreakable_bones == 2, "Unbreakable Bones", FontSize, 2, 2, true, 0) then
        if config.goreai.unbreakable_bones == 0 then --todo add original switching system back in
            config.goreai.unbreakable_bones = 2
        elseif config.goreai.unbreakable_bones == 2 then
            config.goreai.unbreakable_bones = 0
        end
    end

    margin(-MarginH, 0)
    margin(0, MarginH)
    margin(0, MarginH)


    AutoText("Gore NPCs Behaviour")
    margin(MarginH, 0)
    margin(0, MarginH)

    -- ToggleButton
    if AutoToggleButton(config.goreai.thinkingEnabled, "Thinking enabled", FontSize, 2, 2, true, 0) then
        config.goreai.thinkingEnabled = not config.goreai.thinkingEnabled
    end
    margin(0, MarginH)

    -- ToggleButton
    if AutoToggleButton(config.goreai.shoot, "Shooting Enabled", FontSize, 2, 2, true, 0) then
        config.goreai.shoot = not config.goreai.shoot
    end
    margin(0, MarginH)

    -- ToggleButton
    if AutoToggleButton(config.goreai.throw_grenades, "Throw Grenades", FontSize, 2, 2, true, 0) then
        config.goreai.throw_grenades = not config.goreai.throw_grenades
    end
    margin(0, MarginH)

    -- ToggleButton
    if AutoToggleButton(config.goreai.movement, "Run and Navigate", FontSize, 2, 2, true, 0) then
        config.goreai.movement = not config.goreai.movement
    end
    margin(0, MarginH)

    -- ToggleButton
    if AutoToggleButton(config.goreai.turning, "Turn and Rotate", FontSize, 2, 2, true, 0) then
        config.goreai.turning = not config.goreai.turning
    end
    margin(0, MarginH)

    -- ToggleButton
    if AutoToggleButton(config.goreai.reposition, "Automatically Reposition", FontSize, 2, 2, true, 0) then
        config.goreai.reposition = not config.goreai.reposition
    end
    margin(0, MarginH)

    -- ToggleButton
    if AutoToggleButton(config.goreai.aggressive, "Aggressive Navigation Enabled", FontSize, 2, 2, true, 0) then
        config.goreai.aggressive = not config.goreai.aggressive
    end
    margin(0, MarginH)

    -- ToggleButton
    if AutoToggleButton(config.goreai.dont_clear_nav, "Don't Clear Nav Points", FontSize, 2, 2, true, 0) then
        config.goreai.dont_clear_nav = not config.goreai.dont_clear_nav
    end
    margin(0, MarginH)

    -- Slider
    margin(0, FontSize)
    AutoText("NPC Weapon Sway = " .. sfn(config.goreai.weapon_sway) .. " (default = 1)")
    margin(-FontSize, FontSize)
    config.goreai.weapon_sway = AutoSlider(config.goreai.weapon_sway, 0, 2)

    margin(0, FontSize * 2)
    DrawConfigUi_procedural()

end

function DrawConfigUi_spawn()

    AutoText("Spawn NPCs")
    margin(0, MarginH)
    margin(MarginH, 0)

    do

        UiPush()

            local npcTagKey = GetString("savegame.mod.debugScreen.npcTagKey")

            NpcTags = NpcTags or {
                Normal        = {""},
                Cover         = {"cover"},
                CoverRanged   = {"cover", "ranged"},
                Ranged        = {"ranged"},
                CQC           = {"outside"},
                RPG           = {"rpg"},
            }

            if GetString("savegame.mod.debugScreen.npcTagKey") == "" then
                SetString("savegame.mod.debugScreen.npcTagKey", GetTableKeys(NpcTags)[1])
            end

            UiPush()
                for key, value in pairs(NpcTags) do
                    if AutoToggleButton(key == npcTagKey, key, FontSize, 2, 2, true, 0) then
                        SetString("savegame.mod.debugScreen.npcTagKey", key)
                    end
                    margin(0, MarginH)
                end

                if AutoButton("Enemy Vehicle", FontSize, 4, 4, true) then
                    -- (v2) at the crosshair (10 m ahead if aiming at nothing), spawned by the server
                    ConfigVehicleEvent("roadblock", GetCrosshairWorldPos() or VecAdd(GetPlayerTransform().pos, Vec(10, 2, 0)))
                end
            UiPop()


            local tags = NpcTags[GetString("savegame.mod.debugScreen.npcTagKey")]


        UiPop()

        do

            margin(200, 0)

            local insurgents = {
                "MOD/prefabs/spawnables/enemies/civilian/Ragdollciv1.xml",
                "MOD/prefabs/spawnables/enemies/civilian/Ragdollciv2.xml",
                "MOD/prefabs/spawnables/enemies/civilian/Ragdollciv3.xml",
                "MOD/prefabs/spawnables/enemies/civilian/Ragdollciv4.xml",
                "MOD/prefabs/spawnables/enemies/civilian/Ragdollciv5.xml",
                "MOD/prefabs/spawnables/enemies/civilian/Ragdollciv6.xml",
            }
            -- Button
            if AutoButton("Insurgent", FontSize, 4, 4, true) then
                spawn_npc_at_hitpos(GetRandomArrayValue(insurgents), tags)
            end
            margin(0, MarginH)


            local cultists = {
                "MOD/prefabs/spawnables/enemies/cult/Ragdollcult1.xml",
                "MOD/prefabs/spawnables/enemies/cult/Ragdollcult2.xml",
                "MOD/prefabs/spawnables/enemies/cult/Ragdollcult3.xml",
                "MOD/prefabs/spawnables/enemies/cult/Ragdollcult4.xml",
                "MOD/prefabs/spawnables/enemies/cult/Ragdollcult5.xml",
            }
            -- Button
            if AutoButton("Cultist", FontSize, 4, 4, true) then
                spawn_npc_at_hitpos(GetRandomArrayValue(cultists), tags)
            end
            margin(0, MarginH)


            local mil = {
                "MOD/prefabs/spawnables/enemies/millitary/Ragdollmil1.xml",
                "MOD/prefabs/spawnables/enemies/millitary/Ragdollmil2.xml",
                "MOD/prefabs/spawnables/enemies/millitary/Ragdollmil3.xml",
                "MOD/prefabs/spawnables/enemies/millitary/Ragdollmilofficer1.xml",
                "MOD/prefabs/spawnables/enemies/millitary/Ragdollmilofficer2.xml",
                "MOD/prefabs/spawnables/enemies/millitary/Ragdollmilnight1.xml",
            }
            -- Button
            if AutoButton("AAF", FontSize, 4, 4, true) then
                spawn_npc_at_hitpos(GetRandomArrayValue(mil), tags)
            end
            margin(0, MarginH)


            local um = {
                "MOD/prefabs/spawnables/enemies/um/Ragdollum1.xml",
                "MOD/prefabs/spawnables/enemies/um/Ragdollum2.xml",
                "MOD/prefabs/spawnables/enemies/um/Ragdollpur1.xml",
                "MOD/prefabs/spawnables/enemies/um/Ragdollpur2.xml",
                "MOD/prefabs/spawnables/enemies/um/Ragdollumofficer1.xml",
                "MOD/prefabs/spawnables/enemies/um/Ragdollumofficer2.xml",
            }
            -- Button
            if AutoButton("UM", FontSize, 4, 4, true) then
                spawn_npc_at_hitpos(GetRandomArrayValue(um), tags)
            end
            margin(0, MarginH)


            local merc = {
                "MOD/prefabs/spawnables/enemies/security/Ragdollsecurity2.xml",
            }
            -- Button
            if AutoButton("Friendly Merc", FontSize, 4, 4, true) then
                spawn_npc_at_hitpos(GetRandomArrayValue(merc), tags)
            end
            margin(0, MarginH)

            -- Button
            if AutoButton("Friendly Juggernaut", FontSize, 4, 4, true) then
                spawn_npc_at_hitpos("MOD/prefabs/spawnables/enemies/security/juggernaut.xml", tags)
            end
            margin(0, MarginH)

            -- Button
            if AutoButton("NPC Seated Humvee", FontSize, 4, 4, true) then
                spawn_npc_at_hitpos("MOD/prefabs/spawnables/vehicles/Vehiclewg30.xml", tags)
            end
            margin(0, MarginH)


            margin(-200, 0)

        end


    end
    margin(0, MarginH)
    margin(0, MarginH)
    margin(-MarginH, 0)


    -- (v2) Debug auto-travel (ui/ConfigMenu.lua server.configTravel): fly down the road until the distance
    -- counter grew by the chosen amount, to test long runs quickly.
    AutoText("Auto Travel")
    margin(MarginH, 0)
        margin(0, MarginH)
        UiPush()
        for _, km in ipairs({ 1, 5, 10, 20 }) do
            if AutoButton(km .. " km", FontSize, 4, 4, true) then
                ConfigTravel(km * 1000)
                ShowDebugMod = false
            end
            margin(110, 0)
        end
        UiPop()
        margin(0, MarginH) -- Stop on its own row (the panel is narrow)
        if AutoButton("Stop", FontSize, 4, 4, true) then
            ConfigTravel(0)
        end
        margin(0, MarginH)
        margin(0, MarginH)
    margin(-MarginH, 0)


    -- (v2) Start a timed vehicle event now (world/generation/RandomVehicleEnemy.lua). Ignores the distance and
    -- helicopter-setting conditions. Vehicles arrive from behind (helicopter from ahead), like the timed events.
    AutoText("Vehicle Events")
    margin(MarginH, 0)
        margin(0, MarginH)
        for i = 1, #ConfigVehicleEvents, 2 do -- two buttons per row (the panel does not scroll)
            UiPush()
            for j = i, math.min(i + 1, #ConfigVehicleEvents) do
                local ev = ConfigVehicleEvents[j]
                if AutoButton(ev[2], FontSize, 4, 4, true) then
                    ConfigVehicleEvent(ev[1])
                end
                margin(190, 0)
            end
            UiPop()
            margin(0, MarginH)
        end
        margin(0, MarginH)
    margin(-MarginH, 0)


    -- Spawn menu button
    AutoText("NPC Controller")
    margin(MarginH, 0)
        margin(0, MarginH)
        UiColor(1,1,0,1)
        if AutoButton("Select NPC to Control", FontSize, 4, 4, true) then
            SetBool("level.npcs.selectingControllerNPC", true)
            ShowDebugMod = false
        end
        margin(0, MarginH)
        margin(0, MarginH)
    margin(-MarginH, 0)


    -- Spawn menu button
    AutoText("Spawn Menu")
    margin(MarginH, 0)
        margin(0, MarginH)
        UiColor(1,1,0,1)
        if AutoButton("Open Spawn Menu   (" .. GetKeybindString(Settings.keybinds.other.spawn_menu_) .. ")", FontSize, 4, 4, true) then
            SetBool('level.spawnmenu.api.open', true)
            ShowDebugMod = false
        end
        margin(0, MarginH)
        margin(0, MarginH)
    margin(-MarginH, 0)



    AutoText("Quick Guns + Ammo")
    margin(MarginH, 0)

        margin(0, MarginH)

        for key, data in pairs(SpawnGuns) do
            UiPush()
            if AutoButton(key, FontSize, 4, 4, true) then
                Spawn_Loot_Gun(data, 0, true)
                Spawn_Loot_Gun(data, 1)
            end
            margin(170, 0)
            if AutoButton("Ammo", FontSize, 4, 4, true) then
                Spawn_Loot_Gun(data, 3, true)
            end
            UiPop()
            margin(0, MarginH)
        end
    margin(-MarginH, 0)



end


-- (2026-11-14) moved here from the end of the spawning column, which ran off the bottom of the screen; drawn under
-- the Gore NPCs column (DrawConfigUi_goreai)
function DrawConfigUi_procedural()
    margin(0, MarginH)
    AutoText("Procedural Spawning Controls")
    UiPush()
        margin(MarginH, MarginH)

        local reg_road_segments       = "savegame.mod.procedural.disable.spawn_road_segments"
        local reg_special_segments    = "savegame.mod.procedural.disable.spawn_special_segments"
        local reg_buildings           = "savegame.mod.procedural.disable.spawn_buildings"
        local reg_enemies             = "savegame.mod.procedural.disable.spawn_enemies"
        local reg_loot                = "savegame.mod.procedural.disable.spawn_loot"
        local reg_vehicles            = "savegame.mod.procedural.disable.spawn_vehicles"
        -- (2026-11-14) v1 had a "spawn roadblocks" switch read by the loot spawner and the vehicle events (its roadblock
        -- spawner, RandomRoadBLock.lua, is v1 and only in dev test levels) and a "spawn loot" switch nothing read
        local reg_vehicle_events      = "savegame.mod.procedural.disable.spawn_vehicle_events"
        local reg_decor               = "savegame.mod.procedural.disable.spawn_decor" -- (2026-11-14) GenerateRoad QueueDecor

        if AutoToggleButton(not GetBool(reg_road_segments), "spawn road segments", FontSize, 2, 2, true, 0) then
            SetBool(reg_road_segments, not GetBool(reg_road_segments))
        end
        margin(0, MarginH)

        if AutoToggleButton(not GetBool(reg_special_segments), "spawn special road segments", FontSize, 2, 2, true, 0) then
            SetBool(reg_special_segments, not GetBool(reg_special_segments))
        end
        margin(0, MarginH)

        if AutoToggleButton(not GetBool(reg_buildings), "spawn buildings", FontSize, 2, 2, true, 0) then
            SetBool(reg_buildings, not GetBool(reg_buildings))
        end
        margin(0, MarginH)

        if AutoToggleButton(not GetBool(reg_enemies), "spawn enemies", FontSize, 2, 2, true, 0) then
            SetBool(reg_enemies, not GetBool(reg_enemies))
        end
        margin(0, MarginH)

        if AutoToggleButton(not GetBool(reg_loot), "spawn loot", FontSize, 2, 2, true, 0) then
            SetBool(reg_loot, not GetBool(reg_loot))
        end
        margin(0, MarginH)

        if AutoToggleButton(not GetBool(reg_vehicles), "spawn vehicles", FontSize, 2, 2, true, 0) then
            SetBool(reg_vehicles, not GetBool(reg_vehicles))
        end
        margin(0, MarginH)

        if AutoToggleButton(not GetBool(reg_vehicle_events), "spawn enemy vehicle events", FontSize, 2, 2, true, 0) then
            SetBool(reg_vehicle_events, not GetBool(reg_vehicle_events))
        end
        margin(0, MarginH)

        if AutoToggleButton(not GetBool(reg_decor), "spawn roadside decor", FontSize, 2, 2, true, 0) then
            SetBool(reg_decor, not GetBool(reg_decor))
        end
        margin(0, MarginH)


    UiPop()

end



function Spawn_Loot_Gun(tb_gun, count, dont_spawn_gun)

    if not dont_spawn_gun then
        Spawn_Loot_Single(tb_gun.gun)
    end

    for i = 1, count do
        Spawn_Loot_Single(tb_gun.mag)
    end

end

function spawn_npc_at_hitpos(xml, tags)

    local hit, pos = RaycastFromTransform(GetCameraTransform())
    if hit then

        -- concatenate tags into string, then split it later back into a table.
        local torsoInt      = GetInt("level.torsoInt")
        local tagDataString = table.concat(tags, ",")
        SetString("level.torsoData."..torsoInt, tagDataString) -- Find tags string by torso.

        ConfigSpawn(xml, Transform(pos))

        SetInt("level.torsoInt", GetInt("level.torsoInt") + 1)

    end

end

function Spawn_Loot_Single(path)

    local hit, pos = RaycastFromTransform(GetCameraTransform())

    if hit then
        ConfigSpawn(path, Transform(pos), true)
    end

end

function Spawn_Loot(loots_prefabs)

    local hit, pos = RaycastFromTransform(GetCameraTransform())

    if hit then

        beep()

        for i = 1, loots_prefabs.count or 1 do

            local x = 1
            local z = 1
            for index, prefab in ipairs(loots_prefabs.xmls) do

                ConfigSpawn(prefab, Transform(VecAdd(pos, Vec(x * 3, 0, z * 3)), QuatEuler(0, 0, 0)), true, true)

                if x >= 20 then
                   x   = 1
                   z   = z + 1
                else
                    x = x + 1
                end

            end

        end

    end

end

function Spawn_Loot_All()

    local hit, pos = RaycastFromTransform(GetCameraTransform())

    if hit then

        beep()

        local x = 1
        for key, prefab_category in pairs(Loot_Prefabs) do

            for index, prefab in ipairs(prefab_category.xmls) do

                ConfigSpawn(prefab, Transform(VecAdd(pos, Vec(x*2.5, 0, index)), QuatEuler(0, 90, 0)), true, true)

            end

            x = x + 1

        end


    end

end

SpawnGuns = {

    G17 = {
        gun = "MOD/prefabs/spawnables/loots/Gun P17 TAN3.xml",
        mag = "MOD/prefabs/spawnables/loots/Mag P17 9x19 #2.xml",
    },

    Scalar = {
        gun = "MOD/prefabs/spawnables/loots/Gun SCALAR MILITARY1.xml",
        mag = "MOD/prefabs/spawnables/loots/Mag P17 9x19 #2.xml",
    },

    Simonov545 = {
        gun = "MOD/prefabs/spawnables/loots/Gun Kovalyov-545.xml",
        mag = "MOD/prefabs/spawnables/loots/Mag Simonov 5.45 #4.xml",
    },

    N870 = {
        gun = "MOD/prefabs/spawnables/loots/Gun N870.xml",
        mag = "MOD/prefabs/spawnables/loots/Ammo 12GA.xml",
    },

    Medvedev = {
        gun = "MOD/prefabs/spawnables/loots/Gun Medvedev SNIPER SUPPRESSED MILITARY.xml",
        mag = "MOD/prefabs/spawnables/loots/Ammo 7.62x54R.xml",
    },

    RPG = {
        gun = "MOD/prefabs/spawnables/loots/Gun RPG.xml",
        mag = "MOD/prefabs/spawnables/loots/ROCKET #0.xml",
    },


}

-- count        = how many of each item to spawn in at the same position.
Loot_Prefabs = {

    material = {
        count = 5,
        xmls  = {
            "MOD/items/Loots/material-driftwood.xml",
            "MOD/items/Loots/material-explosive.xml",
            "MOD/items/Loots/material-kevlar.xml",
            "MOD/items/Loots/material-rubber.xml",
            "MOD/items/Loots/material-scrap.xml",
            "MOD/items/Loots/material-steel.xml",
        }
    },

    food = {
        count = 3,
        xmls  = {
            "MOD/items/Loots/food1.xml",
            "MOD/items/Loots/food2.xml",
            "MOD/items/Loots/food3.xml",
            "MOD/items/Loots/food4.xml",
            "MOD/items/Loots/food5.xml",
        }
    },

    gun = {
        count = 1,
        xmls  = {
            "MOD/prefabs/spawnables/loots/Gun Autumnatic's Mudafie.xml",
            "MOD/prefabs/spawnables/loots/Gun Avertnus's Simonov-545.xml",
            "MOD/prefabs/spawnables/loots/Gun Bauer-553.xml",
            "MOD/prefabs/spawnables/loots/Gun Cheejin's SKS.xml",
            "MOD/prefabs/spawnables/loots/Gun CZ-1012.xml",
            "MOD/prefabs/spawnables/loots/Gun Drozdov SNIPER.xml",
            "MOD/prefabs/spawnables/loots/Gun Drozdov.xml",
            "MOD/prefabs/spawnables/loots/Gun Drozdov1.xml",
            "MOD/prefabs/spawnables/loots/Gun Drozdov2.xml",
            "MOD/prefabs/spawnables/loots/Gun Jalaad.xml",
            "MOD/prefabs/spawnables/loots/Gun Kovalyov-545.xml",
            "MOD/prefabs/spawnables/loots/Gun Kovalyov-762.xml",
            "MOD/prefabs/spawnables/loots/Gun N16 Scope.xml",
            "MOD/prefabs/spawnables/loots/Gun N16.xml",
            "MOD/prefabs/spawnables/loots/Gun N4A1 SOPMOD.xml",
            "MOD/prefabs/spawnables/loots/Gun N4A1 STANDARD.xml",
            "MOD/prefabs/spawnables/loots/Gun N4A1.xml",
            "MOD/prefabs/spawnables/loots/Gun N870.xml",
            "MOD/prefabs/spawnables/loots/Gun MC308.xml",
            "MOD/prefabs/spawnables/loots/Gun MC9.xml",
            "MOD/prefabs/spawnables/loots/Gun Medvedev MILITARY.xml",
            "MOD/prefabs/spawnables/loots/Gun Medvedev SNIPER MILITARY.xml",
            "MOD/prefabs/spawnables/loots/Gun Medvedev SNIPER SUPPRESSED MILITARY.xml",
            "MOD/prefabs/spawnables/loots/Gun Medvedev SNIPER SUPPRESSED.xml",
            "MOD/prefabs/spawnables/loots/Gun Medvedev Sniper.xml",
            "MOD/prefabs/spawnables/loots/Gun Medvedev SUPPRESSED MILITARY.xml",
            "MOD/prefabs/spawnables/loots/Gun Medvedev SUPPRESSED.xml",
            "MOD/prefabs/spawnables/loots/Gun Medvedev.xml",
            "MOD/prefabs/spawnables/loots/Gun MGL.xml",
            "MOD/prefabs/spawnables/loots/Gun MK36 MILITARY.xml",
            "MOD/prefabs/spawnables/loots/Gun MK36.xml",
            "MOD/prefabs/spawnables/loots/Gun MK36C MILITARY.xml",
            "MOD/prefabs/spawnables/loots/Gun MK36C.xml",
            "MOD/prefabs/spawnables/loots/Gun Mudafie.xml",
            "MOD/prefabs/spawnables/loots/Gun Offensive's N4A1.xml",
            "MOD/prefabs/spawnables/loots/Gun P17 TAN.xml",
            "MOD/prefabs/spawnables/loots/Gun P17 TAN1.xml",
            "MOD/prefabs/spawnables/loots/Gun P17 TAN2.xml",
            "MOD/prefabs/spawnables/loots/Gun P17 TAN3.xml",
            "MOD/prefabs/spawnables/loots/Gun P17.xml",
            "MOD/prefabs/spawnables/loots/Gun P17A.xml",
            "MOD/prefabs/spawnables/loots/Gun PPSH41.xml",
            "MOD/prefabs/spawnables/loots/Gun Qasira.xml",
            "MOD/prefabs/spawnables/loots/Gun RPG.xml",
            "MOD/prefabs/spawnables/loots/Gun SCALAR.xml",
            "MOD/prefabs/spawnables/loots/Gun Simonov-105.xml",
            "MOD/prefabs/spawnables/loots/Gun Simonov-106 MILITARY1.xml",
            "MOD/prefabs/spawnables/loots/Gun Simonov-106 MILITARY2.xml",
            "MOD/prefabs/spawnables/loots/Gun Simonov-106 MILITARY3.xml",
            "MOD/prefabs/spawnables/loots/Gun Simonov-106 MILITARY4.xml",
            "MOD/prefabs/spawnables/loots/Gun Simonov-106 MILITARY5.xml",
            "MOD/prefabs/spawnables/loots/Gun Simonov-106 MILITARY6.xml",
            "MOD/prefabs/spawnables/loots/Gun Simonov-106.xml",
            "MOD/prefabs/spawnables/loots/Gun Simonov-545 MILITARY.xml",
            "MOD/prefabs/spawnables/loots/Gun Simonov-545.xml",
            "MOD/prefabs/spawnables/loots/Gun Simonov-545U.xml",
            "MOD/prefabs/spawnables/loots/Gun Simonov-762.xml",
            "MOD/prefabs/spawnables/loots/Gun SKS MILITARY.xml",
            "MOD/prefabs/spawnables/loots/Gun SKS.xml",
            "MOD/prefabs/spawnables/loots/Gun Snakey's TCR-308.xml",
            "MOD/prefabs/spawnables/loots/Gun TCR-308 SNIPER.xml",
            "MOD/prefabs/spawnables/loots/Gun TCR-308.xml",
            "MOD/prefabs/spawnables/loots/Gun TCR-556.xml",
            "MOD/prefabs/spawnables/loots/Gun TT-33.xml",
        }
    },

    bullets = {
        count = 5,
        xmls  = {
            "MOD/items/Loots/bullets-12ga.xml",
            "MOD/items/Loots/bullets-545.xml",
            "MOD/items/Loots/bullets-556.xml",
            "MOD/items/Loots/bullets-762x25.xml",
            "MOD/items/Loots/bullets-762x39.xml",
            "MOD/items/Loots/bullets-762x51.xml",
            "MOD/items/Loots/bullets-762x54.xml",
            "MOD/items/Loots/bullets-9x19.xml",
            "rocket.xml",
        }
    },

    armor = {
        count = 2,
        xmls  = {
            "MOD/items/Loots/helmet-altyn.xml",
            "MOD/items/Loots/helmet-ulach.xml",
            "MOD/items/Loots/vest-gzhel.xml",
            "MOD/items/Loots/vest-hexgrid.xml",
            "MOD/items/Loots/vest-killa.xml",
            "MOD/items/Loots/vest-lbtplate.xml",
            "MOD/items/Loots/vest-nfmthor.xml",
            "MOD/items/Loots/vest-sixb2.xml",
            "MOD/items/Loots/vest-thor.xml",
            "MOD/items/Loots/vest-zabralo.xml",
            "MOD/Loots/nvg.xml",
        }
    },

    mag = {
        count = 3,
        xmls  = {
            "MOD/items/Loots/mag0-ak-545.xml",
            "MOD/items/Loots/mag0-ak-762x39.xml",
            "MOD/items/Loots/mag0-ak-762x54.xml",
            "MOD/items/Loots/mag0-ar-556.xml",
            "MOD/items/Loots/mag0-glock-9x19.xml",
            "MOD/items/Loots/mag0-hk-556.xml",
            "MOD/items/Loots/mag0-ppsh-762x25.xml",
            "MOD/items/Loots/mag0-scar-762x51.xml",
            "MOD/items/Loots/mag0-tt33-762x25.xml",
            "MOD/items/Loots/mag1-ak-545.xml",
            "MOD/items/Loots/mag1-ak-762x39.xml",
            "MOD/items/Loots/mag1-ar-556.xml",
            "MOD/items/Loots/mag1-glock-9x19.xml",
            "MOD/items/Loots/mag2-ak-545.xml",
            "MOD/items/Loots/mag2-ar-556.xml",
            "MOD/items/Loots/mag2-glock-9x19.xml",
            "MOD/items/Loots/mag3-ak-545.xml",
            "MOD/items/Loots/mag3-ar-556.xml",
            "MOD/items/Loots/mag4-ak-545.xml",
            "MOD/items/Loots/mag4-ar-556.xml",
            "MOD/items/Loots/mag5-ar-556.xml",
        }
    },

    meds = {
        count = 3,
        xmls  = {
            "MOD/items/Loots/meds-bleed-bandage.xml",
            "MOD/items/Loots/meds-fracture-splint.xml",
            "MOD/items/Loots/meds-general-ai2.xml",
            "MOD/items/Loots/meds-bleed-general-ifak.xml",
            "MOD/items/Loots/meds-stim-adrenaline.xml",
            "MOD/items/Loots/meds-stim-morphine.xml",
            "MOD/items/Loots/meds-stim-pz1.xml",
            "MOD/items/Loots/meds-surgery-cms.xml",
        }
    }

}



function Init_ModVersion()
    VERSION_LATEST = {
        year  = 2022,
        month = 12,
        day   = 25,
    }
end


function CheejinsShortcuts()

    ShowShortcuts = ShowShortcuts or false

    if InputPressed("tab") then
        ShowShortcuts = not ShowShortcuts
    end


    if InputDown("pgup") then
        if InputPressed("f5") then
            MenuStartLevel("", "MOD/npcs/GoreNPCs/map/gore_map.xml", "") -- (v2) host only, menu_host.lua
        end
        if InputPressed("f6") then
            MenuStartLevel("", "MOD/GoreNPCs/map/blankahmap.xml", "")
        end
    end


    if ShowShortcuts then
        UiPush()

            local btnH = 48
            local fs = btnH * 0.75
            uiSetFont(fs)
            UiAlign("center top")
            UiTranslate(UiCenter(), UiMiddle()/2)

            local levels = {
                "MOD/dev/levels/test_npc.xml",
                "MOD/npcs/GoreNPCs/map/gore_map.xml",
            }

            UiText("Shortcuts (press tab to close)")
            UiTranslate(0, btnH)
            UiButtonImageBox('ui/common/box-solid-6.png', 6, 6, 0.5,0.5,0.5, 0.75)
            UiButtonHoverColor(0,1,0, 1)
            for _, path in ipairs(levels) do
                if UiTextButton(path) then
                    MenuStartLevel("", path, "")
                end
                UiTranslate(0, btnH)
            end

        UiPop()
    end

end

function HandleQuickload(cmd)
	for _, word in ipairs(splitString(cmd, " ")) do
		if word == "quickload" then
			ConfigMenu_Init()
		end
		break
	end
end

-- (v2) Debug menu: auto-travel request (0 = stop); the server moves the player (ui/ConfigMenu.lua).
function ConfigTravel(meters)
    if ServerCall and client then
        ServerCall("server.configTravel", GetLocalPlayer(), meters)
    end
end

-- (v2) Debug menu: vehicle events (see the buttons above and server.configVehicleEvent in ui/ConfigMenu.lua).
ConfigVehicleEvents = {
    { "civ",     "Hostile Car" },
    { "aaf",     "Military" },
    { "refugee", "Refugees" },
    { "refugee_van", "Refugee Van" }, -- the refugee event with VehicleC3 (rebuilt 2026-11-08) instead of a random one
    { "heli",    "Helicopter" },
}
function ConfigVehicleEvent(name, pos)
    if ServerCall and client then
        ServerCall("server.configVehicleEvent", name, pos or Vec())
        return
    end
    -- v1 includers (no ServerCall): same registry request, read by RandomVehicleEnemy.lua
    pos = pos or Vec()
    SetFloat("level.debug.vehicle_event_x", pos[1])
    SetFloat("level.debug.vehicle_event_y", pos[2])
    SetFloat("level.debug.vehicle_event_z", pos[3])
    SetString("level.debug.vehicle_event", name)
end

-- (v2) Spawn for the debug menu: in a v2 script the client asks the server (server.configSpawn in
-- ui/ConfigMenu.lua), so the object is a real, shared one. v1 includers have no ServerCall: spawn directly.
-- allowStatic: Spawn(..., true, true) as before; makeStatic: make the spawned bodies static (loot grids).
function ConfigSpawn(xml, transform, allowStatic, makeStatic)
    if ServerCall and client then
        ServerCall("server.configSpawn", xml, transform, allowStatic or false, makeStatic or false)
        return
    end
    local entities = allowStatic and Spawn(xml, transform, true, true) or Spawn(xml, transform)
    if makeStatic then
        for _, entity in ipairs(entities) do
            if GetEntityType(entity) == "body" then SetBodyDynamic(entity, false) end
        end
    end
end

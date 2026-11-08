--[[
#include "./scripts/TDSU/tdsu.lua"
#include "Automatic.lua"
]]


layers = {
    "Required",
    "MorsLonga",
    "ProceduralGeneration",
    "ToolsAndWeapons",
}

function init()

    FontSize = 24
    MarginH = 30

    ShowDebugMod = false -- toggle ui screen drawing.

    SetString("hud.notification", "Press shift + alt to open layer selection menu")

    -- print("init test.lua")

end

function tick()
    if InputPressed("alt") and InputDown("shift") then
        ShowDebugMod = not ShowDebugMod
    end
end

function draw()

    UiPush()

        -- if true then

            UiMakeInteractive()
            margin(UiCenter() - 400, 300)

            -- Container
            AutoContainer(800, 500, 2, false, true)


            -- Title
            AutoText("Layer Selector", FontSize)
            margin(0, MarginH)


            -- Layer buttons
            for index, layer_string in ipairs(layers) do

                if layer_string == GetString("savegame.mod.test.layer") then
                    UiColor(0,1,0, 1)
                    UiRect(8, 24)
                else
                    UiColor(1,0,0, 1)
                    UiRect(8, 24)
                end

                UiPush()
                    UiTranslate(10, 0)
                    -- Button
                    if AutoButton(layer_string, FontSize, 0, 0, true, 0) then
                        StartLevel("", "MOD/test.xml", layer_string)
                        SetString("savegame.mod.test.layer", layer_string)
                    end
                UiPop()

                margin(0, MarginH)

            end

            -- -- ToggleButton
            -- config.goreai.isEnabled = AutoToggleButton(config.goreai.isEnabled, "config.goreai.isEnabled", FontSize, 0, 0, true, 0)
            -- margin(0, MarginH)

        -- end

    UiPop()

end

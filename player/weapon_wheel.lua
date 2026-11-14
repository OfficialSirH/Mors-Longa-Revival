#include "inventory.lua"

function draw_WeaponWheel()

    -- if KeybindDown(Settings.keybinds.player.weapon_wheel) then

    --     UiMakeInteractive()

    --     local gun1  = GetString("level.weapon_wheel.gun1")
    --     local gun2  = GetString("level.weapon_wheel.gun2")
    --     local melee = GetString("level.weapon_wheel.melee")
    --     local gun4  = GetString("level.weapon_wheel.gun4")

    --     UiPush()

    --         UiTranslate(UiCenter(), UiMiddle())
    --         UiAlign("center middle")
    --         UiFont("regular.ttf", 28)

    --         draw_WeaponWheelItem(gun1,  true, 0,250,  100, 100, 1)
    --         draw_WeaponWheelItem(gun2,  true, 0,-250,  100, 100, 2)
    --         draw_WeaponWheelItem(melee, true, 500,0, 100, 100, 3)
    --         draw_WeaponWheelItem(gun4,  true, -500,0, 100, 100, 4)

    --     UiPop()

    -- end

end


function draw_WeaponWheelItem(tool_id, active, x,y, w,h, slot)

    if tool_id ~= "" then
        UiPush()

            local scale = 3.5

            local img_path = "MOD/assets/img/icon/" .. tool_id .. ".png"
            local iw, ih = UiGetImageSize(img_path)
            UiTranslate(x, -y)

            local mouse_in_rect = UiIsMouseInRect(iw*scale, ih*scale)
            local a = ternary(mouse_in_rect, 0.3, 0.5)
            UiPush()
                UiColor(0,0,0, a)
                UiRect(iw*scale, ih*scale)
            UiPop()

            -- local clicked_rect = (mouse_in_rect and InputPressed("usetool"))

            if slot ~= 3 then
                drawGun(GetString("inventory.guns."..slot..".item"), true)
            else
                UiImageBox(img_path, iw, ih)
            end

            if active and mouse_in_rect then
                InvSetTool(tool_id) -- (v2) see inventory.lua
            end

            UiTranslate(0, ih*scale/2)
            UiColor(1,1,1, 1)
            UiAlign("center bottom")
            UiText(GetString("game.tool." .. tool_id .. ".name"))

        UiPop()
    end

end


#include "menu_main.lua"

function init()

    init_config()
	Init_Settings()
	init_update_log()

    ShowSettings = false

end

function tick()
    if PauseMenuButton("MorsLonga Settings") then
        ShowSettings = true
    end
end

function draw()

    if not Menu_Initialized then
		Init_Main_Menu()
		return
	end

    UiTranslate(UiCenter() * 0.5, UiMiddle() * 0.1)

    if ShowSettings then
        UiMakeInteractive()
        Select_Menu_Item(Menu_Items.options)

        UiAlign("left top")
        if draw_menu_item_options(UiWidth() * 0.5, UiHeight() * 0.9) then
            ShowSettings = false
        end
    end

end
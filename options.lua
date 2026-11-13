function draw()

    local fs = 24
    local fs2 = fs*2
    UiAlign("center middle")
    UiFont("bold.ttf", fs)

    -- Title
    UiPush()
        UiAlign("center top")
        UiColor(1,1,1, 1)
        UiTranslate(UiCenter(), 0)
        local w, h = UiGetImageSize("MOD/img/logo_normal.png")
        UiImageBox("MOD/img/logo_normal.png", w/3, h/3)
    UiPop()

    -- Close button
    UiPush()
        UiColor(1, 1, 1, 1)
        UiButtonImageBox('ui/common/box-outline-6.png', 6, 6, 1,1,1, 1)
        UiTranslate(UiCenter(), UiHeight() - fs2*2)
        UiFont("bold.ttf", fs2)
        if UiTextButton("Close", 200, fs2*1.5) then
            Menu()
        end
    UiPop()

    -- Reset button
    UiColor(1, 0, 0, 1)
    UiButtonImageBox('ui/common/box-outline-6.png', 6, 6, 1,0,0, 1)
    UiPush()
        UiTranslate(UiCenter(), UiMiddle())
        UiFont("bold.ttf", fs2)
        if UiTextButton("Reset Mod and Save Data", 550, fs2*2) then
            ClearKey("savegame.mod")
            DebugPrint("Mors Longa successfully reset.")
        end
    UiPop()

end

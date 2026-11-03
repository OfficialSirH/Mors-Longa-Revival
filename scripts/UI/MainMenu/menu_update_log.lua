--[[

    Output
        List
        Expanding window

    Input
        Buttons
        Scrolling

    Requirements
        Version checking.
        Open and close
        Scroll box
        Update Indicator
        List
            Bullet points
            Word wrap
            Formatting
                - Update version/date
                - Update Title
                - Single change
                - Change details
                - Sublists

    Future
        Number of updates.
        Hover over single changes removes indicator

]]

local reg_updatesCheckPath = "savegame.mod.updatesChecked"

local fontSizes = {
    title = 32,
    text = 24
}


function init_update_log()

    UpdateLog = {
    }

    SelectedListItem = 1

    init_update_log_data()

end


function draw_update_log(btn_width, btn_height, font_size)
    UiPush()

        UiAlign("center top")
        UiFont("bold.ttf", font_size)
        UiColor(1, 1, 1, 1)
        UiButtonImageBox("ui/common/box-solid-6.png", 6,6, Grey_Dark,Grey_Dark,Grey_Dark, 3/4)


        -- Top right corner.
        UiTranslate(UiWidth() - (btn_width/2) - 20, (btn_height/2) - 10)


        -- Button
        if UiTextButton("Update Log", btn_width, btn_height) then
            PlaySound(sndnext)
            Select_Menu_Item(Menu_Items.update_log)
            clear_update_log_notification()
        end


        -- Update indicator icon
        if check_update_log_notification() then
            DrawCenterImage(-btn_width / 2, 0, btn_height, btn_height, Button_Icons.update, 1,1,1, Oscillate())
            UiTranslate(0, font_size * 3)
        end

    UiPop()
end


function draw_menu_item_update_log()

    -- Draw container
    -- if UpdateLog.Expanded then

        Pad = 20
        local pad = Pad
        local x = -280
        local y = -UiMiddle()
        local w = UiCenter() * 1.2
        local h = UiHeight() * 0.9


        uiSetFont(fontSizes.title)
        UiTranslate(x, y + 50)


        UiPush()
            UiAlign("left top")
            UiColor(0,0,0, 0.9)
            UiImageBox("ui/common/box-solid-6.png", w, h, 6, 6)
        UiPop()


        -- Title
        UiPush()
            UiAlign("center top")
            UiTranslate(w/2, pad)
            UiText("Update Log")
        UiPop()


        --Button: Close
        UiPush()
            UiAlign("center bottom")
            UiTranslate(w/2, h - pad)
			UiColor(1, 1, 1, 1)
			UiButtonImageBox("ui/common/box-solid-6.png", 6,6, Grey_Dark,Grey_Dark,Grey_Dark, 3/4)
            if UiTextButton('Close', 200, fontSizes.title * 1.5) then
				PlaySound(sndnext)
				Select_Menu_Item(nil)
			end
        UiPop()


        -- Draw list.
        UiAlign("left top")
        UiTranslate(pad, fontSizes.title * 2)
        uiSetFont(fontSizes.text)

        local listW = w - (pad*4)
        local listH = h - (fontSizes.title * 5)
        UiColor(1,1,1, 0.1/2)
        UiRect(listW, listH)


        draw_update_log_list(listW, listH)

    -- end

end


function draw_update_log_list(w, h)

    -- Scrollbar can be uncapped for the first tick.

    local fs = fontSizes.text
    local sp = fontSizes.text
    local indent = fs*2
    local indents = 0
    local listHeight = 0

    UiPush()

        -- Side list
        UiPush()
            UiTranslate(-650, 300)
            UiAlign("left middle")
            UiFont("bold.ttf", fs - 4)
            UiColor(1,1,1, 1)
            for index, item in ipairs(UpdateLogItems) do

                local item = item[1]

                if index == SelectedListItem then
                    UiButtonImageBox("ui/common/box-solid-6.png", 6,6, Grey_Light,Grey_Light,Grey_Light, 3/4)
                    UiPush()
                        UiTranslate(-30, 0)
                        UiImageBox("MOD/img/icon_arrow_right.png", 20, 20)
                    UiPop()
                else
                    UiButtonImageBox("ui/common/box-solid-6.png", 6,6, Grey_Dark,Grey_Dark,Grey_Dark, 3/4)
                end

                if UiTextButton(" ", 600, 40) then
                    SelectedListItem = index
                    updateLog_dy = 0
                    PlaySound(sndnext)
                end

                UiPush()
                    UiTranslate(20, 0)
                    UiText(item.version)
                    UiTranslate(80, 0)
                    UiText(item.date)
                    UiTranslate(180, 0)
                    UiText(item.title)
                UiPop()

                UiTranslate(0, 50)

            end
        UiPop()

        UiAlign("left top")
        UiWindow(w, h, true)

        UiPush()
            local listTotHeight = 0
            UiPush()
                local listTempIndents = 0
                for _, item in ipairs(UpdateLogItems) do
                    local itemH = 0
                    item = item[1] -- Wrapped in a table.
                    UiTranslate(0, sp) itemH=itemH+sp
                    UiFont("bold.ttf", fs)
                    local _, textH = UiGetTextSize(item.date) itemH=itemH+math.max(textH,0) -- Item date
                    local _, textH = UiGetTextSize(item.title) itemH=itemH+math.max(textH,0) -- Item title
                    -- Draw changes list
                    UiTranslate(0, sp) itemH=itemH+sp
                    uiSetFont(fs)
                    for _, change in ipairs(item.changes) do

                        -- Header
                        UiTranslate(indent, 0)
                        local _, textH = UiGetTextSize(change.header) itemH=itemH+math.max(textH,0)
                        listTempIndents = listTempIndents + 1
                        UiTranslate(0, sp) itemH=itemH+sp
                        -- Bullet points
                        UiTranslate(indent, 0)
                        listTempIndents = listTempIndents + 1
                        UiWordWrap(w - ((listTempIndents*indent) + sp*2))
                        for _, change_content in ipairs(change.changes) do

                            if type(change_content) == "string" then
                                local _, textH = UiGetTextSize(change_content) itemH=itemH+math.max(textH,0)

                            elseif type(change_content) == "table" then -- Sublists

                                for index, sublist_string in ipairs(change_content) do
                                    local _, textH = UiGetTextSize(sublist_string) itemH=itemH+math.max(textH,0)
                                end

                            end


                        end
                        UiTranslate(0, sp) itemH=itemH+sp -- Space between each change
                        UiTranslate(-indent*2, 0)
                    end
                    listTotHeight = listTotHeight + itemH
                end
            UiPop()
            local extraH = listTotHeight - h

            updateLog_dy = AutoDefault(updateLog_dy, 0)
            if UiIsMouseInRect(w, h) then
                local rawScroll = InputValue('mousewheel')
                updateLog_dy = updateLog_dy - math.abs(rawScroll) * rawScroll * 15
                if math.abs(rawScroll) > 0 then PlaySound(sndscroll) end
            end
            updateLog_dy = AutoClamp(updateLog_dy, 0, math.max(extraH,0))

            if extraH > 0 then
                UiColor(1, 1, 1, 1)
                UiTranslate(w)
                UiAlign("right top")
                local screen = AutoMap(updateLog_dy, 0, extraH, 0, h - 16)
                screen, released = UiSlider('ui/common/dot.png', "y", screen, 0, h - 16)
                updateLog_dy = AutoMap(screen, 0, h - 16, 0, extraH)
                UiColor(0, 0, 0, .2)
                UiRect(16, h)
            end
        UiPop()
        uiSetFont(fs)
        UiTranslate(sp, -updateLog_dy)

        for index, item in ipairs(UpdateLogItems) do

            local itemH = 0
            item = item[1] -- Wrapped in a table.
            indents = 0

            if SelectedListItem == index then

                UiTranslate(0, sp) itemH=itemH+sp
                UiFont("bold.ttf", fs)
                local _, textH = UiText(item.date, true) itemH=itemH+textH -- Item date
                local _, textH = UiText(item.title, true) itemH=itemH+textH -- Item title


                -- Draw changes list
                UiTranslate(0, sp) itemH=itemH+sp
                uiSetFont(fs)
                for _, change in ipairs(item.changes) do

                    -- Header
                    UiTranslate(indent, 0)
                    local _, textH = UiText(change.header, true) itemH=itemH+textH
                    indents = indents + 1

                    UiTranslate(0, sp) itemH=itemH+sp

                    -- Bullet points
                    UiTranslate(indent, 0)
                    indents = indents + 1
                    UiWordWrap(w - ((indents*indent) + sp*2))
                    for _, change_content in ipairs(change.changes) do

                        if type(change_content) == "string" then

                            DrawCenterImage(-sp/2, sp/4, sp/3, sp/3, "ui/common/dot.png", 1,1,1,1)
                            local _, textH = UiText(change_content, true) itemH=itemH+textH

                        elseif type(change_content) == "table" then -- Sublists

                            UiTranslate(indent/2, 0)
                            for _, item_text in ipairs(change_content) do

                                if item_text ~= "" then

                                    DrawCenterImage(-sp/2, sp/4, sp/2, sp/2, "ui/common/play.png", 1,1,1,1)
                                    local _, textH = UiText(item_text, true) itemH=itemH+textH

                                else -- Black space

                                    local _, textH = UiText("asd", true) itemH=itemH+textH

                                end

                            end
                            UiTranslate(-indent/2, 0)
                            UiTranslate(0, sp) itemH=itemH+sp

                        end


                    end

                    UiTranslate(0, sp) itemH=itemH+sp -- Space between each change
                    UiTranslate(-indent*2, 0)

                end

                listHeight = listHeight + itemH
                UiTranslate(-Pad*2, 0)

            end

        end

        UpdateLogListSize = UpdateLogListSize or listHeight

    UiPop()

end



function check_update_log_notification()
    return GetInt(reg_updatesCheckPath) < #UpdateLogItems
end

function clear_update_log_notification()
    SetInt(reg_updatesCheckPath, #UpdateLogItems)
end

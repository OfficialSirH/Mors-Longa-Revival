#version 2
#include "script/include/player.lua"
--[[
#include "../lib/TDSU/tdsu.lua"
#include "../lib/Automatic.lua"
#include "../world/generation/SpawnRefrenceTable.lua"
#include "../lib/Settings.lua"
]]


SpawnMenuAPI = {
    bool = {
        open = 'level.spawnmenu.api.open',
        close = 'level.spawnmenu.api.close',
    }
}

-- (v2) client: the menu UI. The server spawns the items (server.spawnMenuSpawn) and keeps each player's
-- spawn history for the undo key (server.spawnMenuUndo).

function server.init()
    SpawnedByPlayer = {}
end

function server.spawnMenuSpawn(p, xml, pos, count)
    local all_entities = {}
    for i = 1, count do
        table.insert(all_entities, Spawn(xml, Transform(pos)))
    end
    SpawnedByPlayer[p] = SpawnedByPlayer[p] or {}
    table.insert(SpawnedByPlayer[p], all_entities)
end

function server.spawnMenuUndo(p)
    local list = SpawnedByPlayer[p]
    if list and #list >= 1 then
        for index_item, item in ipairs(list[#list]) do
            for index, entity in ipairs(item) do
                if IsHandleValid(entity) then Delete(entity) end
            end
        end
        list[#list] = nil
    end
end

function client.init()

	Init_Settings()
    init_spawnMenu()

    Selected_Cat = GetTableKeys(spawnables.loots)[1]

    if GetInt(LootCountPath) == 0 then
        SetInt(LootCountPath, 1)
    end

end

function init_spawnMenu()

    Spawned_Items = {} -- All spawned entities. Use for undo function.


    Loot_Count_Button_Numbers = { 1, 2, 3, 5, 10, 25, 50}
    Loot_Count = 1
    LootsFilePath = "MOD/prefabs/spawnables/loots/"
    LootCountPath = "savegame.mod.SpawnMenu.Loot_Count"

    FavoritesSelected = false
    FavoritesPath = "savegame.mod.spawnmenu.favorites."
    FavoritesPathNoDot = "savegame.mod.spawnmenu.favorites"

    SearchString = ""
    SearchResults = {}
    SearchResultsCount = 0

    ShouldFilter = false -- Aids in making sure a query is run only the tick it is needed.
    FilteredData = nil -- Table containing results of a filter (search, favorites, category)

    Selected_Cat_Header = nil


    pressed_open = function() return KeybindPressed(Settings.keybinds.other.spawn_menu_) or GetBool(SpawnMenuAPI.bool.open) end --- Checks if shortcut pressed.
    pressed_undo = function() return KeybindPressed(Settings.keybinds.other.spawn_menu_undo) end --- Checks if shortcut pressed.

    color_cat      = function() return 0.8, 0.2, 0.2, 1 end -- category
    color_loot     = function() return 0.2, 0.2, 0.8, 1 end -- mouse hover over list item (highlight row)
    color_count    = function() return 0.5, 0.8, 0.5, 1 end -- spawn count
    color_fav      = function() return 1, 0.8, 0.1, 1 end -- spawn count

    SpawnMenuIcons = {
        favorite_solid = "MOD/assets/img/icon_star_solid.png",
        favorite_outline = "MOD/assets/img/icon_star_outline.png",
    }


    -- Category, subcategory
    CategoryTitles = {

        Food = {
            { "civFood",         "Civilian"},
            { "milFood",         "Military"},
        },

        Materials = {
            { "banditGeneral",   "Bandit"},
            { "civGeneral",      "Civilian"},
            { "milGeneral",      "Military"},
        },

        Weapons = {
            { "banditWeapon",    "Bandit"},
            { "eggWeapon",       "Dev Guns"},
            { "civWeapon",       "Civilian"},
            { "milWeapon",       "Military"},
            { "UMWeapon",        "UM"},
            { "debugTest",       "Testing"}, -- (v2) guns/mags/ammo missing from the loot tables
        },

        Medical = {
            { "medical",         "Healing Meds"},
            { "stim",            "Stimulants"},
        },

    }

end


function client.tick()

    pressed_open = function() return KeybindPressed(Settings.keybinds.other.spawn_menu_) or GetBool(SpawnMenuAPI.bool.open) end --- Checks if shortcut pressed.
    pressed_undo = function() return KeybindPressed(Settings.keybinds.other.spawn_menu_undo) end --- Checks if shortcut pressed.

    -- Undo last set of spawned entities.
    if pressed_undo() and #Spawned_Items >= 1 then
        ServerCall("server.spawnMenuUndo", GetLocalPlayer())
        Spawned_Items[#Spawned_Items] = nil
        beep()
    end

    reset_spawnmenu_api()

end


--todo Save last amount spawned for each loot in savegame so player does not have to change it back each time.
function client.draw()
    UiPush()

        local hit, pos = nil,nil

        Loot_Count = GetInt(LootCountPath)
        CloseAfterSpawning = GetBool("savegame.mod.SpawnMenu.CloseAfterSpawning")
        IsMouseOnAnyPanel = false
        local shouldClose = false


        Show_Spawn_Menu = Show_Spawn_Menu or false
        if pressed_open() then
            Show_Spawn_Menu = not Show_Spawn_Menu
            beep()
        elseif InputPressed("esc") or KeybindPressed(Settings.keybinds.inventory.toggle_inv) then
            Show_Spawn_Menu = false
        end
        -- if InputDown("up") or InputDown("down") or InputDown("left") or InputDown("right") then Show_Spawn_Menu = false end
        if Show_Spawn_Menu then
            UiMakeInteractive()
            hit, pos = RaycastFromTransform(GetCameraTransform(), nil, nil, nil, nil, true)
            if pos then
                DrawDot(pos, 1/10,1/10, 1,1,1, 1)
            end
        else
            return
        end


        local fs = 22 -- font size
        local sp = fs + 4 -- vertical spacing
        local pad = 25
        local width = UiCenter()
        local height = UiHeight() * 0.9
        local a_list = 0.8
        local a_btn = 0.9

        UiColor(1,1,1, 1)
        UiTextShadow(0.5,0.5,0.5, 1, 0.1)
        UiFont("regular.ttf", fs)
        UiAlign("left top")
        UiButtonImageBox('ui/common/box-solid-6.png', 6, 6, 0,0,0, a_btn)

        Scroll_val = Scroll_val or 0
        Scroll_val = clamp(Scroll_val + InputValue("mousewheel")*fs*2, Scroll_max or -math.huge, 0)
        Scroll_max = Scroll_max or 0


        local loots = spawnables.loots
        UiTranslate(0, UiHeight() * 0.1)

        -- List Header
        UiPush()

            UiTranslate(UiCenter())
            UiAlign("center bottom")

            if FavoritesSelected and SearchString == "" then
                UiColor(color_fav())
            else
                UiColor(color_cat())
            end
            UiRect(width, sp*2)

            UiFont("regular.ttf", fs*2)
            UiColor(1,1,1, 1)

            -- Choose spawn menu header
            local header = Selected_Cat_Header or Selected_Cat
            if SearchString ~= "" then
                header = "Custom Search"
            elseif FavoritesSelected then
                header = "Favorites"
            end
            UiText(header)

        UiPop()


        local listH = height * 0.85
        UiPush()

            local scrW = 24 -- Scrollbar width
            UiTranslate(UiCenter()/2 + (width-scrW) -1, 0)

            UiColor(0.2,0.2,0.2, 1)
            UiRect(scrW, listH)

            UiTranslate(2, 2)
            UiColor(0,0,0, 1)
            UiRect(scrW-4, listH-4)

            UiTranslate(2, 0)
            UiColor(1,1,1, 1)
            local scroll = AutoMap(Scroll_val, 0, Scroll_max, 0, listH - scrW)
            scroll, released = UiSlider('ui/common/dot.png', "y", scroll, 0, listH - scrW)
            Scroll_val = AutoMap(scroll, 0, listH - scrW, 0, Scroll_max)

            IsMouseOnAnyPanel = IsMouseOnAnyPanel or UiIsMouseInRect(scrW, listH)
            -- DebugWatch("Scroll_val", Scroll_val)
            -- DebugWatch("scroll_max", Scroll_max)

        UiPop()


        local mouseOnList = UiIsMouseInRect(UiWidth(), height * 0.85)

        -- List panel
        UiTranslate(UiCenter()/2)
        UiPush()

            width = width - scrW

            UiWindow(width, listH, true)
            IsMouseOnAnyPanel = IsMouseOnAnyPanel or UiIsMouseInRect(UiWidth(), UiHeight())

            UiColor(0,0,0, a_list)
            UiRect(width, listH)
            UiColor(1,1,1, 1)


            local itemsCount = 0

            --> Choose which data set to display (category, search results, favorites, etc...).
            if FilteredData == nil or ShouldFilter then
                if SearchString ~= "" and SearchResultsCount >= 1 then -- Favorites selected
                    FilteredData = SearchResults
                elseif FavoritesSelected then -- Search results valid
                    FilteredData = GetAllFavorites()
                else
                    FilteredData = loots[Selected_Cat]
                end

                Scroll_val = 0
            end
            ShouldFilter = false


            if SearchString ~= "" and SearchResultsCount == 0 then

                uiSetFont(fs*2)
                UiText("No results for: " .. SearchString)

            elseif FavoritesSelected and not has_favorites() then

                uiSetFont(fs*2)
                UiText("No favorites have been set.")

            else

                UiTranslate(0, Scroll_val)

                --> Draw list items.
                for string_rarity, rarity in pairs(FilteredData) do

                    local all_rarities = {} -- Stores xml path strings.
                    local all_rarities_titles = {} -- Stores custom title strings.

                    -- Create array of filenames.
                    for _, loot in ipairs(rarity) do
                        if type(loot[1]) == "string" then

                            local path = loot[1]

                            TableInsertUnique(all_rarities, path)

                            if loot[3] then
                                all_rarities_titles[path] = loot[3] -- Custom item title.
                            end

                        end
                    end
                    table.sort(all_rarities) --> Sort A-Z

                    for index, loot in ipairs(all_rarities) do
                        UiPush()

                            local xml = LootsFilePath .. loot

                            -- Choose custom title over xml path. Removes ".xml" from text display
                            local title = all_rarities_titles[loot] or string.sub(loot, 1, -5)

                            -- Highlight list item on mouse over.
                            if UiIsMouseInRect(width, sp) then
                                UiColor(color_loot())
                                UiRect(width, sp)
                            end

                            -- Check favorite in registry.
                            local isFav = GetBool(FavoritesPath .. xml)
                            UiPush()
                                if isFav then
                                    UiButtonImageBox(SpawnMenuIcons.favorite_solid, 0,0, color_fav())
                                else
                                    UiButtonImageBox(SpawnMenuIcons.favorite_outline, 0,0, 0.6,0.6,0.6, 1)
                                end

                                if UiTextButton(" ", sp-2, sp-2) then spawnmenu_toggle_favorite(xml) end
                            UiPop()

                            
                            UiTranslate(sp*2, 0)
                            local pressed = UiIsMouseInRect(width - (sp*2), sp) and (InputPressed("usetool") or InputPressed("lmb")) and mouseOnList

                            UiText(string_pad(string_rarity, pad)) -- Display text: rarity

                            UiTranslate(20, sp/2)
                            UiAlign("left middle")
                            UiColor(1,1,1, 1)
                            UiTranslate(fs*10, 0)
                            UiText(title) -- Display text: title of the item

                            -- Spawn items based on count
                            if pressed then
                                -- beep()
                                if not hit then
                                    pos = TransformToParentPoint(GetCameraTransform(), Vec(0,0,-10))
                                end
                                ServerCall("server.spawnMenuSpawn", GetLocalPlayer(), xml, pos, Loot_Count)
                                table.insert(Spawned_Items, true) -- (v2) entities live on the server; this only counts batches

                                if CloseAfterSpawning then
                                    shouldClose = true
                                end
                            end

                        UiPop()

                        UiTranslate(0, sp)
                        itemsCount = itemsCount + 1

                    end

                    UiTranslate(0, sp)
                    itemsCount = itemsCount + 1 -- Space between rarities.

                end

            end

            Scroll_max = -sp * itemsCount + (height/2)

            -- DebugWatch("scroll_max", scroll_max)
            -- DebugWatch("scroll_sm", scroll_sm)
        UiPop()


        width = width + scrW

        -- Count and CloseAfterSpawning panel
        UiPush()

            UiPush()
                local btnW = width / #Loot_Count_Button_Numbers / 2

                UiColor(0.5,0.5,0.5, 1)
                UiTranslate(0, (height * 0.85) + 3)
                UiFont("bold.ttf", fs * 1.35)

                IsMouseOnAnyPanel = IsMouseOnAnyPanel or UiIsMouseInRect(width, fs * 2)

                -- Spawn items count button
                UiAlign("left top")
                for index, value in ipairs(Loot_Count_Button_Numbers) do
                    UiPush()
                        if value == Loot_Count then
                            UiColor(0,0,0,1)
                            if index > #Loot_Count_Button_Numbers - 2 then -- Higher count is red to indicate potential lag (more than 25 items usually)
                                UiButtonImageBox('ui/common/box-solid-6.png', 6,6, 1, 0.2, 0.2, 1)
                            else
                                UiButtonImageBox('ui/common/box-solid-6.png', 6,6, 0.9, 0.9, 0.9, 1)
                            end
                            UiColor(0,0,0,1)
                            UiImageBox("ui/common/box-solid-6.png", btnW, fs*2, 6, 6)
                        else
                            UiColor(0,0,0,0.7)
                            UiImageBox("ui/common/box-solid-6.png", btnW, fs*2, 6, 6)
                            UiColor(1,1,1,1)
                            UiButtonImageBox('ui/common/box-outline-6.png', 6,6, 0, 0, 0, 1)
                        end
                        if UiTextButton(tostring(value), btnW, fs*2) then
                            SetInt(LootCountPath, value)
                            break
                        end
                    UiPop()
                    UiTranslate(btnW, 0)
                end

                -- CloseAfterSpawning button
                local btnW = width/4
                UiTranslate(btnW, 0)
                if CloseAfterSpawning then
                    UiColor(0,0,0, 1)
                    UiButtonImageBox('ui/common/box-solid-6.png', 6,6, 0.9, 0.9, 0.9, 1)
                else
                    UiColor(0,0,0,0.8)
                    UiImageBox("ui/common/box-solid-6.png", btnW, fs*2, 6, 6)
                    UiColor(1,1,1,1)
                    UiButtonImageBox('ui/common/box-outline-6.png', 6,6, 0, 0, 0, 1)
                end
                if UiTextButton(" ", btnW, fs*2) then
                    CloseAfterSpawning = not CloseAfterSpawning
                    SetBool("savegame.mod.SpawnMenu.CloseAfterSpawning", CloseAfterSpawning)
                end

                UiTranslate(0, fs)

                UiPush() -- Text
                    UiAlign("left middle")
                    UiTranslate(10)
                    UiText("Close After Spawning")
                UiPop()

                UiAlign("right middle")
                UiTranslate(btnW - 10)

                if CloseAfterSpawning then
                    UiColor(0,1,0, 1)
                    UiImageBox("MOD/assets/img/icon_checkmark.png", fs*2, fs*2) -- Checkbox image
                else
                    UiColor(1,0,0, 1)
                    UiImageBox("MOD/assets/img/icon_cross.png", fs*2, fs*2)
                end

            UiPop()

        UiPop()

        -- Nav and favorites panel
        UiPush()
            UiTranslate(UiCenter())

            UiPush()
                local btnW = fs * 10
                local keys = GetTableKeys(loots)
                table.sort(keys)

                local category_keys = GetTableKeys(CategoryTitles)
                table.sort(category_keys)


                UiAlign("left top")
                local listItems = 0
                for index, categoryParent in ipairs(category_keys) do

                    local keysCount = GetTableSize(CategoryTitles[categoryParent])
                    UiColor(0,0,0, 0.3)
                    UiRect(btnW, (keysCount + 1) * sp)

                    uiSetFont(sp)
                    UiText(categoryParent) -- Cateogry title
                    UiTranslate(0, sp)

                    for _, category in ipairs(CategoryTitles[categoryParent]) do
                        UiPush()

                            local catKey   = category[1] -- key used to access spawn table category.
                            local catTitle = category[2] -- display title string.

                            if catKey == Selected_Cat and not FavoritesSelected then
                                UiColor(1,1,1, 1)
                                UiButtonImageBox('ui/common/box-solid-6.png', 6, 6, color_cat())

                                if Selected_Cat_Header == nil then
                                    Selected_Cat_Header = categoryParent .. " - " .. catTitle
                                end
                            else
                                UiColor(0,0,0,0.7)
                                UiImageBox("ui/common/box-solid-6.png", btnW, sp, 6, 6)
                                UiColor(1,1,1,1)
                                UiButtonImageBox('ui/common/box-outline-6.png', 6,6, 0, 0, 0, 1)
                            end

                            if UiTextButton(" ", btnW, sp) then -- Select loot category to display
                                Selected_Cat = catKey
                                Selected_Cat_Header = categoryParent .. " - " .. catTitle
                                FavoritesSelected = false
                                require_filter()
                                break
                            end

                            UiPush()
                                UiTranslate(sp * 0.15, sp * 0.15)
                                if catKey == Selected_Cat and not FavoritesSelected then
                                    UiImageBox("MOD/assets/img/icon_arrow_right.png", sp * 0.7, sp * 0.7)
                                end
                            UiPop()

                            UiTranslate(sp, 0)
                            UiText(catTitle)


                            listItems = listItems + 1

                        UiPop()
                        UiTranslate(0, sp)
                    end

                    listItems = listItems + 2
                    UiTranslate(0, sp)

                end

                UiTranslate(0, sp)
                if FavoritesSelected then
                    UiButtonImageBox('ui/common/box-solid-6.png', 6, 6, color_fav())
                else
                    UiButtonImageBox('ui/common/box-solid-6.png', 6, 6, 0,0,0,0.7)
                end
                UiColor(1,1,1,1)
                if UiTextButton("Favorites", btnW, sp) then -- Toggle favorites list to display
                    FavoritesSelected = not FavoritesSelected
                    SearchString = ""
                    require_filter()
                end

                UiColor(0,0,0,0.7)
                UiImageBox("ui/common/box-outline-6.png", btnW, sp, 6, 6)

                UiColor(color_fav())
                UiTranslate(4, 2)
                UiImageBox(SpawnMenuIcons.favorite_solid, sp-4, sp-4, 0, 0)
                listItems = listItems + 2
            UiPop()

            IsMouseOnAnyPanel = IsMouseOnAnyPanel or UiIsMouseInRect(btnW, sp * listItems)
        UiPop()


        -- Search panel
        UiTranslate(0, height * 0.9)
        UiPush()

            UiColor(0,0,0, a_list)
            UiRect(width, fs * 3)
            UiColor(1,1,1, 1)

            IsMouseOnAnyPanel = IsMouseOnAnyPanel or UiIsMouseInRect(width, fs * 3)

            UiTranslate(0, fs * 1.5)
            uiSetFont(fs * 2)
            UiAlign("left middle")
            UiText("Search:")
            UiTranslate(150, 0)

            local clearBtnW = 120
            local searchbarW = width - 150 - clearBtnW

            -- Search bar background.
            UiPush()
                UiTranslate(-pad/2, 0)
                UiColor(1,1,1, 0.1)
                UiRect(searchbarW, fs * 2)
            UiPop()

            local searchStringLast = SearchString

            -- Search bar input field.
            local inputString = UiStringInput(SearchString, searchbarW, fs, true)


            -- Search bar clear text button.
            UiTranslate(searchbarW - pad/4, 0)
            UiButtonImageBox('ui/common/box-solid-6.png', 6,6, 1, 0.5, 0.1, 1)
            if UiTextButton("Clear", clearBtnW, fs*2) then
                SearchString = ""
                SearchResults = {}
                SearchResultsCount = 0
                return
            end

            if pressed_open() then
                return -- Prevents keybind and input conflict.
            end

            if InputPressed("backspace") then

                local len = string.len(SearchString)
                if len >= 1 then
                    SearchString = string.sub(SearchString, 1, len-1)
                    SearchResults = GetSortedLootItems(inputString)
                    -- PrintTable(SearchResults)
                else
                    SearchString = ""
                    SearchResults = {}
                end

            elseif inputString ~= SearchString then

                SearchString = inputString
                SearchResults = GetSortedLootItems(inputString)

            end

            if searchStringLast ~= SearchString then
                FavoritesSelected = false
                require_filter()
            end

            -- DebugWatch("SearchString", SearchString)
            -- DebugWatch("inputString", inputString)
            -- DebugWatch("SearchResultsCount", SearchResultsCount)
            -- DebugWatch("IsMouseOnAnyPanel", IsMouseOnAnyPanel)
            -- DebugWatch("CloseAfterSpawning", CloseAfterSpawning)
            -- DebugWatch("shouldClose", shouldClose)
            -- DebugWatch("Show_Spawn_Menu", Show_Spawn_Menu)

        UiPop()

    UiPop()

    if shouldClose or (InputPressed("lmb") and not IsMouseOnAnyPanel) then
        Show_Spawn_Menu = false
    end

end

function GetSortedLootItems(searchString)

    SearchResultsCount = 0

    local matches = {}

    for catKey, cat in pairs(spawnables.loots) do

        for rarity, items in pairs(cat) do

            for index, item in ipairs(items) do

                if type(item[1]) == "string" then

                    if string_contains(string.lower(item[3] or item[1]), searchString) then
                        if matches[rarity] == nil then
                            matches[rarity] = {}
                        end
                        TableInsertUnique(matches[rarity], item)
                        SearchResultsCount = SearchResultsCount + 1
                    end

                end

            end

        end

    end

    return matches

end

function UiStringInput(currentString, width, height, focus)

    if focus then
        for index, key in ipairs({ ' ', '.', ',', '-' }) do -- Check extra chars.
            if InputPressed(key) then
                currentString = currentString .. key
                break
            end
        end
    end

    return UiTextInput(currentString, width, height, focus) -- Run through original func.

end



--- Make the filter run for a single tick.
function require_filter() ShouldFilter = true end

--- Checks if a loot item is stored as a favorite in the registry.
function is_favorite(xml) return GetBool(FavoritesPath .. xml) end

--- Checks if any favorites are set to true.
function has_favorites()
    for index, value in ipairs(ListKeys(FavoritesPathNoDot)) do
        if GetBool(FavoritesPath .. value .. ".xml") then
            return true
        end
    end
end

--- Adds a favorite to the registry
---@param filePath string Complete filepath to the loot item starting at MOD/
function spawnmenu_toggle_favorite(filePath) SetBool(FavoritesPath .. filePath, not GetBool(FavoritesPath .. filePath)) end

--- Removes a favorite from the registry
---@param filePath string Complete filepath to the loot item starting at MOD/
function spawnmenu_remove_favorite(filePath) SetBool(FavoritesPath .. filePath, false) end

--- Searches through all prefabs for favorites. (not super efficient but it works and a more complex solution will require lots of time)
function GetAllFavorites()

    local matches = {}

    for catKey, cat in pairs(spawnables.loots) do

        for rarity, items in pairs(cat) do

            if not matches[rarity] then matches[rarity] = {} end

            for index, item in ipairs(items) do

                if type(item[1]) == "string" then

                    local xml = LootsFilePath .. item[1]

                    if is_favorite(xml) then
                        TableInsertUnique(matches[rarity], item)
                    end

                end

            end

        end

    end

    return matches

end



function spawnmenu_display_lootItem(item)

end

function spawnmenu_display_invItem(item)

end


-- Reset SpawnMenuAPI for next tick. Called at the end of Draw().
function reset_spawnmenu_api()
    SetBool(SpawnMenuAPI.bool.open, false)
end


function client.handleCommand(cmd) HandleQuickload(cmd) end
function HandleQuickload(cmd)
	for _, word in ipairs(splitString(cmd, " ")) do
		if word == "quickload" then
            init()
            Init_Settings()
        end
		break
	end
end

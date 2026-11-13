-- (v2) main menu UI (client); library: entry script main_menu.lua, also included by ingame_settings.lua
--[[
#include "../../../Automatic.lua"
#include "../../../Config.lua"
#include "../../../menu_update_log_data.lua"
#include "../../../Settings.lua"
#include "../../../scripts/TDSU/tdsu.lua"
#include "../../FramePlayer/FramePlayer.lua"
#include "../../savegamePatchHandler.lua"
#include "menu_settings.lua"
#include "menu_update_log.lua"
#include "../../perkTable.lua"
#include "menu_host.lua"
]]


function Init_Main_Menu()

	Menu_Initialized = false


	sndnext = LoadSound("MOD/snd/UI/UI_Select.ogg")
	sndback = LoadSound("MOD/snd/UI/UI_Select_Light.ogg")
	sndscroll = LoadSound("MOD/snd/UI/UI_SliderTick.ogg")
	snderror = LoadSound("error.ogg")

	ChristmasMode = GetBool("level.modconfig.christmas")
	Music_Path = ternary(ChristmasMode,
		"MOD/snd/Music/Menus/Music_Underscore_Christmas_Deffcolony.ogg",
		"MOD/snd/Music/Menus/Music_Underscore_Main_Deffcolony.ogg")


	Grey = 0.65
	Grey_Light = 0.75
	Grey_Dark = 0.4
	Button_Icons = {
		continue  = "MOD/img/icon_continue.png",
		start     = "MOD/img/icon_start.png",
		tutorial  = "MOD/img/icon_tutorial.png",
		options   = "MOD/img/icon_options.png",
		credits   = "MOD/img/icon_credits.png",
		exit      = "MOD/img/icon_exit.png",
		try_again = "MOD/img/icon_try_again.png",
		update 	  = "MOD/img/icon_update.png",
	}

	LogoPath = ternary(ChristmasMode, "MOD/img/logo.png", "MOD/img/logo_normal.png")

	CreditList = {

		"Developers", {
			"SnakeyWakey",
			"Depravity",
			"Tesseractahedron",
			"Cheejins",
			"Please Pick a Name",
			"Waffle",
			"Laz",
			"Deffcolony",
			"avertnus",
			"Jacob Mario",
			"Kooshing",
			"Autumnatic",
		},

		"Borrowed assets and scripts:", {
			"Elboydo",
			"OpaBlyat1",
			"Artzert",
			"The Mafia",
			"Micro",
			"Morvex",
			"Dounut",
			"Regvin",
		},

		"Major thanks to our supporters:", {
			"Jay.",
			"SoymilkPapi",
			"Kvaler",
			"Zar",
			"Mirusa",
		},

		"Special thanks to:", {
			"ONSVRG",
		},
	}

	local W = UiWidth()
	local H = UiHeight()
	local W_half = UiWidth() / 2
	local H_half = UiHeight() / 2

	SetBool('savegame.mod.warnNewKey.done',true) -- Stop showing old keybind message

	Menu_Items = {

		options = MakeUiDimensions("options",
			W * 0.25, H * 0.25,
			W * 0.5, H * 0.5 + 200
		),

		tutorial = MakeUiDimensions("tutorial",
			W_half / 2, H_half / 2,
			W_half, H_half
		),

		askIfTutorial = MakeUiDimensions("askIfTutorial",
			700 / 2, 500 / 2,
			700, 500
		),

		warnNewKey = MakeUiDimensions("warnNewKey",
			700 / 2, 500 / 2,
			700, 500
		),

		groovybaby = MakeUiDimensions("groovybaby",
			W_half, H_half,
			W, H
		),

		update_log = MakeUiDimensions("update_log",
			0,0,
			0,0
		)

	}
	Selected_Menu_Item = nil

	Options_Items = {
		game        = { key = "game", value = "Game" },
		performance = { key = "performance", value = "Performance" },
		keybinds    = { key = "keybinds", value = "Keybinds" },
	}
	Selected_Options_Item = Options_Items.performance


	Menu_Initialized = true

end

function MainMenu_Init() -- (v2) called by main_menu.lua client.init

	init_config()
	Init_Settings()
	init_update_log()

	TICK = 1

	savegamePatchHandler()

	Frames = LoadFrames("MOD/scripts/FramePlayer/frames/", 125)
	Frame_Player = CreatePlayer(0.035, "MOD/snd/Music/Menus/Easteregg/MUS_Easteregg_FramePlayer.ogg")

	Title_osc_1 = 1
	Title_osc_2 = 1

	morbEaster = math.random() <= .05


	if config.game.try_again.deaths >= config.game.try_again.menu_count then -- More deaths than menu loads.
		config.game.try_again.show = true
	else
		config.game.try_again.show = false
	end

	config.game.try_again.menu_count = config.game.try_again.menu_count + 1

	creditTime = 0
	creditDY = -1 * 100 -- pixel/second

end

function MainMenu_Tick() -- (v2) called by main_menu.lua client.tick

	if not Menu_Initialized then
		return
	end

	if not GetBool("level.cat") then
		PlayMusic(Music_Path)
	else
		StopMusic()
	end

	-- force continue
	if (InputDown('c') and InputDown('t') and InputDown('n')) then
		SetBool("savegame.mod.continue",true)
	end

	--[[ if InputPressed("mmb") then
		print("killcam", Settings.game.killcam.value)
		print("foliage_percentage", Settings.performance.visual.foliage_percentage.value)
		print("draw_loot_outlines", Settings_Table.game.draw_loot_outlines.value)

		beep()
	end ]]

	SetBool("game.disablepause", true)
	SetBool("hud.disable", true)


	TICK = TICK + 1
end

function MainMenu_Draw(dt) -- (v2) called by main_menu.lua client.draw

	if not Menu_Initialized then
		Init_Main_Menu()
		return
	end

	CheejinsShortcuts()

	if GetBool('savegame.mod.refuseToMorb') then
		if Selected_Menu_Item == nil then
			Select_Menu_Item(Menu_Items.groovybaby)
		end
	elseif not GetBool('savegame.mod.warnNewKey.done') then
		if Selected_Menu_Item == nil then
			Select_Menu_Item(Menu_Items.warnNewKey)
		end
	end

	if InputPressed("pause") and not creditScene then
		Menu()
	end

	UiColor(0, 0, 0, 1)
	UiFont("bold.ttf", 24)
	UiMakeInteractive()

	local mouseX, mouseY = UiGetMousePos()
	SetFloat('level.UI.mouseX', mouseX)
	SetFloat('level.UI.mouseY', mouseY)

	if GetBool('level.UI.menu_select_difficulty') then
		return
	end

	if creditScene then
		if InputPressed("any") then
			creditScene = false
			creditTime = 1
		end
		creditTime = creditTime + dt
	else
		creditTime = math.max(creditTime - dt, 0)
	end

	if creditTime > 0 then
		UiPush()
		creditDY = creditDY + dt * 100 -- pixel/second
		UiColorFilter(1, 1, 1, AutoClamp(creditTime, 0, 1))
		UiColor(0, 0, 0, .6)
		UiImageBox("ui/common/box-solid-6.png", UiWidth(), UiHeight(), 6, 6)
		UiTranslate(UiCenter(), UiHeight() - creditDY)
		UiAlign('center top')
		UiColor(1, 1, 1, 1)
		CreditList_Display(CreditList, 60)
		UiPop()
	else
		creditDY = -1 * 100 -- pixel/second
		SetBool("level.cat", false)
		draw_menu()
	end

end




-- Container that holds the whole menu.
function draw_menu(containers_only)

	--todo Add all of this to a global table.
	local pad = 0
	local margin_left = pad
	local font_size = 30

	local title_container_margin = 100
	local title_size = 100
	local title_width = 500
	local title_height = 700

	local btn_width = title_width * 2 / 3
	local btn_height = font_size * 2


	--> Update log
	if not Selected_Menu_Item then
		draw_update_log(btn_width, btn_height, font_size)
	end


	--> Try agian button
	if Selected_Menu_Item == nil and config.game.try_again.show then
		UiPush()
			draw_try_again(btn_width, btn_height)
		UiPop()
	else
		SetBool("savegame.mod.hardcore_died", false)
		SetBool("savegame.mod.hardcore_died_menu", false)
	end


	--> Container
	do UiPush()

		UiTranslate(title_container_margin + title_width / 2, title_container_margin / 2)
		UiAlign("center top")
		UiColor(0.9, 0.9, 0.9, 1)


		-- Title
		UiPush()
			UiAlign("center top")
			UiColor(1, 1, 1, 1)
			local w, h = UiGetImageSize(LogoPath)
			UiScale((title_width + 100) / w)
			UiImage(LogoPath)
			UiImage(LogoPath)
		UiPop()
		UiTranslate(0, title_size * 3)

		local a = 0.9


		if not Selected_Menu_Item then

			UiFont("bold.ttf", font_size)
			UiColor(1, 1, 1, 1)
			UiButtonImageBox("ui/common/box-solid-6.png", 6,6, Grey_Dark,Grey_Dark,Grey_Dark, 3/4)


			-- Button List
			UiPush()
			if GetBool("savegame.mod.continue") and MenuIsHost() then -- (v2) only the host starts the game
				if UiTextButton(string.upper('Continue'), btn_width, btn_height) then
					playLastChar()
				end
			else
				UiColor(1, 1, 1, 0.5)
				UiTextButton(string.upper('Continue'), btn_width, btn_height)
			end
			UiPop()
			DrawCenterImage(-btn_width / 2, 0, btn_height, btn_height, Button_Icons.continue)
			UiTranslate(0, font_size * 3)


			if MenuHostButton(string.upper('New Save'), btn_width, btn_height) then -- (v2) only the host starts the game
				PlaySound(sndnext)
				if GetBool('savegame.mod.tutorial.states.hasFinishedTutorialLevel') or
					GetBool('savegame.mod.tutorial.states.hasSkippedTutorialLevel') then
					SetBool("inventory.givestarterweapons", true)

					SetBool('level.UI.menu_select_difficulty', true)
				else
					Select_Menu_Item(Menu_Items.askIfTutorial)
				end
			end
			DrawCenterImage(-btn_width / 2, 0, btn_height, btn_height, Button_Icons.start)
			UiTranslate(0, font_size * 3)


			if MenuHostButton(string.upper('Tutorial'), btn_width, btn_height) then -- (v2) only the host starts the game
				PlaySound(sndnext)
				-- Select_Menu_Item(Menu_Items.tutorial)
				MenuStartLevel("morslonga_tutorial", "MOD/level_tutorial.xml", "")
			end
			DrawCenterImage(-btn_width / 2, 0, btn_height, btn_height, Button_Icons.tutorial)
			UiTranslate(0, font_size * 3)


			if UiTextButton(string.upper('Options'), btn_width, btn_height) then
				PlaySound(sndnext)
				Select_Menu_Item(Menu_Items.options)
			end
			DrawCenterImage(-btn_width / 2, 0, btn_height, btn_height, Button_Icons.options)
			UiTranslate(0, font_size * 3)


			if morbEaster then
				if UiTextButton(string.upper(':3'), btn_width, btn_height) then
					PlaySound(sndnext)
					Select_Menu_Item(Menu_Items.groovybaby)
				end
				-- DrawCenterImage(-btn_width/2, 0, btn_height, btn_height, "")
				UiTranslate(0, font_size*3)
			end


			if UiTextButton(string.upper('Credits'), btn_width, btn_height) then
				PlaySound(sndnext)
				--SetBool('savegame.mod.tutorial.states.hasSkippedTutorialLevel', false)
				--SetBool('savegame.mod.tutorial.states.hasFinishedTutorialLevel',false)
				--SetBool('savegame.mod.warnNewKey.done',false)
				creditScene = true
			end
			DrawCenterImage(-btn_width / 2, 0, btn_height, btn_height, Button_Icons.credits)
			UiTranslate(0, font_size * 3)


			if UiTextButton(string.upper('Exit Mod'), btn_width, btn_height) then
				PlaySound(sndback)
				Menu()
			end
			DrawCenterImage(-btn_width / 2, 0, btn_height, btn_height, Button_Icons.exit)
			UiTranslate(0, font_size * 3)

			if not MenuIsHost() then -- (v2)
				UiText("THE HOST STARTS THE GAME")
			end

		end

		UiPop()
	end

	-- Center container
	UiPush()

	if Selected_Menu_Item ~= nil then

		UiAlign("left top")
		UiFont("regular.ttf", 32)
		UiColor(0.9, 0.9, 0.9, 1)

		-- Ui for selected item.
		draw_center_container()

	end

	UiPop()

end

--- Center containers for selected menu items.
function draw_center_container()

	UiTranslate(UiCenter(), UiMiddle())
	UiTranslate(-Selected_Menu_Item.x, -Selected_Menu_Item.y)

	_G["draw_menu_item_" .. Selected_Menu_Item.key](
		Selected_Menu_Item.w,
		Selected_Menu_Item.h)

end

function Select_Menu_Item(menu_item)
	Selected_Menu_Item = ternary(
		Selected_Menu_Item == menu_item,
		nil,
		menu_item)
end



--- Draw custom options
---@return boolean close Pressed close button.
function draw_menu_item_options(w, h)

	-- UiTranslate(-w/4, 0)
	UiFont("regular.ttf", 24)

	-- Background
	UiColor(.3, .3, .3, 3 / 4)
	UiImageBox("ui/common/box-solid-6.png", w, h, 6, 6)
	local margin_y = 0


	-- Back button
	do
		UiPush()
			UiTranslate(w/2, h)
			UiAlign("center bottom")
			UiColor(1, 1, 1, 1)
			UiButtonImageBox("ui/common/box-solid-6.png", 6,6, Grey_Dark,Grey_Dark,Grey_Dark, 3/4)
			if UiTextButton("CLOSE", 100, 40) then
				PlaySound(sndback)
				Select_Menu_Item(nil)
				return true -- Pressed close
			end
		UiPop()
		margin_y = margin_y + 40
	end

	--Reset button
	do
		UiPush()
			UiTranslate(w, h)
			UiAlign("right bottom")
			UiColor(1, 1, 1, 1)
			UiButtonImageBox("ui/common/box-solid-6.png", 6,6, 0.8,0.2,0.2, 3/4)
			if UiTextButton("RESET SECTION", 200, 40) then
				if Selected_Options_Item.key then
					ClearKey("savegame.mod.settings." .. Selected_Options_Item.key)
				end
				beep()
			end
		UiPop()
		margin_y = margin_y + 40
	end


	-- Title
	do
		UiColor(1, 1, 1, 1)
		UiPush()
		UiFont("bold.ttf", 30)
		UiTranslate(20, 20)
		UiText("OPTIONS")
		UiPop()
		UiTranslate(0, 40 + 20)
		margin_y = margin_y + 60
	end


	-- Nav bar
	do
		local buttons_count = GetTableSize(Options_Items)
		local button_w = w / buttons_count - buttons_count * 2
		UiPush()
		for key, value in pairs(Options_Items) do

			UiPush()

			if value == Selected_Options_Item then
				UiButtonImageBox("ui/common/box-solid-6.png", 6,6, Grey,Grey,Grey, 3/4)
			else
				UiButtonImageBox("ui/common/box-solid-6.png", 6,6, Grey_Dark,Grey_Dark,Grey_Dark, 3/4)
			end

			if UiTextButton(string.upper(value.value), button_w, 60) then
				Selected_Options_Item = value
				PlaySound(sndnext)
			end
			UiPop()

			UiTranslate(button_w + 9, 0)

		end
		UiPop()
		UiTranslate(0, 40)
		margin_y = margin_y + 40
	end

	UiTranslate(0, 20)

	-- Options buttons and sliders.
	local list_margin_y = 20
	local list_item_height = 50
	UiAlign("top left")
	UiPush()

		local settingsToSkip = 0
		local settingsToDraw = 0
		UiWindow(w, h - margin_y - 30, true)
		UiPush()
			UiColor(0, 0, 0, .2)
			local w = UiWidth()
			local h = UiHeight()
			UiImageBox("ui/common/box-solid-6.png", UiWidth(), UiHeight(), 6, 6)

			local totH = 20

			for _, tb_key_path in ipairs(Valid_Keys) do
				if tb_key_path[1] == Selected_Options_Item.key then
					totH = totH + 80
				end
			end
			local extraH = totH - h

			dy = AutoDefault(dy, 0)
			if UiIsMouseInRect(w, h) then
				local rawScroll = InputValue('mousewheel')
				dy = dy - math.abs(rawScroll) * rawScroll * 60
				if math.abs(rawScroll) > 0 then PlaySound(sndscroll) end
			end
			dy = AutoClamp(dy, 0, math.max(extraH,0))

			if extraH > 0 then
				UiColor(1, 1, 1, 1)
				UiTranslate(w)
				UiAlign("right top")
				local screen = AutoMap(dy, 0, extraH, 0, h - 16)
				screen, released = UiSlider('ui/common/dot.png', "y", screen, 0, h - 16)
				dy = AutoMap(screen, 0, h - 16, 0, extraH)
				UiColor(0, 0, 0, .2)
				UiRect(16, h)
			end

			settingsToSkip = math.floor(dy/80)
			settingsToDraw = math.ceil((dy%80 + h - 20)/80)
		UiPop()
		UiTranslate(0, list_margin_y - dy)

		for _, tb_key_path in ipairs(Valid_Keys) do

			if tb_key_path[1] == Selected_Options_Item.key then
				if settingsToSkip > 0 then
					settingsToSkip = settingsToSkip - 1
					UiTranslate(0, 80)
				elseif settingsToDraw > 0 then
					settingsToDraw = settingsToDraw - 1
					local st_object = GetNestedTable(tb_key_path, Settings)

					local h = draw_setting(st_object, 0.5)

					-- if st_object.type == struct_table_types.keybind and KeybindDown(st_object) then
					-- 	DebugWatch("Keybind Down: " .. st_object.title, table.concat(st_object.values, ", "))
					-- end

					UiTranslate(0, h + 20)
				else
					break
				end

			end

		end

	UiPop()
end

function draw_menu_item_askIfTutorial(w, h)

	UiPush()

	UiFont("regular.ttf", 30)

	-- Background
	UiColor(.3, .3, .3, 3 / 4)
	UiImageBox("ui/common/box-solid-6.png", w, h, 6, 6)
	local margin_y = 0

	-- Back button
	UiPush()
	UiTranslate(0, h)
	UiAlign("bottom left")
	UiColor(1, 1, 1, 1)
	UiButtonImageBox("ui/common/box-solid-6.png", 6,6, Grey_Dark,Grey_Dark,Grey_Dark, 3/4)
	if UiTextButton("BACK", 100, 40) then
		PlaySound(sndback)
		Select_Menu_Item(nil)
	end
	UiPop()
	margin_y = margin_y + 40


	UiTranslate(0, 80)
	margin_y = margin_y + 80

	-- Title
	-- UiColor(1,1,1, 1)
	-- UiPush()
	--     UiFont("bold.ttf", 40)
	--     UiTranslate(w/2, 20)
	--     UiAlign("center top")
	--     UiText("You have not finished the tutorial.")
	-- UiPop()
	-- UiTranslate(0, 80)
	margin_y = margin_y + 80

	-- Title
	UiColor(1, 1, 1, 1)
	UiPush()
	UiFont("regular.ttf", 40)
	UiTranslate(w / 2, 20)
	UiAlign("center top")
	UiText("Play the tutorial?")
	UiPop()
	UiTranslate(0, 80)
	margin_y = margin_y + 80

	UiTranslate(0, 80)
	margin_y = margin_y + 80

	UiPush()
	local button_w = w * .85 / 2
	local button_pad = w * .05
	UiAlign("left top")
	UiButtonImageBox("ui/common/box-solid-6.png", 6,6, Grey_Light,Grey_Light,Grey_Light, 3/4)
	UiPush()
	UiTranslate(button_pad)
	if UiTextButton(string.upper("Yes"), button_w, 40) then
		PlaySound(sndnext)
		MenuStartLevel("morslonga_tutorial", "MOD/level_tutorial.xml", "")
	end
	UiTranslate(button_w + button_pad)
	UiButtonImageBox("ui/common/box-solid-6.png", 6,6, Grey_Dark,Grey_Dark,Grey_Dark, 3/4)
	if UiTextButton(string.upper("No"), button_w, 40) then
		PlaySound(sndnext)
		SetBool('level.UI.menu_select_difficulty', true)
		SetBool("savegame.mod.inventory.init", true)
		Select_Menu_Item(nil)
	end
	UiPop()
	UiPush()
	UiTranslate(button_pad, 60)
	UiFont("bold.ttf", 24)
	UiButtonImageBox("ui/common/box-solid-6.png", 6,6, .8, .2, .2, 3/4)
	if UiTextButton(string.upper("No, Never ask again."), w * .9, 40) then
		PlaySound(sndnext)
		SetBool('savegame.mod.tutorial.states.hasSkippedTutorialLevel', true)
		SetBool('level.UI.menu_select_difficulty', true)
		SetBool("savegame.mod.inventory.init", true)
		Select_Menu_Item(nil)
	end
	UiPop()
	UiPop()

	UiPop()
end

local _warnNewKey_Stage = 0
function draw_menu_item_warnNewKey(w, h)
	UiPush()

		UiFont("regular.ttf", 30)

		-- Background
		UiColor(.3, .3, .3, 3 / 4)
		UiImageBox("ui/common/box-solid-6.png", w, h, 6, 6)
		local margin_y = 0

		UiTranslate(0, 120)
		margin_y = margin_y + 120

		-- Title
		UiColor(1, 1, 1, 1)
		UiPush()
			UiTextOutline(0,0,0,1,.2)
			UiFont("bold.ttf", 30)
			UiTranslate(w / 2)
			UiAlign("center top")
			UiColor(.9,.1,.1,1)
			UiWordWrap(w*0.9)
			UiText("ATTENTION: KEYBINDS HAVE BEEN CHANGED",true)
			UiTranslate(0,30)
			UiText("INVENTORY NOW USES <TAB> AS DEFAULT KEY",true)
			UiText("THROWABLE NOW USES <G> AS DEFAULT KEY")
		UiPop()
		UiTranslate(0, 80)
		margin_y = margin_y + 80

		UiTranslate(0, 120)
		margin_y = margin_y + 120

		UiPush()
			local button_w = w * .9
			local button_pad = w * .05
			UiAlign("left top")
			UiButtonImageBox("ui/common/box-solid-6.png", 6,6, Grey_Light,Grey_Light,Grey_Light, 3/4)

			UiPush()
				UiFont("bold.ttf", 24)
				UiButtonImageBox("ui/common/box-solid-6.png", 6,6, Grey_Dark,Grey_Dark,Grey_Dark, 3/4)

				UiTranslate(button_pad)
				if _warnNewKey_Stage==0 then
					if UiTextButton("Acknowledge", button_w, 40) then
						PlaySound(snderror)
						_warnNewKey_Stage = _warnNewKey_Stage + 1
					end
				else
					if UiTextButton("I really read the warning.", button_w, 40) then
						PlaySound(sndnext)
						Select_Menu_Item(nil)
						SetBool('savegame.mod.warnNewKey.done',true)
					end
				end
				
				UiTranslate(0, 60)
				if UiTextButton("bring me to keybind options", button_w, 40) then
					PlaySound(sndnext)
					Select_Menu_Item(Menu_Items.options)
					Selected_Options_Item = Options_Items.keybinds
					SetBool('savegame.mod.warnNewKey.done',true)
				end
			UiPop()
		UiPop()

	UiPop()
end

function draw_menu_item_groovybaby(w, h)

	RGB_RATE = 60 / 112
	RGB_TIME = RGB_TIME or 0
	RGB_C = RGB_C or Vec(math.random() + 0.5, math.random() + 0.5, math.random() + 0.5)

	if RGB_TIME + RGB_RATE < GetTime() then
		RGB_C = Vec(math.random() + 0.5, math.random() + 0.5, math.random() + 0.5)
		RGB_TIME = GetTime()
	end

	-- UiTranslate(-600, -250)

	UiColor(RGB_C[1], RGB_C[2], RGB_C[3], 1)
	UiRect(UiWidth(), UiHeight())

	UiTranslate(400, 200)

	UiPush()
	UiColor(1, 1, 1, 1)
	UiAlign("left top")
	PlayFrames(Frames, Frame_Player, UiWidth() - 800, UiHeight() - 400)
	UiPop()

	UiTranslate(UiCenter() - 400, UiMiddle() + 20)

	UiAlign("center middle")
	UiColor(0, 1, 0, 1)
	UiButtonImageBox("ui/common/box-solid-6.png", 6,6, Grey_Dark,Grey_Dark,Grey_Dark, 3/4)
	if UiTextButton(string.upper('YES, I WILL KEEP MORBING'), 350, 30) then
		PlaySound(sndnext)
		morbEaster = false
		Select_Menu_Item(nil)
		ClearKey("savegame.mod.refuseToMorb")
	end

	UiColor(1, 0, 0, 1)
	UiTranslate(0, 50)
	if UiTextButton(string.upper('NO, I WILL STOP MORBING (WRONG ANSWER)'), 650, 30) then
		SetBool('savegame.mod.refuseToMorb',true)
		Menu()
	end

	SetBool("level.cat", true)

end


function draw_try_again(btn_width, btn_height)

	local level_path = ternary(
		Settings.performance.visual.no_shadow.value,
		"MOD/level_no_shadow.xml",
		"MOD/level.xml"
	)

	UiRotate(math.sin(TICK * 1.7) / 10)
	UiRotate(math.sin(TICK * 1.7) / 13)

	UiColor(1, 1, 1, 1)
	UiTranslate(UiCenter(), UiMiddle())
	UiAlign("center middle")

	local shake = 1 + (math.sin(RandomSpreadPercent25(TICK) * 1.8) / 500)

	UiFont("bold.ttf", btn_height * 0.6 * shake)
	UiButtonImageBox('MOD/img/ui_button.png', 6, 6, 0.6, 0, 0, 0.8)
	if MenuHostButton(string.upper('Try Again?'), btn_width, btn_height) then -- (v2) only the host starts the game

		SetString("savegame.mod.difficulty", "hardcore")
		SetInt("savegame.mod.player.money", 0)
		SetFloat("savegame.mod.newLevel.gamerule.lrarity", 1)
		SetBool("savegame.mod.newLevel.gamerule.drugs", true)
		SetBool("savegame.mod.newLevel.gamerule.god", false)
		SetBool("savegame.mod.newLevel.gamerule.infuel", false)
		SetBool("savegame.mod.newLevel.gamerule.keepinv", false)
		SetBool("savegame.mod.newLevel.gamerule.nhat", false)
		SetBool("savegame.mod.newLevel.gamerule.permadeath", true)
		SetBool("savegame.mod.newLevel.gamerule.armored", false)
		SetBool("inventory.givestarterweapons", true)
		SetBool("savegame.mod.inventory.init", true)
		SetBool("savegame.mod.bountyboard.cultist", false)
		SetBool("savegame.mod.bountyboard.military", false)
		SetBool("savegame.mod.bountyboard.insurgent", false)
		for i = 1, 4 do
			SetBool("savegame.mod.bountyboard." .. i, false)
		end

		for i=1,#PERKORDER do
			local perk=PERKORDER[i]
			if HasKey("savegame.mod.perks."..perk)then
				SetInt("savegame.mod.perks."..perk, 0)
			end
		end

		ClearKey("savegame.mod.parkingSpot")

		MenuStartLevel("morslonga_main", level_path, "hardcore nodev")
	end

	DrawCenterImage(-btn_width / 2, -btn_height / 2, btn_height * shake, btn_height * shake, Button_Icons.try_again, 1,1,1,1)

	return h
end




function MainMenu_HandleCommand(cmd) handle_quickload(cmd) end -- (v2) unused

function handle_quickload(cmd)
	for _, word in ipairs(splitString(cmd, " ")) do
		if word == "quickload" then Init_Settings() end
		break
	end
end

KEYS={
	"lmb","mmb","rmb",-- mouse
	"1","2","3","4","5","6","7","8","9","0",-- numerical
	"a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z",-- alphabatical
	"f1","f2","f3","f4","f5","f6","f7","f8","f9","f10","f11","f12",-- function key
	"uparrow","downarrow","leftarrow","rightarrow",-- arrow key
	"backspace","alt","delete","home","end","pgup","pgdown","insert","return","space","shift","ctrl","tab","esc",--random key
	",",".","-","+",-- undocumented key (yes, '=' key is '+' key)
}
function GetInputPressed()
	local key = ""
	if InputDown("any") then
		for i = 1, #KEYS do
			if InputDown(KEYS[i]) then
				key = KEYS[i]
				break
			end
		end
	end
	return key
end

function CreditList_Display(list, fontSize)
	for i, val in ipairs(list) do
		UiFont("bold.ttf", fontSize)
		if type(val) == "table" then
			UiTranslate(0, 30)
			CreditList_Display(val, fontSize * 0.6)
			UiTranslate(0, 50)
		else
			UiText(val, true)
		end
		UiTranslate(0, 5)
	end
end

function playLastChar()
	local level_path = ternary(
		Settings.performance.visual.no_shadow.value,
		"MOD/level_no_shadow.xml",
		"MOD/level.xml"
	)
	--for i=1,4 do
	--	SetBool("savegame.mod.bountyboard."..i, false)
	--end
	--SetBool("savegame.mod.bountyboard.cultist", false)
	--SetBool("savegame.mod.bountyboard.military", false)
	--SetBool("savegame.mod.bountyboard.insurgent", false)
	local diff = GetString("savegame.mod.difficulty")
	if diff=="peaceful"then
		SetFloat("savegame.mod.lastLevel.gamerule.lrarity", 2)
	elseif diff=="normal"then
		SetFloat("savegame.mod.lastLevel.gamerule.lrarity", 1.5)
	elseif diff=="hardcore"then
		SetFloat("savegame.mod.lastLevel.gamerule.lrarity", 1)
	end
	SetFloat("savegame.mod.newLevel.gamerule.lrarity", GetFloat("savegame.mod.lastLevel.gamerule.lrarity"))
	SetBool("savegame.mod.newLevel.gamerule.drugs", GetBool("savegame.mod.lastLevel.gamerule.drugs"))
	SetBool("savegame.mod.newLevel.gamerule.god", GetBool("savegame.mod.lastLevel.gamerule.god"))
	SetBool("savegame.mod.newLevel.gamerule.infuel", GetBool("savegame.mod.lastLevel.gamerule.infuel"))
	SetBool("savegame.mod.newLevel.gamerule.keepinv", GetBool("savegame.mod.lastLevel.gamerule.keepinv"))
	SetBool("savegame.mod.newLevel.gamerule.nhat", GetBool("savegame.mod.lastLevel.gamerule.nhat"))
	SetBool("savegame.mod.newLevel.gamerule.permadeath", GetBool("savegame.mod.lastLevel.gamerule.permadeath"))
	SetBool("savegame.mod.newLevel.gamerule.armored", GetBool("savegame.mod.lastLevel.gamerule.armored"))
	if diff == "custom" then
		diff = "normal"
	end
	MenuStartLevel("morslonga_main", level_path, diff .. " nodev")
end

function MakeUiDimensions(key, x, y, w, h)
	return {
		key = key,
		x = x,
		y = y,
		w = w,
		h = h,
	}
end

function DrawCenterImage(x,y, w,h, path, r,g,b,a)
	UiPush()
	UiColor(r or 1, g or 1, b or 1, a or 0.5)
	UiTranslate(w * 0.15, h * 0.15)
	UiAlign("left top")
	UiTranslate(x, y)
	UiImageBox(path, w * 0.7, h * 0.7, 0, 0)
	UiPop()
end

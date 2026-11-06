#version 2
#include "script/include/player.lua"
--[[
#include "../../Automatic.lua"
#include "../../scripts/TDSU/tdsu.lua"
]]

local function AutoButton(name, fontsize, bg_color, paddingwidth, paddingheight, draw, spreadpad)

	fontsize = AutoDefault(fontsize, 28)
	paddingwidth = AutoDefault(paddingwidth, AutoPad.thick)
	paddingheight = AutoDefault(paddingheight, AutoPad.thin)
	draw = AutoDefault(draw, true)
	spreadpad = AutoDefault(spreadpad, true)

	UiPush()
		UiWordWrap(UiWidth() - AutoPad.thick)
		UiFont(AutoFont, fontsize)
		UiButtonHoverColor(unpack(AutoSpecialColor))
		UiButtonPressColor(0.75, 0.75, 0.75, 1)
		UiButtonPressDist(0.25)

		UiColor(0, 0, 0, 0)
		local rw, rh = UiText(name)
		local padrw, padrh = rw + paddingwidth * 2, rh + paddingheight * 2

		if draw then
			hover = UiIsMouseInRect(padrw, padrh)
			UiColor(unpack(AutoPrimaryColor))

			UiButtonImageBox('ui/common/box-solid-6.png', 6, 6, unpack(bg_color or AutoPrimaryColor))
			pressed = UiTextButton(name, padrw, padrh)
		end
	UiPop()

	local data = { pressed = pressed, hover = hover, rect = { w = padrw, h = padrh } }
	if draw then HandleSpread(AutoGetSpread(), data, 'draw', spreadpad) end

	return pressed, data
end

-- (v2) client only: the Instructions book (pause menu button)
function client.init()
    --[[ ToolCatagory = 5
    RegisterTool('manual', 'Instructions', nil, ToolCatagory)
    SetBool('game.tool.manual.enabled', true) ]]

    -- This changes the color of all the text
    AutoPrimaryColor = { 0.1, 0.1, 0.1, 1 }

    Selected = true
    Animation = 0

    Page = 1
    Sway = Vec(0,0,0)
    Rotation = 0
    FallDirection = false

   -- _SelectionOnStart = true

end

function client.tick(dt)

    Walking = InputDown("up") or InputDown("down") or InputDown("left") or InputDown("right")

    if Walking then
        Selected = false
    end

    --if _SelectionOnStart then SetString('game.player.tool', 'manual') Selected = true _SelectionOnStart = false end

    if --[[ GetString('game.player.tool') == 'manual' and (not Selected) and InputPressed('usetool') ]] PauseMenuButton("Instructions") then
        Selected = not Selected
    end

    if Selected and GetPlayerVehicle() ~= 0 then SetString('game.player.tool', nil) end

    local veldir = TransformToLocalVec(GetCameraTransform(), GetPlayerVelocity())
	Sway = VecAdd(Sway, veldir)
	Sway = VecLerp(Sway, Vec(0,0,0), dt * 4)

    -- DebugWatch("Sway", Sway)

    Rotation = Rotation + dt
end

-- This can be used in combination with AutoTooltip() and Interact
function OpenToPage(page)
    SetString('game.player.tool', 'manual')
    Page = page
end

function bump()
    Rotation = 0
end

function client.draw(dt)

    if --[[ GetString('game.player.tool') == 'manual' ]] true then

        --[[ if not Selected and GetPlayerVehicle() == 0 then
            UiPush()
                UiFont("bold.ttf", 32)
                UiColor(1,1,1, 3/4)
                UiAlign("center middle")
                UiTextShadow(0,0,0,1, 1,1)
                UiTranslate(UiCenter(), UiMiddle() + 100)
                UiText("LEFT CLICK to open the instructions manual.")
            UiPop()
        end ]]

        Animation = Animation + dt * (Selected and 1 or -2) -- -1.5 is so that it goes away faster than it comes back. Adds just a bit more visual juice.
        Animation = AutoClamp(Animation, 0, Selected and math.huge or 1)

        if Animation > 0 then
            local amount = AutoLogistic(Animation, 0.125, -15, 0.3)
            SetCameraDof(0.75, amount)
        end

        if AutoRound(Animation, 0.01) > 0 then
            UiPush()
                UiAlign("center middle")
                UiTranslate(UiCenter(), UiMiddle())

                -- Juicy Bring Up Animation
                UiTranslate(AutoLogistic(Animation, UiWidth() * 2 * (FallDirection and -1 or 1), 10, 0.1), AutoLogistic(Animation, UiHeight() + 1280, 20, 0.2))
                UiScale(math.max(AutoLogistic(Animation, 1, -8, 0.4), 0.5), 1)
                UiRotate(-AutoLogistic(Animation, 360 * 3, 7.5, 0) * (FallDirection and -1 or 1))

                -- Diffrent Scaling Animations, Leave all Commented, or only one Uncommented.
                UiScale(math.max(AutoLogistic(Animation, 1, -10, 0.5), 0.55)) -- Bring up then Scale
                -- UiScale(math.min(AutoLogistic(Animation, 1, -10, 0.5) + 0.5, 1)) -- Smacks the Screen like a Super Smash Bros Character
                -- UiScale(AutoLogistic(Animation, 1 - 0.55, -10, 0.5) + 0.55) -- Smooth

                -- Sway and Juice
                local velmag = VecLength(Sway)
                local vellog = AutoLogistic(velmag, 1, -4, 8)

                local sway = VecScale(Sway, vellog)
                UiTranslate(sway[1], sway[2]) -- Move with Horizontal movement (relative to the camera)
                UiScale(1 + math.abs(sway[1] / 10000), 1 + math.abs(sway[2] / 4000)) -- Squash And Stretch
                UiScale(1 + (-sway[3] / 2000), 1 + (-sway[3] / 2000)) -- Scale with foward/backward

                RenderUI()

                if Animation > 0.35 and Selected then UiMakeInteractive() end
                if InputPressed('esc') then Selected = false Animation = 0 end
            UiPop()
        else
            FallDirection = math.random(0, 1) > 0.5
        end

    end

end

function RenderUI()
    UiPush()
        UiPush()
            UiRotate(-(AutoLogistic(Rotation, 1, -100, 0.025) * AutoLogistic(Rotation, 1, 50, 0.05)) * 2.5 * (FallDirection and 1 or -1))
            UiAlign('center middle')
            local maincontainer = AutoContainer(610, 800, AutoPad.thick, false, false)

            UiPush()
                UiTranslate(-AutoPad.thick, -AutoPad.thick)
                UiImage('MOD/img/UI/Manual/background.png')
            UiPop()

            UiPush()
                UiAlign('right bottom')
                UiTranslate(UiWidth(), UiHeight())
                AutoText("Page "..Page, 24)
            UiPop()

            UiPush()
                if PageContent[Page] ~= nil then PageContent[Page]() end
            UiPop()
        UiPop()

        -- Tabs
        UiPush()
            UiAlign('left top')
            UiTranslate((maincontainer.rect.w / 2) + AutoPad.thick + AutoPad.micro, -(maincontainer.rect.h / 2) - AutoPad.thick)

            local bg_color = { 0.75, 0.75, 0.75, 0.75}

            AutoSpreadDown(AutoPad.thin)
                local CloseBook = AutoButton("Close Book", 42, bg_color)
                UiTranslate(0, AutoPad.thick)
                local Tab1 = AutoButton("Cover Tab", 28, bg_color)
                local Tab2 = AutoButton("Refuel Tab", 28, bg_color)
                local Tab3 = AutoButton("Thirst and Hunger Tab", 28, bg_color)
                local Tab4 = AutoButton("Place Tool Tab", 28, bg_color)
                local Tab5 = AutoButton("Lore Tab", 28, bg_color)
                local Tab6 = AutoButton("Bounty Board", 28, bg_color)
                -- local Tab6 = AutoButton("Settings Tab", 28, bgc)
                -- local Tab7 = AutoButton("Weapon Keybinds", 28, bgc)
            AutoSpreadEnd()

            UiAlign('left bottom')
            UiTranslate(0, maincontainer.rect.h + AutoPad.thick * 2)
            AutoSpreadUp(AutoPad.thin)
                local NextPage = AutoButton("Next Page", 32, bg_color)
                local PrevPage = AutoButton("Previous Page", 32, bg_color)
            AutoSpreadEnd()
        UiPop()

        -- Tab Logic
        if CloseBook then Selected = false end
        if NextPage then Page = AutoClamp(Page + 1, 1, #PageContent) bump() end
        if PrevPage then Page = AutoClamp(Page - 1, 1, #PageContent) bump() end
        if Tab1 then Page = 1 bump() end -- Cover and Credits
        if Tab2 then Page = 2 bump() end -- Refuel
        if Tab3 then Page = 10 bump() end -- Thirst and Hunger
        if Tab4 then Page = 12 bump() end -- Place Tool
        if Tab6 then Page = 14 bump() end -- Bounty Coard
        if Tab5 then Page = 15 bump() end -- Lore
        -- if Tab7 then Page = 8 bump() end -- Keybinds
    UiPop()
end

-- Each function is a different page
PageContent = {
    function () -- Cover and Credits
        AutoSpreadDown(AutoPad.thick)
            AutoText("The Instruction Manual for Fleeing Alashya", 64)
            local s = AutoGetSpread()
            s.padding = AutoPad.micro
            AutoSetSpread(s)
            AutoText("Created By:", 22)
            AutoText("Snakey Wakey", 22)
            AutoText("Tesseractahedron", 22)
            AutoText("Depravity", 22)
            AutoText("Jacob Mario", 22)
            AutoText("Cheejins", 22)
            AutoText("Please Pick a Name", 22)
            AutoText("Deffcolony", 22)
            AutoText("Avertnus", 22)
            AutoText("Autumnatic", 22)
            AutoText("Some tabs in the manual have multiple pages.", 34)
            AutoText("It is recommended that you use 'Next Page' to progress through the manual.", 34)
        AutoSpreadEnd()
    end,
    function () -- Gascan
        AutoSpreadDown(AutoPad.thick)
            AutoText("To refuel a vehicle, place a gas can near the vehicle's base and hold the interact button. You will hear a sound when you are transferring fuel.")
            AutoImage('MOD/img/UI/Manual/refuelvehicle.png', UiWidth() / 2, nil, 0.75)
            AutoText("Refueling gas cans can be done the same way you refuel vehicles.")
            AutoImage('MOD/img/UI/Manual/refuel_gascan.png', UiWidth() / 2, nil, 0.75)
            AutoText("You can also transfer fuel into fuel barrels.")
        AutoSpreadEnd()
    end,
    function () -- Siphoning
        AutoSpreadDown(AutoPad.thick)
            AutoText("You can siphon gas from a vehicle into the nearest gas container by holding Q while driving.")
            AutoImage('MOD/img/UI/Manual/Siphon.png', UiWidth(), nil, 0.75)
        AutoSpreadEnd()
    end,
    function () -- Inventory
        AutoSpreadDown(AutoPad.thick)
            AutoText("To open your inventory, press the G key on your keyboard.")
            AutoImage('MOD/img/UI/Manual/press_g.png', UiWidth(), nil, 0.75)
        AutoSpreadEnd()
    end,
    function () -- Equipping a Weapon
        AutoSpreadDown(AutoPad.thick)
            AutoText("To equip a weapon, drag it to your weapon slot. It will become accessible in-game, and you can switch to it.")
            AutoImage('MOD/img/UI/Manual/equipping_a_weapon.png', UiWidth(), nil, 0.75)
        AutoSpreadEnd()
    end,
    function () -- Managing Magazines
        AutoSpreadDown(AutoPad.thick)
            AutoText("To load a magazine for a weapon, simply drag the corresponding ammunition to the magazine. Different magazine-fed weapons use different magazines. Check the accepted bullet type under the magazine and weapon to make sure it matches.")
            AutoImage('MOD/img/UI/Manual/Loading_a_mag.png', UiWidth() / 2, nil, 0.75)
            AutoText("To unload a magazine, simply right-click it and press unload. This will take out all the bullets from the magazine.")
            AutoImage('MOD/img/UI/Manual/NoMag.png', UiWidth() / 2, nil, 0.75)
        AutoSpreadEnd()
    end,
    function () -- Loading non-Magazine Weapons
        AutoSpreadDown(AutoPad.thick)
            AutoText("Some weapons, like the RPG, Mudafie, and Medvedev, do not require magazines. Simply having the ammunition in your inventory will let you reload them.")
            AutoImage('MOD/img/UI/Manual/NoMag.png', UiWidth(), nil, 0.75)
        AutoSpreadEnd()
    end,
    function () -- Keybinds
        AutoSpreadDown(AutoPad.thick)
            AutoText("LMB - Shoot")
            AutoText("RMB - Aim down sights")
            AutoText("R - Automatically load the magazine with the most ammunition in it")
            AutoText("R (hold) - Bring up a menu where you can select a specific magazine to load (release R after clicking a magazine)")
            AutoText("V - Change fire mode (tabs through semi, burst, full, safe, etc., depending on the weapon)")
            --[[ AutoText("Q & E - Lean the gun left or right (toggle)") ]]
            AutoText("B - Toggle any attachments such as lasers, flashlights, or rangefinders")
            AutoText("Y - Inspect weapon (press again or perform any other action to cancel)")
            AutoText("ALT - Will change aiming mode if holding right click (will toggle magnification on compatible scopes/magnifiers)")
            AutoText("C - Will switch to canted sight if equipped")
        AutoSpreadEnd()
    end,
    function () -- Equipping Armor
        AutoSpreadDown(AutoPad.thick)
            AutoText("To equip armor, simply drag it into the armor slot in your inventory.")
            AutoImage('MOD/img/UI/Manual/putting_on_armor.png', UiWidth(), nil, 0.75)
        AutoSpreadEnd()
    end,
    function () -- Hunger and Thirst
        AutoSpreadDown(AutoPad.thick)
            AutoText("Hunger and thirst are crucial for your survival. If these bars become empty, you will die very quickly.")
            AutoImage('MOD/img/UI/Manual/hunger_and_thirst_bars.png', UiWidth(), nil, 0.75)
        AutoSpreadEnd()
    end,
    function () -- Eating
        AutoSpreadDown(AutoPad.thick)
            AutoText("Right-clicking on food in your inventory will give you the prompt to eat it. Some foods also deplete the thirst bar.")
            AutoImage('MOD/img/UI/Manual/eating.png', UiWidth(), nil, 0.75)
        AutoSpreadEnd()
    end,
    function () -- Place Tool
        AutoSpreadDown(AutoPad.thick)
            AutoText("The Place tool is used to attach various structures, armor, and weaponry.")
            AutoText("Using the Place tool, it is possible to armor your vehicle or add fuel storage containers to it.")
            AutoImage('MOD/img/UI/Manual/placing.png', UiWidth(), nil, 0.75)
            AutoImage('MOD/img/UI/Manual/refuel_barrel.png', UiWidth() / 3, nil, 0.75)
        AutoSpreadEnd()
    end,
    function () -- Materials
        AutoSpreadDown(AutoPad.thick)
            AutoText("Placing structures requires materials. These are all the materials you can find in the world. Some structures require more materials than others.")
            AutoImage('MOD/img/UI/Manual/allmats.png', UiWidth(), nil, 0.75)
        AutoSpreadEnd()
    end,
    function () -- Bosses
        AutoSpreadDown(AutoPad.thick)
            AutoText("Bounty Board")
            AutoText("Here you can see all the enemies that you have killed.")
            AutoText("More enemy types will be added later. There will be a total of 8 bosses that are exceptionally difficult to kill.")

            local fs = 24

            AutoText(" ")
            AutoText("Factions")
            -- General faction killed
            display_bountyboard_item(GetInt("savegame.mod.bountyboard.Military"),  "Alashyan Armed Forces", fs)
            display_bountyboard_item(GetInt("savegame.mod.bountyboard.Insurgent"), "Insurgents", fs)
            display_bountyboard_item(GetInt("savegame.mod.bountyboard.Cultist"),   "Cultists", fs)
            display_bountyboard_item(GetInt("savegame.mod.bountyboard.UM"),        "United Mates", fs)

            AutoText(" ")
            AutoText("Bosses")
            -- Bosses killed
            display_bountyboard_item(GetInt("savegame.mod.bountyboard.BossInsurgentC"),  "Spes Pugnator (Insurgent)", fs)
            display_bountyboard_item(GetInt("savegame.mod.bountyboard.BossMilitaryC"),   "Vires Gerentis (AAF)", fs)
            display_bountyboard_item(GetInt("savegame.mod.bountyboard.BossCultistC"),    "Nox Daemonium  (Cultist)", fs)

            -- display_bountyboard_item(GetInt("savegame.mod.bountyboard.BossUnisC"),       "Unis (AAF)")
            -- AutoText("Unis (AAF)" .. "(N/A yet)", fs)
            -- display_bountyboard_item(GetInt("savegame.mod.bountyboard.BossDuoC"),        "Duo (AAF)")
            -- AutoText("Duo (AAF)" .. "(N/A yet)", fs)
            -- display_bountyboard_item(GetInt("savegame.mod.bountyboard.BossTriaC"),       "Tria (AAF)")
            -- AutoText("Tria (AAF)" .. "(N/A yet)", fs)
            -- display_bountyboard_item(GetInt("savegame.mod.bountyboard.BossQuattuorC"),   "Quattuor (AAF)")
            -- AutoText("Quattuor (AAF)" .. "(N/A yet)", fs)
            -- display_bountyboard_item(GetInt("savegame.mod.bountyboard.bingus"),          "Angelic creations")
            -- AutoText("Angelic creations" .. "(N/A yet)", fs)


        AutoSpreadEnd()
    end,
    function () -- Lore
        AutoSpreadDown(AutoPad.thick)
            AutoText("Lore", 48)
            AutoText("The country of Alashya, heavily influenced by America in the Middle East, has entered lockdown due to a deadly, paranoia-inducing virus.", 28)
            AutoText("Civilians are outraged and attempting to flee the country, but the UM government has shut down the inner cities and rural areas, making it almost impossible to leave.", 28)
            AutoText("Insurgents and anarchists have risen up. The population is frantic as everyone tries to escape Alashya. The UM forces have now been given the green light to eliminate anyone attempting to escape through the country's vast highways with lethal force.", 28)
        AutoSpreadEnd()
    end,
    --[[ function () -- Settings
        AutoSpreadDown(AutoPad.thick)
            AutoText("Change Settings Here :", 48)
            AutoText("Change Tool Catagory : "..ToolCatagory)
            local set, rel = AutoSlider(ToolCatagory, 1, 6, 1)
        AutoSpreadEnd()
        if rel then
            ToolCatagory = set
            RegisterTool('manual', 'Instructions', nil, ToolCatagory)
        end
    end, ]]
}


function display_bountyboard_item(savegame_int, title, font_size)
    UiTranslate(font_size * 2, 0)
    AutoText(title .. " killed: ".. savegame_int, font_size or 20)
    UiTranslate(-font_size * 2, 0)
end
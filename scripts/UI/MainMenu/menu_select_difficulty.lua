#version 2
#include "script/include/player.lua"
-- (v2) client: New Save -> difficulty / character select (host only); camera moves per client.
--[[
#include "../../../scripts/TDSU/tdsu.lua"
#include "../../../Settings.lua"
#include "../../perkTable.lua"
#include "menu_host.lua"
]]



function client.init()

	-- (v2) moved from load time (API calls are not allowed there)
	sndnext = LoadSound("MOD/snd/ui_button_next.ogg")
	sndback = LoadSound("MOD/snd/ui_button_back.ogg")

	Init_Settings()

	cam = FindBody("cam")
	-- (v2) camera path kept per client; v1 moved the static "cam" body itself (a world change, server-only)
	CamT = GetBodyTransform(cam)
	locations = FindLocations("camdest", true)
	lookAts = FindLocations("lookat", true)

	currentChar = 2

	FOVDiff = VecLength(VecSub(GetLocationTransform(locations[currentChar]).pos, GetLocationTransform(lookAts[currentChar]).pos))*4

	selectsounds={
		LoadSound("MOD/snd/Weapons/g17/g17_0.ogg"),
		LoadSound("MOD/snd/Weapons/ak/ak_0.ogg"),
		LoadSound("MOD/snd/Weapons/dragunov/dragunov_0.ogg"),
		LoadSound("MOD/snd/Explosions/frag_sand_0.ogg")
	}

	hints = true

	Drugs = false
	God = false
	infFuel = false
	KeepInv = false
	NHAT = false
	Permadeath = false
	Armored = false
	LRarity = "Common"
	Music = true

	hintFade=-2

	TICK = 1
end

function PlayCharSound()
	PlaySound(selectsounds[currentChar])
end

function client.tick()

	if not GetBool('level.UI.menu_select_difficulty')then
		return
	end
	if InputPressed("pause") then
		SetBool('level.UI.menu_select_difficulty',false)
	end

	local DistForFOV = VecLength(VecSub(GetLocationTransform(locations[currentChar]).pos, GetLocationTransform(lookAts[currentChar]).pos))*4
	FOVDiff = lerp(FOVDiff,DistForFOV,.1)
	SetCameraFov(90 - FOVDiff)
	SetCameraDof(DistForFOV/4)

	SetCameraTransform(CamT)

	if InputPressed("rightarrow") or InputPressed("right") then
		currentChar = currentChar + 1
		if currentChar > #locations then
			currentChar = 1
		end
		PlayCharSound()
		hints = false
	end
	if InputPressed("leftarrow") or InputPressed("left") then
		currentChar = currentChar - 1
		if currentChar < 1 then
			currentChar = #locations
		end
		PlayCharSound()
		hints = false
	end

	if currentChar < 1 then
		currentChar = #locations
	elseif currentChar < 1 then
		currentChar = #locations
	end

	nextCharecter()

	TICK = TICK + 1
end
function lerp(a,b,r)
	return a*(1-r)+b*r
end
function nextCharecter()
	local camTrans = CamT
	local locPos = GetLocationTransform(locations[currentChar]).pos
	local rot = QuatLookAt(camTrans.pos, GetLocationTransform(lookAts[currentChar]).pos)

	CamT = Transform(VecLerp(camTrans.pos,locPos,.1), rot)

	local distToDest = VecLength(VecSub(camTrans.pos, locPos))
	if distToDest < 0.05 and not plaied then
		PlayCharSound()
		plaied = true
	end
	--DebugWatch("debugging",GetTagValue(locations[currentChar],'camdest')..": "..currentChar)
end

DISPLAYTEXT={
	[true]="Active",
	[false]="Inactive",
}

DIFFCULTYTEXTS={
	{
		["name"]="Peaceful",
		["character"]="INSURGENT",
		["color"]={.7,1,.7},
		["desc"]="No enemies spawn. Enjoy exploring and learning in peace while others struggle.",
	},
	{
		["name"]="Normal",
		["character"]="DESERTER",
		["color"]={1,1,.7},
		["desc"]="Average loot/enemy spawn. For the average player.",
	},
	{
		["name"]="Hardcore",
		["character"]="SURVIVOR",
		["color"]={1,.7,.7},
		["desc"]="High risk low reward. For those who wish to torture themselves.",
	},
	{
		["name"]="Horde",
		["character"]="Gladiator",
		["color"]={0.5,0,0},
		["desc"]="Test your skills in this arcadey style ",
	},
	{
		["name"]="Make a wish",
		["character"]="CUSTOM",
		["color"]={1,1,1},
		["desc"]="Customize your own experience.",
	},
}
function playCharacter(char)
	if not MenuIsHost() then return end -- (v2) only the host starts the game
	SetBool("savegame.mod.continue",true)
	SetBool("savegame.mod.inventory.init", true)

	for i=1,4 do
		SetBool("savegame.mod.bountyboard."..i, false)
	end
	SetBool("savegame.mod.bountyboard.cultist", false)
	SetBool("savegame.mod.bountyboard.military", false)
	SetBool("savegame.mod.bountyboard.insurgent", false)
	SetFloat("savegame.mod.distanceProgressed", 0)
	SetFloat("savegame.mod.LastSpawnedWarehouseDist", 0)
	local level_path = ternary(
		Settings.performance.visual.no_shadow.value,
		"MOD/level_no_shadow.xml",
		"MOD/level.xml"
	)

	for i=1,#PERKORDER do
		local perk=PERKORDER[i]
		if HasKey("savegame.mod.perks."..perk)then
			SetInt("savegame.mod.perks."..perk, 0)
		end
	end

	ClearKey("savegame.mod.parkingSpot")

	if char == 1 then
		SetString("savegame.mod.difficulty", "peaceful")

		SetFloat("savegame.mod.newLevel.gamerule.lrarity", 2)
		SetBool("savegame.mod.newLevel.gamerule.drugs", false)
		SetBool("savegame.mod.newLevel.gamerule.god", true)
		SetBool("savegame.mod.newLevel.gamerule.infuel", true)
		SetBool("savegame.mod.newLevel.gamerule.keepinv", true)
		SetBool("savegame.mod.newLevel.gamerule.nhat", true)
		SetBool("savegame.mod.newLevel.gamerule.permadeath", false)
		SetBool("savegame.mod.newLevel.gamerule.armored", true)

		MenuStartLevel("morslonga_main", level_path,"peaceful nodev")
	elseif char == 2 then
		SetString("savegame.mod.difficulty", "normal")

		SetFloat("savegame.mod.newLevel.gamerule.lrarity", 1.5)
		SetBool("savegame.mod.newLevel.gamerule.drugs", false)
		SetBool("savegame.mod.newLevel.gamerule.god", false)
		SetBool("savegame.mod.newLevel.gamerule.infuel", false)
		SetBool("savegame.mod.newLevel.gamerule.keepinv", false)
		SetBool("savegame.mod.newLevel.gamerule.nhat", false)
		SetBool("savegame.mod.newLevel.gamerule.permadeath", false)
		SetBool("savegame.mod.newLevel.gamerule.armored", false)

		MenuStartLevel("morslonga_main", level_path,"normal nodev")
	elseif char == 3 then
		SetString("savegame.mod.difficulty", "hardcore")

		SetFloat("savegame.mod.newLevel.gamerule.lrarity", 1)
		SetBool("savegame.mod.newLevel.gamerule.drugs", true)
		SetBool("savegame.mod.newLevel.gamerule.god", false)
		SetBool("savegame.mod.newLevel.gamerule.infuel", false)
		SetBool("savegame.mod.newLevel.gamerule.keepinv", false)
		SetBool("savegame.mod.newLevel.gamerule.nhat", false)
		SetBool("savegame.mod.newLevel.gamerule.permadeath", true)
		SetBool("savegame.mod.newLevel.gamerule.armored", false)
		
		MenuStartLevel("morslonga_main", level_path,"hardcore nodev")
	elseif char == 4 then
		SetString("savegame.mod.difficulty", "hardcore")

		SetFloat("savegame.mod.newLevel.gamerule.lrarity", 8000)
		SetBool("savegame.mod.newLevel.gamerule.drugs", true)
		SetBool("savegame.mod.newLevel.gamerule.god", false)
		SetBool("savegame.mod.newLevel.gamerule.infuel", false)
		SetBool("savegame.mod.newLevel.gamerule.keepinv", false)
		SetBool("savegame.mod.newLevel.gamerule.nhat", false)
		SetBool("savegame.mod.newLevel.gamerule.permadeath", true)
		SetBool("savegame.mod.newLevel.gamerule.armored", false)
		
		MenuStartLevel("morslonga_level1","MOD/level_horde.xml")
	--[[ elseif char == 5 then
		SetString("savegame.mod.difficulty", "custom")

		SetFloat("savegame.mod.newLevel.gamerule.lrarity", LR)
		SetBool("savegame.mod.newLevel.gamerule.drugs", Drugs)
		SetBool("savegame.mod.newLevel.gamerule.god", God)
		SetBool("savegame.mod.newLevel.gamerule.infuel", infFuel)
		SetBool("savegame.mod.newLevel.gamerule.keepinv", KeepInv)
		SetBool("savegame.mod.newLevel.gamerule.nhat", NHAT)
		SetBool("savegame.mod.newLevel.gamerule.permadeath", Permadeath)
		SetBool("savegame.mod.newLevel.gamerule.armored", Armored)
		
		MenuStartLevel("morslonga_main", level_path,"normal nodev") ]]
	end
end
function client.draw()


	Width = 900
	Width2 = Width*2
	WidthHalf = Width/2

	Height = 124
	Height2 = Height*2
	HeightHalf = Height/2

	Pad = 20
	Pad2 = Pad*2
	Pad10 = Pad*10



	UiColor(1,1,1, 1)
	UiFont("bold.ttf", 24)


	if not GetBool('level.UI.menu_select_difficulty')then
		return
	end
	if plaied then


		UiColor(1,1,1, 1)
		UiAlign("left top")


		UiMakeInteractive()

		UiButtonPressColor(.8,.8,.8,.8)
		UiButtonHoverColor(.8,.8,.8)
		UiTextOutline(0,0,0,.5)


		do UiPush()
			UiAlign("center top")
			UiTranslate(UiCenter(), UiHeight() - Height*2)
			do UiPush()
				UiColor(0,0,0, .9)
				UiImageBox('ui/menu/white_32.png',Width,Height,0,0) -- Text background

				UiFont("bold.ttf", 80)
				UiColor(unpack(DIFFCULTYTEXTS[currentChar].color))
				UiButtonImageBox('ui/menu/white_32.png', 0,0, 0,0,0, 0)
				if UiTextButton(DIFFCULTYTEXTS[currentChar].character, 800, 124) or InputPressed("space") or InputPressed("return") then
					playCharacter(currentChar)
				end
				UiTranslate(0, 5)
				UiFont("bold.ttf", 25)
				UiText(DIFFCULTYTEXTS[currentChar].name)
				UiTranslate(0, 90)
				UiFont("regular.ttf", 26)
				UiText(DIFFCULTYTEXTS[currentChar].desc)
			UiPop() end
			UiColor(.6,.6,.6, .6)
			UiAlign("left middle")
			UiTranslate(0, HeightHalf)
			-- UiButtonPressDist(0)

			local btn_w = 60
			local btn_h = 120
			UiAlign("center middle")

			do UiPush()

				UiTranslate(418)

				UiColor(1,1,1, 1)
				UiButtonImageBox('ui/menu/white_32.png', 6,6, 0.4,0.4,0.4, 4/5)
				if UiTextButton(" ", btn_w, btn_h) then
					currentChar = currentChar + 1
					if currentChar > #locations then
						currentChar = 1
					end
					PlayCharSound()
					hints = false
					return
				end
				UiImageBox("MOD/img/icon_arrow_right.png", btn_w * 0.8, btn_w * 0.8)

			UiPop() end

			do UiPush()

				UiTranslate(-418)

				UiColor(1,1,1, 1)
				UiButtonImageBox('ui/menu/white_32.png', 6,6, 0.4,0.4,0.4, 4/5)
				if UiTextButton(" ", btn_w, btn_h)then
					currentChar = currentChar - 1
					if currentChar < 1 then
						currentChar = #locations
					end
					PlayCharSound()
					hints = false
					return
				end
				UiImageBox("MOD/img/icon_arrow_left.png", btn_w * 0.8, btn_w * 0.8)

			UiPop() end


			-- Nav arrows
			do UiPush()

				UiFont("bold.ttf", 50)
				UiColor(1,1,1, 1)
				UiButtonImageBox('ui/menu/white_32.png', 6,6, .4,.4,.4, .8)

				UiTranslate(0, Height/2 + Pad)

				do UiPush()
					UiAlign("right top")
					UiTranslate(-Pad2, 0)
					if UiTextButton("Back", 300, 80) then
						PlaySound(sndback)
						SetBool('level.UI.menu_select_difficulty',false)
					end
				UiPop() end

				do UiPush()
					UiAlign("left top")

					-- local iterations = 1
					-- if GetTime() % 1 > 0.5 then
					-- 	iterations = 2
					-- end

					UiButtonImageBox('ui/menu/white_32.png', 6,6, .4,.4,.4, 0.8)

					UiColor(1,1,1, 1)
					if UiTextButton("Play", 300, 80) then
						playCharacter(currentChar)
					end




				UiPop() end

			UiPop() end

		UiPop() end

		do UiPush()
			if currentChar == 5 then
				local labelMargin = 190

				UiColor(1,1,1, 1)
				UiFont("bold.ttf", 32)
				UiAlign("right middle")
				UiButtonImageBox("ui/common/box-outline-6.png",6,6)
				UiTranslate(UiCenter() - UiCenter()/1.5, UiMiddle() * 0.9)
				UiButtonPressColor(0.5,0.5,0.5, 1)
				UiButtonHoverColor(1,1,1, 1)

				do UiPush()
					--UiDrawButtonBackground(380,40,Permadeath)
					UiText("Permadeath: ")
					UiTranslate(labelMargin, 0)
					UiColorBool(Permadeath)
					if UiTextButton(DISPLAYTEXT[Permadeath], 170,40) then
						Permadeath = not Permadeath
					end
				UiPop() end
				UiTranslate(0, 40)

				do UiPush()
					--UiDrawButtonBackground(380,40,NHAT)
					UiText("No hunger and thirst: ")
					UiTranslate(labelMargin, 0)
					UiColorBool(NHAT)
					if UiTextButton(DISPLAYTEXT[NHAT], 170,40) then
						NHAT = not NHAT
					end
				UiPop() end
				UiTranslate(0, 40)

				do UiPush()
					--UiDrawButtonBackground(380,40,infFuel)
					UiText("Infinite fuel: ")
					UiTranslate(labelMargin, 0)
					UiColorBool(infFuel)
					if UiTextButton(DISPLAYTEXT[infFuel], 170,40) then
						infFuel = not infFuel
					end
				UiPop() end
				UiTranslate(0, 40)

				do UiPush()
					--UiDrawButtonBackground(380,40,God)
					UiText("Invulnerable: ")
					UiTranslate(labelMargin, 0)
					UiColorBool(God)
					if UiTextButton(DISPLAYTEXT[God], 170,40) then
						God = not God
					end
				UiPop() end
				UiTranslate(0, 40)

				do UiPush()
					--UiDrawButtonBackground(380,40,KeepInv)
					UiText("Keep inventory: ")
					UiTranslate(labelMargin, 0)
					UiColorBool(KeepInv)
					if UiTextButton(DISPLAYTEXT[KeepInv], 170,40) then
						KeepInv = not KeepInv
					end
				UiPop() end
				UiTranslate(0, 40)

				do UiPush()
					--UiDrawButtonBackground(380,40,Armored)
					UiText("Heavily armored: ")
					UiTranslate(labelMargin, 0)
					UiColorBool(Armored)
					if UiTextButton(DISPLAYTEXT[Armored], 170,40) then
						Armored = not Armored
					end
				UiPop() end
				UiTranslate(0, 40)

				do UiPush()
					--UiDrawButtonBackground(380,40,Drugs)
					UiText("Drugged up enemies: ")
					UiTranslate(labelMargin, 0)
					UiColorBool(Drugs)
					if UiTextButton(DISPLAYTEXT[Drugs], 170,40) then
						Drugs = not Drugs
					end
				UiPop() end

				UiTranslate(0, 40)

				do UiPush()
					--UiDrawButtonBackground(380,40,Drugs)
					UiText("Loot rarity: ")
					UiTranslate(labelMargin, 0)
					--UiDrawButtonBackground(380,40)
					if UiTextButton(LRarity, 170,40) then
						if LRarity == "Rare" then
							LRarity = "Scarce"
							LR = 1.25
						elseif LRarity == "Scarce" then
							LRarity = "Common"
							LR = 1.5
						elseif LRarity == "Common" then
							LRarity = "Frequent"
							LR = 2
						elseif LRarity == "Frequent" then
							LRarity = "Rare"
							LR = 1
						end
					end
				UiPop() end
				UiTranslate(0, 40)
			end
		UiPop() end
		if hints then
			hintFade=hintFade+GetTimeStep()
			local fadePercent=math.max(0,math.min(3,hintFade))/3
			UiAlign("center middle")
			UiFont("regular.ttf", 32)

			UiTextOutline(0,0,0,.6*fadePercent^2)
			UiColor(1,1,1, 1)
			UiTranslate(UiCenter(), UiMiddle())


			UiTextShadow(0,0,0, 1, 1, 1)
			UiText("Use Left/Right arrow key or A/D key to switch between mode.",true)
			UiText("Press the Enter/Space key or Click on the big text to play",true)


			-- hintFade=hintFade+GetTimeStep()
			-- UiAlign("center middle")
			-- UiFont("regular.ttf", 32)
			-- UiColor(1,1,1, 1)
			-- UiTextOutline(0,0,0, 0.5)
			-- UiTranslate(UiCenter(), UiHeight()-100)
			-- UiText("Use Left/Right arrow key or A/D key to switch between mode.", true)
			-- UiTranslate(0, 40)
			-- UiText("Press the Enter/Space key or Click on the big text to play", true)
		end
	else
		if hints then
			hintFade=-2
		end
	end
end

function UiDrawButtonBackground(w,h,green)
	local green = green or false
	do UiPush()
		if green then
			UiColor(0,.2,0,0.5)
		else
			UiColor(0,0,0,0.5)
		end
		UiImageBox("ui/common/box-solid-6.png",w,h,6,6)
	UiPop() end
end

function UiColorBool(b)
	if b then
		UiColor(0, 1, 0, 1)
		return
	end
	UiColor(1, 0, 0, 1)
end

function init()
	cam = FindBody("cam")
	locations = FindLocations("camdest", true)
	lookAts = FindLocations("lookat", true)

	currentChar = 1

	FOVDiff = VecLength(VecSub(GetLocationTransform(locations[currentChar]).pos, GetLocationTransform(lookAts[currentChar]).pos))*4

	snd = LoadSound("MOD/snd/selectsnd.ogg")

	hints = true

	Drugs = false
	God = false
	infFuel = false
	KeepInv = false
	NHAT = false
	Permadeath = false
	Armored = false
	LRarity = "Common"
end

function tick()	
	local DistForFOV = VecLength(VecSub(GetLocationTransform(locations[currentChar]).pos, GetLocationTransform(lookAts[currentChar]).pos))*4
	FOVDiff = lerp(FOVDiff,DistForFOV,.1)
	SetCameraFov(120 - FOVDiff)
	--SetCameraDof(DistForFOV/2)

	SetCameraTransform(GetBodyTransform(cam))

	if InputPressed("rightarrow") or InputPressed("d") then
		currentChar = currentChar + 1
		hints = false
	end
	if InputPressed("leftarrow") or InputPressed("a") then
		currentChar = currentChar - 1
		hints = false
	end

	if currentChar < 1 then
		currentChar = #locations
	elseif currentChar > #locations then
		currentChar = 1
	end
	
	nextCharecter()
end
function lerp(a,b,r)
	return a*(1-r)+b*r
end
function nextCharecter()
	local camTrans = GetBodyTransform(cam)
	local locPos = GetLocationTransform(locations[currentChar]).pos
	local rot = QuatLookAt(camTrans.pos, GetLocationTransform(lookAts[currentChar]).pos)
	
	SetBodyTransform(cam, Transform(VecLerp(camTrans.pos,locPos,.1), rot))

	local distToDest = VecLength(VecSub(camTrans.pos, locPos))
	if distToDest < 0.05 and not plaied then
		PlaySound(snd)
		plaied = true
	elseif distToDest > 1 then
		plaied = false
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
		["color"]={0,1,0},
		["desc"]="Enjoy while others struggle, Perfect choice for new players.",
	},
	{
		["name"]="Normal",
		["character"]="DESERTER",
		["color"]={1,1,0},
		["desc"]="Average loot/enemy spawn, fits the average you players.",
	},
	{
		["name"]="Hardcore",
		["character"]="SURVIVOR",
		["color"]={1,0,0},
		["desc"]="High risk low reward, for those who wish to torture themselves.",
	},
	{
		["name"]="Make a wish",
		["character"]="CUSTOM",
		["color"]={1,1,1},
		["desc"]="Customize your own experience.",
	},
	{
		["name"]="Credits",
		["character"]="Credit",
		["color"]={1,1,1},
		["desc"]="Roll throught the credits of who made this mod.",
	},
}

	
function draw()
	if plaied then
		UiMakeInteractive()
		
		UiButtonPressColor(1,1,.6,0.5)
		UiButtonHoverColor(1,1,.6)
		UiTextOutline(0,0,0,1)
		UiPush()
			UiFont("bold.ttf", 32)
			UiAlign("center middle")
			UiTranslate(UiCenter(), UiMiddle() + 130)
			UiColor(unpack(DIFFCULTYTEXTS[currentChar].color))
			UiText(DIFFCULTYTEXTS[currentChar].name)
			UiTranslate(0, 50)
			UiFont("bold.ttf", 92)
			if InputPressed("space") or InputPressed("return") then
				if currentChar == 1 then
					SetString("savegame.mod.difficulty", "peaceful")
				

					SetFloat("savegame.mod.gamerule.lrarity", 10)
					SetBool("savegame.mod.gamerule.drugs", false)
					SetBool("savegame.mod.gamerule.god", true)
					SetBool("savegame.mod.gamerule.infuel", true)
					SetBool("savegame.mod.gamerule.keepinv", true)
					SetBool("savegame.mod.gamerule.nhat", true)
					SetBool("savegame.mod.gamerule.permadeath", false)
					SetBool("savegame.mod.gamerule.armored", true)
					SetBool("savegame.mod.bountyboard.cultist", false)
					SetBool("savegame.mod.bountyboard.military", false)
					SetBool("savegame.mod.bountyboard.insurgent", false)
					for i=1,4 do
						SetBool("savegame.mod.bountyboard."..i, false)
					end
				elseif currentChar == 2 then
					SetString("savegame.mod.difficulty", "normal")
					

					SetFloat("savegame.mod.gamerule.lrarity", 9)
					SetBool("savegame.mod.gamerule.drugs", false)
					SetBool("savegame.mod.gamerule.god", false)
					SetBool("savegame.mod.gamerule.infuel", false)
					SetBool("savegame.mod.gamerule.keepinv", false)
					SetBool("savegame.mod.gamerule.nhat", false)
					SetBool("savegame.mod.gamerule.permadeath", false)
					SetBool("savegame.mod.gamerule.armored", false)
					SetBool("savegame.mod.bountyboard.cultist", false)
					SetBool("savegame.mod.bountyboard.military", false)
					SetBool("savegame.mod.bountyboard.insurgent", false)
					for i=1,4 do
						SetBool("savegame.mod.bountyboard."..i, false)
					end
				elseif currentChar == 3 then
					SetString("savegame.mod.difficulty", "hardcore")
				

					SetFloat("savegame.mod.gamerule.lrarity", 8)
					SetBool("savegame.mod.gamerule.drugs", true)
					SetBool("savegame.mod.gamerule.god", false)
					SetBool("savegame.mod.gamerule.infuel", false)
					SetBool("savegame.mod.gamerule.keepinv", false)
					SetBool("savegame.mod.gamerule.nhat", false)
					SetBool("savegame.mod.gamerule.permadeath", true)
					SetBool("savegame.mod.gamerule.armored", false)
					SetBool("savegame.mod.bountyboard.cultist", false)
					SetBool("savegame.mod.bountyboard.military", false)
					SetBool("savegame.mod.bountyboard.insurgent", false)
					for i=1,4 do
						SetBool("savegame.mod.bountyboard."..i, false)
					end
				elseif currentChar == 4 then
					SetString("savegame.mod.difficulty", "custom")
				

					SetFloat("savegame.mod.gamerule.lrarity", LR)
					SetBool("savegame.mod.gamerule.drugs", Drugs)
					SetBool("savegame.mod.gamerule.god", God)
					SetBool("savegame.mod.gamerule.infuel", infFuel)
					SetBool("savegame.mod.gamerule.keepinv", KeepInv)
					SetBool("savegame.mod.gamerule.nhat", NHAT)
					SetBool("savegame.mod.gamerule.permadeath", Permadeath)
					SetBool("savegame.mod.gamerule.armored", Armored)
					SetBool("savegame.mod.bountyboard.cultist", false)
					SetBool("savegame.mod.bountyboard.military", false)
					SetBool("savegame.mod.bountyboard.insurgent", false)
					for i=1,4 do
						SetBool("savegame.mod.bountyboard."..i, false)
					end
				elseif currentChar == 5 then
						

						SetFloat("savegame.mod.gamerule.lrarity", 9)
						SetBool("savegame.mod.gamerule.drugs", false)
						SetBool("savegame.mod.gamerule.god", false)
						SetBool("savegame.mod.gamerule.infuel", false)
						SetBool("savegame.mod.gamerule.keepinv", false)
						SetBool("savegame.mod.gamerule.nhat", false)
						SetBool("savegame.mod.gamerule.permadeath", false)
						SetBool("savegame.mod.gamerule.armored", false)
						SetBool("savegame.mod.bountyboard.cultist", false)
						SetBool("savegame.mod.bountyboard.military", false)
						SetBool("savegame.mod.bountyboard.insurgent", false)
						for i=1,4 do
							SetBool("savegame.mod.bountyboard."..i, false)
						end
				end
			end
			UiTranslate(0, 60)
			UiFont("regular.ttf", 26)
			UiText(DIFFCULTYTEXTS[currentChar].desc)
			
		UiPop()

		UiPush()
			if currentChar == 4 then

				local labelMargin = 190

				UiColor(1,1,1, 1)
				UiFont("bold.ttf", 32)
				UiAlign("right middle")
				UiButtonImageBox("ui/common/box-outline-6.png",6,6)
				UiTranslate(UiCenter(), 200)
				UiButtonPressColor(0.5,0.5,0.5, 1)
				UiButtonHoverColor(1,1,1, 1)


				UiPush()
					--UiDrawButtonBackground(380,40,Permadeath)
					UiText("Permadeath: ")
					UiTranslate(labelMargin, 0)
					UiColorBool(Permadeath)
					if UiTextButton(DISPLAYTEXT[Permadeath], 170,40) then
						Permadeath = not Permadeath
					end
				UiPop()
				UiTranslate(0, 40)

				UiPush()
					--UiDrawButtonBackground(380,40,NHAT)
					UiText("No hunger and thirst: ")
					UiTranslate(labelMargin, 0)
					UiColorBool(NHAT)
					if UiTextButton(DISPLAYTEXT[NHAT], 170,40) then
						NHAT = not NHAT
					end
				UiPop()
				UiTranslate(0, 40)

				UiPush()
					--UiDrawButtonBackground(380,40,infFuel)
					UiText("Infinite fuel: ")
					UiTranslate(labelMargin, 0)
					UiColorBool(infFuel)
					if UiTextButton(DISPLAYTEXT[infFuel], 170,40) then
						infFuel = not infFuel
					end
				UiPop()
				UiTranslate(0, 40)

				UiPush()
					--UiDrawButtonBackground(380,40,God)
					UiText("Invulnerable: ")
					UiTranslate(labelMargin, 0)
					UiColorBool(God)
					if UiTextButton(DISPLAYTEXT[God], 170,40) then
						God = not God
					end
				UiPop()
				UiTranslate(0, 40)

				UiPush()
					--UiDrawButtonBackground(380,40,KeepInv)
					UiText("Keep inventory: ")
					UiTranslate(labelMargin, 0)
					UiColorBool(KeepInv)
					if UiTextButton(DISPLAYTEXT[KeepInv], 170,40) then
						KeepInv = not KeepInv
					end
				UiPop()
				UiTranslate(0, 40)

				UiPush()
					--UiDrawButtonBackground(380,40,Armored)
					UiText("Heavily armored: ")
					UiTranslate(labelMargin, 0)
					UiColorBool(Armored)
					if UiTextButton(DISPLAYTEXT[Armored], 170,40) then
						Armored = not Armored
					end
				UiPop()
				UiTranslate(0, 40)

				UiPush()
					--UiDrawButtonBackground(380,40,Drugs)
					UiText("Drugged up enemies: ")
					UiTranslate(labelMargin, 0)
					UiColorBool(Drugs)
					if UiTextButton(DISPLAYTEXT[Drugs], 170,40) then
						Drugs = not Drugs
					end
				UiPop()

				UiTranslate(0, 40)

				UiPush()
					--UiDrawButtonBackground(380,40,Drugs)
					UiText("Loot rarity: ")
					UiTranslate(labelMargin, 0)
					--UiDrawButtonBackground(380,40)
					if UiTextButton(LRarity, 170,40) then
						if LRarity == "Rare" then
							LRarity = "Scarce"
							LR = 3
						elseif LRarity == "Scarce" then
							LRarity = "Common"
							LR = 5
						elseif LRarity == "Common" then
							LRarity = "Frequent"
							LR = 10
						elseif LRarity == "Frequent" then
							LRarity = "Rare"
							LR = 1
						end
					end
				UiPop()
				UiTranslate(0, 40)
			end
		UiPop()
		if hints then
			-- hintFade=hintFade+GetTimeStep()
			-- fadePercent=math.max(0,math.min(3,hintFade))/3
			-- UiAlign("center middle")
			-- UiFont("regular.ttf", 26)

			-- UiTextOutline(0,0,0,fadePercent)
			-- UiColor(1,1,1,.6*fadePercent)
			-- UiTranslate(UiCenter(), UiHeight()-100)
			-- UiText("Use Left/Right arrow key or A/D key to switch between mode.",true)
			-- UiText("Press the Enter/Space key or Click on the big text to play",true)


			hintFade=hintFade+GetTimeStep()
			UiAlign("center middle")
			UiFont("regular.ttf", 32)
			UiColor(1,1,1, 1)
			UiTextOutline(0,0,0, 0.5)
			UiTranslate(UiCenter(), UiHeight()-100)
			UiText("Use Left/Right arrow key or A/D key to switch between mode.", true)
			UiTranslate(0, 40)
			UiText("Press the Enter/Space key or Click on the big text to play", true)
		end
	else
		if hints then
			hintFade=-3
		end
	end
end

function UiDrawButtonBackground(w,h,green)
	local green = green or false
	UiPush()
		if green then
			UiColor(0,.2,0,0.5)
		else
			UiColor(0,0,0,0.5)
		end
		UiImageBox("ui/common/box-solid-6.png",w,h,6,6)
	UiPop()
end

function UiColorBool(b)
	if b then
		UiColor(0, 1, 0, 1)
		return
	end
	UiColor(1, 0, 0, 1)
end
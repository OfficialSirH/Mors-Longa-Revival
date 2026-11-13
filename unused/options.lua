function init()
	waiting=false

	init_check()
end

function init_check()
	if not HasKey("savegame.mod.settings.performance.grass")then
		SetFloat("savegame.mod.settings.performance.grass",.6)
	end
	if not HasKey("savegame.mod.settings.gameConfig.killcam")then
		SetBool("savegame.mod.settings.gameConfig.killcam",true)
	end
end

function default()
	SetFloat("savegame.mod.settings.performance.grass",.6)
	SetBool("savegame.mod.settings.performance.noShadow",false)
end

function tick()
end
function lerp(a,b,r)
	return a*(1-r)+b*r
end

DISPLAYTEXT={
	[true]="Active",
	[false]="Inactive",
}

function draw()
	--Default Ui
	UiAlign("center middle")
	UiFont("regular.ttf",26)
	UiButtonImageBox("ui/common/box-outline-6.png",6,6)
	UiButtonHoverColor(1,1,.6)
	UiButtonPressColor(1,1,.6,0.5)
	UiTextOutline(0,0,0,10)
	
	--Draw Header
	UiPush()
		UiFont("bold.ttf",48)
		UiTranslate(UiCenter(),50)
		UiText("Mors Longa Options")
	UiPop()

	--Draw buttons
	UiPush()
		UiTranslate(UiCenter(),UiMiddle()-(12*50/2))

		UiTranslate(0,50)
		UiPush()
			UiFont("bold.ttf",30)
			UiText("Performance")
		UiPop()
		
		UiTranslate(0,50)
		UiPush()
			UiTranslate(0,10)
			local val=optionsSlider("savegame.mod.settings.performance.grass",500,0,1,.1,.6)
			UiTranslate(0,-20)
			UiText("Grass Percent: "..val)
		UiPop()
		
		--[[ UiTranslate(0,50)
		UiDrawButtonBackground(500,40,GetBool("savegame.mod.settings.performance.noShadow"))
		UiPush()
			if UiTextButton("Dont worry about shadow: "..DISPLAYTEXT[GetBool("savegame.mod.settings.performance.noShadow")],500,40) then
				UiSound("../ui/common/click.ogg")
				SetBool("savegame.mod.settings.performance.noShadow",not GetBool("savegame.mod.settings.performance.noShadow"))
			end
		UiPop() ]]

		UiTranslate(0,50)

		UiTranslate(0,50)
		UiPush()
			UiFont("bold.ttf",30)
			UiText("Game")
		UiPop()

		UiTranslate(0,50)
		UiDrawButtonBackground(500,40,GetBool("savegame.mod.settings.gameConfig.killcam"))
		UiPush()
			if UiTextButton("Kill cam: "..DISPLAYTEXT[GetBool("savegame.mod.settings.gameConfig.killcam")],500,40) then
				UiSound("../ui/common/click.ogg")
				SetBool("savegame.mod.settings.gameConfig.killcam",not GetBool("savegame.mod.settings.gameConfig.killcam"))
			end
		UiPop()

		UiTranslate(0,50)
		UiDrawButtonBackground(500,40,GetBool("savegame.mod.settings.gameConfig.copyrightMusic"))
		UiPush()
			if UiTextButton("Copy righted musics: "..DISPLAYTEXT[GetBool("savegame.mod.settings.gameConfig.copyrightMusic")],500,40) then
				UiSound("../ui/common/click.ogg")
				SetBool("savegame.mod.settings.gameConfig.copyrightMusic",not GetBool("savegame.mod.settings.gameConfig.copyrightMusic"))
			end
		UiPop()

		UiTranslate(0,50)

		UiTranslate(0,50)
		UiPush()
			UiFont("bold.ttf",30)
			UiText("Others")
		UiPop()


		UiTranslate(0,50)
		UiDrawButtonBackground(500,40)
		if UiTextButton("Reset Settings",500,40)then
			UiSound("../ui/common/click.ogg")
			default(true)
		end

		UiTranslate(0,50)
		UiDrawButtonBackground(500,40)
		if UiTextButton("Reset Progress",500,40)then
			UiSound("../ui/common/click.ogg")
			waiting=true
		end
		if waiting then
			if action~=nil then
				if action then
					resetProgress()
				end
				waiting=false
				action=nil
			end
		end
		UiTranslate(0,50)
		UiDrawButtonBackground(500,40)
		if UiTextButton("Reset Mod",500,40)then
			UiSound("../ui/common/click.ogg")
			ClearKey("savegame.mod")
		end

		UiTranslate(0,50)
		UiDrawButtonBackground(500,40)
		if UiTextButton("Close",500,40) then
			UiSound("../ui/common/click.ogg")
			Menu()
		end
	UiPop()

	--hardcoded mess
	if waiting then
		action=drawWarningWindow("Are you sure you want to reset your progress?\nYour mod settings will not be reset.")
	end
end

RESETKEYLIST={"backpack","guns1","guns2","guns3","guns4","armor1","armor2","armor3","hunger","thirst","dayphase","difficulty","gamerule","bountyboard"}
function resetProgress()
	for i,key in pairs(RESETKEYLIST)do
		ClearKey("savegame.mod."..key)
	end
end

function UiDrawButtonBackground(w,h,green)
	local green = green or false
	UiPush()
		if green then
			UiColor(0,.2,0,0.7)
		else
			UiColor(0,0,0,0.7)
		end
		UiImageBox("ui/common/box-solid-6.png",w,h,6,6)
	UiPop()
end

function optionsSlider(setting,w,mi,ma,step,default)
	if not HasKey(setting)then
		SetFloat(setting,default)
	end
	UiPush()
		local steps=step or 1
		UiColor(1,1,0.6)
		local val=GetFloat(setting)
		val=(val-mi)/(ma-mi)
		UiRect(w,3)
		UiAlign("center middle")
		UiTranslate(-w/2)
		val=UiSlider("ui/common/dot.png","x",val*w,0,w)/w
		UiTranslate(w/2)
		if UiIsMouseInRect(w,10)and InputPressed("rmb")and default~=nil then
			val=default
		else
			val=math.floor((val*(ma-mi)+mi)/steps+0.5)*steps
		end
		SetFloat(setting,val)
	UiPop()
	return val
end

function drawWarningWindow(txt)
	local action
	UiPush()
		UiBlur(.5)

		UiTranslate(UiCenter(),UiMiddle())
		UiColor(.2,.2,.2,.5)
		UiImageBox("ui/common/box-solid-6.png",700,300,6,6)

		UiTranslate(0,-100)
		UiColor(.8,.1,.1)
		UiFont("bold.ttf",50)
		UiText("Warning!")

		UiTranslate(0,100)
		UiFont("bold.ttf",26)
		UiColor(1,1,1)
		UiWordWrap(450)
		UiText(txt)

		UiTranslate(200,400)
		UiPush()
			UiColorFilter(.8,.1,.1)
			if UiTextButton("Confirm",200,50) then
				UiSound("../ui/common/click.ogg")
				action = true
			end
		UiPop()
		
		UiTranslate(-400,0)
		UiPush()
			if UiTextButton("Cancel",200,50) then
				UiSound("../ui/common/click.ogg")
				action = false
			end
		UiPop()
	UiPop()
	return action
end
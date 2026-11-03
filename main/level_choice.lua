Levels = {
	{
		name = "Populated Area",
		id = "main",
		map = "MOD/main.xml",
		layers = "a b ground temp2storye temproof",
		description = "Filled with ragdolls, background buildings, and various other props"
	},
	{
		name = "Paying the Bills",
		id = "level4",
		map = "MOD/GasGoBoom.xml",
		layers = "a b ground temp2storye temproof",
		description = "11/30/2021 10:22 AM | Multiple units responded \n\n9-1-1 call reporting a gas explosion, multiple people reported dead, house set on fire, possible injured."
	},	
	{
		name = "[NTSB]Flight N011AB",
		id = "level3",
		map = "MOD/planecrashscenario.xml",
		layers = "a b ground temp2storye temproof",
		description = "9/22/2021 12:09 PM | Multiple units responded \n\nNTSB called police, CRJ200 type Aircraft out of control and impact zone has been determined, multiple units responding to evacuate civilians."
	},

		{
		name = "[REDACTED]",
		id = "level2",
		map = "MOD/thermonuclear bomb, my beloved.xml",
		layers = "a b ground temp2storye temproof",
		description = "11/27/2021 7:34 PM | 1 Engine, 1 Ambulance \n\n9-1-1 call reporting a dumpster fire, unknown origin. \n\n[CLASSIFIED INFORMATION] THIS DOCUMENT HAS BEEN CLASSIFIED UNDER THE UNITED STATES DEPARTMENT OF DEFENSE AND THE NORTH AMERICAN AEROSPACE DEFENSE COMMAND "
	},
}

SetInt("level.selected",1)	

function tick(dt)	
	SetTimeScale(0)
end

function draw()
	UiMakeInteractive()
	
	--UiColor(0,0,0)
	--UiRect(UiWidth(),UiHeight())		
	
	UiColor(0.5,0.5,0.5)
	UiImageBox("MOD/imgs/cork-board.png",UiWidth(),UiHeight(),10,10)
	UiColor(1,1,1,0.4)
	UiImageBox("MOD/imgs/burnt.jpg",UiWidth(),UiHeight())	
	
	
	--UiRect(UiWidth(),UiHeight())		
		
	UiPush()
		UiColor(1,1,1)
		UiTranslate(UiWidth()/2-500,UiHeight()/8)
		UiImageBox("MOD/imgs/title.png",1000,120,10,10)
	UiPop()

	DrawLevelPhotos()	
	
	UiPush()
		UiTranslate(UiWidth()*1/3+50,UiHeight()*2/3)
		UiColor(1,1,0.8,0.2)
		UiImageBox("ui/common/box-solid-4.png",900,300,4,4)
		UiColor(.7,.7,0.5)
		UiTranslate(-10,-10)
		UiImageBox("ui/common/box-solid-4.png",900,300,4,4)
		UiTranslate(4,4)
		UiColor(.9,0.9,0.8)
		UiImageBox("ui/common/box-solid-4.png",900-8,50,4,4)
		UiPush()
			UiTranslate(10,12)		
			UiAlign("Top Left")
			UiColor(.1,0.1,0.1)
			UiFont("bold.ttf",30)
			UiText(Levels[GetInt("level.selected")].name)		
			UiPush()
				UiTranslate(-10,38)		
				UiColor(.9,0.9,0.8)
				UiImageBox("ui/common/box-solid-4.png",900-8,300-50-8,4,4)				
			UiPop()
			UiFont("regular.ttf",24)
			UiTranslate(10,50)	
			UiColor(.1,0.1,0.1)					
			UiWordWrap(600)
			UiText(Levels[GetInt("level.selected")].description)								
		UiPop()		
		
		UiButtonImageBox("ui/common/box-solid-4.png",4,4)		
		UiTranslate(900-30,300-30)	
		UiAlign("bottom right")
		UiFont("bold.ttf",36)
		UiColor(0.1,0.1,0.1)
		if UiBlankButton(230,56) then
			local level = GetInt("level.selected")	
			StartLevel(Levels[level].id, Levels[level].map, Levels[level].layers)
		end
		UiTranslate(-20,-12)	
		UiText("Start Mission")		
	UiPop()				
end

function DrawLevelPhotos()
	UiPush()				
		UiTranslate(UiWidth()/8,UiHeight()/3)		
		UiPush()
			DrawLevelSelect(1)
			
			UiTranslate(UiWidth()/4,0)
			if #Levels > 1 then
				DrawLevelSelect(2)
			end
			
			UiTranslate(UiWidth()/4,0)
			if #Levels > 2 then
				DrawLevelSelect(3)
			end			
		UiPop()
		UiTranslate(0, UiHeight()/3)
		UiPush()
			if #Levels > 3 then
				DrawLevelSelect(4)
			end
		UiPop()
	UiPop()
end

function DrawLevelSelect(levelId)
	UiPush()
		UiScale(0.7)
		UiPush()
			UiColor(1,1,1)	
			UiRotate(-3)
			UiPush()
				UiPush()
					UiButtonImageBox("ui/common/box-solid-4.png",4,4)				
					UiTranslate(220,170)				
					if UiBlankButton(440,350) then
						SetInt("level.selected",levelId)					
					end				
				UiPop()			
				UiTranslate(20,20)			
				UiImageBox("MOD/imgs/"..Levels[levelId].id..".PNG",400,280,0,0)		
				UiFont("regular.ttf",26)
				UiTranslate(110,260)	
				UiColor(0,0,0)	
				UiRect(300,50)
				UiTranslate(2,2)
				UiColor(1,1,1)	
				UiRect(296,46)
				UiTranslate(-2,-2)
				UiColor(0,0,0)	
				UiTranslate(25,32)	
				UiText(Levels[levelId].name)
			UiPop()
			if GetInt("level.selected") ~= levelId then				
				UiTranslate(0,-4)
				UiColor(0,0,0,0.7)
				UiRect(440,348)
				--UiColor(1,0.5,0.5,0.7)
				--UiImageBox("MOD/imgs/burnt.jpg",440,348)
			end
		UiPop()
		UiPush()
			UiColor(0.8,0,0)
			UiTranslate(190,-10)
			UiImage("ui/hud/location-dot.png")
			UiColor(1,0,0)
			UiTranslate(5,-8)
			UiImage("ui/hud/location-dot.png")
		UiPop()
	UiPop()
end
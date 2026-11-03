#include "../scripts/Game/Blood/Blood.lua"

function init()
	NVGON = false
	THERMAL = false
	findtimer = 0
	Enemies = FindBodies("bodypart", true)
	Shapes = FindShapes("Bleedable", true)
end

function tick(dt)
	findtimer = findtimer - dt
	-------------------------------Bools
	DURABILITY = GetFloat("inventory.nvg.durability")
	NVGON = GetBool("inventory.nvg.enabled")
	local curEyeWear = GetString("inventory.nvg.current")
	NVG = curEyeWear == "nvg"
	THERMAL = curEyeWear == "thermals"
	PVS14 = curEyeWear == "pvs14"
	PNV10T = curEyeWear == "pnv10t"
	-------------------------------Debug
	if not NVGON then
		for i=1,#Shapes do 
			if HasTag(Shapes[i], "ThermalPalette") then
				EditPalette(Shapes[i],{{"plastic",0.32,0.0,0.0,1,0,0,0,0,200}})
				RemoveTag(Shapes[i], "ThermalPalette")
			end
		end
	end
	if NVGON then
		--DebugPrint(DURABILITY)
		if THERMAL then
			if findtimer < 0 then
				Shapes = FindShapes("Bleedable", true)
				Enemies = FindBodies("bodypart", true)
				findtimer = .25
			end
			
			for i=1,#Shapes do 
				if not HasTag(Shapes[i], "ThermalPalette") then 
					EditPalette(Shapes[i],{{"plastic",1,1,1,1,0,0,0,0.5,200}})
					SetTag(Shapes[i], "ThermalPalette")
				elseif HasTag(Shapes[i], "ThermalPalette") then
					
				end
			end
			
			for i=1,#Enemies do
				if HasTag(Enemies[i], "blood") then
					local Opacity = tonumber(GetTagValue(Enemies[i], "blood"))
					local Opacity = Opacity - .001
					if Opacity > 0.35 then
						SetTag(Enemies[i], "blood", Opacity)
						DrawBodyHighlight(Enemies[i], Opacity)
					else
						DrawBodyHighlight(Enemies[i], .35)
					end
					else
					DrawBodyHighlight(Enemies[i], 0.7)
				end
			end
		elseif PNV10T then
			if findtimer < 0 then
				Shapes = FindShapes("Bleedable", true)
				Enemies = FindBodies("bodypart", true)
				findtimer = .25
			end
			
			for i=1,#Shapes do 
				if not HasTag(Shapes[i], "ThermalPalette") then 
					EditPalette(Shapes[i],{{"plastic",1,1,1,1,0,0,0,0.2,200}})
					SetTag(Shapes[i], "ThermalPalette")
				elseif HasTag(Shapes[i], "ThermalPalette") then
					
				end
			end
			for i=1,#Enemies do
				if HasTag(Enemies[i], "blood") then
					local Opacity = tonumber(GetTagValue(Enemies[i], "blood"))
					local Opacity = Opacity - .001
					if Opacity > 0.35 then
						SetTag(Enemies[i], "blood", Opacity)
						DrawBodyHighlight(Enemies[i], Opacity)
					else
						DrawBodyHighlight(Enemies[i], .35)
					end
				else
					DrawBodyHighlight(Enemies[i], 1)
				end
			end
		else
			for i=1,#Shapes do 
				if HasTag(Shapes[i], "ThermalPalette") then
					EditPalette(Shapes[i],200)
					RemoveTag(Shapes[i], "ThermalPalette")
				end
			end
		end
		
	end
end

function draw()
	if NVGON then
		UiPush()
			UiAlign("center middle")
			UiTranslate(UiWidth()/2, UiHeight()/2)
			if THERMAL then
				UiImageBox("MOD/img/thermaloverlay.png", UiWidth(), UiHeight())
			elseif PVS14 then
				UiImageBox("MOD/img/thermaloverlay.png", UiWidth(), UiHeight())
			elseif PNV10T then
				UiImageBox("MOD/img/nvgoverlay.png", UiWidth(), UiHeight())
				UiPush()
					UiTranslate(700, 0)
					if DURABILITY > 80 then
						UiImageBox("MOD/img/Battery Icons1.png", UiWidth()/10, UiHeight()/7)
					elseif DURABILITY > 60 then
						UiImageBox("MOD/img/Battery Icons2.png", UiWidth()/10, UiHeight()/7)
					elseif DURABILITY > 40 then
						UiImageBox("MOD/img/Battery Icons3.png", UiWidth()/10, UiHeight()/7)
					elseif DURABILITY > 20 then
						UiImageBox("MOD/img/Battery Icons4.png", UiWidth()/10, UiHeight()/7)
					elseif DURABILITY > 0 then
						UiImageBox("MOD/img/Battery Icons5.png", UiWidth()/10, UiHeight()/7)
					end
				UiPop()
			else
				UiImageBox("MOD/img/nvgoverlay.png", UiWidth(), UiHeight())
			end
			--local lol = math.random(1,5)
			UiColor(0.3,0.3,0.3,0.4)
			if PVS14 then
				UiColor(0.15,0.7,0.15,0.30)
				UiImageBox("MOD/img/nvgoverlay3.png", UiWidth(), UiHeight(), 10, 10)
			elseif PNV10T then
				UiColor(0.2,1.5,1.5,0.1)
				UiImageBox("MOD/img/nvgoverlay4.png", UiWidth(), UiHeight(), 10, 10)
			elseif NVG then
				UiColor(0.2,0.5,0.2,0.25)
				UiImageBox("MOD/img/nvgoverlay2.png", UiWidth(), UiHeight(), 10, 10)
			end
			UiImageBox("MOD/img/noise" .. math.random(1,5) .. ".png", UiWidth(), UiHeight(), 10, 10)
		UiPop()
	end

end


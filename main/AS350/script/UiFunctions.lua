--Version 1.6
--19/2/2023

--Use ShowOptions to show Ui

--example for using values in main
--ToolTransform.pos = Vec(Val[ToolRight],Val[ToolUp], Val[ToolBack])

--in game options
--function draw()
--if InputPressed("m") then
--	ShowOptions =not ShowOptions
--end
--	if ShowOptions then
--		UiMakeInteractive()


	--DrawOptions("center","",1, 3)

--end

--InitialiseOptions



function InitialiseOptions()
	OptionValues()
	ShowOptions = false
	--------------------------------------------------------------------------------------------
	
	for i = 1,#Default,1 do
		--If has saved value then use that otherwise default
		if HasKey("savegame.mod.Val" .. i) and StoreValue[i] then 
			if type(Default[i]) == "number" then
				Val[i] = GetFloat("savegame.mod.Val" .. i)
			elseif type(Default[i]) == "boolean" then
				Val[i] = GetBool("savegame.mod.Val" .. i)
			end
		else
			Val[i] = Default[i]
		end
		
		--for headers UiName is left empty and is taken from the default value (done like this so default is string type there)
		if UiName[i] == nil then
			UiName[i] = Default[i]
		end
		
		--text height to pixel conversion
		if TextHeight[i] ~= nil then
			TextHeight[i] = TextHeight[i]*28 + 14
		end 
	end
end

function SideOptions()
    UiPush()
        UiColor(0, 0, 0)
        --UiRect(UiWidth(), UiHeight())

        UiColorFilter(0, 0, 0, 0.7)
        UiRect(700, UiHeight())
    UiPop()
    UiTranslate(330, 70)
    UiAlign("center middle")
end

function WholeScreenOptions()
    UiTranslate(UiCenter(), 70)
    UiAlign("center middle")
end

function DisplayMainHeader(Name)
	UiFont("bold.ttf", 48)
	UiText(Name)
	--UiFont("regular.ttf", 26)
	--UiTranslate(0, 40)
	--UiText("Extra info")
	UiTranslate(0, 30)
end

function CenterSmallUi(FromUi, ToUi)
    UiTranslate(UiCenter()-350, UiMiddle()+150)


    UiPush()
        UiColor(0, 0, 0)
        --UiRect(UiWidth(), UiHeight())

        UiColorFilter(0, 0, 0, 0.7)
        UiRect(700, (ToUi-FromUi)*50+180)
    UiPop()
    UiTranslate(220, 20)
    UiAlign("center middle")
end

function DrawOptions(OptionType,MainHeader,FromUi, ToUi)
    if OptionType == "options" then
        WholeScreenOptions()
    elseif OptionType == "side" then
        SideOptions()
    elseif OptionType == "center" then
        CenterSmallUi(FromUi, ToUi)
    end
	
    if MainHeader~= nil then
        if MainHeader~= "" then
            DisplayMainHeader(MainHeader)
        end
    end

    if OptionType == "options" then
		UiText("Press M in game to see this menu.")
		UiTranslate(0, 20)
	end
	--Var init doesn't work if in init when called from game
	----------------------------
	PopupWidth = 500
	PopupHeight = 100
	
	UiFont("regular.ttf", 26)

    if OptionType == "options" or OptionType == "side" then
        UiTranslate(-80, 0)
    end

	UiPush()

    if FromUi == nil then FromUi = 1 end
    if ToUi == nil then ToUi = #UiName end  

	--Draw the gasic Ui
	for i = FromUi,ToUi,1 do
		if type(Default[i]) == "string" then
			UiHeader(UiName[i], TextBox[i])
		elseif type(Default[i]) == "boolean" then
			Val[i] = UITickBox(UiName[i],Val[i],"Val" .. i, TextBox[i])
		elseif type(Default[i]) == "number" then
			Val[i] = UISliderExplain(UiName[i],Val[i],MinVal[i],MaxVal[i],UnitFactor[i],Unit[i],"Val" .. i, Rounding[i], TextBox[i])
		end
	end
	
	UiButtonImageBox("ui/common/box-outline-6.png", 6, 6)
	
	UiTranslate(80, 60)
	UiColor(1, 0, 0)
	if UiTextButton("Close", 80, 40) then
		if OptionType == "options" then
			Menu()
		else
			ShowOptions = false
		end
	end
	
	UiColor(1, 1, 1)
	--UiTranslate(0, 60)
	UiTranslate(-140, 0)
	if UiTextButton("Reset to default", 170, 40) then
		for i = FromUi,ToUi,1 do
			SaveSetting("savegame.mod.AdjustedVal" .. i, Val[i])
			Val[i] = Default[i]
			
			SaveSetting("savegame.mod.InGameVal" .. i, Val[i])
		end
		RecenterSliders()
	end

	--UiTranslate(0, 60)
	UiTranslate(140+140, 0)
	if UiTextButton("Recenter sliders", 170, 40) then
		RecenterSliders()
	end
	----------------------------------------------------------------------------------------
	--TextBoxes
	

	UiPop()
	--relative position of question box: 
	UiTranslate(15, -10)

	for i = 1,ToUi-FromUi+1,1 do
		if type(Default[i]) == "string" then
			UiTranslate(0, 60)
		else
			UiTranslate(0, 40)
		end
		--Debug the rectanbles where you can get popup
		--UiRect(22, 22)
        local UiId = FromUi+i-1

		if TextBox[UiId] ~=nil then
		if TextBox[UiId] ~="" then
		if UiIsMouseInRect(22, 22) then
			UiPush()
				UiColor(1, 1, 1)
				UiTranslate(PopupWidth/2+10,TextHeight[UiId]/2+10)
				UiRect(PopupWidth, TextHeight[UiId])
				UiColor(0.1, 0.1, 0.1)
				UiRect(PopupWidth-4, TextHeight[UiId]-4)

				
				UiWordWrap(PopupWidth-30)
				--UiTranslate(-40,35)
				UiColor(1, 1, 1)
				UiText(TextBox[UiId])
			UiPop()
		end
		end
		end
	end
end

--##slider types need to be adjusted here
function RecenterSliders(SliderRange)
	
	for i = 1,#Default,1 do
		if MinVal[i] ~= nil then
			local range = (MaxVal[i]-MinVal[i])/2
			MinVal[i] = Round(Val[i] - range ,Rounding[i])
			MaxVal[i] = Round(Val[i] + range,Rounding[i])
			if NonNegative[i] then
				if MinVal[i]<0 then MinVal[i] = 0 end
			end
		end
	end
end

function SaveSetting(SettingName, Value)
	if type(Value) == "number" then
		SetFloat("savegame.mod." .. SettingName, Value)
   	elseif type(Value) == "boolean" then
		SetBool("savegame.mod." .. SettingName,Value)
   	end
end

function GetSetting(SettingName, OldValue)
	if type(OldValue) == "number" then
		return GetFloat("savegame.mod." .. SettingName)
   	elseif type(OldValue) == "boolean" then
		return GetBool("savegame.mod." .. SettingName)
   	end
end

function UiHeader(TextB, PopupText)
	local Result = 0
	UiTranslate(0, 60)
	UiPush()
		UiFont("bold.ttf", 26)
		TextWithPopup(TextB, PopupText~="")
	UiPop()	
	return Result
end

function UITickBox(TextB,CurrentVal,SaveName, PopupText)
	local Result = 0
	UiTranslate(0, 40)
	UiPush()
		TextWithPopup(TextB, PopupText~="")

		--
		UiTranslate(40, 0)
		
		Result = CurrentVal
		UiButtonImageBox("ui/common/box-outline-6.png", 6, 6)
		if UiTextButton(" ", 25, 25) then
			Result = not(CurrentVal)
			SetBool("savegame.mod."..SaveName, Result)
		end
		
		UiPush()
			--UiColor(0.7, 0.6, 0.1)
			UiFont("bold.ttf", 26)
			UiColor(0.2, 0.6, 1)
			if Result then UiText("X") end
		UiPop()
		

		
	UiPop()	
	return Result
end

function TextWithPopup(Text, HasPopup)
	--text
	--UiColor(1,1,1)
	--UiColorFilter(1, 1, 1, 1)
	UiAlign("right")
	UiText(Text)
		
	UiTranslate(23, 0)

		--question mark
	if HasPopup then
		UiPush()
		UiTranslate(0,-17)
		UiColor(0.3, 0.3, 0.3)
		UiRect(20, 20)

		UiPop()
		
		UiPush()
		UiColor(1, 1, 1)
		UiFont("bold.ttf", 26)
		UiTextButton("?")
		UiPop()
	end
end


function UISliderExplain(TextB,CurrentVal,MinV,MaxV,UnitFactor,Unit,SaveName, RNo,PopupText)
	local Result = 0
	UiTranslate(0, 40)
	UiPush()
		TextWithPopup(TextB, PopupText~="")

		UiTranslate(250+15, 0)

		Result = optionsSlider(CurrentVal, MinV, MaxV, RNo)
		UiTranslate(40, 0)
		UiAlign("left")
		UiColor(0.7, 0.6, 0.1)
		UiText(Result*UnitFactor..Unit)
		SetFloat("savegame.mod."..SaveName, Result)
	UiPop()	
	return Result
end



function optionsSlider(val, min, max, RoundingNo)
	UiColor(0.2, 0.6, 1)
	UiPush()
		UiTranslate(0, -8)

		val = (val-min) / (max-min)
		local w = 250
		UiRect(w, 3)
		UiAlign("center middle")
		UiTranslate(-w, 1)
		val = UiSlider("ui/common/dot.png", "x", val*w, 0, w) / w

		val = Round((val*(max-min)+min), RoundingNo)
		if val < min then val = min end
		if val > max then val = max end

	UiPop()
	return val
end

function Round(number, RoundingNo)
	RoundingNo = 1/RoundingNo
	local lowerRound = 0
	local highherRound = 0
	
	lowerRound = math.floor(number * RoundingNo) / RoundingNo
	highherRound = math.ceil(number * RoundingNo) / RoundingNo
	
	floorerror =  math.abs(number - lowerRound)							
	ceilingerror =  math.abs(number - highherRound)
	
								
	if floorerror < ceilingerror then							
		return lowerRound						
	else							
		return highherRound						
	end		
end

function CalcUiValues(i)
	if Val[i] == nil then 
		Default[i] = ConfigDefault
		if type(Default[i]) == "number" then 
			Default[i] = Default[i] / UnitFactor[i]
		end
	else 
		Default[i] = Val[i] 
	end

	if type(Default[i]) == "number" then
		MinVal[i] = Round(Default[i] - MinRange / UnitFactor[i],Rounding[i])
		MaxVal[i] = Round(Default[i] + MaxRange / UnitFactor[i],Rounding[i])
		
		if NonNegative[i] then
			if MinVal[i]<0 then MinVal[i] = 0 end
		end
	end

	Val[i] = Default[i]
end

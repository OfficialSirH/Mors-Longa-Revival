
function OptionValues()
	Default= {} --Default values
	Val = {} --Current values
	UiName = {} --Name shown on UiAlign
	TextBox = {} --Helping text for setting
	TextHeight = {} --user gives in rows how long the text is, which is converted to pixels later
	MinVal = {} --Min Slider value
	MaxVal = {} --Max Slider value
	Unit = {} --unit shown in display
	UnitFactor = {} --displayed value only is multiplied by this number, when setting defaults below use all the displayed values (eg 1 voxel min, 1 voxel default) but internally it uses 
	--value without the above factor (eg 0.1 m)
	Rounding = {} --how many decimals to keep
	NonNegative = {} --can't go below 0
	--ConfigDefault defaults to ConfigDefault when starting, then when opening options again, defaults to current value
	StoreValue = {}

	local i = 0
	--Initialise each variable
	
	i = i + 1
		PFactor = i
		UnitFactor[i] = 1
		Rounding[i] = 0.01 / UnitFactor[i]
		ConfigDefault = 0
		UiName[i] = "Power of P"
		TextBox[i] = "Overall power of PID, everyting multiplied by 10 to this factor"
		TextHeight[i] = 2
		Unit[i] = "" 
		NonNegative[i] = false
		MinRange = 1
		MaxRange = 1
		StoreValue[i] = false

		CalcUiValues(i)

	i = i + 1
		IFactor = i
		UnitFactor[i] = 1
		Rounding[i] = 0.01 / UnitFactor[i]
		ConfigDefault = 0
		UiName[i] = "Power of I"
		TextBox[i] = "Multiply value of I constant by 10 this factor"
		TextHeight[i] = 2
		Unit[i] = "" 
		NonNegative[i] = false
		MinRange = 1
		MaxRange = 1
		StoreValue[i] = false

		CalcUiValues(i)

	i = i + 1
		DFactor = i
		UnitFactor[i] = 1
		Rounding[i] = 0.01 / UnitFactor[i]
		ConfigDefault = 0
		UiName[i] = "Power of D"
		TextBox[i] = "Multiply value of D constant by 10 this factor"
		TextHeight[i] = 2
		Unit[i] = "" 
		NonNegative[i] = false
		MinRange = 1
		MaxRange = 1
		StoreValue[i] = false

		CalcUiValues(i)

	i = i + 1
		RangeFactor = i
		UnitFactor[i] = 1
		Rounding[i] = 0.01 / UnitFactor[i]
		ConfigDefault = 0
		UiName[i] = "Power of range"
		TextBox[i] = "Multiply value of min max values by 10 this factor"
		TextHeight[i] = 2
		Unit[i] = "" 
		NonNegative[i] = false
		MinRange = 1
		MaxRange = 1
		StoreValue[i] = false

		CalcUiValues(i)
	--[[
	i = i + 1	
		AutoAimSet = i
		ConfigDefault = false
		UiName[i] = "Auto Aim"
		TextBox[i] = "If enabled, you have a bit of time to choose a target by aiming and clicking."
		TextHeight[i] = 3
		StoreValue[i] = false
		CalcUiValues(i)

		
		CalcUiValues(i)
		]]
end

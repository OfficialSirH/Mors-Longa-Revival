
--show a graph of a selected variable (must select variable in the draw function)
--Error variables are good to show.
	--function draw()
		--GraphValue(HeightError[1] * GraphHeight + GraphHeight/2 )
	--end
function GraphConfig()
	GraphWidth = 1500
	GraphHeight = 200
	GraphEveryXFrame = 1
	BackGroundAlpha = 0.4 --1, pure white graph background, 0, no background only lines, in between transparent graph background
end

function initGraph()
	GraphConfig()
	UiFrameCounter = 0
	
	GraphCounter = {}

	SNo = 0
	SeriesCount = 0
	GraphVals = {}
	RawVals = {}
	SeriesColor = {}
	for SNo = 1,10,1 do
		GraphCounter[SNo] = 0
		GraphVals[SNo] = {}
		RawVals[SNo] = {}
	end
end



--must be called in draw
--value: value to be graphed each tick
--range: range of values on the graph, at large range the graph is more squished
	--at low range high values are cut off. The center of the graph is 0
	--choose to cover the largets expected value
	--if omitted, choosen automatically to fit the range of values
--background: true or false to show whether the white background should be drawn
	--this makes the graph easier to see, however if multiple lines are graphed only the first one needs a background
--col: text colors such as "red", "black", see the LineColor function for all options
function GraphValue(val,range,Col,Background)
	if val == nil then return end
	GetSeriesNumber(Col)
	AddNewValue(val)

	--defaults
	range = CalculateRange(range)
	if Background == nil then Background = true end
	if Col == nil then Col = "red" end

	ScaleValues(range)

	if Background then 
		DrawGraphBackground()
		ShowNumberValue(val)
	end

	LineColor(Col)
		
	SecondCounter = 0
	for i = 2,GraphCounter[SNo],1 do 
		UiPush()
			UiLineGraph(i,GraphVals[SNo][i],i-1,GraphVals[SNo][i-1])
			--[[
			UiTranslate(i,GraphVals[SNo][i])
			UiRect(2,2)]]
		UiPop()
		
		ShowSecondMarking(i)
	end
	
	--UiColor(0,0,1)
	--for i = 1,GraphCounter[SNo],1 do 
		--UiPush()
		--UiTranslate(i,GraphVals2[i])
		--UiRect(2,2)
		--UiPop()
	--end
end

function UiLineGraph(a1,a2,b1,b2)
	local angle = math.atan2(b1 - a1, b2 - a2) * 180 / math.pi
	local distance = math.sqrt((a1-b1)^2+(a2-b2)^2)
	local width = 2

	UiPush()
		UiTranslate(a1 - width / 2, a2 - width / 2)
		UiRotate(angle)

		UiAlign('left top')
		UiRect(width, distance + 1)
	UiPop()
end

function AddNewValue(val)
	UiFrameCounter = UiFrameCounter + 1
		
	if UiFrameCounter % GraphEveryXFrame == 0 then
		UiFrameCounter = 1
		GraphCounter[SNo] = GraphCounter[SNo] + 1
		if GraphCounter[SNo] > GraphWidth then
			GraphCounter[SNo] = 1
		end
		RawVals[SNo][GraphCounter[SNo]] = val
	end
end

function GetSeriesNumber(col)
	local found = false

	for i = 1,SeriesCount+1,1 do
		SNo = i
		if SeriesColor[SNo] == nil then 
			SeriesColor[SNo] = col
			found = true 
			SeriesCount = SNo
		elseif SeriesColor[SNo] == col then 
			found = true 
		end
		if found then break end
	end
end


function CalculateRange(range)
	local res = 0
	local min = RawVals[SNo][1]
	local max = RawVals[SNo][1]

	if range ~= nil then
		if range~=0 then
			return range
		end
	end

	for i = 1,GraphCounter[SNo],1 do 
		if RawVals[SNo][i] < min then min = RawVals[SNo][i] end
		if RawVals[SNo][i] > max then max = RawVals[SNo][i] end
	end
	local center = 0
	res = (max-center)*2
	if (center-min)*2 > res then res = math.abs(center-min)*2 end

	return res
end

function ScaleValues(range)
	for k = 1,SeriesCount,1 do
		for i = 1,GraphCounter[k],1 do 
			GraphVals[k][i] = GraphHeight/2 - RawVals[k][i]/ range * GraphHeight--
		end
	end
end

function DrawGraphBackground()
	--White background
	UiTranslate(250,0)
	UiColor(1,1,1,BackGroundAlpha)
	UiRect(GraphWidth,200)
	
	--Center line
	UiPush()
		UiTranslate(0,100)
		UiColor(0,0,0)
		UiRect(GraphWidth,2)
	UiPop()
end

function ShowNumberValue(val)
	--Write value
	UiPush()
		UiTranslate(15,15)
		UiColor(0,0,0)
		UiFont("regular.ttf", 18)
		UiText(val)
	UiPop()
end

function LineColor(Col)
	--Graph color
	if Col == "red" then
		UiColor(1,0,0)
	elseif Col == "green" then
		UiColor(0,1,0)
	elseif Col == "blue" then
		UiColor(0,0,1)
	elseif Col == "black" then
		UiColor(0,0,0)
	else
		UiColor(1,0,0)
	end
end

function ShowSecondMarking(i)
	if i % (60/GraphEveryXFrame) == 0 then 
		UiPush()
			UiColor(0,0,0)
			UiTranslate(i,100-8/2)
			UiRect(2,8)

			SecondCounter = SecondCounter + 1
			UiTranslate(-6,20)
			UiColor(0.6,0.6,0.6)
			UiFont("regular.ttf", 16)
			UiText(SecondCounter .. "s")
		UiPop()
	end
end
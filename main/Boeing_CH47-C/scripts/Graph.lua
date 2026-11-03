

function initGraph()
--show a graph of a selected variable (must select variable in the draw function)
						--Error variables are good to show.
	GraphWidth = 1500
	GraphCounter = 0
	GraphEveryXFrame = 1
	UiFrameCounter = 0
	GraphHeight = 200
	

	GraphVals1 = {}
	RawVals = {}

	
	--function draw()
		--GraphValue(HeightError[1] * GraphHeight + GraphHeight/2 )
	--end
	GraphVal = 0
	
end

function GraphValue(val,range,Col,Background)
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
	for i = 1,GraphCounter,1 do 
		UiPush()
		UiTranslate(i,GraphVals1[i])
		UiRect(2,2)
		UiPop()
		
		ShowSecondMarking(i)
	end
	
	--UiColor(0,0,1)
	--for i = 1,GraphCounter,1 do 
		--UiPush()
		--UiTranslate(i,GraphVals2[i])
		--UiRect(2,2)
		--UiPop()
	--end
end


function AddNewValue(val)
	UiFrameCounter = UiFrameCounter + 1
		
	if UiFrameCounter % GraphEveryXFrame == 0 then
		UiFrameCounter = 1
		GraphCounter = GraphCounter + 1
		if GraphCounter > GraphWidth then
			GraphCounter = 1
		end
		RawVals[GraphCounter] = val
	end
end

function CalculateRange(range)
	local res = 0
	local min = RawVals[1]
	local max = RawVals[1]

	if range ~= nil then
		if range~=0 then
			return range
		end
	end

	for i = 1,GraphCounter,1 do 
		if RawVals[i] < min then min = RawVals[i] end
		if RawVals[i] > max then max = RawVals[i] end
	end
	local center = 0
	res = (max-center)*2
	if (center-min)*2 > res then res = math.abs(center-min)*2 end

	return res
end

function ScaleValues(range)
	for i = 1,GraphCounter,1 do 
		GraphVals1[i] = GraphHeight/2 - RawVals[i]/ range * GraphHeight--
	end
end

function DrawGraphBackground()
	--White background
	UiTranslate(250,0)
	UiColor(1,1,1)
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
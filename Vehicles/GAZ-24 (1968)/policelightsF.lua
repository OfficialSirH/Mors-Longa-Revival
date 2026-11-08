function init()
	lights = FindShapes("blink")
	pLights = false
	vehicle = FindVehicle()
end

function draw()
	if InputPressed("f") then
		if GetPlayerVehicle() == vehicle then
		 	if pLights == false then
				pLights = true
			else
				pLights = false
			end
		end
	end
	if pLights then
		for i=1, #lights do
			local l = lights[i]
			local p = tonumber(GetTagValue(l, "blink"))
			if p then
				local s = math.sin((GetTime()+i) * p)
				SetShapeEmissiveScale(l, s > 0 and 1 or 0)
			end
		end
	else
		for i=1, #lights do
			SetShapeEmissiveScale(lights[i], 0 > 0 and 1 or 0)
		end
	end
end

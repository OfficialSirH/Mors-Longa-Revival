function init()
	r,g,b = GetEnvironmentProperty("skyboxtint")
	x = 0
end

function update()
x = x + 0.000001
--[[ if InputDown("y") then
	x = x + 0.01
end ]]
xsin = math.sin(x)
xsin = xsin + 0.5
--DebugPrint(xsin)
if xsin < 0.01 then
	xsin = 0.001
end

SetEnvironmentProperty("skyboxtint", r*xsin,g*xsin,b*xsin)
SetEnvironmentProperty("fogColor", r*xsin,g*xsin,b*xsin)
SetEnvironmentProperty("sunColorTint", r*xsin,g*xsin,b*xsin)
end
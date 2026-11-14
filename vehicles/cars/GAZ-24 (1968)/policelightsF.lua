#version 2
#include "script/include/player.lua"
-- (v2) SERVER: militia GAZ-24 police lights ("blink" shapes, tag value = blink rate): F toggles them for any player
-- in the car (driver or passenger; v1: the host, in draw); blinking set on the server. Hand-converted 2026-11-09.

function server.init()
	lights = FindShapes("blink")
	pLights = false
	vehicle = FindVehicle()
end

function server.tick(dt)
	for p in Players() do
		if vehicle ~= 0 and GetPlayerVehicle(p) == vehicle and InputPressed("f", p) then
			pLights = not pLights
		end
	end
	if pLights then
		for i = 1, #lights do
			local l = lights[i]
			local rate = tonumber(GetTagValue(l, "blink"))
			if rate then
				local s = math.sin((GetTime() + i) * rate)
				SetShapeEmissiveScale(l, s > 0 and 1 or 0)
			end
		end
	else
		for i = 1, #lights do
			SetShapeEmissiveScale(lights[i], 0)
		end
	end
end

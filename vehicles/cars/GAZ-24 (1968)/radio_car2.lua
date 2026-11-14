#version 2
#include "script/include/player.lua"
-- (v2) SERVER: militia GAZ-24 "radio" shape = siren switch: any player toggles it (v1: the host); click at the
-- radio, the loop at its position. Hand-converted 2026-11-09. Siren path fixed (v1 "MOD/Vehicle/..." does not exist,
-- same in 9dde6dd: the siren never played; user OK 2026-11-09, TECHNICAL_REFERENCE §8).
on = false
function server.init()
	--Find handle to radio
	radio = FindShape("radio")

	--Make sure the light is turned off and make interactable
	SetShapeEmissiveScale(radio, 0)
	SetTag(radio, "interact", "Turn on")

	--Load click sound and music from game assets
	clickSound = LoadSound("clickdown.ogg")
	musicLoop = LoadLoop("MOD/vehicles/cars/GAZ-24 (1968)/Sounds/Siren.ogg") -- (v2 fix) v1: "MOD/Vehicle/"
end

function server.tick(dt)
	--If radio is broken it should not be interactable and not function
	if IsShapeBroken(radio) then
		RemoveTag(radio, "interact")
		return
	end

	--Turn on/off radio
	for p in Players() do
		if GetPlayerInteractShape(p) == radio and InputPressed("interact", p) then
			PlaySound(clickSound, GetShapeWorldTransform(radio).pos)
			if on then
				on = false
				SetShapeEmissiveScale(radio, 0)
				SetTag(radio, "interact", "Turn on")
			else
				on = true
				SetShapeEmissiveScale(radio, 1)
				SetTag(radio, "interact", "Turn off")
			end
		end
	end

	--If radio is on, play music at the world position
	if on then
		local pos = GetShapeWorldTransform(radio).pos
		PlayLoop(musicLoop, pos)
	end
end

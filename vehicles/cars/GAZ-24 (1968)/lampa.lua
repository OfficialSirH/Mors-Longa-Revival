#version 2
#include "script/include/player.lua"
-- (v2) SERVER: GAZ-24 interior light switch ("switch" shape, "lamp" light): any player toggles it (v1: the host);
-- the click plays at the switch (v1: in the listener's ears, no position). Hand-converted 2026-11-09.

function server.init()
	--Find handles to the light switch and and lamp
	switch = FindShape("switch")
	lamp = FindLight("lamp")

	--The light should start turned off
	on = false
	SetLightEnabled(lamp, false)
	SetTag(switch, "interact", "Turn on")

	--Load sounds from the game asset folder (data/snd)
	onSound = LoadSound("screen-on.ogg")
	offSound = LoadSound("screen-off.ogg")
end

function server.tick(dt)
	for p in Players() do
		--Check if a player interacts with the light switch
		if GetPlayerInteractShape(p) == switch and InputPressed("interact", p) then
			local pos = GetShapeWorldTransform(switch).pos
			--Turn light on or off, depending on the current state
			if on then
				on = false
				PlaySound(offSound, pos)
				SetLightEnabled(lamp, false)
				SetTag(switch, "interact", "Turn on")
			else
				on = true
				PlaySound(onSound, pos)
				SetLightEnabled(lamp, true)
				SetTag(switch, "interact", "Turn off")
			end
		end
	end
end

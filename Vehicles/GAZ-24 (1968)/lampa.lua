function init()	
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


function tick()
	--Check if player interacts with light switch and presses interact button
	if GetPlayerInteractShape() == switch and InputPressed("interact") then

		--Turn light on or off, depending on the current state
		if on then
			on = false
			PlaySound(offSound)
			SetLightEnabled(lamp, false)
			SetTag(switch, "interact", "Turn on")
		else
			on = true
			PlaySound(onSound)
			SetLightEnabled(lamp, true)
			SetTag(switch, "interact", "Turn off")
		end
		
	end
end


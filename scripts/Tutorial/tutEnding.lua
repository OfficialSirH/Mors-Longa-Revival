#version 2
#include "script/include/player.lua"
-- (v2) Tutorial end. Server: when ANY player enters a "tutEnding" trigger, shared.ending is set; 5.5 s later the
-- host starts MOD/main.xml (StartLevel). Client (every player): camera on "tutEndingCam", 5 s fade to black, and
-- the player's own savegame is marked "tutorial finished" (savegames are per machine).
function server.init()
	triggers = FindTriggers("tutEnding",true)
	EndTimer = 0
	Started = false
end

function server.tick(dt)
	if not shared.ending then
		for p in Players() do
			local pos = GetPlayerTransform(p).pos
			for i,trigger in ipairs(triggers)do
				if IsPointInTrigger(trigger,pos)then
					shared.ending = true
					break
				end
			end
			if shared.ending then break end
		end
	else
		EndTimer = EndTimer + dt
		-- 0.5 s after the clients' fade is complete, so every client has saved
		if EndTimer >= 5.5 and not Started then
			Started = true
			StartLevel('','MOD/main.xml',"",true)
		end
	end
end

function client.init()
	camLoc = FindLocation("tutEndingCam",true)
	gTutEndTime = 0
	Saved = false
	Seen = false
end

function client.tick(dt)
	if not shared.ending then return end
	if not Seen then
		Seen = true
		SetString('hud.notification',"")
		SetBool("inventory.init", true)
	end
	SetCameraTransform(GetLocationTransform(camLoc))
	gTutEndTime = gTutEndTime + dt
	if gTutEndTime >= 5 and not Saved then
		Saved = true
		SetBool('savegame.mod.tutorial.states.hasFinishedTutorialLevel',true)
	end
end

function client.draw()
	if shared.ending then
		UiColor(0,0,0,math.min(gTutEndTime / 5, 1))
		UiRect(UiWidth(),UiHeight())
	end
end
function init()
	triggers = FindTriggers("tutEnding",true)
	camLoc = FindLocation("tutEndingCam",true)
	gTutEndTime = 0
end
function tick(dt)
	local pT = GetPlayerTransform()
	for i,trigger in ipairs(triggers)do
		if IsPointInTrigger(trigger,pT.pos)then
			SetString('hud.notification',"")
			gTutEnd = true
			SetBool("inventory.init", true)
			break
		end
	end
	if gTutEnd then
		SetCameraTransform(GetLocationTransform(camLoc))
	end
end
function draw(dt)
	if gTutEnd then
		gTutEndTime = gTutEndTime + dt
		local tutEndFade = gTutEndTime / 5
		UiColor(0,0,0,tutEndFade)
		UiRect(UiWidth(),UiHeight())
		if gTutEndTime>=5 then
			SetBool('savegame.mod.tutorial.states.hasFinishedTutorialLevel',true)
			StartLevel('','MOD/main.xml',"",true)
		end
	end
end
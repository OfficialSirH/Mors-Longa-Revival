function init()
	hitboxes = FindTriggers('hitbox',true)
end

function tick()
	
end

function draw()
	local drawWarn = false
	for i,hitbox in ipairs(hitboxes) do
		if HasTag(hitbox,'Bleed') then
			drawWarn = true
			break
		end
	end

	if drawWarn then
		UiTranslate(UiCenter(),UiMiddle())
		UiAlign('center middle')
		UiFont('bold.ttf',40)
		UiColor(math.sin(GetTime()*math.pi/2)/6 + 5/6,0,0)
		UiText('You are bleeding.',true)
		UiText('Seek medical attention.',true)
		UiFont('bold.ttf',30)
		UiText('You need a bandage.',true)
	end
end
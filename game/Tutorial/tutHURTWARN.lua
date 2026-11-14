#version 2
-- (v2) client: "You are bleeding" warning. The health script runs on each player's client and tags that player's
-- own hitbox triggers "Bleed", so each player only sees their own warning. Triggers are looked up every draw
-- because the local hitboxes may be spawned after this script's init.
function client.draw()
	local drawWarn = false
	for i,hitbox in ipairs(FindTriggers('hitbox',true)) do
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
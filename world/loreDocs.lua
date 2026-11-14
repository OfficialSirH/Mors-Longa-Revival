function init()
	disp=0
	showing=false
	interactShape=FindShape("doc")
	SetTag(interactShape,"interact","inspect")
	names={"PZ1_1C","PZ1_1UC","PZ1_2C","PZ1_2UC","PZ1_3C","PZ1_3UC","PZ1_4C","PZ1_4UC"}
	path="MOD/assets/img/documents/"..names[math.random(1,#names)]..".png"
	if math.random()<0.0001 then
		path="MOD/assets/img/documents/example.png"
	end
end

function tick(dt)
	if GetPlayerInteractShape()==interactShape and InputPressed("interact") and not showing then
		showing = true
	elseif InputPressed("interact") and showing then
		showing=false
	end
end

function draw()
	if showing then
		disp=lerp(disp,1,0.1)
		UiMakeInteractive()
	else
		disp=lerp(disp,0,0.1)
	end
	UiColor(1,1,1,disp)
	UiScale((0.1*disp+0.9))
	UiTranslate(UiCenter(),UiMiddle())
	UiAlign("center middle")
	UiScale(0.5)
	UiRect(10,10)
	UiImage(path)
end

function lerp(a, b, m)
	return (b-a)*m+a
end
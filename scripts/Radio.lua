function init()
	RadioMusic = LoadLoop("MOD/snd/Music/Shop/MUS_Radio_Shop0.ogg")
	Radios = FindShapes("Radio", true)
	radtim = 0
end
function tick(dt)
	radtim = radtim + dt
	if radtim > 10 then
	Radios = FindShapes("Radio", true)
	radtim = 0
	end
	for i=1,#Radios do
		if not IsShapeBroken(Radios[i]) then
		RadioTrans = GetShapeWorldTransform(Radios[i])
		PlayLoop(RadioMusic, RadioTrans.pos, 1)
	end
	end
end
#version 2
#include "script/include/player.lua"
-- (v2) sound only: runs on every client
function client.init()
	RadioMusic = LoadLoop("MOD/assets/snd/Music/Shop/MUS_Radio_Shop0.ogg")
	Radios = FindShapes("Radio", true)
	radtim = 0
end
function client.tick(dt)
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
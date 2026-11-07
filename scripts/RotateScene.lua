#version 2
#include "script/include/player.lua"
-- (v2) menu turntable (server) and menu camera with mouse depth of field (client).
function FindSceneHandles()
	Body = FindBody("Rotate")
	Shape = FindShape("Camera")
	Shape2 = FindShape("Look")

end

function server.update(dt)
	local BodyTrans = GetBodyTransform(Body)
	BodyTrans.rot = QuatRotateQuat(BodyTrans.rot, QuatEuler(0, dt * 6, 0))
	SetBodyTransform(Body, BodyTrans)
end

function client.draw(dt)
	local mouseX = GetFloat('level.UI.mouseX')
	local mouseY = GetFloat('level.UI.mouseY')

	local ShapeTrans = GetShapeWorldTransform(Shape)
	ShapeTrans.pos[2] = ShapeTrans.pos[2] + 20

	local LookTrans = GetShapeWorldTransform(Shape2)
	local Rot = QuatLookAt(ShapeTrans.pos, LookTrans.pos)
	local camT = Transform(ShapeTrans.pos, Rot)
	SetCameraTransform(camT, 30)
	SetCameraFov(30)

	local mouseDir = UiPixelToWorld(mouseX, mouseY)
	--DebugWatch('mouseDir',mouseDir)
	local hit, dist, normal, shape = QueryRaycast(camT.pos, mouseDir, 100, nil, true)
	if hit then
		--DebugWatch('dist',dist)
		SetCameraDof(dist)
	else
		SetCameraDof(40)
	end
end

function ternary( cond , T , F ) if cond then return T else return F end end

-- (v2) the turntable turns on the server (synced); each client sets its own menu camera
function server.init()
	FindSceneHandles()
end

function client.init()
	FindSceneHandles()
end

-- (v2) v2 players have a visible character, which stood in the middle of the menu scene: hide every player
-- (per tick, as the official creativemode.lua does on the server)
function server.tick(dt)
	for p in Players() do
		SetPlayerHidden(p)
	end
end

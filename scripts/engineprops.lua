#version 2
#include "script/include/player.lua"
-- (v2) server: spins the supply plane's propeller joint.
function server.init()
	blade = FindJoint("engine")

	SetJointMotor(blade, 20)
end
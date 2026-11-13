#version 2
#include "script/include/player.lua"
-- (v2) server: supply-drop parachute drag; removed near the ground.
function server.init()
	chute = FindBody("chute")


end

function server.update(dt)	
	if HasTag(chute, "vehicle") then 
		number = 500 
	else
		number = 50
	end
	-- (v2) removed v1 leftover DebugPrint(height) (printed nil on screen every frame)
	local height = GetBodyTransform(chute).pos[2]
	if height < 7 or IsBodyBroken(chute) then 
		Delete(chute)
	end
		velocity = GetBodyVelocity(chute)
		bodyTrans = GetBodyTransform(chute)
		localVel = TransformToLocalVec(bodyTrans, velocity)
		ver_speed= -localVel[2]
	
	dragforce_ver = ver_speed * number
	ApplyBodyImpulse(chute,VecAdd(GetBodyCenterOfMass(chute),GetBodyTransform(chute).pos),TransformToParentVec(GetBodyTransform(chute), Vec(0,dragforce_ver,0)))
end

		

		



   
   
   
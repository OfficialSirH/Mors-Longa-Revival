#version 2
#include "script/include/player.lua"

-- (v2) camera tilt only: client
function client.init()
	leanAngle = 15
	leanAmount = 0.5
	curangle = 0
	curleanamount = 0
	firstrot = Quat(0,0,0,0)
	secondrot = Quat(0,0,0,0)
	thirdrot = Quat(0,0,0,0)
	fourthrot = Quat(0,0,0,0)
	CurTool = nil
	cycled = false
	leangrowth = 0.05
end

function client.tick(dt)
	local moving = GetPlayerVelocity()[1] > 0 or GetPlayerVelocity()[3] > 0
	local Sprinting = InputDown("shift")
	local walking = not InputDown("shift")
	

	if InputDown("q") and InputDown("alt") and not Sprinting and GetPlayerVehicle() == 0  then
        if curangle < leanAngle then
			curangle = curangle + (1+math.random())/2
		else	
			curangle = leanAngle
		end

    elseif InputDown("e") and InputDown("alt") and not Sprinting and GetPlayerVehicle() == 0 then
		if curleanamount < leanAmount then		
			local dir2 = TransformToParentPoint(GetPlayerTransform(), Vec(leangrowth, 0,0))
			--SetPlayerTransform(Transform(dir2,GetPlayerTransform().rot))
			curleanamount = curleanamount + leangrowth
		end
		if curangle > -leanAngle then
			curangle = curangle - (1+math.random())/2
		else	
			curangle = -leanAngle
		end

    end
	if not InputDown("q") and not InputDown("e") then
		if curleanamount > 0 then	
			local dir2 = TransformToParentPoint(GetPlayerTransform(), Vec(-leangrowth, 0,0))
			--SetPlayerTransform(Transform(dir2,GetPlayerTransform().rot))
			curleanamount = curleanamount - leangrowth
		end
		if curleanamount < 0 then	
			local dir2 = TransformToParentPoint(GetPlayerTransform(), Vec(leangrowth, 0,0))
			--SetPlayerTransform(Transform(dir2,GetPlayerTransform().rot))
			curleanamount = curleanamount + leangrowth
		end
		if curangle > 0 then
			curangle = curangle - 1
		end
		if curangle < 0 then
			curangle = curangle + 1
		end
	end
	firstrot = QuatAxisAngle(Vec(0, 0, 1), curangle)
	--secondrot = QuatAxisAngle(Vec(1, 0, 0), math.sin(GetTime()*5) * 3.0)
	--thirdrot = QuatAxisAngle(Vec(0, 1, 0), math.sin(GetTime()*3) * 3.0)
	--fourthrot = QuatAxisAngle(Vec(0, 0, 1), math.sin(GetTime()*6) * 3.0)


	
	rot = firstrot
	--for i=1,40 do DebugPrint("") end
	--DebugPrint("" .. rot[1] .. "," .. rot[2] .. "," .. rot[3] .. "")
	--DebugPrint("" .. firstrot[1] .. "," .. firstrot[2] .. "," .. firstrot[3] .. "")
	--DebugPrint("" .. secondrot[1] .. "," .. secondrot[2] .. "," .. secondrot[3] .. "")
	local dir2 = TransformToParentPoint(GetPlayerTransform(), Vec(1, 0,0))
	SetPlayerCameraOffsetTransform(Transform(Vec(), rot))
	--DebugPrint(GetPlayerWalkingSpeed())
end



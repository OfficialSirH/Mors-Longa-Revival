LAYER_A = 1 -- Default
LAYER_B = 2
LAYER_C = 4
LAYER_D = 8
LAYER_E = 16
LAYER_F = 32
LAYER_G = 64
LAYER_H = 128
LAYER_ALL = 255

function init()
	TORSO = FindShape("TORSO")
	Neck = FindJoint("neck")
	if IsHandleValid(TORSO) then
		shapes = FindShapes("")
		for i=1,#shapes do
			SetShapeCollisionFilter(shapes[i], LAYER_H, LAYER_ALL-LAYER_H)
		end
	else
		removeEverything()
		done = true
		return
	end

	bodyparts = FindShapes("bodypart")
	delay = math.random(1,3)
end
function removeEverything()
	local shapes = FindShapes()
	for i=1,#shapes do
		Delete(shapes[i])
	end
	local joints = FindJoints()
	for i=1,#joints do
		Delete(joints[i])
	end
end
function tick()
		
		
	
	
		if not done then
			delay = delay - .01
				if delay < 0 then 
					local neckturn = math.random(-90,90)
					local neckturnrate = math.random(1,5)
					SetJointMotorTarget(Neck, neckturn, neckturnrate)
					delay = math.random(1,7)
				end
			
		
	
		
		
		if not IsHandleValid(TORSO) then
			removeEverything()
			done = true
			return
			
		end
		
		for i=1,#bodyparts do
			if IsShapeBroken(bodyparts[i]) then
				deleteandspawn = true
				break
			end
		end

		if deleteandspawn then
			local cooltrans = GetShapeWorldTransform(TORSO)
			local ragdollname = GetTagValue(TORSO, "ragdollname")
			removeEverything()
			--DebugPrint("Ragdoll name: ".. ragdollname)
			Spawn("MOD/main/GoreRagdolls2/Sitters/" .. ragdollname .. ".xml", cooltrans)
			done = true
			--DebugPrint("MOD/main/GoreRagdolls2/Sitters/" .. ragdollname .. ".xml")
		end
	end
end	

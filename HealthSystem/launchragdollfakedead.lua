function init()
	bingy = 3
	boc = 2
end
function tick()
	if not done then
		bodyparts = FindBodies("bodypart")
		for i=1,#bodyparts do
			SetBodyVelocity(bodyparts[i], GetPlayerVelocity())
		end
		done = true
	end
	if done and not stop then


		FP = FindBody("FakePlayer")
		Torso = FindBody("Torso")
		x,y,z = GetQuatEuler(GetPlayerCameraTransform().rot)
		TorsoTrans = GetBodyTransform(Torso)
		SetBodyTransform(FP, Transform(TorsoTrans.pos, QuatEuler(-x,y,z)))
		DebugCross(GetBodyTransform(FP).pos)
		DebugCross(GetBodyTransform(Torso).pos)

		ct = GetBodyTransform(FP)


		local sbt = GetBodyTransform(FP)
    	local bias = Vec()
    	local trVec = VecScale(Vec(InputValue('left')-InputValue('right'),0,InputValue('up')-InputValue('down')),boc)
		local currentVelocity = GetBodyVelocity(Torso)

    	local trVel = TransformToParentPoint(sbt, trVec)
    	local velSub = VecSub(trVel, sbt.pos)
        SetBodyVelocity(Torso, VecAdd(GetBodyVelocity(Torso),velSub))

		gunTrans = ct
        gunPos = gunTrans.pos
        direction = TransformToParentVec(gunTrans, Vec(0, -1, 0))
        shootPos = VecAdd(gunPos, VecScale(direction, 0.2))
		startpos = TransformToParentPoint(ct, Vec(0, 0, -5))

		if not olded then
			--oldct = Transform(Vec(ct.pos[1] + math.random(-3,3),ct.pos[2] + math.random(3,3),ct.pos[3] + math.random(-3,3)), ct.rot)
			oldct = Transform(Vec(ct.pos[1] + math.random(-3,3),ct.pos[2] + math.random(3,3),ct.pos[3] + math.random(-3,3)), ct.rot)
			olded = true
			newctadd = Vec( math.random(-bingy,bingy), math.random(bingy,bingy*2),  math.random(-bingy,bingy))
		end

		tppcamtrans = startpos
		--newct = VecAdd(ct.pos, newctadd)
    	--Rot = QuatLookAt(newct, ct.pos)
    	Rot = QuatLookAt(startpos, ct.pos)
		--SetCameraTransform(Transform(newct, Rot))
		SetCameraTransform(Transform(startpos, Rot))
		--DebugPrint(canSeePlayer())
		if not canSeePlayer() then
			--olded = false
			if bingy > 0 then
			--bingy = bingy - 0.1
			end
		end
	end
	--[[ if InputPressed("L") then
		stop = true
		shapes = FindShapes("")
		bodies = FindBodies("")
		playervel = GetPlayerVelocity()
		tt = GetBodyTransform(FindBody("Torso"))
		SetPlayerTransform(Transform(Vec(tt.pos[1],tt.pos[2] + 1,tt.pos[3]), QuatEuler(x,y,z)), true)
		SetPlayerVelocity(playervel)
		joints = FindJoints("")
		for i=1,#joints do
			Delete(joints[i])
		end
		for i=1,#shapes do
			Delete(shapes[i])
		end
		for i=1,#bodies do
			Delete(bodies[i])
		end
	end ]]
end

function canSeePlayer()
    local camTrans = Transform(newct, Rot)
    local playerPos = camTrans.pos

    -- Direction to player
    local dir = VecSub(playerPos, shootPos)
    local dist = VecLength(dir)
    dir = VecNormalize(dir)

    QueryRejectVehicle(GetPlayerVehicle())
    shapes = FindShapes("")
    for i=1,#shapes do
		QueryRejectShape(shapes[i])
	end
    return not QueryRaycast(shootPos, dir, dist, 0, true)
end
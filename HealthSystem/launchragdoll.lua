function init()
	bingy = 3
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
		ct = GetBodyTransform(FindBody("Head"))

		gunTrans = ct
        gunPos = gunTrans.pos
        direction = TransformToParentVec(gunTrans, Vec(0, -1, 0))
        shootPos = VecAdd(gunPos, VecScale(direction, 0.2))

		startpos = TransformToParentPoint(ct, Vec(0, 0, -2))
		if not olded then
			oldct = Transform(Vec(ct.pos[1] + math.random(-5,5),ct.pos[2] + math.random(3,5),ct.pos[3] + math.random(-5,5)), ct.rot)
			olded = true
			newctadd = Vec( math.random(-bingy,bingy), math.random(bingy,bingy*2),  math.random(-bingy,bingy))
		end

		tppcamtrans = startpos
		newct = VecAdd(ct.pos, newctadd)
    	Rot = QuatLookAt(newct, ct.pos)
		--SetCameraTransform(Transform(newct, Rot))
    	local gunpos = TransformToParentPoint(ct, Vec(-0.2, 0, 0))
		SetCameraTransform(Transform(gunpos, ct.rot))
		if not canSeePlayer() and bingy > 1 then
		--	olded = false
			--bingy = bingy - 0.1
		end
	end
	if GetPlayerHealth() ~= 0 then
		stop = true
	end
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
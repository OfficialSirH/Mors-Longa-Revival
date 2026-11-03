--todo
--[[

	bugs
		regular npc hoverUpright() makes npc wobble heavily, especially when walking.
		npcs cannot slimb steadily like robots. their legs seem short .

]]

function npc_init_robot(npc)

	npc.config = {}
	npc.hasVision = false
	npc.config.viewDistance = 25
	npc.config.viewFov = 150
	npc.config.canHearPlayer = false
	npc.config.canSeePlayer = false
	npc.config.patrol = false
	npc.config.sensorDist = 5.0
	npc.config.speed = 0
	npc.config.turnSpeed = 4
	npc.config.huntPlayer = false
	npc.config.huntSpeedScale = 1.6
	npc.config.avoidPlayer = false
	npc.config.triggerAlarmWhenSeen = false
	npc.config.visibilityTimer = 0.3 --Time player must be seen to be identified as enemy (ideal condition)
	npc.config.lostVisibilityTimer = 5.0 --Time player is seen after losing visibility
	npc.config.outline = 13
	npc.config.aimTime = 5.0
	npc.config.maxSoundDist = 100.0
	npc.config.aggressive = false
	npc.config.stepSound = "m"
	npc.config.practice = false


	npc.robot = {}
	npc.robot.body = 0
	npc.robot.transform = Transform()
	npc.robot.axes = {}
	npc.robot.bodyCenter = Vec()
	npc.robot.navigationCenter = Vec()
	npc.robot.dir = Vec(0, 0, -1)
	npc.robot.speed = 0
	npc.robot.blocked = 0
	npc.robot.mass = 0
	npc.robot.allBodies = {}
	npc.robot.allShapes = {}
	npc.robot.allJoints = {}
	npc.robot.initialBodyTransforms = {}
	npc.robot.enabled = true
	npc.robot.deleted = false
	npc.robot.speedScale = 2.5
	npc.robot.breakAll = false
	npc.robot.breakAllTimer = 0
	npc.robot.distToPlayer = 100
	npc.robot.dirToPlayer = 0
	npc.robot.roamTrigger = 0
	npc.robot.limitTrigger = 0
	npc.robot.investigateTrigger = 0
	npc.robot.activateTrigger = 0
	npc.robot.stunned = 0
	npc.robot.outlineAlpha = 0
	npc.robot.canSensePlayer = false
	npc.robot.playerPos = Vec()


	npc.hover = {}
	npc.hover.hitBody = 0
	npc.hover.contact = 0.0
	npc.hover.distTarget = 1.4
	npc.hover.distPadding = 0.35
	npc.hover.timeSinceContact = 0.0


	npc.head = {}
	npc.head.body = 0
	npc.head.eye = 0
	npc.head.dir = Vec(0,0,-1)
	npc.head.lookOffset = 0
	npc.head.lookOffsetTimer = 0
	npc.head.canSeePlayer = false
	npc.head.lastSeenPos = Vec(0,0,0)
	npc.head.timeSinceLastSeen = 999
	npc.head.seenTimer = 0
	npc.head.alarmTimer = 0
	npc.head.alarmTime = 2.0
	npc.head.aim = 0	-- 1.0 = perfect aim, 0.0 = will always miss player. This increases when robot sees player based on npc.config.aimTime


	-- configInit(npc)
	robotInit(npc)
	hoverInit(npc)
	headInit(npc)
	sensorInit(npc)
	-- wheelsInit(npc)
	feetInit(npc)
	-- aimsInit(npc)
	-- weaponsInit(npc)
	-- navigationInit(npc)
	-- hearingInit(npc)
	-- stackInit(npc)

end

function npc_robot_update(npc, dt)

	UPRIGHT_STRENGTH 	= 1 * npc.proficiency	-- Spring strength
	UPRIGHT_MAX 		= 1 * npc.proficiency	-- Max spring force
	UPRIGHT_BASE 		= 1 * npc.proficiency	-- Fraction of max spring force to always apply (less springy)

	npc.robot.transform = GetBodyTransform(npc.Torso)

	if not IsControllerNPC(npc) then
		if npc.running then
			npc.robot.speed = FeetData.speed
		else
			npc.robot.speed = 0
		end
	end

	robotUpdate(npc, dt)
	-- wheelsUpdate(npc, dt)
	feetUpdate(npc, dt)
	hoverUpdate(npc, dt)
	-- headUpdate(npc, dt)
	-- sensorUpdate(npc, dt)
	-- aimsUpdate(npc, dt)
	-- weaponsUpdate(npc, dt)
	-- hearingUpdate(npc, dt)
	-- stackUpdate(npc, dt)

end


function robotSetAxes(npc)
	npc.robot.transform = GetBodyTransform(npc.robot.body)
	npc.robot.axes[1] = TransformToParentVec(npc.robot.transform, Vec(1, 0, 0))
	npc.robot.axes[2] = TransformToParentVec(npc.robot.transform, Vec(0, 1, 0))
	npc.robot.axes[3] = TransformToParentVec(npc.robot.transform, Vec(0, 0, 1))
end


function robotInit(npc)
	npc.robot.body = npc.Torso
	npc.robot.allBodies = npc.AllBodies
	npc.robot.allShapes = npc.AllShapes
	npc.robot.allJoints = npc.AllJoints
	-- npc.robot.roamTrigger = FindTrigger("roam")
	-- npc.robot.limitTrigger = FindTrigger("limit")
	-- npc.robot.investigateTrigger = FindTrigger("investigate")
	-- npc.robot.activateTrigger = FindTrigger("activate")
	-- if npc.robot.activateTrigger ~= 0 then
	-- 	SetTag(npc.robot.body, "inactive")
	-- end
	-- for i=1, #npc.robot.allBodies do
	-- 	npc.robot.initialBodyTransforms[i] = GetBodyTransform(npc.robot.allBodies[i])
	-- end
	robotSetAxes(npc)
end


function robotTurnTowards(npc, pos)
	npc.robot.dir = VecNormalize(VecSub(pos, npc.robot.transform.pos))
end


function robotSetDirAngle(npc, angle)
	npc.robot.dir[1] = math.cos(angle)
	npc.robot.dir[3] = math.sin(angle)
end


function robotGetDirAngle(npc)
	return math.atan2(npc.robot.dir[3], npc.robot.dir[1])
end


function robotUpdate(npc, dt)

	robotSetAxes(npc)

	npc.robot.playerPos = GetPlayerCameraTransform().pos

	local vel = GetBodyVelocity(npc.robot.body)
	local fwdSpeed = VecDot(vel, npc.robot.dir)
	local blocked = 0
	if npc.robot.speed > 0 and fwdSpeed > -0.1 then
		blocked = 1.0 - clamp(fwdSpeed/0.5, 0.0, 1.0)
	end
	npc.robot.blocked = npc.robot.blocked * 0.95 + blocked * 0.05

	--Always blocked if fall is detected
	if npc.sensor.detectFall > 0 then
		npc.robot.blocked = 1.0
	end

	--Evaluate mass every frame since robots can break
	npc.robot.mass = npc_get_mass(npc)*2 --= Keeps relative velocity constraint consistent.

	npc.robot.bodyCenter = TransformToParentPoint(npc.robot.transform, GetBodyCenterOfMass(npc.robot.body))
	npc.robot.navigationCenter = TransformToParentPoint(npc.robot.transform, Vec(0, -npc.hover.distTarget, 0))

	--Handle break all
	npc.robot.breakAllTimer = math.max(0.0, npc.robot.breakAllTimer - dt)
	if not npc.robot.breakAll and npc.robot.breakAllTimer > 0.0 then
		for i=1, #npc.robot.allShapes do
			SetTag(npc.robot.allShapes[i], "breakall")
		end
		npc.robot.breakAll = true
	end
	if npc.robot.breakAll and npc.robot.breakAllTimer <= 0.0 then
		for i=1, #npc.robot.allShapes do
			RemoveTag(npc.robot.allShapes[i], "breakall")
		end
		npc.robot.breakAll = false
	end

	--Distance and direction to player
	local pp = VecAdd(GetPlayerTransform().pos, Vec(0, 1, 0))
	local d = VecSub(pp, npc.robot.bodyCenter)
	npc.robot.distToPlayer = VecLength(d)
	npc.robot.dirToPlayer = VecScale(d, 1.0/npc.robot.distToPlayer)

	--Sense player if player is close and there is nothing in between
	-- npc.robot.canSensePlayer = false
	-- if npc.robot.distToPlayer < 3.0 then
	-- 	RejectAllBodies(npc.robot.allBodies)
	-- 	if not QueryRaycast(npc.robot.bodyCenter, npc.robot.dirToPlayer, npc.robot.distToPlayer) then
	-- 		npc.robot.canSensePlayer = true
	-- 	end
	-- end

	--Robot body sounds
	if npc.robot.enabled and npc.hover.contact > 0 then
		local vol
		vol = clamp(VecLength(GetBodyVelocity(npc.robot.body)) * 0.4, 0.0, 1.0)
		if vol > 0 then
			PlayLoop(walkLoop, npc.robot.transform.pos, vol)
		end

		vol = clamp(VecLength(GetBodyAngularVelocity(npc.robot.body)) * 0.4, 0.0, 1.0)
		if vol > 0 then
			PlayLoop(turnLoop, npc.robot.transform.pos, vol)
		end
	end
end


------------------------------------------------------------------------



function hoverInit(npc)

	local feet = { -->
		npc.LLLEG,
		npc.RRLEG,
	}

	if #feet > 0 then
		npc.hover.distTarget = 0
		for i=1, #feet do
			local ft = GetBodyTransform(feet[i])
			local fp = TransformToLocalPoint(npc.robot.transform, ft.pos)
			npc.hover.distTarget = math.max(npc.hover.distTarget, -fp[2])
		end
	else
		QueryRequire("physical large")
		RejectAllBodies(npc.robot.allBodies)
		local maxDist = 2.0

		local hit, dist = QueryRaycast(npc.robot.transform.pos, VecScale(npc.robot.axes[2], -1), maxDist)
		if hit then
			npc.hover.distTarget = dist
			npc.hover.distPadding = math.min(0.3, dist*0.5)
		end
	end
end


function hoverFloat(npc)
	if npc.hover.contact > 0 then
		local d = clamp(npc.hover.distTarget - npc.hover.currentDist, -0.2, 0.2)
		local v = d * 10
		local f = npc.hover.contact * math.max(0, d*npc.robot.mass*10.0) + npc.robot.mass*0.2
		ConstrainVelocity(npc.robot.body, npc.hover.hitBody, npc.robot.bodyCenter, Vec(0,1,0), v, 0 , f)
	end
end


UPRIGHT_STRENGTH 	= 1	-- Spring strength
UPRIGHT_MAX 		= 1	-- Max spring force
UPRIGHT_BASE 		= 1	-- Fraction of max spring force to always apply (less springy)
function hoverUpright(npc)
	local up = VecCross(npc.robot.axes[2], VecAdd(Vec(0,1,0)))
	npc.axes = {}
	npc.axes[1] = Vec(1,0,0)
	npc.axes[2] = Vec(0,1,0)
	npc.axes[3] = Vec(0,0,1)
	for a = 1, 3, 2 do
		local d = VecDot(up, npc.axes[a])
		local v = math.clamp(d * 25, -2, 2)
		local f = math.clamp(math.abs(d)*UPRIGHT_STRENGTH, -UPRIGHT_MAX, UPRIGHT_MAX)
		f = f + UPRIGHT_MAX * UPRIGHT_BASE
		f = f * npc.robot.mass
		f = f * npc.hover.contact
		-- f = 10000
		f = f * clamp(npc.proficiency, 0.5, 1)
		ConstrainAngularVelocity(npc.robot.body, npc.hover.hitBody, npc.axes[a], v, -f , f)
	end

end


function hoverTurn(npc)

	-- local fwd = VecScale(npc.robot.axes[3], -1)
	-- local c = VecCross(fwd, npc.robot.dir)
	-- local d = VecDot(c, npc.robot.axes[2])
	-- local angVel = clamp(d*10, -npc.config.turnSpeed * npc.robot.speedScale, npc.config.turnSpeed * npc.robot.speedScale) * 1000

	-- local curr = VecDot(npc.robot.axes[2], GetBodyAngularVelocity(npc.robot.body))
	-- angVel = curr + clamp(angVel - curr, -0.2*npc.robot.speedScale, 0.2*npc.robot.speedScale)

	-- local f = npc.robot.mass * npc.hover.contact * 1000
	-- ConstrainAngularVelocity(npc.robot.body, npc.hover.hitBody, npc.robot.axes[2], angVel * 50)

end


function hoverMove(npc, override_speed, direction, forceMult)

	forceMult = forceMult or 1

	local desiredSpeed = npc.robot.speed * npc.robot.speedScale * (npc.proficiency^1.5)

	if override_speed then desiredSpeed = override_speed end

	local axis = 3
	local opposite = 1
	local sign = -1
	if direction == "left" then
		opposite = 3
		axis = 1
	elseif direction == "right" then
		opposite = 3
		axis = 1
		sign = 1
	end

	local fwd = VecScale(npc.robot.axes[axis], sign)
	fwd[2] = 0

	fwd = VecNormalize(fwd)
	local currSpeed = VecDot(fwd, GetBodyVelocityAtPos(npc.robot.body, npc.robot.bodyCenter))
	local speed = currSpeed + clamp(desiredSpeed - currSpeed, -0.05*npc.robot.speedScale, 0.05*npc.robot.speedScale)
	local f = npc.robot.mass*0.2 * npc.hover.contact * forceMult

	if currSpeed < speed then
		ConstrainVelocity(npc.robot.body, npc.hover.hitBody, npc.robot.bodyCenter, fwd, speed, -f , f)
		ConstrainVelocity(npc.robot.body, npc.hover.hitBody, npc.robot.bodyCenter, npc.robot.axes[opposite], 0, -f * npc.proficiency , f * npc.proficiency)
	end

end


BALANCE_RADIUS = 0.5
function hoverUpdate(npc, dt)

	local dir = VecScale(npc.robot.axes[2], -1)

	--Shoot rays from four locations downwards
	local hit = false
	local dist = 0
	local normal = Vec(0,0,0)
	local shape = 0
	local samples = {}
	samples[#samples+1] = Vec(0,0,0)
	-- samples[#samples+1] = Vec(-BALANCE_RADIUS,0,0)
	-- samples[#samples+1] = Vec(BALANCE_RADIUS,0,0)
	-- samples[#samples+1] = Vec(0,0,BALANCE_RADIUS)
	-- samples[#samples+1] = Vec(0,0,-BALANCE_RADIUS)
	local castRadius = 0.1
	local maxDist = npc.hover.distTarget + npc.hover.distPadding
	for i=1, #samples do
		QueryRequire("physical large")
		RejectAllBodies(npc.robot.allBodies)
		RejectAllBodies(NPC_Bodies)
		local origin = TransformToParentPoint(npc.robot.transform, samples[i])
		local rhit, rdist, rnormal, rshape = QueryRaycast(origin, dir, maxDist, castRadius)
		if rhit then
			hit = true
			dist = dist + rdist + castRadius
			if rdist == 0 then
				--Raycast origin in geometry, normal unsafe. Assume upright
				rnormal = Vec(0,1,0)
			end
			if shape == 0 then
				shape = rshape
			else
				local b = GetShapeBody(rshape)
				local bb = GetShapeBody(shape)
				--Prefer new hit if it's static or has more mass than old one
				if not IsBodyDynamic(b) or (IsBodyDynamic(bb) and GetBodyMass(b) > GetBodyMass(bb)) then
					shape = rshape
				end
			end
			normal = VecAdd(normal, rnormal)
		else
			dist = dist + maxDist
		end
	end

	--Use average of rays to determine contact and height
	if hit then
		dist = dist / #samples
		normal = VecNormalize(normal)
		npc.hover.hitBody = GetShapeBody(shape)
		if IsBodyDynamic(npc.hover.hitBody) and GetBodyMass(npc.hover.hitBody) < 300 then
			--Hack alert! Treat small bodies as static to avoid sliding and glitching around on debris
			npc.hover.hitBody = 0
		end
		npc.hover.currentDist = dist
		npc.hover.contact = clamp(1.0 - (dist - npc.hover.distTarget) / npc.hover.distPadding, 0.0, 1.0)
		npc.hover.contact = npc.hover.contact * math.max(0, normal[2])
	else
		npc.hover.hitBody = 0
		npc.hover.currentDist = maxDist
		npc.hover.contact = 0
	end

	--Limit body angular velocity magnitude to 10 rad/s at max contact
	if npc.hover.contact > 0 then
		local maxAngVel = 1
		local angVel = GetBodyAngularVelocity(npc.robot.body)
		local angVelLength = VecLength(angVel)
		if angVelLength > maxAngVel then
			SetBodyAngularVelocity(npc.robot.body, VecScale(maxAngVel / angVelLength))
		end
	end

	if npc.hover.contact > 0 then
		npc.hover.timeSinceContact = 0
	else
		npc.hover.timeSinceContact = npc.hover.timeSinceContact + dt
	end

	if npc.hover.timeSinceContact > 1 then
		npc_add_stun(npc, 0.5)
	end


	hoverFloat(npc)

	if #npc.nav.path <= 0 then
		npc_slow_down(npc, 2)
	else
		hoverMove(npc)
	end


	if config.goreai.turning then
		if npc.running then
			headTurnTowards(npc, npc.ai.navPos)
			robotTurnTowards(npc, npc.ai.navPos)
			npc_turn_towards(npc, npc.ai.navPos)
		else
			headTurnTowards(npc, npc.ai.lookPos)
			robotTurnTowards(npc, npc.ai.lookPos)
			npc_turn_towards(npc, npc.ai.lookPos)
		end
	end

	-- npc_keep_upright(npc)

end

function hoverGetUp(npc)
	local up = VecCross(npc.robot.axes[2], VecAdd(Vec(0,1,0)))
	npc.axes = {}
	npc.axes[1] = Vec(1,0,0)
	npc.axes[2] = Vec(0,1,0)
	npc.axes[3] = Vec(0,0,1)
	for a = 1, 3, 2 do
		local d = VecDot(up, npc.axes[a])
		local v = math.clamp(d * 15, -2, 2)
		local f = math.clamp(math.abs(d)*UPRIGHT_STRENGTH, -UPRIGHT_MAX, UPRIGHT_MAX)
		f = f + UPRIGHT_MAX * UPRIGHT_BASE
		f = f * npc.robot.mass
		ConstrainAngularVelocity(npc.robot.body, npc.hover.hitBody, npc.axes[a], v, -f , f)
	end
end


------------------------------------------------------------------------

function feetInit(npc)

	npc.feet = {}

	local f = { --.
		npc.LLLEG,
		npc.RRLEG,
	}

	for i=1, #f do
		local foot = {}
		foot.body = f[i]
		local t = GetBodyTransform(foot.body)
		local rayOrigin = TransformToParentPoint(t, Vec(0, 0.9, 0))
		local rayDir = TransformToParentVec(t, Vec(0, -1, 0))

		for index, footshape in ipairs(GetBodyShapes(foot.body)) do
			SetShapeCollisionFilter(footshape, 0, 0)
		end

		foot.lastTransform = TransformCopy(t)
		foot.targetTransform = TransformCopy(t)
		foot.candidateTransform = TransformCopy(t)
		foot.worldTransform = TransformCopy(t)
		foot.stepAge = 1
		foot.stepLifeTime = 1
		foot.localRestTransform = TransformToLocalTransform(npc.robot.transform, t)
		foot.localTransform = TransformCopy(foot.localRestTransform)
		foot.rayOrigin = TransformToLocalPoint(npc.robot.transform, rayOrigin)
		foot.rayDir = TransformToLocalVec(npc.robot.transform, rayDir)
		foot.rayDist = npc.hover.distTarget + npc.hover.distPadding
		foot.contact = true
		local mass = GetBodyMass(foot.body)
		foot.linForce = 30 * mass
		foot.angForce = 2 * mass
		local linScale, angScale = 1, 2
		foot.linForce = foot.linForce * linScale
		foot.angForce = foot.angForce * angScale
		npc.feet[i] = foot
	end
end

function feetUpdate(npc, dt)

	-- local vel = GetBodyVelocity(npc.robot.body)
	-- local velLength = VecLength(vel)
	-- local stepLength = clamp(velLength*1.5, 0.34, 1)
	-- local stepTime = math.min(stepLength / velLength * 0.5, 0.5)
	-- local stepHeight = stepLength * 0.3

	local ang = 1
	if #npc.nav.path >= 2 then

		local subY = 0
		local nextPathPoint = AutoVecSubsituteY(npc.nav.path[1], subY)

		ang = npc_movement_check_alignment(
			-- AutoVecSubsituteY(GetBodyVelocity(npc.Torso), subY),
			AutoVecSubsituteY(quat_to_dir(GetBodyTransform(npc.Torso).rot), subY),
			quat_to_dir(QuatLookAt(GetBodyTransform(npc.Torso).pos, nextPathPoint)))

		ang = (ang + 1) / 2
		ang = (ang * 0.5) + 0.5

		-- DebugWatchNPC(npc, "ang", ang)
		-- DebugLine(npc.nav.path[1], Vec(0, 10, 0))

	end


	local vel 			= VecScale(GetBodyVelocity(npc.robot.body), FeetData.vel_mult)
	local velLength 	= VecLength(vel) * FeetData.velLength_mult * clamp(npc.proficiency, 0.5, 1)
	local stepLength 	= clamp(velLength*1.5, FeetData.stepLengthMin * ang, FeetData.stepLengthMax * ang)
	local stepTime 		= math.min(stepLength / velLength * FeetData.stepTimeMult, FeetData.stepTimeMax * ang)
	local stepHeight	= stepLength * FeetData.stepHeightMult * clamp(npc.proficiency, 0.5, 1)


	local inStep = false
	for i=1, #npc.feet do

		local q = npc.feet[i].stepAge/npc.feet[i].stepLifeTime
		if npc.feet[i].stepLifeTime > stepTime then
			npc.feet[i].stepLifeTime = stepTime
		end
		if q < 0.8 then
			inStep = true
		end
	end

	for i=1, #npc.feet do
		local foot = npc.feet[i]

		if not inStep then
			--Find candidate footstep
			local tPredict = TransformCopy(npc.robot.transform)
			tPredict.pos = VecAdd(tPredict.pos, VecScale(VecLerp(VecScale(npc.robot.dir, npc.robot.speed), vel, 0.5), stepTime*1.5))
			local rayOrigin = TransformToParentPoint(tPredict, foot.rayOrigin)
			local rayDir = TransformToParentVec(tPredict, foot.rayDir)
			QueryRequire("physical large")
			RejectAllBodies(npc.robot.allBodies)
			RejectAllBodies(NPC_Bodies)
			local hit, dist, normal, shape = QueryRaycast(rayOrigin, rayDir, foot.rayDist)
			local targetTransform = TransformToParentTransform(npc.robot.transform, foot.localRestTransform)
			if hit then
				targetTransform.pos = VecAdd(rayOrigin, VecScale(rayDir, dist))
			end
			foot.candidateTransform = targetTransform
		end

		--Animate foot
		if npc.hover.contact > 0 then
			if foot.stepAge < foot.stepLifeTime then
				foot.stepAge = math.min(foot.stepAge + dt, foot.stepLifeTime)
				local q = foot.stepAge / foot.stepLifeTime
				q = q * q * (3.0 - 2.0 * q) -- smoothstep
				local p = VecLerp(foot.lastTransform.pos, foot.targetTransform.pos, q)
				p[2] = p[2] + math.sin(math.pi * q)*stepHeight
				local r = QuatSlerp(foot.lastTransform.rot, foot.targetTransform.rot, q)
				foot.worldTransform = Transform(p, r)
				foot.localTransform = TransformToLocalTransform(npc.robot.transform, foot.worldTransform)
				if foot.stepAge == foot.stepLifeTime then
					PlaySound(stepSound, p, 0.5, false)
				end
			end
			ConstrainPosition(foot.body, npc.robot.body, GetBodyTransform(foot.body).pos, foot.worldTransform.pos, 8, foot.linForce)
			ConstrainOrientation(foot.body, npc.robot.body, GetBodyTransform(foot.body).rot, foot.worldTransform.rot, 16, foot.angForce)

			-- DebugLine(npc.robot.transform.pos, foot.worldTransform.pos, 1,1,0, 1) --##
			-- DebugLine(npc.robot.transform.pos, foot.candidateTransform.pos, 1,0,0, 1) --##
		end

	end

	if not inStep then
		--Find best step candidate
		local bestFoot = 0
		local bestDist = 0
		for i=1, #npc.feet do
			local foot = npc.feet[i]
			local dist = VecLength(VecSub(foot.targetTransform.pos, foot.candidateTransform.pos))
			if dist > stepLength and dist > bestDist then
				bestDist = dist
				bestFoot = i
			end
		end
		--Initiate best footstep
		if bestFoot ~= 0 then
			local foot = npc.feet[bestFoot]
			foot.lastTransform = TransformCopy(GetBodyTransform(foot.body))
			foot.targetTransform = TransformCopy(foot.candidateTransform)
			foot.stepAge = 0
			foot.stepLifeTime = stepTime
		end
	end

end


------------------------------------------------------------------------

function headInit(npc)
	npc.head.body = npc.Head
	-- npc.head.eye = FindLight("eye")
	npc.head.joint = npc.headJoint
end

function headTurnTowards(npc, pos)
	npc.head.dir = VecNormalize(VecSub(pos, GetBodyTransform(npc.head.body).pos))
end

function headUpdate(npc, dt)

	local t = GetBodyTransform(npc.head.body)
	local fwd = TransformToParentVec(t, Vec(0, 0, -1))

	--Check if head can see player
	local et = GetLightTransform(npc.head.eye)
	local pp = VecCopy(npc.robot.playerPos)
	local toPlayer = VecSub(pp, et.pos)
	local distToPlayer = VecLength(toPlayer)
	toPlayer = VecNormalize(toPlayer)

	-- --Determine player visibility
	-- local playerVisible = false
	-- if npc.config.hasVision and npc.config.canSeePlayer then
	-- 	if distToPlayer < npc.config.viewDistance then	--Within view distance
	-- 		local limit = math.cos(npc.config.viewFov * 0.5 * math.pi / 180)
	-- 		if VecDot(toPlayer, fwd) > limit then --In view frustum
	-- 			RejectAllBodies(npc.robot.allBodies)
	-- 			QueryRejectVehicle(GetPlayerVehicle())
	-- 			if not QueryRaycast(et.pos, toPlayer, distToPlayer, 0, true) then --Not blocked
	-- 				playerVisible = true
	-- 			end
	-- 		end
	-- 	end
	-- end

	if npc.config.aggressive then
		playerVisible = true
	end

	--If player is visible it takes some time before registered as seen
	--If player goes out of sight, head can still see for some time second (approximation of motion estimation)
	if playerVisible then
		local distanceScale = clamp(1.0 - distToPlayer/npc.config.viewDistance, 0.5, 1.0)
		local angleScale = clamp(VecDot(toPlayer, fwd), 0.5, 1.0)
		local delta = (dt * distanceScale * angleScale) / (npc.config.visibilityTimer / 0.5)
		npc.head.seenTimer = math.min(1.0, npc.head.seenTimer + delta)
	else
		npc.head.seenTimer = math.max(0.0, npc.head.seenTimer - dt / npc.config.lostVisibilityTimer)
	end
	npc.head.canSeePlayer = (npc.head.seenTimer > 0.5)

	if npc.head.canSeePlayer then
		npc.head.lastSeenPos = pp
		npc.head.timeSinceLastSeen = 0
	else
		npc.head.timeSinceLastSeen = npc.head.timeSinceLastSeen + dt
	end

	if playerVisible and npc.head.canSeePlayer then
		npc.head.aim = math.min(1.0, npc.head.aim + dt / npc.config.aimTime)
	else
		npc.head.aim = math.max(0.0, npc.head.aim - dt / npc.config.aimTime)
	end

	if npc.config.triggerAlarmWhenSeen then
		local red = false
		if GetBool("level.alarm") then
			red = math.mod(GetTime(), 0.5) > 0.25
		else
			if playerVisible and IsPointAffectedByLight(npc.head.eye, pp) then
				red = true
				npc.head.alarmTimer = npc.head.alarmTimer + dt
				PlayLoop(chargeLoop, npc.robot.transform.pos)
				if npc.head.alarmTimer > npc.head.alarmTime and playerVisible then
					SetString("hud.notification", "Detected by npc.robot. Alarm triggered.")
					SetBool("level.alarm", true)
				end
			else
				npc.head.alarmTimer = math.max(0.0, npc.head.alarmTimer - dt)
			end
		end
		if red then
			SetLightColor(npc.head.eye, 1, 0, 0)
		else
			SetLightColor(npc.head.eye, 1, 1, 1)
		end
	end

	--Rotate head to npc.head.dir
	local fwd = TransformToParentVec(t, Vec(0, 0, -1))
	if playerVisible then
		headTurnTowards(npc, npc.ai.aimPos)
	end
	npc.head.dir = VecNormalize(npc.head.dir)
	--end
	local c = VecCross(fwd, npc.head.dir)
	local d = VecDot(c, npc.robot.axes[2])
	local angVel = clamp(d*10, -3, 3)
	local f = 100
	local mi, ma = GetJointLimits(npc.head.joint)
	local ang = GetJointMovement(npc.head.joint)
	if ang < mi+1 and angVel < 0 then
		angVel = 0
	end
	if ang > ma-1 and angVel > 0 then
		angVel = 0
	end

	ConstrainAngularVelocity(npc.head.body, npc.robot.body, npc.robot.axes[2], angVel, -f , f)

	local vol = clamp(math.abs(angVel)*0.3, 0.0, 1.0)
	if vol > 0 then
		PlayLoop(headLoop, npc.robot.transform.pos, vol)
	end
end

-- function truncateToGround(npc, pos)
-- 	rejectAllBodies(npc.robot.allBodies)
-- 	QueryRejectVehicle(GetPlayerVehicle())
-- 	local hit, dist = QueryRaycast(pos, Vec(0, -1, 0), 5, 0.2)
-- 	if hit then pos = VecAdd(pos, Vec(0, -dist, 0)) end
-- 	return pos
-- end


------------------------------------------------------------------------

function sensorInit(npc)
	npc.sensor = {}
	npc.sensor.blocked = 0
	npc.sensor.blockedLeft = 0
	npc.sensor.blockedRight = 0
	npc.sensor.detectFall = 0
end

function sensorGetBlocked(npc, dir, maxDist)
	dir = VecNormalize(VecAdd(dir, rndVec(0.3)))
	local origin = TransformToParentPoint(npc.robot.transform, Vec(0, 0.8, 0))
	QueryRequire("physical large")
	RejectAllBodies(npc.robot.allBodies)
	local hit, dist = QueryRaycast(origin, dir, maxDist)
	return 1.0 - dist/maxDist
end

function sensorDetectFall(npc)
	local dir = Vec(0, -1, 0)
	local lookAheadDist = 0.6 + clamp(VecLength(GetBodyVelocity(npc.robot.body))/6.0, 0.0, 0.6)
	local origin = TransformToParentPoint(npc.robot.transform, Vec(0, 0.5, -lookAheadDist))
	QueryRequire("physical large")
	RejectAllBodies(npc.robot.allBodies)
	local maxDist = npc.hover.distTarget + 1.0
	local hit, dist = QueryRaycast(origin, dir, maxDist, 0.2)
	return not hit
end

function sensorUpdate(npc, dt)
	local maxDist = npc.config.sensorDist
	local blocked = sensorGetBlocked(npc, TransformToParentVec(npc.robot.transform, Vec(0, 0, -1)), maxDist)
	if sensorDetectFall(npc) then
		npc.sensor.detectFall = 1.0
	else
		npc.sensor.detectFall = 0.0
	end
	npc.sensor.blocked = npc.sensor.blocked * 0.9 + blocked * 0.1

	local blockedLeft = sensorGetBlocked(npc, TransformToParentVec(npc.robot.transform, Vec(-0.5, 0, -1)), maxDist)
	npc.sensor.blockedLeft = npc.sensor.blockedLeft * 0.9 + blockedLeft * 0.1

	local blockedRight = sensorGetBlocked(npc, TransformToParentVec(npc.robot.transform, Vec(0.5, 0, -1)), maxDist)
	npc.sensor.blockedRight = npc.sensor.blockedRight * 0.9 + blockedRight * 0.1
end

------------------------------------------------------------------------

function npc_movement_check_alignment(velocity, direction)
    return VecDot(VecNormalize(velocity), VecNormalize(direction))
end
-- function npc_init_robot_config(npc)
-- 	npc.config = {}
-- 	npc.config.hasVision = false
-- 	npc.config.viewDistance = 25
-- 	npc.config.viewFov = 150
-- 	npc.config.canHearPlayer = false
-- 	npc.config.canSeePlayer = false
-- 	npc.config.patrol = false
-- 	npc.config.sensorDist = 5.0
-- 	npc.config.speed = 1
-- 	npc.config.turnSpeed = 2
-- 	npc.config.huntPlayer = false
-- 	npc.config.huntSpeedScale = 1
-- 	npc.config.avoidPlayer = false
-- 	npc.config.triggerAlarmWhenSeen = false
-- 	npc.config.visibilityTimer = 0.3 --Time player must be seen to be identified as enemy (ideal condition)
-- 	npc.config.lostVisibilityTimer = 5.0 --Time player is seen after losing visibility
-- 	npc.config.outline = 13
-- 	npc.config.aimTime = 5.0
-- 	npc.config.maxSoundDist = 100.0
-- 	npc.config.aggressive = false
-- 	npc.config.stepSound = "m"
-- 	npc.config.practice = false
-- end

-- function npc_init_robot_movement(npc)

-- 	npc.robot = {}

-- 	npc.robot.body = npc.Torso
-- 	npc.robot.transform = GetBodyTransform(npc.robot.body)
-- 	npc.robot.axes = {}
-- 	npc.robot.bodyCenter = npc.torsoPos
-- 	npc.robot.dir = Vec(0, 0, -1)
-- 	npc.robot.speed = 1
-- 	npc.robot.blocked = 0
-- 	npc.robot.mass = 0
-- 	npc.robot.initialBodyTransforms = {}
-- 	npc.robot.enabled = true
-- 	npc.robot.deleted = false
-- 	npc.robot.speedScale = 2
-- 	npc.robot.breakAll = false
-- 	npc.robot.breakAllTimer = 0
-- 	npc.robot.distToPlayer = 100
-- 	npc.robot.dirToPlayer = 0
-- 	npc.robot.roamTrigger = 0
-- 	npc.robot.limitTrigger = 0
-- 	npc.robot.investigateTrigger = 0
-- 	npc.robot.activateTrigger = 0
-- 	npc.robot.stunned = 0
-- 	npc.robot.outlineAlpha = 0
-- 	npc.robot.canSensePlayer = false
-- 	npc.robot.playerPos = Vec()

-- 	npc.robot.vel = GetBodyVelocity(npc.robot.body)
-- 	npc.robot.totalVel = VecLength(npc.robot.vel)

-- 	npc.hover = {}
-- 	npc.hover.hitBody = 0
-- 	npc.hover.contact = 0.0
-- 	npc.hover.distTarget = 1.3 --##
-- 	npc.hover.distTargetRunning = 1.3 --##
-- 	npc.hover.distPadding = 0
-- 	npc.hover.timeSinceContact = 0.0
-- 	npc.hover.min_shape_voxels = 20 -- Min voxels required to be a valid floor.


-- 	npc.hover.BALANCE_RADIUS = 0.5

-- 	-- npc.hover.UPRIGHT_STRENGTH = 2 -- Spring strength
-- 	-- npc.hover.UPRIGHT_MAX = 1 -- Max spring force
-- 	-- npc.hover.UPRIGHT_BASE = 0.1 -- Fraction of max spring force to always apply (less springy)

-- end

-- function npc_robot_update(npc, dt)

-- 	npc.robot.body = npc.Torso

-- 	npc.robot.transform = GetBodyTransform(npc.robot.body)
-- 	npc.robot.axes[1]   = TransformToParentVec(npc.robot.transform, Vec(1, 0, 0))
-- 	npc.robot.axes[2]   = TransformToParentVec(npc.robot.transform, Vec(0, 1, 0))
-- 	npc.robot.axes[3]   = TransformToParentVec(npc.robot.transform, Vec(0, 0, 1))

-- 	npc.robot.transform.pos          = AabbGetBodyCenterBottomPos(npc.Torso)
-- 	npc.robot.bodyCenter   = AabbGetBodyCenterPos(npc.robot.body)
-- 	npc.robot.vel          = GetBodyVelocity(npc.robot.body)
-- 	npc.robot.totalVel     = VecLength(npc.robot.vel)
-- 	npc.robot.mass         = npc_get_mass(npc)
-- 	npc.robot.dir          = DirLookAt(npc.robot.transform.pos, npc.ai.lookPos)


-- 	npc_hover_update(npc, dt)
-- 	npc_hover_upright(npc)
-- 	npc_hover_float(npc)
-- 	npc_hover_move(npc)

-- 	npc_feet_update(npc, dt)

-- 	if npc.running then
-- 		npc_turn_towards(npc, npc.ai.navPos)
-- 	else
-- 		npc_turn_towards(npc, npc.ai.lookPos)
-- 	end

-- 	DebugWatchNPC(npc, "npc.navigation.state", npc.navigation.state) --##
-- 	DebugWatchNPC(npc, "#npc.nav.path", #npc.nav.path) --##

-- end




-- function npc_hover_float(npc)
-- 	if npc.hover.contact > 0 then
-- 		local d = clamp(npc.hover.distTarget - npc.hover.currentDist, -0.2, 0.2)
-- 		local v = d * 10
-- 		local f = npc.hover.contact * math.max(0, d*npc.robot.mass) + npc.robot.mass*0.2
-- 		ConstrainVelocity(npc.robot.body, npc.hover.hitBody, npc.robot.bodyCenter, Vec(0,1,0), v, 0 , f)
-- 	end
-- end

-- UPRIGHT_STRENGTH = 1	-- Spring strength
-- UPRIGHT_MAX = 0			-- Max spring force
-- UPRIGHT_BASE = 0		-- Fraction of max spring force to always apply (less springy)
-- function npc_hover_upright(npc)
-- 	local up = VecCross(npc.robot.axes[2], VecAdd(Vec(0,1,0)))
-- 	axes = {}
-- 	axes[1] = Vec(1,0,0)
-- 	axes[2] = Vec(0,1,0)
-- 	axes[3] = Vec(0,0,1)
-- 	for a = 1, 3, 2 do
-- 		local d = VecDot(up, axes[a])
-- 		local v = math.clamp(d * 15, -2, 2)
-- 		local f = math.clamp(math.abs(d)*UPRIGHT_STRENGTH, -UPRIGHT_MAX, UPRIGHT_MAX)
-- 		f = f + UPRIGHT_MAX * UPRIGHT_BASE
-- 		f = f * npc.robot.mass
-- 		f = f * npc.hover.contact
-- 		-- f = 10000
-- 		ConstrainAngularVelocity(npc.robot.body, npc.hover.hitBody, axes[a], v, -f , f)
-- 	end
-- end

-- function npc_hover_turn(npc)

-- 	local fwd = VecScale(npc.robot.axes[3], -1)
-- 	local c = VecCross(fwd, npc.robot.dir)
-- 	local d = VecDot(c, npc.robot.axes[2])
-- 	local angVel = clamp(d*10, -npc.config.turnSpeed * npc.robot.speedScale, npc.config.turnSpeed * npc.robot.speedScale)

-- 	local curr = VecDot(npc.robot.axes[2], GetBodyAngularVelocity(npc.robot.body))
-- 	angVel = curr + clamp(angVel - curr, -0.2*npc.robot.speedScale, 0.2*npc.robot.speedScale)

-- 	local f = npc.robot.mass*0.5 * npc.hover.contact
-- 	ConstrainAngularVelocity(npc.robot.body, npc.hover.hitBody, npc.robot.axes[2], angVel, -f , f)

-- end

-- function npc_hover_move(npc)

-- 	local desiredSpeed = npc.robot.speed * npc.robot.speedScale
-- 	local fwd = VecScale(npc.robot.axes[3], -1)
-- 	fwd[2] = 0
-- 	fwd = VecNormalize(fwd)
-- 	local side = VecCross(Vec(0,1,0), fwd)
-- 	local currSpeed = VecDot(fwd, GetBodyVelocityAtPos(npc.robot.body, npc.robot.bodyCenter))
-- 	local speed = currSpeed + clamp(desiredSpeed - currSpeed, -0.05*npc.robot.speedScale, 0.05*npc.robot.speedScale)
-- 	local f = npc.robot.mass*0.2 * npc.hover.contact

-- 	ConstrainVelocity(npc.robot.body, npc.hover.hitBody, npc.robot.bodyCenter, fwd, speed, -f , f)
-- 	ConstrainVelocity(npc.robot.body, npc.hover.hitBody, npc.robot.bodyCenter, npc.robot.axes[1], 0, -f , f)

-- end

-- function npc_hover_update(npc, dt)

-- 	-- local dir = VecScale(npc.robot.axes[2], -1)
-- 	local dir = Vec(0,-1,0)
-- 	local p

-- 	--Shoot rays from four locations downwards
-- 	local hit = false
-- 	local dist = 0
-- 	local normal = Vec(0, 0, 0)
-- 	local shape = 0

-- 	local samples = {}
-- 	samples[#samples + 1] = Vec(0, 0, 0)
-- 	-- samples[#samples + 1] = Vec(-npc.hover.BALANCE_RADIUS, 0, 0)
-- 	-- samples[#samples + 1] = Vec(npc.hover.BALANCE_RADIUS, 0, 0)
-- 	-- samples[#samples + 1] = Vec(0, 0, npc.hover.BALANCE_RADIUS)
-- 	-- samples[#samples + 1] = Vec(0, 0, -npc.hover.BALANCE_RADIUS)

-- 	-- -- Keep only 2 random samples.
-- 	-- table.remove(samples, GetRandomIndex(samples))
-- 	-- table.remove(samples, GetRandomIndex(samples))
-- 	-- table.remove(samples, GetRandomIndex(samples))

-- 	if UPDATE % UPDATE_INTERVAL == 1 then

-- 		local castRadius = 0.2

-- 		-- Npc floats slightly higher while standing still.
-- 		local maxDist = ternary(npc.run,
-- 			npc.hover.distTargetRunning,
-- 			npc.hover.distTarget)

-- 		for i = 1, #samples do

-- 			QueryRequire("physical large")
-- 			RejectAllShapes(npc.AllShapes)
-- 			RejectAllBodies(BloodDrops)
-- 			RejectAllBodies(npc.AllBodies)
-- 			RejectAllBodies(NPC_Bodies)
-- 			local origin = TransformToParentPoint(npc.robot.transform, samples[i])
-- 			local rhit, rdist, rnormal, rshape = QueryRaycast(origin, dir, maxDist, castRadius)
-- 			if rhit then

-- 				hit = true

-- 				p = TransformToParentPoint(Transform(origin, DirToQuat(dir)), Vec(0, 0, rdist * -1))

-- 				dist = dist + rdist + castRadius
-- 				if rdist == 0 then
-- 					--Raycast origin in geometry, normal unsafe. Assume upright
-- 					rnormal = Vec(0, 1, 0)
-- 				end
-- 				if shape == 0 then
-- 					shape = rshape
-- 				else
-- 					local b = GetShapeBody(rshape)
-- 					local bb = GetShapeBody(shape)
-- 					--Prefer new hit if it's static or has more mass than old one
-- 					if not IsBodyDynamic(b) or (IsBodyDynamic(bb) and GetBodyMass(b) > GetBodyMass(bb)) then
-- 						shape = rshape
-- 					end
-- 				end
-- 				normal = VecAdd(normal, rnormal)
-- 			else
-- 				dist = dist + maxDist
-- 			end

-- 			if p and GetBool("savegame.mod.config.goreai.draw_debug") then
-- 				DebugLine(origin, p, 1, 1, 0, 1)
-- 			end

-- 		end


-- 		--Use average of rays to determine contact and height
-- 		if hit then

-- 			dist = dist / #samples
-- 			normal = VecNormalize(normal)
-- 			npc.hover.hitBody = GetShapeBody(shape)
-- 			if IsBodyDynamic(npc.hover.hitBody) and (GetBodyMass(npc.hover.hitBody) < 300) then
-- 				--Hack alert! Treat small bodies as static to avoid sliding and glitching around on debris
-- 				npc.hover.hitBody = 0
-- 			end
-- 			npc.hover.currentDist = dist
-- 			--npc.hover.contact = clamp(1.0 - (dist - npc.hover.distTarget) / npc.hover.distPadding, 0.0, 1.0)
-- 			npc.hover.contact = dist - npc.hover.distPadding
-- 			npc.hover.contact = npc.hover.contact * math.max(0, normal[2])

-- 		else

-- 			npc.hover.hitBody = 0
-- 			npc.hover.currentDist = maxDist
-- 			npc.hover.contact = 0

-- 		end

-- 		if npc.hover.contact > 0 then
-- 			npc.hover.timeSinceContact = 0
-- 		else
-- 			npc.hover.timeSinceContact = npc.hover.timeSinceContact + GetTimeStep()
-- 		end

-- 		-- -- if npc.hover.timeSinceContact > 0.5 and GetBodyVelocity(npc.Torso)[2] < 0 then
-- 		-- if not hit and GetBodyVelocity(npc.Torso)[2] < -0.5 and npc.hover.timeSinceContact > 1 then
-- 		-- 	npc.ai.stun.duration = npc.ai.stun.duration + 0.5
-- 		-- 	print("falling", sfnTime())
-- 		-- end

-- 		-- print("hit", hit, sfnTime(), "last hit", npc.hover.timeSinceContact)

-- 	end

-- end




-- function npc_init_robot_feet(npc)

-- 	npc.feet = {
-- 		npc.LLLEG,
-- 		npc.RRLEG,
-- 	}

-- 	for i=1, #npc.feet do

-- 		local foot = {}

-- 		foot.body = npc.feet[i]

-- 		local t                   = GetBodyTransform(foot.body)
-- 		local rayOrigin           = TransformToParentPoint(t, Vec(0, 1, 0))
-- 		local rayDir              = TransformToParentVec(t, Vec(0, -1, -1))

-- 		foot.lastTransform        = TransformCopy(t)
-- 		foot.targetTransform      = TransformCopy(t)
-- 		foot.candidateTransform   = TransformCopy(t)
-- 		foot.worldTransform       = TransformCopy(t)
-- 		foot.stepAge              = 1
-- 		foot.stepLifeTime         = 1
-- 		foot.localRestTransform   = TransformToLocalTransform(npc.robot.transform, t)
-- 		foot.localTransform       = TransformCopy(foot.localRestTransform)
-- 		foot.rayOrigin            = TransformToLocalPoint(npc.robot.transform, rayOrigin)
-- 		foot.rayDir               = TransformToLocalVec(npc.robot.transform, rayDir)
-- 		foot.rayDist              = npc.hover.distTarget + npc.hover.distPadding
-- 		foot.contact              = true
-- 		local mass                = GetBodyMass(foot.body)
-- 		foot.linForce             = 20 * mass
-- 		foot.angForce             = 1 * mass
-- 		local linScale, angScale  = 1, 1
-- 		foot.linForce             = foot.linForce * linScale
-- 		foot.angForce             = foot.angForce * angScale
-- 		npc.feet[i]               = foot

-- 	end

-- end

-- function npc_feet_update(npc, dt)

-- 	-- local vel = GetBodyVelocity(npc.robot.body)
-- 	-- local velLength = VecLength(vel)
-- 	-- local stepLength = clamp(velLength*1.5, 0.35, 1.1)
-- 	-- local stepTime = math.min(stepLength / velLength * 0.5, 0.5)
-- 	-- local stepHeight = stepLength * 0.4

-- 	local vel 			= VecScale(GetBodyVelocity(npc.robot.body), FeetData.vel_mult)
-- 	local velLength 	= VecLength(vel) * FeetData.velLength_mult
-- 	local stepLength 	= clamp(velLength*1.5, FeetData.stepLengthMin, FeetData.stepLengthMax)
-- 	local stepTime 		= math.min(stepLength / velLength * FeetData.stepTimeMult, FeetData.stepTimeMax)
-- 	local stepHeight	= stepLength * FeetData.stepHeightMult

-- 	local inStep = false
-- 	for i=1, #npc.feet do

-- 		local q = npc.feet[i].stepAge/npc.feet[i].stepLifeTime
-- 		if npc.feet[i].stepLifeTime > stepTime then
-- 			npc.feet[i].stepLifeTime = stepTime
-- 		end
-- 		if q < 0.8 then
-- 			inStep = true
-- 		end
-- 	end

-- 	for i=1, #npc.feet do

-- 		local foot = npc.feet[i]

-- 		if not inStep then

-- 			--Find candidate footstep
-- 			local tPredict = TransformCopy(npc.robot.transform)
-- 			tPredict.pos = VecAdd(tPredict.pos, VecScale(VecLerp(VecScale(quat_to_dir(npc.robot.transform.rot), npc.robot.speed), vel, 0.5), stepTime*-1.5))
-- 			local rayOrigin = TransformToParentPoint(tPredict, foot.rayOrigin)
-- 			local rayDir = TransformToParentVec(tPredict, foot.rayDir)
-- 			QueryRequire("physical large")
-- 			RejectAllBodies(npc.AllBodies)
-- 			RejectAllShapes(npc.AllShapes)
-- 			local hit, dist, normal, shape = QueryRaycast(rayOrigin, rayDir, foot.rayDist)
-- 			local targetTransform = TransformToParentTransform(npc.robot.transform, foot.localRestTransform)
-- 			if hit then
-- 				targetTransform.pos = VecAdd(rayOrigin, VecScale(rayDir, dist))
-- 				DrawDot(targetTransform.pos, 1/4,1/4, 1,0,0, 1)
-- 				DrawShapeOutline(shape, 1,0,0, 1)
-- 			end
-- 			foot.candidateTransform = targetTransform
-- 		end

-- 		--Animate foot
-- 		if npc.hover.contact > 0 then
-- 			if foot.stepAge < foot.stepLifeTime then
-- 				foot.stepAge = math.min(foot.stepAge + dt, foot.stepLifeTime)
-- 				local q = foot.stepAge / foot.stepLifeTime
-- 				q = q * q * (3.0 - 2.0 * q) -- smoothstep
-- 				local p = VecLerp(foot.lastTransform.pos, foot.targetTransform.pos, q)
-- 				p[2] = p[2] + math.sin(math.pi * q)*stepHeight
-- 				local r = QuatSlerp(foot.lastTransform.rot, foot.targetTransform.rot, q)
-- 				foot.worldTransform = Transform(p, r)
-- 				foot.localTransform = TransformToLocalTransform(npc.robot.transform, foot.worldTransform)
-- 				-- if foot.stepAge == foot.stepLifeTime then --todo Add footstep sound
-- 				-- 	PlaySound(stepSound, p, 0.5, false)
-- 				-- end
-- 			end

-- 			ConstrainPosition(foot.body, npc.robot.body, GetBodyTransform(foot.body).pos, foot.worldTransform.pos, 8, foot.linForce)
-- 			ConstrainOrientation(foot.body, npc.robot.body, GetBodyTransform(foot.body).rot, foot.worldTransform.rot, 16, foot.angForce)



-- 			DebugLine(npc.robot.transform.pos, foot.worldTransform.pos, 1,1,0, 1) --##
-- 			DebugLine(npc.robot.transform.pos, foot.candidateTransform.pos, 1,0,0, 1) --##

-- 		end

-- 	end

-- 	if not inStep then
-- 		--Find best step candidate
-- 		local bestFoot = 0
-- 		local bestDist = 0
-- 		for i=1, #npc.feet do
-- 			local foot = npc.feet[i]
-- 			local dist = VecLength(VecSub(foot.targetTransform.pos, foot.candidateTransform.pos))
-- 			if dist > stepLength and dist > bestDist then
-- 				bestDist = dist
-- 				bestFoot = i
-- 			end
-- 		end
-- 		--Initiate best footstep
-- 		if bestFoot ~= 0 then
-- 			local foot = npc.feet[bestFoot]
-- 			foot.lastTransform = TransformCopy(GetBodyTransform(foot.body))
-- 			foot.targetTransform = TransformCopy(foot.candidateTransform)
-- 			foot.stepAge = 0
-- 			foot.stepLifeTime = stepTime
-- 		end
-- 	end

-- end




function npc_keep_upright(npc)

    local rot = TransformCopy(npc.torsoTr.rot)

    local dir = Vec(GetQuatEuler(rot)) --todo Make slight dynamic bobbing
    dir[1] = 0
    dir[3] = 0

    rot = dir_to_quat(dir)
	-- local vel = GetBodyVelocity(npc.Torso)
	-- local tVel = VecLength(vel)

    ConstrainOrientation(npc.Torso, 0, npc.torsoTr.rot, rot)

end

function npc_turn_towards(npc, pos)

	local tr = GetBodyTransform(npc.Torso)
	local rot = QuatLookAt(
		tr.pos,
		AutoVecSubsituteY(pos or Vec(0,0,0), tr.pos[2]))


	local dir = Vec(GetQuatEuler(rot)) --todo Make slight dynamic bobbing
	dir[1] = 0
	dir[3] = 0

	ConstrainOrientation(npc.Torso, 0, tr.rot, rot, 10)

end



function npc_run_assist(npc)

	local pos          = AutoVecSubsituteY(npc.torsoPos, 0)
	local vel          = AutoVecSubsituteY(GetBodyVelocity(npc.Torso), 0)
	local nextPathNode = npc.nav.path[1]


	local ang = quat_angle(
		QuatLookAt(pos, VecAdd(pos, vel)),
		QuatLookAt(pos, VecAdd(pos, nextPathNode)))


	if ang > 0.5 then
		local scale = ang
		npc_slow_down(npc, scale)
	end

end

function npc_stand_still(npc)

	npc.run = false
	npc.running = false
	npc.ai.moving = false

	-- npc_align_feet_torso(npc)

end


--- NPC stands in one spot and stops cacccccccccccccccccccccccccccccccccccccring about life.
function npc_stand_idle(npc)

	npc_stand_still(npc)
	npc_stop_attacking(npc)

	npc.nav.path = {}
	npc.ai.navPos = npc.robot.transform.pos
	npc.ai.lookPos = TransformToParentPoint(npc.torsoTr, Vec(0,0,-10))

end

function npc_run_to_target_pos(npc)
	npc.run = true
	npc.running = true
	npc.ai.lookPos = VecCopy(npc.ai.navPos)
end

--- Slow down zx velocity. Mainly to stop sliding.
function npc_slow_down(npc, scale)

	local vel = GetBodyVelocity(npc.Torso)
	local tvel = VecLength(vel) -- High vel will make it harder to slow down, like changing 1m/s to 20m/s when hit by a vehicle.
	if tvel > npc.ai.stun.velocity then
		return
	end

	scale = scale or 1
	if tvel > 0.2 then
		ApplyBodyImpulse(npc.Torso, npc.torsoPos, VecScale(vel, -npc.mass_start/50 * scale))
	end

end

function npc_align_feet_torso(npc)

	for index, foot in ipairs(npc.feet) do
		local footRot = GetBodyTransform(foot.body).rot
		ConstrainOrientation(foot.body, 0, footRot, npc.torsoTr.rot)
	end

	local legRot = GetBodyTransform(npc.RRLEG).rot
	ConstrainOrientation(npc.RRLEG, 0, legRot, npc.torsoTr.rot)

	legRot = GetBodyTransform(npc.LLLEG).rot
	ConstrainOrientation(npc.LLLEG, 0, legRot, npc.torsoTr.rot)

end

function npc_strafing_process(npc)

	if not TimerConsumed(npc.ai.strafing.timer_check) and npc.ai.strafing.side ~= "none" then
		hoverMove(npc, npc.ai.strafing.speed, npc.ai.strafing.side, 0.5)
	end

end

function npc_strafing_check(npc)

	-- DebugWatch("timer_move", npc.ai.strafing.timer_move.time)
	-- DebugWatch("timer_check", npc.ai.strafing.timer_check.time)
	-- DebugWatch("side", npc.ai.strafing.side)
	-- DebugWatch("speed", npc.ai.strafing.speed)

	TimerRunTime(npc.ai.strafing.timer_move)
	TimerRunTime(npc.ai.strafing.timer_check, nil, ternary(TimerConsumed(npc.ai.strafing.timer_move), 1, 2))

    if TimerConsumed(npc.ai.strafing.timer_check) then
        TimerResetTime(npc.ai.strafing.timer_check, math.random())

		-- todo fix
        -- local torsoTr = GetBodyTransform(npc.Torso)

        -- local p_left = TransformToParentPoint(torsoTr, Vec(-0.8, 0, 0))
        -- local p_right = TransformToParentPoint(torsoTr, Vec(0.8, 0, 0))

        -- local tr_left = Transform(p_left, QuatLookAt(torsoTr.pos, TransformToParentPoint(torsoTr, Vec(-1, 0, 0))))
        -- local tr_right = Transform(p_right, QuatLookAt(torsoTr.pos, TransformToParentPoint(torsoTr, Vec(1, 0, 0))))

        -- local h_left, _, _, _, d_left = RaycastFromTransform(tr_left, npc.ai.strafing.raycast_dist, 1, NPC_Bodies)
        -- local h_right, _, _, _, d_right = RaycastFromTransform(tr_right, npc.ai.strafing.raycast_dist, 1, NPC_Bodies)

		-- if config.goreai.draw_debug then
		-- 	DebugRay(tr_left, npc.ai.strafing.raycast_dist, 1,0,0, 1)
		-- 	DebugRay(tr_right, npc.ai.strafing.raycast_dist, 1,0,0, 1)
		-- end

		-- if not TimerConsumed(npc.ai.strafing.timer_move) and (h_left or h_right) then -- stop strafing if hit wall
		-- 	npc.ai.strafing.timer_move.time = 0
		-- 	print("strafe cancelled")
		-- 	return
		-- end

		local sides = { "left", "right", "none" }
        local side = GetRandomArrayValue(sides)
        -- if not (h_left or h_right) then
        --     side = GetRandomArrayValue({"left", "right"}) -- random side
        -- elseif h_left and h_right then
        --     side = ternary(d_left > d_right, "left", "right") -- side with furthest hit dist 
        -- elseif h_left then
        --     side = "left"
        -- elseif h_right then
        --     side = "right"
        -- end

		if npc.ai.strafing.side ~= "none" and side == npc.ai.strafing.side then -- avoid constant strafe to one side
			npc.ai.strafing.side = "none"
		else
			npc.ai.strafing.side = side
		end

		TimerResetTime(npc.ai.strafing.timer_move,  math.random() + 0.75)
		npc.ai.strafing.speed = 2 + math.random() * 1.75

    end

end

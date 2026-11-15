function npc_init_navigation(npc)

	-- Creates a magic table that allows easy cross-script variable sharing. 
	npc.navigation = util.structured_table("level.goreai.nav_api." .. npc.id, get_npc_api_nav_table())
	-- npc.navigation = {}


	local npc_nav_api_reg = "level.nav_api_tables." .. npc.id
	npc.nav = {
		reg = {
			tb_path = npc_nav_api_reg .. "path",
			tb_startPos = npc_nav_api_reg .. "startPos",
			tb_target = npc_nav_api_reg .. "target",
			robot_pos = npc_nav_api_reg .. "robot_pos",
		}
	}

	-- npc.navigation.state = "done"
	npc.nav.path = {}
	npc.nav.target = Vec()
	setRegTable(npc.nav.reg.tb_target, npc.nav.target)
	setRegTable(npc.nav.reg.tb_startPos, npc.robot.transform.pos)
	-- npc.navigation.hasNewTarget = false
	-- npc.navigation.resultRetrieved = true
	-- npc.navigation.deviation = 0 -- Distance to path
	-- npc.navigation.blocked = 0
	-- npc.navigation.unblockTimer = 0 -- Timer that ticks up when blocked. If reaching limit, unblock kicks in and timer resets
	-- npc.navigation.unblock = 0 -- If more than zero, navigation is in unblock mode (reverse direction)
	-- npc.navigation.vertical = 0
	-- npc.navigation.thinkTime = 0
	-- npc.navigation.timeout = 3
	-- npc.navigation.lastQueryTime = 0
	-- npc.navigation.timeSinceProgress = 0
	-- npc.navigation.pathType = "standard"

	-- npc.navigation.targetRadius        = 1 -- How close the last node will be to the target.
	-- npc.navigation.pathSpacing         = 1.5 -- Spacing between nav nodes.
	-- npc.navigation.minDistToPath       = npc.navigation.pathSpacing*3 -- Recalc nav path if too far from next node
	-- npc.navigation.PATH_NODE_TOLERANCE = npc.navigation.pathSpacing/2 -- Dist to node to progress to next node.

end

function npc_navigation_update(npc, dt)

	npc.navigation.timeSinceProgress = npc.navigation.timeSinceProgress or 0

	-- (2026-11-15, NPC performance) v1 serialized robot_pos and startPos into the registry every update (60 Hz per
	-- npc). The path script (goreai_initializer.lua) reads robot_pos only when it starts a path and computes
	-- startPos from it itself, so robot_pos is written when the npc moved 0.5 m (the path start is snapped to the
	-- ground anyway) or after a world shift, and startPos not at all.
	local p = npc.robot.transform.pos
	if not npc.nav.robotPosSent or MapMoved or VecDist(npc.nav.robotPosSent, p) > 0.5 then
		setRegTable(npc.nav.reg.robot_pos, p)
		npc.nav.robotPosSent = VecCopy(p)
	end

	-- Reposition nav points if procedural scripts moves the map.
	if MapMoved then
		for index, point in ipairs(npc.nav.path) do -- nav points
			for i = 1, 3 do npc.nav.path[index][i] = npc.nav.path[index][i] + MapMoveVec[i] end -- must add components. magic tables do not support loops.
		end

		for i = 1, 3 do npc.ai.navPos[i] = npc.ai.navPos[i] + MapMoveVec[i] end -- must add components. magic tables do not support loops.
		for i = 1, 3 do npc.nav.target[i] = npc.nav.target[i] + MapMoveVec[i] end -- must add components. magic tables do not support loops.

		setRegTable(npc.nav.reg.tb_target, npc.nav.target)

		return
	end

	if npc.navigation.newPath then
		npc.nav.path = getRegTable(npc.nav.reg.tb_path)
		npc_navigationPrunePath(npc)
		npc.navigation.newPath = false
		npc.navigation.resultRetrieved = true
		return
	end

	if npc.navigation.timeSinceProgress > 5 then
		npc_clear_navigation(npc)
	end

	npc_navigationMove(npc, dt)


	if npc.navigation.GetPathState ~= "busy" and #npc.nav.path == 0 and not npc.navigation.hasNewTarget then
		if npc.navigation.GetPathState == "done" or npc.navigation.GetPathState == "idle" then
			npc.navigation.state = "done"
		else
			npc.navigation.state = "fail"
		end
	end

end


--Prune path backwards so robot don't need to go backwards
function npc_navigationPrunePath(npc)
	if #npc.nav.path > 0 then
		for i = #npc.nav.path, 1, -1 do
			local p = npc.nav.path[i]
			-- local dv = VecSub(p, torsoPos)
			local dv = VecSub(p, npc.robot.transform.pos)
			local d = VecLength(dv)
			if d < npc.navigation.PATH_NODE_TOLERANCE then
				--Keep everything after this node and throw out the rest
				local newPath = {}
				for j = i, #npc.nav.path do
					newPath[#newPath + 1] = npc.nav.path[j]
				end
				npc.nav.path = newPath
				return
			end
		end
	end
end

function npc_navigationClear(npc)

	-- AbortPath()
	npc.navigation.input_AbortPath = true

	npc.navigation.state = "done"
	npc.nav.path = {}
	npc.navigation.hasNewTarget = false
	npc.navigation.resultRetrieved = true
	npc.navigation.deviation = 0
	npc.navigation.blocked = 0
	npc.navigation.unblock = 0
	npc.navigation.vertical = 0
	npc.nav.target = Vec(0, -100, 0)
	setRegTable(npc.nav.reg.tb_target, npc.nav.target)
	npc.navigation.thinkTime = 0
	npc.navigation.lastQueryTime = 0
	npc.navigation.unblockTimer = 0
	npc.navigation.timeSinceProgress = 0
	npc.navigation.pathType = "standard"

end

function npc_navigationSetTarget(npc, pos, timeout)
	pos = truncateToGround(pos, npc.AllBodies)
	if VecDist(npc.nav.target, pos) > 0.5 then
		npc.nav.target = VecCopy(pos)
		setRegTable(npc.nav.reg.tb_target, npc.nav.target)
		npc.navigation.hasNewTarget = true
		npc.navigation.state = "move"
	end
	npc.navigation.timeout = timeout
	npc.navigation.timeSinceProgress = 0
end

function npc_navigationMove(npc, dt)

	-- if #npc.nav.path > 0 then
	-- 	npc.robot.speed = 1
	-- else
	-- 	npc.robot.speed = 0
	-- end

	if #npc.nav.path > 0 then

		if npc.navigation.resultRetrieved then
			--If we have a finished path and didn't progress along it for five seconds, recompute
			--Should probably only do this for a limited time until giving up
			npc.navigation.timeSinceProgress = npc.navigation.timeSinceProgress + GetTimeStep()
			if npc.navigation.timeSinceProgress > 5.0 then --*npcconfig
				npc.navigation.hasNewTarget = true
				npc.nav.path = {}
			end
		end

		local target = npc.nav.path[1]
		-- local dv = VecSub(target, robot.navigationCenter)
		local dv = VecSub(target, npc.robot.transform.pos)
		npc.ai.lookPos = target
		npc.ai.navPos = target
		local distToFirstPathPoint = VecLength(dv)
		dv[2] = 0
		local d = VecLength(dv)
		if distToFirstPathPoint < npc.navigation.minDistToPath then
			if d < npc.navigation.PATH_NODE_TOLERANCE then
				if #npc.nav.path > 1 then
					--Measure verticality which should decrease speed
					local diff = VecSub(npc.nav.path[2], npc.nav.path[1])
					npc.navigation.vertical = diff[2] / (VecLength(diff) + 0.001)
					--Remove the first one
					local newPath = {}
					for i = 2, #npc.nav.path do
						newPath[#newPath + 1] = npc.nav.path[i]
					end
					npc.nav.path = newPath
					npc.navigation.timeSinceProgress = 0
				else
					--We're done
					npc.nav.path = {}
					return
				end

			end
		else
			-- Went off path, scrap everything and recompute
			npc.navigation.hasNewTarget = true
			-- npc.nav.path = {}
			-- print("off path")
		end

	else
		-- ai.lookPos = navigation.target
		npc.ai.navPos = npc.nav.target
	end

end

function truncateToGround(pos, rejectBodies)
	RejectAllBodies(rejectBodies or {})
	QueryRejectVehicle(GetPlayerVehicle(GoreP)) -- (v2 goreai) target player
	local hit, dist = QueryRaycast(pos, Vec(0, -1, 0), 5, 0.2)
	if hit then
		return VecAdd(pos, Vec(0, -dist, 0))
	end
	return false
end


function roundPath(vectors, numSegments)

	if #vectors < 2 or numSegments < 1 then
		return vectors -- Not enough vectors or segments to round the path
	end

	local roundedVectors = {}
	roundedVectors[1] = vectors[1] -- Keep the first vector as is

	for i = 2, #vectors do
		local prevVector = vectors[i - 1]
		local currentVector = vectors[i]

		for j = 1, numSegments do
			local t = j / (numSegments + 1) -- Interpolation parameter
			local interpolatedVector = {
				prevVector[1] + (currentVector[1] - prevVector[1]) * t,
				prevVector[2] + (currentVector[2] - prevVector[2]) * t
			}
			table.insert(roundedVectors, interpolatedVector)
		end

		roundedVectors[#roundedVectors + 1] = currentVector -- Keep the current vector as is
	end

	return roundedVectors

end
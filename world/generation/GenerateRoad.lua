#version 2
#include "script/include/player.lua"
-- (v2) server: road generation, world shift (moves ALL players), distance; registry keys read by clients are synced.
-- (v2, Phase 3) Co-op: the FURTHEST living player drives generation, the world shift and the distance counter
-- (GetGenerationPlayerPos); players far behind are teleported up to the leader (TeleportStragglers).
--[[
#include "../../lib/Automatic.lua"
#include "../../lib/Settings.lua"
#include "../../lib/TDSU/tdsu.lua"
#include "EnemySpawnsProcessor.lua"
]]

-- #include "GenerateRoad_Reuse.lua"

reg_map_move_vec = "level.map_move_vec" -- concatenated vec string


function server.init()

	Init_Settings()

	differentRoads={
		[""]=5,
		["M"]=7,
		["L"]=2,
		["B"]=1,
		["S"]=1,
	}
	chanceforlargesegment = 1
	chanceforblocksegment = 2
	chanceformediumsegment = 31
	chanceforsandegment = 6

	Distfornewroad = 200
	RoadSegments = 0
	if GetString("savegame.mod.difficulty") == "hardcore" then
		difficulty = 0.1
	else
		difficulty = 1
	end
	bb = 0
	debugyea = false
	maxragdolls = 5
	spawntim = 0
	Roadsegmentz = 5

	point = FindLocation("pointOreturn", true)

	PlayerZ = GetGenerationPlayerPos()[1]
	PlayerZStart = GetGenerationPlayerPos()[1] - GetFloat("savegame.mod.distanceProgressed")
	Returns = 0
	DistanceProgressed = GetFloat("savegame.mod.distanceProgressed")

	Bodies_NoDelete = FindBodies("nodelete", true)

	ManageVegDeleting(FindShapes("veg", true))

	DELETED = 0
	if GetString("savegame.mod.difficulty") == "hardcore" then
		chanceforsafe = math.random(8,14)
	else
		chanceforsafe = 10
	end

	TICK = 1
end

function server.update(dt)

	TICK = TICK + 1

	if GetBool("savegame.mod.procedural.disable.spawn_road_segments") then
		return
	end

	-- if GetBool("level.reset_distanceProgressed") then
	-- 	DistanceProgressed = 0
	-- 	SetFloat("savegame.mod.distanceProgressed", 0)
	-- 	SetBool("level.reset_distanceProgressed", false)
	-- else
	-- 	SetFloat("savegame.mod.distanceProgressed", DistanceProgressed)
	-- end

	local segmentType = ""

	local NewRoads = FindTriggers("PuzzlePiece", true)
	if GetBool('Level.Debug')then
		DebugWatch("#NewRoads", #NewRoads)
	end
	if not GetBool("level.roadgen")then
		for i=1, #NewRoads do
			local NewRoadTrans = GetTriggerTransform(NewRoads[1])
			local DistToPlayer = NewRoadTrans.pos[1] - GetGenerationPlayerPos()[1]
			if DistToPlayer < Distfornewroad then
				if GetBool('Level.Debug')then DebugPrint(GetTime().." ----------SPAWNING SEGMENT----------")end
				if GetBool('Level.Debug')then DebugPrint(GetTime().." player at: "..VecStr(playerPos))end
				Delete(NewRoads[i])
				local spawnedEntities
				local spawnCountOverride
				if Roadsegmentz < chanceforsafe then
					local Type=""
					local generates = math.random(1,100)
					if generates <= chanceforlargesegment then
						Type = "L"
					elseif generates <= chanceforblocksegment and DistanceProgressed >= 2000 and not GetBool("savegame.mod.procedural.disable.spawn_special_segments") then
						Type = "B"
					elseif generates <= chanceformediumsegment and not GetBool("savegame.mod.procedural.disable.spawn_special_segments") then
						Type = "M"
					elseif generates <= chanceforsandegment then
						Type = "S"
					else
						Type = ""
					end
					segmentType = Type
					local whichone = math.random(1,differentRoads[Type])
					local roadXML = "MOD/prefabs/spawnables/roadsegments/RoadSegment" .. Type .. whichone ..".xml"
					if GetString("savegame.mod.difficulty") ~= "nightmare" then
						spawnedEntities = Spawn(roadXML, NewRoadTrans, true)
					else
						spawnedEntities = Spawn("MOD/prefabs/spawnables/roadsegments/RoadSegment2.xml", NewRoadTrans, true)
					end
					ManageVegDeleting(spawnedEntities)
					if Type == "M" and whichone == 6 then
						spawnCountOverride = 6
					end
				else
					spawnedEntities = Spawn("MOD/prefabs/spawnables/roadsegments/RoadSegmentH.xml", NewRoadTrans, true)
					SetBool("inventory.refreshshop", true, true)
					ManageVegDeleting(spawnedEntities)
					Roadsegmentz = 0
					if GetString("savegame.mod.difficulty") == "hardcore" then
						chanceforsafe = math.random(8,22)
					else
						chanceforsafe = 10
					end
				end
				if GetBool('Level.Debug')then DebugPrint(GetTime().." spawned segment")end
	
				for _, v in ipairs(FindLocations("special", true)) do
					if GetTagValue(v, "special") == "town"
					or GetTagValue(v, "special") == "um_base"
					then
						spawnCountOverride = math.random(4,6)
					end
				end
	
				RegisterSegmentScripts(spawnedEntities) -- (v2 perf) see TickSegmentScripts
				ProcessEnemySpawns(spawnedEntities, spawnCountOverride)
	
				SetBool("level.roadgen", true)
				if GetBool('Level.Debug')then DebugPrint(GetTime().." mark new segment spawned")end
				--SetBool("level.spawnstuff", true)
				--SetBool("level.fuelgen", true) --? Is this meant to be disabled? -- sake of supporting vehicle spawning from runtime, plus we have roadgen, so stop makig another 5 billion reg keys
				RoadSegments = RoadSegments + 1
				Roadsegmentz = Roadsegmentz + 1
				if GetBool('Level.Debug')then DebugPrint(GetTime().." ----------SPAWNED  SEGMENT----------")end
			end
	
		end
	else
		if GetBool('Level.Debug') and GetBool('level.roadgen')then DebugPrint(GetTime().." -- Resetted segment spawn key --")end
		SetBool("level.roadgen", false)
	end

	if not stopall then
		bb = bb + dt
		difficultycoef = ((1 + bb) * RoadSegments)/(difficulty * 500)
		if difficultycoef > 6 then
			difficultycoef = 6
		end
	end

	SetInt("level.distancetraveled",RoadSegments, true)
	SetInt("level.difficultycoef",difficultycoef, true)
	--DebugPrint("Difficulty: "..difficultycoef)
	--DebugPrint("RoadSegments: "..RoadSegments)

	ReturnToShadowVolume()
	TeleportStragglers(dt)
	TickSegmentScripts()

	if InputDown('d') and InputDown('e') and InputDown('b') and InputDown('u') and InputPressed('g') then
		debugyea = not debugyea
		SetBool('Level.Debug',debugyea)
	end
	if debugyea then
		local triggers = FindTriggers("",true)
		local locations = FindLocations("",true)
		local lights = FindLights("",true)
		local bodies = FindBodies("",true)
		local shapes = FindShapes("",true)
		local joints = FindJoints("",true)
		local screens = FindScreens("",true)
		local vehicles = FindVehicles("",true)
		--difficultycoef = 0.01
		DebugWatch("Triggers", #triggers)
		DebugWatch("Locations", #locations)
		DebugWatch("Lights", #lights)
		DebugWatch("Bodies", #bodies)
		DebugWatch("Shapes", #shapes)
		DebugWatch("Joints", #joints)
		DebugWatch("Screens", #screens)
		DebugWatch("Vehicles", #vehicles)
	end

	--[[ if GetBool("level.spawnstuff") == true then
		spawntim = spawntim + dt
		if spawntim > 0.2 then
			SetBool("level.spawnstuff", false)
			spawntim = 0
		end
	end ]]

	-- local roadgen = tostring(GetBool("level.roadgen"))  .. ": " .. segmentType
	-- local p = GetVehicleTransform(GetPlayerVehicle()).pos
	-- print("Tick = " .. TICK, "V = " .. GetPlayerVehicle() .. ", " .. "HV = " .. tostring(IsHandleValid(GetPlayerVehicle())), "RSV: " .. tostring(GetBool("level.map_moved")) .. "  ", "RDGN: " .. roadgen .. "  ",  sfn(p[1]), sfn(p[2]), sfn(p[3]))

end


function ReturnToShadowVolume()

	local pointTrans = GetLocationTransform(point)
	local disttopoint = pointTrans.pos[1] - GetGenerationPlayerPos()[1]

	local shiftDist = 200
	if disttopoint < shiftDist then
		if GetBool('Level.Debug')then DebugPrint(GetTime().." ----------RETURN  SHADOW  VOLUME----------")end
		if GetBool('Level.Debug')then DebugPrint(GetTime().." player at: "..VecStr(GetGenerationPlayerPos()))end

		SetFloat(reg_map_move_vec .. ".1", -shiftDist, true)
		SetFloat(reg_map_move_vec .. ".2", 0, true)
		SetFloat(reg_map_move_vec .. ".3", 0, true)

		SetBool("level.map_moved", true, true)
		local bodies = FindBodies("",true)
		for i=1, #bodies do
			local body = bodies[i]
			local bodyT = GetBodyTransform(body)
			bodyT.pos[1] = bodyT.pos[1]-shiftDist
			SetBodyTransform(body, bodyT)
		end

		local triggers = FindTriggers("", true)
		for i=1, #triggers do
			local trigger = triggers[i]
			local triggerT = GetTriggerTransform(trigger)
			triggerT.pos[1] = triggerT.pos[1]-shiftDist
			SetTriggerTransform(trigger, triggerT)
		end

		-- (v2) every player is shifted with the world (agreed co-op design); players in a vehicle move with it
		for p in Players() do
			if GetPlayerVehicle(p)==0 then
				local playerT = GetPlayerTransformWithPitch(p)
				local playerVel = GetPlayerVelocity(p)
				playerT.pos[1] = playerT.pos[1]-shiftDist
				SetPlayerTransformWithPitch(playerT, p)
				SetPlayerVelocity(playerVel, p)
				if GetBool('Level.Debug')then DebugPrint(GetTime().." player "..p.." not in vehicle, teleported")end
			else
				if GetBool('Level.Debug')then DebugPrint(GetTime().." player "..p.." in vehicle, vehicle should be teleported with player")end
			end
		end
		Returns = Returns + 1
		SetInt("level.world_shifts", GetInt("level.world_shifts") + 1, true) -- (v2) for movers (debug auto-travel)
		-- (v2) positions read in the shift frame (and the next) can still be the unshifted ones, which made the
		-- distance 200 m too high for a frame; with the never-decreasing counter that froze it for 200 m.
		DistanceSkipFrames = 2

		if GetBool('Level.Debug')then DebugPrint(GetTime().." teleported everything by: "..shiftDist)end
		if GetBool('Level.Debug')then DebugPrint(GetTime().." player now at: "..VecStr(GetGenerationPlayerPos()))end
		if GetBool('Level.Debug')then DebugPrint(GetTime().." ----------RETURNED SHADOW VOLUME----------")end
	else
		SetBool("level.map_moved", false, true)

		SetFloat(reg_map_move_vec .. ".1", 0, true)
		SetFloat(reg_map_move_vec .. ".2", 0, true)
		SetFloat(reg_map_move_vec .. ".3", 0, true)
	end


	local PlayerZ = GetGenerationPlayerPos()[1]
	local totalReturnDist = Returns * shiftDist
	-- (v2) never decreases: the leading player can change (dies, leaves, falls behind). Not updated right after a
	-- world shift (see DistanceSkipFrames).
	if (DistanceSkipFrames or 0) > 0 then
		DistanceSkipFrames = DistanceSkipFrames - 1
	else
		DistanceProgressed = math.max(DistanceProgressed or 0, clamp(PlayerZ - PlayerZStart + totalReturnDist, 0, math.huge))
	end

	if GetBool("level.reset_distanceProgressed") then
		PlayerZStart = GetGenerationPlayerPos()[1]
		Returns = 0
		DistanceProgressed = 0
	end

	SetFloat("savegame.mod.distanceProgressed", ternary(GetBool("level.reset_distanceProgressed"), 0, DistanceProgressed), true)

	SetBool("level.reset_distanceProgressed", false)

end


-- (v2) The player whose position drives road generation, the world shift and the distance counter:
-- the living player furthest along the road (+x); if nobody is alive, the furthest player.
function GetGenerationPlayer()
	local best, bestX, bestAlive = nil, -math.huge, false
	for p in Players() do
		local x = GetPlayerTransform(p).pos[1]
		local alive = GetPlayerHealth(p) > 0
		if (alive and not bestAlive) or (alive == bestAlive and x > bestX) then
			best, bestX, bestAlive = p, x, alive
		end
	end
	return best
end

function GetGenerationPlayerPos()
	local p = GetGenerationPlayer()
	if p == nil then return GetPlayerTransform(0).pos end
	return GetPlayerTransform(p).pos
end

-- (v2) Stragglers: a living player more than STRAGGLER_DIST behind the leader (along the road, x) for
-- STRAGGLER_TIME seconds is put just behind the leader, on the ground. A player in a vehicle is moved with it.
-- The playable world is ~400 m long (shadow volume) and RemoveRoad deletes things 250 m behind the rearmost
-- player, so everyone stays well inside both.
STRAGGLER_DIST = 150
STRAGGLER_TIME = 3
StragglerTimers = {}

function TeleportStragglers(dt)
	local leader = GetGenerationPlayer()
	if leader == nil then return end
	local leaderPos = GetPlayerTransform(leader).pos
	local slot = 0
	local seen = {}
	for p in Players() do
		seen[p] = true
		local behind = leaderPos[1] - GetPlayerTransform(p).pos[1]
		if p ~= leader and GetPlayerHealth(p) > 0 and behind > STRAGGLER_DIST then
			StragglerTimers[p] = (StragglerTimers[p] or 0) + dt
			if StragglerTimers[p] >= STRAGGLER_TIME then
				slot = slot + 1
				TeleportPlayerBehind(p, leaderPos, slot)
				StragglerTimers[p] = 0
			end
		else
			StragglerTimers[p] = 0
		end
	end
	for p in pairs(StragglerTimers) do
		if not seen[p] then StragglerTimers[p] = nil end
	end
end

-- Ground position 8 m behind pos (x), side by side per slot (z), found by a raycast down.
function StragglerTarget(pos, slot)
	local side = (slot % 2 == 1) and 1 or -1
	local target = Vec(pos[1] - 8, pos[2], pos[3] + side * 3 * math.ceil(slot / 2))
	local from = VecAdd(target, Vec(0, 30, 0))
	local hit, dist = QueryRaycast(from, Vec(0, -1, 0), 80)
	if hit then target[2] = from[2] - dist end
	return target
end

function TeleportPlayerBehind(p, leaderPos, slot)
	local target = StragglerTarget(leaderPos, slot)
	local vehicle = GetPlayerVehicle(p)
	if vehicle ~= 0 then
		local body = GetVehicleBody(vehicle)
		local t = GetBodyTransform(body)
		SetBodyTransform(body, Transform(VecAdd(target, Vec(0, 2, 0)), t.rot))
		SetBodyVelocity(body, Vec())
		SetBodyAngularVelocity(body, Vec())
	else
		local t = GetPlayerTransform(p)
		SetPlayerTransform(Transform(VecAdd(target, Vec(0, 0.5, 0)), t.rot), p)
		SetPlayerVelocity(Vec(), p)
	end
	if GetBool('Level.Debug') then DebugPrint(GetTime().." straggler "..p.." teleported behind the leader") end
end

--- (v2 perf 2026-11-07) Scripts that come with a road segment (vehicles, doors, shops, rotating props, ...) kept
--- running after RemoveRoad deleted the segment behind the players (scripts 106 → 219 in 5 km). Remember each
--- segment's scripts and world objects (from Spawn's result); once none of its bodies / shapes / vehicles / triggers
--- is left, delete its scripts. Works however the scripts are nested in the prefab xml.
SegmentGroups = {}
function RegisterSegmentScripts(entities)
	local group = { scripts = {}, anchors = {} }
	for _, e in ipairs(entities or {}) do
		local t = GetEntityType(e)
		if t == "script" then
			group.scripts[#group.scripts + 1] = e
		elseif t == "body" or t == "shape" or t == "vehicle" or t == "trigger" then
			group.anchors[#group.anchors + 1] = e
		end
	end
	if #group.scripts > 0 and #group.anchors > 0 then SegmentGroups[#SegmentGroups + 1] = group end
end

function TickSegmentScripts()
	if GetTime() < (SegmentGroupsNext or 0) then return end
	SegmentGroupsNext = GetTime() + 1
	for i = #SegmentGroups, 1, -1 do
		local group = SegmentGroups[i]
		local alive = false
		for _, a in ipairs(group.anchors) do
			if IsHandleValid(a) then alive = true break end
		end
		if not alive then
			for _, s in ipairs(group.scripts) do
				if IsHandleValid(s) then Delete(s) end
			end
			table.remove(SegmentGroups, i)
		end
	end
end

-- Check and delete shapes tagged "veg" after spawning a road segement.
function ManageVegDeleting(spawed_entities)
	-- local deletes = 0
	for i = 1, #spawed_entities do
		local ent = spawed_entities[i]
		--DebugPrint(GetEntityType(ent))
		if GetEntityType(ent) == "shape" then
			if HasTag(ent, "veg") then
				if GetString("savegame.mod.difficulty") == "nightmare" then
					Delete(ent)
				else
					if math.random() < Settings.performance.visual.foliage_percentage.value/2 then
						-- deletes = deletes + 1
						Delete(ent)
					end
					--[[ if #GetBodyShapes(GetShapeBody(ent)) <= 0 then -- Delete empty bodies.
						Delete(GetShapeBody(ent))
					end ]]
				end
			end
		end
	end
end
function server.handleCommand(cmd) HandleQuickload(cmd) end
function HandleQuickload(cmd)
	for _, word in ipairs(splitString(cmd, " ")) do
		if word == "quickload" then
			Init_Settings()
		end
		break
	end
end
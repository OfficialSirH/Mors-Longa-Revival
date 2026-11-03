--[[
#include "../Automatic.lua"
#include "../Settings.lua"
#include "../scripts/TDSU/tdsu.lua"
#include "EnemySpawnsProcessor.lua"
]]

-- #include "GenerateRoad_Reuse.lua"

reg_map_move_vec = "level.map_move_vec" -- concatenated vec string


function init()

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

	PlayerZ = GetPlayerTransform().pos[1]
	PlayerZStart = GetPlayerTransform().pos[1] - GetFloat("savegame.mod.distanceProgressed")
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

function update(dt)

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
			local DistToPlayer = NewRoadTrans.pos[1] - GetPlayerTransform().pos[1]
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
					SetBool("inventory.refreshshop", true)
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

	SetInt("level.distancetraveled",RoadSegments)
	SetInt("level.difficultycoef",difficultycoef)
	--DebugPrint("Difficulty: "..difficultycoef)
	--DebugPrint("RoadSegments: "..RoadSegments)

	ReturnToShadowVolume()

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
	local disttopoint = pointTrans.pos[1] - GetPlayerTransform().pos[1]

	local shiftDist = 200
	if disttopoint < shiftDist then
		if GetBool('Level.Debug')then DebugPrint(GetTime().." ----------RETURN  SHADOW  VOLUME----------")end
		if GetBool('Level.Debug')then DebugPrint(GetTime().." player at: "..VecStr(GetPlayerTransform().pos))end

		SetFloat(reg_map_move_vec .. ".1", -shiftDist)
		SetFloat(reg_map_move_vec .. ".2", 0)
		SetFloat(reg_map_move_vec .. ".3", 0)

		SetBool("level.map_moved", true)
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

		if GetPlayerVehicle()==0 then
			local playerT = GetPlayerTransform(true)
			local playerVel = GetPlayerVelocity()
			playerT.pos[1] = playerT.pos[1]-shiftDist
			SetPlayerTransform(playerT, true)
			SetPlayerVelocity(playerVel)
			if GetBool('Level.Debug')then DebugPrint(GetTime().." player not in vehicle, teleported")end
		else
			if GetBool('Level.Debug')then DebugPrint(GetTime().." player in vehicle, vehicle should be teleported with player")end
		end
		Returns = Returns + 1

		if GetBool('Level.Debug')then DebugPrint(GetTime().." teleported everything by: "..shiftDist)end
		if GetBool('Level.Debug')then DebugPrint(GetTime().." player now at: "..VecStr(GetPlayerTransform().pos))end
		if GetBool('Level.Debug')then DebugPrint(GetTime().." ----------RETURNED SHADOW VOLUME----------")end
	else
		SetBool("level.map_moved", false)

		SetFloat(reg_map_move_vec .. ".1", 0)
		SetFloat(reg_map_move_vec .. ".2", 0)
		SetFloat(reg_map_move_vec .. ".3", 0)
	end


	local PlayerZ = GetPlayerTransform().pos[1]
	local totalReturnDist = Returns * shiftDist
	DistanceProgressed = clamp(PlayerZ - PlayerZStart + totalReturnDist, 0, math.huge)

	if GetBool("level.reset_distanceProgressed") then
		PlayerZStart = GetPlayerTransform().pos[1]
		Returns = 0
	end

	SetFloat("savegame.mod.distanceProgressed", ternary(GetBool("level.reset_distanceProgressed"), 0, DistanceProgressed))

	SetBool("level.reset_distanceProgressed", false)

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
function handleCommand(cmd) HandleQuickload(cmd) end
function HandleQuickload(cmd)
	for _, word in ipairs(splitString(cmd, " ")) do
		if word == "quickload" then
			Init_Settings()
		end
		break
	end
end
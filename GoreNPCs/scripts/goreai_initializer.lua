#version 2
--[[
#include "../../scripts/TDSU/tdsu.lua"
#include "./systems/goreai_API_nav.lua"
#include "../../scripts/masterScriptRemoverAPI.lua"
]]


--================================================================================================================================
-- All entities of the ragdoll must be inside of this script.
-- This script initializes the tags for the goreai constructor to find and create the gore npc.
--================================================================================================================================
-- (v2 goreai) Server only: tags, collision filter, shape merging, spawning the manager script (goreai_main.lua)
-- once, and this npc's path queries (QueryPath), exchanged with goreai_main through the registry
-- (level.goreai.nav_api.<id>, level.nav_api_tables.<id>*). Nothing runs on clients.


function server.init()

	check_script_exists()

	ID = GetInt("level.gore_id") -- This int can always be used as the current ID.
	if ID == 0 then
		ID = 1
	end
	SetInt("level.gore_id", ID + 1) -- Increment ID for each gore npc.

	-- Tag name.
	IDTag = "gore_id"

	-- Apply IDs
	apply_entity_ids(ID)
	merge_extra_shapes()


	npc = {}
	npc.navigation = util.structured_table("level.goreai.nav_api." .. ID, get_npc_api_nav_table())


	local npc_nav_api_reg = "level.nav_api_tables." .. ID
	npc.nav = {
		reg = {
			tb_path = npc_nav_api_reg .. "path",
			tb_startPos = npc_nav_api_reg .. "startPos",
			tb_target = npc_nav_api_reg .. "target",
			robot_pos = npc_nav_api_reg .. "robot_pos",
		}
	}

	isDead = false
	MyTorso = FindBody("Torso") -- (v2 perf) see server.tick

end

function server.tick(dt)

	-- remove script when npc is dead.
	-- (v2) v1 queueRemoval() registered a pause menu button to find its own script handle; that does not work
	-- on the server, so the script just stops working once its npc is dead.
	if Finished then return end
	if GetBool("level.goreai.api.npcs.dead_id." .. ID) then
		Finished = true
		return
	end
	-- (v2 perf 2026-11-07) also stop once the npc's torso is gone (RemoveRoad deleted it behind the players);
	-- v1 kept these scripts reading/writing the registry every tick for the rest of the run.
	if MyTorso ~= 0 and not IsHandleValid(MyTorso) then
		Finished = true
		return
	end

	npc.navigation.GetPathState = GetPathState()

	if npc.navigation.input_AbortPath then
		AbortPath()
		npc.navigation.input_AbortPath = false
		return
	end

	if npc.navigation.GetPathState == "busy" then
		npc.navigation.timeSinceProgress = 0
		npc.navigation.thinkTime = npc.navigation.thinkTime + GetTimeStep()
		if npc.navigation.thinkTime > npc.navigation.timeout then
			AbortPath()
			return
		end
	end

	if npc.navigation.GetPathState ~= "busy" then
		if npc.navigation.GetPathState == "done" or npc.navigation.GetPathState == "fail" then
			if not npc.navigation.resultRetrieved then
				npc.navigation.GetPathLength = GetPathLength()

				local path = {}
				if npc.navigation.GetPathLength >= 1 then
					for l = npc.navigation.pathSpacing, npc.navigation.GetPathLength, npc.navigation.pathSpacing do
						path[#path + 1] = GetPathPoint(l)
					end
				end

				-- print("path:")
				-- for index, value in ipairs(path) do
				-- 	print(index, table.concat(value, ", "))
				-- end

				setRegTable(npc.nav.reg.tb_path, path)

				npc.navigation.lastQueryTime = npc.navigation.thinkTime
				npc.navigation.resultRetrieved = true
				npc.navigation.state = "move"
				npc.navigation.newPath = true
				-- npc_navigationPrunePath(npc)
			end
		end
		npc.navigation.thinkTime = 0
	end

	if npc.navigation.hasNewTarget then

		local startPos = truncateToGround(util.unserialize(GetString(npc.nav.reg.robot_pos)))
		setRegTable(npc.nav.reg.tb_startPos, startPos)

		local target = truncateToGround(getRegTable(npc.nav.reg.tb_target))
		setRegTable(npc.nav.reg.tb_target, target)

		QueryRequire("physical large")
		-- RejectAllBodies(npc.AllBodies)
		-- RejectAllBodies(NPC_Bodies)
		-- QueryPath(startPos, target, 150, npc.navigation.targetRadius)

		-- print()
		-- print("startPos", table.concat(startPos, ", "))
		-- print("target  ", table.concat(target, ", "))
		QueryPath(startPos, target)

		npc.navigation.timeSinceProgress = 0
		npc.navigation.hasNewTarget = false
		npc.navigation.resultRetrieved = false
		npc.navigation.state = "move"
	end


	npc.navigation.GetPathState = GetPathState()

end

function apply_entity_ids(ID)

	AllEntities = {
		AllBodies    = FindBodies(""),
		AllShapes    = FindShapes(""),
		AllLights    = FindLights(""),
		AllJoints    = FindJoints(""),
		AllLocations = FindLocations(""),
		AllTriggers  = FindTriggers(""),
	}

	for _, entity_group in pairs(AllEntities) do
		for _, entity in ipairs(entity_group) do
			SetTag(entity, IDTag, ID)
		end
	end

	-- No intercollisions, but leave world collision on.
	for _, shape in ipairs(AllEntities.AllShapes) do
		if GetShapeBody(shape) ~= GetWorldBody() then
			SetShapeCollisionFilter(shape, 4, 255-4)
		end
	end

end

function merge_extra_shapes()

	local head = FindBody("Head")
	local HEAD_EXTRAS = FindShapes("HEAD_EXTRAS")
	for _, shape in ipairs(HEAD_EXTRAS) do
		SetShapeBody(shape, head, TransformToLocalTransform(GetBodyTransform(head), GetShapeWorldTransform(shape)))
	end

	local torso = FindBody("Torso")
	local TORSO_EXTRAS = FindShapes("TORSO_EXTRAS")
	for _, shape in ipairs(TORSO_EXTRAS) do
		SetShapeBody(shape, torso, TransformToLocalTransform(GetBodyTransform(torso), GetShapeWorldTransform(shape)))
	end

end

--- Spawns the main script only once.
--- The main script will handle all newly spawned gore npcs once they are initialized by the goreai_initializer script.
function check_script_exists()
	if not GetBool("level.goreai_script_exists") then
		local xml = '<script file="MOD/GoreNPCs/scripts/goreai_main.lua"/>'
		-- (v2) tag the manager "nodelete" (never removed by cleanup code)
		for _, e in ipairs(Spawn(xml, Transform(), true) or {}) do
			if GetEntityType(e) == "script" then SetTag(e, "nodelete") end
		end
		SetBool("level.goreai_script_exists", true)
	end
end


-- (v2) no handleCommand/quickload in v2; handle_quickload below is unused.

function handle_quickload(cmd)
	for _, word in ipairs(splitString(cmd, " ")) do
		if word == "quickload" then

			-- Clear existing npc data so main script can reinitialize them.

			SetInt("level.gore_id", 1)

			for index, torso in ipairs(FindBodies("Torso", false)) do
				RemoveTag(torso, "npc_initialized")
			end

			server.init()

		end
		break
	end
end

--[[
#include "../../scripts/TDSU/tdsu.lua"
#include "./systems/goreai_API_nav.lua"
#include "../../scripts/masterScriptRemoverAPI.lua"
]]


--================================================================================================================================
-- All entities of the ragdoll must be inside of this script.
-- This script initializes the tags for the goreai constructor to find and create the gore npc.
--================================================================================================================================


function init()

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

end

function tick(dt)

	-- remove script when npc is dead.
	if GetBool("level.goreai.api.npcs.dead_id." .. ID) then
		queueRemoval()
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
		Spawn(xml, Transform(), true)
		SetBool("level.goreai_script_exists", true)
	end
end


function handleCommand(cmd)
	handle_quickload(cmd)
end

function handle_quickload(cmd)
	for _, word in ipairs(splitString(cmd, " ")) do
		if word == "quickload" then

			-- Clear existing npc data so main script can reinitialize them.

			SetInt("level.gore_id", 1)

			for index, torso in ipairs(FindBodies("Torso", false)) do
				RemoveTag(torso, "npc_initialized")
			end

			init()

		end
		break
	end
end

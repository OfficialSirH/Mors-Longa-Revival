function ProcessEnemySpawns(entities, spawnCountOverride)

	local enemyLocs = {} -- All enemy spawn locations of the building.

	-- Find nemy locations in spawned entities.
	for index, entity in ipairs(entities) do
		if GetEntityType(entity) == "location" then
			if HasTag(entity, "RandomRagdoll") then
				table.insert(enemyLocs, entity)
			end
		end
	end

	local spawnLocs = {} -- List of valid spawn locs
	local enemyLocsCount = #enemyLocs or 2

	local maxSpawnsCount = GetInt("level.spawning.maxSpawnsPerBuidling")
	if maxSpawnsCount == 0 then
		maxSpawnsCount = 2
	end

	if spawnCountOverride then
		maxSpawnsCount = spawnCountOverride
	end


	-- print(maxSpawnsCount)

	-- if math.random() < 0.2 then -- Leave some empty buldings.

	-- 	for _, loc in ipairs(enemyLocs) do Delete(loc) end -- Delete all locations because we are ignoring this building.

	-- else

		-- Add maxSpawns number of unique spawn locs.
		if enemyLocsCount > maxSpawnsCount then

			-- Populate usableSpawns
			local usableSpawns = {}
			for i = 1, enemyLocsCount do usableSpawns[i] = { enemyLocsIndex = i } end

			for i = 1, maxSpawnsCount do

				local rdm = math.random(1, #usableSpawns)
				local spawnLocIndex = usableSpawns[rdm].enemyLocsIndex
				table.insert(spawnLocs, enemyLocs[spawnLocIndex])
				table.remove(usableSpawns, rdm)

			end

			-- Find extra spawns to delete.
			local spawnsToDelete = {}
			for _, enemyLoc in ipairs(enemyLocs) do

				-- Check buildings spawns.
				local markSpawnForDeletion = true
				for _, spawnLoc in ipairs(spawnLocs) do
					if enemyLoc == spawnLoc then -- Spawn is in the spawnLocs list.
						markSpawnForDeletion = false -- Keep the spawn.
						break
					end
				end

				-- Mark the extra spawn to delete and delete them after the loop.
				if markSpawnForDeletion then
					table.insert(spawnsToDelete, enemyLoc)
				end

			end

			for _, spawn in ipairs(spawnsToDelete) do
				Delete(spawn) -- Delete location entity of extra spawn.
			end

		end

	-- end

end

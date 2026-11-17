-- (2026-11-14, performance) One spawn per frame across the generation spawners (RandomBuilding, RandomEnemy,
-- RandomLoot, RandomVehicle, RandomRoadSign, RandomDeceasedBurnt). When a segment's pieces are all in, every
-- spawner used to handle all of its markers in the same frame (debug readout: vehicle, road sign, decor, loot
-- within 0.1 s). A spawner checks SpawnSlotFree() before each marker and stops for this frame when another spawn
-- happened; TakeSpawnSlot() after spawning. level.frame is GenerateRoad's frame counter (server.tick); without it
-- (levels without road generation) the slot is always free.
-- (2026-11-17) level.spawn.gap (option "Segment Loading Pace", GenerateRoad.lua SpawnGap): the slot is free again
-- only that many frames after the last spawn (1 = the next frame, as before).
function SpawnSlotFree()
	local frame = GetInt("level.frame")
	if frame == 0 then return true end
	local gap = math.max(1, GetInt("level.spawn.gap"))
	return frame - GetInt("level.spawn.slot") >= gap
end

function TakeSpawnSlot()
	SetInt("level.spawn.slot", GetInt("level.frame"))
end

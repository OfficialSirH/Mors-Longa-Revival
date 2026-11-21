#version 2
#include "script/include/player.lua"
-- (2026-11-17, DEBUG) collector probe / skip switch, off unless level.debug.* is set (lib/GcProbe.lua)
#include "../../lib/GcProbe.lua"
DL_LABEL = "RemoveRoad"  -- crash breadcrumbs (lib/DeleteLog.lua)
#include "../../lib/DeleteLog.lua"
GCP_LABEL = "removeroad"
-- (v2) server: deletes what is far behind the REARMOST player (nothing near any player), never a car a player is in.
-- Scripts that came with deleted road segments are removed by GenerateRoad (TickSegmentScripts): in v2 a script
-- cannot be linked to its objects (GetEntityChildren / GetEntityParent return nothing for scripts, 2026-11-07).
--
-- (2026-11-15, performance; user: "everything should be gradual and continuous") v1 deleted everything more than
-- deletionDist behind in ONE pass after each new segment (a whole segment's shapes in one frame). Now a continuous
-- sweep: every frame it checks up to SWEEP_SCAN objects of the current phase (shapes -> bodies -> triggers -> joints
-- -> vehicles, each phase listed once with Find*) and deletes at most SWEEP_DELETE of them, so a far segment
-- disappears a few objects per frame shortly after its parts cross the distance. Same rules as v1 per object:
--   (2026-11-15) none of them while in its spawn grace time (InGrace: vehicle events)
--   shape: not "nodelete", more than deletionDist behind (x) the rearmost player: its whole bounds (2026-11-15)
--   body (not a vehicle's): not "nodelete", that far behind, and none of its shapes left
--   vehicle: not "nodelete", every body without shapes, no player in it
--   trigger: not "nodelete", that far behind
--   joint: none of its shapes left
-- In the frames right after a world shift positions can be half-updated (bodies moved, players not yet: see
-- GenerateRoad DistanceSkipFrames), which would make near objects look 200 m further behind: the sweep waits.

SWEEP_SCAN = 200          -- objects checked per frame (600 cost 0.57 ms in Teardown's profiler; a pass over ~10k
                          -- shapes now takes ~50 frames, fine for things already 250 m behind)
SWEEP_DELETE = 120        -- objects deleted per frame at most
SHIFT_WAIT_FRAMES = 3     -- frames without deleting after a world shift
CLEANUP_GRACE = 90        -- (2026-11-15) seconds a body / trigger tagged "ml_grace" (vehicle events, spawned behind
                          -- and driving in: RandomVehicleEnemy.lua) is kept even when it is far behind

--- true while h (body or trigger) is in its spawn grace time
function InGrace(h)
	if not HasTag(h, "ml_grace") then return false end
	return GetTime() - (tonumber(GetTagValue(h, "ml_grace")) or 0) < CLEANUP_GRACE
end

function server.init()
	deletionDist = 250
	vList = {} -- no easy way to get all vehicle body, so this will have to do
	Sweep = { phase = 0, list = {}, i = 1 }
	LastShifts = GetInt("level.world_shifts")
	ShiftWait = 0
end

local PHASES = { "shapes", "bodies", "triggers", "joints", "vehicles" }

function server.tick()
	local shifts = GetInt("level.world_shifts")
	if shifts ~= LastShifts then
		LastShifts = shifts
		ShiftWait = SHIFT_WAIT_FRAMES
	end
	if ShiftWait > 0 then
		ShiftWait = ShiftWait - 1
		return
	end
	local rearmostX = RearmostPlayerX()
	-- (v2 fix 2026-11-07) no players found (e.g. the first frames of a level, before the player is registered):
	-- "rearmost player" would be infinitely far ahead and EVERYTHING would be deleted (whole level, tool bodies).
	if rearmostX == nil then return end
	SweepStep(rearmostX, SWEEP_SCAN, SWEEP_DELETE)
end

--- One frame of the sweep: check up to `scan` objects, delete at most `maxDelete`. Returns the number deleted.
function SweepStep(rearmostX, scan, maxDelete)
	SweepRearX = rearmostX
	local deleted = 0
	while scan > 0 and deleted < maxDelete do
		if Sweep.i > #Sweep.list then
			Sweep.phase = Sweep.phase % #PHASES + 1
			Sweep.list = SweepList(PHASES[Sweep.phase])
			Sweep.i = 1
			if #Sweep.list == 0 and Sweep.phase == #PHASES then break end -- a full cycle with nothing to do
			if #Sweep.list == 0 then scan = scan - 1 end
		else
			local h = Sweep.list[Sweep.i]
			Sweep.i = Sweep.i + 1
			scan = scan - 1
			if SweepCheck(PHASES[Sweep.phase], h, rearmostX) then
				deleted = deleted + 1
			end
		end
	end
	if deleted > 0 then
		SetFloat("level.debug.spawned.cleanup", GetTime()) -- (2026-11-14) debug menu "spawn activity" readout
		SetString("level.debug.what.cleanup", deleted .. " deleted")
	end
	return deleted
end

-- (2026-11-15, performance) the shapes phase listed every shape of the level (~10k) each pass: a 2.3 ms frame in
-- Teardown's profiler every second or two. Now it asks for the shapes in the region behind the deletion line only
-- (QueryAabbShapes), and lists everything once every FULL_SCAN_INTERVAL seconds in case the query leaves out shapes
-- (e.g. non-colliding decor).
FULL_SCAN_INTERVAL = 30

function SweepList(phase)
	if phase == "shapes" then
		if GetTime() >= (FullScanAt or 0) then
			FullScanAt = GetTime() + FULL_SCAN_INTERVAL
			return FindShapes(nil, true)
		end
		local x = SweepRearX or 0
		return QueryAabbShapes(Vec(-1e6, -1e5, -1e6), Vec(x - deletionDist, 1e5, 1e6)) or {}
	end
	if phase == "bodies" then return FindBodies(nil, true) end
	if phase == "triggers" then return FindTriggers(nil, true) end
	if phase == "joints" then return FindJoints(nil, true) end
	local vehicles = {}
	for v in pairs(vList) do vehicles[#vehicles + 1] = v end
	return vehicles
end

--- v1's rule for one object; true if it was deleted.
function SweepCheck(phase, h, rearmostX)
	if phase == "vehicles" then
		local bodies = vList[h]
		if not IsHandleValid(h) then
			vList[h] = nil -- (v2 perf) forget deleted vehicles (v1 kept them and re-deleted them every update)
			return false
		end
		if HasTag(h, "nodelete") then return false end
		for _, empty in pairs(bodies) do
			if not empty then return false end
		end
		if IsAnyPlayerVehicle(h) then
			if GetBool('Level.Debug') then
				DebugPrint(GetTime().." player vehicle was flagged to be removed at: "..TransformStr(GetVehicleTransform(h)))
			end
			return false
		end
		Delete(h)
		vList[h] = nil
		return true
	end
	if not IsHandleValid(h) then return false end
	-- (2026-11-15) "behind" = the object's FAR end (bounds max x), not its origin: a 200 m road / sand box whose
	-- origin is its back corner was deleted while its front end was 50 m behind the player, in sight (user)
	if phase == "shapes" then
		if HasTag(h, "nodelete") or InGrace(GetShapeBody(h)) then return false end
		local _, max = GetShapeBounds(h)
		if rearmostX - max[1] > deletionDist then
			Delete(h)
			return true
		end
	elseif phase == "bodies" then
		local v = GetBodyVehicle(h)
		if v ~= 0 then
			vList[v] = vList[v] or {}
			vList[v][h] = not isBodyValid(h)
			return false
		end
		if HasTag(h, "nodelete") or InGrace(h) then return false end
		-- (a body is deleted only once its shapes are gone: its bounds mean nothing then, its position is v1's rule)
		if rearmostX - GetBodyTransform(h).pos[1] > deletionDist and not isBodyValid(h) then
			Delete(h)
			return true
		end
	elseif phase == "triggers" then
		if HasTag(h, "nodelete") or InGrace(h) then return false end
		local _, max = GetTriggerBounds(h)
		if rearmostX - max[1] > deletionDist then
			Delete(h)
			return true
		end
	elseif phase == "joints" then
		for _, s in ipairs(GetJointShapes(h)) do
			if IsHandleValid(s) then return false end
		end
		Delete(h)
		return true
	end
	return false
end

--- x of the rearmost player, or nil when there are no players (never infinity: see server.tick)
function RearmostPlayerX()
	local x = nil
	for p in Players() do
		local px = GetPlayerTransform(p).pos[1]
		if x == nil or px < x then x = px end
	end
	return x
end

function IsAnyPlayerVehicle(vehicle)
	for p in Players() do if GetPlayerVehicle(p) == vehicle then return true end end
	return false
end

function isBodyValid(b)
	local ss=GetBodyShapes(b)
	for i=1,#ss do
		if IsHandleValid(ss[i])then
			return true
		end
	end
	return false
end

#version 2
#include "script/include/player.lua"
-- (2026-11-17, DEBUG) collector probe / skip switch, off unless level.debug.* is set (lib/GcProbe.lua)
#include "../../lib/GcProbe.lua"
GCP_LABEL = "generateroad"
-- (v2) server: road generation, world shift (moves ALL players), distance; registry keys read by clients are synced.
-- (v2, Phase 3) Co-op: the FURTHEST living player drives generation, the world shift and the distance counter
-- (GetGenerationPlayerPos); players far behind are teleported up to the leader (TeleportStragglers).
--[[
#include "../../lib/Automatic.lua"
#include "../../lib/Settings.lua"
#include "../../lib/TDSU/tdsu.lua"
#include "EnemySpawnsProcessor.lua"
#include "DecorParts.lua"
#include "SegmentPieces.lua"
#include "SegmentFileChunks.lua"
#include "SpawnSlot.lua"
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

	Distfornewroad = 300 -- (2026-11-15, gradual generation) v1: 200; a segment is queued earlier and fills in gradually
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

	-- (2026-11-15 fix) a deleted trigger stays in FindTriggers until the end of the frame, and server.update runs 2-3
	-- times per frame below 60 FPS. v1 raised level.roadgen right away, which skipped those extra updates; since
	-- segments are queued (the pulse comes when the file spawns), they queued the SAME segment again: duplicate
	-- segments, roadblocks piled on one spot (user screenshot), double enemies / vehicles. Triggers already used are
	-- skipped until they are really gone (handles can be reused afterwards).
	local NewRoads = UnusedPuzzlePieces()
	if GetBool('Level.Debug')then
		DebugWatch("#NewRoads", #NewRoads)
	end
	if not GetBool("level.roadgen")then
		for i=1, #NewRoads do
			local NewRoadTrans = GetTriggerTransform(NewRoads[1])
			local DistToPlayer = NewRoadTrans.pos[1] - GetGenerationPlayerPos()[1]
			-- (2026-11-15) debug menu "generate ahead" (200 / 250 / 300 m) to compare FPS; default Distfornewroad
			local ahead = GetInt("savegame.mod.debug.gen_ahead")
			if DistToPlayer < (ahead > 0 and ahead or Distfornewroad) then
				if GetBool('Level.Debug')then DebugPrint(GetTime().." ----------SPAWNING SEGMENT----------")end
				if GetBool('Level.Debug')then DebugPrint(GetTime().." player at: "..VecStr(playerPos))end
				UsedPuzzlePieces[NewRoads[i]] = true
				Delete(NewRoads[i])
				-- (2026-11-15, gradual generation) the segment is QUEUED: its static pieces nearest-first, then its
				-- file (markers, scripts, dynamic objects: after the ground under them), then the decor; the work
				-- that followed the file's Spawn runs when the queue reaches it (SpawnSegmentFile)
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
					if Type == "M" and whichone == 6 then
						spawnCountOverride = 6
					end
					if GetString("savegame.mod.difficulty") ~= "nightmare" then
						QueueSegment("RoadSegment" .. Type .. whichone, NewRoadTrans, { override = spawnCountOverride })
					else
						-- (2026-11-15 fix) Nightmare spawned only RoadSegment2's file: its floors / rocks / road pieces
						-- were never queued (QueueDecor leaves out the decor on Nightmare)
						QueueSegment("RoadSegment2", NewRoadTrans, { override = spawnCountOverride })
					end
				else
					QueueSegment("RoadSegmentH", NewRoadTrans, { shop = true })
					Roadsegmentz = 0
					if GetString("savegame.mod.difficulty") == "hardcore" then
						chanceforsafe = math.random(8,22)
					else
						chanceforsafe = 10
					end
				end
				if GetBool('Level.Debug')then DebugPrint(GetTime().." queued segment")end
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
	-- (2026-11-15) a queued segment's file was spawned (server.tick): raise the one-update "segment spawned" pulse
	-- here, where v1 raised it, so every script's next tick sees it (mines, WaterMover, randomdelete)
	if RoadgenPending then
		RoadgenPending = false
		SetBool("level.roadgen", true)
		if GetBool('Level.Debug')then DebugPrint(GetTime().." mark new segment spawned")end
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


--- PuzzlePiece triggers not yet used for a segment (see the fix note in server.update)
UsedPuzzlePieces = {}
function UnusedPuzzlePieces()
	for h in pairs(UsedPuzzlePieces) do
		if not IsHandleValid(h) then UsedPuzzlePieces[h] = nil end
	end
	local out = {}
	for _, h in ipairs(FindTriggers("PuzzlePiece", true)) do
		if not UsedPuzzlePieces[h] then out[#out + 1] = h end
	end
	return out
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
		ShiftDecorQueue(shiftDist)   -- decor still waiting to spawn moves with the world
		ShiftResync_Start()
		SetFloat("level.debug.spawned.world_shift", GetTime()) -- (2026-11-14) debug menu "spawn activity" readout
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

-- (2026-11-14, performance) Roadside decor: in most segments ~3300 of ~3400 shapes are bushes and rocks, and Spawn()
-- builds a prefab in one frame, so a segment spawn froze the game for seconds. tools/porting/split_decor.py moved the
-- decor into its own prefabs (DecorParts.lua); they are spawned one per tick after their segment, at its transform.
-- Debug menu "spawn roadside decor" (savegame.mod.procedural.disable.spawn_decor) leaves them out.
-- Nightmare deletes all veg-tagged shapes after spawning (ManageVegDeleting): its decor is not spawned at all.
DecorQueue = {}
-- (2026-11-17) Roadside decor waits in its own queue, served only with what a frame has left after DecorQueue (the
-- ground, the segment file): with the decor cut into ~20 chunks per segment (chunk_decor.py) one shared queue fell
-- behind at driving speed (in-game run at 25 m/s: up to 425 entries waiting, the road ahead missing, the spawners
-- held). Decor does not collide, so the spawners (level.segment.loading) do not wait for it.
VegQueue = {}
DecorFrame = 0   -- server.tick count (once per frame; server.update can run several times in one frame)
-- (2026-11-14) also the segment's heavy content: tools/porting/split_heavy.py moved the terrain / background groups
-- and every rock / hill model into parts, tools/porting/segment_pieces.py cut those into ~2200 small pieces with
-- their box-cell cost (SegmentPieces.lua; rocks and hills per model: tools/porting/vox_pieces.py). They come
-- before the decor, as many per frame as fit in PieceBudget() cells (at least one), so the cost is spread evenly
-- instead of one heavy part per frame. The Random* spawners wait while a segment is still loading
-- (level.segment.loading) so nothing spawns where a rock is about to appear.
PIECE_BUDGET_DEFAULT = 250000   -- box cells per frame; debug menu "piece budget" (savegame.mod.debug.piece_budget)
function PieceBudget()
	local b = GetInt("savegame.mod.debug.piece_budget")
	return b > 0 and b or PIECE_BUDGET_DEFAULT
end

-- (2026-11-14, performance) Option "Low Detail Rocks" (Performance > Visual, the host's; on by default): a rock piece
-- spawns from rock1_low (half resolution at twice the scale: 8x fewer cells; tools/porting/rock_variant.py).
-- Read at each spawn (no restart).
function LowDetailRocks()
	local low = Settings and Settings.performance and Settings.performance.visual.low_detail_rocks
	return low and low.value and true or false
end

-- (2026-11-15, gradual generation) A segment = its static pieces (since 2026-11-15 ALL its static geometry: road,
-- sand, floors, walls, signs, rocks, hills; nearest-first, tools/porting/segment_pieces.py), then its file (what is
-- left: markers, triggers, scripts, lights on joints, vehicles, dynamic bodies, which need the ground under them),
-- then its decor. opts: override = enemy spawn count (RoadSegmentM6), shop = refresh the shop (RoadSegmentH).
-- (2026-11-17, performance) The file itself is streamed too: SEGMENT_FILE_CHUNKS (tools/porting/chunk_segments.py)
-- cuts it into chunks spawned one per frame (it cost 0.2-0.5 s in one frame on H, M3, M5, M6, M7: ground left under
-- a script, a town, trains); the last chunk is the "file" and its after-spawn work gets every chunk's entities.
function QueueSegment(segment, transform, opts)
	local path = "MOD/prefabs/spawnables/roadsegments/" .. segment .. ".xml"
	local chunks = (SEGMENT_FILE_CHUNKS or {})[segment]
	local entries = {}
	if chunks and #chunks > 0 then
		local group = { entities = {} }
		for i, xml in ipairs(chunks) do
			entries[i] = { xml = xml, chunk = group, name = path .. " #" .. i }
		end
		local last = entries[#entries]
		last.segment, last.opts, last.file = segment, opts or {}, true
	else
		entries[1] = { segment = segment, opts = opts or {}, xml = path, name = path, file = true }
	end
	QueueDecor(segment, transform, entries)
end

function QueueDecor(segment, transform, fileEntries)
	local function add(entry, queue)
		-- not in the segment's own frame: from the next frame on
		entry.t = Transform(VecCopy(transform.pos), transform.rot)
		entry.frame = DecorFrame + 1
		queue[#queue + 1] = entry
	end
	for _, p in ipairs((SEGMENT_PIECES or {})[segment] or {}) do add({ piece = p }, DecorQueue) end
	for _, e in ipairs(fileEntries or {}) do add(e, DecorQueue) end
	if not (GetBool("savegame.mod.procedural.disable.spawn_decor") or GetString("savegame.mod.difficulty") == "nightmare") then
		for _, xml in ipairs((DECOR_PARTS or {})[segment] or {}) do add({ xml = xml, veg = true }, VegQueue) end
	end
	SetBool("level.segment.loading", #DecorQueue > 0)
	SetInt("level.debug.parts_waiting", #DecorQueue + #VegQueue)
end

--- The segment file's turn in the queue: what v1 did right after spawning a segment.
function SpawnSegmentFile(d, entities)
	SetString("level.debug.what.segment", d.name or d.xml)
	SetFloat("level.debug.spawned.segment", GetTime()) -- (2026-11-14) debug menu "spawn activity" readout
	ManageVegDeleting(entities)
	local spawnCountOverride = d.opts.override
	for _, v in ipairs(FindLocations("special", true)) do
		if GetTagValue(v, "special") == "town"
		or GetTagValue(v, "special") == "um_base"
		then
			spawnCountOverride = math.random(4,6)
		end
	end
	if d.opts.shop then SetBool("inventory.refreshshop", true, true) end
	RegisterSegmentScripts(entities) -- (v2 perf) see TickSegmentScripts
	ProcessEnemySpawns(entities, spawnCountOverride)
	RoadgenPending = true -- the "segment spawned" pulse, raised by the next server.update
end

-- xml and box-cell cost of a queue entry (a decor part: ~1600 small bushes, felt instant: costs a whole frame; the
-- segment file: its own frame too)
function QueueEntryXml(d)
	local p = d.piece
	if d.veg then return d.xml, PieceBudget() / 2 end -- a decor chunk (~200 shapes, ~25 ms): two fit in a frame
	if not p then return d.xml, PieceBudget() end
	local h = p[1]
	if p[4] and LowDetailRocks() then
		return SEGMENT_PIECE_HEADS[h] .. p[4] .. SEGMENT_PIECE_TAILS[h], p[5]
	end
	return SEGMENT_PIECE_HEADS[h] .. p[2] .. SEGMENT_PIECE_TAILS[h], p[3]
end

-- (2026-11-17, user) Option "Segment Loading Pace" (Performance > Physical, the host's): the generation spawns only
-- every SpawnGap() frames (segment pieces, segment files, decor here; buildings, enemies, loot, vehicles, signs through
-- SpawnSlot.lua, which reads level.spawn.gap). Above 1 the pieces also share the spawners' slot, so a frame has at most
-- one of the two. 1 = every frame, as before. Read every tick (no restart).
SPAWN_GAP_MAX = 6

function SpawnGap()
	local o = Settings and Settings.performance and Settings.performance.physical
		and Settings.performance.physical.spawn_pace
	local g = o and math.floor((tonumber(o.value) or 1) + 0.5) or 1
	return math.max(1, math.min(SPAWN_GAP_MAX, g))
end

-- (2026-11-17) The pace never holds back the ground in front of the players: a segment is about 100-600 spawn frames
-- of pieces (SegmentPieces.lua at the 250k-cell budget), so at pace 3-6 the road could not keep up with a car (in-game
-- run at 25 m/s, pace 3: up to 425 entries waiting, the player fell where the road was missing). When the next waiting
-- ground entry's segment starts less than PACE_URGENT_DIST ahead of the generation player, the ground spawns every
-- frame whatever the pace; the spawners and the decor keep the pace.
PACE_URGENT_DIST = 100

function GroundUrgent()
	local d = DecorQueue[1]
	if not d then return false end
	return d.t.pos[1] - GetGenerationPlayerPos()[1] < PACE_URGENT_DIST
end

function server.tick(dt)
	ShiftResync_Tick()
	DecorFrame = DecorFrame + 1
	SetInt("level.frame", DecorFrame)   -- (2026-11-14) frame counter for the spawners' one-spawn-per-frame slot
	local gap = SpawnGap()
	if GetInt("level.spawn.gap") ~= gap then SetInt("level.spawn.gap", gap) end
	if gap > 1 and not GroundUrgent() then
		if not SpawnSlotFree() then return end
	end
	local used = 0
	while true do
		-- the ground / file queue first; decor only with what the frame has left
		local queue = (DecorQueue[1] and DecorFrame >= DecorQueue[1].frame) and DecorQueue
			or (not DecorQueue[1] or used > 0) and VegQueue[1] and DecorFrame >= VegQueue[1].frame and VegQueue
		if not queue then break end
		local d = queue[1]
		local xml, cost = QueueEntryXml(d)
		if used > 0 and used + cost > PieceBudget() then break end
		table.remove(queue, 1)
		used = used + cost
		local entities = Spawn(xml, d.t, true)
		if d.chunk then
			-- a chunk of the segment file: collected, the last chunk ("file") does the after-spawn work for all
			local all = d.chunk.entities
			for i = 1, #entities do all[#all + 1] = entities[i] end
			entities = all
			SetFloat("level.debug.spawned.segment", GetTime()) -- debug readout
			SetString("level.debug.what.segment", d.name)
		end
		if d.file then
			SpawnSegmentFile(d, entities)
		elseif d.chunk then
			-- nothing more until the last chunk
		else
			SetFloat(d.veg and "level.debug.spawned.decor" or "level.debug.spawned.part", GetTime()) -- debug readout
			-- the foliage setting thins veg-tagged shapes out as before (v1: decor and the segment file's own)
			ManageVegDeleting(entities)
		end
	end
	if used > 0 and gap > 1 then TakeSpawnSlot() end
	if used > 0 then SetString("level.debug.what.part", string.format("%.2fM cells", used / 1e6)) end -- debug readout
	SetInt("level.debug.parts_waiting", #DecorQueue + #VegQueue)
	if #DecorQueue == 0 and GetBool("level.segment.loading") then SetBool("level.segment.loading", false) end
end

-- (MP fix 2026-11-16, measured with the MCP bridge's two-window test) "Other players may not see a building / a
-- stretch of road the host sees": static prefabs (no <body>) are spawned into the world body, which the world shift
-- moves (SetBodyTransform above). A shape spawned after that move, before a client has applied it, is placed against
-- the client's old world-body position: permanently 200 m off there (missing in front of the player, a copy one shift
-- behind). Test: a box spawned before the move in the same tick was right on the client, boxes spawned after it (same
-- tick, ~1 s later) were off by the move; the client had the move within 3 s. A changed shape local transform is
-- synced (re-setting the same value is not), so after a shift every world-body shape newer than the mark (handles
-- grow; GetBodyShapes lists them in ascending order) is nudged 1 mm and set back: each client gets the server's
-- local transform again. Second in-game run: pieces spawned shortly BEFORE a shift were also off on the client
-- (one shift ahead: the client built them after it had the move), so the mark is the newest world-body shape
-- SHIFT_RESYNC_BEFORE s before the shift (recorded every second), and a late pass covers pieces a client builds late.
-- (2026-11-17 performance, measured in SP with the MCP bridge) Each SetShapeLocalTransform on a world-body shape costs
-- ~0.28 ms whether it is spread or not; a pass over ~10000 shapes froze the game 2-5 s, 1, 2 and 5 s after every shift.
-- Now: no passes without other players; only shapes of SHIFT_RESYNC_MIN_VOXELS or more (of 10000 recent world shapes,
-- 8900 were bush pieces / bits of ~13 voxels, ~1070 the road, rocks, terrain); one set per shape and pass (toggled
-- 1 mm up / back down, ResyncUp); a pass is queued and worked off SHIFT_RESYNC_PER_FRAME shapes per frame.
SHIFT_RESYNC_AFTER = { 1, 5, 10 }
SHIFT_RESYNC_BEFORE = 10
SHIFT_RESYNC_MIN_VOXELS = 500
SHIFT_RESYNC_PER_FRAME = 25
ShiftResyncHistory = {}   -- { { time, newest world-body shape }, ... } once a second, the last SHIFT_RESYNC_BEFORE s
ShiftResyncQueue = {}     -- shapes waiting for their set, in order; ShiftResyncQueued[s] = true while queued
ShiftResyncQueued = {}
ResyncUp = {}             -- shapes currently 1 mm up (the next set moves them back down)

local function newestWorldShape()
	local shapes = GetBodyShapes(GetWorldBody())
	return shapes[#shapes] or 0
end

-- One job per shift, each with its own mark (2026-11-17: a single job that kept the oldest mark while shifts came
-- every ~8 s never moved its mark on: passes grew to 12000 shapes). Jobs due in the same tick share one pass.
ShiftResyncJobs = {}

function ShiftResync_Start()
	if not IsMultiplayer() then return end
	local h = ShiftResyncHistory
	local mark = h[1] and h[1][2] or newestWorldShape()   -- the oldest record: ~SHIFT_RESYNC_BEFORE s ago
	ShiftResyncJobs[#ShiftResyncJobs + 1] = { mark = mark, at = GetTime(), step = 1 }
end

--- One set per shape: 1 mm up, or back down if it is up. Any change is synced, and a shape is never more than 1 mm off.
local function resyncShape(s)
	if not IsHandleValid(s) then ResyncUp[s] = nil return end
	local lt = GetShapeLocalTransform(s)
	local dy = ResyncUp[s] and -0.001 or 0.001
	SetShapeLocalTransform(s, Transform(VecAdd(lt.pos, Vec(0, dy, 0)), lt.rot))
	if ResyncUp[s] then ResyncUp[s] = nil else ResyncUp[s] = true end
end

function ShiftResync_Tick()
	-- the queue first: a pass is worked off SHIFT_RESYNC_PER_FRAME shapes per frame
	local q = ShiftResyncQueue
	if #q > 0 then
		local n = math.min(#q, SHIFT_RESYNC_PER_FRAME)
		for i = 1, n do
			resyncShape(q[i])
			ShiftResyncQueued[q[i]] = nil
		end
		for i = 1, #q - n do q[i] = q[i + n] end
		for i = #q, #q - n + 1, -1 do q[i] = nil end
	end
	if not IsMultiplayer() then return end
	local now = GetTime()
	local h = ShiftResyncHistory
	if not h[#h] or now - h[#h][1] >= 1 then
		h[#h + 1] = { now, newestWorldShape() }
		while h[2] and now - h[2][1] >= SHIFT_RESYNC_BEFORE do table.remove(h, 1) end
	end
	local mark, due = nil, {}
	for _, r in ipairs(ShiftResyncJobs) do
		if now >= r.at + SHIFT_RESYNC_AFTER[r.step] then
			due[#due + 1] = r
			if not mark or r.mark < mark then mark = r.mark end
		end
	end
	if not mark then return end
	ResyncUpPasses = (ResyncUpPasses or 0) + 1
	if ResyncUpPasses % 20 == 0 then -- drop deleted shapes that were left 1 mm up
		for s in pairs(ResyncUp) do if not IsHandleValid(s) then ResyncUp[s] = nil end end
	end
	local n, skipped, first, last = 0, 0, 0, 0
	for _, s in ipairs(GetBodyShapes(GetWorldBody())) do
		if s > mark then
			if GetShapeVoxelCount(s) < SHIFT_RESYNC_MIN_VOXELS then
				skipped = skipped + 1
			elseif not ShiftResyncQueued[s] then
				q[#q + 1] = s
				ShiftResyncQueued[s] = true
				n = n + 1
				if first == 0 then first = s end
				last = s
			end
		end
	end
	SetString("level.debug.shift_resync", string.format("%.1f: mark %d, %d shapes queued, %d small skipped, %d job(s) due (#%d..#%d)",
		now, mark, n, skipped, #due, first, last))
	for _, r in ipairs(due) do r.step = r.step + 1 end
	for i = #ShiftResyncJobs, 1, -1 do
		if not SHIFT_RESYNC_AFTER[ShiftResyncJobs[i].step] then table.remove(ShiftResyncJobs, i) end
	end
end

function ShiftDecorQueue(shiftDist)
	for _, q in ipairs({ DecorQueue, VegQueue }) do
		for _, d in ipairs(q) do
			d.t.pos[1] = d.t.pos[1] - shiftDist
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
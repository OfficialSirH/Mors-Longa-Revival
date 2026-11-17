-- (2026-11-17, performance, user request "NPC holds once per frame") server.update runs once per 1/60 s physics step,
-- so below 60 FPS it runs 2-3 times in one frame, and update_npcs (AI thinking, navigation, the robot movement code,
-- head / jaw / gun / melee holds) ran in full each time. Measured with Teardown's profiler: ~2.7 ms of goreai_main and
-- ~2.7 ms of physics per step with 12 NPCs; FPS 42.7 -> 29.2 with 10 more NPCs.
-- Now the first step of a frame runs everything and records every Constrain* call; the frame's other steps re-apply
-- those recorded holds (Constrain* only acts on the step it is called in, so the npcs keep their support on every
-- step) without running the Lua again. The time of the skipped steps is added to the next full run (GoreFrameDt,
-- and GetTimeStep() returns it inside update_npcs), so timers, stun, step animation and walking keep their pace.
-- ConstrainPosition / ConstrainOrientation calls whose first point / rotation was the body's own current transform
-- are replayed with the body's transform at that step. Off switch for A/B tests: level.goreai.no_step_replay.
-- The game's own robot script (data/script/robot.lua) runs everything every step but moves the heavy parts to native
-- helpers (Robot*CPP); ours is a retuned Lua port, so those helpers are not drop-in (different constants).

StepReplayReal = StepReplayReal or {}
StepReplayList = nil          -- the list the current npc's Constrain* calls are recorded into (nil: not recording)
GoreUpdateFrame = -1          -- frame (ConfigMemoGen) of the last full run
GorePendingDt = 0             -- time of steps replayed since the last full run
GoreFrameDt = 1 / 60          -- the time a full run covers
GoreNavInterval = false       -- (thinking) true once every 0.25 s of game time, on a full run

local NAMES = { "ConstrainVelocity", "ConstrainAngularVelocity", "ConstrainPosition", "ConstrainOrientation" }

if not StepReplayInstalled then
	StepReplayInstalled = true
	for _, name in ipairs(NAMES) do
		local real = _G[name]
		StepReplayReal[name] = real
		_G[name] = function(...)
			local rec = StepReplayList
			if rec then
				local args = { ... }
				local entry = { name = name, n = select("#", ...), args = args }
				-- the first point / rotation is the body's own current transform: refresh it when replaying
				if name == "ConstrainPosition" and args[1] and args[3] then
					local p = GetBodyTransform(args[1]).pos
					entry.refresh = math.abs(p[1] - args[3][1]) + math.abs(p[2] - args[3][2]) + math.abs(p[3] - args[3][3]) < 1e-5
				elseif name == "ConstrainOrientation" and args[1] and args[3] then
					local r = GetBodyTransform(args[1]).rot
					entry.refresh = math.abs(r[1] - args[3][1]) + math.abs(r[2] - args[3][2]) + math.abs(r[3] - args[3][3])
						+ math.abs(r[4] - args[3][4]) < 1e-5
				end
				rec[#rec + 1] = entry
			end
			return real(...)
		end
	end
end

function StepReplayOn()
	return not GetBool("level.goreai.no_step_replay")
end

--- Called at the start of update_npcs. Returns true on the frame's first step (run everything), false on its other
--- steps (replay the recorded holds). Keeps GoreFrameDt / GorePendingDt / GoreNavInterval.
function StepReplayBegin(dt, frame)
	-- debug readout: full runs / replayed steps in the last second (level.debug.npc_steps)
	StepCount = StepCount or { full = 0, replay = 0, at = GetTime() }
	if GetTime() - StepCount.at >= 1 then
		SetString("level.debug.npc_steps", StepCount.full .. " full, " .. StepCount.replay .. " replayed")
		StepCount.full, StepCount.replay, StepCount.at = 0, 0, GetTime()
	end
	local full = StepReplayBegin_(dt, frame)
	if full then StepCount.full = StepCount.full + 1 else StepCount.replay = StepCount.replay + 1 end
	return full
end

function StepReplayBegin_(dt, frame)
	if not StepReplayOn() then
		GoreFrameDt = dt
		GoreNavInterval = IsTickInterval(UPDATE, 0.25)
		return true
	end
	if GoreUpdateFrame ~= frame then
		GoreUpdateFrame = frame
		GoreFrameDt = dt + GorePendingDt
		GorePendingDt = 0
		local t = GetTime()
		GoreNavInterval = math.floor(t * 4) ~= math.floor((GoreNavLastTime or t) * 4)
		GoreNavLastTime = t
		return true
	end
	GorePendingDt = GorePendingDt + dt
	return false
end

--- Re-apply an npc's holds recorded on this frame's full run.
function StepReplayApply(list)
	for i = 1, #list do
		local e = list[i]
		local a = e.args
		if e.refresh then
			local t = GetBodyTransform(a[1])
			a[3] = e.name == "ConstrainPosition" and t.pos or t.rot
		end
		StepReplayReal[e.name](unpack(a, 1, e.n))
	end
end

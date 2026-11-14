#version 2
#include "script/include/player.lua"
-- (v2) server: sleeping NPC wakes when ANY player is near, standing still-ish and not crouching.
sleeptypes = { "heavy", "light", "normal" }

sleeptypetypes = {
	heavy = {
		dist = 5,
		ttime = 5.5,
	},
	light = {
		dist = 22,
		ttime = 1.2,
	},
	normal = {
		dist = 12,
		ttime = 3,
	},
}

function server.init()
	Body = FindBody("Torso")
	prefab = GetTagValue(Body, "Prefab")
	WakeUp = false
	sleeptype = sleeptypes[math.random(1, 3)]
	Shapes = FindShapes("")
	ForeverSleep = false
	SleepyTimer = sleeptypetypes[sleeptype].ttime

	bodies = FindBodies("")
	shapes = FindShapes("")
end

function server.tick(dt)
	if not WakeUp then
		if not ForeverSleep then
			for i = 1, #Shapes do
				if IsShapeBroken(Shapes[i]) then
					ForeverSleep = true
				end
			end
		end

		local waker, nearest = nil, math.huge -- (v2) any player (v1 conditions per player)
		for p in Players() do
			local d = GetDist(GetPlayerTransform(p).pos, GetBodyTransform(Body).pos)
			nearest = math.min(nearest, d)
			if not InputDown("crouch", p) and d <= sleeptypetypes[sleeptype].dist and GetPlayerVelocity(p)[1] < 3 then waker = p end
		end
		if waker then
			SleepyTimer = SleepyTimer - dt
			if SleepyTimer <= 0 then
				WakeUp = true
			end
		else
			if nearest > sleeptypetypes[sleeptype].dist then
				SleepyTimer = sleeptypetypes[sleeptype].ttime
			end
		end
	end
	if WakeUp and not ForeverSleep then
		Spawn("" .. prefab .. ".xml", Transform(GetBodyTransform(Body).pos))
		for i = 1, #bodies do Delete(bodies[i]) end
		for i = 1, #shapes do Delete(shapes[i]) end
		ForeverSleep = true
	end
end

function GetDist(Pos1, Pos2)
	local dist = VecLength(VecSub(Pos1, Pos2))
	return dist
end

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

function init()
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

function tick(dt)
	if not WakeUp then
		if not ForeverSleep then
			for i = 1, #Shapes do
				if IsShapeBroken(Shapes[i]) then
					ForeverSleep = true
				end
			end
		end

		if not InputDown("crouch") and GetDist(GetPlayerTransform().pos, GetBodyTransform(Body).pos) <= sleeptypetypes[sleeptype].dist and GetPlayerVelocity()[1] < 3 and GetPlayerVelocity()[2] and GetPlayerVelocity()[3] then
			SleepyTimer = SleepyTimer - dt
			if SleepyTimer <= 0 then
				WakeUp = true
			end
		else
			if GetDist(GetPlayerTransform().pos, GetBodyTransform(Body).pos) > sleeptypetypes[sleeptype].dist then
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

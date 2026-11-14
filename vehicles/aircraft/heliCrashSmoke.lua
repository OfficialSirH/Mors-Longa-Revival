#version 2
#include "script/include/player.lua"
-- (v2) server: heli wreck smoke, scorch paint and fire loop.
--[[
#include "../../lib/TDSU/tdsu.lua"
#include "../../lib/masterScriptRemoverAPI.lua"
]]

DebugMode = false


function server.init()

	DrawPoints = {}

	CrashLight = FindLight("heliCrash", false)
	local pos = GetLightTransform(CrashLight).pos

	CrashLoop = LoadLoop("MOD/assets/snd/Physics/fire_small.ogg")

	local width = 5
	local points = 20
	local h = 3.5
	for i = 1, points do

		local paintPos = VecAdd(pos, Vec(
			(math.random() - 0.5) * width * 2,
			(math.random() * -h),
			(math.random() - 0.5) * width * 2
		))

		Paint(paintPos, math.random()*4, "explosion", math.random() + 0.5)

		table.insert(DrawPoints, paintPos)

	end

end

function server.update()

	if Finished then return end
	local pos = VecAdd(GetLightTransform(CrashLight).pos, Vec(0, -0.3, 0))

	ParticleReset()
	ParticleType("smoke")
	ParticleRadius(0.5, math.random())
	ParticleAlpha(math.random(), 0, "constant", 0.1, 0.5)
	ParticleGravity(10)
	ParticleDrag(2)
	ParticleColor(
		0 + (math.random()/5),
		0 + (math.random()/5),
		0 + (math.random()/5),
		0 + (math.random()/5),
		0 + (math.random()/5),
		0 + (math.random()/5))

	SpawnParticle(
		pos,
		Vec(2 * math.random(), 5 + math.random(), 2 * math.random()),
		math.random(10,20))

end

function server.tick()
	if not IsHandleValid(CrashLight) then
		-- (v2) v1 queueRemoval() (pause-menu handle trick) does not work on the server: just stop.
		Finished = true
	end
	if Finished then return end
	local pos = VecAdd(GetLightTransform(CrashLight).pos, Vec(0, -0.3, 0))

	PlayLoop(CrashLoop, pos, 0.1)

	if DebugMode then
		for index, pos in ipairs(DrawPoints) do
			DrawDot(pos, 1/10,1/10, 1,0,1,1, false)
		end
	end

end

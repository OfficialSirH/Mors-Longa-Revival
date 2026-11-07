#version 2
#include "script/include/player.lua"
-- (v2) server: burning debris thrown from wrecked cars, explodes after a while.
function server.init()
	yeeeeeeeeted = false
	force = 15
	tim = 0
	B = math.random(100,250)/3
end

function server.tick()
	body = FindBody("debri")
	if not yeeeeeeeeted then
		local pos = Vec(0,0,0)
		imp = Vec(math.random(-force,force),math.random(force/3,force),math.random(-force,force))
		SetBodyVelocity(body, imp)
		imp = Vec(math.random(-force,force),math.random(force/3,force),math.random(-force,force))
		SetBodyAngularVelocity(body, imp)
		yeeeeeeeeted = true
	end
	tim = tim + 1
	BodyTrans = GetBodyTransform(body)
	if tim < B then
		fire()
	end
	if tim > B and not done then
		Explosion(BodyTrans.pos, 1)
		done = true
	end
end

function fire()
	ParticleColor(1,0.6,0.3,0.1,0.1,0.1,"linear",0,0.5)
    ParticleEmissive(2,0,"linear",0,0.5)
    ParticleRadius(0.5,0)
    ParticleAlpha(1.0,0.0)
    ParticleCollide(0)
    ParticleGravity(0,-2)
    SpawnParticle(BodyTrans.pos, Vec(math.random(-100,100)/50, math.random(-100,100)/50, math.random(-100,100)/50), 2)
    ParticleReset()
        ParticleColor(0.3,0.3,0.3)
        ParticleRadius(1.75,3,"linear",0.2,1)
        ParticleAlpha(0.5,0.0)
        ParticleCollide(0)
        ParticleGravity(1)
        SpawnParticle(BodyTrans.pos, Vec(math.random(-100,100)/50, math.random(-100,100)/50, math.random(-100,100)/50), 12)
        ParticleReset()
end
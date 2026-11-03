#include "../masterScriptRemoverAPI.lua"

function init()
	boss_trigger = FindTrigger("cultist_boss_trigger")
	local triggerT=GetTriggerTransform(boss_trigger)

	local Loc_cultist_boss_spawn = FindLocation("cultist_boss_spawn")
	Transform_cultist_boss_spawn = TransformToLocalTransform(triggerT, GetLocationTransform(Loc_cultist_boss_spawn))
	Delete(Loc_cultist_boss_spawn)

	local Locs_cultist_spawns = FindLocations("cultist_spawn")
	Transforms_cultist_spawns={}
	for i=1,#Locs_cultist_spawns do
		Transforms_cultist_spawns[i] = TransformToLocalTransform(triggerT, GetLocationTransform(Locs_cultist_spawns[i]))
		Delete(Locs_cultist_spawns[i])
	end

	local Locs_cultist_spawns_random  = FindLocations("cultist_spawn_random")
	Transforms_cultist_spawns_random={}
	for i=1,#Locs_cultist_spawns_random do
		Transforms_cultist_spawns_random[i] = TransformToLocalTransform(triggerT, GetLocationTransform(Locs_cultist_spawns_random[i]))
		Delete(Locs_cultist_spawns_random[i])
	end

	Lights = FindLights("")

	Triggered = false

end

function tick(dt)

	if Triggered then
		queueRemoval()
		return
	end

	local PlayerPos = GetPlayerTransform().pos

	--DebugWatch("Triggered", Triggered)
	--DebugWatch("IsPointInTrigger", IsPointInTrigger(boss_trigger, PlayerPos))

	if IsPointInTrigger(boss_trigger, PlayerPos) then
		local triggerT=GetTriggerTransform(boss_trigger)

		local tr = TransformToParentTransform(triggerT, Transform_cultist_boss_spawn)
		Spawn("MOD/prefabs/BossCultist.xml", tr) --boss
		-- smoke(tr.pos)

		for i=1,#Transforms_cultist_spawns do
			local tr = TransformToParentTransform(triggerT, Transforms_cultist_spawns[i])
			Spawn("MOD/prefabs/spawnables/enemies/cult/Ragdollcult3.xml", tr) -- 100% spawn
			-- smoke(tr.pos)
		end

		local tr = TransformToParentTransform(triggerT, Transforms_cultist_spawns_random[math.random(1, #Transforms_cultist_spawns_random)])
		Spawn("MOD/prefabs/spawnables/enemies/cult/Ragdollcult3.xml", tr)
		-- smoke(tr.pos)

		for i=1,#Lights do
			SetLightEnabled(Lights[i], false)
		end

		Triggered = true

	end

end

function smoke(particlepos)
	ParticleReset()
	ParticleType("smoke")
	ParticleColor(0.8,0,0)
	ParticleRadius(2)
	ParticleDrag(1.0)
	ParticleAlpha(1, 1, "constant", 0, 0.5)
	for i = 1, 10 do
		ParticleGravity(-math.random())
		SpawnParticle(VecAdd(particlepos, Vec(0, 2, 0)), Vec(0,3,0), math.random(10,15))
	end
end
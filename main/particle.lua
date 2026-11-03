-- particle.lua
-- @date 2022-02-20
-- @author MrRare
-- @brief Enhanced fire and smoke particle spawner, based on ThiccSmoke & ThiccFire (I am the author of that mod :P).

Particle_TypeFire = {3, 8, 5, 8, 5, 13, 14, 8}
Particle_TypeSmoke = {3, 5, 3, 5, 3, 5}
Particle_Fire = {
    r=0.93,
	g=0.25,
	b=0.10,
	a=1,
	light="true",
	light_brightness_offset=0,
	light_flickering=0,
    lifetime=2,
    size=1,
    gravity=6,
    speed=1,
    drag=0.5,
    variation=0.1,
	location_random=0.5,
	fade_in=0,
	fade_out=5,
    custom_direction=nil,
	duplicator=1,
	emissive=6,
}

Particle_Smoke = {
    r=0.08,
	g=0.08,
	b=0.08,
	a=1,
	light="false",
	light_brightness_offset=0,
	light_flickering=0,
    lifetime=8,
    size=1,
    gravity=8,
    speed=2,
    drag=0.3,
    variation=0.3,
	location_random=3,
	fade_in=0,
	fade_out=5,
    custom_direction=nil,
	duplicator=1,
	emissive=0,
}

Particle_Spark = {
	r=0.93,
	g=0.25,
	b=0.10,
	a=1,
	light="true",
	light_brightness_offset=0,
	light_flickering=0,
    lifetime=5,
    size_min=0.01,
    size_max=0.03,
    gravity_min=-2,
    gravity_max=-20,
	random_velocity=5,
	rotation_min=1,
	rotation_max=2,
    drag_max=0.3,
    drag_min=0.1,
    sticky_max=1,
    sticky_min=0.1,
    variation=0.1,
	location_random=0.5,
	fade_in=0,
	fade_out=5,
    custom_direction=nil,
	duplicator=1,
	emissive=6,
}

Particle_FireGradient = {
    {-0.2, -0.3, -0.3},
    {0, -0.2, -0.2},
    {-0.2, -0.1, -0.1},
    {-0.3, 0, 0},
    {-0.3, 0.1, 0.2}
}

-- Global sparks particle relevant settings

function Particle_EmitParticle(emitter, location, particle, intensity)
	local radius = emitter["size"]
	local life = emitter["lifetime"]
	local vel = emitter["speed"]
	local drag = emitter["drag"]
	local gravity = emitter["gravity"]
	local red = emitter["r"]
	local green = emitter["g"]
	local blue = emitter["b"]
	local alpha = emitter["a"]
    local location_random = emitter["location_random"]
	local iterator = emitter["duplicator"]
	local variation = emitter["variation"]
    local custom_direction = emitter["custom_direction"]
	local fade_in = emitter["fade_in"]
	local fade_out = emitter["fade_out"]
	local emissive = emitter["emissive"]
	local light_enabled = emitter["light"]

	if light_enabled == "true" then
		local light_brightness_offset = tonumber(emitter["light_brightness_offset"])
		local light_flickering = emitter["light_flickering"]
		local brightness = intensity + light_brightness_offset
		brightness = brightness + Generic_rnd(-light_flickering, light_flickering)
		local l = Generic_SpawnLight(location, emitter, brightness)
		LightSpawner_Spawn(l[1], l[2], l[3], l[4], true)
	end

	for d=1, iterator do
		alpha = alpha +  Generic_rnd(-variation, variation)
		-- gravity = gravity + Generic_rnd(gravity / 2 , gravity * 2)
		if alpha > 1 then
			alpha = 1
		end

		if alpha < 0 then
			alpha = 0
		end

		--Set up the particle state
		ParticleReset()
		ParticleCollide(1, 1, "constant", 0.01)

		local v = custom_direction
		if particle == "spark" then
			local sprites = {3, 8, 4, 6, 12}
			local random_sprite = Generic_rndInt(1, #sprites)
			local random_emissive = Generic_rnd(emitter["emissive"], emitter["emissive"] * 2)
			local random_color = Generic_rnd(-variation, variation)
			local s_red =  red + random_color
			local s_green = green + random_color
			local s_blue =  blue + random_color

			if random_sprite == 8 then
				ParticleRadius(0.5, 0.1)
			else
				local rad = Generic_rnd(emitter["size_min"], emitter["size_max"])
				ParticleRadius(rad, rad / 4)
			end
			ParticleTile(sprites[random_sprite])
			ParticleColor (s_red, s_green, s_blue, red, green, blue)
			ParticleAlpha(alpha, 0, "smooth",  life * (fade_in / 100),  life * (fade_out / 100))	-- Ramp up fast, ramp down after 50%
			ParticleEmissive(random_emissive, 2, "easeout", 0, (fade_in / 100) * Generic_rnd(variation, variation * 3))
			ParticleGravity(Generic_rnd(emitter["gravity_min"], emitter["gravity_max"]))
			ParticleDrag(Generic_rnd(emitter["drag_min"], emitter["drag_max"]))
			ParticleRotation(Generic_rnd(emitter["rotation_min"], emitter["rotation_max"]), 0, "easein", 1)
			ParticleSticky(emitter["sticky_min"], Generic_rnd(emitter["sticky_min"], emitter["sticky_max"]), "easeout")
			v = Generic_rndVec(intensity / 5)
			v = VecAdd(v, Generic_rndVec(Generic_rnd(emitter["random_velocity"] / 10, emitter["random_velocity"])))
			v = VecScale(v, Generic_rnd(emitter["random_velocity"] / 5, emitter["random_velocity"]))
			v =  {v[1] * Generic_rnd(-1, 1), v[2] * Generic_rnd(-1, 1), v[3] * Generic_rnd(-1, 1)}
		elseif particle == "fire" then
			drag = ((drag / (100 / 1.5)) * intensity)
			radius = ((radius / (100 / 1.5)) * intensity)
			gravity = ((gravity / (75 / 1.5)) * intensity)

			local rand = Generic_rndInt(1, #Particle_TypeFire)
			local particle_type = Particle_TypeFire[rand]
			ParticleType("smoke")
			ParticleDrag(drag)
			ParticleTile(particle_type)

			ParticleGravity(Generic_rnd(gravity / 2, gravity))		-- Slightly randomized gravity looks better
			local s_random = Particle_FireGradient[Generic_rndInt(1, #Particle_FireGradient)]
			local s_red =  0.8 + s_random[1]
			local s_green = 0.6 + s_random[2]
			local s_blue =  0.3 + s_random[3]
			-- 3 - 5 - 13 -  14
			-- 8 = fire embers
			life = life + Generic_rnd(-life / 2, life / 2)
			if life < 0.5 then
				life = 0.5
			end

			ParticleColor (s_red, s_green, s_blue, red, green, blue)
			ParticleStretch(0, Generic_rnd(1, variation * 2))
			ParticleAlpha(alpha, 0, "smooth",  life * (fade_in / 100),  life * (fade_out / 100))	-- Ramp up fast, ramp down after 50%

			if particle_type == 5 then
				local emissive = Generic_rnd(emissive, emissive * 2)
				ParticleEmissive(emissive, 2, "easeout", 0, (fade_in / 100) * Generic_rnd(variation , variation * 3))
				ParticleRadius(radius, radius / 4, "easein", life *(fade_in / 100), life * (fade_out / 100))
				-- life = radius * life * 2
			elseif particle_type == 8 then
				gravity = gravity +  Generic_rnd(1, 3)
				vel = vel + Generic_rnd(2 , 4)
				ParticleStretch(1, 10)
				local emissive = Generic_rnd(emissive / 2, emissive * 2)
				ParticleEmissive(emissive, 2, "easeout")
				ParticleRadius(radius , radius / 2, "easein", life *(fade_in / 100), life * (fade_out / 100))
			else
				-- life = radius * life * 2
				local emissive = Generic_rnd(emissive / 2, emissive * 2)
				ParticleEmissive(emissive, 2, "easeout", 0, (fade_in / 100) * Generic_rnd(variation , variation * 3))
				ParticleRadius(radius, radius / 4, "easeout",life *(fade_in / 100), life * (fade_out / 100))
			end
			v = custom_direction
			if  v == nil then
				v = {Generic_rnd(-vel, vel),Generic_rnd(vel/2, vel),Generic_rnd(-vel, vel)}
			end
			ParticleRotation(Generic_rnd(-vel / 10 , vel / 10), Generic_rnd(-vel / 40 , vel / 40), "smooth")
		else


			drag = ((drag / (100 / 1.5)) * intensity)
			radius = ((radius / (100 / 1.5)) * intensity)
			gravity = ((gravity / (75 / 1.5)) * intensity)

			local rand = Generic_rndInt(1, #Particle_TypeSmoke)
			local particle_type = Particle_TypeSmoke[rand]
			ParticleType("smoke")
			ParticleGravity(Generic_rnd(gravity / 2, gravity))		-- Slightly randomized gravity looks better
			ParticleDrag(drag)
			ParticleTile(particle_type)
			ParticleAlpha(alpha, alpha / 2, "easein", (life / 100) * fade_in, (life / 100) * fade_out)
			ParticleRadius(radius * 0.75, radius / 4, "smooth", life *(fade_in / 100), life * (fade_out / 100))
			ParticleColor(red, green, blue, red + 0.2, green + 0.2, blue + 0.2)
			v = custom_direction
			if  v == nil then
				v = {Generic_rnd(-vel, vel),Generic_rnd(vel/2, vel),Generic_rnd(-vel, vel)}
			end
			ParticleRotation(Generic_rnd(-vel / 10 , vel / 10), Generic_rnd(-vel / 40 , vel / 40), "smooth")
		end

		--Emit particles
		--Spawn particle into the world
		SpawnParticle(VecAdd(location, Generic_rndVec(location_random)), v, life)
	end
end

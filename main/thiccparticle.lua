--[[
#include "light_spawner/lightspawner.lua"
#include "generic.lua"
#include "particle.lua"
]]

particle_spawn_info = nil

function Fill_TableTags(object, table_object)
	for key, value in pairs(table_object) do
		if type(value) ~= "table" then
			if HasTag(object, key) then
				table_object[key] = GetTagValue(object, key)
				--DebugPrint("Updating " .. key .. " with: " .. table_object[key] )
			else
				--DebugPrint("Not Found, keeping " .. key .. " with: " .. value )
			end
		else
			table_object[key] = Fill_TableTags(object, table_object[key])
		end
	end
	return table_object
end

function tick(dt)
	LightSpawner_DeleteAll()
	if particle_spawn_info ~= nil and  particle_spawn_info ~= false then
		local point = GetLocationTransform(particle_spawn_info["location"]).pos
		local rot = GetLocationTransform(particle_spawn_info["location"]).rot
		particle_spawn_info["emitter"]["custom_direction"] = rot
		Particle_EmitParticle(particle_spawn_info["emitter"], point, particle_spawn_info["type"], particle_spawn_info["intensity"])
	elseif particle_spawn_info == nil then
		local location = FindLocation("thiccparticle")
		if HasTag(location, "type") and HasTag(location, "intensity") then
			local particle_type = GetTagValue(location, "type")
			local particle_intensity = GetTagValue(location, "intensity")
			local particle_info = nil
			--DebugPrint("Found particle spawn location of type: " .. particle_type)

			if particle_type == "fire" then
				particle_info = Generic_deepCopy(Particle_Fire)
			elseif particle_type == "smoke" then
				particle_info = Generic_deepCopy(Particle_Smoke)
			elseif particle_type == "spark" then
				particle_info = Generic_deepCopy(Particle_Spark)
			end

			if particle_info ~= nil then
				particle_info = Fill_TableTags(location, particle_info)
				particle_spawn_info = {
					type=particle_type,
					emitter=particle_info,
					intensity=particle_intensity,
					location=location
				}
			else

				DebugPrint("Could not find correct particle template for type:  " .. particle_type .. "!")
			end
		else
			particle_spawn_info = false
			DebugPrint("Either location not found or missing required tags for spawner!")
		end
	end
end


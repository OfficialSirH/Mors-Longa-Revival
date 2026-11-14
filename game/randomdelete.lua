#version 2
#include "script/include/player.lua"
-- (v2) server: deletes/keeps tagged level entities once per generated road piece
function server.tick()
	if GetBool("level.roadgen") then
		local shapes = FindShapes("randomdelete", true)
		for i=1,#shapes do
			local chance = tonumber(GetTagValue(shapes[i], "chance")) or 25
			if math.random() < chance/100 then
				Delete(shapes[i])
			else
				RemoveTag(shapes[i], "randomdelete")
				RemoveTag(shapes[i], "chance")
			end
		end
		local bodies = FindBodies("randomdelete", true)
		for i=1,#bodies do
			local chance = tonumber(GetTagValue(bodies[i], "chance")) or 25
			if math.random() < chance/100 then
				Delete(bodies[i])
			else
				RemoveTag(bodies[i], "randomdelete")
				RemoveTag(bodies[i], "chance")
			end
		end
		local lights = FindLights("randomdelete", true)
		for i=1,#lights do
			if not HasTag(lights[i], "chance") then
				if not HasTag(lights[i], "night") then
					SetTag(lights[i], "chance", "23")
				else
					SetTag(lights[i], "chance", "65")
				end
			end
			local chance = tonumber(GetTagValue(lights[i], "chance"))
			if math.random() < chance/100 then
				Delete(lights[i])
				SetShapeEmissiveScale(GetLightShape(lights[i]), 0)
			else
				RemoveTag(lights[i], "randomdelete")
				RemoveTag(lights[i], "chance")
			end
		end
	end
end

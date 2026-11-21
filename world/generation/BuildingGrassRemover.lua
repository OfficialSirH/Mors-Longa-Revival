#version 2
DL_LABEL = "BuildingGrassRemover"  -- crash breadcrumbs (lib/DeleteLog.lua)
#include "../../lib/DeleteLog.lua"
#include "script/include/player.lua"
-- (v2) server: removes grass inside buildings.
function server.tick()

	local triggers = FindTriggers("vegRemove",true)

	if #triggers > 0 then
		local grasses = FindShapes("veg",true)
		for _,trigger in pairs(triggers)do
			for i,grass in pairs(grasses)do
				if IsShapeInTrigger(trigger,grass)then
					Delete(grass)
					table.remove(grasses,i)
				end
			end
			Delete(trigger)
		end
	end

end

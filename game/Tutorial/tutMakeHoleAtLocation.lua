#version 2
DL_LABEL = "tutMakeHoleAtLocation"  -- crash breadcrumbs (lib/DeleteLog.lua)
#include "../../lib/DeleteLog.lua"
-- (v2) server: MakeHole is server-only.
function server.init()
	locations = FindLocations('makeHole',true)
end

function server.tick(dt)
	for i=#locations, 1, -1 do
		local location = locations[i]
		local size = tonumber(GetTagValue(location,'makeHole'))or 1
		MakeHole(GetLocationTransform(location).pos,size,size,size,true)
		Delete(location)
		table.remove(locations,i)
	end
end
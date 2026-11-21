#version 2
DL_LABEL = "window"  -- crash breadcrumbs (lib/DeleteLog.lua)
#include "../lib/DeleteLog.lua"
-- (v2) the whole script was already commented out in the original
--[[function init()
end
function tick(dt)
	windows = FindShapes("window", true)
	spawns = FindLights("spawn", true)
	for i=1,#spawns do
		local window = spawns[i]
		local shape = GetLightShape(window)
		if IsShapeBroken(shape) then
			local SpawnT = GetLightTransform(spawns[i])
			
			if HasTag(shape, "big") then
				local what = math.random(1,2)
				if what == 1 then
					Spawn("MOD/prefabs/brokenwindow1.xml", SpawnT)
					Delete(shape)
				elseif what == 2 then
					Spawn("MOD/prefabs/brokenwindow3.xml", SpawnT)
					Delete(shape)
				end
			elseif HasTag(shape, "vsmall")  then
				Spawn("MOD/prefabs/brokenwindow4.xml", SpawnT)
				Delete(shape)
			elseif HasTag(shape, "nsmall") then
				Spawn("MOD/prefabs/brokenwindow8.xml", SpawnT)
				Delete(shape)
			elseif HasTag(shape, "small") then
				Spawn("MOD/prefabs/brokenwindow5.xml", SpawnT)
				Delete(shape)
			end
		end
	end
end]]
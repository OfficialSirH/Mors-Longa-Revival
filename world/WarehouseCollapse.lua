#version 2
DL_LABEL = "WarehouseCollapse"  -- crash breadcrumbs (lib/DeleteLog.lua)
#include "../lib/DeleteLog.lua"
#include "script/include/player.lua"
-- (v2) server: warehouse roof may collapse when ANY player enters the trigger.
function server.init()
	RCollapse = FindTrigger("rc_trigger")
	RoofShapes = FindShapes("warehouse_roof")

	Triggered = false

	for index, shape in ipairs(RoofShapes) do
		local b = GetShapeBody(shape)
		SetBodyActive(b, false)
		SetBodyDynamic(b, false)
	end
end

function server.tick(dt)
	--[[ if InputDown("f") and InputDown("e") and InputDown("l") then
		Triggered = false
	end ]]

	if Triggered then
	   return
	end
	
	local inside = false -- (v2) any player
	for p in Players() do
		if IsPointInTrigger(RCollapse, GetPlayerTransform(p).pos) then inside = true end
	end
	if inside and not Triggered then
		if math.random() <= 0.1 then
			Collapse()
		end
		Triggered = true
	end
end

function Collapse()
	for index, shape in ipairs(RoofShapes) do
		local b = GetShapeBody(shape)
		SetBodyDynamic(b, true)
		SetBodyActive(b, true)
		SetBodyVelocity(b, Vec(0, -0.1, 0))
	end
end
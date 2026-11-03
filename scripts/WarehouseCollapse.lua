function init()
	RCollapse = FindTrigger("rc_trigger")
	RoofShapes = FindShapes("warehouse_roof")

	Triggered = false

	for index, shape in ipairs(RoofShapes) do
		local b = GetShapeBody(shape)
		SetBodyActive(b, false)
		SetBodyDynamic(b, false)
	end
end

function tick(dt)
	--[[ if InputDown("f") and InputDown("e") and InputDown("l") then
		Triggered = false
	end ]]

	if Triggered then
	   return
	end
	
	local PlayerPos = GetPlayerTransform().pos
	if IsPointInTrigger(RCollapse, PlayerPos) and not Triggered then
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
#version 2
-- (v2, Phase 4, hand-written) Steering wheels that turn with the vehicle's steering.
--
-- Usage (tools/porting/history/convert_steering.py does this): wrap the <vehicle> in
--   <script file="MOD/scripts/SteeringWheel.lua"> ... </script>
-- and make the steering wheel a plain <vox tags="steer"> part of the vehicle body (not a <wheel>: the original UAZ
-- built it as a fifth road wheel, which the physics spun freely after crashes).
--
-- Each "steer" shape turns about its own column: the axis is the shape's thinnest voxel dimension (a steering wheel
-- is flat) and the pivot its bounding-box centre, both measured once at init. Neither depends on the XML rot or on
-- the rotation the model has inside its .vox file (in-game test 1 turned about the XML frame's y axis, which the
-- .vox node rotation moves: the wheel tipped forward/back instead of turning).
-- Param angle (default 180 = what the engine turns the driver's hands by, data/script/player_locomotion.lua);
-- a negative angle reverses the direction.
--
-- Server only: shape transforms are world state and reach the clients by themselves.

local function thinAxis(shape)
	local x, y, z = GetShapeSize(shape)
	if x <= y and x <= z then return Vec(1, 0, 0) end
	if y <= z then return Vec(0, 1, 0) end
	return Vec(0, 0, 1)
end

function server.init()
	Angle = GetFloatParam("angle", 180)
	Wheels = {}
	for _, shape in ipairs(FindShapes("steer")) do
		local body = GetShapeBody(shape)
		local base = GetShapeLocalTransform(shape) -- straight-ahead pose from the XML, in body space
		local lo, hi = GetShapeBounds(shape)       -- world space
		local centre = TransformToLocalPoint(GetBodyTransform(body), VecScale(VecAdd(lo, hi), 0.5))
		Wheels[#Wheels + 1] = {
			shape = shape,
			vehicle = GetBodyVehicle(body),
			base = base,
			pivot = centre,                                   -- body space
			axis = QuatRotateVec(base.rot, thinAxis(shape)),  -- body space
			angle = 0,
		}
	end
end

function server.tick(dt)
	for _, w in ipairs(Wheels) do
		if w.vehicle ~= 0 and IsHandleValid(w.shape) and IsHandleValid(w.vehicle) then
			local a = GetVehicleSteering(w.vehicle) * Angle
			if math.abs(a - w.angle) > 0.5 then -- only touch the shape when it visibly changes
				w.angle = a
				local q = QuatAxisAngle(w.axis, a)
				local pos = VecAdd(w.pivot, QuatRotateVec(q, VecSub(w.base.pos, w.pivot)))
				SetShapeLocalTransform(w.shape, Transform(pos, QuatRotateQuat(q, w.base.rot)))
			end
		end
	end
end

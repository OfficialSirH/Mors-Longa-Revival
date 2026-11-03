function init()
	local shape=FindShape('steer')
	steerJoint=GetShapeJoints(shape)[1]
	scale=tonumber(GetTagValue(shape,'steer'))
	v=GetBodyVehicle(GetShapeBody(shape))
end
	
function tick()
	local steer=0
	if v==GetPlayerVehicle()then
		steer=InputValue("right")-InputValue("left")
	end
	SetJointMotorTarget(steerJoint,30*scale*steer,math.pi/6/.4*scale)
end
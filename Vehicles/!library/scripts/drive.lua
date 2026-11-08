function init()
	driveJoints = FindJoints("drive")
	v = FindVehicle()
end
	
function tick()
	if GetVehicleHealth(v)==0 then
		for i,driveJoint in pairs(driveJoints)do
			SetJointMotor(driveJoint, 0, 0)
		end
		return
	end
	local drive = 0
	if v==GetPlayerVehicle()then
		drive = -10 -math.max(InputValue("up")*40,InputValue("down")*20)
	end
	for i,driveJoint in pairs(driveJoints)do
		SetJointMotor(driveJoint, drive, 100)
	end
end
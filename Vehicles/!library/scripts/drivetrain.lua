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
		drive = InputValue("up")-InputValue("down")
	end
	for i,driveJoint in pairs(driveJoints)do
		SetJointMotor(driveJoint, drive*(tonumber(GetTagValue(driveJoint,'drive')) or 1), 100)
	end
end
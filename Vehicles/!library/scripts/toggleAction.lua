function init()
	shapes = FindShapes('actionToggle')
	vehicle = FindVehicle()
	for i,shape in pairs(shapes)do
		SetTag(shape,'interact',"Toggle Action")
		local joints = GetShapeJoints(shape)
		for i,joint in pairs(joints)do
			if HasTag(joint,'toggle_joint') then
				local min,max = GetJointLimits(joint)
				SetJointMotorTarget(joint, min, 3)
			end
		end
	end
end
function tick()
	if InputPressed('interact')then
		for i,shape in pairs(shapes)do
			if GetPlayerInteractShape()==shape then
				local joints = GetShapeJoints(shape)
				for i,joint in pairs(joints)do
					if HasTag(joint,'toggle_joint') then
						local min,max = GetJointLimits(joint)
						if GetTagValue(joint,'toggle_joint')=="deploied" then
							SetJointMotorTarget(joint, min, 3)
							SetTag(joint,'toggle_joint',"")
						else
							SetJointMotorTarget(joint, max, 3)
							SetTag(joint,'toggle_joint',"deploied")
						end
					end
				end
			end
		end
	end
	if GetPlayerVehicle() == vehicle then
		for i,shape in pairs(shapes)do
			local joints = GetShapeJoints(shape)
			for i,joint in pairs(joints)do
				if HasTag(joint,'toggle_joint') then
					if GetTagValue(joint,'toggle_joint')=="deploied" then
						local min,max = GetJointLimits(joint)
						SetJointMotorTarget(joint, min, 3)
						SetTag(joint,'toggle_joint',"")
					end
				end
			end
		end
	end
end
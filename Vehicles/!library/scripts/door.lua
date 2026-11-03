Vehicle = FindVehicle("Door")
doors = FindJoints("door")

function tick()
	if GetPlayerVehicle() == Vehicle then
		for i=1, #doors do
			door = doors[i]
			SetJointMotorTarget(door, 0, 3)
		end
	else
		for i=1, #doors do
			door = doors[i]
			SetJointMotorTarget(door, 90, 0, 0)
		end
	end
end
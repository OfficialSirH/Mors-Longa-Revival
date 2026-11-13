function init()

	blades = FindJoints("engine", true)

	if GetPlayerVehicle() ~= 0 then

		for i = 1, #blades do
			local blade = blades[i]
			SetJointMotor(blade, 30)
		end

	end

end
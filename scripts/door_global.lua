function init()
	lastPlayerVehicle = 0
end
function tick()
	local pV = GetPlayerVehicle()
	if pV ~= lastPlayerVehicle then
		if HasTag(lastPlayerVehicle,"Door") then
			local jBs = GetJointedBodies(GetVehicleBody(lastPlayerVehicle))
			for i,jB in ipairs(jBs)do
				local dJs=GetBodyJoints(jB)
				for i,dJ in ipairs(dJs) do
					if HasTag(dJ,"door")then SetJointMotor(dJ, 0, 0)end
				end
			end
		end
		if HasTag(pV,"Door") then
			local jBs = GetJointedBodies(GetVehicleBody(pV))
			for i,jB in ipairs(jBs)do
				local dJs=GetBodyJoints(jB)
				for i,dJ in ipairs(dJs) do
					if HasTag(dJ,"door")then SetJointMotor(dJ, 3)end
				end
			end
		end
		lastPlayerVehicle = pV
	end
end

function GetBodyJoints(b)
	local js={}
	for _,s in ipairs(GetBodyShapes(b))do
		for __,sj in ipairs(GetShapeJoints(s))do
			js[#js+1]=sj
		end
	end
	return js
end
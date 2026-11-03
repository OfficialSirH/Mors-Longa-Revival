function init()
	local i = 0
	alarms = {}
	alarmVariations = 0
	while true do
		local filePath = "MOD/snd/Vehicles/Shared/Alarm/car_alarm"..i..".ogg"
		if HasFile(filePath)then
			i = i + 1
			alarms[i] = LoadLoop(filePath)
		else
			alarmVariations = i
			break
		end
	end
end

function tick(dt)

	AllVehicles = FindVehicles("DoAlarm", true)
	for i = 1, #AllVehicles do
		DebugPrint(Vehicle)
		local Vehicle = AllVehicles[i]
		if IsBodyBroken(GetVehicleBody(Vehicle)) and not HasTag(Vehicle, "AlarmStart") and HasTag(Vehicle, "DoAlarm") and not HasTag(Vehicle, "hadalarm") and not HasTag(Vehicle, "chasecar") then
			SetTag(Vehicle, "AlarmStart", 0)
		end

		if HasTag(Vehicle, "AlarmStart") then
			local timer = tonumber(GetTagValue(Vehicle,"AlarmStart")) or 0

			if timer < 20 then
				local VehiclePos = GetVehicleTransform(Vehicle).pos
				VehiclePos[2] = VehiclePos[2] + 1
				PlayLoop(alarms[tonumber(GetTagValue(Vehicle, "Alarm")) or 1], VehiclePos, 2)

				local vehicleShapes = GetBodyShapes(GetVehicleBody(Vehicle))
				if timer%2 < 1 then
					PointLight(VehiclePos, 1, 1, 1, 3)
					for j=1,#vehicleShapes do
						SetShapeEmissiveScale(vehicleShapes[j],1)
					end
				else
					for j=1,#vehicleShapes do
						SetShapeEmissiveScale(vehicleShapes[j],1)
					end
				end
				timer = timer + dt
				SetTag(Vehicle,"AlarmStart",timer)

				if GetPlayerVehicle() == Vehicle then
					RemoveTag(Vehicle, "AlarmStart")
					SetTag(Vehicle, "hadalarm")
				end
			end

			if timer >= 20 then
				RemoveTag(Vehicle, "AlarmStart")
				SetTag(Vehicle, "hadalarm")
			end
		end
	end
end

function hitByExplosion(strength, pos)
	for i = 1, #AllVehicles do
		local Vehicle = AllVehicles[i]
		local DistToSplosion = VecLength(VecSub(pos, GetVehicleTransform(Vehicle).pos))
		if not HasTag(Vehicle, "AlarmStart") and DistToSplosion < 5*strength then
			SetTag(Vehicle, "AlarmStart", 0)
		end
		--DebugPrint(HasTag(Vehicle, "AlarmStart"), " "..DistToSplosion)
	end

end

function handleCommand(cmd)
	words = splitString(cmd, " ")
	if #words == 5 then
		if words[1] == "explosion" then
			local strength = tonumber(words[2])
			local x = tonumber(words[3])
			local y = tonumber(words[4])
			local z = tonumber(words[5])
			hitByExplosion(strength, Vec(x,y,z))
		end
	end
end

function splitString(str, delimiter)
	local result = {}
	for word in string.gmatch(str, '([^'..delimiter..']+)') do
		result[#result+1] = trim(word)
	end
	return result
end

function trim(s)
   return (s:gsub("^%s*(.-)%s*$", "%1"))
end
#version 2
#include "script/include/player.lua"
-- (v2) server: alarm triggers (broken body, nearby explosion via GetEvent, entering the car) and timers;
-- the list of sounding cars is in shared.carAlarms. Clients play the loop and blink the light.
function server.init()
	shared.carAlarms = {}
end

function client.init()
	alarmSeen = {}
	local i = 0
	alarms = {}
	alarmVariations = 0
	while true do
		local filePath = "MOD/assets/snd/Vehicles/Shared/Alarm/car_alarm"..i..".ogg"
		if HasFile(filePath)then
			i = i + 1
			alarms[i] = LoadLoop(filePath)
		else
			alarmVariations = i
			break
		end
	end
end

function server.tick(dt)

	AllVehicles = FindVehicles("DoAlarm", true)
	local count = GetEventCount("explosion") -- (v2) replaces the v1 "explosion" handleCommand
	for i = 1, count do
		local pos, str = GetEvent("explosion", i)
		hitByExplosion(str, pos)
	end
	for i = 1, #AllVehicles do
		local Vehicle = AllVehicles[i]
		if IsBodyBroken(GetVehicleBody(Vehicle)) and not HasTag(Vehicle, "AlarmStart") and HasTag(Vehicle, "DoAlarm") and not HasTag(Vehicle, "hadalarm") and not HasTag(Vehicle, "chasecar") then
			SetTag(Vehicle, "AlarmStart", 0)
		end

		if HasTag(Vehicle, "AlarmStart") then
			local timer = tonumber(GetTagValue(Vehicle,"AlarmStart")) or 0

			if timer < 20 then
				if not shared.carAlarms[tostring(Vehicle)] then
					shared.carAlarms[tostring(Vehicle)] = tonumber(GetTagValue(Vehicle, "Alarm")) or 1
				end

				local vehicleShapes = GetBodyShapes(GetVehicleBody(Vehicle))
				if timer%2 < 1 then
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

				for p in Players() do
					if GetPlayerVehicle(p) == Vehicle then
						RemoveTag(Vehicle, "AlarmStart")
						SetTag(Vehicle, "hadalarm")
						shared.carAlarms[tostring(Vehicle)] = nil
					end
				end
			end

			if timer >= 20 then
				RemoveTag(Vehicle, "AlarmStart")
				SetTag(Vehicle, "hadalarm")
				shared.carAlarms[tostring(Vehicle)] = nil
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

function client.tick(dt)
	for key, alarm in pairs(shared.carAlarms or {}) do
		local Vehicle = tonumber(key)
		alarmSeen[key] = (alarmSeen[key] or 0) + dt
		if IsHandleValid(Vehicle) then
			local VehiclePos = GetVehicleTransform(Vehicle).pos
			VehiclePos[2] = VehiclePos[2] + 1
			PlayLoop(alarms[alarm] or alarms[1], VehiclePos, 2)
			if alarmSeen[key] % 2 < 1 then
				PointLight(VehiclePos, 1, 1, 1, 3)
			end
		end
	end
	for key in pairs(alarmSeen) do
		if not (shared.carAlarms or {})[key] then alarmSeen[key] = nil end
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
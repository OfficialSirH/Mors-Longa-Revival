--[[
#include "../scripts/TDSU/tdsu.lua"
#include "../Settings.lua"
#include "../Automatic.lua"
]]

local disable_spawning = "savegame.mod.procedural.disable.spawn_roadblocks"


function init()

	Init_Settings()
	DistanceProgressed = GetFloat("savegame.mod.distanceProgressed")

	differentDvehicles = 8
	differentDDvehicles = 4
	differentCvehicles = 3
	differentAAFvehicles = 2
	chanceform = 66
	if GetBool('level.RND.vehicleenemy')then -- YOU SHOULDNT NEED A DUPLICATE OF THIS SCRIPT
		DebugWatch('RND vehicleenemy',"DUPLICATED!")
	else
		SetBool('level.RND.vehicleenemy',true)
	end--


	timforciv = 0
	timforHeli = 0
	timforins = 0

	min = 2
	max = 5
	if Settings.game.enemy_helicopter.value then
		Hmin = 15 -- heli spawn timer, minimal, minutes
		Hmax = 25 -- heli spawn timer, maximal, minutes
	end

	Imin = 3
	Imax = 6
	if GetString("savegame.mod.difficulty") == "nightmare" then
		Hmin = 20
		Hmax = 70
		Imin = 5
		Imax = 5
	end

	TimerRange_ref = { 4,  8 }
	TimerRange_heli= { 25, 30 }
	TimerRange_civ = { 3,  8 }
	TimerRange_aaf = { 4,  10 }

	MaxTime_ref = RandomSpreadPercent(math.random(TimerRange_ref[1],  TimerRange_ref[2])) * 60
	MaxTime_heli= RandomSpreadPercent(math.random(TimerRange_heli[1], TimerRange_heli[2])) * 60
	MaxTime_civ = RandomSpreadPercent(math.random(TimerRange_civ[1],  TimerRange_civ[2])) * 60
	MaxTime_aaf = RandomSpreadPercent(math.random(TimerRange_aaf[1],  TimerRange_aaf[2])) * 60

	SpawnTimer_Heli      = TimerCreateSeconds(MaxTime_heli)
	SpawnTimer_AAF       = TimerCreateSeconds(MaxTime_aaf)
	SpawnTimer_Civ       = TimerCreateSeconds(MaxTime_civ)
	SpawnTimer_Refugee   = TimerCreateSeconds(MaxTime_ref)

end


function tick(dt)
	if GetBool(disable_spawning) or GetTime() < 1 then
		return
	end
	if nocando then return end
	if GetString("savegame.mod.difficulty") == "peaceful" then
		nocando = true
		return
	end

	DistanceProgressed = GetFloat("savegame.mod.distanceProgressed")
	local timerDiv = 1 / clamp(AutoMap(DistanceProgressed, 0, 30000, 1, 2), 1, 2) -- scale timers down based on distance.


	DayPhase = GetString("level.dayphase")


	-- DebugWatch("multiplierDist", timerDiv)
	-- DebugWatch("SpawnTimer_Heli", 	 SpawnTimer_Heli.time)
	-- DebugWatch("SpawnTimer_AAF", 	 SpawnTimer_AAF.time)
	-- DebugWatch("SpawnTimer_Civ", 	 SpawnTimer_Civ.time)
	-- DebugWatch("SpawnTimer_Refugee", SpawnTimer_Refugee.time)

	TimerRunTime(SpawnTimer_Heli)
	TimerRunTime(SpawnTimer_AAF)
	TimerRunTime(SpawnTimer_Civ)
	TimerRunTime(SpawnTimer_Refugee)


	--Heli
	if SpawnTimer_Heli.time * timerDiv <= 0 then
		MaxTime_heli = RandomSpreadPercent(math.random(TimerRange_heli[1], TimerRange_heli[2])) * 60
		SpawnTimer_Heli = TimerCreateSeconds(MaxTime_heli)

		if Settings.game.enemy_helicopter.value then

			local xml = "MOD/main/AS350/AS350_INSURGENT.xml"

			if DistanceProgressed > 10000 and math.random() * timerDiv < 0.5 then
				xml = "MOD/main/AS350/AS350_MILITARY.xml"
			end

			local entities = Spawn(xml, Transform(Vec(200,50,3), QuatEuler(0,-90,0)))
			addSpawnedVehicleXMLToRegistry(entities, xml)
		end
	end


	--AAF
	if SpawnTimer_AAF.time * timerDiv <= 0 then
		MaxTime_aaf = RandomSpreadPercent(math.random(TimerRange_aaf[1],  TimerRange_aaf[2])) * 60
		SpawnTimer_AAF = TimerCreateSeconds(MaxTime_aaf)

		if DistanceProgressed > 5000 then
			whichone = "AAF2" -- jeep
		elseif DistanceProgressed > 8000 then
			if math.random() * timerDiv > 0.7 then
				whichone = "AAF1" -- truck
			else
				whichone = "AAF2" -- jeep
			end
		end

		local xml = "MOD/prefabs/spawnables/enemy vehicles/Vehicle" .. whichone ..".xml"
		entities = Spawn(xml, Transform(Vec(-300, 4.5, 3), QuatEuler(0,-90,0)))
		addSpawnedVehicleXMLToRegistry(entities, xml)
	end


	--Civ
	if SpawnTimer_Civ.time * timerDiv <= 0 then
		MaxTime_civ = RandomSpreadPercent(math.random(TimerRange_civ[1],  TimerRange_civ[2])) * 60
		SpawnTimer_Civ = TimerCreateSeconds(MaxTime_civ)

		whichone = "D"..math.random(1,differentDvehicles)
		local xml = "MOD/prefabs/spawnables/enemy vehicles/Vehicle" ..whichone..".xml"
		local entities = nil
		entities = Spawn(xml, Transform(Vec(-300, 4.5, math.random(-3, 3)), QuatEuler(0,-90,0)))
		addSpawnedVehicleXMLToRegistry(entities, xml)
	end


	--Refugee
	if SpawnTimer_Refugee.time * timerDiv <= 0 then
		MaxTime_ref = RandomSpreadPercent(math.random(TimerRange_ref[1],  TimerRange_ref[2])) * 60
		SpawnTimer_Refugee = TimerCreateSeconds(MaxTime_ref)

		whichone = math.random(1, differentCvehicles)
		local xml = "MOD/prefabs/spawnables/enemy vehicles/VehicleC" ..whichone..".xml"
		local entities = Spawn(xml, Transform(Vec(-300,4.5,3), QuatEuler(0,-90,0)))
		addSpawnedVehicleXMLToRegistry(entities, xml)
	end



	local Locations = FindLocations("RandomVehicleEnemy",true)
	local multiplier = GetInt("level.difficultycoef")/2
	for i=1,#Locations do
		local Location = Locations[i]

		local chance = 11 * multiplier / timerDiv

		if math.random(0,100) <= chance then
			local locTrans = GetLocationTransform(Location)
			local LocRnd = tonumber(GetTagValue(Location, "Loc"))or 0
			local RotRnd = tonumber(GetTagValue(Location, "Rot"))or 0
			RandomizedPosition = Vec(locTrans.pos[1] + math.random(-LocRnd, LocRnd)/100, locTrans.pos[2] , locTrans.pos[3] + math.random(-LocRnd, LocRnd)/100)
			local rotX,rotY,rotZ = GetQuatEuler(locTrans.rot)
			RandomizedRotation = QuatEuler(rotX, rotY + math.random(-RotRnd, RotRnd), rotZ)

			SpawnRandomEnemyVehicle()
		end
		Delete(Location)
	end

	if GetBool("level.procedural.spawn_npc_vehicle") then
		SpawnRandomEnemyVehicle(GetCrosshairWorldPos())
		SetBool("level.procedural.spawn_npc_vehicle", false)
	end

end

function SpawnRandomEnemyVehicle(opt_pos)

	local dist = GetFloat("savegame.mod.distanceProgressed")

	local whichone
	if DayPhase ~= "Night" then

		whichone = "D" .. math.random(1, differentDvehicles)

		if dist > 4000 then

			whichone = "AAF2" -- jeep

		elseif dist > 8000 then

			if math.random() > 0.7 then
				whichone = "AAF1" -- truck
			else
				whichone = "AAF2" -- jeep
			end

		end

	else

		whichone = "DD"..math.random(1, differentDDvehicles)

	end


	local xml = "MOD/prefabs/spawnables/enemy vehicles/Vehicle" ..whichone..".xml"
	local entities = Spawn(xml, Transform(opt_pos or RandomizedPosition, RandomizedRotation or QuatEuler(0, math.random(-180, 180), 0)))
	addSpawnedVehicleXMLToRegistry(entities, xml)

end
function randomFloat(min,max)
	min = tonumber(min) or 0
	max = tonumber(max) or 1
	return math.random()*(max-min)+min
end
function handleCommand(cmd) HandleQuickload(cmd) end
function HandleQuickload(cmd)
	for _, word in ipairs(splitString(cmd, " ")) do
		if word == "quickload" then
			Init_Settings()
		end
		break
	end
end

-- Store spawn xml at vehicle handle number in registry.
function addSpawnedVehicleXMLToRegistry(entities, xml)
	for _, e in ipairs(entities) do
		if GetEntityType(e) == "vehicle" then
			SetString("level.spawnedVehicles." .. e, xml)
			SetTag(e, "path", xml)
			break
		end
	end
end
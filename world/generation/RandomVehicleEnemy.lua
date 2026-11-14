#version 2
#include "script/include/player.lua"
-- (v2) server: timed enemy/civilian/refugee/helicopter vehicle spawns.
-- Debug menu: ui/ConfigMenu.lua writes level.debug.vehicle_event (+ _x/_y/_z); handled in HandleDebugVehicleEvent.
--[[
#include "../../lib/TDSU/tdsu.lua"
#include "../../lib/Settings.lua"
#include "../../lib/Automatic.lua"
]]

local disable_spawning = "savegame.mod.procedural.disable.spawn_roadblocks"


function server.init()

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


function server.tick(dt)
	DayPhase = GetString("level.dayphase")
	HandleDebugVehicleEvent() -- (v2) debug menu buttons work even with spawning disabled / peaceful
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
		SpawnEventHeli(timerDiv, false)
	end


	--AAF
	if SpawnTimer_AAF.time * timerDiv <= 0 then
		MaxTime_aaf = RandomSpreadPercent(math.random(TimerRange_aaf[1],  TimerRange_aaf[2])) * 60
		SpawnTimer_AAF = TimerCreateSeconds(MaxTime_aaf)
		SpawnEventAAF(timerDiv, false)
	end


	--Civ
	if SpawnTimer_Civ.time * timerDiv <= 0 then
		MaxTime_civ = RandomSpreadPercent(math.random(TimerRange_civ[1],  TimerRange_civ[2])) * 60
		SpawnTimer_Civ = TimerCreateSeconds(MaxTime_civ)
		SpawnEventCiv()
	end


	--Refugee
	if SpawnTimer_Refugee.time * timerDiv <= 0 then
		MaxTime_ref = RandomSpreadPercent(math.random(TimerRange_ref[1],  TimerRange_ref[2])) * 60
		SpawnTimer_Refugee = TimerCreateSeconds(MaxTime_ref)
		SpawnEventRefugee()
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

	-- (v2) the debug menu's "Enemy Vehicle" button now goes through HandleDebugVehicleEvent ("roadblock"):
	-- v1 read GetCrosshairWorldPos() here, which needs the camera (client only).

end

-- (v2) The timed events, one function each (used by the timers above and by the debug menu).
-- force = debug menu: ignore the distance / setting conditions.
function SpawnEventHeli(timerDiv, force)
	if not force and not Settings.game.enemy_helicopter.value then return end
	local xml = "MOD/vehicles/aircraft/AS350/AS350_INSURGENT.xml"
	if (DistanceProgressed > 10000 or force) and math.random() * (timerDiv or 1) < 0.5 then
		xml = "MOD/vehicles/aircraft/AS350/AS350_MILITARY.xml"
	end
	local entities = Spawn(xml, Transform(Vec(200,50,3), QuatEuler(0,-90,0)))
	addSpawnedVehicleXMLToRegistry(entities, xml)
end

function SpawnEventAAF(timerDiv, force)
	-- (v2 fix) original left the global 'whichone' unset below 5000 m (crash at the concat
	-- before any civ spawn, otherwise it re-spawned the last civ vehicle). No AAF spawn before 5000 m.
	local whichone = nil
	-- (v2 fix) 8000 m checked first; the original order made the truck branch unreachable.
	if DistanceProgressed > 8000 or force then
		if math.random() * (timerDiv or 1) > 0.7 then
			whichone = "AAF1" -- truck
		else
			whichone = "AAF2" -- jeep
		end
	elseif DistanceProgressed > 5000 then
		whichone = "AAF2" -- jeep
	end

	if whichone then
		local xml = "MOD/prefabs/spawnables/enemy vehicles/Vehicle" .. whichone ..".xml"
		local entities = Spawn(xml, Transform(Vec(-300, 4.5, 3), QuatEuler(0,-90,0)))
		addSpawnedVehicleXMLToRegistry(entities, xml)
	end
end

function SpawnEventCiv()
	local whichone = "D"..math.random(1,differentDvehicles)
	local xml = "MOD/prefabs/spawnables/enemy vehicles/Vehicle" ..whichone..".xml"
	local entities = Spawn(xml, Transform(Vec(-300, 4.5, math.random(-3, 3)), QuatEuler(0,-90,0)))
	addSpawnedVehicleXMLToRegistry(entities, xml)
end

function SpawnEventRefugee(opt_which) -- (v2) opt_which: debug menu "Refugee Van" picks VehicleC3
	local whichone = opt_which or math.random(1, differentCvehicles)
	local xml = "MOD/prefabs/spawnables/enemy vehicles/VehicleC" ..whichone..".xml"
	local entities = Spawn(xml, Transform(Vec(-300,4.5,3), QuatEuler(0,-90,0)))
	addSpawnedVehicleXMLToRegistry(entities, xml)
end

-- (v2) Debug menu request (ui/ConfigMenu.lua server.configVehicleEvent): run one event now.
DEBUG_VEHICLE_EVENT = "level.debug.vehicle_event"
function HandleDebugVehicleEvent()
	local name = GetString(DEBUG_VEHICLE_EVENT)
	if name == "" then return end
	SetString(DEBUG_VEHICLE_EVENT, "")
	DistanceProgressed = GetFloat("savegame.mod.distanceProgressed")
	if name == "heli" then
		SpawnEventHeli(1, true)
	elseif name == "aaf" then
		SpawnEventAAF(1, true)
	elseif name == "civ" then
		SpawnEventCiv()
	elseif name == "refugee" then
		SpawnEventRefugee()
	elseif name == "refugee_van" then
		SpawnEventRefugee(3)
	elseif name == "roadblock" then -- v1 "Enemy Vehicle": a random road enemy vehicle at the crosshair
		local pos = Vec(GetFloat(DEBUG_VEHICLE_EVENT .. "_x"), GetFloat(DEBUG_VEHICLE_EVENT .. "_y"), GetFloat(DEBUG_VEHICLE_EVENT .. "_z"))
		RandomizedPosition, RandomizedRotation = nil, nil
		SpawnRandomEnemyVehicle(pos)
	end
end

function SpawnRandomEnemyVehicle(opt_pos)

	local dist = GetFloat("savegame.mod.distanceProgressed")

	local whichone
	if DayPhase ~= "Night" then

		whichone = "D" .. math.random(1, differentDvehicles)

		-- (v2 fix) 8000 m checked first; the original order made the truck branch unreachable.
		if dist > 8000 then

			if math.random() > 0.7 then
				whichone = "AAF1" -- truck
			else
				whichone = "AAF2" -- jeep
			end

		elseif dist > 4000 then

			whichone = "AAF2" -- jeep

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
function server.handleCommand(cmd) HandleQuickload(cmd) end
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
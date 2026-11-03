--[[
#include "../TDSU/tdsu.lua"
#include "../../Settings.lua"
#include "../../Automatic.lua"
#include "../masterScriptRemoverAPI.lua"
]]

DebugMode = false

Reg_MapVehicles     = "level.spawnedVehicles"
Reg_SavedVehicles   = "savegame.mod.parkingSpot.savedVehicles"
Reg_MaxSpots   		= "savegame.mod.parkingSpot.maxSpots"

Icons_Parking = {
	checkmark   = "MOD/img/icon_checkmark.png",
	cross       = "MOD/img/icon_cross.png",
	error       = "MOD/img/icon_error.png",
	parking     = "MOD/img/icon_parking.png"
}

Slot_Price_List = {
	3000,
	5000,
	7000,
	10000,
}



function init()

	Init_Settings()

	if GetInt(Reg_MaxSpots) <= 0 then
		SetInt(Reg_MaxSpots, 1)
	end

	VehicleFindTimer    = TimerCreateSeconds(1.1, true)
	SafezoneLoadCount   = GetInt("level.safezoneLoadCount")
	ParkingSpotTrigger  = FindTrigger("parkingSpot", false)
	ParkingSpotSprite   = LoadSprite(Icons_Parking.parking)
	ParkingSpotBooth  	= FindBody("garageBooth", false)

	GarageShopUiAlpha = 0
	ShowGarageShopUi = false
	local parkingCam = FindLocation("parkingCamera", false)
	ParkingCameraLocalTransform = TransformToLocalTransform(GetTriggerTransform(ParkingSpotTrigger), GetLocationTransform(parkingCam))
	Delete(parkingCam)

	SavedVehicles 					= GetSavedVehiclesTable() --- Serialized table of vehicles in the registry.
	SavedVehicles_SpotsUnlocked 	= GetInt(Reg_MaxSpots)
	SavedVehicles_SpotsMax 			= #Slot_Price_List + 1
	ChangesMade 					= false -- Determines whether the table should update.

	ParkedVehicles 			  	= {} -- All vehicles in the trigger.
	ParkedVehicleHistory      	= {} --todo If multiple vehicles are on spot and saved vehicle leaves, the last driven vehicle should be saved.
	ParkedVehicleHistoryLimit 	= 10
	IncompatibleVehicles      	= {}
	UnsavedVehicles           	= {}

	PlayerShouldBuyMoreSpots	= false
	MaxSpotsReached				= false
	IconsDrawDist = 50

	PV 					  = GetPlayerVehicle() --- Curent player vehicle.
	LV                    = 0 --- Last vehicle the player drove.


	TrimSavedVehiclesList(SavedVehicles)
	init_saved_vehicles()

end

function tick()
	-- Conditionally disable script
	if STOP_distTooFar or STOP_newSafezone or STOP_triggerDoesNotExist or STOP_map_moved then
		SetTag(ParkingSpotBooth, "interact", "Disabled for: "..(STOP_distTooFar and "Player Too far ahead, " or "")..(STOP_newSafezone and "New Safezone Spawned, " or "")..(STOP_triggerDoesNotExist and "Parking Trigger 404, " or "")..(STOP_map_moved and "Segment shifted, " or ""))
		queueRemoval()
		return
	end
	STOP_distTooFar         	= GetPlayerTransform().pos[1] - GetTriggerTransform(ParkingSpotTrigger).pos[1] > 200
	STOP_newSafezone        	= SafezoneLoadCount < GetInt("level.safezoneLoadCount")
	STOP_triggerDoesNotExist	= not IsHandleValid(ParkingSpotTrigger)
	--STOP_map_moved          	= GetBool("level.map_moved")

	if GetInt(Reg_MaxSpots) <= 0 then
		SetInt(Reg_MaxSpots, 1) -- Ensure at least one spot exists.
	end

	if ShowGarageShopUi and InputPressed("interact") then
		ShowGarageShopUi = false
	end


	SavedVehicles = GetSavedVehiclesTable()


	if SavedVehicles_SpotsUnlocked ~= GetInt(Reg_MaxSpots) then
		ChangesMade = true
		SavedVehicles_SpotsUnlocked = GetInt(Reg_MaxSpots)
	end

	-- Determine which vehicles are stored, ignored and invalid.
	tick_read_scene_info()
	tick_process_parking_spot()
	tick_outline_parked_vehicles()

	if DebugMode then
		garage_debug()
	end

	if ChangesMade then
		TrimSavedVehiclesList(SavedVehicles)
		UpdateSavedVehiclesTable(SavedVehicles)
	end
	ChangesMade = false

	if InputPressed("rmb") or KeybindPressed(Settings.keybinds.inventory.toggle_inv) then
		ShowGarageShopUi = false
	end

end

function draw(dt)

	if STOP_distTooFar or STOP_newSafezone or STOP_triggerDoesNotExist or STOP_map_moved then
		return
	end

	-- Show incompatible vehicle cross icon and error message.
	UiPush()
		for index, v in ipairs(IncompatibleVehicles) do
			local pos = AabbGetBodyCenterTopPos(GetVehicleBody(v))
			if IsInfrontOfTransform(GetCameraTransform(), pos) then
				draw_ui_vehicle_message_error(pos, "Incompatible vehicle! Vehicle must be spawned by the map.", 1,0,0)
			end
		end
	UiPop()

	-- Show unsaved vehicle details.
	UiPush()
		for index, v in ipairs(UnsavedVehicles) do
			local pos = AabbGetBodyCenterTopPos(GetVehicleBody(v))
			if IsInfrontOfTransform(GetCameraTransform(), pos) then
				if v == LV and PlayerShouldBuyMoreSpots then
					draw_ui_vehicle_message_error(pos, "Buy more parking spots at the parking booth.", 1,1,1)
				elseif v == LV and MaxSpotsReached then
					draw_ui_vehicle_message_error(pos, "Max parking spots reached.", 1,0.2,0.2)
				else
					draw_ui_vehicle_parked(pos, Icons_Parking.cross, 1,0,0)
				end
			end
		end
	UiPop()

	-- Show saved vehicle checkmark ui icon.
	UiPush()
		for index, v in ipairs(SavedVehicles) do
			draw_ui_vehicle_parked_new(v.vehicle)
		end
	UiPop()

	-- Draw parking spot sprite.
	UiPush()
		local triggerPos    = VecAdd(GetTriggerTransform(ParkingSpotTrigger).pos, Vec(0,1,0))
		local rotation      = (((GetTime()/3) % 1) * 360)
		local tr            = Transform(triggerPos, QuatEuler(0, rotation, 0))
		local dist			= VecDist(tr.pos, GetCameraTransform().pos)

		if dist < 100 then
			local a = 1-AutoMap(dist, 0, 70, 0, 0.5) + (1-AutoMap(dist, 0, 40, 0.5, 1))
			DrawSprite(ParkingSpotSprite, tr, 2, 2, 1,1,1, a, false)
		end
	UiPop()

	-- draw garage ui
	UiPush()
		if GetPlayerInteractBody() == ParkingSpotBooth then
			if GarageShopUiAlpha < 1 then
				UiPush()
					UiColorFilter(1, 1, 1, 1-GarageShopUiAlpha)
					UiAlign("center top")
					draw_ui_garage_simple_stat()
				UiPop()
			end

			if InputPressed("interact") then
				ShowGarageShopUi = not ShowGarageShopUi
			end
		end

		if InputPressed("esc") or InputPressed("up") or InputPressed("down") or InputPressed("left") or InputPressed("right") then
			ShowGarageShopUi = false
		end
		if ShowGarageShopUi then
			UiMakeInteractive()
			SetBool("game.disablepause", true)
			GarageShopUiAlpha = math.min(GarageShopUiAlpha+dt/0.5,1)
		else
			GarageShopUiAlpha = math.max(GarageShopUiAlpha-dt/0.5,0)
		end

		SetBool("level.parkingSpot.garageUiShowing", GarageShopUiAlpha > 0)
		if GarageShopUiAlpha > 0 then
			UiPush()
				UiColorFilter(1, 1, 1, GarageShopUiAlpha)
				UiTranslate(UiWidth()-20, 20)
				UiAlign("top right")
				draw_ui_garage(UiWidth()/3 - 20,UiHeight()/3 - 20)
			UiPop()
			local parkingCamWorldT = TransformToParentTransform(GetTriggerTransform(ParkingSpotTrigger), ParkingCameraLocalTransform)
			SetCameraTransform(TransformLerp(GetPlayerCameraTransform(),parkingCamWorldT,SmoothTransition(GarageShopUiAlpha)), NumberLerp(GetFloat("options.gfx.fov"),70,SmoothTransition(GarageShopUiAlpha)))
		end
	UiPop()

end



--- Called only when there is a new safezone loaded, otherwise the vehicle objects manages vehicle saving and removing.
function init_saved_vehicles()

	local tMin, tMax = GetTriggerBounds(ParkingSpotTrigger)
	-- local pos = VecLerp(tMin, tMax, 0.5)
	local pos = VecLerp(tMin, tMax, 0.5)
	pos[1] = tMin[1] + 0.5

	-- QueryRequire("static")
	-- local hit, dist = QueryRaycast(pos, Vec(0,-1,0), pos[2]-tMin[2])
	-- pos[2] = ternary(hit, pos[2] - dist, tMin[2])


	for index, savedVehicle in ipairs(SavedVehicles) do

		local spawnPos = VecCopy(pos)
		spawnPos[1] = spawnPos[1] + (index*5)

		local entities = Spawn(savedVehicle.xml, Transform(spawnPos, GetTriggerTransform(ParkingSpotTrigger).rot) , false, false)
		for _, e in ipairs(entities) do
			if GetEntityType(e) == "vehicle" then
				savedVehicle.vehicle = e
				SetTag(e, "path", savedVehicle.xml)
				SetTag(e, "fuelLevel", tonumber(savedVehicle.fuel))
				SetTag(e, "ai_disabled")
				table.insert(ParkedVehicleHistory, e)
			end
			if GetEntityType(e) == "location" then
				if HasTag(e, "RandomLoot") or HasTag(e, "RandomRagdoll") or HasTag(e, "RandomDeceasedBurnt")then -- remove additional procedural shit
					Delete(e)
				end
			end
		end

	end

	UpdateSavedVehiclesTable(SavedVehicles)

end

function tick_read_scene_info()

	-- Find vehicles periodically.
	if TimerConsumed(VehicleFindTimer) then
		AllVehicles = FindVehicles("", true)
		for index, v in ipairs(AllVehicles) do
			if GetString(Reg_MapVehicles .. "." .. v) == "" then
				if HasTag(v, "path") then
					if GetTagValue(v, "path") ~= "" and GetTagValue(v, "path") ~= nil then
						local path = GetTagValue(v, "path")
						SetString(Reg_MapVehicles .. "." .. v, path)
						print("ParkingSpot: Using backup vehicle path: ", path)
					end
				end
			end
		end
	end
	TimerRunTime(VehicleFindTimer, true)


	PV = GetPlayerVehicle()
	LV = ternary(IsPlayerInVehicle(), PV, LV)

	-- Update last vehicle driven in parking spot.
	LastPlayerVehicleInSpot = ternary(IsPointInTrigger(ParkingSpotTrigger, GetVehicleCenterOfMassPos(LV)) and IsCompatibleVehicle(LV), LV, LastPlayerVehicleInSpot)


	-- Maintain list of vehicles in trigger.
	ParkedVehicles = {}
	for _, v in ipairs(AllVehicles) do
		if IsPointInTrigger(ParkingSpotTrigger, GetVehicleCenterOfMassPos(v)) then
			table.insert(ParkedVehicles, v)
			TableInsertUnique(ParkedVehicleHistory, v) -- add new vehicles to end of list.
		else
			TableRemoveUniqueValue(ParkedVehicleHistory, v) -- makes sure vehicles get readded if they reenter the trigger.
		end
	end
	-- Remove oldest vehicle history.
	-- if #ParkedVehicleHistory > ParkedVehicleHistoryLimit then table.remove(ParkedVehicleHistory, #ParkedVehicleHistory) end


	IncompatibleVehicles = {}
	UnsavedVehicles = {}
	for _, v in ipairs(AllVehicles) do
		if IsPointInTrigger(ParkingSpotTrigger, GetVehicleCenterOfMassPos(v)) then
			if IsCompatibleVehicle(v) then
				if not IsSavedVehicle(v) then
					table.insert(UnsavedVehicles, v)
				end
			else
				table.insert(IncompatibleVehicles, v) -- Incompatible vehicles
			end
		end
	end

end

-- Determine which vehicles are stored, ignored and invalid.
function tick_process_parking_spot()

	-- Update last vehicle driven in parking spot.
	if IsPointInTrigger(ParkingSpotTrigger, GetVehicleCenterOfMassPos(LV)) and IsCompatibleVehicle(LV) and not IsSavedVehicle(LV) then

		-- Check spot limits.
		PlayerShouldBuyMoreSpots = false
		MaxSpotsReached = false
		if SavedVehicles_SpotsUnlocked < SavedVehicles_SpotsMax then
			PlayerShouldBuyMoreSpots = true
			DrawBodyOutline(ParkingSpotBooth, 1,1,1, 1)
			DrawBodyHighlight(ParkingSpotBooth, Oscillate())
		elseif SavedVehicles_SpotsUnlocked == SavedVehicles_SpotsMax then
			MaxSpotsReached = true
		else
			InsertNewSavedVehicle(LV) -- Save valid vehicles.
		end

	end

	-- Fill any unsaved vehicles if they can be saved.
	if #SavedVehicles < SavedVehicles_SpotsUnlocked and #ParkedVehicleHistory > #SavedVehicles then
		for index, historyVehicle in ipairs(ParkedVehicleHistory) do

			InsertNewSavedVehicle(historyVehicle)

			if #SavedVehicles == SavedVehicles_SpotsUnlocked then
				break
			end

		end
	end

	-- Saved vehicle has left the trigger.
	for index, savedVehicle in ipairs(SavedVehicles) do

		if PV == savedVehicle.vehicle then -- Update fuel value in real-time
			savedVehicle.fuel = GetTagValue(PV, "fuelLevel")
			ChangesMade = true
		end

		if not TableContainsValue(ParkedVehicleHistory, savedVehicle.vehicle) then
			RemoveSavedVehicle(savedVehicle.vehicle)
		end

	end

end

---Outline vehicles in parking spot.
function tick_outline_parked_vehicles()
	-- DrawBodyOutline(GetVehicleBody(vehicle), 0,1,0, 1) -- Saved vehicle in spot.
	-- DrawBodyOutline(GetVehicleBody(vehicle), 1,0,0, 1)
end



---Add a new unique vehicle to the saved vehicles table.
function InsertNewSavedVehicle(v)
	if not IsSavedVehicle(v) then

		local xml = GetTagValue(v, "path")
		if xml == "" then xml = GetString(Reg_MapVehicles .. "." .. v) end

		local vehicleObject = CreateVehicleObject(v, xml, GetTagValue(v, "fuelLevel"))
		table.insert(SavedVehicles, vehicleObject)
		ChangesMade = true
	end
end

function CreateVehicleObject(vehicle, xml, fuel)
	return {
		vehicle = vehicle,
		xml 	= xml,
		fuel 	= fuel
	}
end

function RemoveSavedVehicle(v)
	local rmIndex = nil
	for index, storedVehicle in ipairs(SavedVehicles) do
		if storedVehicle.vehicle == v then
			rmIndex = index
		end
	end
	table.remove(SavedVehicles, rmIndex)
	ChangesMade = true
end

---Returns the unserialized saved vehicles table.
function GetSavedVehiclesTable()
	if GetString(Reg_SavedVehicles) ~= "" then
		return util.unserialize(GetString(Reg_SavedVehicles))
	else
		print("ParkingSpot: Saved vehicles registry is empty. Setting empty table.")
		UpdateSavedVehiclesTable({})
		return {}
	end
end

---Serializes saved vehicles table in the registry.
function UpdateSavedVehiclesTable(tb)
	SetString(Reg_SavedVehicles, util.serialize(tb))
	ChangesMade = true
end

---Remove any saved vehicles older than the max limit.
function TrimSavedVehiclesList(vehicles)

	--todo create a check to make sure table is an array.

	-- Remove all vehicles past max limit.
	local iterations = clamp(#vehicles - SavedVehicles_SpotsUnlocked, 0, math.huge)
	for i = 1, iterations do
		local rmVal = table.remove(SavedVehicles, 1)
	end

	local newSavedVehicles = {}
	for index, savedVehicle in pairs(SavedVehicles) do
		if savedVehicle.xml == "" or savedVehicle.vehicle == nil then
			print("ParkingSpot: Removed empty/invalid vehicle.")
		else
			table.insert(newSavedVehicles, savedVehicle)
		end
	end

	SavedVehicles = DeepCopy(newSavedVehicles) -- New valid version of the table.

	if DebugMode then
		print("#vehicles", #vehicles)
		print("SavedVehicles_MaxCount", SavedVehicles_SpotsUnlocked)
		print("iterations", iterations)
		for index, savedVehicle in ipairs(SavedVehicles) do
			print(index, savedVehicle.vehicle)
		end
		print()
	end

end



---@param v number
---@return boolean
function IsCompatibleVehicle(v) return GetString(Reg_MapVehicles .. "." .. v) ~= "" or GetTagValue(v, "path") ~= "" end

---@param v number
---@return boolean
function IsSavedVehicle(v)
	for index, savedVehicle in ipairs(SavedVehicles) do
		if v == savedVehicle.vehicle then
			return true
		end
	end
	return false
end



function draw_ui_vehicle_message_error(pos, text, r,g,b)
	UiPush()

		local x, y = UiWorldToPixel(pos)
		UiTranslate(x, y)
		UiAlign("center middle")

		local dist = VecDist(GetCameraTransform().pos, pos) -- Display text when close
		local lookAngle = quat_angle(GetCameraTransform().rot, QuatLookAt(GetCameraTransform().pos, pos)) * 100
		if dist < IconsDrawDist/2 and lookAngle < 30 then

			local fs = 24
			uiSetFont(fs)
			UiWordWrap(300)

			UiColor(0,0,0,0)
			local mx, my = UiText(text)
			UiColor(0,0,0, 0.5)
			UiRect(mx, my)

			UiColor(r,g,b, 1)
			UiText(text)

		else -- Show flashing X.

			if GetTime() % 1 > 0.5 then

				UiColor(0,0,0, 0.5)
				UiRect(50,50)

				UiColor(1,0,0, 1)
				UiImageBox(Icons_Parking.error, 40,40)

			end

		end

	UiPop()
end

function draw_ui_vehicle_parked(pos, icon, r,g,b)
	UiPush()

		local x, y = UiWorldToPixel(pos)
		UiTranslate(x, y)
		UiAlign("center middle")

		local dist = VecDist(GetCameraTransform().pos, pos) -- Display text when close
		if dist < IconsDrawDist then

			local s = 50 - (dist/2)

			UiColor(0,0,0, 0.5)
			UiRect(s, s)

			UiColor(r,g,b, 1)
			UiImageBox(icon, s,s)

		end

	UiPop()
end

function draw_ui_vehicle_parked_new(v)
	local pos = AabbGetBodyCenterTopPos(GetVehicleBody(v))
	pos[2] = pos[2] + 1
	local x, y, dist = UiWorldToPixel(pos)
	if dist > 0 then
		local alpha = (1-AutoMap(dist, 0, 120, 0.2, 1) + (1-AutoMap(dist, 0, 40, 0, 1))) - 0.2
		if IsPlayerInVehicle() and IsPointInTrigger(ParkingSpotTrigger, GetVehicleCenterOfMassPos(PV)) then
			alpha = 1
		end
		if alpha > 0 then
			UiPush()
				UiTranslate(x, y)
				UiAlign("center middle")

				UiColorFilter(1, 1, 1, alpha)

				local s = clamp((40 - (dist/2)) + AutoMap(dist, 10, 40, 40, 0), 30, math.huge)
				s = clamp(s - quat_angle(GetCameraTransform().rot, QuatLookAt(GetCameraTransform().pos, pos)) * 10, 30, math.huge)


				UiColor(0,0,0, 0.5)
				UiRect(s*2.5+10, s+10)
				UiTranslate(-s*.75)

				UiRect(s, s)
				UiColor(0,1,0, 1)
				UiImageBox(Icons_Parking.checkmark, s,s)

				local curFuel = tonumber(GetTagValue(v, "fuelLevel")) or 0
				local maxFuel = tonumber(GetTagValue(v, "fuelLevelMAX")) or 100
				local fuelVal = curFuel/maxFuel
				UiTranslate(s*0.75)
				UiAlign("left middle")

				UiColor(0,0,0, 1)
				UiImageBox("MOD/img/semi_circle.png", s/2,s)
				UiImageBox("MOD/img/semi_ring.png", s/2,s)
				--if InputDown(",")then fuelVal=(GetTime()/2)%1 end
				if fuelVal>0 then
					UiColor(unpack(VecNormalize(VecLerp(Vec(1,0,0), Vec(0,1,0), fuelVal))))
					UiPush()
						UiWindow(s/2,s,true,true)
						UiTranslate(0, s/2)
						UiAlign("left middle")
						UiRotate(180*fuelVal-180)
						UiImageBox("MOD/img/semi_ring.png", s/2,s)
					UiPop()
				end
				UiColor(1,1,1, 1)
				UiAlign("center middle")
				UiImageBox("MOD/img/icon_gas_pump.png", s/2,s/2)

				local vHealth = GetVehicleHealth(v)
				UiTranslate(s*0.75)
				UiAlign("left middle")
				UiColor(0,0,0, 1)
				UiImageBox("MOD/img/semi_circle.png", s/2,s)
				UiImageBox("MOD/img/semi_ring.png", s/2,s)
				--if InputDown(",")then vHealth=(GetTime()/2)%1 end
				if vHealth>0 then
					UiColor(unpack(VecNormalize(VecLerp(Vec(1,0,0), Vec(0,1,0), vHealth))))
					UiPush()
						UiWindow(s/2,s,true,true)
						UiTranslate(0, s/2)
						UiAlign("left middle")
						UiRotate(180*vHealth-180)
						UiImageBox("MOD/img/semi_ring.png", s/2,s)
					UiPop()
				end
				UiColor(1,1,1, 1)
				UiAlign("center middle")
				UiImageBox("MOD/img/icon_spanner.png", s/2,s/2)

			UiPop()

		end
	end
end

function draw_ui_garage(w,h)

	local playerMoney = GetInt("savegame.mod.player.money")

	UiPush()
		UiWindow(w, h, true, true) -- UiWindow will relocate cursor to the top left of this window
		UiAlign("left top")
		UiColor(0,0,0,0.8)
		UiImageBox("ui/common/box-solid-6.png", UiWidth(), UiHeight(), 6, 6)

		UiTranslate(20, 10)

		UiPush()
			UiTranslate(0, 32)
			UiAlign("left")
			UiFont("regular.ttf", 32)
			UiColor(1, 1, 1)
			UiText("Garage")
			UiTranslate(0, 32 + 4)
			UiColor(0, 1, 0)
			UiText("$" .. sfnCommas(playerMoney))
		UiPop()

		UiPush()

			UiAlign("left bottom")

			UiTranslate(0, 180)
			UiFont("regular.ttf", 32)
			UiButtonImageBox("ui/common/box-outline-6.png", 6, 6, 1,1,1,1)
			UiButtonHoverColor(1,1,.6)
			if SavedVehicles_SpotsUnlocked < SavedVehicles_SpotsMax then

				local cost = Slot_Price_List[SavedVehicles_SpotsUnlocked]
				local canBuy = playerMoney >= cost
				if canBuy then
					UiColor(1,1,1, 1)
				else
					UiColor(1,0,0, 1)
				end

				if UiTextButton("Purchase slot: $"..sfnCommas(tostring(cost)), (w-20)*0.5-20, 50)then
					if canBuy then
						SetFloat("savegame.mod.player.money", playerMoney - cost)
						SetInt(Reg_MaxSpots, SavedVehicles_SpotsUnlocked+1)
						UiSound("MOD/snd/UI/UI_Shop_Cash.ogg")
					else
						UiSound("error.ogg")
					end
				end
			else
				UiTranslate(0, -10)
				UiColor(1,1,1, 1)
				UiFont("regular.ttf", 32)
				UiText("All Spots Purchased")
			end
		UiPop()

		UiPush()
			UiTranslate((w-20)*0.75, 150)
			UiAlign("center")
			UiFont("bold.ttf", 128)
			UiColor(1, 1, 1)
			UiText(SavedVehicles_SpotsUnlocked.."/" .. SavedVehicles_SpotsMax)
			UiTranslate(0, 30)
			UiFont("regular.ttf", 32)
			UiText("Spots Owned")
		UiPop()
	UiPop()
end

function draw_ui_garage_simple_stat()
	local x, y, dist = UiWorldToPixel(GetBodyTransform(ParkingSpotBooth).pos)
	if dist>0 then
		UiPush()
			UiTranslate(x, y+20)
			local displayText = "Spots owned: "..SavedVehicles_SpotsUnlocked .. "/" .. SavedVehicles_SpotsMax
			UiFont("regular.ttf", 32)
			local w, h = UiGetTextSize(displayText)
			UiWindow(w+20, 42) -- UiWindow will relocate cursor to the top left of this window
			UiAlign("left top")
			UiColor(0,0,0,0.7)
			UiImageBox("ui/common/box-solid-6.png", UiWidth(), UiHeight(), 6, 6)

			UiTranslate(10, 32)
			UiAlign("left")
			UiColor(1, 1, 1)
			UiText(displayText)
		UiPop()
	end
end



function garage_debug()

	DebugWatch("PV", PV)
	DebugWatch("LV", LV)
	DebugWatch("SavedVehicles_MaxCount", SavedVehicles_SpotsUnlocked)
	DebugWatch("#SavedVehicles", #SavedVehicles)
	DebugWatch("ParkedVehicleHistory", table.concat(ParkedVehicleHistory, ", "))

	-- if InputPressed("i") then
	-- 	InsertNewSavedVehicle(GetRandomArrayValue(AllVehicles))
	-- 	-- PrintTable(SavedVehicles)
	-- elseif InputPressed("o") then
	-- 	table.remove(SavedVehicles, 1)
	-- 	PrintTable(SavedVehicles)
	-- elseif InputPressed("k") then
	-- 	ClearKey(Reg_SavedVehicles)
	-- 	SavedVehicles = {}
	-- end

	-- if InputPressed("p") then
	-- 	print("reg table:")
	-- 	PrintTable(SavedVehicles)
	-- 	print()
	-- end

	-- if InputPressed("i") then
	-- 	SetInt(Reg_MaxSpots, GetInt(Reg_MaxSpots) + 1)
	-- elseif InputPressed("o") then
	-- 	SetInt(Reg_MaxSpots, 1)
	-- end
end

---@param t1 table
---@param t2 table
---@param f number
---@return table
function TransformLerp(t1,t2,f)
	return Transform(VecLerp(t1.pos,t2.pos,f),QuatSlerp(t1.rot,t2.rot,f))
end

---@param a number
---@param b number
---@param f number
---@return number
function NumberLerp(a,b,f)
	return a*(1-f)+b*f
end

---@param f number
---@return number
function SmoothTransition(f)
	return .5-math.cos(f*math.pi)/2
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

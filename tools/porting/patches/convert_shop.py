#!/usr/bin/env python3
"""Phase 3 batch B (shop area + supply plane) v1 -> v2. In place, each file once (asserts v1).

* convert_server.convert (callbacks -> server.*, asserted edits): WarehouseScript_Cultist, AC130.
* Hand-written v2 (whole file replaced, the v1 code kept where it still applies): SafeZone, PerkMachine,
  ParkingSpot - see the comments at the top of each file.
Usage (repo root): python3 tools/porting/patches/convert_shop.py [file ...]
"""
import os, sys
sys.path.insert(0, os.path.dirname(__file__))
from convert_server import convert

EDITS = {
"scripts/Game/WarehouseScript_Cultist.lua": ("server: cultist warehouse; the boss ambush triggers when ANY player enters.", [
    ("""	if Triggered then
		queueRemoval()
		return
	end

	local PlayerPos = GetPlayerTransform().pos
""", """	if Triggered then
		return -- (v2) v1 queueRemoval() (pause-menu handle trick) does not work on the server: just stop
	end

	local PlayerPos = nil -- (v2) any player inside the trigger
	for p in Players() do
		if IsPointInTrigger(boss_trigger, GetPlayerTransform(p).pos) then PlayerPos = GetPlayerTransform(p).pos end
	end
	if PlayerPos == nil then return end
"""),
]),
"scripts/Game/AC130.lua": ("server: supply plane flies over, drops crates when the NEAREST player is within 300 m, despawns.", [
    (" function init()", "function init()"), # v1 has a leading space, which convert() would not rename (found by test_shop)
    ("    a = GetPlayerCameraTransform()\n", "    -- (v2) removed unused a = GetPlayerCameraTransform()\n"),
    ("local playerPos = GetPlayerTransform().pos\nlocal planePos = GetBodyTransform(planeBody).pos\nlocal dist = VecLength(VecSub(playerPos, planePos))  \n",
     "local planePos = GetBodyTransform(planeBody).pos\nlocal dist = math.huge -- (v2) nearest player\nfor p in Players() do dist = math.min(dist, VecLength(VecSub(GetPlayerTransform(p).pos, planePos))) end\n"),
]),
}

PARKING = "scripts/Game/ParkingSpot.lua"
PARKING_EDITS = [
("""--[[
#include "../TDSU/tdsu.lua\"""", """#version 2
#include "script/include/player.lua"
-- (v2) Garage / parking spot (shop segment). ONE shared garage, saved in the host's savegame
-- (savegame.mod.parkingSpot.*), run by the SERVER: saved vehicles are respawned at each new shop, any player's vehicle
-- parked on the spot is saved, fuel is tracked, the spot disables itself when every player is 200 m past it.
-- The server publishes what the clients draw in shared.garage (GaragePublish). CLIENT: icons over vehicles, parking
-- sprite, booth hint, garage UI + booth camera; buying a spot pays from the buyer's own money (savegame, per
-- player) and asks the server (server.garageBuySpot), which refunds if the spot count changed meanwhile.
--[[
#include "../TDSU/tdsu.lua\""""),
("function init()\n\n\tInit_Settings()\n", "function server.init()\n\n\tInit_Settings()\n"),
("\tParkingSpotSprite   = LoadSprite(Icons_Parking.parking)\n", ""),
("""	PV 					  = GetPlayerVehicle() --- Curent player vehicle.
	LV                    = 0 --- Last vehicle the player drove.
""", """	LVs                   = {} --- (v2) [player] = last vehicle that player drove (v1: PV / LV of the one player)
	Hints                 = {} --- (v2) [player] = { lv = vehicle, hint = "buy" | "max" } for the garage hints
"""),
("""function tick()
	-- Conditionally disable script
	if STOP_distTooFar or STOP_newSafezone or STOP_triggerDoesNotExist or STOP_map_moved then
		SetTag(ParkingSpotBooth, "interact", "Disabled for: "..(STOP_distTooFar and "Player Too far ahead, " or "")..(STOP_newSafezone and "New Safezone Spawned, " or "")..(STOP_triggerDoesNotExist and "Parking Trigger 404, " or "")..(STOP_map_moved and "Segment shifted, " or ""))
		queueRemoval()
		return
	end
	STOP_distTooFar         	= GetPlayerTransform().pos[1] - GetTriggerTransform(ParkingSpotTrigger).pos[1] > 200
""", """function server.tick()
	if Stopped then return end
	-- Conditionally disable script
	if STOP_distTooFar or STOP_newSafezone or STOP_triggerDoesNotExist or STOP_map_moved then
		local reason = "Disabled for: "..(STOP_distTooFar and "Player Too far ahead, " or "")..(STOP_newSafezone and "New Safezone Spawned, " or "")..(STOP_triggerDoesNotExist and "Parking Trigger 404, " or "")..(STOP_map_moved and "Segment shifted, " or "")
		SetTag(ParkingSpotBooth, "interact", reason)
		Stopped = true -- (v2) v1 queueRemoval() (pause-menu handle trick) does not work on the server: just stop
		GaragePublish(reason)
		return
	end
	local rearmostX = math.huge -- (v2) disabled when EVERY player is 200 m past it
	for p in Players() do rearmostX = math.min(rearmostX, GetPlayerTransform(p).pos[1]) end
	STOP_distTooFar         	= rearmostX ~= math.huge and rearmostX - GetTriggerTransform(ParkingSpotTrigger).pos[1] > 200
"""),
("""	if ShowGarageShopUi and InputPressed("interact") then
		ShowGarageShopUi = false
	end


	SavedVehicles = GetSavedVehiclesTable()
""", """	SavedVehicles = GetSavedVehiclesTable()
"""),
("""	ChangesMade = false

	if InputPressed("rmb") or KeybindPressed(Settings.keybinds.inventory.toggle_inv) then
		ShowGarageShopUi = false
	end

end

function draw(dt)

	if STOP_distTooFar or STOP_newSafezone or STOP_triggerDoesNotExist or STOP_map_moved then
		return
	end
""", """	ChangesMade = false

	GaragePublish("")

end

-- (v2) v1 draw(), now client only: called from client.draw with the v1 globals filled from shared.garage.
function GarageDraw(dt)
"""),
("""	PV = GetPlayerVehicle()
	LV = ternary(IsPlayerInVehicle(), PV, LV)

	-- Update last vehicle driven in parking spot.
	LastPlayerVehicleInSpot = ternary(IsPointInTrigger(ParkingSpotTrigger, GetVehicleCenterOfMassPos(LV)) and IsCompatibleVehicle(LV), LV, LastPlayerVehicleInSpot)
""", """	-- (v2) last vehicle driven, per player (v1: PV / LV; LastPlayerVehicleInSpot was never read)
	for p in Players() do
		local pv = GetPlayerVehicle(p)
		if pv ~= 0 then LVs[p] = pv end
	end
"""),
("""	-- Update last vehicle driven in parking spot.
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
""", """	-- Update last vehicle driven in parking spot. (v2) per player; the booth outline and messages are drawn by that
	-- player's client from shared.garage.hint
	Hints = {}
	for p, LV in pairs(LVs) do
		if IsHandleValid(LV) and IsPointInTrigger(ParkingSpotTrigger, GetVehicleCenterOfMassPos(LV)) and IsCompatibleVehicle(LV) and not IsSavedVehicle(LV) then

			-- Check spot limits.
			if SavedVehicles_SpotsUnlocked < SavedVehicles_SpotsMax then
				Hints[p] = { lv = LV, hint = "buy" }
			elseif SavedVehicles_SpotsUnlocked == SavedVehicles_SpotsMax then
				Hints[p] = { lv = LV, hint = "max" }
			else
				InsertNewSavedVehicle(LV) -- Save valid vehicles.
			end

		end
	end
"""),
("""		if PV == savedVehicle.vehicle then -- Update fuel value in real-time
""", """		if AnyPlayerInVehicle(savedVehicle.vehicle) then -- Update fuel value in real-time (v2: any player driving it)
"""),
('\t\t\tsavedVehicle.fuel = GetTagValue(PV, "fuelLevel")\n',
 '\t\t\tsavedVehicle.fuel = GetTagValue(savedVehicle.vehicle, "fuelLevel") -- (v2) was PV (the one player\'s vehicle)\n'),
('\tDebugWatch("PV", PV)\n\tDebugWatch("LV", LV)\n', '\tDebugWatch("LVs", util.serialize(LVs)) -- (v2)\n'),
("""					if canBuy then
						SetFloat("savegame.mod.player.money", playerMoney - cost)
						SetInt(Reg_MaxSpots, SavedVehicles_SpotsUnlocked+1)
						UiSound("MOD/snd/UI/UI_Shop_Cash.ogg")
""", """					if canBuy then
						-- (v2) pay from this player's money (v1 wrote it with SetFloat), the server adds the spot
						SetInt("savegame.mod.player.money", playerMoney - cost)
						ServerCall("server.garageBuySpot", GetLocalPlayer(), SavedVehicles_SpotsUnlocked, cost)
						UiSound("MOD/snd/UI/UI_Shop_Cash.ogg")
"""),
("""function handleCommand(cmd) HandleQuickload(cmd) end
""", """-- (v2) no handleCommand/quickload in v2
"""),
]

PARKING_APPEND = """

------------------------------------------------------------------
-- (v2) Server <-> client
------------------------------------------------------------------

function AnyPlayerInVehicle(v)
	for p in Players() do
		if GetPlayerVehicle(p) == v then return true end
	end
	return false
end

--- Server: publish what the clients draw (only when it changed).
function GaragePublish(stopReason)
	local saved = {}
	for i, sv in ipairs(SavedVehicles) do saved[i] = { vehicle = sv.vehicle } end
	local hint = {}
	for p, h in pairs(Hints) do hint[tostring(p)] = h end
	local g = {
		stop = stopReason or "",
		unlocked = SavedVehicles_SpotsUnlocked,
		max = SavedVehicles_SpotsMax,
		saved = saved,
		unsaved = UnsavedVehicles,
		incompatible = IncompatibleVehicles,
		hint = hint,
		cam = ParkingCameraLocalTransform,
	}
	local sig = util.serialize(g)
	if sig ~= GaragePublished then
		GaragePublished = sig
		shared.garage = g
	end
end

--- Server: a client paid `paid` for the next spot; `expected` = the spot count it saw.
function server.garageBuySpot(p, expected, paid)
	local unlocked = GetInt(Reg_MaxSpots)
	if not Stopped and unlocked == expected and unlocked < SavedVehicles_SpotsMax then
		SetInt(Reg_MaxSpots, unlocked + 1)
	else
		ClientCall(p, "client.garageRefund", p, paid)
	end
end

function client.garageRefund(target, amount)
	local me = GetLocalPlayer()
	if target ~= me and not (target == 0 and IsPlayerHost(me)) then return end
	SetInt("savegame.mod.player.money", GetInt("savegame.mod.player.money") + amount)
end

function client.init()
	Init_Settings()
	ParkingSpotTrigger  = FindTrigger("parkingSpot", false)
	ParkingSpotSprite   = LoadSprite(Icons_Parking.parking)
	ParkingSpotBooth    = FindBody("garageBooth", false)
	GarageShopUiAlpha   = 0
	ShowGarageShopUi    = false
	SavedVehicles, UnsavedVehicles, IncompatibleVehicles = {}, {}, {}
	SavedVehicles_SpotsUnlocked, SavedVehicles_SpotsMax = 1, #Slot_Price_List + 1
	LV, PV = 0, 0
	IconsDrawDist = 50
end

function client.tick(dt)
	-- v1 tick's UI handling (runs before draw, as in v1)
	if ShowGarageShopUi and InputPressed("interact") then
		ShowGarageShopUi = false
	end
	if InputPressed("rmb") or KeybindPressed(Settings.keybinds.inventory.toggle_inv) then
		ShowGarageShopUi = false
	end
end

function client.draw(dt)
	local g = shared.garage
	if not g or g.stop ~= "" then
		if GarageShopUiAlpha > 0 or ShowGarageShopUi then
			ShowGarageShopUi, GarageShopUiAlpha = false, 0
			SetBool("level.parkingSpot.garageUiShowing", false)
		end
		return
	end
	-- the v1 globals GarageDraw and its helpers use
	SavedVehicles                = g.saved or {}
	UnsavedVehicles              = g.unsaved or {}
	IncompatibleVehicles         = g.incompatible or {}
	SavedVehicles_SpotsUnlocked  = g.unlocked or 1
	SavedVehicles_SpotsMax       = g.max or (#Slot_Price_List + 1)
	ParkingCameraLocalTransform  = g.cam or Transform()
	local h = (g.hint or {})[tostring(GetLocalPlayer())]
	LV                           = h and h.lv or 0
	PlayerShouldBuyMoreSpots     = h ~= nil and h.hint == "buy"
	MaxSpotsReached              = h ~= nil and h.hint == "max"
	PV                           = GetPlayerVehicle()
	if PlayerShouldBuyMoreSpots then -- v1 drew this in tick
		DrawBodyOutline(ParkingSpotBooth, 1,1,1, 1)
		DrawBodyHighlight(ParkingSpotBooth, Oscillate())
	end
	GarageDraw(dt)
end
"""

def convert_parking():
    import re
    b = open(PARKING, "rb").read().decode("utf-8")
    crlf = "\r\n" in b
    t = b.replace("\r\n", "\n")
    assert not t.startswith("#version"), "ParkingSpot already v2"
    for old, new in PARKING_EDITS:
        n = t.count(old)
        assert n == 1, f"ParkingSpot: expected 1x {old[:70]!r}, found {n}"
        t = t.replace(old, new)
    t = t.rstrip("\n") + "\n" + PARKING_APPEND
    assert re.search(r'\nfunction (init|tick|update|draw|handleCommand)\(', t) is None
    if crlf:
        t = t.replace("\n", "\r\n")
    open(PARKING, "wb").write(t.encode("utf-8"))
    print("converted", PARKING)

if __name__ == "__main__":
    for f in sys.argv[1:] or (list(EDITS) + [PARKING]):
        if f == PARKING:
            convert_parking()
            continue
        note, edits = EDITS[f]
        convert(f, edits, note)

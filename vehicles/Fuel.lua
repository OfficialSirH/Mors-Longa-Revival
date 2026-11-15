#version 2
#include "script/include/player.lua"
#include "../lib/Settings.lua"

-- (v2) Split. Fuel lives in vehicle / gas can tags, so the server owns it: random start fuel, consumption
-- (any driving player, from their own throttle input), running dry (SetPlayerVehicle is server-only),
-- refueling from a held gas can and siphoning (client asks with server.fuelSiphon), can leaking/health.
-- Clients: outlines, fuel line + sound, fuel bar registry for the HUD (FuelScript.*), gas can bar.
-- v1 cleared the can's "interact" tag in draw to hide the engine prompt; a client can't change server
-- entities, so the engine prompt now shows the fuel text and the client only draws the bar.
-- Original behaviour kept: `not GetString(...) == "hardcore"` is always false (start fuel always 1-35 %),
-- fuelCanUpdate tags the nil global `Vehicle` (no-op).

---------------------------------------------------------------- server

function server.init()
	Init_Settings()

	currentFuel = 0
	FuelMoney = {}   -- [player] = money earned selling fuel, not yet sent (see FlushFuelMoney)
	infiniteFuel = HasKey('level.gamerule.infuel') and GetBool('level.gamerule.infuel') or false
	SetBool('level.InfiniteFuel',infiniteFuel,true)

	fuelCanUpdate()
	if not GetString("savegame.mod.difficulty") == "hardcore" then
		minPercent = 2.5
		maxPercent = 50
	else
		minPercent = 1
		maxPercent = 35
	end
end

function server.tick(dt)
	SetBool('level.InfiniteFuel', GetBool("savegame.mod.config.game.inf_fuel"), true)
	infiniteFuel = GetBool('level.InfiniteFuel')

	fuelConsumptionMultiplier = 1 / (1 + GetInt("savegame.mod.perks.experienceddriver"))
	if GetInt("savegame.mod.perks.experienceddriver") == 10 then
		fuelConsumptionMultiplier = 0
	end

	fuelCanUpdate()
	local allVehicles = FindVehicles("", true)
	for i=1,#allVehicles do
		local Vehicle = allVehicles[i]
		if not HasTag(Vehicle, "fuelLevelMAX") then
			SetTag(Vehicle, "fuelLevelMAX", 100)
		end

		if not HasTag(Vehicle, "fuelLevel") then
			local percent = minPercent*.01 + math.random()*(maxPercent-minPercent)*.01
			SetTag(Vehicle, "fuelLevel", percent*tonumber(GetTagValue(Vehicle, "fuelLevelMAX")))
		end

		if not infiniteFuel then
			local throttle = tonumber(GetTagValue(Vehicle, "drive"))
			if throttle and throttle>0 then
				SetTag(Vehicle, "AlarmTriggered")
				local currentFuel = tonumber(GetTagValue(Vehicle, "fuelLevel"))
				local baseFuelConsumption = tonumber(GetTagValue(Vehicle, "fuelConsumption")) or 0.25
				currentFuel=currentFuel-baseFuelConsumption*math.abs(throttle)*dt*fuelConsumptionMultiplier
				if currentFuel > 0 then
					SetTag(Vehicle,"fuelLevel",currentFuel)
				else
					SetTag(Vehicle,"fuelLevel",0)
				end
			end
		end
		SetTag(Vehicle, "drive", 0)
		SetTag(Vehicle, "turn", 0)
		SetTag(Vehicle, "brake", 0)
	end

	for p in Players() do
		-- refuel from a held gas can
		local gasCan = GetPlayerGrabBody(p)
		if HasTag(gasCan, "GasCan") and GetPlayerInteractBody(p) == gasCan then
			local target = GasCanTarget(gasCan)
			if target ~= 0 then
				updateGasCanInteractText(gasCan,"Refuel")
				if InputDown("interact", p) then
					local fuelTransfered=refuel(gasCan,target,nil,p)
					if fuelTransfered~=0 then
						updateGasCanInteractText(gasCan,"Refueling")
					end
				end
			end
		end

		-- the vehicle this player drives
		local playerVehicle = GetPlayerVehicle(p)
		if playerVehicle ~= 0 then
			SetTag(playerVehicle, "AlarmTriggered")
			local throttle = InputValue("up", p) - InputValue("down", p)
			if not infiniteFuel then
				local currentFuel = tonumber(GetTagValue(playerVehicle, "fuelLevel")) or 0
				local baseFuelConsumption = tonumber(GetTagValue(playerVehicle, "fuelConsumption")) or 0.25
				currentFuel=currentFuel-baseFuelConsumption*math.abs(throttle)*dt*fuelConsumptionMultiplier
				if currentFuel > 0 then
					SetTag(playerVehicle,"fuelLevel",currentFuel)
				else
					SetTag(playerVehicle,"fuelLevel",0)
					SetPlayerVehicle(0, p)
				end
			end
		end
	end
	FlushFuelMoney()
end

-- whole dollars earned since the last send go to the seller's machine (at most one call per player per tick)
function FlushFuelMoney()
	for p, amount in pairs(FuelMoney) do
		local whole = math.floor(amount)
		if whole >= 1 then
			ClientCall(p, "client.fuelMoney", whole)
			FuelMoney[p] = amount - whole
		end
	end
	for p in PlayersRemoved() do FuelMoney[p] = nil end
end

function client.fuelMoney(amount)
	SetInt("savegame.mod.player.money", GetInt("savegame.mod.player.money") + amount)
end

-- client holds the siphon key while driving
function server.fuelSiphon(p)
	local v = GetPlayerVehicle(p)
	if v ~= 0 then SiphonFuel(v) end
end

-- what a held gas can touches: a vehicle (refuel it) or another gas can (pour over). 0 = nothing
function GasCanTarget(gasCan)
	local gasCanTrans = GetBodyTransform(gasCan)
	QueryRejectBody(gasCan)
	local hit, pos, normal, shape = QueryClosestPoint(gasCanTrans.pos, 1)
	if hit then
		local shapeBody = GetShapeBody(shape)
		local shapeVehicle = GetBodyVehicle(shapeBody)
		if shapeVehicle ~= 0 then return shapeVehicle, shapeBody end
		if HasTag(shapeBody,"GasCan") then return shapeBody, shapeBody end
	end
	return 0, 0
end

---------------------------------------------------------------- client

function client.init()
	Init_Settings()
	fuelsnd = LoadLoop("MOD/assets/snd/Fueling.ogg")
	fuelBarFade=0
	pulseVal=0
	lastInfiniteFuelChangeTime=-100
	displayFuelAmmount=0
end

function client.tick(dt)
	SetInt('FuelScript.vehicleToDraw',0)
	infiniteFuel = GetBool('level.InfiniteFuel')
	gDrawFuelBar = false

	-- leaking gas cans
	for _, gasCan in pairs(FindBodies("GasCan",true)) do
		if HasTag(gasCan, "bodyOriginalVoxelCount") then
			local health = getBodyHealth(gasCan)
			local fuelLevel = tonumber(GetTagValue(gasCan,"fuelLevel")) or 0
			local fuelLevelMAX = tonumber(GetTagValue(gasCan,"fuelLevelMAX")) or 100
			if health < 1 and health >= .75 then
				PlayLoop(fuelsnd,GetBodyTransform(gasCan).pos,math.min(fuelLevel,fuelLevelMAX*(1-health)/60))
			end
		end
	end

	local gasCan = GetPlayerGrabBody()
	if HasTag(gasCan, "GasCan") then
		DrawBodyOutline(gasCan, 1)
		if GetPlayerInteractBody() == gasCan then
			local target, targetBody = GasCanTarget(gasCan)
			if target ~= 0 then
				if GetBodyVehicle(targetBody) ~= 0 then
					gDrawFuelBar=true
					vehicleFuelBarToDraw=target
					SetInt('FuelScript.vehicleToDraw',vehicleFuelBarToDraw)
				end
				DrawBodyOutline(targetBody,1)
				if InputDown("interact") and (tonumber(GetTagValue(gasCan, "fuelLevel")) or 0) > 0 then
					DrawLine(getEntityTransform(gasCan).pos,getEntityTransform(target).pos)
					if (tonumber(GetTagValue(target, "fuelLevel")) or 0) < (tonumber(GetTagValue(target, "fuelLevelMAX")) or 100) then
						PlayLoop(fuelsnd)
					end
				end
			end
		end
	end

	local playerVehicle = GetPlayerVehicle()
	if playerVehicle ~= 0 then
		gDrawFuelBar=true
		vehicleFuelBarToDraw=playerVehicle
		SetInt('FuelScript.vehicleToDraw',vehicleFuelBarToDraw)
		if KeybindDown(Settings.keybinds.vehicles.siphon_fuel) then
			ServerCall("server.fuelSiphon", GetLocalPlayer())
			local vehicleTrans=GetVehicleTransform(playerVehicle)
			for _, can in ipairs(FindBodies("GasCan",true)) do
				if VecLength(VecSub(GetBodyTransform(can).pos, vehicleTrans.pos)) < 5 then
					DrawBodyOutline(can, 1)
					DrawLine(vehicleTrans.pos, GetBodyTransform(can).pos)
				end
			end
		end
	end

	if gLastDrawFuelBar~=gDrawFuelBar then
		if gDrawFuelBar then
			SetValue('fuelBarFade',1,"easeout",.05)
		else
			SetValue('fuelBarFade',0,"easein",.05)
		end
	end
	SetFloat('FuelScript.UI.fuelBarFade',fuelBarFade)
	gLastDrawFuelBar = gDrawFuelBar
end

function client.draw()
	if gDrawFuelBar and false then
		UiPush()
			local currentFuel = tonumber(GetTagValue(vehicleFuelBarToDraw, "fuelLevel"))
			local maxFuel = tonumber(GetTagValue(vehicleFuelBarToDraw, "fuelLevelMAX"))
			UiFont('regular.ttf',26)
			UiTranslate((210*fuelBarFade)-200,150)
			UiText("Fuel Level")

			if lastInfiniteFuel~=infiniteFuel then
				lastInfiniteFuelChangeTime=GetTime()
			end
			local timePassed = GetTime()-lastInfiniteFuelChangeTime
			local lerpPercent = math.min(1,timePassed/.5)

			if infiniteFuel then
				pulseVal = math.sin(math.pi*(GetTime()%3)/3)/2 * lerpPercent + pulseVal*(1-lerpPercent)
				displayFuelAmmount = maxFuel*lerpPercent + displayFuelAmmount*(1-lerpPercent)
			else
				pulseVal = 0 * lerpPercent + math.sin(math.pi*(GetTime()%3)/3)/2 * (1-lerpPercent)
				displayFuelAmmount = currentFuel*lerpPercent + displayFuelAmmount*(1-lerpPercent)
			end

			UiProgressBar(displayFuelAmmount, maxFuel, 200, 40, 1-1*pulseVal, 1, 1-1*pulseVal, .2)
		UiPop()
	end
	lastInfiniteFuel=infiniteFuel

	lastInfiniteFuel=infiniteFuel

	local gasCan = GetPlayerInteractBody()
	if HasTag(gasCan, "GasCan") and HasTag(gasCan, "bodyOriginalVoxelCount") then
		local gasCanTransform = GetBodyTransform(gasCan)
		local x,y = UiWorldToPixel(gasCanTransform.pos)
		local currentFuel = tonumber(GetTagValue(gasCan, "fuelLevel")) or 0
		local maxFuel = tonumber(GetTagValue(gasCan, "fuelLevelMAX")) or 100
		local gasCanHealth = getBodyHealth(gasCan)
		UiTranslate(x-100,y-20 + 40)
		if gasCanHealth~=1 then
			UiProgressBar(currentFuel,maxFuel,200,40,1,0,0,0)
		else
			UiProgressBar(currentFuel,maxFuel,200,40,.8,.7,.6,.2)
		end
	end
end

function UiProgressBar(val, max, w, h, r,g,b,critical)
	UiPush()
		local w = w or 300
		local h = h or 30
		local pad = 6
		local borderWidth = 6
		local borderHeight = 6
		local r = r or 1
		local g = g or 1
		local b = b or 1
		local critical = critical or 1

		local t = val/max
		UiAlign("left top")
		UiColor(0, 0, 0, 0.5)
		UiImageBox("ui/common/box-solid-10.png", w, h, borderWidth, borderHeight)
		if t > 0 then
			UiTranslate(pad/2, pad/2)
			w=(w-pad)*t
			h=h-pad
			borderWidth=math.min(w/2,6)
			local critPercent = math.min(t/critical,1)
			UiColor(1-(1-r)*critPercent,g*critPercent,b*critPercent,1)
			UiImageBox("ui/common/box-solid-6.png", w, h, borderWidth, borderHeight)
		end
	UiPop()
end

function fuelCanUpdate()
	local gasCans = FindBodies("GasCan",true)
	for _,gasCan in pairs(gasCans)do
		initBodyHealth(gasCan)
		if not HasTag(Vehicle, "fuelLevelMAX") then
			SetTag(Vehicle, "fuelLevelMAX", 100)
		end
		if not HasTag(Vehicle, "fuelLevel") then
			SetTag(Vehicle, "fuelLevel",0)
		end

		if HasTag(gasCan,"RNDfuelLevel")then
			local rawInfos=GetTagValue(gasCan,"RNDfuelLevel")
			local fuelLevelMAX=tonumber(GetTagValue(gasCan,"fuelLevelMAX"))
			if rawInfos~=""then
				local infos=Split(rawInfos,"_")
				if #infos==1 then
					SetTag(gasCan, "fuelLevel", math.random()*infos[1])
				else
					SetTag(gasCan, "fuelLevel", math.random()*(infos[2]-infos[1])+info[1])
				end
			else
				SetTag(gasCan, "fuelLevel", math.random()*.25*fuelLevelMAX)
			end
			RemoveTag(gasCan,"RNDfuelLevel")
		end

		local gasCanHealth=getBodyHealth(gasCan)
		if gasCanHealth<.75 then
			RemoveTag(gasCan,"GasCan")
			RemoveTag(gasCan,"fuelLevel")
			RemoveTag(gasCan,"fuelLevelMAX")
			RemoveTag(gasCan,"explosive")
			RemoveTag(gasCan,"interact")
		else
			local fuelLevel=tonumber(GetTagValue(gasCan,"fuelLevel"))
			local fuelLevelMAX=tonumber(GetTagValue(gasCan,"fuelLevelMAX"))
			if gasCanHealth<1 then
				local fuelLeaked=math.min(fuelLevel,fuelLevelMAX*(1-gasCanHealth)/60)
				SetTag(gasCan, "fuelLevel", fuelLevel-fuelLeaked)
				updateGasCanInteractText(gasCan,"Leaking Fuel!")
				-- (v2) leak sound: client.tick
			else
				updateGasCanInteractText(gasCan)
			end

			local explosionSize=fuelLevel/fuelLevelMAX
			if explosionSize>0.5 then
				SetTag(gasCan,"explosive",explosionSize)
			else
				RemoveTag(gasCan,"explosive")
			end
		end
	end
end
function updateGasCanInteractText(can, t)
	local t=t or""
	local f=tonumber(GetTagValue(can,"fuelLevel"))or 0
	local fMAX=tonumber(GetTagValue(can,"fuelLevelMAX"))or 100
	SetTag(can,"interact",round(f,.01).." / "..fMAX.." "..t)
end
function refuel(source,target,percent,seller)
	local sourceFuelLevel = tonumber(GetTagValue(source, "fuelLevel"))or 0
	local targetFuelLevel = tonumber(GetTagValue(target, "fuelLevel"))or 0
	local sourceMaxFuelLevel = tonumber(GetTagValue(source, "fuelLevelMAX"))or 100
	local targetMaxFuelLevel = tonumber(GetTagValue(target, "fuelLevelMAX"))or 100
	local percent=percent or 1
	local fuelTransfered=0
	if targetFuelLevel<targetMaxFuelLevel and sourceFuelLevel>0 and not HasTag(target, "sell") then
		fuelTransfered=math.min(.1,math.min(targetMaxFuelLevel-targetFuelLevel,sourceFuelLevel))
		SetTag(source,"fuelLevel",sourceFuelLevel-fuelTransfered)
		SetTag(target,"fuelLevel",targetFuelLevel+(fuelTransfered*percent))
	else
		fuelTransfered=math.min(.1,math.min(targetMaxFuelLevel-targetFuelLevel,sourceFuelLevel))
		--SetTag(target,"fuelLevel",targetFuelLevel+(fuelTransfered*percent))
		SetTag(source,"fuelLevel",sourceFuelLevel-fuelTransfered)
		-- (2026-11-14, MP) the money is the selling player's (their own savegame, on their machine); v1 wrote it here,
		-- on the server, which in multiplayer is the host's savegame whoever sold
		if seller then FuelMoney[seller] = (FuelMoney[seller] or 0) + fuelTransfered*30 end
	end
	-- (v2) the fuel line + sound are drawn by the client (client.tick)
	return fuelTransfered
end

function SiphonFuel(v)
	local siphonFuelMultiplier = math.min(.5 + GetInt("savegame.mod.perks.fuelthief")*.05, 1)
	local gasCans = FindBodies("GasCan",true)
	if v ~= 0 then
		local vehicleTrans=GetVehicleTransform(v)
		for i=1,#gasCans do
			local gasCan = gasCans[i]
			local GasCanTrans = GetBodyTransform(gasCan)
			if VecLength(VecSub(GasCanTrans.pos, vehicleTrans.pos)) < 5 then
				refuel(v,gasCan,siphonFuelMultiplier)
			end
		end
	end
end

function getEntityTransform(entity)
	if GetEntityType(entity)=="vehicle"then
		return GetBodyTransform(GetVehicleBody(entity))
	elseif GetEntityType(entity)=="shape"then
		return GetShapeWorldTransform(entity)
	elseif GetEntityType(entity)=="body"then
		return GetBodyTransform(entity)
	end
end
function getBodyVoxelCount(body)
	local cnt=0
	for _,shape in pairs(GetBodyShapes(body))do
		cnt=cnt+GetShapeVoxelCount(shape)
	end
	return cnt
end
function initBodyHealth(body)
	if not HasTag(body,"bodyOriginalVoxelCount")then
		SetTag(body,"bodyOriginalVoxelCount",getBodyVoxelCount(body))
	end
end
function getBodyHealth(body)
	return getBodyVoxelCount(body)/tonumber(GetTagValue(body,"bodyOriginalVoxelCount"))
end
function round(val,step)
	local steps=step or 1
    if val>=0 then val=math.floor(val/steps+.5)*steps
    else val=math.ceil(val/steps-.5)*steps end
	if val==0 then val=0 end
	return val
end
function Split(s,delimiter)
    result={}
    for match in(s..delimiter):gmatch("(.-)"..delimiter)do
        table.insert(result,match)
    end
    return result
end

function server.handleCommand(cmd) handle_quickload(cmd) end
function handle_quickload(cmd)
    for _, word in ipairs(splitString(cmd, " ")) do
        if word == "quickload" then
            Init_Settings()
        end
        break
    end
end
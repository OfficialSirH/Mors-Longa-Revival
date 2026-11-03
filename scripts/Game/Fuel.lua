#include "../../Settings.lua"

function init()
	Init_Settings()

	currentFuel = 0
	infiniteFuel = HasKey('level.gamerule.infuel') and GetBool('level.gamerule.infuel') or false
	SetBool('level.InfiniteFuel',infiniteFuel)
	fuelsnd = LoadLoop("MOD/snd/Fueling.ogg")

	fuelBarFade=0

	pulseVal=0
	lastInfiniteFuelChangeTime=-100
	displayFuelAmmount=0

	NOLAGPlayerInteractBody=0
	fuelCanUpdate()
	if not GetString("savegame.mod.difficulty") == "hardcore" then
		minPercent = 2.5
		maxPercent = 50
	else
		minPercent = 1
		maxPercent = 35
	end
end

function tick(dt)
	SetInt('FuelScript.vehicleToDraw',0)

	SetBool('level.InfiniteFuel', GetBool("savegame.mod.config.game.inf_fuel"))
	infiniteFuel = GetBool('level.InfiniteFuel')


	-- if GetBool('level.InfiniteFuel')~=infiniteFuel then
	-- 	infiniteFuel = GetBool('level.InfiniteFuel')
	-- end
	-- if InputDown('i') and InputDown('n') and InputPressed('f') then
	-- 	infiniteFuel = not infiniteFuel
	-- 	SetBool('level.InfiniteFuel',infiniteFuel)
	-- end

	fuelConsumptionMultiplier = 1 / (1 + GetInt("savegame.mod.perks.experienceddriver"))
	if GetInt("savegame.mod.perks.experienceddriver") == 10 then
		fuelConsumptionMultiplier = 0
	end

	fuelCanUpdate()
	--if GetBool("level.fuelgen") == true then
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
					--[[ SetPlayerVehicle(0)
					--DriveVehicle(playerVehicle,0,0,true)
					gDrawFuelBar = false ]]
				end
			end
		end
		SetTag(Vehicle, "drive", 0)
		SetTag(Vehicle, "turn", 0)
		SetTag(Vehicle, "brake", 0)
	end
	--SetBool("level.fuelgen", false)
	--end

	gDrawFuelBar = false

	local gasCan = GetPlayerGrabBody()
	if HasTag(gasCan, "GasCan") then
		DrawBodyOutline(gasCan, 1)
		if GetPlayerInteractBody() == gasCan then
			local gasCanTrans = GetBodyTransform(gasCan)
			QueryRejectBody(gasCan)
			local hit, pos, normal, shape = QueryClosestPoint(gasCanTrans.pos, 1)
			if hit then
				local shapeBody = GetShapeBody(shape)
				local shapeVehicle = GetBodyVehicle(shapeBody)
				if shapeVehicle~=0 or HasTag(shapeBody,"GasCan")then
					updateGasCanInteractText(gasCan,"Refuel")
					local target
					if shapeVehicle~=0 then
						target=shapeVehicle
						gDrawFuelBar=true
						vehicleFuelBarToDraw=shapeVehicle
						SetInt('FuelScript.vehicleToDraw',vehicleFuelBarToDraw)
					else
						target=shapeBody
					end
					DrawBodyOutline(shapeBody,1)
					if InputDown("interact")then
						local fuelTransfered=refuel(gasCan,target)
						if fuelTransfered~=0 then
							updateGasCanInteractText(gasCan,"Refueling")
						end
					end
				end
			end
		end
	end

	local playerVehicle = GetPlayerVehicle()
	if playerVehicle ~= 0 then
		SetTag(playerVehicle, "AlarmTriggered")
		gDrawFuelBar=true
		vehicleFuelBarToDraw=playerVehicle
		SetInt('FuelScript.vehicleToDraw',vehicleFuelBarToDraw)

		local throttle = InputValue("up") - InputValue("down")

		if KeybindDown(Settings.keybinds.vehicles.siphon_fuel) then
			SiphonFuel(playerVehicle)
		end

		if not infiniteFuel then
			local currentFuel = tonumber(GetTagValue(playerVehicle, "fuelLevel"))
			local baseFuelConsumption = tonumber(GetTagValue(playerVehicle, "fuelConsumption")) or 0.25
			currentFuel=currentFuel-baseFuelConsumption*math.abs(throttle)*dt*fuelConsumptionMultiplier
			if currentFuel > 0 then
				SetTag(playerVehicle,"fuelLevel",currentFuel)
			else
				SetTag(playerVehicle,"fuelLevel",0)
				SetPlayerVehicle(0)
				--DriveVehicle(playerVehicle,0,0,true)
				gDrawFuelBar = false
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

function draw()
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

	local gasCan = GetPlayerInteractBody()
	if HasTag(gasCan, "GasCan") then
		local gasCanTransform = GetBodyTransform(gasCan)
		local x,y = UiWorldToPixel(gasCanTransform.pos)
		local currentFuel = tonumber(GetTagValue(gasCan, "fuelLevel"))
		local maxFuel = tonumber(GetTagValue(gasCan, "fuelLevelMAX"))
		local interactText = GetTagValue(gasCan,"interact")
		SetTag(gasCan,"interact","")
		local gasCanHealth = getBodyHealth(gasCan)
		UiTranslate(x-100,y-20 + 40)
		if gasCanHealth~=1 then
			UiProgressBar(currentFuel,maxFuel,200,40,1,0,0,0)
		else
			UiProgressBar(currentFuel,maxFuel,200,40,.8,.7,.6,.2)
		end
		UiTranslate(100,20)
		UiAlign("center middle")
		UiFont('bold.ttf',22)
		UiTextOutline(0,0,0,10)
		UiText(interactText)
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
				PlayLoop(fuelsnd,GetBodyTransform(gasCan).pos,fuelLeaked)
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
function refuel(source,target,percent)
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
		DrawLine(getEntityTransform(source).pos,getEntityTransform(target).pos)
	else
		fuelTransfered=math.min(.1,math.min(targetMaxFuelLevel-targetFuelLevel,sourceFuelLevel))
		--SetTag(target,"fuelLevel",targetFuelLevel+(fuelTransfered*percent))
		SetTag(source,"fuelLevel",sourceFuelLevel-fuelTransfered)
		DrawLine(getEntityTransform(source).pos,getEntityTransform(target).pos)
		CurrentMoney = GetInt("savegame.mod.player.money")
		SetInt("savegame.mod.player.money", CurrentMoney + fuelTransfered*30 )
	end
	if sourceFuelLevel > 0 and targetFuelLevel < targetMaxFuelLevel then
		PlayLoop(fuelsnd)
	end
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
				DrawBodyOutline(gasCan, 1)
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

function handleCommand(cmd) handle_quickload(cmd) end
function handle_quickload(cmd)
    for _, word in ipairs(splitString(cmd, " ")) do
        if word == "quickload" then
            Init_Settings()
        end
        break
    end
end
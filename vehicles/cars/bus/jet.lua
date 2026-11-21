#version 2
DL_LABEL = "jet"  -- crash breadcrumbs (lib/DeleteLog.lua)
#include "../../../lib/DeleteLog.lua"
#include "script/include/player.lua"
-- (v2) JetBus jet (Shift boost). SERVER: throttle from the DRIVER (idle 0.1 while driving, 1 with Shift held; v1: the
-- host whenever in the bus), push, turbine, smoke, engine loop, damage / explosion. CLIENT: the throttle bar for
-- whoever is in the bus, from shared.jetThrottle / shared.jetTarget. Hand-converted 2026-11-09.

-- the player driving vehicle (passengers ride too but must not boost), or nil
function VehicleDriver(vehicle)
	if vehicle == 0 then return nil end
	for p in Players() do
		if IsPlayerVehicleDriver(vehicle, p) then return p end
	end
	return nil
end

function server.init()
	v=FindVehicle()
	JetInit()
	shared.jetThrottle, shared.jetTarget = 0, 0
end

function server.tick(dt)
	local driver = VehicleDriver(v)
	if driver and GetVehicleHealth(v)>=0 then
		if InputDown('shift', driver)then
			SetJetPower(1)
		else
			SetJetPower(.1)
		end
	else
		SetJetPower(0)
	end

	JetTick(dt)
	shared.jetThrottle, shared.jetTarget = jetThrottle, jetTargetThrottle
end

function server.update(dt)
	JetUpdate(dt)
end

function client.init()
	v=FindVehicle()
end

function client.draw(dt)
	JetDraw(dt)
end

function SetJetPower(val)
	jetTargetThrottle=val
end
function JetInit()
	jet=FindShape('jet')
	jetPower=tonumber(GetTagValue(jet,'jet'))or 100
	local min,max = GetShapeBounds(jet)
	local jetT = GetShapeWorldTransform(jet)
	jetLocalCenterPos=TransformToLocalPoint(jetT,VecLerp(min,max,.5))

	jetThrottle=0
	jetHealthThreshold=.7

	jetOriginalVoxelCount = GetShapeVoxelCount(jet)
	jetTurbineBrokenTime = 0

	turbine=FindJoint('turbine')

	jetLocalExhaustPos=TransformToLocalPoint(jetT,GetTriggerTransform(FindTrigger('exhaust')).pos)

	jetLoop = LoadLoop("MOD/vehicles/cars/bus/engine_exterior.ogg")
	lastJetHealth = GetJetHealth() -- (v2) v1 left it nil until the first update (nil compare if the jet starts damaged)
end
RPM = 1000*math.pi/3
function JetTick(dt)
	if GetJetHealth() >= jetHealthThreshold and not jetBroken then
		local dThrottle = jetTargetThrottle - jetThrottle
		if dThrottle<0 then
			jetThrottle = jetThrottle + math.max(dThrottle, -0.25*dt)
		elseif dThrottle>0 then
			jetThrottle = jetThrottle + math.min(dThrottle, 0.25*dt)
		end

		local jetT = GetShapeWorldTransform(jet)
		local jetWorldExhaustPos = TransformToParentPoint(jetT,jetLocalExhaustPos)
		local jetWorldForwardDir = TransformToParentVec(jetT,Vec(0,-1))

		ParticleReset()
		ParticleType("smoke")
		ParticleColor(0.9, 0.9, 0.9)
		ParticleAlpha(0.2,0.5)
		ParticleRadius(0.1, 2)
		ParticleDrag(0.1)
		SpawnParticle(jetWorldExhaustPos, VecScale(jetWorldForwardDir,-5*jetThrottle), 10*jetThrottle)
		
		local jetWorldCenterPos = TransformToParentPoint(jetT,jetLocalCenterPos)
		PlayLoop(jetLoop,jetWorldCenterPos,2*jetThrottle)
	else
		jetThrottle=0
	end
end
function JetUpdate(dt)
	if GetJetHealth() >= jetHealthThreshold and not jetBroken then
		local jetT = GetShapeWorldTransform(jet)
		local jetWorldCenterPos = TransformToParentPoint(jetT,jetLocalCenterPos)
		local jetWorldForwardDir = TransformToParentVec(jetT,Vec(0,1))
		ApplyBodyImpulse(GetShapeBody(jet),jetWorldCenterPos,VecScale(jetWorldForwardDir,jetPower*jetThrottle))
		SetJointMotor(turbine,jetThrottle*RPM,100)
	elseif lastJetHealth>=jetHealthThreshold then
		local jetT = GetShapeWorldTransform(jet)
		local jetWorldCenterPos = TransformToParentPoint(jetT,jetLocalCenterPos)
		Explosion(jetWorldCenterPos,3)
	end
	if IsBodyBroken(GetShapeBody(GetJointOtherShape(turbine,jet))) then
		jetTurbineBrokenTime = jetTurbineBrokenTime + dt*jetThrottle
		if jetTurbineBrokenTime>=5 then
			jetBroken=true
			Delete(turbine)
		elseif jetTurbineBrokenTime>=2 then
			SetTag(jet,'autobreak')
			SetTag(jet,'explosive',3)
		end
	end
	lastJetHealth = GetJetHealth()
end
function JetDraw(dt)
	local jetThrottle, jetTargetThrottle = shared.jetThrottle or 0, shared.jetTarget or 0 -- (v2) from the server
	if GetPlayerVehicle() == v then
		UiPush()
			UiTranslate(20,UiHeight()-300)
			UiAlign('left bottom')
			UiColor(0,0,0,0.5)
			UiImageBox("ui/common/box-solid-6.png", 50, 120, 6, 6)
			UiTranslate(25,-10)
			UiAlign('center bottom')
			UiColor(0.2,0.2,0.2,0.75)
			UiImageBox("ui/common/box-solid-6.png", 10, 100, 6, 6)
			UiPush()
				UiTranslate(0,-100*jetThrottle)
				UiAlign('center middle')
				UiColor(0.7,0,0)
				UiRect(30,10)
			UiPop()
			UiPush()
				UiTranslate(0,-100*jetTargetThrottle)
				UiAlign('center middle')
				UiColor(1,0,0,.7)
				UiRect(30,10)
			UiPop()
		UiPop()
	end
end
function GetJetHealth()
	return GetShapeVoxelCount(jet)/jetOriginalVoxelCount
end
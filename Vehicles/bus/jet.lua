function init()
	v=FindVehicle()
	JetInit()
end

function tick(dt)
	if GetPlayerVehicle()==v and GetVehicleHealth(v)>=0 then
		if InputDown('shift')then
			SetJetPower(1)
		else
			SetJetPower(.1)
		end
	else
		SetJetPower(0)
	end

	JetTick(dt)
end

function update(dt)
	JetUpdate(dt)    
end

function draw(dt)
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

	jetLoop = LoadLoop("MOD/Vehicles/bus/engine_exterior.ogg")
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
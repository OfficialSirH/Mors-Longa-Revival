function init()
	interactrange = 3
	cycletimer = 0
	timeup = false
	ontimer = 0
	trn = FindShape("trn")
	control = FindShape("control")
	controle = false
	takeoff = true
	startspeed = 22
	maxheight = 10
	boc = 400
	Heli = FindBody("Heli")
	weight = 0.1
	acceleration = 0.01
	Rotspeedz = Vec(0,0,0)
	helilandheight = GetBodyTransform(Heli).pos[2]
	helistartmass = GetBodyMass(Heli)
	impulsepos = Vec(5,5,0)
	imp = Vec(190, 0, 0)
	Fuel = 3900
	startrotmass = GetBodyMass(FindBody("rot"))
	FuelLeak = 0
	pilot = FindBody("Pilot")
	pilot2 = FindBody("Pilot2")
	FuelIntegrity = 0
	Fuelamount = 3900
	fuelline = FindShape("fuelline")
	SFuelIntegrity = 0
	Fuel = FindShapes("fuel")
	for i=1,#Fuel do
		SFuelIntegrity = SFuelIntegrity + GetShapeVoxelCount(Fuel[i]) 
	end
	FuelLeak = 0
	Nullify = 1
	rottime = 3
	ExternalTrig = FindTrigger("external")
	InternalTrig = FindTrigger("internal")
	CriticalTrig = FindTrigger("critical")
	Rottotmass = 9099990
	Console = FindShape("Console")
	SConsoleIntegrity = GetShapeVoxelCount(Console)
	damage = 0
	divam = 1.2
	allowedfordamage = helistartmass/divam
	insnd = LoadSound("MOD/vehicles/aircraft/Boeing_CH47-C/snd/experimental.ogg")
	realslow = 1
	outsnd = LoadSound("MOD/vehicles/aircraft/Boeing_CH47-C/snd/heli_crash_out.ogg")
	target = Vec(0,0,0)
	bocz = 28
	funnyvalue = Vec(0,0,0)
	targetreached = true
	brokenliftoffattempt = false
	off = false
	button = FindShape("buffon")
	jointsz = FindJoints("cringo")
	joinspeed = 0.4
	closer = true
	closetim = 0
end
function update(dt)
	SetTag(button, "interact", "toggle ramp")
	cycledzz = false
	if closer or not closer then
		closetim = closetim + dt
		joinspeed = joinspeed / 1.008
		if not closer then
			for i=1,#jointsz do
				joint = jointsz[i]
				SetJointMotor(joint, -joinspeed)
			end
		end
		if closer then
			for i=1,#jointsz do
				joint = jointsz[i]
				SetJointMotor(joint, joinspeed)
			end
		end
	end
	if GetPlayerInteractShape() == button and InputPressed("interact") and closer and closetim > 0.3 and not cycledzz then
			joinspeed = 0.4
		closetim = 0
		DebugPrint(close)
		cycledzz = true
		closer = false
	end
	if GetPlayerInteractShape() == button and InputPressed("interact") and closetim > 0.3 and not closer and not cycledzz then
			joinspeed = 0.4
		closetim = 0
		for i=1,#jointsz do
			joint = jointsz[i]
		SetJointMotor(joint, joinspeed)
		end
		DebugPrint(close)
		cycledzz = true
		closer = true
	end

	if cycled then
		cycletimer = cycletimer + dt
		if cycletimer > 1 then
			cycled = false
			cycletimer = 0
		end
	end

	if crashed then
		startspeed = startspeed / 1.005
	end

	blades = FindJoints("engine")
	for i=1,#blades do
		blade = blades[i]
	SetJointMotor(blade, startspeed)
	end


	ConsoleIntegrity = GetShapeVoxelCount(Console)

	ConsoleTrans = GetShapeWorldTransform(Console)
	PTrans = GetPlayerTransform()
	Disttoconsole = VecLength(VecSub(ConsoleTrans.pos, PTrans.pos))
	if not off then
		draw()
	end
	if Disttoconsole < interactrange then
		Near = true
	else
		Near = false
	end

	if ConsoleIntegrity < SConsoleIntegrity/1.1 then
		damagedenough = true
		consolefucked = true
	end

	if HasTag(pilot, "dead") and HasTag(pilot2, "dead") then
		pilotdead = true
	else
		pilotdead = false
	end
	if Near and controle then
		pilotdead = false
	end

	currentmass = GetBodyMass(Heli)
	if currentmass < helistartmass/1.1 then
		damagedenough = true
	end

	if GetPlayerInteractShape() == trn and InputPressed("interact") and not takeoff and not pilotdead and not damagedenough and not consolefucked then
		takeoff = true
	end

	if GetPlayerInteractShape() == trn and InputPressed("interact") and not takeoff then
		if pilotdead or damagedenough or consolefucked then
		takeoff = true
		brokenliftoffattempt = true
		end
	end

	if GetPlayerInteractShape() == control and InputPressed("interact") and not cycled and not controle then
		controle = true
		cycled = true
	end
	if GetPlayerInteractShape() == control and InputPressed("interact") and not cycled and controle then
		controle = false
		cycled = true
	end

		if brokenliftoffattempt then
			ontimer = ontimer + dt
			if ontimer > 5 then
				timeup = true
			end
		end

	if takeoff then
	HeliPos = GetBodyTransform(Heli)
	xx, yy, zz = GetQuatEuler(HeliPos.rot)
	--if InputPressed("X") and controle then
		targetacquired = true
		target = GetPlayerTransform().pos
		--DebugCross(target, 0,1,0)
	--end
	--DebugCross(target)

	target[2] = HeliPos.pos[2]

	disttotarget = VecLength(VecSub(HeliPos.pos, target))
	range = 15
	calmer = 1.001
	if disttotarget < range then
		targetreached = true
		HeliVel = GetBodyVelocity(Heli)
		V1 = HeliVel[1] / calmer
		V3 = HeliVel[3] / calmer
		if not brokenliftoffattempt then
		SetBodyVelocity(Heli, Vec(V1, HeliVel[2], V3))
		end

	else
		targetreached = false
	end

	if targetacquired and not targetreached and not pilotdead and not damagedenough and Rottotmass > 4000 and not brokenliftoffattempt then
		local approachspeed = 0.03
		local smoothspeed = 0.03
		--startspeed = 44

		local ttr = GetBodyTransform(Heli)
		local currentavel = GetBodyAngularVelocity(Heli)

		local targetrot = QuatLookAt(ttr.pos, target)

		local ltargetrot = TransformToLocalTransform(ttr, Transform(Vec(), targetrot))
		x,y,z = GetQuatEuler(ltargetrot)
		--z = z + 90
		--ltargetrot = QuatEuler(x,y,z)
		local targetavel = VecScale(Vec(GetQuatEuler(ltargetrot.rot)), approachspeed)
		local diff = VecSub(targetavel, currentavel)
		local stab = 0.01
		if xx < 0 then
			xx = xx * -1
		end
		stab = xx/480
		diff[1] = 0 --math.max(math.min(diff[1], smoothspeed), -smoothspeed)
		diff[2] = math.max(math.min(diff[2], smoothspeed), -smoothspeed)
		diff[3] = 0 --math.max(math.min(diff[3], smoothspeed), -smoothspeed)
		SetBodyAngularVelocity(Heli, VecAdd(currentavel, diff))

boosters = FindBodies("Booster")
for i=1,#boosters do
	Booster = boosters[i]
	if not IsBodyBroken(Booster) then
		local sbtz = GetBodyTransform(Booster)
    	local trVecz = Vec(0,0, bocz)
    	local trVelz = TransformToParentPoint(sbtz, trVecz)
    	local velSubz = VecSub(trVelz, sbtz.pos)
    	local biasz = Vec(0, 0, 0)
        --bias[2] = boc
        --boc = boc
        local currentVelocity = GetBodyVelocity(Booster)
        VelAdd = VecAdd(currentVelocity, velSubz)
        SetBodyVelocity(Booster, VelAdd)
    end
    end
	end
	velz = GetBodyAngularVelocity(Heli)
        SetBodyAngularVelocity(Heli, VecAdd(velz, funnyvalue))

	lights = FindLights("reglight")
	for i=1,#lights do
		light = lights[i]
		if damagedenough or pilotdead or Rottotmass < 4000 or brokenliftoffattempt then
			if Fuelamount > 0 then
				if not timeup then
		SetLightColor(light, 1, 0, 0)
		SetLightIntensity(light, 5)
				else
					SetLightEnabled(light, false)
				end
			else
		SetLightEnabled(light, false)
			end
		else
		SetLightColor(light, 1, 1, 1)
		end
	end

	if IsShapeBroken(fuelline) then
		Nullify = 4
	end
	if not consolefucked then
	if pilotdead or damagedenough or Rottotmass < 4000 or brokenliftoffattempt then
		--startspeed = startspeed - 0.5
		if not timeup then
		SetTriggerTransform(CriticalTrig, Transform(HeliPos.pos, Vec(0,0,0)))
	else
		SetTriggerTransform(CriticalTrig, Transform(Vec(0,-1000,0), Vec(0,0,0)))
	end
	else
		SetTriggerTransform(CriticalTrig, Transform(Vec(0,-1000,0), Vec(0,0,0)))
	end
	else
		SetTriggerTransform(CriticalTrig, Transform(Vec(0,-1000,0), Vec(0,0,0)))
end

	Fuel = FindShapes("fuel")
	FuelIntegrity = 0
	for i=1,#Fuel do
		FuelIntegrity = FuelIntegrity + GetShapeVoxelCount(Fuel[i]) 
	end
	FuelLeak = FuelIntegrity/200 - SFuelIntegrity/200
	Fuelamount = Fuelamount + FuelLeak * Nullify
	if Fuelamount < 0 then
		Fuelamount = 0
	end

	if Rottotmass > 3000 and not brokenliftoffattempt then
	SetTriggerTransform(InternalTrig, Transform(HeliPos.pos, HeliPos.rot))
	if not IsPointInTrigger(InternalTrig, GetPlayerTransform().pos)then
	SetTriggerTransform(ExternalTrig, Transform(HeliPos.pos, HeliPos.rot))
	inside = false
	else
		SetTriggerTransform(ExternalTrig, Transform(Vec(0,-1000,0), Vec(0,0,0)))
		inside = true
	end
else 
	SetTriggerTransform(ExternalTrig, Transform(Vec(0,-1000,0), Vec(0,0,0)))
	SetTriggerTransform(InternalTrig, Transform(Vec(0,-1000,0), Vec(0,0,0)))
	end

	if brokenliftoffattempt or damagedenough and GetBodyTransform(Heli).pos[2] < helilandheight + 4 then
		Rottotmass = 0
		crashed = true
		realslow = 1.002
		if not plaid and not brokenliftoffattempt then
			plaid = true
		if inside then
			PlaySound(insnd, HeliPos.pos)
		else
			PlaySound(outsnd, HeliPos.pos)
		end
	end
	end

	Disttoheight = helilandheight + maxheight - GetBodyTransform(Heli).pos[2]
	RealAcceleration = Disttoheight * acceleration
	if RealAcceleration < 0 then
		RealAcceleration = 1
	end
	--if GetBodyTransform(Heli).pos[2] < helilandheight + 10 then
	if not pilotdead and not damagedenough and Rottotmass > 4000 then
	startspeed = startspeed + RealAcceleration
end
	--else
		--startspeed = startspeed - RealAcceleration / 5
	--end

	if startspeed > 22 then
		startspeed = 22
	end
	if Fuelamount > 0 then
	if Rottotmass > 3000 and pilotdead or damagedenough and Rottotmass > 3000 and not brokenliftoffattempt then
		if pilotdead  or damagedenough then
		Rotspeedadd = Vec(0,0.006,0)
		end
		if not brokenliftoffattempt then
		SetBodyAngularVelocity(Heli, VecAdd(Rotspeed, Rotspeedadd))
		ApplyBodyImpulse(Heli, impulsepos, imp)
	end
	end


Rottotmass = 0
rots = FindBodies("rot")
if not crashed and not brokenliftoffattempt then
	for i=1,#rots do
	rot = rots[i]
	Rottotmass = Rottotmass + GetBodyMass(rot)
	if GetBodyMass(rot) > startrotmass / 2 then
	local sbt = GetBodyTransform(rot)
	disttoheli = VecLength(VecSub(sbt.pos, HeliPos.pos))
	if disttoheli > 10 then
		Rottotmass = 0
	end
	boc = startspeed
    local trVec = Vec(0,boc,0)
    local trVel = TransformToParentPoint(sbt, trVec)
    local velSub = VecSub(trVel, sbt.pos)
    local bias = Vec(0, 0, 0)
        local currentVelocity = GetBodyVelocity(rot)
        if disttoheli < 10 then
        SetBodyVelocity(rot, velSub)
    end
		end
	end

	Rotspeed = GetBodyAngularVelocity(Heli)
	if not damagedenough and not pilotdead and not brokenliftoffattempt then
	for i=1,3 do
		if Rotspeed[i] < 0 or Rotspeed[i] > 0 then
			Rotspeed[i] = Rotspeed[i] / 1.05
		end
		SetBodyAngularVelocity(Heli, Rotspeed)
	end
end
end
end
if currentmass < helistartmass/1.01 then
	lightdamage = true
end
dmg = currentmass - allowedfordamage
damage = dmg / 90000

if lightdamage  and Fuelamount > 0 then
	particleplaces = FindShapes("smoker")
	for i=1,#particleplaces do
		smoker = particleplaces[i]
		particlepos = GetShapeWorldTransform(smoker)
		smoke()
	end
end
end

end

function smoke()
    ParticleType("smoke")
    ParticleColor(damage, damage, damage)
     ParticleEmissive(0)
    ParticleRadius(0.2, 0.5)
    ParticleAlpha(1000,0)
    ParticleCollide(1)
    ParticleDrag(0.6)
    ParticleGravity(5,10)
    ParticleStretch(1)
    SpawnParticle(particlepos.pos, Vec(math.random(-1,1), math.random(-1,1), math.random(-1,1)),4)
    ParticleReset()
end

function GetAimPos()
    local ct = GetPlayerCameraTransform()
    local forwardPos = TransformToParentPoint(ct, Vec(0, 0, -150))
    local direction = VecSub(forwardPos, ct.pos)
    local distance = VecLength(direction)
    local direction = VecNormalize(direction)
    QueryRejectBody(sb)
    local hit, hitDistance = QueryRaycast(ct.pos, direction, distance)
    if hit then
        forwardPos = TransformToParentPoint(ct, Vec(0, 0, -hitDistance))
        distance = hitDistance
    end
    return forwardPos, hit, distance
end

function draw()
	if Near then
    	UiPush()
      	UiAlign("center middle")
      	UiTranslate(900, 200)
      	UiFont("bold.ttf", 30)
      	UiColor(1 - Fuelamount/3900,0, 0)
      	UiText("Fuel:  "..Fuelamount)
      	UiTranslate(0, 20)
      	UiFont("bold.ttf", 30)
      	if controle then
      	UiColor(0,1,0)
      	UiText("Press X to select helicopter destination")
      	else
      	UiColor(1,0,0)
      	UiText("helicopter isnt currently controlled, interact with dashboard")
      	end
    	UiPop()
    end
end
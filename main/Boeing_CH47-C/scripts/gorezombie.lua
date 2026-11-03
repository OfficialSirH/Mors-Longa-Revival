function init()
	valkval = 0.5
	Head = FindBody("Head")
	HeadBloodCapacity = GetBodyMass(Head)
	HeadBloodLevel = HeadBloodCapacity * 20
	StartingBleed = HeadBloodCapacity
	MaxBloodCapacity = GetBodyMass(Head)
	bleed = true

	Torso = FindBody("Torso")
	TorsoBloodCapacity = GetBodyMass(Torso)
	TorsoBloodLevel = TorsoBloodCapacity * 20
	StartingBleed1 = TorsoBloodCapacity
	MaxBloodCapacity1 = GetBodyMass(Torso)
	bleed1 = true

	LARM = FindBody("LARM")
	LARMBloodCapacity = GetBodyMass(LARM)
	LARMBloodLevel = LARMBloodCapacity * 20
	StartingBleed2 = LARMBloodCapacity
	MaxBloodCapacity2 = GetBodyMass(LARM)

	bleed2 = true

	LLARM = FindBody("LLARM")
	LLARMBloodCapacity = GetBodyMass(LLARM)
	LLARMBloodLevel = LLARMBloodCapacity * 20
	StartingBleed3 = LLARMBloodCapacity
	MaxBloodCapacity3 = GetBodyMass(LLARM)
	bleed3 = true

	RARM = FindBody("RARM")
	RARMBloodCapacity = GetBodyMass(RARM)
	RARMBloodLevel = RARMBloodCapacity * 20
	StartingBleed4 = RARMBloodCapacity
	MaxBloodCapacity4 = GetBodyMass(RARM)
	bleed4 = true

	RRARM = FindBody("RRARM")
	RRARMBloodCapacity = GetBodyMass(RRARM)
	RRARMBloodLevel = RRARMBloodCapacity * 20
	StartingBleed5 = RRARMBloodCapacity
	MaxBloodCapacity5 = GetBodyMass(RRARM)
	bleed5 = true

	LLEG = FindBody("LLEG")
	LLEGBloodCapacity = GetBodyMass(LLEG)
	LLEGBloodLevel = LLEGBloodCapacity * 20
	StartingBleed6 = LLEGBloodCapacity
	MaxBloodCapacity6 = GetBodyMass(LLEG)
	bleed6 = true

	LLLEG = FindBody("LLLEG")
	LLLEGBloodCapacity = GetBodyMass(LLLEG)
	LLLEGBloodLevel = LLLEGBloodCapacity * 20
	StartingBleed7 = LLLEGBloodCapacity
	MaxBloodCapacity7 = GetBodyMass(LLLEG)
	bleed7 = true

	RLEG = FindBody("RLEG")
	RLEGBloodCapacity = GetBodyMass(RLEG)
	RLEGBloodLevel = RLEGBloodCapacity * 20
	StartingBleed8 = RLEGBloodCapacity
	MaxBloodCapacity8 = GetBodyMass(RLEG)
	bleed8 = true

	RRLEG = FindBody("RRLEG")
	RRLEGBloodCapacity = GetBodyMass(RRLEG)
	RRLEGBloodLevel = RRLEGBloodCapacity * 20
	StartingBleed9 = RRLEGBloodCapacity
	MaxBloodCapacity9 = GetBodyMass(RRLEG)
	bleed9 = true

	antibleed = 15 -- only affects smoke speed
	extremeantibleed = 500 -- affects extreme bleed which is caused by total organ failure, reduce for blood to explode more
	regularantibleed = 30 -- affects cureable bleeds, reduce to have more blood in general
	limbantibleed = 30 -- affects bleeding of limbs, decrease to have more blood from arms and legs
	MinBloodValue = 100 -- minimum allowed blood value for human to stay alive

	LimbBleedSpeed = 0.1

	bloodgrav = -20
	blooddrag = 0
	standup = 4
	startupspeed = Vec(0,standup,0)
	upspeed = Vec(0,standup,0)
	downspeed = Vec(0,-standup,0)
	alive = true
	enabled = true
	weightb = -0.1
	startweightb = weightb
	switched = true
	attacktim = 0
	attackslash = 1
	attackforce = weightb * 100
	att1 = false
	att2 = false
	walk = true
	walktimer = 0
	s = 1
	distToCheckpoint = 0
	weight = 11
	Shock = 235
	range = 10
	PrioritizeCiv = false
	infection = 0
	InfectRange = 2
	startblood = 1000000
	xray = false
	damage = 0.1
	melle = 2
	punchsnd = LoadSound("MOD/gorescript/snd/zombie/punch.ogg")
	miss = LoadSound("MOD/gorescript/snd/zombie/miss.ogg")
	tripped = false
	trippingspeed = 5
	triptimer = 0
	MaxTimeSpentAsleep = 3
	NoPoint = false
	neck = FindJoint("neck")
end


function tick(dt)

	switched = false
		if InputPressed("H") then
		if not switched and not enabled then
			enabled = true
			switched = true
		end
		if not switched and enabled then
			enabled = false
			switched = true
		end
		end

	if IsJointBroken(neck) then
		alive = false
	end

	if not alive then
		SetTag(Head, "dead")
	end
	if conditioncritical and not HasTag(Torso, "Zombie") then
		tripped = true
	end
	if conditioncritical and HasTag(Torso, "Zombie") then
		Shock = 240
	end
	if tripped and HeadVel < trippingspeed and not conditioncritical then
		triptimer = triptimer + dt
		if triptimer > MaxTimeSpentAsleep then
			tripped = false
			triptimer = 0
		end
	end
	HeadVolocity = GetBodyVelocity(Torso)
	HeadVel = VecLength(HeadVolocity)
	if HeadVel > trippingspeed then
		tripped = true
	end
	cycled = false
	if InputPressed("L") and not xray and not cycled then
		xray = true
		cycled = true
	end
	if InputPressed("L") and xray and not cycled then
		xray = false
		cycled = true
	end
	if not alive then
		RemoveTag(Torso, "Civillian")
		RemoveTag(Torso, "Zombie")
	end
	if IsBodyBroken(Torso) then
		Shock = Shock + 1
	end
	if distToCheckpoint < 4 or distToPlayer < 4 then
		close = true
	else
		close = false
	end
	if xray then
	if HasTag(Torso, "Civillian") then
		DrawBodyOutline(Head, 0,1,0,1)
	else
		DrawBodyOutline(Head, 1,1,1,1)
	end
	if not alive then
		DrawBodyOutline(Head, 1,0,0,1)
	end
end

	if IsBodyBroken(LARM) or IsBodyBroken(LLARM) then
		Leftbroke = true
	end

	if IsBodyBroken(RARM) or IsBodyBroken(RRARM) then
		rightbroke = true
	end

	if canSeePlayer() and HasTag(Torso, "Zombie") then
		agro = true
	end
	HeadPos = GetBodyTransform(Head)

	if infection > 100 then
		SetTag(Torso, "Zombie")
	end

	distToPlayer = VecLength(VecSub(HeadPos.pos, GetPlayerTransform().pos))
PrioritizeCiv = false
	if HasTag(Torso, "Zombie") then
		if distToPlayer < melle then
			Hit = true
		else
			Hit = false
		end
		infection = 100
		RemoveTag(Torso, "Civillian")
		Civillians = FindBodies("Torso", true)
		for i=1,#Civillians do
			Civillian = Civillians[i]
			if HasTag(Civillian, "Civillian") then
				CivPos = GetBodyTransform(Civillian)
				Disttociv = VecLength(VecSub(CivPos.pos, HeadPos.pos))
				--DebugLine(CivPos.pos, HeadPos.pos, 1,0,0)
				if Disttociv < range and Disttociv < distToPlayer then
					CivPos = GetBodyTransform(Civillian)
					enemy = CivPos
					PrioritizeCiv = true
					close = true
				end
			end
		end
	end


	if HasTag(Torso, "Civillian") then
		Zombies = FindBodies("Zombie", true)
		for i=1,#Zombies do
			Zombie = Zombies[i]
			ZombPos = GetBodyTransform(Zombie)
			DistToZombie = VecLength(VecSub(ZombPos.pos, HeadPos.pos))
			if DistToZombie < InfectRange then
				infection = infection + 0.1
			end
		end
	end


	if PrioritizeCiv then
		agro = true
	end

	chckpnts = FindLocations("patrol")
	if #chckpnts < 1 then
		NoPoint = true
	end
	if s > #chckpnts then
		s = 1
	end
	if alive and not NoPoint then
	for i=1,#chckpnts do
        checkpoint = chckpnts[s]
        checkpointposition = GetLocationTransform(checkpoint)
        distToCheckpoint = VecLength(VecSub(HeadPos.pos, checkpointposition.pos))
        if not agro then
        enemy = checkpointposition
    	else if not PrioritizeCiv then
    		enemy = GetPlayerTransform()
    	end
    		--enemy = checkpointposition
    	end
        if distToCheckpoint < 1 then
            s = s + 1
        end
    end

	if alive and not tripped then
		walktimer = walktimer + dt

		if walktimer > valkval/2 and not walked1 then
		local ppos = enemy.pos
    	local bmi, bma = GetBodyBounds(LLLEG)
		local bc = VecLerp(bmi, bma, 0.5)
		local ppos = enemy.pos
		local dir = VecSub(bc, ppos)
		local dist = VecLength(dir)
		dir = VecScale(dir, 1.0/dist)
		local add = VecScale(dir, weightb * 150)
		local vel = GetBodyVelocity(LLLEG)
		totvel = VecAdd(vel, add)
		SetBodyVelocity(LLLEG, totvel)
		walked1 = true
		walked2 = false
		end

		if walktimer > valkval and not walked2 then
		local ppos = enemy.pos
    	local bmi, bma = GetBodyBounds(RRLEG)
		local bc = VecLerp(bmi, bma, 0.5)
		local ppos = enemy.pos
		local dir = VecSub(bc, ppos)
		local dist = VecLength(dir)
		dir = VecScale(dir, 1.0/dist)
		local add = VecScale(dir, weightb * 150)
		local vel = GetBodyVelocity(RRLEG)
		totvel = VecAdd(vel, add)
		SetBodyVelocity(RRLEG, totvel)
		walked2 = true
		walked1 = false
		walktimer = 0
		end
		
		local target = enemy.pos
		local approachspeed = 5
		local smoothspeed = 5

		local ttr = GetBodyTransform(Torso)
		local currentavel = GetBodyAngularVelocity(Torso)

		local targetrot = QuatLookAt(ttr.pos, target)
		local ltargetrot = TransformToLocalTransform(ttr, Transform(Vec(), targetrot))
		local targetavel = VecScale(Vec(GetQuatEuler(ltargetrot.rot)), approachspeed)
		local diff = VecSub(targetavel, currentavel)
		diff[1] = math.max(math.min(diff[1], smoothspeed), -smoothspeed)
		diff[2] = math.max(math.min(diff[2], smoothspeed), -smoothspeed)
		diff[3] = math.max(math.min(diff[3], smoothspeed), -smoothspeed)
		SetBodyAngularVelocity(Torso, VecAdd(currentavel, diff))

	end

	  if alive and walk then
    	if agro or HasTag(Torso, "Zombie") then
    		trippingspeed = 10
    		attacktim = attacktim + dt
    local ppos = enemy.pos
    local bmi, bma = GetBodyBounds(LLARM)
		local bc = VecLerp(bmi, bma, 0.5)
		local ppos = enemy.pos
		local dir = VecSub(bc, ppos)
		local dist = VecLength(dir)
		dir = VecScale(dir, 1.0/dist)
		weightb = startweightb

	if attacktim > attackslash then
		if not att1 then
    weightb = attackforce
	if not Leftbroke then
	local add = VecScale(dir, weightb)
	local vel = GetBodyVelocity(LLARM)
	vel = VecAdd(vel, add)
    SetBodyVelocity(LLARM, vel)
    if Hit then
    	SetPlayerHealth(GetPlayerHealth() - damage)
    	PlaySound(punchsnd, HeadPos.pos)
    else
    	--PlaySound(miss, HeadPos.pos)
    end
    att1 = true
    att2 = false
	end
	end

	if attacktim > attackslash * 2 then
		if not att2 then
	weightb = attackforce
    attacktim = 0
    if not rightbroke then
    local add = VecScale(dir, weightb)
	local vel = GetBodyVelocity(LLARM)
	vel = VecAdd(vel, add)
    SetBodyVelocity(RRARM, vel)
    att2 = true
    att1 = false
   if Hit then
    	SetPlayerHealth(GetPlayerHealth() - damage)
    	PlaySound(punchsnd, HeadPos.pos)
    else
    	--PlaySound(miss, HeadPos.pos)
    end

	end
    end
end
end
    weightb = startweightb
local bmi, bma = GetBodyBounds(RRARM)
		local bc = VecLerp(bmi, bma, 0.5)
		local ppos = enemy.pos
		local dir = VecSub(bc, ppos)
		local dist = VecLength(dir)
		dir = VecScale(dir, 1.0/dist)
    local add = VecScale(dir, weightb)
	local vel = GetBodyVelocity(RRARM)
	vel = VecAdd(vel, add)
	if not rightbroke then
    SetBodyVelocity(RRARM, vel)
end
if not Leftbroke then
    SetBodyVelocity(LLARM, vel)
end
end
end

	gunTrans = GetBodyTransform(Head)
	gunPos = gunTrans.pos
	direction = TransformToParentVec(gunTrans, Vec(0, -1, 0))
	 shootPos = VecAdd(gunPos, VecScale(direction,0.2))

	if IsBodyBroken(Head) then
		alive = false
	end
end

	drawtext = false

	HeadBloodCapacity = GetBodyMass(Head)
	Bleed = StartingBleed - HeadBloodCapacity
	HeadPos = GetBodyTransform(Head)

	TorsoBloodCapacity = GetBodyMass(Torso)
	Bleed1 = StartingBleed1 - TorsoBloodCapacity
	TorsoPos = GetBodyTransform(Torso)

	LARMBloodCapacity = GetBodyMass(LARM)
	Bleed2 = StartingBleed2 - LARMBloodCapacity
	LARMPos = GetBodyTransform(LARM)

	LLARMBloodCapacity = GetBodyMass(LLARM)
	Bleed3 = StartingBleed3 - LLARMBloodCapacity
	LLARMPos = GetBodyTransform(LLARM)

	RARMBloodCapacity = GetBodyMass(RARM)
	Bleed4 = StartingBleed4 - RARMBloodCapacity
	RARMPos = GetBodyTransform(RARM)

	RRARMBloodCapacity = GetBodyMass(RRARM)
	Bleed5 = StartingBleed5 - RRARMBloodCapacity
	RRARMPos = GetBodyTransform(RRARM)

	LLEGBloodCapacity = GetBodyMass(LLEG)
	Bleed6 = StartingBleed6 - LLEGBloodCapacity
	LLEGPos = GetBodyTransform(LLEG)

	LLLEGBloodCapacity = GetBodyMass(LLLEG)
	Bleed7 = StartingBleed7 - LLLEGBloodCapacity
	LLLEGPos = GetBodyTransform(LLLEG)

	RLEGBloodCapacity = GetBodyMass(RLEG)
	Bleed8 = StartingBleed8 - RLEGBloodCapacity
	RLEGPos = GetBodyTransform(RLEG)

	RRLEGBloodCapacity = GetBodyMass(RRLEG)
	Bleed9 = StartingBleed9 - RRLEGBloodCapacity
	RRLEGPos = GetBodyTransform(RRLEG)

--HEAD HEAD HEAD HEAD HEAD HEAD LLEGHEAD HEAD HEAD HEAD
	if bleed then
	if IsBodyBroken(Head) then

		for i=1, 9 do
		 	 thingz = FindJoints("eye")
		 	 for i=1, #thingz do
		 	 	thinz = thingz[i]
		 	 	Delete(thinz)
		 	 end
		 end

		for i=1,Bleed/2 do
		smoke()
	end
end
end

if bleed then
	
		if HeadBloodCapacity < MaxBloodCapacity then
		Bleed = Bleed * 6 

		for i=1,Bleed/6 do
		smoke()
	end
	end

HeadBloodLevel = HeadBloodLevel - Bleed/2
end

	if HeadBloodLevel <= 0 then
		bleed = false
		HeadBloodLevel = 0
	end

	--TORSO TORSO TORSO TORSO TORSO TORSO TORSO

	if bleed1 then
	if IsBodyBroken(Torso) then
		for i=1,Bleed1/regularantibleed do
		smoke1()
	end
end
end

if bleed1 then

		if TorsoBloodCapacity < MaxBloodCapacity1/2 then
		Bleed1 = Bleed1 * 6 

		 for i=1, 9 do
		 	 things = FindBodies("gut", true)
		 	 for i=1, #things do
		 	 	thing = things[i]
		 	 	SetBodyDynamic(thing, true)
		 	 end
		 end
		for i=1,Bleed1/extremeantibleed do
		smoke1()
	end
	end

TorsoBloodLevel = TorsoBloodLevel - Bleed1
end

	if TorsoBloodLevel <= 0 then
		bleed1 = false
		TorsoBloodLevel = 0
	end

-- ARMARMARMARMAMRAMRMARMAMRAMRMARMAMRAMMARMAMAMRMARMMRMARMRMAMRMAR

if bleed2 then

	if LARMBloodCapacity < MaxBloodCapacity2/3 then
		Bleed2 = Bleed2 * 6 

		for i=1,Bleed2/extremeantibleed do
		smoke2()
	end
	end

	if IsBodyBroken(LARM) then
		for i=1,Bleed2/limbantibleed do
		smoke2()
	end
end
end

if bleed2 then
LARMBloodLevel = LARMBloodLevel - Bleed2*LimbBleedSpeed
end

	if LARMBloodLevel <= 0 then
		bleed2 = false
		LARMBloodLevel = 0
	end

	--aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa

if bleed3 then

	if LLARMBloodCapacity < MaxBloodCapacity3/3 then
		Bleed3 = Bleed3 * 6 

		for i=1,Bleed3/extremeantibleed do
		smoke3()
	end
	end

	if IsBodyBroken(LLARM) then
		for i=1,Bleed3/limbantibleed do
		smoke3()
	end
end
end

if bleed3 then
LLARMBloodLevel = LLARMBloodLevel - Bleed3*LimbBleedSpeed
end

	if LLARMBloodLevel <= 0 then
		bleed3 = false
		LLARMBloodLevel = 0
	end

	--aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa

	if bleed4 then

		if RARMBloodCapacity < MaxBloodCapacity4/3 then
		Bleed4 = Bleed4 * 6 

		for i=1,Bleed4/extremeantibleed do
		smoke4()
	end
	end

	if IsBodyBroken(RARM) then
		for i=1,Bleed4/limbantibleed do
		smoke4()
	end
end
end

if bleed4 then
RARMBloodLevel = RARMBloodLevel - Bleed4*LimbBleedSpeed
end

	if RARMBloodLevel <= 0 then
		bleed4 = false
		RARMBloodLevel = 0
	end

	--aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa

	if bleed5 then

		if RRARMBloodCapacity < MaxBloodCapacity5/3 then
		Bleed5 = Bleed5 * 6 

		for i=1,Bleed5/extremeantibleed do
		smoke5()
	end
	end

	if IsBodyBroken(RRARM) then
		for i=1,Bleed5/limbantibleed do
		smoke5()
	end
end
end

if bleed5 then
RRARMBloodLevel = RRARMBloodLevel - Bleed5*LimbBleedSpeed
end

	if RRARMBloodLevel <= 0 then
		bleed5 = false
		RRARMBloodLevel = 0
	end

	--LEGLEGLEGLELGLELGLGLELGLEGLLGLEGLELGLEGLELGLEGLEGLELGELLEGLEGLLEGLEGLGELGELGLEGLELGELGLEGLEGLLEGLEGLLEGLELGLEGLELGLEGLLEGLELGELGELG

	if bleed6 then

		if LLEGBloodCapacity < MaxBloodCapacity6/3 then
		Bleed6 = Bleed6 * 6 

		for i=1,Bleed6/extremeantibleed do
		smoke6()
	end
	end

	if IsBodyBroken(LLEG) then
		for i=1,Bleed6/limbantibleed do
		smoke6()
	end
end
end

if bleed6 then
LLEGBloodLevel = LLEGBloodLevel - Bleed6*LimbBleedSpeed
end

	if LLEGBloodLevel <= 0 then
		bleed6 = false
	LLEGBloodLevel = 0
	end

	--lllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll

	if bleed7 then

		if LLLEGBloodCapacity < MaxBloodCapacity7/3 then
		Bleed7 = Bleed7 * 6 

		for i=1,Bleed7/extremeantibleed do
		smoke7()
	end
	end

	if IsBodyBroken(LLLEG) then
		for i=1,Bleed7/limbantibleed do
		smoke7()
	end
end
end

if bleed7 then
LLLEGBloodLevel = LLLEGBloodLevel - Bleed7*LimbBleedSpeed
end

	if LLLEGBloodLevel <= 0 then
		bleed7 = false
	LLLEGBloodLevel = 0
	end

	--lllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll

	if bleed8 then

		if RLEGBloodCapacity < MaxBloodCapacity8/3 then
		Bleed8 = Bleed8 * 6 

		for i=1,Bleed8/extremeantibleed do
		smoke8()
	end
	end

	if IsBodyBroken(RLEG) then
		for i=1,Bleed8/limbantibleed do
		smoke8()
	end
end
end

if bleed8 then
RLEGBloodLevel = RLEGBloodLevel - Bleed8*LimbBleedSpeed
end

	if RLEGBloodLevel <= 0 then
		bleed8 = false
	RLEGBloodLevel = 0
	end

	--lllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll

	if bleed9 then

		if RRLEGBloodCapacity < MaxBloodCapacity9/3 then
		Bleed9 = Bleed9 * 6 

		for i=1,Bleed9/extremeantibleed do
		smoke9()
	end
	end

	if IsBodyBroken(RRLEG) then
		for i=1,Bleed9/limbantibleed do
		smoke9()
	end
end
end

if bleed9 then
RRLEGBloodLevel = RRLEGBloodLevel - Bleed9*LimbBleedSpeed
end

	if RRLEGBloodLevel <= 0 then
		bleed9 = false
	RRLEGBloodLevel = 0
	end

	TotalLegBloodCapacity = MaxBloodCapacity6 + MaxBloodCapacity7 + MaxBloodCapacity8 + MaxBloodCapacity9
	TotalLegBloodValue = RRLEGBloodLevel + RLEGBloodLevel + LLLEGBloodLevel + LLEGBloodLevel

	TotalBloodValue = RRLEGBloodLevel + RLEGBloodLevel + LLLEGBloodLevel + LLEGBloodLevel + RRARMBloodLevel + RARMBloodLevel + LLARMBloodLevel + LARMBloodLevel + TorsoBloodLevel + HeadBloodLevel
		upspeed[2] = TotalLegBloodValue/Shock
		if IsBodyBroken(LLLEG) then
			upspeed[2] = upspeed[2] / 2
		end
		if IsBodyBroken(LRLEG) then
			upspeed[2] = upspeed[2] / 2
		end



	currentvel = GetBodyVelocity(Head)
	currentvel1 = GetBodyVelocity(LLLEG)
	currentvel2 = GetBodyVelocity(RRLEG)

	if IsBodyBroken(Head) then
		alive = false
	end

	if not HasTag(Torso, "Zombie") then
	if TorsoBloodLevel < MaxBloodCapacity1/4 or TorsoBloodCapacity < MaxBloodCapacity1/3 then
		alive = false
	end

	if TotalBloodValue < MinBloodValue then
		alive = false
	end
end
	if alive and not tripped then
	SetBodyVelocity(Head,VecAdd(currentvel,upspeed))
	SetBodyVelocity(LLLEG,VecAdd(currentvel1,downspeed))
	SetBodyVelocity(RRLEG,VecAdd(currentvel2,downspeed))
end

a = GetPlayerTransform()

	distToPlayer = VecLength(VecSub(a.pos, TorsoPos.pos))

	if distToPlayer < 3 then
		inrange = true
	else
		inrange = false
	end

	if not started then
		startblood = TotalBloodValue
		started = true
	end

	if TotalBloodValue < startblood/1.1 then
		conditioncritical = true
	end

end


function smoke()
    --spawn sparks
    ParticleType("smoke")
    ParticleColor(0.3, 0, 0)
    ParticleRadius(0.05, 0.005)
    ParticleAlpha(1000)
    ParticleCollide(1)
    ParticleGravity(bloodgrav)
    ParticleSticky(0.5)
    ParticleDrag(blooddrag)
    ParticleStretch(1)
    SpawnParticle(HeadPos.pos, Vec(math.random(-Bleed/antibleed, Bleed/antibleed), math.random(-Bleed/antibleed, Bleed/antibleed), math.random(-Bleed/antibleed, Bleed/antibleed)),10)
end

function smoke1()
    --spawn sparks
     ParticleType("smoke")
    ParticleColor(0.3, 0, 0)
    ParticleRadius(0.05, 0.005)
    ParticleAlpha(1000)
    ParticleCollide(1)
    ParticleGravity(bloodgrav)
    ParticleSticky(0.5)
    ParticleDrag(blooddrag)
    ParticleStretch(1)
    SpawnParticle(TorsoPos.pos, Vec(math.random(-Bleed1/antibleed, Bleed1/antibleed), math.random(-Bleed1/antibleed, Bleed1/antibleed), math.random(-Bleed1/antibleed, Bleed1/antibleed)),10)
end

function smoke2()
    --spawn sparks
    ParticleType("smoke")
    ParticleColor(0.3, 0, 0)
    ParticleRadius(0.05, 0.005)
    ParticleAlpha(1000)
    ParticleCollide(1)
    ParticleGravity(bloodgrav)
    ParticleSticky(0.5)
    ParticleDrag(blooddrag)
    ParticleStretch(1)
    SpawnParticle(LARMPos.pos, Vec(math.random(-Bleed2/antibleed, Bleed2/antibleed), math.random(-Bleed2/antibleed, Bleed2/antibleed), math.random(-Bleed2/antibleed, Bleed2/antibleed)),10)
end

function smoke3()
    --spawn sparks
     ParticleType("smoke")
    ParticleColor(0.3, 0, 0)
    ParticleRadius(0.05, 0.005)
    ParticleAlpha(1000)
    ParticleCollide(1)
    ParticleGravity(bloodgrav)
    ParticleSticky(0.5)
    ParticleDrag(blooddrag)
    ParticleStretch(1)
    SpawnParticle(LLARMPos.pos, Vec(math.random(-Bleed3/antibleed, Bleed3/antibleed), math.random(-Bleed3/antibleed, Bleed3/antibleed), math.random(-Bleed3/antibleed, Bleed3/antibleed)),10)
end

function smoke4()
    --spawn sparks
    ParticleType("smoke")
    ParticleColor(0.3, 0, 0)
    ParticleRadius(0.05, 0.005)
    ParticleAlpha(1000)
    ParticleCollide(1)
    ParticleGravity(bloodgrav)
    ParticleSticky(0.5)
    ParticleDrag(blooddrag)
    ParticleStretch(1)
    SpawnParticle(RARMPos.pos, Vec(math.random(-Bleed3/antibleed, Bleed3/antibleed), math.random(-Bleed3/antibleed, Bleed3/antibleed), math.random(-Bleed3/antibleed, Bleed3/antibleed)),10)
end

function smoke5()
    --spawn sparks
    ParticleType("smoke")
    ParticleColor(0.3, 0, 0)
    ParticleRadius(0.05, 0.005)
    ParticleAlpha(1000)
    ParticleCollide(1)
    ParticleGravity(bloodgrav)
    ParticleSticky(0.5)
    ParticleDrag(blooddrag)
    ParticleStretch(1)
    SpawnParticle(RRARMPos.pos, Vec(math.random(-Bleed3/antibleed, Bleed3/antibleed), math.random(-Bleed3/antibleed, Bleed3/antibleed), math.random(-Bleed3/antibleed, Bleed3/antibleed)),10)
end

function smoke6()
    --spawn sparks
    ParticleType("smoke")
    ParticleColor(0.3, 0, 0)
    ParticleRadius(0.05, 0.005)
    ParticleAlpha(1000)
    ParticleCollide(1)
    ParticleGravity(bloodgrav)
    ParticleSticky(0.5)
    ParticleDrag(blooddrag)
    ParticleStretch(1)
    SpawnParticle(LLEGPos.pos, Vec(math.random(-Bleed3/antibleed, Bleed3/antibleed), math.random(-Bleed3/antibleed, Bleed3/antibleed), math.random(-Bleed3/antibleed, Bleed3/antibleed)),10)
end

function smoke7()
    --spawn sparks
    ParticleType("smoke")
    ParticleColor(0.3, 0, 0)
    ParticleRadius(0.05, 0.005)
    ParticleAlpha(1000)
    ParticleCollide(1)
    ParticleGravity(bloodgrav)
    ParticleSticky(0.5)
    ParticleDrag(blooddrag)
    ParticleStretch(1)
    SpawnParticle(LLLEGPos.pos, Vec(math.random(-Bleed3/antibleed, Bleed3/antibleed), math.random(-Bleed3/antibleed, Bleed3/antibleed), math.random(-Bleed3/antibleed, Bleed3/antibleed)),10)
end

function smoke8()
    --spawn sparks
    ParticleType("smoke")
    ParticleColor(0.3, 0, 0)
    ParticleRadius(0.05, 0.005)
    ParticleAlpha(1000)
    ParticleCollide(1)
    ParticleGravity(bloodgrav)
    ParticleSticky(0.5)
    ParticleDrag(blooddrag)
    ParticleStretch(1)
    SpawnParticle(RLEGPos.pos, Vec(math.random(-Bleed3/antibleed, Bleed3/antibleed), math.random(-Bleed3/antibleed, Bleed3/antibleed), math.random(-Bleed3/antibleed, Bleed3/antibleed)),10)
end

function smoke9()
    --spawn sparks
    ParticleType("smoke")
    ParticleColor(0.3, 0, 0)
    ParticleRadius(0.05, 0.005)
    ParticleAlpha(1000)
    ParticleCollide(1)
    ParticleGravity(bloodgrav)
    ParticleSticky(0.5)
    ParticleDrag(blooddrag)
    ParticleStretch(1)
    SpawnParticle(RRLEGPos.pos, Vec(math.random(-Bleed3/antibleed, Bleed3/antibleed), math.random(-Bleed3/antibleed, Bleed3/antibleed), math.random(-Bleed3/antibleed, Bleed3/antibleed)),10)
end

function draw()
if drawtext then
    UiPush()
      UiAlign("center middle")
      UiTranslate(400, 200)
      UiFont("bold.ttf", 30)
      UiText("Head Blood Level:  "..HeadBloodLevel)
    UiPop()

     UiPush()
      UiAlign("center middle")
      UiTranslate(400, 220)
      UiFont("bold.ttf", 30)
      UiText("Torso Blood Level:  "..TorsoBloodLevel)
    UiPop()

    UiPush()
      UiAlign("center middle")
      UiTranslate(400, 240)
      UiFont("bold.ttf", 30)
      UiText("upper left arm Blood Level:  "..LARMBloodLevel)
    UiPop()

     UiPush()
      UiAlign("center middle")
      UiTranslate(400, 260)
      UiFont("bold.ttf", 30)
      UiText("Lower left arm Blood Level:  "..LLARMBloodLevel)
    UiPop()

     UiPush()
      UiAlign("center middle")
      UiTranslate(400, 280)
      UiFont("bold.ttf", 30)
      UiText("Upper right arm Blood Level:  "..RARMBloodLevel)
    UiPop()

    UiPush()
      UiAlign("center middle")
      UiTranslate(400, 300)
      UiFont("bold.ttf", 30)
      UiText("Lower right arm Blood Level:  "..RRARMBloodLevel)
    UiPop()

    UiPush()
      UiAlign("center middle")
      UiTranslate(400, 320)
      UiFont("bold.ttf", 30)
      UiText("Upper left leg Blood Level:  "..LLEGBloodLevel)
    UiPop()

    UiPush()
      UiAlign("center middle")
      UiTranslate(400, 340)
      UiFont("bold.ttf", 30)
      UiText("Lower left leg Blood Level:  "..LLLEGBloodLevel)
    UiPop()

     UiPush()
      UiAlign("center middle")
      UiTranslate(400, 360)
      UiFont("bold.ttf", 30)
      UiText("Upper right leg Blood Level:  "..RLEGBloodLevel)
    UiPop()

     UiPush()
      UiAlign("center middle")
      UiTranslate(400, 380)
      UiFont("bold.ttf", 30)
      UiText("Lower right leg Blood Level:  "..RRLEGBloodLevel)
    UiPop()

    UiPush()
      UiAlign("center middle")
      UiTranslate(400, 400)
      UiFont("bold.ttf", 30)
      UiText("total Blood Level:  "..TotalBloodValue)
    UiPop()
end
if inrange then
	if enabled then
	UiPush()
      UiAlign("center middle")
      UiTranslate(900, 300)
      UiColor(0,0,1)
     UiFont("bold.ttf", 30)
      UiText("To disable viewable ragdoll stats, press H ")
      UiTranslate(-10, -30)
       UiFont("bold.ttf", 30)
      UiText("To enable XRAY, press L ")
    UiPop()
	UiPush()
      UiAlign("center middle")
      UiTranslate(900, 350)
      UiColor(0,1,0)
      UiFont("bold.ttf", 30)
      UiText("Total Blood Volume:  "..TotalBloodValue)
    UiPop()

    if alive then
    	  UiPush()
      UiAlign("center middle")
      UiTranslate(900, 400)
      UiColor(0,1,0)
      UiFont("bold.ttf", 60)
      UiText("ALIVE")
    UiPop()
    if HasTag(Torso, "Zombie") then
    	UiPush()
      UiAlign("center middle")
      UiTranslate(900, 450)
      UiColor(1,1,1)
      UiFont("bold.ttf", 50)
      UiText("INFECTED")
    UiPop()
else
		UiPush()
      UiAlign("center middle")
      UiTranslate(900, 450)
      UiColor(1,1,1)
      UiFont("bold.ttf", 30)
      UiText("infection: "..infection)
    UiPop()
    if conditioncritical then
    	UiPush()
      UiAlign("center middle")
      UiTranslate(900, 490)
      UiColor(1,1,0)
      UiFont("bold.ttf", 30)
      UiText("CRITICAL CONDITION")
    UiPop()
end
end
end
end
if not alive and enabled then
	  UiPush()
	  UiColor(1,0,0)
      UiAlign("center middle")
      UiTranslate(900, 400)
      UiFont("bold.ttf", 60)
      UiText("DECEASED")
    UiPop()
end
end
end

function canSeePlayer()
    local camTrans = GetPlayerCameraTransform()
	local playerPos = camTrans.pos

	--Direction to player
	local dir = VecSub(playerPos, shootPos)
	local dist = VecLength(dir)
	dir = VecNormalize(dir)

	QueryRejectVehicle(GetPlayerVehicle())
	return not QueryRaycast(shootPos, dir, dist, 0, true)
end
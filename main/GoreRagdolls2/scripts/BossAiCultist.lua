projectileHandler = {
	shellNum = 1,
	shells = {},
	defaultShell = {active = false}
}

casing = {
	amount = 1,
	shells = {},
	defaultShell = {
		active = false,
		grenadeTimer = 0,
		boomTimer = 0,
		bounces = 0,
		pos = Vec(0,0,0),
		type = "casing",
		crot = 0
	}
}



function init()
	ShoulderJoints = FindJoints("shoulder")
	ArmJoints = FindJoints("hand1")
	Eyes = FindBody("Head")
	Torso = FindBody("Torso")
	R_ARM = FindBody("LLARM")
	HipJoints = FindJoints("hip")
	KneeJoints = FindJoints("knee")
	walktim = 0
	speed = 0.15

	ShootTimer = 0
	shootTimer = 0
	shotDelay = 0.09
	damage = 0.15
	gravity = Vec(0, -40, 0)
	velocity = 300 --tonumber(GetTagValue(barrel, "bulletspeed"))
	maxMomentum = 1
	ShootTimMax = 0.5
	--GetTagValue(barrel,"gun")
	--shoot = LoadSound("MOD/snd/".."makarov"..".ogg")
	shoot = LoadSound("MOD/snd/"..GetTagValue(barrel, "gun")..".ogg")
	rpghit = LoadSound("MOD/snd/rpghit.ogg")
	rpghitdist = LoadSound("MOD/snd/rpghitdist.ogg")
	BulletsShot = 0
	oldbulletsshot = 0
	bulletsshot = 1
	reloading = false
	reloadtim = 0
	maxreloadtim = 3
	barrel = FindShape("barrel")
	MagSize = tonumber(GetTagValue(barrel, "magsize"))
	maxrange = tonumber(GetTagValue(barrel, "range"))
	pdamage = tonumber(GetTagValue(barrel, "damage"))
	roundsize = tonumber(GetTagValue(barrel, "roundsize"))
	firerate = tonumber(GetTagValue(barrel, "firerate"))
	Fucked = false
	Torso = FindBody("Torso")
	exp = tonumber(GetTagValue(barrel, "exp"))
	expgrav = tonumber(GetTagValue(barrel, "expgrav"))
	for i=1, 150 do
		projectileHandler.shells[i] = deepcopy(projectileHandler.defaultShell)
	end
	if GetTagValue(barrel, "team") == friend then
		SetTag(Torso, "friend")
	end
	if GetTagValue(barrel, "team") == enemy then
		SetTag(Torso, "enemy")
	end
	deadtim = 0
	BW1 = LoadSound("MOD/snd/BWhiz1.ogg")
   	BW2 = LoadSound("MOD/snd/BWhiz2.ogg")
   	BW3 = LoadSound("MOD/snd/BWhiz3.ogg")
   	entirelystop = false
   	--canSeePlayer = false
   	gunshot = LoadSound("MOD/snd/"..GetTagValue(barrel, "gun")..".ogg")
   	rpggunshot = LoadSound("MOD/snd/"..GetTagValue(barrel, "gun").."dist.ogg")
   	DistGunShot = LoadSound("MOD/snd/"..GetTagValue(barrel, "gun").."dist.ogg")
   	ImpWood = LoadSound("MOD/snd/Impact/Impact_wood.ogg")
   	ImpMetal = LoadSound("MOD/snd/Impact/Impact_metal.ogg")
   	ImpGlass = LoadSound("MOD/snd/Impact/Impact_glass.ogg")
   	ImpDirt = LoadSound("MOD/snd/Impact/Impact_dirt.ogg")
   	ImpStone = LoadSound("MOD/snd/Impact/Impact_stone.ogg")
   	Hitboxes = FindTriggers("hitbox", true)
   	ReactionTim = 2
   	Maxreactiontim = ReactionTim
   	AimForHead = 0
   	MaxChanceForHeadshot = 15
   	Accuracy = 0.3
   	DruggedUp = GetBool("level.gamerule.drugs")
   	bossCultistLoop = LoadLoop("MOD/snd/Enemies/Boss/Boss_Cultist_Call.ogg")
   	if DruggedUp then
   		firerate = firerate/1.2
   		Maxreactiontim =  ReactionTim/4
   		Accuracy = Accuracy/2
   		maxrange = maxrange * 1.5
   	end
   	if HasTag(barrel, "nvg") then
   		nvg = true
   	else
   		nvg = false
   		Light = FindLight("gunlight")
   	end

   	if HasTag(barrel, "stealth") then
   		stealth = true
   	else
   		stealth = false
   	end
   	bodyparts = FindBodies("bodypart")
   	armorbroke = false
   	for i=1,#bodyparts do
   		SetTag(bodyparts[i], "unbreakable")
   	end
   	maxhp = 500
   	health = maxhp
   	ArmorBreak = LoadSound("MOD/snd/ArmorBreak.ogg")
   	Loot = FindBody("Loot")
   	enemyweapontag = GetTagValue(Loot, "interact")
   	RemoveTag(Loot, "interact")
   	bodyparts = FindBodies("bodypart", true)
end
function update(dt)
	if entirelystop and not finished then
      SetTag(Loot, "interact", enemyweapontag)
      finished = true
   	end

   	if VecLength(VecSub(GetPlayerTransform().pos, GetBodyTransform(Eyes).pos)) > 450 then
   		entirelystop = true
   	end

	if not entirelystop then
	PlayLoop(bossCultistLoop, GetShapeWorldTransform(barrel).pos, 10)
	DayPhase = GetString("level.dayphase")
	if DayPhase ~= "Night" then
		SetLightEnabled(Light, false)
	else
		SetLightEnabled(Light, true)
	end
	HT = GetBodyTransform(Eyes)
	DistToAim = VecLength(VecSub(GetAimPos(), HT.pos))
		canSeePlayerz = true

	if DistToAim < 3 and deadtim < 0.5 and Fucked and disttoplayer > 50 then
		lockcam = true
	end
	if deadtim > 0.5 then
		lockcam = false
	end
	if lockcam then
		if not humaned then
		HumanDeathCam = Vec(HT.pos[1] + math.random(-3,3), HT.pos[2] + math.random(0,3), HT.pos[3] + math.random(-3,3))
		humaned = true
		end
		rot = QuatLookAt(HumanDeathCam, HT.pos)
		SetCameraTransform(Transform(HumanDeathCam, rot))
		SetTimeScale(0.1)
		ApplyBodyImpulse(Eyes, Vec(0.001,0.001,0.001),Vec(0,0,0))

         	for i=1,#bodyparts do
          	  bodypart = bodyparts[i]
           	 DrawBodyOutline(bodypart, 1, 0, 0, 1)
        	 end
	end

	if tonumber(GetTagValue(Torso, "QueriedDamage")) > 0 then
		health = health - tonumber(GetTagValue(Torso, "QueriedDamage"))
		SetTag(Torso, "QueriedDamage", 0)
	end

	if health < 0 then
		if not alreadydone then
			alreadydone = true
			PlaySound(ArmorBreak)
			RemoveTag(Torso, "Boss")
			for i=1,#bodyparts do
				bodypart = bodyparts[i]
				RemoveTag(bodypart, "unbreakable")
			end
		end
	end

	if Fucked then
		deadtim = deadtim + dt
		if deadtim > 3 then
			entirelystop = true
			SetBool("savegame.mod.bountyboard.BossCultist", true)
			SetInt("savegame.mod.bountyboard.BossCultistC", GetInt("savegame.mod.bountyboard.BossCultistC")+1)
		end
	gunj = FindJoints("gun")
	for i=1,#gunj do
		Delete(gunj[i])
	end
	end
	if not HasTag(barrel, "stat") then
		stationary = false
	else
		stationary = true
	end
	if not Fucked then
	if HasTag(barrel, "exp") then
		rpg = true
		expvel = tonumber(GetTagValue(barrel, "expvel"))
		velocity = expvel
		gravity = Vec(0, -expgrav, 0)
	end

	if GetTagValue(barrel, "team") == "friend" then
		TT = GetBodyTransform(Torso)
		--DrawLine(TT.pos, Vec(TT.pos[1], TT.pos[2] + 10, TT.pos[3]), 0,0,1)
		Team = "friend"
	end
	if GetTagValue(barrel, "team") == "enemy" then
		TT = GetBodyTransform(Torso)
		--DrawLine(TT.pos, Vec(TT.pos[1], TT.pos[2] + 10, TT.pos[3]), 1,0,0)
		Team = "enemy"
	end

	if HasTag(Torso, "dead") or HasTag(Torso, "panicked") then
		Fucked = true
	end
	-- LOLOLOLOLOLOLOLOLOLOLOLOLOLOLOLOLOLOLOLOLOLOLOLOLOLOLOLOLOLOLOLOLOLOLOLOOOLOLOLOLOLOL
	gunTrans = GetBodyTransform(Eyes)
	gunPos = gunTrans.pos
	direction = TransformToParentVec(gunTrans, Vec(0, -1, 0))
	shootPos = VecAdd(gunPos, VecScale(direction,0.2))
	enemy = GetPlayerCameraTransform()
	disttoplayer = VecLength(VecSub(enemy.pos, gunTrans.pos))
	if reloading then
		reloadtim = reloadtim + dt
		if reloadtim > maxreloadtim then
			reloading = false
			reloadtim = 0
			BulletsShot = 0
		end
	end
	if canSeePlayerz then
		if AimForHead < MaxChanceForHeadshot then
		AimForHead = AimForHead + dt*0.5
		end

		if ReactionTim > 0 then
		ReactionTim = ReactionTim - dt
		end
	else
		if ReactionTim < Maxreactiontim then
		ReactionTim = ReactionTim + dt/8
		end

		if AimForHead > 0 then
			AimForHead = AimForHead - dt
		end
	end
	ShootTimer = ShootTimer + dt
	if canSeePlayerz and ShootTimer > firerate and not reloading and not Fucked and ReactionTim < 0 then
		if not run then
		Shoot()
		BulletsShot = BulletsShot + 1
		bulletsshot = bulletsshot + 1
		if BulletsShot == MagSize then
			reloading = true
		end
		ShootTimer = 0
	end
	end
	if not Fucked then
	FaceTowards()
	end
	if canSeePlayerz and not Fucked then
		--agro = true
		if not stationary then
		aimweapon()
		RunTowards()
		end
		range = maxrange
		if DayPhase == "Night" and not nvg then
		range = maxrange/2
		end
		if disttoplayer > range then
		run = true
	else
		run = false
		agro = false
	end
	end
end
end
end

function tick()
	draw()
	if not fucked then
	for key, shell in ipairs(projectileHandler.shells) do
		if shell.active then
			ProjectileOperations(shell)
		end
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
	rejectragdoll()
	return not QueryRaycast(shootPos, dir, dist, 0, true)
end

function rejectragdoll()
	for i=1,#bodyparts do
		QueryRejectBody(bodyparts[i])
	end
end

function aimweapon()
	if disttoplayer > 4 then
	SetJointMotor(ArmJoints[2], 0, 0)
	SetJointMotor(ShoulderJoints[1], 8)
	end
	if disttoplayer < 4 then
	SetJointMotor(ArmJoints[2], 8)
	SetJointMotor(ShoulderJoints[1], 0, 0)
	end
end

function RunTowards()
--if InputDown("o") then\
if run then
walktim = walktim + speed
--else
	--SetJointMotor(HipJoints[1], 0, 0)
	--SetJointMotor(HipJoints[2], 0, 0)
--end

if walktim > 1 and walktim < 1.5 then
	SetJointMotor(HipJoints[1], speed*275)
	SetJointMotor(HipJoints[2], -speed*275)
end
if walktim > 2 then
	SetJointMotor(HipJoints[2], speed*275)
	SetJointMotor(HipJoints[1], -speed*275)
	walktim = 0
end
else
	SetJointMotor(HipJoints[1], 0, 0)
	SetJointMotor(HipJoints[2], 0, 0)
end
end

function FaceTowards()
		armvel = -0.9
		local bmi, bma = GetBodyBounds(R_ARM)
      	local bc = VecLerp(bmi, bma, 0.5)
      	local ppos = VecSub(GetPlayerCameraTransform().pos, Vec(0,1,0))
      	local dir = VecSub(bc, ppos)
      	local dist = VecLength(dir)
      	dir = VecScale(dir, 1.0 / dist)
     	local add = VecScale(dir, armvel*8)
      	local vel = GetBodyVelocity(R_ARM)
      	Vel = VecAdd(vel, add)
      	--SetBodyVelocity(RRARM, Vel)

      	local target = enemy.pos
		local approachspeed = 35
		local smoothspeed = 35

		local ttr = GetBodyTransform(Torso)
		local currentavel = GetBodyAngularVelocity(Torso)

		local targetrot = QuatLookAt(ttr.pos, target)
		local ltargetrot = TransformToLocalTransform(ttr, Transform(Vec(), targetrot))
		local targetavel = VecScale(Vec(GetQuatEuler(ltargetrot.rot)), approachspeed)
		local diff = VecSub(targetavel, currentavel)
		diff[1] = 0 --math.max(math.min(diff[1], smoothspeed), -smoothspeed)
		diff[2] = math.max(math.min(diff[2], smoothspeed), -smoothspeed)
		diff[3] = 0 --math.max(math.min(diff[3], smoothspeed), -smoothspeed)
		SetBodyAngularVelocity(Torso, VecAdd(currentavel, diff))
		TorsoVel = VecLength(GetBodyVelocity(Torso))

		local target = enemy.pos
		local approachspeed = 1
		local smoothspeed = 1

		local ttr = GetBodyTransform(R_ARM)
		local currentavel = GetBodyAngularVelocity(R_ARM)
		x,y,z = GetQuatEuler(ttr.rot)
		ttr.rot = QuatEuler(x,y+90,z)
		local targetrot = QuatLookAt(ttr.pos, target)
		local ltargetrot = TransformToLocalTransform(ttr, Transform(Vec(), targetrot))
		local targetavel = VecScale(Vec(GetQuatEuler(ltargetrot.rot)), approachspeed)
		local diff = VecSub(targetavel, currentavel)
		diff[1] = 0 --math.max(math.min(diff[1], smoothspeed), -smoothspeed)
		diff[2] = math.max(math.min(diff[2], smoothspeed), -smoothspeed)
		diff[3] = 0 --math.max(math.min(diff[3], smoothspeed), -smoothspeed)
		SetBodyAngularVelocity(R_ARM, VecAdd(currentavel, diff))
end

function Shoot()

	local gt = GetShapeWorldTransform(barrel)
	local bb = enemy
	local fwdpos = enemy.pos
    local gunpos = TransformToParentPoint(gt, Vec(-0.2, 0, 0))
    if not stealth then
    ParticleColor(1,0.6,0.4,0.1,0.1,0.1,"linear",0,0.5)
        ParticleEmissive(2,0,"linear",0,0.5)
        ParticleRadius(0.02)
        ParticleCollide(1)
        ParticleAlpha(1.0,0.0)
        ParticleCollide(1)
        ParticleGravity(-4)
        ParticleStretch(1)
        ParticleDrag(0)
        for i=1,4 do
        SpawnParticle(gunpos, Vec(math.random(-800,800)/30, math.random(-800,800)/30, math.random(-800,800)/30), 1)
    	end
    	ParticleReset()

    PointLight(gunpos, 1,1,0,15)
	end
	dir = VecNormalize(VecSub(fwdpos, gunpos))
	PlaySound(gunshot, gunpos, 1)

	local maxSpread = InputDown("ctrl") and 1.5 or 3
	if ironsight then maxSpread = maxSpread / 3 end
	local factor = Accuracy

	dir[1] = dir[1] + (math.random()-0.5)*factor
	dir[2] = dir[2] + (math.random()-0.5)*factor
	dir[3] = dir[3] + (math.random()-0.5)*factor

	projectileHandler.shells[projectileHandler.shellNum] = deepcopy(projectileHandler.defaultShell)
	loadedShell = projectileHandler.shells[projectileHandler.shellNum]
	loadedShell.active = true
	loadedShell.pos = gunpos
	loadedShell.momentum = maxMomentum
	loadedShell.predictedBulletVelocity = VecScale(dir, velocity)
	projectileHandler.shellNum = (projectileHandler.shellNum%#projectileHandler.shells) + 1

	shootTimer = shotDelay

	--shootTimer = shotDelay
	--recoilTimer = shotDelay
	--lightTimer = shotDelay/2


	--if spentcasingsoption then
	--	SpentCasing()
	--end
end

function ProjectileOperations(projectile)
	projectile.predictedBulletVelocity = VecAdd(projectile.predictedBulletVelocity, (VecScale(gravity, GetTimeStep())))
	local dir = VecNormalize(projectile.predictedBulletVelocity)
	for i=1,#bodyparts do
		bodypart = bodyparts[i]
	QueryRejectBody(bodypart)
	end
	local hit, dist, normal, shape = QueryRaycast(projectile.pos, dir, VecLength(projectile.predictedBulletVelocity)*GetTimeStep())

	local point2 = VecAdd(projectile.pos, VecScale(dir, dist))
	local Player
	if GetPlayerVehicle()==0 then
		Player = VecAdd(GetPlayerTransform().pos, Vec(0, 1, 0))
	else
		Player = VecCopy(GetPlayerTransform().pos)
	end
	local Relative = VecSub(point2, Player)
	local Lookback = VecScale(dir,-VecLength(Relative))
	local Range = VecSub(Player, VecAdd(point2,Lookback))

	if not rpg and VecLength(Range) < (GetPlayerVehicle()==0 and .7 or .3) and projectile.momentum ~= 0 then
		--SetFloat("inventory.takedamage", damage)
		projectile.momentum = 0
		PlaySound(rpggunshot, GetPlayerTransform().pos, disttoplayer/10)
			--Hitbox = Hitboxes[math.random(1,#Hitboxes)]
			for i=1,#Hitboxes do
				Hitbox = Hitboxes[i]
				Rnd = math.random(0,100)
				if GetTagValue(Hitbox,"hitbox") == "HEAD" then
					--DebugPrint("Random: "..Rnd)
					--DebugPrint("bodypart 2: "..GetTagValue(Hitboxes[4],"hitbox"))
				if Rnd < AimForHead and not damagedone then
					-- DebugPrint("bodypart: HEAD")
				SetTag(Hitbox, "QueriedDamage", pdamage)
				SetTag(Hitbox, "S", roundsize)
				damagedone = true
				else
					if not damagedone then
				Hitbox = Hitboxes[math.random(1,3)]
				--DebugPrint("bodypart:"..GetTagValue(Hitbox,"hitbox"))
				if GetTagValue(Hitbox,"hitbox") ~= "HEAD" then
				SetTag(Hitbox, "QueriedDamage", pdamage)
				SetTag(Hitbox, "S", roundsize)
				damagedone = true
				end
				if not damagedone then
				Hitbox = Hitboxes[math.random(5,6)]
				--DebugPrint("bodypart:"..GetTagValue(Hitbox,"hitbox"))
				if GetTagValue(Hitbox,"hitbox") ~= "HEAD" then
				SetTag(Hitbox, "QueriedDamage", pdamage)
				SetTag(Hitbox, "S", roundsize)
				damagedone = true
				end
				end
				end
				end
			end
			damagedone = false
		end
	end

	--for i=1,#Hitboxes do
	--	Hitbox = Hitboxes[i]
	--	ppoint = projectile.pos
	--	min, max = GetTriggerBounds(Hitbox)
	--	tmiddleheight = (max[2] - min[2])/2
	--	tposition = GetTriggerTransform(Hitbox).pos
	--	tmiddlepoint = Vec(tposition[1], tmiddleheight, tposition[3])
	--	dist = VecLength(VecSub(ppoint, tmiddlepoint))
	--	lookbackpoint = GetTriggerClosestPoint(Hitbox)
	--	--lookbackpoint = VecAdd(ppoint,VecScale(dir,-dist))
	--	if IsPointInTrigger(Hitbox, lookbackpoint) then
	--		SetTag(Hitbox, "QueriedDamage", pdamage)
	--		SetTag(Hitbox, "S", roundsize)
	--		projectile.momentum = 0
	--		PlaySound(rpggunshot, GetPlayerTransform().pos, disttoplayer/10)
	--	end
	--end

	if rpg and GetTagValue(barrel, "gun") ~= "vgo"  then
		smoke()
		obog = projectile.pos
	end

	if not rpg and VecLength(Range) <  3.7 and projectile.momentum ~= 0 then
		PlaySound("BW"..math.random(1,3))
	end

	if bulletsshot > oldbulletsshot then
	PlaySound(DistGunShot, GetPlayerTransform().pos, disttoplayer/10)
	oldbulletsshot = bulletsshot
	end

	if hit then
		--hitPos = VecAdd(projectile.pos, VecScale(VecNormalize(VecSub(point2, projectile.pos)), dist))
		hitPos=point2
		if not stealth then
		DrawLine(projectile.pos, point2)
		end
		local mat, r, g, b, a = GetShapeMaterialAtPosition(shape, hitPos)

		if mat == "metal" or mat == "heavymetal" or mat == "hardmetal" then
			bounceangle = 20
			PlaySound(ImpMetal, projectile.pos, 0.2)
		else
			bounceangle = 10
		end

		if mat == "masonry" or mat == "concrete" or mat == "brick" then
			PlaySound(ImpStone, projectile.pos, 0.2)
		end

		if mat == "glass" then
			PlaySound(ImpGlass, projectile.pos, 0.2)
		end

		if mat == "plastic" or mat == "dirt" then
			PlaySound(ImpDirt, projectile.pos, 0.2)
		end

		if mat == "wood" then
			PlaySound(ImpWood, projectile.pos, 0.2)
		end




		local hitangle = math.acos(VecDot(projectile.predictedBulletVelocity, normal)/VecLength(projectile.predictedBulletVelocity))*57.3-90
		if hitangle < bounceangle and math.random(0, 100)/100 > (hitangle/bounceangle)^2 then
			PlaySound(bouncesound, projectile.pos, 1, false)
			local dot = VecDot(normal, projectile.predictedBulletVelocity)
			projectile.predictedBulletVelocity = VecSub(projectile.predictedBulletVelocity, VecScale(normal, dot*(1+math.random(1,10)/10)))
		else
			ApplyBodyImpulse(GetShapeBody(shape), hitPos, VecScale(projectile.predictedBulletVelocity, velocity/200))

			if mat == "glass" and math.random() > 0.65 then
				if rpg then
					Explosion(hitPos, exp)
					--PlaySound(rpghit, hitPos)
				end
				MakeHole(hitPos, 0.75)
				projectile.momentum = projectile.momentum - 0.2
			elseif mat == "metal" or mat == "heavymetal" or mat == "hardmetal" then
				SpawnParticle("smoke", hitPos, Vec(0, 1.0+math.random(1,10)*0.1, 0), damage, 1)
				ParticleReset()
				ParticleType("plain")
				ParticleTile(6)
				ParticleSticky(0, 0)
				ParticleRadius(0.1, 0.01)
				ParticleAlpha(1, 0)
				ParticleEmissive(10, 10)
				ParticleColor(1, 0.75, 0.25, 1, 0.25, 0.25)
				ParticleGravity(-10, -10)
				for i = 1, math.random(10, 10*maxMomentum) do
					SpawnParticle(hitPos, Vec((math.random(-100,100)/100)*5,(math.random(-100,100)/100)*5, (math.random(-100,100)/100)*5), math.random(10,25)/20)
				end
				PointLight(hitPos, 1, 0.75, 0.25, 0.25)
				projectile.momentum = projectile.momentum - 1
			else
				ParticleReset()
				ParticleType("plain")
				ParticleTile(6)
				ParticleSticky(0, 0)
				ParticleRadius(0.05, 0.05)
				ParticleAlpha(a, 0)
				ParticleEmissive(0, 0)
				ParticleColor(r, g, b, r, g, b)
				ParticleGravity(-10, -10)
				for i = 1, math.random(10, 10*maxMomentum) do
					SpawnParticle(hitPos, Vec((math.random(-100,100)/100)*5,(math.random(-100,100)/100)*5, (math.random(-100,100)/100)*5), math.random(10,25)/20)
					if mat == "dirt" then
						ParticleTile(1)
						ParticleRadius(0.5, 0.1)
						SpawnParticle(hitPos, Vec((math.random(-100,100)/100),(math.random(-100,100)/100)*5, (math.random(-100,100)/100)), math.random(10,25)/20)
					end
				end
				projectile.momentum = projectile.momentum - 0.5
			end

			local factor = 1

			if rpg then
					Explosion(hitPos, exp)
					PlaySound(rpghit, hitPos)
					projectile.active = false
					distfromhittoplayer = VecLength(VecSub(GetPlayerCameraTransform().pos, hitPos))
					PlaySound(rpghitdist, GetPlayerCameraTransform().pos, distfromhittoplayer/10)
			end

			MakeHole(hitPos, damage*factor, damage*0.85*factor, damage*0.7*factor)
		end
	else
		--point2 = VecAdd(projectile.pos, VecScale(projectile.predictedBulletVelocity, GetTimeStep()))
		if not stealth then
		DrawLine(projectile.pos, point2)
	end
	end

	if projectile.momentum < 0.1 or projectile.pos[2] < 0 or VecLength(VecSub(point2, projectile.pos)) < 0.01 then
		projectile.active = false
	end

	projectile.pos = point2
end

function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else
        copy = orig
    end
    return copy
end

function draw()
	if health < 0 then

		if donnit then
			fade = fade - 0.01
		end

	if not donnit then
    	fade = 1
    	donnit = true
    end

    UiPush()
      UiAlign("center middle")
      UiTranslate(UiCenter(), UiHeight()/2)
      UiFont("bold.ttf", 200)
      UiColor(0.5,0,1,fade)
      UiText("X")
    UiPop()
end
end

function smoke()
    --spawn sparks
    ParticleReset()
    ParticleType("smoke")
    ParticleColor(0.3, 0.3, 0.3)
    ParticleRadius(0.5, 1)
    ParticleAlpha(1000)
    ParticleCollide(1)
    ParticleGravity(-1)
    ParticleSticky(0)
    ParticleDrag(0.5)
    ParticleStretch(1)
    SpawnParticle(obog, Vec(0,0,0),10)
    ParticleReset()
end

function GetAimPos()
   local ct = GetPlayerCameraTransform()
   local forwardPos = TransformToParentPoint(ct, Vec(0, 0, -200))
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
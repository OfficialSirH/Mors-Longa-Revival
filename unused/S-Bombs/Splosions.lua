--[[
#include "script/common.lua"
#include "/../TABS/scripts/Debug/UiFunctions.lua"
#include "/../TABS/scripts/Debug/UiSettings.lua"
#include "UiTest.lua"
#include "../TABS/scripts/ballistics.lua"
]]

spallHandler = {
	shellNum = 1,
	shells = {},
	defaultShell = {active = false}
}
--Spall(pos, Vec(0,1,0), projectile.shrapnelamount, projectile.explosionpayload*20, projectile.momentum, 1) -- this is called on explosion

function SplosionInit()
	InitialiseOptions()

	debuglines = {}
	debugholes = {}
	drawdebug = true
	
	ArmTim = 0

	Devices = {
		RG42 = {
			--BASIC INFO
			Type = "Grenade", -- Type of the explosive device
			Name = "RG42", -- Name of the explosive device
			RequireArm = true, -- Require arm adds a difference between explosive devices that can be armed (for example grenades) and explosives that cant be armed (barrel of gunpowder)
			Fuse = 3.2, -- How much time it takes for the explosive to detonate, only works if requirearm is true
			--DAMAGE
			ExplosionDamage = 1, -- Amount of damage directly done to the environment by the explosive
			Edmg = 5, -- Pressure damage done by explosive
			--SHOCKWAVE
			Force = 7, -- Maximum force applied to objects
			ForceRange = 2, -- does nothing atm
			Shockwave = 4, -- Amount of shockwave particles
			--PARTICLES
			ParticleAmount = 60, -- How dense the particles for the explosion are going to be
			ShockParticleSize = 0.1, -- Shockwave particle size
			PType = "plain", -- particle Type
			PC = 0, -- particle collide
			DG = -1, -- debri gravity
			PLife = 7, -- particle lifetime
			BDebri = true, -- Debri bool, determines if debri is expelled by explosion
			ShockParticleSize = 0.01, -- Shockwave particle size
			ParticleSize = {1, 3},-- Explosion particle size
			PR = 0.7, -- Particle red
			PG = 0.7, -- Particle green
			PB = 0.7, -- particle blue
			PA = 0.7, -- particle alpha
			PD = 0.5, -- particle drag
			PGr = 1, -- particle gravity
			PC = 0, -- particle collide
			ExtraUpVel = 5, -- How much the smoke will move upwards
			Violence = 13, -- How fast the particles from the explosion will travel
			--LIGHTS
			Flash = 30, -- strength of explosion flash 
			Glare = 0.3, -- how long the explosion flash will stay
			DynamicRange = 5, -- maximum distance the explosion can affect objects at
			--FAST SHRAPNEL
			Shrapnel = 10,  -- Amount of shrapnel ejected by the explosive over time
			MaxShrapSize = 2, -- maximum size of shrapnel (VISUAL ONLY)
			ShrapVel = 80, -- maximum shrapnel velocity (VISUAL ONLY)
			ShrapCollide = 0, -- Will shrapnel collide
			ShrapMaxDist = 70, -- Maximum distance the shrapnel can travel
			ShrapDamageMax = 0.5, -- Maximum amount of damage done by shrapnel depending on distance
			ShrapnelType = "realistic", -- Type of shrapnel, can be either fast or realistic
			--REALISTIC SHRAPNEL
			RShrapnel = 400, -- Amount of realistic shrapnel, only spawned at explosion so it has to be higher than fast shrapnel
			RShrapnelPen = 10, -- Amount of realistic shrapnel penetration
			RShrapVelocity = 100, -- The speed of the realistic shrapnel
			-- Both Shrapnel
			Shaped = false;
		},
		Stielhandgranate = {
			Type = "Grenade",
			Name = "Stielhandgranate",
			Fuse = 4.5,
			Violence = 27,
			ParticleAmount = 90,
			ExplosionDamage = 1,
			Shrapnel = 20,
			Force = 3,
			ForceRange = 5,
			Shockwave = 4, 
			ShockParticleSize = 0.1, 
			RequireArm = true,
			PType = "plain", -- particle Type
			PC = 0, -- particle collide
			DG = -1, -- debri gravity
			PLife = 7, -- particle lifetime
			BDebri = true, -- Debri bool, determines if debri is expelled by explosion
			ShockParticleSize = 0.01, -- Shockwave particle size
			ParticleSize = {1, 3},-- Explosion particle size
			PR = 0.9,
			PG = 0.9,
			PB = 0.9,
			PA = 1,
			PD = 0.5,
			Flash = 50,
			Glare = 0.3,
			DynamicRange = 5,
			PGr = 1,
			Edmg = 5,
			MaxShrapSize = 3,
			ShrapVel = 80,
			ShrapCollide = 0,
			ShrapMaxDist = 70,
			ShrapDamageMax = 0.5,
			ExtraUpVel = 3,
			ShrapnelType = "realistic",
			RShrapnel = 90,
			RShrapnelPen = 20,
			RShrapVelocity = 120,
			Shaped = false;
		},
		PMN4 = {
			Type = "Mine",
			Name = "PMN-4",
			Fuse = 2.5,
			Violence = 17,
			ParticleAmount = 30,
			ExplosionDamage = 1,
			Shrapnel = 25,
			Force = 2,
			ForceRange = 3,
			Shockwave = 1, 
			ShockParticleSize = 0.1, 
			RequireArm = true,
			PType = "plain", -- particle Type
			PC = 0, -- particle collide
			DG = -1, -- debri gravity
			PLife = 7, -- particle lifetime
			BDebri = true, -- Debri bool, determines if debri is expelled by explosion
			ShockParticleSize = 0.01, -- Shockwave particle size
			ParticleSize = {1, 3},-- Explosion particle size
			PR = 0.2,
			PG = 0.2,
			PB = 0.2,
			PA = 1,
			PD = 0.5,
			Flash = 50,
			Glare = 0.3,
			DynamicRange = 5,
			PGr = 2,
			Edmg = 1,
			MaxShrapSize = 2,
			ShrapVel = 80,
			ShrapCollide = 0,
			ShrapMaxDist = 70,
			ShrapDamageMax = 0.3,
			ExtraUpVel = 3,
			ShrapnelType = "realistic",
			RShrapnel = 30,
			RShrapnelPen = 4,
			RShrapVelocity = 90,
			Shaped = true;
		},
		Claymore = {
			Type = "Mine",
			Name = "Claymore",
			Fuse = 2.5,
			Violence = 17,
			ParticleAmount = 30,
			ExplosionDamage = 1,
			Shrapnel = 25,
			Force = 2,
			ForceRange = 3,
			Shockwave = 1, 
			ShockParticleSize = 0.1, 
			RequireArm = true,
			PType = "plain", -- particle Type
			PC = 0, -- particle collide
			DG = -1, -- debri gravity
			PLife = 7, -- particle lifetime
			BDebri = true, -- Debri bool, determines if debri is expelled by explosion
			ShockParticleSize = 0.01, -- Shockwave particle size
			ParticleSize = {1, 3},-- Explosion particle size
			PR = 0.3,
			PG = 0.3,
			PB = 0.3,
			PA = 1,
			PD = 0.5,
			Flash = 150,
			Glare = 0.3,
			DynamicRange = 5,
			PGr = 2,
			Edmg = 1,
			MaxShrapSize = 2,
			ShrapVel = 80,
			ShrapCollide = 0,
			ShrapMaxDist = 70,
			ShrapDamageMax = 0.3,
			ExtraUpVel = 3,
			ShrapnelType = "realistic",
			RShrapnel = 500,
			RShrapnelPen = 8,
			RShrapVelocity = 250,
			Shaped = true;
		},

		NailBomb = {
			Type = "IED",
			Name = "NailBomb",
			Fuse = 3.5,
			Violence = 17,
			ParticleAmount = 70,
			ExplosionDamage = 1,
			Shrapnel = 50,
			Force = 2,
			ForceRange = 3,
			Shockwave = 1, 
			ShockParticleSize = 0.1, 
			RequireArm = true,
			PType = "plain", -- particle Type
			PC = 0, -- particle collide
			DG = -1, -- debri gravity
			PLife = 7, -- particle lifetime
			BDebri = true, -- Debri bool, determines if debri is expelled by explosion
			ShockParticleSize = 0.01, -- Shockwave particle size
			ParticleSize = {1, 3},-- Explosion particle size
			PR = 0.2,
			PG = 0.2,
			PB = 0.2,
			PA = 1,
			PD = 0.5,
			Flash = 50,
			Glare = 0.3,
			DynamicRange = 5,
			PGr = 2,
			Edmg = 1,
			MaxShrapSize = 5,
			ShrapVel = 80,
			ShrapCollide = 0,
			ShrapMaxDist = 270,
			ShrapDamageMax = 0.1,
			ExtraUpVel = 3,
			ShrapnelType = "realistic",
			RShrapnel = 120,
			RShrapnelPen = 7,
			RShrapVelocity = 50,
			Shaped = false;
		},
		IEDa = {
			Type = "IED",
			Name = "IEDa",
			Fuse = 5.5,
			Violence = 60,
			ParticleAmount = 120,
			ExplosionDamage = 2,
			Shrapnel = 420,
			Force = 1,
			ForceRange = 5,
			Shockwave = 12, 
			ShockParticleSize = 0.3, 
			RequireArm = true,
			PType = "plain", -- particle Type
			PC = 0, -- particle collide
			DG = -1, -- debri gravity
			PLife = 7, -- particle lifetime
			BDebri = true, -- Debri bool, determines if debri is expelled by explosion
			ShockParticleSize = 0.01, -- Shockwave particle size
			ParticleSize = {3, 6},-- Explosion particle size
			PR = 0.3,
			PG = 0.3,
			PB = 0.3,
			PA = 1,
			PD = 0.5,
			Flash = 150,
			Glare = 0.6,
			DynamicRange = 14,
			PGr = 2,
			Edmg = 6,
			MaxShrapSize = 7,
			ShrapVel = 120,
			ShrapCollide = 0,
			ShrapMaxDist = 120,
			ShrapDamageMax = 0.9,
			ExtraUpVel = 5,
			ShrapnelType = "realistic",
			RShrapnel = 590,
			RShrapnelPen = 70,
			RShrapVelocity = 250,
			Shaped = false;
		},
		FuelBomb = {
			Type = "IED",
			Name = "Fuel bomb",
			Fuse = 7.5,
			Violence = 150,
			ParticleAmount = 120,
			ExplosionDamage = 5,
			Shrapnel = 100,
			Force = 30,
			ForceRange = 35,
			Shockwave = 18,
			ShockParticleSize = 2, 
			RequireArm = true,
			PType = "plain", -- particle Type
			PC = 0, -- particle collide
			DG = -1, -- debri gravity
			PLife = 7, -- particle lifetime
			BDebri = true, -- Debri bool, determines if debri is expelled by explosion
			ShockParticleSize = 0.01, -- Shockwave particle size
			ParticleSize = {9, 15},-- Explosion particle size
			PR = 0.9,
			PG = 0.9,
			PB = 0.9,
			PA = 0.2,
			PD = 0.7,
			Flash = 350,
			Glare = 0.8,
			DynamicRange = 25,
			PGr = 2,
			Edmg = 7,
			MaxShrapSize = 14,
			ShrapVel = 160,
			ShrapCollide = 0,
			ShrapMaxDist = 70,
			ShrapDamageMax = 3.5,
			ExtraUpVel = 4,
			ShrapnelType = "fast",
			Shaped = false;
		},
		GBU12 = {
			Type = "Bomb",
			Name = "Laser guided bomb",
			Fuse = 5.5,
			Violence = 170,
			ParticleAmount = 220,
			ExplosionDamage = 5,
			Shrapnel = 150,
			Force = 10,
			ForceRange = 35,
			Shockwave = 28,
			ShockParticleSize = 2.5, 
			RequireArm = true,
			PType = "plain", -- particle Type
			PC = 0, -- particle collide
			DG = -1, -- debri gravity
			PLife = 7, -- particle lifetime
			BDebri = true, -- Debri bool, determines if debri is expelled by explosion
			ShockParticleSize = 0.01, -- Shockwave particle size
			ParticleSize = {9, 15},-- Explosion particle size
			PR = 0.2,
			PG = 0.2,
			PB = 0.2,
			PA = 1,
			PD = 0.7,
			Flash = 450,
			Glare = 0.8,
			DynamicRange = 45,
			PGr = 2,
			Edmg = 9,
			MaxShrapSize = 20,
			ShrapVel = 300,
			ShrapCollide = 0,
			ShrapMaxDist = 120,
			ShrapDamageMax = 3.5,
			ExtraUpVel = 6,
			ShrapnelType = "fast",
			Shaped = false;
		},
		JDAM = {
			Type = "Bomb",
			Name = "Laser guided bomb",
			Fuse = 5.5,
			Violence = 180,
			ParticleAmount = 320,
			ExplosionDamage = 5,
			Shrapnel = 220,
			Force = 20,
			ForceRange = 45,
			Shockwave = 38,
			ShockParticleSize = 2.5, 
			RequireArm = true,
			PType = "plain", -- particle Type
			PC = 0, -- particle collide
			DG = -1, -- debri gravity
			PLife = 7, -- particle lifetime
			BDebri = true, -- Debri bool, determines if debri is expelled by explosion
			ShockParticleSize = 0.01, -- Shockwave particle size
			ParticleSize = {9, 15},-- Explosion particle size
			PR = 0.6,
			PG = 0.5,
			PB = 0.4,
			PA = 1,
			PD = 0.7,
			Flash = 450,
			Glare = 0.8,
			DynamicRange = 45,
			PGr = 2,
			Edmg = 9,
			MaxShrapSize = 25,
			ShrapVel = 430,
			ShrapCollide = 0,
			ShrapMaxDist = 120,
			ShrapDamageMax = 4.5,
			ExtraUpVel = 6,
			ShrapnelType = "fast",
			Shaped = false;
		},
		crockett = {
			Type = "nuclear device",
			Name = "crockett",
			Fuse = 12.5,
			Violence = 180,
			ParticleAmount = 320,
			ExplosionDamage = 5,
			Shrapnel = 300,
			Force = 20,
			ForceRange = 75,
			Shockwave = 80,
			ShockParticleSize = 3, 
			RequireArm = true,
			PType = "plain", -- particle Type
			PC = 0, -- particle collide
			DG = -1, -- debri gravity
			PLife = 7, -- particle lifetime
			BDebri = true, -- Debri bool, determines if debri is expelled by explosion
			ShockParticleSize = 0.01, -- Shockwave particle size
			ParticleSize = {10, 45},-- Explosion particle size
			PR = 0.5,
			PG = 0.5,
			PB = 0.5,
			PA = 1,
			PD = 0.3,
			Flash = 2350,
			Glare = 3,
			DynamicRange = 141,
			PGr = 7,
			Edmg = 3,
			MaxShrapSize = 40,
			ShrapVel = 500,
			ShrapCollide = 0,
			ShrapMaxDist = 700,
			ShrapDamageMax = 2,
			ExtraUpVel = 8,
			ShrapnelType = "fast",
			Shaped = false;
		},
		Cooker = {
			--BASIC INFO
			Type = "IED", -- Type of the explosive device
			Name = "Pressure Cooker", -- Name of the explosive device
			RequireArm = true, -- Require arm adds a difference between explosive devices that can be armed (for example grenades) and explosives that cant be armed (barrel of gunpowder)
			Fuse = 3.2, -- How much time it takes for the explosive to detonate, only works if requirearm is true
			--DAMAGE
			ExplosionDamage = 1, -- Amount of damage directly done to the environment by the explosive
			Edmg = 5, -- Pressure damage done by explosive
			--SHOCKWAVE
			Force = 5, -- Maximum force applied to objects
			ForceRange = 2, -- does nothing atm
			Shockwave = 1, -- Amount of shockwave particles
			--PARTICLES
			ParticleAmount = 90, -- How dense the particles for the explosion are going to be
			ShockParticleSize = 0.1, -- Shockwave particle size
			PType = "plain", -- particle Type
			PC = 0, -- particle collide
			DG = -1, -- debri gravity
			PLife = 7, -- particle lifetime
			BDebri = true, -- Debri bool, determines if debri is expelled by explosion
			ShockParticleSize = 0.01, -- Shockwave particle size
			ParticleSize = {0.8, 15},-- Explosion particle size
			PR = 0.9, -- Particle red
			PG = 0.9, -- Particle green
			PB = 0.9, -- particle blue
			PA = 1, -- particle alpha
			PD = 0.5, -- particle drag
			PGr = 1, -- particle gravity
			ExtraUpVel = 10, -- How much the smoke will move upwards
			Violence = 23, -- How fast the particles from the explosion will travel
			--LIGHTS
			Flash = 30, -- strength of explosion flash 
			Glare = 0.3, -- how long the explosion flash will stay
			DynamicRange = 3, -- maximum distance the explosion can affect objects at
			--FAST SHRAPNEL
			Shrapnel = 10,  -- Amount of shrapnel ejected by the explosive over time
			MaxShrapSize = 2, -- maximum size of shrapnel (VISUAL ONLY)
			ShrapVel = 80, -- maximum shrapnel velocity (VISUAL ONLY)
			ShrapCollide = 0, -- Will shrapnel collide
			ShrapMaxDist = 70, -- Maximum distance the shrapnel can travel
			ShrapDamageMax = 0.5, -- Maximum amount of damage done by shrapnel depending on distance
			ShrapnelType = "realistic", -- Type of shrapnel, can be either fast or realistic
			--REALISTIC SHRAPNEL
			RShrapnel = 70, -- Amount of realistic shrapnel, only spawned at explosion so it has to be higher than fast shrapnel
			RShrapnelPen = 6, -- Amount of realistic shrapnel penetration
			RShrapVelocity = 7, -- The speed of the realistic shrapnel
			Shaped = false;
		},
		Smoke_1 = {
			--BASIC INFO
			Type = "plain", -- Type of the explosive device
			Name = "Smoke_1", -- Name of the explosive device
			RequireArm = true, -- Require arm adds a difference between explosive devices that can be armed (for example grenades) and explosives that cant be armed (barrel of gunpowder)
			Fuse = 1.2, -- How much time it takes for the explosive to detonate, only works if requirearm is true
			--DAMAGE
			ExplosionDamage = 0.2, -- Amount of damage directly done to the environment by the explosive
			Edmg = 0.1, -- Pressure damage done by explosive
			--SHOCKWAVE
			Force = 0.1, -- Maximum force applied to objects
			ForceRange = 0.1, -- does nothing atm
			Shockwave = 0.1, -- Amount of shockwave particles
			--PARTICLES
			PType = "smoke", -- particle Type
			PC = 1, -- particle collide
			DG = -1, -- debri gravity
			PLife = 32, -- particle lifetime
			BDebri = false, -- Debri bool, determines if debri is expelled by explosion
			ParticleAmount = 220, -- How dense the particles for the explosion are going to be
			ShockParticleSize = 0.01, -- Shockwave particle size
			ParticleSize = {0.8, 15},-- Explosion particle size
			PR = 0.8, -- Particle red
			PG = 0.8, -- Particle green
			PB = 0.8, -- particle blue
			PA = 1, -- particle alpha
			PD = 0.6, -- particle drag
			PGr = -0.2, -- particle gravity
			ExtraUpVel = 1, -- How much the smoke will move upwards
			Violence = 43, -- How fast the particles from the explosion will travel
			--LIGHTS
			Flash = 10, -- strength of explosion flash 
			Glare = 0.1, -- how long the explosion flash will stay
			DynamicRange = 0.01, -- maximum distance the explosion can affect objects at
			--FAST SHRAPNEL
			Shrapnel = 10,  -- Amount of shrapnel ejected by the explosive over time
			MaxShrapSize = 2, -- maximum size of shrapnel (VISUAL ONLY)
			ShrapVel = 80, -- maximum shrapnel velocity (VISUAL ONLY)
			ShrapCollide = 0, -- Will shrapnel collide
			ShrapMaxDist = 70, -- Maximum distance the shrapnel can travel
			ShrapDamageMax = 0.5, -- Maximum amount of damage done by shrapnel depending on distance
			ShrapnelType = "none", -- Type of shrapnel, can be either fast or realistic
			--REALISTIC SHRAPNEL
			RShrapnel = 70, -- Amount of realistic shrapnel, only spawned at explosion so it has to be higher than fast shrapnel
			RShrapnelPen = 6, -- Amount of realistic shrapnel penetration
			RShrapVelocity = 7, -- The speed of the realistic shrapnel
			Shaped = false;
		},
	}
	Stim = 0
	armvel = 0
  MaxDist = 17

	InitTesting()
	InitBallistics()
end

function CheckArming(Splosive,Species)
	local IsArmed = false
	if Devices[Species]["RequireArm"] then
		if GetPlayerInteractBody() == Splosive and InputPressed("interact") then IsArmed = true end
	end
	
	if IsArmed then
		SetTag(Splosive, "interact", "!!!ARMED!!!")
		SetTag(Splosive, "Fuse", Devices[Species]["Fuse"])
	end

	if IsBodyBroken(Splosive) then 
		SetTag(Splosive, "Fuse", -1)
	end
end

function SplosionTick(dt)
	-- DebugWatch('Splosion.lua #spallHandler.shells',#spallHandler.shells)
	local spallToRemove={}
	local i = 1
	local removeStart
	while i < spallHandler.shellNum do
		local shell=spallHandler.shells[i]
		if shell.active then
			SpallOperations(shell)
		else
			if not removeStart then removeStart = i end
			spallToRemove[i]=true
		end
		i=i+1
	end

	local spallRemoved=0
	for i = removeStart or spallHandler.shellNum, spallHandler.shellNum-1 do
		if spallToRemove[i] then
			spallHandler.shells[i-spallRemoved]=nil
			spallRemoved=spallRemoved+1
		end
		spallHandler.shells[i-spallRemoved+1],spallHandler.shells[i+1] = spallHandler.shells[i+1],spallHandler.shells[i-spallRemoved+1]
	end
	spallHandler.shellNum=spallHandler.shellNum-spallRemoved

	if drawdebug then
		DebugShooting()
	end
end


function SplosionUpdate(dt)
	Splosives = FindBodies("Splosion",true)
	for i=1,#Splosives do
		Splosive = Splosives[i]
		Species = GetTagValue(Splosive, "Splosion")
		local ValidExplosive = Species ~= nil and Devices[Species] ~= nil and Devices[Species]["Name"] ~= nil

		if ValidExplosive then --Checks if explosive device is registered
			--DebugPrint("SPECIES: "..Devices[Species]["Name"])
			CheckArming(Splosive,Species)

			if HasTag(Splosive, "Fuse") then
				FuseTime = tonumber(GetTagValue(Splosive, "Fuse"))
				FuseTime = FuseTime - dt
				SetTag(Splosive, "Fuse", tostring(FuseTime))
				if FuseTime < 0 then
					
					local Initialised = HasTag(Splosive, "Glare")
					if not Initialised then
						SetBodyDynamic(Splosive, false)
						local tr = GetBodyTransform(Splosive)
						tr.pos[2] = tr.pos[2]-30
						SetBodyTransform(Splosive,tr)
						Position = tr.pos
						Position[2] = Position[2] + 30

						Splosion(Position, Devices[Species]["Violence"], Devices[Species]["ParticleAmount"], Devices[Species]["ExplosionDamage"], Devices[Species]["ParticleSize"])

						SetTag(Splosive, "Glare", Devices[Species]["Glare"]*10^Val[Glare])
						SetTag(Splosive, "Shockwave", Devices[Species]["Shockwave"])
						SetTag(Splosive, "ShrpT", 0)
						SetTag(Splosive, "SndT", 0)
						if Devices[Species]["ShrapnelType"] == "realistic" and Devices[Species]["ShrapnelType"] ~= "none" then
							debuglines = {}
							debugholes = {}
							if Devices[Species]["Shaped"] then
								ShapedTrans = GetBodyTransform(Splosive)
								Dir = TransformToParentVec(ShapedTrans,Vec(0,0,1))
								Spall(Position, VecScale(Dir,Devices[Species]["RShrapVelocity"]), Devices[Species]["RShrapnel"]*(10^Val[Shrapnel]), 0.3, Devices[Species]["RShrapnelPen"], 1)
							else
								if Devices[Species]["ShrapnelType"] ~= "none" then
									Spall(Position, Vec(0,Devices[Species]["RShrapVelocity"],0), Devices[Species]["RShrapnel"]*(10^Val[Shrapnel]), 1, Devices[Species]["RShrapnelPen"], 1)
								end
							end
						end
						if Devices[Species]["Shrapnel"]*10^Val[Shrapnel] > 0 then
							maxdist = 1
							damagemax = 100
							--for z=1,Devices[Species]["Shrapnel"]*10^Val[Shrapnel] do
								--damagemax = damagemax - 100/Devices[Species]["Shrapnel"]*10^Val[Shrapnel]
								--maxdist = maxdist + 50/Devices[Species]["Shrapnel"]*10^Val[Shrapnel]
								--if damagemax <= 1 then
								--	damagemax = 1
								--end
								--Shoot(Position, RSV(0.01), "gun", math.random(1,damagemax)/200, maxdist)
								--local hit, dist, normal, shape = QueryRaycast(Vec(math.random(1,10),math.random(1,10),math.random(1,10)), Vec(math.random(1,10),math.random(1,10),math.random(1,10)), 70)
								--DebugPrint(dist)
							--end
						end
					else
						Position = GetBodyTransform(Splosive).pos
						Position[2] = Position[2] + 30

					
						GlareT = GetTagValue(Splosive, "Glare")
						GlareT = GlareT - dt
						SetTag(Splosive, "Glare", GlareT)
						if GlareT > 0 then 
							PointLight(Position, 1, 0.7, 0.3, Devices[Species]["Flash"]*10^Val[Flash]*GlareT)
						else
							SetTag(Splosive, "NoL")
						end

						if not HasTag(Splosive, "NoShrp") and Devices[Species]["ShrapnelType"] ~= "realistic" and Devices[Species]["ShrapnelType"] ~= "none" then
							ShrpT = GetTagValue(Splosive, "ShrpT")
							ShrpT = ShrpT + dt*(Devices[Species]["ShrapVel"]*8.2)
							SetTag(Splosive, "ShrpT", ShrpT)
							CreateShrapnel(Devices[Species]["Shrapnel"]*ShrpT/30*(10^Val[Shrapnel]),Position)
							--DebugPrint(ShrpT)
							if not(ShrpT < Devices[Species]["ShrapMaxDist"]) then 
								SetTag(Splosive, "NoShrp")
							end
						end

						if not HasTag(Splosive, "NoSnd") then

						SndT = tonumber(GetTagValue(Splosive, "SndT"))
						SndT = SndT + dt*250
						--DebugPrint(SndT)
						SetTag(Splosive, "SndT", tostring(SndT))
						playerpos = GetPlayerCameraTransform().pos
						DistToPlayer = VecLength(VecSub(Position, playerpos))
						if SndT > DistToPlayer then
						SetTag(Splosive, "NoSnd")
						local smallRange = 25
						local mediumRange = 45
						local largeRange = 100

						local largeVolume = math.max(0, math.min(1, (DistToPlayer - mediumRange) / (largeRange - mediumRange)))
						local mediumVolume = math.max(0, math.min(1, (DistToPlayer - smallRange) / (mediumRange - smallRange))) - largeVolume
						local smallVolume = math.max(0, (smallRange - DistToPlayer) / smallRange)
						if mediumVolume == 0 and largeVolume == 0 then
							mediumVolume = 1 - smallVolume
						end
						if mediumVolume < 1 and largeVolume == 0 then
							mediumVolume = 1 - smallVolume
						end

						PlaySound(LoadSound("../Sounds/"..Devices[Species]["Name"].."SDist"),Position,smallVolume*smallRange)
						PlaySound(LoadSound("../Sounds/"..Devices[Species]["Name"].."MDist"),playerpos,mediumVolume)
						PlaySound(LoadSound("../Sounds/"..Devices[Species]["Name"].."LDist"),playerpos,largeVolume)

						--DebugPrint("Small range volume: "..smallVolume)
						--DebugPrint("Medium range volume: "..mediumVolume)
						--DebugPrint("Large range volume: "..largeVolume)

						end

						end

						if Devices[Species]["Shockwave"] > 0 and not HasTag(Splosive, "NoS") then
							Stim = tonumber(GetTagValue(Splosive, "Shockwave"))
							Stim = Stim - dt*65
							SetTag(Splosive, "Shockwave", tostring(Stim))
							Shockwave(Position, Devices[Species]["Violence"], Devices[Species]["ParticleAmount"], Devices[Species]["ExplosionDamage"], Devices[Species]["ParticleSize"],Stim*2)
							if Stim < 0 then
								SetTag(Splosive, "NoS")
							end
						end
						if Devices[Species]["Shockwave"] == 0 then
							SetTag(Splosive, "NoS")
						end

						if HasTag(Splosive, "NoS") and HasTag(Splosive, "NoL") and HasTag(Splosive, "NoShrp") then
							Delete(Splosive)
						end

					end
				end
			end

		else
			-- DebugPrint("Unknown explosive device detected, this explosive device will not work, make sure the table name of the device matches the splosion tag")

			if HasTag(Splosive, "Fuse") then

				if GetPlayerInteractBody() == Splosive and InputPressed("interact") then
					SetTag(Splosive, "interact", "!!!ARMED!!!")
					SetTag(Splosive, "Armed")
					local shapes = GetBodyShapes(Splosive)
					for i = 1, #shapes do
						local Stickies = GetShapeLights(shapes[i])
						for j = 1, #Stickies do
							if HasTag(Stickies[j],"Sticky") then
								Spawn('<joint size="0.25" rotstrength="999" rotspring="0.8" collide="true"/>',GetLightTransform(Stickies[j]),false,true)
								Delete(Stickies[j])
							end
						end
					end
				end

				local FuseTime = tonumber(GetTagValue(Splosive, "Fuse"))
				if HasTag(Splosive, "Armed") then
					FuseTime = FuseTime - dt
					SetTag(Splosive, "Fuse", tostring(FuseTime))
				end

				if FuseTime < 0 or IsBodyBroken(Splosive) then
					local expMass = tonumber(GetTagValue(Splosive, "Mass")) or 0.2
					local shrapAmt = tonumber(GetTagValue(Splosive, "Shrap")) or 40
					local angle = tonumber(GetTagValue(Splosive, "Angle")) or 1
					local momentum = tonumber(GetTagValue(Splosive, "Momentum")) or 15
					local type = GetTagValue(Splosive, "Type")
					local spall = tonumber(GetTagValue(Splosive, "Spall")) or 20
					local tr = GetBodyTransform(Splosive)
					local dir = TransformToParentVec(tr,Vec(0,1,0))
					Delete(Splosive)

					if type == "shaped" then
						local shellInfo = {
							type = "heat",
							name = "Shaped Charge",
							velocity = 50,--m/s
							propulsion = "ballistic", -- propulsion type	
							mass = 1, -- mass of projectile in kg
							maxrange = .2, -- max range in m
							momentum = momentum, --mm of RHA (rolled homogeneous armor)
							projectilecaliber = 50, --projectile caliber in mm
							shellcaliber = 50, --shell caliber in mm
							
							tracer = false,
							recoil = 0,
							
							spallamount = spall,
							spallangle = angle, --cone area of spall from 0 to 1 (0 being no deviation from projectile direction, 1 being sphere)
							shrapnelamount = shrapAmt, --number of shrapnel pieces (used for HE shells)
							explosionpayload = mass, --(kg) used for HE shells
						}
						Shoot(tr.pos, dir, shellInfo, {Splosive}, false, 0, 0, "mg")
					else
						RealisticExplosion(tr.pos, dir, expMass*1.5, expMass, shrapAmt, angle, momentum, 1, 0, 1)
					end

				end
			end

		end

	end
end

function Impact(pos)
	--FIRE
	ParticleReset() -- SMOKE
	ParticleType("plain")
	m = math.random(5,10)/10
	ParticleColor(m,m,m)
	ParticleEmissive(0)
	ParticleRadius(math.random(1,40)/100, math.random(40,60)/100)
	ParticleAlpha(1,0)
	ParticleCollide(0)
	ParticleGravity(0)
	ParticleSticky(0.5)
	ParticleDrag(0)
	ParticleStretch(1)
	SpawnParticle(pos, Vec(0,0,0) ,3)
	ParticleReset()
end

function Splosion(pos, violence, amount, size, psize)
	--FIRE
	ParticleReset() -- SMOKE
	ParticleType(Devices[Species]["PType"])
	ParticleEmissive(0)
	ParticleRadius(psize[1], psize[2])
	ParticleAlpha(Devices[Species]["PA"],0)
	ParticleCollide(Devices[Species]["PC"])
	ParticleGravity(Devices[Species]["PGr"],Devices[Species]["PGr"]*2)
	ParticleSticky(0.5)
	ParticleDrag(Devices[Species]["PD"],0)
	ParticleStretch(1)
	MakeHole(pos, size*3, 0, 0, true)
	for i=1,amount do
		rndSC = math.random(-10,10)/100
		ParticleColor(Devices[Species]["PR"] + rndSC, Devices[Species]["PG"] + rndSC, Devices[Species]["PB"] + rndSC)
	SpawnParticle(VecAdd(pos,RSV(violence/20)), VecAdd(RSV(violence), Vec(0,math.random(violence,violence*Devices[Species]["ExtraUpVel"])-violence,0)) ,Devices[Species]["PLife"])
	end
	ParticleReset()

	ParticleType(Devices[Species]["PType"]) -- SPIKEY THINGIES
	ParticleColor(Devices[Species]["PR"]/2, Devices[Species]["PG"]/2, Devices[Species]["PB"]/2)
	ParticleEmissive(0)
	ParticleRadius(psize[1]/3, psize[2]/3)
	ParticleAlpha(1,0)
	ParticleCollide(Devices[Species]["PC"])
	ParticleGravity(Devices[Species]["PGr"])
	ParticleSticky(0.5)
	ParticleDrag(Devices[Species]["PD"]/8)
	ParticleStretch(1000000)
	MakeHole(pos, size*3, 0, 0, true)
	for i=1,amount do
	SpawnParticle(pos, RSV(violence*1.5) ,0.5)
	end
	ParticleReset()

	ParticleReset()

	ParticleType("plain") -- DEBRI
	ParticleEmissive(0)
	ParticleRadius(0.07, 0)
	ParticleAlpha(1)
	ParticleCollide(Devices[Species]["PC"])
	ParticleGravity(Devices[Species]["DG"]*9)
	ParticleSticky(0)
	ParticleDrag(0)
	ParticleStretch(3)
	MakeHole(pos, size*3, 0, 0, true)
	if Devices[Species]["BDebri"] then
	for i=1,amount*3 do
		roingi = math.random(1,90)/100
		ParticleTile(math.random(1,11))
		ParticleColor(roingi, roingi, roingi)
	SpawnParticle(VecAdd(pos,Vec(0,1,0)), VecAdd(RSV(violence), Vec(0,violence/4,0)) ,6)
	end
	end
	ParticleReset()
end

function Shockwave(pos,violence,amount,size,psize,Stim)
	ParticleReset()

	if Devices[Species]["Shockwave"] > 0 then
	ParticleType("smoke")
	--ParticleColor(Devices[Species]["PR"], Devices[Species]["PG"], Devices[Species]["PB"])
	ParticleColor(0.7, 0.7, 0.7)
	ParticleEmissive(0)
	ParticleRadius(Devices[Species]["ShockParticleSize"],0)
	ParticleAlpha(Devices[Species]["PA"],0)
	ParticleCollide(1)
	ParticleGravity(-0.5)
	ParticleSticky(0.5)
	ParticleDrag(0)
	ParticleStretch(1)
	--MakeHole(pos, size, size/2, size/3, true)
	for i=1,amount/2 do
		bb = math.abs(Devices[Species]["Shockwave"]*2 - Stim)

		DynamicDamage = math.max(Devices[Species]["Shockwave"]*2 - bb,1)
		SpawnParticle(VecAdd(pos, RRV(math.random(bb/1.1,bb))), Vec(0,0,0) ,17)
		--for z=1,Devices[Species]["Edmg"] do
		--MakeHole(VecAdd(pos, RSV(math.random(bb/1.1,bb))), math.random(1,DynamicDamage*Devices[Species]["Edmg"])/100, math.random(1,DynamicDamage*Devices[Species]["Edmg"])/120, math.random(1,DynamicDamage*Devices[Species]["Edmg"])/170)
		--end
end
	ParticleReset()

					local list = QueryAabbBodies(Vec(Position[1] - Devices[Species]["DynamicRange"]*10^Val[DynamicRange], Position[2] - Devices[Species]["DynamicRange"]*10^Val[DynamicRange], Position[3] - Devices[Species]["DynamicRange"]*10^Val[DynamicRange]), Vec(Position[1] + Devices[Species]["DynamicRange"]*10^Val[DynamicRange], Position[2] + Devices[Species]["DynamicRange"]*10^Val[DynamicRange], Position[3] + Devices[Species]["DynamicRange"]*10^Val[DynamicRange]))
					--DebugPrint(bb)
					for x=1, #list do
						bodie = list[x]
						bodiepos = GetBodyTransform(bodie).pos
						Distobodie = VecLength(VecSub(pos, bodiepos))
						if Distobodie < bb then
						Repel(bodie, math.min(Devices[Species]["Force"]/(Distobodie/60)^2,Devices[Species]["Force"]/2), Position)
						end
					--DebugPrint(math.min(Devices[Species]["Force"]/(Distobodie/60)^2,Devices[Species]["Force"]))
				end
		end
end

function RSV(r)
  	local d = math.random() * r
  	local a = math.random() * 2 * math.pi
  	local b = math.acos(2 * math.random() - 1)
	
  	local x = d * math.sin(b) * math.cos(a)
  	local y = d * math.sin(b) * math.sin(a)
  	local z = d * math.cos(b)
  
  	return Vec(x, y, z)
end

function RCV(r)
  	local angle = math.random() * 2 * math.pi
  	local radius = math.sqrt(math.random()) * r
  	local x = radius * math.cos(angle)
  	local y = radius * math.sin(angle)
  	return Vec(x + math.random(-10,10)/10, 0, y + math.random(-10,10)/10)
end

function RRV(radius)
  local angle = math.random() * 2 * math.pi
  return Vec(radius * math.cos(angle), 0, radius * math.sin(angle))
end

function Split(s, delimiter)
	result = {}
	for match in (s .. delimiter):gmatch("(.-)" .. delimiter) do
		table.insert(result, match)
	end
	return result
end

function Repel(Body, Amount, Point)
	armvel = Amount
	if armvel ~= nil and IsBodyDynamic(Body) then
		local bmi, bma = GetBodyBounds(Body)
      	local bc = VecLerp(bmi, bma, 0.5)
      	local ppos = VecSub(Point, Vec(0,1,0))
      	local dir = VecSub(bc, ppos)
      	local dist = VecLength(dir)
      	dir = VecScale(dir, 1.0 / dist)
     	local add = VecScale(dir, armvel*8)
      	local vel = GetBodyVelocity(Body)
      	Vel = VecAdd(vel, add)
      	--Vel = VecAdd(Vel, Vec(0,armvel,0))
      	ApplyBodyImpulse(Body, GetBodyTransform(Body).pos ,Vel)
      	--DebugPrint("APPLIED VELOCITY TO BODY: "..Body.." WITH FORCE OF: "..Amount.." AT POINT: "..Point[1]..", "..Point[2]..", "..Point[3])
      end
end

function random_direction()
    local theta = math.random() * 2 * math.pi -- random angle around the z-axis
    local z = math.random() * 2 - 1 -- random z-coordinate between -1 and 1
    local r = math.sqrt(1 - z*z) -- radius of the circle at this z-coordinate
    local x = r * math.cos(theta) -- x-coordinate on the circle
    local y = r * math.sin(theta) -- y-coordinate on the circle
    return Vec(x, y, z)
end

function CreateShrapnel(RayCount,center)
    for i = 1, RayCount,1 do
        local md = MaxDist * math.random(1,math.max(ShrpT,2))/500
        local d = random_direction()
        local hit, dist, normal, shape = QueryRaycast(center, d, md)
        if hit == false then dist = md end


        local p = VecAdd(center,VecScale(d,dist))
        local holesize = dist / md *Devices[Species]["ShrapDamageMax"]
        if not HasTag(Splosive, "Roinged") then
        	for z=1,Devices[Species]["Shrapnel"] * Devices[Species]["ShrapMaxDist"]/10 do
        		local d = random_direction()
        	VisualizeShrap(center,d,hit, dist)
        	SetTag(Splosive, "Roinged")
      		end
      	end
        MakeHole(p, math.random(1,math.max(holesize*100,2))/100, math.random(1,math.max(holesize*100,2))/150, math.random(1,math.max(holesize*100,2))/180, true)
        Paint(p, math.random(1,Devices[Species]["ShrapDamageMax"]*100)/200, "explosion")
        if hit then
        Impact(p)
      end
    end
end

function VisualizeShrap(pos,Direction,hit, dist)
	local speed = math.random(5,Devices[Species]["ShrapVel"]*10^Val[ShrapVel])

	local time = math.random(100,500)/100
	local mt = 0
	if hit then
		mt = dist/speed*1.05
		if mt>time then
			time = mt
		end
	end

	ParticleReset() -- SMOKE
	ParticleType("plain")
	m = math.random(5,10)/10
	ParticleColor(1,0.5,0.4)
	ParticleEmissive(1,0)
	ParticleRadius(math.random(1,Devices[Species]["MaxShrapSize"]*10^Val[MaxShrapSize])/100)
	ParticleAlpha(1,0)
	ParticleCollide(Devices[Species]["ShrapCollide"])
	ParticleGravity(-5)
	ParticleSticky(0.5)
	ParticleDrag(math.random(5,60)/100)
	ParticleStretch(1)
	SpawnParticle(VecAdd(pos,Vec(0,0.1,0)), VecScale(Direction,speed) ,time)
	ParticleReset()
end


function draw(dt)
    --TestingUi(dt)
end
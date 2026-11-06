#version 2
#include "script/include/player.lua"
--[[
(v2) removed the include of GoreNPCs/scripts/systems/goreai_grenades.lua: nothing in it is used here and its
top-level do-block calls LoadSprite while loading, which v2 forbids.
#include "../scripts/TDSU/tdsu.lua"
#include "../Automatic.lua"
#include "../Settings.lua"
]]

-- (v2) Split: the client reads input + inventory (v1 registry) and asks the server to spawn the grenade.
-- The server owns the grenades: timers, holes, shrapnel (Shoot), knock-back, throw-back by any player.
-- Explosion particles and sounds run on every client (client.grenadeExplode).
-- Note: an exploded grenade is removed from Splosives in the same frame, so the original "Glare" /
-- "Shockwave" branch below never runs (kept as in the original).

Devices = {
	["RGD-5"] = {
		Type = "Grenade", -- Type of the explosive device
		Name = "RG-42", -- Name of the explosive device
		Fuse = 3.2, -- How much time it takes for the explosive to detonate, only works if requirearm is true
		Violence = 27, -- How fast the particles from the explosion will travel
		ParticleAmount = 30, -- How dense the particles for the explosion are going to be
		ExplosionDamage = 1, -- Amount of damage directly done to the environment by the explosive
		Shrapnel = 100,  -- Amount of shrapnel ejected by the explosive
		ShrapnelDist = 10,
		Force = 0, -- Maximum force applied to objects
		ForceRange = 2, -- does nothing atm
		Shockwave = 2, -- Amount of shockwave particles
		ShockParticleSize = 0.1, -- Shockwave particle size
		RequireArm = true, -- Require arm adds a difference between explosive devices that can be armed (for example grenades) and explosives that cant be armed (barrel of gunpowder)
		ParticleSize = 1, -- Explosion particle size
		PR = 0.7, -- Particle red
		PG = 0.7, -- Particle green
		PB = 0.7, -- particle blue
		PA = 0.7, -- particle alpha
		PD = 0.5, -- particle drag
		Flash = 30, -- strength of explosion flash 
		Glare = 0.3, -- how long the explosion flash will stay
		DynamicRange = 3, -- maximum distance the explosion can affect objects at
		PGr = 1, -- particle gravity
		Edmg = 5, -- Pressure damage done by explosive
	},
	["Type-67"] = {
		Type = "Grenade", -- Type of the explosive device
		Name = "Type-67", -- Name of the explosive device
		Fuse = 3.2, -- How much time it takes for the explosive to detonate, only works if requirearm is true
		Violence = 27, -- How fast the particles from the explosion will travel
		ParticleAmount = 30, -- How dense the particles for the explosion are going to be
		ExplosionDamage = 0.7, -- Amount of damage directly done to the environment by the explosive
		Shrapnel = 120,  -- Amount of shrapnel ejected by the explosive
		ShrapnelDist = 16,
		Force = 0, -- Maximum force applied to objects
		ForceRange = 2, -- does nothing atm
		Shockwave = 0, -- Amount of shockwave particles
		ShockParticleSize = 0.1, -- Shockwave particle size
		RequireArm = true, -- Require arm adds a difference between explosive devices that can be armed (for example grenades) and explosives that cant be armed (barrel of gunpowder)
		ParticleSize = 1, -- Explosion particle size
		PR = 0.7, -- Particle red
		PG = 0.7, -- Particle green
		PB = 0.7, -- particle blue
		PA = 0.7, -- particle alpha
		PD = 0.5, -- particle drag
		Flash = 30, -- strength of explosion flash 
		Glare = 0.3, -- how long the explosion flash will stay
		DynamicRange = 3, -- maximum distance the explosion can affect objects at
		PGr = 1, -- particle gravity
		Edmg = 5, -- Pressure damage done by explosive
	},

}

---------------------------------------------------------------- server

function server.init()
	Splosives = {}
end

function server.throwGrenade(playerId, kind, throwTr)
	local throwVel = Vec(0, 10, -15)
	if kind == "RGD-5" then
		local Spawn = Spawn("MOD/main/GoreRagdolls2/prefab/RGD5.xml", throwTr)
		SetBodyVelocity(Spawn[1], TransformToParentVec(throwTr, throwVel))
		SetBodyAngularVelocity(Spawn[1], QuatEuler(math.random()*-600,0, (math.random()-0.5)*200))
		SetTag(Spawn[1], "Splosion","RGD-5")
		SetTag(Spawn[1], "interact","Throw Back")
		SetTag(Spawn[1], "Timer", Devices[GetTagValue(Spawn[1], "Splosion")]["Fuse"])
		table.insert(Splosives, Spawn[1])
	elseif kind == "Type-67" then
		local Spawn = Spawn("MOD/main/GoreRagdolls2/prefab/Type 67.xml", throwTr)
		SetBodyVelocity(Spawn[1], TransformToParentVec(throwTr, throwVel))
		SetBodyAngularVelocity(Spawn[1], QuatEuler(math.random()*-600, math.random()*-600, (math.random()-0.5)*200))
		SetTag(Spawn[1], "Splosion","Type-67")
		SetTag(Spawn[1], "interact","Throw Back")
		SetTag(Spawn[1], "Timer", Devices[GetTagValue(Spawn[1], "Splosion")]["Fuse"])
		table.insert(Splosives, Spawn[1])
	end
end

function server.tick(dt)
    --print(active_spall)
	for i=#Splosives,1,-1 do -- (v2) backwards: entries are removed inside the loop
		Splosive = Splosives[i]
		Species = GetTagValue(Splosive, "Splosion")
		SetTag(Splosive, "unbreakable")
		for p in Players() do -- (v2) any player can throw it back
			if GetPlayerInteractBody(p) == Splosive and InputPressed("interact", p) then
				local throwVel = VecScale(VecNormalize(VecSub(GetBodyTransform(Splosive).pos,GetPlayerTransform(p).pos)), 15)
				SetBodyVelocity(Splosive, throwVel)
			end
		end
		if Species ~= nil and Devices[Species] ~= nil and Devices[Species]["Name"] ~= nil then --Checks if explosive device is registered
		--DebugPrint("SPECIES: "..Devices[Species]["Name"])
	
		if HasTag(Splosive, "Timer") then
			CurrentTim = tonumber(GetTagValue(Splosive, "Timer"))
			CurrentTim = CurrentTim - dt
			SetTag(Splosive, "Timer", tostring(CurrentTim))
			QueryRejectBody(Splosive)
			local hit, dist, normal, shape = QueryRaycast(GetBodyTransform(Splosive).pos, Vec(0, -1, 0), 0.1)
			if hit and not HasTag(Splosive, "stopped") then
				SetBodyVelocity(Splosive, Vec(GetBodyVelocity(Splosive)[1]/5,GetBodyVelocity(Splosive)[2]/5,GetBodyVelocity(Splosive)[3]/5))
				SetTag(Splosive, "stopped")	
				ClientCall(0, "client.grenadeRattle", GetBodyTransform(Splosive).pos)
			end
			if tonumber(GetTagValue(Splosive, "Timer")) < 0 or IsBodyBroken(Splosive) or (HasTag(Splosive, "Impact") and hit) then
				Position = GetBodyTransform(Splosive).pos
				if not HasTag(Splosive, "Glare") then
				SetBodyDynamic(Splosive, false)
				SplosionWorld(Position, Devices[Species]["ExplosionDamage"])
				ClientCall(0, "client.grenadeExplode", Species, Position) -- particles + sounds on every client
				SetTag(Splosive, "Glare", Devices[Species]["Glare"])
				SetTag(Splosive, "Shockwave", Devices[Species]["Shockwave"])
				table.remove(Splosives, i)
				local shapes = GetBodyShapes(Splosive)
				for i=1,#shapes do 
					Delete(shapes[i])
				end
				Delete(Splosive)
				if Devices[Species]["Shrapnel"] > 0 then
					maxdist = 1
					damagemax = 100
					for z=1,Devices[Species]["Shrapnel"] do
						damagemax = damagemax - 100/Devices[Species]["Shrapnel"]
						maxdist = Devices[Species]["ShrapnelDist"]
						if damagemax <= 1 then
							damagemax = 1
						end
						-- (v2 fix) Shoot needs a unit-length direction; RSV(0.01) is at most 0.01 long
						Shoot(Position, VecNormalize(RSV(0.01)), "shotgun", math.random(1,damagemax)/200, maxdist)
						local hit, dist, normal, shape = QueryRaycast(Vec(math.random(1,10),math.random(1,10),math.random(1,10)), Vec(math.random(1,10),math.random(1,10),math.random(1,10)), 70)
						--DebugPrint(dist)
					end
				end
			else
				GlareT = GetTagValue(Splosive, "Glare")
				GlareT = GlareT - dt
				SetTag(Splosive, "Glare", GlareT)
				if GlareT > 0 then 
					Position = GetBodyTransform(Splosive).pos
					-- (v2) PointLight is client-side; this branch is unreachable anyway (see top of file)
				else
					SetTag(Splosive, "NoL")
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
				if HasTag(Splosive, "NoS") and HasTag(Splosive, "NoL") then
				end
				end
			end
		end
		else
		end
	end
end


---------------------------------------------------------------- client

function client.init()
    Sounds = {
        GrenadeBeep       = LoadSound("MOD/snd/Weapons/Handheld/Grenade/Grenade_beep.ogg"),
    }
    Init_Settings()
	Stim = 0
	armvel = 0
	ArmTim = 0
	CurrentGrenade = 1
	CoolDownTimer = 0
	ActiveGrenades = {}
end

function client.tick(dt)
	CoolDownTimer = CoolDownTimer - dt
	ActiveGrenades = {}
	if GetInt("inventory.ammocount_grenade") ~= 0 then
		table.insert(ActiveGrenades, "RGD-5")
	end
	if GetInt("inventory.ammocount_grenade1") ~= 0 then 
		table.insert(ActiveGrenades, "Type-67")
	end
	if InputPressed("t") then 
		CurrentGrenade = CurrentGrenade + 1
	end
	if CurrentGrenade > #ActiveGrenades then CurrentGrenade = 1 end

    local throwValid =
        GetPlayerVehicle() == 0
        and (GetInt("inventory.ammocount_grenade") > 0 or GetInt("inventory.ammocount_grenade1"))
        and GetPlayerGrabShape() == 0
		and CoolDownTimer < 0 

    if KeybindReleased(Settings.keybinds.player.throw_grenade) and throwValid then
		CoolDownTimer = 0
		if next(ActiveGrenades) then
			local throwTr = GetPlayerCameraTransform()
			throwTr.pos = TransformToParentPoint(throwTr, Vec(0,0,-0.5))
			PlaySound(LoadSound("MOD/snd/Weapons/Handheld/Grenade/frag_throw.ogg"), throwTr.pos, 1)
			local kind = ActiveGrenades[CurrentGrenade]
			ServerCall("server.throwGrenade", GetLocalPlayer(), kind, throwTr)
			if kind == "RGD-5" then
				SetBool("inventory.removegrenade", true)
			elseif kind == "Type-67" then
				SetBool("inventory.removegrenade1", true)
			end
		end
    end
end

function client.grenadeRattle(pos)
	PlaySound(LoadSound("MOD/snd/Weapons/Handheld/Grenade/rattle_dirt_0.ogg"), pos, 4)
end

function client.grenadeExplode(species, pos)
	Species = species
	SplosionFx(pos, Devices[Species]["Violence"], Devices[Species]["ParticleAmount"], Devices[Species]["ExplosionDamage"], Devices[Species]["ParticleSize"])
	PlaySound(LoadSound("MOD/snd/"..Devices[Species]["Name"]))
	PlaySound(LoadSound("MOD/snd/Explosions/frag_sand_0.ogg"), pos, 8)
	PlaySound(LoadSound("MOD/snd/Explosions/Shared/Debris/expl_debris_dirt_0.ogg"), pos, 3)
	PlaySound(LoadSound("MOD/snd/Explosions/Shared/Debris/expl_debris_sand_0.ogg"), pos, 3)
	if Sounds.GrenadeExplosion then PlaySound(Sounds.GrenadeExplosion, pos, 2) end -- (never set in the original)
end

function client.draw()

-------- Thanks GS_115 :)
	if KeybindDown(Settings.keybinds.player.throw_grenade) and #ActiveGrenades ~= 0 then
		local prox_alert = "" 
		Vo = 4
		g = 0.24
		r = 0.4
		local pos = 0
		UiPush()
		UiTranslate(UiCenter(), UiMiddle()-300)
		UiAlign("center middle")
		UiColor(1, 1, 1)
		UiFont("bold.ttf", 32)
		UiTextOutline(0,0,0,1,0.1)
					
		local rx, ry, rz = GetQuatEuler(GetPlayerCameraTransform().rot)
		local h = 0
		if 0 >= 0 then
			t = 0.5/Vo
			local tr = GetPlayerTransform()
			local cam = GetPlayerCameraTransform()
			cam.pos = Vec(0, 0, 0)
			cam.rot = QuatEuler(0, 0, 0)
			local subb = TransformToLocalVec(cam, Vec(0, 1.5, 0))
			tr.pos = VecAdd(tr.pos, subb)
			if InputDown("crouch") then
				tr.pos = VecAdd(tr.pos, Vec(0, -0.75, 0))
			end
			local x, y, hit_vec
			repeat
			x = math.cos(math.rad(rx))*Vo*(t-0.01)
			y = (-0.5)*g*((t-0.01)^2)+(math.sin(math.rad(rx)))*Vo*(t-0.01)+h
			local start = TransformToParentPoint(tr, Vec(0, y, -x))
			x = math.cos(math.rad(rx))*Vo*(t+0.015)
			y = (-0.5)*g*((t+0.015)^2)+(math.sin(math.rad(rx)))*Vo*(t+0.015)+h
			local endd = TransformToParentPoint(tr, Vec(0, y, -x))
			local direction = VecSub(endd, start)
			t = t + 0.01
			QueryRejectBody(GetToolBody())
			local hit, d, normal = QueryRaycast(start, direction, VecLength(direction), r)
			hit_vec = normal
			if hit then
				pos = endd
			end
			until pos ~= 0 or t >= 30
			if pos ~= 0 then
				local xx, yy, distance = UiWorldToPixel(pos)
				if VecLength(VecSub(pos, tr.pos)) <= 5 then prox_alert = "Impact Close" end
				UiTranslate(xx, yy)
				UiText("--")
				flying_time = tostring(math.floor(t*10*2.15)/10).." s" --unusable
			else	
				flying_time = "-NULL-" --unusable
			end
		end
	end
	
end			
-- (v2) server: the three MakeHole calls of the original Splosion (particles are in SplosionFx on clients)
function SplosionWorld(pos, size)
	MakeHole(pos, size, size/2, size/3, true)
	MakeHole(pos, size, size/2, size/3, true)
	MakeHole(pos, size, size/2, size/3, true)
end
function SplosionFx(pos, violence, amount, size, psize)
	--FIRE
	ParticleReset() -- SMOKE
	ParticleType("plain")
	ParticleColor(Devices[Species]["PR"], Devices[Species]["PG"], Devices[Species]["PB"])
	ParticleEmissive(0)
	ParticleRadius(psize/1.5, psize*2)
	ParticleAlpha(Devices[Species]["PA"],0)
	ParticleCollide(0)
	ParticleGravity(Devices[Species]["PGr"])
	ParticleSticky(0.5)
	ParticleDrag(Devices[Species]["PD"])
	ParticleStretch(1)
	for i=1,amount do
	SpawnParticle(VecAdd(pos,RSV(violence/20)), RSV(violence) ,7)
	end
	ParticleReset()
	ParticleType("plain") -- SPIKEY THINGIES
	ParticleColor(Devices[Species]["PR"]/2, Devices[Species]["PG"]/2, Devices[Species]["PB"]/2)
	ParticleEmissive(0)
	ParticleRadius(psize/3, psize/2)
	ParticleAlpha(1,0)
	ParticleCollide(0)
	ParticleGravity(Devices[Species]["PGr"])
	ParticleSticky(0.5)
	ParticleDrag(Devices[Species]["PD"]/8)
	ParticleStretch(1000000)
	for i=1,amount do
	SpawnParticle(pos, RSV(violence*1.5) ,0.5)
	end
	ParticleReset()
	ParticleReset()
	ParticleType("plain") -- DEBRI
	ParticleEmissive(0)
	ParticleRadius(0.07, 0)
	ParticleAlpha(1)
	ParticleCollide(0)
	ParticleGravity(-Devices[Species]["PGr"]*9)
	ParticleSticky(0)
	ParticleDrag(0)
	ParticleStretch(3)
	for i=1,amount*3 do
		roingi = math.random(1,90)/100
		ParticleTile(math.random(1,11))
		ParticleColor(roingi, roingi, roingi)
	SpawnParticle(VecAdd(pos,Vec(0,1,0)), VecAdd(RSV(violence), Vec(0,violence/4,0)) ,6)
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
		for z=1,Devices[Species]["Edmg"] do
		MakeHole(VecAdd(pos, RSV(math.random(bb/1.1,bb))), math.random(1,DynamicDamage*Devices[Species]["Edmg"])/100, math.random(1,DynamicDamage*Devices[Species]["Edmg"])/120, math.random(1,DynamicDamage*Devices[Species]["Edmg"])/170)
		end
end
	ParticleReset()
					local list = QueryAabbBodies(Vec(Position[1] - Devices[Species]["DynamicRange"], Position[2] - Devices[Species]["DynamicRange"], Position[3] - Devices[Species]["DynamicRange"]), Vec(Position[1] + Devices[Species]["DynamicRange"], Position[2] + Devices[Species]["DynamicRange"], Position[3] + Devices[Species]["DynamicRange"]))
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

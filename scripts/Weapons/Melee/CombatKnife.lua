#version 2
#include "script/include/player.lua"
#include "Melee_Functions.lua"


function server.init()
	RegisterTool("melee-CombatKnife", "CombatKnife", "MOD/vox/Weapons/Melee/CombatKnife.vox", 3)
end

function client.init()

	Tool_Id = "melee-CombatKnife"

	-- (v2) RegisterTool moved to server.init()
	thrown = false
	ttime = 5
	smashTimer = 0
	swingback = 0
	swingtow = 0
	soundtimer = 0
	ForceOfMelee = 1
	spinsmash = false
	damage = 9
	AOE = 0.01
	penetration = 1
	spawnjoint = false
	swingSoundFile = "MOD/snd/Weapons/Melee/Knife/melee_attack_knife_plr_02.ogg"
	hitSoundFile = "MOD/snd/Weapons/Melee/Knife/melee_world_knife_wood_plr_02.ogg"

	if HasFile(swingSoundFile) then
		swingsound = LoadSound(swingSoundFile)
	else
		swingsound = LoadSound("MOD/snd/Weapons/Melee/swing0.ogg")
	end
	if HasFile(hitSoundFile) then
		hitsound = LoadSound(hitSoundFile)
	else
		hitsound = LoadSound("MOD/snd/Weapons/Melee/hit1.ogg")
	end
end


--[[function tossweapon()
	SetString("inventory.guns.3.item", "")
	SetString("savegame.mod.inventory.guns.3", "")
	SetBool("inventory.update", true)
	local tt = GetPlayerCameraTransform()
	Spawn("MOD/scripts/Weapons/Melee/CombatKnife.xml", tt)
	throw = FindBodies("throw", true)
	for i=1,#throw do
		if not HasTag(throw[i], "dont") then
			local t = GetBodyTransform(throw[i])
			local force = -300
			local fwd = TransformToParentVec(t,Vec(0,0,1))
			local force1 = 20
			local fwd1 = TransformToParentVec(t,Vec(1,0,0))
			ApplyBodyImpulse(throw[i], t.pos, VecScale(fwd,force))
			ApplyBodyImpulse(throw[i], t.pos, VecScale(fwd1,force1))
			SetTag(throw[i], "dont")
			SetTag(throw[i], "cut")
			thrown = true
		end
	end
end]]





function Smash()
	if smashTimer == 0 then smashTimer = 0.1 end
end

-- (v2) unused; SetPlayerVelocity is server-only, needs a ServerCall if this is ever used
function Boost()
	local pt = GetPlayerTransform()
	local d = TransformToParentVec(pt, Vec(0, 7.5, -2.5))
	local vel = GetPlayerVelocity()
	vel[2] = 0
	vel = VecAdd(vel, d)
	SetPlayerVelocity(vel)
end

function Spin()
	local ct = GetCameraTransform()
	local pt = GetPlayerTransform()

	pt.pos[2] = pt.pos[2] + 1.8
	ct.pos = pt.pos
	ct.rot = QuatRotateQuat(ct.rot, QuatEuler(0, 10, 0))
	SetCameraTransform(ct)

	if smashTimer == 0 then smashTimer = 0.05 end
	if soundtimer == 0 then soundtimer = 0.05 end
end

function client.tick(dt)
	--DebugWatch("CountDown", ttime)
	--[[if not thrown and ttime < 5 then thrown = true
	end


	if thrown then
		ttime = ttime - dt



			cut = FindLights("knife", true)
			for i=1,#cut do
			local cutpos = GetLightTransform(cut[i]).pos
			count = MeleeNet_MakeHole(cutpos, .15, .5, 0)

			--DebugWatch("Cuts", count)
			if count > 1.5 then
			for i=1,#throw do
			local vel = Vec(0,0,0)
			SetBodyVelocity(throw[i], vel)

			end

			if ttime < 0 then
				thrown = false
				ttime = 5
				Delete(cut[i])
			end
		end
	end
end
if ttime < 0 then
thrown = false
ttime = 5
for i=1,#cut do
Delete(cut[i])
end
end]]

	if not GetPlayerCanUseTool() then
		cycled = false
		spinsmash = false
	end
	if GetPlayerTool() == "melee-CombatKnife" and GetPlayerVehicle() == 0 and GetPlayerCanUseTool() then
		if not cycled then
		smashTimer = 0
		cycled = true
		end

		if InputPressed("usetool") then
			Smash()
		end
		if InputPressed("grab") then
			spinsmash = true
			Smash()
		end
		--if InputPressed("q") and not thrown then
			--tossweapon()
		--end

		local b = GetToolBody()
		if b ~= 0 then
			local offset = Transform(Vec(0.3, -0.4, -0.45), QuatEuler(60, -5, 0))
			SetToolTransform(offset)

			--if smashTimer > 0 then
			--	if spinsmash then
			--		local t = Transform()
			--		t.pos = Vec(0.2, -0.4, -0.75+smashTimer*2)
			--		t.rot = QuatEuler(0, 60, 90)
			--		SetToolTransform(t)
			--	else
			--		local t = Transform()
			--		t.pos = Vec(0.6, -0.4, -0.75+smashTimer*2)
			--		t.rot = QuatEuler(smashTimer*400, smashTimer*150, 0)
			--		SetToolTransform(t)
			--	end
			--end

			if smashTimer > 0 then
				if spinsmash then
					local t = Transform()
					if swingback < 0.5 then
						swingback = swingback + dt
						t.pos = Vec(0.6, -0.5, -0.75+smashTimer*2)
						t.rot = QuatEuler(60-smashTimer*300, 60-smashTimer*300, 70)
						swingback = 0
					end
					SetToolTransform(t)
				else
					local t = Transform()
					if swingback < 0.5 then
						swingback = swingback + dt
						t.pos = Vec(0.6, -0.5, -0.75+smashTimer*2)
						t.rot = QuatEuler(90+smashTimer*200, 0, 0-smashTimer*100)
						swingback = 0
					end
					SetToolTransform(t)
				end
			end
		end

		if smashTimer > 0 then
			smashTimer = smashTimer - dt
			if smashTimer < 0.0001 then
				--PlaySound(swingsound, GetPlayerTransform().pos, 0.6)
				holeposes = {}
				local hitcount = 0
				for i=1, 16 do
					local inc = 0.2*i

					local meleedist = 0.8
					slashrange = 0.1
					if i < 6 or i > 10 then meleedist = meleedist * slashrange end
					if i < 5 or i > 11 then meleedist = meleedist * slashrange end
					if i < 4 or i > 12 then meleedist = meleedist * slashrange end
					if i < 3 or i > 13 then meleedist = meleedist * slashrange end
					if i < 2 or i > 14 then meleedist = meleedist * slashrange end
					local vec = spinsmash and Vec(-1.5+inc, 0, -meleedist) or Vec(0, -1.3+inc, -meleedist)

					ct = GetCameraTransform()
					fwdpos = TransformToParentPoint(GetCameraTransform(), vec)
					direction = VecSub(fwdpos, ct.pos)
					distance = VecLength(direction)
					direction = VecNormalize(direction)
					hit, hitDistance, normal, shapeQ = QueryRaycast(ct.pos, direction, distance)

					if hit then

						local hit_pos = VecAdd(ct.pos, VecScale(direction, hitDistance))
						Apply_NPC_Damage_Player(shapeQ, hit_pos, Tool_Id)

						PlaySound(hitsound, GetPlayerTransform().pos, 0.6)
						hitcount = hitcount + 1
						local vec2 = spinsmash and Vec(-1.5+inc, 0, -hitDistance) or Vec(0, -1.3+inc, -hitDistance)

						vec2 = VecScale(vec2, 1.03)
						if i < 6 or i > 10 then vec2 = VecScale(vec2, 0.95) end
						if i < 4 or i > 12 then vec2 = VecScale(vec2, 0.95) end
						if i < 2 or i > 14 then vec2 = VecScale(vec2, 0.95) end
						holeposes[hitcount] = TransformToParentPoint(GetCameraTransform(), vec2)
					end
				end
				for i=1, #holeposes do
					local list = QueryAabbShapes(VecSub(GetAimPos(), Vec(AOE,AOE,AOE)), VecAdd(GetAimPos(), Vec(AOE,AOE,AOE)))
					for z=1, #list do
						local shape = list[z]
						body = GetShapeBody(shape)
						mat, r, g ,b, a = GetShapeMaterialAtPosition(shape, GetAimPos())

						if IsBodyDynamic(body) then
							Force = ForceOfMelee/#list
						   	VelocityFromPlayer(body, Force)
						end
						MeleeNet_MakeHole(holeposes[i], math.random(damage,damage*1.2)/100, math.random(damage,damage*1.2)/100*penetration, math.random(damage,damage*1.2)/100*penetration/2)
					end
					for q=1,10 do
						ParticleReset()
						ParticleType("plain")
						ParticleTile(6)
    					ParticleColor(r,g,b)
    					ParticleRadius(0.05, 0.01)
    					ParticleAlpha(100)
    					ParticleCollide(1)
    					ParticleGravity(-5)
    					ParticleSticky(0.1)
    					ParticleDrag(0)
    					ParticleStretch(0)
    					SpawnParticle(holeposes[i], Vec(math.random(-2,2), math.random(-2,2), math.random(-2,2)),19)
    					ParticleReset()
    					end
				end
				PlaySound(swingsound, GetPlayerTransform().pos, 0.6)
				smashTimer = 0
				spinsmash = false
			end
		end
		--DebugCross(hitPoint)
	end
end





function GetAimPos()
	local ct = GetCameraTransform()
	local forwardPos = TransformToParentPoint(ct, Vec(0, 0, -100))
    local direction = VecSub(forwardPos, ct.pos)
    local distance = VecLength(direction)
	local direction = VecNormalize(direction)
	local hit, hitDistance, normal, shape = QueryRaycast(ct.pos, direction, distance)
	if hit then
		forwardPos = TransformToParentPoint(ct, Vec(0, 0, -hitDistance))
		distance = hitDistance
	end
	return forwardPos, hit, distance
end

function VelocityFromPlayer(body, force)
	armvel = force
	local bmi, bma = GetBodyBounds(body)
    local bc = VecLerp(bmi, bma, 0.5)
    local ppos = VecSub(GetPlayerCameraTransform().pos, Vec(0,1,0))
    local dir = VecSub(bc, ppos)
    local dist = VecLength(dir)
    dir = VecScale(dir, 1.0 / dist)
    local add = VecScale(dir, armvel*8)
    local vel = GetBodyVelocity(body)
    Vel = VecAdd(vel, add)
    --SetBodyVelocity(body, Vel)
    MeleeNet_Impulse(body, GetPlayerCameraTransform().pos, Vel)
  end
#include "../masterScriptRemoverAPI.lua"

function init()
	PerkMachine = FindBody("PerkMachine")
	screen = FindShape("screen")
	machine = FindShape("machine")
	SetTag(screen,"interact","Buy perk: $500")
	Lottery = LoadSound("MOD/snd/Inventory/PerkMachine/Lottery.ogg")
	printingTime = 0

	leverJoint = FindJoint("lever")
	lever = FindShape("lever")
	supercharge=false

	-- perkamount = 17 -- gun perks
	perkamount = 6

	totalPerkBought = 0
	maxPerkBought = 10
end
function tick(dt)
	if not IsHandleValid(PerkMachine)then
		queueRemoval()
		return
	end
	if terminatePerkMachine then
		smoke(GetBodyTransform(PerkMachine).pos,GetBodyVelocity(PerkMachine))
		return
	end

	if totalPerkBought >= maxPerkBought then
		terminatePerkMachine = true
		printing = false
		RemoveTag(screen,"interact")
		SetShapeEmissiveScale(machine, 0)
		if supercharge then -- just to eject a bloody screen
			local entities = Spawn([[<body tags="unbreakable" dynamic="true"><voxbox size="1 1 1"><joint rot="90" type="prismatic" autodisable="true"/></voxbox></body>]], GetShapeWorldTransform(screen),true,true)
			CopyShapeContent(screen, entities[2])
			CopyShapePalette(screen, entities[2])
			local min,max = GetShapeBounds(screen)
			Explosion(VecLerp(min,max,0.5), 0.1)
			Delete(screen)
			SetShapeEmissiveScale(entities[2], 0)
			SetBodyVelocity(entities[1], TransformToParentVec(GetBodyTransform(PerkMachine),Vec(5+math.random()*2,0,0)))
			RemoveTag(entities[1], "unbreakable")
		else
			SetShapeEmissiveScale(screen, 0)
		end
	end

	local perksLeft = maxPerkBought - totalPerkBought
	if perksLeft>1 then
		if GetPlayerInteractShape() == lever and InputPressed("interact") then
			supercharge=not supercharge
		end
	else
		RemoveTag(lever,"interact")
	end
	if _lastSC ~= supercharge then
		local min,max=GetJointLimits(leverJoint)
		if supercharge then
			SetJointMotorTarget(leverJoint, max,math.pi*2)
			SetTag(lever,"interact","Supercharge: ON")
			SetTag(screen,"interact","Buy "..perksLeft.." perk"..(perksLeft>1 and "s" or "")..": $".. 500*perksLeft)
		else
			SetJointMotorTarget(leverJoint, min,math.pi*2)
			SetTag(lever,"interact","Supercharge: OFF")
			SetTag(screen,"interact","Buy perk: $500")
		end
		_lastSC = supercharge
	end

	if interupted then
		SetDescription(PerkMachine, "ERROR: Credit Card Declined.\n"..perksLeft.." Perk".. (perksLeft>1 and "s" or "") .." Left.")
	else
		SetDescription(PerkMachine, perksLeft.." Perk".. (perksLeft>1 and "s" or "") .." Left.")
	end
	if supercharge then
		if printing then
			if printingTime >= 1 then
				spawnPerk()
				totalPerkBought = totalPerkBought + 1

				local PlayerMoney = GetInt("savegame.mod.player.money")
				if PlayerMoney >= 500 and totalPerkBought < maxPerkBought then
					PlaySound(Lottery)
					SetInt("savegame.mod.player.money", PlayerMoney - 500)
					printingTime = printingTime - 0.5
				else
					printingTime = 0
					printing = false
					if totalPerkBought < maxPerkBought then
						interupted = true
						supercharge=false
					end
				end
			end
			printingTime = printingTime + dt
		else
			local PlayerMoney = GetInt("savegame.mod.player.money")
			if GetPlayerInteractShape() == screen and InputPressed("interact") and PlayerMoney >= 500*perksLeft then
				PlaySound(Lottery)
				printing = true
				interupted = false
				SetInt("savegame.mod.player.money", PlayerMoney - 500)
			end
		end

	else
		if printing then
			if printingTime >= 1 then
				spawnPerk()
				totalPerkBought = totalPerkBought + 1
				printingTime = 0
				printing = false
			end
			printingTime = printingTime + dt
		else
			local PlayerMoney = GetInt("savegame.mod.player.money")
			if GetPlayerInteractShape() == screen and InputPressed("interact") and PlayerMoney >= 500 then
				PlaySound(Lottery)
				printing = true
				interupted = false
				SetInt("savegame.mod.player.money", PlayerMoney - 500)
			end
		end
	end
end

function spawnPerk()
	local entities = Spawn("MOD/prefabs/Perk"..math.random(1,perkamount)..".xml", GetBodyTransform(PerkMachine))
	for i=1,#entities do
		local entity=entities[i]
		if GetEntityType(entity) == "body" then
			SetBodyVelocity(entity,TransformToParentVec(GetBodyTransform(PerkMachine),Vec(5+math.random()*2,0,0)))
		end
	end
end

function smoke(pos,vel)
	ParticleType("smoke")
	ParticleColor(0.3,0.3,0.3, 0.6,0.6,0.6)
	ParticleRadius(0.4,2)
	ParticleAlpha(1,0,"easeout")
	ParticleCollide(1, 1, "constant", 0.05)
	ParticleGravity(2)
	ParticleDrag(0.6)
	SpawnParticle(pos,vel, 15)
	ParticleReset()
end
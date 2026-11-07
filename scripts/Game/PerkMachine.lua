#version 2
#include "script/include/player.lua"
-- (v2) Perk machine ($500 per perk; lever = "supercharge": buy all remaining perks at once).
-- Money is per player (each player's own savegame, as in the inventory), so:
--   client: the player looking at the screen presses interact -> pays from THEIR money locally and asks the
--           server (server.perkBuy); the server refunds (client.perkRefund) if the machine is busy/changed meanwhile.
--   server: the machine itself - lever (any player), printing perks, descriptions/prompts, screen ejection.
--           State for the clients in shared.perk (left, supercharge, busy).
-- Change vs v1: supercharge pays all remaining perks up front (v1 took $500 per perk while printing and stopped with
-- "Credit Card Declined" if the money ran out; v1 also required the full amount before starting, so the only
-- difference is spending money elsewhere during printing). Printing no longer stops if the lever is flipped mid-run.

------------------------------------------------------------------
-- Server
------------------------------------------------------------------

function server.init()
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
	PerksToPrint = 0
end

function server.tick(dt)
	if Finished then return end
	if not IsHandleValid(PerkMachine)then
		Finished = true -- (v2) v1 queueRemoval() does not work on the server: just stop
		return
	end
	if terminatePerkMachine then
		smoke(GetBodyTransform(PerkMachine).pos,GetBodyVelocity(PerkMachine))
		PublishPerkState()
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
		for p in Players() do -- (v2) any player can flip the lever
			if GetPlayerInteractShape(p) == lever and InputPressed("interact", p) then
				supercharge=not supercharge
			end
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

	SetDescription(PerkMachine, perksLeft.." Perk".. (perksLeft>1 and "s" or "") .." Left.")

	-- (v2) printing the perks that were paid for (v1: separate supercharge / normal branches, money taken here)
	if printing then
		if printingTime >= 1 then
			spawnPerk()
			totalPerkBought = totalPerkBought + 1
			PerksToPrint = PerksToPrint - 1
			if PerksToPrint > 0 and totalPerkBought < maxPerkBought then
				PlaySound(Lottery, GetBodyTransform(PerkMachine).pos)
				printingTime = printingTime - 0.5
			else
				printingTime = 0
				printing = false
				PerksToPrint = 0
			end
		end
		if printing then printingTime = printingTime + dt end
	end

	PublishPerkState()
end

--- A client paid `paid` for `count` perks (1, or all remaining with supercharge).
function server.perkBuy(p, count, paid)
	local perksLeft = maxPerkBought - totalPerkBought
	local wanted = supercharge and perksLeft or 1
	if Finished or terminatePerkMachine or printing or count ~= wanted or paid < 500 * count then
		ClientCall(p, "client.perkRefund", p, paid)
		return
	end
	PlaySound(Lottery, GetBodyTransform(PerkMachine).pos) -- (v2) at the machine (v1: 2D sound for the one player)
	printing = true
	PerksToPrint = count
	printingTime = 0
end

function PublishPerkState()
	local left = maxPerkBought - totalPerkBought
	local busy = (printing or terminatePerkMachine or Finished) and true or false
	if PublishedLeft ~= left or PublishedSC ~= supercharge or PublishedBusy ~= busy then
		PublishedLeft, PublishedSC, PublishedBusy = left, supercharge, busy
		shared.perk = { left = left, supercharge = supercharge, busy = busy }
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

------------------------------------------------------------------
-- Client
------------------------------------------------------------------

function client.init()
	ClientScreen = FindShape("screen")
end

function client.tick(dt)
	local s = shared.perk
	if not s or s.busy or s.left < 1 then return end
	if GetPlayerInteractShape() == ClientScreen and InputPressed("interact") then
		local count = s.supercharge and s.left or 1
		local cost = 500 * count
		local money = GetInt("savegame.mod.player.money")
		if money >= cost then
			SetInt("savegame.mod.player.money", money - cost)
			ServerCall("server.perkBuy", GetLocalPlayer(), count, cost)
		end
	end
end

function client.perkRefund(target, amount)
	local me = GetLocalPlayer()
	if target ~= me and not (target == 0 and IsPlayerHost(me)) then return end
	SetInt("savegame.mod.player.money", GetInt("savegame.mod.player.money") + amount)
end

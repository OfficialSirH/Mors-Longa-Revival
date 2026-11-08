#version 2
#include "script/include/player.lua"
--[[
#include ../Settings.lua
#include "gunfunctions.lua"
#include "gunperks.lua"
#include "gunstats.lua"
]]


-- (v2) Split: the server picks the target, spawns and flies the A-10 and simulates the rounds for world effects.
-- Clients get every round for tracers/impacts (client.a10Round), the radio/flyover/brrt sounds as events, and
-- draw the engine smoke while shared.a10Plane is set. Target choice is unchanged (non-military NPCs).

---------------------------------------------------------------- server

function server.init()
	Init_Settings()
	ProjectileHandlerInit()
	strikeTimer = 0
	strikePos = Vec()
	planePos0 = Vec()
	plane = 0
	rndAngle = 0
	a10flyoverPlaying = false
	a10soundPlaying = false
	a10radioConfirm = false
	nextStrikeTime = math.random(17*60,23*60)
	VoxModels = {"MOD/vox/a10.xml","MOD/vox/a10_1.xml","MOD/vox/a10_2.xml"}
	AmountVoxModels = #VoxModels
	shared.a10Plane = 0
end

function server.update(dt)
	
	if not Settings.game.a10_brt.value then
		return
	end
	
	local gameTime = GetTime()
	if gameTime > nextStrikeTime then
		local targets = {}
		local aliveNPCsKeys = ListKeys("level.goreai.api.npcs.alive")
		for index, key in ipairs(aliveNPCsKeys) do
			local targetTorso = GetInt("level.goreai.api.npcs.alive." .. key)
			if GetTagValue(targetTorso, "spawn_team") ~= "mil" then
				table.insert(targets, targetTorso)
			end
		end
		local number = #targets

		if number > 0 then
			strikePos = GetBodyTransform(targets[math.random(1,number)]).pos
			nextStrikeTime = gameTime+math.random(10*60,20*60)
			strikeTimer = 40
			endtime = randomFloat(17,18)
			starttime = randomFloat(15,16)
			entities = Spawn(VoxModels[math.random(1,AmountVoxModels)], Transform(Vec(-4000,-100,-4000)))
			plane = entities[1]
			SetTag(plane, "nodelete")
			shared.a10Plane = plane
			rndAngle = math.random()*math.pi*2
			ClientCall(0, "client.a10Event", "prestrike")
		else
			nextStrikeTime = gameTime+randomFloat(4*60,6*60)
		end
	end

	MapMoved	= GetBool("level.map_moved")
	MapMoveVec	= Vec(GetFloat("level.map_move_vec.1"), GetFloat("level.map_move_vec.2"), GetFloat("level.map_move_vec.3"))
	if MapMoved then
		strikePos = VecAdd(strikePos, MapMoveVec) -- Adjust strike pos when map moves to prevent hitting wrong pos.
	end

	if strikeTimer > 0 then

		if strikeTimer < 10 and not a10flyoverPlaying then
			a10flyoverPlaying = true
			ClientCall(0, "client.a10Event", "flyover")
		end

		local x = 20-strikeTimer
		local planePos = VecAdd(strikePos,Vec((1500*(10-x)/20-20)*math.cos(rndAngle), 300*math.cos((x+5)/5)+400, (1500*(10-x)/20-20)*math.sin(rndAngle)))

		local planeTrans = Transform(planePos,QuatLookAt(planePos0,planePos))
		SetBodyTransform(plane,planeTrans)
		SetBodyVelocity(plane,VecScale(VecSub(planePos,planePos0),1/dt))
		planePos0 = VecCopy(planePos)

		if strikeTimer < 30 and not a10radioConfirm then
			a10radioConfirm = true
			ClientCall(0, "client.a10Event", "confirm")
		end
		if starttime < strikeTimer and strikeTimer < endtime then
			if not a10soundPlaying then
				-- each client delays the brrt by its own distance to the strike (<= 50 m: 0-1 s, else 2-3 s)
				ClientCall(0, "client.a10Event", "brrt", strikePos)
				a10soundPlaying = true
			end
			for i=1,math.random(1,22) do 
				A10Fire(planeTrans, "556", "T")
			end
		end

		strikeTimer = strikeTimer - dt * 1.5
		if strikeTimer <= 0 then
			strikeTimer = 0
			a10flyoverPlaying = false
			a10soundPlaying = false
			a10radioConfirm = false
			shared.a10Plane = 0
			Delete(plane)
		end
	end
end

function server.tick(dt)
	for key, shell in ipairs(projectileHandler.shells) do
		if shell.active then
			ProjectileOperations(shell)
		end
	end
	for key, shell in ipairs(grenadeHandler.shells) do
		if shell.active then
			GrenadeOperations(shell)
		end
	end
end

function server.handleCommand(cmd) HandleQuickload(cmd) end

---------------------------------------------------------------- client

function client.init()
	Init_Settings()
	a10sound = LoadSound("MOD/snd/Vehicles/Air/A10/a10-brrt.ogg")
	a10flyover = LoadSound("MOD/snd/Vehicles/Air/A10/a10-flyover.ogg")
	a10PrestrikeRadio = LoadSound("MOD/snd/Vehicles/Air/A10/a10-prestrike-0.ogg")
	a10Radio = LoadSound("MOD/snd/Vehicles/Air/A10/a10-radio-0.ogg")
	soundstoplay = {}
	a10Rounds = {}
	a10flyoverPlayed = false
end

function client.a10Event(kind, pos)
	if kind == "prestrike" then
		a10flyoverPlayed = false
		PlaySound(a10PrestrikeRadio,GetPlayerTransform().pos,2)
	elseif kind == "confirm" then
		PlaySound(a10Radio,GetPlayerTransform().pos,4)
	elseif kind == "flyover" then
		client.a10Flyover()
	elseif kind == "brrt" then
		local dist = VecLength(VecSub(GetPlayerTransform().pos, pos))
		table.insert(soundstoplay, { pos = pos, timer = (dist <= 50 and 0 or 2) + math.random() })
	end
end

function client.a10Flyover()
	local plane = shared.a10Plane or 0
	if not a10flyoverPlayed and plane ~= 0 and IsHandleValid(plane) then
		a10flyoverPlayed = true
		PlaySound(a10flyover, GetBodyTransform(plane).pos, 1000)
	end
end

function client.a10Round(data)
	local shell = {}
	for k, v in pairs(data) do shell[k] = v end
	shell.active = true
	shell.doWorld = false
	a10Rounds[#a10Rounds + 1] = shell
end

function client.update(dt)
	for i=#soundstoplay,1,-1 do
		if soundstoplay[i].timer <= 0 then
			PlaySound(a10sound,soundstoplay[i].pos,1200)
			table.remove(soundstoplay, i)
		else 
			soundstoplay[i].timer = soundstoplay[i].timer - dt
		end
	end
	local plane = shared.a10Plane or 0
	if plane ~= 0 and IsHandleValid(plane) then
		local planeTrans = GetBodyTransform(plane)
		-- original: flyover also starts when the plane comes within 200 m of the player
		if VecDist(planeTrans.pos, GetPlayerTransform().pos) < 200 then client.a10Flyover() end
		ParticleReset()
		ParticleType("smoke")
		ParticleRadius(3,1)
		ParticleColor(0.8,0.8,0.8)
		ParticleAlpha(0.3)
		SpawnParticle(TransformToParentPoint(planeTrans, Vec(-1.55,2.75,4.6)),Vec(),10)
		SpawnParticle(TransformToParentPoint(planeTrans, Vec(1.25,2.75,4.6)),Vec(),10)
	end
end

function client.tick(dt)
	local i = 1
	while i <= #a10Rounds do
		local shell = a10Rounds[i]
		if shell.active then ProjectileOperations(shell) end
		if shell.active then i = i + 1 else table.remove(a10Rounds, i) end
	end
end

---------------------------------------------------------------- shared helpers

function randomFloat(min,max)
	min = tonumber(min) or 0
	max = tonumber(max) or 1
	return math.random()*(max-min)+min
end

function HandleQuickload(cmd)
	for _, word in ipairs(splitString(cmd, " ")) do
		if word == "quickload" then
			Init_Settings()
		end
		break
	end
end

-- (v2) server: one A-10 round, simulated here for world effects only, sent to clients for visuals.
-- (renamed from Shoot, which shadowed the engine function)
function A10Fire(gt, Cartridge, Type)
	local perktable=gunperks[Cartridge][Type]
	local damage = perktable["damage"]
	local pdamage = perktable["pdamage"]
	local explosive = perktable["explosive"]
	local tracer = perktable["tracer"]
	local velocity = perktable["velocity"]
	local maxMomentum = perktable["maxMomentum"]
	
	local lvl5armor = perktable["lvl5armor"]
	local lvl4armor = perktable["lvl4armor"]
	local lvl3armor = perktable["lvl3armor"]
	local lvl2armor = perktable["lvl2armor"]
	local lvl1armor = perktable["lvl1armor"]
	local accuracyFactor = 2
	
	local fwd = TransformToParentVec(gt,VecNormalize(VecAdd(Vec(0,0,-1), randVec(-0.01, 0.01))))

	
	projectileHandler.shells[projectileHandler.shellNum] = deepcopy(projectileHandler.defaultShell)
	loadedShell = projectileHandler.shells[projectileHandler.shellNum] 
	loadedShell.armor = {lvl1armor,lvl2armor,lvl3armor,lvl4armor,lvl5armor}
	loadedShell.damage = damage
	loadedShell.pdamage = pdamage
	loadedShell.explosive = explosive
	loadedShell.tracer = tracer
	loadedShell.velocity = velocity
	loadedShell.maxmomentum = maxMomentum
	loadedShell.active = true
	loadedShell.pos = gt.pos
	loadedShell.momentum = maxMomentum
	loadedShell.predictedBulletVelocity = VecScale(fwd, velocity)
	projectileHandler.shellNum = (projectileHandler.shellNum%#projectileHandler.shells) + 1
	loadedShell.predictedBulletVelocity = VecAdd(loadedShell.predictedBulletVelocity, Vec((math.random()-0.5)*accuracyFactor*2, (math.random()-0.5)*accuracyFactor*2, (math.random()-0.5)*accuracyFactor*2))
	loadedShell.doFx = false
	ClientCall(0, "client.a10Round", {
		armor = loadedShell.armor, damage = damage, pdamage = pdamage, explosive = explosive, tracer = tracer,
		velocity = velocity, maxmomentum = maxMomentum, momentum = maxMomentum,
		pos = VecCopy(gt.pos), predictedBulletVelocity = VecCopy(loadedShell.predictedBulletVelocity),
	})

end

function randBetween(min, max)
	return math.random() * (max - min) + min
end

function randVec(min, max)
    return Vec(randBetween(min, max), randBetween(min, max), randBetween(min, max))
end

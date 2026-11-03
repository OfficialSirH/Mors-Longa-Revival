--[[
#include ../Settings.lua
#include "gunfunctions.lua"
#include "gunperks.lua"
#include "gunstats.lua"
]]


function init()
	Init_Settings()
	ProjectileHandlerInit()
	strikeTimer = 0
	strikePos = Vec()
	planePos0 = Vec()
	plane = 0
	rndAngle = 0

	a10sound = LoadSound("MOD/snd/Vehicles/Air/A10/a10-brrt.ogg")
	a10flyover = LoadSound("MOD/snd/Vehicles/Air/A10/a10-flyover.ogg")
	a10PrestrikeRadio = LoadSound("MOD/snd/Vehicles/Air/A10/a10-prestrike-0.ogg")
	a10Radio = LoadSound("MOD/snd/Vehicles/Air/A10/a10-radio-0.ogg")

	a10flyoverPlaying = false
	a10soundPlaying = false
	a10radioConfirm = false
	a10flyoverPlayed = false

	nextStrikeTime = math.random(17*60,23*60)
	VoxModels = {"MOD/vox/a10.xml","MOD/vox/a10_1.xml","MOD/vox/a10_2.xml"}
	AmountVoxModels = #VoxModels
	Drag = 0
	soundstoplay = {}
end

function update(dt)
	
	if not Settings.game.a10_brt.value then
		return
	end
	
	for i=#soundstoplay,1,-1 do
		if soundstoplay[i].timer <= 0 then
			PlaySound(a10sound,soundstoplay[i].pos,1200)
			table.remove(soundstoplay, i)
		else 
			soundstoplay[i].timer = soundstoplay[i].timer - dt
		end
		
	end
	--[[if InputPressed("r") then
		nextStrikeTime = 0
	end]]
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
		--DebugWatch("# a10 targets", #targets)


		-- for i=#targets,1,-1 do
		-- 	if HasTag(targets[i], "dead") then
		-- 		RemoveTag(targets[i], "Attack")
		-- 		table.remove(targets,i)
		-- 		number = number - 1
		-- 	end
		-- end

		if number > 0 then
			-- local whichone = math.random(2,12)
			-- if math.random(2,12) <= 1 then
			-- 	strikePos = GetPlayerTransform().pos
			-- else
			strikePos = GetBodyTransform(targets[math.random(1,number)]).pos
			-- end
			nextStrikeTime = gameTime+math.random(10*60,20*60)
			strikeTimer = 40
			endtime = randomFloat(17,18)
			starttime = randomFloat(15,16)
			entities = Spawn(VoxModels[math.random(1,AmountVoxModels)], Transform(Vec(-4000,-100,-4000)))
			light = entities[3]
			DebugCross(GetLightTransform(light).pos)
			plane = entities[1]
			SetTag(plane, "nodelete")
			rndAngle = math.random()*math.pi*2
			PlaySound(a10PrestrikeRadio,GetPlayerTransform().pos,2)
		else
			nextStrikeTime = gameTime+randomFloat(4*60,6*60)
		end
	end

	-- if InputPressed("i") then
	-- 	nextStrikeTime = 0
	-- 	starttime = 0
	-- end

	MapMoved	= GetBool("level.map_moved")
	MapMoveVec	= Vec(GetFloat("level.map_move_vec.1"), GetFloat("level.map_move_vec.2"), GetFloat("level.map_move_vec.3"))
	if MapMoved then
		strikePos = VecAdd(strikePos, MapMoveVec) -- Adjust strike pos when map moves to prevent hitting wrong pos.
	end


	if strikeTimer > 0 then

		local planeTr = GetBodyTransform(plane)

		if (strikeTimer < 10 or VecDist(planeTr.pos, GetPlayerTransform().pos) < 200) and not a10flyoverPlaying then
			a10flyoverPlaying = true
			PlaySound(a10flyover, planeTr.pos, 1000)
		end


		local playerPos = GetPlayerTransform().pos
		local dist = VecLength(VecSub(playerPos, strikePos))
		local x = 20-strikeTimer
		local planePos = VecAdd(strikePos,Vec((1500*(10-x)/20-20)*math.cos(rndAngle), 300*math.cos((x+5)/5)+400, (1500*(10-x)/20-20)*math.sin(rndAngle)))

		local planeTrans = Transform(planePos,QuatLookAt(planePos0,planePos))
		SetBodyTransform(plane,planeTrans)
		SetBodyVelocity(plane,VecScale(VecSub(planePos,planePos0),1/dt))
		planePos0 = VecCopy(planePos)
		--if dist < 45 then
		--	DrawBodyOutline(targets[whichtarget], 1, 0, 0, 1)
		--else
		--	DrawBodyOutline(targets[whichtarget], 0, 1, 0, 1)
		--end


		if strikeTimer < 30 and not a10radioConfirm then
			a10radioConfirm = true
			PlaySound(a10Radio,GetPlayerTransform().pos,4)
		end
		if starttime < strikeTimer and strikeTimer < endtime then
			if --[[ dist > 45 ]] true then
			
				
				if dist <= 50 then
					if not a10soundPlaying then
						table.insert(soundstoplay, {
						["pos"] = strikePos,
						["timer"] = 0 + math.random(),
						})
						a10soundPlaying = true
					end
				else
					if not a10soundPlaying then
						table.insert(soundstoplay, {
						["pos"] = strikePos,
						["timer"] = 2 + math.random(),
						})
						a10soundPlaying = true
					end
				end
				for i=1,math.random(1,22) do 
					Shoot(planeTrans, "556", "T")
				end
			else
				nextStrikeTime = gameTime + randomFloat(10,40)
			end
		end

		ParticleReset()
		ParticleType("smoke")
		ParticleRadius(3,1)
		ParticleColor(0.8,0.8,0.8)
		ParticleAlpha(0.3)
		SpawnParticle(TransformToParentPoint(planeTrans, Vec(-1.55,2.75,4.6)),Vec(),10)
		SpawnParticle(TransformToParentPoint(planeTrans, Vec(1.25,2.75,4.6)),Vec(),10)

		strikeTimer = strikeTimer - dt * 1.5
		if strikeTimer <= 0 then
			strikeTimer = 0
			a10flyoverPlaying = false
			a10soundPlaying = false
			a10radioConfirm = false
			Delete(plane)
		end

	else
		a10dist = nil
		a10dist_last = nil -- reset for next flyover
		a10flyoverPlayed = false -- reset for next flyover
	end
	
	
end

function tick(dt)
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

function randomFloat(min,max)
	min = tonumber(min) or 0
	max = tonumber(max) or 1
	return math.random()*(max-min)+min
end

function handleCommand(cmd) HandleQuickload(cmd) end
function HandleQuickload(cmd)
	for _, word in ipairs(splitString(cmd, " ")) do
		if word == "quickload" then
			Init_Settings()
		end
		break
	end
end

function Shoot(gt, Cartridge, Type)
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

end

function randBetween(min, max)
	return math.random() * (max - min) + min
end

function randVec(min, max)
    return Vec(randBetween(min, max), randBetween(min, max), randBetween(min, max))
end

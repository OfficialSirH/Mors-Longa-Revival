#version 2
#include "script/include/player.lua"
-- (v2 operator) SERVER only: AI driving (DriveVehicle), damage, explosions, sounds, siren/lights. Targets the
-- nearest living player; helpers in vehicleOperatorCoop.lua. Converted by tools/porting/history/convert_operators.py.
#include "masterScriptRemoverAPI.lua"
#include "vehicleOperatorCoop.lua"
--debug toggle
debug = false

local NpcPrefabs = {
	refugee = "MOD/prefabs/spawnables/enemies/refugees/Ragdollrefugee1.xml" -- (v2) v1 path had "refugee/"
}

detectRange = 2.5--3

detectPoints = {
	[1] = Vec(0,0,-detectRange*2),
	[2] = Vec(detectRange,0,-detectRange),
	[3] = Vec(-detectRange,0,-detectRange),
	[4] = Vec(-detectRange,0,0),
	[5] = Vec(detectRange,0,0),
	[6] = Vec(0,0,detectRange),

}

costs = {}

weights = {

	[1] = 0.85,
	[2] = 0.85,
	[3] = 0.85,
	[4] = 0.5,
	[5] = 0.5,
	[6] = 0.25,

}

addheight = 1

targetMoves = {
	list        = {},
	target      = Vec(0,0,0),
	targetIndex = 1
}

goalPos = Vec(0,0,0)

drivePower = 1.5

function costFunc(testPos,hit,key)
	local cost = 100
	if(not hit) then
		cost = VecLength(VecSub(testPos,goalPos))*(1-weights[key])
	end
	return cost
end

function GetBestCost()
	local vhtrans = GetVehicleTransform(vehicle)
	vhtrans.pos[2] = vhtrans.pos[2] + addheight
	local bestCost = {key = 0, val = 1000, target = Vec(0,0,0)}
	for key,detect in ipairs(detectPoints) do
		QueryRejectVehicle(vehicle)
		local fwdPos = TransformToParentPoint(vhtrans,detect)
		local direction = VecSub(fwdPos,vhtrans.pos)
		hit, dist = QueryRaycast(vhtrans.pos, direction, VecLength(direction)/1,0.25)
		costs[key] = costFunc(fwdPos,hit,key)
		if costs[key] < bestCost.val  then
			bestCost.key = key
			bestCost.val = costs[key]
			bestCost.target = detect
		end
	end
	return bestCost
end

function MAV(targetCost)
	targetMoves.targetIndex = (targetMoves.targetIndex % #targetMoves.list)+1
	targetMoves.target = VecSub(targetMoves.target,targetMoves.list[targetMoves.targetIndex])
	targetMoves.target = VecAdd(targetMoves.target,targetCost)
	targetMoves.list[targetMoves.targetIndex] = targetCost
	return VecScale(targetMoves.target,(#targetMoves.list/100))
end

function controlVehicle(targetCost)
	if VecLength(goalPos)> 0.5 then
		local targetMove = VecNormalize(targetCost.target)

		if VecLength(VecSub(GetVehicleTransform(vehicle).pos, goalPos)) > 0 then
			-- if(targetMove[1] ~= 0 and targetMove[3] ==0) then
			--    targetMove[3] = 1
			--    targetMove[1] = -targetMove[1]
			-- end
			brakes = false
			vehicleSpeed = VecLength(GetBodyVelocity(vehicleBody))
			if math.abs(targetMove[1]) > 0.7 and vehicleSpeed > 10 then
				brakes = true
			end
			DriveVehicle(vehicle, -targetMove[3]*drivePower,-targetMove[1], brakes)
			--DebugPrint(targetMove[1])
		end
	end
end

function lookatcarnage()
	PPos = GetPlayerTransform().pos
	VPos = GetVehicleTransform(vehicle).pos
	DistToTarget = VecLength(VecSub(VPos, PPos))
	if DistToTarget < 45 then
		rot = QuatLookAt(PPos, VPos)
		--SetCameraTransform(Transform(Vec(PPos[1], PPos[2] + 3, PPos[3]), rot))
		--SetCameraFov(120 - DistToTarget*1.4)
		--SetCameraDof(DistToTarget)
		--SetTimeScale(0.3)
	end
end

LAYER_A = 1 -- Default
LAYER_B = 2
LAYER_C = 4
LAYER_D = 8
LAYER_E = 16
LAYER_F = 32
LAYER_G = 64
LAYER_H = 128
LAYER_ALL = 255

function server.init(dt)

	if HasTag(vehicle, "ai_disabled") then
		return
	end

	vehicle = FindVehicle()
	minhp = 0.8
	if vehicle ~= 0 then
		vehicleBody = GetVehicleBody(vehicle)
		local vBSs = GetBodyShapes(vehicleBody)
		for i,vBS in pairs(vBSs)do
			SetShapeCollisionFilter(vBS, LAYER_H, LAYER_ALL-LAYER_H)
		end

		local vT = GetVehicleTransform(vehicle)
		expOrginLocalT = TransformToLocalTransform(vT,GetLocationTransform(FindLocation("explosionorigin")))
		spawnOrginLocalT = TransformToLocalTransform(vT,GetLocationTransform(FindLocation("locationspawn")))

		underControl = true
		completestop = false
		combusting = false
		ragdollSpawnCD = 0
		vehicleBroke = false
		combustingTime = 0
		spawnedragdolls = 0
		stoppedTime = 0
		--targetfound = math.random() < .5
		targetfound = true

		Rock = LoadLoop("MOD/snd/Music/Vehicle/MUS_Radio_Vehicle0.ogg")
		DebriSnd = LoadSound("MOD/snd/Vehicles/Shared/Destruction/DebriCar"..math.random(1,2)..".ogg")
		CB = LoadSound("MOD/snd/Vehicles/Shared/Destruction/CarGoBoom.ogg")
		--CBD = LoadSound("MOD/snd/Vehicles/Shared/Destruction/CarGoBoomDist.ogg")
		CBD = LoadSound("MOD/snd/Vehicles/Shared/Destruction/CarGoBoomDist"..math.random(1,2)..".ogg")

		for i=1,10 do
			targetMoves.list[i] = Vec(0,0,0)
		end
	end
end

function OperatorTick(dt)
	if vehicle ~= 0 then
		if HasTag(vehicle, "ai_disabled") then
			for index, value in ipairs(FindShapes("TORSO")) do
				Delete(value)
			end
			queueRemoval()
			return
		end
		-- vehicle still active
		if not completestop then
			local vT = GetVehicleTransform(vehicle)
			local vBT = GetBodyTransform(vehicleBody)
			local vVel = GetBodyVelocity(vehicleBody)
			local vehicleSpeed = VecLength(vVel)

			local vehicleHealth = GetVehicleHealth(vehicle)

			local pT = OpTargetTransform(vT.pos) -- (v2 operator) nearest living player
			if vBT.pos[1] < pT.pos[1] or VecLength(VecSub(pT.pos,vT.pos)) < 2 then
				targetfound = true
			end

			local disttoplayer = VecLength(VecSub(vT.pos, pT.pos))
			if disttoplayer < 10 and not underControl and GetPlayerVehicle(OpTargetPlayer(vT.pos)) == 0 then
				ragdollExit = true
			end

			local bodyparts = FindShapes("TORSOD")
			underControl = #bodyparts > 0

			-- driver ragdolls still present on vehicle
			if underControl then
				SetTag(vehicle, "nodrive")

				-- vehicle started (where all the explosion sits in)
				if targetfound then
					--PlayLoop(Rock, GetVehicleTransform(vehicle).pos, 1)
					-- vehicle in range of player
					if ragdollExit then
						DriveVehicle(vehicle, 0,1, true)

						-- open gate
						local doorj = FindJoints("doorr")
						for i=1,#doorj do
							SetJointMotor(doorj[i], -2)
						end

						-- vehicle slow enough
						if vehicleSpeed < 2 then
							-- vehicle stopped
							if stoppedTime > 3 then
								-- delete ragdoll one by one
								local TORSOS = FindShapes("TORSO")
								if ragdollSpawnCD <= 0 and #TORSOS > 0 then
									ragdollSpawnCD = 2
									spawnedragdolls = spawnedragdolls + 1

									local spawnOriginWorldT = TransformToParentTransform(vT, spawnOrginLocalT)
									Spawn(NpcPrefabs.refugee, spawnOriginWorldT)
									Delete(FindShape("TORSO"))
								else
									ragdollSpawnCD = ragdollSpawnCD - dt
								end
							else
								stoppedTime = stoppedTime + dt
							end
						else
							stoppedTime = 0
						end

					else
						-- vehicle slightly damaged
						if vehicleHealth < 0.9 and not vehicleBroke then
							smokedmg()
						end

						-- vehicle not damaged bad enough for ragdoll
						if vehicleHealth > minhp then
							--make car drive to player
							targetCost = GetBestCost()
							if debug then
								DebugWatch("targetDir:",targetCost.key)
							end
							targetCost.target = MAV(targetCost.target)
							controlVehicle(targetCost)

						-- vehicle damaged bad enough for ragdoll
						elseif vehicleHealth < minhp then
							combusting = true
						end
					end

				end
			-- driver ragdolls nolonger present on vehicle
			else
				RemoveTag(vehicle, "nodrive")
				local doorj = FindJoints("doorr")
				for i=1,#doorj do
					SetJointMotor(doorj[i], 0, 0)
				end

				-- vehicle in range of player
				if ragdollExit then
					-- vehicle slow enough
					if vehicleSpeed < 2 or OpAnyPlayerInVehicle(vehicle) then
						-- vehicle stopped
						if stoppedTime > 3 or OpAnyPlayerInVehicle(vehicle) then
							-- ragdoll leave vehicle
							if ragdollSpawnCD <= 0 then
								-- no idea, delete ragdoll one by one
								local TORSOS = FindShapes("TORSO")
								if #TORSOS > 0 then
									ragdollSpawnCD = OpAnyPlayerInVehicle(vehicle) and 1 or 2
									spawnedragdolls = spawnedragdolls + 1

									local ragdollname = GetTagValue(TORSOS[1], "ragdollname")
									local spawnOriginWorldT = TransformToParentTransform(vT, spawnOrginLocalT)
									Spawn(NpcPrefabs.refugee, spawnOriginWorldT)
									Delete(TORSOS[1])
								else
									completestop = true
								end
							else
								ragdollSpawnCD = ragdollSpawnCD - dt
							end
						else
							stoppedTime = stoppedTime + dt
						end
					else
						stoppedTime = 0
						-- vehicle damaged bad enough and still moving
						if vehicleHealth < minhp then
							combusting = true
						end
					end
				end
			end
			-- vehicle is blowing up
			if combusting then
				-- vehicle still "alive"
				if not vehicleBroke then
					smokebefo()

					-- launch vehicle
					if not preplode then
						preplode = true

						local expOrginWorldT = TransformToParentTransform(vT, expOrginLocalT)
						ApplyBodyImpulse(vehicleBody, expOrginWorldT.pos, Vec(0,149000,0))
					end

					-- vehicle now "dead"
					if combustingTime > 0.3 then
						--ApplyBodyImpulse(vehicleBody, GetVehicleTransform(vehicle).pos, Vec(math.random(-vehicleSpeed * 1000,vehicleSpeed * 1000),vehicleSpeed * 5000,math.random(-vehicleSpeed * 1000,vehicleSpeed * 1000)))
						vehicleBroke = true
						--DebugPrint("YEEET")

						local alljoints = FindJoints()
						for i=1,#alljoints do
							Delete(alljoints[i])
						end

						Explosion(vT.pos, 1)
						for i=1,20 do
							Spawn("MOD/prefabs/Debri.xml", Transform(Vec(vT.pos[1] + math.random(-100,100)/100, vT.pos[2] + math.random(-100,100)/100, vT.pos[3] + math.random(-100,100)/100)))
						end
						PlaySound(CB, GetVehicleTransform(vehicle).pos, 15)
						PlaySound(DebriSnd, GetVehicleTransform(vehicle).pos, 15)

						OpPlayDistantSound(CBD, GetVehicleTransform(vehicle).pos) -- (v2 operator) for every player

						sparks()
						debri()
					end

				-- vehicle is "dead" and still fast
				elseif vehicleSpeed > 10 then
					smoke()
					PointLight(GetVehicleTransform(vehicle).pos, 1, 0.75, 0.25, 20)
					local AllBodies = FindBodies()
					for i=1,#AllBodies do
						DrawBodyOutline(AllBodies[i])
						smokeBody(AllBodies[i])
					end
					lookatcarnage()
				end
				if combustingTime > 7 then
					completestop = true
				end
				combustingTime = combustingTime + dt
			end
		else
			queueRemoval()
		end
	else
		queueRemoval()
	end
end

function OperatorUpdate(dt)

	if HasTag(vehicle, "ai_disabled") then
		return
	end

	if not completestop then
		if vehicle and vehicle~=0 then
		   RemoveTag(GetVehicleBody(vehicle), "bounded")
		end
		if targetfound then
			--targetlocation = FindLocation("followroad", true)
			--goalPos = VecAdd(GetLocationTransform(targetlocation).pos, Vec(0,1,0))
			local vhtrans = GetVehicleTransform(vehicle)
			vhtrans.pos[1] = vhtrans.pos[1] + 10
			vhtrans.pos[3] = 0--vhtrans.pos[3] + 10
			goalPos = vhtrans.pos
		end
	end
end

function OperatorDraw(dt)

	if HasTag(vehicle, "ai_disabled") then
		return
	end

	if debug then
		local vhtrans = GetVehicleTransform(vehicle)
		vhtrans.pos[2] = vhtrans.pos[2] + addheight
		for key,detect in ipairs(detectPoints) do
			lineColour = {costs[key]/100,(100-costs[key])/100,0}
			DebugLine(vhtrans.pos, TransformToParentPoint(vhtrans,detect), lineColour[1], lineColour[2], lineColour[3])
		end
		DebugWatch("Siren",sirentick.."/"..sirenchangeinterval)
	end

end

function smoke()
	ParticleColor(1,0.6,0.3,0.1,0.1,0.1,"linear",0,0.5)
	ParticleEmissive(2,0,"linear",0,0.5)
	ParticleRadius(1,0)
	ParticleAlpha(1.0,0.0)
	ParticleCollide(0)
	ParticleGravity(0,-2)
	SpawnParticle(GetVehicleTransform(vehicle).pos, Vec(math.random(-100,100)/50, math.random(-100,100)/50, math.random(-100,100)/50), 2)
	ParticleReset()
	ParticleColor(0.3,0.3,0.3)
	--ParticleEmissive(2,0,"linear",0,0.5)
	ParticleRadius(1.75,3,"linear",0.2,1)
	ParticleAlpha(0.5,0.0)
	ParticleCollide(0)
	ParticleGravity(1)
	SpawnParticle(GetVehicleTransform(vehicle).pos, Vec(math.random(-100,100)/50, math.random(-100,100)/50, math.random(-100,100)/50), 12)
	ParticleReset()
end

function smokedmg()
	ParticleType("smoke")
	ParticleColor(0.3,0.3,0.3)
	--ParticleEmissive(2,0,"linear",0,0.5)
	ParticleRadius(0.4,2)
	ParticleAlpha(1,0)
	ParticleCollide(0)
	ParticleGravity(4)
	ParticleDrag(0.6)
	SpawnParticle(GetVehicleTransform(vehicle).pos, Vec(math.random(-100,100)/150, math.random(-100,100)/150, math.random(-100,100)/150), 8)
	ParticleReset()
end

function smokebefo()
	ParticleColor(1,0.6,0.3,0.1,0.1,0.1,"linear",0,0.5)
	ParticleEmissive(2,0,"linear",0,0.5)
	ParticleRadius(0.5,0)
	ParticleAlpha(1.0,0.0)
	ParticleCollide(0)
	ParticleGravity(0,-2)
	SpawnParticle(GetVehicleTransform(vehicle).pos, Vec(math.random(-100,100)/50, math.random(-100,100)/50, math.random(-100,100)/50), 2)
	ParticleReset()
end

function smokeBody(b)
	ParticleColor(1,0.6,0.3,0.1,0.1,0.1,"linear",0,0.5)
	ParticleEmissive(2,0,"linear",0,0.5)
	ParticleRadius(0.2,0)
	ParticleAlpha(1.0,0.0)
	ParticleCollide(0)
	ParticleGravity(0,-2)
	SpawnParticle(GetBodyTransform(b).pos, Vec(math.random(-100,100)/50, math.random(-100,100)/50, math.random(-100,100)/50), 2)
	ParticleReset()
end

function sparks()
	ParticleColor(1,0.6,0.4,0.1,0.1,0.1,"linear",0,0.5)
	ParticleEmissive(2,0,"linear",0,0.5)
	ParticleRadius(0.02)
	ParticleCollide(1)
	ParticleAlpha(1.0,0.0)
	ParticleCollide(1)
	ParticleGravity(-4)
	ParticleStretch(5)
	ParticleDrag(0)
	for i=1,152 do
		SpawnParticle(GetVehicleTransform(vehicle).pos, Vec(math.random(-800,800)/90, math.random(-800,800)/90, math.random(-800,800)/90), 5)
	end
	ParticleReset()
end

function debri()
	ParticleReset()
	--ParticleEmissive(2,0,"linear",0,0.5)
	ParticleTile(6)
	ParticleRadius(0.2)
	ParticleCollide(1)
	ParticleAlpha(1.0,0.0)
	ParticleCollide(1)
	ParticleGravity(-5)
	--sParticleStretch(5)
	ParticleDrag(0)
	for i=1,152 do
		b = math.random(1,70)/100
		ParticleColor(b, b, b)
		SpawnParticle(GetVehicleTransform(vehicle).pos, Vec(math.random(-18,18), math.random(-18,18), math.random(-18,18), 15))
	end
	ParticleReset()
end


-- (v2 operator) v1 callbacks, run on the server. draw() only played the siren, blinked lights and drew debug lines.
function server.tick(dt)
	if OpFinished then return end
	OperatorTick(dt)
	OpTicked = true
	if not OpFinished then OperatorDraw() end
end

-- update reads values the first tick sets (health, VehicleSpeed); wait for it in case v2 orders them differently
function server.update(dt)
	if OpFinished or not OpTicked then return end
	OperatorUpdate(dt)
end

#version 2
#include "script/include/player.lua"
-- (v2 operator) SERVER only: AI driving (DriveVehicle), damage, explosions, sounds, siren/lights. Targets the
-- nearest living player; helpers in vehicleOperatorCoop.lua. Converted by tools/porting/patches/convert_operators.py.
#include "masterScriptRemoverAPI.lua"
#include "vehicleOperatorCoop.lua"
--debug toggle
debug = false

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

function controlVehicle(targetCost, vehicleid)
	if(VecLength(goalPos)> 0.5) and undercontrol then
		local targetMove = VecNormalize(targetCost.target)

		if(VecLength(VecSub(GetVehicleTransform(vehicleid).pos,goalPos))>0) then
			-- if(targetMove[1] ~= 0 and targetMove[3] ==0) then
			--    targetMove[3] = 1
			--    targetMove[1] = -targetMove[1]
			-- end
			brakes = false
			vehicleB = GetVehicleBody(vehicle)
			VehicleSpeed = VecLength(GetBodyVelocity(vehicleB))
			if targetMove[1] > 0.7 and VehicleSpeed > 10 or targetMove[1] < -0.7 and VehicleSpeed > 10 then
				brakes = true
			end
			DriveVehicle(vehicleid, -targetMove[3]*drivePower,-targetMove[1], brakes)
			--DebugPrint(targetMove[1])
		else
			DriveVehicle(vehicleid, 1,T, false)
		end
	end
	if not undercontrol and dead < 15 then
		DriveVehicle(vehicleid, 1,math.random(-1,1), false)
	end
end

function lookatcarnage()
	-- (v2 operator) depth of field on each player within 45 m (client), slow motion only alone
	OpCarnage(GetVehicleTransform(vehicle).pos)
end

function server.init(dt)
	vehiclebroke = false
	Rock = LoadLoop("MOD/snd/Music/Vehicle/MUS_Radio_Vehicle0.ogg")
	tillblo = 0
	for i=1,10 do
		targetMoves.list[i] = Vec(0,0,0)
	end

	lights = FindShapes("blink", false)
	communicator = FindBody("chasecar", false)
	vehicle = FindVehicle("chasecar", false)
	if HasTag(vehicle,"moto") then
		moto = true
	end
	--init shared values with manager script
	SetTag(communicator, "lightson", "0")
	--check for master script
	if not GetBool("azc.hasmaster") then
		--DebugPrint("AZ-CHASE: Master script not present, please download \"[AZC] Artzert\'s Chase Controller\"")
	end
	--assign sirens
	siren1 = LoadLoop("MOD/snd/police.ogg")
	siren2 = LoadLoop("MOD/snd/police2.ogg")
	sirenchangeinterval = math.random(3600,18000)
	sirentick = 0
	toplay = (math.random(0,1)==1) and siren1 or siren2
	dead = 0
	CB = LoadSound("MOD/snd/Vehicles/Shared/Destruction/CarGoBoom.ogg")
	CBD = LoadSound("MOD/snd/Vehicles/Shared/Destruction/CarGoBoomDist.ogg")
	undercontrol = true
	minhp = 0.6
	completestop = false
	targetfound = false
	exporg = FindShape("explosionorigin")
	exittim = 0
	bodypartz = FindShapes("bodypart")
	chance = 50
	SetTag(vehicle, "nodrive")
	T = math.random(-1,1)
	isMusicEnabled = GetBool("savegame.mod.settings.gameConfig.copyrightMusic")
	DebriSnd = LoadSound("MOD/snd/Vehicles/Shared/Destruction/DebriCar"..math.random(1,2)..".ogg")
end

function OperatorTick(dt)
	--DebugCross(GetShapeWorldTransform(exporg).pos)
	if not completestop then
		if vehicle ~= 0 then
			vehicleB = GetVehicleBody(vehicle)
			vBT = GetBodyTransform(vehicleB)
			pT = OpTargetTransform(vBT.pos) -- (v2 operator) nearest living player
			if not rndzi then
			random = math.random(0,100)
			rndzi = true
			end
			if vBT.pos[1] < pT.pos[1] or random < chance then
				targetfound = true
			end
			health = GetVehicleHealth(vehicle)


			if dead > 15 then
				completestop = true
			end
			VehicleSpeed = VecLength(GetBodyVelocity(vehicleB))
			if VehicleSpeed < 2 and undercontrol and targetfound then
				exittim = exittim + dt
				if exittim > 3 then
					completestop = true
				if HasTag(vehicle, "ragdoll1") then
					Spawn("MOD/prefabs/spawnables/enemies/civilian/RagdollcivDriver.xml", Transform(Vec(vBT.pos[1], vBT.pos[2]+2, vBT.pos[3])))
					for i=1,#bodypartz do
						Delete(bodypartz[i])
					end
				elseif HasTag(vehicle, "ragdoll2") then
					Spawn("MOD/prefabs/spawnables/enemies/civilian/RagdollcivDriver2.xml", Transform(Vec(vBT.pos[1], vBT.pos[2]+2, vBT.pos[3])))
					for i=1,#bodypartz do
					Delete(bodypartz[i])
					end
				elseif HasTag(vehicle, "ragdoll3") then
					Spawn("MOD/prefabs/spawnables/enemies/civilian/RagdollcivDriver3.xml", Transform(Vec(vBT.pos[1], vBT.pos[2]+2, vBT.pos[3])))
					for i=1,#bodypartz do
					Delete(bodypartz[i])
					end

				elseif HasTag(vehicle, "ragdoll4") then
					Spawn("MOD/prefabs/spawnables/enemies/civilian/RagdollcivDriver4.xml", Transform(Vec(vBT.pos[1], vBT.pos[2]+2, vBT.pos[3])))
					for i=1,#bodypartz do
					Delete(bodypartz[i])
					end

				end
				end
			else
				exittim = 0
			end
			if health < 0.9 and not vehiclebroke and not moto then
				smokedmg()
			end



			if health < minhp and not vehiclebroke and not moto then
				tillblo = tillblo + dt
				smokebefo()
				if not preplode then
					eorgpos = GetShapeWorldTransform(exporg).pos
					ApplyBodyImpulse(vehicleB, eorgpos, Vec(0,49000,0))
					preplode = true
				end
				alljoints = FindJoints()
				for i=1,#alljoints do
					Delete(alljoints[i])
				end
				if tillblo > 0.3 then
					--ApplyBodyImpulse(vehicleB, GetVehicleTransform(vehicle).pos, Vec(math.random(-VehicleSpeed * 1000,VehicleSpeed * 1000),VehicleSpeed * 5000,math.random(-VehicleSpeed * 1000,VehicleSpeed * 1000)))
					vehiclebroke = true
					--DebugPrint("YEEET")
					V = GetVehicleTransform(vehicle)
					Explosion(V.pos, 1)
					for i=1,10 do
						Spawn("MOD/prefabs/Debri.xml", Transform(Vec(V.pos[1] + math.random(-100,100)/100, V.pos[2] + math.random(-100,100)/100, V.pos[3] + math.random(-100,100)/100)))
					end
					PlaySound(CB, GetVehicleTransform(vehicle).pos, 15)
					PlaySound(DebriSnd, GetVehicleTransform(vehicle).pos, 15)
					OpPlayDistantSound(CBD, GetVehicleTransform(vehicle).pos) -- (v2 operator) for every player
					sparks()
					debri()
					v = GetVehicleTransform(vehicle).pos
				end
			end
			if targetfound then
				bodyparts = FindShapes("TORSO")
				if #bodyparts > 0 and health > minhp and not vehiclebroke then
					PlayLoop(Rock, GetVehicleTransform(vehicle).pos, 20)
					--PlayMusic("MOD/snd/Music/Vehicle/MUS_Radio_Vehicle0.ogg")
					undercontrol = true
				else
					undercontrol = false
					RemoveTag(vehicle, "nodrive")
					if not moto then
					DriveVehicle(vehicle, 1,math.random(-1,1), false)
					end
					dead = dead + dt
				end
				if (GetVehicleHealth(vehicle) > minhp) then
					--make car drive to player
					targetCost = GetBestCost()
					if debug then
						DebugWatch("targetDir:",targetCost.key)
					end
					targetCost.target = MAV(targetCost.target)
					controlVehicle(targetCost, vehicle)
				else
					if not vehiclebroke and not moto then
						DriveVehicle(vehicle, 1,math.random(-1,1), false)
					end
				end
			end

			if health < minhp and dead < 3 and vehiclebroke and VehicleSpeed > 10 then
				smoke()
				PointLight(GetVehicleTransform(vehicle).pos, 1, 0.75, 0.25, 20)
				AllBodies = FindBodies("")
				--DebugPrint("All bodies: "..#AllBodies)
				for i=1,#AllBodies do
					DrawBodyOutline(AllBodies[i])
					B = GetBodyTransform(AllBodies[i])
					smokeall()
				end
			end
		else
			queueRemoval()
		end
	else
		queueRemoval()
	end
end

function OperatorUpdate(dt)
	if not completestop then
		if vehicle and vehicle~=0 then
			RemoveTag(GetVehicleBody(vehicle), "bounded")
		end
		if targetfound then
			--DebugPrint(VehicleSpeed)
			goalPos = VecAdd(OpTargetTransform(GetVehicleTransform(vehicle).pos).pos, Vec(0,1,0))

			sirentick = sirentick +1
		end
		if health < minhp and dead < 3 and VehicleSpeed > 15 then
			--lookatcarnage()
		end
	end

end

function OperatorDraw(dt)
	local vhtrans = GetVehicleTransform(vehicle)
	vhtrans.pos[2] = vhtrans.pos[2] + addheight
	if debug then
		for key,detect in ipairs(detectPoints) do
			lineColour = {costs[key]/100,(100-costs[key])/100,0}
			DebugLine(vhtrans.pos, TransformToParentPoint(vhtrans,detect), lineColour[1], lineColour[2], lineColour[3])
		end
		DebugWatch("Siren",sirentick.."/"..sirenchangeinterval)
	end

	if (GetTagValue(communicator, "lightson") == "1") and (GetVehicleHealth(vehicle) > 0.2) then
		if sirentick > sirenchangeinterval then
			if toplay == siren1 then
				toplay = siren2
			else
				toplay = siren1
			end
			sirentick = 0
			sirenchangeinterval = math.random(3600,18000)
		end
		if GetVehicleHealth(vehicle) > 0.5 then
			PlayLoop(toplay, vhtrans.pos, 0.4)
		end
		for i=1, #lights do
			local l = lights[i]
			local p = tonumber(GetTagValue(l, "blink"))
			if p then
				local s = math.sin((GetTime()+i) * p)
				SetShapeEmissiveScale(l, s > 0 and 1 or 0)
			end
		end
	else
		for i=1, #lights do
			SetShapeEmissiveScale(lights[i], 0)
		end
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

function smokeall()
	ParticleColor(1,0.6,0.3,0.1,0.1,0.1,"linear",0,0.5)
	ParticleEmissive(2,0,"linear",0,0.5)
	ParticleRadius(0.2,0)
	ParticleAlpha(1.0,0.0)
	ParticleCollide(0)
	ParticleGravity(0,-2)
	SpawnParticle(B.pos, Vec(math.random(-100,100)/50, math.random(-100,100)/50, math.random(-100,100)/50), 2)
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

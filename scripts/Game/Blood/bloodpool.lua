#version 2
#include "script/include/player.lua"
#include "Blood.lua"

-- (v2) server: blood pools are paint (PaintRGBA is server-only). Blood.lua's v1 init() is not called in v2.
function server.init()
	Init_Settings()
end

function server.handleCommand(cmd) HandleQuickload(cmd) end

function server.tick(dt)

	if not Settings.game.blood_and_gore.value then
		return
	end
	--DebugPrint("hi")
	-- local torsos = FindBodies("Torso", true)

	local torsos = {}
	local torsoKeys = ListKeys("level.goreai.api.npcs.dead") -- Get
	for index, key in ipairs(torsoKeys) do
        table.insert(torsos, GetInt("level.goreai.api.npcs.dead" .. "." .. key))
    end


	--if #torsos < 0 then
	for i=1,#torsos do
		local timer = tonumber(GetTagValue(torsos[i], "timer")) or math.random(25,35) + math.random()
		if timer > 0 and GetBodyMass(torsos[i]) > 10 then 
			if HasTag(torsos[i], "dead") then
				if not HasTag(torsos[i], "poolamount") and math.random() < 0.25 then RemoveTag(torsos[i], "Torso") end
				local bloodamount = tonumber(GetTagValue(torsos[i], "poolamount")) or rnd(0.08,0.3)
				if GetBodyVelocity(torsos[i])[1] > 0.0 or GetBodyVelocity(torsos[i])[3] > 0.0 then bloodamount = rnd(0.08,0.1) end
				local dir = Vec(0,-1,0)
				-- DebugPrint(bloodamount)
				Blood_Pool(GetBodyTransform(torsos[i]).pos, 1, 12, torsos[i], bloodamount, 0.3)
				if bloodamount < 0.6 then
					SetTag(torsos[i], "poolamount", bloodamount + 0.005)
					timer = 0
				else
					--RemoveTag(torsos[i], "Torso")
				end
				SetTag(torsos[i], "timer", timer - dt)
			end
		end
	end
end

function Blood_Pool(pos, amount, length, body, size2, spread)

	if not Settings.game.blood_and_gore.value then
		return
	end

	spread = spread or 0

	for i=1,amount do
		local dir = Vec(rnd(-0.1,0.1),-1,rnd(-0.1,0.1))
		local bodies = FindBodies("bodypart", true)
		for i=1,#bodies do
			QueryRejectBody(bodies[i])
		end
		local vecRdm = VecScale(Vec(rnd(-1,1),rnd(-1,1),rnd(-1,1)), spread)
		dir = VecAdd(dir, vecRdm)
		local hit, dist, normal, shape = QueryRaycast(pos, dir, math.random(1,length))
		local ISNPC = HasTag(GetShapeBody(shape),"bodypart") or HasTag(GetShapeBody(shape),"Head") or false

		if hit then
			RayCompute(pos,dir,dist,normal,shape,3,size2,"sphere",true)
		end
	end

end

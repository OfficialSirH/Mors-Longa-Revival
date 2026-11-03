--[[
#include "shape_utils.lua"
#include "../../../Settings.lua"
]]

function init()
	Init_Settings()
end

function rnd(mi, ma)
	return math.random()*(ma-mi)+mi
end

function Blood_Pop(pos, amount, length, body)
	if not Settings.game.blood_and_gore.value then
		return
	end
	
	for i=1,amount do
		dir = Vec(rnd(-1,1),rnd(-1,1),rnd(-1,1))
		if math.random() <= 0.5 then
			QueryRejectBody(body)
		end
		local hit, dist, normal, shape = QueryRaycast(pos, dir, math.random(1,length))
		local ISNPC = HasTag(GetShapeBody(shape),"bodypart") or HasTag(GetShapeBody(shape),"Head") or false
		
		
		if hit then
			RayCompute(pos,dir,dist,normal,shape,3,0.1,"noise",false)
		end
	end
end

function rnd(mi, ma)
	return math.random()*(ma-mi)+mi
end

function RayCompute(pos,dir,dist,normal,shape,mat,size,stype,metal,yes)
	local p = VecAdd(VecAdd(pos, VecScale(dir, dist)), VecScale(normal, - 0.05))
	
	PaintRGBA(p, rnd(0.1,0.3), 0.3,0.025,0.025, math.random(), .5)
end

function getShapeCoord(shape, worldPos)
	local lp = TransformToLocalPoint(GetShapeWorldTransform(shape), worldPos)
	lp[1] = math.floor(lp[1]/.1)
	lp[2] = math.floor(lp[2]/.1)
	lp[3] = math.floor(lp[3]/.1)
	return lp
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
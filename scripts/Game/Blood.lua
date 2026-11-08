--[[
#include "shape_utils.lua"
#include "../../Settings.lua"
]]

function init()
	Init_Settings()
end

function tick(dt)
	-- MLDebugPrint("Blood.lua", "Working")
	local camera_transform = GetCameraTransform()
    local origin = camera_transform.pos
    local direction = QuatRotateVec(camera_transform.rot, Vec(0, 0, -1))
    local hit, distance, normal, shape = QueryRaycast(origin, direction, 100)
    if not hit then
        return
    end
    local body = GetShapeBody(shape)
    DrawShapeOutline(shape, 1,1,0,1)
	if InputPressed("m") then
		GlassHandler(shape)
		DebugPrint("pp")
	end
end

function CheckIndexCompatability(Content,Entries,Number) 
	local Table = {}
	for i=1,#Entries do
		table.insert(Table, Content[i].index)
	end
	return Table
end

function Blood_Pop(pos, amount)

	if not Settings.game.blood_and_gore.value then
		return
	end

	for i=1,amount do
		local dir = Vec(math.random()*2-1,math.random()*2-1,math.random()*2-1)
		--QueryRejectBody(GetToolBody())
		local hit, dist, normal, shape = QueryRaycast(pos, dir, math.random(1,7))
		if hit and not HasTag(GetShapeBody(shape), "bodypart") and not HasTag(GetShapeBody(shape), "Head") and not HasTag(GetShapeBody(shape), "Loot") and not HasTag(shape, "jaw") and GetShapeVoxelCount(shape) > 1 then
			RayCompute(pos,dir,dist,normal,shape,3,math.random(1,3))
		elseif hit and (HasTag(GetShapeBody(shape), "bodypart") or HasTag(GetShapeBody(shape), "Head") or HasTag(shape, "jaw")) then
			RayCompute(pos,dir,dist,normal,shape,3,math.random(1,3))
		end
	end
end

function GlassHandler(shape,pos)
    local size = { GetShapeSize(shape) }
	for x=0, size[1] - 1 do
		for y=0, size[2] - 1 do
			for z=0, size[3] - 1 do
				local material = { GetShapeMaterialAtIndex(shape, x, y, z) }
				if material[1] == "glass" and math.random() < .6 then
					SetBrush("cube", 1, 0)
					DrawShapeLine(shape, x, y, z, x, y, z, false, false)	
				end
			end
		end
	end
	newShapes = SplitShape(shape, false)
	for i=1,#newShapes do 
		local newBody = Spawn("<body dynamic='true'/>", pos)
		SetShapeBody(newShapes[i], newBody[1])
		SetBodyDynamic(newBody[1], true)
		local pos = Vec(0,1,0)
		local imp = Vec(0,0,10)
		--ApplyBodyImpulse(newBody[1], pos, imp)
	end
end

function GlassCleaner(shape)
    local size = { GetShapeSize(shape) }
	for x=0, size[1] - 1 do
		for y=0, size[2] - 1 do
			for z=0, size[3] - 1 do
				local material = { GetShapeMaterialAtIndex(shape, x, y, z) }
				local materials = {GetShapeMaterialAtIndex(shape, x+1, y, z), GetShapeMaterialAtIndex(shape, x-1, y, z), GetShapeMaterialAtIndex(shape, x, y+1, z), GetShapeMaterialAtIndex(shape, x, y-1, z), GetShapeMaterialAtIndex(shape, x, y, z+1), GetShapeMaterialAtIndex(shape, x, y, z-1)}
				if material[1] == "glass" and materials[1] == "air" and materials[2] == "air" and materials[3] == "air" and materials[4] == "air" and materials[5] == "air" and materials[6] == "air" then
					SetBrush("cube", 1, 0)
					DrawShapeLine(shape, x, y, z, x, y, z, false, false)	
				end
			end
		end
	end
end

function RayCompute(pos,dir,dist,normal,shape,mat,size)
	local p = VecAdd(VecAdd(pos, VecScale(dir, dist)), VecScale(normal, - 0.05))
	local pos = getShapeCoord(shape, p)
	if not HasTag(shape, "Bleedable") then
		EditPalette(shape,200)
	end
	
	SetBrush("noise", size, 200)
	DrawShapeLine(shape, pos[1], pos[2], pos[3], pos[1], pos[2], pos[3], true, false)
	-- MLDebugPrint("Blood.Lua","Painted")
end

function EditPalette(shape, Index)
	local palette = {
			index = Index, 
			material = "plastic",
			r = 0.29,  
			g = 0.02,   
			b = 0.02,  
			a = 1,
			reflect = 0,  
			shiny = 0,  
			metal = 0, 
			emissive = 0 
		}
		local content = GetShapePaletteContent(shape)
		table.insert(content, palette)
		SetShapePaletteContent(shape,content)
		SetTag(shape, "Bleedable")
end


function getShapeCoord(shape, worldPos)
	local lp = TransformToLocalPoint(GetShapeWorldTransform(shape), worldPos)
	lp[1] = math.floor(lp[1]/.1)
	lp[2] = math.floor(lp[2]/.1)
	lp[3] = math.floor(lp[3]/.1)
	return lp
end

function GetAimPos()
    local ct = GetPlayerCameraTransform()
    local forwardPos = TransformToParentPoint(ct, Vec(0, 0, -150))
    local direction = VecSub(forwardPos, ct.pos)
    local distance = VecLength(direction)
    local direction = VecNormalize(direction)
    QueryRejectBody(sb)
    local hit, hitDistance = QueryRaycast(ct.pos, direction, distance)
    if hit then
        forwardPos = TransformToParentPoint(ct, Vec(0, 0, -hitDistance))
        distance = hitDistance
    end
    return forwardPos, hit, distance
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
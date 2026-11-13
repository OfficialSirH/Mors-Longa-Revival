--[[
#include "shape_utils.lua"
#include "../../../Settings.lua"
]]

function init()
	Init_Settings()
end



function CheckIndexCompatability(Content,Entries,Number) 
	local Table = {}
	for i=1,#Entries do
		table.insert(Table, Content[i].index)
	end
	return Table
end

function rnd(mi, ma)
	return math.random()*(ma-mi)+mi
end

function Blood_Pop(pos, amount, length, body, nd, second)

	nd = nd or Vec()

	second = second or false
	amounthit = 0
	if not Settings.game.blood_and_gore.value then
		return
	end
	--DebugPrint(dir)
	local hit1, dist1, normal1, shape1 = QueryRaycast(pos, Vec(nd[1],nd[2],nd[3]), length)
	if not hit1 then
		--DebugPrint("NOHit")
		second = true
	end
	for i=1,amount do
		local number = math.random()
		if not second then
			if number <= 0.6 then
				dir = Vec(nd[1] + rnd(-0.5,0.5),nd[2] +  rnd(-0.5,0.5),nd[3] +  rnd(-0.5,0.5))
			elseif number <= 0.3 then
				dir = Vec(-nd[1] - rnd(-0.5,0.5),-nd[2] -  -rnd(-0.5,0.5),-nd[3] -  rnd(-0.5,0.5))
			else
				dir = Vec(rnd(-1,1),rnd(-1,1),rnd(-1,1))
			end
		else
			dir = Vec(rnd(-1,1),rnd(-1,1),rnd(-1,1))
		end
		if math.random() <= 0.5 or second then
			QueryRejectBody(body)
		end
		local hit, dist, normal, shape = QueryRaycast(pos, dir, math.random(1,length))
		local ISNPC = HasTag(GetShapeBody(shape),"bodypart") or HasTag(GetShapeBody(shape),"Head") or false
		if hit and not ISNPC then 
			amounthit = amounthit + 1
		end
		
		if hit and dist < 1 and GetShapeVoxelCount(shape) > 1 and not ISNPC then
			RayCompute(pos,dir,dist,normal,shape,3,0.1,"noise",false)
		elseif hit and dist < 2 and GetShapeVoxelCount(shape) > 1 and not ISNPC then
			RayCompute(pos,dir,dist,normal,shape,3,0.1,"noise",false)
		elseif hit and dist < 4 and GetShapeVoxelCount(shape) > 1 and not ISNPC then
			RayCompute(pos,dir,dist,normal,shape,3,0.1,"sphere",false)
		elseif hit and dist < 7 and GetShapeVoxelCount(shape) > 1 and not ISNPC then
			RayCompute(pos,dir,dist,normal,shape,3,0.1,"sphere",false)
		elseif hit and GetShapeVoxelCount(shape) > 1 and ISNPC then
			RayCompute(pos,dir,dist,normal,shape,3,0.1,"sphere",false)
		end
	end
	if amounthit < 30 and not second then 
		--Blood_Pop(pos, amount*1.3, length, body, Vec(rnd(-1,1),rnd(-1,1),rnd(-1,1)), true)
	end
end



function countair(body)
	local shapes = GetBodyShapes(body)
	for i=1,#shapes do 
		Table = {}
		if HasTag(shapes[i], "bodypart") then
			if not HasTag(shapes[i], "Bleedable") then
				EditPalette(shapes[i],{{"plastic",0.32,0.0,0.0,1,0,0,0,0,200},{"metal",0.6,0.6,0.6,1,0,0,1,0,201}})
			end
			local size = { GetShapeSize(shapes[i]) }
			for x=0, size[1] - 1 do
				for y=0, size[2] - 1 do
					for z=0, size[3] - 1 do
						
						local material = { GetShapeMaterialAtIndex(shapes[i], x, y, z) }
						if material[1] == "" then
							DebugPrint("" .. tostring(x) .. "" .. tostring(y) .. "" .. tostring(z) .. "")
							local newtable = {tostring(x),tostring(y),tostring(z)}
							table.insert(Table, table.concat(newtable, ""))
							
							
							
						end
					end
				end
			end
		end
		SetTag(shapes[i], "coord", table.concat(Table, "-")) 
	end
end
TableDeezNuts = {
	torso = {
		["000"] = {},
		["010"] = {},
		["100"] = {},
		["110"] = {},
				

		
		["310"] = {},
		["410"] = {},
		["300"] = {},
		["400"] = {},
	},
	head = {
	
	
	},
	arm = {
	
	},
	arml = {
	
	
	
	},
	leg = {
	
	},
	legl = {
	
	
	
	},
	
	leglr = {
	
	},
	legr = {
	
	
	
	},
	jaw = {
	
	
	},
}


function Blood_Sides(body)
	local shapes = GetBodyShapes(body)
	for i=1,#shapes do 
		local Coords = Split(GetTagValue(shapes[i], "coord"), "-")
		if HasTag(shapes[i], "bodypart") then
			if not HasTag(shapes[i], "Bleedable") then
				EditPalette(shapes[i],{{"plastic",0.32,0.0,0.0,1,0,0,0,0,200},{"metal",0.6,0.6,0.6,1,0,0,1,0,201}})
			end
			local size = { GetShapeSize(shapes[i]) }
			for x=0, size[1] - 1 do
				for y=0, size[2] - 1 do
					for z=0, size[3] - 1 do
						local material = { GetShapeMaterialAtIndex(shapes[i], x, y, z) }		
					
						if material[1] == "" then
							DebugPrint("" .. tostring(x) .. "" .. tostring(y) .. "" .. tostring(z) .. "")
							SetBrush("cube", 1, 200)
							DrawShapeLine(shapes[i], x+1, y, z, x+1, y, z, true, false)
							SetBrush("cube", 1, 200)
							DrawShapeLine(shapes[i], x-1, y, z, x-1, y, z, true, false)
							SetBrush("cube", 1, 200)
							DrawShapeLine(shapes[i], x, y-1, z, x, y-1, z, true, false)
							SetBrush("cube", 1, 200)
							DrawShapeLine(shapes[i], x, y+1, z, x, y+1, z, true, false)
							SetBrush("cube", 1, 200)
							DrawShapeLine(shapes[i], x, y, z-1, x, y, z-1, true, false)	
							SetBrush("cube", 1, 200)
							DrawShapeLine(shapes[i], x, y, z+1, x, y, z+1, true, false)	
							
						end
					end
				end
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

function GlassHandler(shape,pos)
    local NewShapeXYZ = getShapeCoord(shape, pos)
	DebugPrint(NewShapeXYZ)
	local size = { GetShapeSize(shape) }
	for x=0, size[1] - 1 do
		for y=0, size[2] - 1 do
			for z=0, size[3] - 1 do
				local material = { GetShapeMaterialAtIndex(shape, x, y, z) }
				if material[1] == "glass" and math.random() < .1 then
					SetBrush('cube', 1, 0)
					DrawShapeLine(shape, x, y, z, x, y, z)	
				end
			end
		end
	end
	local bodies = AutoSplitShapeIntoBodies(shape,false,false)
	for i=1,#bodies do 
		if math.random() < 0.5 then
			Delete(bodies[i])
		end
	end
		
end

function AutoPopVoxel(shape, voxel_position, keep_original, no_body, reject_materials)
	local material = { GetShapeMaterialAtIndex(shape, unpack(voxel_position)) }
	if material[1] == '' or (reject_materials and AutoTableContains(reject_materials, material[1])) then return false, false end

	local shape_size = { GetShapeSize(shape) }
	local shape_transform = GetShapeWorldTransform(shape)
	local shape_body = GetShapeBody(shape)
	local shape_body_velocity = { linear = GetBodyVelocity(shape_body), rotational = GetBodyAngularVelocity(shape_body) }

	if not keep_original then
		SetBrush('cube', 1, 0)
		DrawShapeLine(shape, voxel_position[1], voxel_position[2], voxel_position[3], voxel_position[1], voxel_position[2], voxel_position[3])
	end

	local body
	local new_shape

	if no_body then
		--new_shape = CreateShape(GetWorldBody(), Transform(TransformToParentPoint(shape_transform, VecScale(voxel_position, shape_size[4])), shape_transform.rot), shape)
		SetBrush('cube', 1, material[6])
		DrawShapeLine(new_shape, 0, 0, 0, 0, 0, 0)
	else
		--local body_transform = Transform(TransformToParentPoint(shape_transform, VecScale(voxel_position, shape_size[4])), shape_transform.rot)
		--body = Spawn('<body/>', body_transform)[1]
	
		--new_shape = CreateShape(body, Transform(), shape)
		--SetBrush('cube', 1, material[6])
		--DrawShapeLine(new_shape, 0, 0, 0, 0, 0, 0)
	
		SetBodyDynamic(body, true)
		SetBodyActive(body, true)
	
		SetBodyVelocity(body, shape_body_velocity.linear)
		SetBodyAngularVelocity(body, shape_body_velocity.rotational)
	end

	return body, new_shape
end

function AutoShapeCenter(shape)
	local aa, bb = GetShapeBounds(shape)
	return VecScale(VecAdd(aa, bb), 0.5)
end

function AutoMoveShapeToNewBody(shape, static)
	local shape_transform = GetShapeWorldTransform(shape)
	local shape_body = GetShapeBody(shape)

	local shape_center = AutoShapeCenter(shape)
	local body_transform = Transform(shape_center, shape_transform.rot)
	local body = Spawn('<body/>', body_transform)[1]
	SetShapeBody(shape, body, TransformToLocalTransform(body_transform, GetShapeWorldTransform(shape)))

	if static then
		SetBodyDynamic(body, false)
	else
		local shape_body_velocity = { linear = GetBodyVelocityAtPos(shape_body, shape_center), rotational = GetBodyAngularVelocity(shape_body) }

		SetBodyDynamic(body, true)
		SetBodyActive(body, true)
		
		SetBodyVelocity(body, shape_body_velocity.linear)
		SetBodyAngularVelocity(body, shape_body_velocity.rotational)
	end
		
	return body
end

function AutoSplitShapeIntoBodies(shape, removeResidual, static)
	local new_bodies = {}

	for _, new_shape in pairs(SplitShape(shape, removeResidual)) do
		new_bodies[#new_bodies+1] = AutoMoveShapeToNewBody(new_shape, static)
	end

	return new_bodies
end

function rnd(mi, ma)
	return math.random()*(ma-mi)+mi
end

function RayCompute(pos,dir,dist,normal,shape,mat,size,stype,metal,yes)
	Colors = {
	{0.3,0.025,0.025},
	{0.2,0.025,0.025},
	{0.34,0.03,0.03},
	}
	AmountColors = #Colors
	local p = VecAdd(VecAdd(pos, VecScale(dir, dist)), VecScale(normal, - 0.05))
	local color = math.random(1,AmountColors)
	if metal then
		if size < 0.6 then
			PaintRGBA(p,size,Colors[color][1],Colors[color][2],Colors[color][3],1,rnd(0.5,0.99))
		else
			PaintRGBA(VecAdd(p,Vec(0,-0.6,0)),size,Colors[color][1],Colors[color][2],Colors[color][3],1,rnd(0.5,0.99))
		end
	else
		PaintRGBA(p,size,Colors[color][1],Colors[color][2],Colors[color][3],1,rnd(0.5,0.99))
	end
end

function EditPalette(shape, stats)
	local content = {}
	local Stats = stats
	local content1 = GetShapePaletteContent(shape)
	for j=1,#content1 do 
		if j ~= 200 then
			table.insert(Stats, {
			content1[j].material,
			content1[j].r,
			content1[j].g,
			content1[j].b,
			content1[j].a,
			content1[j].reflect,
			content1[j].shiny,
			content1[j].metal,
			content1[j].emissive,	
			content1[j].index,})
		end
	end
	--for i=1,#content do table.insert(Stats, {content[i][2],content[i][3],content[i][4],content[i][5],content[i][6],content[i][7],content[i][8],content[i][9],content[i][1]}) end
	--DebugPrint(#content)
	for i=1,255 do 
		
		for j=1,#Stats do 
			falsey = false
			if i == Stats[j][10] then
				falsey = true
			
			end
		end
	
			if not falsey then
					local grey = {
					index = i, 
					material = "plastic",
					r = 0.25,  
					g = 0.25,   
					b = 0.25,  
					a = 1,
					reflect = 0,  
					shiny = 0,  
					metal = 0, 
					emissive = 0
				}
				table.insert(content, grey)
			end
		end
	
	
	for i=1,#Stats do 
		local palette = {
			index = Stats[i][10], 
			material = Stats[i][1],
			r = Stats[i][2],  
			g = Stats[i][3],   
			b = Stats[i][4],  
			a = Stats[i][5],
			reflect = Stats[i][6],  
			shiny = Stats[i][7],  
			metal = Stats[i][8], 
			emissive = Stats[i][9] 
		}
		table.insert(content, palette)
	end
		SetShapePaletteContent(shape,content)
		SetTag(shape, "Bleedable")
end

function EditPaletteThermal(shape, Index)
	local palette = {
			index = Index, 
			material = "plastic",
			r = 1,  
			g = 1,   
			b = 1,  
			a = 1,
			reflect = 0,  
			shiny = 0,  
			metal = 0, 
			emissive = 0.5 
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
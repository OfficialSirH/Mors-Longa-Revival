#version 2
#include "script/include/player.lua"
#include "../../../Settings.lua"
#include "shape_utils.lua"

-- (v2) Split: the client shows the menu and a local (client-spawned) see-through preview body and
-- sends the placement to the server, which spawns and attaches the real object.

function server.init()
	RegisterTool("placer", "Place Tool", "MOD/vox/placer.vox", 4)
	for p in Players() do SetToolEnabled("placer", true, p) end
end

function server.tick(dt)
	for p in PlayersAdded() do SetToolEnabled("placer", true, p) end
	for p in Players() do
		if GetPlayerTool(p) == "placer" then ReleasePlayerGrab(p) end -- server-only in v2
	end
end

function server.placeAt(path, pos, shape, rot)
	if shape == 0 or not IsHandleValid(shape) then return end
	SpawnAtPos(path, pos, shape, rot)
end

function client.init()
	Init_Settings()
	PlaceTool_Interactive = false
	PlaceTool_UiSound = false
	
	Rotation = 0
	
	models = {}
	do 
		table.insert(models, {
			name = "Armor Plate III",
			path = "MOD/scripts/Game/PlaceTool/Placeables/Armor3.xml",
			amountrubber = 0,
			amountsteel = 1,
			amountkevlar = 0,
			amountscrap = 1,
			amountdriftwood = 0,
			amountexplosive = 0
		})
		table.insert(models, {
			name = "Armor Plate IV",
			path = "MOD/scripts/Game/PlaceTool/Placeables/Armor4.xml",
			amountrubber = 0,
			amountsteel = 1,
			amountkevlar = 1,
			amountscrap = 2,
			amountdriftwood = 0,
			amountexplosive = 0
		})
		table.insert(models, {
			name = "Spotlight",
			path = "MOD/scripts/Game/PlaceTool/Placeables/SpotLight.xml",
			amountrubber = 2,
			amountsteel = 2,
			amountkevlar = 0,
			amountscrap = 2,
			amountdriftwood = 0,
			amountexplosive = 0
		})
		table.insert(models, {
			name = "Gun",
			path = "MOD/scripts/Game/PlaceTool/Placeables/Gun1.xml",
			amountrubber = 2,
			amountsteel = 2,
			amountkevlar = 0,
			amountscrap = 2,
			amountdriftwood = 0,
			amountexplosive = 0
		})
		table.insert(models, {
			name = "Armor Plate V",
			path = "MOD/scripts/Game/PlaceTool/Placeables/Armor5.xml",
			amountrubber = 2,
			amountsteel = 2,
			amountkevlar = 3,
			amountscrap = 0,
			amountdriftwood = 0,
			amountexplosive = 0
		})
		table.insert(models, {
			name = "Sandbag",
			path = "MOD/scripts/Game/PlaceTool/Placeables/Sandbag.xml",
			amountrubber = 2,
			amountsteel = 0,
			amountkevlar = 0,
			amountscrap = 1,
			amountdriftwood = 0,
			amountexplosive = 0
		})
		table.insert(models, {
			name = "Ladder",
			path = "MOD/scripts/Game/PlaceTool/Placeables/Driftwood.xml",
			amountrubber = 0,
			amountsteel = 0,
			amountkevlar = 0,
			amountscrap = 0,
			amountdriftwood = 3,
			amountexplosive = 0
		})
		table.insert(models, {
			name = "Fuel Barrel",
			path = "MOD/scripts/Game/PlaceTool/Placeables/FuelBarrel.xml",
			amountrubber = 3,
			amountsteel = 3,
			amountkevlar = 0,
			amountscrap = 1,
			amountdriftwood = 0,
			amountexplosive = 0
		})
		table.insert(models, {
			name = "Crate",
			path = "MOD/scripts/Game/PlaceTool/Placeables/Crate.xml",
			amountrubber = 0,
			amountsteel = 0,
			amountkevlar = 0,
			amountscrap = 1,
			amountdriftwood = 3,
			amountexplosive = 0
		})
		table.insert(models, {
			name = "IED Stick I",
			path = "MOD/scripts/Game/PlaceTool/Placeables/IEDStickI.xml",
			amountrubber = 3,
			amountsteel = 1,
			amountkevlar = 0,
			amountscrap = 2,
			amountdriftwood = 0,
			amountexplosive = 1
		})
		table.insert(models, {
			name = "IED Stick II",
			path = "MOD/scripts/Game/PlaceTool/Placeables/IEDStickII.xml",
			amountrubber = 3,
			amountsteel = 2,
			amountkevlar = 0,
			amountscrap = 2,
			amountdriftwood = 0,
			amountexplosive = 2
		})
		table.insert(models, {
			name = "IED Stick III",
			path = "MOD/scripts/Game/PlaceTool/Placeables/IEDStickIII.xml",
			amountrubber = 3,
			amountsteel = 3,
			amountkevlar = 0,
			amountscrap = 2,
			amountdriftwood = 0,
			amountexplosive = 4
		})
		table.insert(models, {
			name = "Armored Glass III",
			path = "MOD/scripts/Game/PlaceTool/Placeables/Glass3.xml",
			amountrubber = 0,
			amountsteel = 0,
			amountkevlar = 1,
			amountscrap = 1,
			amountdriftwood = 0,
			amountexplosive = 0
		})
		table.insert(models, {
			name = "Armored Glass IV",
			path = "MOD/scripts/Game/PlaceTool/Placeables/Glass4.xml",
			amountrubber = 0,
			amountsteel = 0,
			amountkevlar = 2,
			amountscrap = 2,
			amountdriftwood = 0,
			amountexplosive = 0
		})
		table.insert(models, {
			name = "Armored Glass V",
			path = "MOD/scripts/Game/PlaceTool/Placeables/Glass5.xml",
			amountrubber = 0,
			amountsteel = 0,
			amountkevlar = 3,
			amountscrap = 3,
			amountdriftwood = 0,
			amountexplosive = 0
		})
		table.insert(models, {
			name = "Ramp",
			path = "MOD/scripts/Game/PlaceTool/Placeables/Ramp.xml",
			amountrubber = 5,
			amountsteel = 3,
			amountkevlar = 3,
			amountscrap = 4,
			amountdriftwood = 4,
			amountexplosive = 0
		})
		table.insert(models, {
		name = "Campfire",
		path = "MOD/scripts/Game/PlaceTool/Placeables/Campfire.xml",
		amountrubber = 0,
		amountsteel = 0,
		amountkevlar = 0,
		amountscrap = 2,
		amountdriftwood = 3,
		amountexplosive = 0
	})
	end
	CurrentModelIndex = 1
	CurrentModel = models[CurrentModelIndex]
	PreviewBody = SpawnPreviewBody(CurrentModel.path)
	scroll = false
end

function client.draw()
	-- (v2) Ui* calls only work in draw: tick sets these flags
	if PlaceTool_Interactive then UiMakeInteractive() end
	if PlaceTool_UiSound then UiSound("clickup.ogg") PlaceTool_UiSound = false end

	UiTranslate(390, -10)

	if GetPlayerTool() == "placer" then
		drawMenu()
	end
end

function drawItemRequirements(margin_x)
	UiPush()

		UiTranslate(margin_x + 10)
		UiAlign("top left")
		UiColor(1, 1, 1, 1)
		UiFont("bold.ttf", 24)

		local marginY = 30

		local matInv = {
			{ name = "rubber", invAmt = GetInt("inventory.count_rubber"), needed =  CurrentModel.amountrubber },
			{ name = "steel", invAmt = GetInt("inventory.count_steel"), needed =  CurrentModel.amountsteel },
			{ name = "kevlar", invAmt = GetInt("inventory.count_kevlar"), needed =  CurrentModel.amountkevlar },
			{ name = "scrap", invAmt = GetInt("inventory.count_scrap"), needed =  CurrentModel.amountscrap },
			{ name = "driftwood", invAmt = GetInt("inventory.count_driftwood"), needed =  CurrentModel.amountdriftwood },
			{ name = "explosive", invAmt = GetInt("inventory.count_explosive"), needed =  CurrentModel.amountexplosive },
		}
		
		for i=#matInv,1,-1 do 
			if matInv[i].needed == 0 then
				table.remove(matInv,i)
			end
		end
		if GetBool("savegame.mod.infiniteMaterials") then
			for _, item in ipairs(matInv) do
				item.needed = 0
			end
		end

		UiPush()

			local count = 0
			for index, mat in ipairs(matInv) do
					count = count + 1
			end

			UiColor(0, 0, 0, 0.7)
			UiRect(200, marginY*count)

		UiPop()

		for index, mat in ipairs(matInv) do
			if mat.needed >= 0 then
				UiColorBool(mat.invAmt >= mat.needed)
			else
				UiColor(0,0,0,0)
			end

			UiText(mat.name .. ": ")
			UiPush()
				UiTranslate(120, 0)
				UiText(mat.invAmt .. "/" .. mat.needed)
			UiPop()

			UiTranslate(0, marginY)

		end

	UiPop()
end

function UiColorBool(bool)
	if bool then
		UiColor(1, 1, 1, 1)
	else
		UiColor(1, 0.4, 0.4, 1)
	end
end

function drawMenu()
	local height = #models * 30
	local padding = 30

	UiTranslate(30, UiHeight() - padding - height)
	UiColor(0, 0, 0, 0.7)
	UiRect(200, height + padding)

	drawMenuTitle(200, 70)

	for i = 1, #models do
		drawMenuItem(i)
	end

	UiPush()
		drawItemRequirements(200)
	UiPop()
end

function SpawnPreviewBody(xml)
	if PreviewBody then Delete(PreviewBody) end
	local Entities = Spawn(xml, Transform())
	for i=1,#Entities do 
		if GetEntityType(Entities[i]) == "light" then
			Delete(Entities[i])
		end
		if GetEntityType(Entities[i]) == "shape" then
			local NewTable = {}
			local content = GetShapePaletteContent(Entities[i])
			for i=1,#content do 
				table.insert(NewTable, {
				content[i].material,
				content[i].r,
				content[i].g,
				content[i].b,
				content[i].a,
				content[i].reflect,
				content[i].shiny,
				content[i].metal,
				content[i].emissive,
				content[i].index,})
			end
			EditPalette(Entities[i], NewTable)
		end
	end 
	return Entities[1]
end

function EditPalette(shape, Stats)
	local Table = {}
	for i=1,#Stats do 
		local palette = {
			index = Stats[i][10], 
			material = "nonphysical",  
			r = Stats[i][2]*0.2,   
			g = Stats[i][3]*0.2,  
			b = Stats[i][4]*0.8, 
			a = 0.5, 
			reflect = 0,
			shiny = 1,
			metal = Stats[i][8],
			emissive = 1,
		}
		table.insert(Table, palette)
	end
	SetShapePaletteContent(shape,Table)
end

function client.tick(dt)
	PlaceTool_Interactive = false
	if GetPlayerTool() == "placer" then
		if KeybindDown(Settings.keybinds.player.placetool_Scroll) then
		PlaceTool_Interactive = true
		if InputValue("mousewheel") ~= 0 then
			if InputValue("mousewheel") > 0 then
				CurrentModelIndex = CurrentModelIndex - 1
				scroll = true
				PlaceTool_UiSound = true
			end
			if InputValue("mousewheel") < 0 then
				CurrentModelIndex = CurrentModelIndex + 1
				scroll = true
				PlaceTool_UiSound = true
			end
			if CurrentModelIndex > #models then
				CurrentModelIndex = 1
			end
			if CurrentModelIndex < 1 then
				CurrentModelIndex = #models
			end
			CurrentModel = models[CurrentModelIndex]
			PreviewBody = SpawnPreviewBody(CurrentModel.path)
		end
	end

	if KeybindReleased(Settings.keybinds.player.placetool_Scroll) and not scroll then
		PlaceTool_UiSound = true
		CurrentModelIndex = CurrentModelIndex + 1
		if CurrentModelIndex > #models then
			CurrentModelIndex = 1
		end
		CurrentModel = models[CurrentModelIndex]
		PreviewBody = SpawnPreviewBody(CurrentModel.path)
	end

	if KeybindReleased(Settings.keybinds.player.placetool_Scroll) and scroll then
		scroll = false
	end
		
		
		
		-- (v2) ReleasePlayerGrab() is done by server.tick
		local PreviewShapes = GetBodyShapes(PreviewBody)
		for i=1,#PreviewShapes do 
			SetShapeCollisionFilter(PreviewShapes[i], 0, 0)
		end
		SetBodyDynamic(PreviewBody, false)
		
		if InputDown("rmb") and not InputDown("shift") then
			Rotation = Rotation + 1
		end
		if InputPressed("rmb") and InputDown("shift") then
			Rotation = math.floor((Rotation + 7.5) / 15) * 15
			Rotation = Rotation + 15
		end
		
		local shapes = { GetAimPos() }
		DrawBodyOutline(GetShapeBody(shapes[2]),1,1,1,1)
		if InputPressed("lmb") and checkPlaceable(CurrentModelIndex) and shapes[1] then
			ServerCall("server.placeAt", CurrentModel.path, shapes[1], shapes[2], shapes[3])
			SetString(
				"inventory.removematerials",
				CurrentModel.amountrubber .. "_" ..
				CurrentModel.amountsteel .. "_" ..
				CurrentModel.amountkevlar .. "_" ..
				CurrentModel.amountscrap .. "_" ..
				CurrentModel.amountdriftwood .. "_" ..
				CurrentModel.amountexplosive)
		end

		SetBodyTransform(PreviewBody, Transform(shapes[1],shapes[3]))
	else
		BackGroundTick(dt)	
	end
end

function BackGroundTick(dt)
	SetBodyTransform(PreviewBody, Transform(Vec(0,-900,0)))
end

-- (v2) server only (called from server.placeAt)
function SpawnAtPos(path, pos, shape, rot)
	local entity = Spawn(path,Transform(pos, rot))	
	local Table = {
		shapes = {},
		lights = {},
	}
	for i=1,#entity do 
		if GetEntityType(entity[i]) == "shape" then
			table.insert(Table.shapes, entity[i])
		end
		if GetEntityType(entity[i]) == "light" then
			table.insert(Table.lights, {shape = entity[i], transform = GetLightTransform(entity[i])})
		end
	end
	for i=1,#Table.shapes do
		local transform = TransformToLocalTransform(GetBodyTransform(GetShapeBody(shape)),GetShapeWorldTransform(Table.shapes[i]))	
		SetShapeBody(Table.shapes[i], GetShapeBody(shape),transform)
	end
	for i=1,#Table.lights do
		local trans1 = Table.lights[i].transform
		local light = Table.lights[i].shape
		
		SetProperty(light, "transform", TransformToLocalTransform(GetBodyTransform(GetShapeBody(shape)),trans1))
	end
end


function GetAimPos()
    local cameraTransform = GetCameraTransform()
    local cameraPos = cameraTransform.pos
    local cameraDir = TransformToParentVec(cameraTransform, Vec(0, 0, -1))

    local maxDistance = 5
    QueryRejectBody(PreviewBody)
    QueryRejectBody(GetToolBody())
    local hit, dist, normal, shape = QueryRaycast(cameraPos, cameraDir, maxDistance)

    if hit then
        local hitPos = VecAdd(cameraPos, VecScale(cameraDir, dist))
        local shapeTransform = GetShapeWorldTransform(shape)
        local localHitPos = TransformToLocalPoint(shapeTransform, hitPos)
        local localNormal = TransformToLocalVec(shapeTransform, normal)

        local snapSize = 0.05
        
        if math.abs(localNormal[1]) > math.abs(localNormal[2]) and math.abs(localNormal[1]) > math.abs(localNormal[3]) then
            localHitPos = Vec(
                localHitPos[1],
                math.floor(localHitPos[2] / snapSize + 0.5) * snapSize,
                math.floor(localHitPos[3] / snapSize + 0.5) * snapSize
            )
        elseif math.abs(localNormal[2]) > math.abs(localNormal[1]) and math.abs(localNormal[2]) > math.abs(localNormal[3]) then
            localHitPos = Vec(
                math.floor(localHitPos[1] / snapSize + 0.5) * snapSize,
                localHitPos[2],
                math.floor(localHitPos[3] / snapSize + 0.5) * snapSize
            )
        else
            localHitPos = Vec(
                math.floor(localHitPos[1] / snapSize + 0.5) * snapSize,
                math.floor(localHitPos[2] / snapSize + 0.5) * snapSize,
                localHitPos[3]
            )
        end

        local worldSnapPos = TransformToParentPoint(shapeTransform, localHitPos)
        local worldNormal = TransformToParentVec(shapeTransform, localNormal)

        local rot = QuatLookAt(worldSnapPos, VecAdd(worldSnapPos, worldNormal))
        rot = QuatRotateQuat(rot, QuatEuler(-90, 0, 0 + Rotation))

        local pos = VecAdd(worldSnapPos, VecScale(worldNormal, 1))
        
        return worldSnapPos, shape, rot, hitPos, pos
    else 
        return nil
    end
end

function drawMenuTitle(w, h)
	UiPush()
	UiTranslate(0, -h)
	UiColor(0, 0, 0, 0.8)
	UiRect(w, h)

	UiAlign("top left")

	UiColor(1, 1, 1, 0.4)
	UiTranslate(8, 8)
	UiFont("bold.ttf", 18)
	UiText("Press 'R' to change or\nHold 'R' and Scroll\nHold 'RMB' to preview")

	UiPop()
end

function drawMenuItem(idx)
	local h = 30
	local model = models[idx]
	UiPush()
	UiTranslate(10, idx * h)
	HasRequiredMaterials = checkPlaceable(idx)
	if not HasRequiredMaterials then
		if CurrentModelIndex == idx then
			UiColor(1, 0.4, 0.4, 1)
		else
			UiColor(1, 0.4, 0.4, 0.2)
		end
	else
		if CurrentModelIndex == idx then
			UiColor(1, 1, 1, 1)
		else
			UiColor(1, 1, 1, 0.2)
		end
	end

	UiFont("bold.ttf", 26)
	-- UiTextShadow(0, 0, 0, 0.5, 0.5)
	UiText(model.name)
	UiPop()
end

function checkPlaceable(CurrentModelIndex)
	local CurrentModel = models[CurrentModelIndex]

	hasrubber = GetInt("inventory.count_rubber") >= CurrentModel.amountrubber
	hassteel = GetInt("inventory.count_steel") >= CurrentModel.amountsteel
	haskevlar = GetInt("inventory.count_kevlar") >= CurrentModel.amountkevlar
	hasscrap = GetInt("inventory.count_scrap") >= CurrentModel.amountscrap
	hasdriftwood = GetInt("inventory.count_driftwood") >= CurrentModel.amountdriftwood
	hasexplosive = GetInt("inventory.count_explosive") >= CurrentModel.amountexplosive

	return GetBool("savegame.mod.infiniteMaterials") or (hasrubber and hassteel and haskevlar and hasscrap and hasdriftwood and hasexplosive)

end

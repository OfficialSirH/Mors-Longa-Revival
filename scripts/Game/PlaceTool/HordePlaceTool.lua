#include "../../../Settings.lua"

Max_Spawn_Dist = 7


function init()

	Init_Settings()

	RegisterTool("placer", "Place Tool", "MOD/vox/placer.vox", 4)
	SetBool("game.tool.placer.enabled", true)

	scroll = false

	models = {}
	table.insert(models, {
		name = "Armor Plate III",
		path = "MOD/scripts/Game/PlaceTool/Placeables/Armor3.xml",
		amountrubber = 0,
		amountsteel = 0,
		amountkevlar = 0,
		amountscrap = 0,
		amountdriftwood = 0,
		amountexplosive = 0,
		amountmoney = 10
	})
	table.insert(models, {
		name = "Armor Plate IV",
		path = "MOD/scripts/Game/PlaceTool/Placeables/Armor4.xml",
		amountrubber = 0,
		amountsteel = 0,
		amountkevlar = 0,
		amountscrap = 0,
		amountdriftwood = 0,
		amountexplosive = 0,
		amountmoney = 20
	})
	table.insert(models, {
		name = "Armor Plate V",
		path = "MOD/scripts/Game/PlaceTool/Placeables/Armor5.xml",
		amountrubber = 0,
		amountsteel = 0,
		amountkevlar = 0,
		amountscrap = 0,
		amountdriftwood = 0,
		amountexplosive = 0,
		amountmoney = 30
	})
	table.insert(models, {
		name = "Sandbag",
		path = "MOD/scripts/Game/PlaceTool/Placeables/Sandbag.xml",
		amountrubber = 0,
		amountsteel = 0,
		amountkevlar = 0,
		amountscrap = 0,
		amountdriftwood = 0,
		amountexplosive = 0,
		amountmoney = 2
	})
	table.insert(models, {
		name = "Ladder",
		path = "MOD/scripts/Game/PlaceTool/Placeables/Driftwood.xml",
		amountrubber = 0,
		amountsteel = 0,
		amountkevlar = 0,
		amountscrap = 0,
		amountdriftwood = 0,
		amountexplosive = 0,
		amountmoney = 50
	})
	table.insert(models, {
		name = "Crate",
		path = "MOD/scripts/Game/PlaceTool/Placeables/Crate.xml",
		amountrubber = 0,
		amountsteel = 0,
		amountkevlar = 0,
		amountscrap = 0,
		amountdriftwood = 0,
		amountexplosive = 0,
		amountmoney = 40
	})
	table.insert(models, {
		name = "Hesco",
		path = "MOD/scripts/Game/PlaceTool/Placeables/Hesco.xml",
		amountrubber = 0,
		amountsteel = 0,
		amountkevlar = 0,
		amountscrap = 0,
		amountdriftwood = 0,
		amountexplosive = 0,
		amountmoney = 250
	})
	table.insert(models, {
		name = "High Wall",
		path = "MOD/scripts/Game/PlaceTool/Placeables/Ballistic Wall High.xml",
		amountrubber = 0,
		amountsteel = 0,
		amountkevlar = 0,
		amountscrap = 0,
		amountdriftwood = 0,
		amountexplosive = 0,
		amountmoney = 500
	})
	table.insert(models, {
		name = "Low Wall",
		path = "MOD/scripts/Game/PlaceTool/Placeables/Ballistic Wall Low.xml",
		amountrubber = 0,
		amountsteel = 0,
		amountkevlar = 0,
		amountscrap = 0,
		amountdriftwood = 0,
		amountexplosive = 0,
		amountmoney = 300
	})
	table.insert(models, {
		name = "Hedgehog",
		path = "MOD/scripts/Game/PlaceTool/Placeables/Hedgehog.xml",
		amountrubber = 0,
		amountsteel = 0,
		amountkevlar = 0,
		amountscrap = 0,
		amountdriftwood = 0,
		amountexplosive = 0,
		amountmoney = 25
	})
	
	currentModelIndex = 1
	currentModel = models[1]

	FlagRotation = Vec(0, 0, 0)

	ManagePreviewModels()
	rotate = 0

end

-- Keep models as non-colliding placement previews.
function ManagePreviewModels()

	local reg_bodies = ""

	for index, model in ipairs(models) do

		if model.preview == nil then -- Check if preview table exists.
			CreateModelPreview(model)
		end

		if not IsHandleValid(model.preview.body) then -- Replace missing model body.
			CreateModelPreview(model)
		end

		-- DebugLine(GetBodyTransform(model.preview.body).pos, GetPlayerTransform().pos, 1,1,0, 1)

		if model == currentModel then
			HideModelPreview(model.preview.body)
		end

		reg_bodies = reg_bodies .. "_" .. model.preview.body

	end

	SetString("level.placetool.preview_bodies", reg_bodies)

end

function CreateModelPreview(model)

	local spawnPos = VecAdd(GetPlayerTransform().pos, Vec(1000,-1000,1000))
	local entities = Spawn(model.path, Transform(spawnPos))

	-- Find body
	for _, entity in ipairs(entities) do

		if HasTag(entity, "GasCan") then
			RemoveTag(entity, "GasCan")
		end

		if GetEntityType(entity) == "body" then -- Create preview object.

			local body = entity

			SetTag(body, "unbreakable")
			SetTag(body, "nodelete")
			SetTag(body, "placetool_preview")

			-- No collide with all.
			for _, shape in ipairs(GetBodyShapes(body)) do
				SetShapeCollisionFilter(shape, 0, 0)
				SetTag(shape, "unbreakable")
				SetTag(shape, "nodelete")
				SetTag(shape, "placetool_preview")
			end

			-- Body bounds used for placement preview transform offset.
			local bbMin, bbMax = GetBodyBounds(body)

			-- Preview object.
			model.preview = {
				body = body,
				bounds = { min = bbMin, max = bbMax }
			}

		end

	end

end


function DisplayModelPreview(modelBody, tr)

	SetBodyTransform(modelBody, tr)
	SetBodyVelocity(modelBody, Vec(0,0,0))
	SetBodyAngularVelocity(modelBody, Vec(0,0,0))
	SetBodyDynamic(modelBody, true)

end

function HideModelPreview(modelBody)

	SetBodyTransform(modelBody, Transform(Vec(1000, -1000, 1000)))
	SetBodyVelocity(modelBody, Vec(0,0,0))
	SetBodyAngularVelocity(modelBody, Vec(0,0,0))

end

function tick(dt)
	Money = GetString("savegame.mod.player.money")
	ManagePreviewModels()

	if GetString("game.player.tool") == "placer" then
		if GetBool("game.player.canusetool") then

			FlagRotation[1] = FlagRotation[1] + InputValue("camerax") * 2
			FlagRotation = VecLerp(FlagRotation, Vec(0, 0, 0), 0.1)

			SetToolTransform(Transform(Vec(0.25, -0.25, -0.4), QuatEuler(0, FlagRotation[1], -10)))


			-- if InputDown("grab") then

				for _, model in ipairs(models) do
					QueryRejectBody(model.preview.body)
				end
				local t = GetCameraTransform()
				local dir = TransformToParentVec(t, Vec(0, 0, -1))
				local hit, dist, normal, shape = QueryRaycast(t.pos, dir, 100)
				if hit then

					SetBool("hud.aimdot", false)

					local hitpoint = VecAdd(t.pos, VecScale(dir, dist))


					local hp = VecAdd(hitpoint, normal)
					local rot = QuatLookAt(hitpoint, hp)
					rot = QuatRotateQuat(rot, QuatEuler(-90, 0, 0+rotate))

					if currentModel.name == "Flag Small"
							or currentModel.name == "Flag Normal"
							or currentModel.name == "Flag Big"
					then
						local hp2 = VecSub(hitpoint, dir)
						local rot2 = QuatLookAt(hitpoint, hp2)
						local rx, ry, rz = GetQuatEuler(rot2)
						rot = QuatRotateQuat(rot, QuatEuler(0, ry+rotate, 0))
					end

					local within_bounds = VecDist(GetPlayerTransform().pos, hitpoint) <= Max_Spawn_Dist
					local pos = VecAdd(hitpoint, VecScale(normal, 1))

					-- Spawn and place model body.
					HasRequiredMaterials = checkPlaceable(currentModelIndex)
					if HasRequiredMaterials and within_bounds and not HasTag(GetShapeBody(shape), "gore_id")  then

							DisplayModelPreview(currentModel.preview.body, Transform(hitpoint, rot))
							DrawBodyOutline(currentModel.preview.body, 0, 1, 0, 1)
							DrawLine(hitpoint, pos, 0, 1, 0, 1)

							if InputDown("rmb") then
								rotate = rotate + 1
							end
							if InputDown("rmb") and InputDown("shift") then
								rotate = rotate + 5
							end

							if InputPressed("usetool") then

								HideModelPreview(currentModel.preview.body)

								local items = Spawn(currentModel.path, Transform(hitpoint, rot), false, true)
								SetString(
									"savegame.mod.player.money", 
									Money - currentModel.amountmoney)
							end

					else

						if within_bounds then
							DisplayModelPreview(currentModel.preview.body, Transform(hitpoint, rot))
							DrawBodyOutline(currentModel.preview.body, 1, 0, 0, 1)
							DrawBodyHighlight(currentModel.preview.body, 0.2)
							DrawLine(hitpoint, pos, 1, 0, 0, 1)
						end

					end
				end

			else

				HideModelPreview(currentModel.preview.body)

			end
		end
	-- end
end



function draw()

	UiTranslate(390, -10)

	if GetString("game.player.tool") == "placer" then
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
			{ name = "Money", invAmt = GetInt("savegame.mod.player.money"), needed =  currentModel.amountmoney }
		}

		UiPush()

			local count = 0
			for index, mat in ipairs(matInv) do
					count = count + 1
			end

			UiColor(0, 0, 0, 0.7)
			UiRect(200, marginY*count)

		UiPop()

		for index, mat in ipairs(matInv) do
			if mat.needed > 0 then
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
	if KeybindDown(Settings.keybinds.player.placetool_Scroll) then
		UiMakeInteractive()
		if InputValue("mousewheel") ~= 0 then
			if InputValue("mousewheel") > 0 then
				currentModelIndex = currentModelIndex - 1
				scroll = true
				UiSound("clickup.ogg")
			end
			if InputValue("mousewheel") < 0 then
				currentModelIndex = currentModelIndex + 1
				scroll = true
				UiSound("clickup.ogg")
			end
			if currentModelIndex > #models then
				currentModelIndex = 1
			end
			if currentModelIndex < 1 then
				currentModelIndex = #models
			end
			currentModel = models[currentModelIndex]
		end
	end

	if KeybindReleased(Settings.keybinds.player.placetool_Scroll) and not scroll then
		UiSound("clickup.ogg")
		currentModelIndex = currentModelIndex + 1
		if currentModelIndex > #models then
			currentModelIndex = 1
		end
		currentModel = models[currentModelIndex]
	end

	if KeybindReleased(Settings.keybinds.player.placetool_Scroll) and scroll then
		scroll = false
	end

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
		if currentModelIndex == idx then
			UiColor(1, 0.4, 0.4, 1)
		else
			UiColor(1, 0.4, 0.4, 0.2)
		end
	else
		if currentModelIndex == idx then
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

function checkPlaceable(currentModelIndex)
	local currentModel = models[currentModelIndex]

	hasrubber = GetInt("inventory.count_rubber") >= currentModel.amountrubber
	hassteel = GetInt("inventory.count_steel") >= currentModel.amountsteel
	haskevlar = GetInt("inventory.count_kevlar") >= currentModel.amountkevlar
	hasscrap = GetInt("inventory.count_scrap") >= currentModel.amountscrap
	hasdriftwood = GetInt("inventory.count_driftwood") >= currentModel.amountdriftwood
	hasexplosive = GetInt("inventory.count_explosive") >= currentModel.amountexplosive
	hasmoney = GetInt("savegame.mod.player.money") >= currentModel.amountmoney
	return hasrubber and hassteel and haskevlar and hasscrap and hasdriftwood and hasexplosive and hasmoney

end




function handleCommand(cmd) handle_quickload(cmd) end
function handle_quickload(cmd)
	for _, word in ipairs(splitString(cmd, " ")) do
		if word == "quickload" then
			Init_Settings()
		end
		break
	end
end
#version 2
#include "script/include/player.lua"
-- (v2) horde place tool, per player (client: aim, money, menu; server: preview bodies, spawning).
#include "../../../Settings.lua"

Max_Spawn_Dist = 7


-- (v2) the placeable list, used by both server and client
function DefineModels()

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
	
end

-- (v2) Place tool, per player.
--   client: tool pose, aim raycast, placement rules, money (own savegame), menu. Sends its preview pose to the
--     server when it changes (server.placerPreview) and places with server.placerPlace.
--   server: one preview body per player (spawned far away, no collision), moved to that player's pose; spawns placed
--     items. shared.placer[tostring(player)] = preview body (clients outline it and ignore all previews in their
--     raycast). level.placetool.preview_bodies lists every preview body for GoreNPCs (it ignores them).

PREVIEW_HIDDEN = Vec(1000, -1000, 1000)

------------------------------------------------------------------ server

function server.init()
	DefineModels()
	RegisterTool("placer", "Place Tool", "MOD/vox/placer.vox", 4)
	SetBool("game.tool.placer.enabled", true)
	for p in Players() do SetToolEnabled("placer", true, p) end
	Previews = {}
	shared.placer = {}
end

function server.tick(dt)
	for p in PlayersAdded() do SetToolEnabled("placer", true, p) end
	for p in PlayersRemoved() do PlacerRemovePreview(p) end
	local reg = ""
	for p, pv in pairs(Previews) do
		if IsHandleValid(pv.body) then
			reg = reg .. "_" .. pv.body
		else
			PlacerRemovePreview(p)
		end
	end
	SetString("level.placetool.preview_bodies", reg)
end

function PlacerRemovePreview(p)
	local pv = Previews[p]
	if pv then
		for _, e in ipairs(pv.entities) do
			if IsHandleValid(e) then Delete(e) end
		end
	end
	Previews[p] = nil
	shared.placer[tostring(p)] = nil
end

-- non-colliding, unbreakable copy of the model (v1 CreateModelPreview)
function CreateModelPreview(model)

	local entities = Spawn(model.path, Transform(PREVIEW_HIDDEN))
	local preview = nil

	for _, entity in ipairs(entities) do

		if HasTag(entity, "GasCan") then
			RemoveTag(entity, "GasCan")
		end

		if GetEntityType(entity) == "body" and not preview then

			local body = entity

			SetTag(body, "unbreakable")
			SetTag(body, "nodelete")
			SetTag(body, "placetool_preview")

			for _, shape in ipairs(GetBodyShapes(body)) do
				SetShapeCollisionFilter(shape, 0, 0)
				SetTag(shape, "unbreakable")
				SetTag(shape, "nodelete")
				SetTag(shape, "placetool_preview")
			end

			preview = { body = body, entities = entities }

		end

	end

	if not preview then
		for _, e in ipairs(entities) do Delete(e) end
	end
	return preview

end

function DisplayModelPreview(modelBody, tr)

	SetBodyTransform(modelBody, tr)
	SetBodyVelocity(modelBody, Vec(0,0,0))
	SetBodyAngularVelocity(modelBody, Vec(0,0,0))
	SetBodyDynamic(modelBody, true)

end

function HideModelPreview(modelBody)

	SetBodyTransform(modelBody, Transform(PREVIEW_HIDDEN))
	SetBodyVelocity(modelBody, Vec(0,0,0))
	SetBodyAngularVelocity(modelBody, Vec(0,0,0))

end

--- index 0 = the player put the tool away. show + pose = where the preview goes.
function server.placerPreview(p, index, show, x, y, z, qx, qy, qz, qw)
	index = tonumber(index) or 0
	if index < 1 or not models[index] then
		PlacerRemovePreview(p)
		return
	end
	local pv = Previews[p]
	if not pv or pv.index ~= index or not IsHandleValid(pv.body) then
		PlacerRemovePreview(p)
		pv = CreateModelPreview(models[index])
		if not pv then return end
		pv.index = index
		Previews[p] = pv
		shared.placer[tostring(p)] = pv.body
	end
	if show then
		DisplayModelPreview(pv.body, Transform(Vec(x, y, z), Quat(qx, qy, qz, qw)))
	else
		HideModelPreview(pv.body)
	end
end

--- the client already checked distance + money and paid (client-trusted, as all money in this port)
function server.placerPlace(p, index, x, y, z, qx, qy, qz, qw)
	local model = models[tonumber(index) or 0]
	if not model then return end
	Spawn(model.path, Transform(Vec(x, y, z), Quat(qx, qy, qz, qw)), false, true)
	if Previews[p] then HideModelPreview(Previews[p].body) end
end

------------------------------------------------------------------ client

function client.init()

	Init_Settings()
	DefineModels()

	scroll = false
	currentModelIndex = 1
	currentModel = models[1]

	FlagRotation = Vec(0, 0, 0)
	rotate = 0
	PlacerSentSig = nil

end

local function sendPreview(index, show, tr)
	local sig
	if show then
		local p, r = tr.pos, tr.rot
		sig = string.format("%d/%.2f/%.2f/%.2f/%.3f/%.3f/%.3f/%.3f", index, p[1], p[2], p[3], r[1], r[2], r[3], r[4])
	else
		sig = index .. "/hidden"
	end
	if sig == PlacerSentSig then return end
	PlacerSentSig = sig
	if show then
		ServerCall("server.placerPreview", GetLocalPlayer(), index, true, tr.pos[1], tr.pos[2], tr.pos[3],
			tr.rot[1], tr.rot[2], tr.rot[3], tr.rot[4])
	else
		ServerCall("server.placerPreview", GetLocalPlayer(), index, false)
	end
end

function client.tick(dt)

	if GetPlayerTool() ~= "placer" or GetPlayerVehicle() ~= 0 then
		if PlacerSentSig ~= nil then
			PlacerSentSig = nil
			ServerCall("server.placerPreview", GetLocalPlayer(), 0, false) -- tool put away: drop my preview
		end
		return
	end

	local previewBody = shared.placer and shared.placer[tostring(GetLocalPlayer())]

	FlagRotation[1] = FlagRotation[1] + InputValue("camerax") * 2
	FlagRotation = VecLerp(FlagRotation, Vec(0, 0, 0), 0.1)

	SetToolTransform(Transform(Vec(0.25, -0.25, -0.4), QuatEuler(0, FlagRotation[1], -10)))

	for _, body in pairs(shared.placer or {}) do
		QueryRejectBody(body)
	end
	local t = GetCameraTransform()
	local dir = TransformToParentVec(t, Vec(0, 0, -1))
	local hit, dist, normal, shape = QueryRaycast(t.pos, dir, 100)
	if not hit then
		sendPreview(currentModelIndex, false)
		return
	end

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
	local tr = Transform(hitpoint, rot)

	HasRequiredMaterials = checkPlaceable(currentModelIndex)
	local valid = previewBody and IsHandleValid(previewBody)
	if HasRequiredMaterials and within_bounds and not HasTag(GetShapeBody(shape), "gore_id") then

		sendPreview(currentModelIndex, true, tr)
		if valid then DrawBodyOutline(previewBody, 0, 1, 0, 1) end
		DrawLine(hitpoint, pos, 0, 1, 0, 1)

		if InputDown("rmb") then
			rotate = rotate + 1
		end
		if InputDown("rmb") and InputDown("shift") then
			rotate = rotate + 5
		end

		if InputPressed("usetool") then
			-- (v2 fix) v1 used Get/SetString on this int key
			SetInt("savegame.mod.player.money", GetInt("savegame.mod.player.money") - currentModel.amountmoney)
			ServerCall("server.placerPlace", GetLocalPlayer(), currentModelIndex, tr.pos[1], tr.pos[2], tr.pos[3],
				tr.rot[1], tr.rot[2], tr.rot[3], tr.rot[4])
			sendPreview(currentModelIndex, false)
		end

	elseif within_bounds then

		sendPreview(currentModelIndex, true, tr)
		if valid then
			DrawBodyOutline(previewBody, 1, 0, 0, 1)
			DrawBodyHighlight(previewBody, 0.2)
		end
		DrawLine(hitpoint, pos, 1, 0, 0, 1)

	else

		sendPreview(currentModelIndex, false)

	end

end



function client.draw()

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




-- (v2) v1 quickload hook (re-read the settings) dropped: no client-side handleCommand in v2
function handle_quickload(cmd)
	for _, word in ipairs(splitString(cmd, " ")) do
		if word == "quickload" then
			Init_Settings()
		end
		break
	end
end
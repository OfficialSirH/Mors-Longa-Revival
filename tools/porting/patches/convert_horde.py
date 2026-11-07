#!/usr/bin/env python3
"""Phase 3: horde mode (level_horde.xml, "Gladiator" on the character select) v1 -> v2.

* Procedural/WaveHandler.lua: waves run on the server. Wave number / countdown / "last enemies" outline go to every
  client through shared.horde (v1 wrote the host's savegame and drew outlines from tick); the wave prize goes to every
  player's own money (client savegame, as all money in this port); each player starts with 500.
* scripts/Game/PlaceTool/HordePlaceTool.lua: the place tool, per player. Client: tool pose, aim, placement rules,
  money, menu. Server: one non-colliding preview body per player, moved to the pose the client sends; spawns what
  is placed. v1 moved shared preview bodies from tick (world changes are server-only in v2).

Usage (repo root): python3 tools/porting/patches/convert_horde.py   (rebuilds both files from git HEAD, v1 there)
"""
import os, subprocess, sys
sys.path.insert(0, os.path.dirname(__file__))
from convert_server import convert

WAVE = "Procedural/WaveHandler.lua"
PLACE = "scripts/Game/PlaceTool/HordePlaceTool.lua"

WAVE_EDITS = [
    ('SetInt("savegame.mod.player.money", 500)\nSetBool("level.horde.enabled", true)\nSetBool("savegame.mod.inventory.init", true)\n',
     'SetBool("level.horde.enabled", true)\n'
     '-- (v2) start money and the inventory reset are per player: client.init below\n'
     'HordeOngoing = false\n'),
    ("function tick(dt)\n", "function HordeTick(dt) -- (v2) called by server.tick\n"),
    ('\tSetInt("savegame.mod.player.current.wave", Wave)\n\tSetInt("savegame.mod.player.current.wave.time", NextWaveTime)\n',
     "\tHordeOutline = {} -- (v2) wave UI values go to the clients: HordePublish\n"),
    ('\tMoney = GetInt("savegame.mod.player.money")\n', ""),
    ("\t\t\t\tDrawBodyOutline(Torsos[i], 0, 1, 0, 1)\n",
     "\t\t\t\tHordeOutline[#HordeOutline + 1] = Torsos[i] -- (v2) outlined by every client (client.tick)\n"),
    ('\t\t\tdone = false\n\t\t\tSetBool("level.horde.ongoing.enabled", true)\n',
     "\t\t\tdone = false\n\t\t\tHordeOngoing = true\n"),
    ("\t\tDebugPrint(CurrentPart)\n\t\tDebugPrint(#Torsos)\n\t\tDebugPrint(NextWaveTime)\n",
     "\t\t-- (v2) removed v1 leftover DebugPrint(CurrentPart / #Torsos / NextWaveTime): printed on screen every frame\n"),
    ('\t\t\t\tSetInt("savegame.mod.player.money", Money + 100 * Wave)\n\t\t\t\tSetBool("inventory.refreshshop", true)\n'
     '\t\t\t\tSetBool("level.horde.ongoing.enabled", true)\n',
     '\t\t\t\tClientCall(0, "client.hordeReward", 100 * Wave) -- (v2) every player\'s own money\n'
     "\t\t\t\t-- (v2 fix) v1 set \"ongoing\" to true here too, so the countdown to the next wave never showed\n"
     "\t\t\t\tHordeOngoing = false\n"),
    ("\nfunction draw()\n\n\n\n\n\nend\n", "\n"),
]

WAVE_APPEND = """
-- (v2) server: run the wave logic, then publish what the clients show (only when it changed)
function server.tick(dt)
	HordeTick(dt)
	HordePublish()
end

function HordePublish()
	local outline = HordeOutline or {}
	local time = math.max(0, math.floor(NextWaveTime))
	local sig = Wave .. "/" .. time .. "/" .. tostring(HordeOngoing) .. "/" .. table.concat(outline, ",")
	if sig ~= HordeSig then
		HordeSig = sig
		shared.horde = { wave = Wave, time = time, ongoing = HordeOngoing and true or false, outline = outline }
	end
end

-- (v2) client: every player starts the horde with 500 money and a fresh inventory (v1: the host's savegame only)
function client.init()
	SetInt("savegame.mod.player.money", 500)
	SetBool("savegame.mod.inventory.init", true)
	SetBool("level.horde.enabled", true)
end

-- (v2) the health overlay (UiHealthOverlay_Draw.lua) reads the wave UI from these local keys, as in v1
function client.tick(dt)
	local h = shared.horde
	if not h then return end
	SetInt("savegame.mod.player.current.wave", h.wave or 0)
	SetInt("savegame.mod.player.current.wave.time", h.time or 0)
	SetBool("level.horde.ongoing.enabled", h.ongoing and true or false)
	for _, torso in ipairs(h.outline or {}) do
		if IsHandleValid(torso) then DrawBodyOutline(torso, 0, 1, 0, 1) end
	end
end

-- (v2) wave cleared: the prize goes to every player's own money; the shop refreshes
function client.hordeReward(amount)
	SetInt("savegame.mod.player.money", GetInt("savegame.mod.player.money") + amount)
	SetBool("inventory.refreshshop", true)
end
"""

PLACE_SERVER_CLIENT = """-- (v2) Place tool, per player.
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



"""

PLACE_EDITS = [
    ('function init()\n\n\tInit_Settings()\n\n\tRegisterTool("placer", "Place Tool", "MOD/vox/placer.vox", 4)\n'
     '\tSetBool("game.tool.placer.enabled", true)\n\n\tscroll = false\n\n\tmodels = {}\n',
     "-- (v2) the placeable list, used by both server and client\nfunction DefineModels()\n\n\tmodels = {}\n"),
    ("\tcurrentModelIndex = 1\n\tcurrentModel = models[1]\n\n\tFlagRotation = Vec(0, 0, 0)\n\n\tManagePreviewModels()\n"
     "\trotate = 0\n\nend\n", "end\n"),
    ("function draw()\n", "function client.draw()\n"),
    ("function handleCommand(cmd) handle_quickload(cmd) end\n",
     "-- (v2) v1 quickload hook (re-read the settings) dropped: no client-side handleCommand in v2\n"),
]
PLACE_BLOCK_START = "-- Keep models as non-colliding placement previews.\n"
PLACE_BLOCK_END = "function draw()\n"


def head(path):
    return subprocess.run(["git", "show", "HEAD:" + path], capture_output=True, check=True).stdout.decode("utf-8")


def write(path, text):
    open(path, "wb").write(text.replace("\r\n", "\n").replace("\n", "\r\n").encode("utf-8"))


def main():
    write(WAVE, head(WAVE))
    convert(WAVE, WAVE_EDITS, "horde waves (server); wave UI, outlines and prize money on every client.", {"init": "server"})
    t = open(WAVE, "rb").read().decode("utf-8").replace("\r\n", "\n")
    write(WAVE, t.rstrip("\n") + "\n" + WAVE_APPEND)

    t = head(PLACE).replace("\r\n", "\n")
    a, z = t.index(PLACE_BLOCK_START), t.index(PLACE_BLOCK_END)
    write(PLACE, t)
    edits = [(t[a:z], PLACE_SERVER_CLIENT)] + PLACE_EDITS
    convert(PLACE, edits, "horde place tool, per player (client: aim, money, menu; server: preview bodies, spawning).", {})


if __name__ == "__main__":
    main()

--================================================================
-- gunnet.lua  (Mors Longa Revival)
--
-- Networking layer for #version 2 gun scripts.
--
-- Model (co-op, so the shooting client is trusted with its own gun state):
--  * The client that holds the gun runs all of the gun "feel" logic exactly
--    as before (input, ammo, recoil, ADS, reload, viewmodel, HUD).
--  * When it fires, the projectile is simulated twice by ProjectileOperations
--    (gunfunctions.lua):
--      - on the shooting client and every other client for visuals/sound
--        only (doWorld = false)
--      - on the server for world effects only (doFx = false): holes,
--        impulses, NPC damage, explosions, fire, blood paint.
--  * Everything else that is server-only (melee holes, spent casings,
--    forcing the selected tool) goes through the small requests below.
--
-- Include from a v2 gun script AFTER gunfunctions.lua, and call
-- GunNet_ServerInit() from server.init(), GunNet_ServerTick(dt) from
-- server.tick(dt) and GunNet_ClientTick(dt) from client.tick(dt).
--================================================================

local GUNNET_MAX_SHELLS = 400

-- Fields of a shell that are sent over the network. Keep this small.
local SHELL_FIELDS = {
	"armor", "damage", "pdamage", "explosive", "incendiary", "tracer",
	"velocity", "maxmomentum", "bloodamount", "momentum", "pos",
	"predictedBulletVelocity", "factor",
}

local function GunNet_PackShell(shell)
	local data = {}
	for i = 1, #SHELL_FIELDS do
		local k = SHELL_FIELDS[i]
		data[k] = shell[k]
	end
	return data
end

local function GunNet_UnpackShell(data, owner, doWorld, doFx)
	local shell = {}
	for k, v in pairs(data) do shell[k] = v end
	shell.pos = VecCopy(data.pos)
	shell.predictedBulletVelocity = VecCopy(data.predictedBulletVelocity)
	shell.active = true
	shell.owner = owner
	shell.doWorld = doWorld
	shell.doFx = doFx
	return shell
end

local function GunNet_AddShell(list, shell)
	if #list >= GUNNET_MAX_SHELLS then table.remove(list, 1) end
	list[#list + 1] = shell
end

local function GunNet_StepList(list, operation)
	local i = 1
	while i <= #list do
		local shell = list[i]
		if shell.active then operation(shell) end
		if shell.active then i = i + 1 else table.remove(list, i) end
	end
end

------------------------------------------------------------------
-- Server
------------------------------------------------------------------

function GunNet_ServerInit()
	server.gunShells = {}
	server.gunGrenades = {}
end

function GunNet_ServerTick(dt)
	GunNet_StepList(server.gunShells, ProjectileOperations)
	GunNet_StepList(server.gunGrenades, GrenadeOperations)
end

-- A client fired a bullet. Simulate it for world effects and tell the other
-- clients so they can draw it and hear it.
function server.gunFire(playerId, data, soundPath, volume)
	GunNet_AddShell(server.gunShells, GunNet_UnpackShell(data, playerId, true, false))
	ClientCall(0, "client.gunRemoteFire", playerId, data, soundPath, volume)
end

function server.gunFireGrenade(playerId, data)
	GunNet_AddShell(server.gunGrenades, GunNet_UnpackShell(data, playerId, true, false))
	ClientCall(0, "client.gunRemoteGrenade", playerId, data)
end

function server.gunMakeHole(pos, r0, r1, r2)
	MakeHole(pos, r0, r1 or 0, r2 or 0)
end

-- Spawns a prefab (spent casing, RPG rocket, ...) and gives all its bodies a velocity.
function server.gunSpawnCasing(xml, transform, velocity)
	local entities = Spawn(xml, transform)
	for i = 1, #entities do
		if GetEntityType(entities[i]) == "body" then SetBodyVelocity(entities[i], velocity) end
	end
end

-- The tool body is owned by the server, so the weapon model (prefab parts
-- attached to the tool body) is built there; it then replicates to everyone.
function server.gunLoadTool(playerId, prefab)
	local body = GetToolBody(playerId)
	if body ~= 0 then LoadTool(body, prefab) end
end

function server.gunSetTool(playerId, toolId)
	SetPlayerTool(toolId, playerId)
end

------------------------------------------------------------------
-- Client
------------------------------------------------------------------

client.gunShells = {}
client.gunGrenades = {}

function GunNet_ClientTick(dt)
	GunNet_StepList(client.gunShells, ProjectileOperations)
	GunNet_StepList(client.gunGrenades, GrenadeOperations)
	-- Debug: Ctrl+O toggles part index labels on the held gun (see GunNet_DebugParts).
	if InputDown("ctrl") and InputPressed("o") then client.gunDebugParts = not client.gunDebugParts end
	-- Ctrl+L toggles a table of every part's local transform (position, size, rotation).
	if InputDown("ctrl") and InputPressed("l") then client.gunDebugTable = not client.gunDebugTable end
end

local function gunNetFmt(v) return string.format("%6.2f", v) end

function GunNet_DebugTable()
	if not client.gunDebugTable then return end
	local b = GetToolBody()
	if b == 0 then return end
	local shapes = GetBodyShapes(b)
	UiPush()
	UiFont("regular.ttf", 15)
	UiAlign("left top")
	UiColor(0, 0, 0, 0.75)
	UiTranslate(10, 60)
	UiRect(UiWidth() - 20, 24 * 17 + 20)
	UiColor(1, 1, 0.3)
	UiTranslate(8, 6)
	for i = 1, #shapes do
		local t = GetShapeLocalTransform(shapes[i])
		local sx, sy, sz, sc = GetShapeSize(shapes[i])
		local rx, ry, rz = GetQuatEuler(t.rot)
		local col, row = math.floor((i - 1) / 24), (i - 1) % 24
		UiPush()
		UiTranslate(col * 640, row * 17)
		UiText(string.format("%2d  p %s %s %s  s %dx%dx%d@%.3f  r %d %d %d", i,
			gunNetFmt(t.pos[1]), gunNetFmt(t.pos[2]), gunNetFmt(t.pos[3]), sx, sy, sz, sc,
			math.floor(rx + 0.5), math.floor(ry + 0.5), math.floor(rz + 0.5)))
		UiPop()
	end
	UiPop()
end

-- Tool prefabs from tools/porting/make_tool_prefab.py build each part in its own
-- lane on a grid (part i: x += lane_x(i), y += lane_y(i)) so no two parts overlap
-- while the engine builds the tool (overlapping parts lose voxels). Move them back.
-- Decided per part: a part is moved back only while it is still in its lane (real
-- part positions are within +-SPACING/2 of the gun), so parts the gun script
-- already moved or hid, and parts fixed earlier, are left alone.
-- Keep SPACING/COLUMNS in sync with tools/porting/make_tool_prefab.py.
GUN_TOOL_PART_SPACING = 24.0
GUN_TOOL_PART_COLUMNS = 10
function GunNet_FixToolParts(shapes)
	for i = 1, #shapes do
		local t = GetShapeLocalTransform(shapes[i])
		local laneX = ((i - 1) % GUN_TOOL_PART_COLUMNS + 1) * GUN_TOOL_PART_SPACING
		local laneY = math.floor((i - 1) / GUN_TOOL_PART_COLUMNS) * GUN_TOOL_PART_SPACING
		if math.abs(t.pos[1] - laneX) < GUN_TOOL_PART_SPACING * 0.5 then
			t.pos = VecSub(t.pos, Vec(laneX, laneY, 0))
			SetShapeLocalTransform(shapes[i], t)
		end
	end
end

-- Debug overlay: draws the index of every part of the local player's tool body
-- (the index the gun scripts use: GetBodyShapes(GetToolBody())[i]). Call from client.draw().
function GunNet_DebugParts()
	GunNet_DebugTable()
	if not client.gunDebugParts then return end
	local b = GetToolBody()
	if b == 0 then return end
	local shapes = GetBodyShapes(b)
	UiPush()
	UiFont("bold.ttf", 18)
	UiAlign("center middle")
	UiTextOutline(0, 0, 0, 1, 0.2)
	for i = 1, #shapes do
		local mi, ma = GetShapeBounds(shapes[i])
		local x, y, dist = UiWorldToPixel(VecLerp(mi, ma, 0.5))
		if dist > 0 and dist < 10 then
			UiPush()
			UiTranslate(x, y)
			UiColor(1, 1, 0)
			UiText(tostring(i))
			UiPop()
		end
	end
	UiColor(1, 1, 0)
	UiTranslate(UiCenter(), 40)
	UiText("Part debug (Ctrl+O): " .. #shapes .. " parts on tool body")
	UiPop()
end

-- Called by the gun when the local player fires a bullet.
-- `shell` is the fully set up shell table (see the gun's FireRound()).
-- soundPath is the sound file remote players hear (sound handles are local
-- to each machine, so the path is sent instead).
function GunNet_Fire(shell, soundPath, volume)
	local data = GunNet_PackShell(shell)
	GunNet_AddShell(client.gunShells, GunNet_UnpackShell(data, GetLocalPlayer(), false, true))
	ServerCall("server.gunFire", GetLocalPlayer(), data, soundPath, volume)
end

function GunNet_FireGrenade(shell)
	local data = GunNet_PackShell(shell)
	GunNet_AddShell(client.gunGrenades, GunNet_UnpackShell(data, GetLocalPlayer(), false, true))
	ServerCall("server.gunFireGrenade", GetLocalPlayer(), data)
end

function GunNet_MakeHole(pos, r0, r1, r2)
	ServerCall("server.gunMakeHole", pos, r0, r1 or 0, r2 or 0)
end

function GunNet_SpawnCasing(xml, transform, velocity)
	ServerCall("server.gunSpawnCasing", xml, transform, velocity)
end

function GunNet_LoadTool(prefab)
	ServerCall("server.gunLoadTool", GetLocalPlayer(), prefab)
end

-- Force the local player's selected tool (used to lock the gun while reloading).
function GunNet_SetTool(toolId)
	if GetPlayerTool() ~= toolId then
		ServerCall("server.gunSetTool", GetLocalPlayer(), toolId)
	end
end

-- Another player fired: draw the bullet and play the shot at their position.
local gunNetSounds = {}
function client.gunRemoteFire(playerId, data, soundPath, volume)
	if IsPlayerLocal(playerId) then return end
	GunNet_AddShell(client.gunShells, GunNet_UnpackShell(data, playerId, false, true))
	-- One sound per shot: shotguns send one shell per pellet in the same frame.
	client.gunLastRemoteSound = client.gunLastRemoteSound or {}
	local now = GetTime()
	if soundPath and soundPath ~= "" and (client.gunLastRemoteSound[playerId] or -1) < now - 0.02 then
		client.gunLastRemoteSound[playerId] = now
		gunNetSounds[soundPath] = gunNetSounds[soundPath] or LoadSound(soundPath)
		PlaySound(gunNetSounds[soundPath], data.pos, volume or 0.7)
	end
end

function client.gunRemoteGrenade(playerId, data)
	if IsPlayerLocal(playerId) then return end
	GunNet_AddShell(client.gunGrenades, GunNet_UnpackShell(data, playerId, false, true))
end

------------------------------------------------------------------
-- Other players' guns (MP 2026-11-14)
------------------------------------------------------------------
-- The gun scripts place, animate and hide the parts of the LOCAL player's tool body only (client-side
-- SetShapeLocalTransform; see GunNet_FixToolParts), so the other machines showed the raw tool prefab: every part
-- still in its build lane (tools/porting/make_tool_prefab.py), arms included. Now the holder's machine sends its
-- parts' local transforms (only the changed ones, at most GUNNET_PARTS_RATE apart, all of them every
-- GUNNET_PARTS_FULL seconds and on a tool change) and every other machine applies them to that player's tool body
-- each frame, as the official snowball tool does with its tool (data/script/snowball.lua client.render). The
-- first-person arms and hands (the gun script's hand1 / hand2 / arm1 / arm2) are hidden on the other machines:
-- the player's character holds the gun there.
-- Uses the gun script's global `body` (its tool body while it is the held tool), so only the script of the held
-- gun sends; the ClientCall reaches the same gun script on the other machines.

GUNNET_PARTS_RATE = 0.1
GUNNET_PARTS_FULL = 2.0

client.gunPartsSent = {}     -- [part index] = what was last sent for it
client.gunPartsNext = 0
client.gunPartsFull = 0
client.gunPartsTool = nil
client.gunRemoteParts = {}   -- [player] = { tool = id, parts = { [i] = Transform }, hidden = { [i] = true } }

local function gunNetPartStr(t)
	return string.format("%.3f,%.3f,%.3f,%.4f,%.4f,%.4f,%.4f",
		t.pos[1], t.pos[2], t.pos[3], t.rot[1], t.rot[2], t.rot[3], t.rot[4])
end

-- "i=x,y,z,qx,qy,qz,qw;..." plus "|h=i,i,i" (hidden parts)
function GunNet_PackParts(shapes, sent, full, hiddenSet)
	local out, changed = {}, false
	for i = 1, #shapes do
		local s = gunNetPartStr(GetShapeLocalTransform(shapes[i]))
		if full or sent[i] ~= s then
			out[#out + 1] = i .. "=" .. s
			sent[i] = s
			changed = true
		end
	end
	local h = {}
	for i in pairs(hiddenSet) do h[#h + 1] = i end
	table.sort(h)
	return changed, table.concat(out, ";") .. "|h=" .. table.concat(h, ",")
end

function GunNet_UnpackParts(data, entry)
	local partsStr, hiddenStr = data:match("^(.-)|h=(.*)$")
	for i, x, y, z, a, b, c, d in (partsStr or ""):gmatch("(%d+)=([^,;]+),([^,;]+),([^,;]+),([^,;]+),([^,;]+),([^,;]+),([^,;]+)") do
		entry.parts[tonumber(i)] = Transform(Vec(tonumber(x), tonumber(y), tonumber(z)),
			Quat(tonumber(a), tonumber(b), tonumber(c), tonumber(d)))
	end
	entry.hidden = {}
	for i in (hiddenStr or ""):gmatch("%d+") do entry.hidden[tonumber(i)] = true end
end

function GunNet_SendParts()
	local b = GetToolBody()
	if b == 0 or b ~= body then return end
	local shapes = GetBodyShapes(b)
	if #shapes <= 8 then return end   -- still being built
	local now = GetTime()
	local tool = GetPlayerTool()
	local full = tool ~= client.gunPartsTool or now >= client.gunPartsFull
	if not full and now < client.gunPartsNext then return end
	if full then
		client.gunPartsSent = {}
		client.gunPartsFull = now + GUNNET_PARTS_FULL
		client.gunPartsTool = tool
	end
	local hidden, index = {}, {}
	for i = 1, #shapes do index[shapes[i]] = i end
	for _, h in pairs({ hand1, hand2, arm1, arm2 }) do   -- pairs: any of them may be nil
		if h and index[h] then hidden[index[h]] = true end
	end
	local changed, data = GunNet_PackParts(shapes, client.gunPartsSent, full, hidden)
	if changed then
		client.gunPartsNext = now + GUNNET_PARTS_RATE
		ServerCall("server.gunParts", GetLocalPlayer(), tool, full, data)
	end
end

function server.gunParts(playerId, tool, full, data)
	ClientCall(0, "client.gunParts", playerId, tool, full, data)
end

function client.gunParts(playerId, tool, full, data)
	if IsPlayerLocal(playerId) then return end
	local entry = client.gunRemoteParts[playerId]
	if full or not entry or entry.tool ~= tool then
		entry = { tool = tool, parts = {}, hidden = {} }
		client.gunRemoteParts[playerId] = entry
	end
	GunNet_UnpackParts(data, entry)
end

function GunNet_ApplyRemoteParts()
	for p in Players() do
		local entry = client.gunRemoteParts[p]
		if entry and not IsPlayerLocal(p) and GetPlayerTool(p) == entry.tool then
			local b = GetToolBody(p)
			if b ~= 0 then
				local shapes = GetBodyShapes(b)
				for i, t in pairs(entry.parts) do
					if shapes[i] then SetShapeLocalTransform(shapes[i], t) end
				end
				for i = 1, #shapes do
					if entry.hidden[i] then SetTag(shapes[i], "invisible") end
				end
			end
		end
	end
	for p in PlayersRemoved() do client.gunRemoteParts[p] = nil end
end

-- After the gun scripts' client.tick (where they move the local parts), before rendering.
function client.render(dt)
	GunNet_SendParts()
	GunNet_ApplyRemoteParts()
end

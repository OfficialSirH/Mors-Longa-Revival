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
	-- (2026-11-14) the server's copy of each bullet (holes, NPC damage) fell with the global `gravity`, which the gun
	-- scripts set only in client.init / ProjectileHandlerInit: nil on the server, so it flew without drop while every
	-- client's tracer fell. Every gunnet gun uses (0, -10, 0) there.
	if gravity == nil then gravity = Vec(0, -10, 0) end
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
-- (2026-11-15, user OK) Spent casings (*casing.xml) are capped: only the newest CASING_CAP stay in the world, older ones
-- are deleted (v1 kept every casing until RemoveRoad reached it 250 m behind). Each casing is a dynamic body that the
-- server syncs to every player and that every world shift moves. Every gun script is its own Lua instance, so the
-- count is shared through a tag on the bodies (value = spawn time) rather than a list here.
CASING_CAP = 60
function server.gunSpawnCasing(xml, transform, velocity)
	local entities = Spawn(xml, transform) or {}
	local casing = xml:find("casing%.xml$") ~= nil
	for i = 1, #entities do
		if GetEntityType(entities[i]) == "body" then
			SetBodyVelocity(entities[i], velocity)
			if casing then SetTag(entities[i], "ml_casing", string.format("%.3f", GetTime())) end
		end
	end
	if casing then GunNet_CapCasings(CASING_CAP) end
end

--- Delete the oldest tagged casings beyond `cap`.
function GunNet_CapCasings(cap)
	local list = FindBodies("ml_casing", true)
	if #list <= cap then return end
	local aged = {}
	for i = 1, #list do aged[i] = { body = list[i], t = tonumber(GetTagValue(list[i], "ml_casing")) or 0 } end
	table.sort(aged, function(a, b) return a.t < b.t end)
	for i = 1, #list - cap do Delete(aged[i].body) end
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
	Gun3P_Pose()
	Gun3P_ScopeTick()
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
	if client.gun3pFired then client.gun3pFired[playerId] = GetTime() end   -- third-person pose: shooting
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

-- "i=x,y,z,qx,qy,qz,qw;..." plus "|h=i,i,i" (hidden parts) plus "|g=i,i" (the first-person hands hand1, hand2:
-- where the gun is gripped, for the third-person copy below; 0 = none)
function GunNet_PackParts(shapes, sent, full, hiddenSet, gripIdx)
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
	local g = gripIdx and ("|g=" .. (gripIdx[1] or 0) .. "," .. (gripIdx[2] or 0)) or ""
	return changed, table.concat(out, ";") .. "|h=" .. table.concat(h, ",") .. g
end

function GunNet_UnpackParts(data, entry)
	local rest, gripStr = data:match("^(.-)|g=([%d,]*)$")
	if rest then
		data = rest
		local a, b = gripStr:match("^(%d+),(%d+)$")
		entry.grip = { tonumber(a) or 0, tonumber(b) or 0 }
	end
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
	local grip = { hand1 and index[hand1] or 0, hand2 and index[hand2] or 0 }
	local changed, data = GunNet_PackParts(shapes, client.gunPartsSent, full, hidden, grip)
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

------------------------------------------------------------------
-- Third-person guns (2026-11-15)
------------------------------------------------------------------
-- The gun models are built at first-person viewmodel scale: ~2.5x a real gun (AKM: stock 0.4 m, muzzle 2.6 m in
-- front of the tool origin; a real AKM is 0.88 m), placed far in front of the eye so they look right in first
-- person. Other players (and the holder in third person) saw that giant gun plus the first-person fake arms (user
-- screenshots). Shapes cannot be scaled at runtime, so each machine builds its own small copy of the held gun: a
-- static body spawned locally with one shape per tool part at GUN3P_SCALE of the part's voxel size, the voxels
-- and colours copied from the tool's parts (CopyShapeContent / CopyShapePalette). Every frame the copy's parts take
-- the tool parts' local transforms (positions scaled), so reloads / bolts / magazines move as in first person; the
-- tool itself and the fake arms are hidden. The character's hands go where the first-person fake hands are (the
-- gun script's hand2 = grip, hand1 = handguard; their positions follow reloads).
-- The pose is the engine's own for its rifle in third person (data/script/toolanimation.lua tickToolAnimator, poses
-- from data/prefab/tool/rifle.xml): held low ("run") when idle; shouldered ("action") while aiming (right mouse)
-- or for 2 s after a shot, turned so the barrel points at what the crosshair hits; crouch variants; the arm
-- follows the look pitch about the neck; poses blend at the engine's rates.
-- First person is untouched. If the copy can't be built, nothing is hidden (the old look stays).
-- Verified in-game (2026-11-15): a client's Spawn stays local, a copied shape keeps its own voxel size.

GUN3P_SCALE = 0.4
GUN3P_CELL = "MOD/assets/vox/gun3p_cell.vox"   -- one voxel; every copied part starts as this
-- rifle.xml eye_space poses (tool origin = right hand) in the override frame; Euler degrees
GUN3P_POSE = {
	action        = { pos = { 0.2, -0.4, -0.15 },   rot = { 0, 0, 5 } },
	action_crouch = { pos = { 0.3, -0.5, -0.15 },   rot = { 0, 0, 5 } },
	run           = { pos = { 0.2, -0.5, -0.2 },    rot = { 20, 30, 0 } },
	crouch        = { pos = { 0.275, -0.55, -0.05 }, rot = { -15, -5, 5 } },
}
GUN3P_RH_POS = { 0, 0.05, -0.1 }                -- rifle.xml tp_action_rh (where its grip is)
GUN3P_HAND_R = { 0, 90, 0 }                     -- right hand rotation, rifle.xml tp_*_rh
GUN3P_HAND_L = { action = { -45, 30, -30 }, run = { -90, 0, 0 } }   -- rifle.xml tp_action_lh / tp_run_lh
-- How long the shouldered pose stays after letting go of aim / after a shot. The engine keeps 2 s
-- (toolanimation.lua maxActionPoseTime); after aiming that felt like a huge delay (user, 2026-11-15).
GUN3P_AIM_HOLD = 0.15
GUN3P_SHOT_HOLD = 1.0
GUN3P_AIM_DIST = 10.0                           -- toolanimation.lua getAimTarget(10.0)
-- Parts outside this box (tool coordinates, first-person scale) are not part of the visible gun: parked parts
-- (hideTrans, y -200) and parts the script never moves, left where the .vox puts them (MC308: a stick 22 m behind,
-- one voxel 5.6 m ahead; user screenshot 2026-11-15). Muzzles are at z -2.5 plus the barrel extension; anything
-- behind z 0.5 is behind the first-person camera.
GUN3P_BOX_MIN = Vec(-1.5, -2.0, -4.5)
GUN3P_BOX_MAX = Vec(1.5, 1.0, 0.5)
GUN3P_GRIP_R = Vec(0.275, -0.95, -0.85)        -- fallbacks (AKM's hand positions) for a gun without fake hands
GUN3P_GRIP_L = Vec(0.175, -0.8, -1.9)
-- (2026-11-16, user: "the RPG is too small, and should be held over the shoulder when aimed") Tools that don't
-- fit the rifle defaults:
-- * length: the copy is scaled so its longest part is this long (metres), instead of GUN3P_SCALE. The RPG-7 is a
--   .vox registered directly (RegisterTool), not one of the gun prefabs the 0.4 was chosen for; a real RPG-7 is
--   0.95 m.
-- * axis: a point on the tube's axis, tool coordinates (first-person scale). While in action this point is put
--   at the pose's position instead of the grip at the rifle's grip (RPG.lua: rocket at 0.225 -0.475 -2,
--   backblast at 0.075 -0.4 1.75, pistol grip hand at z -0.6; the shoulder rests just behind the grip).
-- * action / action_crouch: replace GUN3P_POSE's; here the tube on top of the right shoulder, beside the head.
GUN3P_TOOL = {
	["gun-rpg"] = {
		length = 1.0,
		axis = { 0.15, -0.45, -0.2 },
		action        = { pos = { 0.2, -0.15, 0.05 }, rot = { 0, 0, 0 } },
		action_crouch = { pos = { 0.2, -0.15, 0.05 }, rot = { 0, 0, 0 } },
	},
}

client.gun3p = {}   -- [player] = { src = tool body, n = parts, body = copy body, shapes = { copy parts }, pose state }
client.gun3pFired = {}   -- [player] = time of the last shot seen (client.gunRemoteFire)

-- The animated right shoulder's offset from its standing place, in the override frame (as Melee_Functions.lua
-- MeleeNet_ShoulderOffset / the engine's toolanimation.lua): crouching and the walk bob.
function Gun3P_ShoulderOffset(p)
	local a = GetPlayerAnimator(p)
	if not a or a == 0 then return Vec() end
	local bind = TransformToParentTransform(GetAnimatorTransform(a), GetBoneBindPoseTransform(a, "shoulder_r"))
	local now = GetBoneWorldTransform(a, "shoulder_r").pos
	return TransformToLocalVec(Transform(Vec(), GetPlayerTransform(p).rot), VecSub(now, bind.pos))
end

-- World transform of SetToolTransformOverride's frame: standing eye height above the character, the player's yaw.
function Gun3P_Frame(p)
	local t = GetPlayerTransform(p)
	local a = GetPlayerAnimator(p)
	local pos = (a and a ~= 0) and GetAnimatorTransform(a).pos or t.pos
	return Transform(VecAdd(pos, Vec(0, 1.7, 0)), t.rot)
end

local function g3pDamp(rate, dt) return 1.0 - 2.0 ^ (-rate * dt) end
local function g3pClamp(v, lo, hi) return math.max(lo, math.min(hi, v)) end
local function g3pPose(d) return Transform(Vec(d.pos[1], d.pos[2], d.pos[3]), QuatEuler(d.rot[1], d.rot[2], d.rot[3])) end
local function g3pMix(a, b, k) return Transform(VecLerp(a.pos, b.pos, k), QuatSlerp(a.rot, b.rot, k)) end
local function g3pAngle(v0, v1, axis)   -- toolanimation.lua getSignedAngle, radians
	local a0 = VecNormalize(VecSub(v0, VecScale(axis, VecDot(axis, v0))))
	local a1 = VecNormalize(VecSub(v1, VecScale(axis, VecDot(axis, v1))))
	local angle = math.acos(g3pClamp(VecDot(a0, a1), -1, 1))
	if VecDot(VecCross(a0, a1), axis) < 0 then return -angle end
	return angle
end

-- 0 standing .. 1 crouched, from the eye height (toolanimation.lua getCrouching)
function Gun3P_Crouch(p)
	local h = GetPlayerEyeTransform(p).pos[2] - GetPlayerTransform(p).pos[2]
	return 1.0 - (g3pClamp(h, 0.85, 1.7) - 0.85) / (1.7 - 0.85)
end

-- Rotation turning the gun's -z from `pivot` toward what the player's crosshair hits (toolanimation.lua
-- getAimTarget / getAimRotation: 10 m ray from the camera, yaw limited to 10 deg up / 5 down, pitch to 80).
function Gun3P_AimRotation(p, frame, pivot, copyBody)
	local ct = GetPlayerCameraTransform(p)
	local dir = QuatRotateVec(ct.rot, Vec(0, 0, -1))
	local start = VecAdd(ct.pos, VecScale(dir, math.max(VecDot(VecSub(GetPlayerEyeTransform(p).pos, ct.pos), dir), 0)))
	QueryRequire("physical visible")
	if copyBody and copyBody ~= 0 then QueryRejectBody(copyBody) end
	local hit, dist = QueryRaycast(start, dir, GUN3P_AIM_DIST)
	if not hit or type(dist) ~= "number" then dist = GUN3P_AIM_DIST end
	local target = TransformToLocalPoint(frame, VecAdd(start, VecScale(dir, dist)))
	local d = VecNormalize(VecSub(target, pivot))
	local pitch = g3pClamp(g3pAngle(Vec(0, 0, -1), d, Vec(1, 0, 0)), -math.rad(80), math.rad(80))
	local yaw = g3pAngle(Vec(0, 0, -1), d, Vec(0, 1, 0))
	local lim = pitch < 0 and math.rad(5) or math.rad(10)
	yaw = g3pClamp(yaw, -lim, lim)
	return QuatRotateQuat(QuatAxisAngle(Vec(0, 1, 0), math.deg(yaw)), QuatAxisAngle(Vec(1, 0, 0), math.deg(pitch)))
end

-- Is the player aiming (or let go < GUN3P_AIM_HOLD ago) or shooting (last shot < GUN3P_SHOT_HOLD ago)?
function Gun3P_Action(p, c)
	local now = GetTime()
	if InputDown("grab", p) or (IsPlayerLocal(p) and ironsight) then c.lastAim = now end
	if InputDown("usetool", p) or (client.gun3pFired[p] or -100) > now - 0.05 then c.lastShot = now end
	return now - (c.lastAim or -100) < GUN3P_AIM_HOLD or now - (c.lastShot or -100) < GUN3P_SHOT_HOLD
end

-- Scope overlays (the reticle + see-through outline drawn on screen) are projected from the first-person tool:
-- in third person they don't line up with anything (user, SV-98, 2026-11-15). The gun scripts call this where
-- they draw one; while they do, the view switches to first person (the engine's view-finder pattern,
-- RequestFirstPerson every tick, script_defs.lua) and returns to third person on its own once they stop.
function Gun3P_ScopeOverlay()
	client.gun3pScopeAt = GetTime()
end

function Gun3P_ScopeTick()
	if client.gun3pScopeAt and GetTime() - client.gun3pScopeAt < 0.1 then RequestFirstPerson(true) end
end

-- The engine's third-person tool animation for this player (toolanimation.lua tickToolAnimator, third-person
-- branch, without the sway / contact solver), then shifted so this gun's own grip lands where the rifle's is.
-- Returns the tool body's transform in the override frame and the left-hand rotation for the pose.
function Gun3P_Animate(p, c, dt, frame, gripR)
	local action = Gun3P_Action(p, c)
	local crouch = Gun3P_Crouch(p)
	local target
	local spec = c.spec or {}
	local function pose(name) return g3pPose(spec[name] or GUN3P_POSE[name]) end
	if action then target = g3pMix(pose("action"), pose("action_crouch"), crouch)
	else target = g3pMix(pose("run"), pose("crouch"), crouch) end
	local a = g3pDamp(action and 60 or 20, dt)
	c.pose = c.pose and g3pMix(c.pose, target, a) or target
	local t = Transform(VecAdd(c.pose.pos, Gun3P_ShoulderOffset(p)), c.pose.rot)
	-- arm pitch: the hand swings about the neck with the look pitch (half of it when idle)
	local pitch = GetPlayerPitch(p)
	c.armPitch = (c.armPitch or 0) + ((pitch * (action and 1.0 or 0.5)) - (c.armPitch or 0)) * a
	local anim = GetPlayerAnimator(p)
	local pivot = Vec(0, -0.2, 0)
	if anim and anim ~= 0 then pivot = TransformToLocalPoint(frame, GetBoneWorldTransform(anim, "neck").pos) end
	t.pos = VecAdd(pivot, QuatRotateVec(QuatAxisAngle(Vec(1, 0, 0), c.armPitch), VecSub(t.pos, pivot)))
	-- tool rotation: at the crosshair target while in action, else a share of the pitch
	local rot, b
	if action then
		rot, b = Gun3P_AimRotation(p, frame, t.pos, c.body), g3pDamp(15, dt)
	else
		rot, b = QuatAxisAngle(Vec(1, 0, 0), pitch * 0.4), g3pDamp(30, dt)
	end
	c.toolRot = c.toolRot and QuatSlerp(c.toolRot, rot, b) or rot
	t.rot = QuatRotateQuat(c.toolRot, t.rot)
	-- what lands at the pose's position: the grip at the rifle's grip, or (in action) the tube's axis (GUN3P_TOOL)
	local off
	if action and spec.axis then
		off = VecScale(Vec(spec.axis[1], spec.axis[2], spec.axis[3]), -c.scale)
	else
		off = VecSub(Vec(GUN3P_RH_POS[1], GUN3P_RH_POS[2], GUN3P_RH_POS[3]), VecScale(gripR, c.scale))
	end
	c.off = c.off and VecLerp(c.off, off, a) or off
	local tool = TransformToParentTransform(t, Transform(c.off))
	local lh = action and GUN3P_HAND_L.action or GUN3P_HAND_L.run
	return tool, QuatEuler(lh[1], lh[2], lh[3])
end

-- Who gets a copy on this machine, and that player's tool parts, the parts not to copy, the two hand parts.
function Gun3P_Source(p)
	if GetPlayerVehicle(p) ~= 0 then return nil end
	if IsPlayerLocal(p) then
		if not GetBool("game.thirdperson") or body == nil or GetToolBody() ~= body then return nil end
		local shapes = GetBodyShapes(body)
		local index, skip = {}, {}
		for i = 1, #shapes do index[shapes[i]] = i end
		for _, h in pairs({ hand1, hand2, arm1, arm2 }) do if h and index[h] then skip[index[h]] = true end end
		return body, shapes, skip, { hand1 and index[hand1] or 0, hand2 and index[hand2] or 0 }
	end
	local e = client.gunRemoteParts[p]
	if not e or GetPlayerTool(p) ~= e.tool or next(e.parts) == nil then return nil end
	local b = GetToolBody(p)
	if b == 0 then return nil end
	return b, GetBodyShapes(b), e.hidden, e.grip or { 0, 0 }
end

function Gun3P_Delete(p)
	local c = client.gun3p[p]
	if c and c.body and IsHandleValid(c.body) then Delete(c.body) end
	client.gun3p[p] = nil
end

function Gun3P_Build(p, src, shapes)
	local toolId = GetPlayerTool(p)
	local spec = GUN3P_TOOL[toolId]
	local scale = GUN3P_SCALE
	if spec and spec.length then
		local longest = 0
		for i = 1, #shapes do
			local sx, sy, sz, vs = GetShapeSize(shapes[i])
			longest = math.max(longest, math.max(sx, sy, sz) * (vs or 0.1))
		end
		if longest > 0 then scale = spec.length / longest end
	end
	local xml = {}
	for i = 1, #shapes do
		local _, _, _, vs = GetShapeSize(shapes[i])
		if not vs or vs <= 0 then vs = 0.1 end
		xml[i] = string.format('<vox file="%s" scale="%.4f" collide="false"/>', GUN3P_CELL, vs * scale / 0.1)
	end
	-- dynamic: a static body took its first placement but didn't follow the player (user, 2026-11-15)
	local ents = Spawn('<body dynamic="true" tags="ml_gun3p">' .. table.concat(xml) .. '</body>', Transform(), true) or {}
	local c = { src = src, n = #shapes, body = 0, shapes = {}, toolId = toolId, spec = spec, scale = scale }
	for _, e in ipairs(ents) do
		local kind = GetEntityType(e)
		if kind == "body" then c.body = e elseif kind == "shape" then c.shapes[#c.shapes + 1] = e end
	end
	if c.body == 0 or #c.shapes ~= #shapes then
		for _, e in ipairs(ents) do if IsHandleValid(e) then Delete(e) end end
		c.body, c.shapes, c.failed = 0, {}, true   -- keep the old look; don't retry every frame
		return c
	end
	SetBodyGravityScale(c.body, 0)
	for i = 1, #shapes do
		CopyShapeContent(shapes[i], c.shapes[i])
		CopyShapePalette(shapes[i], c.shapes[i])
		SetTag(c.shapes[i], "ml_toolpart")      -- skipped by the guns' own raycasts (GunRaycast)
		SetTag(c.shapes[i], "unbreakable")
	end
	return c
end

function Gun3P_InBox(p)
	return p[1] >= GUN3P_BOX_MIN[1] and p[1] <= GUN3P_BOX_MAX[1] and p[2] >= GUN3P_BOX_MIN[2] and p[2] <= GUN3P_BOX_MAX[2]
		and p[3] >= GUN3P_BOX_MIN[3] and p[3] <= GUN3P_BOX_MAX[3]
end

-- (MP fix 2026-11-16) The box test uses a part's centre, not its local position (= one corner of its voxel grid):
-- the RPG-7's launcher tube (40 voxels long) has that corner at its rear end, behind z 0.5, so the whole tube was
-- left out of the copy while the real tool was hidden, and other players saw no launcher.
function Gun3P_PartCentre(shape, t)
	local sx, sy, sz, scale = GetShapeSize(shape)
	return TransformToParentPoint(t, Vec(sx * scale * 0.5, sy * scale * 0.5, sz * scale * 0.5))
end

-- Right / left grip in tool coordinates: the fake hand nearer the stock holds the grip.
function Gun3P_Grips(shapes, grip)
	local a = grip[1] ~= 0 and shapes[grip[1]] and GetShapeLocalTransform(shapes[grip[1]]).pos
	local b = grip[2] ~= 0 and shapes[grip[2]] and GetShapeLocalTransform(shapes[grip[2]]).pos
	if a and not Gun3P_InBox(a) then a = nil end
	if b and not Gun3P_InBox(b) then b = nil end
	if a and b then
		if a[3] > b[3] then return a, b end
		return b, a
	end
	if a or b then return a or b, nil end   -- one hand only (e.g. the other is busy with the magazine)
	return GUN3P_GRIP_R, GUN3P_GRIP_L
end

-- Re-issues this frame's tool pose and hands at the start of the next client.tick too (the API asks for them
-- from tick; client.render computes them after the gun script moved its parts).
function Gun3P_Pose()
	for p, c in pairs(client.gun3p) do
		if c.tool then
			if c.override then SetToolTransformOverride(c.tool, p) end
			SetToolHandPoseLocalTransform(c.handR, c.handL, p)
		end
	end
end

-- Poses every copy on this machine (client.render: after the gun script moved its parts this frame).
-- Other players: the tool body is placed with SetToolTransformOverride (hidden) and the hands are given relative to
-- it. The local player in third person: the gun script keeps placing the hidden tool with SetToolTransform as in
-- first person (its bullets start from the tool, so shooting stays as it was), and the hands are converted into
-- that tool's frame. Before (2026-11-15), the hands were given relative to it as if it were at the copy, so the
-- aiming offset (ADS() moves the tool to the screen centre) dragged them to the left (user).
function Gun3P_Update(dt)
	dt = dt or GetTimeStep()
	for p in Players() do
		local src, shapes, skip, grip = Gun3P_Source(p)
		local c = client.gun3p[p]
		if not src then
			if c then
				if c.src and IsHandleValid(c.src) and IsPlayerLocal(p) then
					for _, s in ipairs(GetBodyShapes(c.src)) do RemoveTag(s, "invisible") end   -- back to first person
				end
				Gun3P_Delete(p)
			end
		else
			if not c or c.src ~= src or c.n ~= #shapes or c.toolId ~= GetPlayerTool(p) then
				Gun3P_Delete(p)
				c = Gun3P_Build(p, src, shapes)
				client.gun3p[p] = c
			end
			if not c.failed then
				local gripR, gripL = Gun3P_Grips(shapes, grip)
				local frame = Gun3P_Frame(p)
				local tool, lhRot = Gun3P_Animate(p, c, dt, frame, gripR)
				local handR = Transform(VecScale(gripR, c.scale), QuatEuler(GUN3P_HAND_R[1], GUN3P_HAND_R[2], GUN3P_HAND_R[3]))
				local handL = gripL and Transform(VecScale(gripL, c.scale), lhRot) or nil
				c.tool, c.override = tool, not IsPlayerLocal(p)
				if c.override then
					c.handR, c.handL = handR, handL
					SetToolTransformOverride(tool, p)
				else
					-- hands in world space via the copy, then into the frame of the tool body the gun script placed
					local toolWorld = GetBodyTransform(src)
					local copyWorld = TransformToParentTransform(frame, tool)
					c.handR = TransformToLocalTransform(toolWorld, TransformToParentTransform(copyWorld, handR))
					c.handL = handL and TransformToLocalTransform(toolWorld, TransformToParentTransform(copyWorld, handL)) or nil
				end
				SetToolHandPoseLocalTransform(c.handR, c.handL, p)
				for i = 1, #shapes do
					local t = GetShapeLocalTransform(shapes[i])
					SetTag(shapes[i], "invisible")
					local part = c.shapes[i]
					if skip[i] or not Gun3P_InBox(Gun3P_PartCentre(shapes[i], t)) then
						SetTag(part, "invisible")
					else
						RemoveTag(part, "invisible")
						SetShapeLocalTransform(part, Transform(VecScale(t.pos, c.scale), t.rot))
					end
				end
				SetBodyTransform(c.body, TransformToParentTransform(frame, tool))
				SetBodyVelocity(c.body, Vec())          -- dynamic, no gravity: placed by hand every frame
				SetBodyAngularVelocity(c.body, Vec())
			end
		end
	end
	for p in PlayersRemoved() do Gun3P_Delete(p) end
end

-- After the gun scripts' client.tick (where they move the local parts), before rendering.
function client.render(dt)
	GunNet_SendParts()
	GunNet_ApplyRemoteParts()
	Gun3P_Update(dt)
end

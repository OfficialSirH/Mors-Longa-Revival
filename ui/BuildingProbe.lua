-- (2026-11-16, MP) Debug menu "building sync readout (all players)" (host), for the report "there are cases where
-- other players may not see a building the host sees" (post-release MP test with a friend). Cause not known: the
-- buildings are spawned by server code only (world/generation/RandomBuilding.lua) and their prefabs have no
-- scripts. This shows what each machine has of the last buildings / roadblocks the server spawned.
-- * RandomBuilding.lua records every spawn (BuildingProbe_Record, always on: one short string in the server's
--   registry): the spawn's largest shape (the most voxels; some building prefabs have no <body>, so a shape is what
--   every spawn has), the prefab name, the spawn time. The last BUILD_PROBE_COUNT are kept.
-- * While the readout is on, the server publishes twice a second (level.debug.buildprobe, synced): per recorded
--   spawn its shape handle, where that shape is now, its voxel count, how many shapes its body has; plus the
--   number of shapes in the whole level.
-- * Every machine lists per spawn: whether the handle is a shape there at all, how far its copy is from the
--   server's, voxels and body shapes here vs the server, the body asleep / active, and the distance to this
--   machine's player. A building missing on a client = NO SUCH SHAPE (never arrived / deleted there), far apart
--   (left behind, e.g. at a world shift) or 0 voxels (an empty copy).
-- * Aim check (2026-11-16, user screenshot: a stretch of road missing for the non-host): while the readout is on,
--   Ctrl+J on any machine casts the camera ray here and on the server (server.buildProbeAim). The server answers
--   with what it hits (shape, distance, body static / dynamic, voxels, where), and this machine shows what it hits
--   itself and whether it has the server's shapes: NOT HERE = never arrived / deleted here, far apart = left behind.

BUILD_PROBE_COUNT = 8
BUILD_PROBE_RATE = 0.5
BUILD_PROBE_LIST = "level.debug.buildprobe.list"   -- server registry only (not synced)

BUILD_PROBE_AIM_HITS = 3
BUILD_PROBE_AIM_DIST = 150

-- Level scan (2026-11-16): the server publishes, per BUILD_PROBE_CELL m square (x / z), how many static shapes it
-- has there and their voxels (level.debug.buildprobe.cells, every BUILD_PROBE_CELL_RATE s). Every machine counts its
-- own static shapes the same way and lists the cells that differ; for the worst cell it asks the server for the
-- shapes there (server.buildProbeCell) and shows those it doesn't have, or has elsewhere. Static only: other
-- machines' local shapes (third-person gun copies, casings) are dynamic, and debris moves. Players' held tools
-- (GetToolBody) are left out: each machine rebuilds them with its own handles. The grid is offset by
-- BUILD_PROBE_CELL_OFFSET so no cell border runs along the road's centre line (z = 0), where shapes a few mm apart
-- landed in different cells on the two machines (first in-game run, 2026-11-16).
BUILD_PROBE_CELL = 20
BUILD_PROBE_CELL_OFFSET = 7.3
BUILD_PROBE_CELL_RATE = 2
BUILD_PROBE_CELL_LINES = 5
BUILD_PROBE_CELL_SHAPES = 40

BP = { nextPublish = 0, nextCells = 0, lines = {}, aimLocal = nil }

-- fn(shape, pos, cx, cz) for every static shape outside the players' held tools
function BuildingProbe_EachShape(fn)
	local tools = {}
	for _, p in ipairs(GetAllPlayers()) do
		local tb = GetToolBody(p)
		if tb ~= 0 then tools[tb] = true end
	end
	for _, s in ipairs(FindShapes("", true)) do
		local b = GetShapeBody(s)
		if (b == 0 or not IsBodyDynamic(b)) and not tools[b] then
			local pos = GetShapeWorldTransform(s).pos
			fn(s, pos, math.floor((pos[1] + BUILD_PROBE_CELL_OFFSET) / BUILD_PROBE_CELL),
				math.floor((pos[3] + BUILD_PROBE_CELL_OFFSET) / BUILD_PROBE_CELL))
		end
	end
end

-- { ["cx,cz"] = { n, vox } } over this machine's static shapes
function BuildingProbe_Cells()
	local cells = {}
	BuildingProbe_EachShape(function(s, pos, cx, cz)
		local key = cx .. "," .. cz
		local c = cells[key]
		if not c then c = { 0, 0 } cells[key] = c end
		c[1] = c[1] + 1
		c[2] = c[2] + GetShapeVoxelCount(s)
	end)
	return cells
end

function server.buildProbeCell(p, cx, cz, seq)
	local list = {}
	BuildingProbe_EachShape(function(s, pos, x, z)
		if x == cx and z == cz then list[#list + 1] = { s, pos, GetShapeVoxelCount(s) } end
	end)
	table.sort(list, function(a, c) return a[3] > c[3] end)
	local parts = {}
	for i = 1, math.min(#list, BUILD_PROBE_CELL_SHAPES) do
		local e = list[i]
		parts[i] = string.format("%d,%.2f,%.2f,%.2f,%d", e[1], e[2][1], e[2][2], e[2][3], e[3])
	end
	SetString("level.debug.buildprobe.cell." .. p, string.format("%d|%d,%d|", seq or 0, cx, cz) .. table.concat(parts, ";"),
		true)
end

function BuildingProbe_CellLines()
	local s = GetString("level.debug.buildprobe.cells")
	if s == "" then return {} end
	if s ~= BP.cellsSeen then   -- a new server count: count here once
		BP.cellsSeen = s
		local mine = BuildingProbe_Cells()
		local diffs, total = {}, 0
		local seen = {}
		for cx, cz, n, vox in s:gmatch("([%-%d]+),([%-%d]+),(%d+),(%d+)") do
			local key = cx .. "," .. cz
			seen[key] = true
			total = total + 1
			local m = mine[key] or { 0, 0 }
			if m[1] ~= tonumber(n) or m[2] ~= tonumber(vox) then
				diffs[#diffs + 1] = { key = key, cx = tonumber(cx), cz = tonumber(cz), n = tonumber(n), vox = tonumber(vox),
					hn = m[1], hvox = m[2] }
			end
		end
		for key, m in pairs(mine) do
			if not seen[key] then
				local cx, cz = key:match("^([%-%d]+),([%-%d]+)$")
				diffs[#diffs + 1] = { key = key, cx = tonumber(cx), cz = tonumber(cz), n = 0, vox = 0, hn = m[1], hvox = m[2] }
			end
		end
		table.sort(diffs, function(a, c)
			local da, dc = math.abs(a.vox - a.hvox), math.abs(c.vox - c.hvox)
			if da ~= dc then return da > dc end
			return a.n > c.n
		end)
		BP.cellDiffs, BP.cellTotal = diffs, total
		local worst
		for _, d in ipairs(diffs) do if d.n > 0 then worst = d break end end
		if worst and worst.key ~= BP.cellAsked then   -- ask the server what is in the worst cell it has shapes in
			BP.cellAsked = worst.key
			BP.cellSeq = (BP.cellSeq or 0) + 1
			ServerCall("server.buildProbeCell", GetLocalPlayer(), worst.cx, worst.cz, BP.cellSeq)
		end
	end
	local diffs = BP.cellDiffs or {}
	local lines = { string.format("Level scan (static shapes, %d m cells): %d of %d cells differ", BUILD_PROBE_CELL, #diffs,
		BP.cellTotal or 0) }
	for i = 1, math.min(#diffs, BUILD_PROBE_CELL_LINES) do
		local d = diffs[i]
		lines[#lines + 1] = string.format("  x %.0f..%.0f z %.0f..%.0f: server %d shapes / %d voxels, here %d / %d",
			d.cx * BUILD_PROBE_CELL - BUILD_PROBE_CELL_OFFSET, (d.cx + 1) * BUILD_PROBE_CELL - BUILD_PROBE_CELL_OFFSET,
			d.cz * BUILD_PROBE_CELL - BUILD_PROBE_CELL_OFFSET, (d.cz + 1) * BUILD_PROBE_CELL - BUILD_PROBE_CELL_OFFSET,
			d.n, d.vox, d.hn, d.hvox)
	end
	local a = GetString("level.debug.buildprobe.cell." .. GetLocalPlayer())
	local seq, cell, body = a:match("^(%d+)|([%-%d]+,[%-%d]+)|(.*)$")
	if seq and tonumber(seq) == BP.cellSeq then
		local missing, apart, shown = 0, 0, 0
		local detail = {}
		for h, x, y, z, vox in (body or ""):gmatch("(%d+),([%d%.%-]+),([%d%.%-]+),([%d%.%-]+),(%d+)") do
			h = tonumber(h)
			local spos = Vec(tonumber(x), tonumber(y), tonumber(z))
			local text
			if not (IsHandleValid(h) and GetEntityType(h) == "shape") then
				missing = missing + 1
				text = "NOT HERE"
			else
				local d = VecLength(VecSub(GetShapeWorldTransform(h).pos, spos))
				if d > 1 then apart = apart + 1 text = string.format("here apart %.1f m", d) end
			end
			if text and shown < BUILD_PROBE_CELL_LINES then
				shown = shown + 1
				detail[#detail + 1] = string.format("    #%d at %.0f,%.0f,%.0f, %s voxels: %s", h, spos[1], spos[2], spos[3], vox,
					text)
			end
		end
		lines[#lines + 1] = string.format("  cell %s, server's %d largest shapes: %d not here, %d elsewhere here", cell,
			select(2, body:gsub(";", "")) + (body ~= "" and 1 or 0), missing, apart)
		for _, l in ipairs(detail) do lines[#lines + 1] = l end
	end
	return lines
end

-- up to BUILD_PROBE_AIM_HITS shapes along a ray: { { h, dist }, ... }
function BuildingProbe_Ray(origin, dir)
	local hits, rejected = {}, {}
	for _ = 1, BUILD_PROBE_AIM_HITS do
		QueryRejectShapes(rejected)
		local hit, dist, _, shape = QueryRaycast(origin, dir, BUILD_PROBE_AIM_DIST)
		if not hit then break end
		hits[#hits + 1] = { shape, dist }
		rejected[#rejected + 1] = shape
	end
	return hits
end

function server.buildProbeAim(p, origin, dir, seq)
	local parts = {}
	for _, hd in ipairs(BuildingProbe_Ray(origin, dir)) do
		local h = hd[1]
		local b = GetShapeBody(h)
		local pos = GetShapeWorldTransform(h).pos
		parts[#parts + 1] = string.format("%d,%.1f,%d,%s,%d,%.2f,%.2f,%.2f", h, hd[2], b,
			(b ~= 0 and IsBodyDynamic(b)) and "dynamic" or "static", GetShapeVoxelCount(h), pos[1], pos[2], pos[3])
	end
	SetString("level.debug.buildprobe.aim." .. p, string.format("%d|", seq or 0) .. table.concat(parts, ";"), true)
end

function BuildingProbe_AimLines()
	local lines = {}
	if not BP.aimLocal then return lines end
	local here = {}
	for _, hd in ipairs(BP.aimLocal) do here[#here + 1] = string.format("#%d at %.1f m", hd[1], hd[2]) end
	lines[1] = "Aim check (Ctrl+J): this machine hits " .. (#here > 0 and table.concat(here, ", ") or "nothing")
	local s = GetString("level.debug.buildprobe.aim." .. GetLocalPlayer())
	local seq, body = s:match("^(%d+)|(.*)$")
	if tonumber(seq) ~= BP.aimSeq then   -- the answer to this request (machines' clocks differ: a request number)
		lines[2] = "  server: waiting for its answer"
		return lines
	end
	if body == "" then lines[2] = "  server hits nothing" end
	for entry in body:gmatch("[^;]+") do
		local h, d, b, kind, vox, x, y, z = entry:match("^(%d+),([%d%.%-]+),(%d+),(%a+),(%d+),([%d%.%-]+),([%d%.%-]+),([%d%.%-]+)$")
		h = tonumber(h)
		if h then
			local spos = Vec(tonumber(x), tonumber(y), tonumber(z))
			local mine
			if IsHandleValid(h) and GetEntityType(h) == "shape" then
				mine = string.format("here: apart %.2f m, voxels %d", VecLength(VecSub(GetShapeWorldTransform(h).pos, spos)),
					GetShapeVoxelCount(h))
			else
				mine = "NOT HERE"
			end
			lines[#lines + 1] = string.format("  server hits #%d at %s m (body #%s %s, voxels %s)  %s", h, d, b, kind, vox, mine)
		end
	end
	return lines
end

--- Server (RandomBuilding.lua): remember one spawn. `entities` = Spawn's result, `xml` = the prefab path.
function BuildingProbe_Record(entities, xml)
	local best, most = 0, -1
	for _, e in ipairs(entities or {}) do
		if IsHandleValid(e) and GetEntityType(e) == "shape" then   -- detail shapes may be deleted already
			local n = GetShapeVoxelCount(e)
			if n > most then best, most = e, n end
		end
	end
	if best == 0 then return end
	local name = (xml or "?"):match("([^/]+)%.xml$") or "?"
	local list = {}
	for entry in GetString(BUILD_PROBE_LIST):gmatch("[^;]+") do list[#list + 1] = entry end
	list[#list + 1] = string.format("%d,%s,%.1f", best, name, GetTime())
	while #list > BUILD_PROBE_COUNT do table.remove(list, 1) end
	SetString(BUILD_PROBE_LIST, table.concat(list, ";"))
end

function BuildingProbe_ServerTick()
	local on = GetBool("savegame.mod.debug.buildprobe")
	if on ~= BuildProbeSent then
		BuildProbeSent = on
		SetBool("level.debug.buildprobe_on", on, true)
	end
	-- the synced key, not the savegame: a test tool (MCP bridge) can switch the readout on there
	if not GetBool("level.debug.buildprobe_on") then return end
	if GetTime() >= BP.nextCells then
		BP.nextCells = GetTime() + BUILD_PROBE_CELL_RATE
		local parts = {}
		for key, c in pairs(BuildingProbe_Cells()) do parts[#parts + 1] = key .. "," .. c[1] .. "," .. c[2] end
		SetString("level.debug.buildprobe.cells", table.concat(parts, ";"), true)
	end
	if GetTime() < BP.nextPublish then return end
	BP.nextPublish = GetTime() + BUILD_PROBE_RATE
	local parts = {}
	for entry in GetString(BUILD_PROBE_LIST):gmatch("[^;]+") do
		local h, name, t = entry:match("^(%d+),([^,]+),([%d%.%-]+)$")
		h = tonumber(h)
		if h then
			if IsHandleValid(h) then
				local pos = GetShapeWorldTransform(h).pos
				local b = GetShapeBody(h)
				parts[#parts + 1] = string.format("%d,%s,%s,%.2f,%.2f,%.2f,%d,%d", h, name, t, pos[1], pos[2], pos[3],
					GetShapeVoxelCount(h), b ~= 0 and #GetBodyShapes(b) or 0)
			else
				parts[#parts + 1] = string.format("%d,%s,%s,gone", h, name, t)
			end
		end
	end
	SetString("level.debug.buildprobe", string.format("%.1f|%d|", GetTime(), #FindShapes("", true))
		.. table.concat(parts, ";"), true)
end

function BuildingProbe_ClientTick()
	if not GetBool("level.debug.buildprobe_on") then return end
	if InputDown("ctrl") and InputPressed("j") then
		local cam = GetCameraTransform()
		local dir = QuatRotateVec(cam.rot, Vec(0, 0, -1))
		BP.aimLocal = BuildingProbe_Ray(cam.pos, dir)
		BP.aimSeq = (BP.aimSeq or 0) + 1
		ServerCall("server.buildProbeAim", GetLocalPlayer(), cam.pos, dir, BP.aimSeq)
	end
	local s = GetString("level.debug.buildprobe")
	local t, total, body = s:match("^([%d%.%-]+)|(%d+)|(.*)$")
	local now = tonumber(t) or 0
	local me = GetPlayerTransform().pos
	local lines = {}
	lines[1] = string.format("Building sync: server has %s shapes in the level, this machine %d (server time %s)",
		total or "?", #FindShapes("", true), t or "?")
	for entry in (body or ""):gmatch("[^;]+") do
		local h, name, st, rest = entry:match("^(%d+),([^,]+),([%d%.%-]+),(.*)$")
		h = tonumber(h)
		if h then
			local age = string.format("%s, %.0f s ago", name, now - (tonumber(st) or now))
			if rest == "gone" then
				lines[#lines + 1] = string.format("  #%d %s  deleted on the server", h, age)
			else
				local x, y, z, vox, n = rest:match("^([%d%.%-]+),([%d%.%-]+),([%d%.%-]+),(%d+),(%d+)$")
				local spos = Vec(tonumber(x) or 0, tonumber(y) or 0, tonumber(z) or 0)
				if IsHandleValid(h) and GetEntityType(h) == "shape" then
					local lpos = GetShapeWorldTransform(h).pos
					local b = GetShapeBody(h)
					lines[#lines + 1] = string.format(
						"  #%d %s  %.0f m from you  apart %.2f m  voxels %d / server %s  body shapes %d / %s  %s%s",
						h, age, VecLength(VecSub(lpos, me)), VecLength(VecSub(lpos, spos)), GetShapeVoxelCount(h),
						vox or "?", b ~= 0 and #GetBodyShapes(b) or 0, n or "?",
						b ~= 0 and (IsBodyActive(b) and "active" or "asleep") or "no body",
						HasTag(h, "invisible") and "  INVISIBLE TAG" or "")
				else
					lines[#lines + 1] = string.format("  #%d %s  %.0f m from you (server place)  NO SUCH SHAPE HERE",
						h, age, VecLength(VecSub(spos, me)))
				end
			end
		end
	end
	for _, l in ipairs(BuildingProbe_CellLines()) do lines[#lines + 1] = l end
	for _, l in ipairs(BuildingProbe_AimLines()) do lines[#lines + 1] = l end
	BP.lines = lines
end

function BuildingProbe_Draw()
	if not GetBool("level.debug.buildprobe_on") then return end
	UiPush()
		UiFont("bold.ttf", 18)
		UiAlign("right top")
		UiTranslate(UiWidth() - 20, 300)
		UiTextShadow(0, 0, 0, 0.8, 1.5)
		UiColor(0.6, 0.9, 1, 1)
		for _, l in ipairs(BP.lines) do UiText(l) UiTranslate(0, 20) end
	UiPop()
end

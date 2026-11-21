-- (2026-11-20, user: "Yes, add the log") Crash breadcrumbs: which of our scripts deleted which physics objects, written
-- into the game's log so that the log in a crash report (%LOCALAPPDATA%\Teardown\crash\...\crashData.zip, log.txt)
-- ends with the deletions of the last frames before the crash.
--
-- Why: the MP / SP crashes of 2026-11-17..20 are all the engine reading freed memory inside its physics step
-- (docs/STATUS.md "Engine crash in physics"); a deletion or other scene change by one of our scripts is the prime suspect, but the dumps
-- cannot say which object it was.
--
-- How: include this file in a script BEFORE it defines its callbacks (like lib/GcProbe.lua). It replaces this Lua
-- state's global Delete with a wrapper that counts the deleted shapes / bodies / joints / vehicles / wheels / scripts /
-- triggers, and at the end of each callback (init / tick / update / postUpdate / render / draw) writes one log line
-- for that callback's deletions, if any. A mod script's print() never reaches the game's log (measured 2026-11-20); a
-- LoadSound of a missing file does: the line is the file name, e.g.
--   Couldn't find sound bank .../DL/42_t812.3_RemoveRoad_s_s14-1853_b2-1854x-312.ogg
--   = 42nd line of this script, game time 812.3 s, label RemoveRoad, server half, 14 shapes (first handle 1853),
--     2 bodies (first 1854, at world x -312). A vehicle adds its first tags (v3-82663x-611-tag1-tag2), a joint its type.
-- A LoadSound by the server half is replicated: every client's log gets the server's lines too (so a client's crash
-- report shows what the host deleted). Capped at MAX_LINES lines per script half (late joiners replay them).
-- Codes: s shape, b body, j joint, v vehicle, w wheel, x script, t trigger.
-- DL_LABEL (set by the includer before the #include) names the script in the line.

if not DeleteLogInstalled and Delete then
	DeleteLogInstalled = true
	local MAX_LINES = 20000   -- RemoveRoad writes ~60 lines per segment (120 shapes per frame): 4000 lasted ~70 segments
	local CODES = { shape = "s", body = "b", joint = "j", vehicle = "v", wheel = "w", script = "x", trigger = "t" }
	local ORDER = { "s", "b", "j", "v", "w", "x", "t" }
	local rawDelete = Delete
	local L = { n = 0, lines = 0 }

	local function where(c, h)
		if c == "b" then return GetBodyTransform(h).pos[1] end
		if c == "v" then return GetVehicleTransform(h).pos[1] end
		return nil
	end

	-- (2026-11-20) what the first deleted vehicle / joint was: the vehicle's first tags, the joint's type
	local function what(c, h)
		if c == "v" then
			local tags = ListTags and ListTags(h) or {}
			local t = {}
			for _, tag in ipairs(tags) do   -- Fuel.lua sets drive / turn / brake on every vehicle: not telling
				if #t < 3 and tag ~= "drive" and tag ~= "turn" and tag ~= "brake" then
					t[#t + 1] = string.gsub(tag, "[^%w]", "")
				end
			end
			return #t > 0 and table.concat(t, "-") or nil
		end
		if c == "j" then return GetJointType(h) end
		return nil
	end

	function Delete(h, ...)
		if L.lines < MAX_LINES and type(h) == "number" and h ~= 0 and IsHandleValid(h) then
			local c = CODES[GetEntityType(h)]
			if c then
				local e = L[c]
				if not e then
					e = { 0, h, where(c, h), what(c, h) }
					L[c] = e
					L.n = L.n + 1
				end
				e[1] = e[1] + 1
			end
		end
		return rawDelete(h, ...)
	end

	-- (2026-11-21, user: "add some quick logging to everything") the other calls that change the scene's structure, in
	-- the same line: <code><count>-<first argument> (a handle, or a spawned file's name without .xml, "xml" for an XML
	-- string). Per-frame movers (SetBodyTransform / Velocity, Constrain*) are left out: a line every frame per script.
	--   S Spawn, H MakeHole, E Explosion, D SetBodyDynamic, A SetBodyActive, R SetShapeBody, J DetachJointFromShape,
	--   C CreateShape, K ClearShape, Z ResizeShape, M MergeShape, P SplitShape, T TrimShape, L SetShapeLocalTransform,
	--   Q Paint / PaintRGBA, F Shoot, I SpawnFire, N SetShapeDensity (SetShapeCollisionFilter: goreai_main calls it
	--   every frame, left out)
	local WATCH = { Spawn = "S", MakeHole = "H", Explosion = "E", SetBodyDynamic = "D", SetBodyActive = "A",
		SetShapeBody = "R", DetachJointFromShape = "J", CreateShape = "C", ClearShape = "K", ResizeShape = "Z",
		MergeShape = "M", SplitShape = "P", TrimShape = "T", SetShapeLocalTransform = "L", Paint = "Q", PaintRGBA = "Q",
		Shoot = "F", SpawnFire = "I", SetShapeDensity = "N" }
	local WORDER = { "S", "H", "E", "D", "A", "R", "J", "C", "K", "Z", "M", "P", "T", "L", "Q", "F", "I", "N" }
	for _, c in ipairs(WORDER) do ORDER[#ORDER + 1] = c end
	local function detail(a)
		if type(a) == "number" then return a end
		if type(a) == "string" then
			if string.find(a, "<", 1, true) then return "xml" end
			return (string.gsub(string.match(a, "([^/]+)$") or a, "%.xml$", ""))
		end
		return 0
	end
	if _G then
		for name, code in pairs(WATCH) do
			local raw = _G[name]
			if type(raw) == "function" then
				_G[name] = function(a, ...)
					if L.lines < MAX_LINES then
						local e = L[code]
						if not e then
							e = { 0, detail(a) }
							L[code] = e
							L.n = L.n + 1
						end
						e[1] = e[1] + 1
					end
					return raw(a, ...)
				end
			end
		end
	end

	local function flush(side)
		if L.n == 0 then return end
		local parts = {}
		for _, c in ipairs(ORDER) do
			local e = L[c]
			if e then
				parts[#parts + 1] = (e[3] and string.format("%s%d-%dx%d", c, e[1], e[2], e[3]) or
					string.format("%s%d-%s", c, e[1], tostring(e[2]))) .. (e[4] and ("-" .. e[4]) or "")
				L[c] = nil
			end
		end
		L.n = 0
		L.lines = L.lines + 1
		local label = string.gsub(DL_LABEL or "script", "[^%w]", "")
		-- file names from Spawn may hold spaces etc.: keep the line one clean path
		LoadSound(string.format("MOD/DL/%d_t%.1f_%s_%s_%s.ogg", L.lines, GetTime(), label, side,
			(string.gsub(table.concat(parts, "_"), "[^%w%-_]", ""))))
	end

	-- (2026-11-20) an event line of its own, written at once (GenerateRoad: each world shift, "WORLDSHIFT<bodies moved>")
	function DeleteLogNote(text)
		L.lines = L.lines + 1
		LoadSound(string.format("MOD/DL/%d_t%.1f_%s_%s.ogg", L.lines, GetTime(),
			string.gsub(DL_LABEL or "script", "[^%w]", ""), (string.gsub(text, "[^%w%-]", ""))))
	end

	local CALLBACKS = { init = true, tick = true, update = true, postUpdate = true, render = true, draw = true }
	local function hook(tbl, side)
		if type(tbl) ~= "table" then return end
		local mt = getmetatable(tbl)
		local prev = mt and mt.__newindex   -- lib/GcProbe.lua (debug) may already wrap these: chain onto it
		local function set(t, k, v)
			if prev then prev(t, k, v) else rawset(t, k, v) end
		end
		if not mt then
			mt = {}
			setmetatable(tbl, mt)
		end
		mt.__newindex = function(t, k, v)
			if CALLBACKS[k] and type(v) == "function" then
				local f = v
				v = function(...)
					f(...)
					flush(side)
				end
			end
			set(t, k, v)
		end
	end
	hook(server, "s")
	hook(client, "c")
end

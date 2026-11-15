-- Mock test: world/generation/RemoveRoad.lua, the continuous cleanup sweep (2026-11-15). v1's rules per object
-- (shapes / bodies / vehicles / triggers / joints, "nodelete", rearmost player), but spread over frames: at most
-- SWEEP_DELETE deletions per frame, nothing in the frames right after a world shift, and never anything when no
-- player is found (2026-11-07: a fresh game showed no world). Also WaterMover.lua's no-player rule.
-- Run from the repo root with Lua 5.1: lua5.1 tools/porting/tests/test_removeroad.lua
dofile("tools/porting/tests/mockengine.lua")
local function check(cond, msg) if not cond then error("FAIL: " .. msg, 2) end print("ok  " .. msg) end

-- a small world: entities with a kind, x position, tags, shapes (bodies), bodies (vehicles), joint shapes
local function world(players)
	local env = MockEngine.load("world/generation/RemoveRoad.lua")
	env.PLAYERS, env.ORDER = {}, {}
	for i, p in ipairs(players) do
		env.PLAYERS[i] = { pos = { p.x, 0, 0 }, health = 1, vehicle = p.vehicle or 0 }
		env.ORDER[i] = i
	end
	local W = { e = {}, deleted = {}, reg = {} }
	local function list(kind)
		local out = {}
		for h, e in pairs(W.e) do if e.kind == kind and not e.gone then out[#out + 1] = h end end
		table.sort(out)
		return out
	end
	function W.add(h, kind, x, extra)
		local e = extra or {}
		e.kind, e.x = kind, x
		W.e[h] = e
		return h
	end
	env.def("FindShapes", function() W.fullScans = (W.fullScans or 0) + 1 return list("shape") end)
	-- shapes whose bounds overlap the box (x only matters here)
	env.def("QueryAabbShapes", function(min, max)
		W.regionScans = (W.regionScans or 0) + 1
		local out = {}
		for _, h in ipairs(list("shape")) do
			local e = W.e[h]
			if e.x <= max[1] and e.x + (e.len or 1) >= min[1] then out[#out + 1] = h end
		end
		return out
	end)
	env.def("GetTime", function() return W.t or 0 end)
	env.def("FindBodies", function() return list("body") end)
	env.def("FindTriggers", function() return list("trigger") end)
	env.def("FindJoints", function() return list("joint") end)
	env.def("IsHandleValid", function(h) return W.e[h] ~= nil and not W.e[h].gone end)
	env.def("HasTag", function(h, t) return W.e[h] and W.e[h].tags and W.e[h].tags[t] or false end)
	local function tr(h) return env.Transform({ W.e[h] and W.e[h].x or 0, 0, 0 }) end
	-- bounds: from x to x + len (len = the object's extent along the road, default 1 m)
	local function bounds(h)
		local e = W.e[h]
		return { e.x, 0, 0 }, { e.x + (e.len or 1), 1, 1 }
	end
	env.def("GetShapeWorldTransform", tr)
	env.def("GetBodyTransform", tr)
	env.def("GetTriggerTransform", tr)
	env.def("GetShapeBounds", bounds)
	env.def("GetTriggerBounds", bounds)
	env.def("GetBodyVehicle", function(h) return W.e[h].vehicle or 0 end)
	env.def("GetBodyShapes", function(h) return W.e[h].shapes or {} end)
	env.def("GetJointShapes", function(h) return W.e[h].shapes or {} end)
	env.def("GetPlayerVehicle", function(p) return env.PLAYERS[p].vehicle end)
	env.def("GetInt", function(k) return W.reg[k] or 0 end)
	env.def("GetBool", function() return false end)
	env.def("Delete", function(h) W.e[h].gone = true W.deleted[#W.deleted + 1] = h end)
	env.def("GetShapeBody", function(h) return W.e[h] and W.e[h].body or 0 end)
	env.def("GetTagValue", function(h, tag) local v = W.e[h] and W.e[h].tags and W.e[h].tags[tag] return type(v) == "string" and v or "" end)
	env.server.init()
	W.env = env
	function W.frames(n) for i = 1, n do env.server.tick(1/60) end end
	function W.gone(h) return W.e[h].gone == true end
	return W
end

-- no players: nothing, ever
local W = world({})
W.add(101, "shape", -1000)
W.frames(20)
check(#W.deleted == 0, "no players -> deletes nothing (v1-port bug: deleted the whole level)")

-- v1's rules
W = world({ { x = 0 } })
W.add(101, "shape", -1000)
W.add(102, "shape", 0)
W.add(103, "shape", -1000, { tags = { nodelete = true } })
W.add(201, "body", -1000, { shapes = { 104 } }) W.add(104, "shape", 0)        -- far body, its shape near
W.add(202, "body", -1000, { shapes = { 105 } }) W.add(105, "shape", -1000)    -- far body, its shape far
W.add(301, "trigger", -1000)
W.add(302, "trigger", -100)
W.add(401, "joint", 0, { shapes = { 105 } })
W.add(402, "joint", 0, { shapes = { 102 } })
W.add(501, "vehicle", -1000) W.add(203, "body", -1000, { vehicle = 501, shapes = { 106 } }) W.add(106, "shape", -1000)
W.frames(30)
check(W.gone(101) and not W.gone(102) and not W.gone(103), "shapes: far deleted, near and nodelete kept")
check(not W.gone(201) and W.gone(202), "bodies: deleted only when far AND without shapes left")
check(W.gone(301) and not W.gone(302), "triggers: far deleted (v1 read them with a shape call: never deleted)")
check(W.gone(401) and not W.gone(402), "joints: deleted when their shapes are gone")
check(W.gone(501), "vehicle: deleted when all its bodies are empty")

-- a long shape (a 200 m road) whose origin is far behind but whose front end is near: kept until all of it is far
W = world({ { x = 0 } })
W.add(601, "shape", -300, { len = 200 })   -- spans -300..-100: front end 100 m behind
W.add(602, "shape", -500, { len = 200 })   -- spans -500..-300: all of it 300 m behind
W.frames(30)
check(not W.gone(601) and W.gone(602), "long shapes: deleted only when their far end is behind the distance")

-- a player's vehicle is never deleted; a straggler keeps the area
W = world({ { x = 0, vehicle = 501 }, { x = -900 } })
W.add(501, "vehicle", -1000) W.add(203, "body", -1000, { vehicle = 501, shapes = { 106 } }) W.add(106, "shape", -1000)
W.add(101, "shape", -1000)
W.frames(30)
check(not W.gone(501), "a vehicle a player is in is never deleted")
check(not W.gone(101) and not W.gone(106), "a straggler at x=-900 keeps that area")

-- gradual: 1000 far shapes go a limited number per frame
W = world({ { x = 0 } })
for i = 1, 1000 do W.add(1000 + i, "shape", -1000) end
W.frames(1)
local first = #W.deleted
check(first > 0 and first <= W.env.SWEEP_DELETE, "gradual: one frame deletes at most " .. W.env.SWEEP_DELETE .. " (" .. first .. ")")
W.frames(20)
check(#W.deleted == 1000, "all far shapes gone after a few frames")

-- shapes are found by a region query behind the line; the whole level is listed only every FULL_SCAN_INTERVAL s
W = world({ { x = 0 } })
for i = 1, 50 do W.add(2000 + i, "shape", -1000) end
W.t = 0
W.frames(5)                 -- first pass: a full listing
W.t = 1
W.frames(40)
check(W.fullScans == 1 and (W.regionScans or 0) >= 1, "after the first full listing, passes use the region query")
check(#W.deleted == 50, "the region query finds the far shapes")
W.t = 31
W.frames(10)
check(W.fullScans == 2, "a full listing again after " .. W.env.FULL_SCAN_INTERVAL .. " s")

-- world shift: no deletions for SHIFT_WAIT_FRAMES frames (positions can be half-updated)
W = world({ { x = 0 } })
W.add(101, "shape", -1000)
W.reg["level.world_shifts"] = 1
W.frames(W.env.SHIFT_WAIT_FRAMES)
check(#W.deleted == 0, "right after a world shift: nothing deleted")
W.frames(5)
check(W.gone(101), "then the sweep goes on")

-- (2026-11-15) vehicle events spawn at x -300, behind the line: kept for CLEANUP_GRACE s after they spawn
W = world({ { x = 0 } })
W.t = 100
W.add(801, "body", -300, { tags = { ml_grace = "95.00" } })
W.add(802, "shape", -300, { body = 801 })
W.add(803, "trigger", -300, { tags = { ml_grace = "95.00" } })
W.add(804, "shape", -300, { body = 805 })   -- an old road piece's shape, no grace
W.add(805, "body", -300)
W.frames(30)
check(not W.gone(802) and not W.gone(803), "event spawn far behind: kept during its grace time")
check(W.gone(804), "other far shapes still deleted")
W.t = 95 + W.env.CLEANUP_GRACE + 1
W.frames(60)
check(W.gone(802) and W.gone(803), "after the grace time: deleted as before (still far behind)")

-- WaterMover.lua: same no-player rule
do
	local env = MockEngine.load("world/generation/WaterMover.lua")
	env.PLAYERS, env.ORDER = {}, {}
	local deleted = 0
	env.def("Delete", function() deleted = deleted + 1 end)
	if env.server.init then env.server.init() end
	for _, f in ipairs({ "tick", "update" }) do if env.server[f] then env.server[f](1/60) end end
	check(deleted == 0, "WaterMover: no players -> deletes nothing")
end

print("all removeroad tests passed")

-- Profile (not a pass/fail test): one BMP-2 shell into a "bush" of N thin layers, real quaternion maths in the mock.
-- usage (repo root): lua5.1 tools/porting/tests/profile_avf_foliage.lua <ammo type index> <layers>
-- (2026-11-13: APDS into 20 foliage layers made 8115 holes before the hard-material spall gate, 40 after)
-- usage: lua51 foliage_profile.lua <ammo type index> <layers>
dofile("tools/porting/tests/mockengine.lua")
local T, LAYERS = tonumber(arg[1]) or 1, tonumber(arg[2]) or 20
local B = "avf/prefabs/bmp/BMP-2.lua"
local e = MockEngine.load(B, { preload = MockEngine.includes(B) })

-- ---------- real quaternions (x, y, z, w); Teardown: QuatEuler applies Y, then Z, then X
local function qmul(a, b)
	return { a[4]*b[1] + a[1]*b[4] + a[2]*b[3] - a[3]*b[2], a[4]*b[2] - a[1]*b[3] + a[2]*b[4] + a[3]*b[1],
		a[4]*b[3] + a[1]*b[2] - a[2]*b[1] + a[3]*b[4], a[4]*b[4] - a[1]*b[1] - a[2]*b[2] - a[3]*b[3] }
end
local function qaxis(ax, ay, az, deg)
	local h = math.rad(deg) / 2
	local s = math.sin(h)
	return { ax * s, ay * s, az * s, math.cos(h) }
end
local function qconj(q) return { -q[1], -q[2], -q[3], q[4] } end
local function qrot(q, v)
	local p = qmul(qmul(q, { v[1], v[2], v[3], 0 }), qconj(q))
	return { p[1], p[2], p[3] }
end
local function fromMatrix(xa, ya, za)
	local m00, m11, m22 = xa[1], ya[2], za[3]
	local tr = m00 + m11 + m22
	if tr > 0 then
		local s = math.sqrt(tr + 1) * 2
		return { (ya[3] - za[2]) / s, (za[1] - xa[3]) / s, (xa[2] - ya[1]) / s, 0.25 * s }
	elseif m00 > m11 and m00 > m22 then
		local s = math.sqrt(1 + m00 - m11 - m22) * 2
		return { 0.25 * s, (ya[1] + xa[2]) / s, (za[1] + xa[3]) / s, (ya[3] - za[2]) / s }
	elseif m11 > m22 then
		local s = math.sqrt(1 + m11 - m00 - m22) * 2
		return { (ya[1] + xa[2]) / s, 0.25 * s, (za[2] + ya[3]) / s, (za[1] - xa[3]) / s }
	else
		local s = math.sqrt(1 + m22 - m00 - m11) * 2
		return { (za[1] + xa[3]) / s, (za[2] + ya[3]) / s, 0.25 * s, (xa[2] - ya[1]) / s }
	end
end
e.Quat = function() return { 0, 0, 0, 1 } end
e.QuatEuler = function(x, y, z) return qmul(qmul(qaxis(0, 1, 0, y or 0), qaxis(0, 0, 1, z or 0)), qaxis(1, 0, 0, x or 0)) end
e.QuatRotateQuat = function(a, b) return qmul(a, b) end
e.QuatRotateVec = function(q, v) return qrot(q, v) end
e.QuatLookAt = function(eye, target)
	local z = e.VecNormalize(e.VecSub(eye, target))
	local up = math.abs(z[2]) > 0.999 and { 1, 0, 0 } or { 0, 1, 0 }
	local x = e.VecNormalize(e.VecCross(up, z))
	local y = e.VecCross(z, x)
	return fromMatrix(x, y, z)
end
e.TransformToParentPoint = function(t, p) return e.VecAdd(t.pos, qrot(t.rot, p)) end
e.TransformToParentVec = function(t, v) return qrot(t.rot, v) end
e.TransformToLocalPoint = function(t, p) return qrot(qconj(t.rot), e.VecSub(p, t.pos)) end
e.TransformToLocalVec = function(t, v) return qrot(qconj(t.rot), v) end
e.TransformToParentTransform = function(t, l) return e.Transform(e.TransformToParentPoint(t, l.pos), qmul(t.rot, l.rot)) end
e.TransformToLocalTransform = function(t, w) return e.Transform(e.TransformToLocalPoint(t, w.pos), qmul(qconj(t.rot), w.rot)) end
e.TransformCopy = function(t) return e.Transform(e.VecCopy(t.pos), { t.rot[1], t.rot[2], t.rot[3], t.rot[4] }) end

-- ---------- world: LAYERS foliage sheets, 2 cm thick, 15 cm apart, from z = -20 on (infinite sideways)
local function inside(z) for k = 0, LAYERS - 1 do local top = -20 - k * 0.15 if z <= top and z > top - 0.02 then return true end end return false end
e.def("QueryRaycast", function(o, d, len)
	if inside(o[3]) then return true, 0, { 0, 0, 1 }, 77 end
	if math.abs(d[3]) < 1e-6 then return false, 0, { 0, 0, 0 }, 0 end
	local best
	for k = 0, LAYERS - 1 do
		for _, zf in ipairs({ -20 - k * 0.15, -20 - k * 0.15 - 0.02 }) do
			local t = (zf - o[3]) / d[3]
			if t > 0 and t <= len and (not best or t < best) then best = t end
		end
	end
	if best then return true, best, { 0, 0, d[3] < 0 and 1 or -1 }, 77 end
	return false, 0, { 0, 0, 0 }, 0
end)
e.def("GetShapeMaterialAtPosition", function() return "foliage", 0.2, 0.5, 0.2 end)
e.def("QueryAabbBodies", function() return {} end)
e.def("HasTag", function() return false end)
e.def("GetWindVelocity", function() return { 0, 0, 0 } end)
e.def("GetBodyVelocity", function() return { 0, 0, 0 } end)
e.def("GetBodyTransform", function() return e.Transform({ 0, 0, 0 }) end)
e.def("GetShapeWorldTransform", function() return e.Transform({ 0, 0, 0 }) end)
e.def("GetVehicleTransform", function() return e.Transform({ 0, 0, 0 }) end)

e.side = "server"
e.PLAYERS, e.ORDER = { [1] = { pos = { 0, 0, 0 }, health = 1 } }, { 1 }
local TAGS = { [20] = { component = "turret" }, [21] = { component = "gun", weaponType = "customcannon", coax = "COAXMG" } }
e.def("FindVehicle", function() return 9 end)
e.def("FindShapes", function(tag) return tag == "component" and { 20, 21 } or tag == "mainCannon" and { 21 } or {} end)
e.def("GetTagValue", function(h, tag) return TAGS[h] and TAGS[h][tag] or "" end)
e.def("FindRig", function() return 40 end)
e.def("GetShapeSize", function() return 2, 2, 10, 0.1 end)
e.def("GetShapeBody", function(sh) return sh + 100 end)
e.def("HasFile", function() return true end)
e.def("IsJointBroken", function() return false end)
local HOLES = 0
e.def("MakeHole", function(p, r) if p and r and r > 0 then HOLES = HOLES + 1 end return 0 end)
e.server.init()
e.MG.gunnerId, e.shared.mgGunner = 1, 1
for k in pairs(e.calls) do e.calls[k] = 0 end
e.sent = {}
local t0 = os.clock()
e.server.mgCannonFire(1, T, false)
for i = 1, 300 do e.server.tick(1 / 60) end
local dt = os.clock() - t0
local ev = {}
for _, c in ipairs(e.sent) do local k = c.fn .. (c.args[1] and type(c.args[1]) == "string" and (":" .. c.args[1]) or "") ev[k] = (ev[k] or 0) + 1 end
print(("%s into %d foliage layers: %.0f ms Lua"):format(e.MG.types[T].name, LAYERS, dt * 1000))
for _, n in ipairs({ "QueryRaycast", "GetShapeMaterialAtPosition", "MakeHole", "Paint", "SpawnFire" }) do io.write(n, "=", e.calls[n] or 0, " ") end
print("realHoles=" .. HOLES)
for k, v in pairs(ev) do io.write(k, "=", v, " ") end
print()

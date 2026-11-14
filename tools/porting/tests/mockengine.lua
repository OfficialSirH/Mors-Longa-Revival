-- Shared mock engine for script smoke tests (run from the repo root with Lua 5.1).
-- MockEngine.load(path, overrides) loads a Teardown script into its own environment in which every API function
-- from Teardown's script_defs.lua is a stub (returns 0, or {} for list getters like FindShapes / GetBodyShapes),
-- plus Vec/Transform math, Players() over env.PLAYERS, the registry, and call recording:
--   env.calls[name]      number of calls
--   env.violations[name] client-only function called while env.side == "server" (or server-only while "client")
-- Includes: "script/include/player.lua" is provided; other #include lines are dropped unless listed in opts.inline.

MockEngine = {}

local DEFS = "C:/Program Files (x86)/Steam/steamapps/common/Teardown/data/script_defs.lua"

local CLIENT_ONLY, SERVER_ONLY = {}, {}
for n in ("InputClear InputResetOnTransition SetPlayerCharacter SetPlayerCameraOffsetTransform SetToolHandPoseLocalTransform " ..
	"SetToolTransform SetToolAllowedZoom SetToolTransformOverride SetToolOffset SetPlayerRigTags SetSoundLoopUser PlaySoundForUser " ..
	"AddMapMarker SelectedMapMarker GetCameraTransform SetCameraTransform RequestFirstPerson RequestThirdPerson " ..
	"SetCameraOffsetTransform AttachCameraTo SetPivotClipBody ShakeCamera SetCameraFov SetCameraDof DisableMotionBlur " ..
	"SetLowHealthBlurThreshold"):gmatch("%S+") do CLIENT_ONLY[n] = true end
for n in ("SetVehicleParam DriveVehicle SetVehicleHealth SetPlayerTransform SetPlayerTransformWithPitch SetPlayerGroundVelocity " ..
	"SetPlayerSpawnTransform SetPlayerSpawnHealth SetPlayerSpawnTool SetPlayerVehicle SetPlayerVelocity ReleasePlayerGrab " ..
	"SetPlayerScreen SetPlayerHealth SetPlayerRegenerationState SetPlayerTool RespawnPlayer RespawnPlayerAtTransform " ..
	"SetPlayerWalkingSpeed SetPlayerCrouchSpeedScale SetPlayerHurtSpeedScale SetPlayerParam RegisterTool SetToolAmmoPickupAmount " ..
	"SetToolAmmo SetToolEnabled ApplyPlayerDamage DisablePlayerInput DisablePlayer DisablePlayerDamage Shoot Paint PaintRGBA " ..
	"MakeHole Explosion SpawnFire RemoveAabbFires SetTimeScale SetEnvironmentDefault SetEnvironmentProperty AddHeat SetGravity " ..
	"StartLevel"):gmatch("%S+") do
	SERVER_ONLY[n] = true
end

local API = {}
for line in io.lines(DEFS) do
	local n = line:match("^function ([A-Z][%w_]*)%(")
	if n then API[#API + 1] = n end
end
assert(#API > 500, "script_defs.lua not found: " .. DEFS)

function MockEngine.load(path, opts)
	opts = opts or {}
	local env = setmetatable({}, { __index = _G })
	env.calls, env.violations, env.side = {}, {}, "server"
	env._G = env -- scripts index their own globals via _G (e.g. lib/Settings.lua st_table)
	local function record(n)
		env.calls[n] = (env.calls[n] or 0) + 1
		if env.side == "server" and CLIENT_ONLY[n] then env.violations[n] = true end
		if env.side == "client" and SERVER_ONLY[n] then env.violations[n] = true end
	end
	for _, n in ipairs(API) do
		local list = n:match("s$") and (n:match("^Find") or n:match("^Get")) and not n:match("Pos$")
		local tr = n:match("^Get") and n:match("Transform$")
		local vec = n:match("^Get") and (n:match("Velocity$") or n:match("Pos$") or n:match("CenterOfMass$"))
		local bounds = n:match("^Get") and n:match("Bounds$")
		env[n] = function()
			record(n)
			if bounds then return env.Vec(), env.Vec() end
			if tr then return env.Transform() end
			if vec then return env.Vec() end
			if list then return {} end
			return 0
		end
	end
	-- wrap a behaviour so calls are still recorded / checked
	function env.def(name, fn) env[name] = function(...) record(name) return fn(...) end end

	env.Vec = function(x,y,z) return {x or 0,y or 0,z or 0} end
	env.VecCopy = function(v) return {v[1],v[2],v[3]} end
	env.VecAdd = function(a,b) return {a[1]+b[1],a[2]+b[2],a[3]+b[3]} end
	env.VecSub = function(a,b) return {a[1]-b[1],a[2]-b[2],a[3]-b[3]} end
	env.VecScale = function(a,s) return {a[1]*s,a[2]*s,a[3]*s} end
	env.VecLength = function(a) return math.sqrt(a[1]^2+a[2]^2+a[3]^2) end
	env.VecNormalize = function(a) local l = env.VecLength(a) return l > 0 and env.VecScale(a, 1/l) or a end
	env.Quat = function() return {0,0,0,1} end
	env.QuatLookAt = env.Quat
	env.QuatEuler = env.Quat
	env.Transform = function(p, r) return { pos = p or env.Vec(), rot = r or env.Quat() } end
	env.TransformToParentPoint = function(t, p) return env.VecAdd(t.pos, p) end
	env.TransformToParentVec = function(t, v) return env.VecCopy(v) end
	env.TransformToLocalVec = function(t, v) return env.VecCopy(v) end
	-- rotation ignored (identity) - enough for smoke tests
	env.TransformToLocalPoint = function(t, p) return env.VecSub(p, t.pos) end
	env.TransformToParentTransform = function(t, l) return env.Transform(env.VecAdd(t.pos, l.pos), l.rot) end
	env.TransformToLocalTransform = function(t, w) return env.Transform(env.VecSub(w.pos, t.pos), w.rot) end
	env.VecLerp = function(a, b, f) return {a[1]+(b[1]-a[1])*f, a[2]+(b[2]-a[2])*f, a[3]+(b[3]-a[3])*f} end
	env.VecCross = function(a, b) return {a[2]*b[3]-a[3]*b[2], a[3]*b[1]-a[1]*b[3], a[1]*b[2]-a[2]*b[1]} end
	env.VecDot = function(a, b) return a[1]*b[1]+a[2]*b[2]+a[3]*b[3] end
	env.T = 0
	env.GetTime = function() return env.T end
	env.GetTimeStep = function() return 1/60 end

	-- players
	env.PLAYERS = { [1] = { pos = {0,0,0}, health = 1 } }
	env.ORDER = { 1 }
	env.LOCAL = 1
	env.Players = function() local i = 0 return function() i = i + 1 return env.ORDER[i] end end
	env.ADDED, env.REMOVED = {}, {} -- player ids reported once by PlayersAdded / PlayersRemoved
	env.PlayersAdded = function() local i = 0 return function() i = i + 1 return env.ADDED[i] end end
	env.PlayersRemoved = function() local i = 0 return function() i = i + 1 return env.REMOVED[i] end end
	env.def("Spawn", function() return {} end)
	env.def("UiWorldToPixel", function() return 0, 0, 10 end)
	env.def("UiGetTextSize", function() return 10, 10 end)
	env.def("UiText", function() return 10, 10 end)
	env.def("GetPlayerTransform", function(p) p = (p and p ~= 0) and p or env.LOCAL return env.Transform(env.VecCopy(env.PLAYERS[p].pos)) end)
	env.def("GetPlayerCameraTransform", function(p) return env.GetPlayerTransform(p) end)
	env.def("GetPlayerHealth", function(p) p = (p and p ~= 0) and p or env.LOCAL return env.PLAYERS[p].health end)
	env.def("GetPlayerVelocity", function() return env.Vec() end)
	env.def("GetPlayerVehicle", function() return 0 end)
	env.def("GetLocalPlayer", function() return env.LOCAL end)
	env.def("IsPlayerHost", function(p) return p == 1 end)
	env.def("IsMultiplayer", function() return #env.ORDER > 1 end)

	-- registry
	env.R = {}
	for _, t in ipairs({"Int", "Float", "String", "Bool"}) do
		local default = 0
		if t == "String" then default = "" elseif t == "Bool" then default = false end -- (v1 of this line gave 0 for Bool)
		env["Get" .. t] = function(k) local v = env.R[k] if v == nil then return default end return v end
		env["Set" .. t] = function(k, v) env.R[k] = v end
	end

	-- network
	env.sent = {}
	env.ClientCall = function(p, fn, ...) env.sent[#env.sent + 1] = { to = p, fn = fn, args = {...} } end
	env.ServerCall = function(fn, ...) env.sent[#env.sent + 1] = { to = "server", fn = fn, args = {...} } end
	env.server, env.client, env.shared = {}, {}, {}

	for k, v in pairs(opts.overrides or {}) do env[k] = v end

	-- library files run in the same environment first (e.g. lib/TDSU/compat.lua for util.serialize)
	for _, lib in ipairs(opts.preload or {}) do
		local lsrc = io.open(lib, "rb"):read("*a"):gsub("\r", "")
		lsrc = lsrc:gsub("([^\n]*)", function(l) if l:match("^%s*#") then return "" end return l end)
		local lchunk = assert(loadstring(lsrc, lib))
		setfenv(lchunk, env)
		lchunk()
	end

	local src = io.open(path, "rb"):read("*a"):gsub("\r", "")
	src = src:gsub('#include "script/include/player.lua"', "")
	for _, rel in ipairs(opts.inline or {}) do
		src = src:gsub('#include "' .. rel:gsub("%p", "%%%0") .. '"', function()
			return (io.open(opts.inlineDir .. rel, "rb"):read("*a"):gsub("\r", ""))
		end)
	end
	src = src:gsub("([^\n]*)", function(l) if l:match("^%s*#") then return "" end return l end)
	local chunk = assert(loadstring(src, path))
	setfenv(chunk, env)
	chunk()
	return env
end

--- Files a script includes, in load order (same resolution as tools/porting/toplevel.lua; engine includes such as
--- "script/include/player.lua" are skipped). Pass as opts.preload to run a script with its libraries.
function MockEngine.includes(entry)
	local seen, order = {}, {}
	local function dirname(p) return p:match("^(.*)/[^/]*$") or "." end
	local function norm(p)
		local parts = {}
		for seg in p:gmatch("[^/]+") do
			if seg == ".." then table.remove(parts) elseif seg ~= "." then parts[#parts + 1] = seg end
		end
		return table.concat(parts, "/")
	end
	local function exists(p) local f = io.open(p, "rb") if f then f:close() return true end end
	local function visit(rel, top)
		rel = norm(rel)
		if seen[rel] then return end
		seen[rel] = true
		local src = io.open(rel, "rb"):read("*a")
		for inc in src:gmatch('#include%s*"([^"]+)"') do
			local cand = norm(dirname(rel) .. "/" .. inc)
			if exists(cand) then visit(cand) elseif exists(norm(inc)) then visit(norm(inc)) end
		end
		if not top then order[#order + 1] = rel end
	end
	visit(entry, true)
	return order
end

return MockEngine

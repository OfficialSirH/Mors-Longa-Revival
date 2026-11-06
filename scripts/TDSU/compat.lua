--================================================================
-- compat.lua  (Mors Longa Revival)
--
-- Drop-in replacement for the parts of Thomasims' UMF that Mors Longa
-- actually used:
--   util.structured_table, util.serialize, util.unserialize,
--   IsPlayerInVehicle
--
-- UMF is not used anymore because it detours the global v1 callbacks
-- (init/tick/draw), which does not work with Teardown 2.x multiplayer
-- (#version 2) scripts. Behaviour of the functions below matches UMF v0.9.1.
--================================================================

util = util or {}

do
	local serialize_any, serialize_table

	serialize_table = function(val, seen)
		if seen[val] then return "nil" end
		seen[val] = true
		local entries = {}
		for k, v in pairs(val) do
			entries[#entries + 1] = string.format("[%s] = %s", serialize_any(k, seen), serialize_any(v, seen))
		end
		return string.format("{%s}", table.concat(entries, ","))
	end

	serialize_any = function(val, seen)
		local vtype = type(val)
		if vtype == "table" then
			return serialize_table(val, seen)
		elseif vtype == "string" then
			return string.format("%q", val)
		elseif vtype == "function" or vtype == "userdata" then
			return "nil"
		else
			return tostring(val)
		end
	end

	--- Serializes values to a lua-like string (same format as UMF).
	function util.serialize(...)
		local result = {}
		for i = 1, select("#", ...) do
			result[i] = serialize_any(select(i, ...), {})
		end
		return table.concat(result, ",")
	end
end

--- Unserializes a string produced by util.serialize.
function util.unserialize(str)
	if str == nil or str == "" then return nil end
	local fn = loadstring("return " .. str)
	if fn then
		setfenv(fn, {})
		return fn()
	end
end

do
	local gets = {
		number  = GetFloat,
		integer = GetInt,
		boolean = GetBool,
		string  = GetString,
		table   = function(key) return util.unserialize(GetString(key)) end,
	}
	local sets = {
		number  = SetFloat,
		integer = SetInt,
		boolean = SetBool,
		string  = SetString,
		table   = function(key, val) SetString(key, util.serialize(val)) end,
	}

	--- Creates a table whose fields are backed by registry keys under `name`.
	--- Field definitions: { "type", default } or "type", where type is
	--- number | integer | boolean | string | table. Nested plain tables
	--- become nested structured tables.
	function util.structured_table(name, base)
		local function generate(def)
			local root = {}
			local keys = {}
			for k, v in pairs(def) do
				local key = name .. "." .. tostring(k)
				if type(v) == "table" then
					if #v == 0 then
						root[k] = util.structured_table(key, v)
					else
						keys[k] = { type = v[1], key = key, default = v[2] }
					end
				elseif type(v) == "string" then
					keys[k] = { type = v, key = key }
				else
					root[k] = v
				end
			end
			return setmetatable(root, {
				__index = function(_, k)
					local entry = keys[k]
					if entry and gets[entry.type] then
						if HasKey(entry.key) then
							return gets[entry.type](entry.key)
						end
						return entry.default
					end
				end,
				__newindex = function(_, k, v)
					local entry = keys[k]
					if entry and sets[entry.type] then
						return sets[entry.type](entry.key, v)
					end
				end,
			})
		end
		if type(base) == "table" then
			return generate(base)
		end
		return generate
	end
end

--- True if the player is in a vehicle. playerId is optional
--- (defaults to the local/host player, like the engine functions).
function IsPlayerInVehicle(playerId)
	return GetPlayerVehicle(playerId) ~= 0
end

--- UMF replaced the global print; keep a safe fallback in case the
--- engine does not provide one in some context.
print = print or function(...) end

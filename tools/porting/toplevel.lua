-- Usage: lua51 toplevel.lua <repo_root> <entry.lua>
-- Loads a Teardown script with its #include chain and reports engine API calls
-- made while the file loads (v2 forbids them before init).
local root, entry = arg[1], arg[2]
local seen, order = {}, {}
local function dirname(p) return p:match("^(.*)/[^/]*$") or "." end
local function norm(p)
  local parts = {}
  for seg in p:gmatch("[^/]+") do
    if seg == ".." then table.remove(parts) elseif seg ~= "." then parts[#parts+1] = seg end
  end
  return table.concat(parts, "/")
end
local function exists(p) local f = io.open(root.."/"..p, "rb") if f then f:close() return true end end
local function visit(rel)
  rel = norm(rel)
  if seen[rel] then return end
  seen[rel] = true
  local f = assert(io.open(root.."/"..rel, "rb"), rel); local src = f:read("*a"); f:close()
  for inc in src:gmatch('#include%s*"([^"]+)"') do
    local cand = norm(dirname(rel).."/"..inc)
    if exists(cand) then visit(cand)
    elseif exists(norm(inc)) then visit(norm(inc))
    else order[#order+1] = {engine=inc} end
  end
  order[#order+1] = {file=rel, src=src}
end
visit(entry)
local calls = {}
local current = "?"
local env = setmetatable({}, {__index = function(t, k)
  local v = rawget(_G, k); if v ~= nil then return v end
  if type(k) == "string" and k:match("^[A-Z]") then
    local fn = function(...) local key = current.." -> "..k; calls[key] = (calls[key] or 0) + 1
      if k:match("^Vec$") or k:match("^Quat") or k:match("^Transform") then return {0,0,0,pos={0,0,0},rot={0,0,0,1}} end
      if k == "GetString" then return "" end
      if k:match("^Find%u%l+s$") or k:match("^List") then return {} end
      return 0 end
    rawset(t, k, fn); return fn
  end
end})
env.server, env.client, env.shared = {}, {}, {}
env._G = env
for _, item in ipairs(order) do
  if item.file then
    current = item.file
    local src = item.src:gsub("\r", ""):gsub("([^\n]*)", function(l) if l:match("^%s*#") then return "" end return l end)
    local fn, err
    if setfenv then -- Lua 5.1
      fn, err = loadstring(src, "@"..item.file)
      if fn then setfenv(fn, env) end
    else -- Lua 5.2+ (e.g. texlua from TeX Live)
      fn, err = load(src, "@"..item.file, "t", env)
    end
    if not fn then print("SYNTAX", err) else
      local ok, e = pcall(fn); if not ok then print("RUNTIME", item.file, e) end
    end
  else print("engine include:", item.engine) end
end
local keys = {} for k in pairs(calls) do keys[#keys+1] = k end table.sort(keys)
for _, k in ipairs(keys) do print(("%4d  %s"):format(calls[k], k)) end

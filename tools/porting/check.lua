-- Usage: lua51 check.lua file1 file2 ...
-- Teardown preprocessor lines (#include/#version) are blanked before compiling.
local bad = 0
for _, path in ipairs(arg) do
  local f = assert(io.open(path, "rb")); local src = f:read("*a"); f:close()
  src = src:gsub("^\239\187\191", "")
  src = src:gsub("([^\n]*)", function(line)
    if line:match("^%s*#") then return "" end
    return line
  end)
  local fn, err = loadstring(src, "@" .. path)
  if not fn then bad = bad + 1; print("SYNTAX " .. err) end
end
print(("checked %d file(s), %d error(s)"):format(#arg, bad))
os.exit(bad == 0 and 0 or 1)

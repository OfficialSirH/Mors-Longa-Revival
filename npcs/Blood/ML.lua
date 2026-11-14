DebugEnabled = true
Presets = {
	Color = {
		red = {1,0,0,1},
		green = {0,1,0,1},
		blue = {0,0,1,1},
		yellow = {1,1,0,1},
	}
}
function MLDebugPrint(ScriptName, String)
	if DebugEnabled then
		DebugPrint("" .. ScriptName .. " | " .. String .. "")
	end
end


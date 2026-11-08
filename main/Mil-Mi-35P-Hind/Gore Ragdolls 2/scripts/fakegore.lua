#version 2
#include "script/include/player.lua"
-- (v2) server: helicopter crew ragdoll (full ragdoll spawned when a body part breaks).
function server.init()
	TORSO = FindShape("TORSO")
end
function server.tick()
	if not done then
	bodyparts = FindShapes("bodypart")

		for i=1,#bodyparts do
			if IsShapeBroken(bodyparts[i]) then
			deleteandspawn = true
			cooltrans = GetShapeWorldTransform(TORSO)
			end
		end

		if deleteandspawn then
		shapes = FindShapes("")
		ragdollname = GetTagValue(TORSO, "ragdollname")
			for i=1,#shapes do
				Delete(shapes[i])
			end
			--DebugPrint("Ragdoll name: ".. ragdollname)
			Spawn("MOD/main/AS350/Gore Ragdolls 2/Sitters/" .. ragdollname .. ".xml", Transform(cooltrans.pos, cooltrans.rot))
			done = true
			--DebugPrint("MOD/main/Gore Ragdolls 2/Sitters/" .. ragdollname .. ".xml")
		end
	end
end

--used in the settings, I don't know what they do

-- (v2) v1 quickload hook removed: it called Init_Settings, which this script never defines (error on quickload)

function handle_quickload(cmd)
    for _, word in ipairs(splitString(cmd, " ")) do
        if word == "quickload" then
            Init_Settings()
        end
        break
    end
end

function splitString(str, delimiter)
    local result = {}
    for word in string.gmatch(str, '([^'..delimiter..']+)') do
        result[#result+1] = trim(word)
    end
    return result
end

function trim(s)
	return (s:gsub("^%s*(.-)%s*$", "%1"))
 end
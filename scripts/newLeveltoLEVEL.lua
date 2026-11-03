function init()
	recursiveKeyTransfer("savegame.mod.newLevel", "level")
	recursiveKeyTransfer("savegame.mod.newLevel", "savegame.mod.lastLevel")
	ClearKey("savegame.mod.newLevel")
end
function recursiveKeyTransfer(originParent, targetParent)
	local list = ListKeys(originParent)
	for i,key in pairs(list) do
		SetString(targetParent.."."..key,GetString(originParent.."."..key))
		recursiveKeyTransfer(originParent.."."..key, targetParent.."."..key)
	end
end
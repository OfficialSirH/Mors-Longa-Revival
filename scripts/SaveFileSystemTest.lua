function init()
	recursiveKeyTransfer("savegame.mod.newLevel", "level")
	recursiveKeyTransfer("savegame.mod.newLevel", "savegame.mod.lastLevel")
	ClearKey("savegame.mod.newLevel")
end
function triggerSave()

end
function tick()
	if InputDown("s") and InputDown("a") and InputDown("v") and InputPressed("e")then
		saveMigrationPatch1()
	end
	if InputDown("l") and InputDown("o") and InputDown("a") and InputPressed("d")then
	end
end

-- 2023-9-29: this patch will transfer all information to the new save file system
function saveMigrationPatch1()
	ClearKey("savegame.mod.saves.save1")
	SetString("savegame.mod.saves.save1.name", "Migrated Save File")
	SetString("savegame.mod.saves.save1.description", "This savefile is automaticly generated during the xxx Mors Longa update, ANY PROGRESSES ARE NOT LOST.")

	recursiveKeyTransfer("savegame.mod.inventory","savegame.mod.saves.save1.players.0.inventory", true)
	--recursiveKeyTransfer("savegame.mod.saves.save1.players.0.inventory.stash","savegame.mod.saves.save1.players.0.inventory.stash", true)
	recursiveKeyTransfer("savegame.mod.lastlevel.gamerule","savegame.mod.saves.save1.world_settings.gamerule ", true)
	recursiveKeyTransfer("savegame.mod.difficulty","savegame.mod.saves.save1.world_settings.gamerule.difficulty", true)
	recursiveKeyTransfer("savegame.mod.bountyboard","savegame.mod.saves.save1.bountyboard", true)
	recursiveKeyTransfer("savegame.mod.hunger","savegame.mod.saves.save1.players.0.health_system.hunger", true)
	recursiveKeyTransfer("savegame.mod.thirst","savegame.mod.saves.save1.players.0.health_system.thirst", true)
	recursiveKeyTransfer("savegame.mod.player.money","savegame.mod.saves.save1.players.0.money", true)
	recursiveKeyTransfer("savegame.mod.perks","savegame.mod.saves.save1.players.0.perks", true)
	recursiveKeyTransfer("savegame.mod.parkingspot","savegame.mod.saves.save1.parkingspot", true)
	recursiveKeyTransfer("savegame.mod.distanceprogressed","savegame.mod.saves.save1.distanceprogressed", true)

	

end

function recursiveKeyTransfer(originParent, targetParent, keep)
	SetString(targetParent,GetString(originParent))
	local list = ListKeys(originParent)
	for i=1, #list do
		local key = list[i]
		SetString(targetParent.."."..key,GetString(originParent.."."..key))
		recursiveKeyTransfer(originParent.."."..key, targetParent.."."..key)
	end
	if not keep then
		ClearKey(originParent)
	end
end
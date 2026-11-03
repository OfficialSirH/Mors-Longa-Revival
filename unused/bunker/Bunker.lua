function init()
Bunker = FindTrigger("bunker")


end



function tick(dt)

PlayerPos = GetPlayerPos()
BunkerPos = GetTriggerTransform(Bunker).pos
	if IsPointInTrigger(Bunker, PlayerPos) then
		loadlevel()
	end
end

function loadlevel()
SetFloat("savegame.mod.newLevel.gamerule.lrarity", GetFloat("savegame.mod.lastLevel.gamerule.lrarity"))
	SetBool("savegame.mod.newLevel.gamerule.drugs", GetBool("savegame.mod.lastLevel.gamerule.drugs"))
	SetBool("savegame.mod.newLevel.gamerule.god", GetBool("savegame.mod.lastLevel.gamerule.god"))
	SetBool("savegame.mod.newLevel.gamerule.infuel", GetBool("savegame.mod.lastLevel.gamerule.infuel"))
	SetBool("savegame.mod.newLevel.gamerule.keepinv", GetBool("savegame.mod.lastLevel.gamerule.keepinv"))
	SetBool("savegame.mod.newLevel.gamerule.nhat", GetBool("savegame.mod.lastLevel.gamerule.nhat"))
	SetBool("savegame.mod.newLevel.gamerule.permadeath", GetBool("savegame.mod.lastLevel.gamerule.permadeath"))
	SetBool("savegame.mod.newLevel.gamerule.armored", GetBool("savegame.mod.lastLevel.gamerule.armored"))
	local diff = GetString("savegame.mod.difficulty")
	if diff == "custom" then
		diff = "normal"
	end
	StartLevel("", "MOD/unused/bunker/bunker.xml", diff .. " nodev")

end
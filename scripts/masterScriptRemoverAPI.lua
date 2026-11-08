function queueRemoval()
	local queueCount = GetInt("level.script_remover.queue.count")
	SetInt("level.script_remover.queue.count", queueCount+1)

	local id = "_mSR_"..queueCount*queueCount
	PauseMenuButton(id)
	local items = ListKeys("game.pausemenu.items")
	for i=1, #items do
		local handle = items[i]
		local p = "game.pausemenu.items." .. handle
		if GetString(p) == id then
			ClearKey(p)
			SetString("level.script_remover.queue."..queueCount+1, handle)
		end
	end
end
function tick()
	queueRemoval()
end
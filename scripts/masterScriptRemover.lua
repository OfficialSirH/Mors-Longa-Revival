#version 2
#include "script/include/player.lua"
-- (v2) server: deletes scripts queued for removal by other scripts (level.script_remover.queue).
function server.tick(dt)
	handleDeletionQueue()
end

function handleDeletionQueue()
	local queueCount = GetInt("level.script_remover.queue.count")
	for i=1, queueCount do
		local handle = GetInt("level.script_remover.queue."..i)
		if GetEntityType(handle)=="script"then
			if IsHandleValid(handle)then
				Delete(handle)
				local msg = "Correctly removed script: "..handle
				--DebugPrint(msg)
				print(msg)
			else
				local msg = "Script is already removed wtf: "..handle
				--DebugPrint(msg)
				print(msg)
			end
		else
			local msg = "Entity incorrectly marked for removal: "..handle.." ("..GetEntityType(handle)..")"
			--DebugPrint(msg)
			print(msg)
		end
		ClearKey("level.script_remover.queue."..handle)
	end
	SetInt("level.script_remover.queue.count",0)
end
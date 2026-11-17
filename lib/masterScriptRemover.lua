#version 2
#include "script/include/player.lua"
-- (v2) server: deletes scripts queued for removal by other scripts (level.script_remover.queue).
function server.tick(dt)
	handleDeletionQueue()
end

-- (2026-11-17) used again: finished spawned scripts queue their own handle (lib/ScriptSelfDelete.lua); a script must
-- not delete itself (that crashed the game), this one deletes them from its own tick. v1 cleared the key named by
-- the handle instead of the queue index (entries piled up) and printed every removal to the log.
function handleDeletionQueue()
	local queueCount = GetInt("level.script_remover.queue.count")
	if queueCount <= 0 then return end
	for i=1, queueCount do
		local key = "level.script_remover.queue."..i
		local handle = GetInt(key)
		if handle ~= 0 and IsHandleValid(handle) and GetEntityType(handle) == "script" then
			Delete(handle)
		end
		ClearKey(key)
	end
	SetInt("level.script_remover.queue.count",0)
end
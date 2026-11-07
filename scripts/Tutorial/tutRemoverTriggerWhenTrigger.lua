#version 2
#include "script/include/player.lua"
-- (v2) server: a "tutTrigRemove" trigger is removed as soon as ANY player enters it (v1: the one player).
function server.init()
	triggers = FindTriggers("tutTrigRemove",true)
end

function server.tick(dt)
	for p in Players() do
		local pos = GetPlayerTransform(p).pos
		for i=#triggers, 1, -1 do
			local trigger = triggers[i]
			if IsPointInTrigger(trigger,pos)then
				Delete(trigger)
				table.remove(triggers,i)
			end
		end
	end
end

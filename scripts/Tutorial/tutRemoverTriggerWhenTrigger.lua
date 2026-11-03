function init()
	triggers = FindTriggers("tutTrigRemove",true)
end
function tick(dt)
	local pT = GetPlayerTransform()
	for i=#triggers, 1, -1 do
		local trigger = triggers[i]
		if IsPointInTrigger(trigger,pT.pos)then
			Delete(trigger)
			table.remove(triggers,i)
		end
	end
end

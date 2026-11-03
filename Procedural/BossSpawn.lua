function init()
end
function tick()
	Locations = FindLocations("RandomBoss",true)
	DayPhase = GetString("level.dayphase")
	Distance = GetInt("level.distancetraveled")
	--DebugPrint(DayPhase)
	for i=1,#Locations do
		Location = Locations[i]
		Type = tostring(GetTagValue(Location, "Type"))
		LocPos = GetLocationTransform(Location)
		if Distance > 16 then
		if GetBool("savegame.mod.bountyboard."..Type) == false then
			if Type ~= "BossCultist" and DayPhase ~= "Night" then
				Spawn("MOD/prefabs/"..Type..".xml", LocPos)
			end

			if Type == "BossCultist" and DayPhase == "Night" then
				Spawn("MOD/prefabs/"..Type..".xml", LocPos)
			end
		end
	end
		Delete(Location)
end
end
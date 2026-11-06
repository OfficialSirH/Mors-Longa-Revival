#version 2
#include "script/include/player.lua"
-- (v2) client: per-machine player id + ban check (BanTable is empty).
CharTable = {"A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z","a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z","0","1","2","3","4","5","6","7","8","9"}
BanTable = {}
function client.init()
	if not GetBool("savegame.mod.morb.inventory.playeid.initated") then
		local String = {}
		for i=1,10 do 
			if i ~= 1 and String[i-1] ~= "-" and math.random() <= .25 then
				String[i] = "-"
			else
				String[i] = CharTable[math.random(1,#CharTable)]
			end
		end
	
	SetString("savegame.mod.morb.inventory.playeid.string", tostring(table.concat(String,"")))
	SetBool("savegame.mod.morb.inventory.playeid.initated", true)
	end
	PlayerId = GetString("savegame.mod.morb.inventory.playeid.string")
	Banned = PlayerBanCheck(PlayerId)
end

function PlayerBanCheck(id)
	local IsBanned = false
	for PlayerName, ID in pairs(BanTable) do
		if ID == id then
			IsBanned = true
		end
	end
	return IsBanned
end

function client.tick(dt)
	if Banned then 
		Menu()
	end
end	

function client.draw()
	-- DebugPrint(PlayerId)
end
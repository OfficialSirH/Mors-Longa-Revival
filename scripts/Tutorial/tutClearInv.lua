function init()
	for i = 1,8 do
		for j = 1,15 do
			SetString("inventory.backpack."..i.."_"..j..".item", "") SetString("savegame.mod.inventory.backpack."..i.."_"..j..".item", "")
		end
	end
	for j = 1,3 do
		SetString("inventory.guns."..j..".item", "") SetString("savegame.mod.inventory.guns."..j..".item", "")
	end
	for j = 1,3 do
		SetString("inventory.armor."..j..".item", "") SetString("savegame.mod.inventory.armor."..j..".item", "")
	end
end
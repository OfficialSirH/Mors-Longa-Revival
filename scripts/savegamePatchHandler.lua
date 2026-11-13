-- this is where all the savegame patching happenes
function savegamePatchHandler()
	move_inv_stuff_1()
	headwear_mosin_id_change_1()
	grey_scar_id_change_1()
	--AttachmentNameStandardization()
	inventory_flip()
	complex_inventory_support()
end

-- this patch will organize all inventory related saves into its own and already existing inventory key
function move_inv_stuff_1()
	if not GetBool("savegame.mod.version.patches.move_inv_stuff_1")then
		if HasKey("savegame.mod.backpack")then
			recursiveKeyTransfer("savegame.mod.backpack","savegame.mod.inventory.backpack")
		end
		if HasKey("savegame.mod.stash")then
			recursiveKeyTransfer("savegame.mod.stash","savegame.mod.inventory.stash")
		end
		if HasKey("savegame.mod.guns1")then
			recursiveKeyTransfer("savegame.mod.guns1","savegame.mod.inventory.guns.1")
		end
		if HasKey("savegame.mod.guns2")then
			recursiveKeyTransfer("savegame.mod.guns2","savegame.mod.inventory.guns.2")
		end
		if HasKey("savegame.mod.guns3")then
			recursiveKeyTransfer("savegame.mod.guns3","savegame.mod.inventory.guns.3")
		end
		if HasKey("savegame.mod.guns4")then
			recursiveKeyTransfer("savegame.mod.guns4","savegame.mod.inventory.guns.4")
		end
		if HasKey("savegame.mod.armor1")then
			recursiveKeyTransfer("savegame.mod.armor1","savegame.mod.inventory.armor.1")
		end
		if HasKey("savegame.mod.armor2")then
			recursiveKeyTransfer("savegame.mod.armor2","savegame.mod.inventory.armor.2")
		end
		if HasKey("savegame.mod.armor3")then
			recursiveKeyTransfer("savegame.mod.armor3","savegame.mod.inventory.armor.3")
		end

		-- we are already patching old savegames, clean is not exactly what we are looking for now
		-- this is why im also nuking the savegame.mod.inventory.weight right here
		ClearKey("savegame.mod.inventory.weight")
		
		SetBool("savegame.mod.version.patches.move_inv_stuff_1", true)
	end
end
-- 2023-5-14: this patch will deal with headwear id change and military skin mosin change
function headwear_mosin_id_change_1()
	if not GetBool("savegame.mod.version.patches.headwear_mosin_id_change_1")then
		for i = 1,8 do
			for j = 1,15 do
				local item = GetString("savegame.mod.inventory.backpack."..i.."_"..j)
				if item ~= "" then
					local itemInfos = Split(item, "_")
					local itemID = itemInfos[1]
					local itemIDInfos = Split(itemID, "-")

					if (itemID == "nvg" or itemID == "thermals") then
						SetString("savegame.mod.inventory.backpack."..i.."_"..j, "eyewear-"..item)
					end

					if itemID == "gun-mosin" and #itemInfos >= 8 then
						local itemAttInfos = Split(itemInfos[8], "-")
						if itemAttInfos[4] == "grey" then
							itemInfos[1] = "gun-mosinm" -- fix id
							itemAttInfos[4] = "" -- remove skin 1)
							itemInfos[8] = table.concat(itemAttInfos,"-") -- remove skin 2)
							SetString("savegame.mod.inventory.backpack."..i.."_"..j, IDBuilder(itemInfos))
						end
					end

				end
			end
		end

		for i = 1,1 do
			for j = 1,3 do
				local item = GetString("savegame.mod.inventory.armor."..j)
				if item ~= "" then
					local itemInfos = Split(item, "_")
					local itemID = itemInfos[1]
					local itemIDInfos = Split(itemID, "-")

					if (itemID == "nvg" or itemID == "thermals") then
						SetString("savegame.mod.inventory.armor."..j, "eyewear-"..item)
					end

				end
			end
		end
	
		for i = 1,1 do
			for j = 1,4 do
				local item = GetString("savegame.mod.inventory.guns."..j)
				if item ~= "" then
					local itemInfos = Split(item, "_")
					local itemID = itemInfos[1]
					local itemIDInfos = Split(itemID, "-")

					if itemID == "gun-mosin" and #itemInfos >= 8 then
						local itemAttInfos = Split(itemInfos[8], "-")
						if itemAttInfos[4] == "grey" then
							itemInfos[1] = "gun-mosinm" -- fix id
							itemAttInfos[4] = "" -- remove skin 1)
							itemInfos[8] = table.concat(itemAttInfos,"-") -- remove skin 2)
							SetString("savegame.mod.inventory.guns."..j, IDBuilder(itemInfos))
						end
					end

				end
			end
		end
	
		for i = 1,8 do
			for j = 1,15 do
				local item = GetString("savegame.mod.inventory.stash."..i.."_"..j)
				if item ~= "" then
					local itemInfos = Split(item, "_")
					local itemID = itemInfos[1]
					local itemIDInfos = Split(itemID, "-")

					if (itemID == "nvg" or itemID == "thermals") then
						SetString("savegame.mod.inventory.stash."..i.."_"..j, "eyewear-"..item)
					end

					if itemID == "gun-mosin" and #itemInfos >= 8 then
						local itemAttInfos = Split(itemInfos[8], "-")
						if itemAttInfos[4] == "grey" then
							itemInfos[1] = "gun-mosinm" -- fix id
							itemAttInfos[4] = "" -- remove skin 1)
							itemInfos[8] = table.concat(itemAttInfos,"-") -- remove skin 2)
							SetString("savegame.mod.inventory.stash."..i.."_"..j, IDBuilder(itemInfos))
						end
					end

				end
			end
		end

		SetBool("savegame.mod.version.patches.headwear_mosin_id_change_1", true)
	end
end
-- 2023-5-18: this patch will change the scar camo into its own gun
function grey_scar_id_change_1()
	-- DebugPrint("pp")
	if not GetBool("savegame.mod.version.patches.grey_scar_id_change_1") then
		for i = 1,8 do
			for j = 1,15 do
				local item = GetString("savegame.mod.inventory.backpack."..i.."_"..j)
				if item ~= "" then
					local itemInfos = Split(item, "_")
					local itemID = itemInfos[1]
					local itemIDInfos = Split(itemID, "-")

					if itemID == "gun-scarh" and #itemInfos >= 8 then
						local itemAttInfos = Split(itemInfos[8], "-")
						if itemAttInfos[9] == "grey" then
							itemInfos[1] = "gun-scarhg" -- fix id
							itemAttInfos[9] = "" -- remove skin 1)
							itemInfos[8] = table.concat(itemAttInfos,"-") -- remove skin 2)
							SetString("savegame.mod.inventory.backpack."..i.."_"..j, IDBuilder(itemInfos))
						end
					end
					if itemID == "gun-scarl" and #itemInfos >= 8 then
						local itemAttInfos = Split(itemInfos[8], "-")
						if itemAttInfos[9] == "grey" then
							itemInfos[1] = "gun-scarlg" -- fix id
							itemAttInfos[9] = "" -- remove skin 1)
							itemInfos[8] = table.concat(itemAttInfos,"-") -- remove skin 2)
							SetString("savegame.mod.inventory.backpack."..i.."_"..j, IDBuilder(itemInfos))
						end
					end

				end
			end
		end

	
		for i = 1,1 do
			for j = 1,4 do
				local item = GetString("savegame.mod.inventory.guns."..j)
				if item ~= "" then
					local itemInfos = Split(item, "_")
					local itemID = itemInfos[1]
					local itemIDInfos = Split(itemID, "-")

					if itemID == "gun-scarh" and #itemInfos >= 8 then
						local itemAttInfos = Split(itemInfos[8], "-")
						if itemAttInfos[9] == "grey" then
							itemInfos[1] = "gun-scarhg" -- fix id
							itemAttInfos[9] = "" -- remove skin 1)
							itemInfos[8] = table.concat(itemAttInfos,"-") -- remove skin 2)
							SetString("savegame.mod.inventory.backpack."..i.."_"..j, IDBuilder(itemInfos))
						end
					end
					if itemID == "gun-scarl" and #itemInfos >= 8 then
						local itemAttInfos = Split(itemInfos[8], "-")
						if itemAttInfos[9] == "grey" then
							itemInfos[1] = "gun-scarlg" -- fix id
							itemAttInfos[9] = "" -- remove skin 1)
							itemInfos[8] = table.concat(itemAttInfos,"-") -- remove skin 2)
							SetString("savegame.mod.inventory.backpack."..i.."_"..j, IDBuilder(itemInfos))
						end
					end

				end
			end
		end
	
		for i = 1,8 do
			for j = 1,15 do
				local item = GetString("savegame.mod.inventory.stash."..i.."_"..j)
				if item ~= "" then
					local itemInfos = Split(item, "_")
					local itemID = itemInfos[1]
					local itemIDInfos = Split(itemID, "-")

					if itemID == "gun-scarh" and #itemInfos >= 8 then
						local itemAttInfos = Split(itemInfos[8], "-")
						if itemAttInfos[9] == "grey" then
							itemInfos[1] = "gun-scarhg" -- fix id
							itemAttInfos[9] = "" -- remove skin 1)
							itemInfos[8] = table.concat(itemAttInfos,"-") -- remove skin 2)
							SetString("savegame.mod.inventory.backpack."..i.."_"..j, IDBuilder(itemInfos))
						end
					end
					if itemID == "gun-scarl" and #itemInfos >= 8 then
						local itemAttInfos = Split(itemInfos[8], "-")
						if itemAttInfos[9] == "grey" then
							itemInfos[1] = "gun-scarlg" -- fix id
							itemAttInfos[9] = "" -- remove skin 1)
							itemInfos[8] = table.concat(itemAttInfos,"-") -- remove skin 2)
							SetString("savegame.mod.inventory.backpack."..i.."_"..j, IDBuilder(itemInfos))
						end
					end

				end
			end
		end

		SetBool("savegame.mod.version.patches.grey_scar_id_change_1", true)
	end
end
--2024-1-1: Standardizes Attachment Names
function AttachmentNameStandardization()
	gunattachments = {
		ar15 		= {
			"toprail",
			"canted",
			"muzzle",
			"stock",
			"grip",
			"barrel",
			"side",
			"guard",
			"magnifier",
			"camo"},
		ak74 		= {
			"toprail",
			"toprail2",
			"muzzle",
			"stock",
			"grip",
			"barrel",
			"side",
			"guard",
			"modernguard",
			"dustcover",
			"camo"},
		ak74m 		= {
			"toprail",
			"muzzle",
			"stock",
			"grip",
			"barrel",
			"side",
			"guard",
			"dustcover"},		
		ak101 		= {
			"toprail",
			"toprail2",
			"muzzle",
			"stock",
			"grip",
			"barrel",
			"side",
			"guard",
			"modernguard",
			"dustcover",
			"camo"},
		akm 		= {
			"toprail",
			"toprail2",
			"muzzle",
			"stock",
			"grip",
			"barrel",
			"side",
			"guard",
			"modernguard",
			"dustcover"},
		g3 			= {
			"toprail",
			"muzzle",
			"stock",
			"grip",
			"barrel",
			"side",
			"guard"},
		g17 		= {
			"toprail",
			"muzzle",
			"stock",
			"side",
			"camo"},
		g18 		= {
			"toprail",
			"muzzle",
			"stock",
			"side",
			"camo"},
		tt33		= {
			"toprail",
			"muzzle",
			"stock",
			"side",
			"camo"},
		fiveseven	= {
			"toprail",
			"muzzle",
			"stock",
			"side",
			"camo"},
		deagle		= {	
			"toprail",
			"muzzle",
			"stock",
			"side",
			"camo"},
		m9			= {
			"toprail",
			"muzzle",
			"stock",
			"side",
			"camo"},
		g36k		= { 
			"toprail",
			"muzzle",
			"stock",
			"grip",
			"barrel",
			"side",
			"guard",
			"magnifier"},
		m16 		= {
			"toprail",
			"canted",
			"muzzle",
			"stock",
			"grip",
			"barrel",
			"side",
			"guard",
			"magnifier",
			"camo"},
		m107		= {
			"toprail",
			"canted",
			"muzzle",
			"stock",
			"grip",
			"barrel",
			"side",
			"guard",
			"magnifier",
			"camo"},
		m870		= {
			"toprail",
			"muzzle",
			"stock",
			"grip",
			"side",
			"camo"},
		mp5			= {	
			"toprail",
			"muzzle",
			"stock",
			"grip",
			"barrel",
			"side",
			"guard"},
		p90			= {	
			"toprail",
			"muzzle",
			"stock",
			"grip",
			"barrel",
			"side",
			"guard",
			"magnifier"},
		pp19		= {		
			"toprail",
			"muzzle",
			"stock",
			"grip",
			"barrel",
			"side",
			"guard",
			"dustcover"},
		scarh		= {
			"toprail",
			"muzzle",
			"grip",
			"barrel",
			"side",
			"guard",
			"magnifier",
			"camo"},
		scarhg		= {
			"toprail",
			"muzzle",
			"grip",
			"barrel",
			"side",
			"guard",
			"magnifier",
			"camo"},
		scarl		= {
			"toprail",
			"muzzle",
			"grip",
			"barrel",
			"side",
			"guard",
			"magnifier",
			"camo"},
		scarlg		= {
			"toprail",
			"muzzle",
			"grip",
			"barrel",
			"side",
			"guard",
			"magnifier",
			"camo"},
		sks			= {
			"toprail",
			"muzzle",
			"stock",
			"grip",
			"side",
			"guard",
			"camo"},
		svd			= {		
			"toprail",
			"toprail2",
			"muzzle",
			"stock",
			"grip",
			"barrel",
			"side",
			"guard",
			"modernguard",
			"dustcover"},
		vector		= {
			"toprail",
			"muzzle",
			"grip",
			"barrel",
			"side",
			"guard"},
		mosin 		= {
			"toprail",
			"muzzle",
			"stock"},
		mosinm 		= {	
			"toprail",
			"muzzle",
			"stock",
			"side"},

	}

	Guns = {
		["ak74"] = {
			["toprail"] = { 
				["scope"] = "scope",
				["holo"] = "holo",
				["kobra"] = "kobra",
				[""] = "",
			},
			["muzzle"] = {
				["muzzle1"] = "muzzle1",
				["muzzle2"] = "muzzle2",
			},	
			["stock"] = {
				["stock1"] = "stock1",
				["stock2"] = "stock2",
				["stock3"] = "stock3",
				["removed"] = "removed",
				[""] = "",
			},
			["grip"] = {
				["grip1"] = "grip1",
				["grip2"] = "grip2",
				["grip3"] = "grip3",
			},
			["barrel"] = {
				["barrel1"] = "barrel1",
				["barrel2"] = "barrel2",
			},	
			["side"] = {
				["side1"] = "side1",
				["side2"] = "side2",
				["side3"] = "side3",
			},
		},
	}
		
	for i = 1,8 do
		for j = 1,15 do
			local item = GetString("savegame.mod.inventory.backpack."..i.."_"..j)
			if item ~= "" then
				local itemInfos = Split(item, "_")
				local itemID = itemInfos[1]
				local itemIDInfos = Split(itemID, "-")

				if itemIDInfos[1] == "gun" and #itemInfos >= 8 then
					local itemAttInfos = Split(itemInfos[8], "-")
					for p=1,#itemAttInfos do 
						--if Guns[itemIDInfos[2]][gunattachments[itemIDInfos[2]][p]][itemAttInfos[p]] then
							--itemAttInfos[p] = Guns[itemIDInfos[2]][gunattachments[itemIDInfos[2]][p]][itemAttInfos[p]]
							DebugPrint(itemAttInfos[p])
							DebugPrint(guns[itemIDInfos[2]][gunattachments[itemIDInfos[2]][p]][itemAttInfos[p]])
						--end
					end
					itemInfos[8] = table.concat(itemAttInfos,"-")
					SetString("savegame.mod.inventory.backpack."..i.."_"..j, IDBuilder(itemInfos))
				end
			end
		end
	end
end
--2024-8-7: did you know your inventory is upside down for almost 2 years?
function inventory_flip()
	if not GetBool("savegame.mod.version.patches.inventory_flip")then
		local temp = {}
		for i = 1,8 do
			temp[i]={}
			for j = 1,15 do
				local item = GetString("savegame.mod.inventory.backpack."..i.."_"..j)
				if item ~= "" then
					temp[i][15-j+1] = item
				end
			end
		end
		for i = 1,8 do
			for j = 1,15 do
				SetString("savegame.mod.inventory.backpack."..i.."_"..j, temp[i][j])
			end
		end
	
		for i = 1,8 do
			for j = 1,15 do
				local item = GetString("savegame.mod.inventory.stash."..i.."_"..j)
				if item ~= "" then
					temp[i][15-j+1] = item
				end
			end
		end
		for i = 1,8 do
			for j = 1,15 do
				SetString("savegame.mod.inventory.stash."..i.."_"..j, temp[i][j])
			end
		end

		SetBool("savegame.mod.version.patches.inventory_flip", true)
	end
end
--2024-8-9: give the item string an extra layer so i have somewhere to add rotation and other none item but slot dependent things
function complex_inventory_support()
	if not GetBool("savegame.mod.version.patches.complex_inventory_support")then
		for i = 1,8 do
			for j = 1,15 do
				local item = GetString("savegame.mod.inventory.backpack."..i.."_"..j)
				if item ~= "" then
					SetString("savegame.mod.inventory.backpack."..i.."_"..j..".item", item)
					SetString("savegame.mod.inventory.backpack."..i.."_"..j,"")
				end
			end
		end
	
		for i = 1,8 do
			for j = 1,15 do
				local item = GetString("savegame.mod.inventory.stash."..i.."_"..j)
				if item ~= "" then
					SetString("savegame.mod.inventory.stash."..i.."_"..j..".item", item)
					SetString("savegame.mod.inventory.stash."..i.."_"..j,"")
				end
			end
		end
	
		for i = 1,1 do
			for j = 1,4 do
				local item = GetString("savegame.mod.inventory.guns."..j)
				if item ~= "" then
					SetString("savegame.mod.inventory.guns."..j..".item", item)
					SetString("savegame.mod.inventory.guns."..j,"")
				end
			end
		end
	
		for i = 1,1 do
			for j = 1,3 do
				local item = GetString("savegame.mod.inventory.armor."..j)
				if item ~= "" then
					SetString("savegame.mod.inventory.armor."..j..".item", item)
					SetString("savegame.mod.inventory.armor."..j,"")
				end
			end
		end

		SetBool("savegame.mod.version.patches.complex_inventory_support", true)
	end
end
		
function IDBuilder(t)
	return table.concat(t, "_")
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
function Split(s, delimiter)
    local result = {}
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match)
    end
    return result
end
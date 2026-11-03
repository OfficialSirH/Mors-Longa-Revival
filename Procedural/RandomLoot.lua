#include "SpawnRefrenceTable.lua"

local disable_spawning = "savegame.mod.procedural.disable.spawn_roadblocks"


function init()
	rare = .1
	uncommon = .4
	common = 1

	if GetBool('level.RND.loot')then
		DebugWatch('RND Loot',"DUPLICATED!")
	else
		SetBool('level.RND.loot',true)
	end
	
	luck = HasKey('level.gamerule.lrarity') and GetFloat('level.gamerule.lrarity') or 1
end
function tick()

	if GetBool(disable_spawning) then
		return
	end

	local Locations = FindLocations("RandomLoot",true)
		local Location = Locations[1]
		if IsHandleValid(Location)then
			local chance = 0.01*(tonumber(GetTagValue(Location, "chance")) or 100)
			local newChance = 1-(1-chance)^luck
			--DebugPrint('orig chance: '..chance.." | luck: "..luck.." | new chance : "..newChance)
			if math.random() < newChance or HasTag(Location, "AlwaysSpawn") then
				local Type = "civFood"
				if HasTag(Location,'type')then
					Type = GetTagValue(Location, "type")
				elseif HasTag(Location,'Type')then
					Type = GetTagValue(Location, "Type")
				end

				if Type == "food" then Type = "civFood"
				elseif Type == "general" then Type = "civGeneral"
				elseif Type == "mil" then Type = "banditWeapon"
				elseif Type == "military" then Type = "banditWeapon"
				end
	
				local locTrans = GetLocationTransform(Location)
				local posRnd = 0.01
				local rotRnd = 180
				local rotation = tonumber(GetTagValue(Location, "rotation"))or 0
				local rndPos = VecAdd(locTrans.pos,Vec(randomFloat(-posRnd,posRnd), 0, randomFloat(-posRnd,posRnd)))
				local rndRot = QuatRotateQuat(locTrans.rot,QuatEuler(0, rotation + randomFloat(-rotRnd,rotRnd), 0))
				
				SpawnRandomLoot(Type, Transform(rndPos, rndRot))
			end
		end
		Delete(Location)
	
end

function SpawnRandomLoot(Type, t)
	local whichType = spawnables.loots[Type]
	local rarity = math.random()
	if rarity < rare then
		raritytype = "rare"
	elseif rarity < uncommon then
		raritytype = "uncommon"
	elseif rarity < common then
		raritytype = "common"
	end
	local lootToSpawn = getRNGLoot(whichType[raritytype])
	local lootXML = "MOD/prefabs/spawnables/loots/"..lootToSpawn
	if HasFile(lootXML)then
		local spawnEntities=Spawn(lootXML, t, true)

		SetSpawnedEntityTags(spawnEntities)
	
		-- Random Loot Manipulation
		for i,entity in pairs(spawnEntities)do
			if GetEntityType(entity) == "body" then
				if HasTag(entity,"Loot")then
					local item = GetTagValue(entity,"Loot")
					if item~=""then
						local itemInfos = Split(item, "_")
						local newItem = item
						local itemID = itemInfos[1]
						local itemType=Split(itemID,"-")[1]
						if itemType=="bullets"then
							local itemCount = tonumber(itemInfos[3])
	
							itemInfos[3]=math.random(itemCount)
	
							newItem = IDBuilder(itemInfos)
						elseif itemType=="gun"then
							local magCount=tonumber(itemInfos[5])
							local magMax=tonumber(itemInfos[6])
	
							itemInfos[5]=math.random(magMax)
	
							newItem = IDBuilder(itemInfos)
						elseif string.sub(itemType, 1, 3)=="mag"then
							local itemCount=tonumber(itemInfos[3])
							local itemMax=tonumber(itemInfos[4])
	
							itemInfos[3]=math.random(0,itemMax)
	
							newItem = IDBuilder(itemInfos)
						end
						if newItem~=item then
							SetTag(entity,"Loot",newItem)
						end
					end
				end
			end
		end
	else
		DebugPrint(lootXML.." Does not exist, loot spawn failed, trying again.")
		print(lootXML.." Does not exist, loot spawn failed, trying again.")
		SpawnRandomLoot(Type, t)
	end
end
function getRNGLoot(listToRNG)
	local total = 0
	for i,item in pairs(listToRNG)do
		total = total + item[2]
	end
	local RNG = randomFloat(0,total)
	local itemToSpawn
	for i,item in pairs(listToRNG)do
		RNG = RNG - item[2]
		if RNG<=0 then
			itemToSpawn = item[1]
			if type(itemToSpawn)=="table"then
				return getRNGLoot(itemToSpawn)
			else
				return itemToSpawn
			end
		end
	end

end
function Split(s, delimiter)
    local result = {}
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match)
    end
    return result
end
function IDBuilder(t)
	local ID=""
    for i,s in ipairs(t)do
		if i==#t then
			ID=ID..s
		else
			ID=ID..s.."_"
		end
    end
    return ID
end

function randomFloat(min,max)
	min = tonumber(min) or 0
	max = tonumber(max) or 1
	return math.random()*(max-min)+min
end

function SetSpawnedEntityTags(prefab)
    if prefab ~= nil then
        for _, e in pairs(prefab) do
            if e ~= GetWorldBody() then
                SetTag(e, "procgen_delete")
             end
        end
    end
end
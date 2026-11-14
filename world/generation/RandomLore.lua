#include "SpawnRefrenceTable.lua"
function init()
	if GetBool("level.RND.lore")then
		DebugWatch("RND lore","DUPLICATED!")
	else
		SetBool("level.RND.lore",true)
	end
	
	progresses = {}
	for Type,typeInfos in pairs(spawnables.lores)do
		progresses[Type] = {}
		for i,items in ipairs(typeInfos)do
			progresses[Type][i] = {}
			progresses[Type][i]._done = true
			for _,item in ipairs(items)do
				progresses[Type][i][item.ID] = GetBool("savegame.mod.lore."..Type.."."..i.."."..item.ID)
				if not progresses[Type][i][item.ID] then
					progresses[Type][i]._done = false
				end
			end
			
		end
	end
end
function tick()
	local Locations = FindLocations("RandomLore",true)
	for i=1,#Locations do
		local Location = Locations[i]
		if IsHandleValid(Location)then
			local Type = ""
			if HasTag(Location,"type")then
				Type = GetTagValue(Location, "type")
			elseif HasTag(Location,"Type")then
				Type = GetTagValue(Location, "Type")
			end
			if Type ~= "" then
				local locTrans = GetLocationTransform(Location)
				local posRnd = 0
				local rotRnd = 0
				local rotation = tonumber(GetTagValue(Location, "rotation"))or 0
				local rndPos = VecAdd(locTrans.pos,Vec(randomFloat(-posRnd,posRnd), 0, randomFloat(-posRnd,posRnd)))
				local rndRot = QuatRotateQuat(locTrans.rot,QuatEuler(0, rotation + randomFloat(-rotRnd,rotRnd), 0))
				local RandomizedTransform=Transform(rndPos, rndRot)
				
				SpawnRandomLore(Type, RandomizedTransform)
			end
		end
		Delete(Location)
	end
end

function SpawnRandomLore(Type, t)
	for Type,typeInfos in ipairs(spawnables.lores)do
		for i,items in ipairs(typeInfos)do
			for _,item in ipairs(items)do
				if not progresses[Type][i][item.ID] then
					if GetBool("savegame.mod.lore."..Type.."."..i.."."..item.ID) then
						progresses[Type][i]._done = true
					end
				end
			end
			
		end
	end

	local whichType = spawnables.lores[Type]
	local loreItemToSpawn
	if whichType.ordered then
		for i, items in ipairs(whichType) do
			if not progresses[Type][i]._done then
				possibleItems = items
				break
			end
		end
		
		local total = 0
		for i,item in ipairs(possibleItems)do
			if not GetBool("savegame.mod.lore."..Type.."."..i.."."..item.ID) then
				total = total + item.weight or 1
			end
		end
		local RNG = randomFloat(0,total)
		for i,item in ipairs(possibleItems)do
			if not GetBool("savegame.mod.lore."..Type.."."..i.."."..item.ID) then
				RNG = RNG - item.weight or 1
				if RNG<=0 then
					loreItemToSpawn = item
					break
				end
			end
		end
	else

	end

	local loreXML = "MOD/prefabs/spawnables/lores/"..loreItemToSpawn.file
	if HasFile(loreXML)then
		local spawnEntities=Spawn(loreXML, t, true)
		SetSpawnedEntityTags(spawnEntities)
	else
		DebugPrint(loreXML.." Does not exist, lore spawn failed")
		print(loreXML.." Does not exist, lore spawn failed")
	end
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
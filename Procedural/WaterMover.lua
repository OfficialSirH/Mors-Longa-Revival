#version 2
#include "script/include/player.lua"
-- (v2) server: water volumes follow their sources; removed when far from the NEAREST player.
WATERPROPERTIES = {
	--type = {"box"},
	size = {1000,1000},
	depth = {10},
	wave = {0.5},
	ripple = {0.5},
	motion = {0.5},
	foam = {0.5},
	color = {0.01,0.01,0.01},
}
debug = false
function server.init()
	deletionDist = 500
	
	waterSourcesList = {}
end

function server.tick()
	if GetBool("level.roadgen") then
		ProcessNewWaterSources()
	end
	HandleWaterSources()
end
function ProcessNewWaterSources()
	local waterSources = FindTriggers("WaterSource",true)
	for i=1,#waterSources do
		local waterSource = waterSources[i]

		if not waterSourcesList[waterSource] then
			if debug then DebugPrint('Found an unknown water source: '..waterSource) end
			BuildNewWaterSource(waterSource)
		end

	end
end
function HandleWaterSources()

	for waterSource, waterSourceInfo in pairs(waterSourcesList) do
		if IsHandleValid(waterSource) then
			local waterSourceTransform = GetTriggerTransform(waterSource)
	
			local nearest = NearestPlayerDist(waterSourceTransform.pos)
			-- (v2 fix 2026-11-07) no players found → math.huge → never delete because of that
			if nearest ~= math.huge and nearest > deletionDist then
				if debug then DebugPrint('Removing water source for too far: '..waterSource) end
				RemoveWaterSource(waterSource)
			else
				if VecDist(waterSourceTransform.pos, waterSourceInfo.lastTransform.pos) > 0 then
					UpdateWaterSource(waterSource)
					waterSourceInfo.lastTransform = waterSourceTransform
				end
			end
		else
			if debug then DebugPrint('Removing water source for invalid: '..waterSource) end
			RemoveWaterSource(waterSource)
		end
	end
end
function UpdateWaterSource(waterSource)
	if debug then DebugPrint('updating a water source: '..waterSource) end
	Delete(waterSourcesList[waterSource].waterHandle)
	waterSourcesList[waterSource].waterHandle=SpawnWater(GetWaterPropertiesFromTags(waterSource),GetTriggerTransform(waterSource))
end
function RemoveWaterSource(waterSource)
	if debug then DebugPrint('Water source removed: '..waterSource) end
	Delete(waterSourcesList[waterSource].waterHandle)
	Delete(waterSource)
	waterSourcesList[waterSource]=nil
end
function BuildNewWaterSource(waterSource)
	if not waterSourcesList[waterSource] then
		if debug then DebugPrint('Constructing a water source: '..waterSource) end
		waterSourcesList[waterSource] = {
			waterHandle = 0,
			lastTransform = Transform(),
		}
		if GetEntityType(waterSource+1) == "water" then
			waterSourcesList[waterSource].waterHandle = waterSource+1
		else
			waterSourcesList[waterSource].waterHandle = SpawnWater(GetWaterPropertiesFromTags(waterSource),GetTriggerTransform(waterSource))
		end
	end
	return waterSourcesList[waterSource]
end

function GetWaterPropertiesFromTags(entity)
	local data={}
	for k,v in pairs(WATERPROPERTIES)do
		local rawData = GetTagValue(entity,k)
		local splittedData = Split(rawData, ",")
		local processedData = tableStringToNumber(splittedData)
		if #processedData > 0 then
			data[k] = processedData
		end
	end
	return data
end
function SpawnWater(data,t)
	local xml = '<water '
	for k,v in pairs(data)do
		xml = xml .. k .. '="' .. table.concat(v, " ") .. '"'
	end
	xml = xml .. '/>'
	return Spawn(xml, t, true)[1]
end
function tableStringToNumber(t)
	for k,v in pairs(t)do
		t[k] = tonumber(v)
	end
	return t
end
function VecDist(a,b) return VecLength(VecSub(a,b))end
function NearestPlayerDist(pos)
	local d = math.huge
	for p in Players() do d = math.min(d, VecDist(pos, GetPlayerTransform(p).pos)) end
	return d
end
function Split(s, delimiter)
    local result = {}
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match)
    end
    return result
end
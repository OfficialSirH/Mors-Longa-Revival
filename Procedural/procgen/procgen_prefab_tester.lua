--[[
#include "../../scripts/TDSU/tdsu.lua"
#include "../../Automatic.lua"
#include "procgen_spawnlist.lua"
]]


function init()
    -- EvaluatePrefabs(SpawnList)
    PrintPrefabReferences(SpawnList)
end

DATA = {
    voxels = {}
}

-- RANGES = {
--     voxels = math.floor(#SpawnList / 4)
-- }


function PrintPrefabReferences(list)

    for index, prefab in ipairs(list) do

        -- print()

    end

end


function EvaluatePrefabs(list)

    print("\n\n\n\n")
    print("==============================================================================================")
    print("PREFAB TEST")
    print("==============================================================================================")


    for index, prefab in ipairs(list) do

        print("\n\n\n----------------------------------------------------------------------------------------")
        print(prefab)
        print("")

        Spawn(prefab, Transform(Vec(0,0,0), QuatEuler(0,0,0)))
        EvaluatePrefab(prefab)

        print("")

    end

    ProcessData(DATA)

    SetPaused(true)

end

function EvaluatePrefab(prefab)

    local data = {
        voxels = 0,
        min = Vec(0, 0, 0),
        max = Vec(0, 0, 0),
    }


    local bodies = FindBodies("", true)
    local shapes = FindShapes("", true)
    local locations = FindLocations("", true)
    local lights = FindLights("", true)
    local triggers = FindTriggers("", true)


    for _, value in ipairs(bodies) do
        data.min = VecMin(data.min, GetBodyTransform(value).pos)
        data.min = VecMax(data.max, GetBodyTransform(value).pos)
    end
    for _, value in ipairs(shapes) do
        data.min = VecMin(data.min, GetShapeWorldTransform(value).pos)
        data.min = VecMax(data.max, GetShapeWorldTransform(value).pos)
        data.voxels = data.voxels + GetShapeVoxelCount(value)
    end
    for _, value in ipairs(locations) do
        data.min = VecMin(data.min, GetLocationTransform(value).pos)
        data.min = VecMax(data.max, GetLocationTransform(value).pos)
    end
    for _, value in ipairs(lights) do
        data.min = VecMin(data.min, GetLightTransform(value).pos)
        data.min = VecMax(data.max, GetLightTransform(value).pos)
    end
    for _, value in ipairs(triggers) do
        data.min = VecMin(data.min, GetTriggerTransform(value).pos)
        data.min = VecMax(data.max, GetTriggerTransform(value).pos)
    end

    print("voxels: " .. data.voxels)

    local k = string_replace_path(prefab)
    DATA.voxels[k] = data.voxels

    for _, value in ipairs(bodies) do Delete(value) end
    for _, value in ipairs(shapes) do Delete(value) end
    for _, value in ipairs(locations) do Delete(value) end
    for _, value in ipairs(lights) do Delete(value) end
    for _, value in ipairs(triggers) do Delete(value) end

end


function ProcessData()

    -- local DATA_VOXELS = {}

    -- for _, v in ipairs(DATA_VOXELS) do
    --     print(v[1], v[2])
    -- end

    -- for k, v in pairs(DATA.voxels) do
    --     print(v, k)
    -- end

end


function string_replace_path(str)
    str = string.gsub(str, "%/", "_")
    str = string.gsub(str, "%.", "_")
    return str
end

-- tb = { -- Need to sort this pairs table by value and retain key.
--     a = 67,
--     b = 4,
--     c = 22,
-- }

-- tb = { -- Sorted by value as ipairs.
--     {67, a},
--     {22, c},
--     {4, b},
-- }

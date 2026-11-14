#include "../lib/TDSU/tdsu.lua"

function init_prefab_tester()

    Prefabs = {

        Buildings = {
            "MOD/prefabs/spawnables/buildings/constructionCivillian1.xml",
            "MOD/prefabs/spawnables/buildings/constructionCivillian2.xml",
            "MOD/prefabs/spawnables/buildings/constructionCivillian3.xml",
            "MOD/prefabs/spawnables/buildings/constructionCivillian4.xml",
            "MOD/prefabs/spawnables/buildings/constructionCivillian5.xml",
            "MOD/prefabs/spawnables/buildings/constructionCivillian6.xml",
            "MOD/prefabs/spawnables/buildings/constructionCivillian7.xml",
            "MOD/prefabs/spawnables/buildings/constructionCivillian8.xml",
            "MOD/prefabs/spawnables/buildings/constructionCivillian9.xml",
            "MOD/prefabs/spawnables/buildings/constructionCivillian10.xml",
            "MOD/prefabs/spawnables/buildings/constructionCivillian11.xml",
            "MOD/prefabs/spawnables/buildings/constructionCivillian12.xml",
            "MOD/prefabs/spawnables/buildings/constructionCivSpecial1.xml",
            "MOD/prefabs/spawnables/buildings/constructionSpecial1.xml",
            "MOD/prefabs/spawnables/buildings/constructionSpecial2.xml",
            "MOD/prefabs/spawnables/buildings/constructionSpecial3.xml",
        },

        Roadblocks = {
            "MOD/prefabs/spawnables/roadblocks/roadblock1.xml",
            "MOD/prefabs/spawnables/roadblocks/roadblock2.xml",
            "MOD/prefabs/spawnables/roadblocks/roadblock3.xml",
            "MOD/prefabs/spawnables/roadblocks/roadblock4.xml",
            "MOD/prefabs/spawnables/roadblocks/roadblock5.xml",
            "MOD/prefabs/spawnables/roadblocks/roadblock6.xml",
            "MOD/prefabs/spawnables/roadblocks/roadblock7.xml",
            "MOD/prefabs/spawnables/roadblocks/roadblock8.xml",
            "MOD/prefabs/spawnables/roadblocks/roadblock9.xml",
        },

        RoadSegments = {
            "MOD/prefabs/spawnables/roadsegments/RoadSegment1.xml",
            "MOD/prefabs/spawnables/roadsegments/RoadSegment2.xml",
            "MOD/prefabs/spawnables/roadsegments/RoadSegment3.xml",
            "MOD/prefabs/spawnables/roadsegments/RoadSegment4.xml",
            "MOD/prefabs/spawnables/roadsegments/RoadSegment5.xml",
            "MOD/prefabs/spawnables/roadsegments/RoadSegmentB1.xml",
            "MOD/prefabs/spawnables/roadsegments/RoadSegmentF.xml",
            "MOD/prefabs/spawnables/roadsegments/RoadSegmentH.xml",
            "MOD/prefabs/spawnables/roadsegments/RoadSegmentL1.xml",
            "MOD/prefabs/spawnables/roadsegments/RoadSegmentL2.xml",
            "MOD/prefabs/spawnables/roadsegments/RoadSegmentM1.xml",
            "MOD/prefabs/spawnables/roadsegments/RoadSegmentM2.xml",
            "MOD/prefabs/spawnables/roadsegments/RoadSegmentM3.xml",
            "MOD/prefabs/spawnables/roadsegments/RoadSegmentM4.xml",
            "MOD/prefabs/spawnables/roadsegments/RoadSegmentM5.xml",
            "MOD/prefabs/spawnables/roadsegments/RoadSegmentM6.xml",
            "MOD/prefabs/spawnables/roadsegments/RoadSegmentM7.xml",
            "MOD/prefabs/spawnables/roadsegments/RoadSegmentM8.xml",
            "MOD/prefabs/spawnables/roadsegments/RoadSegmentS1.xml",
        },

    }


    for _, category in pairs(Prefabs) do
        for _, path in ipairs(category) do
            -- test_prefab(path)
        end
    end

end


function tick_prefab_tester()
end


function test_prefab(path)

    local entities = Spawn(path, Transform(Vec(0, 0, 0)))


    -- Check if path is valid.
    if #entities == 0 then

        print(string_pad("Invalid prefab path: ", 25), string_pad(path.gun_path, 40))

    else

        print(path)

        local shapes = 0
        local bodies = 0
        local voxels = 0

        for index, e in ipairs(entities) do
            if GetEntityType(e) == "body" then
                bodies = bodies + 1
            elseif GetEntityType(e) == "shape" then
                shapes = shapes + 1
                voxels = voxels + GetShapeVoxelCount(e)
            end
        end

        print("shapes:", sfnCommas(shapes))
        print("bodies:", sfnCommas(bodies))
        print("voxels:", sfnCommas(voxels))

    end


    for _, e in ipairs(entities) do Delete(e) end -- Delete prefab.


    print("-------------------------------------------------------------------------------------------\n")

end
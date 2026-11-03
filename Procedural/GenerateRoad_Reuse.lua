--[[
    Longer initial load time.
    Load 4 road segments in init() and store them in pool of roads.
    Skip special segments.
    Link to valid prefab paths.
]]

RoadSegmentPaths = {
    "MOD/prefabs/spawnables/roadsegments/RoadSegment1.xml",
    "MOD/prefabs/spawnables/roadsegments/RoadSegment2.xml",
    "MOD/prefabs/spawnables/roadsegments/RoadSegment3.xml",
}


BlankRoadSegments = {} -- Move segment index closer to [1]. Use only [1]. Check how many segments are reusable ones.
BlankRoadSegments_Max = 4



function Init_Road_Reuser()

    --= Select road segments to add into road segment pool.
    local road_index = 1
    for i = 1, BlankRoadSegments_Max do

        local xml = RoadSegmentPaths[road_index]

        local entities = Spawn(xml, Transform(Vec(5000,-5000,5000)))

        local road = {
            entities = entities
        }


        table.insert(BlankRoadSegments, road)
        road_index = GetTableNextIndex(RoadSegmentPaths, road_index) -- Loop through table indexes.
    end

end

function CreateRoadSegment(entities)
    return {
        entities = entities
    }
end

function ReuseRoads()
end

function CheckRoad(road)
end

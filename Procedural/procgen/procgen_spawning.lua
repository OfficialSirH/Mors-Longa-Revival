Territories = {
    mil = "Military",
    civ = "Insurgents",
    desert = "Desert"
}

TerritoryDataY = {}


function Auto_Generate_Territories()

    local function getRandomTerritorySize(min, max)
        return math.random(Depth * (min or 2), Depth * (max or 4))
    end

    -- First few territories
    for y = #TerritoryDataY, #TerritoryDataY + getRandomTerritorySize(3, 4) do
        TerritoryDataY[y] = Territories.desert
    end
    for y = #TerritoryDataY, #TerritoryDataY + getRandomTerritorySize(2, 4) do
        TerritoryDataY[y] = Territories.civ
    end
    for y = #TerritoryDataY, #TerritoryDataY + getRandomTerritorySize(1, 2) do
        TerritoryDataY[y] = Territories.desert
    end
    for y = #TerritoryDataY, #TerritoryDataY + getRandomTerritorySize(2, 4) do
        TerritoryDataY[y] = Territories.civ
    end


    -- The rest of the territories
    local territoryRows = #TerritoryDataY + (Depth ^ 3)
    while #TerritoryDataY <= territoryRows do

        local terr = ternary(math.random() >= 0.5, Territories.mil, Territories.civ)
        for y = #TerritoryDataY, #TerritoryDataY + getRandomTerritorySize() do
            TerritoryDataY[y] = terr
        end

        for y = #TerritoryDataY, #TerritoryDataY + getRandomTerritorySize(2, 3) do
            TerritoryDataY[y] = Territories.desert
        end

    end

end


function Manage_Spawning_TileContent()

    local tile_ids = {} -- Relevant tiles.

    local row_start = Tiles_RowsSpawned+1
    local row_end = clamp(GetGridDepth(), Tiles_RowsSpawned, Tiles_RowsSpawned + Tiles_SpawnDist)
    for y = row_start, row_end do

        for x = 1, Width do

            local id = GridXY[x][y].id

            if TilesSpawned[id] == nil then -- Store only one tile id reference.

                TilesSpawned[id] = true
                table.insert(tile_ids, id)

            end

        end

        Tiles_RowsSpawned = Tiles_RowsSpawned + 1

    end


    -- Spawn the specified tiles.
    for i = 1, #tile_ids do -- Select and spawn the range of tiles.

        SetBool("level.roadgen", true)
        SetBool("level.spawnstuff", true)

        local tile = Tiles[tile_ids[i]]
        local prefab_tr = GetSpawnOffsetTr()
        local spawned_prefabs = {}


        if tile.w == 1 and tile.h == 1 then

            if math.random() < 0.1 then

                Spawn_1x1_Vehicle(tile, prefab_tr, spawned_prefabs)

            elseif math.random() < 0.2 and not IsRoadCell(tile.x) then

                Spawn_1x1_Foliage(tile, prefab_tr, spawned_prefabs)

            end

        end


        -- RoadSigns
        if tile.w == Width_Road and tile.h == 1 and IsRoadCell(tile.x) then
            Spawn_2x1_Roadsign(tile, prefab_tr, spawned_prefabs)
        end


        if tile.w == Width_Road and tile.h == 2 and IsRoadCell(tile.x) then
            prefab_tr = Transform(GetTileCenterPos(tile), QuatEuler(0, -90, 0))
            prefab_tr = TransformAdd(prefab_tr, SpawnOffsetTr)

            table.insert(spawned_prefabs, Spawn("MOD/2x2_roadblock.xml", prefab_tr, true))
        end


        if tile.w == Width and tile.h == 1 then

            prefab_tr = Transform(GetTileCenterPos(tile), QuatEuler(0, 90, 0))
            prefab_tr = TransformAdd(prefab_tr, SpawnOffsetTr)

            if math.random() > 0.5 then
                table.insert(spawned_prefabs, Spawn("MOD/prefabs/spawnables/bridges/8x1_bridge_overpass.xml", prefab_tr, true))
            else
                table.insert(spawned_prefabs, Spawn("MOD/prefabs/spawnables/bridges/8x1_bridge_train.xml", prefab_tr, true))
            end

        end


        if tile.w == Width_Side and tile.h == 3 then

            local whichone = math.random(1, 11)

            local rotate = ternary(tile.x <= Width_Side, -90, 90)

            prefab_tr = Transform(GetTileCenterPos(tile), QuatEuler(0, rotate, 0))
            prefab_tr = TransformAdd(prefab_tr, SpawnOffsetTr)

            table.insert(spawned_prefabs, Spawn("MOD/prefabs/spawnables/buildings/constructionCivillian" .. whichone .. ".xml", prefab_tr, true))

        end


        if tile.w == Width_Side and tile.h == 5 then

            local rotate = ternary(tile.x <= Width_Side, -90, 90)

            prefab_tr = Transform(GetTileCenterPos(tile), QuatEuler(0, rotate, 0))
            prefab_tr = TransformAdd(prefab_tr, SpawnOffsetTr)

            table.insert(spawned_prefabs, Spawn("MOD/prefabs/spawnables/buildings/constructionCivillian4.xml", prefab_tr, true))

        end

        for _, prefab in ipairs(spawned_prefabs) do
            SetSpawnedEntityTags(prefab)
        end

    end

end


function Spawn_1x1_Foliage(tile, prefab_tr, spawned_prefabs)

    -- random foliage
    prefab_tr = Transform(GetTileCenterPos(tile), QuatEuler(0, math.random(0,360), 0))
    prefab_tr = TransformAdd(prefab_tr, SpawnOffsetTr)
    table.insert(spawned_prefabs, Spawn("MOD/1x1_foliage.xml", prefab_tr, true))

end

function Spawn_1x1_Vehicle(tile, prefab_tr, spawned_prefabs)

    local pos = AutoVecSubsituteY(VecRandom(MeterScale/4), 0)
    local rotY = math.random(-30, 30) * -1 -- left lane
    if IsRoadCell(tile.x) then
        local side = GetRoadSide(tile.x)
        rotY = ternary(GetRoadSide(tile.x) == RoadSides.left, rotY + 180, rotY)
        print(side)
    else
        rotY = math.random(0, 360)
    end

    -- random vehicle
    prefab_tr = Transform(GetTileCenterPos(tile), QuatEuler(0, rotY, 0))
    prefab_tr.pos = VecAdd(prefab_tr.pos, pos)
    prefab_tr = TransformAdd(prefab_tr, SpawnOffsetTr)
    table.insert(spawned_prefabs, Spawn("MOD/prefabs/spawnables/vehicles/Vehiclewg" .. math.random(1, 18) .. ".xml", prefab_tr, true))

end

function Spawn_2x1_Roadsign(tile, prefab_tr, spawned_prefabs)

    local whichone = math.random(1, 6)

    if math.random() < 0.5 then
        -- Left lane
        prefab_tr = Transform(GetTileCenterPos(tile), QuatEuler(0, -90, 0))
        prefab_tr = TransformAdd(prefab_tr, SpawnOffsetTr)
        prefab_tr = TransformAdd(prefab_tr, Transform(Vec(-MeterScale/2,0,0)))
        table.insert(spawned_prefabs, Spawn("MOD/prefabs/spawnables/roadsigns/roadsign" .. whichone .. ".xml", prefab_tr, true))
    else
        -- Right lane
        prefab_tr = Transform(GetTileCenterPos(tile), QuatEuler(0, 90, 0))
        prefab_tr = TransformAdd(prefab_tr, SpawnOffsetTr)
        prefab_tr = TransformAdd(prefab_tr, Transform(Vec(MeterScale/2,0,0)))
        table.insert(spawned_prefabs, Spawn("MOD/prefabs/spawnables/roadsigns/roadsign" .. whichone .. ".xml", prefab_tr, true))
    end

end

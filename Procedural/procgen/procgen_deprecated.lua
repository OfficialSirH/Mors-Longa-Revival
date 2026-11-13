
--[[ NO LONGER USED ]]
do

    function SpawnGridTiles(scale)

        local row_mod = 0 -- Spawn highway lights every 2 road cells.

        for i, x in ipairs(GridXY) do

            for j, y in ipairs(GridXY[i]) do

                row_mod = row_mod + 1

                local id = GridXY[i][j].id
                local tile = Tiles[id]

                UiPush()

                    -- local px = i * scale/10 + GridSpawnffset[1]
                    -- local px = i * scale/10
                    -- local py = -j * scale/10
                    -- local pos = 'pos="' .. px .. ' 0 ' .. py .. '" '

                    -- local w = scale
                    -- local h = scale
                    -- local size = 'size="' .. w .. ' ' .. 1 .. ' ' .. h .. '" '

                    -- local color = 'color="' .. t.c[1] .. ' ' .. t.c[2] .. ' ' .. t.c[3] .. ' ' .. 1 .. '"'

                    -- local xml = '<voxbox ' .. pos .. ' ' .. size .. ' ' .. color .. '/>'
                    -- local tile = Spawn(xml, Transform(), true)


                    local px = i * scale/10
                    local py = -j * scale/10
                    local tr = Transform(Vec(px, 0, py))

                    local prefab_tile = TilePrefabs.sides

                    if IsRoadCell(i) then -- Within either road cell.

                        prefab_tile = TilePrefabs.road_left -- Default road = left.

                        if i == Width_Side + 2 then

                            prefab_tile = TilePrefabs.road_right -- Switch to right road.

                            if row_mod % 2 == 0 then -- Every other road cell.
                                Spawn("MOD/prefabs/tiles/2x1_lights_highway.xml", tr, true) -- Spawn highway light.
                            end

                        end

                    end

                    local spawned_tile = Spawn(prefab_tile, tr, true)
                    tile.shape = spawned_tile[1]
                    tile.c = GridXY[i][j].c

                UiPop()

            end

        end

    end

    function SpawnTileContent(tile)

        -- for index, tile in ipairs(Tiles) do

            if tile.w == 1 and tile.h == 1 then

                if math.random() < 0.5 and not IsRoadCell(tile.x) then
                    -- random foliage
                    -- local prefab_tr = Transform(GetTileCenterPos(tile), QuatEuler(0, math.random(0,360), 0))
                    -- local prefab = Spawn("MOD/1x1_foliage.xml", prefab_tr, true)
                elseif math.random() < 0.5 then
                --     -- random vehicle
                    local prefab_tr = Transform(GetTileCenterPos(tile), QuatEuler(0, math.random(0, 360), 0))
                    local prefab = Spawn("MOD/prefabs/spawnables/vehicles/Vehiclewg" .. math.random(1, 18) .. ".xml", prefab_tr, true)
                end

            end

            if tile.w == Width_Road and tile.h == 2 and IsRoadCell(tile.x) then
                local prefab_tr = Transform(GetTileCenterPos(tile), QuatEuler(0, -90, 0))
                local prefab = Spawn("MOD/2x2_roadblock.xml", prefab_tr, true)
            end

            if tile.w == Width and tile.h == 1 then

                local prefab_tr = Transform(GetTileCenterPos(tile), QuatEuler(0, 90, 0))

                if math.random() > 0.5 then
                    local prefab = Spawn("MOD/prefabs/spawnables/bridges/8x1_bridge_overpass.xml", prefab_tr, true)
                else
                    local prefab = Spawn("MOD/prefabs/spawnables/bridges/8x1_bridge_train.xml", prefab_tr, true)
                end

            end

            if tile.w == Width_Side and tile.h == 3 then

                local whichone = math.random(1, 11)

                local rotate = ternary(tile.x <= Width_Side, -90, 90)

                local prefab_tr = Transform(GetTileCenterPos(tile), QuatEuler(0, rotate, 0))
                local prefab = Spawn("MOD/prefabs/spawnables/buildings/constructionCivillian" .. whichone .. ".xml", prefab_tr, true)

            end

            if tile.w == Width_Side and tile.h == 5 then

                local rotate = ternary(tile.x <= Width_Side, -90, 90)

                local prefab_tr = Transform(GetTileCenterPos(tile), QuatEuler(0, rotate, 0))
                local prefab = Spawn("MOD/prefabs/spawnables/buildings/constructionCivillian4.xml", prefab_tr, true)

            end

        -- end

    end

    function SpawnTileCell(i, j, scale)

        row_mod = 0 -- Spawn highway lights every 2 road cells.

        -- for i, x in ipairs(GridXY) do

        --     for j, y in ipairs(GridXY[i]) do

                row_mod = row_mod + 1

                local id = GridXY[i][j].id
                local tile = Tiles[id]

                UiPush()

                    -- local px = i * scale/10 + GridSpawnffset[1]
                    -- local px = i * scale/10
                    -- local py = -j * scale/10
                    -- local pos = 'pos="' .. px .. ' 0 ' .. py .. '" '

                    -- local w = scale
                    -- local h = scale
                    -- local size = 'size="' .. w .. ' ' .. 1 .. ' ' .. h .. '" '

                    -- local color = 'color="' .. t.c[1] .. ' ' .. t.c[2] .. ' ' .. t.c[3] .. ' ' .. 1 .. '"'

                    -- local xml = '<voxbox ' .. pos .. ' ' .. size .. ' ' .. color .. '/>'
                    -- local tile = Spawn(xml, Transform(), true)



                    local px = i * scale/10
                    local py = -j * scale/10
                    local tr = Transform(Vec(px, 0, py))
                    -- local tr = Transform(Vec(px, math.random() * 10, py))

                    local prefab_tile = TilePrefabs.sides

                    if IsRoadCell(i) then -- Within either road cell.

                        prefab_tile = TilePrefabs.road_left -- Default road = left.

                        if i == Width_Side + 2 then

                            prefab_tile = TilePrefabs.road_right -- Switch to right road.

                            if row_mod % 2 == 0 then -- Every other road cell.
                                Spawn("MOD/prefabs/tiles/2x1_lights_highway.xml", tr, true) -- Spawn highway light.
                            end

                        end

                    end

                    local spawned_tile = Spawn(prefab_tile, tr, true)
                    tile.shape = spawned_tile[1]
                    tile.c = GridXY[i][j].c


                UiPop()

        --     end
        -- end

    end

end

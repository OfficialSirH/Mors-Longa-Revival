--[[
#include "../../Automatic.lua"
#include "../../scripts/TDSU/tdsu.lua"
#include "procgen_data.lua"
#include "procgen_shadowVolume.lua"
#include "procgen_spawning.lua"
]]




function UpdateConfig()

    db = GetBool("savegame.mod.config.db")

    Config = {
        draw_preview = false,
        draw_tileIds = false,
        draw_compass = false,
        retain_shadow_volume = true,
        spawnTileContent = GetBool("savegame.mod.config.map.spawnTileContent")
    }

end


function init()

    UpdateConfig()


    ID = 1 -- Unique tile identifier.
    MeterScale = 25
    VoxScale = MeterScale * 10


    -- Each grid item is an individual cell.
    GridXY = {} -- Iterate over x then y
    GridYX = {} -- Iterate over y then x


    Depth = 8 -- Cells in a chunk
    ChunkLength = 200 -- Length of a standard chunk.
    Width_Road = 2 -- DO NOT CHANGE
    Width_Side = 3 -- DO NOT CHANGE
    Width = Width_Road + (Width_Side * 2) -- DO NOT CHANGE
    RoadSides = { left = "left", right = "right" }


    CellGenerationDist = 16 -- When to generate more grid cells.
    ChunkLoading = {
        chunks = 1,
        min = 16,
        max = 24,
    }


    -- A tile is a collection of adjacent cells of the same ID.
    -- You can reference a tile by its ID int.
    Tiles = {}
    TilesSpawned = {} -- Stores the IDs of the tiles spawned. non nil = spawned.
    Tile_DeleteDist = Depth * MeterScale -- Delete behind player.


    Floor_SpawnedIndex = 0 -- Which chunks have been spawned
    Floor_SpawnDist = 16 -- How many chunks to spawn ahead of the trigger
    Floor_SpawnDepth = 8 -- Length of a floor chunk


    Tiles_SpawnedIndex = 0
    Tiles_SpawnDist = 16
    Tiles_SpawnDepth = 8
    Tiles_RowsSpawned = 0


    TilePrefabs = {
        road_left = "MOD/prefabs/tiles/1x1_road_left.xml",
        road_right = "MOD/prefabs/tiles/1x1_road_right.xml",
        sides = "MOD/prefabs/tiles/1x1_desert.xml",
    }

    Tag_Delete = "procgen_delete"


    PlayerTr = GetPlayerTransform()
    AllBodies = FindBodies("", true)
    AllShapes = FindShapes("", true)
    CellsProgressedOffset = 0
    CellsProgressedAdjusted = 0


    Auto_Generate_Territories()

    local startingRows = 8
    for i = 1, startingRows do Auto_Generate_Chunk(1) end -- Start with a few 1x1 tiles

    for i = 1, 10 do
        Auto_Generate_Section(ChunkLoading.chunks)
    end

    Init_ShadowVolume()

end


--- A tile is a collection of individual cells.
--- Creating a tile will create a group of cells with a common ID, starting at xy and ending at x+w,y+h.
--- Always make sure there are no gaps in the grid.
function Grid_AddTile(x,y, w,h, color)

    local tile = {
        id = ID,
        x = x,
        y = y,
        w = w,
        h = h,
        cells = {},
        spawned = false,
    }

    -- Random color for all cells in the tile.
    local color = color or Vec(math.random()+0.2, math.random()+0.2, math.random()+0.2)
    tile.c = color

    for i = x, x + w - 1 do

        if GridXY[i] == nil then GridXY[i] = {} end -- Check XY index validity.
        for j = y, y + h - 1 do -- Fill each cell with ID value.

            GridXY[i][j] = {
                id = ID,
                c = color
                -- territory =
            }

            if GridYX[j] == nil then GridYX[j] = {} end -- Check YX index validity.
            GridYX[j][i] = GridXY[i][j] -- Add table reference to

            table.insert(tile.cells, GridXY[i][j])

        end

    end

    table.insert(Tiles, tile)

    ID = ID + 1

end

-- A section is a collection of chunks
function Auto_Generate_Section(iterations)

    for i = 1, iterations do

        local d = math.random(ChunkLoading.min, ChunkLoading.max)
        Auto_Generate_Chunk(d)

        Auto_Generate_Chunk(1) -- Divider row

        -- local rdm_span_depth = TileLayouts.spans[GetRandomIndex(TileLayouts.spans)].h
        -- Auto_Generate_Span(Width, rdm_span_depth) -- Spanning row (bridges, bases)

        Auto_Generate_Chunk(1) -- Divider row

    end

end

---Create a chunk of complete width of specified depth.
---@param depth number
function Auto_Generate_Chunk(depth)

    local grid_y = 1
    if GridXY[1] then
        grid_y = #GridXY[1] + 1
    end

    -- Generate a side, then the road, then the other side.
    Generate_Column(0, grid_y, Width_Side, depth, TileLayouts.sides)
    Generate_Column(3, grid_y, Width_Road, depth, TileLayouts.road, true)
    Generate_Column(5, grid_y, Width_Side, depth, TileLayouts.sides)

end
function Auto_Generate_Span(width, depth)
    local y = GetNextGridY()
    Generate_Span(y, width, depth)
end
function Generate_Column(grid_x, grid_y, width, depth, layouts, color_greyscale)

    local tiles = {}


    -- Find layout with the longest depth.
    local max_tile_depth = 0
    for index, layout in ipairs(layouts) do
        max_tile_depth = math.max(max_tile_depth, layout.h)
    end


    local depth_limit = depth - max_tile_depth -- The last large tile to be generated, then fill remaining space with 1x1 cells.


    -- Generate the dimensions of each tile.
    local d = 0 -- Depths completed.
    while d < depth do

        local layout = layouts[GetRandomIndex(layouts)] -- Select a random layout for the tile.
        local d_add = layout.h -- Add to d based on the layout depth.


        local last_cells = d >= depth_limit
        if last_cells then

            -- row of 1x1 cells or fill in last few rows with single cells..
            table.insert(tiles, { rows = 1, columns = width }) -- Add two horizontal tiles.
            d = d + 1 -- Added to total depths. Signals when total column depth is complete.


        elseif layout.h == 1 and not IsRoadCell(d) then -- row of 1x1 cells. No road sides are rows of depth 1

            table.insert(tiles, { rows = 1, columns = width }) -- Add two horizontal tiles.
            d = d + 1 -- Added to total depths. Signals when total column depth is complete.

        else

            table.insert(tiles, { rows = d_add, columns = 1 }) -- Add a single tile
            d = d + d_add -- Added to total depths. Signals when total column depth is complete.

        end

    end


    -- Insert each tile into the global grid.
    local gridPosY = grid_y or 1 -- The y position for where to insert the tile into the grid.
    for _, tile in ipairs(tiles) do

        for x = 1, tile.columns do -- Select each horizontal position for the cell.

            local grey = (math.random() * 0.5) + 0.2
            local c = ternary(color_greyscale, Vec(grey,grey,grey), nil) -- Create a greyscale color or let the color auto generate.

            Grid_AddTile(x + grid_x, gridPosY, width/tile.columns, tile.rows, c) -- Insert each tile

        end

        gridPosY = gridPosY + tile.rows -- Shift the grid y position up to the next row to complete.

    end

    -- print("depth: "..depth)
    -- print("d: "..d)
    -- local depth_remaining = depth - d
    -- print("depth_remaining: "..depth_remaining)

end
function Generate_Span(y, width, depth)
    Grid_AddTile(1, y, width, depth, Vec(1,0,0))
end



--- Generate grid based on CellsProgressed.
function Manage_Grid_Generation()
    local shouldGenerate = GetGridDepth() < CellsProgressed + CellGenerationDist -- Player is close enough to last cell generated.
    if shouldGenerate then

        Auto_Generate_Section(1) -- Generate a general section.

    end
end

function Manage_Spawning_Floor()

    local center = Width/2
    SpawnZ = (-Floor_SpawnedIndex - center) * MeterScale -- Base position for prefab.

    local pos = Vec(center*MeterScale, 0, SpawnZ) -- Road tile pos
    pos = VecAdd(pos, SpawnOffsetTr.pos)
    -- pos[2] = -0.1


    local tr = Transform(pos)
    Spawn("MOD/8x8_road.xml", tr, true)

end

function tick_deleting()

    AllShapes_Procgen = FindShapes(Tag_Delete, true)

    local shapesToDelete = {}
    for index, shape in ipairs(AllShapes_Procgen) do
        if PlayerTr.pos[3] + Tile_DeleteDist < GetShapeWorldTransform(shape).pos[3] then
            table.insert(shapesToDelete, shape)
            -- DrawShapeOutline(shape, 1,0,0, 1)
        end
    end

    for index, shape in ipairs(shapesToDelete) do
        Delete(shape)
    end

end



function GetGridDepth() return #GridYX end
-- Remove all tile cells from the grid.
function DeleteTile(tile)

    local x = tile.x
    local y = tile.y
    local w = x + tile.w
    local h = y + tile.h

    -- Delete from GridXY and GridYX.
    for i = x, w do
        for j = x, h do
            GridXY[i][j] = nil
            GridYX[j][i] = nil
            print(i,j)
        end
    end

    -- Delete empty tile.
    Tiles[tile.id] = nil

end
function GetNextGridY()
    return #GridXY[1] + 1 -- +1 for next row.
end
-- Get the avg or min and max cells
function GetTileCenterPos(tile)

    local scale = VoxScale/10

    local x = (tile.x - 1) * scale
    local y = (tile.y - 1) * scale
    local w = tile.w * scale
    local h = tile.h * scale

    local min = Vec(x, 0, -y) -- Bottom left corner.
    local mid = Vec(w/2, 0, -h/2) -- Mid point.

    return VecAdd(min, mid)

end
-- Checks if a cell belongs to a road column.
function IsRoadCell(x)
    return x > Width_Side and x < Width_Side + Width_Road + 1
end
function GetRoadSide(x)
    return ternary(x == Width_Side+1, RoadSides.left, RoadSides.right)
end
function SetSpawnedEntityTags(prefab)
    if prefab ~= nil then
        for _, e in ipairs(prefab) do

            if GetEntityType(e) == "body" then -- global body

                for _, shape in ipairs(GetBodyShapes(e)) do  -- All shapes of every body.
                    SetTag(shape, "procgen_delete")
                end

                if e ~= GetWorldBody() then
                    SetTag(e, "procgen_delete")
                end

            else

                SetTag(e, "procgen_delete") -- Everything else gets the tag.

            end

        end
    end
end

function GetSpawnOffsetTr()

    local pos = Vec(-Width/2*MeterScale,0,0)

    if Config.retain_shadow_volume then
        ShadowVolZOffset = ReturnsCompleted * TotalReturnMeters -- Accounts for shadow volume teleporting.
        pos[3] = ShadowVolZOffset
    end

    return Transform(pos, QuatEuler(0,0,0))

end
function GetCellsProgressed() return math.floor((PlayerTr.pos[3] / -VoxScale) * 10) + 1 + CellsProgressedOffset end



function tick()

    -- UpdateConfig()


    PlayerTr = GetPlayerTransform()
    SpawnOffsetTr = GetSpawnOffsetTr()


    if InputDown("shift") and InputPressed("mmb") then
        Config.draw_tileIds = not Config.draw_tileIds
        Config.draw_preview = not Config.draw_preview
        Config.draw_compass = not Config.draw_compass
    end


    CellsProgressed_Base = math.floor(PlayerTr.pos[3] / -MeterScale) + 1 -- Used for regular calculation.
    CellsProgressedAdjusted = CellsProgressed_Base + CellsProgressedOffset -- Used for when player and spawned tiles are teleported back to shadow volume.


    if Config.retain_shadow_volume then
        CellsProgressed = CellsProgressedAdjusted
    else
        CellsProgressed = CellsProgressed_Base -- Use regular calculation for cell progression (spawned stuff never moves)
    end


    -- Everything is run in a single tick.
    if CellsProgressedAdjusted > Floor_SpawnedIndex - Floor_SpawnDist then

        tick_deleting()
        Manage_Grid_Generation()
        Manage_Spawning_Floor()
        Floor_SpawnedIndex = Floor_SpawnedIndex + Floor_SpawnDepth

        if Config.spawnTileContent then
            Manage_Spawning_TileContent()
        end

    end


    CalculateProgress() -- Must be called before ReturnToShadowVolume()

    if Config.retain_shadow_volume then
        ReturnToShadowVolume() -- Must be called in draw to prevent camera glitch (wrong position for a frame)
    end


    -- DebugWatch("o #GridYX", #GridYX)
    -- DebugWatch("o GetPlayerTransform().pos[3]", GetPlayerTransform().pos[3])
    -- DebugWatch("o Floor_SpawnedIndex", Floor_SpawnedIndex)

    -- DebugWatch("_ CellsProgressed_Base", CellsProgressed_Base)
    -- DebugWatch("_ CellsProgressed", CellsProgressed)
    -- DebugWatch("_ CellsProgressedOffset", CellsProgressedOffset)
    -- DebugWatch("_ CellsProgressedAdjusted", CellsProgressedAdjusted)
    -- DebugWatch("_ SpawnTrigger", Floor_SpawnedIndex - Floor_SpawnDist)
    -- DebugWatch("_ SpawnZ", SpawnZ)
    -- DebugWatch("s ReturnsCompleted", ReturnsCompleted)
    -- DebugWatch("s ShadowVolZOffset", ShadowVolZOffset)

end

function draw()

    if Config.draw_compass then
        DebugCompass()
    end


    UiColor(1,1,1, 1)
    UiTextShadow(0,0,0, 1, 0.3, 0.1)
    UiFont("regular.ttf", 20)
    UiAlign("left top")

    local s = 40 -- cell draw size
    ScrollY = ScrollY or 0
    ScrollY = ScrollY + InputValue("mousewheel")*s*3 -- Scroll drawn grid

    -- Draw grid preview
    if Config.draw_preview then
        UiPush()

            UiTranslate(100, UiHeight()*0.9 + ScrollY)

            for i, x in ipairs(GridXY) do

                for j, y in ipairs(GridXY[i]) do

                    UiPush() -- Y label

                        UiColor(0,0,0, 1)
                        UiAlign("center middle ")
                        UiTranslate(-10, -j*s + s/2)

                        if j == CellsProgressed then
                            UiColor(1,1,1, 1)
                        end

                        UiText(j)

                    UiPop()


                    UiPush() -- Y label

                        UiColor(0,0,0, 1)
                        UiAlign("center middle ")
                        UiTranslate(s*10, -j*s + s/2)

                        if j == CellsProgressed then
                            UiColor(1,1,1, 1)
                        end

                        UiText(TerritoryDataY[j])

                    UiPop()


                    local t = GridXY[i][j] -- tile

                    UiPush() -- Cell

                        UiTranslate(i * s, -j * s)
                        UiColor(t.c[1],t.c[2],t.c[3], 1)
                        UiRect(s-5, s-5)

                        UiTranslate(s/2, s/2)
                        UiAlign("center middle")

                        UiColor(0,0,0, 1)
                        UiText(t.id)

                    UiPop()

                end

            end

        UiPop()
    end

    -- Draw tile rectangles
    if Config.draw_tileIds then
        UiPush()

            for index, tile in ipairs(Tiles) do
                UiPush()

                    local pos = GetTileCenterPos(tile)
                    pos = VecAdd(pos, SpawnOffsetTr.pos)


                    local z = TransformToLocalPoint(GetCameraTransform(), pos)[3]
                    if z < 0 and z > -250 then -- Check rect infront

                        local x,y = UiWorldToPixel(pos)
                        local c = tile.c

                        UiTranslate(x,y)
                        UiColor(c[1], c[2], c[3], 0.75)
                        UiRect(s/1.5, s/1.5)

                        UiTranslate(s/3, s/3)
                        UiAlign("center middle")
                        UiColor(0,0,0, 1)
                        UiText(tile.id)

                    end

                UiPop()
            end

        UiPop()

        for z = 600, -600, -200 do
            UiPush()

                local pos = Vec(0,0,z)

                if TransformToLocalPoint(GetCameraTransform(), pos)[3] < 0 then -- Check rect infront

                    local x,y = UiWorldToPixel(pos)
                    UiTranslate(x,y)
                    UiAlign("center middle")
                    UiColor(0,0,0, 1)
                    UiTextShadow(1,1,1, 1, 0.3, 0.1)
                    UiFont("bold.ttf", 32)
                    UiText(sfn(z))

                end

            UiPop()
        end
    end

    if Config.retain_shadow_volume then

        Draw_ShadowVolume()

    end

end

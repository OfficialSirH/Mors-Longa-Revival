-- ((( This is just a temporary way to change the spawn chance. )))
TileLayouts = { -- Used to randomly assign tile dimensions.

    road = {
        { w = 1, h = 1, }, -- Single cells with potential vehicle spawns
        { w = 1, h = 1, }, -- Single cells with potential vehicle spawns
        { w = 1, h = 1, }, -- Single cells with potential vehicle spawns
        { w = 1, h = 1, }, -- Single cells with potential vehicle spawns
        { w = 1, h = 1, }, -- Single cells with potential vehicle spawns
        { w = 1, h = 1, }, -- Single cells with potential vehicle spawns
        { w = 1, h = 1, }, -- Single cells with potential vehicle spawns
        { w = 1, h = 1, }, -- Single cells with potential vehicle spawns
        { w = 1, h = 1, }, -- Single cells with potential vehicle spawns
        { w = 1, h = 1, }, -- Single cells with potential vehicle spawns
        { w = 1, h = 1, }, -- Single cells with potential vehicle spawns
        { w = 1, h = 1, }, -- Single cells with potential vehicle spawns
        { w = Width_Road, h = 1, }, -- Single cells with potential vehicle spawns
        { w = Width_Road, h = 1, }, -- Single cells with potential vehicle spawns
        { w = Width_Road, h = 1, }, -- Single cells with potential vehicle spawns
        { w = Width_Road, h = 1, }, -- Single cells with potential vehicle spawns
        { w = Width_Road, h = 1, }, -- Single cells with potential vehicle spawns
        { w = Width_Road, h = 1, }, -- Single cells with potential vehicle spawns
        { w = Width_Road, h = 1, }, -- Single cells with potential vehicle spawns
        { w = Width_Road, h = 2, }, -- Short roadblock
        -- { w = Width_Road, h = 3, }, -- Medium roadblock
    },

    sides = {
        { w = 1,          h = 1 }, -- vehicles, open desert, cactus, rocks
        { w = 1,          h = 1 }, -- vehicles, open desert, cactus, rocks
        { w = 1,          h = 1 }, -- vehicles, open desert, cactus, rocks
        { w = 1,          h = 1 }, -- vehicles, open desert, cactus, rocks
        { w = 1,          h = 1 }, -- vehicles, open desert, cactus, rocks
        { w = 1,          h = 1 }, -- vehicles, open desert, cactus, rocks
        { w = 1,          h = 1 }, -- vehicles, open desert, cactus, rocks
        { w = 1,          h = 1 }, -- vehicles, open desert, cactus, rocks
        { w = 1,          h = 1 }, -- vehicles, open desert, cactus, rocks
        { w = 1,          h = 1 }, -- vehicles, open desert, cactus, rocks
        { w = 1,          h = 1 }, -- vehicles, open desert, cactus, rocks
        { w = 1,          h = 1 }, -- vehicles, open desert, cactus, rocks
        { w = 1,          h = 1 }, -- vehicles, open desert, cactus, rocks
        { w = 1,          h = 1 }, -- vehicles, open desert, cactus, rocks
        { w = 1,          h = 1 }, -- vehicles, open desert, cactus, rocks
        { w = Width_Side, h = 3 }, -- buildings, gas stations
        { w = Width_Side, h = 5 }, -- Towns
    },

    -- Span across the entire row.
    spans = {
        { w = Width, h = 1 },
        -- { w = Width, h = 3 },
        -- { w = Width, h = 4 },
    }

}


--[[ progression spawning

    based on cells progressed/distance

    floor tiles
        regular highway
        canal overpass

    biomes
        desert
            - separates faction biomes.
        faction zones
            - a few chunks of areas that spawn with only a single faction.
            - more enemies but more loot. good weapons.
        loot
            - neutral areas with buildings and vehicles to loot.
            - mostly medical and food/drinks

    special chunks
        safe
            - single chunk that has only desert chunks on both ends so no enemies spawn.

    sides


    road

    spans
        bridges
        roadblocks
        bases


]]

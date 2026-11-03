--[[

    Requirements

        There should be only one procgen script with several modules to #include to avoid using the regsitry unnecesarily.
        It should be easy to configure and control different parts of the procgen system through config variables.

    Prefabs file organization

        Prefab files will have to be moved around and reorganized properly.
        File naming and directory structure will be extremely important.
        There is no way around this and it will have to be done near the start.
        Prefab will need to have attributes like:
            type (structures, segments, vehicles)
            size (applies to structures and vehicles)
            faction (civ, mil, um),
            rarity

    Scripting

        Spawned entities table
            Handle references of all spawned entities should be stored in a table.
            All entity operations should be done through said table instead of using Find functions.
        Registry data (like distance travelled) should be very organized for other scripts.

    Prefabs

        Segments

            Flat segments
                There should be a reusable bedrock voxbox for flat segments.
                All spawned prefabs should be placed on top of flat segments, including street lights.
                Structures spawned on flat segments can be spawned sequentially.
                The closest

            Special segments
                There should only be one special segment in the scene at a time.
                Special segments should be padded with flat segments on both sides.
                Only small buildings should be spawned in empty areas of special segments.
                Special segments will cause the largest lag spikes.

        Structures

            Buildings
                Sizes: small, medium, large

            Roadblocks
                Should have an open side with landmines and a closed side with a rock wall.
                Scenrios:
                    1. Player can abandon car to go through rocks.
                    2. Player can take the risk to drive through landmines.
                    3. Player can try to defeat enemies in the roadblock.

        Foliage

            Should only appear in sections with no existing prefabs.
            Should be spawned last to fill in some gaps.
            Foliage needs to be simple as the existing ones have way too many shapes and costly details.

        Loot Items

            Buildings should specify what kind of loot should be inside of them.
            Gun classes should progress from pistols to smgs to snipers based on distance travelled.

        Vehicles

]]
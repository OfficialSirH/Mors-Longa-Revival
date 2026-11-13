local relativePath = "MOD/prefabs/spawnables/loots/"


function npcs_debug_prefabs_guns(prefabs)

    print("Testing gun prefab paths in: " .. relativePath)

    for index, prefab in ipairs(prefabs) do

        local entities = Spawn(relativePath .. prefab.gun_path, Transform(Vec(0,10 * index,0)))

        if #entities == 0 then --> Check if path is valid.

            print(string_pad("Invalid prefab path: ", 25), string_pad(prefab.gun_path, 40))

        else --> Test if gun has light entity that's used as a handle.

            local hasLightHandle = false -- Flag

            for _, e in ipairs(entities) do
                if HasTag(e, "handle") and GetEntityType(e) == "light" then
                    hasLightHandle = true
                    break
                end
            end

            if not hasLightHandle then
                print(string_pad("Prefab missing \"handle\" light: ", 25), string_pad(prefab.gun_path, 40)) -- Check if path is valid.
            end

        end

        for _, e in ipairs(entities) do Delete(e) end -- Delete prefab.

    end

    print("\n")

end


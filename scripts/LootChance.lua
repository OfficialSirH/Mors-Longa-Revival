SpawnPool = {}


function Init_LootChance()

    MaxChance = 0

    LootChances = {
        { title = "common",   val = 250, },
        { title = "uncommon", val = 100, },
        { title = "rare",     val = 40, },
        { title = "epic",     val = 10, },
    }

    -- Determine the max loot chance.
    if MaxChance == 0 then
        for index, chance in ipairs(LootChances) do
            MaxChance = math.max(MaxChance, chance.val)
        end
    end

    print("MaxChance", MaxChance)

end

function GenerateSpawnPool(SpawnPool, items)

    for i = 1, items do

        local rdm = math.random(0, MaxChance)
        local title, val = Recur_CompareChance(LootChances, rdm, 1) -- Start at most likely chance.

        print(rdm, val, title)

    end

end


function Recur_CompareChance(LootChances, target, n)

    if n < #LootChances then

        if target <= LootChances[#LootChances].val then

            return LootChances[#LootChances].title, LootChances[#LootChances].val

        elseif target <= LootChances[n].val and target >= LootChances[n+1].val then

            return LootChances[n].title, LootChances[n].val -- Chance is within the range.

        else -- Shift to next range pair.

            return Recur_CompareChance(LootChances, target, n + 1)

        end

    end

end



-- Init_LootChance()
-- GenerateSpawnPool(SpawnPool, 30)

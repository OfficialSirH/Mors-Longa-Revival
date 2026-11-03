--[[
#include script/Automatic.lua
]]

--[[
    THIS IS TO INSURE THAT THE SCRIPT WILL BE THE LAST ONE CALLED, IT ISN'T PERFECT BECAUSE OTHER SCRIPTS COULD BE SPAWNED, BUT IT IS GOOD ENOUGH
]]

local finished_init = false
local spawned = false

function init()
    finished_init = true
end

function tick(dt)
    if finished_init then
        if not spawned then
            spawned = true
            AutoSpawnScript('MOD/script/reg.lua', 'parent=' .. AutoGetScriptHandle())
        end
    end
end

function update()

end

function draw()

end

--[[
#include Automatic.lua
#include helper.lua
]]

Base_Keys = {
    'game', 'hud', 'level', 'mods', 'options', 'savegame', 'spawn',
}

Keybinds = {
    Toggle = 'f2'
}

local parent_script = GetIntParam('parent')
local finished_init = false
local deleted_parent = false

REGISTRY = { key = '', value = '', children = {} }
WATCHING = {}
-- WATCHING = { ['game.pausemenu'] = 1, }

for _, k in pairs(Base_Keys) do
    WATCHING[k] = 0
    REGISTRY.children[k] = create_node(k)
end

Scroll = 0
Mode = 0


function init()
    finished_init = true
end

function tick(dt)
    if finished_init and not deleted_parent then
        Delete(parent_script)
        deleted_parent = true
    end

    for k, depth in pairs(WATCHING) do
        local n = resolve_node(k)
        scan(n, depth)
    end
end

function draw(dt)

    if GetBool("savegame.mod.config.db") then
        if InputPressed(Keybinds.Toggle) then
            Mode = (Mode + 1) % 3
        end
    else
        Mode = 0
    end


    if Mode >= 1 then
        if Mode == 1 then
            UiMakeInteractive()
            Scroll = Scroll + InputValue('mousewheel') * 16
        end

        UiTranslate(4, 4 + Scroll)
        
        for _, k in pairs(Base_Keys) do
            local height = tree(k)
            UiTranslate(0, height + 4)
        end
    end
end
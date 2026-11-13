#version 2
#include "script/include/player.lua"
-- (v2) client: debug registry viewer (F2 with debug mode on).
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

-- (v2) engine calls are not allowed while the file loads: parent param + registry tree moved to client.init
local parent_script = 0
local finished_init = false
local deleted_parent = false

REGISTRY = { key = '', value = '', children = {} }
WATCHING = {}
-- WATCHING = { ['game.pausemenu'] = 1, }

Scroll = 0
Mode = 0


function client.init()
    parent_script = GetIntParam('parent')
    for _, k in pairs(Base_Keys) do
        WATCHING[k] = 0
        REGISTRY.children[k] = create_node(k)
    end
    finished_init = true
end

function client.tick(dt)
    if finished_init and not deleted_parent then
        if parent_script ~= 0 then Delete(parent_script) end
        deleted_parent = true
    end

    for k, depth in pairs(WATCHING) do
        local n = resolve_node(k)
        scan(n, depth)
    end
end

function client.draw(dt)

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
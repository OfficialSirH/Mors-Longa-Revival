#version 2
#include "script/include/player.lua"
#include "../Config.lua"

-- (v2) The Mors Longa debug menu (BACKSPACE) and version text, formerly Config.lua's own init/tick/draw.
-- UI + input on the client; objects the menu spawns are created by the server (ConfigSpawn in Config.lua).

function server.init()
    init_config()
end

function server.configSpawn(xml, transform, allowStatic, makeStatic)
    local entities = allowStatic and Spawn(xml, transform, true, true) or Spawn(xml, transform)
    if makeStatic then
        for _, entity in ipairs(entities) do
            if GetEntityType(entity) == "body" then SetBodyDynamic(entity, false) end
        end
    end
end

function client.init() ConfigMenu_Init() end
function client.tick() ConfigMenu_Tick() end
function client.draw() ConfigMenu_Draw() end
function client.handleCommand(cmd) HandleQuickload(cmd) end

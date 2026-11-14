#version 2
#include "script/include/player.lua"
#include "../lib/Settings.lua"


-- (v2) server. Still uses the v1 registry keys game.tool.<id>.enabled like the v1 inventory does;
-- per-player tool enabling (SetToolEnabled) belongs to the Phase 2 inventory redesign.
function server.init()
    Init_Settings()
end

function server.tick()
    -- (v2, Phase 2) tools are now enabled per player by player/inventory.lua (server.tick), using the same rules
    -- (always-allowed list, tutorial, "enable all tools" setting). Running this too would fight it.
    do return end

    SetInt("game.tool.extinguisher.index", 4)

    if Settings.game.enable_tools.value then
        AllowAllTools()
        return
    end

    if not GetBool("level.tutorial") then
        ManageTools({"manual", "physgun", "welder", "placer", "extinguisher"})
    else
        ManageTools()
    end

end

function ManageTools(tb_tools_allow)

    tb_tools_allow = tb_tools_allow or {}

    -- disable all tools
    for index, tool in ipairs(ListKeys("game.tool")) do
        SetBool("game.tool." .. tool .. ".enabled", false)
    end

    -- enable only selected tools.
    for index, tool_id in ipairs(ListKeys("level.tools")) do
        SetBool("game.tool." .. tool_id.. ".enabled", GetBool("level.tools." .. tool_id))
    end

    for index, value in ipairs(tb_tools_allow) do
        SetBool("game.tool." .. value.. ".enabled", true)
    end

end

function AllowAllTools()
    for index, value in ipairs(ListKeys("game.tool")) do
        SetBool("game.tool." .. value.. ".enabled", true)
    end
end

--- add tool id as bool to keep enabled/disabled.
function RegisterToolId(tool_id, enabled)
    SetBool("level.tools.".. tool_id, enabled)
end


function server.handleCommand(cmd) handle_quickload(cmd) end
function handle_quickload(cmd)
    for _, word in ipairs(splitString(cmd, " ")) do
if word == "quickload" then
            Init_Settings()
        end
        break
    end
end
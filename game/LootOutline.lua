#version 2
#include "script/include/player.lua"
-- (2026-11-17, DEBUG) collector probe / skip switch, off unless level.debug.* is set (lib/GcProbe.lua)
#include "../lib/GcProbe.lua"
GCP_LABEL = "lootoutline"
--[[
(v2) ToolManager.lua is no longer included: nothing in it was used here, and it runs as its own level script.
#include "../lib/TDSU/tdsu.lua"
#include "../lib/Settings.lua"
#include "../lib/Config.lua"
#include "../lib/Automatic.lua"
#include "PrefabTester.lua"
]]


local maxAngle = 20
local maxDist = 8
LOOT_NEAR = maxDist + 12 -- (2026-11-17) radius of the 4x-a-second candidate list (see client.tick)


-- (v2) client: loot outlines, bounds debug draw, "Debug Mode" pause button
function client.init()

    ShowDebugMod = false -- toggle ui screen drawing.

    -- Init_Config()
    Init_Settings()

    init_prefab_tester()

end

function client.tick()

    if GetBool("savegame.mod.config.game.draw_bounds") then
        local min = Vec(-200, 0, -100)
        local max = Vec(200, 40, 100)
        AabbDraw(min, max, 1,1,0, 1)
    end

    -- Draw loot outlines.
    local pTr = GetPlayerTransform()
    pTr.pos = VecAdd(pTr.pos, Vec(0,0.5,0))
    -- (2026-11-17, performance) every "Loot" body in the world was searched and measured every frame (the road keeps
    -- adding loot until RemoveRoad clears it); ~0.85 ms measured. The ones within LOOT_NEAR (maxDist + 12 m of margin
    -- for movement in between) are collected 4x a second; the per-frame checks below are unchanged.
    local now = GetTime()
    if not LootNear or now >= LootNearAt then
        LootNearAt = now + 0.25
        LootNear = {}
        for _, body in ipairs(FindBodies("Loot", true)) do
            if VecDist(pTr.pos, GetBodyTransform(body).pos) < LOOT_NEAR then LootNear[#LootNear + 1] = body end
        end
    end
    for _, body in ipairs(LootNear) do
        -- (a body collected up to 0.25 s ago may have been picked up / deleted since)
        local bodyTr = IsHandleValid(body) and GetBodyTransform(body)

        local dist = bodyTr and clamp(VecDist(pTr.pos, bodyTr.pos), 2, maxDist) or maxDist
        if dist < maxDist and HasTag(body, "interact") and HasTag(body, "Loot") then

            if QuatAngle(pTr.rot, QuatLookAt(pTr.pos, bodyTr.pos)) < maxAngle then
                local a = 1 - (dist/maxDist)
                DrawBodyNonInvisibleOutline(body, 1,1,1, a)
            end

        end

    end

    -- Config >> Debug mode.
    Debug = GetBool("savegame.mod.config.db")
    if PauseMenuButton("Debug Mode " .. ternary(Debug, "ON", "OFF")) then
        SetBool("savegame.mod.config.db", not Debug)
    end


    -- for index, body in ipairs(FindBodies("", true)) do
    --     if IsBodyActive(body) then
    --         DebugLine(GetPlayerTransform().pos, GetBodyTransform(body).pos, 1,1,0, 1/2)
    --     end
    -- end

    -- for index, body in ipairs(FindShapes("detail", true)) do
    --     DrawShapeOutline(body, 1,0,0.5, 1/2)
    -- end

end

function DrawBodyNonInvisibleOutline(b,...)
    local ss=GetBodyShapes(b)
    for i=1,#ss do
        if not HasTag(ss[i], "invisible")then
            DrawShapeOutline(ss[i],...)
        end
    end
end
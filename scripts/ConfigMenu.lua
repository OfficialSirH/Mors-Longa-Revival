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

-- (v2) Debug menu "vehicle event" buttons (ConfigVehicleEvent in Config.lua). Procedural/RandomVehicleEnemy.lua
-- reads this server registry key on its next tick and runs the event. pos = crosshair (only for "roadblock").
function server.configVehicleEvent(name, pos)
    pos = pos or Vec()
    SetFloat("level.debug.vehicle_event_x", pos[1])
    SetFloat("level.debug.vehicle_event_y", pos[2])
    SetFloat("level.debug.vehicle_event_z", pos[3])
    SetString("level.debug.vehicle_event", name)
end

-- (v2) Debug auto-travel (debug menu "Auto Travel" buttons, ConfigTravel in Config.lua): moves the player forward
-- along the road (+x) until the distance counter (savegame.mod.distanceProgressed) reached start + meters, so a long
-- drive (generation, spawns, cleanup, world shifts) happens without playing it. Hovers TRAVEL_HOVER m above the road
-- in the start lane at TRAVEL_SPEED m/s and waits while there is no road ahead yet. After a world shift
-- (level.world_shifts from GenerateRoad.lua) it pauses a few ticks so it never writes back a pre-shift position.
TRAVEL_SPEED = 40
TRAVEL_HOVER = 2.5

function server.configTravel(p, meters)
    if not meters or meters <= 0 then
        Travel = nil
        shared.travel = nil
        return
    end
    if GetPlayerVehicle(p) ~= 0 then SetPlayerVehicle(0, p) end
    local t = GetPlayerTransform(p)
    local groundY = t.pos[2]
    local hit, dist = QueryRaycast(VecAdd(t.pos, Vec(0, 3, 0)), Vec(0, -1, 0), 20)
    if hit then groundY = t.pos[2] + 3 - dist end
    local start = GetFloat("savegame.mod.distanceProgressed")
    Travel = {
        p = p, start = start, target = start + meters, y = groundY + TRAVEL_HOVER, z = t.pos[3],
        rot = t.rot, shifts = GetInt("level.world_shifts"), wait = 0, published = -1,
    }
end

function server.tick(dt)
    TickTravel(dt)
end

function TickTravel(dt)
    local tr = Travel
    if not tr then return end
    if not IsPlayerValid(tr.p) or GetPlayerHealth(tr.p) <= 0 then
        Travel, shared.travel = nil, nil
        return
    end
    local dist = GetFloat("savegame.mod.distanceProgressed")
    if dist >= tr.target then
        SetPlayerVelocity(Vec(), tr.p)
        Travel, shared.travel = nil, nil
        return
    end
    local shifts = GetInt("level.world_shifts")
    if shifts ~= tr.shifts then
        tr.shifts = shifts
        tr.wait = 3
    end
    if tr.wait > 0 then
        tr.wait = tr.wait - 1
        return
    end
    if GetPlayerVehicle(tr.p) ~= 0 then SetPlayerVehicle(0, tr.p) end
    local pos = GetPlayerTransform(tr.p).pos
    local roadAhead = QueryRaycast(Vec(pos[1] + 30, tr.y + 20, tr.z), Vec(0, -1, 0), 60)
    local step = roadAhead and TRAVEL_SPEED * dt or 0
    SetPlayerTransform(Transform(Vec(pos[1] + step, tr.y, tr.z), tr.rot), tr.p)
    SetPlayerVelocity(Vec(), tr.p)
    if GetTime() - tr.published > 0.25 then
        tr.published = GetTime()
        shared.travel = { done = math.max(0, dist - tr.start), total = tr.target - tr.start, waiting = not roadAhead }
    end
end

function client.init() ConfigMenu_Init() end
function client.tick() ConfigMenu_Tick() end
function client.draw()
    ConfigMenu_Draw()
    local tr = shared.travel
    if tr then -- (v2) auto-travel progress
        UiPush()
            UiFont("bold.ttf", 28)
            UiAlign("center top")
            UiTranslate(UiCenter(), 120)
            UiTextShadow(0, 0, 0, 0.8, 1.5)
            UiColor(1, 1, 0.5, 1)
            UiText(string.format("Auto-travel: %.1f / %.1f km%s  (debug menu: Stop)", tr.done / 1000, tr.total / 1000,
                tr.waiting and "  - waiting for road" or ""))
        UiPop()
    end
end
function client.handleCommand(cmd) HandleQuickload(cmd) end

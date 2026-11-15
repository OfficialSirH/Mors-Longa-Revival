#version 2
#include "script/include/player.lua"
#include "../lib/Config.lua"
#include "ShiftProbe.lua"
#include "NpcProbe.lua"

-- (v2) The Mors Longa debug menu (BACKSPACE) and version text, formerly Config.lua's own init/tick/draw.
-- UI + input on the client; objects the menu spawns are created by the server (ConfigSpawn in Config.lua).

function server.init()
    init_config()
    NpcProbe_ServerInit()
end

function server.configSpawn(xml, transform, allowStatic, makeStatic)
    local entities = allowStatic and Spawn(xml, transform, true, true) or Spawn(xml, transform)
    if makeStatic then
        for _, entity in ipairs(entities) do
            if GetEntityType(entity) == "body" then SetBodyDynamic(entity, false) end
        end
    end
end

-- (2026-11-14, performance) Debug menu "Performance tests": each button does ONE piece of a road segment's work,
-- 40 m above the host, so its freeze can be felt on its own (the API has no wall clock to time it). Spawns are tagged
-- "perftest"; "delete test spawns" removes them (and shows what deleting costs).
PERFTEST = {
    segment = "MOD/prefabs/spawnables/roadsegments/RoadSegment1.xml",
    ground = '<voxbox pos="0.0 0.0 0.0" size="2000 1 784" brush="MOD/main/terrain/ground_building_assets_highway.vox" object="sand:normal"/>',
    decor = "MOD/prefabs/spawnables/roadsegments/decor/RoadSegment1_left.xml",
    -- one rock1.vox reference (8 rocks: 7.4M cells in their boxes, 1.47M filled) and variants
    -- (tools/porting/rock_variant.py). Hollow (same boxes, 0.51M filled): hitch about the same (user, 10 at once).
    -- Half resolution at twice the scale (same size and shapes, 0.94M box cells): much less -> option "Low Detail
    -- Rocks" (rock1_low.vox: tools/porting/rock_variant.py, used per rock piece by segment_pieces.py)
    rock = '<vox pos="0.0 0.0 0.0" file="MOD/assets/vox/terrainpieces/rock1.vox"/>',
    rockhollow = '<vox pos="0.0 0.0 0.0" file="MOD/dev/perftest/rock1_hollow.vox"/>',
    rockhalf = '<vox pos="0.0 0.0 0.0" file="MOD/assets/vox/terrainpieces/rock1_low.vox" scale="2"/>',
}
-- several copies in the SAME frame, 15 m apart in a row (a segment's rocks came all at once before split_heavy.py)
PERFTEST_MANY = { rock10 = { "rock", 10 }, rockhollow10 = { "rockhollow", 10 }, rockhalf10 = { "rockhalf", 10 } }
-- placement check for tools/porting/vox_pieces.py: the whole model, and beside it (+x) its pieces spawned one by one
-- (one file per placed model, same scene transform): the copy must look identical, no gaps or offsets
PERFTEST_SPLIT = {
    rockpieces = { "rock1", 8, 25 },
    hillpieces = { "hill1", 22, 80 },
}
function server.perfTest(p, kind)
    local pos = VecAdd(GetPlayerTransform(p).pos, Vec(0, 40, 0))
    if kind == "scan" then
        -- what RemoveRoad's pass does for every shape, without deleting anything
        local n = 0
        for _, s in ipairs(FindShapes(nil, true)) do
            if not HasTag(s, "nodelete") then
                local t = GetShapeWorldTransform(s)
                if t.pos[1] > 1e9 then n = n + 1 end
            end
        end
        DebugPrint("perftest scan: " .. #FindShapes(nil, true) .. " shapes")
        return
    end
    if kind == "npcs10" then
        -- (2026-11-15, NPC performance) 10 normal hostile NPCs 25-35 m ahead, through the real spawner: markers like
        -- a road segment's (world/generation/RandomEnemy.lua turns them into NPCs, one per frame). FPS with the
        -- Gore NPCs switches (Thinking / Run and Navigate / Script enabled / Delete All NPCs) shows what costs.
        local t = GetPlayerTransform(p)
        local fwd = TransformToParentVec(t, Vec(0, 0, -1))
        fwd = VecNormalize(Vec(fwd[1], 0, fwd[3]))
        local side = Vec(-fwd[3], 0, fwd[1])
        for i = 0, 9 do
            local guess = VecAdd(VecAdd(t.pos, VecScale(fwd, 25 + (i % 2) * 10)), VecScale(side, (math.floor(i / 2) - 2) * 4))
            local from = VecAdd(guess, Vec(0, 30, 0))
            local hit, dist = QueryRaycast(from, Vec(0, -1, 0), 80)
            local ground = hit and VecAdd(from, Vec(0, -dist + 0.2, 0)) or guess
            Spawn('<location tags="RandomRagdoll Type=civ chance=100 outside"/>', Transform(ground), true)
        end
        DebugPrint("perftest: 10 NPC markers placed (RandomEnemy spawns them one per frame)")
        return
    end
    if kind == "pieces" then
        PerfPieces = { i = 0, next = GetTime(), pos = pos }
        DebugPrint("perftest pieces: " .. #PERFTEST_PIECES .. " pieces, one every 2.5 s")
        return
    end
    local count = 1
    local list
    if PERFTEST_MANY[kind] then kind, count = PERFTEST_MANY[kind][1], PERFTEST_MANY[kind][2] end
    if PERFTEST_SPLIT[kind] then
        local s = PERFTEST_SPLIT[kind]
        list = { { '<vox pos="0.0 0.0 0.0" file="MOD/assets/vox/terrainpieces/' .. s[1] .. '.vox"/>', pos } }
        for k = 0, s[2] - 1 do
            list[#list + 1] = { string.format('<vox pos="0.0 0.0 0.0" file="MOD/assets/vox/terrainpieces/pieces/%s_%02d.vox"/>', s[1], k),
                VecAdd(pos, Vec(s[3], 0, 0)) }
        end
    else
        local xml = PERFTEST[kind]
        if not xml then return end
        list = {}
        for i = 1, count do list[i] = { xml, VecAdd(pos, Vec((i - 1) * 15, 0, 0)) } end
    end
    local shapes = 0
    for _, item in ipairs(list) do
        local entities = Spawn(item[1], Transform(item[2]), true)
        for _, e in ipairs(entities) do
            local t = GetEntityType(e)
            if t == "shape" or t == "body" or t == "location" or t == "trigger" or t == "light" then SetTag(e, "perftest") end
            if t == "shape" then shapes = shapes + 1 end
        end
    end
    if count > 1 then kind = kind .. " x" .. count end
    DebugPrint("perftest " .. kind .. ": " .. shapes .. " shapes spawned")
end
function server.perfTestDelete()
    local n = 0
    for _, s in ipairs(FindShapes("perftest", true)) do Delete(s) n = n + 1 end
    for _, b in ipairs(FindBodies("perftest", true)) do Delete(b) end
    for _, l in ipairs(FindLocations("perftest", true)) do Delete(l) end
    for _, t in ipairs(FindTriggers("perftest", true)) do Delete(t) end
    DebugPrint("perftest: deleted " .. n .. " shapes")
end

-- (v2) Debug menu "vehicle event" buttons (ConfigVehicleEvent in Config.lua). world/generation/RandomVehicleEnemy.lua
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
    TickPerfPieces()
    TickActivity()
    ShiftProbe_ServerTick()
    NpcProbe_ServerTick()
end

-- (2026-11-14, performance) Debug menu "spawn activity" (savegame.mod.debug.activity, host): an on-screen list of
-- what the generation scripts spawned in the last seconds (each spawn writes level.debug.spawned.<name> = GetTime()),
-- the segment parts still waiting and the NPC bodies in the level, so a stretch of lag can be matched to its cause.
ACTIVITY_NAMES = { "segment", "part", "decor", "building", "roadblock", "enemy", "vehicle", "vehicle_event", "loot",
    "roadsign", "burnt", "cleanup", "world_shift" }
-- The server publishes, every tick while the readout is on, when each kind of spawn last happened (server GetTime)
-- and what it was (file / piece cells). The slow-frame log is on the host's CLIENT (TickSlowFrames): the server
-- tick's GetTimeStep() never exceeded 50 ms during visible freezes (capped), the client's is the frame time.
function TickActivity()
    if not GetBool("savegame.mod.debug.activity") then
        shared.activity = nil
        return
    end
    if GetTime() >= (ActivityNpcNext or 0) then
        ActivityNpcNext = GetTime() + 1
        ActivityNpcs = #FindBodies("Torso", true)
        -- (2026-11-15) how much world is alive (more content = lower steady FPS), and the leader's x (shift at ~93)
        ActivityShapes = #FindShapes(nil, true)
        ActivityBodies = #FindBodies(nil, true)
        local lead = -math.huge
        for pl in Players() do lead = math.max(lead, GetPlayerTransform(pl).pos[1]) end
        ActivityLeadX = lead
    end
    local times, what = {}, {}
    for _, name in ipairs(ACTIVITY_NAMES) do
        times[name] = GetFloat("level.debug.spawned." .. name)
        what[name] = GetString("level.debug.what." .. name)
    end
    shared.activity = { now = GetTime(), times = times, what = what, parts = GetInt("level.debug.parts_waiting"),
        npcs = ActivityNpcs or 0, shapes = ActivityShapes or 0, bodies = ActivityBodies or 0, leadX = ActivityLeadX or 0,
        ahead = GetInt("savegame.mod.debug.gen_ahead") > 0 and GetInt("savegame.mod.debug.gen_ahead") or 300 }
end

-- (2026-11-14) Debug menu "probe ground": every shape along the host's line of sight (the ray goes on through each
-- hit), then every shape in a 1 m box under the first hit (the ray may pass through shapes without collision), with
-- what the engine says: material and palette entry at that point, size and voxel size, collision layer/mask,
-- static/dynamic, tags. For the report "no collision on the bottom layer once the top layer is broken".
function ProbeLine(shape, point, dist)
    local mat, _, _, _, _, entry = GetShapeMaterialAtPosition(shape, point, true)
    local sx, sy, sz, vs = GetShapeSize(shape)
    local layer, mask = GetShapeCollisionFilter(shape)
    local body = GetShapeBody(shape)
    local tags = ListTags(shape) or {}
    return string.format("%s%s (pal %d) %dx%dx%d @%.1fm  coll %d/%d  %s  %s", dist and string.format("%.2f m: ", dist) or "",
        mat ~= "" and mat or "-", entry or 0, sx, sy, sz, vs or 0, layer or -1, mask or -1,
        IsBodyDynamic(body) and "dynamic" or "static", table.concat(tags, " "))
end

function server.probeGround(origin, dir)
    local lines, rejected, first = {}, {}, nil
    for i = 1, 6 do
        QueryRejectShapes(rejected)
        local hit, dist, _, shape = QueryRaycast(origin, dir, 80)
        if not hit then
            lines[#lines + 1] = "(ray: no more hits)"
            break
        end
        local p = VecAdd(origin, VecScale(dir, dist + 0.02))
        first = first or p
        lines[#lines + 1] = "ray " .. ProbeLine(shape, p, dist)
        rejected[#rejected + 1] = shape
    end
    if first then
        local seen = {}
        for _, s in ipairs(rejected) do seen[s] = true end
        for _, s in ipairs(QueryAabbShapes(VecAdd(first, Vec(-0.5, -1, -0.5)), VecAdd(first, Vec(0.5, 0, 0.5))) or {}) do
            if not seen[s] then
                -- the deepest voxel of this shape found in the 1 m column under the first hit
                local found
                for k = 0, 20 do
                    local q = VecAdd(first, Vec(0, -k * 0.05, 0))
                    local m = GetShapeMaterialAtPosition(s, q, true)
                    if m ~= "" then found = q end
                end
                lines[#lines + 1] = "box " .. ProbeLine(s, found or first, nil) .. (found and "" or " (no voxel in the column)")
            end
        end
    end
    shared.probe = lines
    DebugPrint("probe: " .. #lines .. " lines (debug menu readout)")
end

function DrawProbe()
    local lines = shared.probe
    if not lines or not IsPlayerHost(GetLocalPlayer()) then return end
    UiPush()
        UiFont("regular.ttf", 18)
        UiAlign("left top")
        UiTranslate(UiWidth() - 760, 200)
        UiTextShadow(0, 0, 0, 0.9, 1.5)
        UiColor(0.7, 0.95, 1, 1)
        UiText("probe (first hit downward / along sight):")
        for _, l in ipairs(lines) do
            UiTranslate(0, 21)
            UiText(l)
        end
    UiPop()
end

-- (2026-11-14) A slow-frame log was tried here and removed: GetTimeStep() / the frame time a script sees is capped
-- at 1/30 s on both server and client (the readout showed 33 ms, max 33 ms, while the game's counter showed 4 FPS),
-- so scripts cannot time a freeze. The readout's "what" line still names the last file of each kind.

function DrawActivity()
    local a = shared.activity
    if not a or not IsPlayerHost(GetLocalPlayer()) then return end
    UiPush()
        UiFont("bold.ttf", 20)
        UiAlign("left top")
        UiTranslate(20, 200)
        UiTextShadow(0, 0, 0, 0.8, 1.5)
        UiColor(1, 1, 1, 1)
        UiText(string.format("segment parts waiting: %d   NPC bodies: %d", a.parts or 0, a.npcs or 0))
        UiTranslate(0, 24)
        UiText(string.format("alive: %d shapes, %d bodies   leader x %.0f   generate ahead %d m", a.shapes or 0,
            a.bodies or 0, a.leadX or 0, a.ahead or 300))
        UiTranslate(0, 24)
        for _, name in ipairs(ACTIVITY_NAMES) do
            local t = a.times and a.times[name] or 0
            local age = t > 0 and a.now - t or -1
            if age >= 0 and age < 3 then UiColor(1, 0.9, 0.3, 1) else UiColor(0.7, 0.7, 0.7, 0.8) end
            local detail = ((a.what and a.what[name]) or ""):gsub("^MOD/prefabs/spawnables/", "")
            UiText(name .. ": " .. (age < 0 and "-" or string.format("%.1f s ago", age)) .. (detail ~= "" and ("  " .. detail) or ""))
            UiTranslate(0, 22)
        end
    UiPop()
end

-- "segment piece by piece": RoadSegment1 cut into its content groups by tools/porting/perf_pieces.py (dev files,
-- not in the release), spawned one every 2.5 s with its name printed, to pin the segment's freeze on one group
PERFTEST_PIECES = {
    { "road", "MOD/dev/perftest/RoadSegment1_01_road.xml" },
    { "highway lights", "MOD/dev/perftest/RoadSegment1_02_highway_lights.xml" },
    { "terrain", "MOD/dev/perftest/RoadSegment1_03_terrain.xml" },
    { "ground sand", "MOD/dev/perftest/RoadSegment1_04_ground_sand.xml" },
    { "ground voxagon", "MOD/dev/perftest/RoadSegment1_06_ground_voxagon.xml" },
    { "ground ditch", "MOD/dev/perftest/RoadSegment1_07_ground_ditch.xml" },
    { "ground water", "MOD/dev/perftest/RoadSegment1_08_ground_water.xml" },
    { "ground wall", "MOD/dev/perftest/RoadSegment1_09_ground_wall.xml" },
    { "ground vox", "MOD/dev/perftest/RoadSegment1_10_ground_vox.xml" },
    { "signs", "MOD/dev/perftest/RoadSegment1_11_signs.xml" },
    { "Power Lines", "MOD/dev/perftest/RoadSegment1_12_Power_Lines.xml" },
    { "Background", "MOD/dev/perftest/RoadSegment1_13_Background.xml" },
    { "trigger", "MOD/dev/perftest/RoadSegment1_14_trigger.xml" },
}
function TickPerfPieces()
    local seq = PerfPieces
    if not seq or GetTime() < seq.next then return end
    seq.i = seq.i + 1
    local piece = PERFTEST_PIECES[seq.i]
    if not piece then
        DebugPrint("perftest pieces: done")
        PerfPieces = nil
        return
    end
    local entities = Spawn(piece[2], Transform(seq.pos), true)
    local shapes = 0
    for _, e in ipairs(entities) do
        local t = GetEntityType(e)
        if t == "shape" or t == "body" or t == "location" or t == "trigger" or t == "light" then SetTag(e, "perftest") end
        if t == "shape" then shapes = shapes + 1 end
    end
    DebugPrint(string.format("piece %d/%d: %s (%d shapes)", seq.i, #PERFTEST_PIECES, piece[1], shapes))
    seq.next = GetTime() + 2.5
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
function client.tick() ConfigMenu_Tick() ShiftProbe_ClientTick() NpcProbe_ClientTick() end
function client.draw()
    ConfigMenu_Draw()
    DrawActivity()
    DrawProbe()
    ShiftProbe_Draw()
    NpcProbe_Draw()
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

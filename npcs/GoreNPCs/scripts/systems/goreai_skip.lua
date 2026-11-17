-- (2026-11-17, NPC performance research, DEBUG ONLY) Cost of each part of the NPC manager, read in Teardown's
-- profiler (SHIFT+ALT+F3, goreai_main's Tick / Update averages): level.goreai.skip holds a comma-separated list of
-- global function names of this script (e.g. "npc_robot_update,npc_process_thinking"); each listed function does
-- nothing while it is listed (it returns nil, so only list functions whose result is not used). Empty = normal.
-- Changes NPC behaviour while set (e.g. skipping npc_robot_update makes them fall): for measuring only.

GoreSkipOrig = {}
GoreSkipList = ""

-- (2026-11-17, DEBUG) once a second: what the per-npc loops go through (level.debug.npc_table): npc records by state,
-- their projectile shells (total / active), NPC_Bodies and NPC_Torsos sizes, and Lua memory (collectgarbage count)
-- Allocation rate (kB of new Lua objects per second of this script): every other second the garbage collector is
-- stopped and the memory growth over that second measured, then it is restarted (level.debug.npc_alloc). Only
-- while level.goreai.alloc_probe is set (debug).
-- level.goreai.gc_pause (debug, int; 0 = this script's setting GORE_GC_PAUSE, set in server.init): the collector's
-- pause, i.e. how far the heap grows (in % of the live heap after a cycle) before the next cycle starts
GORE_GC_PAUSE = 500
function GoreSkip_GcPause()
    local p = GetInt("level.goreai.gc_pause")
    if p == (GoreGcPause or 0) or not collectgarbage then return end
    GoreGcPause = p
    collectgarbage("setpause", p > 0 and p or GORE_GC_PAUSE)
end

function GoreSkip_AllocProbe()
    GoreSkip_GcPause()
    -- level.goreai.gc_off (debug): garbage collector stopped while set, to see its share in the profiler; the live
    -- heap (after a full collection) is measured once when it is cleared again and on each probe window
    if collectgarbage and GetBool("level.goreai.gc_off") then
        if not GoreGcOff then collectgarbage("stop") GoreGcOff = true end
        return
    elseif GoreGcOff then
        GoreGcOff = nil
        collectgarbage("collect")
        collectgarbage("restart")
        SetString("level.debug.npc_heap", string.format("%.0f kB live", collectgarbage("count")))
    end
    if not GetBool("level.goreai.alloc_probe") or not collectgarbage then
        if GoreAlloc then collectgarbage("restart") GoreAlloc = nil end
        return
    end
    local now = GetTime()
    if not GoreAlloc then
        GoreAlloc = { at = now + 1, stopped = false }
        return
    end
    if now < GoreAlloc.at then return end
    if GoreAlloc.stopped then
        local kb = collectgarbage("count") - GoreAlloc.start
        SetString("level.debug.npc_alloc", string.format("%.0f kB/s (%.1f kB per tick), update_npcs_full %.0f kB/s, err %s",
            kb / (now - GoreAlloc.t0), kb / math.max(1, TICK - GoreAlloc.tick0), (GoreAllocFull or 0) / (now - GoreAlloc.t0),
            tostring(GoreAllocErr)))
        GoreAllocFull = 0
        local parts = {}
        for name, kb2 in pairs(GoreAllocFns) do
            parts[#parts + 1] = string.format("%s %.0f", name, kb2 / (now - GoreAlloc.t0))
            GoreAllocFns[name] = 0
        end
        table.sort(parts)
        SetString("level.debug.npc_alloc_fns", table.concat(parts, ", "))
        collectgarbage("restart")
        GoreAlloc.stopped = false
        GoreAlloc.at = now + 1
    else
        collectgarbage("collect")
        collectgarbage("stop")
        GoreAlloc.stopped, GoreAlloc.start, GoreAlloc.t0, GoreAlloc.tick0 = true, collectgarbage("count"), now, TICK
        SetString("level.debug.npc_heap", string.format("%.0f kB live", GoreAlloc.start))
        GoreAlloc.at = now + 1
    end
end

-- Allocation per function (inclusive, kB/s while the probe has the collector stopped): level.goreai.alloc_fns is a
-- comma-separated list of global function names; each is wrapped to add its memory growth to GoreAllocFns[name].
GoreAllocFnsList, GoreAllocOrig, GoreAllocFns = "", {}, {}
function GoreSkip_AllocFns()
    local list = GetString("level.goreai.alloc_fns")
    if list == GoreAllocFnsList then return end
    GoreAllocFnsList = list
    for name, f in pairs(GoreAllocOrig) do _G[name] = f end
    GoreAllocOrig, GoreAllocFns = {}, {}
    for name in string.gmatch(list, "[%w_]+") do
        local f = _G[name]
        if type(f) == "function" then
            GoreAllocOrig[name] = f
            GoreAllocFns[name] = 0
            _G[name] = function(...)
                if not (GoreAlloc and GoreAlloc.stopped) then return f(...) end
                local c = collectgarbage("count")
                local r = { f(...) }
                GoreAllocFns[name] = GoreAllocFns[name] + collectgarbage("count") - c
                return unpack(r)
            end
        end
    end
end

function GoreSkip_Readout()
    GoreSkip_AllocFns()
    GoreSkip_AllocProbe()
    if GetTime() < (GoreSkipReadAt or 0) then return end
    GoreSkipReadAt = GetTime() + 1
    local n, alive, dead, rest, invalid, shells, active = 0, 0, 0, 0, 0, 0, 0
    for _, npc in pairs(NPCs) do
        n = n + 1
        if not npc.isValid then invalid = invalid + 1
        elseif npc.restDead then rest = rest + 1
        elseif npc.dead then dead = dead + 1
        else alive = alive + 1 end
        local sh = npc.projectileHandler and npc.projectileHandler.shells or {}
        shells = shells + #sh
        for _, s in ipairs(sh) do if s.active then active = active + 1 end end
    end
    local torsos = 0
    for _ in pairs(NPC_Torsos) do torsos = torsos + 1 end
    SetString("level.debug.npc_table", string.format(
        "records %d (alive %d, dead %d, settled %d, invalid %d), shells %d (active %d), NPC_Bodies %d, NPC_Torsos %d, lua %d kB",
        n, alive, dead, rest, invalid, shells, active, #NPC_Bodies, torsos, collectgarbage and collectgarbage("count") or -1))
end

function GoreSkip_Tick()
    GoreSkip_Readout()
    local list = GetString("level.goreai.skip")
    if list == GoreSkipList then return end
    GoreSkipList = list
    for name, f in pairs(GoreSkipOrig) do _G[name] = f end
    GoreSkipOrig = {}
    for name in string.gmatch(list, "[%w_]+") do
        if type(_G[name]) == "function" then
            GoreSkipOrig[name] = _G[name]
            _G[name] = function() end
        end
    end
end

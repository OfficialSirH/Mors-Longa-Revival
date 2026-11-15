-- (2026-11-15, MP) Debug menu "shift probe" (savegame.mod.debug.shiftprobe, host; published to every machine as
-- level.debug.shiftprobe). For the report "for non-hosts everything is thrown around for a moment at each world
-- shift" (TECHNICAL_REFERENCE §10): the shift (GenerateRoad.lua ReturnToShadowVolume) moves every body 200 m back
-- in one server tick, and nothing in the docs says how that reaches a client. Each machine watches up to
-- SHIFT_PROBE_MAX bodies around its own player and, from the frame a shift shows up (the synced shift counter
-- changes or a watched body jumps over 100 m), records SHIFT_PROBE_FRAMES frames: per frame, how many bodies of
-- each kind are still at the old place (old), on the way (between) or at the new place (new), and how many of the
-- bodies that already arrived jump in one frame (snap) or are suddenly fast (flung): "off". So the screenshots of host and client tell:
-- updates arriving over several frames (old and new mixed), positions sliding (between), or bodies being knocked
-- about after arriving (thrown). Positions are what scripts see (physics), not a render-only smoothing.

SHIFT_PROBE_FRAMES = 90      -- ~1.5 s at 60 FPS
SHIFT_PROBE_MAX = 80         -- watched bodies (NPCs, vehicles and dynamic bodies first, then static)
SHIFT_PROBE_STATIC = 20
SHIFT_PROBE_RADIUS = 60
SHIFT_DIST = 200             -- GenerateRoad.lua ReturnToShadowVolume shiftDist
SHIFT_NEAR = 15              -- within this of the expected old / new x counts as there
SHIFT_SNAP = 1               -- arrived, then moved this much more in one frame than its velocity: snapped (a correction)
SHIFT_FLUNG = 10             -- arrived, then this much faster (m/s) than before the shift: flung
SHIFT_KINDS = { "static", "dynamic", "npc", "vehicle" }

SP = { sample = {}, prev = nil, rec = nil, report = nil, nextSample = 0, shifts = nil }

--- Server (host): publish the host's toggle to every machine.
function ShiftProbe_ServerTick()
    local on = GetBool("savegame.mod.debug.shiftprobe")
    if on ~= ShiftProbeSent then
        ShiftProbeSent = on
        SetBool("level.debug.shiftprobe", on, true)
    end
end

function ShiftProbe_Kind(h)
    if HasTag(h, "Torso") then return "npc" end
    if GetBodyVehicle(h) ~= 0 then return "vehicle" end
    if IsBodyDynamic(h) then return "dynamic" end
    return "static"
end

--- Pick the bodies to watch around the local player.
function ShiftProbe_Sample(me)
    local p = GetPlayerTransform(me).pos
    local r = SHIFT_PROBE_RADIUS
    local list = QueryAabbBodies(Vec(p[1] - r, p[2] - 30, p[3] - r), Vec(p[1] + r, p[2] + 30, p[3] + r)) or {}
    local moving, static = {}, {}
    for _, h in ipairs(list) do
        local kind = ShiftProbe_Kind(h)
        if kind == "static" then static[#static + 1] = { h = h, kind = kind }
        else moving[#moving + 1] = { h = h, kind = kind } end
    end
    local out = {}
    for _, b in ipairs(moving) do if #out < SHIFT_PROBE_MAX - SHIFT_PROBE_STATIC then out[#out + 1] = b end end
    for _, b in ipairs(static) do if #out < SHIFT_PROBE_MAX then out[#out + 1] = b end end
    SP.sample = out
end

--- x and x velocity of every watched body (and the local player as kind "me") this frame
function ShiftProbe_Read(me)
    local now = {}
    for i, b in ipairs(SP.sample) do
        if IsHandleValid(b.h) then
            local v = GetBodyVelocity(b.h)
            now[i] = { x = GetBodyTransform(b.h).pos[1], vx = v[1], v = VecLength(v) }
        end
    end
    local v = GetPlayerVelocity(me)
    now.me = { x = GetPlayerTransform(me).pos[1], vx = v[1], v = VecLength(v) }
    return now
end

--- old / between / new for one body: d = x - (x before the shift + its velocity then * time)
function ShiftProbe_Class(base, cur, t)
    local d = cur.x - (base.x + base.vx * t)
    if math.abs(d) < SHIFT_NEAR then return "old", d end
    if math.abs(d + SHIFT_DIST) < SHIFT_NEAR then return "new", d + SHIFT_DIST end
    return "between", d
end

function ShiftProbe_ClientTick()
    if not GetBool("level.debug.shiftprobe") then
        SP.sample, SP.prev, SP.rec, SP.report = {}, nil, nil, nil
        return
    end
    local me = GetLocalPlayer()
    local t = GetTime()
    local shifts = GetInt("level.world_shifts")
    if SP.shifts == nil then SP.shifts = shifts end
    local counter = shifts ~= SP.shifts
    if not SP.rec and t >= SP.nextSample then
        ShiftProbe_Sample(me)
        SP.nextSample = t + 1
        SP.prev = nil -- new sample: no previous frame for it
    end
    local now = ShiftProbe_Read(me)

    if not SP.rec and SP.prev then
        local jumped = false
        for i, cur in pairs(now) do
            local old = SP.prev.pos[i]
            if old and cur.x - old.x < -100 then jumped = true break end
        end
        if counter or jumped then
            SP.rec = { base = SP.prev.pos, t0 = SP.prev.t, frames = {}, counterAt = counter and t or nil,
                arrived = {}, snapMax = 0, flungMax = 0, thrown = {} }
        end
    end
    SP.shifts = shifts

    if SP.rec then
        local rec = SP.rec
        if counter and not rec.counterAt then rec.counterAt = t end
        local ft = t - rec.t0
        local fdt = t - (SP.prev and SP.prev.t or t)
        local f = { t = ft, counts = {}, me = "-", off = 0 }
        for _, k in ipairs(SHIFT_KINDS) do f.counts[k] = { old = 0, between = 0, new = 0 } end
        for i, cur in pairs(now) do
            local base = rec.base[i]
            if base then
                local cls = ShiftProbe_Class(base, cur, ft)
                local kind = i == "me" and "me" or SP.sample[i].kind
                if i == "me" then f.me = cls else f.counts[kind][cls] = f.counts[kind][cls] + 1 end
                -- arrived in an earlier frame: a jump beyond its own velocity (snap) or a sudden speed (flung)
                local prev = SP.prev and SP.prev.pos[i]
                if rec.arrived[i] and prev and kind ~= "static" then
                    local snap = math.abs((cur.x - prev.x) - prev.vx * fdt)
                    local gain = cur.v - base.v
                    if snap > SHIFT_SNAP or gain > SHIFT_FLUNG then
                        if i ~= "me" then f.off = f.off + 1 end
                        rec.thrown[i] = true
                        rec.snapMax = math.max(rec.snapMax, snap)
                        rec.flungMax = math.max(rec.flungMax, gain)
                    end
                end
                if cls == "new" then rec.arrived[i] = true end
            end
        end
        rec.frames[#rec.frames + 1] = f
        if #rec.frames >= SHIFT_PROBE_FRAMES then
            SP.report = ShiftProbe_Report(rec)
            SP.rec = nil
            SP.nextSample = 0
        end
    end
    SP.prev = { pos = now, t = t }
end

function ShiftProbe_CountStr(c)
    return string.format("%d/%d/%d", c.old, c.between, c.new)
end

--- Report lines: a header, then one line per frame in which the counts changed (at most 16).
function ShiftProbe_Report(rec)
    local lines = {}
    local watched, thrown, firstNew, lastOld = 0, 0, nil, nil
    for i in pairs(rec.base) do if i ~= "me" then watched = watched + 1 end end
    for i in pairs(rec.thrown) do if i ~= "me" then thrown = thrown + 1 end end
    for _, f in ipairs(rec.frames) do
        local olds, news = 0, 0
        for _, k in ipairs(SHIFT_KINDS) do olds = olds + f.counts[k].old news = news + f.counts[k].new end
        if news > 0 and not firstNew then firstNew = f.t end
        if olds > 0 then lastOld = f.t end
    end
    local function ms(t) return t and string.format("%+d ms", math.floor(t * 1000 + 0.5)) or "never" end
    lines[1] = string.format("Shift probe (%s): %d bodies watched; counter %s, first body moved %s, last old %s",
        IsPlayerHost(GetLocalPlayer()) and "host" or "client", watched, rec.counterAt and ms(rec.counterAt - rec.t0) or "unseen",
        ms(firstNew), lastOld and ms(lastOld) or "none")
    lines[2] = string.format("off after arriving (snap > %d m in a frame or > %d m/s faster): %d bodies%s, worst snap %.1f m, speed +%.0f m/s",
        SHIFT_SNAP, SHIFT_FLUNG, thrown, rec.thrown.me and " and me" or "", rec.snapMax, math.max(0, rec.flungMax))
    lines[3] = "time    old/between/new:  static   dynamic   npc   vehicle   me   off"
    local last
    for _, f in ipairs(rec.frames) do
        local key = string.format("%s   %s   %s   %s   %s   %d", ShiftProbe_CountStr(f.counts.static),
            ShiftProbe_CountStr(f.counts.dynamic), ShiftProbe_CountStr(f.counts.npc), ShiftProbe_CountStr(f.counts.vehicle), f.me, f.off)
        if key ~= last and #lines < 19 then lines[#lines + 1] = string.format("%7s  %s", ms(f.t), key) end
        last = key
    end
    return lines
end

function ShiftProbe_Draw()
    if not GetBool("level.debug.shiftprobe") then return end
    UiPush()
        UiFont("bold.ttf", 18)
        UiAlign("left top")
        UiTranslate(20, 560)
        UiTextShadow(0, 0, 0, 0.8, 1.5)
        UiColor(0.6, 1, 1, 1)
        if SP.rec then
            UiText("Shift probe: recording...")
        elseif SP.report then
            for _, l in ipairs(SP.report) do UiText(l) UiTranslate(0, 20) end
        else
            UiText(string.format("Shift probe: watching %d bodies, waiting for a world shift", #SP.sample))
        end
    UiPop()
end

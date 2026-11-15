-- (2026-11-15, performance research, DEBUG ONLY) Call-count profiler for one script.
-- Scripts cannot time anything (frame time capped at 1/30 s), but every call from Lua into the engine has a fixed
-- cost, and the call volume roughly is the script time here (goreai_main: ~16k engine calls per frame, ~5.8 ms in
-- Teardown's built-in profiler, SHIFT+ALT+F3). While on, every engine API function (lib/EngineApiNames.lua) and
-- every global Lua function of the script matching `selectFn` is replaced by a counting wrapper. Each engine call
-- is also ATTRIBUTED to the innermost wrapped Lua function on the call stack, so the report shows which of the
-- script's own functions generate the work. Off = the originals are back.
--   CallProfile_Tick(on)  once per frame (tick); returns the report table every 2 s while on, else nil
--   CallProfile_DrawReport(report, x, y, title)
-- Not counted: functions saved in locals before switching on, and other scripts.

CallProfile = { on = false, orig = {}, counts = {}, attrib = {}, stack = {}, frames = 0, next = 0, api = {} }

local function wrapApi(name, f)
    CallProfile.orig[name] = f
    _G[name] = function(...)
        local P = CallProfile
        P.counts[name] = (P.counts[name] or 0) + 1
        local top = P.stack[#P.stack] or "(callback itself)"
        P.attrib[top] = (P.attrib[top] or 0) + 1
        return f(...)
    end
end

local function pop(...)
    local s = CallProfile.stack
    s[#s] = nil
    return ...
end

local function wrapLua(name, f)
    CallProfile.orig[name] = f
    _G[name] = function(...)
        local P = CallProfile
        P.counts[name] = (P.counts[name] or 0) + 1
        local s = P.stack
        s[#s + 1] = name
        return pop(f(...))
    end
end

local STDLIB = {}
for _, n in ipairs({ "assert", "collectgarbage", "dofile", "error", "getmetatable", "ipairs", "load", "loadstring",
    "next", "pairs", "pcall", "print", "rawequal", "rawget", "rawset", "select", "setmetatable", "tonumber",
    "tostring", "type", "unpack", "xpcall", "require", "module", "getfenv", "setfenv", "gcinfo", "newproxy" }) do
    STDLIB[n] = true
end

function CallProfile_Set(on, selectFn)
    if on == CallProfile.on then return end
    CallProfile.on = on
    if on then
        CallProfile.api = {}
        for _, n in ipairs(ENGINE_API_NAMES or {}) do CallProfile.api[n] = true end
        local apis, luas = {}, {}
        for k, v in pairs(_G) do
            if type(k) == "string" and type(v) == "function" and not k:match("^CallProfile") and not STDLIB[k] then
                if CallProfile.api[k] then apis[#apis + 1] = k
                elseif selectFn(k) then luas[#luas + 1] = k end
            end
        end
        for _, k in ipairs(apis) do wrapApi(k, _G[k]) end
        for _, k in ipairs(luas) do wrapLua(k, _G[k]) end
        CallProfile.counts, CallProfile.attrib, CallProfile.stack, CallProfile.frames, CallProfile.next = {}, {}, {}, 0, 0
    else
        for k, f in pairs(CallProfile.orig) do _G[k] = f end
        CallProfile.orig = {}
    end
end

local function top(tbl, n, frames, perUnit, filter)
    local rows = {}
    for k, c in pairs(tbl) do if not filter or filter(k) then rows[#rows + 1] = { k, c } end end
    table.sort(rows, function(a, b) return a[2] > b[2] end)
    local out = {}
    for i = 1, math.min(n, #rows) do
        local per = rows[i][2] / frames
        out[i] = perUnit and string.format("%s  %.0f/frame  %.1f/npc", rows[i][1], per, per / perUnit)
            or string.format("%s  %.0f/frame", rows[i][1], per)
    end
    return out
end

--- once per frame; `unit` = number to divide by (e.g. living NPCs) or nil. Returns a report every 2 s.
function CallProfile_Tick(on, selectFn, unit)
    CallProfile_Set(on, selectFn)
    if not on then return nil end
    CallProfile.frames = CallProfile.frames + 1
    local now = GetTime()
    if now < CallProfile.next then return nil end
    CallProfile.next = now + 2
    local frames = math.max(1, CallProfile.frames)
    local apiTotal = 0
    for k, c in pairs(CallProfile.counts) do if CallProfile.api[k] then apiTotal = apiTotal + c end end
    local report = {
        frames = frames, apiPerFrame = apiTotal / frames, unit = unit,
        byFunction = top(CallProfile.attrib, 14, frames, unit),
        api = top(CallProfile.counts, 8, frames, unit, function(k) return CallProfile.api[k] end),
        calls = top(CallProfile.counts, 6, frames, unit, function(k) return not CallProfile.api[k] end),
    }
    CallProfile.counts, CallProfile.attrib, CallProfile.frames = {}, {}, 0
    return report
end

function CallProfile_DrawReport(p, x, y, title)
    if not p then return end
    UiPush()
        UiFont("regular.ttf", 16)
        UiAlign("left top")
        UiTranslate(x, y)
        UiTextShadow(0, 0, 0, 0.9, 1.5)
        UiColor(0.75, 1, 0.75, 1)
        UiText(string.format("%s: %.0f engine calls/frame (avg of %d frames)%s", title, p.apiPerFrame, p.frames,
            p.unit and string.format(", %d NPCs alive", p.unit) or ""))
        local function block(name, lines, color)
            UiTranslate(0, 22)
            UiColor(1, 1, 1, 1)
            UiText(name)
            UiColor(color[1], color[2], color[3], 1)
            for _, l in ipairs(lines or {}) do UiTranslate(0, 18) UiText(l) end
        end
        block("engine calls made by (innermost function):", p.byFunction, { 1, 0.85, 0.5 })
        block("top engine functions:", p.api, { 0.75, 1, 0.75 })
        block("most called script functions:", p.calls, { 0.7, 0.85, 1 })
    UiPop()
end

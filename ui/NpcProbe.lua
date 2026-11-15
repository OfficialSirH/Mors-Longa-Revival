-- (2026-11-15, MP) Debug menu "NPC sync readout (all players)" and "server sound test" (host), for the report "an
-- ambush happened; the non-host saw the NPCs piled on the ground as if dead and didn't hear their guns" (host: they
-- stood and shot). Causes not known; this shows what each machine has.
-- * NPC readout: the server publishes, 5 times a second, the 6 NPC torsos nearest the host (handle, position, alive)
--   in level.debug.npcprobe (synced registry). Every machine then lists, per torso: the server's height and the
--   local body's height, how far apart the two are, the local speed, and whether the handle is a Torso there at all.
--   Lying on the client but standing on the server = the client's copy of the ragdoll is not kept upright.
-- * Sound test: the server loads a sound in server.init and plays it at every player's position (as the engine's
--   own robot.lua plays all its sounds from server code). The NPC guns play their shots the same way
--   (goreai_combat.lua), so if the non-host doesn't hear the test either, server sounds don't reach clients.

NPC_PROBE_COUNT = 6
NPC_PROBE_RATE = 0.2

NP = { nextPublish = 0, lines = {} }

function NpcProbe_ServerInit()
    NpcProbeSound = LoadSound("tools/gun0.ogg", 8.0)   -- the engine robot's shot sound (data/script/robot.lua)
end

function server.npcProbeSoundTest()
    for p in Players() do
        PlaySound(NpcProbeSound, GetPlayerTransform(p).pos, 1.0)
    end
end

function NpcProbe_ServerTick()
    local on = GetBool("savegame.mod.debug.npcprobe")
    if on ~= NpcProbeSent then
        NpcProbeSent = on
        SetBool("level.debug.npcprobe_on", on, true)
    end
    if not on or GetTime() < NP.nextPublish then return end
    NP.nextPublish = GetTime() + NPC_PROBE_RATE
    local host = Vec()
    for p in Players() do if IsPlayerHost(p) then host = GetPlayerTransform(p).pos end end
    local list = {}
    local torsos = FindBodies("Torso", true)
    for i = 1, #torsos do
        local h = torsos[i]
        local pos = GetBodyTransform(h).pos
        list[#list + 1] = { h = h, pos = pos, d = VecLength(VecSub(pos, host)) }
    end
    table.sort(list, function(a, b) return a.d < b.d end)
    local parts = {}
    for i = 1, math.min(#list, NPC_PROBE_COUNT) do
        local e = list[i]
        parts[#parts + 1] = string.format("%d,%.2f,%.2f,%.2f", e.h, e.pos[1], e.pos[2], e.pos[3])
    end
    SetString("level.debug.npcprobe", string.format("%.2f|%d|", GetTime(), #torsos) .. table.concat(parts, ";"), true)
end

function NpcProbe_ClientTick()
    if not GetBool("level.debug.npcprobe_on") then return end
    local s = GetString("level.debug.npcprobe")
    local t, total, body = s:match("^([%d%.%-]+)|(%d+)|(.*)$")
    local lines = {}
    local here = FindBodies("Torso", true)
    lines[1] = string.format("NPC sync: server sees %s torsos, this machine %d (server time %s)", total or "?", #here, t or "?")
    for entry in (body or ""):gmatch("[^;]+") do
        local h, x, y, z = entry:match("^(%d+),([%d%.%-]+),([%d%.%-]+),([%d%.%-]+)$")
        h = tonumber(h)
        if h then
            local spos = Vec(tonumber(x), tonumber(y), tonumber(z))
            if IsHandleValid(h) then
                local lpos = GetBodyTransform(h).pos
                local off = VecLength(VecSub(lpos, spos))
                local speed = VecLength(GetBodyVelocity(h))
                lines[#lines + 1] = string.format("  #%d %s  server y %.2f  here y %.2f  apart %.2f m  speed %.1f  %s",
                    h, HasTag(h, "Torso") and "torso" or "NOT A TORSO HERE", spos[2], lpos[2], off, speed,
                    IsBodyActive(h) and "active" or "asleep")
            else
                lines[#lines + 1] = string.format("  #%d  server y %.2f  NO SUCH BODY HERE", h, spos[2])
            end
        end
    end
    NP.lines = lines
end

function NpcProbe_Draw()
    if not GetBool("level.debug.npcprobe_on") then return end
    UiPush()
        UiFont("bold.ttf", 18)
        UiAlign("left top")
        UiTranslate(20, 300)
        UiTextShadow(0, 0, 0, 0.8, 1.5)
        UiColor(1, 0.85, 0.5, 1)
        for _, l in ipairs(NP.lines) do UiText(l) UiTranslate(0, 20) end
    UiPop()
end

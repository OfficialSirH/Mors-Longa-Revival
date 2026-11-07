--================================================================
-- goreai_players.lua  (Mors Longa Revival, v2 co-op)
--
-- GoreNPCs was written for one player: the AI asks GetPlayerTransform(), GetPlayerVehicle(), ...
-- and aims at the global PlayerPos. In v2 the AI runs on the server, where those calls without a
-- playerId mean the host. Instead of rewriting the AI, every NPC gets a TARGET PLAYER (the nearest
-- player it can see, re-checked about once a second) and before an NPC is processed the "context
-- player" is switched to it:
--   GoreP     = that player's id (pass it to every GetPlayer*() call in the AI code)
--   PlayerPos = that player's aim point (v1: player pos + 1 m)
-- Code that is about all players (bullet hits, fly-by sounds, throwing grenades back) loops over
-- GorePlayerIds instead.
--
-- Server only, except GoreAI_IsMe (client handlers). Call GoreAI_UpdatePlayers() at the start of
-- every server.tick.
--================================================================

GorePlayers   = {} -- [playerId] = { id, pos, aimPos, vehicle, alive }
GorePlayerIds = {} -- player ids in Players() order
GoreHost      = 0  -- the host's player id
GoreP         = 0  -- context player (target player of the NPC being processed)

local GoreHitboxSets = {} -- [playerId] = { HEAD = trigger, TORSO = ..., ... }
local GoreHitboxScanTime = -1

function GoreAI_UpdatePlayers()

    GorePlayers, GorePlayerIds = {}, {}
    local host = nil

    for p in Players() do
        local pos = GetPlayerTransform(p).pos
        GorePlayers[p] = {
            id      = p,
            pos     = pos,
            aimPos  = VecAdd(pos, Vec(0, 1, 0)), -- v1 PlayerPos: "adjusted player pos for npcs to aim at"
            vehicle = GetPlayerVehicle(p),
            alive   = GetPlayerHealth(p) > 0,
        }
        GorePlayerIds[#GorePlayerIds + 1] = p
        if host == nil and IsPlayerHost(p) then host = p end
    end

    GoreHost = host or GorePlayerIds[1] or 0
    GoreAI_SetPlayer(GoreHost)

    -- Hitbox triggers: the host has the level's own set, every other player a set spawned by
    -- scripts/PlayerHitboxes.lua (tag hitbox_player=<id>). Re-scanned twice a second for joins/leaves.
    if GetTime() >= GoreHitboxScanTime then
        GoreHitboxScanTime = GetTime() + 0.5
        GoreAI_ScanHitboxes()
    end

end

function GoreAI_ScanHitboxes()
    GoreHitboxSets = {}
    for _, t in ipairs(FindTriggers("hitbox", true)) do
        local owner = GoreHost
        if HasTag(t, "hitbox_player") then owner = tonumber(GetTagValue(t, "hitbox_player")) or GoreHost end
        GoreHitboxSets[owner] = GoreHitboxSets[owner] or {}
        GoreHitboxSets[owner][GetTagValue(t, "hitbox")] = t
    end
    PlayerHitboxes = GoreHitboxSets[GoreHost] or {} -- v1 name (host's set), kept for old callers
end

--- Hitbox triggers of a player, keyed by limb name (HEAD, TORSO, LARM, RARM, LLEG, RLEG).
function GoreAI_Hitboxes(p)
    return GoreHitboxSets[p or GoreP] or {}
end

--- Switch the context player (GoreP + PlayerPos).
function GoreAI_SetPlayer(p)
    if GorePlayers[p] == nil then p = GoreHost end
    GoreP = p
    if GorePlayers[p] then PlayerPos = VecCopy(GorePlayers[p].aimPos) end
end

local function GoreAI_CanSeePlayer(npc, from, pl, dist)
    if dist > 400 then return false end
    if npc.AllBodies then RejectAllBodies(npc.AllBodies) end
    if pl.vehicle ~= 0 then QueryRejectVehicle(pl.vehicle) end
    local hit = QueryRaycast(from, VecNormalize(VecSub(pl.aimPos, from)), dist, 0, true)
    return not hit
end

--- Nearest living player the npc can see; nearest living player if it sees none; else the host.
function GoreAI_PickTargetPlayer(npc)
    local body = npc.Head or npc.Torso
    local from = (body and body ~= 0) and AabbGetBodyCenterPos(body) or (npc.torsoPos or Vec())
    local best, bestDist, bestVisible = nil, math.huge, false
    for _, p in ipairs(GorePlayerIds) do
        local pl = GorePlayers[p]
        if pl.alive then
            local d = VecDist(from, pl.aimPos)
            local visible = GoreAI_CanSeePlayer(npc, from, pl, d)
            if (visible and not bestVisible) or (visible == bestVisible and d < bestDist) then
                best, bestDist, bestVisible = p, d, visible
            end
        end
    end
    return best or GoreHost
end

--- Make npc's target player the context player (GoreP / PlayerPos). Call before processing an npc.
function GoreAI_SetContext(npc)
    local p = npc.goreTargetPlayer
    local now = GetTime()
    if p == nil or GorePlayers[p] == nil or not GorePlayers[p].alive or now >= (npc.goreTargetCheck or 0) then
        p = GoreAI_PickTargetPlayer(npc)
        npc.goreTargetPlayer = p
        npc.goreTargetCheck = now + 1 + math.random() * 0.5
    end
    GoreAI_SetPlayer(p)
end

--- Total limb health of a player (AdvancedHealthScript reports it, see server.healthReport there).
--- v1 read the single player's "level.player.health". Unknown (not reported yet) = full health.
function GoreAI_PlayerHealth(p)
    local key = "level.goreai.player_health." .. tostring(p or GoreP)
    if not HasKey(key) then return math.huge end
    return GetFloat(key)
end

--- A player id from a registry value / shooter id → a valid player id (unknown or 0 = the host).
--- Never pass 0 to ClientCall: 0 means every player.
function GoreAI_ResolvePlayer(p)
    p = tonumber(p) or 0
    if p ~= 0 and GorePlayers[p] then return p end
    return GoreHost
end

--- ClientCall to ONE player. The handler gets the target id as its first argument and must check
--- it with GoreAI_IsMe (guards against a host id of 0 turning into a broadcast).
function GoreAI_ClientCall(p, fn, ...)
    p = GoreAI_ResolvePlayer(p)
    ClientCall(p, fn, p, ...)
end

--- Client side: is a GoreAI_ClientCall meant for this machine?
function GoreAI_IsMe(target)
    local me = GetLocalPlayer()
    return target == me or (target == 0 and IsPlayerHost(me))
end

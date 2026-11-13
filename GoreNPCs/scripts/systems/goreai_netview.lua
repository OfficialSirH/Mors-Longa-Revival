--================================================================
-- goreai_netview.lua  (Mors Longa Revival, v2 co-op, 2026-11-07)
--================================================================
-- The AI and the NPC table (NPCs) live on the server. Clients can read the npc bodies from the world, but not the AI
-- state, and on the host the server and client halves do not share Lua globals either. So the server publishes a
-- small record per npc in shared.goreNpcs[tostring(id)], and each client rebuilds NPCs from it as "proxy" tables
-- with the fields the v1 draw code reads (healthbars, boss icon, debug overlays, controller info). The v1 draw code
-- (debug/goreai_debug.lua, goreai_ui.lua, draw_combat_details) then runs unchanged on the client.
--   Published: bosses (their health bars show for everyone within 20 m), controlled npcs, and every npc while the
--   host's debug mode (config.db) is on; the debug fields (nav path, thinking state, aim points) only in debug mode.
--   A record is replaced whole, at most every GORE_VIEW_INTERVAL s and only when it changed.
-- Not ported: projectile impact debug dots (npcs_debug_projectiles: the hit list is server data).

GORE_VIEW_INTERVAL = 0.1

------------------------------------------------------------------ server

GoreView = { sig = {}, timer = 0 }

local function r1(x)
    if type(x) ~= "number" then return x end
    return math.floor(x * 10 + 0.5) / 10
end

local function rvec(v)
    if type(v) ~= "table" or v[1] == nil then return nil end
    return { r1(v[1]), r1(v[2]), r1(v[3]) }
end

-- stable text form of a record, to send only changes
local function signature(v)
    if type(v) ~= "table" then return tostring(v) end
    local keys = {}
    for k in pairs(v) do keys[#keys + 1] = tostring(k) end
    table.sort(keys)
    local parts = {}
    for _, k in ipairs(keys) do
        local val = v[k]
        if val == nil then val = v[tonumber(k)] end
        parts[#parts + 1] = k .. "=" .. signature(val)
    end
    return "{" .. table.concat(parts, ",") .. "}"
end

function GoreAI_ViewRecord(npc, full)
    local boss = npc.boss and npc.boss.isBoss and true or false
    local rec = {
        id = tostring(npc.id),
        torso = npc.Torso,
        head = npc.Head,
        bodies = npc.AllBodies or {},
        bones = npc.bones or {},
        dead = npc.dead and true or false,
        team = npc.ai.teams and npc.ai.teams.team or "none",
        boss = boss,
        bossTitle = boss and npc.boss.boss_preset and npc.boss.boss_preset.title or nil,
        health = r1(npc.health),
        healthMax = r1(npc.health_max),
        shield = r1(npc.shield and npc.shield.value or 0),
        shieldMax = r1(npc.shield and npc.shield.max or 0),
        burst = npc.burstsize,
        shot = npc.BulletsShot,
        mag = npc.MagSize,
        reloading = npc.reloading and true or false,
        gunPrefab = npc.gun_prefab_path,
    }
    if npc.Gun then
        rec.gunBody, rec.gunLight, rec.gunPath = npc.Gun.body, npc.Gun.handle, npc.Gun.gun_path
    end
    if full then
        local ai = npc.ai or {}
        local th = ai.thinking or {}
        local states = th.states or {}
        local att = th.attacking or {}
        local path = {}
        for i, p in ipairs(npc.nav and npc.nav.path or {}) do path[i] = rvec(p) end
        rec.dbg = {
            state = th.state, dist = states.dist, shoot = states.shoot,
            canSee = th.can_see, seenLast = r1(th.seen_last), seenTime = r1(th.seen_time),
            recheck = ai.targeting and ai.targeting.recheck_timer and r1(ai.targeting.recheck_timer.time),
            blocked = att.blocked, canShoot = att.canShootAimPos,
            canShootLast = att.canShootAimPosLast and r1(GetTime() - att.canShootAimPosLast),
            navPos = rvec(ai.navPos), target = rvec(npc.nav and npc.nav.target), aimPos = rvec(ai.aimPos),
            shootPos = rvec(ai.shootPos), shootPosOffset = rvec(ai.shootPosOffset), path = path,
        }
    end
    return rec
end

function GoreAI_PublishNPCs(dt)
    GoreView.timer = GoreView.timer - dt
    if GoreView.timer > 0 then return end
    GoreView.timer = GORE_VIEW_INTERVAL

    shared.goreNpcs = shared.goreNpcs or {}
    local full = DebugMode and true or false
    local keep = {}
    for id, npc in pairs(NPCs) do
        if npc.isValid and IsHandleValid(npc.Torso) then
            local controlled = IsControllerNPC(npc)
            if full or controlled or (npc.boss and npc.boss.isBoss and not npc.dead) then
                local key = tostring(id)
                keep[key] = true
                local rec = GoreAI_ViewRecord(npc, full)
                local sig = signature(rec)
                if GoreView.sig[key] ~= sig then
                    GoreView.sig[key] = sig
                    shared.goreNpcs[key] = rec
                end
            end
        end
    end
    for key in pairs(GoreView.sig) do
        if not keep[key] then
            GoreView.sig[key] = nil
            shared.goreNpcs[key] = nil
        end
    end
end

------------------------------------------------------------------ client

local function vecOr(v, default)
    if type(v) == "table" and v[1] ~= nil then return { v[1], v[2], v[3] } end
    return VecCopy(default)
end

--- Client proxy with the npc fields the v1 draw code reads.
function GoreAI_ClientProxy(key, r)
    local tr = GetBodyTransform(r.torso)
    local d = r.dbg or {}
    local gun = nil
    if r.gunBody and IsHandleValid(r.gunBody) then
        gun = { body = r.gunBody, handle = r.gunLight, gun_path = r.gunPath }
    end
    local gunPos = gun and GetBodyTransform(gun.body).pos or tr.pos
    local path = {}
    for i, p in ipairs(d.path or {}) do path[i] = vecOr(p, tr.pos) end
    return {
        key = key,
        id = r.id,
        isValid = true,
        dead = r.dead,
        hasDebug = r.dbg ~= nil,
        Torso = r.torso,
        Head = r.head,
        AllBodies = r.bodies or {},
        bones = r.bones or {},
        torsoTr = tr,
        torsoPos = tr.pos,
        health = r.health or 0,
        health_max = r.healthMax or 100,
        shield = { value = r.shield or 0, max = r.shieldMax or 0 },
        boss = { isBoss = r.boss, boss_preset = { title = r.bossTitle or "" } },
        Gun = gun,
        gun_prefab_path = r.gunPrefab or "",
        burstsize = r.burst or 0,
        BulletsShot = r.shot or 0,
        MagSize = r.mag,
        reloading = r.reloading,
        nav = { target = vecOr(d.target, tr.pos), path = path },
        ai = {
            teams = { team = r.team or "none" },
            navPos = vecOr(d.navPos, tr.pos),
            aimPos = vecOr(d.aimPos, tr.pos),
            shootPos = vecOr(d.shootPos, gunPos),
            shootPosOffset = vecOr(d.shootPosOffset, gunPos),
            targeting = { recheck_timer = { time = d.recheck or "-" } }, -- no .target: draw_combat_details skips it
            thinking = {
                state = d.state or "-",
                states = { dist = d.dist or "-", shoot = d.shoot or "-" },
                can_see = d.canSee or false, seen_last = d.seenLast or "-", seen_time = d.seenTime or "-",
                attacking = {
                    blocked = d.blocked or false, canShootAimPos = d.canShoot or false, -- (UiText(nil) errors)
                    canShootAimPosLast = d.canShootLast and (GetTime() - d.canShootLast) or nil,
                },
            },
        },
    }
end

--- client.tick: NPCs / ControllerNPC on this client from the server's records.
function GoreAI_RefreshClientNPCs()
    local list = {}
    for key, r in pairs(shared.goreNpcs or {}) do
        if type(r) == "table" and r.torso and IsHandleValid(r.torso) then
            list[key] = GoreAI_ClientProxy(key, r)
        end
    end
    NPCs = list
    local myKey = shared.goreControl and shared.goreControl[tostring(GetLocalPlayer())]
    ControllerNPC = myKey and list[myKey] or nil
end

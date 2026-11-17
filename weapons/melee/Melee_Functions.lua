-- (2026-11-17, DEBUG) collector probe / skip switch, off unless level.debug.* is set (lib/GcProbe.lua)
#include "../../lib/GcProbe.lua"
GCP_LABEL = GCP_LABEL or "melee"
local sc = 1

MeleeWeapons = {
    ["melee-BaseballBat"]  = { damage = 12 * sc, holesize = 0.1, title = "BaseballBat"},
    ["melee-CombatKnife"]  = { damage = 10 * sc, holesize = 0.2, title = "CombatKnife"},
    ["melee-Crowbar"]      = { damage = 15 * sc, holesize = 0.3, title = "Crowbar"},
    ["melee-DamnedScythe"] = { damage = 20 * sc, holesize = 0.3, title = "DamnedScythe"},
    ["melee-FireAxe"]      = { damage = 35 * sc, holesize = 0.5, title = "FireAxe"},
    ["melee-Katana"]       = { damage = 25 * sc, holesize = 0.4, title = "Katana"},
    ["melee-Pipe"]         = { damage = 15 * sc, holesize = 0.1, title = "Pipe"},
    ["melee-Tomahawk"]     = { damage = 10 * sc, holesize = 0.2, title = "Tomahawk"},
}

function Apply_NPC_Damage_Player(hit_shape, hit_pos, tool_id)

    -- NPC DAMAGE START
    local damage_from_player = MeleeWeapons[tool_id].damage
    local hitBody = GetShapeBody(hit_shape) -- raycast hit shape
    if HasTag(hitBody, "gore_id") then

        -- DebugPrint("hit " .. damage_from_player)

        -- Send damage data to npcs script.
        -- (v2) the registry write that hands damage to the NPC script happens on the server.
        MeleeNet_Queue({ t = "npc", body = hitBody, pos = hit_pos, damage = damage_from_player })

        -- Break voxels.
        MeleeNet_MakeHole(hit_pos, MeleeWeapons[tool_id].holesize)

    end
    -- NPC DAMAGE START

end


-----------------------------------------------------------------------------------------
-- (v2) Melee networking (Mors Longa Revival)
--
-- The client that holds the melee weapon runs input, animation, raycasts, sounds and
-- particles as before. World effects are server-only in v2, so they are queued during
-- the frame and sent to the server in one ServerCall from client.postUpdate():
--   hole   = MakeHole(pos, r0, r1, r2)      (merged per position, largest radii kept)
--   impulse= ApplyBodyImpulse(body, pos, v) (summed per body)
--   npc    = GoreNPCs damage hand-off via the registry (level.goreai.body_damage_player.*)
-- Each melee script includes this file, so each script gets its own server.meleeOps.
-----------------------------------------------------------------------------------------

MeleeNet = { ops = {}, holes = {}, impulses = {} }

function MeleeNet_Queue(op)
    MeleeNet.ops[#MeleeNet.ops + 1] = op
end

function MeleeNet_MakeHole(pos, r0, r1, r2)
    r0, r1, r2 = r0 or 0, r1 or 0, r2 or 0
    local key = string.format("%.2f %.2f %.2f", pos[1], pos[2], pos[3])
    local h = MeleeNet.holes[key]
    if h then
        h.r0, h.r1, h.r2 = math.max(h.r0, r0), math.max(h.r1, r1), math.max(h.r2, r2)
    else
        h = { t = "hole", pos = VecCopy(pos), r0 = r0, r1 = r1, r2 = r2 }
        MeleeNet.holes[key] = h
        MeleeNet_Queue(h)
    end
    return 0 -- v1 MakeHole returned the voxel count; no caller uses it on this path
end

function MeleeNet_Impulse(body, pos, impulse)
    local i = MeleeNet.impulses[body]
    if i then
        i.imp = VecAdd(i.imp, impulse)
    else
        i = { t = "impulse", body = body, pos = VecCopy(pos), imp = VecCopy(impulse) }
        MeleeNet.impulses[body] = i
        MeleeNet_Queue(i)
    end
end

function client.postUpdate()
    if #MeleeNet.ops > 0 then
        ServerCall("server.meleeOps", MeleeNet.ops, GetLocalPlayer())
        MeleeNet.ops, MeleeNet.holes, MeleeNet.impulses = {}, {}, {}
    end
end

-----------------------------------------------------------------------------------------
-- (2026-11-15, MP) Other players' melee weapons. The swing animation (SetToolTransform), its sounds and the hit
-- particles ran only on the holding player's machine, so the others heard nothing and saw the weapon in the
-- engine's default third-person place: its origin (the handle's end) at the player's eye height, pointing
-- straight ahead, the hands reaching for nothing (user screenshot, all melee weapons). Now:
-- * Every machine poses each OTHER player's melee weapon itself every tick, as the engine's own tools do
--   (data/script/toolanimation.lua, snowball.lua: SetToolTransformOverride + SetToolHandPoseLocalTransform per
--   player): the handle's grip in the right hand at chest height, tilted up like the first-person view, the left
--   hand further up the handle on two-handed weapons. Grip points from the .vox models (MELEE_GRIPS).
-- * The holding client also queues
--     swing = a swing started (spin = right-click sweep, dur = seconds until it lands, the script's own timing)
--     fx    = the swing landed: swing sound, hit sound if a ray hit, up to 8 hit points for the particles
--   and the server forwards both to every client (client.meleeRemoteOps): the others play the sounds at the
--   swinger's position, spawn the particles, and swing the pose about the right hand.
-- Each melee script calls MeleeNet_RemoteTick(dt) at the start of its client.tick.
-----------------------------------------------------------------------------------------

MeleeNet.remote = {}     -- [player] = { dur, left, spin } while a swing is shown
MELEE_REMOTE_PARTICLES = 8

function MeleeNet_SwingStart(spin, duration)
    MeleeNet_Queue({ t = "swing", spin = spin and true or false, dur = duration })
end

function MeleeNet_SwingFx(hitcount, holes, r, g, b)
    local list = {}
    holes = holes or {}
    for i = 1, math.min(#holes, MELEE_REMOTE_PARTICLES) do list[i] = VecCopy(holes[i]) end
    -- r, g, b: the scripts' last GetShapeMaterialAtPosition colour; their `b` is the tool body handle until a
    -- material was read (the script's own `local b`), so anything outside 0..1 becomes grey
    local function c(v) return (type(v) == "number" and v >= 0 and v <= 1) and v or 0.5 end
    MeleeNet_Queue({ t = "fx", hit = (hitcount or 0) > 0, holes = list, r = c(r), g = c(g), b = c(b) })
end

function client.meleeRemoteOps(playerId, ops)
    if IsPlayerLocal(playerId) then return end
    for i = 1, #ops do
        local op = ops[i]
        if op.t == "swing" then
            local dur = math.max(op.dur or 0.4, 0.05)
            MeleeNet.remote[playerId] = { dur = dur, left = dur, spin = op.spin }
        elseif op.t == "fx" then
            MeleeNet_RemoteFx(playerId, op)
        end
    end
end

function MeleeNet_RemoteFx(playerId, op)
    local pos = GetPlayerTransform(playerId).pos
    if swingsound then PlaySound(swingsound, pos, 0.6) end
    if op.hit and hitsound then PlaySound(hitsound, pos, 0.6) end
    for i = 1, #(op.holes or {}) do
        for q = 1, 10 do -- the same particles as the swinging player's (the melee scripts' hit loop)
            ParticleReset()
            ParticleType("plain")
            ParticleTile(6)
            ParticleColor(op.r, op.g, op.b)
            ParticleRadius(0.05, 0.01)
            ParticleAlpha(100)
            ParticleCollide(1)
            ParticleGravity(-5)
            ParticleSticky(0.1)
            ParticleDrag(0)
            ParticleStretch(0)
            SpawnParticle(op.holes[i], Vec(math.random(-2, 2), math.random(-2, 2), math.random(-2, 2)), 19)
            ParticleReset()
        end
    end
end

-- Grip points in the tool's own space, from the .vox models (0.05 m voxels; MagicaVoxel x, z, y ->
-- tool x, y, -z: the handle's end at the origin, the head toward -z). r = right hand, l = left hand (two-handed:
-- left at the end, right further up, as on the engine's sledgehammer, data/prefab/tool/sledge.xml).
-- (2026-11-15, second MP screenshot: the hands sat one handle-width to the right of the handle) sideways the model
-- is centred: every handle runs along the model's middle column, so the grips are at x 0 (x is kept for the record).
local function voxPoint(x, z, y) return Vec(0, (z + 0.5) * 0.05, -(y + 0.5) * 0.05) end
MELEE_GRIPS = {
    ["melee-BaseballBat"]  = { r = voxPoint(2, 3.5, 9), l = voxPoint(2, 3.5, 3) },   -- knob 0, grip 1-5, barrel 16-30
    ["melee-CombatKnife"]  = { r = voxPoint(1, 3.5, 2) },                           -- handle 0-3, guard 4
    ["melee-Crowbar"]      = { r = voxPoint(1, 5, 4) },                             -- bar 1-17
    ["melee-DamnedScythe"] = { r = voxPoint(1, 14.5, 20), l = voxPoint(1, 15.5, 8) }, -- snath 5-40, blade 41-47
    ["melee-FireAxe"]      = { r = voxPoint(1, 4.5, 10), l = voxPoint(1, 4.5, 2) },  -- handle 0-24, head 25-28
    ["melee-Katana"]       = { r = voxPoint(1, 3.5, 9), l = voxPoint(1, 3.5, 3) },   -- grip 0-12, guard 13
    ["melee-Pipe"]         = { r = voxPoint(2, 5, 3) },                             -- pipe 0-16
    ["melee-Tomahawk"]     = { r = voxPoint(1, 4.5, 3) },                           -- handle 0-13, head 14-18
}
-- Where the right hand holds it, in the player's frame at eye height (x right, y up, -z forward), as the engine's
-- third-person tool frame (toolanimation.lua getToWorldTransform), and the resting tilt (= the first-person 60).
MELEE_HAND = Vec(0.25, -0.55, -0.3)
MELEE_REST_PITCH = 60
-- Two-handed weapons rest across the chest (head up to the right, handle end down to the left), so the left hand
-- stays on the left (held upright at the right side, the left arm went through the body: user 2026-11-15).
MELEE_HAND_2H = Vec(0.2, -0.45, -0.4)
MELEE_REST_ROLL_2H = -35

-- The weapon's rotation at k = 0 (swing starts) .. 1 (lands), or at rest (k = nil): a chop from raised over the
-- shoulder down past level, or a sweep from right to left with the weapon near level.
function MeleeNet_PoseRot(spin, k, twoHanded)
    if not k then
        if twoHanded then return QuatRotateQuat(QuatEuler(0, 0, MELEE_REST_ROLL_2H), QuatEuler(MELEE_REST_PITCH, -5, 0)) end
        return QuatEuler(MELEE_REST_PITCH, -5, 0)
    end
    -- sweep: the head's lower side (blade / striking side, tool -y) rolled to the left so it leads (user 2026-11-15:
    -- the first version swung the flat side first)
    if spin then return QuatRotateQuat(QuatRotateQuat(QuatEuler(0, -70 + 140 * k, 0), QuatEuler(15, 0, 0)), QuatEuler(0, 0, -90)) end
    return QuatEuler(110 - 130 * k, -5, 0)
end

-- Tool transform that puts the grip point `grip` at the hand `hand` with rotation `rot`.
function MeleeNet_GripTransform(rot, grip, hand)
    local g = TransformToParentVec(Transform(Vec(), rot), grip)
    return Transform(VecSub(hand, g), rot)
end

-- How far the player's animated right shoulder is from where it sits standing, in the pose frame (x right, y up,
-- -z forward). The override frame stays at standing eye height, so without this the weapon floated when the player
-- crouched (user screenshot 2026-11-15). Same as the engine tools' "Add shoulder movement" (data/script/
-- toolanimation.lua getBoneAnimationOffset); it also carries the walk bob.
function MeleeNet_ShoulderOffset(p)
    local a = GetPlayerAnimator(p)
    if not a or a == 0 then return Vec() end
    local bind = TransformToParentTransform(GetAnimatorTransform(a), GetBoneBindPoseTransform(a, "shoulder_r"))
    local now = GetBoneWorldTransform(a, "shoulder_r").pos
    return TransformToLocalVec(Transform(Vec(), GetPlayerTransform(p).rot), VecSub(now, bind.pos))
end

function MeleeNet_RemoteTick(dt)
    local grips = MELEE_GRIPS[Tool_Id] or { r = Vec() }
    for p in Players() do
        if not IsPlayerLocal(p) and GetPlayerTool(p) == Tool_Id then
            local e, k = MeleeNet.remote[p], nil
            local hand = VecAdd(grips.l and MELEE_HAND_2H or MELEE_HAND, MeleeNet_ShoulderOffset(p))
            if e then
                e.left = e.left - dt
                if e.left <= 0 then
                    MeleeNet.remote[p] = nil
                else
                    k = 1 - e.left / e.dur
                    hand[3] = hand[3] - 0.2 * k   -- the arm follows the blow forward
                end
            end
            local rot = MeleeNet_PoseRot(e and e.spin, k, grips.l ~= nil)
            SetToolTransformOverride(MeleeNet_GripTransform(rot, grips.r, hand), p)
            -- hand frames turned as on the engine's sledgehammer (a handle along z); identity left the fists beside the
            -- handle (user screenshot 2026-11-15)
            SetToolHandPoseLocalTransform(Transform(VecCopy(grips.r), QuatEuler(0, 90, -90)),
                grips.l and Transform(VecCopy(grips.l), QuatEuler(-90, 0, -60)) or nil, p)
        else
            MeleeNet.remote[p] = nil   -- switched tool, or it's us
        end
    end
    for p in PlayersRemoved() do MeleeNet.remote[p] = nil end
end

function server.meleeOps(ops, playerId)
    local forward = {}
    for i = 1, #ops do
        local op = ops[i]
        if op.t == "swing" or op.t == "fx" then
            forward[#forward + 1] = op
        elseif op.t == "hole" then
            MakeHole(op.pos, op.r0, op.r1, op.r2)
        elseif op.t == "impulse" then
            if op.body ~= 0 and IsHandleValid(op.body) then ApplyBodyImpulse(op.body, op.pos, op.imp) end
        elseif op.t == "npc" then
            local path_damage = "level.goreai.body_damage_player." .. op.body
            SetFloat(path_damage, GetFloat(path_damage) + op.damage) -- Specific damage to each body by handle.
            SetBool("level.goreai.damage_pending", true) -- (2026-11-15) npcs read body damage only when a hit is pending (goreai_health.lua)
            SetFloat("level.goreai.body_damage_player_x", op.pos[1])
            SetFloat("level.goreai.body_damage_player_y", op.pos[2])
            SetFloat("level.goreai.body_damage_player_z", op.pos[3])
            SetInt("level.goreai.body_damage_player_owner", playerId or 0) -- (v2 goreai) who hit, for hitmarkers/kills
        end
    end
    if #forward > 0 then ClientCall(0, "client.meleeRemoteOps", playerId, forward) end
end

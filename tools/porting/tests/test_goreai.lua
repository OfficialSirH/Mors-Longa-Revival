-- Mock-engine test for the GoreNPCs co-op layer (Phase 3): run from the repo root with Lua 5.1:
--   lua5.1 tools/porting/tests/test_goreai.lua
-- Covers goreai_players.lua (target player, hitboxes per player, routing), the killcam split,
-- hitmarker_receive, the synced NPC torso lists, and an NPC bullet hitting the 2nd player's hitbox.

------------------------------------------------------------------ engine mock
function Vec(x,y,z) return {x or 0,y or 0,z or 0} end
function VecCopy(v) return {v[1],v[2],v[3]} end
function VecAdd(a,b) return {a[1]+b[1],a[2]+b[2],a[3]+b[3]} end
function VecSub(a,b) return {a[1]-b[1],a[2]-b[2],a[3]-b[3]} end
function VecScale(a,s) return {a[1]*s,a[2]*s,a[3]*s} end
function VecLength(a) return math.sqrt(a[1]^2+a[2]^2+a[3]^2) end
function VecNormalize(a) local l=VecLength(a) return l>0 and VecScale(a,1/l) or a end
function VecDot(a,b) return a[1]*b[1]+a[2]*b[2]+a[3]*b[3] end
function VecDist(a,b) return VecLength(VecSub(a,b)) end
function Quat() return {0,0,0,1} end
function QuatLookAt() return Quat() end
function Transform(p,r) return {pos=p or Vec(), rot=r or Quat()} end
function TransformToParentPoint(t, p) return VecAdd(t.pos, p) end

local T = 0
function GetTime() return T end
function GetTimeStep() return 1/60 end

-- players: 1 = host at origin, 2 at x=20, 3 at x=-10 (dead)
PLAYERS = {
	[1] = { pos = Vec(0,0,0),   health = 1, vehicle = 0 },
	[2] = { pos = Vec(20,0,0),  health = 1, vehicle = 0 },
	[3] = { pos = Vec(-10,0,0), health = 0, vehicle = 0 },
}
ORDER = {1, 2, 3}
function Players() local i = 0 return function() i = i + 1 return ORDER[i] end end
function GetPlayerTransform(p) return Transform(PLAYERS[p].pos) end
function GetPlayerCameraTransform(p) return Transform(VecAdd(PLAYERS[p].pos, Vec(0,1.7,0))) end
function GetPlayerVehicle(p) return PLAYERS[p].vehicle end
function GetPlayerHealth(p) return PLAYERS[p].health end
function GetPlayerVelocity(p) return Vec() end
function IsPlayerHost(p) return p == 1 end
LOCAL = 1
function GetLocalPlayer() return LOCAL end

-- triggers: host's level set (no tag), player 2's spawned set
TRIGGERS = {}
local TAGS = {}
local function trigger(part, owner, center)
	local h = #TRIGGERS + 100
	TRIGGERS[#TRIGGERS + 1] = h
	TAGS[h] = { hitbox = part, QueriedDamage = "0", hitbox_player = owner and tostring(owner) or nil, _c = center }
	return h
end
local hostHead = trigger("HEAD", nil, Vec(0,1.4,0))
local p2Head = trigger("HEAD", 2, Vec(20,1.4,0))
local p2Torso = trigger("TORSO", 2, Vec(20,0.8,0))
function FindTriggers(tag) return TRIGGERS end
function HasTag(h, t) return TAGS[h] ~= nil and TAGS[h][t] ~= nil end
function GetTagValue(h, t) return TAGS[h] and TAGS[h][t] or "" end
function SetTag(h, t, v) TAGS[h] = TAGS[h] or {} TAGS[h][t] = tostring(v) end
function GetTriggerBounds(h) local c = TAGS[h]._c return VecSub(c, Vec(.3,.3,.3)), VecAdd(c, Vec(.3,.3,.3)) end

-- raycast: a wall blocks anything crossing x = 5..6 (so player 2 is not visible from x < 5)
BLOCK = true
function QueryRaycast(o, d, dist)
	if not BLOCK then return false end
	local e = VecAdd(o, VecScale(d, dist))
	local lo, hi = math.min(o[1], e[1]), math.max(o[1], e[1])
	if lo < 5 and hi > 6 then return true, 5, Vec(-1,0,0), 0 end
	return false
end
function QueryRejectBody() end
function QueryRejectVehicle() end
function AabbGetBodyCenterPos(b) return BODYPOS[b] or Vec() end
BODYPOS = {}

-- registry
local R, SYNCED = {}, {}
function SetInt(k, v, sync) R[k] = v if sync then SYNCED[k] = v end end
function GetInt(k) return R[k] or 0 end
function SetFloat(k, v, sync) R[k] = v end
function GetFloat(k) return R[k] or 0 end
function SetBool(k, v) R[k] = v end
function GetBool(k) return R[k] or false end
function GetString(k) return R[k] and tostring(R[k]) or "" end
function HasKey(k) return R[k] ~= nil end
function ClearKey(k) for key in pairs(R) do if key == k or key:sub(1, #k + 1) == k .. "." then R[key] = nil end end end

-- network: record calls
server, client = {}, {}
SENT = {}
function ClientCall(p, fn, ...) SENT[#SENT + 1] = { to = p, fn = fn, args = {...} } end
function ServerCall(fn, ...) SENT[#SENT + 1] = { to = "server", fn = fn, args = {...} } end

local scale = nil
function SetTimeScale(s) scale = s end
function SetBodyActive() end
function ApplyBodyImpulse() end
function IsHandleValid(h) return h ~= 0 end
function GetBodyTransform(b) return Transform(BODYPOS[b] or Vec()) end
local camSet = nil
function SetCameraTransform(t) camSet = t end
function DrawBodyOutline() end
function InputPressed() return false end
function PlaySound() end
function LoadSound(p) return p end

------------------------------------------------------------------ code under test
local function load(path) assert(loadfile(path))() end
local function loadFns(path, names)
	local src = io.open(path, "rb"):read("*a"):gsub("\r", "")
	src = src:gsub("([^\n]*)", function(l) if l:match("^%s*#") then return "" end return l end)
	assert(loadstring(src, path))()
end
loadFns("lib/TDSU/util_td.lua")    -- timers
loadFns("lib/TDSU/util_table.lua")
loadFns("lib/TDSU/util_lua.lua")
function RejectAllBodies(bodies) for i=1, #bodies do QueryRejectBody(bodies[i]) end end
function DirLookAt(eye, target) return VecNormalize(VecSub(target, eye)) end
loadFns("lib/TDSU/util_vec.lua")   -- LineIntersectsAABB
function AabbGetBodyCenterPos(b) return BODYPOS[b] or Vec() end -- mock again (util_vec defines it)
loadFns("npcs/GoreNPCs/scripts/systems/goreai_players.lua")
loadFns("npcs/GoreNPCs/scripts/systems/goreai_killcam.lua")
loadFns("npcs/GoreNPCs/scripts/systems/goreai_hitmarkers.lua")
loadFns("npcs/GoreNPCs/scripts/systems/goreai_sounds.lua")
loadFns("npcs/GoreNPCs/scripts/components/goreai_ui.lua")
loadFns("npcs/GoreNPCs/scripts/systems/goreai_API.lua")

local function check(cond, msg) if not cond then error("FAIL: " .. msg, 2) end print("ok  " .. msg) end

------------------------------------------------------------------ players + hitboxes
GoreAI_UpdatePlayers()
check(GoreHost == 1 and #GorePlayerIds == 3, "host found, 3 players")
check(GoreAI_Hitboxes(1).HEAD == hostHead, "untagged hitboxes belong to the host")
check(GoreAI_Hitboxes(2).HEAD == p2Head and GoreAI_Hitboxes(2).TORSO == p2Torso, "hitbox_player=2 set mapped to player 2")
check(next(GoreAI_Hitboxes(3)) == nil, "player without hitboxes -> empty table")
check(GorePlayers[3].alive == false, "dead player marked")

------------------------------------------------------------------ target player choice
local npc = { Head = 50, Torso = 51, AllBodies = {} }
BODYPOS[50] = Vec(8, 1, 0) -- behind the wall from the host, 12 m from player 2
check(GoreAI_PickTargetPlayer(npc) == 2, "picks the visible player over the nearer hidden one")
BLOCK = false
check(GoreAI_PickTargetPlayer(npc) == 1, "nothing blocks: picks the nearest (host 8 m vs p2 12 m)")
BODYPOS[50] = Vec(-9, 1, 0)
check(GoreAI_PickTargetPlayer(npc) == 1, "skips dead player 3 even if nearest")

BODYPOS[50] = Vec(15, 1, 0)
GoreAI_SetContext(npc)
check(GoreP == 2 and PlayerPos[1] == 20 and PlayerPos[2] == 1, "context = target player, PlayerPos = pos + 1 m")
BODYPOS[50] = Vec(1, 1, 0)
GoreAI_SetContext(npc)
check(GoreP == 2, "target kept until the re-check time")
T = T + 2
GoreAI_SetContext(npc)
check(GoreP == 1, "re-checked after ~1 s, switches to the nearer player")
PLAYERS[1].health = 0
GoreAI_UpdatePlayers()
GoreAI_SetContext(npc)
check(GoreP == 2, "target died -> switches at once")
PLAYERS[1].health = 1
GoreAI_UpdatePlayers()

------------------------------------------------------------------ routing
check(GoreAI_ResolvePlayer(0) == 1 and GoreAI_ResolvePlayer(7) == 1 and GoreAI_ResolvePlayer(2) == 2, "unknown/0 shooter -> host")
SENT = {}
GoreAI_ClientCall(2, "client.goreHit", "hit", Vec())
check(#SENT == 1 and SENT[1].to == 2 and SENT[1].args[1] == 2 and SENT[1].args[2] == "hit", "ClientCall to one player, target id first")
LOCAL = 2 check(GoreAI_IsMe(2) and not GoreAI_IsMe(1), "IsMe on player 2's machine")
LOCAL = 1 check(GoreAI_IsMe(0) and GoreAI_IsMe(1), "target 0 accepted by the host only")
check(GoreAI_PlayerHealth(2) == math.huge, "unreported health = full")
SetFloat("level.goreai.player_health.2", 120)
check(GoreAI_PlayerHealth(2) == 120, "reported health read per player")

------------------------------------------------------------------ hitmarkers (client)
init_hitmarkers()
Sounds = { hitmarker = 1, hitmarker_headshot1 = 2, hitmarker_headshot2 = 3 }
hitmarker_receive("headshot", Vec(1,2,3))
check(#Hitmarker_Sounds == 3 and #Hitmarker_Icons == 2 and Hitmarker_Last_Pos[2] == 2, "headshot: 3 sounds, 2 icons, position")
hitmarker_receive("kill", Vec())
check(Hitmarker_Icons[3] == Icons.hitmarker_dead, "kill marker while a hit marker shows")
Hitmarker_Icons = {}
hitmarker_receive("kill", Vec())
check(#Hitmarker_Icons == 0, "no kill marker without a recent hit (as v1)")

------------------------------------------------------------------ killcam
Settings = { game = { killcam = { value = true } } }
Killcam_Data._player_damaged = {}
mark_body_damaged_by_player(60, 2)
local dead = { Head = 60, HT = Transform(Vec(30,1,0)), bodyparts = {60, 61} }
SENT = {}
set_lock_cam(dead) set_lock_cam(dead)
check(#SENT == 1 and SENT[1].to == 2 and SENT[1].fn == "client.goreKillcam", "killcam sent once, to the killer")
-- on player 2's client
LOCAL = 2 SENT = {}
killcam_receive(60, SENT[1] and Vec() or Vec(30,3,0), {60, 61})
check(SENT[1].fn == "server.goreKillcamSlowmo" and SENT[1].args[1] == 2 and SENT[1].args[2] == true, "client asks for slow motion")
tick_lockcam()
check(camSet ~= nil and GetBool("level.killcam.active"), "client moves camera, sets level.killcam.active")
server.goreKillcamSlowmo(2, true)
scale = nil tick_lockcam_server()
check(scale == nil, "no slow motion with 3 players")
-- single player
ORDER = {1} GoreAI_UpdatePlayers()
mark_body_damaged_by_player(60, 1)
LOCAL = 1 SENT = {} set_lock_cam(dead)
server.goreKillcamSlowmo(1, true)
tick_lockcam_server()
check(scale == 0.1, "slow motion when alone")
Killcam_Data.timer.time = 0 SENT = {}
tick_lockcam()
check(not GetBool("level.killcam.active") and SENT[1].args[2] == false, "killcam ends, slow motion off")
-- npc dies one tick after the head hit (_player_damaged is cleared each tick): still a killcam within 0.3 s
Killcam_Data._player_damaged_recent = {}
mark_body_damaged_by_player(60, 1)
Killcam_Data._player_damaged = {} -- next tick
T = T + 0.05 SENT = {}
set_lock_cam(dead)
check(#SENT == 1 and SENT[1].fn == "client.goreKillcam", "killcam when the npc dies a tick after the head hit")
mark_body_damaged_by_player(60, 1)
Killcam_Data._player_damaged = {}
T = T + 1 SENT = {}
tick_lockcam_server()
set_lock_cam(dead)
check(#SENT == 0 and next(Killcam_Data._player_damaged_recent) == nil, "no killcam for an old head hit; old hits pruned")
ORDER = {1, 2, 3} GoreAI_UpdatePlayers()

------------------------------------------------------------------ synced torso lists
API_npcs_alive({ {Torso = 11}, {Torso = 12}, {Torso = 13} })
check(SYNCED["level.goreai.api.npcs.alive.3"] == 13, "alive list written with sync")
SYNCED = {}
API_npcs_alive({ {Torso = 11}, {Torso = 12}, {Torso = 13} })
check(next(SYNCED) == nil, "unchanged list not re-sent")
API_npcs_alive({ {Torso = 12} })
check(SYNCED["level.goreai.api.npcs.alive.1"] == 12 and SYNCED["level.goreai.api.npcs.alive.3"] == 0, "shrunk: stale synced entries zeroed")
check(R["level.goreai.api.npcs.alive.2"] == nil and R["level.goreai.api.npcs.alive.1"] == 12, "shrunk: stale server keys cleared")

------------------------------------------------------------------ NPC bullet hits player 2 (goreai_combat.lua)
for _, n in ipairs{"SpawnParticle","PointLight","DrawLine","MakeHole","Explosion","ParticleReset","ParticleType","ParticleTile",
	"ParticleSticky","ParticleRadius","ParticleAlpha","ParticleEmissive","ParticleColor","ParticleGravity","Blood_Pop"} do _G[n] = function() end end
function GetShapeBody() return 0 end
function GetShapeMaterialAtPosition() return "wood", 1,1,1,1 end
Debug_hitPositions_shapes = {}
loadFns("npcs/GoreNPCs/scripts/components/goreai_combat.lua")
BLOCK = false
local shooter = { rpg = false, velocity = 600, AllBodies = {}, pdamage = 33, roundsize = 1, BulletsShot = 0, oldbulletsshot = 0,
	disttoplayer = 10, maxMomentum = 1, torsoPos = Vec(10, 1.4, 0), barrel = 0, sounds = {} }
SetBool("level.healthScriptSpawned", true)
GoreAI_UpdatePlayers()
GoreAI_SetPlayer(1) -- context = host, but the bullet flies at player 2
local shell = { active = true, time = 0, pos = Vec(19, 1.4, 0), momentum = 1, predictedBulletVelocity = Vec(600, 0, 0) }
for i = 1, 3 do if shell.active then npc_projectile_operations(shooter, shell) end end
check(GetTagValue(p2Head, "QueriedDamage") == "33", "bullet hits player 2's HEAD hitbox (damage tag)")
check(GetTagValue(hostHead, "QueriedDamage") == "0", "host's hitbox untouched")
check(shell.hitPlayer == true, "bullet stops after a player hit")

-- (2026-11-07 crash fix) Constrain* only from update: tick_npcs must not point/hold the gun, update_npcs must
do
	local src = io.open("npcs/GoreNPCs/scripts/goreai_manage.lua", "rb"):read("*a"):gsub("\r", "")
	local function body(name)
		local s = src:find("\nfunction " .. name .. "%(")
		local e = src:find("\nfunction ", s + 1) or #src
		return (src:sub(s, e):gsub("%-%-[^\n]*", "")) -- without comments
	end
	local tick, update = body("tick_npcs"), body("update_npcs")
	check(not tick:find("npc_point_gun%(") and not tick:find("npc_hold_gun%("), "gun constraints not called from tick_npcs")
	check(update:find("npc_point_gun%(") and update:find("npc_hold_gun%("), "gun constraints called from update_npcs")
end

print("all goreai tests passed")

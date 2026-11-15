-- Mock test for the NPC performance cuts (2026-11-15): same results, less per-tick work.
--   tick_bones: an npc's bones are tagged once, and again when the setting changes (v1: every tick)
--   npc_navigation_update: robot_pos is written after 0.5 m of movement or a world shift, startPos no more
--   goreai_initializer: the path state is written to the registry only when it changes
--   npc_find_random_enemy: FindBodies("Heli") once per tick
-- Run from the repo root with Lua 5.1: lua5.1 tools/porting/tests/test_npcperf.lua

local function check(cond, msg) if not cond then error("FAIL: " .. msg, 2) end print("ok  " .. msg) end
local function load(f)
	local src = io.open(f, "rb"):read("*a"):gsub("\r", "")
	src = src:gsub("([^\n]*)", function(l) if l:match("^%s*#") then return "" end return l end)
	assert(loadstring(src, f))()
end

function Vec(x,y,z) return {x or 0,y or 0,z or 0} end
function VecCopy(v) return {v[1],v[2],v[3]} end
function VecSub(a,b) return {a[1]-b[1],a[2]-b[2],a[3]-b[3]} end
function VecLength(a) return math.sqrt(a[1]^2+a[2]^2+a[3]^2) end
function VecDist(a,b) return VecLength(VecSub(a,b)) end
REG, CALLS = {}, {}
local function count(name) CALLS[name] = (CALLS[name] or 0) + 1 end
function SetString(k, v) count("SetString:" .. k) REG[k] = v end
function GetString(k) return REG[k] or "" end
TAGS = {}
function HasTag(h, t) return TAGS[h] and TAGS[h][t] ~= nil end
function SetTag(h, t) count("SetTag") TAGS[h] = TAGS[h] or {} TAGS[h][t] = "" end
function RemoveTag(h, t) count("RemoveTag") if TAGS[h] then TAGS[h][t] = nil end end
util = { serialize = function(t) return table.concat(t, ",") end, unserialize = function(s) return {} end }
server, client = {}, {}

-- tick_bones
load("npcs/GoreNPCs/scripts/components/goreai_functions.lua")
config = { goreai = { unbreakable_bones = 2 } }
local bones = { 11, 12, 13 }
for _, b in ipairs(bones) do TAGS[b] = { bone = "" } end
NPCs = { a = { bones = bones } }
tick_bones()
check(HasTag(11, "unbreakable") and HasTag(13, "unbreakable"), "setting on: bones tagged unbreakable")
local n = CALLS.SetTag
tick_bones() tick_bones()
check(CALLS.SetTag == n, "next ticks: no re-tagging")
config.goreai.unbreakable_bones = 0
tick_bones()
check(not HasTag(11, "unbreakable"), "setting off: tags removed")
NPCs.b = { bones = { 21 } } TAGS[21] = { bone = "", unbreakable = "" }
tick_bones()
check(not HasTag(21, "unbreakable"), "a new npc gets the current setting")

-- npc_navigation_update: robot_pos
setRegTable = function(path, t) count("reg:" .. path) REG[path] = util.serialize(t) end
getRegTable = function() return {} end
load("npcs/GoreNPCs/scripts/components/goreai_robot_navigation.lua")
local npc = { navigation = { newPath = false }, nav = { path = {}, target = Vec(), reg = { robot_pos = "rp", tb_startPos = "sp", tb_target = "tg", tb_path = "pa" } },
	ai = { navPos = Vec() }, robot = { transform = { pos = Vec(0, 0, 0) } } }
MapMoved = false
local ok = pcall(npc_navigation_update, npc, 1/60)
check(CALLS["reg:rp"] == 1 and not CALLS["reg:sp"], "first update writes robot_pos, never startPos")
for i = 1, 10 do npc.robot.transform.pos = Vec(i * 0.04, 0, 0) pcall(npc_navigation_update, npc, 1/60) end
check(CALLS["reg:rp"] == 1, "moving 0.4 m: no rewrite")
npc.robot.transform.pos = Vec(0.6, 0, 0) pcall(npc_navigation_update, npc, 1/60)
check(CALLS["reg:rp"] == 2 and REG.rp == "0.6,0,0", "moved over 0.5 m: robot_pos rewritten")
MapMoved, MapMoveVec = true, Vec(0, 0, 0)
pcall(npc_navigation_update, npc, 1/60)
check(CALLS["reg:rp"] == 3, "world shift: rewritten")
MapMoved = false

-- goreai_initializer: path state on change
local state = "idle"
function GetPathState() return state end
function GetBool() return false end
function IsHandleValid() return true end
load("npcs/GoreNPCs/scripts/goreai_initializer.lua")
function GetTimeStep() return 1/60 end
function AbortPath() end
-- npc.navigation is a registry-backed table in the game: a proxy that counts every GetPathState write
local store, writes = { input_AbortPath = false, hasNewTarget = false, thinkTime = 0, timeout = 3 }, 0
_G.npc = { nav = { reg = {} }, navigation = setmetatable({}, {
	__index = store,
	__newindex = function(_, k, v) if k == "GetPathState" then writes = writes + 1 end store[k] = v end }) }
MyTorso, Finished, ID = 0, false, 1
for i = 1, 5 do server.tick(1/60) end
check(writes == 1, "same path state for 5 ticks: written once")
state = "busy"
server.tick(1/60) server.tick(1/60)
check(writes == 2, "state change: written again")

-- heli search once per tick
local finds = 0
function FindBodies(tag) if tag == "Heli" then finds = finds + 1 end return {} end
load("npcs/GoreNPCs/scripts/components/goreai_targetting.lua")
GoreHelisTick = nil
NPCs = {}
local me = { ai = { teams = { team = 1 }, thinking = { distances = { hunt = 100 } } }, Torso = 1, isFriendly = true }
for i = 1, 5 do pcall(npc_find_random_enemy, me, false) end
check(finds == 1, "5 target searches in one tick: one Heli search")
-- debug call profiler (lib/CallProfiler.lua via goreai_profiler.lua): counts engine calls per frame, attributes
-- them to the innermost NPC function, returns every value, restores the originals when off
ENGINE_API_NAMES = { "QueryRaycast", "GetBodyTransform", "GetTime", "GetBool" }
local ray = function(a) return "hit", a end
QueryRaycast = ray
GetBodyTransform = function() return {} end
function npc_inner() return GetBodyTransform(1) end
function npc_think() QueryRaycast(1) QueryRaycast(2) npc_inner() return "a", "b", "c" end
shared = {}
local on = true
GetBool = function(k) return k == "savegame.mod.debug.npcprofile" and on end
GetTime = function() return 10 end
IsPlayerHost = function() return true end
GetLocalPlayer = function() return 1 end
NPCs = { a = {}, b = { dead = true } }
load("lib/CallProfiler.lua")
load("npcs/GoreNPCs/scripts/systems/goreai_profiler.lua")
GoreProfile_Tick()                 -- switches on (and publishes the first report)
check(QueryRaycast ~= ray and npc_think ~= nil, "profile on: engine and npc functions wrapped")
local r1, r2 = QueryRaycast(5)
check(r1 == "hit" and r2 == 5, "wrapped engine functions return every value")
local a, b, c = npc_think()
npc_think()
check(a == "a" and c == "c", "wrapped npc functions return every value")
CallProfile.next = 0
GoreProfile_Tick()
local p = shared.npcProfile
local function has(lines, s) for _, l in ipairs(lines) do if l:find(s, 1, true) then return l end end end
check(p and has(p.byFunction, "npc_think  4/frame") and has(p.byFunction, "npc_inner  2/frame"),
	"attribution: npc_think made its 4 raycasts, npc_inner its 2 transform reads")
check(has(p.api, "QueryRaycast  5/frame"), "top engine functions: QueryRaycast 5 per frame")
on = false
GoreProfile_Tick()
check(QueryRaycast == ray and shared.npcProfile == nil, "profile off: originals restored")
-- MemoConfig: one registry read per field per frame, same values, writes visible at once
local reads = 0
local raw = { db = false, goreai = setmetatable({}, { __index = function(_, k) reads = reads + 1 return k == "isEnabled" end,
	__newindex = function() end }) }
local cfg = MemoConfig(raw)
ConfigMemoGen = 1
local a1, a2, a3 = cfg.goreai.isEnabled, cfg.goreai.isEnabled, cfg.goreai.thinking
check(a1 == true and a2 == true and a3 == false and reads == 2, "config memo: 2 fields, 2 registry reads in a frame")
check(cfg.db == false and cfg.db == false, "config memo: false values cached too")
ConfigMemoGen = 2
local _ = cfg.goreai.isEnabled
check(reads == 3, "next frame: read again (debug menu changes are seen)")
cfg.goreai.thinking = true
check(cfg.goreai.thinking == true and reads == 3, "a write is visible at once")
-- damage only when a hit is pending: every writer of a body damage value also raises the flag
local writers = { "npcs/GoreNPCs/scripts/components/goreai_combat.lua", "vehicles/aircraft/AS350/script/HeliV2.lua",
	"vehicles/aircraft/AS350/script/Weapons.lua", "vehicles/aircraft/Mil-Mi-35P-Hind/script/Weapons.lua",
	"vehicles/avf_port/AVF_Shells.lua", "weapons/guns/gunfunctions.lua", "weapons/melee/Melee_Functions.lua" }
local allFlagged = true
for _, f in ipairs(writers) do
	local t = io.open(f, "rb"):read("*a")
	local writes = select(2, t:gsub("SetFloat%(path_damage,", ""))
	local flags = select(2, t:gsub('SetBool%("level%.goreai%.damage_pending", true%)', ""))
	if writes ~= flags or writes == 0 then allFlagged = false print("  " .. f .. ": " .. writes .. " writes, " .. flags .. " flags") end
end
check(allFlagged, "every body damage writer raises level.goreai.damage_pending")
local fn = io.open("npcs/GoreNPCs/scripts/components/goreai_functions.lua", "rb"):read("*a")
local _, seeSets = fn:gsub("check_see_player%.rpm = SEE_INTERVAL", "")
check(seeSets == 2 and not fn:find('rpm = GetFloat%("savegame%.mod%.config%.goreai%.see_timer"%)') and fn:find("SEE_INTERVAL = 0%.2"),
	"sight checks: SEE_INTERVAL 0.2 s (v1 read an unset key: 0 = every tick)")

-- ground rays every 2nd update: on a skipped update the hover distance follows the torso
function VecDot(a, b) return a[1]*b[1] + a[2]*b[2] + a[3]*b[3] end
local L = { dist = 1.0, pos = Vec(0, 5, 0) }
local est = L.dist + VecDot(VecSub(Vec(0, 5.2, 0), L.pos), Vec(0, 1, 0))
check(math.abs(est - 1.2) < 1e-9, "skipped ray: torso 0.2 m higher -> 0.2 m farther from the ground")
print("all npc performance tests passed")

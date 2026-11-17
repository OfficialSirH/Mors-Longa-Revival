-- Mock test for the settled-dead npc path in npcs/GoreNPCs/scripts/goreai_manage.lua (2026-11-17, performance): a dead
-- npc past its 3 s window skips the per-tick target-player pick, checks all body parts and reads its position once a
-- second (the torso handle every tick), writes its light only when day / night changes, frees its projectile records
-- once none is in flight, and is still listed as dead and marked for removal. Run from the repo root with Lua 5.1: lua5.1 tools/porting/tests/test_restdead.lua

local T, STEP = 0, 1 / 60
function GetTime() return T end
function GetTimeStep() return STEP end
local REG = {}
function GetBool(k) return REG[k] == true end
function SetBool(k, v) REG[k] = v end
local VALID = {}
function IsHandleValid(h) return VALID[h] == true end
function GetBodyTransform(b) return { pos = { b, 0, 0 }, rot = { 0, 0, 0, 1 } } end
function AabbGetBodyCenterPos(b) return { b, 1, 0 } end
function VecDist() return 1 end
config = { goreai = { thinkingEnabled = true, isEnabled = true }, db = false }
Controls = { gunsway = { value = 1 } }
function IsControllerNPC() return false end
local count = { context = 0, valid = 0, light = 0, removal = 0 }
function GoreAI_SetContext() count.context = count.context + 1 end
function npc_is_valid(npc)
	count.valid = count.valid + 1
	npc.isValid = IsHandleValid(npc.Torso)
	for _, b in ipairs(npc.bodyparts) do if not IsHandleValid(b) then npc.isValid = false end end
	return npc.isValid
end
function npc_get_voxels() return 100 end
for _, n in ipairs({ "npc_process_health", "npc_process_shield", "npc_process_stun", "npc_process_aim_sway",
	"npc_process_target", "npc_manage_gun", "npc_die", "npc_release_gun", "npc_release_melee_weapons",
	"npc_delete_entities", "npc_projectile_operations" }) do _G[n] = function() end end
function npc_mark_for_removal() count.removal = count.removal + 1 end
local lightOn
function SetLightEnabled(l, on) count.light = count.light + 1 lightOn = on end
local lastDead, lastAlive
function API_npcs_alive(l) lastAlive = l end
function API_npcs_dead(l) lastDead = l end

local src = io.open("npcs/GoreNPCs/scripts/goreai_manage.lua", "rb"):read("*a"):gsub("\r", ""):gsub("\n#[^\n]*", "\n")
src = src:gsub("^#[^\n]*", "")
assert(loadstring(src, "goreai_manage.lua"))()

local function check(cond, msg) if not cond then error("FAIL: " .. msg, 2) end print("ok  " .. msg) end

local npc = { id = 1, Torso = 10, Light = 5, bodyparts = { 10, 11, 12 }, dead = true, deadTime = 0, ai = {},
	projectileHandler = { shells = { { active = false }, { active = true } } } }
VALID[10], VALID[11], VALID[12] = true, true, true
NPCs = { [1] = npc }
DayPhase = "Day"
IsGoreMap = false

local function tick() T = T + STEP tick_npcs(STEP) end

-- the 3 s dead window: the normal path (target pick every tick)
for _ = 1, 60 * 3 do tick() end
check(not npc.restDead and count.context == 180, "first 3 s dead: normal path, context every tick")
for _ = 1, 3 do tick() end
check(npc.restDead and npc.died, "past 3 s: settled-dead path")

-- settled: no target pick, body-part check once a second, light written once
for k in pairs(count) do count[k] = 0 end
for _ = 1, 120 do tick() end
check(count.context == 0, "no target-player pick while settled dead")
check(count.valid >= 1 and count.valid <= 3, "body parts checked once a second (" .. count.valid .. " in 2 s)")
check(count.light == 0 and lightOn == false, "light not rewritten while day stays (set off on entering)")
check(count.removal == 120, "still marked for removal every tick")
check(#lastDead == 1 and lastDead[1] == npc and #lastAlive == 0, "still listed as dead")
check(npc.torsoPos[1] == 10 and npc.deadTime > 5, "torso position (once a second) and dead time kept current")
check(#npc.projectileHandler.shells == 2, "projectile records kept while one is in flight")
npc.projectileHandler.shells[2].active = false
for _ = 1, 61 do tick() end
check(#npc.projectileHandler.shells == 0 and npc.restShellsFreed, "projectile records freed once none is in flight")

-- night: the light follows
DayPhase = "Night"
tick()
check(count.light == 1 and lightOn == true, "light written again when night comes")

-- torso deleted: invalid at once, no longer listed
VALID[10] = false
tick()
check(npc.isValid == false and #lastDead == 0, "torso deleted: invalid on the same tick, not listed")
VALID[10] = true

-- a limb deleted: caught by the once-a-second check
VALID[11] = false
for _ = 1, 61 do tick() end
check(npc.isValid == false, "limb deleted: invalid within a second")

-- tick_npcs_info uses the kept validity for settled npcs
loadstring((io.open("npcs/GoreNPCs/scripts/components/goreai_friendlies.lua", "rb"):read("*a"):gsub("\r", "")))()
NPC_TEAMS, PlayerTeam, FriendliesCount = { a = 1 }, 1, 0
npc.ai.teams = { team = "a" }
npc.isValid = true
count.valid = 0
tick_npcs_info()
check(count.valid == 0 and FriendliesCount == 1, "tick_npcs_info: no body-part check for a settled npc, still counted")

print("all rest-dead tests passed")

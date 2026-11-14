-- Mock test for the GoreNPCs client view (systems/goreai_netview.lua) and "control an NPC" (goreai_controller.lua),
-- loaded through the real goreai_main.lua include chain. Run from the repo root with Lua 5.1:
--   lua5.1 tools/porting/tests/test_npcview.lua
dofile("tools/porting/tests/mockengine.lua")

local function check(cond, msg) if not cond then error("FAIL: " .. msg, 2) end print("ok  " .. msg) end
local MAIN = "npcs/GoreNPCs/scripts/goreai_main.lua"

local function load(side)
	local env = MockEngine.load(MAIN, { preload = MockEngine.includes(MAIN) })
	env.side = side
	env.def("IsHandleValid", function(h) return h ~= nil and h ~= 0 end)
	env.def("InputPressed", function() return false end)
	env.def("InputDown", function() return false end)
	env.def("ListKeys", function() return {} end)
	env.def("GetBodyTransform", function(b) return env.Transform({ b, 0, 0 }) end)
	return env
end

-- shared as the engine would sync it: count server writes, hand clients a copy
local function deepcopy(v)
	if type(v) ~= "table" then return v end
	local c = {} for k, x in pairs(v) do c[k] = deepcopy(x) end return c
end
local function countingShared(env)
	local store, writes = {}, { n = 0 }
	env.shared.goreNpcs = setmetatable({}, {
		__index = store,
		__newindex = function(_, k, v) writes.n = writes.n + 1 store[k] = v end,
	})
	env.shared.goreControl = {}
	return store, writes
end
local function sync(server, client, store)
	client.shared.goreNpcs = deepcopy(store)
	client.shared.goreControl = deepcopy(server.shared.goreControl)
end

local function fakeNpc(id, torso, opts)
	opts = opts or {}
	return {
		id = id, isValid = true, dead = opts.dead or false, deadTime = opts.deadTime or 0,
		Torso = torso, Head = torso + 1, AllBodies = { torso, torso + 1 }, bones = { torso + 50 },
		torsoTr = { pos = { torso, 0, 0 }, rot = { 0, 0, 0, 1 } },
		health = opts.health or 100, health_max = 125,
		shield = { value = opts.shield or 0, max = opts.shield or 0 },
		boss = { isBoss = opts.boss or false, boss_preset = { title = "Big Boss" } },
		ai = { teams = { team = "mil" }, thinking = { state = "attack", states = { dist = "far", shoot = "yes" },
			attacking = {} }, targeting = { recheck_timer = { time = 0.4 } }, navPos = { 1, 2, 3 } },
		nav = { path = { { 1, 1, 1 }, { 2, 2, 2 } }, target = { 3, 3, 3 }, reg = { tb_target = "x" } },
		robot = { speed = 1 },
		Gun = { body = torso + 10, handle = torso + 11, gun_path = "MOD/ak.xml" },
		burstsize = 30, BulletsShot = 4, MagSize = 30,
	}
end

------------------------------------------------------------------ 1. server publishes
local srv = load("server")
local store, writes = countingShared(srv)
srv.config = { db = false, goreai = {} }
srv.DebugMode = false
local grunt, boss = fakeNpc("g1", 100), fakeNpc("b1", 200, { boss = true, shield = 90 })
srv.NPCs = { g1 = grunt, b1 = boss }
srv.NPC_Torsos = { [100] = grunt, [200] = boss }
srv.GoreAI_PublishNPCs(0.2)
check(store.b1 and not store.g1 and next(srv.violations) == nil, "publish: boss sent, ordinary npc not (debug off)")
check(store.b1.health == 100 and store.b1.shieldMax == 90 and store.b1.boss and store.b1.team == "mil"
	and store.b1.bossTitle == "Big Boss" and store.b1.dbg == nil, "publish: boss record has health / shield / team, no debug fields")
local n = writes.n
srv.GoreAI_PublishNPCs(0.2)
check(writes.n == n, "publish: unchanged record is not sent again")
boss.health = 60
srv.GoreAI_PublishNPCs(0.05)
check(writes.n == n, "publish: at most every 0.1 s")
srv.GoreAI_PublishNPCs(0.06)
check(writes.n == n + 1 and store.b1.health == 60, "publish: changed health is sent")
srv.DebugMode = true
srv.GoreAI_PublishNPCs(0.2)
check(store.g1 and store.g1.dbg and store.g1.dbg.state == "attack" and #store.g1.dbg.path == 2,
	"publish (host debug mode): every npc, with nav / thinking fields")
srv.DebugMode = false
srv.GoreAI_PublishNPCs(0.2)
check(store.g1 == nil and store.b1 and store.b1.dbg == nil, "publish: debug off again -> ordinary npc removed")

------------------------------------------------------------------ 2. client view + v1 draw code
local cli = load("client")
cli.LOCAL = 2
cli.PLAYERS[2] = { pos = { 0, 0, 0 }, health = 1 }
sync(srv, cli, store)
cli.client.init()
cli.config.goreai.isEnabled = true
cli.client.tick(1/60)
check(cli.NPCs.b1 and cli.NPCs.b1.health == 60 and cli.NPCs.b1.Head == 201 and cli.NPCs.b1.boss.isBoss,
	"client: NPCs rebuilt from shared (non-host player)")
cli.def("TransformToLocalPoint", function() return { 0, 0, -5 } end) -- in front of the camera
cli.def("GetCameraTransform", function() return cli.Transform({ 0, 0, 5 }) end) -- mock bounds put the head at 0,0,0
local bars = 0
cli.def("UiProgressBarTitled", function() bars = bars + 1 end)
cli.client.draw()
check(bars >= 2 and next(cli.violations) == nil, "client: boss health + shield bars drawn by the v1 code (non-host)")
srv.DebugMode = true
srv.GoreAI_PublishNPCs(0.2)
sync(srv, cli, store)
for _, k in ipairs({ "text_debug", "draw_debug", "draw_combat", "pos_dot", "outlines", "healthbar_debug", "draw_bones" }) do
	cli.config.goreai[k] = true
end
cli.client.tick(1/60)
local lines = 0
cli.def("DebugLine", function() lines = lines + 1 end)
cli.client.draw()
check(cli.NPCs.g1 and lines > 0 and next(cli.violations) == nil, "client: all debug overlays draw from the proxies without errors")

------------------------------------------------------------------ 3. control an npc (player 2)
local sent = {}
cli.sent = sent
cli.ServerCall = function(fn, ...) sent[#sent + 1] = { fn = fn, args = { ... } } end
cli.R["level.npcs.selectingControllerNPC"] = true
cli.def("RaycastFromTransform", function() return true, { 100, 0, 0 }, { 0, 1, 0 }, 100 end)
cli.def("HasTag", function(b, t) return t == "Torso" and b == 100 end)
local clickNow = true
cli.def("InputPressed", function(k) return clickNow and k == "lmb" end)
cli.client.tick(1/60)
clickNow = false
check(sent[1] and sent[1].fn == "server.goreControlStart" and sent[1].args[1] == 2 and sent[1].args[2] == 100
	and cli.R["level.npcs.selectingControllerNPC"] == false, "controller: click on a torso asks the server (player 2)")

srv.server.goreControlStart(2, 100)
check(srv.shared.goreControl["2"] == "g1" and srv.IsControllerNPC(grunt) and not srv.IsControllerNPC(boss),
	"controller: server maps player 2 -> npc g1")
srv.server.goreControlStart(3, 100)
check(srv.shared.goreControl["3"] == nil, "controller: a second player cannot take the same npc")
srv.GoreAI_PublishNPCs(0.2)
sync(srv, cli, store)
cli.def("InputDown", function(k) return k == "up" or k == "usetool" end)
cli.client.tick(1/60)
local input = sent[#sent]
check(cli.ControllerNPC and cli.ControllerNPC.id == "g1" and input.fn == "server.goreControlInput" and input.args[1] == 2
	and input.args[5] == "up" and input.args[6] == true, "controller: client sends aim, move and shoot each tick")

local moved, shot, tool
srv.hoverMove = function(npc, speed) moved = speed end
srv.npc_stop_attacking = function() end
srv.npc_manage_shooting = function(npc, dt, s) shot = s end
srv.setRegTable = function() end
srv.def("SetPlayerTool", function(t, p) tool = { t, p } end)
local frozen, hidden
srv.def("DisablePlayerInput", function(p) frozen = p end)
srv.def("SetPlayerHidden", function(p) hidden = p end)
srv.ORDER = { 1, 2 }
srv.PLAYERS[2] = { pos = { 0, 0, 0 }, health = 1 }
srv.server.goreControlInput(unpack(input.args))
srv.tick_controller(1/60)
check(moved == 3 and shot == true and grunt.ai.aimPos[1] == 100 and tool[1] == "physgun" and tool[2] == 2
	and next(srv.violations) == nil, "controller: server drives the npc with player 2's input")
check(frozen == 2 and hidden == 2, "controller: player 2's own character is frozen and hidden while controlling")

cli.def("InputDown", function(k) return k == "ctrl" end)
cli.def("InputPressed", function(k) return k == "x" end)
cli.client.tick(1/60)
check(sent[#sent].fn == "server.goreControlStop", "controller: ctrl+x asks the server to stop")
local where
srv.def("SetPlayerTransform", function(t, p) where = { t, p } end)
srv.server.goreControlStop(2)
check(where and where[2] == 2 and where[1].pos[2] == 2 and srv.shared.goreControl["2"] == nil and not srv.IsControllerNPC(grunt),
	"controller: stop puts player 2 above the npc and frees it")

srv.server.goreControlStart(2, 100)
grunt.deadTime = 3
srv.tick_controller(1/60)
check(srv.shared.goreControl["2"] == nil, "controller: released 3 s after the npc died")
srv.server.goreControlStart(2, 100)
srv.ORDER = { 1 }
grunt.deadTime = 0
srv.tick_controller(1/60)
check(srv.shared.goreControl["2"] == nil, "controller: released when the player leaves")

print("all npcview tests passed")

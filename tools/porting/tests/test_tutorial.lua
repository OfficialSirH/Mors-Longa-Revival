-- Mock test for the tutorial scripts (Phase 3, scripts/Tutorial). Run from the repo root with Lua 5.1:
--   lua5.1 tools/porting/tests/test_tutorial.lua
dofile("tools/porting/tests/mockengine.lua")

local function check(cond, msg) if not cond then error("FAIL: " .. msg, 2) end print("ok  " .. msg) end
local function twoPlayers(env, p2pos)
	env.PLAYERS = { [1] = { pos = {100,0,0}, health = 1 }, [2] = { pos = p2pos, health = 1 } }
	env.ORDER = { 1, 2 }
end
local function serverSteps(env, n, dt)
	for i = 1, n do
		env.T = env.T + dt
		if env.server.update then env.server.update(dt) end
		if env.server.tick then env.server.tick(dt) end
	end
end
local function sentTo(env, fn)
	local n = 0
	for _, m in ipairs(env.sent) do if m.fn == fn then n = n + 1 end end
	return n
end

-- client-only scripts: per-machine inventory / hunger, bleeding warning
for _, f in ipairs({ "tutClearInv", "tutForceHungry" }) do
	local env = MockEngine.load("scripts/Tutorial/" .. f .. ".lua")
	check(env.server.init == nil and env.client.init ~= nil, f .. ": client only")
	env.side = "client" env.client.init()
	check(next(env.violations) == nil, f .. ": no server-only calls")
end
local env = MockEngine.load("scripts/Tutorial/tutClearInv.lua")
env.R["savegame.mod.inventory.guns.1.item"] = "AK74"
env.side = "client" env.client.init()
check(env.R["savegame.mod.inventory.guns.1.item"] == "", "tutClearInv: empties the local saved inventory")

env = MockEngine.load("scripts/Tutorial/tutHURTWARN.lua")
env.def("FindTriggers", function() return { 11 } end)
env.def("HasTag", function(h, t) return t == "Bleed" end)
env.side = "client" env.client.draw()
check((env.calls.UiText or 0) == 3 and next(env.violations) == nil, "tutHURTWARN: warning drawn on the client")

-- server-only world scripts
env = MockEngine.load("scripts/Tutorial/tutMakeHoleAtLocation.lua")
env.def("FindLocations", function() return { 5, 6 } end)
env.server.init() serverSteps(env, 2, 1/60)
check(env.calls.MakeHole == 2 and next(env.violations) == nil, "tutMakeHole: holes made on the server, once each")

env = MockEngine.load("scripts/Tutorial/tutRemoverTriggerWhenTrigger.lua")
twoPlayers(env, {5,0,0})
local deleted = {}
env.def("FindTriggers", function() return { 21, 22 } end)
env.def("IsPointInTrigger", function(t, pos) return t == 22 and pos[1] == 5 end)
env.def("Delete", function(h) deleted[#deleted + 1] = h end)
env.server.init() serverSteps(env, 3, 1/60)
check(#deleted == 1 and deleted[1] == 22, "tutRemoverTrigger: player 2 (not the host) removes the trigger, once")

-- ending: any player starts it; every client fades and saves; the host loads main.xml once
env = MockEngine.load("scripts/Tutorial/tutEnding.lua")
twoPlayers(env, {5,0,0})
env.def("FindTriggers", function() return { 31 } end)
env.def("IsPointInTrigger", function(t, pos) return pos[1] == 5 end)
local started = 0
env.def("StartLevel", function() started = started + 1 end)
env.server.init()
env.side = "client" env.client.init() env.side = "server"
serverSteps(env, 1, 1/60)
check(env.shared.ending == true, "tutEnding: player 2 entering the trigger starts the ending")
for i = 1, 60 * 6 do
	env.side = "client" env.client.tick(1/60) env.client.draw()
	env.side = "server" serverSteps(env, 1, 1/60)
end
check(env.R["savegame.mod.tutorial.states.hasFinishedTutorialLevel"] == true, "tutEnding: client marks its savegame finished")
check(started == 1, "tutEnding: host starts main.xml once")
check(env.calls.SetCameraTransform and next(env.violations) == nil, "tutEnding: camera on the client, StartLevel on the server")

-- tips: the local player's trigger, slow-down through the server
env = MockEngine.load("scripts/Tutorial/tutTriggerHUDNotification.lua")
twoPlayers(env, {5,0,0})
env.LOCAL = 2
env.Init_Settings = function() env.Settings = { keybinds = { jump = { type = "key", values = { k1 = "space", k2 = "none", k3 = "none" } } } } end
env.ternary = function(c, a, b) if c then return a end return b end
env.Oscillate = function() return 0 end
env.beep = function() end
env.AabbGetBodyCenterPos = function() return env.Vec() end
env.AabbGetShapeCenterPos = function() return env.Vec() end
env.def("FindTriggers", function() return { 41, 43 } end)
env.def("GetDescription", function(h) return "Press <jump> to jump" end)
env.def("GetTagValue", function(h, t) return "Jump_Tip" end)
env.def("IsHandleValid", function() return true end)
env.def("HasTag", function() return false end)
local inTrigger = 41
env.def("IsPointInTrigger", function(t, pos) return t == inTrigger end)
env.server.init()
env.side = "client" env.client.init() env.client.tick(1/60)
check(env.Desc == "Press <SPACE> to jump" and env.CurrentTriggerTitle == "Jump Tip", "tips: text with this player's keybinds")
inTrigger = 43
env.client.tick(1/60) env.client.draw()
check(sentTo(env, "server.tutSlow") == 1 and env.sent[1].args[1] == 2, "tips: entering a new tip asks the server to slow player 2")
env.side = "server"
local slowed
env.def("SetPlayerVelocity", function(v, p) slowed = p end)
env.server.tutSlow(2)
serverSteps(env, 1, 1/60)
check(slowed == 2 and next(env.violations) == nil, "tips: server slows player 2; no wrong-side calls")
serverSteps(env, 40, 1/60)
check(next(env.Slowed) == nil, "tips: slow-down ends after 0.5 s")

print("all tutorial tests passed")

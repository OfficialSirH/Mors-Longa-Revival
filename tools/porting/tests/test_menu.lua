-- Mock test for the main menu (main.xml) v2 port. Run from the repo root with Lua 5.1:
--   lua5.1 tools/porting/tests/test_menu.lua
dofile("tools/porting/tests/mockengine.lua")

local function check(cond, msg) if not cond then error("FAIL: " .. msg, 2) end print("ok  " .. msg) end

local includes = MockEngine.includes

local press -- label of the button the "user" clicks this frame
local function load(path)
	local env = MockEngine.load(path, { preload = includes(path) })
	env.side = "client"
	env.def("UiTextButton", function(label) return label == press end)
	env.def("InputPressed", function() return false end)
	env.def("InputDown", function() return false end)
	env.def("UiGetMousePos", function() return 0, 0 end)
	env.def("ListKeys", function() return {} end)
	env.def("UiGetImageSize", function() return 100, 100 end)
	env.def("UiIsMouseInRect", function() return false end)
	env.def("UiReceivesInput", function() return false end)
	local texts = {}
	env.def("UiText", function(t) texts[#texts + 1] = t return 10, 10 end)
	env.texts = texts
	return env
end
local function frames(env, n)
	for i = 1, n or 3 do
		env.client.tick(1/60)
		env.client.draw(1/60)
	end
end
local function startCalls(env)
	local list = {}
	for _, s in ipairs(env.sent) do if s.fn == "server.startLevel" then list[#list + 1] = s end end
	return list
end
local function has(list, v) for _, x in ipairs(list) do if x == v then return true end end return false end

-- 1. host: menu runs on the client without server-only calls; Continue asks the server to start the level
local env = load("ui/MainMenu/main_menu.lua")
env.R["savegame.mod.continue"] = true
env.R["savegame.mod.difficulty"] = "normal"
env.client.init()
frames(env, 3)
check(next(env.violations) == nil and not env.calls.StartLevel, "menu (host): runs on the client, no server-only calls")
check(not has(env.texts, "THE HOST STARTS THE GAME"), "menu (host): no 'host starts' notice")
press = "CONTINUE"
frames(env, 1)
press = nil
local s = startCalls(env)
check(#s == 1 and s[1].args[1] == "morslonga_main" and s[1].args[2] == "MOD/levels/level.xml" and s[1].args[3] == "normal nodev",
	"menu (host): CONTINUE -> server.startLevel(morslonga_main, MOD/levels/level.xml, 'normal nodev')")
env.side = "server"
env.server.startLevel(unpack(s[1].args))
check(env.calls.StartLevel == 1 and next(env.violations) == nil, "server.startLevel calls StartLevel on the server")
env.side = "client"
press = "TUTORIAL"
frames(env, 1)
press = nil
s = startCalls(env)
check(#s == 2 and s[2].args[2] == "MOD/levels/level_tutorial.xml", "menu (host): TUTORIAL -> tutorial level")
press = "NEW SAVE"
env.R["savegame.mod.tutorial.states.hasFinishedTutorialLevel"] = true
frames(env, 1)
press = nil
check(env.R["level.UI.menu_select_difficulty"] == true, "menu (host): NEW SAVE opens the difficulty screen")

-- 2. other player: start buttons do nothing, notice shown, options still work
env = load("ui/MainMenu/main_menu.lua")
env.LOCAL = 2
env.PLAYERS[2] = { pos = {0,0,0}, health = 1 }
env.R["savegame.mod.continue"] = true
env.client.init()
frames(env, 2)
for _, label in ipairs({ "CONTINUE", "NEW SAVE", "TUTORIAL" }) do
	press = label
	frames(env, 1)
end
press = nil
check(#startCalls(env) == 0 and env.R["level.UI.menu_select_difficulty"] == nil, "menu (other player): CONTINUE / NEW SAVE / TUTORIAL do nothing")
check(has(env.texts, "THE HOST STARTS THE GAME"), "menu (other player): 'THE HOST STARTS THE GAME' shown")
press = "OPTIONS"
frames(env, 1)
press = nil
check(env.Selected_Menu_Item and env.Selected_Menu_Item.key == "options" and next(env.violations) == nil, "menu (other player): OPTIONS still opens")

-- 3. difficulty screen: client camera (no world change), host picks -> savegame + start request
env = load("ui/MainMenu/menu_select_difficulty.lua")
local locs = { 11, 12, 13, 14 }
env.def("FindLocations", function(tag) if tag == "camdest" then return locs end return { 21, 22, 23, 24 } end)
env.def("GetLocationTransform", function(h) return env.Transform({ h, 0, 0 }) end)
env.client.init()
env.R["level.UI.menu_select_difficulty"] = true
frames(env, 5)
check(next(env.violations) == nil and not env.calls.SetBodyTransform and (env.calls.SetCameraTransform or 0) >= 5,
	"difficulty: camera moves on the client only (v1 moved the 'cam' body)")
check(env.CamT.pos[1] > 0, "difficulty: camera travels towards the selected character")
env.playCharacter(3)
s = startCalls(env)
check(#s == 1 and s[1].args[3] == "hardcore nodev" and env.R["savegame.mod.difficulty"] == "hardcore"
	and env.R["savegame.mod.newLevel.gamerule.permadeath"] == true, "difficulty (host): SURVIVOR -> hardcore rules saved, server.startLevel")
env.playCharacter(4)
s = startCalls(env)
check(#s == 2 and s[2].args[1] == "morslonga_level1" and s[2].args[2] == "MOD/levels/level_horde.xml" and s[2].args[3] == "",
	"difficulty (host): Gladiator -> horde level")
env = load("ui/MainMenu/menu_select_difficulty.lua")
env.LOCAL = 2
env.PLAYERS[2] = { pos = {0,0,0}, health = 1 }
env.client.init()
env.playCharacter(2)
check(#startCalls(env) == 0 and env.R["savegame.mod.difficulty"] == nil, "difficulty (other player): nothing saved or started")

-- 4. turntable: body turns on the server, camera on each client
env = load("ui/RotateScene.lua")
env.side = "server"
env.server.init()
env.server.update(1/60)
check(env.calls.SetBodyTransform == 1 and next(env.violations) == nil, "turntable: turned on the server")
local hidden = {}
env.ORDER = { 1, 2 }
env.PLAYERS[2] = { pos = {0,0,0}, health = 1 }
env.def("SetPlayerHidden", function(p) hidden[#hidden + 1] = p end)
env.server.tick(1/60)
check(hidden[1] == 1 and hidden[2] == 2 and next(env.violations) == nil, "menu scene: every player's character hidden (server)")
env.side = "client"
env.client.init()
env.client.draw(1/60)
check(env.calls.SetCameraTransform == 1 and next(env.violations) == nil and env.client.tick == nil, "turntable: menu camera set on the client")

-- 5. ingame_settings still loads with the library version of menu_main (its own client callbacks win)
env = load("ui/MainMenu/ingame_settings.lua")
env.client.init()
env.client.draw()
env.client.tick()
env.client.draw()
check(next(env.violations) == nil and env.server.startLevel ~= nil, "ingame_settings: loads with the menu library, no wrong-side calls")

print("all menu tests passed")

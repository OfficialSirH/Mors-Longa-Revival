-- Mock test for horde mode (world/generation/WaveHandler.lua, weapons/PlaceTool/HordePlaceTool.lua). Run from the
-- repo root with Lua 5.1:   lua5.1 tools/porting/tests/test_horde.lua
dofile("tools/porting/tests/mockengine.lua")

local function check(cond, msg) if not cond then error("FAIL: " .. msg, 2) end print("ok  " .. msg) end
local function deepcopy(v)
	if type(v) ~= "table" then return v end
	local c = {} for k, x in pairs(v) do c[k] = deepcopy(x) end return c
end

------------------------------------------------------------------ waves
local srv = MockEngine.load("world/generation/WaveHandler.lua")
local torsos = {}
srv.def("FindBodies", function(tag) if tag == "Torso" then return torsos end return {} end)
local spawned = {}
srv.def("Spawn", function(path) spawned[#spawned + 1] = path return {} end)
srv.server.init()
for i = 1, 60 do srv.server.tick(1/60) end
check(srv.shared.horde and srv.shared.horde.wave == 0 and srv.shared.horde.ongoing == false and srv.shared.horde.time == 4,
	"waves: countdown to wave 1 published (shared.horde)")
check(not srv.calls.DebugPrint and not srv.calls.DrawBodyOutline and next(srv.violations) == nil, "waves: server only, no DebugPrint spam")
for i = 1, 5 * 60 do srv.server.tick(1/60) end
check(srv.shared.horde.wave == 1 and srv.shared.horde.ongoing == false and #spawned >= 1
	and spawned[1]:match("^MOD/prefabs/spawnables/Waves/%a+Wave_%d%.xml$"), "waves: wave 1 parts spawned")
local reward
for _, s in ipairs(srv.sent) do if s.fn == "client.hordeReward" then reward = s end end
check(reward and reward.to == 0 and reward.args[1] == 100, "waves: wave 1 cleared -> 100 to every player (ClientCall 0)")
check(srv.shared.horde.ongoing == false, "waves: countdown shown again after a cleared wave (v1 bug: stayed 'ongoing')")
-- ongoing while enemies are alive
srv = MockEngine.load("world/generation/WaveHandler.lua")
torsos = { 7, 8 }
srv.def("FindBodies", function(tag) if tag == "Torso" then return torsos end return {} end)
srv.def("HasTag", function() return false end)
srv.server.init()
for i = 1, 6 * 60 do srv.server.tick(1/60) end
check(srv.shared.horde.wave == 1 and srv.shared.horde.ongoing == true, "waves: 'wave ongoing' while enemies live")
for i = 1, 20 * 60 do srv.server.tick(1/60) end
local seen = false
for i = 1, 6 * 60 do srv.server.tick(1/60) if #srv.shared.horde.outline == 2 then seen = true end end -- flashes 0.5 s every 1-5 s
check(seen, "waves: last enemies listed for the client outline")

local cli = MockEngine.load("world/generation/WaveHandler.lua")
cli.side = "client"
cli.client.init()
check(cli.R["savegame.mod.player.money"] == 500 and cli.R["savegame.mod.inventory.init"] == true, "waves (client): every player starts with 500 + fresh inventory")
cli.shared.horde = deepcopy(srv.shared.horde)
cli.shared.horde.outline = { 7, 8 }
cli.def("IsHandleValid", function() return true end)
cli.client.tick(1/60)
check(cli.R["savegame.mod.player.current.wave"] == 1 and cli.R["level.horde.ongoing.enabled"] == true
	and cli.calls.DrawBodyOutline == 2 and next(cli.violations) == nil, "waves (client): wave UI keys + outlines")
cli.client.hordeReward(300)
check(cli.R["savegame.mod.player.money"] == 800 and cli.R["inventory.refreshshop"] == true, "waves (client): prize added to own money")

------------------------------------------------------------------ place tool, server
local PLACE = "weapons/PlaceTool/HordePlaceTool.lua"
srv = MockEngine.load(PLACE, { preload = MockEngine.includes(PLACE) })
local nextHandle, spawns, deleted = 500, {}, {}
srv.def("Spawn", function(path, t, a, b)
	nextHandle = nextHandle + 2
	spawns[#spawns + 1] = { path = path, t = t, a = a, b = b }
	return { nextHandle, nextHandle + 1 }
end)
srv.def("GetEntityType", function(e) return e % 2 == 0 and "body" or "shape" end)
srv.def("IsHandleValid", function(h) return not deleted[h] end)
srv.def("Delete", function(h) deleted[h] = true end)
srv.server.init()
check(srv.calls.RegisterTool == 1 and (srv.calls.SetToolEnabled or 0) >= 1, "place tool (server): tool registered and enabled")
srv.server.placerPreview(2, 3, true, 1, 2, 3, 0, 0, 0, 1)
local body = srv.shared.placer["2"]
check(#spawns == 1 and spawns[1].path:match("Armor5%.xml$") and body == 502 and srv.calls.SetBodyTransform == 1,
	"place tool (server): player 2's preview spawned and moved")
srv.server.placerPreview(2, 3, true, 1, 2, 4, 0, 0, 0, 1)
check(#spawns == 1 and srv.calls.SetBodyTransform == 2, "place tool (server): same model -> same preview body")
srv.server.placerPreview(2, 4, false)
check(#spawns == 2 and deleted[502] and srv.shared.placer["2"] == 504, "place tool (server): new model -> old preview deleted")
srv.server.tick(1/60)
check(srv.R["level.placetool.preview_bodies"] == "_504", "place tool (server): preview list for GoreNPCs")
srv.server.placerPlace(2, 4, 5, 0, 5, 0, 0, 0, 1)
check(#spawns == 3 and spawns[3].path:match("Sandbag%.xml$") and spawns[3].a == false and spawns[3].b == true
	and spawns[3].t.pos[1] == 5, "place tool (server): places the item where the client asked")
srv.server.placerPreview(2, 0, false)
check(srv.shared.placer["2"] == nil and deleted[504] and next(srv.violations) == nil, "place tool (server): tool put away -> preview removed")

------------------------------------------------------------------ place tool, client
cli = MockEngine.load(PLACE, { preload = MockEngine.includes(PLACE) })
cli.side = "client"
cli.LOCAL = 2
cli.PLAYERS[2] = { pos = { 0, 0, 0 }, health = 1 }
cli.def("ListKeys", function() return {} end)
local tool = "placer"
cli.def("GetPlayerTool", function() return tool end)
cli.def("GetPlayerVehicle", function() return 0 end)
cli.def("InputValue", function() return 0 end)
local hitDist = 3
cli.def("QueryRaycast", function() return true, hitDist, { 0, 1, 0 }, 9 end)
cli.def("GetShapeBody", function() return 10 end)
cli.def("HasTag", function() return false end)
local pressed = false
cli.def("InputPressed", function(k) return pressed and k == "usetool" end)
cli.def("InputDown", function() return false end)
cli.QuatRotateQuat = function(a) return a end
cli.GetQuatEuler = function() return 0, 0, 0 end
cli.client.init()
cli.R["savegame.mod.player.money"] = 100
cli.shared.placer = { ["2"] = 502 }
cli.client.tick(1/60)
local function calls(fn) local n = 0 for _, s in ipairs(cli.sent) do if s.fn == fn then n = n + 1 end end return n end
check(calls("server.placerPreview") == 1 and cli.sent[1].args[1] == 2 and cli.sent[1].args[2] == 1 and cli.sent[1].args[3] == true
	and next(cli.violations) == nil, "place tool (client): preview pose sent for player 2")
cli.client.tick(1/60)
check(calls("server.placerPreview") == 1, "place tool (client): unchanged pose is not sent again")
pressed = true
cli.client.tick(1/60)
pressed = false
check(calls("server.placerPlace") == 1 and cli.R["savegame.mod.player.money"] == 90, "place tool (client): placing costs 10 (Armor Plate III)")
cli.R["savegame.mod.player.money"] = 5
pressed = true
cli.client.tick(1/60)
pressed = false
check(calls("server.placerPlace") == 1 and cli.R["savegame.mod.player.money"] == 5, "place tool (client): not enough money -> nothing placed")
hitDist = 50
cli.client.tick(1/60)
check(cli.sent[#cli.sent].fn == "server.placerPreview" and cli.sent[#cli.sent].args[3] == false, "place tool (client): out of reach -> preview hidden")
tool = "gun-ak74"
cli.client.tick(1/60)
local n = #cli.sent
cli.client.tick(1/60)
check(cli.sent[n].args[2] == 0 and #cli.sent == n, "place tool (client): tool put away -> preview dropped once")

print("all horde tests passed")

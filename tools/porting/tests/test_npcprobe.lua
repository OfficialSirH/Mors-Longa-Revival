-- Mock test for the debug "NPC sync readout" and "server sound test" (ui/NpcProbe.lua, 2026-11-15).
-- Run from the repo root with Lua 5.1:  lua5.1 tools/porting/tests/test_npcprobe.lua
dofile("tools/porting/tests/mockengine.lua")

local function check(cond, msg) if not cond then error("FAIL: " .. msg, 2) end print("ok  " .. msg) end

local env = MockEngine.load("ui/NpcProbe.lua")
env.PLAYERS = { [1] = { pos = { 0, 0, 0 }, health = 1 }, [2] = { pos = { 5, 0, 0 }, health = 1 } }
env.ORDER = { 1, 2 }
local POS = { [11] = { 3, 1.1, 0 }, [12] = { 40, 1.0, 0 }, [13] = { 8, 1.2, 0 } }
env.def("FindBodies", function(tag) return tag == "Torso" and { 11, 12, 13 } or {} end)
env.def("GetBodyTransform", function(h) return env.Transform(env.VecCopy(POS[h])) end)
local played = {}
env.def("PlaySound", function(s, pos) played[#played + 1] = pos end)

-- server (host)
env.side = "server"
env.NpcProbe_ServerInit()
env.server.npcProbeSoundTest()
check(#played == 2 and played[2][1] == 5, "sound test: one sound at each player")
env.R["savegame.mod.debug.npcprobe"] = true
env.T = 1
env.NpcProbe_ServerTick()
check(env.R["level.debug.npcprobe_on"] == true, "toggle published to every machine")
local s = env.R["level.debug.npcprobe"]
check(s and s:match("^1%.00|3|11,") and s:find(";13,") and s:find(";12,"), "nearest torsos first: " .. tostring(s))

-- a client: torso 11 lying (y 0.2), torso 13 unknown here
env.side = "client"
POS[11] = { 3, 0.2, 0 }
env.def("IsHandleValid", function(h) return h ~= 13 end)
env.def("HasTag", function(h, t) return t == "Torso" end)
env.NpcProbe_ClientTick()
local L = env.NP.lines
check(L[1]:find("server sees 3 torsos"), "header: " .. L[1])
check(L[2]:find("#11 torso") and L[2]:find("server y 1.10") and L[2]:find("here y 0.20") and L[2]:find("apart 0.90"), L[2])
check(L[3]:find("#13") and L[3]:find("NO SUCH BODY HERE"), L[3])
for n in pairs(env.violations) do error("FAIL: wrong-side call " .. n) end
print("all NPC probe tests passed")

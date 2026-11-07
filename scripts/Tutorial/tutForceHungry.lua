#version 2
-- (v2) client: hunger / thirst live in each player's own savegame (health runs on the client, Phase 2).
function client.init()
	SetInt('savegame.mod.hunger',100)
	SetInt('savegame.mod.thirst',100)
end
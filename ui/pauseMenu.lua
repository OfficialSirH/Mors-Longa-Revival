#version 2
#include "script/include/player.lua"
-- (v2) Only the host gets the button (it restarts the level for everyone).
-- Placement: the engine's pause menu (data/ui/hud.lua) draws "main_top" buttons above "Main menu" and one
-- v1-style primary button (game.pausemenu.primary) below it. The documented "main_bottom" is never drawn there,
-- so the v1 form PauseMenuButton(title, true) is used to keep the original position below "Main menu".
-- (Both earlier attempts used "main_bottom"; that alone explains why they never showed up.)
function client.tick()
	if IsPlayerHost() and PauseMenuButton("MorsLonga Menu", true) then
		ServerCall("server.startLevel")
	end
end

function server.startLevel()
	StartLevel("", "MOD/main.xml")
end

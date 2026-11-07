#version 2
#include "script/include/player.lua"
#include "menu_main.lua"

-- (v2) Entry script of the mod's main menu (main.xml, main_christmas.xml). The menu itself is client UI in
-- menu_main.lua (a library: ingame_settings.lua includes it too, for the in-game options window).
-- Starting a level goes through the host's server (menu_host.lua).

function client.init()
	MainMenu_Init()
end

function client.tick(dt)
	MainMenu_Tick()
end

function client.draw(dt)
	MainMenu_Draw(dt)
end

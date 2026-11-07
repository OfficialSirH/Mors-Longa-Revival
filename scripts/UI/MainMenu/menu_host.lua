-- (v2) Main menu helpers, included by menu_main.lua and menu_select_difficulty.lua.
-- StartLevel is server-only in v2: menu buttons (client UI) ask the server with ServerCall.
-- Only the host starts a game: the level reads the host's savegame (difficulty, game rules, perks), and a level
-- change takes every player along. Other players see the start buttons greyed out.

function MenuIsHost()
	return IsPlayerHost(GetLocalPlayer())
end

function MenuStartLevel(mission, path, layers)
	if not MenuIsHost() then return end
	ServerCall("server.startLevel", mission, path, layers or "")
end

function server.startLevel(mission, path, layers)
	StartLevel(mission, path, layers)
end

-- UiTextButton that only works for the host (greyed out for the others, like v1's disabled Continue)
function MenuHostButton(label, w, h)
	if MenuIsHost() then
		return UiTextButton(label, w, h)
	end
	UiPush()
	UiColor(1, 1, 1, 0.5)
	UiTextButton(label, w, h)
	UiPop()
	return false
end

function init_hitmarkers()
    Hitmarker_Icons = {} -- Stores references of active hitmarker.
    Hitmarker_Last_Pos = Vec(0,0,0)
end

function draw_hitmarkers()

	if GetString("savegame.mod.difficulty") == "hardcore" then
		return
	end

	if TimerConsumed(UI_Timers.hitmarker) then -- Draw while timer has time left.
		Hitmarker_Icons = {}
		return
	end

	local a = clamp(TimerGetProgress(UI_Timers.hitmarker), 0, 1)
	local icon = nil

	--todo use body reltaive pos.
	for index, icons_key in ipairs({ -- Order of importance.
		"headshot_dead",
		"hitmarker_dead",
		"shield",
		"headshot",
		"hitmarker",
	}) do
		if TableContainsValue(Hitmarker_Icons, Icons[icons_key]) then
			icon = Icons[icons_key]
			break
		end
	end

	if not icon then --no icon no draw
		return
	end

	UiPush()

	-- DrawCameraSprite(icon.path, Hitmarker_Last_Pos, 1,1, icon.color[1], icon.color[2], icon.color[3], false)

		local x,y = UiWorldToPixel(Hitmarker_Last_Pos)
		UiTranslate(x, y)

		-- UiColor(1,1,1, 1)
		UiFont("regular.ttf", 24)
		UiAlign("center middle")

		local icon_size = 50 - (30 / ((VecDist(GetCameraTransform().pos, Hitmarker_Last_Pos)) + 1))

		-- Draw center crosshair icons
		UiColor(icon.color[1],icon.color[2],icon.color[3], a) --idea image fade scaler thing.
		UiImageBox(icon.path, icon_size, icon_size)
		-- UiImageBox(icon.path, icon_size / a / 2, icon_size / a / 2)

	UiPop()

end

function add_hitmarker(icon)

	TimerResetTime(UI_Timers.hitmarker)

	--idea use body reltaive pos so hitmarker moves with hit location.
	-- Hitmarker_Last_Pos = Vec(
	--     GetFloat("level.goreai.body_damage_player_x"),
	--     GetFloat("level.goreai.body_damage_player_y"),
	--     GetFloat("level.goreai.body_damage_player_z"))

	table.insert(Hitmarker_Icons, icon)

end

--- (v2 goreai) server: remember which player damaged body b this tick (for the killcam).
--- Also kept for 0.3 s of game time in _player_damaged_recent: the hit is processed one tick before the npc counts
--- as dead, and _player_damaged is cleared every tick, so v1's same-tick check missed every single-shot kill
--- [verified in-game 2026-11-06: 6 deaths, 0 killcams].
function mark_body_damaged_by_player(b, p)
	Killcam_Data._player_damaged[b] = p or GoreHost
	Killcam_Data._player_damaged_recent[b] = { p = p or GoreHost, t = GetTime() }
end

--- (v2 goreai) client: the server says the local player hit an npc (client.goreHit in goreai_main.lua).
--- kind = "hit" | "headshot" | "kill" | "headshot_kill". This is v1's code from npc_process_shield / npc_die.
function hitmarker_receive(kind, pos)
	if GetString("savegame.mod.difficulty") == "hardcore" then return end -- no hitmarkers on hardcore (v1 draw rule)
	if pos then Hitmarker_Last_Pos = VecCopy(pos) end
	if kind == "hit" or kind == "headshot" then
		if TimerConsumed(Sound_Timers.hitmarker) then
			TimerResetTime(Sound_Timers.hitmarker)
			table.insert(Hitmarker_Sounds, { sound = Sounds.hitmarker, vol = 2 })
			if kind == "headshot" then
				table.insert(Hitmarker_Sounds, { sound = Sounds.hitmarker_headshot1, vol = 0.25 })
				table.insert(Hitmarker_Sounds, { sound = Sounds.hitmarker_headshot2, vol = 0.55 })
			end
		end
		add_hitmarker(Icons.hitmarker) -- New/latest hitmarker resets total hitmarker display time.
		if kind == "headshot" then add_hitmarker(Icons.headshot) end
	elseif GetTableSize(Hitmarker_Icons) >= 1 then -- v1: death markers only while a hit marker shows
		add_hitmarker(kind == "headshot_kill" and Icons.headshot_dead or Icons.hitmarker_dead)
	end
end

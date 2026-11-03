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

function mark_body_damaged_by_player(b)
	Killcam_Data._player_damaged[b] = true
end

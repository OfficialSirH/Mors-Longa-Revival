function init_controls()

	if IsHardcore then
		NPC_AIM_SWAY_MULT = NPC_AIM_SWAY_MULT * 0.8
	end

	Controls = {
		gunsway_speed  	= st_object_range("NPC Gun Sway Speed",		NPC_AIM_SWAY_SPEED, 	0, 3, 1/1000),
		gunsway  		= st_object_range("NPC Gun Sway Amount",	NPC_AIM_SWAY_MULT, 		0, 5, 1/100),
		hitchance  		= st_object_range("NPC Hit Chance", 		NPC_HIT_CHANCE, 	0, 1, 1/1000),
		distmin  		= st_object_range("NPC Aim Dist Min", 		NPC_AIM_SWAY_DIST_MIN, 	0, 40, 1/1000),
		distmax  		= st_object_range("NPC Aim Dist Max", 		NPC_AIM_SWAY_DIST_MAX, 	40, 120, 1/1000),

		f				= st_object_range("frequency", 0.93, -2, 2, 1/1000),
		r				= st_object_range("dampening", 0.94, -2, 2, 1/1000),
		d				= st_object_range("response", 0.17, -2, 2, 1/1000),
		t				= st_object_range("time", 0.07, 0, 0.5, 1/1000),
	}

	-- local path = "savegame.mod.goreai.debug.feetdata"
	-- FeetData = util.structured_table(path, {
	-- 	vel_mult		= { "number", 0.41 },
	-- 	velLength_mult	= { "number", 0.46 },
	-- 	stepLengthMin	= { "number", 0.14 },
	-- 	stepLengthMax	= { "number", 0.55 },
	-- 	stepTimeMult	= { "number", 0.80 },
	-- 	stepTimeMax		= { "number", 0.33 },
	-- 	stepHeightMult	= { "number", 0.87 },
	-- })

	local path = "savegame.mod.goreai.debug.feetdata"
	if not DebugMode then
		ClearKey(path)
	end
	FeetData = util.structured_table(path, {
		speed			= { "number", 1 },
		vel_mult		= { "number", 1.25 },
		velLength_mult	= { "number", 1 },
		stepLengthMin	= { "number", 0.2 },
		stepLengthMax	= { "number", 0.6 },
		stepTimeMult	= { "number", 1.75 },
		stepTimeMax		= { "number", 0.75 },
		stepHeightMult	= { "number", 0.6 },
	})

end

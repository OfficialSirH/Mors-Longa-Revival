UI_Timers = {
	hitmarker = TimerCreateSeconds(2/3, true)
}


Icons = {
	headshot_dead  = { path = "MOD/img/icon_headshot.png",  color = Vec(1,0,0),      center = false},
	hitmarker_dead = { path = "MOD/img/icon_hitmarker.png", color = Vec(1,0,0),      center = true},
	shield         = { path = "MOD/img/icon_shield.png",    color = Vec(0.3,0.3,1),  center = false},
	headshot       = { path = "MOD/img/icon_headshot.png",  color = Vec(1,1,1),      center = false},
	hitmarker      = { path = "MOD/img/icon_hitmarker.png", color = Vec(1,1,1),      center = true},
	-- kill           = { path = "MOD/img/icon_hitmarker.png", color = Vec(1,0,0),      center = true},
}


function npc_draw_healthbars(npc, validBoss)

	npc_draw_healthbar(npc, 25, -30)

	if npc.shield.value > 0 then
		npc_draw_shieldbar(npc, 25, -60)
	end

	if validBoss then
		npc_draw_boss(npc, -90)
	end

end

--idea Create tick function queue for draw to use.
-- function INSERT_DRAW_FUNCTION(func, tb_args, allow_duplicates)

--     if not DRAW_FUNCTIONS[func] and not allow_duplicates then
--         return -- Cancel insertion.
--     end

--     DRAW_FUNCTIONS[func] = { -- Not a duplicate.
--         func = func,
--         tb_args = tb_args or {}
--     }

-- end

-- function CALL_DRAW_FUNCTIONS(dont_clear_functions_table)

--     for index, func in pairs(DRAW_FUNCTIONS) do -- Run function
--         func.args = func.args or {}
--         func.func(unpack(func.args))
--     end

--     if not dont_clear_functions_table then -- Reset table.
--         DRAW_FUNCTIONS = {}
--     end

-- end

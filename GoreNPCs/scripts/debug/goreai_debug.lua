function debug_npcs()

	-- if GetBool("savegame.mod.config.db") then DebugWatch("#NPCs", GetTableSize(NPCs)) end

	npc_debug_feet()

	if SelectedNPC then
		local npc = SelectedNPC
		npc_draw_debug_text(npc)
		npc_draw_debug_combat(npc)
        npc_draw_debug_navigation(npc)
    end

	for index, npc in pairs(NPCs) do

        if npc.isValid and not npc.dead then
            UiPush()

				local pos = AabbGetBodyCenterPos(npc.Head)
				local validBoss = npc.boss.isBoss

				local valid_pos =
					IsInfrontOfTransform(GetCameraTransform(), pos)
					and QuatAngle(GetCameraTransform().rot, QuatLookAt(GetCameraTransform().pos, pos))
					and VecDist(pos, GetCameraTransform().pos) < 20

				if TransformToLocalPoint(GetCameraTransform(), pos)[3] < 0 then

					UiTranslate(UiWorldToPixel(pos))
					UiTranslate(0, -50)

					if config.goreai.pos_dot then
						npc_draw_debug_pos_dots(npc)
					end

					if config.goreai.healthbar_debug or (validBoss and valid_pos) then
						npc_draw_healthbars(npc, validBoss)
					end

					if config.goreai.outlines then
						npc_draw_outline(npc)
					end

					if config.goreai.text_debug then
						npc_draw_debug_text(npc)
					end

					if config.goreai.draw_debug then
						npc_draw_debug_navigation(npc)
					end

					if config.goreai.draw_combat then
						npc_draw_debug_combat(npc)
					end

					if config.goreai.draw_combat then
						npc_draw_debug_combat(npc)
					end

					if config.goreai.draw_bones then
						npc_debug_joints(npc)
					end

				end

            UiPop()
        end

    end


	if config.goreai.draw_projectile_impacts then
		npcs_debug_projectiles()
	else
		Debug_hitPositions_shapes = {} -- Clear all hit position data.
	end


end

--- Draw 3D debug information such as navigation points and look direction.
function npc_draw_debug_navigation(npc)

	local a = 0.5

	DebugLine(npc.torsoTr.pos, npc.ai.navPos, 0, 1, 1, a)

	DrawDot(npc.nav.target, 0.5, 0.5, 0, 1, 1, a)
	DrawDot(npc.ai.aimPos, 0.5, 0.5, 1, 1, 1, a)


	-- Draw navigation path
	if #npc.nav.path > 0 then

		-- path points and lines
		for i = 1, #npc.nav.path - 1 do
			DrawDot(npc.nav.path[i], 0.25, 0.25, 1, 0, 1, a, false)
			DebugLine(npc.nav.path[i], npc.nav.path[i + 1], 1, 0, 1, a)
		end

		DrawDot(npc.nav.path[#npc.nav.path], 0.25, 0.25, 1, 0, 1, a, false)
		DebugLine(npc.nav.path[#npc.nav.path], npc.nav.target, 1, 0, 1, a) -- last point to target pos

	end

	-- local armShape = GetBodyShapes(npc.R_ARM)[1]
	-- DrawDot(AabbGetShapeCenterBottomPos(armShape), 0.1,0.1, 1,1,0, a)

	-- -- Draw hand to gun.
	-- for index, hand in pairs(npc.hands) do
	-- 	DrawDot(npc_get_hand_pos(hand), 0.1,0.1, 1,1,1, 1, false)
	-- end


end

function npc_draw_debug_combat(npc)

	local a = 0.5

	if npc.Gun then

		local gunPos = GetBodyTransform(npc.Gun.body).pos
		local shootPos = npc.ai.shootPos -- Where the shot will be shot at.
		local dist = VecDist(gunPos, shootPos)

		DebugLine(gunPos, TransformToParentPoint(GetBodyTransform(npc.Gun.body), Vec(0,0, dist)), 1, 0.5, 0, a)
		DebugLine(gunPos, npc.ai.shootPosOffset, 0, 1, 0, a)

		-- Draw gun pos dots
		DrawDot(GetLightTransform(npc.Gun.handle).pos, 0.1,0.1, 1,0,0, a)
		DrawDot(gunPos, 0.1,0.1, 0,1,0, a)

		-- DebugLine(gunPos, npc.torsoPos, 1,1,0, a)

	end

end

--- Draw UI text list of npc status items.
function npc_draw_debug_text(npc)

		local fontSize = 18
		local marginH = fontSize

		UiPush()

			UiAlign("center bottom")
			UiFont("bold.ttf", fontSize)
			UiColor(1, 1, 1, 1)
			UiTextOutline(0, 0, 0, 1, 0.3)

			-- local camDir   = DirLookAt(GetPlayerCameraTransform().pos, TransformToParentPoint(GetPlayerCameraTransform(), Vec(0,0,-1)))
			-- local torsoDir = DirLookAt(GetPlayerCameraTransform().pos, torsoPos)

			local pos = GetBodyTransform(npc.Head).pos

			if not IsInfrontOfTransform(GetCameraTransform(), GetBodyTransform(npc.Head).pos) then
				return
			end

			local x,y = UiWorldToPixel(pos)
			UiTranslate(x, y)

			UiColor(0.7,0.7,0.7, 1)

			if npc.boss.isBoss then
				UiPush()
					UiTranslate(0, 100)
					UiColor(0.5,0.5,0.5, 1)
					UiText("Boss: ".. npc.boss.boss_preset.title)
				UiPop()
			end


			margin(0, -marginH)
			Text_Debug_Item("Ammo", 			npc.burstsize - npc.BulletsShot, -marginH)
			if npc.Gun then --##
				Text_Debug_Item("Weap", 		 	ternary(npc.Gun, npc.Gun.gun_path, "none"), -marginH)
			end

			margin(0, -marginH)
			Text_Debug_Item("Team", 			npc.ai.teams.team, -marginH)
			Text_Debug_Item("Type", 			ternary(npc.boss.isBoss, "Boss", "Regular"), -marginH)
			margin(0, -marginH)

			Text_Debug_Item("NAV", 				npc.ai.thinking.state, -marginH)
			Text_Debug_Item("DIST", 			npc.ai.thinking.states.dist, -marginH)
			Text_Debug_Item("ATTACK", 			npc.ai.thinking.states.shoot, -marginH)
			margin(0, -marginH)

			UiColor(1,1,1, 1)

			Text_Debug_Item("can_see", 						npc.ai.thinking.can_see, -marginH)
			Text_Debug_Item("seen_last", 					npc.ai.thinking.seen_last, -marginH)
			Text_Debug_Item("seen_time", 					npc.ai.thinking.seen_time, -marginH)
			Text_Debug_Item("target timer", 				npc.ai.targeting.recheck_timer.time, -marginH)
			Text_Debug_Item("gun blocked", 					npc.ai.thinking.attacking.blocked, -marginH)
			-- Text_Debug_Item("recheck_timer", 				npc.ai.targeting.recheck_timer.time, -marginH)

			margin(0, -marginH)

			Text_Debug_Item("Shoot angle valid", npc.ai.thinking.attacking.canShootAimPos, -marginH)
			if npc.ai.thinking.attacking.canShootAimPosLast then --##
				Text_Debug_Item("Shoot angle last valid", GetTime() - (npc.ai.thinking.attacking.canShootAimPosLast), -marginH)
			end
			-- Text_Debug_Item("See Timer", 		 npc.ai.timers.check_see_player.time, -marginH)
			margin(0, -marginH)

			-- Text_Debug_Item("Aggressive", 		npc.ai.thinking.positioning.aggressive, -marginH)
			-- Text_Debug_Item("agro_nav", 	 	npc.ai.timers.agro_nav.time, -marginH)
			-- Text_Debug_Item("agro_shoot", 		npc.ai.timers.agro_shoot.time, -marginH)

			margin(0, -marginH)

			-- Text_Debug_Item("Reposition", 				 npc.ai.timers.reposition.time, -marginH)

			margin(0, -marginH)

			-- Text_Debug_Item("Grenade time", 	 npc.ai.thinking.grenades.throwTime, -marginH)
			-- Text_Debug_Item("Grenade in range",  npc.ai.thinking.grenades.withinRange, -marginH)

			margin(0, -marginH)

			-- Text_Debug_Item("Spawn Tags", 		npc.ai.spawnTags_string, -marginH)
			-- Text_Debug_Item("Taking Cover", 	npc.ai.thinking.takingCover, -marginH)
			-- Text_Debug_Item("Cover Timer", 		npc.ai.thinking.coverTimer.time, -marginH)

			margin(0, -marginH)


		UiPop()

end

function npc_draw_debug_pos_dots(npc)

	local pos = AabbGetBodyCenterPos(npc.Head)
	if TransformToLocalPoint(GetCameraTransform(), pos)[3] < 0 then
		UiPush()

			UiTranslate(UiWorldToPixel(pos))
			UiAlign("center middle")

			if NpcTeamsEnabled and npc.ai.teams.team then

				local c = NPC_TEAMS[npc.ai.teams.team].color
				UiColor(c[1],c[2],c[3], 1)

			else

				UiColor(1/2, 1/2, 1/2, 1)

			end

			UiRect(10, 10)

		UiPop()
	end

end

function npc_draw_outline(npc)

	local c = NPC_TEAMS[npc.ai.teams.team].color
	UiColor(c[1],c[2],c[3], 1)

	for index, body in ipairs(npc.AllBodies) do
		DrawBodyOutline(body, c[1],c[2],c[3], 1/2)
	end

end

function npc_draw_healthbar(npc, height, offset)
	UiPush()

		local scale = VecDist(GetCameraTransform().pos, npc.torsoPos) / 10

		local width = 150
		UiTranslate(-width/2, offset)

		-- local title = sfn(npc.health or 0, 0) .. "/" .. npc.health_max
		local title = sfn(npc.health, 0) or npc.health
		local val = npc.health
		local max = npc.health_max
		local w = 150
		local h = height

		UiProgressBarTitled(title, val, max, w, h, 0,1,0, 0)

	UiPop()
end

function npc_draw_shieldbar(npc, height, offset)
	UiPush()

		local scale = VecDist(GetCameraTransform().pos, npc.torsoPos) / 10

		local width = npc.shield.max/1.3
		UiTranslate(-width/2, offset)

		local text = sfn(npc.shield.value, 0) .. "/" ..	sfn(npc.shield.max, 0)
		UiProgressBarTitled(text, npc.shield.value, npc.shield.max, width, height, 1/3, 1/3, 1, 0)

	UiPop()
end

function npc_debug_set_nav_poses(npc)

	if GetBool("savegame.mod.config.db") then

		if InputDown("pgdown") and InputDown("alt") then

			if InputPressed("pgdown") then -- shift + lmb to move to position
				local hit, pos = RaycastFromTransform(GetCameraTransform())
				if hit then
					npc_set_navigation_point(npc, pos)
					beep()
				end
			end

			-- if InputPressed("pgdown") then -- Look at position
			--     local hit, pos = RaycastFromTransform(GetCameraTransform())
			--     if hit then
			--         npc_RepositionNormal(npc, pos, 15)
			--         beep()
			--     end
			-- end

		end

	end

end

function npc_draw_boss(npc, offset)
	local pos = AabbGetBodyCenterPos(npc.Head)
	if TransformToLocalPoint(GetCameraTransform(), pos)[3] < 0 then
		UiPush()

			UiTranslate(UiWorldToPixel(pos), offset)
			UiAlign("center middle")

			-- if NpcTeamsEnabled then
			-- 	if npc.ai.teams.team == NPC_TEAMS.red then
			-- 		UiColor(1, 0, 0, 1)
			-- 	elseif npc.ai.teams.team == NPC_TEAMS.blue then
			-- 		UiColor(0, 0, 1, 1)
			-- 	end
			-- else
			-- 	UiColor(1, 1, 0, 1)
			-- end


			UiColor(1, 0, 0, 1)

			-- local osc = Oscillate(GetTime()/2)
			-- UiColor(1, osc, osc, 1)
			UiColor(1, 0, 0, 1)
			UiImageBox("MOD/img/icon_boss.png", 40,40)

		UiPop()
	end
end

function npc_draw_debug(npc, x,y, w,h)
	UiPush()

		UiColor(0,0,0, 1/2)
		-- UiRect(UiCenter()*0.6, UiHeight())

		local fs = 20
		UiFont("regular.ttf", fs)
		UiColor(1,1,1, 1)
		UiTextShadow(0.5,0.5,0.5, 1, 2)
		UiTranslate(x, y)

		-- UiProgressBarTitled(npc.ai.timers.check_see_player.time, npc.ai.timers.check_see_player.rpm, w,h, 1,1,0, 1)

	UiPop()
end

function DebugWatchNPC(npc, title, value)
    DebugWatch(table.concat({
            string_pad(npc.id, 3),
            string_pad("Team: ", 0),
            string_pad(npc.ai.teams.team, 4),
            string_pad(title, 15),
            -- string_pad("Gun: ", 0),
            -- string_pad(npc.gun_prefab_path, 20),
        }, " | "), value)
end

function npc_debug_feet()
UiPush()

	--todo-util - make a function for this kind of thing.
	ShowFeetData = ShowFeetData or false
	if DebugMode and InputDown("ctrl") and InputPressed("f") then
		ShowFeetData = not ShowFeetData
	end

	if not DebugMode then
		ShowFeetData = false
	end

	if ShowFeetData then

		UiMakeInteractive()

		uiSetFont(24)
		UiTranslate(20, 100)
		AutoContainer(500, 900)

		AutoSpreadDown()

			AutoText("speed = " .. sfn(FeetData.speed))
			FeetData.speed		 = 	AutoSlider(FeetData.speed,		0, 20, 0.1)

			AutoText("vel_mult = " .. sfn(FeetData.vel_mult))
			FeetData.vel_mult		 = 	AutoSlider(FeetData.vel_mult,		0, 2, 0.01)

			AutoText("velLength_mult = " .. sfn(FeetData.velLength_mult))
			FeetData.velLength_mult	 = 	AutoSlider(FeetData.velLength_mult,	0, 2, 0.01)

			AutoText("stepLengthMin = " .. sfn(FeetData.stepLengthMin))
			FeetData.stepLengthMin	 = 	AutoSlider(FeetData.stepLengthMin,	0, 2, 0.01)

			AutoText("stepLengthMax = " .. sfn(FeetData.stepLengthMax))
			FeetData.stepLengthMax	 = 	AutoSlider(FeetData.stepLengthMax,	0, 2, 0.01)

			AutoText("stepTimeMult = " .. sfn(FeetData.stepTimeMult))
			FeetData.stepTimeMult	 = 	AutoSlider(FeetData.stepTimeMult,	0, 2, 0.01)

			AutoText("stepTimeMax = " .. sfn(FeetData.stepTimeMax))
			FeetData.stepTimeMax	 = 	AutoSlider(FeetData.stepTimeMax,	0, 2, 0.01)

			AutoText("stepHeightMult = " .. sfn(FeetData.stepHeightMult))
			FeetData.stepHeightMult	 = 	AutoSlider(FeetData.stepHeightMult,	0, 2, 0.01)

			if	AutoButton("reset", 24) then
				ClearKey("savegame.mod.goreai.debug.feetdata")
				init_controls()
			end
		AutoSpreadEnd()

	end

UiPop()
end


---@param gunPos table From pos.
---@param shootPos table To pos.
---@param spacing number -- Arrow spacing.
---@param r number
---@param g number
---@param b number
---@param a number
---@param size number Size of a UI arrow.
---@param rate number Arrow animation flow rate.
function DrawArrowLine(gunPos, shootPos, spacing, r,g,b,a, size, rate)

	DebugLine(gunPos, shootPos, r,g,b,a)

	size = size or 25

	local dist = VecDist(gunPos, shootPos)
	local tr = vecs_to_tr(gunPos, shootPos)
	-- local phase = (rate * GetTime()) % 1
	-- local space_length = dist/spacing

	-- UiColor(r or 1, g or 1, b or 1, a or 1)
	UiColor(1,1,1, 1)

	for i = 1, dist do
		UiPush()

			local pos = TransformToParentPoint(tr, Vec(0,0, -i))
			-- local x,y = UiWorldToPixel(pos)
			-- UiTranslate(x, y)
			-- UiImageBox("common/arrow-left.png", size,size)
			-- UiRect(size,size)

			DrawDot(pos, 1,1, 1,1,1,1)

		UiPop()
	end

end



function npc_draw_debug_nav_api(npc)
	UiPush()
		local fs = 24
		uiSetFont(fs)
		UiTranslate(10, 100)

		UiText("npc.navigation.state = " .. tostring(npc.navigation.state))
		UiTranslate(0, fs)

		UiText("npc.navigation.hasNewTarget = " .. tostring(npc.navigation.hasNewTarget))
		UiTranslate(0, fs)

		UiText("npc.navigation.resultRetrieved = " .. tostring(npc.navigation.resultRetrieved))
		UiTranslate(0, fs)

		UiText("npc.navigation.thinkTime = " .. tostring(npc.navigation.thinkTime))
		UiTranslate(0, fs)

		UiText("npc.navigation.lastQueryTime = " .. tostring(npc.navigation.lastQueryTime))
		UiTranslate(0, fs)

		UiText("npc.navigation.timeSinceProgress = " .. tostring(npc.navigation.timeSinceProgress))
		UiTranslate(0, fs)

		UiText("npc.nav.path = " .. tostring(#npc.nav.path))
		UiTranslate(0, fs)

	UiPop()
end


function npc_debug_joints(npc)

	-- DrawBodyOutline(npc.Torso, 1,1,1, 1)

	for index, b in ipairs(npc.AllBodies) do
		for _, s in ipairs(GetBodyShapes(b)) do
			for _, j in ipairs(GetShapeJoints(s)) do

				local otherShape = GetJointOtherShape(j, s)
				if HasTag(otherShape, "bone") then
					DebugLine(AabbGetShapeCenterPos(otherShape), AabbGetShapeCenterPos(s), 1,1,1, 1)
				else
					DebugLine(AabbGetShapeCenterPos(otherShape), AabbGetShapeCenterPos(s), 1,0,0, 1)
				end

			end
		end
	end

	for index, s in ipairs(npc.bones) do
		DrawShapeOutline(s, 0,1,0, 1)
	end


end


function npcs_debug_projectiles()

    local positions_max = 50

    if #Debug_hitPositions_shapes > positions_max then
        table.remove(Debug_hitPositions_shapes, 1)
    end

    for index, data in ipairs(Debug_hitPositions_shapes) do

        data.sourcePos  = VecAdd(data.sourcePos, MapMoveVec)
        data.hitPos     = VecAdd(data.hitPos, MapMoveVec)

        -- local r = (GetTime() - data.time) / 10 -- fades to red over 10 seconds.
        local r = AutoMap(index, 1, #Debug_hitPositions_shapes, 0, 1)

        DebugLine(data.sourcePos, data.hitPos, 1, r, 0, 1)
        DebugCross(data.hitPos, 1, 0, 0, 1)

    end

end

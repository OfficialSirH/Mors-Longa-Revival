-- NPCs_SeatTaken = {}
SeatLightTag = "seat"

IsSeatingEnabled = true


function tick_sitting()

    SeatsTaken = {} -- light entities npcs are sitting at.

    if IsSeatingEnabled then
        for _, npc in pairs(NPCs) do
            if npc.ai.sitting.isSitting then
                table.insert(SeatsTaken, npc.ai.sitting.sitLight)
            end
        end
    end

end

function npc_sitting_process(npc)

    local v = GetPlayerVehicle(GoreP) -- (v2 goreai) target player
    local emptySeats = get_vehicle_empty_seats(v)

    local shouldEnterVehicle = VecDist(npc.torsoPos, PlayerPos) <= 5 and not npc.ai.sitting.isSitting and #emptySeats >= 1
    local shouldApproachVehicle = VecDist(npc.torsoPos, PlayerPos) > 5 and #emptySeats >= 1

    if shouldApproachVehicle then

        npc.ai.sitting.isSitting = false

        if #npc.nav.path >= 1 and VecDist(npc.nav.path[#npc.nav.path], PlayerPos) <= 5 then
            npc_run_to_target_pos(npc)
        else
            npc_set_navigation_point(npc, GetVehicleTransform(v).pos)
        end

    elseif shouldEnterVehicle then

        npc_sitting_enter_vehicle(npc, v, GetRandomArrayValue(emptySeats))

    end

    if npc.ai.sitting.isSitting then

        npc_clear_navigation(npc)
        npc.nav.target = VecCopy(npc.torsoPos)
        npc.ai.navPos = VecCopy(npc.torsoPos)

        if npc.ai.thinking.can_see and npc.ai.thinking.attacking.canShootAimPos then -- Will run and shoot if player is in line of sight.
            npc_shoot_target(npc)
        else
            npc_stop_attacking(npc)
        end

    end

end



function get_vehicle_seats(v)
    -- local emptySeats = {}
    -- for _, light in ipairs(GetVehicleLights(v, { SeatLightTag })) do
    --     if GetTagValue(light, SeatLightTag) == "" then -- tag does not have an npc id value.
    --         table.insert(emptySeats, light)
    --     end
    -- end
    -- return emptySeats
    return GetVehicleLights(v, { SeatLightTag })
end

function get_vehicle_empty_seats(v)
    local emptySeats = {}

    for _, seat in ipairs(get_vehicle_seats(v)) do
        if not TableContainsValue(SeatsTaken, seat) then
            table.insert(emptySeats, seat)
        end
    end

    return emptySeats
end



function npc_sitting_enter_vehicle(npc, v, seat_light)

    npc.ai.sitting.isSitting = true
    npc.ai.sitting.sitVehicle = v
    npc.ai.sitting.sitBody = GetVehicleBody(v)

    for _, s in ipairs(GetVehicleShapes(npc.ai.sitting.sitVehicle)) do
        SetShapeCollisionFilter(s, 8, 255-8)
    end

    for _, s in ipairs(npc.AllShapes) do -- restore normal collision groups
		if GetShapeBody(s) ~= GetWorldBody() then
			SetShapeCollisionFilter(s, 8, 255-8)
		end
	end

    npc.ai.sitting.sitLight = seat_light
    npc_sitting_enter_seat(npc, npc.ai.sitting.sitLight)

end

function npc_sitting_enter_seat(npc, light_seat)

    npc.ai.sitting.sitLight = light_seat
    TableInsertUnique(SeatsTaken, npc.ai.sitting.sitLight)

    PlaySound(GetRandomArrayValue(Sounds.seat), GetLightTransform(npc.ai.sitting.sitLight).pos, 0.5)

end

function npc_sitting_exit_vehicle(npc)

    npc_sitting_exit_seat(npc)

    npc.ai.sitting.isSitting = false
    npc.ai.sitting.sitVehicle = 0
    npc.ai.sitting.sitBody = 0

end

function npc_sitting_exit_seat(npc)

    local exit_pos = get_vehicle_exit_pos(npc.ai.sitting.sitVehicle, GetLightTransform(npc.ai.sitting.sitLight).pos)
    npc_move_to_pos(npc, exit_pos)

    if npc.ai.sitting.sitVehicle then
        local vehVel = GetBodyVelocity(GetVehicleBody(npc.ai.sitting.sitVehicle))
        if VecLength(vehVel) > npc.ai.stun.velocity then
            npc.ai.stun.duration = 3
            for index, body in ipairs(npc.AllBodies) do
                local bodyTr = GetBodyTransform(body)
                bodyTr.pos = VecAdd(bodyTr.pos, Vec(0,1,0))
                SetBodyTransform(body, bodyTr)
                SetBodyVelocity(body, vehVel)
            end
        else
            npc.ai.stun.duration = 0
        end
    end

    for _, shape in ipairs(npc.AllShapes) do -- restore normal collision groups
		if GetShapeBody(shape) ~= GetWorldBody() then
			SetShapeCollisionFilter(shape, 4, 255-4)
		end
	end

    TableRemoveUniqueValue(SeatsTaken, npc.ai.sitting.sitLight)
    npc.ai.sitting.sitLight = 0
end

function get_vehicle_exit_pos(v, seat_pos)

    local x = GetVehicleDimensions(v)
    local vehicleCenterPos = AabbGetBodyCenterPos(GetVehicleBody(v))
    local vTr = Transform(vehicleCenterPos, GetVehicleTransform(v).rot)
    local posSide = TransformToLocalPoint(vTr, seat_pos)[1]
    local side = ternary(posSide >= 0, 1, -1)
    local seatRelativePosZ = TransformToLocalPoint(vTr, seat_pos)[3]

    -- local exit_pos = TransformToParentPoint(vTr, Vec(side*(x/2),0,seatRelativePosZ))
    local exit_pos = TransformToParentPoint(vTr, Vec(side*3,1,seatRelativePosZ))
    exit_pos = truncateToGround(exit_pos) or exit_pos

    return exit_pos

end



function draw_vehicle_empty_seats(v)
	UiPush()
		local seats_lights = get_vehicle_seats(v)
		for _, seat_light in ipairs(seats_lights) do
			local seat_pos = GetLightTransform(seat_light).pos
			if IsInfrontOfCamera(seat_pos) then
				UiPush()

					UiTranslate(UiWorldToPixel(seat_pos))
					UiAlign("center middle")

					local s = 30
					UiColor(0,0,0, 0.5)
					UiImageBox("ui/common/box-solid-6.png", s,s, 6,6)
					if TableContainsValue(SeatsTaken or {}, seat_light) then -- (v2) SeatsTaken is server state (host only)
						UiColor(1, 0, 0, 1)
					else
						UiColor(0, 1, 0, 1)
					end
					UiImageBox("MOD/img/icon_person.png", s * 0.8, s * 0.8)

				UiPop()
			end
		end
	UiPop()
end

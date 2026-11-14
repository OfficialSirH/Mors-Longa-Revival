-- (v2) NPC seating, hand-written (Phase 4, 2026-11-08; no longer patched by convert_goreai.py).
-- v1: friendly NPCs sat in invisible lights tagged "seat" that only Vehiclewg30 had. v2: they use the vehicle's
-- passenger seat rigs (<rig name="passenger"> with a "seat" location, added per vehicle by
-- tools/porting/add_seats.py), the same seats players use. Players come first: an NPC never picks a seat
-- a player sits in, and an NPC whose seat a player takes moves to another free seat or gets out.
-- npc.ai.sitting.sitLight now holds the seat's rig handle (name kept: goreai_health/_manage use it).
-- Server: everything except draw_vehicle_empty_seats. Client: draw_vehicle_empty_seats, from shared.goreSeats.

SeatLightTag = "seat" -- (v1 name) the rig location the seat is read from
SeatHeadOffset = { 0, 0.65, 0.1 } -- (a Vec; no API calls at load time) the sit pose is placed by the head: 0.65 m
                                   -- above the seated player's pelvis (v1 seat light height) and 0.1 m back (+z) so the
                                   -- NPC's back touches the backrest (Humvee in-game check 2026-11-08: one voxel gap at
                                   -- 0); in the player's body frame, so it leans with the seat

IsSeatingEnabled = true

SeatsTaken = {} -- rig handles NPCs are sitting in (server)


-- ---------------------------------------------------------------- seats

--- Passenger seat rigs of vehicle v (driver and "floor" rigs excluded), in their sort order. Server and client.
function get_vehicle_seats(v)
    local seats = {}
    if not v or v == 0 then return seats end
    local rigs = GetEntityChildren(v, "", true, "rig") or {}
    if #rigs == 0 then -- fallback in case rigs are not children of the vehicle entity
        for _, r in ipairs(FindEntities("", true, "rig") or {}) do
            if GetEntityParent(r, "", "vehicle") == v then rigs[#rigs + 1] = r end
        end
    end
    for _, r in ipairs(rigs) do
        -- "floor" rigs (players sitting on a cargo floor, add_seats.py) do not fit the NPC sit pose
        if not HasTag(r, "driver") and not HasTag(r, "floor") and GetRigLocationWorldTransform(r, SeatLightTag) ~= nil then
            seats[#seats + 1] = r
        end
    end
    table.sort(seats, function(a, b)
        return (tonumber(GetTagValue(a, "sort")) or 99) < (tonumber(GetTagValue(b, "sort")) or 99)
    end)
    return seats
end

--- Set of rig handles players sit in.
function get_player_seats()
    local taken = {}
    for p in Players() do
        local r = GetPlayerRig(p)
        if r ~= 0 then taken[r] = true end
    end
    return taken
end

function get_vehicle_empty_seats(v)
    local emptySeats = {}
    local players = get_player_seats()
    for _, seat in ipairs(get_vehicle_seats(v)) do
        if not players[seat] and not TableContainsValue(SeatsTaken, seat) then
            table.insert(emptySeats, seat)
        end
    end
    return emptySeats
end

SeatPelvis = { 0, 0.875, 0.05 } -- player character's pelvis above its animator root (player_sven_lagom.xml)

--- The seated player's body frame on this seat (pelvis point, body rotation), as the engine computes it
--- (data/script/player_locomotion.lua): pelvis on the seat point, the seat's rotation, eased toward upright by
--- weight up.y^2 about a pivot 0.8 m above the animator root (seat rot x 55 -> ~37 deg lean, 80 -> ~78 deg).
function get_seat_body_transform(seat)
    local t = GetRigLocationWorldTransform(seat, SeatLightTag)
    if t == nil then return nil end
    local rot, pelvis = t.rot, t.pos
    local up = QuatRotateVec(rot, Vec(0, 1, 0))
    if up[2] > 0 then
        local off = Vec(SeatPelvis[1], SeatPelvis[2], SeatPelvis[3])
        local pivot = VecAdd(VecSub(pelvis, QuatRotateVec(rot, off)), QuatRotateVec(rot, Vec(0, 0.8, 0)))
        local rot2 = QuatSlerp(rot, QuatRotateQuat(QuatDeltaVectors(up, Vec(0, 1, 0)), rot), up[2] * up[2])
        pelvis = VecAdd(VecSub(pivot, QuatRotateVec(rot2, Vec(0, 0.8, 0))), QuatRotateVec(rot2, off))
        rot = rot2
    end
    return Transform(pelvis, rot)
end

SeatHeadAim = { 0, -0.15, -0.05 } -- NPC head point relative to the rig's ik_head (rig frame): our own layouts put
                                   -- ik_head 0.8 m above and 0.15 m behind the seat point, which this maps onto the
                                   -- upright head position checked in-game (Humvee, UAZ, GAZ)

--- World transform of a seat's head point (what the sit pose is placed by). The NPC sits like the player:
--- * hips at the seated player's pelvis (get_seat_body_transform) + (0, 0.05, 0.1), the offset that matched the
---   player on every upright seat checked in-game (Humvee, UAZ, GAZ rear, SUV);
--- * with an ik_head location, the engine bends the player's spine so the head reaches it (player_locomotion.lua
---   SetAnimatorTransformIK "stomach".."head"): reclined official seats (rot x 70-80) still look nearly upright
---   in-game. The NPC (rigid) leans about the hips toward ik_head + SeatHeadAim: upright on our layouts, ~7 deg on
---   the saloon, ~27 deg on the sports car;
--- * without ik_head the player's whole body leans with the (eased) seat rotation, and so does the NPC.
function get_seat_head_transform(seat)
    local b = get_seat_body_transform(seat)
    if b == nil then return nil end
    local rt = GetRigWorldTransform(seat)
    local ik = GetRigLocationWorldTransform(seat, "ik_head")
    if ik ~= nil and rt ~= nil then
        local hip = VecAdd(b.pos, QuatRotateVec(rt.rot, Vec(0, SeatHeadOffset[2] - 0.6, SeatHeadOffset[3])))
        local aim = VecAdd(ik.pos, QuatRotateVec(rt.rot, Vec(SeatHeadAim[1], SeatHeadAim[2], SeatHeadAim[3])))
        local d = TransformToLocalVec(rt, VecSub(aim, hip))
        local lean = math.max(0, math.deg(math.atan2(d[3], d[2]))) -- leaning back only
        local rot = QuatRotateQuat(rt.rot, QuatEuler(lean, 0, 0))
        return Transform(VecAdd(hip, QuatRotateVec(rot, Vec(0, 0.6, 0))), rot)
    end
    return Transform(TransformToParentPoint(b, SeatHeadOffset), b.rot)
end

--- RagdollPoses.sit adapted to the seat: head, torso and arms lean with the body; the legs keep the sit pose from
--- the same hip but stay with the vehicle, tilted up only as far as needed to point the feet at the seat's foot
--- points (ik_foot_l/r, where the player's feet go), at most 60 deg. Seats where the NPC sits upright: unchanged.
local LegKeys = { "LLEG", "LLLEG", "RLEG", "RRLEG" }
function npc_sitting_pose(npc)
    local sit = RagdollPoses.sit
    local seat = npc.ai.sitting.sitLight
    local head = get_seat_head_transform(seat)
    local rt = GetRigWorldTransform(seat)
    if head == nil or rt == nil then return sit end
    local lean = math.deg(math.acos(math.min(1, VecDot(QuatRotateVec(head.rot, Vec(0, 1, 0)), QuatRotateVec(rt.rot, Vec(0, 1, 0))))))
    if lean < 1 then return sit end
    local hip = TransformToParentPoint(head, Vec(0, -0.6, 0))
    local tilt = 0
    local fl = GetRigLocationWorldTransform(seat, "ik_foot_l")
    local fr = GetRigLocationWorldTransform(seat, "ik_foot_r")
    if fl or fr then
        local foot = (fl and fr) and VecLerp(fl.pos, fr.pos, 0.5) or (fl or fr).pos
        local d = TransformToLocalVec(rt, VecSub(foot, hip))
        -- feet of the sit pose: 0.45 m below and 0.35 m in front of the hip (angle below forward ~52 deg)
        tilt = math.deg(math.atan2(0.45, 0.35) - math.atan2(-d[2], -d[3]))
        tilt = math.max(0, math.min(60, tilt)) -- sports car: hips at floor level, legs go forward (~56 deg)
    end
    local legRot = QuatRotateQuat(rt.rot, QuatEuler(tilt, 0, 0))
    local legHead = Transform(VecAdd(hip, QuatRotateVec(legRot, Vec(0, 0.6, 0))), legRot)
    local pose = {}
    for k, v in pairs(sit) do pose[k] = v end
    for _, k in ipairs(LegKeys) do
        pose[k] = TransformToLocalTransform(head, TransformToParentTransform(legHead, sit[k]))
    end
    return pose
end

--- Head transform for a sitting npc (goreai_manage.lua poses the ragdoll with it).
function npc_sitting_head_transform(npc)
    return get_seat_head_transform(npc.ai.sitting.sitLight) or GetBodyTransform(npc.Head)
end


-- ---------------------------------------------------------------- server

function tick_sitting()

    SeatsTaken = {}

    if IsSeatingEnabled then
        for _, npc in pairs(NPCs) do
            if npc.ai.sitting.isSitting then
                table.insert(SeatsTaken, npc.ai.sitting.sitLight)
            end
        end

        -- players win: move NPCs out of seats a player took (or that no longer exist)
        local players = get_player_seats()
        for _, npc in pairs(NPCs) do
            local sit = npc.ai.sitting
            if sit.isSitting and (players[sit.sitLight] or get_seat_head_transform(sit.sitLight) == nil) then
                TableRemoveUniqueValue(SeatsTaken, sit.sitLight)
                local free = get_vehicle_empty_seats(sit.sitVehicle)
                if #free >= 1 and get_seat_head_transform(sit.sitLight) ~= nil then
                    npc_sitting_enter_seat(npc, free[1])
                else
                    npc_sitting_exit_vehicle(npc)
                end
            end
        end
    end

    publish_seats()

end

--- shared.goreSeats: [tostring(rig)] = true for seats NPCs sit in; shared.goreSeatsShow: friendly NPCs exist
--- (the clients draw the seat icons only then). Written only on change.
function publish_seats()
    local friendly = false
    for _, npc in pairs(NPCs) do
        if npc.isFriendly and not npc.dead then friendly = true break end
    end
    local sig = friendly and "1" or "0"
    local keys = {}
    for _, seat in ipairs(SeatsTaken) do keys[#keys + 1] = tostring(seat) end
    table.sort(keys)
    sig = sig .. table.concat(keys, ",")
    if sig == SeatsSig then return end
    SeatsSig = sig
    local t = {}
    for _, k in ipairs(keys) do t[k] = true end
    shared.goreSeats = t
    shared.goreSeatsShow = friendly
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

function npc_sitting_enter_vehicle(npc, v, seat)

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

    npc_sitting_enter_seat(npc, seat)

end

function npc_sitting_enter_seat(npc, seat)

    npc.ai.sitting.sitLight = seat
    TableInsertUnique(SeatsTaken, seat)

    local head = get_seat_head_transform(seat)
    if head then PlaySound(GetRandomArrayValue(Sounds.seat), head.pos, 0.5) end

end

function npc_sitting_exit_vehicle(npc)

    npc_sitting_exit_seat(npc)

    npc.ai.sitting.isSitting = false
    npc.ai.sitting.sitVehicle = 0
    npc.ai.sitting.sitBody = 0

end

function npc_sitting_exit_seat(npc)

    local head = get_seat_head_transform(npc.ai.sitting.sitLight)
    local seat_pos = head and head.pos or GetBodyTransform(npc.Head).pos
    if npc.ai.sitting.sitVehicle ~= 0 and IsHandleValid(npc.ai.sitting.sitVehicle) then
        npc_move_to_pos(npc, get_vehicle_exit_pos(npc.ai.sitting.sitVehicle, seat_pos))
    end

    if npc.ai.sitting.sitVehicle ~= 0 and IsHandleValid(npc.ai.sitting.sitVehicle) then
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


-- ---------------------------------------------------------------- client

--- Seat icons over the local player's vehicle while friendly NPCs exist: green free, red taken (player or NPC).
function draw_vehicle_empty_seats(v)
    if not shared.goreSeatsShow then return end
    local npcSeats = shared.goreSeats or {}
    local players = get_player_seats()
	UiPush()
		for _, seat in ipairs(get_vehicle_seats(v)) do
			local head = get_seat_head_transform(seat)
			if head and IsInfrontOfCamera(head.pos) then
				UiPush()

					UiTranslate(UiWorldToPixel(head.pos))
					UiAlign("center middle")

					local s = 30
					UiColor(0,0,0, 0.5)
					UiImageBox("ui/common/box-solid-6.png", s,s, 6,6)
					if players[seat] or npcSeats[tostring(seat)] then
						UiColor(1, 0, 0, 1)
					else
						UiColor(0, 1, 0, 1)
					end
					UiImageBox("MOD/assets/img/icon_person.png", s * 0.8, s * 0.8)

				UiPop()
			end
		end
	UiPop()
end

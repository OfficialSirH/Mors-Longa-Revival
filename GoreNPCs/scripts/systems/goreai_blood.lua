BloodDrops = {}
BloodEmitters = {}


local Max_BloodDrops = 200


-- Manage blood drops and blood emitters.
function tick_blood()

    -- Remove oldest blood drop.
    if #BloodDrops > Max_BloodDrops then

        Delete(BloodDrops[1])
        table.remove(BloodDrops, 1)

        if #BloodDrops > Max_BloodDrops * 1.5 then
            Delete(BloodDrops[1])
            table.remove(BloodDrops, 1)
        end

    end

    local remove_emitters = {}
    for index, be in pairs(BloodEmitters) do

        if not IsHandleValid(be.body) then
            table.insert(remove_emitters, index)
        end

        local rel_tr = TransformToParentTransform(GetBodyTransform(be.body), be.rel_tr)
        rel_tr.pos = VecAdd(rel_tr.pos, VecRandom(0.1))

        if be.drops_emitted >= be.drops_count or not IsHandleValid(be.body) then -- Remove finished emitter.

            table.insert(remove_emitters, index)

        else -- Run emitter

            be.emit_time = be.emit_time + GetTimeStep()

            if be.emit_time > RandomSpreadPercent25(be.emit_rate) then

                be.emit_time = 0

                for i = 1, 2 do
                    blood_drop_create(rel_tr, be.vel, be.spread)
                    be.drops_emitted = be.drops_emitted + 1
                end

            end

            -- PlayLoop(Loops.blood_pouring1, rel_tr.pos, 1)

        end

    end

    -- Safely delete emitters.
    for _, be_index in pairs(remove_emitters) do
        BloodEmitters[be_index] = nil
    end

end


--todo fix floating blood spawn
function blood_drop_create(tr, vel, spread)

    local blood_prefab = '<body dynamic="true"><voxbox density="3" size="1 1 1" color="0.29 0.02 0.02"/><voxbox rot="180 180 180" density="3" size="1 1 1" color="0.29 0.02 0.02"/></body>'

    local rot = QuatEuler(math.random(0,360),math.random(0,360),math.random(0,360))
    local entities = Spawn(blood_prefab, Transform(tr.pos, rot), false, false)

    local vel_spread = VecRandom(spread)
    local blood_vel = VecAdd(VecScale(QuatToDir(tr.rot), vel), vel_spread)
    SetBodyVelocity(body, blood_vel) -- Make that bitch squirt.

    table.insert(BloodDrops, entities[1])

end


--- Blood will spray relative to a body for a number of drops at a specific rate.
function blood_emitter_create(body, tr, vel, spread, drop_rate, drops_count, pressurized)

    local be = {

        body = body,
        rel_tr = TransformToLocalTransform(GetBodyTransform(body), tr),
        vel = vel,
        spread = spread,

        drops_count = drops_count or 20,
        emit_rate = drop_rate or (1/4),
        emit_time = 0,
        drops_emitted = 0,
        pressurized = pressurized or false,

    }


    table.insert(BloodEmitters, be)

end

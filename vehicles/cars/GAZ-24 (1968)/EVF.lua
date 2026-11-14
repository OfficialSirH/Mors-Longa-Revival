#version 2
#include "script/include/player.lua"
-- (v2) SERVER: GAZ-24 doors / hood / trunk latches (free while ANY player grabs them, latched shut when let go, open /
-- close sounds), hinged steering wheel from the DRIVER's left/right, door-open beep while any player is inside.
-- v1 used the host's grab and input. Parameters read in init (v2: no API calls at load time). Hand-converted 2026-11-09.
--script version 1.1
doorvolume = 0.4                                                                --if you reading this, get ready for yanderecode

-- (v2) the player driving vehicle (passengers ride too but must not steer), or nil
function VehicleDriver(vehicle)
    if vehicle == 0 then return nil end
    for p in Players() do
        if IsPlayerVehicleDriver(vehicle, p) then return p end
    end
    return nil
end

function AnyPlayerInside(vehicle)
    if vehicle == 0 then return false end
    for p in Players() do
        if GetPlayerVehicle(p) == vehicle then return true end
    end
    return false
end

-- (v2) v1: GetPlayerGrabShape() == shape or GetPlayerGrabBody() == body (the host)
function AnyPlayerGrabs(shape, body)
    for p in Players() do
        if GetPlayerGrabShape(p) == shape or GetPlayerGrabBody(p) == body then return true end
    end
    return false
end
function indexshapes()
    local doors = FindShapes("door")
    d1 = doors[1]
    d2 = doors[2]
    d3 = doors[3]
    d4 = doors[4]
    d5 = doors[5]
    d6 = doors[6]
    ho = FindShape("hood")
    tr = FindShape("trunk")
    --[[local mirrors = FindShapes("mirror")
    ml = mirrors[1]
    mr = mirrors[2]
    if mr == nil or ml == nil then
        fold = false
    else
        fold = true
    end]]--
    steer = FindShape("steer")
    veh = FindVehicle("vehicle")
    d1_valid = IsHandleValid(d1)
    d2_valid = IsHandleValid(d2)
    d3_valid = IsHandleValid(d3)
    d4_valid = IsHandleValid(d4)
    d5_valid = IsHandleValid(d5)
    d6_valid = IsHandleValid(d6)
    ho_valid = IsHandleValid(ho)
    tr_valid = IsHandleValid(tr)
end

function indexjoints(shape, ID)
    local joints = GetShapeJoints(shape)
    local ID
    if shape == ho then
        ho_j = joints[1]
        ID = 7
    elseif shape == tr then
        tr_j = joints[1]
        ID = 8
    elseif shape == d1 then
        d1_j = joints[1]
        ID = 1
    elseif shape == d2 then
        d2_j = joints[1]
        ID = 2
    elseif shape == d3 then
        d3_j = joints[1]
        ID = 3
    elseif shape == d4 then
        d4_j = joints[1]
        ID = 4
    elseif shape == d5 then
        d5_j = joints[1]
        ID = 5
    elseif shape == d6 then
        d6_j = joints[1]
        ID = 6
    elseif shape == ml then
        ml_j = joints[1]
    elseif shape == mr then
        mr_j = joints[1]
    elseif shape == steer then
        steer_j = joints[1]
    end
end

function GenerateSoundTable(ID)
    if ID ~= nil then
        if ID ~= 7 or ID ~= 8 then
            played[ID] = {
                ["played1o"] = false,
                ["played2o"] = true,
                ["playedc"] = true,
                ["open"] = false
            }
        else
            played[ID] = {
                ["played1o"] = false,
                ["played2o"] = true,
                ["played3o"] = true,
                ["playedc"] = true,
                ["open"] = false
            }
        end
    end
end

function server.init()
    beep = GetBoolParam("doornotification")
    trunklift = GetBoolParam("trunklift")
    hoodlift = GetBoolParam("hoodlift")
    sounddir = GetStringParam("sounddir")
    if sounddir == "" then
        sounddir = "MOD/vehicles/cars/GAZ-24 (1968)/EVF/snd"
    end
    doorbeep = LoadLoop(sounddir .. "/doorbeep.ogg") -- (v2 note) the file never shipped; the beep stays off (no XML sets "doornotification")
    door_o1 = LoadSound(sounddir .. "/door_o1.ogg")
    door_o2 = LoadSound(sounddir .. "/door_o2.ogg")
    door_c = LoadSound(sounddir .. "/door_c.ogg")
    hood_o = LoadSound(sounddir .. "/hood_o.ogg")
    hood_o1 = LoadSound(sounddir .. "/hood_o1.ogg")
    hood_c = LoadSound(sounddir .. "/hood_c.ogg")
    trunk_o1 = LoadSound(sounddir .. "/trunk_o1.ogg")
    trunk_o2 = LoadSound(sounddir .. "/trunk_o2.ogg")
    trunk_c = LoadSound(sounddir .. "/trunk_c.ogg")
    hood_lift_loop = LoadLoop(sounddir .. "/hood_lift_loop.ogg")
    indexshapes()
    played = {}
    indexjoints(ho)
    indexjoints(tr)
    indexjoints(d1)
    indexjoints(d2)
    indexjoints(d3)
    indexjoints(d4)
    indexjoints(d5)
    indexjoints(d6)
    for i = 1, 8 do
        GenerateSoundTable(i)
    end
    --[[indexjoints(ml)
    indexjoints(mr)]]--
    indexjoints(steer)
end

function doorlatchsystem(shape, joint, ID)
    if not IsJointBroken(joint) then
        local a = GetJointMovement(joint)
        local body1 = GetShapeBody(shape)
        local grabbed = AnyPlayerGrabs(shape, body1)
        local pos = GetShapeWorldTransform(shape).pos
        if not IsJointBroken(joint) then
            if grabbed then
                SetJointMotor(joint, 0, 0)
                if not played[ID]["played1o"] and a >= 0.06 then
                    played[ID]["played1o"] = true
                    played[ID]["played2o"] = false
                    PlaySound(door_o1, pos, doorvolume)
                end
            else
                if not played[ID]["played2o"] then
                    played[ID]["played2o"] = true
                    played[ID]["playedc"] = false
                    PlaySound(door_o2, pos, doorvolume)
                end
                if a <= 0.05 then
                    SetJointMotorTarget(joint, 0)
                    played[ID]["open"] = false
                    if not played[ID]["playedc"] then
                        played[ID]["playedc"] = true
                        played[ID]["played1o"] = false
                        PlaySound(door_c, pos, doorvolume)
                    end
                end
                if a >= 0.2 then
                    played[ID]["open"] = true
                end
            end
        end
    end
end

function hoodlatchsystem(shape, joint, ID, sound_o1, sound_c, lift, sound_o2)
    if not IsJointBroken(joint) then
        local a = GetJointMovement(joint)
        local body1 = GetShapeBody(shape)
        local grabbed = AnyPlayerGrabs(shape, body1)
        local pos = GetShapeWorldTransform(shape).pos
        local min, max = GetJointLimits(joint)
        local b = max / 2 - 15
        local c = max - 0.2
        if grabbed then
            SetJointMotor(joint, 0, 0)
            played[ID]["open"] = true
            if not played[ID]["played1o"] and a >= 0.06 then
                played[ID]["played1o"] = true
                played[ID]["playedc"] = false
                played[ID]["played3o"] = false
                played[ID]["played2o"] = false
                PlaySound(sound_o1, pos, doorvolume)
            end
        else
            if sound_o2 ~= nil then
                if not played[ID]["played2o"] then
                    played[ID]["played2o"] = true
                    PlaySound(sound_o2, pos, doorvolume)
                end
            end
            if played[ID]["open"] then
                if lift then
                    if a >= b then
                        SetJointMotorTarget(joint, max, 0.5)
                        if not played[ID]["played3o"] then
                            PlayLoop(hood_lift_loop, pos, doorvolume)
                        end
                    else
                        SetJointMotor(joint, 0, 0)
                    end
                else
                    if a >= c then
                        SetJointMotorTarget(joint, max, 0.5)
                    else
                        SetJointMotor(joint, 0, 0)
                    end
                end
            end
            if a <= 0.05 then
                SetJointMotorTarget(joint, 0)
                played[ID]["open"] = false
                if not played[ID]["playedc"] then
                    PlaySound(sound_c, pos, doorvolume)
                    played[ID]["playedc"] = true
                    played[ID]["played1o"] = false
                end
            end
            if a >= c then
                if not played[ID]["played3o"] then
                    played[ID]["played3o"] = true
                    PlaySound(hood_o1, pos, doorvolume)
                end
            else
                played[ID]["played3o"] = false
            end
        end
    end
end

function server.update(dt)
    local driver = VehicleDriver(veh)
    if AnyPlayerInside(veh) then
        -- (v2) v1 swung the wheel to +-130 deg from the keys; the driver's hands turn with GetVehicleSteering x 180
        -- (data/script/player_locomotion.lua), less than that (user, 2026-11-09). The wheel now follows the same
        -- value. Sign: v1 turned the joint positive for "left"; the first time the driver holds left with the
        -- steering away from zero, the sign of GetVehicleSteering for "left" is recorded (LeftSign).
        if driver then
            local s = GetVehicleSteering(veh)
            if InputDown("left", driver) and math.abs(s) > 0.05 then
                LeftSign = s > 0 and 1 or -1
            end
            SetJointMotorTarget(steer_j, s * 180 * (LeftSign or -1), 4.5)
        else
            SetJointMotorTarget(steer_j, 0, 4.5)
        end
        --[[if fold then
            SetJointMotorTarget(ml_j, 0, 1.5)
            SetJointMotorTarget(mr_j, 0, 1.5)
        end]]--
        if beep then
            local pos = GetVehicleTransform(veh).pos
            if played[1]["open"] or played[2]["open"] or played[3]["open"] or played[4]["open"] or played[5]["open"] or played[6]["open"] then
                PlayLoop(doorbeep, pos, doorvolume)
            end
        end
    else
        SetJointMotorTarget(steer_j, 0, 4.5)
        --[[if fold then
            SetJointMotorTarget(ml_j, -90, 1.5)
            SetJointMotorTarget(mr_j, 90, 1.5)
        end]]--
    end
    if d1_valid then
        doorlatchsystem(d1,d1_j,1)
    end
    if d2_valid then
        doorlatchsystem(d2,d2_j,2)
    end
    if d3_valid then
        doorlatchsystem(d3,d3_j,3)
    end
    if d4_valid then
        doorlatchsystem(d4,d4_j,4)
    end
    if d5_valid then
        doorlatchsystem(d5,d5_j,5)
    end
    if d6_valid then
        doorlatchsystem(d6,d6_j,6)
    end
    if ho_valid then
        hoodlatchsystem(ho,ho_j,7,hood_o, hood_c, hoodlift)
    end
    if tr_valid then
        hoodlatchsystem(tr,tr_j,8,trunk_o1, trunk_c, trunklift, trunk_o2)
    end
end
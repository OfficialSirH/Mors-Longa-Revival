function init()
    --[[
    Options for door:

    OpenTarget: Where the door moves to when it is opened.
    ClosedTarget: Where the door moves to when it is closed.
    CloseSpeed: How fast the door moves when closing.
    OpenSpeed: How fast the door moves when opening.
    sound: Have door play sound when opening or closing.
    ]]

    trigger = FindTrigger("open")
    motor = FindJoint("motor")

    OpenTarget = GetFloatParam("OpenTarget", 10)
    ClosedTarget = GetFloatParam("ClosedTarget", 0)

    CloseSpeed = GetFloatParam("CloseSpeed", 4)
    OpenSpeed =  GetFloatParam("OpenSpeed", 4)

    --Sound for playing when doors open or close
    DoorSound = LoadSound("doors.ogg")
    UseSound =  GetBoolParam("sound", true)
    DoorsOpening = false
end

function tick(dt)
    PlayerPos = GetPlayerPos()
    TriggerPos = GetTriggerTransform(trigger).pos

    --Playsound whenever someone enters or leaves trigger
    if UseSound then
        if not DoorsOpening and IsPointInTrigger(trigger, PlayerPos) then
            PlaySound(DoorSound, TriggerPos)
            DoorsOpening = true
        end
        if DoorsOpening and not IsPointInTrigger(trigger, PlayerPos) then
            PlaySound(DoorSound, TriggerPos)
            DoorsOpening = false
        end
    end

    --Opens doors if palyer is in trigger and closes them otherwise
    if IsPointInTrigger(trigger, PlayerPos) then
        SetJointMotorTarget(motor, OpenTarget, OpenSpeed)
    else
        SetJointMotorTarget(motor, ClosedTarget, CloseSpeed)
    end
end
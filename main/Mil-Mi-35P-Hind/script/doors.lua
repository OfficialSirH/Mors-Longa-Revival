#include "Config.lua"

function init()
    config()

    upJoint = FindJoint("upJoint")
    downJoint = FindJoint("downJoint")

    doorShape = FindShape("shape")

    door = false
end

function tick()
    if (InputPressed("interact") and GetPlayerInteractShape() == doorShape) then
        door = not door
    end

    if (door) then
        SetJointMotorTarget(upJoint, 90, sideDoor.speed[1])
        SetJointMotorTarget(downJoint, 150, sideDoor.speed[1])
    else
        SetJointMotorTarget(upJoint, 0, sideDoor.speed[2] * 0.45)
        SetJointMotorTarget(downJoint, 0, sideDoor.speed[2])
    end
        
end
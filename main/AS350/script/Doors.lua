function InitDoors()
    local sps = FindShapes("doorcollider")
    for i = 1,#sps,1 do
        SetShapeCollisionFilter(sps[i],8,255-8)
    end
    SlidingDoorJoints = FindJoints("slidingdoor")
    FrontDoorJoints = FindJoints("frontdoor")
    EngineDoorJoints = FindJoints("enginedoor")
    CargoJoints = FindJoints("cargo")
    TopDoorJoints = FindJoints("topdoor")


    sps = FindShapes("enginedoor")
    sps[#sps+1] = FindShape("engine")
    for i = 1,#sps,1 do
        SetShapeCollisionFilter(sps[i],16,255-16)
    end


end



function ManageDoors()

    if DetailedControl == false then
        ManageDoorJoints(SlidingDoorJoints,0,1.1,1,70,0.05)
        ManageDoorJoints(FrontDoorJoints,0,100,2,30,12)
    else
        --don't keep door open when player is pilot also close harder
        ManageDoorJoints(SlidingDoorJoints,0,1.1*2,2,70*4,0.05+1.1)
        ManageDoorJoints(FrontDoorJoints,0,200,2,30*4,11) 
    end

    ManageDoorJoints(EngineDoorJoints,0,75,2,70,8)
    ManageDoorJoints(CargoJoints,0,1000,2,20,8)
    ManageDoorJoints(TopDoorJoints,0,75,2,20,8)
end

function ManageDoorJoints(Joints,Closed,Open,CloseSpeed,CloseForce,mindist)
    local CPos = 0
    local dist = 0
    local dist2 = 0


    for i = 1,#Joints,1 do
        CPos = GetJointMovement(Joints[i])
        dist = math.abs(CPos-Closed)
        dist2 = math.abs(CPos-Open)
        if dist<mindist then
            SetJointMotorTarget(Joints[i], Closed, CloseSpeed*(dist)/mindist, CloseForce)

        elseif dist2<mindist then
            SetJointMotorTarget(Joints[i], Open, CloseSpeed*(dist)/mindist, CloseForce)
        else
            SetJointMotor(Joints[i], 0, 0)
        end
    end
end

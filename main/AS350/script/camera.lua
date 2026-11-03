--[[
function ManageCamera(dt)
    if InputPressed("interact") then
        Counter[HoldE] = CounterMax[HoldE] 
    end
    if Counter[HoldE]>0 then return end
    if BurningBall == 0 then return end
    if GetPlayerInteractBody() ~= 0 then return end
    if InputDown("interact") == false then
        CamPos = nil
        return
    end

    FollowCamera(dt,GetBodyTransform(BurningBall).pos,GetBodyVelocity(BurningBall),GetBodyTransform(Frame))
end
]]


function InitCamera()
    CamPos = nil
    CamSpeed = Vec(0,0,0) --in meter per second the current veloctity of camera
    CamAcc = 0 --in m /s acceleration of camera
    CamOffsetBack = Vec(0,0,0)
    CamOffsetSide = Vec(0,0,0)
    CamDist = 8
end

function FollowCamera(dt,BallPos,BallVel,FrameTr,Follow,VisibilityCheck)
    ReduceDist = false

    if CamPos == nil then
        CamPos = GetCameraTransform().pos
        CamRot = GetCameraTransform().rot
        CamSpeed = Vec(0,0,0)
        CamOffsetBack = TransformToParentVec(FrameTr,Vec(0,0,CamDist))
        CamOffsetSide = TransformToParentVec(FrameTr,Vec(-2,0,0))
        local p = TransformToLocalTransform(FrameTr, CamPos)
        if CamPos[1]>0 then 
            CamOffsetSide = TransformToParentVec(FrameTr,Vec(2,0,0))
        end
        if TransformToLocalPoint(Frame,GetPlayerTransform().pos)[1] < 0 then
            CamOffsetSide = VecScale(CamOffsetSide,-1)
        end
        FellInWater = false
        CamTimer = -1
        CamChangeTimer = 100
        CamType = 1
        LastCamType = 1

        BlockTimer = 0
        CanSee = true
    end

    CamTimer = CamTimer + 1

    if BallVel[2] > 0 then BallVel[2] = 0 end --not soo good if the camera looks upward when the ball is flying upward as everything intersting is below
    CamOffsetBack = VecAdd(CamOffsetBack,VecScale(BallVel,-0.01))
    CamOffsetBack = VecScale(VecNormalize(CamOffsetBack),CamDist)

    IdealCamPos0 = VecAdd(BallPos,CamOffsetBack)

    local hit = true
    bdist = -1
    
    if CamTimer > 150 then
        for i = 1,1,1 do --5 in total
            hit = TestCamPos(i,hit, BallPos, IdealCamPos0,CamOffsetSide,CamOffsetBack)
        end

        if hit then
            BlockTimer = BlockTimer + 1
        else
            BlockTimer = 0
        end
    else
        Camtype = LastCamType
    end

    if VisibilityCheck then
    if BlockTimer > 5 then
        CanSee = false
    end
    end
    --DebugPrint(CamType .. " " .. CamTimer)
    IdealCamPos = GetCamFromType(CamType,BallPos, IdealCamPos0,CamOffsetSide,CamOffsetBack)

    CamTimer = CamTimer + 1
    if Camtype ~= LastCamType then
        CamTimer = 0
    end
    LastCamType= CamType



    local v = VecSub(IdealCamPos,CamPos)
    CamSpeed = VecScale(v,2)

    if ReduceDist then
    if bdist<5 then bdist = 5 end
    if hit then
        IdealCamPos = VecAdd(BallPos,VecScale(VecNormalize(VecSub(IdealCamPos,BallPos)),bdist))
    end
    end

    if IsPointInWater(BallPos)  then
        FellInWater = true
        bdist = bdist * 1.3
    end

    
    if Follow then
    if FellInWater == false then
        if CanSee then
            CamPos = VecAdd(CamPos,VecScale(CamSpeed,dt))
        end
    end
    end

    if FellInWater == false then
        local NewCamRot = QuatLookAt(CamPos,VecAdd(BallPos,VecScale(CamOffsetSide,0.3)))
        local RotSpeed = ChooseRotationSpeed(CamTimer)
        CamRot = QuatSlerp(CamRot,NewCamRot,RotSpeed)
    end
    
    SetCameraTransform(Transform(CamPos,CamRot))
end

function ChooseRotationSpeed(CamTimer)
    local r = 0
    local f = 0

    f = CamTimer/(1.75*60)
    if f > 1 then f = 1 end
    
    r = 0.02*(1-f)+0.1*f

    return r
end

function TestCamPos(ct, hit, BallPos, IdealCamPos0,CamOffsetSide,CamOffsetBack)
    if hit == false then return end
    
    local IdealCamPosTest = GetCamFromType(ct,BallPos, IdealCamPos0,CamOffsetSide,CamOffsetBack)
    local v = VecSub(IdealCamPosTest,BallPos)
    local lookdist = VecLength(v)*1.1
    QueryRejectBody(BurningBall)
    local hit, dist, normal, shape = QueryRaycast(BallPos, VecNormalize(v), lookdist, 0, true)
    if hit == false then
        dist = lookdist
    else
        dist = dist * 0.99
    end

    if dist>bdist then
        bdist = dist
        CamType = ct
        return hit
    end

end

function GetCamFromType(CamType,BallPos, IdealCamPos0,CamOffsetSide,CamOffsetBack)
    if CamType == 1 then
        return VecAdd(IdealCamPos0,CamOffsetSide)
    end
    if CamType == 2 then
        return VecAdd(IdealCamPos0,VecScale(CamOffsetSide,-1))
    end
    if CamType == 3 then
        return IdealCamPos0
    end
    if CamType == 4 then
        local IdealCamPosTest = VecAdd(BallPos,VecScale(CamOffsetBack,0.7))
        IdealCamPosTest = VecAdd(IdealCamPosTest,Vec(0,CamDist*0.4,0))
        return VecAdd(IdealCamPos0,CamOffsetSide)
    end
    if CamType == 5 then
        return VecAdd(BallPos,Vec(0,CamDist*0.7,0))
    end
end


--[[
#include "camera.lua"
]]

FollowCamEnabled = true

function init()
    Bd = FindBody("rocket")
    Sp = FindShape("rocket")
    Tr = GetBodyTransform(Bd)
    CamFrameTr = Tr
    Dir = QuatRotateVec(Tr.rot,Vec(0,0,-1))
    SetShapeCollisionFilter(Sp, 0, 0)
    Counter = 0
    Active = true
    PrimingCounter = 30
    Sound_fly = LoadLoop("MOD/genzero_tank/sound/effects2/rocket_effect.ogg")

    TrackingPower = 0.5 --max angular velocity

    --guidance
    local QueryPos = VecAdd(Tr.pos,VecScale(Dir,5)) --query a bit ahead to avoid coming backto things very close, if hitting things very close, it's dumbfire

    QueryDir = Dir
    TargetPoint = Vec(0,0,0)
    PlayerTracking = false
    if HasKey("RocketTarget" .. 1) then
        for i2 = 1,3,1 do
            TargetPoint[i2] = GetFloat("RocketTarget" .. i2)
            ClearKey("RocketTarget" .. i2)
        end
        QueryDir = VecNormalize(VecSub(TargetPoint,QueryPos))
        local l = VecLength(VecSub(TargetPoint,GetPlayerCameraTransform().pos))
        --DebugPrint(l)
        if l < 0.6 then
            PlayerTracking = true
        end
    end

    QueryRejectBody(Bd)
    local hit, dist, normal, sp = QueryRaycast(QueryPos, QueryDir, 1000)
    Guided = false
    if hit then
        TargetBody = GetShapeBody(sp)
        Guided = true
        TargetPoint = VecAdd(QueryPos,VecScale(QueryDir,dist))
        TargetPointLoc = TransformToLocalPoint(GetBodyTransform(TargetBody),TargetPoint)
    end
end

function update(dt)
    if Active == false then 
        return 
    end
    if Counter == PrimingCounter then
        SetShapeCollisionFilter(Sp, 255, 255)
    end
    Tr = GetBodyTransform(Bd)
    Pos = TransformToParentPoint(Tr,GetBodyCenterOfMass(Bd))
    if Counter < 30 then
        ApplyBodyImpulse(Bd,Pos,VecScale(Dir,1000))
    end
    ApplyBodyImpulse(Bd,Pos,Vec(0,23,0)) -- keep floating

    EndPoint = TransformToParentPoint(Tr,Vec(0,0,3))
    ForwardPoint = TransformToParentPoint(Tr,Vec(0,0,-0.2))

    local Detonate = false
    if Counter > PrimingCounter then
        if IsShapeBroken(Sp) then
            Detonate = true
        end


        hit, point, normal, shape = QueryClosestPoint(ForwardPoint, 0.15)
        if hit then
            Detonate = true
        end

        local v = VecSub(ForwardPoint,GetCameraTransform().pos)
        local l = VecLength(v)
        if l < 1.5 then
            v = VecSub(VecAdd(ForwardPoint,GetBodyVelocity(Bd)),GetCameraTransform().pos)
            local l2 = VecLength(v)
            if l <= l2 then
            Detonate = true
            end
        end
    end

    if Counter > 105 then Detonate = true end --auto detonate when too far

    if Detonate then
        Explosion(Pos,2)
        Active = false
    end

    if Guided then
        if IsHandleValid(TargetBody) == false and PlayerTracking == false then 
            Guided = false
        end
        if PlayerTracking == false then
            TargetPoint = TransformToParentPoint(GetBodyTransform(TargetBody),TargetPointLoc)
        else
            TargetPoint = GetPlayerCameraTransform().pos
            if Counter>25 then Guided = false end
        end
        --DebugCross(TargetPoint)
        --DebugLine(GetBodyTransform(Bd).pos,TargetPoint)
        
        --update Dir based on vec to target point from tr.pos

        ConstrainOrientation(Bd,0,Tr.rot,QuatLookAt(Tr.pos,TargetPoint),TrackingPower)
        Dir = QuatRotateVec(Tr.rot,Vec(0,0,-1))
        Vel = GetBodyVelocity(Bd)
        Vel = VecScale(Dir,VecLength(Vel))
        SetBodyVelocity(Bd,Vel)
    end

    PlayLoop(Sound_fly,ForwardPoint,2)
    smoke(Pos,GetBodyVelocity(Bd))
    Counter = Counter + 1

end

function tick(dt)
    if FollowCamEnabled then
        if Active then
            FollowCamera(dt,GetBodyTransform(Bd).pos,GetBodyVelocity(Bd),CamFrameTr,true,false)
            FinalCamTr = GetCameraTransform()
            finalcount= 0
                --DebugPrint(VecStr(Pos))

        else

            finalcount = finalcount + 1
            if finalcount>60*1.5 then return end
            SetCameraTransform(FinalCamTr)
        end
    end
end

function smoke(bpos,vel)
    --flame
    local dirR = 10
    ParticleColor(1,0.6,0.3,0.1,0.1,0.1,"linear",0,0.5)
    ParticleEmissive(2,0,"linear",0,0.5)
    ParticleRadius(0.2,0)
    ParticleAlpha(1.0,0.0)
    ParticleCollide(0)
    ParticleGravity(2,0)
    SpawnParticle(bpos, Vec(math.random(-dirR,dirR)/20, math.random(-dirR,dirR)/20, math.random(-dirR,dirR)/20), 1)
    ParticleReset()

    --smoke
    SCount = 3

    ParticleColor(0.8,0.8,0.8)
    --ParticleEmissive(2,0,"linear",0,0.5)
    ParticleRadius(0.4,0.8,"linear")
    ParticleAlpha(0.2,0.0)
    ParticleCollide(0)
    ParticleGravity(0)

    local l = VecLength(vel)/60
    vel = VecNormalize(vel)

    for SNo = 1,SCount,1 do
        SpawnParticle(VecAdd(bpos,VecScale(vel,-l/SCount*(SCount-1))), Vec(0,0,0), 4)
    end

    ParticleReset()
end
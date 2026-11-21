#version 2
DL_LABEL = "rocket"  -- crash breadcrumbs (lib/DeleteLog.lua)
#include "../../../../lib/DeleteLog.lua"
#include "script/include/player.lua"
-- AS350 rocket (rocket_small.xml; also the Hind's rocket.xml), v2 port 2026-11-13 (hand-written; original: git
-- 9dde6dd vehicles/aircraft/AS350/script/rocket.lua). Server: thrust, guidance (ConstrainOrientation: server.update only),
-- detonation. Clients: flame / smoke trail and the flight sound. The original's follow camera (FollowCamEnabled,
-- off; camera.lua) is not ported. v1 used "the camera" (the one player) to home on a player and to blow up next to
-- one: now every player (their eyes, GetPlayerCameraTransform).

local function nearestPlayerEye(pos)
	local best, bestD
	for p in Players() do
		if GetPlayerHealth(p) > 0 then
			local e = GetPlayerCameraTransform(p).pos
			local d = VecLength(VecSub(e, pos))
			if best == nil or d < bestD then best, bestD = p, d end
		end
	end
	return best, bestD
end

function server.init()
    Bd = FindBody("rocket")
    Sp = FindShape("rocket")
    Tr = GetBodyTransform(Bd)
    MassFactor = GetBodyMass(Bd)/291
    Dir = QuatRotateVec(Tr.rot,Vec(0,0,-1))
    SetShapeCollisionFilter(Sp, 0, 0)
    Counter = 0
    Active = true
    shared.active = true
    PrimingCounter = 30

    TrackingPower = 0.75 --max angular velocity

    --guidance
    local QueryPos = VecAdd(Tr.pos,VecScale(Dir,5)) --query a bit ahead to avoid coming backto things very close, if hitting things very close, it's dumbfire

    QueryDir = Dir
    TargetPoint = Vec(0,0,0)
    PlayerTracking = false
    if HasKey("level.RocketTarget" .. 1) then
        for i2 = 1,3,1 do
            TargetPoint[i2] = GetFloat("level.RocketTarget" .. i2)
            ClearKey("level.RocketTarget" .. i2)
        end
        QueryDir = VecNormalize(VecSub(TargetPoint,QueryPos))
        -- (v2) aimed at a player's eye: home on that player (v1: the one player's camera)
        local p, l = nearestPlayerEye(TargetPoint)
        if p and l < 0.6 then
            PlayerTracking = true
            TrackedPlayer = p
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

function server.update(dt)
    if Active == false then
        return
    end
    if Counter == PrimingCounter then
        SetShapeCollisionFilter(Sp, 255, 255)
    end
    Tr = GetBodyTransform(Bd)
    Pos = TransformToParentPoint(Tr,GetBodyCenterOfMass(Bd))
    if Counter < 30 then
        ApplyBodyImpulse(Bd,Pos,VecScale(Dir,1000*MassFactor))
    end
    ApplyBodyImpulse(Bd,Pos,Vec(0,23*MassFactor,0)) -- keep floating

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

        -- (v2) next to any player's eye (v1: the camera)
        for p in Players() do
            if GetPlayerHealth(p) > 0 then
                local eye = GetPlayerCameraTransform(p).pos
                local l = VecLength(VecSub(ForwardPoint, eye))
                if l < 1.5 then
                    local l2 = VecLength(VecSub(VecAdd(ForwardPoint,GetBodyVelocity(Bd)), eye))
                    if l <= l2 then
                        Detonate = true
                    end
                end
            end
        end
    end

    if Counter > 105 then Detonate = true end --auto detonate when too far

    if Detonate then
        Explosion(Pos,1.2)
        Active = false
        shared.active = false
    end

    if Guided then
        if IsHandleValid(TargetBody) == false and PlayerTracking == false then
            Guided = false
        end
        if PlayerTracking == false then
            TargetPoint = TransformToParentPoint(GetBodyTransform(TargetBody),TargetPointLoc)
        else
            if TrackedPlayer and GetPlayerHealth(TrackedPlayer) > 0 then
                TargetPoint = GetPlayerCameraTransform(TrackedPlayer).pos
            end
            if Counter>15 then Guided = false end
        end

        ConstrainOrientation(Bd,0,Tr.rot,QuatLookAt(Tr.pos,TargetPoint),TrackingPower)
        Dir = QuatRotateVec(Tr.rot,Vec(0,0,-1))
        Vel = GetBodyVelocity(Bd)
        Vel = VecScale(Dir,VecLength(Vel))
        SetBodyVelocity(Bd,Vel)
    end

    Counter = Counter + 1
end

function client.init()
    Bd = FindBody("rocket")
    Sound_fly = LoadLoop("MOD/vehicles/aircraft/AS350/rocket_effect.ogg")
end

-- 60 Hz like the original's update: flight sound and trail while the server says the rocket flies
function client.update(dt)
    if shared.active == false or not IsHandleValid(Bd) then return end
    local tr = GetBodyTransform(Bd)
    local pos = TransformToParentPoint(tr, GetBodyCenterOfMass(Bd))
    PlayLoop(Sound_fly, TransformToParentPoint(tr, Vec(0,0,-0.2)), 2)
    smoke(pos, GetBodyVelocity(Bd))
end

function smoke(bpos,vel)
    --flame
    local dirR = 10
    ParticleColor(1,0.6,0.3,0.1,0.1,0.1,"linear",0,0.5)
    ParticleEmissive(2,0,"linear",0,0.5)
    ParticleRadius(0.15,0)
    ParticleAlpha(0.8,0.0)
    ParticleCollide(0)
    ParticleGravity(2,0)
    SpawnParticle(bpos, Vec(math.random(-dirR,dirR)/20, math.random(-dirR,dirR)/20, math.random(-dirR,dirR)/20), 1)
    ParticleReset()

    --smoke
    SCount = 3

    ParticleColor(0.8,0.8,0.8)
    ParticleRadius(0.2,0.4,"linear")
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

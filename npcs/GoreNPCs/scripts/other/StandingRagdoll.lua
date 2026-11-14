#version 2
#include "script/include/player.lua"
-- (v2) server: shop trader; looks at the nearest player; killing it halves the NEAREST player's money (their savegame, via ClientCall).
function server.init()
	StabilizeJoint = FindJoints("joint")
	---ShoulderJoint = FindJoints("shoulder")
	dead = false
	bodypart = FindShapes("bodypart")
	deletejoint = FindJoints("break")
	Torso = FindBody("torso")
	Head = FindBody("Head")
	done = false
end

function server.tick(dt)
	if not dead then
		local NPCPos = GetBodyTransform(Torso).pos
		local nearestP, dist = NearestPlayer(NPCPos) -- (v2) nearest player (v1: the camera)

		-- (v2) the head constraint is applied in server.update: Constrain* in tick crashed the v2 engine
		LookAtPos = nil
		if dist < 7 then
			LookAtPos = GetPlayerCameraTransform(nearestP).pos
		end
		---for i=1,#ShoulderJoint do
		---SetJointMotorTarget(ShoulderJoint[i], 20, 5)
		---end
		for i = 1, #StabilizeJoint do
			SetJointMotorTarget(StabilizeJoint[i], 0, 915)
		end
		for i = 1, #bodypart do
			if IsShapeBroken(bodypart[i]) then
				dead = true
			end
		end
	end
	if dead and not done then
		done = true
		-- (v2) money is per player (client savegame): the nearest player (most likely the killer) loses half
		local killer = NearestPlayer(GetBodyTransform(Torso).pos)
		ClientCall(killer, "client.halveMoney", killer)
		for i = 1, #deletejoint do
			Delete(deletejoint[i])
			RemoveTag(Torso, "interact")
		end
		local t = GetBodyTransform(Torso)
		local force1 = 12
		local fwd2 = TransformToParentVec(t, Vec(0, 1, 0))
		ApplyBodyImpulse(Torso, t.pos, VecScale(fwd2, force1)) -- (v2 fix) v1 used undefined fwd1 (error on death)
	end
end

-- (v2) head look-at constraint (target chosen in server.tick); Constrain* belongs in update
function server.update(dt)
	if not dead and LookAtPos and IsHandleValid(Head) then
		ConstrainOrientation(Head, GetWorldBody(), GetBodyTransform(Head).rot,
			QuatLookAt(GetBodyTransform(Head).pos, LookAtPos))
	end
end

-- (v2) nearest player to pos (0 = host if there are none)
function NearestPlayer(pos)
	local best, bestD = 0, math.huge
	for p in Players() do
		local d = VecLength(VecSub(GetPlayerTransform(p).pos, pos))
		if d < bestD then best, bestD = p, d end
	end
	return best, bestD
end

function client.halveMoney(target)
	local me = GetLocalPlayer()
	if target ~= me and not (target == 0 and IsPlayerHost(me)) then return end
	SetInt("savegame.mod.player.money", GetInt("savegame.mod.player.money") / 2)
end

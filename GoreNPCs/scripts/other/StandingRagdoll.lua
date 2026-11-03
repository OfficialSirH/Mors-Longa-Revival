function init()
	StabilizeJoint = FindJoints("joint")
	---ShoulderJoint = FindJoints("shoulder")
	dead = false
	bodypart = FindShapes("bodypart")
	deletejoint = FindJoints("break")
	Torso = FindBody("torso")
	Head = FindBody("Head")
	done = false
end

function tick(dt)
	if not dead then
		local playerPos = GetPlayerTransform().pos
		local NPCPos = GetBodyTransform(Torso).pos
		local dist = VecLength(VecSub(playerPos, NPCPos))

		if dist < 7 then
			ConstrainOrientation(
				Head,
				GetWorldBody(),
				GetBodyTransform(Head).rot,
				QuatLookAt(GetBodyTransform(Head).pos, GetCameraTransform().pos))
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
		Money = GetInt("savegame.mod.player.money")
		SetInt("savegame.mod.player.money", Money / 2)
		for i = 1, #deletejoint do
			Delete(deletejoint[i])
			RemoveTag(Torso, "interact")
		end
		local t = GetBodyTransform(Torso)
		local force1 = 12
		local fwd2 = TransformToParentVec(t, Vec(0, 1, 0))
		ApplyBodyImpulse(Torso, t.pos, VecScale(fwd1, force1))
	end
end

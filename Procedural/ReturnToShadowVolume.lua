#version 2
-- (v2) the whole script was already commented out in the original (logic lives in GenerateRoad.lua)
-- function init()
-- 	point = FindLocation("pointOreturn", true)

-- 	PlayerZ = GetPlayerTransform().pos[3]
-- 	RoadSegements

-- end
-- function tick()
-- 	pointTrans = GetLocationTransform(point)
-- 	disttopoint = VecLength(VecSub(GetPlayerTransform().pos,pointTrans.pos))
-- 	if disttopoint < 200 then
-- 		SetBool("level.map_moved", false)
-- 		Bodies = FindBodies("",true)
-- 		Triggers = FindTriggers("", true)
-- 		for i=1,#Bodies do
-- 			c = GetBodyTransform(Bodies[i]).pos
-- 			r = GetBodyTransform(Bodies[i]).rot
-- 			ok = IsBodyActive(Bodies[i])
-- 			bodyspeed = GetBodyVelocity(Bodies[i])
-- 			bodyrotationspeed = GetBodyAngularVelocity(Bodies[i])
-- 			SetBodyTransform(Bodies[i], Transform(Vec(c[1] - 300,c[2],c[3]), r))
-- 			SetBodyActive(Bodies[i], ok)
-- 			SetBodyVelocity(Bodies[i], bodyspeed)
-- 			SetBodyAngularVelocity(Bodies[i], bodyrotationspeed)
-- 		end

-- 		for i=1,#Triggers do
-- 			c = GetTriggerTransform(Triggers[i]).pos
-- 			SetTriggerTransform(Triggers[i], Transform(Vec(c[1] - 300,c[2],c[3])))
-- 		end

-- 		b = GetPlayerTransform()
-- 		bs = GetPlayerVelocity()
-- 		b.pos = Vec(b.pos[1] - 300, b.pos[2], b.pos[3])
-- 		SetPlayerTransform(b, true)
-- 		SetPlayerVelocity(bs)

-- 		DistanceTravelled = DistanceTravelled +

-- 	else
-- 		SetBool("level.map_moved", true)
-- 	end


-- 	DebugWatch()

-- end
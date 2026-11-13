#version 2
-- (v2) Death ragdoll camera, CLIENT only. The server spawns the ragdoll prefab for the player who died
-- (server.healthDied in AdvancedHealthScript.lua, which also gives the body parts that player's velocity - v1 did
-- that here on the first tick). Every client runs this script; it is "mine" if, on its first tick, the ragdoll is
-- within 4 m of the local player, and it follows only once the local player is dead (2 s grace for the health to
-- arrive). As v1: the camera sits at the ragdoll's head until the player is alive again.

function client.init()
	State = "check" -- check -> wait (mine, health not 0 yet) -> follow -> done
	WaitTime = 0
end

function client.tick(dt)
	if State == "done" then return end
	local head = FindBody("Head")
	if head == 0 then return end
	local ct = GetBodyTransform(head)

	if State == "check" then
		State = VecLength(VecSub(GetPlayerTransform().pos, ct.pos)) <= 4 and "wait" or "done"
	end
	if State == "wait" then
		if GetPlayerHealth() == 0 then
			State = "follow"
		else
			WaitTime = WaitTime + dt
			if WaitTime > 2 then State = "done" end
		end
	end
	if State == "follow" then
		local gunpos = TransformToParentPoint(ct, Vec(-0.2, 0, 0))
		SetCameraTransform(Transform(gunpos, ct.rot))
		if GetPlayerHealth() ~= 0 then State = "done" end
	end
end

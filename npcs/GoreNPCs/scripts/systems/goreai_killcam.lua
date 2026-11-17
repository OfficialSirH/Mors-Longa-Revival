-- (v2 goreai) Killcam, split for co-op:
--   server: npc_process_shield marks which player damaged each body this tick (mark_body_damaged_by_player);
--           when an npc is dead and its head was damaged this tick, set_lock_cam sends client.goreKillcam to
--           that player only. Slow motion (SetTimeScale, server only) is applied while that client asks for
--           it, and only when there is a single player (it would slow everyone down).
--   client: killcam_receive / tick_lockcam move the camera and outline the body, as v1 did.

-- Holds table of icons to display each tick.
Killcam_Data = {
	timer = TimerCreateSeconds(0.5, true),
	cam_Pos = Vec(),
	focus_Body = 0,
	bodyparts = {},
	_player_damaged = {}, -- server: [body] = player id, this tick
	_player_damaged_recent = {}, -- server: [body] = { p, t }, kept 0.3 s (see mark_body_damaged_by_player)
	active = false,       -- client
}

Killcam_Server = nil -- server: { player, bodyparts, on, time }

function npc_init_lockcam(npc)
    npc.lockCamReleased = false
    npc.lockCam = false --* add control
end

------------------------------------------------------------------
-- Server
------------------------------------------------------------------

function set_lock_cam(npc)
	-- Init locked camera.
	local p = Killcam_Data._player_damaged[npc.Head]
	local recent = Killcam_Data._player_damaged_recent[npc.Head]
	if not p and recent and GetTime() - recent.t < 0.3 then p = recent.p end
	if p then
		Killcam_Data._player_damaged[npc.Head] = nil -- once (update can run several times per tick)
		Killcam_Data._player_damaged_recent[npc.Head] = nil
		-- (2026-11-17) the head's current position (npc.HT is no longer kept for settled dead npcs)
		local camPos = VecAdd(GetBodyTransform(npc.Head).pos, Vec(math.random(-3,3), math.random(0,3), math.random(-3,3)))
		Killcam_Server = { player = GoreAI_ResolvePlayer(p), bodyparts = npc.bodyparts, on = false, time = 0 }
		GoreAI_ClientCall(p, "client.goreKillcam", npc.Head, camPos, npc.bodyparts)
	end
end

function server.goreKillcamSlowmo(p, on)
	local k = Killcam_Server
	if k and k.player == p then
		k.on = on and true or false
		k.time = 0
		if not k.on then Killcam_Server = nil end
	end
end

function tick_lockcam_server()
	for b, hit in pairs(Killcam_Data._player_damaged_recent) do -- forget old head hits
		if GetTime() - hit.t >= 0.3 then Killcam_Data._player_damaged_recent[b] = nil end
	end
	local k = Killcam_Server
	if not k or not k.on then return end
	k.time = k.time + GetTimeStep()
	if k.time > 1 or #GorePlayerIds > 1 then -- safety limit (game time); no slow motion in co-op
		Killcam_Server = nil
		return
	end
	SetTimeScale(0.1)
	for i = 1, #k.bodyparts do
		SetBodyActive(k.bodyparts[i])
		ApplyBodyImpulse(k.bodyparts[i],Vec(),Vec(.01,.01,.01))
	end
end

------------------------------------------------------------------
-- Client
------------------------------------------------------------------

function killcam_receive(head, camPos, bodyparts)
	if not Settings.game.killcam.value then return end
	Killcam_Data.focus_Body = head
	Killcam_Data.cam_Pos = VecCopy(camPos)
	Killcam_Data.bodyparts = bodyparts or {}
	TimerResetTime(Killcam_Data.timer)
	ServerCall("server.goreKillcamSlowmo", GetLocalPlayer(), true)
end

function killcam_stop()
	if Killcam_Data.active then
		Killcam_Data.active = false
		SetBool('level.killcam.active',false) -- guns skip their HUD while this is set
		ServerCall("server.goreKillcamSlowmo", GetLocalPlayer(), false)
	end
end

function tick_lockcam()

	if TimerConsumed(Killcam_Data.timer) then
		killcam_stop()
		return
	end

	if InputPressed("any") then
		TimerEndTime(Killcam_Data.timer)
		killcam_stop()
		return
	end

	if not IsHandleValid(Killcam_Data.focus_Body) then
		TimerEndTime(Killcam_Data.timer)
		killcam_stop()
		return
	end

	local camT = Transform(Killcam_Data.cam_Pos, QuatLookAt(Killcam_Data.cam_Pos, GetBodyTransform(Killcam_Data.focus_Body).pos))
	SetCameraTransform(camT)
	for i = 1, #Killcam_Data.bodyparts do
		DrawBodyOutline(Killcam_Data.bodyparts[i], 1, 0, 0, 1)
	end

	TimerRunTime(Killcam_Data.timer)
	Killcam_Data.active = true
	SetBool('level.killcam.active',true)
end

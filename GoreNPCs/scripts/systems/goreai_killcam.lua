-- Holds table of icons to display each tick.
Killcam_Data = {
	timer = TimerCreateSeconds(0.5, true),
	cam_Pos = Vec(),
	focus_Body = 0,
	bodyparts = {},
	_player_damaged = {},
}

function npc_init_lockcam(npc)
    npc.lockCamReleased = false
    npc.lockCam = false --* add control
end

function npc_manage_lockcam(npc)

    -- Init locked camera.
    if  npc.deadTime < 0.5
    and npc.disttoplayer > 50
    and not npc.lockCam
    and Settings.game.killcam.value
    then
        npc.lockcam = true
        npc.lockPlayerTr = GetPlayerTransform(true)
    end


    if npc.lockcam then

        if npc.deadTime >= 0.5 or InputPressed("any") then
            npc.lockcam = false
            -- npc_MarkForRemoval(npc)
        end

        if not npc.humaned then
            npc.HumanDeathCam =
                Vec(
                npc.HT.pos[1] + math.random(-3, 3),
                npc.HT.pos[2] + math.random(0, 3),
                npc.HT.pos[3] + math.random(-3, 3)
            )
            npc.humaned = true
        end

        local rot = QuatLookAt(npc.HumanDeathCam, npc.HT.pos)
        SetCameraTransform(Transform(npc.HumanDeathCam, rot))
        SetTimeScale(0.1)
        ApplyBodyImpulse(npc.Head, Vec(0.001, 0.001, 0.001), Vec(0, 0, 0))
        for i = 1, #npc.bodyparts do
            local bodypart = npc.bodyparts[i]
            DrawBodyOutline(bodypart, 1, 0, 0, 1)
        end

    end
end

function tick_lockcam()

	if TimerConsumed(Killcam_Data.timer) then
		SetBool('level.killcam.active',false)
		Killcam_Data._player_damaged = {}
		return
	end

	if InputPressed("any") then
		TimerEndTime(Killcam_Data.timer)
		SetBool('level.killcam.active',false)
		Killcam_Data._player_damaged = {}
		return
	end

	local camT = Transform(Killcam_Data.cam_Pos, QuatLookAt(Killcam_Data.cam_Pos, GetBodyTransform(Killcam_Data.focus_Body).pos))
	SetCameraTransform(camT)
	SetTimeScale(0.1)
	for i = 1, #Killcam_Data.bodyparts do
		SetBodyActive(Killcam_Data.bodyparts[i])
		ApplyBodyImpulse(Killcam_Data.bodyparts[i],Vec(),Vec(.01,.01,.01))
		DrawBodyOutline(Killcam_Data.bodyparts[i], 1, 0, 0, 1)
	end

	TimerRunTime(Killcam_Data.timer)
	SetBool('level.killcam.active',true)
	Killcam_Data._player_damaged = {}
end

function set_lock_cam(npc)
	-- Init locked camera.
	if Killcam_Data._player_damaged[npc.Head] then

		Killcam_Data.focus_Body = npc.Head
		Killcam_Data.cam_Pos = VecAdd(npc.HT.pos, Vec(math.random(-3,3), math.random(0,3), math.random(-3,3)))
		Killcam_Data.bodyparts = npc.bodyparts

		TimerResetTime(Killcam_Data.timer)
	end
end

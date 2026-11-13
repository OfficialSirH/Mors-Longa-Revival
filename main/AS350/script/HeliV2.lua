-- AS350 v2 port (2026-11-13): replacements for functions of the original files (included before this one, so these
-- definitions win) where the original assumed one player on one machine, plus the clients' effects.
-- Originals: git 9dde6dd main/AS350/script/<file>. Every replaced function names its file; changes are marked (v2).

local function clamp(v, a, b) return math.max(a, math.min(b, v)) end

HELI_GUN_CONE = 0.15 -- player's gun: shots go at the crosshair point while the gun points within ~8.5 degrees of it

--- A location returned by GetLocationLocalTransform (common.lua's last definition returns a transform) as a point.
function LocalPoint(x)
	if x and x.pos then return x.pos end
	return x or Vec()
end

--------------------------------------------------------------------------------------------------- server: players

--- Hitbox triggers of player p in the order the original indexed them (HEAD first): PlayerHitboxes.lua gives the
--- host the level's own set and the other players a set tagged hitbox_player=<id>.
local LIMBS = { "HEAD", "LARM", "LLEG", "RARM", "RLEG", "TORSO" }
function HeliV2_Hitboxes(p)
	local byLimb = {}
	for _, t in ipairs(FindTriggers("hitbox", true)) do
		local owner
		if HasTag(t, "hitbox_player") then owner = tonumber(GetTagValue(t, "hitbox_player")) end
		if owner == p or (owner == nil and IsPlayerHost(p)) then byLimb[GetTagValue(t, "hitbox")] = t end
	end
	local list = {}
	for _, l in ipairs(LIMBS) do if byLimb[l] then list[#list + 1] = byLimb[l] end end
	return list
end

--- The player the AI is after (or was last after when it hunts an NPC): v1 had only the one player. 0 = the host.
function HeliTargetPlayer()
	return TargetPlayer or 0
end

local function canSee(from, to)
	QueryRejectSelf()
	local d = VecSub(to, from)
	local l = VecLength(d)
	if l < 0.01 then return true end
	local hit, dist = QueryRaycast(from, VecScale(d, 1 / l), l, 0, true)
	return not hit or dist > l - 0.5
end

--- Nearest living player the helicopter can see, else the nearest living one, else nil (v2; v1: the one player).
function HeliV2_PickPlayer()
	local best, bestD, bestSeen
	for p in Players() do
		if GetPlayerHealth(p) > 0 then
			local pos = VecAdd(GetPlayerTransform(p).pos, Vec(0, 1, 0))
			local d = VecLength(VecSub(pos, HeliTr.pos))
			local seen = canSee(HeliTr.pos, pos)
			if best == nil or (seen and not bestSeen) or (seen == bestSeen and d < bestD) then
				best, bestD, bestSeen = p, d, seen
			end
		end
	end
	return best
end

--- (v2) The pilot is whoever sits in the driver seat (v1: the player who used the dashboard). While someone sits there
--- the car drive input is held at 0: player_locomotion.lua turns a driver's head back on reverse (S).
function HeliV2_UpdatePilot()
	local seated = 0
	if HeliVehicle ~= 0 then
		for p in Players() do
			if GetPlayerVehicle(p) == HeliVehicle and IsPlayerVehicleDriver(HeliVehicle, p) and GetPlayerHealth(p) > 0 then
				seated = p
			end
		end
		if seated ~= 0 then DriveVehicle(HeliVehicle, 0, 0, false) end
	end
	PilotSeated = seated
	if seated ~= PilotId or (PilotId ~= 0 and not DetailedControl) then
		if PilotId ~= 0 then
			-- the pilot's tool back (v1 StopControl: SetString("game.player.tool", ToolName))
			if PilotPrevTool then SetPlayerTool(PilotPrevTool, PilotId) end
			PilotPrevTool = nil
			StopControl()
		end
		if seated ~= 0 and not ConsoleBroken and not IsCrashed then
			PilotPrevTool = GetPlayerTool(seated)
			TakeControl(seated)
		end
	end
	if PilotId ~= 0 then
		-- empty hands while flying (v1 TakeControl: SetString("game.player.tool", ""); dropped at first in the port;
		-- test 2026-11-13: with a gun in hand, RMB leaned the pilot out of the helicopter to aim instead of firing
		-- rockets), as the mounted-gun gunner (scripts/MountedGun.lua)
		if GetPlayerTool(PilotId) ~= "" then SetPlayerTool("", PilotId) end
		HeliPilot_ReadKeys(PilotId)
	end
end

--- (v2) Inputs.lua ManageControlPanelInteractions: the "Take a ride" interaction (the AI pilot's head) for every
--- player; that player commands the ride (X / Z / C / Shift / Ctrl) and ends it with E. The dashboard ("Control")
--- is gone: the pilot seat gives control.
function HeliV2_RideInteractions()
	-- the player riding died or left the game: the autopilot flies on to its target; the next player who uses the
	-- pilot's head commands it
	if Commander ~= 0 and GetPlayerHealth(Commander) <= 0 then Commander = 0 end
	if not TargetSelectionMode then Commander = 0 end
	for p in Players() do
		if InputPressed("interact", p) then
			if TargetSelectionMode and p == Commander then
				TargetSelectionMode = false -- (v1: E anywhere ended the ride)
				Commander = 0
			elseif Commander == 0 and not DetailedControl and ConsoleBroken == false then
				local s = GetPlayerInteractShape(p)
				for i = 1, #PilotShapes do
					if s == PilotShapes[i] then
						Commander = p
						if not TargetSelectionMode then StartRide() end
					end
				end
			end
		end
	end
end

local function S(k, v) if shared[k] ~= v then shared[k] = v end end
local function r2(x) return math.floor((x or 0) * 100 + 0.5) / 100 end

--- (v2) What the clients need for sounds, effects, the camera and the prompts.
function HeliV2_SyncShared()
	S("heEngineOn", IsEngineOn and true or false)
	S("heHostile", IsHostile and true or false)
	S("heShutOff", ShutOff and true or false)
	S("heStarting", Starting and true or false)
	S("heStartLeft", Starting and math.ceil(StartTimer / 60) or 0)
	S("heEngineHealth", r2(EngineHealth))
	S("heTotalDamage", r2(TotalDamage))
	S("heCrashed", IsCrashed and true or false)
	S("heRotorGone", RotorGone and true or false)
	S("heRot", r2(clamp(MRotSpeedFraction or 0, 0, 4)))
	S("heFuel", math.floor(Fuelamount or 0))
	S("heFuelCap", FuelCapacity or 540)
	S("heSmoking", EngineSmoking and true or false)
	S("heCritical", HeliV2_Critical() and true or false)
	S("hePilot", PilotId or 0)
	S("heCommander", Commander or 0)
	S("heRide", TargetSelectionMode and true or false)
	S("heGunTimer", r2(GunTimer))
	S("heRocketTimer", r2(RocketTimer))
	S("heGunBroken", IsGunBroken and true or false)
	S("heRocketBroken", IsRocketBroken and true or false)
	S("heRocketReady", (RocketCooldown or 0) <= 0)
	HeliPilot_SyncDebug()
end

--------------------------------------------------------------------------------------------------- server: Inputs.lua

-- (v2) Inputs.lua initControl: no "Control" interaction on the dashboard (the pilot seat gives control) and no camera
-- (the pilot's client has its own: HeliPilot.lua).
function initControl()
	ControlPanel = FindShape("panel_left")
	DetailedControl = false
	ThirdPersonView = false

	InitialiseControl()

	PanelCooldownTimer = 0

	ControlWarmUpSeconds = 3
	ControlStartPower = 0.3
	ControlPowerCollective = 0
	ControlPowerSide = 0
	ControlPowerForward = 0
end

--------------------------------------------------------------------------------------------------- server: doors

--- (v2) Ways in: the game's own "Enter vehicle" prompt only shows while the player looks at a body of the vehicle
--- (hud.lua: GetPlayerInteractBody -> GetBodyVehicle) and was hard to get (in-game 2026-11-13: only at an awkward
--- angle from the side, not standing next to it). The cabin doors get a prompt of their own: the pilot's door (front,
--- body +x side) "Fly helicopter", the others "Enter helicopter"; E puts the player in the helicopter (the game picks
--- the seat: the pilot seat while it is free). A door that came off loses its prompt.
function HeliV2_InitDoorEntry()
	DoorEntry = {}
	local function add(joints, front)
		for _, j in ipairs(joints or {}) do
			for _, s in ipairs(GetJointShapes(j) or {}) do
				if GetShapeBody(s) ~= Heli and not DoorEntry[s] then
					local x = TransformToLocalPoint(GetBodyTransform(Heli), GetShapeWorldTransform(s).pos)[1]
					DoorEntry[s] = (front and x > 0) and "Fly helicopter" or "Enter helicopter"
					SetTag(s, "interact", DoorEntry[s])
				end
			end
		end
	end
	add(FrontDoorJoints, true)
	add(SlidingDoorJoints, false)
	DoorCheckTimer = 0
end

local function doorAttached(s)
	local b = GetShapeBody(s)
	for _, o in ipairs(GetJointedBodies(Heli) or {}) do if o == b then return true end end
	return false
end

--- E on a door: into the helicopter. Every second: detached doors lose their prompt.
function HeliV2_DoorEntry(dt)
	if not DoorEntry or HeliVehicle == 0 then return end
	DoorCheckTimer = DoorCheckTimer + dt
	if DoorCheckTimer > 1 then
		DoorCheckTimer = 0
		for s in pairs(DoorEntry) do
			if not IsHandleValid(s) or not doorAttached(s) then
				if IsHandleValid(s) then RemoveTag(s, "interact") end
				DoorEntry[s] = nil
			end
		end
	end
	-- (a player in a vehicle last tick pressed E to get out: that press does not count as a door press)
	WasInVehicle = WasInVehicle or {}
	for p in Players() do
		local inVehicle = GetPlayerVehicle(p) ~= 0
		if InputPressed("interact", p) and not inVehicle and not WasInVehicle[p] and GetPlayerHealth(p) > 0 then
			local s = GetPlayerInteractShape(p)
			if DoorEntry[s] and doorAttached(s) then SetPlayerVehicle(HeliVehicle, p) end
		end
		WasInVehicle[p] = inVehicle
	end
end

--------------------------------------------------------------------------------------------------- server: PointControl.lua / common.lua

-- (v2) PointControl.lua InitPointControl: "Take a ride" on one shape only, the largest of the pilot's head shapes
-- (v1 tagged all of them, head, jaw and two small blocks: the prompt showed in two places, user 2026-11-13;
-- original-mod bug, PointControl.lua unchanged since 9dde6dd). Any of them still starts the ride.
function InitPointControl()
    target = Vec(0,0,0)
    TargetSelectionMode = false
    PilotShapes = FindShapes("PilotHead")
    if IsHostile == false then
        local best, most = 0, -1
        for i = 1,#PilotShapes,1 do
            local n = GetShapeVoxelCount(PilotShapes[i])
            if n > most then best, most = PilotShapes[i], n end
        end
        if best ~= 0 then SetTag(best,"interact","Take a ride") end
    end
    MinHeightOffset = 10 --fly at least this much above the target (unless target is in air)

    Landing = false
    TravelHeightReached = false
    targetacquired = false
	targetreached = false
    CruisingAltitude = 0

    CruisingLastP = 0
    CruisingI = 0

    HeightChange = 1.5

    localTarget = Vec(0,0,0)
    PointTargetDist = 0

    TowardLastP = 0
    TowardI = 0
    TowardRightLastP = 0
    TowardRightI = 0

    LandingSpeed = 1 --m/s

    MoveWithoutYaw = false
    MinYawRange = 10
end

-- (v2) PointControl.lua TargetSelectionInputs: the keys of the player riding (Commander); v1: the one player.
function TargetSelectionInputs()
	if TargetSelectionMode == false then return end
	if IsHostile then return end
	local c = Commander
	if c == 0 then return end
	if IsFlying then
		if InputPressed("X", c) then
			QueryRejectSelf()
			target = GetTargetFromCamDir()

			FlyToTarget(target,nil,nil)
		end

		if InputPressed("Z", c) then
			TravelHeightReached = true
		end

		if InputPressed("C", c) then
			Landing = true
		end

		if InputPressed("ctrl", c) and TargetSelectionMode then
			CruisingAltitude = CruisingAltitude - HeightChange
		end
		if InputPressed("shift", c) and TargetSelectionMode then
			CruisingAltitude = CruisingAltitude + HeightChange
			Landing = false
		end
	end
end

-- (v2) common.lua GetAimPos: from the camera of the player riding (v1: GetCameraTransform, the one player).
function GetAimPos(MaxDist,MinDist)
	if MinDist == nil then MinDist =0 end
	local ct = GetPlayerCameraTransform(Commander)
	local forwardPos = TransformToParentPoint(ct, Vec(0, 0, -150))
	local LookPos = ct.pos
	local direction = VecSub(forwardPos, LookPos)
	local distance = VecLength(direction)
	local direction = VecNormalize(direction)
	if  MaxDist==nil then
		MaxDist = 1000
	end
	if MinDist>0 then
		LookPos = VecAdd(LookPos,VecScale(VecNormalize(direction),MinDist))
	end
	local hit, hitDistance,normal,shape = QueryRaycast(LookPos, direction, MaxDist)
	if hit then
		distance = hitDistance
	else
		distance = MaxDist
	end
	forwardPos = TransformToParentPoint(ct, Vec(0, 0, -distance))
	return forwardPos, hit, distance,shape
end

-- (v2) common.lua QueryRejectVehiclePlus for player p (v1: the one player). Also fixes the original's index into a nil
-- table when the body under the player had no joints.
function QueryRejectVehiclePlus(p)
	p = p or HeliTargetPlayer()
	local retval = GetPlayerVehicle(p)
	local jointedbodies = nil

	if retval == 0 then
		local pos = GetPlayerTransform(p).pos
		local hit, dist, normal, shape = QueryRaycast(pos, Vec(0,-1,0), 0.5)

		if hit then
			jointedbodies = GetJointedBodies(GetShapeBody(shape)) or {}
			jointedbodies[#jointedbodies+1] = GetShapeBody(shape)

			for i = 1,#jointedbodies,1 do
				retval = GetBodyVehicle(jointedbodies[i])
				if HasTag(jointedbodies[i],"Heli") then retval = -1 end
				if retval ~=0 then break end
			end
		end
	end

	if retval > 0 then
		QueryRejectVehicle(retval)
	elseif retval <0 then
		for i = 1,#jointedbodies,1 do
			QueryRejectBody(jointedbodies[i])
		end
	end

	return retval
end

--------------------------------------------------------------------------------------------------- server: AI_Gore.lua / AI.lua

-- (v2) AI_Gore.lua ai_gore_tick: a player target is the nearest living player it can see (v1: the one player),
-- picked again every second (the original's target timer) and whenever that player dies. The debug outline and
-- line are drawn by the clients (HeliV2_ClientOutline).
function ai_gore_tick()

    DistanceProgressed = GetFloat("savegame.mod.distanceProgressed")

    -- Find valid target
    ValidTargets = {}
    for index, _ in ipairs(ListKeys("level.goreai.api.npcs.alive")) do
        local torso = GetInt("level.goreai.api.npcs.alive" .. "." .. index)
        local team = GetTagValue(torso, "spawn_team")
        if team ~= Team then table.insert(ValidTargets, torso) end
    end

    -- Check if current target still valid.
    local isTargetAlive       = SelectedTarget.type == TargetTypes.torso and (TableContainsValue(ValidTargets, SelectedTarget.body))

    local givePlayerABreak    = SelectedTarget.type == TargetTypes.player and GetTime() - PlayerChangeTargetTimer > 0

    local shouldForgetTarget   = SelectedTarget.type == TargetTypes.torso and not isTargetAlive or givePlayerABreak

    -- Clear targets.
    if GetBool("level.goreai.resetTeams") then
        isTargetAlive     = false
        givePlayerABreak  = true
        shouldForgetTarget = true
        PlayerChangeTargetTimer = 0
    end

    -- Find random valid target
    TimerRunTime(CheckTargetTimer)
    local repick = TargetPlayer == nil or GetPlayerHealth(TargetPlayer) <= 0
    if TimerConsumed(CheckTargetTimer) or GetBool("level.goreai.resetTeams") then
        TimerResetTime(CheckTargetTimer)
        repick = true

        if #ValidTargets >= 1 and shouldForgetTarget then

            SelectedTarget = {
                type = TargetTypes.torso,
                body = ValidTargets[GetRandomIndex(ValidTargets)],
            }

        elseif #ValidTargets == 0 then

            SelectedTarget = {
                type = TargetTypes.player,
                body = nil,
            }

        elseif not isTargetAlive and math.random() < 1/#ValidTargets then

            SelectedTarget = {
                type = TargetTypes.player,
                body = 0,
            }

        end

    end
    if repick then TargetPlayer = HeliV2_PickPlayer() end

    -- Set target position
    if SelectedTarget.type == TargetTypes.torso then
        PlayerPos = AabbGetBodyCenterPos(SelectedTarget.body) -- Aim for npc torso.
        PlayerChangeTargetTimer = GetTime() + RandomSpreadPercent25(15)
    elseif SelectedTarget.type == TargetTypes.player then
        if TargetPlayer then
            PlayerPos = VecAdd(GetPlayerTransform(TargetPlayer).pos, Vec(0,1,0)) -- Attack the player as usual.
        end
    else
        PlayerChangeTargetTimer = GetTime() + RandomSpreadPercent25(15)
    end
end

-- (v2) AI.lua AIWaitForRockets: the target player's vehicle.
function AIWaitForRockets(dt)
	if PlayerFirstSeen == false then return end
	if AIRocketReady == false then
		AIRocketWaitTimer = AIRocketWaitTimer+dt
		PlayerVehicle = QueryRejectVehiclePlus(HeliTargetPlayer())
		if PlayerVehicle~= 0 then
			AIRocketWaitTimer = AIRocketWaitTimer+dt*2
		end

		if AIRocketWaitTimer>120 then AIRocketReady = true end
	end
end

-- (v2) AI.lua AimAndShootPlayer: the target player's vehicle (v1: the one player's).
function AimAndShootPlayer()

	AimTarget = ExpectedPos
	TurnTowardAimTarget()
	EnableGun = true
	TriggerHeld = TargetMiss<0.07
	AIActionShoot = "Shoot"

	local targetIsVehicleOrNPC = (SelectedTarget.type == TargetTypes.torso) or (SelectedTarget.type == TargetTypes.player and IsPlayerInVehicle(HeliTargetPlayer()))
	local lateGame = DistanceProgressed > ShootRocketsAtPlayer_Dist
	if TargetVisible and TargetDetected then
		if LeanForwardAmount<0.4 then
			if math.abs(GunPitch)<30 and TargetMiss<0.06 then
				EnableRocket = targetIsVehicleOrNPC or lateGame
			end
		end
	end

	if math.abs(GunPitch)<20 then
	RocketTriggerHeld = TargetMiss<0.03
	end
end

-- (v2) AI.lua MoveInRange: leads the target player's movement (v1: the one player's, also when hunting an NPC).
function MoveInRange()
	if AimTarget == nil then return end
	local reached = false
	if TargetDist2D<IdealMin then
		MovingInRange = Further
		AIAction = "Move further"
		AILastMove = "Move further"
	end
	if TargetDist2D>IdealMax then
		MovingInRange = Closer
		AIAction = "Move closer"
		AILastMove = "Move closer"
	end

	reached = MovingInRange == Closer and TargetDist2D<IdealRange
	if MovingInRange == Further and TargetDist2D>IdealRange then reached = true end
	if reached then
		MovingInRange = 0
		AIAction = "got in range"
		AILastMove = "got in range"
	end

	if MovingInRange == 0 then return end

	local predicttime = 0.5
	local tgtpred = VecAdd(AimTarget,VecScale(GetPlayerVelocity(HeliTargetPlayer()),predicttime))
	local helipos = VecAdd(HeliTr.pos,VecScale(HeliVel,predicttime))

	TargetVec = VecSub(tgtpred,helipos)
	local dir = Vec2D(TargetVec)
	TargetDist2D = VecLength(dir)
	dir = VecNormalize(dir)

	local tgt = VecAdd(helipos, VecScale(dir,TargetDist2D-IdealRange))

	tgt[2] = HeliTr.pos[2]-MinHeightOffset

	FlyToTarget(tgt,nil,nil)
end

-- (v2) AI.lua TargetCheck: the target player's vehicle and speed (v1: the one player's).
function TargetCheck()

	if NoCheckFrame() then return end

	--actual detection
	local SourcePos = HeliTr.pos
	TargetVisible = false

	QueryRejectSelf()
	TargetVec = VecSub(PlayerPos,SourcePos)
	local TargetDir = VecNormalize(TargetVec)
	local TargetDistance = VecLength(TargetVec)

	TargetDist2D = VecLength(Vec2D(TargetVec))

	--do not count being inside a vehicle as hiding
	PlayerVehicle = QueryRejectVehiclePlus(HeliTargetPlayer())
	QueryRejectSelf()
	local hit, dist, normal, shape = QueryRaycast(PlayerPos, VecScale(TargetDir,-1), TargetDistance*1.2, 0, 1)

	if hit then
		if dist> TargetDistance-0.5 then
			TargetVisible = true
		end
	else
		TargetVisible = true
	end

	local Visibility = 0
	if TargetVisible then
		Visibility = 1

		local environmentalvisibility = 1
		if GetBool("level.IsSandstorm") then environmentalvisibility = environmentalvisibility*0.5 end
		if GetString("level.dayphase") == "Night" then environmentalvisibility = environmentalvisibility*0.66 end
		Visibility = Visibility*environmentalvisibility

		local FarDist = 50
		if TargetDistance>FarDist then
			Visibility = Visibility*FarDist/TargetDistance
		end

		local FacingAway =VecFacingDifference(Axes[Forward],VecScale(TargetDir,-1),Axes[Right],Axes[Upward])
		FacingAway = MapValues(math.abs(FacingAway),0.3,0.75,0,0.3)
		Visibility = Visibility*(1-FacingAway)

		if PlayerVehicle~=0 then Visibility = Visibility*1.6 end

		local v = VecLength(GetPlayerVelocity(HeliTargetPlayer()))
		v = MapValues(v,0.5,7,0,0.6)
		Visibility = Visibility*(1+v)
	end

	if TargetVisible then
		DetectionMeter = DetectionMeter + 1/TargetAcquiredTime *DetectionCounterMax*Visibility
	else
		DetectionMeter = DetectionMeter - 1/TargetLostTime *DetectionCounterMax
	end

	DetectionMeter = math.clamp(DetectionMeter, 0, 1)
	--change in detection state
	if DetectionMeter == 0 and TargetDetected then
		TargetDetected = false
		LostTarget = true
		AIAction = "Lost Target"
	elseif DetectionMeter == 1 and TargetDetected == false then
		TargetDetected = true
		AIAction = "Found target"
		TargetReached()
		PlayerFirstSeen = true
	end
end

--------------------------------------------------------------------------------------------------- server: Weapons.lua

-- (v2) Weapons.lua GunImputs: the pilot's left mouse button, aimed at the point under the pilot's crosshair (sent
-- by the pilot's client; v1: 4 m ahead of the gun along the camera, turned 10 degrees down).
function GunImputs()
    if DetailedControl == false or PilotId == 0 then return end
    TriggerHeld = PilotKeys.lmb
    if IsGunBroken then TriggerHeld = false end

    if TriggerHeld then
        if GunTimer<1 then
            GunTimer = GunTimer + 1/(GunStartupTime*60)
        else
            EnableGun = true
        end
    else
        if EnableGun==false then
            if GunTimer>0 then
                GunTimer = 0
            end
        else
            if GunTimer ~= 0 then
                GunTimer = GunTimer - 1/(GunSwitchOffTime*60)
                if GunTimer<0 then
                    GunTimer =0
                    EnableGun = false
                    AimTarget = nil
                    SetJointMotorTarget(GunHinge,0,5)
                end
            end
        end
    end

    if EnableGun and PilotAimPoint then
        AimTarget = PilotAimPoint
    end
end

-- (v2) Weapons.lua RocketImputs: the pilot's right mouse button, at the point under the crosshair (v1: the camera
-- ray turned 3 degrees up).
function RocketImputs()
    if DetailedControl == false or PilotId == 0 then return end
    RocketTriggerHeld = PilotKeys.rmb
    if IsRocketBroken then RocketTriggerHeld = false end

    if RocketTriggerHeld then
        if RocketTimer<1 then
            RocketTimer = RocketTimer + 1/(RocketStartupTime*60)
            EnableRocket = false
        else
            EnableRocket = true
        end
    else
        if EnableRocket==false then
            if RocketTimer>0 then
                RocketTimer = 0
            end
        else
            if RocketTimer ~= 0 then
                RocketTimer = RocketTimer - 1/(RocketSwitchOffTime*60)
                if RocketTimer<0 then
                    RocketTimer =0
                    EnableRocket = false
                    AimTarget = nil
                end
            end
        end
    end

    if EnableRocket and PilotAimPoint then
        AimTarget = PilotAimPoint
    end
end

-- (v2) Weapons.lua ShootGun: muzzle flash, light and sound on every client (client.heliShot, which also draws the
-- tracer); the bullet itself as before.
function ShootGun()

    if GunShotCooldown > 0 then
        GunShotCooldown = GunShotCooldown-1
        return
    end

    if EnableGun == false then return end

    --direction of target regardless of gunfacing
    local tdir = TransformToLocalVec(GunTr,VecSub(AimTarget,GunTr.pos))

    local spread1 = LogisticRandom(AimSpread*1.5)
    local spread2 = LogisticRandom(AimSpread*1.5)

    tdir = VecScale(tdir,1/tdir[3])
    local tdirwitherror = tdir
    tdirwitherror[1] = tdirwitherror[1]+spread1
    tdirwitherror[2] = tdirwitherror[2]+spread2

    local d = math.abs(tdirwitherror[2]) --d is a measure of how close the gun is to aim at the target
    --0 exactly aiming there, 1 at least 90deg away
    if math.abs(tdirwitherror[1])>d then d = math.abs(tdirwitherror[1]) end
    TargetMiss = d

    if LastFrameGunEnabled == false then return end
    if TriggerHeld == false then return end
    GunShotCooldown = GunShotCoolDownMax

    local m1 = 0.01
    local m2 = 0.03

    local dir = {}
    dir = Vec(0,0,1)
    if d<m1 then
        dir = tdir
    elseif d>m2 then
        dir = Vec(0,0,1)
    else
        dir = VecLerp(tdir,Vec(0,0,1),(d-m1)/(m2-m1))
    end
    dir[1] = dir[1]+spread1
    dir[2] = dir[2]+spread2

    dir = TransformToParentVec(GunTr,dir)

    -- (v2) player pilot: at the point under the crosshair while the gun points roughly there (test 2026-11-13: the
    -- gun swings a little on its mount, and its bullets went where it pointed, beside the crosshair); the original's
    -- spread stays. The AI keeps the original: at the target only within 0.01-0.03 of it, else along the barrel.
    if PilotId ~= 0 and d < HELI_GUN_CONE then
        local start = TransformToParentPoint(GunTr, Vec(0, 0, 0.6))
        dir = VecNormalize(VecAdd(VecNormalize(VecSub(AimTarget, start)), TransformToParentVec(GunTr, Vec(spread1, spread2, 0))))
    end

    heliprojectileHandler.shells[heliprojectileHandler.shellNum] = deepcopy(heliprojectileHandler.defaultShell)
    loadedShell = heliprojectileHandler.shells[heliprojectileHandler.shellNum]
    loadedShell.active = true
    loadedShell.pos = TransformToParentPoint(GunTr, Vec(0, 0, 0.6))
    loadedShell.momentum = maxMomentum
    loadedShell.predictedBulletVelocity = VecScale(dir, velocity)
    heliprojectileHandler.shellNum = (heliprojectileHandler.shellNum%#heliprojectileHandler.shells) + 1

    local barrelend = TransformToParentPoint(GunTr, Vec(0, 0, 0))
    ClientCall(0, "client.heliShot", barrelend, VecNormalize(dir), loadedShell.pos)
end

-- (v2) Weapons.lua ProjectileOperations: the world part (holes, impulses, NPC and player damage, blood); tracers,
-- impact particles and sounds are the clients' (HeliV2_ClientShells). Player damage: every player (v1: the one),
-- through that player's own hitboxes, only where that player has a set (v1 errored without hitboxes).
function ProjectileOperations(projectile)
    projectile.predictedBulletVelocity = VecScale(projectile.predictedBulletVelocity, (1-drag*GetTimeStep()*VecLength(projectile.predictedBulletVelocity)/velocity))
    projectile.predictedBulletVelocity = VecAdd(projectile.predictedBulletVelocity, (VecScale(gravity, GetTimeStep())))
    local point2 = VecAdd(projectile.pos, VecScale(projectile.predictedBulletVelocity, GetTimeStep()))
    local dir = VecNormalize(VecSub(point2, projectile.pos))
    local hit, dist, normal, shape = QueryRaycast(projectile.pos, dir, VecLength(VecSub(point2, projectile.pos)))

    if hit then
        hitPos = VecAdd(projectile.pos, VecScale(VecNormalize(VecSub(point2, projectile.pos)), dist))
        point2 = hitPos
        local mat, r, g, b, a = GetShapeMaterialAtPosition(shape, hitPos)

        -- NPC DAMAGE START
        local damage_from_player_gun = pdamage
        local hitBody = GetShapeBody(shape) -- raycast hit shape
        if HasTag(hitBody, "gore_id") and not projectile.hit_npc then
            local path_damage = "level.goreai.body_damage_npc." .. hitBody
            local damage = tonumber(GetFloat(path_damage)) + damage_from_player_gun
            SetFloat(path_damage, damage) -- Specific damage to each body by handle.
            Blood_Pop(hitPos, 5, 7)
            projectile.hit_npc = true
        end
        -- NPC DAMAGE END

        if mat == "metal" or mat == "heavymetal" or mat == "hardmetal" then
            bounceangle = 5*projectile.momentum
        else
            bounceangle = 3*projectile.momentum
        end

        if VecLength(VecSub(projectile.pos, hitPos)) < 0.04 then
            projectile.active = false
            projectile.momentum = 0
        end

        local RHA = 0
        if HasTag(shape, "RHA") then
            RHA = GetTagValue(shape, "RHA") or 0
        end
        projectile.momentum = projectile.momentum - RHA/4

        local hitangle = math.acos(VecDot(projectile.predictedBulletVelocity, normal)/VecLength(projectile.predictedBulletVelocity))*57.3-90
        if hitangle < bounceangle and math.random(0, 100)/100 > (hitangle/bounceangle)^2 then
            local dot = VecDot(normal, projectile.predictedBulletVelocity)
            projectile.predictedBulletVelocity = VecSub(projectile.predictedBulletVelocity, VecScale(normal, dot*(1+math.random(1,10)/10)))
        else
            ApplyBodyImpulse(GetShapeBody(shape), hitPos, VecScale(projectile.predictedBulletVelocity, projectile.momentum/10))

            if mat == "glass" then
                if math.random() > 0.65 then MakeHole(hitPos, 0.75) end
                projectile.momentum = projectile.momentum - 0.2
            elseif mat == "metal" or mat == "heavymetal" or mat == "hardmetal" then
                if mat == "hardmetal" then
                    projectile.momentum = projectile.momentum - 2
                else
                    projectile.momentum = projectile.momentum - 1
                end
                if mat == "hardmetal" and math.random() > lvl5armor^(maxMomentum/projectile.momentum) then
                    projectile.momentum = 0
                elseif mat == "metal" and math.random() > lvl3armor^(maxMomentum/projectile.momentum) then
                    projectile.momentum = 0
                end
            else
                if mat == "hardmasonry" then
                    if math.random() > lvl4armor^(maxMomentum/projectile.momentum) then projectile.momentum = 0 end
                    projectile.momentum = projectile.momentum - 0.8
                elseif mat == "concrete" then
                    if math.random() > lvl2armor^(maxMomentum/projectile.momentum) then projectile.momentum = 0 end
                    projectile.momentum = projectile.momentum - 0.5
                elseif mat == "masonry" then
                    if math.random() > lvl1armor^(maxMomentum/projectile.momentum) then  projectile.momentum = 0 end
                    projectile.momentum = projectile.momentum - 0.6
                elseif mat == "grass" then
                    projectile.momentum = projectile.momentum - 0.6
                elseif mat == "wood" then
                    projectile.momentum = projectile.momentum - 0.4
                elseif mat == "dirt" then
                    projectile.momentum = projectile.momentum - 0.4
                else
                    projectile.momentum = projectile.momentum - 0.5
                end
            end

            for p in Players() do
                if GetPlayerHealth(p) > 0 then
                    local Player
                    if GetPlayerVehicle(p) == 0 then
                        Player = VecAdd(GetPlayerTransform(p).pos, Vec(0, 1, 0))
                    else
                        Player = VecAdd(GetPlayerTransform(p).pos, Vec(0, -0.4, 0))
                    end
                    local Relative = VecSub(Player, point2)
                    local Lookback = VecScale(VecNormalize(VecSub(point2,projectile.pos)), VecDot(Relative, VecNormalize(VecSub(point2,projectile.pos))))
                    local Range = VecSub(Player, VecAdd(point2, Lookback))

                    if VecLength(Range) < .5 and projectile.momentum ~= 0 then
                        local Hitboxes = HeliV2_Hitboxes(p)
                        if #Hitboxes >= 2 then
                            local r = math.random(0,100)/100
                            local headshot = r>0.99
                            local i = math.random(2,#Hitboxes)
                            local ishead = GetTagValue(Hitboxes[i], "hitbox") == "HEAD"
                            if ishead == headshot then
                                SetTag(Hitboxes[i], "QueriedDamage", playerDamage)
                            elseif headshot then
                                i = 1
                                SetTag(Hitboxes[i], "QueriedDamage", playerDamage)
                            end
                        end
                    end
                end
            end

            if projectile.momentum > 0 then
                MakeHole(hitPos, damage, damage*0.85, damage*0.7)
            end

            if HasTag(shape, "unbreakable") or HasTag(GetShapeBody(shape), "unbreakable") or mat == "heavymetal" or mat == "rock" then
                projectile.momentum = 0
                projectile.active = false
            end
        end
    else
        point2 = VecAdd(projectile.pos, VecScale(projectile.predictedBulletVelocity, GetTimeStep()))
    end

    if projectile.momentum < 0.1 or projectile.pos[2] < -50 then
        projectile.active = false
    end

    projectile.pos = point2
end

--------------------------------------------------------------------------------------------------- server: Damage.lua

-- (v2) Damage.lua ManageEngineSmoke: the clients make the smoke (shared.heSmoking).
function ManageEngineSmoke() end

--- Damage.lua CriticalAlert's condition (the alarm sound is the clients').
function HeliV2_Critical()
    if IsFlying == false then return false end
    if ConsoleBroken then return false end
    if BrokenLiftOffTimeUp then return false end
    return HasPilot == false or TooDamaged or RotorGone or SRotorGone
end

-- (v2) Damage.lua CriticalAlert: the red cabin lights here, the alarm on the clients.
function CriticalAlert()
    if HeliV2_Critical() then
        for i=1,#InternalLights do
            SetLightColor(InternalLights[i], 1, 0, 0)
        end
    end
end

-- (v2) Damage.lua ManageCrash: the crash sound on the clients (client.heliCrash, inside or outside sound per player).
function ManageCrash()
    if BrokenLiftoffAttempt or TooDamaged then
        if GetBodyTransform(Heli).pos[2] < CrashAltitude or IsHandleValid(Heli)==false then
            RotorGone = true
            IsCrashed = true
            IsFlying = false
        end
    end
    if IsCrashed == false then return end
    LostControl()
    if IsHandleValid(Heli) == false then PlayedCrashSound = true end
    if not PlayedCrashSound and not brokenliftoffattempt then
        PlayedCrashSound = true
        ClientCall(0, "client.heliCrash")
    end
end

--------------------------------------------------------------------------------------------------- clients

function HeliV2_ClientInit()
	ControlPanel = FindShape("panel_left")
	InternalTrigHalf = Vec(1, 0.75, 1.3) -- the "internal" trigger: box, size 2 1.5 2.6 in the XML (centred)
	ClientShells = {}
	ShootSound = LoadSound("chopper-shoot0.ogg")
	-- impact sounds: the original's bullet code played these globals but never loaded them (silent in v1); the
	-- player guns' files (gunfunctions.lua GunFunctions_LoadSounds)
	dirtimpact = LoadSound("MOD/snd/Projectiles/Impacts/materials/blt_imp_dirt_0.ogg")
	foliageimpact = LoadSound("MOD/snd/Projectiles/Impacts/materials/blt_imp_foliage_0.ogg")
	glassimpact = LoadSound("MOD/snd/Projectiles/Impacts/materials/blt_imp_glass_auto_0.ogg")
	gravelimpact = LoadSound("MOD/snd/Projectiles/Impacts/materials/blt_imp_gravel_0.ogg")
	masonryimpact = LoadSound("MOD/snd/Projectiles/Impacts/materials/blt_imp_masonry_0.ogg")
	softmetalimpact = LoadSound("MOD/snd/Projectiles/Impacts/materials/blt_imp_metal_auto_0.ogg")
	hardmetalimpact = LoadSound("MOD/snd/Projectiles/Impacts/materials/blt_imp_metal_thick_0.ogg")
	woodimpact = LoadSound("MOD/snd/Projectiles/Impacts/materials/blt_imp_wood_0.ogg")
	headimpact = LoadSound("MOD/snd/Projectiles/Impacts/bullet_flesh_plr_head_0.ogg")
	bodyimpact = LoadSound("MOD/snd/Projectiles/Impacts/blt_imp_flesh_kill_head_accent_0.ogg")
	IsEngineOn, IsHostile, ShutOff, IsCrashed, RotorGone = false, true, false, false, false
	EngineHealth, TotalDamage, MRotSpeedFraction = 1, 0, 0
	Inside, Near = false, false
end

--- The server's state as the original's globals (the sound / prompt code reads them).
function HeliV2_ClientState()
	HeliTr = GetBodyTransform(Heli)
	HeliCoM = TransformToParentPoint(HeliTr, GetBodyCenterOfMass(Heli))
	IsEngineOn = shared.heEngineOn == true
	IsHostile = shared.heHostile ~= false
	ShutOff = shared.heShutOff == true
	IsCrashed = shared.heCrashed == true
	RotorGone = shared.heRotorGone == true
	EngineHealth = shared.heEngineHealth or 1
	TotalDamage = shared.heTotalDamage or 0
	MRotSpeedFraction = shared.heRot or 0
	Fuelamount = shared.heFuel or 540
	FuelCapacity = shared.heFuelCap or 540
	TargetSelectionMode = shared.heRide == true
	GunTimer = shared.heGunTimer or 0
	RocketTimer = shared.heRocketTimer or 0
end

--- (v2) Heli.lua WorldVariables' last part: is this player's camera inside the cabin (inside / outside engine sound).
--- v1 moved the trigger onto the cabin every frame; a client cannot move it, so the box is tested here.
function HeliV2_ClientInside()
	local t = TransformToParentTransform(HeliTr, InternalTrigLocalTr)
	local p = TransformToLocalPoint(t, GetCameraTransform().pos)
	Inside = math.abs(p[1]) <= InternalTrigHalf[1] and math.abs(p[2]) <= InternalTrigHalf[2] and math.abs(p[3]) <= InternalTrigHalf[3]
	-- Inputs.lua CheckIfNear (for the prompts)
	Near = VecLength(VecSub(GetShapeWorldTransform(ControlPanel).pos, GetPlayerTransform().pos)) < 3
end

--- 60 Hz effects: engine smoke (Damage.lua ManageEngineSmoke) and the alarm (CriticalAlert).
function HeliV2_ClientEffects()
	if shared.heSmoking then
		smoke(TransformToParentPoint(HeliTr, LocalPoint(SmokePosLocal)), MRotSpeedFraction)
	end
	if shared.heCritical then
		PlayLoop(Sound_Critical, TransformToParentTransform(HeliTr, CriticalLocalTr).pos, 1)
	end
end

function client.heliCrash()
	if not IsHandleValid(Heli) then return end
	if Inside then
		PlaySound(Sound_Crash_In, HeliCoM)
	else
		PlaySound(Sound_Crash_Out, HeliCoM)
	end
end

local SHELL_VEL, SHELL_DRAG, SHELL_G = 850, 1.7, { 0, -10, 0 } -- Weapons.lua InitGun (velocity, drag, gravity)

--- A shot from the helicopter's gun: Weapons.lua ShootGun's flash, light and sound; the tracer follows.
function client.heliShot(barrelend, dir, start)
	ParticleReset()
	SpawnParticle("smoke", barrelend, VecScale(dir, 0.02), 0.3, 0.3)
	ParticleReset()
	ParticleType("plain")
	ParticleTile(5)
	ParticleColor(1, 0.6, 0.4, 1, 0.3, 0.2)
	ParticleRadius(0.1)
	ParticleEmissive(5, 1)
	SpawnParticle("smoke", barrelend, VecScale(dir, 0.02), 0.3, 0.3)
	ParticleReset()
	ParticleType("plain")
	ParticleTile(6)
	ParticleSticky(0, 0)
	ParticleRadius(0.0075, 0.0075)
	ParticleAlpha(1, 0)
	ParticleEmissive(10, 10)
	ParticleColor(1, 0.75, 0.25, 1, 0.25, 0.25)
	ParticleGravity(-10)
	ParticleCollide(0)
	for i = 1, math.random(8, 16) do
		SpawnParticle(barrelend, VecAdd(VecScale(dir, 25), Vec((math.random(-100,100)/100)*4,(math.random(-100,100)/100)*4, (math.random(-100,100)/100)*4)), 0.1)
	end
	PointLight(barrelend, 1, 0.75, 0.25, 1)
	PlaySound(ShootSound, barrelend, 25)
	ClientShells[#ClientShells + 1] = { pos = start, vel = VecScale(dir, SHELL_VEL) }
end

local function impactFx(hitPos, mat, r, g, b, a, body)
	if HasTag(body, "Head") then
		PlaySound(headimpact, hitPos, 0.8)
	elseif HasTag(body, "bodypart") then
		PlaySound(bodyimpact, hitPos, 0.8)
	end
	if HasTag(body, "gore_id") and Settings.game.blood_and_gore.value then
		ParticleReset()
		ParticleType("plain")
		ParticleTile(6)
		ParticleSticky(0, 0)
		ParticleRadius(RandomSpreadPercent25(0.03), 0.01)
		ParticleAlpha(1, 0)
		ParticleEmissive(0.2)
		ParticleColor(0.7, 0.1, 0.1, 0.7, 0, 0)
		ParticleGravity(-10, -10)
		ParticleCollide()
		for i = 1, math.random(10, 50) do
			SpawnParticle(hitPos, Vec((math.random(-100,100)/100)*5,(math.random(-100,100)/100)*5, (math.random(-100,100)/100)*5), math.random(10,25)/20)
		end
	end
	if mat == "glass" then
		PlaySound(glassimpact, hitPos, 0.5)
	elseif mat == "metal" or mat == "heavymetal" or mat == "hardmetal" then
		SpawnParticle("smoke", hitPos, Vec(0, 1.0+math.random(1,10)*0.1, 0), 0.15, 1)
		ParticleReset()
		ParticleType("plain")
		ParticleTile(6)
		ParticleSticky(0, 0)
		ParticleRadius(0.01, 0.01)
		ParticleAlpha(1, 0)
		ParticleEmissive(10, 10)
		ParticleColor(1, 0.75, 0.25, 1, 0.25, 0.25)
		ParticleGravity(-10, -10)
		for i = 1, math.random(10, 50) do
			SpawnParticle(hitPos, Vec((math.random(-100,100)/100)*5,(math.random(-100,100)/100)*5, (math.random(-100,100)/100)*5), math.random(10,25)/20)
		end
		PointLight(hitPos, 1, 0.75, 0.25, 0.25)
		PlaySound(mat == "metal" and softmetalimpact or hardmetalimpact, hitPos, 0.5)
	else
		ParticleReset()
		ParticleType("plain")
		ParticleTile(6)
		ParticleSticky(0.1)
		ParticleRadius(0.05, 0)
		ParticleAlpha(a)
		ParticleEmissive(0, 0)
		ParticleColor(r, g, b, r, g, b)
		ParticleGravity(-10, -10)
		for i = 1, math.random(10, 50) do
			ParticleRadius(math.random()/50+0.025, 0)
			SpawnParticle(hitPos, Vec((math.random(-100,100)/100)*5,(math.random(-100,100)/100)*5, (math.random(-100,100)/100)*5), math.random(10,25)/10)
		end
		for i = 1, math.random(1,5) do
			ParticleTile(3)
			ParticleRadius(0.35, 0.5)
			ParticleAlpha(a, 0)
			ParticleGravity(-3, -3)
			ParticleDrag(0.5)
			SpawnParticle(hitPos, Vec((math.random(-100,100)/100),(math.random(-100,100)/100)*2, (math.random(-100,100)/100)), math.random(10,25)/10)
		end
		local snd = gravelimpact
		if mat == "hardmasonry" or mat == "masonry" then snd = masonryimpact
		elseif mat == "concrete" then snd = softmetalimpact
		elseif mat == "grass" then snd = foliageimpact
		elseif mat == "wood" then snd = woodimpact
		elseif mat == "dirt" then snd = dirtimpact end
		PlaySound(snd, hitPos, 0.5)
	end
end

--- The tracers of the helicopter's bullets (Weapons.lua ProjectileOperations' drawing), each client on its own:
--- same flight (drag, gravity), drawn until the first hit, where the impact effect plays (ricochets are the
--- server's; their tracers are not drawn).
function HeliV2_ClientShells()
	local dt = GetTimeStep()
	local keep = {}
	for _, s in ipairs(ClientShells) do
		s.vel = VecScale(s.vel, (1 - SHELL_DRAG * dt * VecLength(s.vel) / SHELL_VEL))
		s.vel = VecAdd(s.vel, VecScale(SHELL_G, dt))
		local p2 = VecAdd(s.pos, VecScale(s.vel, dt))
		local seg = VecSub(p2, s.pos)
		local len = VecLength(seg)
		local alive = true
		if len > 0 then
			local hit, dist, normal, shape = QueryRaycast(s.pos, VecScale(seg, 1 / len), len)
			if hit then
				p2 = VecAdd(s.pos, VecScale(seg, dist / len))
				DrawLine(s.pos, p2, 0.9, 0.8, 0.6, 0.8)
				local mat, r, g, b, a = GetShapeMaterialAtPosition(shape, p2)
				impactFx(p2, mat, r, g, b, a, GetShapeBody(shape))
				alive = false
			else
				DrawLine(s.pos, p2, 0.9, 0.8, 0.7, 0.8)
			end
		end
		s.pos = p2
		if alive and s.pos[2] > -50 and len > 0.01 then keep[#keep + 1] = s end
	end
	ClientShells = keep
end

--- AI_Gore.lua's debug outline (debug menu "outlines") on the clients.
function HeliV2_ClientOutline()
	if GetBool("savegame.mod.config.goreai.outlines") then
		local team = GetTagValue(Heli, "team")
		local t = NPC_TEAMS[team] or NPC_TEAMS.none
		local c = t.color
		DrawBodyOutline(Heli, c[1], c[2], c[3], 1/2)
	end
end

-- (v2) Inputs.lua InitUi: client.
function InitUi()
	ShowControlCounter = 0
	ShowControlTime = 15
	ControlFadeTime = 1.5
end

-- (v2) Inputs.lua ControlPrompts on each client: fuel and "not controlled" near the dashboard, the ride controls
-- for the player riding (the pilot's controls: HeliPilot_ClientDraw). Texts for the pilot seat instead of the
-- dashboard.
function ControlPrompts()
	if SwitchOffPrompts then return end
	if IsCrashed then return end
	local me = GetLocalPlayer()
	local riding = TargetSelectionMode and shared.heCommander == me
	if riding and not WasRiding then ShowControlCounter = ShowControlTime*60 end
	WasRiding = riding
	if (shared.hePilot or 0) == me and me ~= 0 then return end

	UiPush()
	UiAlign("center top")
	UiTranslate(900, 20)
	UiFont("bold.ttf", 30)
	UiColor(1 - Fuelamount/FuelCapacity,0, 0)
	if Near then
		UiText("Fuel:  "..math.floor(Fuelamount))
	end
	UiTranslate(0, 25)
	UiFont("bold.ttf", 30)

	if TargetSelectionMode == false and (shared.hePilot or 0) == 0 then
		if Near then
			UiColor(1,0,0)
			UiText("helicopter isnt currently controlled, get in the pilot seat (front left)")
		end
	elseif riding and ShowControlCounter>0 then
		UiAlign("left bottom")
		local rowheight = 26
		ShowControlCounter = ShowControlCounter-1
		local col = ShowControlCounter/ControlFadeTime/60
		UiColorFilter(1, 1, 0,col)
		UiTranslate(-900+20, UiHeight()-300) -- 245 puts it above the Ui for Mors Longa
		UiTranslate(0, -rowheight*(4+2))
		UiColor(0,1,0)
		UiText("Press X to select helicopter destination")
		UiTranslate(0, rowheight)
		UiText("Press Z to go immediately before reaching cruising altitude")
		UiTranslate(0, rowheight)
		UiText("Tap Shift/Ctrl to adjust the cruising altitude")
		UiTranslate(0, rowheight)
		UiText("Press C to Auto land (after reached destination)")
	end

	UiPop()
end

-- AS350 player flight, v2 port 2026-11-13 (new; user decision "Mouse-aim like reference": the original's player
-- control was the AI's PID autopilot driven by W/S/A/D speed targets and the camera heading, which the user found
-- poor). Idea after Kooshing's Dynamic Aircraft (Workshop 3729840632, its UH-1: the helicopter turns toward the
-- mouse aim; W/S lift; A/D roll); no code taken from it.
--
-- Pilot controls: the mouse moves the view; the helicopter turns its nose toward the view's heading and pitches to
-- the view's elevation (look down to fly forward, at the horizon to hover, up to slow down / back up), banking into
-- turns by itself. W / S: climb / descend (released: hold the height). A / D: sideways (roll). Left mouse: machine
-- gun, right mouse: rockets, both at the point under the crosshair. Mouse wheel: zoom (all the way in: cockpit view).
-- Server: HeliPilot_Flight (server.update) applies lift and drag and sets the body's turn rate; the rotor's spin
-- (MRotSpeedFraction, start-up and damage) scales both, so a dead or stopped rotor gives no control.
-- Client: the pilot's camera (own look from the mouse, like scripts/MountedGun.lua), aim sent every tick
-- (server.heliAim), crosshair, nose marker and controls.

-- tuning (in-game values to be adjusted after tests)
HELI_CLIMB = 6           -- m/s up while W is held
HELI_SINK = 5            -- m/s down while S is held
HELI_VKP = 1.5           -- 1/s: how hard the lift corrects toward that vertical speed
HELI_MAX_LIFT = 2.0      -- lift limit, times the weight
HELI_PITCH_GAIN = 1.2    -- nose pitch per degree of view elevation
HELI_PITCH_DOWN = 35     -- deg: most nose-down
HELI_PITCH_UP = 25       -- deg: most nose-up
HELI_BANK_GAIN = 1.0     -- deg of bank per degree of heading still to turn
HELI_BANK = 30           -- deg: most bank from turning
HELI_STRAFE_ROLL = 20    -- deg of roll with A / D
HELI_TURN_GAIN = 3.0     -- rad/s per radian of attitude error
HELI_MAX_RATE = 1.6      -- rad/s: fastest turn
HELI_RATE_RESP = 30      -- 1/s: how fast the turn rate follows (test 2, 2026-11-13: 6 = 10 % per update let any
                         -- steady push lean the helicopter far; user: strong lean / yaw at first)
HELI_ATT_AUTH = 2.0      -- attitude control reaches full strength at half the rotor's power (was: in step with it)
HELI_CAM_UP = 2.0        -- m: third-person camera raised above the view line ...
HELI_CAM_UP_PER_M = 0.2  -- ... plus this per metre of zoom (zoom 10: 4 m up), so the tail sits below the crosshair
HELI_DEBUG = false      -- flight readout for the pilot (DebugWatch "heli ..." lines; test 2, off since test 4)
HELI_TILT_I = 2.0        -- 1/s^2: correction of a lasting pitch / roll offset (a heavier side)
HELI_TILT_I_MAX = 0.5    -- limit of that correction (rad*s)
HELI_DRAG_LIN = 0.05     -- horizontal air drag (1/s) ...
HELI_DRAG_QUAD = 0.0025  -- ... and per m/s (top speed about 44 m/s at full nose-down)
HELI_GROUND_RAY = 2.2    -- m below the centre of mass: "on the ground" (levels the helicopter instead of pitching)

local function clamp(v, a, b) return math.max(a, math.min(b, v)) end

--------------------------------------------------------------------------------------------------- server

function HeliPilot_ServerInit()
	PilotKeys = {}
	HeliPilot_UpdateMass()
end

--- The helicopter's mass with everything jointed to it (rotor, gun, doors, landing gear).
function HeliPilot_UpdateMass()
	HeliPilotBodies = { Heli }
	local m = GetBodyMass(Heli)
	for _, b in ipairs(GetJointedBodies(Heli) or {}) do
		m = m + GetBodyMass(b)
		HeliPilotBodies[#HeliPilotBodies + 1] = b
	end
	HeliPilotMass = math.max(m, 1)
	HeliPilotMassTimer = 0
end

--- Centre of mass of the body and everything jointed to it (first in-game test 2026-11-13: both helicopters leaned
--- left all the time; the lift pushed at the main body's own centre, while the gun (left side) and other parts hang
--- off it. Not measured which part weighs how much.)
local function systemCoM()
	local sum, m = Vec(), 0
	for _, b in ipairs(HeliPilotBodies or { Heli }) do
		if IsHandleValid(b) then
			local bm = GetBodyMass(b)
			local c = TransformToParentPoint(GetBodyTransform(b), GetBodyCenterOfMass(b))
			sum = VecAdd(sum, VecScale(c, bm))
			m = m + bm
		end
	end
	if m <= 0 then return HeliCoM end
	return VecScale(sum, 1 / m)
end

--- The pilot's keys (server.tick; the flight runs in server.update).
function HeliPilot_ReadKeys(p)
	PilotKeys = {
		up = InputDown("up", p), down = InputDown("down", p),
		left = InputDown("left", p), right = InputDown("right", p),
		lmb = InputDown("lmb", p), rmb = InputDown("rmb", p),
	}
end

--- A player took the pilot seat.
function HeliPilot_Reset()
	PilotKeys = {}
	HeliAttI = Vec()
	HeliPilot_UpdateMass()
end

local function grounded(vt)
	if vt > 0 then return false end
	if VecLength(HeliVel) > 3 then return false end
	QueryRejectSelf()
	local hit = QueryRaycast(HeliCoM, Vec(0, -1, 0), HELI_GROUND_RAY)
	return hit
end

--- The pilot left: the original autopilot (Control.lua) takes over, heading as it is (YawVector points away from the
--- nose: VecFacingDifference settles with the nose opposite to it). In the air its collective starts at the hover
--- value (its lift impulse per update is RotorForce * Collective * rotor fraction * rotor health), so it holds there;
--- on the ground at the bottom, so its landing check (CheckLanding) shuts the engine down as in the original, where
--- the player landed with Ctrl before letting go.
function HeliPilot_HandOver()
	local back = VecScale(Axes[Forward], -1)
	back[2] = 0
	if VecLength(back) > 0.1 then YawVector = VecNormalize(back) end
	if grounded(0) then
		Collective = -1.8
	else
		local lift = RotorForce * clamp(MRotSpeedFraction or 0, 0.05, 4) * math.max(MRotorHealth or 1, 0.05)
		Collective = clamp(HeliPilotMass * 10 / 60 / lift, -1.8, 1.8)
	end
	CollectiveI, CollectiveLastP = 0, HeliVel[2]
	MoveForwardI, MoveRightI, YawI, LeanForwardI, LeanRightI = 0, 0, 0, 0, 0
	MoveForwardLastP, MoveRightLastP, YawLastP = 0, 0, 0
	MoveForwardOffset, MoveSideOffset, CollectiveOffset = 0, 0, 0
	PilotKeys = {}
end

--- The player's flight (server.update, instead of the original's autopilot while a player flies).
function HeliPilot_Flight(dt)
	HeliPilotMassTimer = (HeliPilotMassTimer or 0) + dt
	if HeliPilotMassTimer > 0.5 then HeliPilot_UpdateMass() end
	local M = HeliPilotMass
	local Y = Vec(0, 1, 0)
	local up, fwd = Axes[Upward], Axes[Forward]
	local k = PilotKeys or {}

	-- how much the rotor can do: its spin (start-up, engine damage, fuel) and its health
	local auth = clamp(MRotSpeedFraction or 0, 0, 1) * clamp(MRotorHealth or 1, 0, 1)
	if RotorGone then auth = 0 end

	-- lift along the rotor axis: toward the wanted vertical speed (W / S, else hold the height)
	local climb = (k.up and 1 or 0) - (k.down and 1 or 0)
	local vt = climb > 0 and HELI_CLIMB or (climb < 0 and -HELI_SINK or 0)
	local av = 10 + clamp(HELI_VKP * (vt - HeliVel[2]), -8, 8)
	local T = math.min(M * av / math.max(up[2], 0.5), M * 10 * HELI_MAX_LIFT) * auth
	if T > 0 then ApplyBodyImpulse(Heli, systemCoM(), VecScale(up, T * dt)) end

	-- air drag (sets the top speed)
	local vh = Vec(HeliVel[1], 0, HeliVel[3])
	local s = VecLength(vh)
	if s > 0.01 then ApplyBodyImpulse(Heli, HeliCoM, VecScale(vh, -M * (HELI_DRAG_LIN + HELI_DRAG_QUAD * s) * dt)) end

	-- attitude: nose toward the view (heading, elevation), banked into the turn, rolled by A / D
	local fh = Vec(fwd[1], 0, fwd[3])
	if VecLength(fh) < 0.1 then fh = Vec(-up[1], 0, -up[3]) end
	fh = VecNormalize(fh)
	local h, elev = fh, 0
	local L = PilotLook
	if L then
		local lh = Vec(L[1], 0, L[3])
		if VecLength(lh) > 0.05 then h = VecNormalize(lh) end
		elev = math.deg(math.asin(clamp(L[2], -1, 1)))
	end
	local yawErr = math.atan2(VecDot(VecCross(fh, h), Y), VecDot(fh, h)) -- + = toward the left (+x of the body)
	local pitch, roll = 0, 0
	local onGround = grounded(vt)
	if not onGround then
		pitch = clamp(elev * HELI_PITCH_GAIN, -HELI_PITCH_DOWN, HELI_PITCH_UP)
		roll = clamp(math.deg(yawErr) * HELI_BANK_GAIN, -HELI_BANK, HELI_BANK)
		roll = roll + ((k.left and 1 or 0) - (k.right and 1 or 0)) * HELI_STRAFE_ROLL -- A: left (+x)
	end
	local pr, rr = math.rad(pitch), math.rad(roll)
	local side = VecNormalize(VecCross(Y, h)) -- the body's +x (left) when level on heading h
	local dF = VecAdd(VecScale(h, math.cos(pr)), VecScale(Y, math.sin(pr)))
	local dU = VecCross(dF, side)
	dU = VecNormalize(VecAdd(VecScale(dU, math.cos(rr)), VecScale(side, math.sin(rr))))

	local err = VecAdd(VecCross(fwd, dF), VecCross(up, dU))
	-- pitch / roll error that stays (a part pulling one side down): integrated and added, so it is worked off
	-- (yaw has none: the heading is set straight)
	-- (kept in the body's frame: a heavier side stays on the same side of the helicopter when it turns)
	local errPR = VecSub(err, VecScale(Y, VecDot(err, Y)))
	HeliAttI = HeliAttI or Vec()
	if auth > 0.5 and not onGround then
		HeliAttI = VecAdd(HeliAttI, VecScale(TransformToLocalVec(HeliTr, errPR), dt))
		local il = VecLength(HeliAttI)
		if il > HELI_TILT_I_MAX then HeliAttI = VecScale(HeliAttI, HELI_TILT_I_MAX / il) end
	end
	local w = VecAdd(VecScale(err, HELI_TURN_GAIN), VecScale(TransformToParentVec(HeliTr, HeliAttI), HELI_TILT_I))
	local wl = VecLength(w)
	if wl > HELI_MAX_RATE then w = VecScale(w, HELI_MAX_RATE / wl) end
	local cur = GetBodyAngularVelocity(Heli)
	if LostYawControl or SRotorGone then -- no tail rotor: no say over the yaw (MainRotorDrag spins it)
		w = VecAdd(VecSub(w, VecScale(Y, VecDot(w, Y))), VecScale(Y, VecDot(cur, Y)))
	end
	local a = math.min(1, HELI_RATE_RESP * dt) * clamp(auth * HELI_ATT_AUTH, 0, 1)
	SetBodyAngularVelocity(Heli, VecAdd(cur, VecScale(VecSub(w, cur), a)))

	if HELI_DEBUG then
		local leanLeft = math.deg(math.asin(clamp(-Axes[Right][2], -1, 1))) -- body +x is the left side
		local noseUp = math.deg(math.asin(clamp(fwd[2], -1, 1)))
		HeliDbg = {
			lean = leanLeft, wantLean = roll, nose = noseUp, wantNose = pitch, yaw = math.deg(yawErr),
			yawRate = math.deg(VecDot(cur, Y)), rotor = (MRotSpeedFraction or 0) * 100, auth = auth * 100,
			lift = T / (M * 10) * 100, fix = VecLength(HeliAttI), ground = onGround,
		}
	end
end

--- (test readout) shared with the pilot's client, 1 decimal
function HeliPilot_SyncDebug()
	if not HELI_DEBUG or not HeliDbg or PilotId == 0 then return end
	for k, v in pairs(HeliDbg) do
		if type(v) == "number" then v = math.floor(v * 10 + 0.5) / 10 end
		if shared["heDbg_" .. k] ~= v then shared["heDbg_" .. k] = v end
	end
end

local DBG_ORDER = {
	{ "lean", "lean left (deg)" }, { "wantLean", "wanted lean left" }, { "nose", "nose up (deg)" },
	{ "wantNose", "wanted nose up" }, { "yaw", "heading to turn (deg, + = left)" }, { "yawRate", "turning left (deg/s)" },
	{ "rotor", "rotor power %" }, { "auth", "control %" }, { "lift", "lift % of weight" },
	{ "fix", "lean correction" }, { "ground", "on the ground" },
}

--- (test readout) the pilot's DebugWatch lines
function HeliPilot_DrawDebug()
	if not HELI_DEBUG then return end
	for _, d in ipairs(DBG_ORDER) do DebugWatch("heli " .. d[2], tostring(shared["heDbg_" .. d[1]])) end
end

--------------------------------------------------------------------------------------------------- client

function HeliPilot_ClientInit()
	local tr = GetBodyTransform(Heli)
	PilotView_loc_1p = TransformToLocalPoint(tr, GetLocationTransform(FindLocation("Pilot_View_1p")).pos)
	PilotView_loc_3p = TransformToLocalPoint(tr, GetLocationTransform(FindLocation("Pilot_View_3p")).pos)
	PilotIsLocal = false
end

local function localIsPilot()
	local me = GetLocalPlayer()
	return (shared.hePilot or 0) ~= 0 and shared.hePilot == me
end

--- The pilot's view: own look from the mouse (InputValue camerax / cameray, as MountedGun.lua), zoom from the wheel
--- (Inputs.lua ManageCamera: 0 = cockpit, 8..20 m behind the third-person point), pulled in when something is
--- behind it. Returns the camera transform.
local function pilotCamera(dt)
	PilotLookPitch = clamp(PilotLookPitch - math.deg(InputValue("cameray")), -80, 80)
	PilotLookYaw = (PilotLookYaw - math.deg(InputValue("camerax"))) % 360
	local rot = QuatEuler(PilotLookPitch, PilotLookYaw, 0)

	local zoomIncrease = -InputValue("mousewheel") * 1.5
	if zoomIncrease ~= 0 then
		DesiredZoom = DesiredZoom + zoomIncrease
		if zoomIncrease > 0 then
			if DesiredZoom < 8 then DesiredZoom = 8 end
		else
			if DesiredZoom < 8 then DesiredZoom = 0 end
		end
		DesiredZoom = clamp(DesiredZoom, 0, 20)
	end
	local want = PilotView_loc_1p
	if DesiredZoom > 0 then
		want = PilotView_loc_3p
		if GunTimer > 0 then want = VecAdd(want, Vec(2 * GunTimer, 0, 0)) end
		if RocketTimer > 0 then want = VecAdd(want, Vec(-2 * RocketTimer, 0, 0)) end
	end
	if VecLength(VecSub(want, CamLocalPos)) > 0.2 then
		CamLocalPos = VecLerp(CamLocalPos, want, 0.06)
	else
		CamLocalPos = want
	end
	local tr = NextFrameTransform(Heli, dt)
	local pivot = TransformToParentPoint(tr, CamLocalPos)
	local zv = (DesiredZoom - zoom) * 0.08
	if math.abs(zv) < 0.005 then zoom = DesiredZoom else zoom = zoom + zv end

	local pos = pivot
	if zoom > 0 then
		-- behind along the view and raised (test 2026-11-13: level with the third-person point the camera sat right
		-- behind the tail boom); pulled in when something is in the way
		local back = QuatRotateVec(rot, Vec(0, 0, 1))
		local want = VecAdd(VecScale(back, zoom), Vec(0, HELI_CAM_UP + HELI_CAM_UP_PER_M * zoom, 0))
		local d = VecLength(want)
		local dir = VecScale(want, 1 / d)
		QueryRejectSelf()
		local hit, dist = QueryRaycast(pivot, dir, d)
		if hit then d = math.max(0, dist - 0.3) end
		pos = VecAdd(pivot, VecScale(dir, d))
	end
	return Transform(pos, rot)
end

function HeliPilot_ClientTick(dt)
	local pilot = localIsPilot() and not IsCrashed
	if pilot and not PilotIsLocal then
		-- start looking along the nose; third person as in the original (zoom 10)
		local f = TransformToParentVec(GetBodyTransform(Heli), Vec(0, 0, 1))
		PilotLookPitch = math.deg(math.asin(clamp(f[2], -1, 1)))
		PilotLookYaw = math.deg(math.atan2(-f[1], -f[3])) % 360
		zoom, DesiredZoom = 10, 10
		CamLocalPos = PilotView_loc_3p
		ShowControlCounter = ShowControlTime * 60
	end
	PilotIsLocal = pilot
	if not pilot then return end

	local ct = pilotCamera(dt)
	SetCameraTransform(ct)
	local look = QuatRotateVec(ct.rot, Vec(0, 0, -1))
	QueryRejectSelf()
	local hit, dist = QueryRaycast(ct.pos, look, 500)
	local aim = VecAdd(ct.pos, VecScale(look, hit and dist or 500))
	ServerCall("server.heliAim", GetLocalPlayer(), look, aim)
end

local function hint(text)
	UiText(text)
	UiTranslate(0, 26)
end

function HeliPilot_ClientDraw()
	if not PilotIsLocal then return end
	HeliPilot_DrawDebug()
	UiPush()
		-- crosshair (where the gun and rockets aim) and the nose marker (where the helicopter points)
		UiAlign("center middle")
		UiPush()
			UiTranslate(UiCenter(), UiMiddle())
			UiColor(1, 1, 1, 0.9)
			UiRect(4, 4)
		UiPop()
		local f = TransformToParentVec(HeliTr, Vec(0, 0, 1))
		local x, y, d = UiWorldToPixel(VecAdd(HeliCoM, VecScale(f, 200)))
		if d > 0 then
			UiPush()
				UiTranslate(x, y)
				UiColor(0.3, 1, 0.3, 0.8)
				UiFont("bold.ttf", 28)
				UiText("o")
			UiPop()
		end

		-- status
		UiAlign("center top")
		UiTranslate(UiCenter(), 20)
		UiFont("bold.ttf", 26)
		UiColor(1 - Fuelamount / FuelCapacity, 1, 0.4)
		UiText("Fuel: " .. math.floor(Fuelamount))
		UiTranslate(0, 28)
		if shared.heStarting then
			UiColor(1, 1, 0.4)
			UiText("Starting engine: " .. (shared.heStartLeft or 0) .. " s")
		elseif (MRotSpeedFraction or 0) < 0.3 and not RotorGone then
			UiColor(1, 0.6, 0.3)
			UiText("Rotor spinning up")
		end
	UiPop()

	if ShowControlCounter > 0 then
		ShowControlCounter = ShowControlCounter - 1
		UiPush()
			UiColorFilter(1, 1, 0, ShowControlCounter / ControlFadeTime / 60)
			UiAlign("left top")
			UiTranslate(20, UiHeight() - 300 - 26 * 8)
			UiFont("bold.ttf", 26)
			UiColor(0, 1, 0)
			hint("Mouse: steer - the nose follows your view")
			hint("Look down to fly forward, at the horizon to hover")
			hint("W / S: climb / descend")
			hint("A / D: sideways")
			hint("Left click: machine gun")
			hint("Right click: rockets")
			hint("Mouse wheel: zoom (all the way in: cockpit)")
			hint("E: leave the pilot seat")
		UiPop()
	end
end

#version 2
#include "script/include/player.lua"
#include "../lib/Settings.lua"

-- (v2) Split. Server, per player: keeps the vehicle driving while the player is out of it (drive-by),
-- positions the player next to the driver seat (DriveVehicle/SetPlayerVehicle/SetPlayerTransform are server-only),
-- puts them back in when the key is released. The drive-by key is the player's own keybind setting, so the
-- client reports it (server.setDriveBy). Client: forced 1st-person camera, fuel bar of the driven car.

---------------------------------------------------------------- server

function server.init()
	Init_Settings()
	DriveBy = {}         -- [player] = drive-by key held (reported by the client)
	DriveState = {}      -- [player] = { vehicle = handle, driving = bool, cycled = bool }
	shared.driveByVehicle = {}
end

function server.setDriveBy(p, down)
	DriveBy[p] = down
end

function server.tick(dt)
	for p in Players() do
		DriveByTick(p, dt)
	end
	for p in PlayersRemoved() do
		DriveBy[p] = nil
		DriveState[p] = nil
		shared.driveByVehicle[p] = nil
	end
end

SEAT_RETRY_GAP = 2.0   -- s; see the re-seat at the end of DriveByTick
SEAT_RESEAT_DELAY = 0.3 -- s the player stays out before the re-seat (see the end of DriveByTick)

-- debug lines while the debug "building sync readout" (all players) is on
local function seatLog(text)
	if GetBool("level.debug.buildprobe_on") then DebugPrint(text) end
end

function DriveByTick(p, dt)
	local s = DriveState[p]
	if not s then s = { vehicle = 0, driving = false, cycled = false } DriveState[p] = s end
	local playerVehicle = GetPlayerVehicle(p)

	if playerVehicle ~= 0 and not s.driving then
		s.vehicle = playerVehicle
		s.driving = true
		s.cycled = false
	end

	if playerVehicle == 0 and not s.driving then
		s.vehicle = 0
	end

	if s.vehicle ~= 0 and not IsHandleValid(s.vehicle) then
		s.vehicle = 0
		s.driving = false
	end

	local outside = false
	if s.driving then
		local keyDown = DriveBy[p] == true
		if GetPlayerHealth(p) <= 0 or InputPressed("interact", p) and s.cycled and not keyDown then
			RemoveTag(GetVehicleBody(s.vehicle), "bounded")
			s.vehicle = 0
			s.driving = false
		end
		s.cycled = true

		if keyDown and s.vehicle ~= 0 and not HasTag(s.vehicle, "cfg") and not HasTag(s.vehicle, "planeVehicle") then
			local RegisteredVehicle = s.vehicle
			local drive = InputValue("up", p) - InputValue("down", p)
			local turn = InputValue("left", p) - InputValue("right", p)
			local brake = InputDown("Space", p)
			if (tonumber(GetTagValue(RegisteredVehicle, "fuelLevel")) or 0) > 0 then
				DriveVehicle(RegisteredVehicle, drive, turn, brake)
			end
			SetTag(RegisteredVehicle, "drive", drive)
			SetTag(RegisteredVehicle, "turn", turn)
			SetTag(RegisteredVehicle, "brake", brake and 1 or 0)
			outside = true

			SetPlayerVehicle(0, p)
			local driverPos = GetVehicleDriverPos(RegisteredVehicle)
			local t = GetVehicleTransform(RegisteredVehicle)
			local CurrentPlayerTrans = GetPlayerTransformWithPitch(p)
			local driverWorldPos = TransformToParentPoint(t, VecAdd(driverPos, Vec(-1.5,-1.2,0)))
			local upVec = QuatRotateVec(QuatRotateQuat(t.rot, QuatEuler(0,0,30)), Vec(0,1))
			if driverPos[1] > 0 then
				driverWorldPos = TransformToParentPoint(t, VecAdd(driverPos, Vec(1.5,-1.2,0)))
				upVec = QuatRotateVec(QuatRotateQuat(t.rot, QuatEuler(0,0,-30)), Vec(0,1))
			end

			local dirVec = QuatRotateVec(CurrentPlayerTrans.rot, Vec(0,0,-1))
			local driverWorldQuat = UMF_VecToQuatLookAt(dirVec, upVec)
			SetPlayerTransformWithPitch(Transform(driverWorldPos,driverWorldQuat), p)
		elseif s.vehicle == 0 then
			SetPlayerVehicle(0, p) -- as v1: right after leaving (interact / death) this puts the player out
		elseif s.outside or GetTime() - (s.backAt or -100) < 0.5 then
			if s.outside then s.backAt = GetTime() end
			SetPlayerVehicle(s.vehicle, p) -- drive-by key released: back in (repeated while the engine settles)
		elseif playerVehicle ~= s.vehicle then
			-- (MP fix 2026-11-16, verified in-game) A player whose seat is destroyed is taken out by the engine. v1 called
			-- SetPlayerVehicle(s.vehicle) every tick while seated, so they were put back in the same tick (into another,
			-- free seat); the client never saw them leave, kept the broken seat for its camera (far off / under the map,
			-- couldn't be turned) until the player exited. Now the player stays out for SEAT_RESEAT_DELAY, then is
			-- re-seated once (the engine picks a free seat; user: keep that); taken out again within SEAT_RETRY_GAP s
			-- = left out. Debug lines (seatLog) while the sync readout is on: the server's seat before / after here,
			-- each machine's own seat in client.tick.
			local now = GetTime()
			if not s.reseatAt then
				if now - (s.reseated or -100) <= SEAT_RETRY_GAP then
					seatLog("player " .. p .. " taken out again: left out of the vehicle")
					s.vehicle = 0
					s.driving = false
				else
					s.reseatAt = now + SEAT_RESEAT_DELAY
					seatLog("player " .. p .. " taken out of the vehicle while seated (seat " .. GetPlayerRig(p)
						.. "): re-seat in " .. SEAT_RESEAT_DELAY .. " s")
				end
			elseif now >= s.reseatAt then
				s.reseatAt = nil
				s.reseated = now
				SetPlayerVehicle(s.vehicle, p)
				seatLog("player " .. p .. " re-seated: server seat " .. GetPlayerRig(p))
			end
		else
			s.reseatAt = nil
		end
	end
	s.outside = outside
	local shown = outside and s.vehicle or 0
	if shared.driveByVehicle[p] ~= shown then shared.driveByVehicle[p] = shown end
end

---------------------------------------------------------------- client

function client.init()
	Init_Settings()
	mouseXtotal = 0
	mouseYtotal = 0
	lastDriveByDown = false
	lastClientVehicle = 0
end

function client.tick(dt)
	local down = KeybindDown(Settings.keybinds.vehicles.drive_by_shooting) and true or false
	if down ~= lastDriveByDown then
		lastDriveByDown = down
		ServerCall("server.setDriveBy", GetLocalPlayer(), down)
	end

	local v = (shared.driveByVehicle or {})[GetLocalPlayer()] or 0
	if v ~= 0 then
		SetInt('FuelScript.vehicleToDraw', v)
		mouseYtotal = 0
		mouseXtotal = 0
	end

	local playerVehicle = GetPlayerVehicle()
	local rig = playerVehicle ~= 0 and GetPlayerRig() or 0
	if rig ~= lastClientRig or playerVehicle ~= lastClientVehicle then   -- (2026-11-16) seat debug (DriveByTick)
		lastClientRig = rig
		seatLog("this machine: vehicle " .. playerVehicle .. ", seat " .. rig)
	end
	if playerVehicle ~= lastClientVehicle then -- v1 reset the mouse totals when entering a car
		lastClientVehicle = playerVehicle
		mouseYtotal = 0
		mouseXtotal = 0
	end
	if Settings.game.forced_1st_person_driving.value then
		if playerVehicle ~= 0 and not HasTag(playerVehicle, "cfg") then
			mouseupdate(dt)
		end
	end
end

function mouseupdate(dt)
	cameraRotationSpeed = 5
	camtrans = GetCameraTransform()
	local x,y,z = GetQuatEuler(camtrans.rot)
	local mouseX = InputValue("mousedx")
	local mouseY = InputValue("mousedy")
	VehicleTrans = GetVehicleTransform(GetPlayerVehicle())
	local cameraY = y
	local cameraX = x
	local vehicleX, vehicleY, vehicleZ = GetQuatEuler(VehicleTrans.rot)
	mouseXtotal = mouseXtotal + mouseX
	mouseYtotal = mouseYtotal + mouseY
	SetCameraTransform(Transform(GetPlayerTransform().pos, QuatEuler(vehicleX - mouseYtotal/13,vehicleY - mouseXtotal/13,0)))
end

function TransformToParentQuat(pT,q)
	return TransformToParentTransform(pT,Transform(Vec(),q)).rot
end
function TransformToLocalQuat(pT,q)
	return TransformToLocalTransform(pT,Transform(Vec(),q)).rot
end

-- This UMF_VecToQuatLookAt function is copied from Teardown UMF by Thomasims
-- Link: https://github.com/Thomasims/TeardownUMF

function UMF_VecToQuatLookAt(vec, up)
	local forward = VecScale(vec, -1 / VecLength(vec))
	local right = VecNormalize(VecCross(up or Vec(0, 1, 0), forward))
	local up = VecCross(forward, right)

	local m00, m01, m02 = right[1], right[2], right[3]
	local m10, m11, m12 = up[1], up[2], up[3]
	local m20, m21, m22 = forward[1], forward[2], forward[3]

	if m22 < 0 then
	  if m00 > m11 then
		local t = 1 + m00 - m11 - m22
		local t2 = 0.5 / math.sqrt(t)
		return Quat(t2 * t, t2 * (m01 + m10), t2 * (m20 + m02), t2 * (m12 - m21))
	  else
		local t = 1 - m00 + m11 - m22
		local t2 = 0.5 / math.sqrt(t)
		return Quat(t2 * (m01 + m10), t2 * t, t2 * (m12 + m21), t2 * (m20 - m02))
	  end
	else
	  if m00 < -m11 then
		local t = 1 - m00 - m11 + m22
		local t2 = 0.5 / math.sqrt(t)
		return Quat(t2 * (m20 + m02), t2 * (m12 + m21), t2 * t, t2 * (m01 - m10))
	  else
		local t = 1 + m00 + m11 + m22
		local t2 = 0.5 / math.sqrt(t)
		return Quat(t2 * (m12 - m21), t2 * (m20 - m02), t2 * (m01 - m10), t2 * t)
	  end
	end
  end
  function server.handleCommand(cmd) HandleQuickload(cmd) end
  function HandleQuickload(cmd)
	  for _, word in ipairs(splitString(cmd, " ")) do
		  if word == "quickload" then
			  Init_Settings()
		  end
		  break
	  end
  end
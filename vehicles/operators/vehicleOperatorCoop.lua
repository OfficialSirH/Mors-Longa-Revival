-- (v2, Phase 3) Co-op helpers for the enemy / convoy car scripts (chaseOperator.lua, chaseOperatorTransport.lua,
-- ConvoyOperations.lua, ConvoyOperatorTransport.lua). Those scripts run on the SERVER only; v1 asked for "the player"
-- (on the server that would always be the host). Include AFTER masterScriptRemoverAPI.lua (queueRemoval is
-- redefined here) and after "script/include/player.lua" (Players()).

--- Nearest living player to pos (all dead: nearest player; no players: 0 = host).
function OpTargetPlayer(pos)
	local best, bestD, bestAlive = nil, math.huge, false
	for p in Players() do
		local alive = GetPlayerHealth(p) > 0
		local d = VecLength(VecSub(GetPlayerTransform(p).pos, pos))
		if (alive and not bestAlive) or (alive == bestAlive and d < bestD) then
			best, bestD, bestAlive = p, d, alive
		end
	end
	return best or 0
end

function OpTargetTransform(pos)
	return GetPlayerTransform(OpTargetPlayer(pos))
end

--- v1 "GetPlayerVehicle() == vehicle": is any player in this vehicle (driver or passenger)?
function OpAnyPlayerInVehicle(vehicle)
	for p in Players() do
		if GetPlayerVehicle(p) == vehicle then return true end
	end
	return false
end

--- v1 played the distant crash layer at the player's camera, volume = distance / 10. Now for every player.
function OpPlayDistantSound(sound, pos)
	for p in Players() do
		local cam = GetPlayerCameraTransform(p).pos
		PlaySound(sound, cam, VecLength(VecSub(pos, cam)) / 10)
	end
end

--- v1 lookatcarnage (ConvoyOperations): a dying car within 45 m blurs the player's camera (depth of field, client)
--- and slows time to 0.3 (server). Slow motion only with one player (it would slow everyone down).
OpCarnageSent = {}
function OpCarnage(vehiclePos)
	local near = false
	for p in Players() do
		local d = VecLength(VecSub(vehiclePos, GetPlayerTransform(p).pos))
		if d < 45 then
			near = true
			if GetTime() - (OpCarnageSent[p] or -1) > 0.1 then
				OpCarnageSent[p] = GetTime()
				ClientCall(p, "client.opCarnageDof", p, d)
			end
		end
	end
	if near and GetPlayerCount() == 1 then SetTimeScale(0.3) end
end

function client.opCarnageDof(target, dist)
	local me = GetLocalPlayer()
	if target ~= me and not (target == 0 and IsPlayerHost(me)) then return end
	OpDofDist = dist
	OpDofUntil = GetTime() + 0.2
end

function client.tick(dt)
	if OpDofUntil and GetTime() < OpDofUntil then SetCameraDof(OpDofDist) end
end

--- v1 queueRemoval (masterScriptRemoverAPI) registers a pause menu button to find the script's own handle; that
--- trick does not work on the server. The script now just goes idle (server callbacks check OpFinished).
function queueRemoval()
	OpFinished = true
	ScriptSelfDelete() -- (2026-11-17) now possible: GetScriptId() (lib/ScriptSelfDelete.lua)
end

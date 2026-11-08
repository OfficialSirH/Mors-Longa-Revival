#version 2
#include "script/include/player.lua"
-- (v2) server: deletes what is far behind the REARMOST player (nothing near any player), never a car a player is in.
-- Scripts that came with deleted road segments are removed by GenerateRoad (TickSegmentScripts): in v2 a script
-- cannot be linked to its objects (GetEntityChildren / GetEntityParent return nothing for scripts, 2026-11-07).
function server.init()
	deletionDist = 250
	vList = {} -- no easy way to get all vehicle body, so this will have to do
	NextPass = 0
end

function server.update()
	-- level.roadgen is a ONE-FRAME pulse: GenerateRoad sets it when it spawns a segment and clears it on its next
	-- tick. v1 cleaned up on every update during that frame. Remember the pulse so a throttled pass never misses it.
	if GetBool("level.roadgen") then RoadgenSeen = true end
	-- (v2 perf 2026-11-07) v1 scanned every shape, body, trigger and joint of the level on every physics update
	-- during the pulse (10-15k shapes); now at most 4 passes per second, only after a segment spawned.
	if GetTime() < NextPass then return end
	NextPass = GetTime() + 0.25
	if not RoadgenSeen then return end
	RoadgenSeen = false
	RemovePass()
end

function RemovePass()
	if GetBool('Level.Debug')then DebugPrint(GetTime().." ----------TRASH  REMOVE----------")end
	local rearmostX = RearmostPlayerX()
	-- (v2 fix 2026-11-07) no players found (e.g. the first frames of a level, before the player is registered):
	-- "rearmost player" would be infinitely far ahead and EVERYTHING would be deleted (whole level, tool bodies).
	if rearmostX == nil then return end
	local playerPos = Vec(rearmostX, 0, 0) -- (v2) rearmost player, x only is used below
	if GetBool('Level.Debug')then DebugPrint(GetTime().." player at: "..VecStr(playerPos))end

	local shapes = FindShapes(nil,true)
	for i=1,#shapes do
		local shape = shapes[i]
		if not HasTag(shape, "nodelete") then
			local shapeT = GetShapeWorldTransform(shape)
			local distToShape = playerPos[1] - shapeT.pos[1]
			if distToShape > deletionDist then
				Delete(shape)
			end
		end
	end

	local bodies = FindBodies(nil, true)
	for i=1,#bodies do
		local body = bodies[i]
		local bodyV = GetBodyVehicle(body)
		if bodyV == 0 then
			if not HasTag(body, "nodelete") then
				local bodyT = GetBodyTransform(body)
				local distToBody = playerPos[1] - bodyT.pos[1]
				if distToBody > deletionDist and not isBodyValid(body)then
					Delete(body)
				end
			end
		else
			if not vList[bodyV] then
				vList[bodyV] = {}
			end
			vList[bodyV][body] = not isBodyValid(body)
		end
	end

	for vehicle, bodies in pairs(vList) do
		if not IsHandleValid(vehicle) then
			vList[vehicle] = nil -- (v2 perf) forget deleted vehicles (v1 kept them and re-deleted them every update)
		elseif not HasTag(vehicle, "nodelete") then
			local willDel = true
			for body, empty in pairs(bodies) do
				willDel = willDel and empty
				if not empty then
					break
				end
			end
			if willDel then
				if not IsAnyPlayerVehicle(vehicle) then
					Delete(vehicle)
				else
					if GetBool('Level.Debug') then
						DebugPrint(GetTime().." player vehicle was flagged to be removed at: "..TransformStr(GetVehicleTransform(vehicle)))
					end
				end
			end
		end
	end

	local triggers = FindTriggers(nil,true)
	for i=1,#triggers do
		local trigger = triggers[i]
		if not HasTag(trigger, "nodelete") then
			local triggerT = GetShapeWorldTransform(trigger)
			local distToTrigger = playerPos[1] - triggerT.pos[1]
			if distToTrigger > deletionDist then
				Delete(trigger)
			end
		end
	end

	local joints = FindJoints(nil, true)
	for i=1, #joints do
		local joint = joints[i]
		local shapes = GetJointShapes(joint)
		local valid = false
		for i=1,#shapes do
			if IsHandleValid(shapes[i]) then
				valid = true
				break
			end
		end
		if not valid then
			Delete(joint)
		end
	end

	if GetBool('Level.Debug')then DebugPrint(GetTime().." ----------TRASH REMOVED----------")end
end

--- x of the rearmost player, or nil when there are no players (never infinity: see server.update)
function RearmostPlayerX()
	local x = nil
	for p in Players() do
		local px = GetPlayerTransform(p).pos[1]
		if x == nil or px < x then x = px end
	end
	return x
end

function IsAnyPlayerVehicle(vehicle)
	for p in Players() do if GetPlayerVehicle(p) == vehicle then return true end end
	return false
end

function isBodyValid(b)
	local ss=GetBodyShapes(b)
	for i=1,#ss do
		if IsHandleValid(ss[i])then
			return true
		end
	end
	return false
end

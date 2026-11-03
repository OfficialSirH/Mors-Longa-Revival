function init()
	deletionDist = 250
	vList = {} -- no easy way to get all vehicle body, so this will have to do
end

function update()
	if GetBool("level.roadgen") then
		if GetBool('Level.Debug')then DebugPrint(GetTime().." ----------TRASH  REMOVE----------")end
		local playerPos = GetPlayerTransform().pos
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
			if not HasTag(vehicle, "nodelete") then
				local willDel = true
				for body, empty in pairs(bodies) do
					willDel = willDel and empty
					if not empty then
						break
					end
				end
				if willDel then
					if GetPlayerVehicle()~=vehicle then
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
--Constrain value between min max
function math.clamp(val, lower, upper)
	if lower == nil then lower = val - 1 end
	if upper == nil then upper = val + 1 end

    if lower > upper then lower, upper = upper, lower end -- swap if boundaries supplied the wrong way
    return math.max(lower, math.min(upper, val))
end

function GetTriggerLocalTransform(tr_tag,ParentBody)
    local tr_handle = FindTrigger(tr_tag)
    local_tr = TransformToLocalTransform(GetBodyTransform(ParentBody),  GetTriggerTransform(tr_handle))
    return local_tr
end

function IsPointInTriggerGlobal(TriggerHandle, TriggerLocaltr, PointToCheck, ParentBody)
	SetTriggerTransform(TriggerHandle, TransformToParentTransform(GetBodyTransform(ParentBody),TriggerLocaltr))
	return IsPointInTrigger(TriggerHandle,PointToCheck)

end


function GetLocationLocalTransform(loc_tag,ParentBody)
    local loc_handle = FindLocation(loc_tag)
    local_tr = TransformToLocalPoint(GetBodyTransform(ParentBody),  GetLocationTransform(loc_handle).pos)
    return local_tr
    --getting back
    --Pos = TransformToParentPoint(GetBodyTransform(ParentBody),local_tr)
end

--similar to perlin noise
function Noise(Timer,Last,Next,Period)
	local factor = 3
	local Levels = 3
	local Result = 0
	Vals = {}


	if Last == nil then
		Last = {}
		Timer = {}
		Next = {}
		for s = 1,Levels,1 do
			Next[s] = math.random(-1000,1000)/1000
			Timer[s] = 0
			Last[s] = 0
		end
	end

	local maxval = 0
	for s = 1,Levels,1 do
		local f = factor^(s-1)
		local p = Period/f
		if Timer[s] <= 0 then
			Last[s] = Next[s]
			Next[s] = math.random(-1000,1000)/1000
			Timer[s] = p

			Vals[s] = Last[s]

		else
			Vals[s] = Last[s]*Timer[s]/p + Next[s]*(1-Timer[s]/p)

			Timer[s] = Timer[s]-1
		end

		Vals[s] = Vals[s]/f
		--DebugPrint(Vals[s] .. " " .. s .. " " .. f .. " " .. Last[s] .. " " .. Next[s] .. " " .. Timer[s]/p)
		Result = Result + Vals[s]
		maxval = maxval+1/f
	end
	Result = Result/maxval --normalise to -1 to 1

	return Timer,Last,Next,Result
end


--Returns the turning difference between 2 vectors along the turning axis
--It is 0 when they are facing same way, -0.5 when desired is exactly to right, +-1 when exactly behind
--Thus the result is going from 0 to +-1 is the angle facing away from the ideal direction, turning axis is the axis of rotation around which the angle is checked
function VecFacingDifference(CurrentVec,DesiredVec,CurrentRight,TurningAxis)
	--I'm not sure why the calculation is done like this
	--The vanilla version only checks up to d, for parallelity, thus facing away and same way look the same

	--cross product returns a vector perpendicular to both, based on interaction between the different dimensions
	local c = VecCross(CurrentVec,DesiredVec)
	--this goes from 0- +-1, -1 if target is to right, and keeps going back down to 0 as it moves to back
	--dot product is usually how "parallel" 2 unit vectors are
	local d = VecDot(c, TurningAxis)
	local Result = 0

	--do the same calculation for the current right vector, this helps deciding if desired is at the back (on the right of the right vector)
	c = VecCross(CurrentRight,DesiredVec)
	local d2 = VecDot(c, TurningAxis)

	--this part makes sure that the vectors facing away from each other are treated appropriately
	if d2>0 then
		Result = d
	else
		if d<0 then
			Result = -2 - d
		else
			Result = 2 - d
		end
	end

	Result = Result /2 --scale result to between -1 to 1
	return Result
end

function QueryRejectSelf()
	for i= 1,#AllBodies,1 do
		QueryRejectBody(AllBodies[i])
	end
end

function GetAimPos(MaxDist,MinDist)
	if MinDist == nil then MinDist =0 end
    local ct = GetCameraTransform()
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


function GetAimPosOffset(MaxDist,MinDist,OffsetUp)
	if MinDist == nil then MinDist =0 end
    local ct = GetCameraTransform()

	local Dir = QuatRotateVec(ct.rot,Vec(1,0,0))
	ct.rot = QuatRotateQuat(QuatAxisAngle(Dir,OffsetUp),ct.rot)

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

--similar to perlin noise
function Noise(Timer,Last,Next,Period)
	local factor = 3
	local Levels = 3
	local Result = 0
	Vals = {}


	if Last == nil then
		Last = {}
		Timer = {}
		Next = {}
		for s = 1,Levels,1 do
			Next[s] = math.random(-1000,1000)/1000
			Timer[s] = 0
			Last[s] = 0
		end
	end

	local maxval = 0
	for s = 1,Levels,1 do
		local f = factor^(s-1)
		local p = Period/f
		if Timer[s] <= 0 then
			Last[s] = Next[s]
			Next[s] = math.random(-1000,1000)/1000
			Timer[s] = p

			Vals[s] = Last[s]

		else
			Vals[s] = Last[s]*Timer[s]/p + Next[s]*(1-Timer[s]/p)

			Timer[s] = Timer[s]-1
		end

		Vals[s] = Vals[s]/f
		--DebugPrint(Vals[s] .. " " .. s .. " " .. f .. " " .. Last[s] .. " " .. Next[s] .. " " .. Timer[s]/p)
		Result = Result + Vals[s]
		maxval = maxval+1/f
	end
	Result = Result/maxval --normalise to -1 to 1

	return Timer,Last,Next,Result
end

function GetTriggerLocalTransform(tr_tag,ParentBody)
    local tr_handle = FindTrigger(tr_tag)
    local_tr = TransformToLocalTransform(GetBodyTransform(ParentBody),  GetTriggerTransform(tr_handle))
    return local_tr
end

function IsPointInTriggerGlobal(TriggerHandle, TriggerLocaltr, PointToCheck, ParentBody)
	SetTriggerTransform(TriggerHandle, TransformToParentTransform(GetBodyTransform(ParentBody),TriggerLocaltr))
	return IsPointInTrigger(TriggerHandle,PointToCheck)

end

function GetLocationLocalTransform(loc_tag,ParentBody)
    local loc_handle = FindLocation(loc_tag)
    local_tr = TransformToLocalPoint(GetBodyTransform(ParentBody),  GetLocationTransform(loc_handle).pos)
    return local_tr
    --getting back
    --Pos = TransformToParentPoint(GetBodyTransform(ParentBody),local_tr)
end

--Steepness: at 1 you have about 50% chance of getting almost 0 and then higher values
--at 0.5 it is still low values at 50%, with a nicer curve, at 2 you get basically 0 up to 75%
--at 0.25 it gets almost linear and you never get close to 0 (0.5 is a good steepness)
function LogisticRandom(MaxValue,ZeroVal,Steepness)
	if Steepness == nil then
		Steepness = 0.5
	end
	if ZeroVal == nil then
		ZeroVal = 0
	end
	local randRange = 10
	local RandVal = (math.random()*2-1)*randRange

	local Result = MaxValue*(1/(1+math.exp(-Steepness*(RandVal-ZeroVal)))*2-1)
	if RandVal<0 then
		Result = Result + MaxValue
	else
		Result = Result - MaxValue
	end
	return Result
end

--similar to perlin noise
function Noise(Timer,Last,Next,Period)
	local factor = 3
	local Levels = 3
	local Result = 0
	Vals = {}


	if Last == nil then
		Last = {}
		Timer = {}
		Next = {}
		for s = 1,Levels,1 do
			Next[s] = math.random(-1000,1000)/1000
			Timer[s] = 0
			Last[s] = 0
		end
	end

	local maxval = 0
	for s = 1,Levels,1 do
		local f = factor^(s-1)
		local p = Period/f
		if Timer[s] <= 0 then
			Last[s] = Next[s]
			Next[s] = math.random(-1000,1000)/1000
			Timer[s] = p

			Vals[s] = Last[s]

		else
			Vals[s] = Last[s]*Timer[s]/p + Next[s]*(1-Timer[s]/p)

			Timer[s] = Timer[s]-1
		end

		Vals[s] = Vals[s]/f
		--DebugPrint(Vals[s] .. " " .. s .. " " .. f .. " " .. Last[s] .. " " .. Next[s] .. " " .. Timer[s]/p)
		Result = Result + Vals[s]
		maxval = maxval+1/f
	end
	Result = Result/maxval --normalise to -1 to 1

	return Timer,Last,Next,Result
end



















function clamp(value, mi, ma)
	if value < mi then value = mi end
	if value > ma then value = ma end
	return value
end


function trim(s)
   return (s:gsub("^%s*(.-)%s*$", "%1"))
end


function startsWith(str, start)
	return string.sub(str, 1, string.len(start)) == start
end

function splitString(str, delimiter)
	local result = {}
	for word in string.gmatch(str, '([^'..delimiter..']+)') do
		result[#result+1] = trim(word)
	end
	return result
end


function hasWord(str, word)
	local words = splitString(str, " ")
	for i=1,#words do
		if string.lower(words[i]) == string.lower(word) then
			return true
		end
	end
	return false
end

function smoothstep(edge0, edge1, x)
	x = math.clamp((x - edge0) / (edge1 - edge0), 0.0, 1.0)
	return x * x * (3 - 2 * x)
end


function math.clamp(val, lower, upper)
    if lower > upper then lower, upper = upper, lower end -- swap if boundaries supplied the wrong way
    return math.max(lower, math.min(upper, val))
end


function progressBar(w, h, t)
	UiPush()
		UiAlign("left top")
		UiColor(0, 0, 0, 0.5)
		UiImageBox("ui/common/box-solid-10.png", w, h, 6, 6)
		if t > 0 then
			UiTranslate(2, 2)
			w = (w-4)*t
			if w < 12 then w = 12 end
			h = h-4
			UiColor(1,1,1,1)
			UiImageBox("ui/common/box-solid-6.png", w, h, 6, 6)
		end
	UiPop()
end


--Draw hint box with arrow to the left, pointing at cursor position
function drawHintArrow(str)
	UiPush()
		UiAlign("middle left")
		UiColor(1,1,1, 0.7)
		local w,h = UiImage("common/arrow-left.png")
		UiTranslate(w-1, 0)
		UiFont("bold.ttf", 22)
		 w,h = UiGetTextSize(str)
		UiImageBox("common/box-solid-6.png", w+40, h+12, 6, 6)
		UiPush()
			UiColor(0,0,0)
			UiTranslate(20, 0)
			UiText(str)
		UiPop()
	UiPop()
end


--used in the settings, I don't know what they do

function handleCommand(cmd) handle_quickload(cmd) end

function handle_quickload(cmd)
    for _, word in ipairs(splitString(cmd, " ")) do
        if word == "quickload" then
            Init_Settings()
        end
        break
    end
end

function splitString(str, delimiter)
    local result = {}
    for word in string.gmatch(str, '([^'..delimiter..']+)') do
        result[#result+1] = trim(word)
    end
    return result
end

function trim(s)
	return (s:gsub("^%s*(.-)%s*$", "%1"))
 end


function GetLocationLocalTransform(loc_tag,ParentBody)
    local loc_handle = FindLocation(loc_tag)
    local_tr = TransformToLocalTransform(GetBodyTransform(ParentBody),  GetLocationTransform(loc_handle))
    return local_tr
    --getting back
    --Pos = TransformToParentTransform(GetBodyTransform(ParentBody),local_tr)
end

--Returns the player vehicle even if the player is being transported by it but not driving it
--Also works for the Helicopter mod, which doesn't have a designated "Vehicle" body in it, by checking a tag
--returns the vehicle ID, -1 of it's a special modded vehicle
function QueryRejectVehiclePlus()
	retval = 0
	retval = GetPlayerVehicle()
	local jointedbodies = nil

	if retval == 0 then
		local pos = GetPlayerTransform().pos
		local hit, dist, normal, shape = QueryRaycast(pos, Vec(0,-1,0), 0.5)

		if hit then
			jointedbodies = GetJointedBodies(GetShapeBody(shape))
			if jointedbodies == nil then
				jointedbodies[1] = GetShapeBody(shape)
			else
				jointedbodies[#jointedbodies+1] = GetShapeBody(shape)
			end

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

function Vec2D(InputVector)
	return Vec(InputVector[1],0,InputVector[3])
end
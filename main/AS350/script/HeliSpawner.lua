--Wanted to test spawning but didn't work for some reason

function init()

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

function SpawnHeli()

    -- if InputPressed("p") then
    --     --local pos, hit, distance,shape = GetAimPos(1,100)
    --     if hit then
    --         local ct = GetCameraTransform()
    --         local pos = TransformToParentPoint(ct, Vec(0, 0, -4))
    --         DebugPrint(VecStr(pos))
    --         local tr = Transform(VecAdd(pos,Vec(0,0.2,0)))
    --         Spawn("MOD/main/AS350/AS350_MILITARY.xml",ct)

    --     end
    -- end

end

function tick(dt)
    SpawnHeli()
end
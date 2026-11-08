

function init()
	object = FindBody("RightTrack")
	objectPosition = GetBodyTransform(object).pos
	objectSpeed = 2.0
	light = FindLights("")
	
end

function update(dt)
	splinePath = {}
	for i=1,#light do 
		table.insert(splinePath, GetLightTransform(light[i]).pos)
	end
	local t = GetTime() * objectSpeed
    t = t % (#splinePath - 1)
    local segmentIndex = math.floor(t) + 1
    local tSegment = t - segmentIndex + 1
    local p0 = splinePath[segmentIndex]
    local p1 = splinePath[segmentIndex + 1]

    local interpolatedX = p0[1] + (p1[1] - p0[1]) * tSegment
    local interpolatedY = p0[2] + (p1[2] - p0[2]) * tSegment
    local interpolatedZ = p0[3] + (p1[3] - p0[3]) * tSegment

    objectPosition = Vec(interpolatedX,interpolatedY,interpolatedZ)
	SetBodyTransform(object, Transform(objectPosition))
	if segmentIndex < #splinePath then
        DrawLine(p0,p1,0,1,0)
    end
	for i=1,#splinePath do 
		if i < #splinePath then
			DrawLine(splinePath[i], splinePath[i+1])
		end
	
    end
end



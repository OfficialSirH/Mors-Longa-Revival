function init()
	timer = 0
	helibody = FindBody("heli")
end

function tick()
	if InputPressed("L") then
		beginextraction = true
	end
end

function update(dt)
	if beginextraction then
		helitransform = GetBodyTransform(helibody)
		DebugCross(GetAimPos())
		DrawLine(GetAimPos(), helitransform.pos, 0,0,0)
		if not ropedeployed then
			ropedeployed = true
		end
		timer = timer + dt
		TORSOS = FindShapes("TORSO")
		if timer > 3 and #TORSOS > 0 then
			timer = 0
			Spawn("MOD/prefabs/spawnables/enemies/millitary/RagdollmilSpecOps.xml", Transform(GetAimPos()))
			Delete(FindShape("TORSO"))
		end
	end
end

function GetAimPos()
   local ct = helitransform
   x, y, z = GetQuatEuler(ct.rot)
   x = x + 90
   y = y + 90
   z = z + 90
   ct.rot = QuatEuler(x,y,z)
   local forwardPos = TransformToParentPoint(ct, Vec(0, 0, -200))
   local direction = VecSub(forwardPos, ct.pos)
   local distance = VecLength(direction)
   local direction = VecNormalize(direction)
   QueryRejectBody(helibody)
   local hit, hitDistance = QueryRaycast(ct.pos, direction, distance)
   if hit then
      forwardPos = TransformToParentPoint(ct, Vec(0, 0, -hitDistance))
      distance = hitDistance
   end
   return forwardPos, hit, distance
end

function SpawnRope(Transform)
RopeLength=5
p = Transform.pos
r = Transform.pos
local slack =  RopeLength-VecLength(VecSub(p,r))
str = [[
    <rope pos="$x1 $y1 $z1" rot="0.0 0.0 0.0" slack="$slack" strength="100" maxstretch="1" color="0.34 0.34 0.34">
        <location pos="0.0 0.0 0.0" rot="0.0 0.0 0.0"/>
        <location pos="$x2 $y2 $z2" rot="0.0 0.0 0.0"/>
    </rope>]]
str = str:gsub("$x1", r[1])
str = str:gsub("$y1", r[2])
str = str:gsub("$z1", r[3])

str = str:gsub("$x2", p[1]-r[1])
str = str:gsub("$y2", p[2]-r[2])
str = str:gsub("$z2", p[3]-r[3])

str = str:gsub("$slack", slack)
Ropes[RopeNo] = Spawn(str, Transform,false, true)[1]
end
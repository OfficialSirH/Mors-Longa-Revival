#version 2
#include "script/include/player.lua"
-- (v2) server: supply plane flies over, drops crates when the NEAREST player is within 300 m, despawns.
function server.init()
    -- (v2) removed unused a = GetPlayerCameraTransform()
    sb = FindBody("plane")
    maxheight = 8
    boc = 20
    absolute = false
    b = FindShape("bby")
	spawnpos = FindLight("spawnpos")
	
	

	Crates = FindBodies("CratePlane", true)

	
	counter = 1
	counter1 = 1
	counter2 = 1
	counter3 = 1
	counter4 = 1
	counter5 = 1
	
	despawn = 25
	prop = FindBodies("prop")	
	
	
	dropped1 = false
	dropped2 = false
	dropped3 = false
	dropped4 = false
	dropped5 = false
	dropped = false
	
	-------- Rarity ------------

	Randomy = math.random(1,3)
	Randomy1 = math.random(1,2)
	Randomy2= math.random(1,3)
	Randomy3 = math.random(1,2)
	Randomy4 = math.random(1,2)
	Randomy5 = math.random(1,3)
	-----------------------------
	ttime = 1
	amountspawn = math.random(1,5)
	wait = 4
	launch = false
end

	
function server.tick(dt)

local planeBody = FindBody("plane")
local planePos = GetBodyTransform(planeBody).pos
local dist = math.huge -- (v2) nearest player
for p in Players() do dist = math.min(dist, VecLength(VecSub(GetPlayerTransform(p).pos, planePos))) end
ttime = ttime - dt
	
    strans = GetShapeWorldTransform(sc)
    spos = strans.pos
    flydirection = TransformToParentVec(strans, Vec(0, -1, 0))
    local sbt = GetBodyTransform(sb)
    local trVec = Vec(0,0, -boc)
    local trVel = TransformToParentPoint(sbt, trVec)
    local velSub = VecSub(trVel, sbt.pos)
    local bias = Vec(0, 0, 0)
    if not absolute then
        if (sbt.pos[2] < maxheight) then
            bias[2] = boc
            boc = boc
        end
        local currentVelocity = GetBodyVelocity(sb)
        SetBodyVelocity(sb, velSub)
    end
    if IsShapeBroken(b) then
		absolute = true
	end
boc = boc + 0.2

if boc > 50 then
	boc = 50
end
	if dist < 300 then 
		wait = wait - dt
		if wait < 0 then
		launch = true
		end
	end
		if launch and amountspawn > 0 and ttime < 0 then 
			
			ttime = .5
			amountspawn = amountspawn - 1
			local size = math.random(1,1)
				if size == 1 then 
					local what = math.random(1,3)
					if what == math.random(1,3) then 
						local SpawnPos = GetLightTransform(spawnpos)
						Spawn("MOD/prefabs/Supply Drop2.xml", SpawnPos)
					elseif what == 2 then 
						local SpawnPos = GetLightTransform(spawnpos)
						Spawn("MOD/prefabs/Supply Drop4.xml", SpawnPos)
					elseif what == 3 then 
						local SpawnPos = GetLightTransform(spawnpos)
						Spawn("MOD/prefabs/Supply Drop6.xml", SpawnPos)
					end
				end
				if size == 2 or size == 3 then 
					local what = math.random(1,3)
					if what == 1 then 
						local SpawnPos = GetLightTransform(spawnpos)
						Spawn("MOD/prefabs/Supply Drop1.xml", SpawnPos)
					elseif what == 2 then 
						local SpawnPos = GetLightTransform(spawnpos)
						Spawn("MOD/prefabs/Supply Drop3.xml", SpawnPos)
					elseif what == 3 then 
						local SpawnPos = GetLightTransform(spawnpos)
						Spawn("MOD/prefabs/Supply Drop5.xml", SpawnPos)
					end
				end
			end
		

	
despawn = despawn - dt
	
if despawn < 0 and launch and dist > 200 then 
Delete(sb)
for i=1,#prop do       
      local props = prop[i]  
      Delete(props)           
    end
end





	
	
	
	



end	

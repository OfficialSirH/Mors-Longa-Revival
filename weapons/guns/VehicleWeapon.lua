#include "gunfunctions.lua"
#include "gunperks.lua"
#include "gunstats.lua"
function init()
	ProjectileHandlerInit()
	InitSettings()
end

function InitSettings()
	VehicleUpdate = true
	Vehicle = nil
	Shapes = nil
	Modifications = {
		["Gun"] = {},
	}
end

function tick(dt)
	DebugWatch("VehicleMods", Modifications)
	if GetPlayerVehicle() ~= 0 then
		do 
			if VehicleUpdate then
				Vehicle = GetPlayerVehicle()
				local Bodies = GetVehicleBodies(Vehicle)
				for j=1,#Bodies do 
					Shapes = GetBodyShapes(Bodies[j])
					for i=1,#Shapes do
						if HasTag(Shapes[i], "mod") then
							table.insert(Modifications[GetTagValue(Shapes[i],"mod")], Shapes[i])
						end
					end
				end
				
				
				VehicleUpdate = false
			end
			if InputPressed("lmb") then
				for i=1,#Modifications.Gun do
					local Light = GetShapeLights(Modifications.Gun[i])[1]
					Shoot(GetLightTransform(Light), "556", "T")
					
					DebugCross(GetLightTransform(Light).pos)
				end
			end
		end
	
	else
		if not VehicleUpdate then		
			InitSettings()
		end
		
	end
	
	
	for key, shell in ipairs(projectileHandler.shells) do
		if shell.active then
			ProjectileOperations(shell)
		end
	end
	for key, shell in ipairs(grenadeHandler.shells) do
		if shell.active then
			GrenadeOperations(shell)
		end
	end

end

function randBetween(min, max)
	return math.random() * (max - min) + min
end

function randVec(min, max)
    return Vec(randBetween(min, max), randBetween(min, max), randBetween(min, max))
end

function Shoot(gt, Cartridge, Type)
	local perktable=gunperks[Cartridge][Type]
	local damage = perktable["damage"]
	local pdamage = perktable["pdamage"]
	local explosive = perktable["explosive"]
	local tracer = perktable["tracer"]
	local velocity = perktable["velocity"]
	local maxMomentum = perktable["maxMomentum"]
	
	local lvl5armor = perktable["lvl5armor"]
	local lvl4armor = perktable["lvl4armor"]
	local lvl3armor = perktable["lvl3armor"]
	local lvl2armor = perktable["lvl2armor"]
	local lvl1armor = perktable["lvl1armor"]
	local accuracyFactor = 2
	
	local fwd = TransformToParentVec(gt,VecNormalize(VecAdd(Vec(1, 0, 0), randVec(-0.01, 0.01))))

	
	projectileHandler.shells[projectileHandler.shellNum] = deepcopy(projectileHandler.defaultShell)
	loadedShell = projectileHandler.shells[projectileHandler.shellNum] 
	loadedShell.armor = {lvl1armor,lvl2armor,lvl3armor,lvl4armor,lvl5armor}
	loadedShell.damage = damage
	loadedShell.pdamage = pdamage
	loadedShell.explosive = explosive
	loadedShell.tracer = tracer
	loadedShell.velocity = velocity
	loadedShell.maxmomentum = maxMomentum
	loadedShell.active = true
	loadedShell.pos = gt.pos
	loadedShell.momentum = maxMomentum
	loadedShell.predictedBulletVelocity = VecScale(fwd, velocity)
	projectileHandler.shellNum = (projectileHandler.shellNum%#projectileHandler.shells) + 1
	loadedShell.predictedBulletVelocity = VecAdd(loadedShell.predictedBulletVelocity, Vec((math.random()-0.5)*accuracyFactor*2, (math.random()-0.5)*accuracyFactor*2, (math.random()-0.5)*accuracyFactor*2))


end
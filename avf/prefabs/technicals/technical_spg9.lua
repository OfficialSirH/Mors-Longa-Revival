#version 2
#include "script/include/player.lua"
#include "../../../scripts/MountedGun.lua"
-- (v2, 2026-11-13) SPG-9 technical (technical_SPG9.xml, road spawn VehicleM4): recoilless gun on our own mounted-gun
-- script with AVF's shells ported (scripts/avf; v1 included ../../scripts/avf_custom.lua and needed the external AVF
-- mod). The AVF table below is still the gun's config (mainCannon, weapon type "rocket": PG-9 AT / OG-9 HE, F
-- switches). Standing gunner place left of the tube (its sight side); the driver does not fire. The XML's backblast
-- location was also tagged mainCannon_emitter (AVF: a second barrel at the rear end): retagged mainCannon_backblast.
MountedGunSound = "MOD/avf/assets/sounds/recoilessRifle0.ogg" -- the config's soundFile (copied from AVF)


--[[

	use this file to config the parameters for your tank

	Feel free to rename this to the name of your tank



]]

vehicleParts = {
	chassis = {
		
	},
	turrets = {

	},
	guns = {
		["mainCannon"] = {	
					name 	= "SPG-9",
					weaponType 				= "rocket",
					caliber 				= 73,
					magazines 					= {
											[1] = {
													name = "PG9_AT",
													magazineCapacity = 1,
													ammoCount = 0,
													magazineCount = 20,
													caliber 				= 73,
													velocity				= 430,
													explosionSize			= 1,
													gravityCoef 			= 1.25,
													maxPenDepth 			= .6,
													timeToLive 				= 12,
													launcher				= "rocket",
													payload					= "HEAT",
													shellWidth				= 0.8,
													shellHeight				= 1.5,
													r						= 0.3,
													g						= 0.8, 
													b						= 0.3, 
													shellSpriteName			= "MOD/gfx/rocketModel.png",
													shellSpriteRearName		= "MOD/gfx/rocketRear.png",

												},
											[2] = {
													name = "OG9_HE",
													magazineCapacity = 1,
													ammoCount = 0,
													magazineCount = 20,
													velocity				= 400,
													explosionSize			= 1.2,
													maxPenDepth 			= 0.1,

													gravityCoef 			= 1.5,
													timeToLive 				= 12,
													launcher				= "rocket",
													payload					= "HE",
													shellWidth				= 0.8,
													shellHeight				= 1.5,
													r						= 0.3,
													g						= 0.8, 
													b						= 0.3, 
													shellSpriteName			= "MOD/gfx/rocketModel.png",
													shellSpriteRearName		= "MOD/gfx/rocketRear.png",
													},
											},
					loadedMagazine 			= 1,
					barrels 				= 
												{
													[1] = {x=0.2,y=0.2,z=-0.3},
												},
					multiBarrel 			= 1,
					sight					= {
												[1] = {
												x = 0.6,
												y = 1.8,
												z = 0.2,
													},


												},
					backBlast				= 
												{
													[1] = {z=4.3,force=5},
												},
					canZoom					= true,
					zoomSight 				= "MOD/gfx/spg9-sight.png",
					highVelocityShells		= true,
					RPM 					= 20,
					reload 					= 2,
					recoil 					= 0.1,
					weapon_recoil 			= 333,
					cannonBlast 			= 2.5,
					dispersion 				= 20,
					gunRange				= 500,
					gunBias 				= -1,
					elevationSpeed			= .5,
					smokeFactor 			= 1,
					smokeMulti				= 5,
					soundFile				= "MOD/sounds/recoilessRifle0",
				},
	},
}
	

	---- magazine num _ val
	---- barrels num value

vehicle = {

}


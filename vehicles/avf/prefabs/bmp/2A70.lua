#version 2
DL_LABEL = "2A70"  -- crash breadcrumbs (lib/DeleteLog.lua)
#include "../../../../lib/DeleteLog.lua"
#include "script/include/player.lua"
#include "../../../MountedGun.lua"
-- (v2) BMP-3 (spawn menu "BMP-3", 100 mm 2A70): main gun on our own mounted-gun script with AVF's shells ported
-- (scripts/avf; v1 included ../../scripts/avf_custom.lua and needed the external AVF mod). The AVF table below is
-- still the gun's config (mainCannon: weaponType "cannon"; the 30 mm coax: later).
MountedGunSound = "MOD/vehicles/avf/assets/sounds/tankshot0.ogg" -- the config's soundFile (copied from AVF)


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

					name 	= "2A70  100mm gun",
					weaponType 				= "cannon",
					caliber 				= 100,
					default = "100mm_HEAT",
					magazines 					= {
						[1] = {
								name = "3UBK10-3 ",
								caliber 				= 100,
								velocity				= 60,
								explosionSize			= 1.2,
								maxPenDepth 			= 2.2,
								timeToLive 				= 15,
								gravityCoef 			= 0,
								launcher				= "guided",
								payload					= "HEAT",
								shellWidth				= 0.35,
								shellHeight				= 4,
								r						= 0.3,
								g						= 0.6, 
								b						= 0.3, 
								shellSpriteName			= "MOD/gfx/rocketModel.png",
								shellSpriteRearName		= "MOD/gfx/rocketRear.png",
								magazineCapacity = 1,
								ammoCount = 0,
								magazineCount = 500,

						
							},
						[2] = {
								name = "3UOF17 HEF",
								caliber 				= 100,
								velocity				= 300,
								explosionSize			= 1.5,
								maxPenDepth 			= 0.1,
								timeToLive 				= 7,
								gravityCoef 			= 8.5,
								launcher				= "cannon",
								payload					= "HE",
								shellWidth				= 1.8,
								shellHeight				= 0.6,
								r						= 0.8,
								g						= 0.3, 
								b						= 0.3, 
								shellSpriteName			= "MOD/gfx/shellModel2.png",
								shellSpriteRearName		= "MOD/gfx/shellRear2.png",
								magazineCapacity = 1,
								ammoCount = 0,
								magazineCount = 500,
							}, 
						},
					loadedMagazine 			= 1,
					barrels 				= 
												{
													[1] = {x=0.2,y=0.2,z=-0.3},
												},
					sight					= {
												[1] = {
												x=3,
												y=1.3,
												z=0.3,
													},
												},

					scope_offset 			= {
												[1] = {
													x = 0.01,
													y = -0.02
													},
											},
					canZoom					= true,
					zoomSight 				= "MOD/gfx/1G46Sight.png",
					multiBarrel 			= 1,
					highVelocityShells		= true,
					cannonBlast 			= 10,
					RPM 					= 12,
					reload 					= 6,
					recoil 					= 1.6,
					dispersion 				= 1,
					gunRange				= 1500,
					gunBias 				= -1,
					elevationSpeed			= .5,
					smokeFactor 			= 2,
					smokeMulti				= 3,
					soundFile				= "MOD/sounds/tankshot0",
					reloadSound				= "MOD/sounds/AltTankReload",

				},
	},
}
	

	---- magazine num _ val
	---- barrels num value

vehicle = {

}


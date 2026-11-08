#version 2
#include "script/include/player.lua"
#include "../../../scripts/MountedGun.lua"
-- (v2) M2 .50 cal on the Hummer With 50 Cal and the Willys in VehicleM7: runs on our own mounted-gun script (scripts/MountedGun.lua) instead of the external AVF mod
-- (v1 included ../../scripts/avf_custom.lua). The AVF table below is still the gun's config.
MountedGunCalibre = "127x99" -- gunperks.lua calibre for damage / velocity
MountedGunSound = "MOD/snd/Weapons/m107/m107_0.ogg" -- AVF's MOD/sounds/... files live in the external AVF mod


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
					name 	= "M2 Browning",
					caliber 				= 12.7,
					weaponType 				= "MGun",
					loadedMagazine 			= 1,
					magazines 					= {
											[1] = {
													name = "12.7 x 99mm",
													magazineCapacity = 110,
													ammoCount = 0,
													magazineCount = 7,
													caliber 				= 12.7,
													velocity				= 210,
													hit 					=3,
													maxPenDepth 			= 0.21,
													timeToLive 				= 7,
													launcher				= "mgun",
													payload					= "AP",
													gravityCoef 			= 1.3,
													shellWidth				= 0.1,
													shellHeight				= 0.1,
													r						= 1.9,
													g						= 0.3, 
													b						= 0.3, 
													tracer 					= 2,
													tracerL					= 7,
													tracerW					= 2,
													tracerR					= 1.8,
													tracerG					= 1.0, 
													tracerB					= 1.0, 
													shellSpriteName			= "MOD/gfx/shellModel2.png",
													shellSpriteRearName		= "MOD/gfx/shellRear2.png",
											},
										},

				barrels 				= 
											{
												[1] = {x=0,y=0.2,z=-0.6},
											},
				multiBarrel 			= 1,

				sight					= {
												[1] = {
											x = .25,
											y = 2.,
											z = 1.8,
												},


											},
				canZoom					= false,
				RPM 					= 550,
				reload 					= 4,
				magazineCapacity 		= 110,
				recoil 					= 0.10,
				weapon_recoil 			= 20,
				dispersion 				= 6,
				gunRange				= 3000,
				elevationSpeed			= .5,
				smokeFactor 			= .1,
				smokeMulti				= 1,
				soundFile 				=	"MOD/sounds/HeavySingleShot",
				mouseDownSoundFile 		=	"MOD/sounds/HeavyAutoFire",
				loopSoundFile			= 	"MOD/sounds/HeavyAutoFire",			
				},
	},
}
	

	---- magazine num _ val
	---- barrels num value

vehicle = {

}
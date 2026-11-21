#version 2
DL_LABEL = "technical_dshk"  -- crash breadcrumbs (lib/DeleteLog.lua)
#include "../../../../lib/DeleteLog.lua"
#include "script/include/player.lua"
#include "../../../MountedGun.lua"
-- (v2) DShK on the AAF Pickup Truck technical (technical_DSHK.xml + copies in roadblock3, test.xml): runs on our own mounted-gun script (vehicles/MountedGun.lua) instead of the external AVF mod
-- (v1 included ../../scripts/avf_custom.lua). The AVF table below is still the gun's config.
MountedGunCalibre = "127x99" -- gunperks.lua calibre for damage / velocity
MountedGunSound = "MOD/assets/snd/Weapons/m107/m107_0.ogg" -- AVF's MOD/sounds/... files live in the external AVF mod


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
					name 	= "DSHK",
					caliber 				= 12.7,
					weaponType 				= "MGun",
					loadedMagazine 			= 1,
					magazines 					= {
											[1] = {
													name = "B_127x107_Ball",
													magazineCapacity = 50,
													ammoCount = 0,
													magazineCount = 20,
													caliber 				= 12.7,
													velocity				= 240,
													hit 					=3,
													maxPenDepth 			= 0.33,
													timeToLive 				= 7,
													launcher				= "mgun",
													payload					= "AP",
													gravityCoef 			= 1.3,
													shellWidth				= 0.1,
													shellHeight				= 0.3,
													r						= 0.8,
													g						= 0.8, 
													b						= 0.5, 
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
				RPM 					= 360,
				reload 					= 4,
				magazineCapacity 		= 100,
				recoil 					= 0.05,
				weapon_recoil 			= 200,
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


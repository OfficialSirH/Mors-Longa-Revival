#include "../../scripts/avf_custom.lua"


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
					name 	= "PKM",
					caliber 				= 7.62,
					weaponType 				= "MGun",
					loadedMagazine 			= 1,
					magazines 					= {
											[1] = {
													name = "PKM 7.62",
													magazineCapacity = 150,
													ammoCount = 0,
													magazineCount = 20,
													caliber 				= 7.62,
													velocity				= 350,
													hit 					=1,
													maxPenDepth 			= 0.33,
													timeToLive 				= 7,
													launcher				= "mgun",
													payload					= "AP",
													gravityCoef 			= 2,
													shellWidth				= 0.1,
													shellHeight				= 0.3,
													r						= 0.8,
													g						= 0.8, 
													b						= 0.5, 
													tracer 					= 5,
													tracerL					= 6,
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
				RPM 					= 750,
				reload 					= 4,
				magazineCapacity 		= 100,
				recoil 					= 0.05,
				weapon_recoil 			= 5,
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


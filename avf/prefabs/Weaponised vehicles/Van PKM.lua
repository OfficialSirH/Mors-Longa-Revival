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
													name = "7.62 × 54mmR",
													magazineCapacity = 250,
													ammoCount = 0,
													magazineCount = 5,
													caliber 				= 7.62,
													velocity				= 170,
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
				RPM 					= 650,
				reload 					= 4,
				magazineCapacity 		= 250,
				recoil 					= 0.10,
				weapon_recoil 			= 20,
				dispersion 				= 6,
				gunRange				= 3000,
				elevationSpeed			= .5,
				smokeFactor 			= .1,
				smokeMulti				= 1,		
				},
	},
}
	

	---- magazine num _ val
	---- barrels num value

vehicle = {

}
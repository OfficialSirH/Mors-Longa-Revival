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
					name 	= "AGS-30",
					caliber 				= 30,
					weaponType 				= "GMGun",
					loadedMagazine 			= 1,
					magazines 					= {
											[1] = {
									name = "30 mm grenade",
									magazineCapacity = 30,
									ammoCount = 0,
									magazineCount = 50,
									caliber 				= 40,
									velocity				= 180,
									gravityCoef 			= 1.7,
									explosionSize			= .5,
									maxPenDepth 			= 0.17,
									timeToLive 				= 20,
									launcher				= "cannon",
									payload					= "HE",
									shellWidth				= 0.3,
									shellHeight				= .55,
									r						= 0.6,
									g						= 0.3, 
									b						= 0.3, 
									shellSpriteName			= "MOD/gfx/shellModel2.png",
									shellSpriteRearName		= "MOD/gfx/shellRear2.png",
			},
											},

				barrels 				= 
											{
												[1] = {x=0.65,y=0.3,z=-0.1},
											},
				multiBarrel 			= 1,

				sight					= {
												[1] = {
											x = 0.15,
											y = 0.9,
											z = 1.68,
												},


											},
				canZoom					= false,
				aimForwards				= true,
				RPM 					= 340 ,
				cannonBlast				= 0.1,
				reload 					= 6,
				magazineCapacity 		= 100,
				recoil 					= 0.2,

				weapon_recoil 					= 0.1,
				dispersion 				= 10,
				gunRange				= 3000,
				elevationSpeed			= .5,
				smokeFactor 			= .3,
				smokeMulti				= 3,
				soundFile 				=	"MOD/sounds/grenade_mg/single_shot_01",
				mouseDownSoundFile 		=	"MOD/sounds/grenade_mg/auto_01",
				loopSoundFile			= 	"MOD/sounds/grenade_mg/auto_01",
				tailOffSound	 		=	"MOD/sounds/grenade_mg/auto_tail_off_01",				
				},
	},
}
	

	---- magazine num _ val
	---- barrels num value

vehicle = {

}


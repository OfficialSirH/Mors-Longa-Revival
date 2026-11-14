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
		["2A4230MM"]  = {
			name 	= "2A42 30mm",
			weaponType 				= "cannon",
			caliber 				= 30,
			default = "30mm",
			magazines 					= {
				[1] = {
					name = "3UBR6 APBC",
					caliber 				= 30,
					velocity				= 390,
					explosionSize			= 0.1,
					maxPenDepth 			= 2.4,
					timeToLive 				= 7,
					gravityCoef 			= 0.5,--0.3,
					launcher				= "cannon",
					payload					= "AP",
					shellWidth				= 0.15,
					shellHeight				= 0.8,
					r						= 1.7,
					g						= 8.7, 
					b						= 1.7, 
					shellSpriteName			= "MOD/gfx/sabot.png",
					shellSpriteRearName		= "MOD/gfx/sabotRear.png",
					magazineCapacity = 100,
					ammoCount = 0,
					magazineCount = 2,				
				},
				[2] = {
					name = "3UOF8 HEI",
					caliber 				= 30,
					velocity				= 270,
					explosionSize			= 0.8,
					maxPenDepth 			= 0.1,
					timeToLive 				= 7,
					gravityCoef 			= 0.9,--0.3,
					launcher				= "cannon",
					payload					= "HE",
					shellWidth				= 0.5,
					shellHeight				= 0.1,
					r						= 8.8,
					g						= 0.3, 
					b						= 0.3, 
					shellSpriteName			= "MOD/gfx/shellModel2.png",
					shellSpriteRearName		= "MOD/gfx/shellRear2.png",
					magazineCapacity = 100,
					ammoCount = 0,
					magazineCount = 1,				
				
				},
			},
			coax = 	{
				name="PKT 7.62 Coax",
				sight					= {
					[1] = {
						x=2.5,
						y=2.5,
						z=0.6,
							},
											},
				barrels		= {
								[1] = {
									x = 0.25,
									y = 2.2,
									z = 0.3,
									}
								},
								scope_offset             = {
									[1] = {
										x = 0.0,
										y = -0.03,
										},
												},
				RPM 					= 750,
				elevationSpeed			= .4,
				zoomSight                 = "MOD/gfx/BPK-2-42.png",
				fireControlComputer		= "MOD/gfx/scopeOutside_2.png",
				canZoom					= true,
				soundFile   = "MOD/sounds/machine_gun/gpmg_single_02.ogg",
				mouseDownSoundFile 			=	"MOD/sounds/machine_gun/m2_single_01.ogg",
				reloadSound                = "MOD/sounds/alt_reload_reject",

				-- 				},
				
				magazines = {
					[1] = {
						name = "7.62×54mm 7N13",
						caliber 				= 7.62,
						velocity				= 825,
						explosionSize			= 0.1,
						maxPenDepth 			= 0.6,
						timeToLive 				= 7,
						gravityCoef 			= 0.5,--0.3,
						launcher				= "cannon",
						payload					= "AP",
						shellWidth				= 0.1,
						shellHeight				= 0.2,
						r						= 1.7,
						g						= 8.7, 
						b						= 1.7, 
						shellSpriteName			= "MOD/gfx/sabot.png",
						shellSpriteRearName		= "MOD/gfx/sabotRear.png",
						magazineCapacity = 500,
						ammoCount = 0,
						magazineCount = 2,
					},
					[2] = {
						name = "7.62×54mm T46",
						caliber 				= 7.62,
						velocity				= 825,
						explosionSize			= 0.2,
						maxPenDepth 			= 0.4,
						timeToLive 				= 7,
						gravityCoef 			= 0.9,--0.3,
						launcher				= "cannon",
						payload					= "HE",
						shellWidth				= 0.1,
						shellHeight				= 0.1,
						r						= 1.7,
						g						= 8.7, 
						b						= 1.7, 
						shellSpriteName			= "MOD/gfx/sabot.png",
						shellSpriteRearName		= "MOD/gfx/sabotRear.png",
						magazineCapacity = 500,
						ammoCount = 0,
						magazineCount = 2,
					},
					},
				},
			loadedMagazine 			= 1,
			barrels 				= 
										{
											[1] = {x=0.15,y=0.15,z=-2}
										},
			sight					= {
										[1] = {
										x=1.5,
										y=2.2,
										z=0.3,
											},
										},

			scope_offset 			= {
										[1] = {
											x = 0.0,
											y = -0.03,
											},
									},
									canZoom                    = true,
									zoomSight                 = "MOD/gfx/BPK-2-42.png",
									fireControlComputer		= "MOD/gfx/scopeOutside_2.png",
									highVelocityShells        = true,
									cannonBlast             = 4,
									RPM                     = 250,
									reload                     = 15,
									recoil                     = 0.1,
									dispersion                 = 6,
									gunRange                = 500,
									gunBias                 = -1,
									elevationSpeed            = .5,
									smokeFactor             = 0.5,
									smokeMulti                = 1,
									soundFile   = "MOD/sounds/BMPsingle",
									mouseDownSoundFile         =    "MOD/sounds/bmpAutoFire",
									loopSoundFile             =    "MOD/sounds/bmpAutoFire.ogg",
									tailOffSound             =    "MOD/sounds/altFirealt_TailOff_2",
									reloadSound                = "MOD/sounds/AltTankReload",
		},
		["9m133m2"]		= {
				name 	= "9M133 Kornet",
				weaponType 				= "atgm",
				caliber 				= 73,
				magazines 					= {
										[1] = {
									name = "9M133M-2",
									magazineCapacity = 1,
									ammoCount = 0,
									magazineCount = 20,
									caliber 				= 152,
									velocity				= 60,
									gravityCoef 			= 0,
									dispersionCoef 			= 10,
									explosionSize			= 1.2,
									maxPenDepth 			= 3.0,
									timeToLive 				= 32,
									launcher				= "guided",
									payload					= "HEAT",
									shellWidth				= 0.3,
									shellHeight				= 4.5,
									r						= 0.9,
									g						= 0.3, 
									b						= 0.3, 
									shellSpriteName			= "MOD/gfx/rocketModel.png",
									shellSpriteRearName		= "MOD/gfx/rocketRear.png",
									flightLoop				= "MOD/sounds/rocketFlightLoop0",

											},
										},
				loadedMagazine 			= 1,
				barrels 				= 
											{
												[1] = {x=0.1,y=0.15,z=-0.5},
											},
				multiBarrel 			= 1,
				sight					= {
											[1] = {
											x=1,
											y=2.2,
											z=0.6,
												},


											},
				backBlast				= 
											{
												[1] = {z=1.3,force=0},
											},
				canZoom					= true,
				aimForwards				= true,
				zoomSight 				= "MOD/gfx/KORNETsight.png",
				fireControlComputer		= "MOD/gfx/TEDAC1.png",
				highVelocityShells		= true,
				RPM 					= 50,
				reload 					= 2,
				recoil 					= 0,
				dispersion 				= 40,
				gunRange				= 1500,
				gunBias 				= -1,
				elevationSpeed			= 0.4,
				smokeFactor 			= 1,
				smokeMulti				= 5,
				soundFile				= "MOD/sounds/atgm00.ogg",
					},
					
	},
}
	

	---- magazine num _ val
	---- barrels num value

vehicle = {

}


#version 2
DL_LABEL = "BMP-2"  -- crash breadcrumbs (lib/DeleteLog.lua)
#include "../../../../lib/DeleteLog.lua"
#include "script/include/player.lua"
#include "../../../MountedGun.lua"
-- (v2) BMP-2 (spawn menu "BMP-2"): main gun on our own mounted-gun script with AVF's shells ported (scripts/avf;
-- v1 included ../../scripts/avf_custom.lua and needed the external AVF mod).
-- The AVF table below is still the gun's config (mainCannon: weaponType "cannon"; coax / ATGM: later).
MountedGunSound = "MOD/vehicles/avf/assets/sounds/autoCannonSingle.ogg" -- the config's soundFile (copied from AVF)


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
			name="2A42 30mm",
			RPM=550,
			weaponType 				= "cannon",
			caliber 				= 30,
			sight					= {
										[1] = {
										x=0.6,
										y=1.45,
										z=-0.35,
											},
										},

			scope_offset 			= {
										[1] = {
											x = -0.02,
											y = -0.06
											},
									},
			zoomSight 				= "MOD/gfx/no_48_mkII.png",
			fireControlComputer			= "MOD/gfx/scopeOutside_3.png",
			soundFile				= "MOD/sounds/autoCannonSingle",
			reloadSound				= "MOD/sounds/alt_reload_reject",
			recoil 					= 0.01,
			smokeFactor 				= 0.5,
			smokeMulti				= 1,
			reloadPlayOnce			= true,
										-- aimForwards = true,
			zero_range 				= 100,
			barrels		= {
							[1] = {
								x = 0.35,
								y = 0.1,
								z = -3.9,
								}

							},
			
			magazines = {
						[1] = {name="3UBR8 APDS",
						caliber 				= 30,
						velocity				= 390,
						explosionSize			= 0.1,
						maxPenDepth 			= 2.4,
						timeToLive 				= 7,
						gravityCoef 			= 0.5,--0.3,
						launcher				= "cannon",
						payload					= "AP",
						shellWidth				= 0.1,
						shellHeight				= 1.1,
						r						= 1.7,
						g						= 8.7, 
						b						= 1.7, 
						shellSpriteName			= "MOD/gfx/sabot.png",
						shellSpriteRearName		= "MOD/gfx/sabotRear.png",
						magazineCapacity = 250,
						ammoCount = 0,
						magazineCount = 2,			
					},
						[2] = {name="3UOF8 HEI",
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
						magazineCapacity = 250,
						ammoCount = 0,
						magazineCount = 1,		
					},
				},
				coax = 	{
					name="PKT 7.62 Coax",
					caliber 				= 7.62,
					RPM = 650,
					sight					= {
												[1] = {
												x=0.6,
												y=0.4,
												z=-0.35,
													},
												},
					scope_offset 			= {
										[1] = {
											x = -0.02,
											y = -0.06
											},
									},	
					barrels		= {
										[1] = {
											x = 0.85,
											y = -0.0,
											z = -0.9,
											}
										},
					elevationSpeed			= .5,
					zoomSight 				= "MOD/gfx/no_48_mkII.png",
					fireControlComputer			= "MOD/gfx/scopeOutside_3.png",
					soundFile   				= "MOD/sounds/machine_gun/gpmg_single_02.ogg",
					mouseDownSoundFile 			= "MOD/sounds/machine_gun/m2_single_01.ogg",
					reloadSound                		= "MOD/sounds/alt_reload_reject",
					canZoom					= true,

					-- 				},
					
					magazines = {
								[1] = {name="7.62mm",
								maxPenDepth = 0.076,
								magazineCapacity = 250,
								magazineCount = 14,
								r						= 0.3,
								g						= 0.3, 
								b						= 0.3, 
							},
						},
				},
			
		},
		["9m133m2"] = 	{
			caliber 				= 125,
			name="M133 Kornet",
			weaponType 				= "atgm",
			RPM = 5,
			canZoom					= true,
			aimForwards				= true,
			zoomSight 				= "MOD/gfx/KORNETsight.png",
			fireControlComputer			= "MOD/gfx/scope_outer_faded_02.png",
			highVelocityShells			= true,
			elevationSpeed				= 0.3,
			reload 					= 2,
			recoil 					= 0,
			dispersion 				= 40,
			gunRange				= 1500,
			gunBias 				= -1,
			elevationSpeed			= 0.4,
			smokeFactor 			= 1,
			smokeMulti				= 5,
			soundFile				= "MOD/sounds/atgm00",
			sight					= {
										[1] = {
										x=0.05,
										y=0.6,
										z=1.95,
											},
										},
			scope_offset 			= {
										[1] = {
											x = -0.0,
											y = 0.01
											},
									},
			zero_range 				= 100,
			barrels		= {
							[1] = {
								x = -0.0,
								y = 0.25,
								z = -0.5,
								}
							},

			-- 				},
			
			magazines = {
						[1] = {name="9M133M-2 ATGM",
						magazineCapacity = 1,
						ammoCount = 0,
						magazineCount = 4,
						caliber 				= 135,
						velocity				= 50,
						explosionSize			= 1,
						maxPenDepth 			= 5.0,
						gravityCoef 			= 0,
						dispersionCoef 			= 10,
						explosionSize			= 1.2,
						maxPenDepth 			= 2.0,
						timeToLive 				= 32,
						launcher				= "guided",
						payload					= "HEAT",
						shellWidth				= 0.3,
						shellHeight				= 4,
						r						= 0.9,
						g						= 0.3, 
						b						= 0.3, 
						shellSpriteName			= "MOD/gfx/rocketModel.png",
						shellSpriteRearName		= "MOD/gfx/rocketRear.png",
						flightLoop				= "MOD/sounds/rocketFlightLoop0",
					},
				},
			},
	},
}
	

	---- magazine num _ val
	---- barrels num value

vehicle = {

}
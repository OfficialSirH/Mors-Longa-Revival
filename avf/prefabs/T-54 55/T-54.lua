#version 2
#include "script/include/player.lua"
#include "../../../scripts/MountedGun.lua"
-- (v2) T-54 (spawn menu "T-54 AAF"): main gun on our own mounted-gun script with AVF's shells ported (scripts/avf; v1 included
-- ../../scripts/avf_custom.lua and needed the external AVF mod). The AVF table below is still the gun's config
-- (mainCannon; coax: later). Gunner place in the turret; the driver fires while it is empty (user, 2026-11-13).
MountedGunSound = "MOD/avf/assets/sounds/tankshot0.ogg" -- the config's soundFile (copied from AVF)
MountedGunDriverFires = true


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
			name="100mm D-10T Cannon",
			RPM=6.5,
			sight					= {
										[1] = {
										x=0.6,
										y=1.45,
										z=-0.35,
											},
										},

			scope_offset 			= {
										[1] = {
											x = 0.01,
											y = -0.07
											},
									},
			zoomSight 				= "MOD/gfx/1G46Sight.png",
			fireControlComputer			= "MOD/gfx/scopeOutside_3.png",
			soundFile				= "MOD/sounds/tankshot0",
			reloadSound				= "MOD/sounds/AltTankReload",
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
						[1] = {name="BR-412B (APHEBC)",
						caliber 				= 100,
						velocity				= 895,
						explosionSize			= 0.5,
						maxPenDepth = 2.18,
						payload					= "APHE",
						magazineCount             = 9,
					},
						[2] = {name="OF-412 (HE)",
						caliber 				= 100,
						velocity				= 900,
						explosionSize			= 0.5,
						maxPenDepth 			= 0.2,
						r						= 0.3,
						g						= 0.3, 
						b						= 0.3, 
						payload = "HE",
						magazineCount             = 9, 
					},
						[3] = {name="3BK-5 (HEAT)",
						caliber 				= 100,
						velocity				= 905,
						explosionSize			= 0.5,
						maxPenDepth = 3.80,
						payload					= "HEAT",
						magazineCount             = 8,
					},
						[4] = {name="3BM-8 (APDS)",
						caliber 				= 100,
						velocity				= 1415,
						maxPenDepth 			= 3.0,
						r						= 0.3,
						g						= 0.3, 
						b						= 0.3, 
						payload = "kinetic",
						magazineCount             = 8, 
					},
				},
				coax = 	{
					name="7.62mm SG-43",
					caliber 				= 7.62,
					RPM = 550,
					sight					= {
												[1] = {
												x=0.6,
												y=0.4,
												z=-0.35,
													},
												},
					scope_offset 			= {
										[1] = {
											x = 0.01,
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
					zoomSight 				= "MOD/gfx/1G46Sight.png",
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
		["DSHK"] = 	{
			caliber 				= 12.7,
			name="12.7mm DSHK",
			RPM = 550,
			elevationSpeed			= 0.3,
			sight					= {
										[1] = {
										x=-0.25,
										y=1.75,
										z=2.90,
											},
										},
			barrels		= {
							[1] = {
								x = 0.05,
								y = 0.25,
								z = -0.5,
								}
							},

			-- 				},
			
			magazines = {
						[1] = {name="12.7mm",
						maxPenDepth = 0.1,
						magazineCapacity = 63,
						magazineCount = 29,
						r						= 0.3,
						g						= 0.3, 
						b						= 0.3, 
					},
				},
			},
	},
}
	

	---- magazine num _ val
	---- barrels num value

vehicle = {

}
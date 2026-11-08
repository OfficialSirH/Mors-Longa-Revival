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
			name="100mm D-10T2S Cannon",
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
						[1] = {name="3BK-5 (HEAT)",
						caliber 				= 100,
						velocity				= 1085,
						explosionSize			= 0.5,
						maxPenDepth = 3.80,
						payload					= "HEAT",
						magazineCount             = 15,
					},
						[2] = {name="3BM25 (APFSDS)",
						caliber 				= 100,
						velocity				= 1430,
						maxPenDepth 			= 3.35,
						r						= 0.3,
						g						= 0.3, 
						b						= 0.3, 
						payload = "kinetic",
						magazineCount             = 15, 
					},
						[3] = {name="OF-412 (HE)",
						caliber 				= 100,
						velocity				= 900,
						explosionSize			= 0.5,
						maxPenDepth 			= 0.2,
						r						= 0.3,
						g						= 0.3, 
						b						= 0.3, 
						payload = "HE",
						magazineCount             = 14, 
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
										x=0.15,
										y=1.75,
										z=2.10,
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
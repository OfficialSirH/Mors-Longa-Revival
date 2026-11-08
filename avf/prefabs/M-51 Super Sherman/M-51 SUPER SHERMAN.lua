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
			name="CN-105-F1",
			RPM=6.5,
			sight					= {
										[1] = {
										x=0.5,
										y=1.45,
										z=-0.3,
											},
										},

			scope_offset 			= {
										[1] = {
											x = 0.04,
											y = -0.04
											},
									},
			zoomSight 				= "MOD/gfx/Sherman_sights.png",
			fireControlComputer			= "MOD/gfx/scopeOutside_3.png",
			soundFile				= "MOD/sounds/Relic700KwK37",
			reloadSound				= "MOD/sounds/Relic700KwKReload",
			reloadPlayOnce			= true,
										-- aimForwards = true,
			zero_range 				= 3000,
			barrels		= {
							[1] = {
								x = 0.5,
								y = 0.15,
								z = -4.7,
								}

							},
			
			magazines = {
						[1] = {name="OCC 105 F1 (HEAT)",
						caliber 				= 105,
						velocity				= 290,
						explosionSize			= 0.4,
						maxPenDepth = 4.0,
						payload					= "HEAT",
						magazineCount             = 28,
					},
						[2] = {name="OE 105 F1 Mle.60(HE)",
						caliber 				= 105,
						velocity				= 290,
						explosionSize			= 0.4,
						maxPenDepth 			= 0.2,
						r						= 0.3,
						g						= 0.3, 
						b						= 0.3, 
						payload = "HE",
						magazineCount             = 28, 
					},
				},
				coax = 	{
					name="7.62mm M1919A4",
					caliber 				= 7.62,
					sight					= {
												[1] = {
												x=0.5,
												y=1.45,
												z=-0.3,
													},
												},
					scope_offset 			= {
										[1] = {
											x = 0.04,
											y = -0.04
											},
									},	
					barrels		= {
										[1] = {
											x = 0.95,
											y = 0.35,
											z = -0.9,
											}
										},

					elevationSpeed			= .5,
					zoomSight 				= "MOD/gfx/Sherman_sights.png",
					canZoom					= true,

					-- 				},
					
					magazines = {
								[1] = {name="7.62mm",
								r						= 1.9,
								g						= 0.3, 
								b						= 0.3, 
							},
						},
				},
			
		},
		["hull_mg"] = 	{
			caliber 				= 7.62,
			name="7.62mm M1919A4",
			sight					= {
										[1] = {
										x=0.5,
										y=1.45,
										z=-0.3,
											},
										},
			barrels		= {
							[1] = {
								x = 0.05,
								y = 0.15,
								z = -0.5,
								}
							},

			-- 				},
			
			magazines = {
						[1] = {name="7.62mm",
						r						= 1.9,
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
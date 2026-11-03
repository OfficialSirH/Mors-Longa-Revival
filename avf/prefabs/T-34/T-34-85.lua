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
			name="85mm ZIS-S-53 Cannon",
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
			zero_range 				= 100,
			barrels		= {
							[1] = {
								x = 0.35,
								y = 0.1,
								z = -3.9,
								}

							},
			
			magazines = {
						[1] = {name="BR-365K (APHE)",
						caliber 				= 85,
						velocity				= 290,
						explosionSize			= 0.5,
						maxPenDepth = 1.48,
						payload					= "APHE",
						magazineCount             = 20,
					},
						[2] = {name="O-365K (HE)",
						caliber 				= 85,
						velocity				= 290,
						explosionSize			= 0.5,
						maxPenDepth 			= 0.2,
						r						= 0.3,
						g						= 0.3, 
						b						= 0.3, 
						payload = "HE",
						magazineCount             = 20, 
					},
						[3] = {name="BR-365P (APCR)",
						caliber 				= 85,
						velocity				= 290,
						maxPenDepth 			= 1.95,
						r						= 0.3,
						g						= 0.3, 
						b						= 0.3, 
						payload = "AP",
						magazineCount             = 20, 
					},
				},
				coax = 	{
					name="7.62mm DT",
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
											x = 0.04,
											y = -0.04
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
					zoomSight 				= "MOD/gfx/Sherman_sights.png",
					canZoom					= true,

					-- 				},
					
					magazines = {
								[1] = {name="7.62mm",
								maxPenDepth = 0.076,
								magazineCapacity = 63,
								magazineCount = 29,
								r						= 0.3,
								g						= 0.3, 
								b						= 0.3, 
							},
						},
				},
			
		},
		["hull_mg"] = 	{
			caliber 				= 7.62,
			name="7.62mm DT",
			RPM = 550,
			sight					= {
										[1] = {
										x=0.5,
										y=-0.4,
										z=-0.05,
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
						[1] = {name="7.62mm",
						maxPenDepth = 0.076,
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
recipes = {

-- GUNS
	["Simonov-545U"]={
		displayName = ""

		description = {
			"",
		}

		consumeItem = {
			"gun-ak74",
			"material-steel",
		},
		requiredItem = {
			"tool-saw",
		},
		outputItem = {
			"gun-ak74_Simonov-545U_mag0-ak-545_6L23_0_30_5.45_--muzzle2-stock1--barrel1----",
			"material-scrap",
			"material-driftwood",
			"tool-saw",
		},
	},

	["Simonov-106"]={
		requiredKnowlage={
			"gunsmith"
		},
		requiredItem = {
			"gun-ak74",
			"material-scrap",
			{"material-rubber",ammount = 3},
		},
		outputItem = {
			"gun-ak74m_Simonov-545U_mag0-ak-545_6L23_0_30_5.45_-muzzle2------",
			{"material-driftwood",ammount = 2},
		}
	},

	["Qasira"]={
		requiredItem = {
			"gun-mudafie",
			"tool-saw",
		},
		outputItem = {
			"gun-sawedoff_Qasira_mag1_Internal_0_2_12ga",
			"material-scrap",
			"tool-saw",
		}
	},

	["Jalaad"]={
		requiredItem = {
			"gun-ak74",
			"tool-saw",
			"material-scrap",
			"material-scrap",
			"material-steel",
			"material-steel",
			"material-steel",
			"material-driftwood",
		},
		outputItem = {
			"gun-ak50_Jalaad_mag0-m107-127x99_N107-Mag_0_10_.50BMG",
			"material-scrap",
			"tool-saw",
		}
	},

-- MAGS

	["6L31"]={
		requiredItem = {
			"mag0-ak-545",
			"mag0-ak-545",
		},
		outputItem = {
			"mag4-ak-545_6L31_0_60_5.45",
		}
	},

-- AMMO

	["Rocket"]={
		requiredItem = {
			"material-explosive",
			"material-explosive",
			"material-steel",
			"material-scrap",
		},
		outputItem = {
			"rocket_Rocket",
		}
	},
	["Jank rocket"]={
		requiredItem = {
			"rocket_Rocket",
			("material-explosive","grenade",ammount = 3)
			"material-scrap",
		},
		outputItem = {
			"rocket_Rocket4",
		}
	},

-- MEDS

	["meds-surgery-cms"]={
		requiredItem = {
			"splint",
			"bandage",
			"bandage",
			"material-scrap",
		}
	},

}
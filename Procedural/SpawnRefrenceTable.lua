spawnables = {
	loots = {
		civFood = { -- common foods
			common = {
				{"food2.xml", 5, "Choccy"}, -- Choccy
				{"food5.xml", 3, "Water"}, -- Water
				{"food1.xml", 1, "Tuna"}, -- Tuna
				{"food4.xml", 1, "Beans"}, -- Beans
				{"food9.xml", 1, "Pineapple"}, -- Pineapple
				{"food11.xml", 1, "Spam"}, -- Spam
				{"food10.xml", 1, "Strawberry"}, -- Strawberry
				{"food21.xml", 1, "Peas"}, -- Peas
				{"food22.xml", 1, "Vegetables"}, -- Vegetables
				{"food23.xml", 1, "Olives"}, -- Olives
				{"food24.xml", 1, "Pepin"}, -- Pepin
				{"food25.xml", 1, "Tomatoes"}, -- Tomatoes
				{"food26.xml", 1, "Carrots"}, -- Carrots
				{"food27.xml", 1, "Blueberries"}, -- Blueberries
				{{
					{"food1.xml", 1, "Tuna"}, -- Tuna
					{"food4.xml", 1, "Beans"}, -- Beans
					{"food9.xml", 1, "Pineapple"}, -- Pineapple
					{"food11.xml", 1, "Spam"}, -- Spam
					{"food10.xml", 1, "Strawberry"}, -- Strawberry
					{"food21.xml", 1, "Peas"}, -- Peas
					{"food22.xml", 1, "Vegetables"}, -- Vegetables
					{"food23.xml", 1, "Olives"}, -- Olives
					{"food24.xml", 1, "Pepin"}, -- Pepin

				}, 4},
			},
			uncommon = {
				{"food5.xml", 3, "Water"}, -- Water
				{"food6.xml", 1, "Vodka"}, -- Vodka
				{"food7.xml", 5, "Cola"}, -- Cola
				{"food12.xml", 2, "Cereal"}, -- Cereal
				{"food15.xml", 1, "Pita"}, -- Pita
			},
			rare = {
				{"food3.xml", 1, "MRE"}, -- MRE
				{"food5.xml", 2, "Water"}, -- Water
				{"food8.xml", 2, "Orange"}, -- Orange
				{"food13.xml", 2, "BreadBull"}, -- BreadBull
				{"food14.xml", 1, "Ribs"}, -- Ribs
			},
		},
		milFood = { -- military foods
			common = {
				{"food4.xml",  1, "Beans"}, -- beans
				{"food5.xml",  2, "Water"}, -- Water
				{"food9.xml",  1, "Pineapple"}, -- Pineapple
				{"food11.xml", 1, "Spam"}, -- Spam
				{"food10.xml", 1, "Strawberry"}, -- Strawberry
				{"food21.xml", 1, "Peas"}, -- Peas
				{"food22.xml", 1, "Vegetables"}, -- Vegetables
				{"food23.xml", 1, "Olives"}, -- Olives
				{"food24.xml", 1, "Pepin"}, -- Pepin
				{"food25.xml", 1, "Tomatoes"}, -- Tomatoes
				{"food26.xml", 1, "Carrots"}, -- Carrots
				{"food27.xml", 1, "Blueberries"}, -- Blueberries
			},
			uncommon = {
				{"food3.xml", 3, "MRE"}, -- MRE
				{"food5.xml", 4, "Water"}, -- Water
				{"food13.xml", 2, "BreadBull"}, -- BreadBull
				{"food14.xml", 1, "Ribs"}, -- Ribs
			},
			rare = {
				{"food3.xml", 2, "MRE"}, -- MRE
				{"food5.xml", 3, "Water"}, -- water
				{"food6.xml", 1, "Vodka"}, -- Vodka
			},
		},
		medical = {
			common = {
				{"Meds BANDAGE.xml", 3},
				{"Meds AI2.xml", 2},
			},
			uncommon = {
				{"Meds SPLINT.xml", 2},
				{"Meds Car.xml", 1},
				{"Meds CMS.xml", 1},
			},
			rare = {
				{"Meds IFAK.xml", 2},
				{"Meds Grizzly.xml", 1},
				{"Meds Surv12.xml", 2},
			},
		},
		stim = {
			common = {
				{"Meds STIM MORPHINE.xml", 1},
			},
			uncommon = {
				{"Meds STIM ADRENALINE.xml", 1},
			},
			rare = {
				{"Meds STIM PZ1.xml", 1},
			},
		},
		civGeneral = { -- materials, and also gascan
			common = {
				{"Material SCRAP.xml", 1},
				{"Material DRIFTWOOD.xml", 1},
				{"general-lighter.xml", 1},
				{"general-book.xml", 1},
				{"Money #2.xml", 1},
				{"Money #1.xml", 1},
				{"Money #4.xml", 1},
			},
			uncommon = {
				{"Material RUBBER.xml", 1},
				{"Material STEEL.xml", 1},
				{"general-nails.xml", 1},
				{"Money #3.xml", 1},
			},
			rare = {
				{"General GASCAN.xml", 1},
				{"General GASCANLARGE.xml", 1},
				{"general-carbattery.xml", 1},
				{"general-battery.xml", 1},
				{"Weld Fuel.xml", 1},
				{"Money #3.xml", 1},
			},
		},
		banditGeneral = { -- explosive, etc?
			common = {
				{"General GASCAN.xml", 2},
				{"Material SCRAP.xml", 1},
				{"Material DRIFTWOOD.xml", 1},
			},
			uncommon = {
				{"Material RUBBER.xml", 1},
				{"Material STEEL.xml", 1},
				{"General GASCANLARGE.xml", 1},
				{"Material EXPLOSIVE.xml", 1},
				{"Weld Fuel.xml", 1},
				{"general-nails.xml", 1},
			},
			rare = {
				{"Material EXPLOSIVE.xml", 1},
				{"NVG.xml", 1},
			},
		},
		milGeneral = { -- kevlar, nightvision, explosive, etc?
			common = {
				{"General GASCAN.xml", 2},
				{"Material EXPLOSIVE.xml", 1},
				{"general-battery.xml", 1},
				{"general-plate.xml", 1},
			},
			uncommon = {
				{"General GASCANLARGE.xml", 1},
				{"Material KEVLAR.xml", 2},
				{"NFM-Thor.xml", 1},
				{"ULACH.xml", 1},
				{"Weld Fuel.xml", 2},
				{"general-gpu.xml", 1},
				{"general-gasan.xml", 1},
				{"general-plate.xml", 1},
			},
			rare = {
				{"Gzhel.xml", 3},
				{"NVG.xml", 3},
				{"Thermals.xml", 1},
			},
		},
		civWeapon = { -- civilian
			common = {
				{"Ammo 12ga BS.xml", 4},
				{"Gun Qasira.xml", 3},
				{"Gun CZ-1012.xml", 2},
				{"Gun KS23.xml", 2},
				{"Gun KS2 #2.xml", 2}, -- (v2 fix) was "Gun KS23 #2.xml", a file that does not exist
				{"Ammo 4GA BS.xml", 4}, -- (v2 fix) the KS23's 4-gauge ammo was in no loot table
				{"Ammo 7.62x25 FMJ.xml", 5},
				{"Mag TT-33 #0.xml", 3},
				{"Gun TT-33.xml", 3},
				{"Gun TT-33 1.xml", 3},
				{"Gun TT-33 2.xml", 3},
				{"Gun TT-33 3.xml", 3},
				{"Gun TT-33 4.xml", 3},
				{"Gun TT-33 5.xml", 3},
				{"Gun TT-33 6.xml", 3},
				{"Gun TT-33 7.xml", 3},
				{"Gun TT-33 8.xml", 3},
			},
			uncommon = {
				{"Melee FireAxe.xml", 10},

				{"Gun Mudafie.xml", 2},
				{"Gun Mudafie 1.xml", 2},

				{"Mag PPSh #0.xml", 2},
				{"Mag PPSh #1.xml", 1},
				{"Gun PPSH41.xml", 3},
				{"Gun PPSH41 Extended.xml", 2},
				
				{"Ammo 7.62x54R FMJ.xml", 4},
				{"Gun Medvedev.xml", 4},

				{"Ammo 7.62x39 FMJ.xml", 4},
				{"Gun SKS.xml", 5},
				{"Gun SKS PSO.xml", 2},
				{"Gun Simonov-762.xml", 1},
			},
			rare = {
				{"Melee Tomahawk.xml", 5},
				
				{"Grenade.xml", 3},

				{"Gun Medvedev Sniper.xml", 1},
			},
		},
		banditWeapon = { -- insurgents
			common = {
				{"Material EXPLOSIVE.xml", 1},

				{"Ammo 12GA BS.xml", 4},
				{"Gun Mudafie.xml", 2},
				{"Gun Qasira.xml", 3},

				{"Ammo 9x19 FMJ.xml", 4},
				{"Mag P17 9x19 #0.xml", 3},

				{"Ammo 7.62x25 FMJ.xml", 4},
				{"Mag PPSh #0.xml", 3},
				{"Mag PPSh #1.xml", 3},
				{"Gun PPSH41.xml", 2},
				{"Gun PPSH41 Extended.xml", 2},
				{"Mag TT-33 #0.xml", 3},
				{"Gun TT-33.xml", 2},

				{"Ammo 7.62x54R FMJ.xml", 4},
				
				{"Melee CombatKnife.xml", 1},
				{"Grenade.xml", 4},

				{"Ammo 7.62x39 FMJ.xml", 4},
				{"Gun SKS.xml", 6},
				{"Gun Simonov-762.xml", 3},
				{"Gun Simonov-545 TRASH.xml", 1},
				{"Gun TT-33 GREY.xml", 3},
				{"Gun TT-33 GREY 1.xml", 3},
				{"Gun TT-33 GREY 2.xml", 3},
				{"Gun TT-33 GREY 3.xml", 3},
				{"Gun TT-33 GREY 4.xml", 3},
				{"Gun TT-33 GREY 5.xml", 3},
				{"Gun TT-33 GREY 6.xml", 3},
				{"Gun TT-33 GREY 7.xml", 3},
				{"Gun TT-33 GREY 8.xml", 3},
			},
			uncommon = {
				{"Material KEVLAR.xml", .5},

				{"Mag P17 9x19 #1.xml", 2},
				{"Mag P17 9x19 #2.xml", 2},
				{"Gun P17 TAN2.xml", 2},
				{"Gun P17 TAN3.xml", 4},
				{"Gun P17 Green2.xml", 2},
				{"Gun P17 Green3.xml", 4},
				{"Gun P17 Grey2.xml", 2},
				{"Gun P17 Grey3.xml", 4},
				{"Gun P17 2.xml", 2},
				{"Gun P17 3.xml", 4},
				
				{"Ammo 5.45 FMJ.xml", 4},
				{"Mag Simonov 5.45 #0.xml", 2},
				{"Gun Simonov-545.xml", 3},
				{"Gun Simonov-556.xml", 2},
				{"Gun Simonov-545 KOBRA.xml", 1},
				{"Gun Simonov-545 HOLO.xml", 1},
				{"Gun Simonov-545 HOLO2.xml", 1},
				{"Gun Simonov-545U.xml", 1},	
				{"Gun Simonov-556U.xml", 1},
				{"Gun Kovalyov-545.xml", 1},

				{"Ammo 5.56 FMJ.xml", 3},
				{"Gun N16.xml", 2},

				{"Ammo 7.62x39 FMJ.xml", 3},
				{"Mag Simonov 7.62x39 #0.xml", 2},
				{"Gun Simonov-762.xml", 3},
				{"Gun Kovalyov-762.xml", 1},
				{"Gun SKS.xml", 3},
				{"Gun SKS PSO.xml", 3},

				{"Gun Simonov-9.xml", 3},
				{"Gun Simonov-9 MILITARY1.xml", 1},
				{"Mag Simonov-9 #0.xml", 3},
				{"Gun P17.xml", 3},

				{"Ammo 7.62x51 FMJ.xml", 2},
				{"Mag MC308 #0.xml", 2},
				{"Mag MC308 #1.xml", 1},
				{"Mag MC308 #2.xml", 1},
				{"Gun MC308.xml", 2},

				{"Gun MC9.xml", 5},
				{"Mag MC9 #0.xml", 3},

				{"Mag Drozdov #0.xml", 1},
				{"Gun Medvedev Sniper.xml", 2},
				{"Gun Medvedev SNIPER MILITARY.xml", 1},
				{"Gun Drozdov.xml", 1},
				{"Gun Drozdov2.xml", 1},
			},
			rare = {
				{"NFM-Thor.xml", 1},
				{"Gzhel.xml", 1},
				{"SIXB2.xml", 5},
				{"ULACH.xml", 2},
				{"Altyn.xml", 1},
				{"Killa-Vest.xml", 1},

				{"Mag Simonov 5.45 #1.xml", 4},
				{"Mag Simonov 5.45 #2.xml", 3},
				{"Mag Simonov 5.45 #3.xml", 2},
				{"Mag Simonov 5.45 #4.xml", 1},
				{"Gun Simonov-545 MILITARY.xml", 1},
				{"Gun Simonov-106.xml", 3},
				{"Gun Simonov-105.xml", 3},

				{"Gun N16 SCOPE.xml", 2},

				{"Gun MC308 COMPACT1.xml", 1},
				{"Gun MC308 COMPACT2.xml", 1},
				{"Gun MC308 MILITARY1.xml", 1},
				{"Gun MC308 MILITARY2.xml", 1},

				{"Mag Simonov 7.62x39 #1.xml", 3},
				-- {"Gun Simonov-762 MILITARY.xml", 2},
				{"Gun SKS MILITARY.xml", 2},

				{"Gun Drozdov1.xml", 1},
				{"Gun Drozdov SNIPER.xml", 2},
				{"Gun Medvedev SNIPER SUPPRESSED MILITARY.xml", 2},
				{"Gun Medvedev MILITARY #1.xml", 2},
				{"Gun Medvedev MILITARY #2.xml", 2},

				{"Ammo 127x99 FMJ.xml", 2}, -- (v2 fix) was "Ammo .50BMG FMJ.xml" (no such file)
				{"Gun Jalaad.xml", 1},

				{"ROCKET #0.xml", 3},
				{"ROCKET #1.xml", 2},
				{"ROCKET #2.xml", 1},
				{"ROCKET #3.xml", 2},
				{"Gun RPG.xml", 1},

				{"Gun N870.xml", 3},
			},
		},
		milWeapon = { -- military
			common = {
				{"Ammo 5.56 FMJ.xml", 6},
				{"Mag AR 5.56 #0.xml", 2},
				{"Mag Deagle #0.xml", 2},
				{"Mag Simonov 5.45 #0.xml", 2},
				{"Gun N16.xml", 2},
				{"Gun N16 1.xml", 1},
				{"Gun N16 2.xml", 1},
				{"Gun N16 3.xml", 1},
				{"Gun N16 4.xml", 1},
				{"Gun N4A1.xml", 3},

				{"Mag MC308 #0.xml", 3},
				{"Mag MC9 #0.xml", 4},

				{"Ammo 9x19 FMJ.xml", 4},
				{"Mag P17 9x19 #0.xml", 3},
				{"Gun P17.xml", 2},

				{"Meds STIM MORPHINE.xml", 2},

				{"Grenade.xml", 6},

				{"Ammo 12ga BS.xml", 3},
			},
			uncommon = {
				{"Gun Simonov-556.xml", 2},
				{"Ammo 7.62x51 FMJ.xml", 3},
				{"Gun MC308.xml", 6},
				{"Gun MC308 COMPACT1.xml", 1},
				{"Gun MC308 COMPACT2.xml", 1},
				{"Gun MC308 MILITARY1.xml", 2},
				{"Gun MC308 MILITARY2.xml", 2},
				{"Mag MC308 #1.xml", 2},
				{"Mag MC308 #2.xml", 3},
				{"Gun MC9.xml", 5},
				{"Gun Deagle.xml", 5},
				{"Gun Deagle #1.xml", 4},
				{"Gun Deagle #2.xml", 3},
				{"Gun Deagle #3.xml", 2},
				{"Gun Deagle #4.xml", 1},
				{"Gun MC9K.xml", 3},
				{"Gun MC9 MILITARY1.xml", 4},
				{"Gun MC9 MILITARY2.xml", 4},
				{"Mag MC9 #1.xml", 3},
				{"Mag MC9 #2.xml", 2},
				-- (v2 fix 2026-11-12) {"Mag MC9 #3.xml", 2}: no such prefab (nor a Loots/mag3-mp5-9x19.xml) in the original either; the spawner printed "Does not exist" and rerolled
				{"Gun Simonov-9.xml", 1},
				{"Gun Simonov-9 MILITARY1.xml", 2},
				{"Gun Simonov-9 MILITARY2.xml", 2},
				{"Mag Simonov-9 #0.xml", 3},

				{"Mag AR 5.56 #1.xml", 2},
				{"Mag AR 5.56 #2.xml", 3},
				{"Mag AR 5.56 #3.xml", 2},
				{"Mag AR 5.56 #4.xml", 1},
				{"Mag AR 5.56 #5.xml", 1},
				{"Mag AR 5.56 #6.xml", 1},
				{"Mag AR 5.56 #7.xml", 1},
				{"Mag AR 5.56 #8.xml", 1},
				{"Gun N4A1 STANDARD.xml", 3}, -- N4A1 + acog
				{"Gun TCR-556.xml", 3},
				{"Gun TCR-556 MILITARY1.xml", 2},
				{"Gun TCR-556 MILITARY2.xml", 2},
				{"Gun TCR-556 MILITARY1 Grey.xml", 2},
				{"Gun TCR-556 MILITARY2 Grey.xml", 2},
				{"Gun TCR-556 Grey.xml", 3},

				{"Ammo 5.45 FMJ.xml", 3},
				{"Mag Simonov 5.45 #1.xml", 2},
				{"Mag Simonov 5.45 #2.xml", 1},
				{"Mag Simonov 5.45 #3.xml", 2},
				{"Mag Simonov 5.45 #4.xml", 3},
				{"Gun Simonov-106.xml", 3},
				{"Gun Simonov-106 MILITARY1.xml", 1},
				{"Gun Simonov-106 MILITARY2.xml", 1},
				{"Gun Simonov-106 MILITARY3.xml", 1},
				{"Gun Simonov-106 MILITARY4.xml", 1},
				{"Gun Simonov-106 MILITARY5.xml", 2},
				{"Gun Simonov-106 MILITARY6.xml", 2},
				{"Gun Simonov-106 MILITARY7.xml", 1},
				{"Gun Simonov-105.xml", 1},
				{"Gun Simonov-545 MILITARY.xml", 2},
				{"Gun Simonov-556 MILITARY.xml", 3},

				{"Ammo 7.62x39 FMJ.xml", 3},
				{"Mag Simonov 7.62x39 #0.xml", 3},
				{"Mag Simonov 7.62x39 #1.xml", 2},
				{"Mag Simonov 7.62x39 #2.xml", 3},
				{"Gun Simonov-762 MILITARY1.xml", 2},
				{"Gun Simonov-762 MILITARY2.xml", 2},
				
				{"Mag P17 9x19 #1.xml", 2},
				{"Mag P17 9x19 #2.xml", 2},
				{"Gun P17A.xml", 1},
				{"Gun P17 TAN.xml", 1},
				{"Gun P17 TAN1.xml", 1},
				{"Gun P17 1.xml", 1},
				{"Gun P17 TAN2.xml", 1},
				{"Gun P17 Green.xml", 1},
				{"Gun P17 Green1.xml", 1},
				{"Gun P17 Green2.xml", 1},
				{"Gun P17 Grey.xml", 1},
				{"Gun P17 Grey.xml", 1}, -- (v2 fix) was "Gun P17 Grey1.xml" (no such file)
				{"Gun P17 Grey2.xml", 1},
				
				{"Ammo 7.62x54R FMJ.xml", 3},
				{"Gun SV98.xml", 2},
				{"Gun SV98 SNIPER.xml", 3},
				{"Mag SV98 #0.xml", 6},
		
			},
			rare = {
				{"Gun TCR-308.xml", 1},
				{"Gun TCR-308 MILITARY1.xml", 1},
				{"Gun TCR-308 SNIPER.xml", 2},
				{"Gun TCR-308 MILITARY1 Grey.xml", 1},
				{"Gun TCR-308 SNIPER Grey.xml", 2},
				{"Gun TCR-556 Grey.xml", 1},
				{"Gun TCR-308 Grey.xml", 1},

				{"Gun N4A1 SOPMOD.xml", 2}, -- N4A1 + special forces attachments
				{"Gun N4A1 MILITARY1.xml", 2},
				{"Gun N4A1 MILITARY2.xml", 2},

				{"ROCKET #0.xml", 3},
				{"ROCKET #1.xml", 2},
				{"ROCKET #2.xml", 1},
				{"ROCKET #3.xml", 2},
				{"Gun RPG.xml", 1},

				--{"Gun MGL.xml", 1},

				{"NFM-Thor.xml", 4},
				{"ULACH.xml", 6},
				{"Gzhel.xml", 4},

				{"Meds STIM ADRENALINE.xml", 3},
				{"Meds STIM PZ1.xml", 2},

				{"Gun Drozdov MILITARY.xml", 2},
				{"Mag Drozdov #0.xml", 2},
				{"Gun SV98 SNIPER.xml", 3},
				{"Gun N870 MILITARY1.xml", 1},
				{"Gun N870 MILITARY2.xml", 1},
				{"Gun N870 MILITARY3.xml", 1},
				{"Gun N870.xml", 3},
			},
		},
		UMWeapon = { -- UM
			common = {
				{"Ammo 5.56 FMJ.xml", 6},
				{"Mag AR 5.56 #0.xml", 2},
				{"Mag MK 5.56 #0.xml", 3},
				{"Gun N16.xml", 3},
				{"Gun N4A1.xml", 3},

				{"Ammo 9x19 FMJ.xml", 4},
				{"Mag P17 9x19 #0.xml", 3},
				{"Gun P17.xml", 2},

				{"Ammo 5.7x28 HP.xml", 3},
				{"Gun TCP-57.xml", 2},
				{"Gun TCP-57 GREY.xml", 2},
				{"Meds STIM MORPHINE.xml", 3},

				{"Grenade.xml", 4},
			},
			uncommon = {
				{"Mag AR 5.56 #1.xml", 1},
				{"Mag AR 5.56 #2.xml", 2},
				{"Mag AR 5.56 #3.xml", 2},
				{"Mag AR 5.56 #4.xml", 1},
				{"Mag AR 5.56 #5.xml", 1},
				{"Mag AR 5.56 #6.xml", 2},
				{"Mag AR 5.56 #7.xml", 1},
				{"Mag AR 5.56 #8.xml", 1},
				{"Gun N4A1 STANDARD.xml", 2}, -- N4A1 + acog
				{"Gun TCR-556.xml", 2},
				{"Gun TCR-556 MILITARY1.xml", 1},
				{"Gun TCR-556 MILITARY2.xml", 1},
				{"Gun MK36.xml", 3},
				{"Gun MK36 MILITARY1.xml", 2},
				{"Gun MK36 MILITARY2.xml", 2},
				{"Gun MK36C.xml", 3},
				{"Gun MK36C MILITARY1.xml", 2},
				{"Gun MK36C MILITARY2.xml", 2},
				
				{"Mag P17 9x19 #1.xml", 2},
				{"Mag P17 9x19 #2.xml", 2},
			
				{"Gun Deagle.xml", 5},
				{"Gun Deagle #1.xml", 4},
				{"Gun Deagle #2.xml", 3},
				{"Gun Deagle #3.xml", 2},
				{"Gun Deagle #4.xml", 1},
				
				{"Gun P17A.xml", 1},
				{"Gun P17A 1.xml", 1},
				{"Gun P17A 2.xml", 1},
				{"Gun P17A 3.xml", 1},
				
				{"Gun P17A Grey.xml", 1},
				{"Gun P17A Grey1.xml", 1},
				{"Gun P17A Grey2.xml", 1},
				{"Gun P17A Grey3.xml", 1},
				
				{"Gun P17A TAN.xml", 1},
				{"Gun P17A TAN1.xml", 1},
				{"Gun P17A TAN2.xml", 1},
				{"Gun P17A TAN3.xml", 1},
				
				{"Gun P17A Green.xml", 1},
				{"Gun P17A Green1.xml", 1},
				{"Gun P17A Green2.xml", 1},
				{"Gun P17A Green3.xml", 1},
				
				{"Gun SCALAR.xml", 3},

				{"Gun TMP-90.xml", 2},
				{"Gun TMP-90 MILITARY1.xml", 2},
				{"Gun TMP-90 MILITARY2.xml", 1},
				{"Gun TMP-90 MILITARY3.xml", 1},
				
				{"Gun N870.xml", 3},
				{"Gun N870 MILITARY1.xml", 1},
				{"Gun N870 MILITARY2.xml", 1},
				{"Gun N870 MILITARY3.xml", 1},
			},
			rare = {
				{"Ammo 127x99 FMJ.xml", 2}, -- (v2 fix) was "Ammo .50BMG FMJ.xml" (no such file)
				{"Gun N107.xml", 1},
				{"Gun N107 MILITARY1.xml", 2},
				{"Gun N107 MILITARY2.xml", 2},
				{"Gun N107 MILITARY3.xml", 2},
				{"Gun N107 MILITARY4.xml", 2},
				{"Gun N107 MILITARY5.xml", 2},
				{"Mag N107 #0.xml", 2},
				{"Gun TCR-308.xml", 1},
				{"Gun TCR-308 MILITARY1.xml", 2},
				{"Gun TCR-308 SNIPER.xml", 4},

				{"Gun N4A1 SOPMOD.xml", 4}, -- N4A1 + special forces attachments

				{"ROCKET #0.xml", 2},
				{"ROCKET #1.xml", 2},
				{"ROCKET #2.xml", 2},
				{"Gun RPG.xml", 1},

				--{"Gun MGL.xml", 1},

				{"Zabralo.xml", 2},
				{"Thor.xml", 2},
				{"HexGrid.xml", 4},
				{"ULACH.xml", 6},
				{"LBT-Plate.xml", 5},
				{"Gzhel.xml", 2},

				{"Meds STIM ADRENALINE.xml", 3},
				{"Meds STIM PZ1.xml", 2},
			},
		},
		Spawn = { -- Spawn Loot
			common = {---------------------------------------------------		
				{{							-- AR Mags	
					{"Mag AR 5.56 #1.xml", 1},
					{"Mag AR 5.56 #2.xml", 1},
					{"Mag AR 5.56 #3.xml", 1},
					{"Mag AR 5.56 #4.xml", 1},
					{"Mag AR 5.56 #5.xml", 1},
					{"Mag AR 5.56 #6.xml", 1},
					{"Mag AR 5.56 #7.xml", 1},
					{"Mag AR 5.56 #8.xml", 1},
				}, 3},
				---------------------------------------------------	
				{{							-- SV98 Mags		
					{"Mag SV98 #0.xml", 1},
				}, 3},
				---------------------------------------------------				
				{{							-- SCAR-H Mags		
					{"Mag TCR 7.62 #0.xml", 1},
					{"Mag TCR 7.62 #2.xml", 1},
				}, 3},
				---------------------------------------------------						
				{{							-- GLOCK Mags		
					{"Mag P17 9x19 #0.xml", 1},
					{"Mag P17 9x19 #1.xml", 1},
					{"Mag P17 9x19 #2.xml", 1},
				}, 3},
				---------------------------------------------------									
				{{							-- H&K Mags		
					{"Mag MK 5.56 #0.xml", 1},
				}, 3},
				---------------------------------------------------										
				{{							-- P90 Mags		
					{"Mag TMP90 #0.xml", 1},
				}, 3},
				---------------------------------------------------			
				{{							-- Ammos				
					{"Ammo 5.56 FMJ.xml", 1},
					{"Ammo 9x19 FMJ.xml", 1},
					{"Ammo 12GA S.xml", 1},
					{"Ammo 5.7x28 HP.xml", 1},
				}, 3},
				---------------------------------------------------					
				{{							-- Stims				
					{"Meds STIM MORPHINE.xml", 1},
					{"Meds STIM ADRENALINE.xml", 1},
					{"Meds STIM PZ1.xml", 1},
				}, 3},
				---------------------------------------------------								
				{{							-- Misc				
					{"Grenade.xml", 1},
					{"general-plate.xml", 1},
					{"General GASCAN.xml", 1},
					{"General GASCANLARGE.xml", 1},
					{"general-battery.xml", 1},
				}, 3},
				---------------------------------------------------			

			},
			uncommon = {---------------------------------------------------			
				{{							-- M870 Guns			
					{"Gun N870.xml", 3},
					{"Gun N870 MILITARY1.xml", 1},
					{"Gun N870 MILITARY2.xml", 1},
					{"Gun N870 MILITARY3.xml", 1},
				}, 2},
				---------------------------------------------------	
				{{							-- G18 Guns			
					{"Gun P17A.xml", 1},
					{"Gun P17A 1.xml", 1},
					{"Gun P17A 2.xml", 1},
					{"Gun P17A 3.xml", 1},
					--------------------
					{"Gun P17A Grey.xml", 1},
					{"Gun P17A Grey1.xml", 1},
					{"Gun P17A Grey2.xml", 1},
					{"Gun P17A Grey3.xml", 1},
					--------------------
					{"Gun P17A TAN.xml", 1},
					{"Gun P17A TAN1.xml", 1},
					{"Gun P17A TAN2.xml", 1},
					{"Gun P17A TAN3.xml", 1},
					--------------------
					{"Gun P17A Green.xml", 1},
					{"Gun P17A Green1.xml", 1},
					{"Gun P17A Green2.xml", 1},
					{"Gun P17A Green3.xml", 1},
				}, 2},
				---------------------------------------------------			
				{{							-- G17 Guns			
					{"Gun P17.xml", 1},
					{"Gun P17 1.xml", 1},
					{"Gun P17 2.xml", 1},
					{"Gun P17 3.xml", 1},
					--------------------
					{"Gun P17 Grey.xml", 1},
					{"Gun P17 Grey.xml", 1}, -- (v2 fix) was "Gun P17 Grey1.xml" (no such file)
					{"Gun P17 Grey2.xml", 1},
					{"Gun P17 Grey3.xml", 1},
					--------------------
					{"Gun P17 TAN.xml", 1},
					{"Gun P17 TAN1.xml", 1},
					{"Gun P17 TAN2.xml", 1},
					{"Gun P17 TAN3.xml", 1},
					--------------------
					{"Gun P17 Green.xml", 1},
					{"Gun P17 Green1.xml", 1},
					{"Gun P17 Green2.xml", 1},
					{"Gun P17 Green3.xml", 1},
				}, 2},
				---------------------------------------------------				
				{{							-- Armors		
					{"ULACH.xml", 1},
					{"LBT-Plate.xml", 1},
					{"Gzhel.xml", 1},

				}, 2},
				---------------------------------------------------											
			},
			rare = {---------------------------------------------------		
				{{							-- P90 Guns			
					{"Gun TMP-90.xml", 3},
					{"Gun TMP-90 MILITARY1.xml", 1},
					{"Gun TMP-90 MILITARY2.xml", 1},
					{"Gun TMP-90 MILITARY3.xml", 1},
				}, 1},
				---------------------------------------------------						
				{{							-- M4A1 Guns			
					{"Gun N4A1 SOPMOD.xml", 1},
					{"Gun N4A1 MILITARY1.xml", 1},
					{"Gun N4A1 MILITARY2.xml", 1},
					{"Gun N4A1 STANDARD.xml", 1},
				}, 1},
				---------------------------------------------------									
				{{							-- M16 Guns			
					{"Gun N16", 1},
					{"Gun N16 1", 1},
					{"Gun N16 2", 1},
					{"Gun N16 3", 1},
					{"Gun N16 4", 1},
					{"Gun N16 Scope", 1},
					
				}, 1},
				---------------------------------------------------						
				{{							-- G36 Guns			
					{"Gun MK36.xml", 1},
					{"Gun MK36 MILITARY1.xml", 1},
					{"Gun MK36 MILITARY2.xml", 1},
					{"Gun MK36C.xml", 1},
					{"Gun MK36C MILITARY1.xml", 1},
					{"Gun MK36C MILITARY2.xml", 1},
				}, 1},
				---------------------------------------------------										
				{{							-- VECTOR Guns			
					{"Gun SCALAR.xml", 1},
					{"Gun SCALAR MILITARY1.xml", 1},
					{"Gun SCALAR MILITARY2.xml", 1},
					{"Gun SCALAR MILITARY3.xml", 1},
					{"Gun SCALAR MILITARY4.xml", 1},
					{"Gun SCALAR MILITARY5.xml", 1},
				}, 1},
				---------------------------------------------------												
				{{							-- SCAR-L Guns			
					{"Gun TCR-556.xml", 1},
					{"Gun TCR-556 MILITARY1.xml", 1},
					{"Gun TCR-556 MILITARY2.xml", 1},
					{"Gun TCR-556 MILITARY1 Grey.xml", 1},
					{"Gun TCR-556 MILITARY2 Grey.xml", 1},
					{"Gun TCR-556 Grey.xml", 1},
				}, 1},
				---------------------------------------------------																
				{{							-- SCAR-H Guns			
					{"Gun TCR-308.xml", 1},
					{"Gun TCR-308 MILITARY1.xml", 1},
					{"Gun TCR-308 SNIPER.xml", 1},
					{"Gun TCR-308 MILITARY1 Grey.xml", 1},
					{"Gun TCR-308 SNIPER Grey.xml", 1},
					{"Gun TCR-308 Grey.xml", 1},
				}, 1},																
				---------------------------------------------------			
				{{							-- SV98 Guns			
					{"Gun SV98.xml", 1},
					{"Gun TCR-308 MILITARY1.xml", 1},
				}, 1},
				---------------------------------------------------				
			},
		},
		debugTest = { -- (v2) spawn-menu-only category for testing; no location uses type=debugTest
			common = {
				{"Gun PKM.xml", 1},
				{"Gun Bauer-553.xml", 1},
				{"Gun M9.xml", 1},
				{"Melee BaseballBat.xml", 1},
				{"Grenade Type-67.xml", 1},
				{"PVS-14.xml", 1},
				{"PNV-10T.xml", 1},
				{"Melee Crowbar.xml", 1},
				{"Melee DamnedScythe.xml", 1},
				{"Melee Katana.xml", 1},
				{"Melee Pipe.xml", 1},
				{"Ammo 127x33 HP.xml", 1},
				{"Ammo 127x99 AP.xml", 1},
				{"Ammo 127x99 APE.xml", 1},
				{"Ammo 127x99 API.xml", 1},
				{"Ammo 127x99 T.xml", 1},
				{"Ammo 12GA APS.xml", 1},
				{"Ammo 12GA BKS.xml", 1},
				{"Ammo 12GA DB.xml", 1},
				{"Ammo 12GA F.xml", 1},
				{"Ammo 12GA S.xml", 1},
				{"Ammo 4GA APS.xml", 1},
				{"Ammo 4GA BKS.xml", 1},
				{"Ammo 4GA S.xml", 1},
				{"Ammo 5.45 AP.xml", 1},
				{"Ammo 5.45 APE.xml", 1},
				{"Ammo 5.45 HP.xml", 1},
				{"Ammo 5.45 T.xml", 1},
				{"Ammo 5.56 AP.xml", 1},
				{"Ammo 5.56 APE.xml", 1},
				{"Ammo 5.56 HP.xml", 1},
				{"Ammo 5.56 T.xml", 1},
				{"Ammo 5.7x28 AP.xml", 1},
				{"Ammo 5.7x28 APE.xml", 1},
				{"Ammo 5.7x28 FMJ.xml", 1},
				{"Ammo 5.7x28 T.xml", 1},
				{"Ammo 7.62x25 AP.xml", 1},
				{"Ammo 7.62x25 APE.xml", 1},
				{"Ammo 7.62x25 HP.xml", 1},
				{"Ammo 7.62x25 T.xml", 1},
				{"Ammo 7.62x39 AP.xml", 1},
				{"Ammo 7.62x39 APE.xml", 1},
				{"Ammo 7.62x39 HP.xml", 1},
				{"Ammo 7.62x39 T.xml", 1},
				{"Ammo 7.62x51 AP.xml", 1},
				{"Ammo 7.62x51 APE.xml", 1},
				{"Ammo 7.62x51 HP.xml", 1},
				{"Ammo 7.62x51 T.xml", 1},
				{"Ammo 7.62x54R AP.xml", 1},
				{"Ammo 7.62x54R APE.xml", 1},
				{"Ammo 7.62x54R HP.xml", 1},
				{"Ammo 7.62x54R T.xml", 1},
				{"Ammo 9x19 AP.xml", 1},
				{"Ammo 9x19 APE.xml", 1},
				{"Ammo 9x19 HP.xml", 1},
				{"Ammo 9x19 T.xml", 1},
				{"Mag Simonov 5.56 #0.xml", 1},
				{"Mag TCP-57 #0.xml", 1},
				{"Mag TCR 7.62 #0.xml", 1},
				{"Mag TCR 7.62 #2.xml", 1},
				{"Mag TMP90 #0.xml", 1},
			},
		},
		eggWeapon = {
			common = {
				{"Gun Autumnatic's Mudafie.xml", 1},	
				{"Gun Avertnus's Simonov-545.xml", 1},
				{"Gun Offensive's N4A1.xml", 1},
				{"Gun Cheejin's N870.xml", 1},
				{"Gun Snakey's TCR-308.xml", 1},
				{"Gun Tess's Drozdov.xml", 1},
			},
			uncommon = {
				{"Gun Autumnatic's Mudafie.xml", 1},	
				{"Gun Avertnus's Simonov-545.xml", 1},
				{"Gun Offensive's N4A1.xml", 1},
				{"Gun Cheejin's N870.xml", 1},
				{"Gun Snakey's TCR-308.xml", 1},
				{"Gun Tess's Drozdov.xml", 1},
			},
			rare = {
				{"Gun Autumnatic's Mudafie.xml", 1},	
				{"Gun Avertnus's Simonov-545.xml", 1},
				{"Gun Offensive's N4A1.xml", 1},
				{"Gun Cheejin's N870.xml", 1},
				{"Gun Snakey's TCR-308.xml", 1},
				{"Gun Tess's Drozdov.xml", 1},
			},
		},
	},
	
	lores = {
		["PZ-1"] = { ordered = true,
			{
				{ID = "classfied", file = "pz_1_1_cl.xml", weight = 1},
				{ID = "declassfied", file = "pz_1_1_de.xml", weight = 1},
			},
			{
				{ID = "classfied", file = "", weight = 1},
				{ID = "declassfied", file = "", weight = 1},
			},
			{
				{ID = "classfied", file = "", weight = 1},
				{ID = "declassfied", file = "", weight = 1},
			},
			{
				{ID = "classfied", file = "", weight = 1},
				{ID = "declassfied", file = "", weight = 1},
			},
			{
				{ID = "classfied", file = "", weight = 1},
				{ID = "declassfied", file = "", weight = 1},
			},
		},
	},
}

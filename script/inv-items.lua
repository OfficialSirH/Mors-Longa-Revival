ITEMS={
	gun={
		_default = {
			displayName = "Unknown weapon",
			description = {
				"Unknown weapon.",
				"UNKNOWNITEMID",
				"GUNFEED",
			},
		},
		--gun-ak12
		["gun-ak50"] = {
			displayName = "Jalaad",
			description = {
				"The Jalaad is the work of a mysterious man only known by the alias \"AK Jesus\".",
				"GUNFEED",
				"Caliber: .50BMG Ammo",
				"Feed: N107 magazines",
			},
			dimension = {7,2},
			pickSound = "MOD/snd/Foley/pickup/weap_pickup_rattle_0.ogg",
			dropSound = "MOD/snd/Foley/drop/weap_drop_sniper_sand_0.ogg",
			equipSound = "MOD/snd/Weapons/Shared/Deploy/weapon_equip_0.ogg",
		},
		["gun-ak74"] = {
			displayName = "Simonov-545",
			description = {
				"The Simonov-545 is a magazine-fed assault rifle capable of engaging moderate body armor.",
				"GUNFEED",
				"Caliber: 5.45 Ammo",
				"Feed: 5.45 Simonov magazines",
			},
		},
		["gun-ak74m"] = {
			displayName = "Simonov-106",
			description = {
				"The Simonov-106 is a modernised version of the Simonov-545 which utilises light-weight material in the handguard, stock and gas piston to improve handling and reduce recoil.",
				"GUNFEED",
				"Caliber: 5.45 Ammo",
				"Feed: 5.45 Simonov magazines",
			}
		},
		["gun-akm"] = {
			displayName = "Simonov-762",
			description = {
				"The Simonov-762 is a magazine-fed assault rifle. It has high stopping power, but lacks in armor penetration.",
				"GUNFEED",
				"Caliber: 7.62x39 Ammo",
				"Feed: 7.62x39 Simonov magazines",
			}
		},
		["gun-ar15"] = {
			displayName = "N4A1",
			description = {
				"The N4A1 is a magazine-fed assault rifle capable of engaging moderate body armor.",
				"GUNFEED",
				"Caliber: 5.56 Ammo",
				"Feed: AR magazines",
			}
		},
		["gun-cz1012"] = {
			"The CZ-1012 is a single-shot break action hunting shotgun, great for unarmed targets but not so much for armored ones.",
			"GUNFEED",
			"Caliber: 12 gauge Ammo",
			"Feed: Break action",
		},
		["gun-g17"] = {
			"The P17 is a semi automatic pistol that deals small ammount of damage towards armored targets.",
			"GUNFEED",
			"Caliber: 9x19 Ammo",
			"Feed: P17 magazines",
		},
		["gun-g18"] = {
			"The P17A is a fully automatic pistol that is suited for flesh damage rather than armored targets.",
			"GUNFEED",
			"Caliber: 9x19 Ammo",
			"Feed: P17 magazines",
		},
		["gun-g3"] = {
			"The MC308 is a magazine-fed battle rifle capable of delivering high energy to a target as well as penetrating strong body armor.",
			"GUNFEED",
			"Caliber: 7.62x51 Ammo",
			"Feed: MC308 magazines",
		},
		["gun-g36k"] = {
			"The MK36 is a magazine-fed assault rifle made by Germany. It is capable of engaging moderate body armor.",
			"GUNFEED",
			"Caliber: 5.56 Ammo",
			"Feed: MK magazines",
		},
		["gun-m16"] = {
			"The N16 is a magazine-fed assault rifle that features burst fire and semi-auto. It is capable of engaging moderate body armor.",
			"GUNFEED",
			"Caliber: 5.56 Ammo",
			"Feed: AR magazines",
		},
		["gun-m870"] = {
			"The N870 is a pump action shotgun with an internal magazine-tube that holds 8 rounds. It's higher capacity makes it more suitable for unpredictable CQB engagements.",
			"GUNFEED",
			"Caliber: 12ga Ammo",
			"Feed: Internal",
		},
		["gun-m107"] = {
			"The N107 is a magazine-fed semi-automatic anti-materiel rifle capable of incredible damage against armored and unarmored targets.",
			"GUNFEED",
			"Caliber: .50BMG Ammo",
			"Feed: N107 magazines",
		},
		["gun-mgl"] = {
			"The MGL can rapid fires grenades to quickly blow your enemy or structures up to the sky, except its broken, just unload it and throw it away.",
			"GUNFEED",
			"Caliber: 7.62x39 Ammo undercovers as 40mm grenades (load it into a mag to blow its cover)",
			"Feed: Internal cylinder",
		},
		["gun-mosin"] = {
			"The Medvedev is a bolt-action rifle made by Russia. It has served as a devastating infantry rifle since the late 1800s, and will still pack a punch against strong body armor.",
			"GUNFEED",
			"Caliber: 7.62x54R Ammo",
			"Feed: Internal magazine",
		},
		["gun-mp43"] = {
			"The Mudafie is a break-action double-barreled shotgun that is highly effective toward flesh target, but fails in the face of armor.",
			"GUNFEED",
			"Caliber: 12ga Ammo",
			"Feed: Break action",
		},
		["gun-mp5"] = {
			"The MC9 is a magazine-fed sub machinegun that has low armor penetration and a decent rate of fire. It's redeeming quality is the reload animation.",
			"GUNFEED",
			"Caliber: 9x19 Ammo",
			"Feed: MC9 magazines",
		},
		["gun-ppsh41"] = {
			"The PPSh-41 is a select-fire sub-machine gun that deals small ammount of damage towards armored targets, but fires incredibly fast at 1200rpm.",
			"GUNFEED",
			"Caliber: 7.62x25 Ammo",
			"Feed: PPSh magazines",
		},
		["gun-rpg"] = {
			"The RPG is a rocket launcher which specialises in armor penetration. It will send a jet of shrapnel through any surface it hits - perfect for enemies who are feeling shy.",
			"GUNFEED",
			"Caliber: Rockets",
		},
		--[[ ["gun-rpk"] = {
			"The Kovalyov-762 is a light squad weapon based on the Simonov-762. It features an extended barrel, reinforced stock and bipod to pack a bit more of a punch overall.",
			"GUNFEED",
		},
		["gun-rpk74"] = {
			"The Kovalyov-545 is a light squad weapon based on the Simonov-545. It features an extended barrel, reinforced stock and bipod to pack a bit more of a punch overall.",
			"GUNFEED",
		}, ]] -- they dont exist
		["gun-sawedoff"] = {
			"The Qasira is a sawed-off double-barrel shotgun. Looks like someone had a saw, a Mudafie and a dream.",
			"GUNFEED",
		},
		["gun-scarh"] = {
			"The TCR-308 is a magazine fed battle rifle that utilises a high velocity and high damage caliber to deal damage to armored targets.",
			"GUNFEED",
			"Caliber: 7.62x51 Ammo",
			"Feed: TCR magazines",
		},
		["gun-scarl"] = {
			"The TCR-556 is an AR-platform assault rifle which capable of moderate armor penetration.",
			"GUNFEED",
			"Caliber: 5.56 Ammo",
			"Feed: AR magazines",
		},
		["gun-sg553"] = {
			"Bauer-553 [TODO] Placeholder",
			"GUNFEED",
		},
		["gun-sg556"] = {
			"Bauer-556 [TODO] Placeholder",
			"GUNFEED",
		},
		["gun-sks"]	= {
			"The SKS is a semi automatic carbine with an internal magazine. It has high stopping power, but lacks in armor penetration.",
			"GUNFEED",
			"Caliber: 7.62x39 Ammo",
			"Feed: Internal magazine",
		},
		["gun-svd"] = {
			"The Drozdov is a deadly marksman rifle that can be used to pick off armored targets from out of their range.",
			"GUNFEED",
			"Caliber: 7.62x54R Ammo",
			"Feed: Drozdov magazines",
		},
		["gun-tt33"] = {
			"The TT-33 is a hammer-fired semi-automatic pistol. It has a low capacity, but better armor penetration than its 9mm counterparts.",
			"GUNFEED",
			"Caliber: 7.62x25 Ammo",
			"Feed: TT-33 magazines",
		},
		["gun-vector"] = {
			"The Scalar is a sub machinegun with a ludicrously high rate of fire and minimal recoil that make up for its lackluster armor penetration.",
			"GUNFEED",
			"Caliber: 9x19 Ammo",
			"Feed: P17 magazines",
		},
	},
	food={default_DESC = {"Unknown food.", "UNKNOWNITEMID", "FOODHUNGERTHIRST"},
		["food1"]={
			"Can of Tuna, smells like rotten fish.",
			"FOODHUNGERTHIRST",
		},
		["food2"]={
			"Disgustling melted Choccolete.",
			"FOODHUNGERTHIRST",
		},
		["food3"]={
			"Meal, Ready-to-Eat, but somehow not quite. Whatever was inside all dried like solid rock.",
			"FOODHUNGERTHIRST",
		},
		["food4"]={
			"Can of old Beans, probably been here since the start of time.",
			"FOODHUNGERTHIRST",
		},
		["food5"]={
			"Bottle of Water, Standard drainage taste, with a bit of plastic flavour.",
			"FOODHUNGERTHIRST",
		},
		["food6"]={
			"Bottle of vodka, otherwise known as Latvian water.",
			"Numbs pain",
			"Forget for how long",
			"FOODHUNGERTHIRST",
		},
		["food7"]={
			"COKE COLA ESPUMA! (throws) (disapointment)",
			"FOODHUNGERTHIRST",
		},
		["food8"]={
			"Jug of orange juice with too much sugar.",
			"FOODHUNGERTHIRST",
		},
		["food9"]={
			"A can of sliced pineapple, it says. It should be bad by now, yet this is still \"fresh\".",
			"FOODHUNGERTHIRST",
		},
		["food10"]={
			"Does this food exist? Please send in our discord if this food does exist.",
			"FOODHUNGERTHIRST",
		},
		["food11"]={
			"Spam, loved by many, but annoying to get in your inbox.",
			"FOODHUNGERTHIRST",
		},
		["food12"]={
			"Big box of cereal. Lasts a long time, but a bad idea to eat it dry.",
			"FOODHUNGERTHIRST",
		},
		["food13"]={
			"BreadBull energy drink. It says it gives you energy, and also aerodynamic capabilites... maybe false advertisement.",
			"Runs faster",
			"Forget for how long",
			"FOODHUNGERTHIRST",
		},
		["food14"]={
			"Cooked ribs, food that existed since the day humans learns how to use fire, still somehow overcooked it after hundreds of thousands of years of experience.",
			"FOODHUNGERTHIRST",
		},
		["food15"]={
			"Pita Bread, best kind of bread in the world, no bias 100% real comment.",
			"FOODHUNGERTHIRST",
		},
	},
	material={default_DESC = {"Unknown material.", "UNKNOWNITEMID", "MATERIALSTACK"},
		["material-driftwood"]={
			"MATERIALSTACK",
			"Random piece of scrap wood, look like it have been broken down by years of water damage, except you are in the middle of a desert.",
		},
		["material-scrap"]={
			"MATERIALSTACK",
			"A pile of scrap metal, it will make the classical clonk sound in your backpack telling everyone that you are THE trash scavanger.",
		},
		["material-rubber"]={
			"MATERIALSTACK",
			"Rubber recycled from old tires and funny toys and scraps, some still have blood stains or burns, try not to became one of them.",
		},
		["material-steel"]={
			"MATERIALSTACK",
			"Stainless Steel, if it sounds good when you hit them, then its good steel. Ignore the rusts on it, of course.",
		},
		["material-explosive"]={
			"MATERIALSTACK",
			"Military grade explosive, it will give you a very memorable time if you do not handle it with care.",
		},
		["material-kevlar"]={
			"MATERIALSTACK",
			"High-quality bulletproof woven material. If it can protect the invasive western soilders then it can protect you. Patch up your armor by applying it while it's in the backpack.",
		},
	},
	meds={default_DESC = {"Unknown meds.", "UNKNOWNITEMID"},
		["meds-bleed-bandage"]={
			"Medical Bandage, still pretty clean.",
			"Stops bleeding.",
			"Use time: 4 seconds.",
			"1 Time Use Only",
		},
		["meds-fracture-splint"]={
			"Basic Splint, Just pretend that it is your bone replacement.",
			"Heals fractures.",
			"Use time: 4 seconds.",
			"1 Time Use Only",
		},
		["meds-surgery-cms"]={
			"Emergency surgical kit - heals body parts from 0HP.",
			"Revives dead body part",
			"Use time: 10 seconds.",
			"5 Times Use",
		},
		["meds-bleed-general-ifak"]={
			"Military grade first aid kit.",
			"Heals bodypart HP as well as bleeds.",
			"Use time: 1-5 seconds.",
			"300 HP in total",
		},
		["meds-general-ai2"]={
			"An old medical kit.",
			"Heals bodypart HP.",
			"Use time: 1-5 seconds.",
			"100 HP in total",
		},
		["meds-bleed-general-car"]={
			"A standard civilian medical kit.",
			"Heals bodypart HP as well as bleeds.",
			"Use time: 1-5 seconds.",
			"220 HP in total",
		},
		["meds-bleed-fracture-general-grizzly"]={
			"A huge travel med-kit containing almost everything you'll need to patch yourself up.",
			"Heals bodypart HP, bleeds and fractures.",
			"Use time: 1-5 seconds.",
			"1200 HP in total",
		},
		["meds-fracture-surgery-surv12"]={
			"An advanced survival surgery kit.",
			"Emergency surgical kit - heals body parts from 0HP and treats fractures.",
			"Use time: 2-10 seconds.",
			"12 Times Use",
		},
		["meds-stim-morphine"]={
			"Morphine",
			"Numbs pain",
			"60 Second Duration",
		},
		["meds-stim-adrenaline"]={
			"Adrenaline",
			"Numbs pain",
			"Heal bodypart",
			"Able to move faster",
			"Reload Faster",
			"15 Second Duration",
		},
		["meds-stim-pz1"]={
			"PZ-1",
			"Numbs pain",
			"Able to move faster",
			"Extream resistance",
			"Reload Faster",
			"30 Second Duration",
		},

	},
	vest={default_DESC = {"Unknown armor vest.", "UNKNOWNITEMID", "LEVEL", "DURRABILITY"},
		["vest-gzhel"]={
			"The Gzhel is a strong armor vest that protects the torso.",
			"LVL5",
			"DURRABILITY",
		},
		["vest-hexgrid"]={
			"The Hexgrid is a strong armor vest that protects the torso.",
			"LVL5",
			"DURRABILITY",
		},
		["vest-killa"]={
			"The Killa is a moderate armor vest that protects the torso.",
			"LVL3",
			"DURRABILITY",
		},
		["vest-lbtplate"]={
			"The LBT Plate (Slick) is a strong armor vest that protects the torso.",
			"LVL4",
			"DURRABILITY",
		},
		["vest-nfmthor"]={
			"The NFM-Thor is a strong armor vest that protects the torso.",
			"LVL4",
			"DURRABILITY",
		},
		["vest-sixb2"]={
			"The 6B2 is a weak flak vest that protects the torso.",
			"LVL2",
			"DURRABILITY",
		},
		["vest-thor"]={
			"The Thor is a strong armor vest that protects the torso and arms.",
			"LVL4",
			"DURRABILITY",
		},
		["vest-zabralo"]={
			"The Zabralo is a strong armor vest that protects the torso and arms.",
			"LVL5",
			"DURRABILITY",
		},
	},
	helmet={default_DESC = {"Unknown helmet.", "UNKNOWNITEMID", "LEVEL", "DURRABILITY"},
		["helmet-altyn"]={
			"The Altyn is a heavily armored Russian helmet that can deflect rifle rounds and entirely stop pistol rounds.",
			"LVL4",
			"DURRABILITY",
		},
		["helmet-ulach"]={
			"The ULACH is an anti-shrapnel helmet that is not rated for stopping bullets. However, it can deflect pistol rounds.",
			"LVL2",
			"DURRABILITY",
		}
	},
	eyewear={default_DESC = {"Unknown eyewear.", "UNKNOWNITEMID", "DURRABILITY"},
		["nvg"]={
			"Military grade night visior, almost as if the sky suddenly turns green.",
			"Press N to use.",
			"DURRABILITY",
		},
		["thermals"]={
			"Military grade thermal visor, highlights warm enemies in white.",
			"Press N to use.",
			"DURRABILITY",
		},
	},
	mag={default_DESC = {"Unknown magazine.", "UNKNOWNITEMID", "AMMOCOUNT"},
		["mag0-ak-545"]={
			"Standard 5.45 Simonov magazine, fits 30 rounds of 5.45 ammo.",
			"AMMOCOUNT",
		},
		["mag1-ak-545"]={
			"Extended 5.45 Simonov magazine, fits 45 rounds of 5.45 ammo.",
			"AMMOCOUNT",
		},
		["mag2-ak-545"]={
			"Large 5.45 Simonov Single Drum magazine, fits 77 rounds of 5.45 ammo.",
			"AMMOCOUNT",
		},
		["mag3-ak-545"]={
			"Large 5.45 Simonov Dual Drum magazine, fits 95 rounds of 5.45 ammo.",
			"AMMOCOUNT",
		},
		["mag4-ak-545"]={
			"Expanded 5.45 Simonov magazine, fits 60 rounds of 5.45 ammo.",
			"AMMOCOUNT",
		},

		["mag0-ak-762x39"]={
			"Standard 7.62 Simonov magazine, fits 30 rounds of 7.62x39 ammo.",
			"AMMOCOUNT",
		},
		["mag1-ak-762x39"]={
			"Extended 7.62 Simonov magazine, fits 40 rounds of 7.62x39 ammo.",
			"AMMOCOUNT",
		},
		["mag2-ak-762x39"]={
			"7.62 Simonov drum, fits 50 rounds of 7.62x39 ammo.",
			"AMMOCOUNT",
		},

		["mag0-ar-556"]={
			"Standard NATO AR magazine, fits 30 rounds of 5.56 ammo.",
			"AMMOCOUNT",
		},
		["mag1-ar-556"]={
			"Extended NATO AR magazine, fits 40 rounds of 5.56 ammo.",
			"AMMOCOUNT",
		},
		["mag2-ar-556"]={
			"Large NATO AR Single Drum magazine, fits 60 rounds of 5.56 ammo.",
			"AMMOCOUNT",
		},
		["mag3-ar-556"]={
			"Large NATO AR Dual Drum magazine, fits 100 rounds of 5.56 ammo.",
			"AMMOCOUNT",
		},
		["mag4-ar-556"]={
			"Short NATO AR magazine, fits 20 rounds of 5.56 ammo.",
			"AMMOCOUNT",
		},
		["mag5-ar-556"]={
			"Expanded NATO AR magazine, fits 60 rounds of 5.56 ammo.",
			"AMMOCOUNT",
		},

		["mag0-hk-556"]={
			"Standard MK magazine, fits 30 rounds of 5.56 ammo.",
			"AMMOCOUNT",
		},

		["mag0-glock-9x19"]={
			"Standard P17 magazine, fits 17 rounds of 9x19 ammo.",
			"AMMOCOUNT",
		},
		["mag1-glock-9x19"]={
			"Extended P17 magazine, fits 33 rounds of 9x19 ammo.",
			"AMMOCOUNT",
		},
		["mag2-glock-9x19"]={
			"Large P17 Drum magazine, fits 50 rounds of 9x19 ammo.",
			"AMMOCOUNT",
		},

		["mag0-ppsh-762x25"]={
			"Standard PPSh magazine, fits 35 rounds of 7.62x25 ammo.",
			"AMMOCOUNT",
		},
		["mag1-ppsh-762x25"]={
			"Large PPSh drum magazine, fits 71 rounds of 7.62x25 ammo.",
			"AMMOCOUNT",
		},

		["mag0-scar-762x51"]={
			"Standard TCR-308 magazine, fits 20 rounds of 7.62x51 ammo.",
			"AMMOCOUNT",
		},

		["mag0-ak-762x54"]={
			"Standard Drozdov magazine, fits 10 rounds of 7.62x54R ammo.",
			"AMMOCOUNT",
		},
		
		["mag0-tt33-762x25"]={
			"Standard TT-33 magazine, fits 8 rounds of 7.62x25 ammo.",
			"AMMOCOUNT",
		},

		["mag0-g3-762x51"]={
			"Standard MC308 magazine, fits 20 rounds of 7.62x51 ammo.",
			"AMMOCOUNT",
		},
		["mag1-g3-762x51"]={
			"Extended MC308 magazine, fits 30 rounds of 7.62x51 ammo.",
			"AMMOCOUNT",
		},

		["mag0-ak-9x19"]={ -- (v2 fix 2026-11-12) entry was missing: "Unknown item: mag0-ak-9x19"
			"Standard Simonov-9 magazine, fits 30 rounds of 9x19 ammo.",
			"AMMOCOUNT",
		},

		["mag0-mp5-9x19"]={
			"Standard MC9 magazine, fits 30 rounds of 9x19 ammo.",
			"AMMOCOUNT",
		},

		["mag0-m107-127x99"]={
			"Standard M107 magazine, fits 10 rounds of .50BMG ammo.",
			"AMMOCOUNT",
		},
	},
	ammo={default_DESC = {"Unknown ammo.", "UNKNOWNITEMID", "AMMOCOUNT"},
		["bullets-12ga"]={
			"Standard 12 Guage shotgun ammo",
			"AMMOCOUNT",
			"Used by: Mudafie, Qasira, CZ-1012, N870",
		},
		["bullets-9x19"]={
			"Small Calibre 9mm ammo",
			"AMMOCOUNT",
			"Used by: P17, P17A, SCALAR, MC9",
		},
		["bullets-545"]={
			"Standard 5.45 ammo",
			"AMMOCOUNT",
			"Used by: Simonov-545, Simonov-545U, Simonov-105, Simonov-106",
		},
		["bullets-556"]={
			"Standard NATO 5.56 ammo",
			"AMMOCOUNT",
			"Used by: N4A1, N16, TCR-556, MK36, Bauer-553",
		},
		["bullets-762x25"]={
			"Small Calibre 7.62 x 25 ammo",
			"AMMOCOUNT",
			"Used by: TT-33, PPSh-41",
		},
		["bullets-762x39"]={
			"Standard 7.62x39 ammo",
			"AMMOCOUNT",
			"Used by: Simonov-762, SKS",
		},
		["bullets-762x51"]={
			"Large Calibre 7.62 x 51 ammo",
			"AMMOCOUNT",
			"Used by: TCR-308, MC-308",
		},
		["bullets-762x54"]={
			"Large Calibre 7.62 x 54 R ammo",
			"AMMOCOUNT",
			"Used by: Medvedev, Drozdov",
		},
		["bullets-127x99"]={
			"Armor piercing .50 BMG ammo",
			"AMMOCOUNT",
			"Used by: Jallad",
		},
		["rocket0"]={
			"High-Explosive Anti-Tank rocket. Good for armor penetration.",
			"Used by: RPG",
		},
		["rocket1"]={
			"High-Explosive Anti-Personnel rocket. Good against infantry.",
			"Used by: RPG",
		},
		["rocket2"]={
			"Tandem High-Explosive Anti-Tank rocket. Great for armor penetrantion, as it uses two anti-tank warheads to penetrate up to 500mm of armor.",
			"Used by: RPG",
		},
		["rocket3"]={
			"Makeshift High-Explosive Anti-Personnel rocket. A modified PG-7V designed for maximum war crimes.",
			"Used by: RPG",
		},
	},
	melee={default_DESC = {"Unknown melee weapon.", "UNKNOWNITEMID"},
		["melee-Pipe"]={
			"Melee weapon",
		},
		["melee-Katana"]={
			"Melee weapon",
		},
		["melee-Crowbar"]={
			"Melee weapon",
		},
		["melee-Tomahawk"]={
			"Cool looking axe, for the fancy people who tries to look cool, damage wise? it will do damage, for sure, though dont ask for much.",
		},
		["melee-BaseballBat"]={
			"Melee weapon",
		},
		["melee-CombatKnife"]={
			"Nice military combat knife. Small, light weight, and rapid. Give you opponent a stab and they are going down.",
		},
		["melee-FireAxe"]={
			"Standard fire axe. lots of weight for lots of inertia. perfect to chop through things of different material, flesh or wood.",
		},
	},
	general={default_DESC = {"Unknown item.", "UNKNOWNITEMID"},
		["grenade"]={
			"RGD-5 frag grenade. Small size big dreams, send your target to the orbit.",
			"Kill Radius: 3m",
			"Fuse: 3.5s",
		},
		["general-battery"]={
			"A battery, maybe it can still power a TV remote.",
		},
		["general-book"]={
			"this book is waste of time why you need study in the middil of a dasert you are trying to life not be profeser and teach boring books to other people",
		},
		["general-carbattery"]={
			"A standard car battery. Intended for discarding in the ocean, or maybe in the dried river.",
		},
		["general-gasan"]={
			"It says that the concertration of a specific type of gas is abnormally high, not sure which gas though.",
		},
		["general-gpu"]={
			"A valueble and highly advanced graphics processor unit for a computer. Not sure how it get here, though.",
		},
		["general-lighter"]={
			"A luxurious lighter, people outside will pay a stupid amount for one of those.",
		},
		["general-nails"]={
			"A box of industrial nails, some how more standout then rest of the junks.",
		},
		["general-snow"]={
			"A bag of white powder, not very sure why it is labled snow, doesn't feel very healthy.",
		},
		["general-ledx"]={
			"A skin transilluminator, incredibly valuable medical device.",
		},
	},
}

--[[ Template
["_id_"]={
	"_description_",
},
]]

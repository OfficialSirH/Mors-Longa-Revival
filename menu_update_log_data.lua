Sections = {}
Sections.summary = "Summary"
Sections.new     = "New Additions"
Sections.fixes   = "Fixes & Improvements"


Categories = {}
Categories.player	 = "Player"
Categories.inventory = "Inventory/Items"
Categories.weapons	 = "Weapons"
Categories.vehicles	 = "Vehicles"
Categories.map		 = "Map"
Categories.shop		 = "Shop"
Categories.events	 = "Random Events"
Categories.npcs		 = "NPCs"
Categories.debugmenu = "Debug Menu"
Categories.spawnmenu = "UI and Spawn Menu"
Categories.options	 = "Options/Controls"
Categories.other	 = "Other"


function init_update_log_data()

	-- DATE FORMAT: "Month DD, YYYY"

	UpdateLogItems = {
		{
			create_update_log_item(
				"1.5.0",
				"October 27, 2024",
				"Inventory Quick Fixes",
				{
					create_update_change(
						Sections.summary, {
							":3",
						}
					),
					create_update_change(
						Sections.new, {
							Categories.inventory, {
								"You can now rotate items in your inventory. Default keybind for it will be \"R\". It can be rebinded in the settings.",
								"Grabbing item nolonger grabs the top left corner of the item, it now grabs at where you grabbed it.",
							},
							Categories.npcs, {
								"Friendly NPCs can now sit in vehicles (Only one vehicle supported at the moment). To spawn the vehicle, go to Debug Menu (press backspace) -> Top right corner -> Spawn \"NPC seated vehicle.\"",
							},
						}
					),
					create_update_change(
						Sections.fixes, {
							Categories.inventory, {
								"Your inventory is nolonger secretly upside-down after almost 2 years of mors longa release.",
								"Right click menu nolonger draws below the slots to its right.",
							},
							Categories.map, {
								"Parking spot should be able store all vehicles with no hassle, now it's detection zone is lowered by 0.5 meter into the ground.",
							},
						}
					),
				}
			)
		},
		{
			create_update_log_item(
				"1.4.8",
				"August 5, 2024",
				"Fixes and Fire",
				{
					create_update_change(
						Sections.summary, {
							"This update fixes some of the things that were broken with the most recent update, while also adding in a new exotic 12 gauge round. :)",
						}
					),
					create_update_change(
						Sections.new, {
							Categories.weapons, {
								"Added dragons breath shotgun rounds.",
							},

						}
					),
					create_update_change(
						Sections.fixes, {
							Categories.weapons, {
								"Removed a bug where internal magazine guns would spawn a dozen bullets when reloading.",
							},
							Categories.other, {
								"Spawn loadouts no longer bug giving the player few items, and the amount of meds the player can start with has increased.",
								"Added item descriptions to new bullet types.",
							},
						}
					),
				}
			)
		},
		{
			create_update_log_item(
				"1.4.7",
				"July 23, 2024",
				"Bullet Types and NPC anatomy",
				{
					create_update_change(
						Sections.summary, {
							"This update introduces a new \"bullet types\" system and improved NPC skeleton/flesh structure.",
						}
					),
					create_update_change(
						Sections.new, {
							Categories.weapons, {
								"New bullet types system including FMJ, Tracers, AP, API, and APE for all guns.",
							},
							Categories.npcs, {
								"NPC joints are now proper bone-to-bone connections. This prevents NPCs from dying too easily from joint shots.",
								"NPC flesh is now a soft layer on top of harder bone that works in tandem with the new ammo types.",
								"Added prototype friendly juggernaut npcs. Spawn: DEBUG MENU (backspace) -> SPAWN NPCs (top right corner) -> test juggernaut.",
								"Added option to spawn vehicle transport npcs. Spawn: DEBUG MENU (backspace) -> SPAWN NPCs (top right corner) -> enemy vehicle.",
								"Added faction based npc pain yelp and death sounds.",
							},
							Categories.other, {
								"Added options screen to the built-in Teardown mod manager.",
								"Backend file organization and mod structure cleanup.",
							},
							Categories.player, {
								"Added improved limb based player hit/hurt sounds."
							}
						}
					),
					create_update_change(
						Sections.fixes, {
							Categories.npcs, {
								"Cultist eyes now go dark when they die.",
								"Slightly improved friendly npc ai.",
							},
							Categories.weapons, {
								"Enabled the built-in fire extinguisher tool.",
							},
							Categories.other, {
								"Fuel cans no longer play liquid pouring sound when empty.",
							},
						}
					),
				}
			)
		},
		{
			create_update_log_item(
				"1.4.6",
				"May 31, 2024",
				"NPCs Fixes and Tuning",
				{
					create_update_change(
						Sections.summary, {
							"This update mainly fixes a few major npc bugs regarding navigation, combat and consistency.",
						}
					),
					create_update_change(
						Sections.new, {
							Categories.npcs, {
								"Friendly NPCs. Go to the DEBUG MENU (backspace) -> SPAWN NPCs (top right corner) -> merc. They are still a work in progress.",
								"NPC controller which lets you play as any npc. Go to the DEBUG MENU (backspace) -> NPC Controller -> Select NPC to Control",
								"NPCs now strafe side to side while in combat.",

							},
							Categories.debugmenu, {
								"Added infinite materials option in the debug menu.",
							},
						}
					),
					create_update_change(
						Sections.fixes, {
							Categories.npcs, {
								"Each NPC is able to query its own path. This stops them from just standing around when they need to navigate.",
								"NPCs now slow down to accommodate sharp turns.",
								"NPC RPGs no longer cause lag spikes.",
								"Faction based combat tuning.",
								"Fixed NPC military vehicle spawn points.",
								"NPCs are much tougher.",
							},
							Categories.weapons, {
								"Guns are far more difficult to hip-fire and have more recoil.",
								"Guns with zero ammo can shoot when \"infinite ammo\" debug option is enabled.",
							},
							
						}
					),
				}
			)
		},
		{
			create_update_log_item(
				"1.4.5", -- last commit: bf07ff03c05d8f9b88181bca9fcf7b091808aa51
				"November 22, 2023",
				"General Fixes, Small Changes",
				{
					create_update_change(
						Sections.summary, {
							"This update fixes some of the issues encountered with TD version 1.5.1",
						}
					),

					create_update_change(
						Sections.new, {
							Categories.player, {
								"Added Movement velocity selection.",
								"Added Leaning with ALT+Q/E.",
							},
							Categories.events, {
								"Added new event that changes with time of day, called: Ambush.",
							},
							Categories.npcs, {
								"NPC's use a new temporary blood system as we work on reworking the blood and gore for the mod.",
							},
							Categories.inventory, {
								"Added new Gray TT33 Icon to the inventory"
							},
						}
					),

					create_update_change(
						Sections.fixes, {
							Categories.npcs, {
								"Helicopter no longer crashes into the ground when first spawning.",
							},
							Categories.vehicles, {
								"Player vehicle is no longer affected by world boundary",
								"NPC Vehicles are no longer affected by the boundary and launched at mach speeds.",
							},
							Categories.other, {
								"Grenade unpin SFX no longer plays when you press the grenade keybind with no grenades.",
								"Removed broken glass script to fix XML Parse error",
								"Removed NPC spawning from the Spawn-list to avoid issues temporarily.",
							},
						}
					),
				}
			)
		},
		{
			create_update_log_item(
				"1.4.0", -- last commit: 20d4c15c16bd4ea702d7fcb9df8d799d293e832e
				"October 6, 2023",
				"Parking Spot Update",
				{
					create_update_change(
						Sections.summary, {
							"This update brings several quality of life improvements, a new parking spot system, enhanced NPC walking, a melee-based NPC boss, and new warehouse buildings.",
						}
					),

					create_update_change(
						Sections.new, {
							Categories.map, {
								"Parking Spot - Allows you to park a vehicle and save it between safezones (does not supports welded items at the moment).",
								"Warehouse buildings (3 versions: Insurgent, UM and Cultist)",
								"Crashed heli at the start of the map has new charring and smoke effects.",
							},
							Categories.player, {
								"Added United Mates vehicle player model for hardcore difficulty."
							},
							Categories.other, {
								"Updated tutorial to account for newer feature.",
							},
							Categories.npcs, {
								"The Cultist boss NPC is now a dedicated melee NPC which chases its targets.",
								"All NPCs can punch the player when close enough.",
								"NPCs now use the built in teardown robot walking animations, making movement much more consistent.",
								"NPC can now climb inclines and stairs.",
								"NPCs now turn their heads towards their targets when appropriate.",
								"NPCs jaws stay in place relative to their heads while alive and not stunned.",
								"New blood pooling system after npcs die.",
								"New standardized ragdoll framework which makes their physics more consistent.",
								"Added new insurgent AI helicopter.",
								"AI helicopters and NPCs now attack eachother based on team.",
								"Enemy vehicle npcs now spawn more frequently as you progress distance wise.",
							},
							Categories.debugmenu, {
								"Debug screen can be closed with the inventory toggle button (\"tab\" by default)",
								"Added buttons to enable/disable the procedural spawning of: road segments, special segments, buildings, enemies, loot, vehicles, and roadblocks.",
								"Added buttons to enable/disable hunger, thirst.",
								"Added buttons to enable/disable infinite ammo and infinite fuel.",
								"Added a button to open the spawn menu (removed old deprecated loot spawning buttons).",
								"Added option to show npc projectile impacts.",
							},
							Categories.spawnmenu, {
								"Spawn menu can now be closed with inventory toggle button (\"tab\" by default)",
							},
						}
					),

					create_update_change(
						Sections.fixes, {
							Categories.player, {
								"It is no longer possible to discover all perks by dying in hardcore mode.",
								"Perks now resets when a new game is created.",
							},
							Categories.events, {
								"A10 airstrike no longer targets the player and keeps its strike position consistent.",
								"A10 airstrike sounds slightly louder and fly over sound plays at a more appropriate time.",
								"A10 airstrike takes less time to do the full strike from start to finish.",
							},
							Categories.npcs, {
								"NPC projectiles no longer hit the player by phasing through objects and vehicles.",
								"NPCs now hit the player much more consistently at close range.",
								"Improved NPC combat, thinking consistency and target detection.",
								"Improved distant NPC gunshot sounds.",
								"NPCs now properly stand idle while thinking is disabled through the debug menu.",
								"Placetool preview objects no longer block the NPC's vision nor makes NPCs float.",
								"NPC ambush vehicles now spawn more consistently and more frequently during late game.",
								"Increase the rate which enemy gets off transport trucks to make camping the exit harder.",
								"Fixed npc RPG accuracy.",
							},
							Categories.weapons, {
								"Fixed player and npc RPG hit detection."
							},
							Categories.inventory, {
								"Added item descriptions for newer food items.",
								"Changed item name of \"Strawberry\" to \"Strawberries\". Existing Strawberry will not change their name.",
							},
							Categories.shop, {
								"It is nolonger possible to refresh the shop by dying or forcing the inventory script to dump.",
							},
							Categories.map, {
								"Player no longer teleports under the map when the segment loading bug occurs.",
								"Fixed issue with destoried semi trucks cliping into scenery when spawned.",
								"Fixed issue where loot outlines also outlined the collision box. It now only outlines the visual model.",
								"Reduced the gas station fuel level to make fuel not so easy mode.",
								"Trigger entities are now correctly removed when they get away far enough.",
								"Fixed potential issue with a certain vehicle wrecks not spawning.",
								"Fixed misaligned foilages on the collapsed train bridge segment.",
								"Fixed duplicated tent component and buildings shapes.",
							},
							Categories.vehicles, {
								"\"AVF unavaliable\" warning now only show up once per play session.",
							},
							Categories.other, {
								"Further made sure that no more rogue keys will be created within the savegame.",
								"Reduced savegame file size by inventory systems by preventing the saving of unnecessary information.",
								"Increased main Mmenu settings scroll speed.",
								"Reorganized built-in spawn menu list.",
							},
						}
					),
				}
			)
		},
		{
			create_update_log_item(
				"1.3.1",
				"July 21, 2023", -- stopped at commit
				"Blood and Spawn Menu Update",
				{
					create_update_change(
						Sections.summary, {
							"A few fixes for existing systems such as the spawn menu and custom settings, new guns like the Deagle and new features like NPC blood splatters.",
						}
					),

					create_update_change(
						Sections.new, {
							Categories.spawnmenu, {
								"Added a search bar.",
								"Added a favorites system and button to display all favorites.",
								"Added an undo keybind to delete the last set of spawned items.",
								"Added \"Close after spawning\" toggle-button.",
								"Spawn menu can be closed by clicking wherever there are no UI panels.",
							},
							Categories.options, {
								"Mors Longa settings can be opened in game (\"MorsLonga Settings\" button at the bottom of the pause menu).",
							},
							Categories.inventory, {
								"New weapon Simonov-556 (Automatic rifle chambered in 556 NATO, using the Simonov platform)",
								"New food items to add a bit more variety to your game",
								"New armor plate items that can be used to repair armor vests"
							},
							Categories.weapons, {
								"New weapon: Simonov-556 (Automatic rifle chambered in 556 NATO, using the Simonov platform)",
								"New weapon: Deagle (Semi Automatic sidearm that uses the new .50AE caliber)",
								"New variants for N16.",
								"Ability to change reticle type by pressing j, and change reticle color by pressing k",
							},
							Categories.npcs, {
								"New realistic bleeding effects for npcs.",
							},


						}
					),


					create_update_change(
						Sections.fixes, {
							Categories.spawnmenu, {
								"Improved the spawn menu's functionality and UI layout.",
								"Queries only run the frame they are needed, preventing constant FPS drop while the spawn menu is open.",
							},
							Categories.inventory, {
								"Fixed grenade clearing out the inventory when thrown.",
								"Fixed armor durability.",
							},
							Categories.npcs, {
								"NPCs run slightly faster and stand more upright.",
							},
							Categories.other, {
								"Added missing scripts into Teardown spawn menu -> [ML - Mors Longa Game Scripts]."
							}
						}
					),
				}
			)
		},
		{
			create_update_log_item(
				"1.3.0",
				"April 25, 2023", -- stopped at commit 5653b338
				"General Fixes",
				{
					create_update_change(
						Sections.summary, {
							"A collection of fixes following the \"Quality of Life Update.\"",
						}
					),

					create_update_change(
						Sections.new, {
							Categories.npcs, {
								"Added Alashyan Millitary troop transport vehicle NPCs.",
							},
							Categories.player, {
								"Added \"Bleeding Out\" warning."
							},
						}
					),

					create_update_change(
						Sections.fixes, {
							Categories.npcs, {
								"AI helicopter no longer endlessly lasers the player into oblivion.",
								"Improved NPC running animation and running speeds.",
								"Tuned NPC shooting behavior and magazine sizes.",
								"Tuned NPC gun damage and rate of fire values.",
								"NPCs now exit vehicles from more realistic locations of the vehicle.",
								"Tuned NPC RPG velocity and damage and improved smoke effects."
							},
							Categories.map, {
								"Slightly improved procedural generation performance.",
								"Fixed game crashing bug that occured when loading new segments.",
								"Made freezers heavier so they don't tip over while opening them.",
								"Improves enemy spawn points."
							},
							Categories.weapons,{
								"Removed broken throwing combat knife mechanic."
							},
							Categories.shop, {
								"Shop now starts on buying screen instead of selling screen.",
								"Visually improved shop buy/sell buttons.",
								"Added shop UI background blur.",
							},
							Categories.options, {
								"Reduce Render Distance option now works.",
							},
							Categories.player, {
								"NPC RPG hits no longer insta-kill the player."
							},
							Categories.debugmenu, {
								"Fixed debug menu quicksave bug.",
								"Organized and renamed a few debug options.",
								"Added sandstorm option to debug menu.",
							},
							Categories.other, {
								"Fixed day/night cycle pause/resume bug.",
								"Fixed several grammatical errors.",
								"Removed several unused files to reduce file bloat.",
								"Slightly improved land mine performance.",
								"Reorganized/improved inventory save structure, it is already done when you saw this.",
							},
						}
					),
				}
			)
		},
		{
			create_update_log_item(
				"1.2.0",
				"March 9, 2023", -- stopped at commit ffce3144
				"Quality of Life Update",
				{
					create_update_change(
						Sections.summary, {
							"The Quality of Life update fixes several bugs, improves on balancing and adds more unique content.",
								"We hope to tackle more of the overall poor performance and lag in the next major update.", {
							},
						}
					),
					create_update_change(
						Sections.new, {
							Categories.npcs, {
								"NPCs now support quicksaving.",
								"Improved NPC combat behavior.",
								"Enemy helicopter can now spawn randomly. (This can be turned off in the options - game.)",
							},
							Categories.vehicles, {
								"11 new special class vehicles.",
								"10 new good class vehicles.",
								"6 new wrecked class vehicles.",
								"6 new damaged class vehicles.",
								"2 new military class vehicles.",
								"Added some new vehicles to the spawn menu.",
								"Soviet van now has more variants.",
							},
							Categories.map, {
								--"Added horde mode.",
								"Added more road segments.",
								--"Added a new modern house as a random building.",
								--"New suply drops that happenes once in a while, i think, idfk, waffle how the fuck does it work.",
								"Gas station buildings now have a small chance to spawn some vehicles.",
								"Street lights now have a chance to be turned off.",
								"Added background for all road segments as well as the tutorial level.",
								"Added random street funiture on the side of roads/buildings.",
								"Some windows now shatter when damaged.",
							},
							Categories.weapons, {
								"New weapon KS23 (shotgun chambered in 4 gauge)",
								--"New weapon TBR-53 (rifle chambered in 7.62x51)",
								"New variants for N107",
								"New variants for MC308",
								"New variants for SKS",
								"New variants for Scalar",
								"New variants for N4A1",
								"New variants for TT-33",
								"New variants for P17 and P17A",
								"New variants for ppsh-41",
							},
							Categories.player, {
								"Added new screen effects when player gets hurt.",
							},
						}
					),
					create_update_change(
						Sections.fixes, {
							Categories.npcs, {
								"Fixed player hit detection from npc bullets.",
								"Reduced RPG NPC spawns.",
								"Adjusted NPC spawn rules.",
								"Adjusted NPC weapon spawns.",
								"Adjusted NPC weapon performance.",
								"Fixed NPC not dropping weapon ammo correctly.",
								"NPC behaviour adjusted/fixed/optimized.",
								"Optimized NPC internal code logic/performance.",
								"Fixed bosses.",
								"Added More NPC model variants.",
								"Added Night variant military NPC models.",
								-- "Merchant now has personal security guards.",
								"Shortened civilian vehicle spawn cooldown by half.",
								"Mclockelle's enemies now wear mclockelle's uniform",
								"Enemy helicopter now reacts to sandstorm/night environment appropriately.",
								"Enemy helicopter behaviour adjusted/fixed/optimized.",
							},
							Categories.map, {
								"Reduced diffculty of refueling from gas station by changing the entire procedure.",
								"Out of border road is now removed earlier.",
								"Fixed loot spawn chance, now it is correctly calculated.",
								"Repositioned some roadblock spawns to fix clipping issues.",
								"Gave more things in roadsegments textures.",
								"Changed bed/stash in the safezone segment to be unbreakable.",
								"Fixed ability to steal bed/stash/perk machine with the physics gun in the safezone segment.",
								"Further updated the gate segment.",
								"Further optimized wall segment.",
								"Optimized ballistic walls, now with longer loadtime but better runtime performance.",
								"Optimized toll cabins, now with longer loadtime but better runtime performance.",
								"Optimized collapsed railway bridge segment.",
								"Landmine script organization/fixes.",
								"Removed randomized building rotations.",
								"Removed roadblock segment temporarily due to performance issues.",
							},
							Categories.weapons, {
								"Updated how sight/scope reticles render, it is now no longer a sprite but rather a UI element to reduce reticle delay",
								"Rebalanced weapon recoil.",
								"Player weapon script only exist in the world when the player has them equipped.",
								"Slightly changed simonov's tool models.",
								"Slightly reduced repeating code.",
								"Fixed ppsh41's attachment menu wrongly accessible.",
								"Increased .50BMG's damage.",
							},
							Categories.inventory, {
								"Updated 6L10 magazine icons.",
								"Fixed missing item description on the Simonov-9, TMP-90, TCP-57.",
								"Fixed missing item description on the 5.7x28 Ammo.",
								"Fixed missing item description on the MC308 drum.",
								"Fixed missing Caliber/Feed info in item descriptions for Qasira.",
								"Fixed missing compatible gun in item description on the .50 BMG Ammo.",
								"Changed CMS description to better reflect its purpose.",
								"Changed Surv-12 description to better reflect its purpose.",
								"Fixed several grammar/typos for all the item descriptions",
								"Slightly changed RPG loot model to give it a better collision",
								"Updated tmp-90 loot model.",
								"Slightly updated simonov 5.45/7.62 magazine's loot model.",
							},
							Categories.shop, {
								"Fixed issue where TCP-57, Simonov-9 and sv-98 does not sell for the correct price.",
								"Fixed issue where Simonov-9 magazine does not sell for the correct price.",
								"Lowered sell price of drozodov from $530 to $510.",
								"Fixed issue where RPG sold in shop has the broken rocket.",
								"Murdering the shop keeper will make you pay for insurance at a great economic loss.",
							},
							Categories.vehicles, {
								"Fixed destroyed vehicle models to no longer glow",
								"Updated camo for military vehicles.",
								"Reduced light fog for vehicle headlights",
								"Readjusted performance of some vehicles",
								"Optimized vehicle doors",
								"Fixed car alarms not working properly",
								"Made tanks lighter",
							},
							Categories.player, {
								"Reduced headshot damage to prevent frustrating gameplay.",
								"Critical health level was raised.",
								"Head bobing now cares about players game options.",
							},
							Categories.options, {
								"Added missing Canted sight/Alternative scope controls.",
							},
							Categories.other, {
								"Perk display is now ordered.",
								"Fixed the missing 5.7x28 perk.",
								"Fixed issue where perk upgrade notification stacks.",
								"Optimized perk pickup.",
								"Fixed sandstorm looking more like snowstorm, the fog is now yellow, the particles are however still white.",
								"Potentially fixed issue with quickload button sometimes not showing.",
								"Fixed issue with custom spawn menu not working correctly with certain data structures",
								"NPC combat music now plays/syncs correctly",
								"Doubled mod options scroll bar sensitivity.",
								"Moved check box options to make space for longer options text.",
								"Fixed issue when dragging the mod options scroll bar fast enough, the options don't immediately appear.",
								"Ragdolls are now standardized a little.",
								"Fixed some useless strings being written into the savegame.",
								"Reorganized folder structure.",
								"God mode is no longer called Cringe mode.",
							},
						}
					),
				}
			)
		},
		{
			create_update_log_item(
				"1.1.0",
				"January 15, 2023",
				"Major Update",
				{
					create_update_change(
					Sections.new,
					{
						"Map is now disabled in the mod",
						"Default Backpack opening key is now swapped to \"TAB\" key.",
						"Default Grenade key is now swapped to \"G\" key.",
						"It is now possible to sell fuel",
						"Experimental dynamic loot models, dropped guns will have their model change appropriately depending on the state of the gun, it is only implemented on the Simonov-545 currently.",
						"New Ammo type 5.7x28",
						"New weapon TMP-90 (sub-machine gun chambered in 5.7x28)",
						"New weapon TCP-57 (pistol chambered in 5.7x28)",
						"New weapon SV-98 (rifle chambered in 7.62x54R)",
						"New medical supplies: Grizzly, Surv12, CAR ",
						"New forced first person camera mode, you can find it in the mod game options",
						"New animations for the Al2 and CMS kit medical items.",
						"New civilian vehicles that roam the vast highways in search for an exit.",
						"Hexgrid has been upgraded from level 4 armor to level 5.",
						"New headwear: GS31-3W thermal",
						"New inventory sprite for NVG",
						"New improved vehicle leaning, you can now drive as you lean out.",
						"Theres now an update log, it's what you are seeing right now",
						"New building spawn",
						"New roadsegment spawn",
						"New food items: Burger, Fries, Chicken Nuggets, Diet Cola and Sad Meal",
						"New experimental boss: AS350 Attack Helicopter",
					}),
					create_update_change(
					Sections.fixes,
					{
						"Enemies will now shoot a random RPG rocket, PG-7V and OG-7V are included, PG-7VT and PG-7VA are excluded.",
						"Scalar now supports dynamic magazine icons.",
						"PPsh41 now supports dynamic magazine icons.",
						"MK36 now supports dynamic magazine icons.",
						"MK36 now supports dynamic attachment icons.",
						"Fixed issue where the perk machine smoke remained emitting even after being deleted.",
						"Fixed issue where the foilage percentage settings didn't work",
						"Fixed issue where the hunger/thirst didn't deal damage to player correctly",
						"Optimised the hesco wall for the military camp and the military roadblock",
						"Grenades now have shrapnel damage.",
						"Lowered price of grenade from $400 to $300.",
						"Tutorial vehicles have been updated to reflect the changes in the last update.",
						"Tutorial RPG's have been fixed.",
						"Splint no longer sells for $100, it now sells for $20",
						"Increased price of bandage from $20 to $30",
						"Increased price of Splint from $20 to $40",
						"RV has had their CoM raised to a more appropriate level, and a slight handling adjustment.",
						"RV now has a custom 3rd person camera focus point, and an appropriate exit location.",
						"White bus has had their CoM raised to a more appropriate level, and slight handling adjustment.",
						"White bus now has a custom 3rd person camera focus point, and an appropriate exit location.",
						"White bus now has a better model with a chassis, an engine, an openable hood and a slanted steering wheel.",
						"Yellow soviet truck now has a custom 3rd person camera focus point, and an appropriate exit location.",
						"Soviet firetruck now has a custom 3rd person camera focus point, and an appropriate exit location.",
						"Green van has had their CoM raised to a more appropriate level, and slight handling adjustment.",
						"Green van now has a custom 3rd person camera focus point, and an appropriate exit location.",
						"Each food now has their own consume sound",
						"Theres now a new backpack opening/closing sound",
						"Fixed issue where N870 and the Medvedev where not re-centering their scope correctly",
						"Fixed issue where tools are not disabled correctly even if custom tools options was disabled",
						"Destroyed Green muscle car is no longer static",
						"Destroyed Brown station wagon is no longer static",
						"Both Destroyed/working Yellow soviet truck/firetruck have possible loot spawns",
						"Working soviet firetruck now spawns with an fire axe",
						"Green van now has possible loot spawns",
						"Modified Green van now has spawn with an gascan",
						"White bus now has possible loot spawns",
						"Military roadblock is now textured, they are now dirty looking",
						"Village has had their texture updated.",
						"Military camp has had their texture updated.",
						"Fixed issue where the starter tt-33 is not recognized by the backpack correctly.",
						"Fixed issue where the status bar only warns you of low percentage when it reaches 0",
						"NPC weaponry is now worse at the start and gets progressively better later in the run",
						"Junk model optimised",
						"IFAK now heals bleeds, as a counter effect, old IFAK is now obsolete, you can still heal with the old IFAK, though",
						"Medical supplies now have a better inventory description",
						"Use items sounds/sound logic have been updated",
						"Enemy weapon RoF has been adjusted to fit the actual gun better",
						"Fixed ladder placeable",
						"better furnished the safesegment",
						"Optimized inventory logic, it should now have fewer performance impacts",
						"Updated several backpack icon drawing logic, its now consistant across everything",
						"Updated several item icons",
						"Fixed issue where when an explosion happens near the player your soul is spit out of your body",
						"Fixed a name type for a rare item",
						"More Simonov-545 variants",
						"Nuked unused sounds to save space",
						"Fixed bug when grabbing 2 items at the same time, only one item will get picked up and the rest gets removed",
						"Fixed bug when reloading bullet into magazine, the bullet will have 0 stack for a single tick, it is now removed at the same time as the bullets run out.",
						"Ammo box now metal instead of wood",
						"It is now possible to bind number keys, function keys (f1-f12), and tab",
						"Fixed issue where end key cannot be bind",
						"Fixed issue where splitting ammo could create an ammo stack with 0 ammo",
						"Fixed issue when reloading magazine with ammo taken from stash, if the ammo runs out, the inventory cell gets cleared instead of the cell in the stash",
						"Made it so when a loot spawn fails due to a file not found, it tries to spawn another item with the same parameter",
						"Changed split ammo behavior, hold ctrl and drag on an ammo stack will split the ammo into your grab.",
						"Choccy no-longer reduces thirst.",
						"MRE now only gives 80 hunger instead of 90.",
						"Fixed issue with complex keybinds not working if it's checking for pressed state.",
					}),
				})
		},
		{
			create_update_log_item(
				"1.0.2",
				"January 1, 2023",
				"Merchant Update",
				{
					create_update_change(
					"Safezone merchant",
					{
						"New merchant on the safe segments with a shop, you can now buy/sell things",
						"Added money balance",
						"New reworked perk machine/mechanic",
						"Added new junk items that you can sell",
						"New RPG Rockets that you can find and use from anti-personnel to tandem anti-tank rockets",
						"New weapon Simonov9 (an AK platform chambered in 9mm)",
					}),
					create_update_change(
					Sections.fixes,
					{
						"New sprites for ammo",
						"New food/drinks that can now spawn",
						"New enemies (enemy vehicles have been reworked)",
						"Improved lights for all vehicles",
						"New truck vehicle added",
						"Added Ladder, Campfires, Spotlights to the placetool",
					}),
				})
		},
		{
			create_update_log_item(
				"1.0.1",
				"December 28, 2022",
				"Mors Longa Release",
				{
					create_update_change(
						Sections.summary, {

							"The Country of Alashya, heavily influenced by America in the middle east, has entered lockdown due to a deadly, paranoia inducing virus. Civilians are outraged, attempting to flee the country, but the Alashyan government has shut down the inner cities and rural areas making it almost impossible to leave. Insurgents and anarchists have risen up. The population is frantic as everyone is trying escape Alashya. The AAF forces have now been given the green light to eliminate anyone attempting to escape through the country's vast highways with lethal force.\n ",

							"Now since the highway is endless and you literally cannot finish the game (may change in the future), your task will be to survive as long as you can, by continuing to move forwards, finding food and fuel to keep you going. Search abandoned roadside buildings for loot, optimize your inventory storage and tread carefully, as getting shot can lead to bleeding damage and bone fractures. And lastly, kill anyone that means you harm.\n ",

						}
					),
				})
		},
	}

end


---Container for a single major update. Holds all the data for a single update.
---@param date string FORMAT: "month day, year"
---@param title string Workshop title of the update. Example: Merchant Update
---@param changes table Use create_update_change to create a change.
function create_update_log_item(version, date, title, changes)
	return{
		version = version,
		date = date,
		title = title,
		changes = changes,
	}
end


-- A single category of changes. Has a header and a list of bullet points.
function create_update_change(header, list_changes)
	return {
		header = header,
		changes = list_changes
	}
end

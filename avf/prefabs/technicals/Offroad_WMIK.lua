#version 2
#include "script/include/player.lua"
#include "../../../scripts/MountedGun.lua"
-- (v2) WMIK Technical (offroad_WMIK_MILAN.xml, spawn menu "WMIK Technical"): MILAN on our own mounted-gun script with
-- AVF's guided missiles ported (scripts/avf). In the original this file's includes were commented out (below), so
-- AVF only saw the XML tags and fired its generic customcannon shell; the user chose a MILAN missile (2026-11-13).
-- The MILAN template the AVF table below names ("MILAN_02") never existed in the mod (weapon_templates.lua has only
-- 2A13 and D-30), so MountedGunConfig is new, built on AVF's Kornet shell (ammo.lua "9M133M-2") with MILAN figures:
-- 115 mm, wire-guided (AVF "guided": rides the sight line), a little less penetration than the Kornet configs (BMP:
-- 2.0), one missile per load. Standing gunner place behind the launcher; the driver does not fire.
MountedGunGunTag = "main_MILAN"
MountedGunEmitterTag = "main_MILAN_emitter"
MountedGunSound = "MOD/avf/assets/sounds/atgm00.ogg" -- AVF's ATGM launch sound (copied)
MountedGunConfig = {
	name = "MILAN",
	weaponType = "atgm",
	RPM = 5,
	reload = 5,
	dispersion = 0,
	magazines = {
		[1] = {
			name = "MILAN",
			displayName = "MILAN ATGM",
			caliber = 115,
			velocity = 55,
			gravityCoef = 0,
			dispersionCoef = 0,
			explosionSize = 1.0,
			maxPenDepth = 1.8,
			timeToLive = 32,
			launcher = "guided",
			payload = "HEAT",
			shellWidth = 0.6,
			shellHeight = 1.2,
			r = 0.9, g = 0.3, b = 0.3,
			shellSpriteName = "MOD/gfx/rocketModel.png",
			shellSpriteRearName = "MOD/gfx/rocketRear.png",
			flightLoop = "MOD/sounds/rocketFlightLoop0",
			magazineCapacity = 1,
			magazineCount = 6,
		},
	},
}

--[[
(v2, 2026-11-13) the original's two include lines stood here inside this comment: Teardown handles include lines
before Lua sees the comment, so they still loaded, and ../weapon_templates/weapon_templates.lua does not exist, so
this script never loaded (in-game: AVF's "mountedGun" prompt, no gun). Removed: weapon_templates.lua (missing) and
../../scripts/avf_custom.lua (v1 AVF glue).
]]

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
		["GPMG"] = {	
					cfgWeapon = {
						component="gun", 
						weaponType="customMG",
						group="2",
						interact="mountedGun",
						commander = true,
						avf_barrel_coords_true = true

					},
					template = "GPMG"
				},	
		["main_GPMG"] = {	
					cfgWeapon = {
						component="gun", 
						weaponType="customMG",
						group="1",
						interact="mountedGun",
						commander = true,
						avf_barrel_coords_true = true

					},
					template = "GPMG"
				},	
		["main_MILAN"] = {	
					cfgWeapon = {
						component="gun", 
						weaponType="simple_cannon",
						group="1",
						interact="mountedGun",
						commander = true,
						avf_barrel_coords_true = true

					},
					template = "MILAN_02"
				},	
		["GMG"] = {	
					cfgWeapon = {
						component="gun", 
						weaponType="customMG",
						group="1",
						interact="mountedGun",
						commander = true,
						avf_barrel_coords_true = true

					},
					template = "GMG"
				},	
		["mainCannon"] = {	
					cfgWeapon = {
						component="gun", 
						weaponType="customMG",
						group="1",
						interact="mountedGun",
						commander = true,
						avf_barrel_coords_true = true

					},
					template = "L1A1_2"
				},	
	},
}
	

	---- magazine num _ val
	---- barrels num value

vehicle = {

}


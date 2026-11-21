#version 2
DL_LABEL = "Offroad_armed"  -- crash breadcrumbs (lib/DeleteLog.lua)
#include "../../../../lib/DeleteLog.lua"
#include "script/include/player.lua"
#include "../../../MountedGun.lua"
-- (v2, 2026-11-13) armed offroads (offroad_GMG / GPMG / NSV / m2.xml; only the GMG one is reached in play: road spawn
-- VehicleM22). As the WMIK (Offroad_WMIK.lua): the original's include lines stood inside a comment, Teardown loaded
-- them anyway and ../weapon_templates/weapon_templates.lua does not exist, so this script never loaded in the original
-- (the gun shape has no AVF gun tags: what the external AVF made of it is unknown). The "GMG" template it names never existed either: MountedGunConfig is new, AVF's
-- MK-19 grenade machine gun (weapons.lua "mk19": RPM 400, 60 grenades, reload 4, dispersion 12) with AVF's grenade
-- shell (ammo.lua "G_30mm_HE": 120 m/s, HE). Standing gunner place in the roof ring; the driver does not fire.
-- The GPMG / NSV / m2 offroads (spawned nowhere) have other gun tags: no gun found there, as before.
MountedGunGunTag = "GMG"
-- the gunner passes through the offroad's own shapes and is held at the place (MountedGun.lua: the roof's crossbar
-- sits at the gunner's waist; in-game 2026-11-13 the gunner bobbed up and down)
MountedGunHoldGunner = true
MountedGunEmitterTag = "GMG_emitter"
MountedGunSound = "MOD/vehicles/avf/assets/sounds/grenade_mg/single_shot_01.ogg" -- AVF's grenade launcher shot (copied)
MountedGunConfig = {
	name = "GMG",
	weaponType = "cannon",
	caliber = 30,
	RPM = 400,
	reload = 4,
	dispersion = 12,
	magazines = {
		[1] = {
			name = "G_30mm_HE",
			displayName = "HE grenade",
			magazineCapacity = 60,
			magazineCount = 1,
		},
	},
}
--[[
(v2) removed from this comment: the original's include lines (weapon_templates.lua: missing; avf_custom.lua: v1 AVF).
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
		["NSV"] = {	
					cfgWeapon = {
						component="gun", 
						weaponType="customMG",
						group="2",
						interact="mountedGun",
						commander = true,
						avf_barrel_coords_true = true

					},
					template = "NSV"
				},	
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
					template = "GPMG_02"
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
		["GMG_01"] = {	
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
		["GMG"] = {	
					cfgWeapon = {
						component="gun", 
						weaponType="customMG",
						group="1",
						interact="mountedGun",
						commander = true,
						avf_barrel_coords_true = true

					},
					template = "GMG_02"
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
					template = "KSP_88"
				},	
	},
}
	

	---- magazine num _ val
	---- barrels num value

vehicle = {

}


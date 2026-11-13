#version 2
#include "script/include/player.lua"
#include "../../scripts/MountedGun.lua"
-- (v2, 2026-11-13) AVF's "simple" config: no gun settings of its own, the gun is AVF's weapon type named by the gun
-- shape's XML tag weaponType. In play: the Kornet (9M133 ATGM) and AGS-30 (grenade machine gun) tripods placed on
-- road segment L1 (also BMD-2 D, type 63 artillery: spawned nowhere). v1 included avf_custom.lua (the external AVF
-- mod). Now our own mounted-gun script with AVF's shells (scripts/avf); weapon, ammo and sound from AVF's weapon type.
-- The tripods are gun emplacements, no longer vehicles (add_seats.py EMPLACEMENTS, user 2026-11-13: only the "Use
-- mounted gun" prompt): a standing gunner place behind the gun. MountedGunDriverFires: the driver of a vehicle using
-- this config works the gun while no gunner does (BMD-2 D, type 63; spawned nowhere). MountedGunKeepGrip: the
-- hands as laid out (the AGS-30's ammo box put the measured barrel line 0.2 m beside the tube).
MountedGunDriverFires = true
MountedGunKeepGrip = true
-- the gunner passes through the tripod while on the gun and is held at the place (MountedGun.lua; in-game
-- 2026-11-13 the AGS-30's gunner, right behind the gun, was pushed 0.25 m off the place)
MountedGunHoldGunner = true


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
			exists = 1,


		},

	},
}


	---- magazine num _ val
	---- barrels num value

vehicle = {

}

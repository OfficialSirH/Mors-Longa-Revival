LootsPath = "MOD/prefabs/spawnables/loots/"


-- Start with pistols, then smgs, then shotguns, rifles, snipers,
GunClassUnlocks_MaxDist = 3000 -- Everything is unlocked at this point.
-- GunClassUnlocks_FadeRange = 1
-- GunClassUnlocks_Curve_Progress = 0.5
-- GunClassUnlocks_Curve_PrefabsSelectios = 0.5


-- Weapons are unlocked mostly by the order of this list.
GUN_CLASSES = {
	pistol  = "pistol",
	smg     = "smg",
	shotgun = "shotgun",
	rpg     = "rpg",   --todo make rpg all techs.
	rifle   = "rifle",
	sniper  = "sniper",
}

GUN_TECHS = {
	high = "high", -- Highest grade - Medvedev Mil
	mid  = "mid",  -- Mid grade - N4A1,     Vector
	low  = "low",  -- Low grade - Medvedev, AKs, Sawedoff
}

--todo Link factions to groups of npc teams. Some factions/teams should share guns. Until then, use tech groups for each faction.
GUN_FACTIONS = {
	civ  = { GUN_TECHS.low  },
	cult = { GUN_TECHS.low  },
	um   = { GUN_TECHS.mid  },
	mil  = { GUN_TECHS.high },
}

GunClassUnlocks = DeepCopy(GUN_CLASSES)



GUN_PREFABS = {}

function init_gun_prefabs()

	-- GUN_PREFABS = BuildSelfReferencingTable({"class", "faction", "tech"})

	--=====Civilian (Insurgents)=====
	CreateGunPrefabs_Civ()

	-- =====Alashyan Military=====
	CreateGunPrefabs_Mil()

	-- =====UM (United Mates)=====
	CreateGunPrefabs_UM()

end

--# Manage_ only for tables
---Sets the table of usable gun classes based on distance travelled.
function tick_gun_class_unlocking()

	GunClassUnlocks = {}


	local last_index = GetTableSize(GUN_CLASSES)

	local progress = GetFloat("savegame.mod.distanceProgressed")
	local progress_scaled = progress / GunClassUnlocks_MaxDist

	local unlocked_indexes = (progress_scaled * last_index)
	local unlock_phase = unlocked_indexes % 1

	-- Fade classes evenly.
	if unlock_phase > math.random() then
		unlocked_indexes = unlocked_indexes + 1
	end


	-- Extra random luck.
	if math.random() < 0.1 then
		unlocked_indexes = clamp(math.ceil(unlocked_indexes), 1, last_index)
	end


	-- Random chance based selection.
	-- if math.random() < 0.01 then

		for index, value in ipairs({ --idea random order progressions.
			"pistol",
			"shotgun",
			"smg",
			"rpg",
			"rifle",
			"sniper",
		}) do

			if index <= unlocked_indexes then
				table.insert(GunClassUnlocks, GUN_CLASSES[value])
			end

		end

		if #GunClassUnlocks < 1 then
			table.insert(GunClassUnlocks, "pistol")
		end

		-- DebugWatch("progress", progress)
		-- DebugWatch("GunClassUnlocks_MaxDist", GunClassUnlocks_MaxDist)
		-- DebugWatch("unlock_phase", unlock_phase)
		-- DebugWatch("unlocked_indexes", unlocked_indexes)
		-- DebugWatch("last_index", last_index)
 		-- DebugWatch("Unlocked NPC guns", table.concat(GunClassUnlocks, ", "))

	-- end

end



function create_gun_prefab(gun_root, gun_path, ammo_path, class, faction, tech)

	local gun_prefab = {
		gun_root = gun_root,
		gun_path = gun_path,
		ammo_path = ammo_path,
		class = class,
		faction = faction,
		tech = tech,
	}

	table.insert(GUN_PREFABS, gun_prefab)

end

---Try a few searches to find specified gun.
function get_random_gun_prefab(attributes)

	TableShuffleInPlace(GUN_PREFABS) -- Randomize order.

	--todo We will have to do it the slow and retarded way for now until I fix the attributes based selector. This is just so it works for release.
	for _, gun in ipairs(GUN_PREFABS) do

		local _, faction_value = TableContainsValue(attributes.faction, gun.tech)

		if attributes.class == gun.class and faction_value then
			if config.db then
				print("NPC", "Specified gun found: ", string_pad(gun.gun_path, 25), "gun.class", gun.class, "faction", faction_value)
			end
			return gun
		end

	end

end

RootGuns = {
	CZ_1012 = "CZ-1012",
    Drozdov = "Drozdov",
    Jalaad = "Jalaad",
    Kovalyov_545 = "Kovalyov-545",
    Kovalyov_762 = "Kovalyov-762",
    KS23 = "KS23",
    MC308 = "MC308",
    MC9 = "MC9",
    Medvedev = "Medvedev",
    MK36 = "MK36",
    Mudafie = "Mudafie",
    N107 = "N107",
    N16 = "N16",
    N4A1 = "N4A1",
    N870 = "N870",
    P17 = "P17",
    P17A = "P17A",
    PPSH41 = "PPSH41",
    Qasira = "Qasira",
    RPG = "RPG",
    SCALAR = "SCALAR",
    Simonov_105 = "Simonov-105",
    Simonov_106 = "Simonov-106",
    Simonov_545 = "Simonov-545",
    Simonov_545U = "Simonov-545U",
    Simonov_762 = "Simonov-762",
    Simonov_9 = "Simonov-9",
    SKS = "SKS",
    SV98 = "SV98",
    TCP_57 = "TCP-57",
    TCR_308 = "TCR-308",
    TCR_556 = "TCR-556",
    TMP_90 = "TMP-90",
    TT_33 = "TT-33",
}

function CreateGunPrefabs_Civ()

	create_gun_prefab(RootGuns.RPG, "Gun RPG.xml", "ROCKET #0.xml",
		GUN_CLASSES.rpg,
		GUN_FACTIONS.civ,
		GUN_TECHS.low)

	create_gun_prefab(RootGuns.RPG, "Gun RPG.xml", "ROCKET #3.xml",
		GUN_CLASSES.rpg,
		GUN_FACTIONS.um,
		GUN_TECHS.low)

--------Shotgun----------

	create_gun_prefab(RootGuns.CZ_1012, "Gun CZ-1012.xml", "Ammo 12GA BS.xml",
		GUN_CLASSES.shotgun,
		GUN_FACTIONS.civ,
		GUN_TECHS.low)

	create_gun_prefab(RootGuns.Qasira, "Gun Qasira.xml", "Ammo 12GA BS.xml",
		GUN_CLASSES.shotgun,
		GUN_FACTIONS.civ,
		GUN_TECHS.low)

	create_gun_prefab(RootGuns.Mudafie, "Gun Mudafie.xml", "Ammo 12GA BS.xml",
		GUN_CLASSES.shotgun,
		GUN_FACTIONS.civ,
		GUN_TECHS.low)

	create_gun_prefab(RootGuns.Mudafie, "Gun Mudafie 1.xml", "Ammo 12GA BS.xml",
		GUN_CLASSES.shotgun,
		GUN_FACTIONS.civ,
		GUN_TECHS.low)

	create_gun_prefab(RootGuns.KS23, "Gun KS23.xml", "Ammo 4GA BS.xml",
		GUN_CLASSES.shotgun,
		GUN_FACTIONS.civ,
		GUN_TECHS.mid)

--------Rifle----------

	create_gun_prefab(RootGuns.N16, "Gun N16.xml", "Ammo 5.56 FMJ.xml",
		GUN_CLASSES.rifle,
		GUN_FACTIONS.civ,
		GUN_TECHS.low)

	create_gun_prefab(RootGuns.Kovalyov_762, "Gun Kovalyov-762.xml", "Ammo 7.62x39 FMJ.xml",
		GUN_CLASSES.rifle,
		GUN_FACTIONS.civ,
		GUN_TECHS.low)

	create_gun_prefab(RootGuns.Kovalyov_545, "Gun Kovalyov-545.xml", "Ammo 5.45 FMJ.xml",
		GUN_CLASSES.rifle,
		GUN_FACTIONS.civ,
		GUN_TECHS.low)

	create_gun_prefab(RootGuns.Simonov_105, "Gun Simonov-105.xml", "Ammo 5.45 FMJ.xml",
		GUN_CLASSES.rifle,
		GUN_FACTIONS.civ,
		GUN_TECHS.low)

	create_gun_prefab(RootGuns.Simonov_106, "Gun Simonov-106.xml", "Ammo 5.45 FMJ.xml",
		GUN_CLASSES.rifle,
		GUN_FACTIONS.civ,
		GUN_TECHS.low)

	create_gun_prefab(RootGuns.Simonov_545, "Gun Simonov-545.xml", "Ammo 5.45 FMJ.xml",
		GUN_CLASSES.rifle,
		GUN_FACTIONS.civ,
		GUN_TECHS.mid)

	create_gun_prefab(RootGuns.Simonov_762, "Gun Simonov-762.xml", "Ammo 7.62x39 FMJ.xml",
		GUN_CLASSES.rifle,
		GUN_FACTIONS.civ,
		GUN_TECHS.mid)

	create_gun_prefab(RootGuns.MC308, "Gun MC308.xml", "Ammo 7.62x51 FMJ.xml",
		GUN_CLASSES.rifle,
		GUN_FACTIONS.civ,
		GUN_TECHS.low)
		
	create_gun_prefab(RootGuns.MC308, "Gun MC308 COMPACT1.xml", "Ammo 7.62x51 FMJ.xml",
		GUN_CLASSES.rifle,
		GUN_FACTIONS.civ,
		GUN_TECHS.low)

	create_gun_prefab(RootGuns.MC308, "Gun MC308 COMPACT2.xml", "Ammo 7.62x51 FMJ.xml",
		GUN_CLASSES.rifle,
		GUN_FACTIONS.civ,
		GUN_TECHS.low)

	create_gun_prefab(RootGuns.SKS, "Gun SKS.xml", "Ammo 7.62x39 FMJ.xml",
		GUN_CLASSES.rifle,
		GUN_FACTIONS.civ,
		GUN_TECHS.low)

	create_gun_prefab(RootGuns.SKS, "Gun SKS1.xml", "Ammo 7.62x39 FMJ.xml",
		GUN_CLASSES.rifle,
		GUN_FACTIONS.civ,
		GUN_TECHS.low)

	create_gun_prefab(RootGuns.SKS, "Gun SKS2.xml", "Ammo 7.62x39 FMJ.xml",
		GUN_CLASSES.rifle,
		GUN_FACTIONS.civ,
		GUN_TECHS.low)

	create_gun_prefab(RootGuns.SKS, "Gun SKS3.xml", "Ammo 7.62x39 FMJ.xml",
		GUN_CLASSES.rifle,
		GUN_FACTIONS.civ,
		GUN_TECHS.low)

	create_gun_prefab(RootGuns.SKS, "Gun SKS4.xml", "Ammo 7.62x39 FMJ.xml",
		GUN_CLASSES.rifle,
		GUN_FACTIONS.civ,
		GUN_TECHS.low)

	create_gun_prefab(RootGuns.SKS, "Gun SKS5.xml", "Ammo 7.62x39 FMJ.xml",
		GUN_CLASSES.rifle,
		GUN_FACTIONS.civ,
		GUN_TECHS.low)

	create_gun_prefab(RootGuns.SKS, "Gun SKS6.xml", "Ammo 7.62x39 FMJ.xml",
		GUN_CLASSES.rifle,
		GUN_FACTIONS.civ,
		GUN_TECHS.low)

	create_gun_prefab(RootGuns.SKS, "Gun SKS7.xml", "Ammo 7.62x39 FMJ.xml",
		GUN_CLASSES.rifle,
		GUN_FACTIONS.civ,
		GUN_TECHS.low)

	create_gun_prefab(RootGuns.SKS, "Gun SKS8.xml", "Ammo 7.62x39 FMJ.xml",
		GUN_CLASSES.rifle,
		GUN_FACTIONS.civ,
		GUN_TECHS.low)

	create_gun_prefab(RootGuns.SKS, "Gun SKS PSO.xml", "Ammo 7.62x39 FMJ.xml",
		GUN_CLASSES.rifle,
		GUN_FACTIONS.civ,
		GUN_TECHS.low)

	create_gun_prefab(RootGuns.N4A1, "Gun N4A1 CIV.xml", "Ammo 5.56 FMJ.xml",
		GUN_CLASSES.rifle,
		GUN_FACTIONS.civ,
		GUN_TECHS.low)

	create_gun_prefab(RootGuns.N4A1, "Gun N4A1 CIV1.xml", "Ammo 5.56 FMJ.xml",
		GUN_CLASSES.rifle,
		GUN_FACTIONS.civ,
		GUN_TECHS.low)

	create_gun_prefab(RootGuns.N4A1, "Gun N4A1 CIV2.xml", "Ammo 5.56 FMJ.xml",
		GUN_CLASSES.rifle,
		GUN_FACTIONS.civ,
		GUN_TECHS.low)

--------Sniper----------

	create_gun_prefab(RootGuns.Medvedev, "Gun Medvedev.xml", "Ammo 7.62x54R FMJ.xml",
		GUN_CLASSES.sniper,
		GUN_FACTIONS.civ,
		GUN_TECHS.low)

	create_gun_prefab(RootGuns.Medvedev, "Gun Medvedev SUPPRESSED.xml", "Ammo 7.62x54R FMJ.xml",
		GUN_CLASSES.sniper,
		GUN_FACTIONS.civ,
		GUN_TECHS.mid)

	create_gun_prefab(RootGuns.Medvedev, "Gun Medvedev SNIPER SUPPRESSED.xml", "Ammo 7.62x54R FMJ.xml",
		GUN_CLASSES.sniper,
		GUN_FACTIONS.civ,
		GUN_TECHS.low)

	create_gun_prefab(RootGuns.Drozdov, "Gun Drozdov SNIPER.xml", "Ammo 7.62x54R FMJ.xml",
		GUN_CLASSES.sniper,
		GUN_FACTIONS.civ,
		GUN_TECHS.low)

	create_gun_prefab(RootGuns.Drozdov, "Gun Drozdov.xml", "Ammo 7.62x54R FMJ.xml",
		GUN_CLASSES.sniper,
		GUN_FACTIONS.civ,
		GUN_TECHS.low)

	create_gun_prefab(RootGuns.Drozdov, "Gun Drozdov1.xml", "Ammo 7.62x54R FMJ.xml",
		GUN_CLASSES.sniper,
		GUN_FACTIONS.civ,
		GUN_TECHS.low)

	create_gun_prefab(RootGuns.Drozdov, "Gun Drozdov2.xml", "Ammo 7.62x54R FMJ.xml",
		GUN_CLASSES.sniper,
		GUN_FACTIONS.civ,
		GUN_TECHS.low)

	create_gun_prefab(RootGuns.Medvedev, "Gun Medvedev.xml", "Ammo 7.62x54R FMJ.xml",

		GUN_CLASSES.sniper,
		GUN_FACTIONS.civ,
		GUN_TECHS.low)

	create_gun_prefab(RootGuns.Jalaad, "Gun Jalaad.xml", "Ammo 127x99 AP.xml",

		GUN_CLASSES.sniper,
		GUN_FACTIONS.civ,
		GUN_TECHS.low)

--------Pistol----------

	create_gun_prefab(RootGuns.TT_33, "Gun TT-33.xml", "Ammo 7.62x25 FMJ.xml",
		GUN_CLASSES.pistol,
		GUN_FACTIONS.civ,
		GUN_TECHS.low)

	create_gun_prefab(RootGuns.TT_33, "Gun TT-33 1.xml", "Ammo 7.62x25 FMJ.xml",
		GUN_CLASSES.pistol,
		GUN_FACTIONS.civ,
		GUN_TECHS.low)

	create_gun_prefab(RootGuns.TT_33, "Gun TT-33 2.xml", "Ammo 7.62x25 FMJ.xml",
		GUN_CLASSES.pistol,
		GUN_FACTIONS.civ,
		GUN_TECHS.low)

	create_gun_prefab(RootGuns.TT_33, "Gun TT-33 3.xml", "Ammo 7.62x25 FMJ.xml",
		GUN_CLASSES.pistol,
		GUN_FACTIONS.civ,
		GUN_TECHS.low)

	create_gun_prefab(RootGuns.TT_33, "Gun TT-33 4.xml", "Ammo 7.62x25 FMJ.xml",
		GUN_CLASSES.pistol,
		GUN_FACTIONS.civ,
		GUN_TECHS.low)

	create_gun_prefab(RootGuns.TT_33, "Gun TT-33 5.xml", "Ammo 7.62x25 FMJ.xml",
		GUN_CLASSES.pistol,
		GUN_FACTIONS.civ,
		GUN_TECHS.low)

	create_gun_prefab(RootGuns.TT_33, "Gun TT-33 6.xml", "Ammo 7.62x25 FMJ.xml",
		GUN_CLASSES.pistol,
		GUN_FACTIONS.civ,
		GUN_TECHS.low)

	create_gun_prefab(RootGuns.TT_33, "Gun TT-33 7.xml", "Ammo 7.62x25 FMJ.xml",
		GUN_CLASSES.pistol,
		GUN_FACTIONS.civ,
		GUN_TECHS.low)

	create_gun_prefab(RootGuns.TT_33, "Gun TT-33 8.xml", "Ammo 7.62x25 FMJ.xml",
		GUN_CLASSES.pistol,
		GUN_FACTIONS.civ,
		GUN_TECHS.low)

-----SMG----------

	create_gun_prefab(RootGuns.Simonov_545U, "Gun Simonov-545U.xml", "Ammo 5.45 FMJ.xml",
		GUN_CLASSES.smg,
		GUN_FACTIONS.civ,
		GUN_TECHS.mid)

	create_gun_prefab(RootGuns.PPSH41, "Gun PPSH41.xml", "Ammo 7.62x25 FMJ.xml",
		GUN_CLASSES.smg,
		GUN_FACTIONS.civ,
		GUN_TECHS.low)
		
	create_gun_prefab(RootGuns.PPSH41, "Gun PPSH41 Extended.xml", "Ammo 7.62x25 FMJ.xml",
		GUN_CLASSES.smg,
		GUN_FACTIONS.civ,
		GUN_TECHS.low)
end

function CreateGunPrefabs_UM()
	create_gun_prefab(RootGuns.RPG, "Gun RPG.xml", "ROCKET #0.xml",
		GUN_CLASSES.rpg,
		GUN_FACTIONS.um,
		GUN_TECHS.mid)

	create_gun_prefab(RootGuns.RPG, "Gun RPG.xml", "ROCKET #1.xml",
		GUN_CLASSES.rpg,
		GUN_FACTIONS.um,
		GUN_TECHS.low)

	create_gun_prefab(RootGuns.RPG, "Gun RPG.xml", "ROCKET #2.xml",
		GUN_CLASSES.rpg,
		GUN_FACTIONS.um,
		GUN_TECHS.high)

	create_gun_prefab(RootGuns.N870, "Gun N870.xml", "Ammo 12GA BS.xml",
		GUN_CLASSES.shotgun,
		GUN_FACTIONS.um,
		GUN_TECHS.low)

-------SMG-Mid----------
	create_gun_prefab(RootGuns.MK36, "Gun MK36C.xml", "Ammo 5.56 FMJ.xml",
		GUN_CLASSES.smg,
		GUN_FACTIONS.um,
		GUN_TECHS.mid)

	create_gun_prefab(RootGuns.MK36, "Gun MK36C.xml", "Ammo 5.56 FMJ.xml",
		GUN_CLASSES.smg,
		GUN_FACTIONS.um,
		GUN_TECHS.mid)

	create_gun_prefab(RootGuns.SCALAR, "Gun SCALAR.xml", "Ammo 5.56 FMJ.xml",
		GUN_CLASSES.smg,
		GUN_FACTIONS.um,
		GUN_TECHS.mid)

	create_gun_prefab(RootGuns.SCALAR, "Gun SCALAR MILITARY1.xml", "Ammo 5.56 FMJ.xml",
		GUN_CLASSES.smg,
		GUN_FACTIONS.um,
		GUN_TECHS.mid)

	create_gun_prefab(RootGuns.TMP_90, "Gun TMP-90.xml", "Ammo 5.7x28 HP.xml",
		GUN_CLASSES.smg,
		GUN_FACTIONS.um,
		GUN_TECHS.mid)

--------SMG-High----------

	create_gun_prefab(RootGuns.SCALAR, "Gun SCALAR MILITARY2.xml", "Ammo 5.56 FMJ.xml",
		GUN_CLASSES.smg,
		GUN_FACTIONS.um,
		GUN_TECHS.high)

	create_gun_prefab(RootGuns.SCALAR, "Gun SCALAR MILITARY3.xml", "Ammo 5.56 FMJ.xml",
		GUN_CLASSES.smg,
		GUN_FACTIONS.um,
		GUN_TECHS.high)

	create_gun_prefab(RootGuns.SCALAR, "Gun SCALAR MILITARY4.xml", "Ammo 5.56 FMJ.xml",
		GUN_CLASSES.smg,
		GUN_FACTIONS.um,
		GUN_TECHS.high)

	create_gun_prefab(RootGuns.SCALAR, "Gun SCALAR MILITARY5.xml", "Ammo 5.56 FMJ.xml",
		GUN_CLASSES.smg,
		GUN_FACTIONS.um,
		GUN_TECHS.high)

	create_gun_prefab(RootGuns.MK36, "Gun MK36C MILITARY1.xml", "Ammo 5.56 FMJ.xml",
		GUN_CLASSES.smg,
		GUN_FACTIONS.um,
		GUN_TECHS.high)

	create_gun_prefab(RootGuns.MK36, "Gun MK36C MILITARY2.xml", "Ammo 5.56 FMJ.xml",
		GUN_CLASSES.smg,
		GUN_FACTIONS.um,
		GUN_TECHS.high)

	create_gun_prefab(RootGuns.TMP_90, "Gun TMP-90 MILITARY1.xml", "Ammo 5.7x28 HP.xml",
		GUN_CLASSES.smg,
		GUN_FACTIONS.um,
		GUN_TECHS.mid)

	create_gun_prefab(RootGuns.TMP_90, "Gun TMP-90 MILITARY2.xml", "Ammo 5.7x28 HP.xml",
		GUN_CLASSES.smg,
		GUN_FACTIONS.um,
		GUN_TECHS.mid)

	create_gun_prefab(RootGuns.TMP_90, "Gun TMP-90 MILITARY3.xml", "Ammo 5.7x28 HP.xml",
		GUN_CLASSES.smg,
		GUN_FACTIONS.um,
		GUN_TECHS.mid)



--------Rifle-Mid----------

	create_gun_prefab(RootGuns.MK36, "Gun MK36.xml", "Ammo 5.56 FMJ.xml",
		GUN_CLASSES.rifle,
		GUN_FACTIONS.um,
		GUN_TECHS.mid)

	create_gun_prefab(RootGuns.MK36, "Gun MK36 MILITARY1.xml", "Ammo 5.56 FMJ.xml",
		GUN_CLASSES.rifle,
		GUN_FACTIONS.um,
		GUN_TECHS.mid)

	create_gun_prefab(RootGuns.MK36, "Gun MK36 MILITARY2.xml", "Ammo 5.56 FMJ.xml",
		GUN_CLASSES.rifle,
		GUN_FACTIONS.um,
		GUN_TECHS.mid)

	create_gun_prefab(RootGuns.N4A1, "Gun N4A1 MILITARY1.xml", "Ammo 5.56 FMJ.xml",
		GUN_CLASSES.rifle,
		GUN_FACTIONS.um,
		GUN_TECHS.mid)

	create_gun_prefab(RootGuns.N4A1, "Gun N4A1 STANDARD.xml", "Ammo 5.56 FMJ.xml",
		GUN_CLASSES.rifle,
		GUN_FACTIONS.um,
		GUN_TECHS.mid)

	create_gun_prefab(RootGuns.N4A1, "Gun N4A1.xml", "Ammo 5.56 FMJ.xml",
		GUN_CLASSES.rifle,
		GUN_FACTIONS.um,
		GUN_TECHS.mid)

	create_gun_prefab(RootGuns.N16, "Gun N16 Scope.xml", "Ammo 5.56 FMJ.xml",
		GUN_CLASSES.rifle,
		GUN_FACTIONS.um,
		GUN_TECHS.mid)

	create_gun_prefab(RootGuns.TCR_556, "Gun TCR-556 Grey.xml", "Ammo 5.56 FMJ.xml",
		GUN_CLASSES.rifle,
		GUN_FACTIONS.um,
		GUN_TECHS.mid)

	create_gun_prefab(RootGuns.TCR_556, "Gun TCR-556 MILITARY1.xml", "Ammo 5.56 FMJ.xml",
		GUN_CLASSES.rifle,
		GUN_FACTIONS.um,
		GUN_TECHS.mid)

	create_gun_prefab(RootGuns.TCR_556, "Gun TCR-556 MILITARY2.xml", "Ammo 5.56 FMJ.xml",
		GUN_CLASSES.rifle,
		GUN_FACTIONS.um,
		GUN_TECHS.mid)

	create_gun_prefab(RootGuns.TCR_556, "Gun TCR-556.xml", "Ammo 5.56 FMJ.xml",
		GUN_CLASSES.rifle,
		GUN_FACTIONS.um,
		GUN_TECHS.mid)

	create_gun_prefab(RootGuns.MK36, "Gun MK36.xml", "Ammo 5.56 FMJ.xml",
		GUN_CLASSES.rifle,
		GUN_FACTIONS.um,
		GUN_TECHS.mid)

--------Rifle-High----------

	create_gun_prefab(RootGuns.TCR_308, "Gun TCR-308 Grey.xml", "Ammo 7.62x51 FMJ.xml",
		GUN_CLASSES.rifle,
		GUN_FACTIONS.um,
		GUN_TECHS.high)

	create_gun_prefab(RootGuns.TCR_308, "Gun TCR-308 MILITARY1.xml", "Ammo 7.62x51 FMJ.xml",
		GUN_CLASSES.rifle,
		GUN_FACTIONS.um,
		GUN_TECHS.high)

	create_gun_prefab(RootGuns.TCR_308, "Gun TCR-308.xml", "Ammo 7.62x51 FMJ.xml",
		GUN_CLASSES.rifle,
		GUN_FACTIONS.um,
		GUN_TECHS.high)

	create_gun_prefab(RootGuns.N4A1, "Gun N4A1 SOPMOD.xml", "Ammo 5.56 FMJ.xml",

		GUN_CLASSES.rifle,
		GUN_FACTIONS.um,
		GUN_TECHS.high)

------Sniper-Mid------------

	create_gun_prefab(RootGuns.TCR_308, "Gun TCR-308 SNIPER.xml", "Ammo 7.62x51 FMJ.xml",
		GUN_CLASSES.sniper,
		GUN_FACTIONS.um,
		GUN_TECHS.mid)

------Sniper-High------------

	create_gun_prefab(RootGuns.N107, "Gun N107.xml", "Ammo 127x99 AP.xml",
		GUN_CLASSES.sniper,
		GUN_FACTIONS.um,
		GUN_TECHS.high)

	create_gun_prefab(RootGuns.N107, "Gun N107 MILITARY1.xml", "Ammo 127x99 AP.xml",
		GUN_CLASSES.sniper,
		GUN_FACTIONS.um,
		GUN_TECHS.high)

	create_gun_prefab(RootGuns.N107, "Gun N107 MILITARY2.xml", "Ammo 127x99 AP.xml",
		GUN_CLASSES.sniper,
		GUN_FACTIONS.um,
		GUN_TECHS.high)

	create_gun_prefab(RootGuns.N107, "Gun N107 MILITARY3.xml", "Ammo 127x99 AP.xml",
		GUN_CLASSES.sniper,
		GUN_FACTIONS.um,
		GUN_TECHS.high)

	create_gun_prefab(RootGuns.TCR_308, "Gun TCR-308 SNIPER.xml", "Ammo 7.62x51 FMJ.xml",
		GUN_CLASSES.sniper,
		GUN_FACTIONS.um,
		GUN_TECHS.high)

	create_gun_prefab(RootGuns.N107, "Gun N107 MILITARY4.xml", "Ammo 127x99 AP.xml",
		GUN_CLASSES.sniper,
		GUN_FACTIONS.um,
		GUN_TECHS.high)

	create_gun_prefab(RootGuns.N107, "Gun N107 MILITARY5.xml", "Ammo 127x99 AP.xml",
		GUN_CLASSES.sniper,
		GUN_FACTIONS.um,
		GUN_TECHS.high)

------Shotgun-Mid------------

	create_gun_prefab(RootGuns.N870, "Gun N870.xml", "Ammo 12GA BS.xml",
		GUN_CLASSES.shotgun,
		GUN_FACTIONS.um,
		GUN_TECHS.mid)

------Shotgun-High------------

	create_gun_prefab(RootGuns.N870, "Gun N870 MILITARY1.xml", "Ammo 12GA BS.xml",
		GUN_CLASSES.shotgun,
		GUN_FACTIONS.um,
		GUN_TECHS.high)

	create_gun_prefab(RootGuns.N870, "Gun N870 MILITARY2.xml", "Ammo 12GA BS.xml",
		GUN_CLASSES.shotgun,
		GUN_FACTIONS.um,
		GUN_TECHS.high)
		
	create_gun_prefab(RootGuns.N870, "Gun N870 MILITARY3.xml", "Ammo 12GA BS.xml",
		GUN_CLASSES.shotgun,
		GUN_FACTIONS.um,
		GUN_TECHS.high)

--------Pistol-Mid----------
	create_gun_prefab(RootGuns.P17, "Gun P17.xml", "Ammo 9x19 FMJ.xml",
		GUN_CLASSES.pistol,
		GUN_FACTIONS.um,
		GUN_TECHS.mid)

	create_gun_prefab(RootGuns.P17, "Gun P17 TAN1.xml", "Ammo 9x19 FMJ.xml",
		GUN_CLASSES.pistol,
		GUN_FACTIONS.um,
		GUN_TECHS.mid)

	create_gun_prefab(RootGuns.P17, "Gun P17 Green1.xml", "Ammo 9x19 FMJ.xml",
		GUN_CLASSES.pistol,
		GUN_FACTIONS.um,
		GUN_TECHS.mid)

	create_gun_prefab(RootGuns.P17, "Gun P17 Grey.xml", "Ammo 9x19 FMJ.xml",
		GUN_CLASSES.pistol,
		GUN_FACTIONS.um,
		GUN_TECHS.mid)

	create_gun_prefab(RootGuns.P17, "Gun P17 1.xml", "Ammo 9x19 FMJ.xml",
		GUN_CLASSES.pistol,
		GUN_FACTIONS.um,
		GUN_TECHS.mid)

	create_gun_prefab(RootGuns.P17, "Gun P17 2.xml", "Ammo 9x19 FMJ.xml",
		GUN_CLASSES.pistol,
		GUN_FACTIONS.um,
		GUN_TECHS.mid)

	create_gun_prefab(RootGuns.P17, "Gun P17 TAN.xml", "Ammo 9x19 FMJ.xml",
		GUN_CLASSES.pistol,
		GUN_FACTIONS.um,
		GUN_TECHS.mid)

	create_gun_prefab(RootGuns.P17, "Gun P17 Green.xml", "Ammo 9x19 FMJ.xml",
		GUN_CLASSES.pistol,
		GUN_FACTIONS.um,
		GUN_TECHS.mid)

	create_gun_prefab(RootGuns.P17, "Gun P17 Grey.xml", "Ammo 9x19 FMJ.xml",
		GUN_CLASSES.pistol,
		GUN_FACTIONS.um,
		GUN_TECHS.mid)

	create_gun_prefab(RootGuns.P17, "Gun P17 TAN3.xml", "Ammo 9x19 FMJ.xml",
		GUN_CLASSES.pistol,
		GUN_FACTIONS.um,
		GUN_TECHS.mid)

	create_gun_prefab(RootGuns.P17, "Gun P17 Green3.xml", "Ammo 9x19 FMJ.xml",
		GUN_CLASSES.pistol,
		GUN_FACTIONS.um,
		GUN_TECHS.mid)

	create_gun_prefab(RootGuns.P17, "Gun P17 Grey3.xml", "Ammo 9x19 FMJ.xml",
		GUN_CLASSES.pistol,
		GUN_FACTIONS.um,
		GUN_TECHS.mid)

	create_gun_prefab(RootGuns.TCP_57, "Gun TCP-57.xml", "Ammo 5.7x28 HP.xml",
		GUN_CLASSES.pistol,
		GUN_FACTIONS.um,
		GUN_TECHS.mid)

	create_gun_prefab(RootGuns.TCP_57, "Gun TCP-57 GREY.xml", "Ammo 5.7x28 HP.xml",
		GUN_CLASSES.pistol,
		GUN_FACTIONS.um,
		GUN_TECHS.mid)


--------Pistol-High----------
	create_gun_prefab(RootGuns.P17A, "Gun P17A.xml", "Ammo 9x19 FMJ.xml",
		GUN_CLASSES.pistol,
		GUN_FACTIONS.mil,
		GUN_TECHS.high)

	create_gun_prefab(RootGuns.P17A, "Gun P17A 1.xml", "Ammo 9x19 FMJ.xml",
		GUN_CLASSES.pistol,
		GUN_FACTIONS.mil,
		GUN_TECHS.high)

	create_gun_prefab(RootGuns.P17A, "Gun P17A 2.xml", "Ammo 9x19 FMJ.xml",
		GUN_CLASSES.pistol,
		GUN_FACTIONS.mil,
		GUN_TECHS.high)

	create_gun_prefab(RootGuns.P17A, "Gun P17A 3.xml", "Ammo 9x19 FMJ.xml",
		GUN_CLASSES.pistol,
		GUN_FACTIONS.mil,
		GUN_TECHS.high)

	create_gun_prefab(RootGuns.P17A, "Gun P17A Grey.xml", "Ammo 9x19 FMJ.xml",
		GUN_CLASSES.pistol,
		GUN_FACTIONS.mil,
		GUN_TECHS.high)

	create_gun_prefab(RootGuns.P17A, "Gun P17A Grey1.xml", "Ammo 9x19 FMJ.xml",
		GUN_CLASSES.pistol,
		GUN_FACTIONS.mil,
		GUN_TECHS.high)

	create_gun_prefab(RootGuns.P17A, "Gun P17A Grey2.xml", "Ammo 9x19 FMJ.xml",
		GUN_CLASSES.pistol,
		GUN_FACTIONS.mil,
		GUN_TECHS.high)

	create_gun_prefab(RootGuns.P17A, "Gun P17A Grey3.xml", "Ammo 9x19 FMJ.xml",
		GUN_CLASSES.pistol,
		GUN_FACTIONS.mil,
		GUN_TECHS.high)

	create_gun_prefab(RootGuns.P17A, "Gun P17A TAN.xml", "Ammo 9x19 FMJ.xml",
		GUN_CLASSES.pistol,
		GUN_FACTIONS.mil,
		GUN_TECHS.high)

	create_gun_prefab(RootGuns.P17A, "Gun P17A TAN1.xml", "Ammo 9x19 FMJ.xml",
		GUN_CLASSES.pistol,
		GUN_FACTIONS.mil,
		GUN_TECHS.high)

	create_gun_prefab(RootGuns.P17A, "Gun P17A TAN2.xml", "Ammo 9x19 FMJ.xml",
		GUN_CLASSES.pistol,
		GUN_FACTIONS.mil,
		GUN_TECHS.high)

	create_gun_prefab(RootGuns.P17A, "Gun P17A TAN3.xml", "Ammo 9x19 FMJ.xml",
		GUN_CLASSES.pistol,
		GUN_FACTIONS.mil,
		GUN_TECHS.high)

		create_gun_prefab(RootGuns.P17A, "Gun P17A Green.xml", "Ammo 9x19 FMJ.xml",
		GUN_CLASSES.pistol,
		GUN_FACTIONS.mil,
		GUN_TECHS.high)

	create_gun_prefab(RootGuns.P17A, "Gun P17A Green1.xml", "Ammo 9x19 FMJ.xml",
		GUN_CLASSES.pistol,
		GUN_FACTIONS.mil,
		GUN_TECHS.high)

	create_gun_prefab(RootGuns.P17A, "Gun P17A Green2.xml", "Ammo 9x19 FMJ.xml",
		GUN_CLASSES.pistol,
		GUN_FACTIONS.mil,
		GUN_TECHS.high)

	create_gun_prefab(RootGuns.P17A, "Gun P17A Green3.xml", "Ammo 9x19 FMJ.xml",
		GUN_CLASSES.pistol,
		GUN_FACTIONS.mil,
		GUN_TECHS.high)

	create_gun_prefab(RootGuns.P17A, "Gun P17 TAN2.xml", "Ammo 9x19 FMJ.xml",
		GUN_CLASSES.pistol,
		GUN_FACTIONS.mil,
		GUN_TECHS.high)

	create_gun_prefab(RootGuns.P17A, "Gun P17 Green2.xml", "Ammo 9x19 FMJ.xml",
		GUN_CLASSES.pistol,
		GUN_FACTIONS.mil,
		GUN_TECHS.high)

	create_gun_prefab(RootGuns.P17A, "Gun P17 Grey2.xml", "Ammo 9x19 FMJ.xml",
		GUN_CLASSES.pistol,
		GUN_FACTIONS.mil,
		GUN_TECHS.high)

	create_gun_prefab(RootGuns.P17A, "Gun P17 2.xml", "Ammo 9x19 FMJ.xml",
		GUN_CLASSES.pistol,
		GUN_FACTIONS.mil,
		GUN_TECHS.high)
end

function CreateGunPrefabs_Mil()
	create_gun_prefab(RootGuns.RPG , "Gun RPG.xml", "ROCKET #0.xml",
		GUN_CLASSES.rpg,
		GUN_FACTIONS.mil,
		GUN_TECHS.mid)

	create_gun_prefab(RootGuns.RPG , "Gun RPG.xml", "ROCKET #1.xml",
		GUN_CLASSES.rpg,
		GUN_FACTIONS.mil,
		GUN_TECHS.high)

	create_gun_prefab(RootGuns.RPG , "Gun RPG.xml", "ROCKET #2.xml",
		GUN_CLASSES.rpg,
		GUN_FACTIONS.um,
		GUN_TECHS.high)
		
--------Shotgun-Mid-----------

	create_gun_prefab(RootGuns.KS23 , "Gun KS23.xml", "Ammo 4GA BS.xml",
		GUN_CLASSES.shotgun,
		GUN_FACTIONS.mil,
		GUN_TECHS.mid)
		
--------SMG-Low -----------

	create_gun_prefab(RootGuns.Simonov_9 , "Gun Simonov-9.xml", "Ammo 9x19 FMJ.xml",
		GUN_CLASSES.smg,
		GUN_FACTIONS.um,
		GUN_TECHS.low)

	create_gun_prefab(RootGuns.MC9 , "Gun MC9K.xml", "Ammo 9x19 FMJ.xml",
		GUN_CLASSES.smg,
		GUN_FACTIONS.um,
		GUN_TECHS.low)

--------SMG-Mid -----------

	create_gun_prefab(RootGuns.Simonov_545 , "Gun Simonov-545U MILITARY2.xml", "Ammo 5.45 FMJ.xml",
		GUN_CLASSES.smg,
		GUN_FACTIONS.mil,
		GUN_TECHS.mid)

	create_gun_prefab(RootGuns.Simonov_545 , "Gun Simonov-545U MILITARY3.xml", "Ammo 5.45 FMJ.xml",
		GUN_CLASSES.smg,
		GUN_FACTIONS.mil,
		GUN_TECHS.mid)

	create_gun_prefab(RootGuns.MC9  , "Gun MC9.xml", "Ammo 9x19 FMJ.xml",
		GUN_CLASSES.smg,
		GUN_FACTIONS.um,
		GUN_TECHS.mid)

		create_gun_prefab(RootGuns.Simonov_9 , "Gun Simonov-9 MILITARY1.xml", "Ammo 9x19 FMJ.xml",
		GUN_CLASSES.smg,
		GUN_FACTIONS.um,
		GUN_TECHS.low)

		create_gun_prefab(RootGuns.Simonov_9 , "Gun Simonov-9 MILITARY2.xml", "Ammo 9x19 FMJ.xml",
		GUN_CLASSES.smg,
		GUN_FACTIONS.um,
		GUN_TECHS.low)

--------SMG-High -----------
	create_gun_prefab(RootGuns.Simonov_545 , "Gun Simonov-545U MILITARY1.xml", "Ammo 5.45 FMJ.xml",
		GUN_CLASSES.smg,
		GUN_FACTIONS.mil,
		GUN_TECHS.high)

	create_gun_prefab(RootGuns.MC9 , "Gun MC9 MILITARY2.xml", "Ammo 9x19 FMJ.xml",
		GUN_CLASSES.smg,
		GUN_FACTIONS.um,
		GUN_TECHS.mid)

	create_gun_prefab(RootGuns.MC9 , "Gun MC9 MILITARY1.xml", "Ammo 9x19 FMJ.xml",
		GUN_CLASSES.smg,
		GUN_FACTIONS.um,
		GUN_TECHS.mid)

--------Sniper-Mid -----------

	create_gun_prefab(RootGuns.SV98 , "Gun SV98.xml", "Ammo 7.62x54R FMJ.xml",
		GUN_CLASSES.sniper,
		GUN_FACTIONS.mil,
		GUN_TECHS.mid)

	create_gun_prefab(RootGuns.Medvedev , "Gun Medvedev MILITARY.xml", "Ammo 7.62x54R FMJ.xml",
		GUN_CLASSES.sniper,
		GUN_FACTIONS.civ,
		GUN_TECHS.low)

	create_gun_prefab(RootGuns.Medvedev , "Gun Medvedev SNIPER MILITARY.xml", "Ammo 7.62x54R FMJ.xml",
		GUN_CLASSES.sniper,
		GUN_FACTIONS.civ,
		GUN_TECHS.low)

	create_gun_prefab(RootGuns.Medvedev , "Gun Medvedev SUPPRESSED MILITARY.xml", "Ammo 7.62x54R FMJ.xml",
		GUN_CLASSES.sniper,
		GUN_FACTIONS.civ,
		GUN_TECHS.mid)

	create_gun_prefab(RootGuns.Medvedev , "Gun Medvedev SNIPER SUPPRESSED MILITARY.xml", "Ammo 7.62x54R FMJ.xml",
		GUN_CLASSES.sniper,
		GUN_FACTIONS.civ,
		GUN_TECHS.high)

--------Sniper-High -----------

	create_gun_prefab(RootGuns.SV98 , "Gun SV98 SNIPER.xml", "Ammo 7.62x54R FMJ.xml",
		GUN_CLASSES.sniper,
		GUN_FACTIONS.mil,
		GUN_TECHS.mid)

	create_gun_prefab(RootGuns.Drozdov , "Gun Drozdov MILITARY.xml", "Ammo 7.62x54R FMJ.xml",
		GUN_CLASSES.sniper,
		GUN_FACTIONS.mil,
		GUN_TECHS.high)

--------Rifle-Mid----------

	create_gun_prefab(RootGuns.Kovalyov_762 , "Gun Kovalyov-762.xml", "Ammo 7.62x39 FMJ.xml",
		GUN_CLASSES.rifle,
		GUN_FACTIONS.mil,
		GUN_TECHS.mid)

	create_gun_prefab(RootGuns.Kovalyov_545 , "Gun Kovalyov-545.xml", "Ammo 5.45 FMJ.xml",
		GUN_CLASSES.rifle,
		GUN_FACTIONS.mil,
		GUN_TECHS.mid)

	create_gun_prefab(RootGuns.MC308 , "Gun MC308.xml", "Ammo 7.62x51 FMJ.xml",
		GUN_CLASSES.rifle,
		GUN_FACTIONS.mil,
		GUN_TECHS.mid)

	create_gun_prefab(RootGuns.N4A1 , "Gun N4A1.xml", "Ammo 5.56 FMJ.xml",
		GUN_CLASSES.rifle,
		GUN_FACTIONS.mil,
		GUN_TECHS.mid)

	create_gun_prefab(RootGuns.N16 , "Gun N16.xml", "Ammo 5.56 FMJ.xml",
		GUN_CLASSES.rifle,
		GUN_FACTIONS.mil,
		GUN_TECHS.mid)

--------Rifle-High----------

	create_gun_prefab(RootGuns.MC308 , "Gun MC308 COMPACT1.xml", "Ammo 7.62x51 FMJ.xml",
		GUN_CLASSES.rifle,
		GUN_FACTIONS.mil,
		GUN_TECHS.high)

	create_gun_prefab(RootGuns.MC308 , "Gun MC308 COMPACT2.xml", "Ammo 7.62x51 FMJ.xml",
		GUN_CLASSES.rifle,
		GUN_FACTIONS.mil,
		GUN_TECHS.high)

	create_gun_prefab(RootGuns.MC308 , "Gun MC308 MILITARY1.xml", "Ammo 7.62x51 FMJ.xml",
		GUN_CLASSES.rifle,
		GUN_FACTIONS.mil,
		GUN_TECHS.high)

	create_gun_prefab(RootGuns.MC308 , "Gun MC308 MILITARY2.xml", "Ammo 7.62x51 FMJ.xml",
		GUN_CLASSES.rifle,
		GUN_FACTIONS.mil,
		GUN_TECHS.high)

	create_gun_prefab(RootGuns.Simonov_106 , "Gun Simonov-106 MILITARY1.xml", "Ammo 5.45 FMJ.xml",
		GUN_CLASSES.rifle,
		GUN_FACTIONS.mil,
		GUN_TECHS.high)

	create_gun_prefab(RootGuns.Simonov_106 , "Gun Simonov-106 MILITARY2.xml", "Ammo 5.45 FMJ.xml",
		GUN_CLASSES.rifle,
		GUN_FACTIONS.mil,
		GUN_TECHS.high)

	create_gun_prefab(RootGuns.Simonov_106 , "Gun Simonov-106 MILITARY3.xml", "Ammo 5.45 FMJ.xml",
		GUN_CLASSES.rifle,
		GUN_FACTIONS.mil,
		GUN_TECHS.high)

	create_gun_prefab(RootGuns.Simonov_106 , "Gun Simonov-106 MILITARY4.xml", "Ammo 5.45 FMJ.xml",
		GUN_CLASSES.rifle,
		GUN_FACTIONS.mil,
		GUN_TECHS.high)

	create_gun_prefab(RootGuns.Simonov_106 , "Gun Simonov-106 MILITARY6.xml", "Ammo 5.45 FMJ.xml",
		GUN_CLASSES.rifle,
		GUN_FACTIONS.mil,
		GUN_TECHS.high)

	create_gun_prefab(RootGuns.Simonov_762 , "Gun Simonov-762 MILITARY1.xml", "Ammo 5.45 FMJ.xml",
		GUN_CLASSES.rifle,
		GUN_FACTIONS.mil,
		GUN_TECHS.high)

	create_gun_prefab(RootGuns.Simonov_545 , "Gun Simonov-545 MILITARY.xml", "Ammo 5.45 FMJ.xml",
		GUN_CLASSES.rifle,
		GUN_FACTIONS.mil,
		GUN_TECHS.high)

	create_gun_prefab(RootGuns.Simonov_762 , "Gun Simonov-762 MILITARY1.xml", "Ammo 7.62x39 FMJ.xml",
		GUN_CLASSES.rifle,
		GUN_FACTIONS.mil,
		GUN_TECHS.high)

	create_gun_prefab(RootGuns.Simonov_762 , "Gun Simonov-762 MILITARY2.xml", "Ammo 7.62x39 FMJ.xml",
		GUN_CLASSES.rifle,
		GUN_FACTIONS.mil,
		GUN_TECHS.high)

	create_gun_prefab(RootGuns.SKS , "Gun SKS MILITARY.xml", "Ammo 7.62x39 FMJ.xml",
		GUN_CLASSES.sniper,
		GUN_FACTIONS.mil,
		GUN_TECHS.high)

		--------Pistol-Mid----------
	create_gun_prefab(RootGuns.TT_33 , "Gun TT-33 GREY.xml", "Ammo 7.62x25 FMJ.xml",
		GUN_CLASSES.pistol,
		GUN_FACTIONS.mil,
		GUN_TECHS.mid)

	create_gun_prefab(RootGuns.TT_33 , "Gun TT-33 GREY 1.xml", "Ammo 7.62x25 FMJ.xml",
		GUN_CLASSES.pistol,
		GUN_FACTIONS.mil,
		GUN_TECHS.mid)

	create_gun_prefab(RootGuns.TT_33 , "Gun TT-33 GREY 2.xml", "Ammo 7.62x25 FMJ.xml",
		GUN_CLASSES.pistol,
		GUN_FACTIONS.mil,
		GUN_TECHS.mid)

	create_gun_prefab(RootGuns.TT_33 , "Gun TT-33 GREY 3.xml", "Ammo 7.62x25 FMJ.xml",
		GUN_CLASSES.pistol,
		GUN_FACTIONS.mil,
		GUN_TECHS.mid)

	create_gun_prefab(RootGuns.TT_33 , "Gun TT-33 GREY 4.xml", "Ammo 7.62x25 FMJ.xml",
		GUN_CLASSES.pistol,
		GUN_FACTIONS.mil,
		GUN_TECHS.mid)

			--------Pistol-High----------
	create_gun_prefab(RootGuns.TT_33 , "Gun TT-33 GREY 5.xml", "Ammo 7.62x25 FMJ.xml",
		GUN_CLASSES.pistol,
		GUN_FACTIONS.mil,
		GUN_TECHS.high)

	create_gun_prefab(RootGuns.TT_33 , "Gun TT-33 GREY 6.xml", "Ammo 7.62x25 FMJ.xml",
		GUN_CLASSES.pistol,
		GUN_FACTIONS.mil,
		GUN_TECHS.high)

	create_gun_prefab(RootGuns.TT_33 , "Gun TT-33 GREY 7.xml", "Ammo 7.62x25 FMJ.xml",
		GUN_CLASSES.pistol,
		GUN_FACTIONS.mil,
		GUN_TECHS.high)

	create_gun_prefab(RootGuns.TT_33 , "Gun TT-33 GREY 8.xml", "Ammo 7.62x25 FMJ.xml",
		GUN_CLASSES.pistol,
		GUN_FACTIONS.mil,
		GUN_TECHS.high)
end

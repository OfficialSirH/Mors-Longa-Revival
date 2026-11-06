#include "inv-desc.lua"
#include "weapon_wheel.lua"
#include "shop.lua"
#include "gunxmlbuilder.lua"
#include "../scripts/perkTable.lua"
#include "../scripts/TDSU/tdsu.lua"
#include "../Settings.lua"
#include "gunperks.lua"

WeaponWheel = true


function RegisterToolId(tool_id, enabled) --- Add tool id as bool to keep enabled/disabled.
    SetBool("level.tools.".. tool_id, enabled)
end
local dimensions = { -- A table with every item dimensions
	gun = {_default = {1, 1},
		["gun-ak74m"] = {5, 2},
		["gun-ak74"] = {5, 2},
		["gun-ak101"] = {5, 2},
		["gun-ak12"] = {4, 2},
		["gun-ar15"] = {5, 2},
		["gun-m16"] = {5, 2},
		["gun-scarl"] = {5, 2},
		["gun-scarlg"] = {5, 2},
		["gun-mosin"] = {5, 1},	
		["gun-mosinm"] = {5, 1},
		["gun-sks"] = {5, 1},
		["gun-mp43"] = {6, 1},
		["gun-m870"] = {5, 1},
		["gun-ks23"] = {4, 1},
		["gun-rpg"] = {6, 2},
		["gun-ppsh41"] = {4, 2},
		["gun-akm"] = {5, 2},
		["gun-g17"] = {2, 1},
		["gun-deagle"] = {2, 1},
		["gun-g18"] = {2, 1},
		["gun-tt33"] = {2, 1},
		["gun-m9"] = {2, 1},
		["gun-sawedoff"] = {2, 1},
		["gun-cz1012"] = {5, 1},
		["gun-mp443"] = {2, 2},
		["gun-mgl"] = {3, 2},
		["gun-scarh"] = {5, 2},
		["gun-scarhg"] = {5, 2},
		["gun-vector"] = {4, 2},
		["gun-svd"] = {7, 2},
		["gun-g36k"] = {5, 2},
		["gun-sg553"] = {5, 2},
		["gun-g3"] = {6, 2},
		["gun-mp5"] = {4, 2},
		["gun-ak50"] = {7, 2},
		["gun-m107"] = {7, 2},
		["gun-p90"] = {4, 2},
		["gun-pp19"] = {4, 2},
		["gun-sv98"] = {6, 2},
		["gun-fiveseven"] = {2, 1},
	},
	food = {_default = {1, 1},
		["food3"] = {1, 1},
		["food6"] = {1, 2},
		["food8"] = {2, 2},
		["food12"] = {2, 2},
		["food14"] = {2, 2},
		["food15"] = {2, 2},
		["food18"] = {1, 2},
		["food20"] = {2, 2},
	},
	material = {_default = {1, 1},
		["material-rubber"] = {2, 1},
		["material-steel"] = {3, 1},
		["material-kevlar"] = {2, 2},
		["material-scrap"] = {2, 2},
		["material-driftwood"] = {3, 1},
		["material-explosive"] = {2, 1},
	},
	meds = {_default = {1, 1},
		["car"] = {2, 1},
		["cms"] = {2, 1},
		["grizzly"] = {2, 2},
		["surv12"] = {3, 1},
	},
	vest = {_default = {3, 3},
		["vest-gzhel"] = {3, 3},
		["vest-zabralo"] = {4, 4},
		["vest-thor"] = {4, 4},
		["vest-killa"] = {3, 4},
		["vest-sixb2"] = {3, 3},
		["vest-hexgrid"] = {3, 3},
		["vest-lbtplate"] = {3, 3},
		["vest-nfmthor"] = {3, 3},
	},
	helmet = {_default = {2, 2},
	},
	eyewear = {_default = {1, 1},
		["eyewear-nvg"] = {2, 1},
		["eyewear-thermals"] = {2, 1},
		["eyewear-pvs14"] = {2, 1},
		["eyewear-pnv10t"] = {2, 1},
	},
	mag = {_default = {1, 1},
		["mag0-ak-545"] = {1, 2},
		["mag0-ak-556"] = {1, 2},
		["mag1-ak-545"] = {1, 3},
		["mag2-ak-545"] = {2, 2},
		["mag3-ak-545"] = {2, 2},
		["mag4-ak-545"] = {1, 2},
		["mag0-ak-762x39"] = {1, 2},
		["mag1-ak-762x39"] = {1, 3},
		["mag2-ak-762x39"] = {1, 2},
		["mag3-ak-762x39"] = {2, 2},
		["mag0-ak-9x19"] = {1, 2},
		["mag0-ar-556"] = {1, 2},
		["mag1-ar-556"] = {1, 2},
		["mag2-ar-556"] = {2, 2},
		["mag3-ar-556"] = {3, 2},
		["mag4-ar-556"] = {1, 1},
		["mag5-ar-556"] = {1, 2},
		["mag6-ar-556"] = {1, 2},
		["mag7-ar-556"] = {1, 1},
		["mag8-ar-556"] = {1, 2},
		["mag1-glock-9x19"] = {1, 2},
		["mag2-glock-9x19"] = {1, 2},
		["mag0-dgl-127x33"] = {1, 1},
		["mag0-tt33-762x25"] = {1, 1},
		["mag0-scar-762x51"] = {1, 2},
		["mag2-scar-762x51"] = {2, 2},
		["mag0-ppsh-762x25"] = {1, 2},
		["mag1-ppsh-762x25"] = {2, 2},
		["mag0-hk-556"] = {1, 2},
		["mag0-g3-762x51"] = {1, 2},
		["mag1-g3-762x51"] = {1, 2},
		["mag2-g3-762x51"] = {2, 2},
		["mag0-mp5-9x19"] = {1, 2},
		["mag1-mp5-9x19"] = {1, 2},
		["mag2-mp5-9x19"] = {1, 2},
		["mag0-m107-127x99"] = {2, 2},
		["mag0-p90-57x28"] = {2, 1},
	},
	ammo = {_default = {1, 1},
		["bullets-127x99-FMJ"] = {2, 1},
		["bullets-127x99-T"] = {2, 1},
		["bullets-127x99-AP"] = {2, 1},
		["bullets-127x99-API"] = {2, 1},
		["bullets-127x99-APE"] = {2, 1},
		["rocket0"] = {3, 1},
		["rocket1"] = {3, 1},
		["rocket2"] = {4, 1},
		["rocket3"] = {3, 1},
	},
	melee = {_default = {1, 1},
		["melee-Pipe"] = {1, 3},
		["melee-Katana"] = {1, 4},
		["melee-Tomahawk"] = {1, 2},
		["melee-Crowbar"] = {1, 3},
		["melee-CombatKnife"] = {1, 2},
		["melee-FireAxe"] = {2, 4},
		["melee-BaseballBat"] = {1, 4},
		["melee-DamnedScythe"] = {2, 3},
	},
	general = {_default = {1, 1},
		["general-gpu"] = {2, 1},
		["general-carbattery"] = {2, 2},
		["general-book"] = {2, 2},
		["general-nails"] = {2, 1},
		["general-plate"] = {2, 2},
		
		
	},
	attachment = {_default = {1, 1},
		
		["attachment-muzzle1-ar"] = {2, 1},
		["attachment-muzzle1-m107"] = {3, 1},
		["attachment-muzzle1-glock"] = {2, 1},
		["attachment-muzzle1-p90"] = {2, 1},
		["attachment-muzzle1-tt33"] = {2, 1},
		["attachment-muzzle1-57"] = {2, 1},
		["attachment-muzzle1-mosin"] = {2, 1},
		["attachment-muzzle1-ak74"] = {2, 1},
		["attachment-muzzle1-akm"] = {2, 1},
		["attachment-muzzle1-pp19"] = {2, 1},
		["attachment-muzzle1-g36"] = {2, 1},
		["attachment-muzzle1-g3"] = {2, 1},
		["attachment-muzzle1-mp5"] = {2, 1},
		["attachment-muzzle1-sks"] = {2, 1},
		["attachment-muzzle1-scarl"] = {2, 1},
		["attachment-muzzle1-scarh"] = {2, 1},
		
		["attachment-muzzle2-ar"] = {2, 1},
		["attachment-muzzle2-m107"] = {3, 1},
		["attachment-muzzle2-glock"] = {2, 1},
		["attachment-muzzle2-p90"] = {2, 1},
		["attachment-muzzle2-tt33"] = {2, 1},
		["attachment-muzzle2-57"] = {2, 1},
		["attachment-muzzle2-mosin"] = {2, 1},
		["attachment-muzzle2-ak74"] = {2, 1},
		["attachment-muzzle2-akm"] = {2, 1},
		["attachment-muzzle2-pp19"] = {2, 1},
		["attachment-muzzle2-g36"] = {2, 1},
		["attachment-muzzle2-g3"] = {2, 1},
		["attachment-muzzle2-mp5"] = {2, 1},
		["attachment-muzzle2-sks"] = {2, 1},
		["attachment-muzzle2-scarl"] = {2, 1},
		["attachment-muzzle2-scarh"] = {2, 1},
		
		["attachment-muzzle2"] = {1, 1},
		
		["attachment-acog"] = {2, 1},
		
	},
	other = {_default = {1, 1},
		["grenade1"] = {1, 2},
	},
}

local GunDefaultBulletType = {
	["556"] = "HP",
	["12ga"] = "BS",
	["9x19"] = "HP",
	["762x54"] = "HP",
	["57x28"] = "HP",
	["4ga"] = "BS",
	["762x25"] = "HP",
	["762x39"] = "HP",
	["762x51"] = "HP",
	["545"] = "HP",
	["127x99"] = "FMJ",
	["127x33"] = "HP",
	
	
	}

local gunattachments = {
		ar15 		= {
			toprail = 1,
			canted = 2,
			muzzle = 3,
			stock = 4,
			grip = 5,
			barrel = 6,
			side = 7,
			guard = 8,
			magnifier = 9,
			camo = 10},
		ak74 		= {
			toprail = 1,
			toprail2 = 2,
			muzzle = 3,
			stock  = 4,
			grip = 5,
			barrel = 6,
			side  = 7,
			guard = 8,
			modernguard = 9,
			dustcover = 10,
			camo = 11},
		ak74m 		= {
			toprail = 1,
			muzzle = 2,
			stock = 3,
			grip = 4,
			barrel = 5,
			side = 6,
			guard = 7,
			dustcover = 8},		
		ak101 		= {
			toprail = 1,
			toprail2 = 2,
			muzzle = 3,
			stock  = 4,
			grip = 5,
			barrel = 6,
			side  = 7,
			guard = 8,
			modernguard = 9,
			dustcover = 10,
			camo = 11},
		akm 		= {
			toprail = 1,
			toprail2 = 2,
			muzzle = 3,
			stock = 4,
			grip = 5,
			barrel = 6,
			side = 7,
			guard = 8,
			modernguard = 9,
			dustcover = 10},
		g3 			= {
			toprail = 1,
			muzzle = 2,
			stock = 3,
			grip = 4,
			barrel = 5,
			side = 6,
			guard = 7},
		g17 		= {
			toprail = 1,
			muzzle = 2,
			stock = 3,
			side = 4,
			camo = 5},
		g18 		= {
			toprail = 1,
			muzzle = 2,
			stock = 3,
			side = 4,
			camo = 5},
		tt33		= {
			toprail = 1,
			muzzle = 2,
			stock = 3,
			side = 4,
			camo = 5},
		fiveseven	= {
			toprail = 1,
			muzzle = 2,
			stock = 3,
			side = 4,
			camo = 5},
		deagle		= {	
			toprail = 1,
			muzzle = 2,
			stock = 3,
			side = 4,
			camo = 5},
		m9			= {
			toprail = 1,
			muzzle = 2,
			stock = 3,
			side = 4,
			camo = 5},
		g36k		= { 
			toprail = 1,
			muzzle = 2,
			stock = 3,
			grip = 4,
			barrel = 5,
			side = 6,
			guard = 7,
			magnifier = 8},
		m16 		= {
			toprail = 1,
			canted = 2,
			muzzle = 3,
			stock = 4,
			grip = 5,
			barrel = 6,
			side = 7,
			guard = 8,
			magnifier = 9,
			camo = 10},
		m107		= {
			toprail = 1,
			canted = 2,
			muzzle = 3,
			stock = 4,
			grip = 5,
			barrel = 6,
			side = 7,
			guard = 8,
			magnifier = 9,
			camo = 10},
		m870		= {
			toprail = 1,
			muzzle = 2,
			stock = 3,
			grip = 4,
			side = 5,
			camo = 6},
		mp5			= {	
			toprail = 1,
			muzzle = 2,
			stock = 3,
			grip = 4,
			barrel = 5,
			side = 6,
			guard = 7},
		p90			= {	
			toprail = 1,
			muzzle = 2,
			stock = 3,
			grip = 4,
			barrel = 5,
			side = 6,
			guard = 7,
			magnifier = 8},
		pp19		= {		
			toprail = 1,
			muzzle = 2,
			stock = 3,
			grip = 4,
			barrel = 5,
			side = 6,
			guard = 7,
			dustcover = 8},
		scarh		= {
			toprail = 1,
			muzzle = 2,
			grip = 4,
			barrel = 5,
			side = 6,
			guard = 7,
			magnifier = 8,
			camo = 9},
		scarhg		= {
			toprail = 1,
			muzzle = 2,
			grip = 4,
			barrel = 5,
			side = 6,
			guard = 7,
			magnifier = 8,
			camo = 9},
		scarl		= {
			toprail = 1,
			muzzle = 2,
			grip = 4,
			barrel = 5,
			side = 6,
			guard = 7,
			magnifier = 8,
			camo = 9},
		scarlg		= {
			toprail = 1,
			muzzle = 2,
			grip = 4,
			barrel = 5,
			side = 6,
			guard = 7,
			magnifier = 8,
			camo = 9},
		sks			= {
			toprail = 1,
			muzzle = 2,
			stock = 3,
			grip = 4,
			side = 5,
			guard = 6,
			camo = 7},
		svd			= {		
			toprail = 1,
			toprail2 = 2,
			muzzle = 3,
			stock = 4,
			grip = 5,
			barrel = 6,
			side = 7,
			guard = 8,
			modernguard = 9,
			dustcover = 10},
		vector		= {
			toprail = 1,
			muzzle = 2,
			grip = 4,
			barrel = 5,
			side = 6,
			guard = 7},
		mosin 		= {
			toprail = 1,
			muzzle = 2,
			stock = 3},
		mosinm 		= {	
			toprail = 1,
			muzzle = 2,
			stock = 3,
			side = 4},

}

local attachmentswap = {
		sides		= {
			side1 = "attachment-side1_Green-Laser",
			side2 = "attachment-side2_Flashlight",
			side3 = "attachment-side3_Red-Laser",
			side4 = "attachment-side4_IR-Laser",
			},		
		sights		= {
			pistol = {
				holo = "attachment-holo-pistol_Holo-Mini",
			},
			notpistol = {
				holo = "attachment-holo-normal_Holo",
				holo2 = "attachment-holo-tan_Holo",
			},	
		},	
		weapons		= {
			ar15 		= {
				muzzle1 = "attachment-muzzle1-ar_Stanag-Suppressor",
				muzzle2 = "attachment-muzzle2-ar_Stanag-Brake",
				
				holo = "attachment-holo-normal_Holo",
				holo2 = "attachment-holo-tan_Holo",
				scope = "attachment-acog_Acog"
				},
			ak74 		= {
				muzzle1 = "attachment-muzzle1-ak74_Simonov-545-Suppressor",
				muzzle2 = "attachment-muzzle2-ak74_Simonov-545-Brake",
				
				holo = "attachment-holo-normal_Holo",
				},
			ak74m 		= {
				muzzle1 = "attachment-muzzle1-ak74_Simonov-545-Suppressor",
				muzzle2 = "attachment-muzzle2-ak74_Simonov-545-Brake",
				
				holo = "attachment-holo-normal_Holo",
				},		
			ak101 		= {
				},
			akm 		= {
				muzzle1 = "attachment-muzzle1-akm_Simonov-762-Suppressor",
				muzzle2 = "attachment-muzzle2-akm_Simonov-762-Brake",
				
				holo = "attachment-holo-normal_Holo",
				},
			g3 			= {
				muzzle1 = "attachment-muzzle1-g3_G3-Suppressor",
				muzzle2 = "attachment-muzzle2-g3_G3-Brake",
				
				holo = "attachment-holo-normal_Holo",
				scope = "attachment-acog_Acog"
				},
			g17 		= {
				muzzle1 = "attachment-muzzle1-glock_Plock-Suppressor",
				muzzle2 = "attachment-muzzle2-glock_Plock-Brake",
				
				holo = "attachment-holo-pistol_Holo-Mini",
				},				
			g18 		= {
				muzzle1 = "attachment-muzzle1-glock_Plock-Suppressor",
				muzzle2 = "attachment-muzzle2-glock_Plock-Brake",
				
				holo = "attachment-holo-pistol_Holo-Mini",
				},	
			tt33		= {
				muzzle1 = "attachment-muzzle1-tt33_TT-33-Suppressor",
				muzzle2 = "attachment-muzzle2-tt33_TT-33-Brake",
				
				holo = "attachment-holo-pistol_Holo-Mini",
				},
			fiveseven	= {
				muzzle1 = "attachment-muzzle1-57_TCP-57-Suppressor",
				muzzle2 = "attachment-muzzle2-57_TCP-57-Brake",
				
				holo = "attachment-holo-pistol_Holo-Mini",
				},
			deagle		= {	
				
				
				holo = "attachment-holo-pistol_Holo-Mini",
				},
			m9			= {
				
				holo = "attachment-holo-pistol_Holo-Mini",
				},
			g36k		= { 
				muzzle1 = "attachment-muzzle1-g36_MK-36-Suppressor",
				muzzle2 = "attachment-muzzle2-g36_MK-36-Brake",
				
				holo = "attachment-holo-normal_Holo",
				scope = "attachment-acog_Acog"
				},
			m16 		= {
				muzzle1 = "attachment-muzzle1-ar_Stanag-Suppressor",
				muzzle2 = "attachment-muzzle2-ar_Stanag-Brake",
				
				holo = "attachment-holo-normal_Holo",
				scope = "attachment-acog_Acog"
				},
			m107		= {
				muzzle1 = "attachment-muzzle1-m107_N107-Suppressor",
				muzzle2 = "attachment-muzzle2-m107_N107-Brake",
				
				holo = "attachment-holo-normal_Holo",
				scope = "attachment-acog_Acog"
				},
			m870		= {
				},
			mp5			= {	
				muzzle1 = "attachment-muzzle1-mp5_MC9-Suppressor",
				muzzle2 = "attachment-muzzle2-mp5_MC9-Brake",
				
				holo = "attachment-holo-normal_Holo",
				},
			p90			= {	
				muzzle1 = "attachment-muzzle1-p90_TMP-90-Suppressor",
				muzzle2 = "attachment-muzzle2-p90_TMP-90-Brake",
				
				holo = "attachment-holo-normal_Holo",
				},
			pp19		= {		
				muzzle1 = "attachment-muzzle1-pp19_Simonov-9-Suppressor",
				muzzle2 = "attachment-muzzle2-pp19_Simonov-9-Brake",
				
				holo = "attachment-holo-normal_Holo",
				},
			scarh		= {
				muzzle1 = "attachment-muzzle1-scarh_TCR-308-Suppressor",
				muzzle2 = "attachment-muzzle2-scarh_TCR-308-Brake",
				
				holo = "attachment-holo-normal_Holo",
				scope = "attachment-acog_Acog"
				},
			scarhg		= {
				muzzle1 = "attachment-muzzle1-scarh_TCR-308-Suppressor",
				muzzle2 = "attachment-muzzle2-scarh_TCR-308-Brake",
				
				holo = "attachment-holo-normal_Holo",
				scope = "attachment-acog_Acog"
				},
			scarl		= {
				muzzle1 = "attachment-muzzle1-scarl_TCR-556-Suppressor",
				muzzle2 = "attachment-muzzle2-scarl_TCR-556-Brake",
				
				holo = "attachment-holo-normal_Holo",
				scope = "attachment-acog_Acog"
				},
			scarlg		= {
				muzzle1 = "attachment-muzzle1-scarl_TCR-556-Suppressor",
				muzzle2 = "attachment-muzzle2-scarl_TCR-556-Brake",
				
				holo = "attachment-holo-normal_Holo",
				scope = "attachment-acog_Acog"
				},
			sks			= {
				muzzle1 = "attachment-muzzle1-sks_SKS-Suppressor",
				muzzle2 = "attachment-muzzle2-sks_SKS-Brake",
				
				holo = "attachment-holo-normal_Holo",
				},
			svd			= {		
				
				holo = "attachment-holo-normal_Holo",
				},
			vector		= {
				muzzle1 = "attachment-muzzle1-glock_Plock-Suppressor",
				muzzle2 = "attachment-muzzle2-glock_Plock-Brake",
				
				holo = "attachment-holo-normal_Holo",
				},	
			mosin 		= {
				muzzle1 = "attachment-muzzle1-mosin_Mosin-Suppressor",
				muzzle2 = "attachment-muzzle2-mosin_Mosin-Brake",
				
				holo = "attachment-holo-normal_Holo",
				},
			mosinm 		= {	
				muzzle1 = "attachment-muzzle1-mosin_Mosin-Suppressor",
				muzzle2 = "attachment-muzzle2-mosin_Mosin-Brake",
				
				holo = "attachment-holo-normal_Holo",
				},
			},
		}

local attachments = {
		weapons		= {
			ar15 		= {
				muzzle1 = "attachment-muzzle1-ar_Stanag-Suppressor",
				muzzle2 = "attachment-muzzle2-ar_Stanag-Brake",
				
				holo = "attachment-holo-normal_Holo",
				holo2 = "attachment-holo-tan_Holo",
				
				none = "none_",
				x = 210,
				y = -110,
				},
			ak74 		= {
				muzzle1 = "attachment-muzzle1-ak74_Simonov-545-Suppressor",
				muzzle2 = "attachment-muzzle2-ak74_Simonov-545-Brake",
				
				holo = "attachment-holo-normal_Holo",
				},
			ak74m 		= {
				muzzle1 = "attachment-muzzle1-ak74_Simonov-545-Suppressor",
				muzzle2 = "attachment-muzzle2-ak74_Simonov-545-Brake",
				
				holo = "attachment-holo-normal_Holo",
				
				none = "none_",
				},		
			ak101 		= {
				
				none = "none_",
				},
			akm 		= {
				muzzle1 = "attachment-muzzle1-akm_Simonov-762-Suppressor",
				muzzle2 = "attachment-muzzle2-akm_Simonov-762-Brake",
				
				holo = "attachment-holo-normal_Holo",
				
				none = "none_",
				},
			g3 			= {
				muzzle1 = "attachment-muzzle1-g3_G3-Suppressor",
				muzzle2 = "attachment-muzzle2-g3_G3-Brake",
				
				holo = "attachment-holo-normal_Holo",
				
				none = "none_",
				},
			g17 		= {
				muzzle1 = "attachment-muzzle1-glock_Plock-Suppressor",
				muzzle2 = "attachment-muzzle2-glock_Plock-Brake",
				
				holo = "attachment-holo-pistol_Holo-Mini",
				},				
			g18 		= {
				muzzle1 = "attachment-muzzle1-glock_Plock-Suppressor",
				muzzle2 = "attachment-muzzle2-glock_Plock-Brake",
				
				holo = "attachment-holo-pistol_Holo-Mini",
				
				none = "none_",
				},	
			tt33		= {
				muzzle1 = "attachment-muzzle1-tt33_TT-33-Suppressor",
				muzzle2 = "attachment-muzzle2-tt33_TT-33-Brake",
				
				holo = "attachment-holo-pistol_Holo-Mini",
				},
			fiveseven	= {
				muzzle1 = "attachment-muzzle1-57_TCP-57-Suppressor",
				muzzle2 = "attachment-muzzle2-57_TCP-57-Brake",
				
				holo = "attachment-holo-pistol_Holo-Mini",
				},
			deagle		= {	
				
				
				holo = "attachment-holo-pistol_Holo-Mini",
				},
			m9			= {
				
				holo = "attachment-holo-pistol_Holo-Mini",
				},
			g36k		= { 
				muzzle1 = "attachment-muzzle1-g36_MK-36-Suppressor",
				muzzle2 = "attachment-muzzle2-g36_MK-36-Brake",
				
				holo = "attachment-holo-normal_Holo",
				},
			m16 		= {
				muzzle1 = "attachment-muzzle1-ar_Stanag-Suppressor",
				muzzle2 = "attachment-muzzle2-ar_Stanag-Brake",
				
				holo = "attachment-holo-normal_Holo",
				},
			m107		= {
				muzzle1 = "attachment-muzzle1-m107_N107-Suppressor",
				muzzle2 = "attachment-muzzle2-m107_N107-Brake",
				
				holo = "attachment-holo-normal_Holo",
				},
			m870		= {
				},
			mp5			= {	
				muzzle1 = "attachment-muzzle1-mp5_MC9-Suppressor",
				muzzle2 = "attachment-muzzle2-mp5_MC9-Brake",
				
				holo = "attachment-holo-normal_Holo",
				},
			p90			= {	
				muzzle1 = "attachment-muzzle1-p90_TMP-90-Suppressor",
				muzzle2 = "attachment-muzzle2-p90_TMP-90-Brake",
				
				holo = "attachment-holo-normal_Holo",
				},
			pp19		= {		
				muzzle1 = "attachment-muzzle1-pp19_Simonov-9-Suppressor",
				muzzle2 = "attachment-muzzle2-pp19_Simonov-9-Brake",
				
				holo = "attachment-holo-normal_Holo",
				},
			scarh		= {
				muzzle1 = "attachment-muzzle1-scarh_TCR-308-Suppressor",
				muzzle2 = "attachment-muzzle2-scarh_TCR-308-Brake",
				
				holo = "attachment-holo-normal_Holo",
				},
			scarhg		= {
				muzzle1 = "attachment-muzzle1-scarh_TCR-308-Suppressor",
				muzzle2 = "attachment-muzzle2-scarh_TCR-308-Brake",
				
				holo = "attachment-holo-normal_Holo",
				},
			scarl		= {
				muzzle1 = "attachment-muzzle1-scarl_TCR-556-Suppressor",
				muzzle2 = "attachment-muzzle2-scarl_TCR-556-Brake",
				
				holo = "attachment-holo-normal_Holo",
				},
			scarlg		= {
				muzzle1 = "attachment-muzzle1-scarl_TCR-556-Suppressor",
				muzzle2 = "attachment-muzzle2-scarl_TCR-556-Brake",
				
				holo = "attachment-holo-normal_Holo",
				},
			sks			= {
				muzzle1 = "attachment-muzzle1-sks_SKS-Suppressor",
				muzzle2 = "attachment-muzzle2-sks_SKS-Brake",
				
				holo = "attachment-holo-normal_Holo",
				},
			svd			= {		
				
				holo = "attachment-holo-normal_Holo",
				},
			vector		= {
				muzzle1 = "attachment-muzzle1-glock_Plock-Suppressor",
				muzzle2 = "attachment-muzzle2-glock_Plock-Brake",
				
				holo = "attachment-holo-normal_Holo",
				},	
			mosin 		= {
				muzzle1 = "attachment-muzzle1-mosin_Mosin-Suppressor",
				muzzle2 = "attachment-muzzle2-mosin_Mosin-Brake",
				
				holo = "attachment-holo-normal_Holo",
				},
			mosinm 		= {	
				muzzle1 = "attachment-muzzle1-mosin_Mosin-Suppressor",
				muzzle2 = "attachment-muzzle2-mosin_Mosin-Brake",
				
				holo = "attachment-holo-normal_Holo",
				},
			},
		}

local gunScriptLookUp = {
	["gun-ak50"]="AK50",
	["gun-ak74"]="AK74",
	["gun-ak101"]="AK101",
	["gun-ak74m"]="AK74M",
	["gun-akm"]="AKM",
	["gun-cz1012"]="CZ-1012",
	["gun-g3"]="G3",
	["gun-g36k"]="G36",
	["gun-ar15"]="M4A1",
	["gun-m16"]="M16",
	["gun-m107"]="M107",
	["gun-m870"]="M870",
	["gun-ks23"]="KS23",
	["gun-mosin"]="MosinNagant",
	["gun-mosinm"]="MosinNagantM",
	["gun-mp5"]="MP5",
	["gun-sg553"]="SG553",
	["gun-mp43"]="MP43",
	["gun-p90"]="P90",
	["gun-pp19"]="PP19",
	["gun-ppsh41"]="PPSh",
	["gun-rpg"]="RPG",
	["gun-scarh"]="SCAR-H",
	["gun-scarhg"]="SCAR-Hg",
	["gun-scarl"]="SCAR-L",
	["gun-scarlg"]="SCAR-Lg",
	["gun-sks"]="SKS",
	["gun-sv98"]="SV98",
	["gun-svd"]="SVD",
	["gun-vector"]="VECTOR",

	["gun-fiveseven"] = "FiveSeven",
	["gun-g17"] = "G17",
	["gun-deagle"] = "Dessert Eagle",
	["gun-g18"] = "G18",
	["gun-sawedoff"] = "Sawed Off",
	["gun-tt33"] = "TT33",
	["gun-m9"] = "M9",
	["gun-pkm"] = "PKM", -- (v2 fix) was missing: picking up a PKM crashed tick() (scriptName nil)
}
function GetDimensions(item)
	local itemInfos = Split(item, "_") -- Gets item info by splitting it.
	local id = itemInfos[1] -- Id is the first item info.
	local idInfos = Split(id, "-")
	local itemType = getItemType(id)
	local w, h = 1, 1

	-- check if the dimensions for this item type exist; if not, use 'general'
	local _dimType = dimensions[itemType] or dimensions.general
	if _dimType then
		-- check if the dimensions for this specific item type exist; if not, use 'default'
		local _dims
		if idInfos[1]=="meds" then
			_dims = _dimType[idInfos[#idInfos]] or _dimType._default or {1,1}
		else
			_dims = _dimType[id] or _dimType._default or {1,1}
		end
		if _dims then
			w, h = unpack(_dims)
		end
	end
	
	-- special case for guns with attachments! yahoo!
	if idInfos[1] == 'gun' then
		local _, dw, dh = attList(item)
		w, h = w + dw, h + dh
	end
	
	return w, h
end

function InitInventory()
	invChanged=true
	backpack = {} -- Makes a table with backpack
	for i = 1,8 do	
		backpack[i] = {}
		for j = 1,15 do
			backpack[i][j] = {"", {0, 0}, 1, 1}
		end
	end
	guns = {}
	--for i = 1,1 do
		guns[1] = {}
		guns[1][1] = {"", {0, 0}, 7, 2}
		guns[1][2] = {"", {0, 0}, 2, 2}
		guns[1][3] = {"", {0, 0}, 2, 2}
		guns[1][4] = {"", {0, 0}, 7, 2}
	--end
	armor = {}
	--for i = 1,1 do
		armor[1] = {}
		armor[1][1] = {"", {0, 0}, 3, 3}
		armor[1][2] = {"", {0, 0}, 2, 2}
		armor[1][3] = {"", {0, 0}, 2, 1}
	--end
	health = {}
	for i = 1,1 do
		health[i] = {}
		for j = 1,6 do
			health[i][j] = {"", {0, 0}, 1, 1}
		end
	end
	loot = {}
	for i = 1,8 do
		loot[i] = {}
		for j = 1,15 do
			loot[i][j] = {"", {0, 0}, 1, 1}
		end
	end
	
	_invOn = false
	_invState = ""
	_shopState = ""

	curshop = nil
	buying = true
	invMarket = {}
	removeShopItem = 0

	InvGrab = {}
	InvGrab.info = {{"", {0, 0}, 1, 1}, 0, 0, backpack}

	rightclickinfo = {"", 0, 0, ""}
	magtable = {}

	gunslist = {"gun-ak74m", "gun-ak101", "gun-ak74", "gun-ak12", "gun-ak50", "gun-akm", "gun-pp19", "gun-ar15", "gun-m16", "gun-m107", "gun-scarl", "gun-scarlg", "gun-scarh", "gun-scarhg", "gun-vector", "gun-mosin", "gun-mosinm", "gun-sks", "gun-mp43", "gun-rpg", "gun-ppsh41", "gun-mgl", "gun-ks23", "gun-svd", "gun-cz1012", "gun-g36k", "gun-sg553", "gun-g3", "gun-mp5", "gun-m870", "gun-p90", "gun-sv98", "gun-pkm"}
	gunslist2 = {"gun-g17", "gun-mp443", "gun-deagle", "gun-tt33", "gun-m9", "gun-sawedoff", "gun-g18", "gun-fiveseven"}
	meleelist = {"melee-BaseballBat", "melee-CombatKnife", "melee-FireAxe", "melee-Katana", "melee-Pipe", "melee-Tomahawk", "melee-DamnedScythe", "melee-Crowbar"} -- (v2 fix) Crowbar was missing

	hololist = {"gun-ak74m", "gun-ak101", "gun-ak74", "gun-ak12", "gun-akm", "gun-pp19", "gun-ar15", "gun-m16", "gun-m107", "gun-scarl", "gun-scarlg", "gun-scarh", "gun-scarhg", "gun-vector", "gun-mosinm", "gun-sks", "gun-mp43", "gun-svd", "gun-cz1012", "gun-g36k", "gun-sg553", "gun-g3", "gun-mp5", "gun-m870", "gun-p90", "gun-sv98", "gun-g17", "gun-deagle", "gun-tt33", "gun-m9", "gun-g18", "gun-fiveseven"}

	HoverDesc={}
	HoverDesc.cord = {0, 0}
	HoverDesc.timer = 0
	HoverDesc.invTable = nil

	toggleprimary = false
	cantoggleprimary = false
	equipTimer = 0
	SetInt("inventory.curprimary", 1)
end

function LoadInventory()
	invChanged=true
	for i = 1,8 do
		for j = 1,15 do
			local item = GetString("savegame.mod.inventory.backpack."..i.."_"..j..".item")
			if item ~= "" then
				local rotation = GetInt("savegame.mod.inventory.backpack."..i.."_"..j..".rotation")
				local w, h = GetDimensions(item)
				placeItem(backpack, {{item, {i, j}, w, h, rotation = rotation}, 0, 0}, i, j)
			end
		end
	end

	for i = 1,8 do
		for j = 1,15 do
			local item = GetString("savegame.mod.inventory.stash."..i.."_"..j..".item")
			if item ~= "" then
				local rotation = GetInt("savegame.mod.inventory.stash."..i.."_"..j..".rotation")
				local w, h = GetDimensions(item)
				placeItem(stash, {{item, {i, j}, w, h, rotation = rotation}, 0, 0}, i, j)
			end
		end
	end

	for i = 1,1 do
		for j = 1,3 do
			local item = GetString("savegame.mod.inventory.armor."..j..".item")
			if item ~= "" then
				local w, h = GetDimensions(item)
				placeItem(armor, {{item, {i, j}, w, h}, 0, 0}, i, j, true)
			end
		end
	end

	for i = 1,1 do
		for j = 1,4 do
			local item = GetString("savegame.mod.inventory.guns."..j..".item")
			if item ~= "" then
				local w, h = GetDimensions(item)
				placeItem(guns, {{item, {i, j}, w, h}, 0, 0}, i, j, true)
			end
		end
	end
end

function SaveInventory()
	local pw=0
	-- standard inv
	for i = 1,8 do
		for j = 1,15 do
			local invSlot = backpack[i][j]
			local item = invSlot[1]
			local rotation = invSlot.rotation
			SetString("inventory.backpack."..i.."_"..j..".item", item)
			if item==""then
				ClearKey("savegame.mod.inventory.backpack."..i.."_"..j)
			else
				SetString("savegame.mod.inventory.backpack."..i.."_"..j..".item", item)
				if rotation==0 then
					ClearKey("savegame.mod.inventory.backpack."..i.."_"..j..".rotation")
				else
					SetInt("savegame.mod.inventory.backpack."..i.."_"..j..".rotation", rotation)
				end
			end
			local w,h=GetDimensions(item)
			pw=pw+w*h
		end
	end
	for i = 1,8 do
		for j = 1,15 do
			local invSlot = stash[i][j]
			local item = invSlot[1]
			local rotation = invSlot.rotation
			SetString("inventory.stash."..i.."_"..j..".item", item)
			if item==""then
				ClearKey("savegame.mod.inventory.stash."..i.."_"..j)
			else
				SetString("savegame.mod.inventory.stash."..i.."_"..j..".item", item)
				if rotation==0 then
					ClearKey("savegame.mod.inventory.stash."..i.."_"..j..".rotation")
				else
					SetInt("savegame.mod.inventory.stash."..i.."_"..j..".rotation", rotation)
				end
			end
		end
	end
	-- special inv, rotation ignored
	for i = 1,1 do
		for j = 1,4 do
			local invSlot = guns[i][j]
			local item = invSlot[1]
			SetString("inventory.guns."..j..".item", item)
			if item==""then
				ClearKey("savegame.mod.inventory.guns."..j)
			else
				SetString("savegame.mod.inventory.guns."..j..".item", item)
			end
			local w,h=GetDimensions(item)
			pw=pw+w*h
		end
	end
	for i = 1,1 do
		for j = 1,3 do
			local invSlot = armor[i][j]
			local item = invSlot[1]
			SetString("inventory.armor."..j..".item", item)
			if item==""then
				ClearKey("savegame.mod.inventory.armor."..j)
			else
				SetString("savegame.mod.inventory.armor."..j..".item", item)
			end
			local w,h=GetDimensions(item)
			pw=pw+w*h
		end
	end
	SetInt("inventory.weight",pw) -- max is 159
end

function PlayBackpackSound()
    PlaySound(SOUNDS.backpack, GetPlayerTransform().pos, 0.75)
end
function PlayGunEquipSound()
	PlaySound(SOUNDS.gunequip)
	PlaySound(LoadSound("MOD/snd/Foley/pickup/weap_pickup_rattle_0.ogg"))
end
function PlayPistolEquipSound()
	PlaySound(SOUNDS.pistolequip)
	PlaySound(LoadSound("MOD/snd/Foley/pickup/weap_pickup_rattle_0.ogg"))
end
function PlayArmorEquipSound(item)
	local id = Split(item,"_")[1]
	local itemType = Split(id,"-")[1]
	if id == "vest-thor" or id == "vest-zabralo" or id == "vest-gzhel" or id == "vest-killa" then
		PlaySound(SOUNDS.vestequipheavy)
	elseif itemType == "eyewear" then
		PlaySound(LoadSound("MOD/snd/Inventory/night_vision_foley_on.ogg"))
	elseif itemType == "helmet" then
		PlaySound(SOUNDS.helmetequip)
	else
		PlaySound(SOUNDS.vestequiplight)
	end
end
function PlayWeaponDropSound(item)
	local id = Split(item,"_")[1]
	local type = "ar"
	if id == "gun-rpg" then
		type = "launcher"
	elseif id == "gun-tt33" or id == "gun-g17" or id == "gun-g18" or id == "gun-sawedoff" or id == "gun-m9" then
		type = "pistol"
	elseif id == "gun-mp5" or id == "gun-vector" or id == "gun-p90" or id == "gun-ppsh41" then
		type = "smg"
	elseif id == "gun-svd" or id == "gun-ak50" or id == "gun-m107" then
		type = "sniper"
	end
	PlaySound(LoadSound("MOD/snd/Foley/drop/weap_drop_"..type.."_sand_0.ogg"))
end
function PlayPickupSound(item)
	local id = Split(item,"_")[1]
	local idInfos = Split(id,"-")
	if idInfos[1] == "gun" then
		PlaySound(SOUNDS.gunequip)
	elseif idInfos[1] == "general" then
		PlaySound(LoadSound("MOD/snd/Foley/pickup/weap_pickup_rattle_0.ogg"))
	elseif idInfos[1] == "attachment" then
		PlaySound(LoadSound("MOD/snd/Foley/pickup/weap_pickup_rattle_0.ogg"))
	elseif idInfos[1] == "grenade" or idInfos[1] == "grenade1" then
		PlaySound(LoadSound("MOD/snd/Foley/pickup/gren_pickup_frag.ogg"))
	elseif idInfos[1] == "bullets" then
		PlaySound(LoadSound("MOD/snd/Foley/pickup/ammo_pickup_0.ogg"))
	elseif string.sub(id,1,3) == "mag" then
		PlaySound(LoadSound("MOD/snd/Foley/pickup/mag_pickup_0.ogg"))
	elseif id == "food5" or id == "food6" or id == "food7" then
		PlaySound(LoadSound("MOD/snd/Foley/pickup/pickup_waterbottle_0.ogg"))
	elseif id == "food3" then
		PlaySound(LoadSound("MOD/snd/Foley/pickup/pickup_mre_0.ogg"))
	else
		PlayBackpackSound()
	end
end

function PlayHealingSound(healtype)
	if healtype == "general" then
    	PlaySound(SOUNDS.meds.ai2, GetPlayerTransform().pos, 1, false)
    elseif healtype == "bleed" then
    	PlaySound(SOUNDS.meds.bandage, GetPlayerTransform().pos, 1, false)
    elseif healtype == "fracture" then
    	PlaySound(SOUNDS.meds.splint, GetPlayerTransform().pos, 1, false)
   	elseif healtype == "surgery" then
    	PlaySound(SOUNDS.meds.cms, GetPlayerTransform().pos, 1, false)
    end
end

function init()
	economytimer = math.random(60*math.random(3,7),60*math.random(15,33))+math.random()
	inflation = 1.00
	economy = {}
	SprintMultiplier = 1
	invChanged = true
	Init_Settings()
	recylce = false
	InitInventory()
	refreshShop()
	stash = {}
	for i = 1,8 do
		stash[i] = {}
		for j = 1,15 do
			stash[i][j] = {"", {0, 0}, 1, 1}
		end
	end
	pickupqueue = {}
	if not GetBool("savegame.mod.inventory.wipe.2") then
		SaveInventory()
		SetBool("savegame.mod.inventory.wipe.2", true)
	end
	LoadInventory()

	SaveInventory()

	scripts = {}

	SOUNDS={}
	SOUNDS.cash = LoadSound("MOD/snd/UI/UI_Shop_Cash.ogg")
	SOUNDS.backpack = LoadSound("MOD/snd/Inventory/backpack/backpack0.ogg")
	SOUNDS.dropWeapon = LoadSound("MOD/snd/Foley/drop/weap_drop_0.ogg")
	SOUNDS.dropHelmet = LoadSound("MOD/snd/Foley/drop/helmet_drop_0.ogg")
	SOUNDS.dropItem = LoadSound("MOD/snd/Foley/drop/item_drop_0.ogg")
	SOUNDS.loadBullet = LoadSound("MOD/snd/bullet_inv.ogg")
	SOUNDS.nvgon = LoadSound("MOD/snd/Inventory/NVG/night_vision_on.ogg")
	SOUNDS.nvgoff = LoadSound("MOD/snd/Inventory/NVG/night_vision_off.ogg")
	SOUNDS.meds = {}
	SOUNDS.meds.ai2 = LoadSound("MOD/snd/Inventory/Meds/ai2.ogg")
	SOUNDS.meds.bandage = LoadSound("MOD/snd/Inventory/Meds/bandage.ogg")
	SOUNDS.meds.cms = LoadSound("MOD/snd/Inventory/Meds/cms.ogg")
	SOUNDS.meds.splint = LoadSound("MOD/snd/Inventory/Meds/splint.ogg")
	SOUNDS.uinext = LoadSound("MOD/snd/UI/UI_Select.ogg")
	SOUNDS.uiback = LoadSound("MOD/snd/UI/UI_Select_Light.ogg")
	SOUNDS.gunequip = LoadSound("MOD/snd/Weapons/Shared/Deploy/weapon_equip_0.ogg")
	SOUNDS.pistolequip = LoadSound("MOD/snd/Weapons/Shared/Deploy/weapon_equip_pistol_0.ogg")
	SOUNDS.vestequipheavy = LoadSound("MOD/snd/Inventory/vest/heavyvest_puton_0.ogg")
	SOUNDS.vestequiplight = LoadSound("MOD/snd/Inventory/vest/lightvest_puton_0.ogg")
	SOUNDS.helmetequip = LoadSound("MOD/snd/helmet_puton_0.ogg")
	SOUNDS.perkPickup = LoadSound("MOD/snd/Inventory/PerkMachine/perkpickup.ogg")

	------NVG SYSTEM------
	add = 1
	nvgon = false
	maxtim = 2
	tim = 0
	findEnemyTimer = 0
	enemyParts = {}
	thermalrange = 50
	playerthermalrange = Vec(30,30,30)
	------VITALS SYSTEM------
	if GetString("savegame.mod.difficulty") == "hardcore" then 
		hunger = GetFloat("savegame.mod.hunger") or math.random(50,100)
		thirst = GetFloat("savegame.mod.thirst") or math.random(50,100)
	else
		hunger = GetFloat("savegame.mod.hunger") or 100
		thirst = GetFloat("savegame.mod.thirst") or 100
	end

	devmultiplier = 1
	malnutrition = 1
	dehydration = 1
	hungertimer = 0
	thirsttimer = 0
	dead = false

	uitimer = 0
	uiopacity = 0
	medtimer = 0
	medtimermax = 0
	currentmed = ""
	currentmedbodypart = 0
	lastPlayerTool=""

	local parts0 = FindTriggers("hitbox",true)
	parts = {}
	for i = 1, 6 do
		if GetTagValue(parts0[i], "hitbox") == "HEAD" then
			parts[1] = parts0[i]
		elseif GetTagValue(parts0[i], "hitbox") == "TORSO" then
			parts[2] = parts0[i]
		elseif GetTagValue(parts0[i], "hitbox") == "LARM" then
			parts[3] = parts0[i]
		elseif GetTagValue(parts0[i], "hitbox") == "RARM" then
			parts[4] = parts0[i]
		elseif GetTagValue(parts0[i], "hitbox") == "RLEG" then
			parts[5] = parts0[i]
		elseif GetTagValue(parts0[i], "hitbox") == "LLEG" then
			parts[6] = parts0[i]
		end
	end

	packmagtimer = 0

	updateCounter = 0

	LETITERROR=false


end

function ClearBulletTypes(iteminfo)
	iteminfos = Split(iteminfo,"-")
	for i=1,#iteminfos do
		iteminfos[i] = ""
	end
	return ""
end

function CountIdenticalString(Table)
    local counts = {}

    for _, String in ipairs(Table) do
        if counts[String] then
            counts[String] = counts[String] + 1
        else
            counts[String] = 1
        end
    end
    
    return counts
end

function drawRightClickMenu(noAttachmentModification)
	local item = rightclickinfo[1]
	local itemInfos = Split(item, "_")
	local itemID = itemInfos[1]
	local idInfos = Split(itemID, "-")
	local w, h = GetDimensions(item)
	local test = true

	UiAlign("center middle")
	UiFont("bold.ttf", 20)
	UiColor(0,0,0,0.7)
	if string.sub(item, 1, 3) == "mag" then
		UiPush()
			UiImageBox("ui/common/box-solid-6.png", 120, 30, 6, 6)
			local amount = itemInfos[3]
			if tonumber(amount) > 0 then
				UiColor(1, 1, 1)
				if UiTextButton("Unload Ammo") then
					local caliber = idInfos[3]
					local caliberDisplay = calIDtoDisplayCal(caliber)
					local types = Split(itemInfos[6],"-")
					local Calibers = {}
					local AmountCalibers = {}
					local Identicals = CountIdenticalString(types)
					for strings, counts in pairs(Identicals) do		
						table.insert(pickupqueue, IDBuilder({"bullets-"..caliber.."-"..strings,caliberDisplay,counts}))
					end
					-- for i=1,amount do 
						-- if not AmountCalibers
						-- table.insert(pickupqueue, IDBuilder({"bullets-"..caliber.."-"..types[i],caliberDisplay,1}))
						-- --DebugPrint(IDBuilder({"bullets-"..caliber,types[i],caliberDisplay,1}))
						-- types[i] = ""
					-- end
					
					itemInfos[6] = ""
					
					--itemInfos[6] = ClearBulletTypes(itemInfos[6]) 
					itemInfos[3]=0
					rightclickinfo[5][rightclickinfo[2]][rightclickinfo[3]][1] = IDBuilder(itemInfos)
					--DebugPrint(IDBuilder(itemInfos))
				end
			else
				UiColor(1,0.4,0.4)
				UiText("Mag Is Empty")
			end
		UiPop()
	elseif string.sub(item, 1, 4) == "food" then
		UiPush()
			UiImageBox("ui/common/box-solid-6.png", 60, 30, 6, 6)
			UiColor(1, 1, 1)
			local buttontext = "Eat"
			local itemIDNum = tonumber(itemID:sub(5,#itemID))or 0
			if itemIDNum == 5 or itemIDNum == 6 or itemIDNum == 7 or itemIDNum == 8 or itemIDNum == 13 or itemIDNum == 18 then
				buttontext = "Drink"
			end
			if UiTextButton(buttontext) then
				rightclickinfo[5][rightclickinfo[2]][rightclickinfo[3]][1] = ""
				clearItem(rightclickinfo[5], {{"", {0, 0}, w, h}, rightclickinfo[2], rightclickinfo[3], rightclickinfo[5]})
				hunger = hunger + tonumber(itemInfos[3])
				thirst = thirst + tonumber(itemInfos[4])
				SetString("health.foodconsumed", itemID)
				PlaySound(LoadSound("MOD/snd/Inventory/backpack/"..itemID..".ogg"))
			end
		UiPop()
	elseif string.sub(item, 1, 9) == "meds-stim" then
		UiPush()
			local itemType = idInfos[3]
			UiImageBox("ui/common/box-solid-6.png", 70, 30, 6, 6)
			UiColor(1, 1, 1)
			if UiTextButton("Inject") then
				SetBool("health.statuseffects."..itemType, true)
				rightclickinfo[5][rightclickinfo[2]][rightclickinfo[3]][1] = ""
				clearItem(rightclickinfo[5], {{"", {0, 0}, 1, 1}, rightclickinfo[2], rightclickinfo[3], rightclickinfo[5]})
			end
		UiPop()
	elseif idInfos[1] == "gun" then
		UiPush()
			if not noAttachmentModification and not test then -- ATTACHMENT REMOVE SECTION
				local isattachedametns = true
				if not (idInfos[2] == "ak50" or idInfos[2] == "sv98" or idInfos[2] == "rpg" or idInfos[2] == "cz1012" or idInfos[2] == "ks23" or idInfos[2] == "ppsh41" or idInfos[2] == "mp43" or idInfos[2] == "sawedoff") then
					if #itemInfos >= 8 then	
						local itemAttInfos = Split(itemInfos[8], "-")		
						for i=1,#itemAttInfos do 
							if not (itemAttInfos[i] == "removed" or itemAttInfos[i] == "") then
								isattachedametns = false				
							end
						end
					end

					UiTranslate(0,-15)
					UiPush()
						--local itemAttInfos = Split(itemInfos[8], "-")
						if isattachedametns then
							local buttontext = "No Attachments"
							local tw, _ = UiGetTextSize(buttontext)
							UiImageBox("ui/common/box-solid-6.png", tw+10, 30, 6, 6)
							UiColor(1,0.4,0.4)
							UiText(buttontext)
						else
							local buttontext = "Clear Attachments"
							local tw, _ = UiGetTextSize(buttontext)
							UiImageBox("ui/common/box-solid-6.png", tw+10, 30, 6, 6)
							UiColor(1,1,1)
							if UiTextButton(buttontext) then
								ClearAttachments(item)
							end
						end
					UiPop()
					UiTranslate(0,30)
				end
			end
			do -- AMMO MAGAZINE UNLOAD SECTION
				-- if the gun have ammo or (is not Internal feed and have magazine attached) (internal feed guns have magazine "attached")
				if tonumber(itemInfos[5]) > 0 or (itemInfos[4] ~= "Internal" and itemInfos[3] ~= "none") then
					local buttontext = "Unload Mag"
					if itemInfos[4] == "Internal" then
						buttontext = "Unload Gun"
					elseif itemInfos[3] == "none" then
						buttontext = "Unload Chamber"
					end
					local tw, th = UiGetTextSize(buttontext)
					UiImageBox("ui/common/box-solid-6.png", tw+10, 30, 6, 6)
					UiColor(1, 1, 1)
					if UiTextButton(buttontext) then
						SetBool("inventory.update_guns1", true)
						SetBool("inventory.update_guns2", true)
						SetBool("inventory.update_guns4", true)

						-- RPG exception
						if itemID == "gun-rpg" then
							SetString("inventory.pickup", itemInfos[3].."_"..itemInfos[4])
							itemInfos[3]="none"
							itemInfos[4]="Unloaded"
							itemInfos[5]=0
							itemInfos[6]=1
							rightclickinfo[5][rightclickinfo[2]][rightclickinfo[3]][1] = IDBuilder(itemInfos)
							PlaySound(LoadSound("MOD/snd/Weapons/rpg/reload/RPG_reload_fast_unload_0.ogg"))
						else
							-- initialize the new item string
							local updatedItem=""
							-- if the gun is using Internal feed system
							if itemInfos[4] == "Internal" then
								local caliber = displayCaltoCalID(itemInfos[7])
															
								local types = Split(itemInfos[10],"-")
								local Identicals = CountIdenticalString(types)
								for strings, counts in pairs(Identicals) do		
									table.insert(pickupqueue, IDBuilder({"bullets-"..caliber.."-"..strings,itemInfos[7],counts}))
								end
								
								itemInfos[5]=0
								itemInfos[10] = ""
								
								updatedItem = IDBuilder(itemInfos)
							-- if the gun is using magazine feed system
							else
								-- if the gun don't have magazine attached (unload chamber)
								if itemInfos[3] == "none" then
									local caliber = displayCaltoCalID(itemInfos[7])
									--DebugPrint(IDBuilder({"bullets-"..caliber,itemInfos[7],itemInfos[5],Split(itemInfos[10],"-")[1]}))
									SetString("inventory.pickup", IDBuilder({"bullets-"..caliber.."-"..Split(itemInfos[10],"-")[1],itemInfos[7],itemInfos[5]}))
									
									itemInfos[4]="Unloaded"
									itemInfos[5]=0
									itemInfos[6]=0
									itemInfos[10] = ""
									updatedItem = IDBuilder(itemInfos)

									if string.sub(itemID,5,6) == "ak" or string.sub(itemID,5,7) == "svd" then
										PlaySound(LoadSound("MOD/snd/Weapons/ak/ak_charge_fast.ogg"))
									elseif idInfos[2] == "g17" or idInfos[2] == "g18" or idInfos[2] == "tt33" or idInfos[2] == "fiveseven" then
										PlaySound(LoadSound("MOD/snd/Weapons/g17/g17slidepull.ogg"))
									elseif idInfos[2] == "sv98" then
										PlaySound(LoadSound("MOD/snd/Weapons/mosin/mosin_rechamber.ogg"))
									else
										PlaySound(LoadSound("MOD/snd/Weapons/m4a1/m4a1_charge.ogg"))
									end
								else
									-- calculate the ammo that will stay in the chamber (if the mag have atleast 1 ammo then that ammo will stay in chamber)
									local ammoInChamber = math.min(tonumber(itemInfos[5]),1)
									-- funny gun exception
									if itemID == "gun-ppsh41" then
										ammoInChamber = 0
									end
									-- remove the ammount of ammo staying in the chamber from the magazine
									
									local types = Split(itemInfos[10],"-")
									local types2 = Split(itemInfos[10],"-")
									local amount123 = #types
									if ammoInChamber ~= 0 then 
										types[amount123] = nil
									end
									
									if itemID == "gun-ppsh41" then
										--DebugPrint(itemInfos[10])
										SetString("inventory.pickup", IDBuilder({itemInfos[3],itemInfos[4],tonumber(itemInfos[5]),itemInfos[6],itemInfos[7],table.concat(Split(itemInfos[10],"-"), "-")}))
									else 									
										SetString("inventory.pickup", IDBuilder({itemInfos[3],itemInfos[4],tonumber(itemInfos[5])-ammoInChamber,itemInfos[6],itemInfos[7],table.concat(types, "-")}))
									end
									--DebugPrint(IDBuilder({itemInfos[3],itemInfos[4],tonumber(itemInfos[5])-ammoInChamber,itemInfos[6],itemInfos[7],itemInfos[10]}))
															
									-- gun have no more magazine
									itemInfos[3]="none"
									itemInfos[4]="Unloaded"
									-- keep the ammount of ammo staying in the chamber in the gun
									itemInfos[5]=ammoInChamber
									itemInfos[6]=0
									itemInfos[10] = types2[amount123]
									updatedItem = IDBuilder(itemInfos)

									if string.sub(itemID,5,6) == "ak" or string.sub(itemID,5,7) == "svd" then
										PlaySound(LoadSound("MOD/snd/Weapons/ak/ak_magout_fast.ogg"))
									elseif idInfos[2] == "g17" or idInfos[2] == "g18" or idInfos[2] == "tt33" or idInfos[2] == "fiveseven" or idInfos[2] == "vector" then
										PlaySound(LoadSound("MOD/snd/Weapons/g17/g17reload.ogg"))
									else
										PlaySound(LoadSound("MOD/snd/Weapons/m4a1/m4a1_magout.ogg"))
									end
								end
							end
							SetString("inventory.guns."..rightclickinfo[3]..".item", updatedItem)
							rightclickinfo[5][rightclickinfo[2]][rightclickinfo[3]][1] = updatedItem
							SetBool("inventory.update_guns"..rightclickinfo[3], true)
						end
					end
				else
					UiPush()
					local tw, th = UiGetTextSize("Gun Is Empty")
					UiImageBox("ui/common/box-solid-6.png", tw+10, 30, 6, 6)
					UiColor(1,0.4,0.4)
					UiText("Gun Is Empty")
					UiPop()
				end
			end
		UiPop()
	--elseif string.sub(item, 1, 4) == "vest" then
	--	local armorhppercent = tonumber(itemInfos[3])/tonumber(itemInfos[4])

	--	if rightclickinfo[4] == "armor" then
	--		UiTranslate(3*30, 3*30)
	--	end
	--	UiImageBox("ui/common/box-solid-6.png", 120, 30, 6, 6)
	--	if GetInt("inventory.count_kevlar") > 0 then
	--		UiColor(1, 1, 1)
	--		if UiTextButton("Repair") and armorhppercent < 1 then
	--			itemInfos[3] = itemInfos[4]
	--			rightclickinfo[5][rightclickinfo[2]][rightclickinfo[3]][1] = IDBuilder(itemInfos)
	--		end
	--	else
	--		UiColor(1,0.4,0.4)
	--		UiText("No Kevlar")
	--	end
	else
		rightclickinfo = {"", 0, 0, ""}
	end
end

function ClearAttachments(item)
	local itemInfos = Split(item, "_")
	local id = itemInfos[1]
	local idInfos = Split(id, "-")
	local whichgun = idInfos[2] 
	local itemAttInfos = Split(itemInfos[8], "-")
	local whichone = gunattachments[whichgun].muzzle
	
	
	local cursight = itemAttInfos[1] or nil
	local curmuzzle = itemAttInfos[gunattachments[whichgun].muzzle] or nil
	local curside = itemAttInfos[gunattachments[whichgun].side] or nil
	
	table.insert(pickupqueue,attachmentswap.weapons[whichgun][curmuzzle])
	table.insert(pickupqueue,attachmentswap.weapons[whichgun][cursight])
	table.insert(pickupqueue,attachmentswap.sides[curside])
	
	
	
	
	for i=1,#itemAttInfos do 
		if i ~= gunattachments[whichgun].camo and i ~= gunattachments[whichgun].barrel and i ~= gunattachments[whichgun].guard then
			itemAttInfos[i] = "" 
		end
	end
	itemInfos[8] = table.concat(itemAttInfos,"-")
	rightclickinfo[5][rightclickinfo[2]][rightclickinfo[3]][1] = IDBuilder(itemInfos)
end

function placeItem(invTable, grabinfo, i, j, gunslot)
	--placeItem(backpack, {{item, {i, j}, w, h, rotation = 0}, 0, 0}, i, j)
	local invSizeX = #invTable
	local invSizeY = #invTable[1]
	
	invChanged=true
	--DebugPrint(invTable)
	local invSlot = grabinfo[1]
	local item, parent, w, h, rotation = invSlot[1], invSlot[2], invSlot[3], invSlot[4], invSlot._tempRotation or invSlot.rotation or 0
	local origx, origy, origtable = grabinfo[2], grabinfo[3], grabinfo[4]
	local collision = false

	local itemW, itemH = GetDimensions(item)
	if rotation % 2 == 1 then
		w, h = itemH, itemW
	end
	
	if i < 1 or j < 1 or i > invSizeX or j > invSizeY then -- early termination
		if (invSlot.rotation or 0) % 2 == 1 then -- use slot's original rotation when putting item back to where its from
			w, h = itemH, itemW
		else
			w, h = itemW, itemH
		end
		invSlot[3] = w
		invSlot[4] = h
		invSlot._tempRotation = nil
		origtable[origx][origy] = invSlot
		if origtable and origtable ~= guns and origtable ~= armor then
			for a = 1, w do
				for b = 1, h do
					origtable[origx+a-1][origy+b-1][2] = {origx, origy}
				end
			end
		end
		return
	end

	local itemInfos = Split(item, "_")
	local id = itemInfos[1]
	local idInfos = Split(id, "-")

	local targetX, targetY = i, j
	if invTable[i][j][2][1]~=0 and invTable[i][j][2][2]~=0 and invTable[i][j][1]=="" then
		targetX, targetY = invTable[i][j][2][1], invTable[i][j][2][2]
	end
	local targetSlot = invTable[targetX][targetY]
	local targetItem = targetSlot[1]
	local targetItemInfos = Split(targetItem, "_")
	local targetId = targetItemInfos[1]
	local targetIdInfos = Split(targetId, "-")
	local newInvSlot = { -- used when item is moved
		item,
		{targetX, targetY},
		w,
		h,
		rotation = rotation,
	}

	if gunslot then
		local placeable = false
		if invTable == guns then
			if guns[1][targetY][1] == "" then
				local curgunslist
				if targetY == 1 or targetY == 4 then
					curgunslist = gunslist
				elseif targetY == 2 then
					curgunslist = gunslist2
				else
					curgunslist = meleelist
				end
	
				for k = 1, #curgunslist do
					if id == curgunslist[k] then
						placeable = true
						break
					end
				end
			else
				collision = true
			end
		elseif invTable == armor then
			if armor[1][targetY][1] ~= "" then
				collision = true
			else
				if (idInfos[1] == "vest" and targetY == 1) or (idInfos[1] == "helmet" and targetY == 2) or (idInfos[1] == "eyewear" and targetY == 3) then
					placeable = true
				end
			end
		elseif invTable == health then
			local bodyPart = parts[targetY]
			if idInfos[1]=="meds" then
				local medTypes = idInfos

				for index = 2, #medTypes-1 do
					local curmedType = medTypes[index]
					currentmed = idInfos[#idInfos]

					if curmedType == "bleed" then
						local BLEED = HasTag(bodyPart, "Bleed")
						local durability = tonumber(itemInfos[3])
						if BLEED then
							if idInfos[#idInfos] == "ifak" or idInfos[#idInfos] == "car" or idInfos[#idInfos] == "grizzly" then
								if durability >= 50 then
									durability = durability - 50
								else
									origtable[origx][origy] = {item, {origx, origy}, w, h}
									if origtable and origtable ~= guns and origtable ~= armor then
										for a = 1, w do
											for b = 1, h do
												origtable[origx+a-1][origy+b-1][2] = {origx, origy}
											end
										end
									end
									return
								end
							else
								durability = durability - 1
							end
							RemoveTag(bodyPart, "Bleed")
							if durability == 0 then
								medtimer = 4
								medtimermax = 4
								PlayHealingSound(curmedType)
								return
							else
								itemInfos[3]=math.floor(durability)
								origtable[origx][origy] = {IDBuilder(itemInfos), {origx, origy}, w, h}
								if origtable and origtable ~= guns and origtable ~= armor then
									for a = 1, w do
										for b = 1, h do
											origtable[origx+a-1][origy+b-1][2] = {origx, origy}
										end
									end
								end
								medtimer = 4
								medtimermax = 4
								PlayHealingSound(curmedType)
								return
							end
						end
					elseif curmedType == "fracture" then
						local FRACTURE = HasTag(bodyPart, "Fracture")
						local durability = tonumber(itemInfos[3])
						if FRACTURE then
							if idInfos[#idInfos] == "grizzly" then
								durability = durability - 50
							else
								durability = durability - 1
							end
							RemoveTag(bodyPart, "Fracture")
							if durability == 0 then
								medtimer = 4
								medtimermax = 4
								PlayHealingSound(curmedType)
								return
							else
								itemInfos[3]=math.floor(durability)
								origtable[origx][origy] = {IDBuilder(itemInfos), {origx, origy}, w, h}
								if origtable and origtable ~= guns and origtable ~= armor then
									for a = 1, w do
										for b = 1, h do
											origtable[origx+a-1][origy+b-1][2] = {origx, origy}
										end
									end
								end
								medtimer = 4
								medtimermax = 4
								PlayHealingSound(curmedType)
								return
							end
						end
					elseif curmedType == "general" then
						local HP = tonumber(GetTagValue(bodyPart, "CurrentHealth"))
						local MAXHP = tonumber(GetTagValue(bodyPart, "MaxHP"))
						local durability = tonumber(itemInfos[3])
						if HP < MAXHP and HP > 0 then
							if durability <= MAXHP - HP then
								SetTag(bodyPart, "QueriedDamage", -durability)
								-- medtimer = 4+durability/20
								medtimer = 4
								medtimermax = medtimer
								PlayHealingSound(curmedType)
								return
							else
								SetTag(bodyPart, "QueriedDamage", -(MAXHP-HP))
								itemInfos[3]=math.floor(durability-(MAXHP-HP))
								origtable[origx][origy] = {IDBuilder(itemInfos), {origx, origy}, w, h}
								if origtable and origtable ~= guns and origtable ~= armor then
									for a = 1, w do
										for b = 1, h do
											origtable[origx+a-1][origy+b-1][2] = {origx, origy}
										end
									end
								end
								-- medtimer = 4+(MAXHP-HP)/20
								medtimer = 4
								medtimermax = medtimer
								PlayHealingSound(curmedType)
								return
							end
						end
					elseif curmedType == "surgery" then
						local HP = tonumber(GetTagValue(bodyPart, "CurrentHealth"))
						local durability = tonumber(itemInfos[3])
						if HP == 0 then
							durability = durability - 1
							SetTag(bodyPart, "QueriedDamage", -1)
							currentmedbodypart = bodyPart
							if durability == 0 then
								medtimer = 10.8
								medtimermax = medtimer
								PlayHealingSound(curmedType)
								return
							else
								itemInfos[3]=math.floor(durability)
								origtable[origx][origy] = {IDBuilder(itemInfos), {origx, origy}, w, h}
								if origtable and origtable ~= guns and origtable ~= armor then
									for a = 1, w do
										for b = 1, h do
											origtable[origx+a-1][origy+b-1][2] = {origx, origy}
										end
									end
								end
								medtimer = 10.8
								medtimermax = medtimer
								PlayHealingSound(curmedType)
								return
							end
						end
					end
				end
			end
			placeable = false
			collision = true
		end
		local ID2 = Split(id,"-")
		local skip = (id == "general-plate" or id == "general-battery" or string.sub(id, 1, 3) == "mag") and invTable[targetX][targetY][1] ~= ""

		if placeable and not collision and not skip then
			newInvSlot.rotation = 0 -- remove item rotation for special slots
			newInvSlot[3] = itemW -- revert inv slot size
			newInvSlot[4] = itemH -- revert inv slot size
			if invTable == guns then
				if targetY == 1 then
					invTable[targetX][targetY] = newInvSlot
					SetString("inventory.guns.1.item", item)
					SetBool("inventory.update_guns1", true)
					SetBool("inventory.update_guns4", true)
				elseif targetY == 4 then
					invTable[targetX][targetY] = newInvSlot
					SetString("inventory.guns.4.item", item)
					SetBool("inventory.update_guns1", true)
					SetBool("inventory.update_guns4", true)
				else
					invTable[targetX][targetY] = newInvSlot
					SetString("inventory.guns.2.item", item)
					SetBool("inventory.update_guns2", true)
				end
			elseif invTable == armor then
				invTable[targetX][targetY] = newInvSlot
			end
		else
			if origtable then
				if origx~=0 and origy~=0 then
					origtable[origx][origy] = grabinfo[1]
				end
				if  origtable ~= guns and origtable ~= armor then
					for a = 1, w do
						for b = 1, h do
							if origx~=0 and origy~=0 then
								origtable[origx+a-1][origy+b-1][2] = {origx, origy}
							end
						end
					end
				end
			end
		end
		if not skip then
			return
		end
	end

	local outofbounds = false
	if targetX+w-1 > invSizeX or targetY+h-1 > invSizeY then
		outofbounds = true
	end

	if invTable ~= guns and invTable ~= armor then
		if not outofbounds then
			for a = 1, w do
				for b = 1, h do
					if invTable[targetX+a-1][targetY+b-1][2][1] ~= 0 or invTable[targetX+a-1][targetY+b-1][1] ~= "" then
						collision = true
					end
				end
			end
		else
			collision = true
		end
	end

	local leftoverammo = 0
	if collision then
		if idInfos[1] == "bullets" then
			if targetIdInfos[1] == "bullets" then
				local caliber1, ammo1, caliber2, ammo2 = id, itemInfos[3], targetId, targetItemInfos[3]
				if caliber1 == caliber2 then
					itemInfos[3]=ammo1+ammo2
					invTable[targetX][targetY][1] = IDBuilder(itemInfos)
					SetString("inventory.pickup", "")
					return
				end
			end
		elseif idInfos[1] == "material" then
			if targetIdInfos[1] == "material" then
				local type1, amount1, type2, amount2 = idInfos[2], itemInfos[3], targetIdInfos[2], targetItemInfos[3]
				if type1 == type2 then
					local totalAmount = amount1+amount2
					local finalAmmount = math.min(totalAmount,4)
					local overFlow = totalAmount-4
					if overFlow > 0 then
						itemInfos[3] = overFlow
						if origtable == nil then
							SetString("inventory.pickup", IDBuilder(itemInfos))
						else
							origtable[origx][origy] = {IDBuilder(itemInfos), {origx, origy}, w, h}
							if origtable and origtable ~= guns and origtable ~= armor then
								for a = 1, w do
									for b = 1, h do
										origtable[origx+a-1][origy+b-1][2] = {origx, origy}
									end
								end
							end
						end
					end
					targetItemInfos[3] = finalAmmount
					invTable[targetX][targetY][1] = IDBuilder(targetItemInfos)
					if not (origtable == nil and amount1+amount2 > 4) then
						SetString("inventory.pickup", "")
					end
					return
				end
			end
			
		elseif id == "general-battery" then
			if targetIdInfos[1] == "eyewear" and origtable ~= nil and GetString("inventory.pickup") == "" then
				local hp=tonumber(targetItemInfos[3])
				local maxhp=tonumber(targetItemInfos[4])
				if hp<maxhp then
					targetItemInfos[3]=math.min(hp+25, maxhp)
					invTable[targetX][targetY][1]=IDBuilder(targetItemInfos)
					origtable[origx][origy]={"", {0, 0}, 1, 1}
					return
				end
			end	
			--------------------------Sights----------------------------'

		elseif checkattachmentCompatibility(item, targetItem) and idInfos[2] == "acog" and _invState ~= "attachmment" then
			if targetIdInfos[1] == "gun" and origtable ~= nil and not (targetIdInfos[2] == "ak50" or targetIdInfos[2] == "mosin" or targetIdInfos[2] == "sv98" or targetIdInfos[2] == "rpg" or targetIdInfos[2] == "CZ-1012" or targetIdInfos[2] == "ks23" or targetIdInfos[2] == "ppsh41" or targetIdInfos[2] == "mp43" or targetIdInfos[2] == "sawedoff") and origtable ~= nil and GetString("inventory.pickup") == "" then
				local whichgun = targetIdInfos[2]
				itemAttInfos = Split(targetItemInfos[8], "-")
				local cursight = itemAttInfos[1] 
					itemAttInfos[1] = "scope" 
					targetItemInfos[8] = table.concat(itemAttInfos,"-")
					invTable[targetX][targetY][1]=IDBuilder(targetItemInfos)
					origtable[origx][origy]={"", {0, 0}, 1, 1}
					--DebugPrint(attachmentswap.weapons[whichgun][cursight])
					SetString("inventory.pickup", attachmentswap.weapons[whichgun][cursight])
					return	
				end
		elseif idInfos[2] == "holo" and _invState ~= "attachmment" then
			if targetIdInfos[1] == "gun" and origtable ~= nil and not (targetIdInfos[2] == "ak50" or targetIdInfos[2] == "mosin" or targetIdInfos[2] == "sv98" or targetIdInfos[2] == "rpg" or targetIdInfos[2] == "CZ-1012" or targetIdInfos[2] == "ks23" or targetIdInfos[2] == "ppsh41" or targetIdInfos[2] == "mp43" or targetIdInfos[2] == "sawedoff") and origtable ~= nil and GetString("inventory.pickup") == "" then
				local whichgun = targetIdInfos[2]
				itemAttInfos = Split(targetItemInfos[8], "-")
				local cursight = itemAttInfos[1] 
				if idInfos[3] == "pistol" and checkattachmentCompatibility(item, targetItem) and itemAttInfos[1] ~= "holo" then 
					itemAttInfos[1] = "holo" 
					targetItemInfos[8] = table.concat(itemAttInfos,"-")
					invTable[targetX][targetY][1]=IDBuilder(targetItemInfos)
					origtable[origx][origy]={"", {0, 0}, 1, 1}
					--DebugPrint(attachmentswap.weapons[whichgun][cursight])
					SetString("inventory.pickup", attachmentswap.weapons[whichgun][cursight])
					return	
				elseif idInfos[3] == "normal" and checkattachmentCompatibility(item, targetItem) and itemAttInfos[1] ~= "holo" then 
					itemAttInfos[1] = "holo" 
					targetItemInfos[8] = table.concat(itemAttInfos,"-")
					invTable[targetX][targetY][1]=IDBuilder(targetItemInfos)
					origtable[origx][origy]={"", {0, 0}, 1, 1}
					DebugPrint(attachmentswap.weapons[whichgun][cursight])
					SetString("inventory.pickup", attachmentswap.weapons[whichgun][cursight])
					return	
				elseif idInfos[3] == "tan" and checkattachmentCompatibility(item, targetItem) and itemAttInfos[1] ~= "holo2" then 
					itemAttInfos[1] = "holo2" 
					targetItemInfos[8] = table.concat(itemAttInfos,"-")
					invTable[targetX][targetY][1]=IDBuilder(targetItemInfos)
					origtable[origx][origy]={"", {0, 0}, 1, 1}
					DebugPrint(attachmentswap.weapons[whichgun][cursight])
					SetString("inventory.pickup", attachmentswap.weapons[whichgun][cursight])
					return	
				end
			end
			--------------------------Muzzles----------------------------					
		elseif idInfos[2] == "muzzle1" then
			if targetIdInfos[1] == "gun" and origtable ~= nil and _invState ~= "attachmment"  and not (targetIdInfos[2] == "ak50" or targetIdInfos[2] == "sv98" or targetIdInfos[2] == "rpg" or targetIdInfos[2] == "CZ-1012" or targetIdInfos[2] == "ks23" or targetIdInfos[2] == "ppsh41" or targetIdInfos[2] == "mp43" or targetIdInfos[2] == "sawedoff") and origtable ~= nil and GetString("inventory.pickup") == "" then
				local whichone = gunattachments[targetIdInfos[2]].muzzle
				local whichgun = targetIdInfos[2]
				itemAttInfos = Split(targetItemInfos[8], "-")
				local curmuzzle = itemAttInfos[whichone] 
				if itemAttInfos[whichone] ~= "muzzle1" and checkattachmentCompatibility(item, targetItem) then 
					itemAttInfos[whichone] = "muzzle1" 
					targetItemInfos[8] = table.concat(itemAttInfos,"-")
					invTable[targetX][targetY][1]=IDBuilder(targetItemInfos)
					origtable[origx][origy]={"", {0, 0}, 1, 1}
					DebugPrint(attachmentswap.weapons[whichgun][curmuzzle])
					SetString("inventory.pickup", attachmentswap.weapons[whichgun][curmuzzle])
					return	
				end
			end	
		elseif idInfos[2] == "muzzle2" then
			if targetIdInfos[1] == "gun" and origtable ~= nil and _invState ~= "attachmment"  and not (targetIdInfos[2] == "ak50" or targetIdInfos[2] == "sv98" or targetIdInfos[2] == "rpg" or targetIdInfos[2] == "CZ-1012" or targetIdInfos[2] == "ks23" or targetIdInfos[2] == "ppsh41" or targetIdInfos[2] == "mp43" or targetIdInfos[2] == "sawedoff") and origtable ~= nil and GetString("inventory.pickup") == "" then
				local whichone = gunattachments[targetIdInfos[2]].muzzle
				local whichgun = targetIdInfos[2]
				itemAttInfos = Split(targetItemInfos[8], "-")
				local curmuzzle = itemAttInfos[whichone] 
				if itemAttInfos[whichone] == "" and checkattachmentCompatibility(item, targetItem) then 
					itemAttInfos[whichone] = "muzzle2" 
					targetItemInfos[8] = table.concat(itemAttInfos,"-")
					invTable[targetX][targetY][1]=IDBuilder(targetItemInfos)
					origtable[origx][origy]={"", {0, 0}, 1, 1}
					return
				elseif itemAttInfos[whichone] ~= "muzzle2" and checkattachmentCompatibility(item, targetItem) then 
					itemAttInfos[whichone] = "muzzle2" 
					targetItemInfos[8] = table.concat(itemAttInfos,"-")
					invTable[targetX][targetY][1]=IDBuilder(targetItemInfos)
					origtable[origx][origy]={"", {0, 0}, 1, 1}
					DebugPrint(attachmentswap.weapons[whichgun][curmuzzle])
					SetString("inventory.pickup", attachmentswap.weapons[whichgun][curmuzzle])
					return	
				end
			end	
			--------------------------Sides----------------------------							
		elseif idInfos[2] == "side1" then
			if targetIdInfos[1] == "gun" and origtable ~= nil and _invState ~= "attachmment"  and not (targetIdInfos[2] == "ak50" or targetIdInfos[2] == "mosin" or targetIdInfos[2] == "sv98" or targetIdInfos[2] == "rpg" or targetIdInfos[2] == "CZ-1012" or targetIdInfos[2] == "ks23" or targetIdInfos[2] == "ppsh41" or targetIdInfos[2] == "mp43" or targetIdInfos[2] == "sawedoff") and origtable ~= nil and GetString("inventory.pickup") == "" then
				local whichone = gunattachments[targetIdInfos[2]].side
				--DebugPrint(whichone)
				itemAttInfos = Split(targetItemInfos[8], "-")
				local curside = itemAttInfos[whichone] 
				if itemAttInfos[whichone] == "" then 
					itemAttInfos[whichone] = "side1" 
					targetItemInfos[8] = table.concat(itemAttInfos,"-")
					invTable[targetX][targetY][1]=IDBuilder(targetItemInfos)
					origtable[origx][origy]={"", {0, 0}, 1, 1}
					return
				elseif itemAttInfos[whichone] ~= "side1" then 
					itemAttInfos[whichone] = "side1" 
					targetItemInfos[8] = table.concat(itemAttInfos,"-")
					invTable[targetX][targetY][1]=IDBuilder(targetItemInfos)
					origtable[origx][origy]={"", {0, 0}, 1, 1}
					SetString("inventory.pickup", attachmentswap.sides[curside])
					return
				end
			end
		elseif idInfos[2] == "side2" then
			if targetIdInfos[1] == "gun" and origtable ~= nil and _invState ~= "attachmment"  and not (targetIdInfos[2] == "ak50" or targetIdInfos[2] == "mosin" or targetIdInfos[2] == "sv98" or targetIdInfos[2] == "rpg" or targetIdInfos[2] == "CZ-1012" or targetIdInfos[2] == "ks23" or targetIdInfos[2] == "ppsh41" or targetIdInfos[2] == "mp43" or targetIdInfos[2] == "sawedoff") and origtable ~= nil and GetString("inventory.pickup") == "" then
				local whichone = gunattachments[targetIdInfos[2]].side
				itemAttInfos = Split(targetItemInfos[8], "-")
				local curside = itemAttInfos[whichone] 
				if itemAttInfos[whichone] == "" then 
					itemAttInfos[whichone] = "side2" 
					targetItemInfos[8] = table.concat(itemAttInfos,"-")
					invTable[targetX][targetY][1]=IDBuilder(targetItemInfos)
					origtable[origx][origy]={"", {0, 0}, 1, 1}
					return
				elseif itemAttInfos[whichone] ~= "side2" then 
					itemAttInfos[whichone] = "side2" 
					targetItemInfos[8] = table.concat(itemAttInfos,"-")
					invTable[targetX][targetY][1]=IDBuilder(targetItemInfos)
					origtable[origx][origy]={"", {0, 0}, 1, 1}
					SetString("inventory.pickup", attachmentswap.sides[curside])
					return
				end
			end	
		elseif idInfos[2] == "side3" then
			if targetIdInfos[1] == "gun" and origtable ~= nil and _invState ~= "attachmment"  and not (targetIdInfos[2] == "ak50" or targetIdInfos[2] == "mosin" or targetIdInfos[2] == "sv98" or targetIdInfos[2] == "rpg" or targetIdInfos[2] == "CZ-1012" or targetIdInfos[2] == "ks23" or targetIdInfos[2] == "ppsh41" or targetIdInfos[2] == "mp43" or targetIdInfos[2] == "sawedoff") and origtable ~= nil and GetString("inventory.pickup") == "" then
				local whichone = gunattachments[targetIdInfos[2]].side
				itemAttInfos = Split(targetItemInfos[8], "-")
				local curside = itemAttInfos[whichone] 
				if itemAttInfos[whichone] == "" and checkattachmentCompatibility(item, targetItem) then 
					itemAttInfos[whichone] = "side3" 
					targetItemInfos[8] = table.concat(itemAttInfos,"-")
					invTable[targetX][targetY][1]=IDBuilder(targetItemInfos)
					origtable[origx][origy]={"", {0, 0}, 1, 1}
					return
				elseif itemAttInfos[whichone] ~= "side3" and checkattachmentCompatibility(item, targetItem) then 
					itemAttInfos[whichone] = "side3" 
					targetItemInfos[8] = table.concat(itemAttInfos,"-")
					invTable[targetX][targetY][1]=IDBuilder(targetItemInfos)
					origtable[origx][origy]={"", {0, 0}, 1, 1}
					SetString("inventory.pickup", attachmentswap.sides[curside])
					return	
				end
			end	
		elseif idInfos[2] == "side4" then
			if targetIdInfos[1] == "gun" and origtable ~= nil and _invState ~= "attachmment"  and not (targetIdInfos[2] == "ak50" or targetIdInfos[2] == "mosin" or targetIdInfos[2] == "sv98" or targetIdInfos[2] == "rpg" or targetIdInfos[2] == "CZ-1012" or targetIdInfos[2] == "ks23" or targetIdInfos[2] == "ppsh41" or targetIdInfos[2] == "mp43" or targetIdInfos[2] == "sawedoff") and origtable ~= nil and GetString("inventory.pickup") == "" then
				local whichone = gunattachments[targetIdInfos[2]].side
				itemAttInfos = Split(targetItemInfos[8], "-")
				local curside = itemAttInfos[whichone] 
				if itemAttInfos[whichone] == "" and checkattachmentCompatibility(item, targetItem) then 
					itemAttInfos[whichone] = "side4" 
					targetItemInfos[8] = table.concat(itemAttInfos,"-")
					invTable[targetX][targetY][1]=IDBuilder(targetItemInfos)
					origtable[origx][origy]={"", {0, 0}, 1, 1}
					return
				elseif itemAttInfos[whichone] ~= "side4" and checkattachmentCompatibility(item, targetItem) then 
					itemAttInfos[whichone] = "side4" 
					targetItemInfos[8] = table.concat(itemAttInfos,"-")
					invTable[targetX][targetY][1]=IDBuilder(targetItemInfos)
					origtable[origx][origy]={"", {0, 0}, 1, 1}
					SetString("inventory.pickup", attachmentswap.sides[curside])
					return	
				end
			end
		elseif id == "general-plate" then
			if targetIdInfos[1] == "vest" and origtable ~= nil and GetString("inventory.pickup") == "" then
				local hp=tonumber(targetItemInfos[3])
				local maxhp=tonumber(targetItemInfos[4])
				local amountheal = maxhp/2
				if hp<maxhp then
					targetItemInfos[3]=math.min(hp+amountheal, maxhp)
					invTable[targetX][targetY][1]=IDBuilder(targetItemInfos)
					for a = 1, w do
						for b = 1, h do
							origtable[origx+a-1][origy+b-1] = {"", {0, 0}, 1, 1}
						end
					end
					return
				end
			end
		elseif string.sub(item, 1, 3) == "mag" then
			if GetString("inventory.pickup") == "" then
				if targetIdInfos[1] == "gun" then
					local caliber1, ammo1, caliber2, ammo2 = itemInfos[5], itemInfos[3], targetItemInfos[7], targetItemInfos[5]
					if caliber1 == caliber2 and targetItemInfos[3] == "none" and checkMagCompatibility(item, targetItem) then
						targetItemInfos[3]=itemInfos[1]
						targetItemInfos[4]=itemInfos[2]
						targetItemInfos[5]=ammo1+ammo2
						targetItemInfos[6]=itemInfos[4]
						local table1 = Split(targetItemInfos[10], "-")
						local table2 = Split(itemInfos[6], "-")
						if targetIdInfos[2] ~= "ppsh41" then
							for targetX=1,#table1 do 
								if table1[targetX] ~= "" then
									table.insert(table2, table1[targetX])
								end
							end
						end
						
						
						targetItemInfos[10]=table.concat(table2, "-")
						invTable[targetX][targetY][1] = IDBuilder(targetItemInfos)
						SetBool("inventory.update_guns"..targetY.."", true)
						for a = 1, w do
							for b = 1, h do
								origtable[origx+a-1][origy+b-1] = {"", {0, 0}, 1, 1}
							end
						end
						--DebugPrint(IDBuilder(targetItemInfos))
						if string.sub(id,5,6) == "ak" or string.sub(id,5,7) == "svd" then
							PlaySound(LoadSound("MOD/snd/Weapons/ak/ak_magin.ogg"))
						elseif targetIdInfos[2] == "g17" or targetIdInfos[2] == "g18" or targetIdInfos[2] == "m9" or targetIdInfos[2] == "tt33" or idInfos[2] == "fiveseven" or targetIdInfos[2] == "vector" then
							PlaySound(LoadSound("MOD/snd/Weapons/g17/g17reload2.ogg"))
						else
							PlaySound(LoadSound("MOD/snd/Weapons/m4a1/m4a1_magin.ogg"))
						end
						return
					end
				end
			end
		elseif string.sub(item, 1, 6) == "rocket" then
			if GetString("inventory.pickup") == "" then
				if targetIdInfos[2] == "rpg" and targetItemInfos[3] == "none" then
					targetItemInfos[3]=itemInfos[1]
					targetItemInfos[4]=itemInfos[2]
					targetItemInfos[5]=1
					invTable[targetX][targetY][1] = IDBuilder(targetItemInfos)
					PlaySound(LoadSound("MOD/snd/Weapons/rpg/reload/RPG_reload_fast_load_0.ogg"))
					return
				end
			end
		end
	end

	if outofbounds then
		if origtable and origx~=0 and origy~=0 then
			-- return split stack bullet back to its original place
			if idInfos[1] == "bullets" and origtable[origx][origy][1] ~= "" and id == Split(origtable[origx][origy][1],"_")[1] then
				local origInvSlot = origtable[origx][origy] -- use original inv slot to be lazy with split-rotate-fail-bug
				local origItemInfos = Split(origInvSlot[1],"_")
				local total = tonumber(origItemInfos[3])+tonumber(itemInfos[3])
				origItemInfos[3]=total
				origInvSlot[1] = IDBuilder(origItemInfos)
				return
			else
				if (invSlot.rotation or 0) % 2 == 1 then -- use slot's original rotation when putting item back to where its from
					w, h = itemH, itemW
				else
					w, h = itemW, itemH
				end
				invSlot[3] = w
				invSlot[4] = h
				invSlot._tempRotation = nil
				origtable[origx][origy] = invSlot
			end
			if origtable ~= guns and origtable ~= armor then
				for a = 1, w do
					for b = 1, h do
						origtable[origx+a-1][origy+b-1][2] = {origx, origy}
					end
				end
			end
		end
		return
	end

	if not collision then
		SetString("inventory.pickup", "")
		invTable[targetX][targetY] = newInvSlot
		for a = 1, w do
			for b = 1, h do
				invTable[targetX+a-1][targetY+b-1][2] = {targetX, targetY}
			end
		end
	elseif collision and origx == 0 then
		return
	else
		-- return split stack bullet back to its original place
		if idInfos[1] == "bullets" and origtable[origx][origy][1] ~= "" and id == Split(origtable[origx][origy][1],"_")[1] then
			local origInvSlot = origtable[origx][origy] -- use original inv slot to be lazy with split-rotate-fail-bug
			local origItemInfos = Split(origInvSlot[1],"_")
			local total = tonumber(origItemInfos[3])+tonumber(itemInfos[3])
			origItemInfos[3]=total
			origInvSlot[1] = IDBuilder(origItemInfos)
			return
		else
			if (invSlot.rotation or 0) % 2 == 1 then -- use slot's original rotation when putting item back to where its from
				w, h = itemH, itemW
			else
				w, h = itemW, itemH
			end
			invSlot[3] = w
			invSlot[4] = h
			invSlot._tempRotation = nil
			origtable[origx][origy] = invSlot
		end
		if origtable and origtable ~= guns and origtable ~= armor then
			for a = 1, w do
				for b = 1, h do
					origtable[origx+a-1][origy+b-1][2] = {origx, origy}
				end
			end
		end
	end
end

function clearItem(invtable, grabinfo)
	invChanged=true
	local invSlot = grabinfo[1]
	local item, parent, w, h, rotation = invSlot[1], invSlot[2], invSlot[3], invSlot[4], invSlot.rotation or 0
	local origx, origy, origtable = grabinfo[2], grabinfo[3], grabinfo[4]

	if invtable ~= guns and invtable ~= armor then
		for a = 1, w do
			for b = 1, h do
				if (origx+a-1)>0 and (origy+b-1)>0 then
					invtable[origx+a-1][origy+b-1][2] = {0, 0}
					invtable[origx+a-1][origy+b-1][3], invtable[origx+a-1][origy+b-1][4]= 1, 1
				end
			end
		end
	end
end

function checkMagCompatibility(mag, gun)
	local magType = Split(mag, "_")[1]
	local magTypeInfos = Split(magType, "-")
	local gunId = Split(Split(gun, "_")[1], "-")[2]

	if magTypeInfos[2] == "ak" then
		if magTypeInfos[3] == "545" then
			return gunId == "ak74" or gunId == "ak74m"
		elseif magTypeInfos[3] == "762x39" then
			return gunId == "akm"
		elseif magTypeInfos[3] == "762x54" then
			return gunId == "svd"
		elseif magTypeInfos[3] == "9x19" then
			return gunId == "pp19"
		elseif magTypeInfos[3] == "556" then
			return gunId == "ak101"
		end
	elseif magTypeInfos[2] == "ar" then
		return gunId == "ar15" or gunId == "scarl" or gunId == "scarlg" or gunId == "m16"
	elseif magTypeInfos[2] == "scar" then
		return gunId == "scarh" or gunId == "scarhg"
	elseif magTypeInfos[2] == "glock" then
		return gunId == "g17" or gunId == "g18" or gunId == "vector"
	elseif magTypeInfos[2] == "dgl" then
		return gunId == "deagle"
	elseif magTypeInfos[2] == "hk" then
		return gunId == "g36k" or gunId == "sg553"
	elseif magTypeInfos[2] == "ppsh" then
		return gunId == "ppsh41"
	elseif magTypeInfos[2] == "tt33" then
		return gunId == "tt33"
	elseif magTypeInfos[2] == "m9" then
		return gunId == "m9"
	elseif magTypeInfos[2] == "m107" then
		return gunId == "ak50" or gunId == "m107"
	elseif magTypeInfos[2] == "g3" then
		return gunId == "g3"
	elseif magTypeInfos[2] == "mp5" then
		return gunId == "mp5"
	elseif magTypeInfos[2] == "p90" then
		return gunId == "p90"
	elseif magTypeInfos[2] == "fs" then
		return gunId == "fiveseven"
	elseif magTypeInfos[2] == "sv98" then
		return gunId == "sv98"
	end
	return false
end

function checkattachmentCompatibility(attachment, gun)
	local attachmentType = Split(attachment, "_")[1]
	local attachmentTypeInfos = Split(attachmentType, "-")
	local gunId = Split(Split(gun, "_")[1], "-")[2]

	if attachmentTypeInfos[2] == "holo" then
		if attachmentTypeInfos[3] == "tan" then
			return gunId == "ar15" or gunId == "g36k"
		elseif attachmentTypeInfos[3] == "pistol" then
			return gunId == "g18" or gunId == "g17" or gunId == "deagle" or gunId == "fiveseven" or gunId == "tt33"
		elseif attachmentTypeInfos[3] == "normal" then
			return gunId ~= "g18" and gunId ~= "g17" and gunId ~= "deagle" and gunId ~= "fiveseven" and gunId ~= "tt33"
		elseif attachmentTypeInfos[3] == "9x19" then
			return gunId == "pp19"		
		elseif attachmentTypeInfos[3] == "556" then
			return gunId == "ak101"
		end
	
	elseif attachmentTypeInfos[2] == "side3" then
		return gunId == "deagle" or gunId == "mosinm" or gunId == "ak101" or gunId == "ar15" or gunId == "tt33" or gunId == "g36k"
		
	elseif attachmentTypeInfos[2] == "acog" then
		return gunId == "ar15" or gunId == "scarh" or gunId == "scarl" or gunId == "scarlg" or gunId == "scarhg" or gunId == "g3" or gunId == "m16" or gunId == "m107" or gunId == "g36"
	
	elseif attachmentTypeInfos[2] == "side4" then
		return gunId == "mp5" or gunId == "ar15" or gunId == "tt33" or gunId == "g36k"
	
	elseif attachmentTypeInfos[2] == "muzzle1" then
		if attachmentTypeInfos[3] == "m107" then
			return gunId == "m107"
		elseif attachmentTypeInfos[3] == "glock" then
			return gunId == "g17" or gunId == "g18" or gunId == "vector"
		elseif attachmentTypeInfos[3] == "g36" then
			return gunId == "g36k"
		elseif attachmentTypeInfos[3] == "p90" then
			return gunId == "p90"
		elseif attachmentTypeInfos[3] == "g3" then
			return gunId == "g3"
		elseif attachmentTypeInfos[3] == "pp19" then
			return gunId == "pp19"
		elseif attachmentTypeInfos[3] == "57" then
			return gunId == "fiveseven"
		elseif attachmentTypeInfos[3] == "ar" then
			return gunId == "m16" or gunId == "ar15"
		elseif attachmentTypeInfos[3] == "tt33" then
			return gunId == "tt33"
		elseif attachmentTypeInfos[3] == "ak74" then
			return gunId == "ak74" or gunId == "ak74m"
		elseif attachmentTypeInfos[3] == "akm" then
			return gunId == "akm"
		elseif attachmentTypeInfos[3] == "mosin" then
			return gunId == "mosin" or gunId == "mosinm"
		elseif attachmentTypeInfos[3] == "scarh" then
			return gunId == "scarh" or gunId == "scarhg"
		elseif attachmentTypeInfos[3] == "scarl" then
			return gunId == "scarl" or gunId == "scarhl"
		elseif attachmentTypeInfos[3] == "sks" then
			return gunId == "sks"
		end
	
	elseif attachmentTypeInfos[2] == "muzzle2" then
		if attachmentTypeInfos[3] == "m107" then
			return gunId == "m107"
		elseif attachmentTypeInfos[3] == "glock" then
			return (gunId == "g17" or gunId == "g18" or gunId == "vector")
		elseif attachmentTypeInfos[3] == "g36" then
			return (gunId == "g36k")	
		elseif attachmentTypeInfos[3] == "g3" then
			return (gunId == "g3")
		elseif attachmentTypeInfos[3] == "p90" then
			return (gunId == "p90")
		elseif attachmentTypeInfos[3] == "pp19" then
			return (gunId == "pp19")
		elseif attachmentTypeInfos[3] == "57" then
			return (gunId == "fiveseven")
		elseif attachmentTypeInfos[3] == "ar" then
			return (gunId == "m16" or gunId == "ar15")
		elseif attachmentTypeInfos[3] == "tt33" then
			return gunId == "tt33"
		elseif attachmentTypeInfos[3] == "ak74" then
			return (gunId == "ak74" or gunId == "ak74m")
		elseif attachmentTypeInfos[3] == "akm" then
			return (gunId == "akm")
		elseif attachmentTypeInfos[3] == "mosin" then
			return (gunId == "mosin" or gunId == "mosinm")
		elseif attachmentTypeInfos[3] == "scarh" then
			return (gunId == "scarh" or gunId == "scarhg")
		elseif attachmentTypeInfos[3] == "scarl" then
			return (gunId == "scarl" or gunId == "scarhl")
		elseif attachmentTypeInfos[3] == "sks" then
			return (gunId == "sks")
		end
		
	end
	return false
end

function update(dt)
	if not GetBool("level.gamerule.nhat") then
		if InputDown("shift") and GetPlayerVehicle() == 0 then
			SprintMultiplier = 2.5
		else 
			SprintMultiplier = 0
		end
		if GetString("savegame.mod.difficulty") == "hardcore" then
			thirst = math.min(math.max(thirst - 0.005 * devmultiplier * SprintMultiplier, 0), 100)
			hunger = math.min(math.max(hunger - 0.002 * devmultiplier, 0), 100)
		else
			thirst = math.min(math.max(thirst - 0.0015 * devmultiplier, 0), 100)
			hunger = math.min(math.max(hunger - 0.001 * devmultiplier, 0), 100)
		end
	end


	SetString("savegame.mod.hunger", hunger)
	SetString("savegame.mod.thirst", thirst)

	-- debug menu hunger and thirst option.
	if GetBool("savegame.mod.config.game.inf_hunger") then hunger = 100 end
	if GetBool("savegame.mod.config.game.inf_thirst") then thirst = 100 end

end

function PlaceItemFromXML(Path, Amount)
	if Path == "nil" then
		return 
	end
	if HasFile("MOD/prefabs/spawnables/loots/"..Path..".xml") then
		local newxml = Spawn("MOD/prefabs/spawnables/loots/"..Path..".xml", Transform())

		local itemInfos = Split(GetTagValue(newxml[1], "Loot"), "_")
		if Split(itemInfos[1], "-")[1] == "bullets" then
			itemInfos[3] = Amount
		end
		
		local item = IDBuilder(itemInfos)	
		table.insert(pickupqueue, item)
		Delete(newxml)
	end
end

function tick(dt)	
	if InputDown("e") and InputDown("r") and InputPressed("o") then
		LETITERROR = not LETITERROR
	end

	if GetBool("inventory.refreshshop") then
		refreshShop()
		SetBool("inventory.refreshshop", false)
	end

 	-- force drop and clear inventory to fix issue
	if not LETITERROR and((InputDown('d') and InputDown('r') and InputDown('o') and InputPressed('p')) or tickCycleBad) then
		invChanged=true
		SetBool("inventory.reload", false)
		for i = 1,8 do
			for j = 1,15 do
				print("backpack:",i,j)
				PrintTable(backpack[i][j])
				print("____________________")
			end
		end
		for i = 1,4 do
			print("guns:",1,i)
			PrintTable(guns[1][i])
			print("____________________")
		end
		for i = 1,3 do
			print("armor:",1,i)
			PrintTable(armor[1][i])
			print("____________________")
		end

		local dropTr = Transform(VecAdd(GetPlayerTransform().pos, Vec(0, 1, 0)), GetPlayerTransform().rot)
		for i = 1,8 do
			for j = 1,15 do
				local entities=spawnItem(backpack[i][j][1], dropTr)
				backpack[i][j] = {"", {0, 0}, 1, 1}
				clearItem(backpack, {{"", {0, 0}, 1, 1}, i, j, backpack})
			end
		end
		for i = 1,4 do
			local entities=spawnItem(guns[1][i][1], dropTr)
			guns[1][i] = {"", {0, 0}, 1, 1}
			clearItem(guns, {{"", {0, 0}, 1, 1}, 1, i, guns})
		end
		for i = 1,3 do
			local entities=spawnItem(armor[1][i][1], dropTr)
			armor[1][i] = {"", {0, 0}, 1, 1}
			clearItem(armor, {{"", {0, 0}, 1, 1}, 1, i, armor})
		end
		InitInventory()
		SaveInventory()
		if tickCycleBad then
			DebugPrint('tick() did not complete a full cycle, Inventory Flushed')
			print('tick() did not complete a full cycle, Inventory Flushed')
		else
			DebugPrint('Manual Inventory Flushed')
			print('Manual Inventory Flushed')
		end
	end
	tickCycleBad=true

	----VITALITY SYSTEM------
	SetBool("level.player.health.doBleed", true)
	if not GetBool("level.gamerule.nhat") and not GetBool("level.gamerule.god") then
		if hunger <= 0 then
			if hungertimer <= 0 then
				for i = 2, #parts do
					SetTag(parts[i], "S", 0)
					SetTag(parts[i], "QueriedDamage", malnutrition)
					SetBool("level.player.health.doBleed", false)
				end
				hungertimer = 3
			end
			hungertimer = hungertimer - dt
		end

		if thirst <= 0 then
			if thirsttimer <= 0 then
				for i = 2, #parts do
					SetTag(parts[i], "S", 0)
					SetTag(parts[i], "QueriedDamage", dehydration)
					SetBool("level.player.health.doBleed", false)
				end
				thirsttimer = 3
			end
			thirsttimer = thirsttimer - dt
		end
	end

	if GetBool("health.status.dead") or GetBool("savegame.mod.inventory.init") then
		SaveInventory()
		SetBool("inventory.reloading", false)

		if not dead and not GetBool("level.gamerule.keepinv") and not GetBool("level.gamerule.permadeath") and not GetBool("savegame.mod.inventory.init") then
			local dropTr = Transform(VecAdd(GetPlayerTransform().pos, Vec(0, 0.5, 0)), GetPlayerTransform().rot)
			for i = 1,8 do
				for j = 1,15 do
					local entities=spawnItem(backpack[i][j][1], dropTr)
	    			backpack[i][j] = {"", {0, 0}, 1, 1}
					clearItem(backpack, {{"", {0, 0}, 1, 1}, i, j, backpack})
				end
			end
			for i = 1,2 do
				local entities=spawnItem(guns[1][i][1], dropTr)
				guns[1][i] = {"", {0, 0}, 1, 1}
				clearItem(guns, {{"", {0, 0}, 1, 1}, 1, i, guns})
			end
			for i = 1,3 do
				local entities=spawnItem(armor[1][i][1], dropTr)
				armor[1][i] = {"", {0, 0}, 1, 1}
				clearItem(armor, {{"", {0, 0}, 1, 1}, 1, i, armor})
			end
		end

		dead = true
		if GetString("savegame.mod.difficulty") == "hardcore" then 
			hunger = math.random(50,100)
			thirst = math.random(50,100)
		else
			hunger = 100
			thirst = 100
		end


		if GetBool("savegame.mod.inventory.init") then
			InitInventory()
			SaveInventory()
			if not GetBool("savegame.mod.inventory.init") and GetString("level.gamerule.permadeath") and GetBool("health.status.dead") then
				SetBool("savegame.mod.continue",false)
			end
			SetBool("savegame.mod.inventory.init", false)
			local Loadouts = {
				["LoadoutConfig"] = {
					{"Gun", "Bullet", "Mag", "Mag", "Med"},
					{"Gun", "Bullet", "Bullet", "Med", "Med", "Med", "Random"},
					{"Gun", "Mag", "Mag", "Mag", "Bullet", "Random", "Random", "Med", "Med", "Med", "Med"},
					{"Gun", "Med", "Med", "Mag", "Mag", "Bullet", "Bullet", "Bullet"}
				},				
				{
					["Gun"] = {"Gun TT-33", "Gun TT-33 1", "Gun TT-33 2", "Gun TT-33 3", "Gun TT-33 4", "Gun TT-33 5", "Gun TT-33 6", "Gun TT-33 7", "Gun TT-33 8", "Gun TT-33 GREY", "Gun TT-33 GREY 1", "Gun TT-33 GREY 2", "Gun TT-33 GREY 3", "Gun TT-33 GREY 4", "Gun TT-33 GREY 5", "Gun TT-33 GREY 6", "Gun TT-33 GREY 7", "Gun TT-33 GREY 8"},
					["Bullet"] = {["Amount"] = {["Min"] = 1, ["Max"] = 30},
					"Ammo 7.62x25 T","Ammo 7.62x25 HP",},
					["Mag"] = {"Mag TT-33 #0"},
					["Random"] = {"general-nails","general-plate","general-book","ROCKET #0","Melee FireAxe","Melee CombatKnife","food1","food2"},
					["Med"] = {"Meds IFAK","Meds SPLINT","Meds STIM ADRENALINE","Meds AI2"},
				},
				{
					["Gun"] = {"Gun Qasira"},
					["Bullet"] = {["Amount"] = {["Min"] = 1, ["Max"] = 10},
					"Ammo 12GA S","Ammo 12GA BS","Ammo 12GA BKS"},
					["Mag"] = {"nil"},
					["Random"] = {"Altyn","general-lighter","Melee FireAxe","Melee CombatKnife","food1","food2"},
					["Med"] = {"Meds AI2","Meds IFAK","Meds BANDAGE","Meds STIM MORPHINE","Meds STIM PZ1"},
				},
				{
					["Gun"] = {"Gun SKS"},
					["Bullet"] = {["Amount"] = {["Min"] = 1, ["Max"] = 25},
					"Ammo 7.62x39 T","Ammo 7.62x39 FMJ"},
					["Mag"] = {"nil"},
					["Random"] = {"general-gpu","general-snow","Grenade","general-lighter","Melee FireAxe","Melee CombatKnife","ROCKET #1","ROCKET #0","food1","food2"},
					["Med"] = {"Meds AI2","Meds IFAK","Meds BANDAGE","Meds STIM MORPHINE","Meds STIM PZ1","Gun P17"},
				},
				{
					["Gun"] = {"Gun Simonov-9","Gun Simonov-9 MILITARY2"},
					["Bullet"] = {["Amount"] = {["Min"] = 5, ["Max"] = 35},
					"Ammo 9x19 AP","Ammo 9x19 T","Ammo 9x19 HP","Ammo 9x19 FMJ"},
					["Mag"] = {"nil"},
					["Random"] = {"food1","food2","general-nails","Grenade","general-plate","general-carbattery","general-battery","food27","ROCKET #3","Melee CombatKnife"},
					["Med"] = {"Meds IFAK","Meds SPLINT","Meds STIM ADRENALINE","Meds AI2"},
				},
				{
					["Gun"] = {"Gun P17","Gun P17 Green","Gun P17 TAN","Gun P17 Grey"},
					["Bullet"] = {["Amount"] = {["Min"] = 5, ["Max"] = 35},
					"Ammo 9x19 AP","Ammo 9x19 T","Ammo 9x19 HP","Ammo 9x19 FMJ"},
					["Mag"] = {"Mag P17 9x19 #0"},
					["Random"] = {"food1","food2","general-nails","Grenade","general-plate","Gzhel","general-battery","food27","ROCKET #3","Melee CombatKnife"},
					["Med"] = {"Meds IFAK","Meds SPLINT","Meds STIM ADRENALINE","Meds AI2"},
				},
				{
					["Gun"] = {"Gun RPG"},
					["Bullet"] = {["Amount"] = {["Min"] = 1, ["Max"] = 1},
					"nil"},
					["Mag"] = {"ROCKET #0","ROCKET #1","ROCKET #2","ROCKET #3"},
					["Random"] = {"food1","food2","general-nails","Grenade","general-plate","Gzhel","general-battery","food27","ROCKET #3","Melee CombatKnife"},
					["Med"] = {"Meds IFAK","Meds SPLINT","Meds STIM ADRENALINE","Meds AI2"},
				},
			}
			local Config = Loadouts.LoadoutConfig[math.random(1,#Loadouts.LoadoutConfig)]
			local Loadout = Loadouts[math.random(1,#Loadouts)]
			for i=1,#Config do 
				local item = Loadout[Config[i]][math.random(1,#Loadout[Config[i]])]
				local bulletamount = math.random(Loadout.Bullet.Amount.Min,Loadout.Bullet.Amount.Max)
				PlaceItemFromXML(item, bulletamount)
				--DebugPrint(i.."|"..#Config.."|"..item)
			end
			
		end
	else
		dead = false
	end

	if GetBool("inventory.givestarterweapons") then
		SetPlayerHealth(0)
	end

	--[[ if GetPlayerHealth() < 0.5 then
		SetTimeScale((GetPlayerHealth()*2)^0.5)
	end ]]

	------NVG SYSTEM------

	local eyeWearItem = armor[1][3][1]
	if eyeWearItem ~= "" then
		local eyeWearItemInfos = Split(eyeWearItem, "_")
		local eyeWearItemID = eyeWearItemInfos[1]
		local eyeWearItemIDInfos = Split(eyeWearItemID, "-")
		if eyeWearItemIDInfos[1] == "eyewear" then
			local NVGDurability = tonumber(eyeWearItemInfos[3])
			SetFloat("inventory.nvg.durability", NVGDurability)
			if NVGDurability > 0 then
	
				if KeybindPressed(Settings.keybinds.player.night_vision) then
					nvgon = not nvgon
					if nvgon then
						PlaySound(SOUNDS.nvgon)
					else
						PlaySound(SOUNDS.nvgoff)
					end
				end
	
				if nvgon then
					eyeWearItemInfos[3] = NVGDurability - dt/7
					armor[1][3][1] = IDBuilder(eyeWearItemInfos)
				end
	
			else
				nvgon = false
			end
		else
			nvgon = false
		end
		SetString("inventory.nvg.current", eyeWearItemIDInfos[2])
	else
		nvgon = false
		SetString("inventory.nvg.current", "")
	end
	SetBool("inventory.nvg.enabled", nvgon)

	------ARMOR SYSTEM------

	--vest
	local incomingdamage = GetFloat("level.damagetaken")
	if incomingdamage ~= 0 then
		local vestItem = armor[1][1][1]
		if vestItem ~= "" then
			local vestItemInfos = Split(vestItem, "_")
			local vestDurability = tonumber(vestItemInfos[3])
			--local armordamage = math.ceil(incomingdamage)
			vestItemInfos[3] = math.max(vestDurability-incomingdamage, 0)
			armor[1][1][1] = IDBuilder(vestItemInfos)
		end
		SetFloat("level.damagetaken", 0)
	end
	--helmet
	local incomingdamage = GetFloat("level.damagetaken2")
	if incomingdamage ~= 0 then
		local helmetItem = armor[1][2][1]
		if helmetItem ~= "" then
			local helmetInfos = Split(helmetItem, "_")
			local helmettDurability = tonumber(helmetInfos[3])
			--local armordamage = math.ceil(incomingdamage)
			helmetInfos[3] = math.max(helmettDurability-incomingdamage, 0)
			armor[1][2][1] = IDBuilder(helmetInfos)
		end
		SetFloat("level.damagetaken2", 0)
	end

	------PICKING UP LOOT------
	if #pickupqueue > 0 and GetString("inventory.pickup") == "" then 
		SetString("inventory.pickup", pickupqueue[1])
		table.remove(pickupqueue, 1)
	end
	
    if GetString("inventory.pickup") ~= "" then
		local item = GetString("inventory.pickup")
		local itemInfos = Split(item, "_")
		local id = itemInfos[1]
		local idInfos = Split(id, "-")
		local w, h = GetDimensions(item)
		
		if idInfos[1] == "gun" then
			local gun1=false
			for i=1,#gunslist do
				if id==gunslist[i]then
					gun1=true
					break
				end
			end
			
			local maginfo = Split(itemInfos[3],"-")
			--DebugPrint(maginfo[3])
			if #itemInfos < 8 then
				itemInfos[8] = "----------------------"
			end
			if #itemInfos < 9 then
				itemInfos[9] = "-----"
			end
			if #itemInfos < 10 then
				itemInfos[10] = ""
				local bulletInfos = {}
				for i=1,tonumber(itemInfos[5]) do 
					bulletInfos[i] = GunDefaultBulletType[displayCaltoCalID(itemInfos[7])]	
				end
				itemInfos[10] = table.concat(bulletInfos, "-")
				item = IDBuilder(itemInfos)
			end
			
			--DebugPrint(item)
			if gun1 then
				if GetString("savegame.mod.inventory.guns.1.item") == "" then
					placeItem(guns, {{item, {1, 1}, w, h}, 0, 0, guns}, 1, 1, true)
					SetString("savegame.mod.inventory.guns.1.item", item)
					SetString("inventory.pickup", "")
					SetBool("inventory.update_guns1", true)
					SetBool("inventory.update_guns4", true)
					PlayGunEquipSound()
				elseif GetString("savegame.mod.inventory.guns.4.item") == "" then
					placeItem(guns, {{item, {1, 4}, w, h}, 0, 0, guns}, 1, 4, true)
					SetString("savegame.mod.inventory.guns.4.item", item)
					SetString("inventory.pickup", "")
					SetBool("inventory.update_guns1", true)
					SetBool("inventory.update_guns4", true)
					PlayGunEquipSound()
				end
			else
				if GetString("savegame.mod.inventory.guns.2.item") == "" then
					placeItem(guns, {{item, {1, 2}, w, h}, 0, 0, guns}, 1, 2, true)
					SetString("savegame.mod.inventory.guns.2.item", item)
					SetString("inventory.pickup", "")
					SetBool("inventory.update_guns2", true)
					PlayPistolEquipSound()
				end
			end
		elseif idInfos[1] == "melee" and GetString("savegame.mod.inventory.guns.3.item") == "" then
			placeItem(guns, {{item, {1, 3}, w, h}, 0, 0, guns}, 1, 3, true)
			SetString("inventory.pickup", "")
			PlayBackpackSound()
		elseif idInfos[1] == "vest" and GetString("savegame.mod.inventory.armor.1.item") == "" then
			placeItem(armor, {{item, {1, 1}, w, h}, 0, 0, armor}, 1, 1, true)
			SetString("inventory.pickup", "")
			PlayArmorEquipSound(item)
		elseif idInfos[1] == "helmet" and GetString("savegame.mod.inventory.armor.2.item") == "" then
			placeItem(armor, {{item, {1, 2}, w, h}, 0, 0, armor}, 1, 2, true)
			SetString("inventory.pickup", "")
			PlayArmorEquipSound(item)
		elseif idInfos[1] == "eyewear" and GetString("savegame.mod.inventory.armor.3.item") == "" then
			placeItem(armor, {{item, {1, 3}, w, h}, 0, 0, armor}, 1, 3, true)
			SetString("inventory.pickup", "")
		end
		if string.sub(id,1,3) == "mag" and #itemInfos < 6 then
			itemInfos[6] = "" 
			local bulletInfos = {}
			for i=1,tonumber(itemInfos[4]) do 
				bulletInfos[i] = GunDefaultBulletType[idInfos[3]]	
			end
			itemInfos[6] = table.concat(bulletInfos, "-")
			--DebugPrint(IDBuilder(itemInfos))
			item = IDBuilder(itemInfos)
		end
		--DebugPrint(item)
		if GetString("inventory.pickup") ~= "" then
			local fakeGrabInfo = {{item, {0, 0}, w, h}, 0, 0}
			for rot = 0, 1 do -- try rotations
				fakeGrabInfo[1].rotation = rot
				for j = 1, #backpack[1] do
					for i = 1, #backpack do
						if GetString("inventory.pickup") ~= "" then
							placeItem(backpack, fakeGrabInfo, i, j)
							PlayPickupSound(item)
						else
							break
						end
					end
					if GetString("inventory.pickup") == "" then
						break
					end
				end
				if GetString("inventory.pickup") == "" then
					break
				end
			end
		end

		if GetString("inventory.pickup") ~= "" then
			SetString("inventory.drop", GetString("inventory.pickup"))
			SetString("inventory.pickup", "")
		end
	end

	if InputPressed("interact") then
		local playerInteractBody = GetPlayerInteractBody()
		if IsHandleValid(playerInteractBody) then
			if HasTag(playerInteractBody,"Loot") and not _invOn then
				local item = GetTagValue(playerInteractBody, "Loot")
				local itemInfos = Split(item, "_")
				local interactName = GetTagValue(playerInteractBody,"interact")
				if #Split(interactName, "_")==1 then
					itemInfos[2] = interactName
					SetString("inventory.pickup", IDBuilder(itemInfos))
				else
					SetString("inventory.pickup", item)
				end
				Delete(playerInteractBody)
				-- PlayBackpackSound()
			elseif HasTag(playerInteractBody,"MultiLoot") and not _invOn then
				local item = GetTagValue(playerInteractBody, "MultiLoot")
				local items = Split(item, "|")
				for i=1,#items do
					table.insert(pickupqueue, items[i])
				end
				Delete(playerInteractBody)
				-- PlayBackpackSound()
			elseif HasTag(playerInteractBody,"Stash") then
				--SetInt("inventory.stashing", Inventory)
				--PlayBackpackSound()
				_invOn = true
				_invState = "stash"
			elseif HasTag(playerInteractBody,"Shop") then
				--SetInt("inventory.stashing", Inventory)
				--PlayBackpackSound()
				_invOn = true
				_invState = "shop"	
			elseif HasTag(playerInteractBody,"Money") then
				local item = GetTagValue(playerInteractBody, "Money")
				local itemInfos = Split(item, "_")
				local MinMoney = itemInfos[1]
				local AmountMoney = tonumber(itemInfos[2])
				local MaxMoney = itemInfos[3]
				local Money = GetInt("savegame.mod.player.money")
				if not AmountMoney then 
					AmountMoney = math.random(MinMoney,MaxMoney)
				end
				SetInt("savegame.mod.player.money", Money + AmountMoney)
				Delete(playerInteractBody)
				PlayBackpackSound()
			elseif HasTag(playerInteractBody,"Crate") then
				SetInt("inventory.looting", playerInteractBody)
				--PlayBackpackSound()
				_invOn = true
				_invState = "loot"
				local width, height = tonumber(GetTagValue(playerInteractBody, "Width")) or 1, tonumber(GetTagValue(playerInteractBody, "Height")) or 1
				loot = {}
				for i = 1,width do
					loot[i] = {}
					for j = 1,height do
						loot[i][j] = {"", {0, 0}, 1, 1}
					end
				end
				for i = 1,width do
					for j = 1,height do
						local item = GetTagValue(playerInteractBody, i.."_"..j)
						if item ~= "" then
							local w, h = GetDimensions(item)
							placeItem(loot, {{item, {i, j}, w, h}, 0, 0}, i, j)
						end
					end
				end
			elseif HasTag(playerInteractBody,"PerkObject") then
				perkUpgrade(GetTagValue(playerInteractBody,"PerkObject"))
				PlaySound(SOUNDS.perkPickup)
				Delete(playerInteractBody)
			end
			
		end
	end

    ------DROPPING LOOT------
    --loc = TransformToParentPoint(GetPlayerCameraTransform(), Vec(0, 0, -0.5))
    if GetString("inventory.drop")~="" then
		local dropTr=Transform(VecAdd(GetPlayerTransform().pos, Vec(0, 0.5, 0)), GetPlayerTransform().rot)
		local item=GetString("inventory.drop")
		local itemType = Split(Split(item,"_")[1], "-")[1]
		local entities=spawnItem(item, dropTr)
		if itemType == "gun" then 
			PlayWeaponDropSound(item)
		elseif itemType == "helmet" then
			PlaySound(SOUNDS.dropHelmet)
		else
			PlaySound(SOUNDS.dropItem)
		end
    	SetString("inventory.drop", "")
    end

    if rightclickinfo[4] ~= "" then
    	rightclickinfo[1] = rightclickinfo[5][rightclickinfo[2]][rightclickinfo[3]][1]
    end
	SetBool("game.disablemap",true)
	
	if KeybindPressed(Settings.keybinds.inventory.toggle_inv) and not GetBool("inventory.reloading") then
		_invOn = not _invOn
		rightclickinfo = {"", 0, 0, "", nil}
		if _invOn then
			--[[ if _invState=="loot" then
				Inventory = GetInt("inventory.looting")
				width, height = tonumber(GetTagValue(Inventory, "Width")), tonumber(GetTagValue(Inventory, "Height"))
				for i = 1,width do
					for j = 1,height do
						SetTag(Inventory, i.."_"..j, item)
					end
				end
			end ]] -- someone tell me wtf is this supposed to do
			_invState = "" -- this is default

			PlaySound(LoadSound("MOD/snd/Inventory/backpack/backpack_open.ogg"))
		else
			PlaySound(LoadSound("MOD/snd/Inventory/backpack/backpack_close.ogg"))
		end
	end
	if GetBool("inventory.reloading") or InputPressed("esc") or InputPressed("up") or InputPressed("down") or InputPressed("left") or InputPressed("right") then
		_invOn = false
	end
	if _invOn and medtimer <= 0 then
		UiMakeInteractive()
		SetBool("game.disablepause", true)
		if uitimer < 0.2 then uitimer = uitimer + dt end
	else
		if uitimer > 0 then uitimer = uitimer - dt end
	end
	uiopacity = (math.clamp(uitimer, 0, 0.2))/0.2

	if currentmed ~= "" then
		if medtimer > 0 then
			if lastPlayerTool=="" then lastPlayerTool = GetString("game.player.tool")end

			SetBool("game.tool."..currentmed..".enabled", true)
			SetString("game.player.tool",currentmed)
			SetFloat("inventory.medtimer", medtimer)
			SetFloat("inventory.medtimermax", medtimermax)
			medtimer = medtimer - dt
		else
			medtimer = 0
			-- if currentmed == "meds-surgery" then
			-- 	SetTag(currentmedbodypart, "QueriedDamage", -1)
			-- end
			SetBool("game.tool."..currentmed..".enabled", false)
			SetString("game.player.tool",lastPlayerTool)
			SetFloat("inventory.medtimer", 0)
			SetFloat("inventory.medtimermax", 0)
			currentmed = ""
			currentmedbodypart = 0
			lastPlayerTool = ""
		end
	end

	------REMOVING ITEMS------

	if GetString("inventory.remove") ~= "" then
		local coords = Split(GetString("inventory.remove"), "_")
		local i, j = tonumber(coords[1]), tonumber(coords[2])
		local item = backpack[i][j][1]
		local id = Split(item, "_")[1]
		local w, h = GetDimensions(item)
		clearItem(backpack, {{"", {0, 0}, w, h}, i, j, backpack})
		backpack[i][j] = {"", {0, 0}, 1, 1}
		SetString("inventory.backpack."..i.."_"..j..".item", "")
		SetString("inventory.remove", "")
	end

    ------SYNCING INVENTORY------

	if GetBool("inventory.update") and updateCounter == 0 and not _invOn then
		
		for i = 1,8 do
			for j = 1,15 do
				clearItem(backpack, {{"", {0, 0}, 1, 1}, i, j, backpack})
				backpack[i][j][1] = ""
			end
		end

		for i = 1,8 do
			for j = 1,15 do
				local item = GetString("savegame.mod.inventory.backpack."..i.."_"..j..".item")
				if item ~= "" then
					local rotation = GetInt("savegame.mod.inventory.backpack."..i.."_"..j..".rotation")
					local w, h = GetDimensions(item)
					placeItem(backpack, {{item, {i, j}, w, h, rotation = rotation}, 0, 0}, i, j)
				end
			end
		end

		for j = 1,4 do
			clearItem(guns, {{"", {0, 0}, 1, 1}, 1, j, guns})
			guns[1][j][1] = ""
		end
		for j = 1,4 do
			local item = GetString("inventory.guns."..j..".item")
			if item ~= "" then
				local w, h = GetDimensions(item)
				guns[1][j] = {item, {i, j}, w, h}
			end
		end

		SetBool("inventory.update", false)
		updateCounter = 1
	else
		if updateCounter > 0 then
			updateCounter = updateCounter - 1
		end
	end

	if updateCounter == 0 then
		SaveInventory()
	end
		local gun1 = Split(GetString("inventory.guns.1.item"), "_")[1]
		local gun2 = Split(GetString("inventory.guns.2.item"), "_")[1]
		local melee = Split(GetString("inventory.guns.3.item"), "_")[1]
		local gun4 = Split(GetString("inventory.guns.4.item"), "_")[1]
		--DebugWatch("Primary","inventory.lua |"..GetString("inventory.guns.1.item"))
		--DebugWatch("SideArm","inventory.lua |"..GetString("inventory.guns.2.item"))
		
		
		SetString("level.weapon_wheel.gun1", gun1) -- Reset weapon wheel item
		SetString("level.weapon_wheel.gun2", gun2) -- Reset weapon wheel item
		SetString("level.weapon_wheel.melee", melee) -- Reset weapon wheel item
		SetString("level.weapon_wheel.gun4", gun4) -- Reset weapon wheel item

		for i = 1, #gunslist do
			SetBool("game.tool."..gunslist[i]..".enabled", false)
		end
		for i = 1, #gunslist2 do
			SetBool("game.tool."..gunslist2[i]..".enabled", false)
		end
		for i = 1, #meleelist do
			SetBool("game.tool."..meleelist[i]..".enabled", false)
		end

		local curtool = GetString("game.player.tool")
		if InputPressed("1") and cantoggleprimary then toggleprimary = not toggleprimary PlaySound(SOUNDS.gunequip) equipTimer = 1 SetBool("inventory.update_guns1", true) SetBool("inventory.update_guns4", true) end
		if gun1 == "" then toggleprimary = true SetBool("inventory.update_guns1", true) SetBool("inventory.update_guns4", true) end
		if gun4 == "" then toggleprimary = false SetBool("inventory.update_guns1", true) SetBool("inventory.update_guns4", true) end
		

		if toggleprimary then
			SetBool("game.tool."..gun4..".enabled", true)
			SetInt("inventory.curprimary", 4)
			if InputPressed("1") then
				SetString("game.player.tool",gun4)
			end
		else
			SetBool("game.tool."..gun1..".enabled", true)
			SetInt("inventory.curprimary", 1)
			if InputPressed("1") then
				SetString("game.player.tool",gun1)
			end
		end
		SetBool("game.tool."..gun2..".enabled", true)
		SetBool("game.tool."..melee..".enabled", true)


		for i = 1,#gunslist do
			if gunslist[i] ~= gun1 and gunslist[i] ~= gun4 then
				SetBool("game.tool."..gunslist[i]..".enabled", false)
				if GetString("game.player.tool") == gunslist[i] then
					SetString("game.player.tool","")
				end
			end
		end
		for i = 1,#gunslist2 do
			if gunslist2[i] ~= gun2 then
				SetBool("game.tool."..gunslist2[i]..".enabled", false)
				if GetString("game.player.tool") == gunslist2[i] then
					SetString("game.player.tool","")
				end
			end
		end
		for i = 1,#meleelist do
			if meleelist[i] ~= melee then
				SetBool("game.tool."..meleelist[i]..".enabled", false)
				if GetString("game.player.tool") == meleelist[i] then
					SetString("game.player.tool","")
				end
			end
		end

		-- if equipTimer > 0 then
		-- 	if lastPlayerTool=="" then lastPlayerTool = GetString("game.player.tool")end
		-- 	SetBool("game.tool."..gun1..".enabled", false)
		-- 	SetBool("game.tool."..gun2..".enabled", false)
		-- 	SetBool("game.tool."..melee..".enabled", false)
		-- 	SetBool("game.tool."..gun4..".enabled", false)
		-- 	if GetString("game.player.tool") == gun1 or GetString("game.player.tool") == gun2 or GetString("game.player.tool") == melee or GetString("game.player.tool") == gun4 then
		-- 		SetString("game.player.tool", "")
		-- 	end

		-- 	equipTimer = equipTimer - dt
		-- elseif equipTimer < 0 then
		-- 	SetBool("game.tool."..gun1..".enabled", true)
		-- 	SetBool("game.tool."..gun2..".enabled", true)
		-- 	SetBool("game.tool."..melee..".enabled", true)
		-- 	SetBool("game.tool."..gun4..".enabled", true)
		-- 	SetString("game.player.tool",lastPlayerTool)
		-- 	lastPlayerTool = ""

		-- 	equipTimer = 0
		-- end

		cantoggleprimary = (curtool == gun1 or curtool == gun4) and not GetBool("inventory.reloading") and not KeybindPressed(Settings.keybinds.player.reload)
		
	-- end	
	for i = 1, #scripts do
		local guns1 = Split(guns[1][1][1], "_")[1] or ""
		local guns2 = Split(guns[1][2][1], "_")[1] or ""
		local guns4 = Split(guns[1][4][1], "_")[1] or ""	
		
		

		if not (scripts[i][1] == guns1 or scripts[i][1] == guns2 or scripts[i][1] == guns4) then
			Delete(scripts[i][2])
			table.remove(scripts, i)
			break
		end
	end
	for i = 1, #gunslist do
		if (gunslist[i] == Split(guns[1][1][1], "_")[1] and guns[1][1][1] ~= "") or (gunslist[i] == Split(guns[1][4][1], "_")[1] and guns[1][4][1] ~= "") then
			local alreadySpawned = false

			for j = 1, #scripts do
				if scripts[j][1] == gunslist[i] then
					alreadySpawned = true
				end
			end

			if not alreadySpawned then
				local id = gunslist[i]
				local scriptName = gunScriptLookUp[id]
				if scriptName then -- (v2 fix) ids without a script (gun-mgl, gun-ak12, gun-mp443) crashed tick()
					local entities = Spawn('<script file="MOD/script/'..scriptName..'.lua"/>', Transform())
					table.insert(scripts, 1, {id,entities[1]})
				end
			end
		end
	end
	for i = 1, #gunslist2 do
		if (gunslist2[i] == Split(guns[1][2][1], "_")[1] and guns[1][2][1] ~= "") then
			local alreadySpawned = false

			for j = 1, #scripts do
				if scripts[j][1] == gunslist2[i] then
					alreadySpawned = true
				end
			end

			if not alreadySpawned then
				local id = gunslist2[i]
				local scriptName = gunScriptLookUp[id]
				if scriptName then -- (v2 fix) ids without a script (gun-mgl, gun-ak12, gun-mp443) crashed tick()
					local entities = Spawn('<script file="MOD/script/'..scriptName..'.lua"/>', Transform())
					table.insert(scripts, 1, {id,entities[1]})
				end
			end
		end
	end

	-- if not GetBool("level.optionstriggered") then



	local ammoRemoveRequest = GetString("inventory.removeammo")
	local materialRemoveRequest = GetString("inventory.removematerials")
	local grenadeRemoveRequest = GetBool("inventory.removegrenade")
	local grenade1RemoveRequest = GetBool("inventory.removegrenade1")

	local haveAmmoToRemove = ammoRemoveRequest ~= ""
	local isRocket = false
	local haveMaterialToRemove = materialRemoveRequest ~= ""
	local haveGrenadeToRemove = grenadeRemoveRequest
	local haveGrenade1ToRemove = grenade1RemoveRequest

	local haveRemoveRequest = haveAmmoToRemove or haveMaterialToRemove or haveGrenadeToRemove or haveGrenade1ToRemove
	if haveRemoveRequest then
		-- ammo
		local ammoTypeToRemove
		local ammoToRemove
		if haveAmmoToRemove then
			local ammoRemoveRequestInfos = Split(ammoRemoveRequest, "_")
			ammoTypeToRemove = ammoRemoveRequestInfos[1]
			ammoToRemove = tonumber(ammoRemoveRequestInfos[2]) or 0
			isRocket = string.sub(ammoTypeToRemove,1,6) == "rocket"
		end
		-- material
		local materialamounts 
		local materialRemoveAmounts = {}
		if haveMaterialToRemove then
			local materialRemoveInfos = Split(materialRemoveRequest, "_")
			materialRemoveAmounts["rubber"] = tonumber(materialRemoveInfos[1]) or 0
			materialRemoveAmounts["steel"] = tonumber(materialRemoveInfos[2]) or 0
			materialRemoveAmounts["kevlar"] = tonumber(materialRemoveInfos[3]) or 0
			materialRemoveAmounts["scrap"] = tonumber(materialRemoveInfos[4]) or 0
			materialRemoveAmounts["driftwood"] = tonumber(materialRemoveInfos[5]) or 0
			materialRemoveAmounts["explosive"] = tonumber(materialRemoveInfos[6]) or 0
		end

		for i = 1, #backpack do
			for j = 1, #backpack[i] do
				local item = backpack[i][j][1]
				local itemInfos = Split(item, "_")
				local id = itemInfos[1]
				local idInfos = Split(id, "-")
				if not isRocket and haveAmmoToRemove and idInfos[1] == "bullets" then
					if ammoToRemove > 0 then
						local ammoType = idInfos[2]
						if ammoType == ammoTypeToRemove or id == ammoTypeToRemove then
							local amount = tonumber(itemInfos[3])
							local ammoLeft = (amount or 1) - ammoToRemove
							if ammoLeft <= 0 then
								local w, h = GetDimensions(item)
								clearItem(backpack, {{"", {0, 0}, w, h}, i, j, backpack})
								backpack[i][j] = {"", {0, 0}, 1, 1}
								if ammoLeft < 0 then
									ammoToRemove = -ammoLeft
								else
									haveAmmoToRemove = false
								end
							else
								itemInfos[3] = ammoLeft
								backpack[i][j][1] = IDBuilder(itemInfos)
								ammoToRemove = 0
								haveAmmoToRemove = false
							end
						end
					else
						haveAmmoToRemove = false
					end
				elseif isRocket and haveAmmoToRemove and string.sub(id,1,6) == "rocket" then
					if ammoToRemove > 0 then
						if id == ammoTypeToRemove then
							local ammoLeft = 1 - ammoToRemove
							local w, h = GetDimensions(item)
							clearItem(backpack, {{"", {0, 0}, w, h}, i, j, backpack})
							backpack[i][j] = {"", {0, 0}, 1, 1}
							if ammoLeft < 0 then
								ammoToRemove = -ammoLeft
							else
								haveAmmoToRemove = false
							end
						end
					else
						haveAmmoToRemove = false
					end
				elseif haveGrenadeToRemove and id == "grenade" then
					clearItem(backpack, {{"", {0, 0}, 1, 1}, i, j, backpack})
					backpack[i][j] = {"", {0, 0}, 1, 1}
					haveGrenadeToRemove = false
				elseif haveGrenade1ToRemove and id == "grenade1" then
					local w, h = GetDimensions(item)
					clearItem(backpack, {{"", {0, 0}, w, h}, i, j, backpack})
					backpack[i][j] = {"", {0, 0}, 1, 1}
					haveGrenade1ToRemove = false
				elseif haveMaterialToRemove and idInfos[1] == "material" then
					local itemType = idInfos[2]
					if materialRemoveAmounts[itemType] then
						local amountToRemove = materialRemoveAmounts[itemType]
						if amountToRemove > 0 then
							local amount = tonumber(itemInfos[3])
							local amountLeft = (amount or 1) - amountToRemove
							if amountLeft <= 0 then
								local w, h = GetDimensions(item)
								clearItem(backpack, {{"", {0, 0}, w, h}, i, j, backpack})
								backpack[i][j] = {"", {0, 0}, 1, 1}
								-- (v2 fix) original used the backpack column [i] as key, so the material's amount was
								-- never reduced: every stack lost the full amount and the loop never finished early
								materialRemoveAmounts[itemType] = math.max(0, -amountLeft)
							else
								itemInfos[3] = amountLeft
								backpack[i][j][1] = IDBuilder(itemInfos)
								materialRemoveAmounts[itemType] = 0
							end
						end
						haveMaterialToRemove = false
						for _,v in pairs(materialRemoveAmounts) do if v > 0 then haveMaterialToRemove=true break end end
					end
				end
				haveRemoveRequest = haveAmmoToRemove or haveMaterialToRemove or haveGrenadeToRemove or haveGrenade1ToRemove
				if not haveRemoveRequest then break end
			end
			if not haveRemoveRequest then break end
		end
		
		-- (v2 fix) a partly used stack doesn't go through clearItem, so the counts (inventory.count_*,
		-- ammocount_*) were not recalculated: Place Tool allowed builds with stale counts, UI lagged.
		invChanged = true
		SetString("inventory.removeammo", "")
		SetString("inventory.removematerials", "")
		SetBool("inventory.removegrenade", false)
		SetBool("inventory.removegrenade1", false)
	end
	
	if invChanged then
		CountAmmo()
	end

	SetBool("level.inventory.open", _invOn)
	if packmagtimer > 0 then
		packmagtimer = packmagtimer - dt
	end
	tickCycleBad = false
	-- DebugWatch("invChanged", invChanged)
	invChanged = false
end

function drawInjuries(part)
	UiPush()
		UiTranslate(30, 70)
		UiAlign("center middle")
		if HasTag(parts[part], "Bleed") then
			UiColor(1,1,1, 1)
			UiImageBox("MOD/HealthSystem/UI/icon_drop.png", 30 + 4, 30 + 4, 0,0)
			UiColor(1,0,0, Oscillate(1)/2 + 1/2)
			UiImageBox("MOD/HealthSystem/UI/icon_drop.png", 30, 30, 0,0)
		end
		if HasTag(parts[part], "Fracture") then
			UiTranslate(0,40)
			UiColor(0,0,0, 1)
			UiImageBox("MOD/HealthSystem/UI/icon_broken_bone.png", 30 + 4,30 + 4 ,0,0)
			UiColor(1,1,1, Oscillate(1)/2 + 1/2)
			UiImageBox("MOD/HealthSystem/UI/icon_broken_bone.png", 30, 30, 0,0)
		end
	UiPop()
end

local scrollTable={}
function drawInv(invTable, w, h)
	if not scrollTable[invTable] then
		scrollTable[invTable] = {x=0,y=0}
	end
	local invSizeX = #invTable
	local invSizeY = #invTable[1]
	local w = w or invSizeX*60
	local h = h or invSizeY*60
	local horiScroll = false
	local vertScroll = false
	local horiExtraVal = 0
	local vertExtraVal = 0
	--local uiopacity = 1
	UiPush()
		UiWindow(w, h) -- fix pivoting
		UiAlign("left top")
		local horiScrollBarCompensationY = 0
		if w < invSizeX*60 then
			horiScroll = true
			horiScrollBarCompensationY = 20
			horiExtraVal = invSizeX*60 - w
		end
		if h < invSizeY*60 + horiScrollBarCompensationY then
			vertScroll = true
			vertExtraVal = invSizeY*60 + horiScrollBarCompensationY - h
		end
		if vertScroll then
			local mouseWheelY = -InputValue("mousewheel")
			scrollTable[invTable].y = math.max(math.min(scrollTable[invTable].y + mouseWheelY*30, vertExtraVal), 0)
		end
		UiPush()
			UiWindow(w, h - horiScrollBarCompensationY, true)
			UiTranslate(-scrollTable[invTable].x, -scrollTable[invTable].y)
			--BACKPACK
			UiColorFilter(1,1,1, uiopacity)
			for i = 1,invSizeX do
				UiPush()
					for j = 1,invSizeY do
						local invSlot = invTable[i][j]
						local item, w, h = invSlot[1], invSlot[3], invSlot[4]
						local rotation = invSlot.rotation or 0
						if invSlot[2][1] == 0 or item ~= "" then
							local itemInfos = Split(item, "_")
							local itemID = itemInfos[1]
							local itemIDInfos = Split(itemID, "-")
							local itemType = itemIDInfos[1]

							UiPush()
								local inside = UiIsMouseInRect(60*w, 60*h)
								--[[ if inside then
									DebugWatch('x',i)
									DebugWatch('y',j)
									DebugWatch('item',invSlot[1])
									DebugWatch('item parent x',invSlot[2][1])
									DebugWatch('item parent y',invSlot[2][2])
									DebugWatch('item parent w',invSlot[3])
									DebugWatch('item parent h',invSlot[4])
								end ]]
								if inside then
									UiColor(0.7, 0.7, 0.7, 1)
									if string.sub(itemType, 1, 3) == "mag" then								
										local bullets = InvGrab.info[1][1]
										local bulletsInfos = Split(bullets, "_")
										local bulletsID = bulletsInfos[1]
										local bulletsIDInfos = Split(bulletsID, "-")
										
										if #itemInfos < 6 then
											itemInfos[6] = "" 
											local bulletInfos = {}
											for i=1,tonumber(itemInfos[3]) do 
												bulletInfos[i] = GunDefaultBulletType[Split(itemInfos[1], "-")[3]]	
											end
											itemInfos[6] = table.concat(bulletInfos, "-")
										end				
										if bulletsIDInfos[1] == "bullets" then
											local itemCurAmmo, itemMaxAmmo = tonumber(itemInfos[3]), tonumber(itemInfos[4])
											local bulletCurAmmo = tonumber(bulletsInfos[3])
											if packmagtimer <= 0 then
												if itemCurAmmo < itemMaxAmmo and bulletsIDInfos[2] == itemIDInfos[3] and bulletCurAmmo > 0 then
													local bullettypeInfos = Split(itemInfos[6], "-")
													bullettypeInfos[itemCurAmmo+1] = bulletsIDInfos[3]
														
													itemInfos[6] = table.concat(bullettypeInfos, "-")
													
													bulletsInfos[3] = bulletCurAmmo - 1
													itemInfos[3] = itemCurAmmo + 1
													InvGrab.info[1][1] = IDBuilder(bulletsInfos)
													invSlot[1] = IDBuilder(itemInfos)
													--for i=1,50 do DebugPrint("") end
													--DebugPrint(invSlot[1])
													PlaySound(SOUNDS.loadBullet, GetPlayerTransform().pos, 1, false)
													packmagtimer = packmagtimer + 0.2
												end
											end
											if tonumber(bulletsInfos[3]) == 0 then
												local ox, oy = InvGrab.info[1][2][1], InvGrab.info[1][2][2]
												clearItem(InvGrab.info[4], {{"", {0, 0}, InvGrab.info[1][3], InvGrab.info[1][4]}, ox, oy, InvGrab.info[4]})
												InvGrab.info = {{"", {0, 0}, 1, 1}, 0, 0}
											end
										end	
									end	
									--DebugPrint(itemType)
									if itemType == "gun" and (itemIDInfos[2] == "m870" or itemIDInfos[2] == "mp43" or itemIDInfos[2] == "sawedoff" or itemIDInfos[2] == "cz1012" or itemIDInfos[2] == "sks" or itemIDInfos[2] == "mosin" or itemIDInfos[2] == "mosinm" or itemIDInfos[2] == "ks23") then								
										local bullets = InvGrab.info[1][1]
										local bulletsInfos = Split(bullets, "_")
										local bulletsID = bulletsInfos[1]
										local bulletsIDInfos = Split(bulletsID, "-")
										
							
										if bulletsIDInfos[1] == "bullets" then
											local itemCurAmmo, itemMaxAmmo = tonumber(itemInfos[5]), tonumber(itemInfos[6])
											local bulletCurAmmo = tonumber(bulletsInfos[3])
											if packmagtimer <= 0 then
												if itemCurAmmo < itemMaxAmmo and bulletsIDInfos[2] == displayCaltoCalID(itemInfos[7]) and bulletCurAmmo > 0 then
													local bullettypeInfos = Split(itemInfos[10], "-")
													bullettypeInfos[itemCurAmmo+1] = bulletsIDInfos[3]
														
													itemInfos[10] = table.concat(bullettypeInfos, "-")
													
													bulletsInfos[3] = bulletCurAmmo - 1
													itemInfos[5] = itemCurAmmo + 1
													InvGrab.info[1][1] = IDBuilder(bulletsInfos)
													invSlot[1] = IDBuilder(itemInfos)
													--for i=1,50 do DebugPrint("") end
													--DebugPrint(invSlot[1])
													PlaySound(SOUNDS.loadBullet, GetPlayerTransform().pos, 1, false)
													packmagtimer = packmagtimer + 0.5
												end
											end
											if tonumber(bulletsInfos[3]) == 0 then
												local ox, oy = InvGrab.info[1][2][1], InvGrab.info[1][2][2]
												clearItem(InvGrab.info[4], {{"", {0, 0}, InvGrab.info[1][3], InvGrab.info[1][4]}, ox, oy, InvGrab.info[4]})
												InvGrab.info = {{"", {0, 0}, 1, 1}, 0, 0}
											end
										end
									end
								
								else
									if itemType == "gun" then
										UiColor(0.2, 0.1, 0.1, 0.5)
		
										local mag = InvGrab.info[1][1]
										if string.sub(mag, 1, 3) == "mag" then
											local guninfo = Split(item, "_")
											local maginfo = Split(mag, "_")
											local caliber1, caliber2 = maginfo[5], guninfo[7]
											if caliber1 == caliber2 and guninfo[3] == "none" and checkMagCompatibility(mag, item) then
												UiColor(0.6, 0.3, 0.3, 0.5)
											end
										end
									elseif string.sub(itemType, 1, 4) == "food" then
										UiColor(0.1, 0.2, 0.1, 0.5)
									elseif itemType == "vest" or itemType == "helmet" or itemType == "eyewear" then
										UiColor(0.1, 0.15, 0.2, 0.5)
									elseif itemType == "material" then
										UiColor(0.2, 0.2, 0.2, 0.5)
									elseif string.sub(itemType, 1, 3) == "mag" then
										UiColor(0.2, 0.15, 0.1, 0.5)
		
										local bullets = InvGrab.info[1][1]
										local bulletsInfos = Split(bullets, "_")
										local bulletsID = bulletsInfos[1]
										local bulletsIDInfos = Split(bulletsID, "-")
										if bulletsIDInfos[1] == "bullets" then
											if tonumber(itemInfos[3]) < tonumber(itemInfos[4]) and bulletsIDInfos[2] == itemIDInfos[3] then
												UiColor(0.6, 0.45, 0.3, 0.5)
											end
										end
									elseif itemType == "bullets" or string.sub(itemType,1,6) == "rocket" then
										UiColor(0.2, 0.15, 0.1, 0.5)
									else
										UiColor(0.1, 0.1, 0.1, 0.5)
									end
								end
								UiImageBox("ui/common/box-solid-6.png", 60*w, 60*h, 6, 6)
								UiColor(1, 1, 1, 1)
								UiImageBox("ui/common/box-outline-6.png", 60*w, 60*h, 6, 6)
								
								if item ~= "" then
									UiPush()
										UiTranslate(w*30, h*30)
										UiAlign("center middle")
										UiRotate(rotation*-90)
										drawItem(item)
									UiPop()
								end

								if inside and item ~= "" then
									HoverDesc.cord = {i, j}
									HoverDesc.invTable = invTable
									if KeybindDown(Settings.keybinds.inventory.drop_item) then
										SetString("inventory.drop", item)
										invTable[i][j] = {"", {0, 0}, w, h}
										clearItem(invTable, {{"", {0, 0}, w, h}, i, j, invTable})
									end
								end

								if HoverDesc.cord[1] == i and HoverDesc.cord[2] == j then
									HoverDesc.timer = HoverDesc.timer + GetTimeStep()
								end
								if InputPressed("grab") and inside and item ~= "" then
									rightclickinfo = {item, i, j, invTable, invTable}
								end
								if not InputDown("usetool") and inside and InvGrab.info[1][1] ~= "" and rightclickinfo[1] == "" then
									local mouseX, mouseY = UiGetMousePos()
									local offsetI, offsetJ = Round(InvGrab.offset[1]/60 - mouseX/60), Round(InvGrab.offset[2]/60 - mouseY/60)
									placeItem(invTable, InvGrab.info, i - offsetI, j - offsetJ, false)
									PlayBackpackSound()
									InvGrab.info = {{"", {0, 0}, 1, 1}, 0, 0}
								end
								if InputPressed("usetool") and inside and rightclickinfo[1] == "" and InvGrab.info[1][1] == "" then
									if item ~= "" then
										if InputDown("ctrl") and itemIDInfos[1] == "bullets" then
											local newStackInfo = Split(item, "_") --"ИДИ НА ХУЙ"
											local oldStackInfo = Split(item, "_")
											local amount = math.floor(tonumber(oldStackInfo[3])/2)
											local amountmax = oldStackInfo[3]

											newStackInfo[3] = amount
											oldStackInfo[3] = amountmax-amount
											print(amount)
											print(amountmax-amount)

											if amount > 0 then
												local mouseX, mouseY = UiGetMousePos()
												InvGrab.offset = {mouseX, mouseY}
												InvGrab.info = {deepcopy(invSlot), i, j, invTable}
												InvGrab.info[1][1] = IDBuilder(newStackInfo)
												invSlot[1] = IDBuilder(oldStackInfo)
											end
										else
											local mouseX, mouseY = UiGetMousePos()
											InvGrab.offset = {mouseX, mouseY}
											InvGrab.info = {invSlot, i, j, invTable}
											invTable[i][j] = {"", {0, 0}, w, h}
											clearItem(invTable, {{"", {0, 0}, w, h}, i, j, invTable})
										end
									end
								end
								
							UiPop()
						end
						UiTranslate(0, 60)
					end
				UiPop()
				UiTranslate(60, 0)
			end
		UiPop()
		if rightclickinfo[4] == invTable and rightclickinfo[1] ~= "" then
			UiPush()
				local i, j = rightclickinfo[2], rightclickinfo[3]
				local invSlot = invTable[i][j]
				local w, h = invSlot[3], invSlot[4]
				UiTranslate(i*60 - 60 + w*30, j*60 - 60 + h*30)
				drawRightClickMenu()
			UiPop()
		end
		if horiScroll then
			UiAlign("left top")
			UiTranslate(0, h-20)
			UiColor(0, 0, 0, 0)
			local magicRatio = w / (invSizeX*60)
			UiSliderThumbSize(w * magicRatio,20)
			scrollTable[invTable].x = UiSlider("", "x", scrollTable[invTable].x * magicRatio, 0 , horiExtraVal * magicRatio) /  magicRatio
			UiTranslate(scrollTable[invTable].x * magicRatio, 0)
			if UiIsMouseInRect(w * magicRatio, 20) then
				UiColor(0.7, 0.7, 0.1, 0.5)
			else
				UiColor(0.1, 0.1, 0.1, 0.5)
			end
			UiImageBox("ui/common/box-solid-6.png", w * magicRatio, 20, 6, 6)
			UiColor(1, 1, 1, 1)
			UiImageBox("ui/common/box-outline-6.png", w * magicRatio, 20, 6, 6)
		end
	UiPop()
end

function draw()
	UiAlign("left top")

	if _invState == "shop" and _invOn then
		UiBlur(0.5)
	end

	if WeaponWheel then
		draw_WeaponWheel()
	end

	if medtimer > 0 then
		local percent = math.floor((1 - medtimer/medtimermax) * 100)
		UiPush()
			UiTranslate(UiWidth()/2-90, UiHeight()*.75-20)
			UiProgressBarTitled("HEALING " .. percent .. "%", medtimermax - medtimer, medtimermax, 180, 40, 1, .2, .1, 0)
		UiPop()
		-- if InputPressed("usetool") then
		-- 	medtimer = 0
		-- end
	end



	------INVENTORY SYSTEM------

	if not _invOn and uiopacity == 0 then
		displayQueedPerkInfos()
		return
	end

	if string.sub(InvGrab.info[1][1], 1, 4) == "meds" then togglemenu = true else togglemenu = false end
	if _invState ~= "" then shifthorizontal = 0 else shifthorizontal = 0 end
	shiftvertical = -30
	if _invOn and medtimer <= 0 or uitimer > 0 then
		local mouseinpane = false
		UiPush()
			UiColor(0, 0, 0, 0.7*uiopacity)
			UiTranslate(UiWidth()/2-810+shifthorizontal, UiHeight()/2-480+shiftvertical)
			UiImageBox("ui/common/box-solid-6.png", 480, 900, 6, 6)
			mouseinpane = mouseinpane or UiIsMouseInRect(480, 900)
			UiAlign("left middle")
			UiFont("bold.ttf", 32)
			UiTranslate(10, 30)
			UiColor(1,1,1,1*uiopacity)
			-- if togglemenu then
			-- 	if UiTextButton("Armor") then togglemenu = not togglemenu end
			-- else
			-- 	if UiTextButton("Health") then togglemenu = not togglemenu end
			-- end
		UiPop()
		UiPush()
			UiColor(0, 0, 0, 0.7*uiopacity)
			UiTranslate(UiWidth()/2-300+shifthorizontal, UiHeight()/2-480+shiftvertical)
			if _invState ~= "" then
				UiImageBox("ui/common/box-solid-6.png", 1170, 990, 6, 6)
				mouseinpane = mouseinpane or UiIsMouseInRect(1170, 990)
			else
				UiImageBox("ui/common/box-solid-6.png", 660, 990, 6, 6)
				mouseinpane = mouseinpane or UiIsMouseInRect(660, 990)
			end
		UiPop()

		if not mouseinpane and (InputPressed("lmb") or InputPressed("usetool")) then
			_invOn = false
		end

		UiPush()
			UiAlign("center middle")
			UiTranslate(UiWidth()/2-210+shifthorizontal, UiHeight()/2-360+shiftvertical)
			UiPush()
				UiAlign("left middle")
				UiFont("regular.ttf", 32)
				UiTranslate(-60,-45)
				UiColor(1, 1, 1, 1*uiopacity)
				UiText("Backpack")
			UiPop()
			UiColor(0.1, 0.1, 0.1, 0.5*uiopacity)
			UiImageBox("ui/common/box-solid-6.png", 120, 120, 6, 6)
			UiColor(1, 1, 1, 1*uiopacity)
			UiImageBox("ui/common/box-outline-6.png", 120, 120, 6, 6)
			UiImageBox("MOD/img/icon/backpack.png", 120, 120)
			UiTranslate(-60,-75)
			UiAlign("left middle")
			UiFont("bold.ttf", 32)
			UiText("Inventory")
			UiPush()
				UiTranslate(0,150)
				UiFont("bold.ttf", 16)
				UiText("Perks:")
				UiTranslate(0,20)
				UiFont("regular.ttf", 12)
				ClearKey("savegame.mod.perks.5")
				for i=1,#PERKORDER do
					local perk=PERKORDER[i]
					if HasKey("savegame.mod.perks."..perk)then
						UiText(string.upper(perk)..": "..GetInt("savegame.mod.perks."..perk))
						UiTranslate(0, 16)
					end
				end
			UiPop()
			if _invState == "stash" then
				UiTranslate(630)
				UiText("Stash")
			elseif _invState == "loot" then
				UiTranslate(630)
				UiText("Loot")
			elseif _invState == "attachmment" then
				UiTranslate(630)
				UiText("Attachments")
			elseif _invState == "shop" then
				UiTranslate(630)
				UiText("Shop")
				UiPush()
					UiColor(0.4,1,0.4,uiopacity)
					UiTranslate(70,0)
					UiFont("regular.ttf", 32)
					UiText("$"..sfnCommas(tostring(GetInt("savegame.mod.player.money"))))
				UiPop()
				UiPush()
					UiTranslate(280,0)
					UiFont("bold.ttf", 30)
					UiAlign("center middle")

					local solid = "ui/common/box-solid-6.png"
					local outline = "ui/common/box-outline-6.png"

					UiColor(1, 1, 1, ternary(buying, 0.5, 0.3))
					UiImageBox(ternary(buying, solid, outline), 130, 32, 6, 6)
					UiColor(1, 1, 1, ternary(buying, 1, 0.7))
					if UiTextButton("Buying") then buying = true PlaySound(SOUNDS.uinext) end

					UiTranslate(135,0)

					UiColor(1, 1, 1, ternary(not buying, 0.5, 0.3))
					UiImageBox(ternary(not buying, solid, outline), 130, 32, 6, 6)
					UiColor(1, 1, 1, ternary(not buying, 1, 0.7))
					if UiTextButton("Selling") then buying = false PlaySound(SOUNDS.uinext) end

				UiPop()
			end
		UiPop()

		UiPush()
			UiAlign("center middle")
			UiTranslate(UiWidth()/2-780+shifthorizontal, UiHeight()/2+45+shiftvertical)
			UiColor(1, 1, 1, 1*uiopacity)
			UiAlign("left middle")
			UiPush()
				UiFont("bold.ttf", 32)
				UiTranslate(0,-30)
				UiText("Weapons")
			UiPop()
			UiFont("regular.ttf", 32)
			UiText("Sling")
			UiTranslate(0,120)
			UiText("Back")
			UiTranslate(0,120)
			UiText("Holster")
			UiTranslate(120,0)
			UiText("Scabbard")
		UiPop()

		UiPush()
			-- if togglemenu then

			-- else
			UiAlign("center middle")
			UiTranslate(UiWidth()/2-780+shifthorizontal, UiHeight()/2-435+shiftvertical)
			UiColor(1, 1, 1, 1*uiopacity)
			UiAlign("left middle")
			UiFont("bold.ttf", 32)
			UiText("Armor")
			UiFont("regular.ttf", 32)
			UiTranslate(0, 30)
			UiText("Eyewear")
			UiTranslate(0, 90)
			UiText("Helmet")
			UiTranslate(0, 150)
			UiText("Vest")
			-- end
		UiPop()

		HoverDesc.cord = {0,0}

		--BACKPACK
		UiPush()
			UiColor(0.7, 0.7, 0.7, 1*uiopacity)
			UiAlign("center middle")
			UiTranslate(UiCenter()+90+shifthorizontal, UiMiddle()+30+shiftvertical)
			--UiRect(100, 1)
			--UiRect(1, 100)
			drawInv(backpack)
		UiPop()

		--STASH
		if _invState=="stash" then
			UiPush()
				UiAlign("center middle")
				UiTranslate(UiCenter()+600+shifthorizontal, UiMiddle()+30+shiftvertical)
				drawInv(stash)
			UiPop()
		end

		--LOOT
		if _invState=="loot" then
			UiPush()
				UiTranslate(UiCenter()+360+shifthorizontal, UiMiddle()-420+shiftvertical)
				drawInv(loot)
			UiPop()
		end

		--SHOP
		if _invState == "shop" then
			if buying and InvGrab.info[1][1] == "" then
				UiPush()
					local playermoney = GetInt("savegame.mod.player.money")
					UiAlign("center middle")
					UiTranslate(UiWidth()/2+410+shifthorizontal, UiHeight()/2-405+shiftvertical)
					local tabno=0
					for section, shoptable in pairs(invMarket) do
						if not curshop then curshop = section end
						tabno = tabno+1
						UiColor(0,0,0,0.7*uiopacity)
						UiImageBox("ui/common/box-solid-6.png", 100, 30, 6, 6)
						UiColor(1,1,1,uiopacity)
						if section == curshop then
							UiFont("bold.ttf", 20)
						else
							UiFont("regular.ttf", 20)
						end
						if UiTextButton(section) then curshop = section PlaySound(SOUNDS.uinext) end
						if tabno%4==0 then UiTranslate(-110*3,40) else UiTranslate(110,0) end
					end
					UiTranslate(-50-110*(tabno%4),30)
					if curshop ~= "" then
						if removeShopItem ~= 0 then
							table.remove(invMarket[curshop],removeShopItem)
							removeShopItem = 0
						end
						curSection = invMarket[curshop]
						for i = 1, #curSection do
							curListing = curSection[i]
							local item = curListing.item
							local price = math.floor(curListing.price * inflation)
							local w,h=GetDimensions(item)
							UiPush()
								UiTranslate(30*w,30*h)
								UiColor(1,1,1,0.4*uiopacity)
								UiImageBox("ui/common/box-outline-6.png", 60*w, 60*h, 6, 6)
								UiColor(1,1,1,uiopacity)
								drawItem(item, w, h)

								if playermoney >= price then -- Red if no money lmao poor
									UiColor(1,1,1,uiopacity)
								else
									UiColor(1,0.4,0.4,uiopacity)
									UiDisableInput()
								end
								if UiBlankButton(60*w,60*h)then
									playermoney = playermoney - price
									SetInt("savegame.mod.player.money", playermoney)
									SetString("inventory.pickup", item)
									removeShopItem = i
									PlaySound(SOUNDS.cash)
								end
								if UiIsMouseInRect(60*w,60*h)then
									UiPush()
										if InputDown('usetool') then
											UiColor(0,0,0,.4*uiopacity)
											UiImageBox("ui/common/box-solid-6.png", 60*w, 60*h, 6, 6)
										else
											UiColor(1,1,1,.4*uiopacity)
											UiImageBox("ui/common/box-solid-6.png", 60*w, 60*h, 6, 6)
										end
									UiPop()
								end
								UiTranslate(30*w+10,0)
								UiPush()
									UiAlign("left middle")
									UiTranslate(0,-20)
									UiFont("regular.ttf", 20)
									UiText("Price: $"..sfn(price))
									UiTranslate(0,40)
									UiFont("bold.ttf", 20)
									if UiTextButton("Purchase") then
										playermoney = playermoney - price
										SetInt("savegame.mod.player.money", playermoney)
										SetString("inventory.pickup", item)
										removeShopItem = i
										PlaySound(SOUNDS.cash)
									end
								UiPop()
							UiPop()

							UiTranslate(0,60*h+30)
						end
					end
				UiPop()
			else
				UiPush()
					local itemPrice = 0
					UiAlign("center middle")
					UiTranslate(UiWidth()/2+600+shifthorizontal, UiHeight()/2+30+shiftvertical)
					UiColor(1,1,1,0.4*uiopacity)
					UiImageBox("ui/common/box-outline-6.png", 480, 900, 6, 6)
					UiFont("bold.ttf", 48)
					if InvGrab.info[1][1] == "" then
						UiText("Drag here to sell")
					else
						itemPrice = { getPrice(InvGrab.info[1][1]) }
						Monetaryitemprice = math.floor(itemPrice[1] * inflation)
						UiText("Sell for: $"..sfn(Monetaryitemprice))
					end
					local inside = UiIsMouseInRect(480, 900)
					if InputReleased("usetool") and inside and InvGrab.info[1][1] ~= "" then
						local playermoney = GetInt("savegame.mod.player.money")
						SetInt("savegame.mod.player.money", playermoney + Monetaryitemprice)
						local amountsoldalready = economy[itemPrice[2]] or 0
						economy[itemPrice[2]] = amountsoldalready + 1
						
						clearItem(InvGrab.info[4], InvGrab.info)
						InvGrab.info = {{"", {0, 0}, 1, 1}, 0, 0}
						PlaySound(SOUNDS.cash)
					end
				UiPop()
			end
		end
	
		--GUNS
		UiTranslate(UiWidth()/2-960+shifthorizontal, UiHeight()/2+shiftvertical)
		UiPush()
			UiTranslate(180, 30)
			local i = 1
			for j = 1,4 do
				local item = guns[i][j][1]
				local itemInfos = Split(item, "_")
				local itemID = itemInfos[1]
				local itemIDInfos = Split(itemID, "-")
				local itemType = itemIDInfos[1]
				local w2, h2 = guns[i][j][3], guns[i][j][4]
				local w, h = 5, 2
				if j == 1 or j == 4 then
					w, h = 7, 2
				else
					w, h = 2, 2
				end
				local scale = 1
				if j == 3 then
					scale = math.min(w/w2,h/h2)
				end
				--DebugPrint(itemType)
				UiPush()
					local inside = UiIsMouseInRect(60*w, 60*h)
					if inside then
						UiColor(0.7, 0.7, 0.7, 1*uiopacity)
						UiImageBox("ui/common/box-solid-6.png", 60*w, 60*h, 6, 6)
						if itemType == "gun" and (itemIDInfos[2] == "m870" or itemIDInfos[2] == "mp43" or itemIDInfos[2] == "cz1012" or itemIDInfos[2] == "mosin" or itemIDInfos[2] == "ks23" or itemIDInfos[2] == "sks" or itemIDInfos[2] == "mosinm" or itemIDInfos[2] == "sawedoff") then										
							local bullets = InvGrab.info[1][1]
							local bulletsInfos = Split(bullets, "_")
							local bulletsID = bulletsInfos[1]
							local bulletsIDInfos = Split(bulletsID, "-")							
							if bulletsIDInfos[1] == "bullets" then
								local itemCurAmmo, itemMaxAmmo = tonumber(itemInfos[5]), tonumber(itemInfos[6])
								local bulletCurAmmo = tonumber(bulletsInfos[3])
								if packmagtimer <= 0 then
									if itemCurAmmo < itemMaxAmmo and bulletsIDInfos[2] == displayCaltoCalID(itemInfos[7]) and bulletCurAmmo > 0 then
										local bullettypeInfos = Split(itemInfos[10], "-")
										bullettypeInfos[itemCurAmmo+1] = bulletsIDInfos[3]
														
										itemInfos[10] = table.concat(bullettypeInfos, "-")
													
										bulletsInfos[3] = bulletCurAmmo - 1
										itemInfos[5] = itemCurAmmo + 1
										InvGrab.info[1][1] = IDBuilder(bulletsInfos)
										guns[i][j][1] = IDBuilder(itemInfos)
										for u=1,4 do 
											SetBool("inventory.update_guns"..u.."", true)
										end
										--for i=1,50 do DebugPrint("") end
										--DebugPrint(backpack[i][j][1])
										PlaySound(SOUNDS.loadBullet, GetPlayerTransform().pos, 1, false)
										packmagtimer = packmagtimer + 0.5
									end
								end
								if tonumber(bulletsInfos[3]) == 0 then
									local ox, oy = InvGrab.info[1][2][1], InvGrab.info[1][2][2]
									clearItem(InvGrab.info[4], {{"", {0, 0}, InvGrab.info[1][3], InvGrab.info[1][4]}, ox, oy, InvGrab.info[4]})
									InvGrab.info = {{"", {0, 0}, 1, 1}, 0, 0}
								end
							end
						end
					else
						UiColor(0.2, 0.1, 0.1, 0.5*uiopacity)
						local grabbedGun = InvGrab.info[1][1]
						local grabbedGunInfos = Split(grabbedGun, "_")
						local grabbedGunIDInfos = Split(grabbedGunInfos[1], "-")
						if grabbedGunIDInfos[1] == "gun" then
							local id = grabbedGunInfos[1]
							if j == 1 or j == 4 then
								for i = 1, #gunslist do
									if gunslist[i] == id then
										UiColor(0.6, 0.3, 0.3, 0.5*uiopacity)
										break
									end
								end
							elseif j==2 then
								for i = 1, #gunslist2 do
									if gunslist2[i] == id then
										UiColor(0.6, 0.3, 0.3, 0.5*uiopacity)
										break
									end
								end
							end
						elseif grabbedGunIDInfos[1] == "melee" and j == 3 then
							UiColor(0.6, 0.3, 0.3, 0.5*uiopacity)
						end
						UiImageBox("ui/common/box-solid-6.png", 60*w, 60*h, 6, 6)
					end
					UiColor(1, 1, 1, 1*uiopacity)
					UiImageBox("ui/common/box-outline-6.png", 60*w, 60*h, 6, 6)
					--SetString("savegame.mod.inventory.guns."..j..".item", guns[i][j][1])
					--SetString("inventory.guns."..j..".item", guns[i][j][1])
					if item ~= "" then
						UiPush()
							UiAlign("center middle")
							UiTranslate(30*w, 30*h)
							drawItem(item, w, h, scale)
						UiPop()
					end
					if inside and item ~= "" then
						HoverDesc.cord = {i, j}
						HoverDesc.invTable = guns
						if KeybindDown(Settings.keybinds.inventory.drop_item) then
							SetString("inventory.drop", guns[i][j][1])
							guns[i][j] = {"", {0, 0}, w, h}
							clearItem(guns, {{"", {0, 0}, w, h}, i, j, guns})
						end
					end
					if HoverDesc.cord[1] == i and HoverDesc.cord[2] == j and HoverDesc.invTable == guns then
						HoverDesc.timer = HoverDesc.timer + GetTimeStep()
					end
					if not InputDown("usetool") and inside and InvGrab.info[1][1] ~= "" and rightclickinfo[1] == "" then
						placeItem(guns, InvGrab.info, i, j, true)
						PlayGunEquipSound()
						InvGrab.info = {{"", {0, 0}, 1, 1}, 0, 0}
					end
					if InputPressed("usetool") and inside and rightclickinfo[1] == "" and InvGrab.info[1][1] == "" then
						if guns[i][j][1] ~= "" then
							local mouseX, mouseY = UiGetMousePos()
							mouseX, mouseY = mouseX/w, mouseY/h
							local w, h = guns[i][j][3], guns[i][j][4]
							mouseX, mouseY = mouseX*w, mouseY*h -- fix pivot so mouse ends up on the item even if its smaller/bigger then the slot box
							InvGrab.offset = {mouseX, mouseY}
							InvGrab.info = {guns[i][j], i, j, guns}
							guns[i][j] = {"", {0, 0}, w, h}
						end
					end
					if InputPressed("grab") and inside then
						rightclickinfo = {guns[i][j][1], i, j, guns, guns}
					end
					if rightclickinfo[4] == guns and rightclickinfo[1] ~= "" and rightclickinfo[2] == i and rightclickinfo[3] == j then
						UiPush()
							UiAlign("center middle")
							UiTranslate(30*w, 30*h)
							drawRightClickMenu(true)
						UiPop()
					end
				UiPop()
				if j == 1 then
					UiTranslate(0, 240)
				elseif j == 2 then
					UiTranslate(120, 0)
				elseif j == 3 then
					UiTranslate(-120, -120)
				end
			end
		UiPop()

		-- if togglemenu then

		--HEALTH
		-- UiTranslate(UiWidth()/2-540, UiHeight()/2-975)
		UiTranslate(420, -435)
		UiPush()
			local function bodyPartsHPColor(bodyPartTrigger) -- too lazy to move it out, also not tested
				local ColorValue = (tonumber(GetTagValue(bodyPartTrigger, "CurrentHealth")) or 1) / (tonumber(GetTagValue(bodyPartTrigger, "MaxHP")) or 1)
				if ColorValue == 0 then
					UiColor(1,1,1, 1*uiopacity)
				else
					UiColor(1 - (.8*ColorValue), ColorValue, .2*ColorValue, 1*uiopacity)
				end
			end
			UiFont("bold.ttf", 25)

			UiTranslate(-15, -15)
			bodyPartsHPColor(parts[1])
			UiRect(90,90)
			drawInjuries(1)

			UiTranslate(-15, 95)
			bodyPartsHPColor(parts[2])
			UiRect(120,180)
			drawInjuries(2)

			UiTranslate(-65, 0)
			bodyPartsHPColor(parts[3])
			UiRect(60,180)
			drawInjuries(3)

			UiTranslate(190, 0)
			bodyPartsHPColor(parts[4])
			UiRect(60,180)
			drawInjuries(4)

			UiTranslate(-62, 185)
			bodyPartsHPColor(parts[5])
			UiRect(57,180)
			drawInjuries(5)

			UiTranslate(-63, 0)
			bodyPartsHPColor(parts[6])
			UiRect(58,180)
			drawInjuries(6)
		UiPop()

		UiPush()
			local i = 1
			for j = 1,#health[i] do
				local w, h = health[i][j][3], health[i][j][4]
				local inside = UiIsMouseInRect(60*w, 60*h)
				if inside then
					UiColor(0.7, 0.7, 0.7, 1*uiopacity)
				else
					UiColor(0.1, 0.15, 0.2, 0.5*uiopacity)
					local grabbedMed = InvGrab.info[1][1]
					local grabbedMedInfos = Split(grabbedMed, "_")
					local grabbedMedIDInfos = Split(grabbedMedInfos[1], "-")
					if grabbedMedIDInfos[1] == "meds" then
						local compatible=false
						local HP=tonumber(GetTagValue(parts[j], "CurrentHealth"))
						local MaxHP=tonumber(GetTagValue(parts[j], "MaxHP"))
						for k = 2, #grabbedMedIDInfos-1 do
							if grabbedMedIDInfos[k] == "general" then
								if HP < MaxHP and HP > 0 then
									compatible=true
								end
							elseif grabbedMedIDInfos[k] == "bleed" then
								if HasTag(parts[j], "Bleed") then compatible=true end
							elseif grabbedMedIDInfos[k] == "fracture" then
								if HasTag(parts[j], "Fracture") then compatible=true end
							elseif grabbedMedIDInfos[k] == "surgery" then
								if HP == 0 then compatible=true end
							end
						end

						if compatible then
							UiColor(0.4, 0.6, 0.8, 0.5*uiopacity)
						end
					end
				end
				UiImageBox("ui/common/box-solid-6.png", 60*w, 60*h, 6, 6)
				UiColor(1, 1, 1, 1*uiopacity)
				UiImageBox("ui/common/box-outline-6.png", 60*w, 60*h, 6, 6)

				--[[ if item ~= "" then
					UiPush()
						UiAlign("center middle")
						UiTranslate(30*w,30*h)
						drawItem(item)
					UiPop()
				end ]]

				if not InputDown("usetool") and inside and InvGrab.info[1][1] ~= "" then
					placeItem(health, InvGrab.info, i, j, true)
					InvGrab.info = {{"", {0, 0}, 1, 1}, 0, 0}
				end

				if j == 1 then
					UiTranslate(0, 120)
				elseif j == 2 then
					UiTranslate(-120, 0)
				elseif j == 3 then
					UiTranslate(240, 0)
				elseif j == 4 then
					UiTranslate(-60, 180)
				elseif j == 5 then
					UiTranslate(-120, 0)
				end
			end
		UiPop()

		-- else

		--ARMOR
		-- UiTranslate(UiWidth()/2-870, UiHeight()/2-750)
		UiTranslate(-270, 225)
		UiPush()
			UiTranslate(30, 30)
			local i = 1
			for j = 1,#armor[i] do
				local item = armor[i][j][1]
				local w, h
				local w2, h2 = armor[i][j][3], armor[i][j][4]
				local scale
				if j == 3 then
					w, h = 2, 1
					scale = math.min(w/w2,h/h2)
				elseif j == 2 then
					w, h = 2, 2
					scale = math.min(w/w2,h/h2)
				elseif j == 1 then
					w, h = 2, 2
					scale = math.min(w/w2,h/h2)
				end
				UiPush()
					local inside = UiIsMouseInRect(60*w, 60*h)
					if inside then
						UiColor(0.7, 0.7, 0.7, 1*uiopacity)
					else
						UiColor(0.1, 0.15, 0.2, 0.5*uiopacity)
						local grabbedArmor = InvGrab.info[1][1]
						local grabbedArmorInfos = Split(grabbedArmor, "_")
						local grabbedArmorIDInfos = Split(grabbedArmorInfos[1], "-")
						if grabbedArmorIDInfos[1] == "vest" and j == 1 then
							UiColor(0.3, 0.45, 0.6, 0.5*uiopacity)
						elseif grabbedArmorIDInfos[1] == "helmet" and j == 2 then
							UiColor(0.3, 0.45, 0.6, 0.5*uiopacity)
						elseif grabbedArmorIDInfos[1] == "eyewear" and j == 3 then
							UiColor(0.3, 0.45, 0.6, 0.5*uiopacity)
						end

					end
					UiImageBox("ui/common/box-solid-6.png", 60*w, 60*h, 6, 6)
					UiColor(1, 1, 1, 1*uiopacity)
					UiImageBox("ui/common/box-outline-6.png", 60*w, 60*h, 6, 6)

					if item ~= "" then
						UiPush()
							UiAlign("center middle")
							UiTranslate(30*w,30*h)
							drawItem(item, w, h, scale)
						UiPop()
					end
					if inside and item ~= "" then
						HoverDesc.cord = {i, j}
						HoverDesc.invTable = armor
						if KeybindDown(Settings.keybinds.inventory.drop_item) then
							SetString("inventory.drop", armor[i][j][1])
							armor[i][j] = {"", {0, 0}, w, h}
							clearItem(armor, {{"", {0, 0}, w, h}, i, j, armor})
						end
					end
					if HoverDesc.cord[1] == i and HoverDesc.cord[2] == j and HoverDesc.invTable == armor then
						HoverDesc.timer = HoverDesc.timer + GetTimeStep()
					end
					if not InputDown("usetool") and inside and InvGrab.info[1][1] ~= "" then
						placeItem(armor, InvGrab.info, i, j, true)
						PlayArmorEquipSound(InvGrab.info[1][1])
						InvGrab.info = {{"", {0, 0}, 1, 1}, 0, 0}
					end
					if InputPressed("usetool") and inside and InvGrab.info[1][1] == "" then
						if armor[i][j][1] ~= "" then
							local mouseX, mouseY = UiGetMousePos()
							mouseX, mouseY = mouseX/w, mouseY/h
							local w, h = armor[i][j][3], armor[i][j][4]
							mouseX, mouseY = mouseX*w, mouseY*h -- fix pivot so mouse ends up on the item even if its smaller/bigger then the slot box
							InvGrab.offset = {mouseX, mouseY}
							InvGrab.info = {armor[i][j], i, j, armor}
							armor[i][j] = {"", {0, 0}, w, h}
						end
					end
				UiPop()
				
				if j == 1 then
					UiTranslate(0, -150)
				else
					UiTranslate(0, -90)
				end
			end
		UiPop()

		-- end

		UiPush()
			if InvGrab.info[1][1] ~= "" then
				local invSlot = InvGrab.info[1]
				local item, w, h = invSlot[1], invSlot[3], invSlot[4]
				local rotation = invSlot._tempRotation or invSlot.rotation or 0 -- tempRotation for bug where item can be grab from inv, rotate, fail to place, and fail to put item back with it rotated

				local x, y = UiGetMousePos()
				UiTranslate(x-InvGrab.offset[1], y-InvGrab.offset[2])
				
				UiColor(0.7, 0.7, 0.7, 0.5)
				UiImageBox("ui/common/box-solid-6.png", 60*w, 60*h, 6, 6)
				UiColor(1, 1, 1)
				UiImageBox("ui/common/box-outline-6.png", 60*w, 60*h, 6, 6)
				UiPush()
					UiTranslate(w*30, h*30)
					UiAlign("center middle")
					UiRotate(rotation*-90)
					drawItem(item)
				UiPop()
				UiFont("bold.ttf", 25)
				if KeybindPressed(Settings.keybinds.inventory.rotate_item) then
					invSlot._tempRotation = (rotation + 1) % 4
					invSlot[3], invSlot[4] = h, w
					InvGrab.offset[1], InvGrab.offset[2] = 60*h - InvGrab.offset[2], InvGrab.offset[1]
				end
				if (not InputDown("usetool") or KeybindPressed(Settings.keybinds.inventory.toggle_inv))then
					clearItem(InvGrab.info[4], InvGrab.info)
					SetString("inventory.drop", invSlot[1])
					InvGrab.info = {{"", {0, 0}, 1, 1}, 0, 0}
				end
			end
		UiPop()
		if InputReleased("usetool") then
			rightclickinfo = {"", 0, 0, ""}
		end
	end

	if HoverDesc.invTable == nil then
		HoverDesc.timer = 0
	else
		if HoverDesc.cord[1] == 0 or HoverDesc.cord[2] == 0 then
			HoverDesc.timer = 0
		end
	end
	if HoverDesc.cord[1] ~= 0 and HoverDesc.timer > 0.3 and _invOn and HoverDesc.invTable ~= nil then
		displayInfo()
	end

	displayQueedPerkInfos()
end

function refreshShop()
	for section, shoptable in pairs(Market) do
		invMarket[section] = {}
		sectionheight = 0
		while sectionheight < 9 do
			newShopEntry = shoptable[math.random(1,#shoptable)]
			local item = newShopEntry["item"]
			local w,h = GetDimensions(item)
			table.insert(invMarket[section], newShopEntry)
			sectionheight = sectionheight + h
		end
	end
end

function getPrice(item)
	local itemInfos = Split(item, "_")
	local id = itemInfos[1]
	local idInfos = Split(id, "-")
	
	local price = 0
	if idInfos[1] == "gun" then
		price = 500
		if     idInfos[2] == "ak74m" then price = 320
		elseif idInfos[2] == "ak74" then price = 280
		elseif idInfos[2] == "ak101" then price = 700
		elseif idInfos[2] == "ak12" then price = 410
		elseif idInfos[2] == "ar15" then price = 350
		elseif idInfos[2] == "m16" then price = 270
		elseif idInfos[2] == "scarl" then price = 380
		elseif idInfos[2] == "scarlg" then price = 380
		elseif idInfos[2] == "mosin" then price = 110
		elseif idInfos[2] == "mosinm" then price = 230
		elseif idInfos[2] == "sks" then price = 130
		elseif idInfos[2] == "mp43" then price = 90
		elseif idInfos[2] == "m870" then price = 270
		elseif idInfos[2] == "ks23" then price = 530
		elseif idInfos[2] == "rpg" then
			local rocketprice = getPrice(itemInfos[3])
			return 330 + rocketprice , idInfos[2]
		elseif idInfos[2] == "ppsh41" then price = 120
		elseif idInfos[2] == "akm" then price = 290
		elseif idInfos[2] == "g17" then price = 320
		elseif idInfos[2] == "m9" then price = 470
		elseif idInfos[2] == "g18" then price = 370
		elseif idInfos[2] == "tt33" then price = 50
		elseif idInfos[2] == "sawedoff" then price = 60
		elseif idInfos[2] == "cz1012" then price = 90
		elseif idInfos[2] == "mp443" then price = 150
		elseif idInfos[2] == "mgl" then price = 850
		elseif idInfos[2] == "scarh" then price = 680
		elseif idInfos[2] == "scarhg" then price = 680
		elseif idInfos[2] == "vector" then price = 480
		elseif idInfos[2] == "svd" then price = 510
		elseif idInfos[2] == "g36k" then price = 460
		elseif idInfos[2] == "deagle" then price = 225
		elseif idInfos[2] == "sg553" then price = 370
		elseif idInfos[2] == "g3" then price = 330
		elseif idInfos[2] == "mp5" then price = 340
		elseif idInfos[2] == "pp19" then price = 350
		elseif idInfos[2] == "ak50" then price = 410
		elseif idInfos[2] == "m107" then price = 4500
		elseif idInfos[2] == "p90" then price = 490
		elseif idInfos[2] == "fiveseven" then price = 380
		elseif idInfos[2] == "sv98" then price = 550
		end
		local additionalPrice = 0
		if itemInfos[3]=="none" or itemInfos[4]=="Internal"then
			additionalPrice = getPrice(IDBuilder({"bullets-"..displayCaltoCalID(itemInfos[7]),itemInfos[7],itemInfos[5]})) -- yes, this is recursive
		else
			additionalPrice = getPrice(IDBuilder({itemInfos[3],itemInfos[4],itemInfos[5],itemInfos[6],itemInfos[7]})) -- yes, this is recursive
		end
		-- local _,dw,dh=attList(item)
		local amountsoldalready = economy[idInfos[2]] or 0
		local subtractpricer = 0.1 * amountsoldalready
		return (price + additionalPrice) * math.max((1 - subtractpricer),0.2), idInfos[2]
	elseif idInfos[1] == "bullets" then
		local amount = tonumber(itemInfos[3])
		price = 0.6
		if     idInfos[2] == "127x99" then price = 2
		elseif idInfos[2] == "127x33" then price = 1.5
		elseif idInfos[2] == "9x19" then price = 0.7
		elseif idInfos[2] == "12ga" then price = 0.7
		elseif idInfos[2] == "4ga" then price = 1.3
		elseif idInfos[2] == "545" then price = 1
		elseif idInfos[2] == "556" then price = 1.1
		elseif idInfos[2] == "57x28" then price = 1.2
		elseif idInfos[2] == "762x25" then price = 0.5
		elseif idInfos[2] == "762x39" then price = 0.7
		elseif idInfos[2] == "762x51" then price = 1.5
		elseif idInfos[2] == "762x54" then price = 1.7
		end
		return math.floor(price*amount),idInfos[2]
	elseif idInfos[1] == "melee" then
		if     idInfos[2] == "Pipe" then price = 10
		elseif idInfos[2] == "Katana" then price = 50
		elseif idInfos[2] == "Tomahawk" then price = 30
		elseif idInfos[2] == "Crowbar" then price = 10
		elseif idInfos[2] == "CombatKnife" then price = 15
		elseif idInfos[2] == "FireAxe" then price = 15
		elseif idInfos[2] == "BaseballBat" then price = 10
		end
		local amountsoldalready = economy[idInfos[2]] or 0
		local subtractpricer = 0.1 * amountsoldalready
		return price * math.max((1 - subtractpricer),0.2), idInfos[2]
	elseif idInfos[1] == "vest" then
		price = 200
		local durability = tonumber(itemInfos[3])/tonumber(itemInfos[4])
		if     idInfos[2] == "gzhel" then price = 350
		elseif idInfos[2] == "zabralo" then price = 450
		elseif idInfos[2] == "thor" then price = 400
		elseif idInfos[2] == "killa" then price = 250
		elseif idInfos[2] == "sixb2" then price = 60
		elseif idInfos[2] == "hexgrid" then price = 250
		elseif idInfos[2] == "lbtplate" then price = 350
		elseif idInfos[2] == "nfmthor" then price = 300
		end
		local amountsoldalready = economy[idInfos[2]] or 0
		local subtractpricer = 0.1 * amountsoldalready
		return (price*durability) * math.max((1 - subtractpricer),0.2), idInfos[2]
	elseif idInfos[1] == "helmet" then
		price = 100
		if     idInfos[2] == "ulach" then price = 100
		elseif idInfos[2] == "altyn" then price = 250
		elseif idInfos[2] == "killa" then price = 250
		end
		local amountsoldalready = economy[idInfos[2]] or 0
		local subtractpricer = 0.1 * amountsoldalready
		return price * math.max((1 - subtractpricer),0.2), idInfos[2]
	elseif idInfos[1] == "material" then
		local amount = tonumber(itemInfos[3])
		if     idInfos[2] == "rubber" then price = 40
		elseif idInfos[2] == "steel" then price = 110
		elseif idInfos[2] == "kevlar" then price = 180
		elseif idInfos[2] == "scrap" then price = 50
		elseif idInfos[2] == "driftwood" then price = 20
		elseif idInfos[2] == "explosive" then price = 270
		end
		local amountsoldalready = economy[idInfos[2]] or 0
		local subtractpricer = 0.1 * amountsoldalready
		return (price * amount) * math.max((1 - subtractpricer),0.2), idInfos[2]
	elseif idInfos[1] == "meds" then
		price = 15
		local durability = tonumber(itemInfos[3])/tonumber(itemInfos[4])
		local medtype = idInfos[#idInfos]
		if     medtype == "car" then price = 35
		elseif medtype == "ai2" then price = 40
		elseif medtype == "ifak" then price = 150
		elseif medtype == "grizzly" then price = 600
		elseif medtype == "cms" then price = 150
		elseif medtype == "surv12" then price = 500
		elseif medtype == "bandage" then price = 15
		elseif medtype == "splint" then price = 20
		elseif medtype == "morphine" then price = 250
		elseif medtype == "adrenaline" then price = 400
		elseif medtype == "pz1" then price = 600
		end
		local amountsoldalready = economy[idInfos[2]] or 0
		local subtractpricer = 0.1 * amountsoldalready
		return (price*durability) * math.max((1 - subtractpricer),0.2), idInfos[2]
		elseif string.sub(idInfos[1], 1, 3) == "mag" then
		price = 5
		if     id == "mag0-ak-545" then price = 10
		elseif id == "mag1-ak-545" then price = 15	
		elseif id == "mag0-ak-556" then price = 15	
		elseif id == "mag1-ak-556" then price = 30
		elseif id == "mag2-ak-545" then price = 50
		elseif id == "mag3-ak-545" then price = 90
		elseif id == "mag4-ak-545" then price = 60
		elseif id == "mag0-ak-9x19" then price = 25
		elseif id == "mag0-ak-762x39" then price = 25
		elseif id == "mag1-ak-762x39" then price = 35
		elseif id == "mag2-ak-762x39" then price = 50
		elseif id == "mag3-ak-762x39" then price = 60
		elseif id == "mag0-ar-556" then price = 10
		elseif id == "mag1-ar-556" then price = 15
		elseif id == "mag2-ar-556" then price = 30
		elseif id == "mag3-ar-556" then price = 90
		elseif id == "mag4-ar-556" then price = 10
		elseif id == "mag7-ar-556" then price = 10
		elseif id == "mag5-ar-556" then price = 50
		elseif id == "mag8-ar-556" then price = 50
		elseif id == "mag6-ar-556" then price = 10
		elseif id == "mag0-glock-9x19" then price = 10
		elseif id == "mag0-m9-9x19" then price = 20
		elseif id == "mag0-dgl-127x33" then price = 25
		elseif id == "mag1-glock-9x19" then price = 20
		elseif id == "mag2-glock-9x19" then price = 50
		elseif id == "mag0-tt33-762x25" then price = 5
		elseif id == "mag0-scar-762x51" then price = 30
		elseif id == "mag2-scar-762x51" then price = 80
		elseif id == "mag0-ppsh-762x25" then price = 10
		elseif id == "mag1-ppsh-762x25" then price = 35
		elseif id == "mag0-hk-556" then price = 30
		elseif id == "mag0-g3-762x51" then price = 20
		elseif id == "mag1-g3-762x51" then price = 35
		elseif id == "mag2-g3-762x51" then price = 60
		elseif id == "mag0-mp5-9x19" then price = 25
		elseif id == "mag1-mp5-9x19" then price = 35
		elseif id == "mag2-mp5-9x19" then price = 60
		elseif id == "mag0-m107-127x99" then price = 90
		elseif id == "mag0-p90-57x28" then price = 40
		end
		local amountsoldalready = economy[id] or 0
		local subtractpricer = 0.1 * amountsoldalready
		local bulletsprice = getPrice(IDBuilder({"bullets-"..idInfos[3],"",itemInfos[3]}))
		return (price+math.floor(bulletsprice)) * (1 - subtractpricer), id
	elseif idInfos[1] == "eyewear" then
		price = 400
		if id == "eyewear-nvg" then price = 5000*tonumber(itemInfos[3])/tonumber(itemInfos[4])
		elseif id == "eyewear-thermals" then price = 8700*tonumber(itemInfos[3])/tonumber(itemInfos[4])
		elseif id == "eyewear-pvs14" then price = 2300*tonumber(itemInfos[3])/tonumber(itemInfos[4])
		elseif id == "eyewear-pnv10t" then price = 12000*tonumber(itemInfos[3])/tonumber(itemInfos[4])
		end
		local amountsoldalready = economy[idInfos[2]] or 0
		local subtractpricer = 0.1 * amountsoldalready
		return (price) * math.max((1 - subtractpricer),0.2), idInfos[2]
	else
		if     id == "rocket0" then price = 250
		elseif id == "rocket1" then price = 200
		elseif id == "rocket2" then price = 350
		elseif id == "rocket3" then price = 280
		elseif id == "food1" then price = 10
		elseif id == "food2" then price = 2
		elseif id == "food3" then price = 15
		elseif id == "food4" then price = 7
		elseif id == "food5" then price = 4
		elseif id == "food6" then price = 35
		elseif id == "food7" then price = 7
		elseif id == "food8" then price = 10
		elseif id == "food9" then price = 9
		elseif id == "food10" then price = 12
		elseif id == "food11" then price = 7
		elseif id == "food12" then price = 10
		elseif id == "food13" then price = 4
		elseif id == "food14" then price = 7
		elseif id == "food15" then price = 8
		elseif id == "food16" then price = 7
		elseif id == "food17" then price = 3
		elseif id == "food18" then price = 2
		elseif id == "food19" then price = 6
		elseif id == "food20" then price = 11
		elseif id == "food21" then price = 11
		elseif id == "food22" then price = 11
		elseif id == "food23" then price = 7
		elseif id == "food24" then price = 11
		elseif id == "food25" then price = 11
		elseif id == "food26" then price = 11
		elseif id == "food27" then price = 11
		elseif id == "grenade" then price = 80
		elseif id == "grenade1" then price = 80
		elseif id == "general-nails" then price = 90
		elseif id == "general-carbattery" then price = 190
		elseif id == "general-battery" then price = 100
		elseif id == "general-book" then price = 150
		elseif id == "general-gpu" then price = 700
		elseif id == "general-plate" then price = 450
		elseif id == "general-lighter" then price = 50
		elseif id == "general-gasan" then price = 320
		elseif id == "general-snow" then price = 950


		
		end
		local amountsoldalready = economy[id] or 0
		local subtractpricer = 0.1 * amountsoldalready
		return (price) * (1 - subtractpricer), id
	end
	
	return price
end

function drawItem(item, itemW, itemH, imgScale, drawattachment)
	imgScale = imgScale or 1
	local w, h = GetDimensions(item)
	local itemW, itemH = itemW or w, itemH or h
	UiPush()
		UiWindow(itemW*60,itemH*60)
		UiAlign("left top")
		local itemInfos = Split(item, "_")
		local id = itemInfos[1]
		local idInfos = Split(id, "-")
		
		local unknownitem = false
		local text = "Unknown"

		if #itemInfos > 1 then
			local text1 = Split(itemInfos[2], "-")
			text = table.concat(text1, "  ")
		else
			unknownitem = true
		end

		UiPush()
			UiTranslate(UiCenter(), UiMiddle())
			UiScale(imgScale)
			UiAlign("center middle")
			if idInfos[1] == "gun" then
				drawGun(item)
			elseif idInfos[1] == "bullets" then
				drawBullet(item)
			elseif idInfos[1] == "attachment" and idInfos[2] ~= "holo" then
				local path = "MOD/img/icon/" ..idInfos[1].."-" ..idInfos[2]..".png"
				local w2,h2 = GetDimensions(item)
				if HasFile(path) then
					UiImageBox(path, 60*w2, 60*h2, 0, 0)
				else
					UiImageBox("MOD/img/icon/imgnotfound.png", 60*w2, 60*h2, 0, 0)
				end
			else
				local path = "MOD/img/icon/"..id..".png"
				local w2,h2 = GetDimensions(item)
				if HasFile(path) then
					UiImageBox(path, 60*w2, 60*h2, 0, 0)
				else
					UiImageBox("MOD/img/icon/imgnotfound.png", 60*w2, 60*h2, 0, 0)
				end
			end
		UiPop()
		if not drawattachment then
			UiFont("bold.ttf", 10)
			UiPush()
				UiTranslate(UiWidth() - 4)
				UiAlign("right top")
				UiText(text)
			UiPop()
			if unknownitem then return end
		end
		if string.sub(id, 1, 3) == "mag" and #itemInfos >= 4 then
			UiPush()
				UiTranslate(UiWidth() - 4, UiHeight())
				UiAlign("right bottom")
				local ammoCount, maxAmmo = tonumber(itemInfos[3]), tonumber(itemInfos[4])
				local r,g,b=ColorGradient((ammoCount/maxAmmo) or 0)
				UiColor(r,g,b,1*uiopacity)
				UiText(ammoCount.."/"..maxAmmo)
			UiPop()
			UiPush()
				local caliber = idInfos[3]
				UiTranslate(4, UiHeight())
				UiAlign("left bottom")
				UiText(calIDtoShortDisplayCal(caliber))
			UiPop()
		elseif idInfos[1] == "bullets" and #itemInfos >= 3 then
			--if itemW < 2 then 
				UiPush()
					local color = gunperks[idInfos[2]][idInfos[3]].bannercolors or {1,1,1}
					UiColor(color[1], color[2], color[3], 0.15)
					UiImageBox("ui/common/box-solid-6.png", UiWidth(), 15, 6, 6)
				UiPop()
			--end
			UiPush()
				UiTranslate(4,0)
				UiAlign("left top")
				UiText(idInfos[3])
			UiPop()
			UiPush()
				UiTranslate(UiWidth()- 4, UiHeight())
				UiAlign("right bottom")
				UiText(itemInfos[3])
			UiPop()
		elseif (idInfos[1] == "helmet" or idInfos[1] == "vest" or idInfos[1] == "eyewear") and #itemInfos >= 4 then
			UiPush()
				UiTranslate(UiWidth() - 4, UiHeight())
				UiAlign("right bottom")
				local durability, maxDurability = tonumber(itemInfos[3]), tonumber(itemInfos[4])
				local r,g,b=ColorGradient((durability/maxDurability) or 0)
				UiColor(r,g,b,1*uiopacity)
				UiText(math.floor(durability).."/"..maxDurability)
			UiPop()
		elseif idInfos[1] == "meds" and #itemInfos >= 4 then
			UiPush()
				UiTranslate(UiWidth() - 4, UiHeight())
				UiAlign("right bottom")
				local durability, maxDurability = tonumber(itemInfos[3]), tonumber(itemInfos[4])
				local r,g,b=ColorGradient((durability/maxDurability) or 0)
				UiColor(r,g,b,1*uiopacity)
				UiText(math.floor(durability).."/"..maxDurability)
			UiPop()
		elseif idInfos[1] == "material" then
			UiPush()
				UiTranslate(UiWidth() - 4, UiHeight())
				UiAlign("right bottom")
				UiText(itemInfos[3])
			UiPop()
		elseif idInfos[1] == "gun" and #itemInfos >= 7 and not drawattachment then
			UiPush()
				UiTranslate(UiWidth() - 4, UiHeight())
				UiAlign("right bottom")
				local ammoCount, maxAmmo = tonumber(itemInfos[5]), tonumber(itemInfos[6])
				local r,g,b=ColorGradient((ammoCount/maxAmmo) or 0)
				UiColor(r,g,b,1*uiopacity)
				UiText(ammoCount.."/"..maxAmmo)
			UiPop()
			
			UiPush()
				UiTranslate(4, UiHeight())
				UiAlign("left bottom")
				UiText(itemInfos[4].." - "..itemInfos[7])
			UiPop()

			if #itemInfos >= 8 and not drawattachment then
				UiPush()
					UiTranslate(5, 5)
					local attachmentInfos = Split(itemInfos[8], "-")
					for k = 1, #attachmentInfos do
						if attachmentInfos[k] ~= "" then
							UiImageBox("MOD/img/icon/"..attachmentInfos[k]..".png", 20, 20)
							UiTranslate(20, 0)
						end
					end
				UiPop()
			end
		elseif idInfos[1] == "melee" and #itemInfos >= 2 then
			UiPush()
				UiTranslate(56*itemW, 60*itemH)
				UiAlign("right bottom")
				local durability, maxDurability = tonumber(itemInfos[3]), tonumber(itemInfos[4])
				local r,g,b=ColorGradient((durability/maxDurability) or 0)
				UiColor(r,g,b,1*uiopacity)
				UiText(math.floor(durability).."/"..maxDurability)
			UiPop()
		end
	UiPop()
end

function drawBullet(item)
	local bulletinfo = Split(item, "_")
	local w,h = GetDimensions(item)
	local id = bulletinfo[1]
	local calId = Split(id, "-")[2]
	local path = "MOD/img/icon/"..id..".png"
	if calId == "9x19" then
		Cpkl = Split(id, "-")[3] or "FMJ"

		path = "MOD/img/icon/Ammo/bullets-9x19_"..Cpkl..".png"
	elseif calId == "12ga" then
		Cpkl = Split(id, "-")[3] or "FMJ"

		path = "MOD/img/icon/Ammo/bullets-12ga_".. Cpkl ..".png"
	elseif calId == "4ga" then
		Cpkl = Split(id, "-")[3] or "FMJ"

		path = "MOD/img/icon/Ammo/bullets-4ga_"..Cpkl..".png"
	elseif calId == "127x99" then
		Cpkl = Split(id, "-")[3] or "FMJ"
		
		path = "MOD/img/icon/Ammo/bullets-127x99_"..Cpkl..".png"
	elseif calId == "127x33" then
		Cpkl = Split(id, "-")[3] or "FMJ"
		
		path = "MOD/img/icon/Ammo/bullets-127x33_"..Cpkl..".png"

	elseif calId == "545" then
		Cpkl = Split(id, "-")[3] or "FMJ"

		path = "MOD/img/icon/Ammo/bullets-545_"..Cpkl..".png"
	elseif calId == "556" then
		Cpkl = Split(id, "-")[3] or "FMJ"

		path = "MOD/img/icon/Ammo/bullets-556_".. Cpkl ..".png"
	elseif calId == "762x25" then
		Cpkl = Split(id, "-")[3] or "FMJ"

		path = "MOD/img/icon/Ammo/bullets-762x25_"..Cpkl..".png"
	elseif calId == "762x39" then
		Cpkl = Split(id, "-")[3] or "FMJ"

		path = "MOD/img/icon/Ammo/bullets-762x39_"..Cpkl..".png"
	elseif calId == "762x51" then
		Cpkl = Split(id, "-")[3] or "FMJ"

		path = "MOD/img/icon/Ammo/bullets-762x51_"..Cpkl..".png"
	elseif calId == "762x54" then
		Cpkl = Split(id, "-")[3] or "FMJ"

		path = "MOD/img/icon/Ammo/bullets-762x54_"..Cpkl..".png"
	elseif calId == "57x28" then
		Cpkl = Split(id, "-")[3] or "HP"
		path = "MOD/img/icon/Ammo/bullets-57x28_"..Cpkl..".png"
	end

	if HasFile(path) then
		UiImageBox(path, 60*w, 60*h, 0, 0)
	else
		UiImageBox("MOD/img/icon/"..id..".png", 60*w, 60*h, 0, 0)
	end
end

function drawGun(item)
	UiPush()
		--UiRect(100,1)
		--UiRect(1,100)
		local guninfo = Split(item, "_")
		local id = guninfo[1]
		local w, h = GetDimensions(item)
		local attlist, dw, dh, brl, dx = attList(item)
		local w2,h2=w,h
		if attlist == nil then
			UiImageBox("MOD/img/icon/"..id..".png", 60*w, 60*h, 0, 0)
		else
			UiTranslate(dx, dy)
			w2,h2=UiGetImageSize("MOD/img/icon/"..id..".png")
			w2,h2=w2/30,h2/30
			UiImageBox("MOD/img/icon/"..id.."-att.png", 60*w2, 60*h2, 0, 0)
			
			for slot,attachment in pairs(attlist) do
				UiPush()
					local path="MOD/img/icon/"..id.."/attachment_"..slot.."_"..attachment..".png"
					if slot == "muzzle" then UiTranslate(brl, 0) end
					if HasFile(path) then
						UiImageBox(path, 60*w2, 60*h2, 0, 0)
					end
				UiPop()
			end
		end
		local path="MOD/img/icon/"..id.."/mag_"..guninfo[3]..".png"
		if HasFile(path) then
			if id == "gun-rpg" then
				if guninfo[5] == "1" then UiImageBox(path, 60*w2, 60*h2, 0, 0) end
			else
				UiImageBox(path, 60*w2, 60*h2, 0, 0)
			end
		end
	UiPop()
end

function attList(item)
	local attlist=nil
	local dw,dh=0,0
	local brl=0
	local dx = 0
	local guninfo = Split(item, "_")
	local id = guninfo[1]
	if Split(id,"-")[1] == "gun" and #guninfo >= 8 then
		attachmentinfo = Split(guninfo[8], "-")

		if id == "gun-ak74" then

			local modernguard=attachmentinfo[9]
			if attachmentinfo[9] == "modernguard" and attachmentinfo[6] == "barrel1" then modernguard = "modernguard2"end

			attlist = {
				toprail = attachmentinfo[1],
				toprail2 = attachmentinfo[2],
				muzzle = attachmentinfo[3],
				stock = attachmentinfo[4],
				grip = attachmentinfo[5],
				barrel = attachmentinfo[6],
				side = attachmentinfo[7],
				guard = attachmentinfo[8],
				modernguard = modernguard,
				dustcover = attachmentinfo[10],
				camo = attachmentinfo[11],
			}
			
			if attachmentinfo[6] == "barrel1" then dw=dw-1 brl=46 elseif attachmentinfo[6] == "barrel2" then dw=dw+1 brl=-21 end
			if attachmentinfo[4] == "removed" then dw=dw-1 dx=11 end
			
		elseif id == "gun-ak74m" then

			attlist = {
				toprail = attachmentinfo[1],
				muzzle = attachmentinfo[2],
				stock = attachmentinfo[3],
				grip = attachmentinfo[4],
				barrel = attachmentinfo[5],
				side = attachmentinfo[6],
				guard = attachmentinfo[7],
				dustcover = attachmentinfo[8],
			}

			if attachmentinfo[5] == "barrel1" then dw=dw-1 elseif attachmentinfo[5] == "barrel2" then dw=dw+1 end
			if attachmentinfo[3] == "removed" then dw=dw-1 end
		
		elseif id == "gun-ak101" then

			local modernguard=attachmentinfo[9]
			if attachmentinfo[9] == "modernguard" and attachmentinfo[6] == "barrel1" then modernguard = "modernguard2"end

			attlist = {
				toprail = attachmentinfo[1],
				toprail2 = attachmentinfo[2],
				muzzle = attachmentinfo[3],
				stock = attachmentinfo[4],
				grip = attachmentinfo[5],
				barrel = attachmentinfo[6],
				side = attachmentinfo[7],
				guard = attachmentinfo[8],
				modernguard = modernguard,
				dustcover = attachmentinfo[10],
				camo = attachmentinfo[11],
			}
			
			if attachmentinfo[6] == "barrel1" then dw=dw-1 brl=46 elseif attachmentinfo[6] == "barrel2" then dw=dw+1 brl=-21 end
			if attachmentinfo[4] == "removed" then dw=dw-1 end
			

		elseif id == "gun-akm" then

			attlist = {
				toprail = attachmentinfo[1],
				toprail2 = attachmentinfo[2],
				muzzle = attachmentinfo[3],
				stock = attachmentinfo[4],
				grip = attachmentinfo[5],
				barrel = attachmentinfo[6],
				side = attachmentinfo[7],
				guard = attachmentinfo[8],
				modernguard = attachmentinfo[9],
				dustcover = attachmentinfo[10],
				camo = attachmentinfo[11],
			}
			
			if attachmentinfo[6] == "barrel1" then dw=dw-1 elseif attachmentinfo[6] == "barrel2" then dw=dw+1 end
			if attachmentinfo[4] == "removed" then dw=dw-1 end

		elseif id == "gun-ak12" then

			if attachmentinfo[5] == "barrel1" then dw=dw-1 elseif attachmentinfo[5] == "barrel2" then dw=dw+1 end
			if attachmentinfo[3] == "removed" then dw=dw-1 end

		elseif id == "gun-ar15" then

			attlist = {
				toprail = attachmentinfo[1],
				canted = attachmentinfo[2],
				muzzle = attachmentinfo[3],
				stock = attachmentinfo[4],
				grip = attachmentinfo[5],
				barrel = attachmentinfo[6],
				side = attachmentinfo[7],
				guard = attachmentinfo[8],
				magnifier = attachmentinfo[9],
				camo = attachmentinfo[10],
			}

			if attachmentinfo[5] == "barrel1" then dw=dw-1 brl=-16 elseif attachmentinfo[5] == "barrel2" then dw=dw+1 brl=16 end

		elseif id == "gun-m16" then

			if attachmentinfo[5] == "barrel1" then dw=dw-1 elseif attachmentinfo[5] == "barrel2" then dw=dw+1 end

		elseif id == "gun-scarl" then

			attlist = {
				toprail = attachmentinfo[1],
				muzzle = attachmentinfo[2],
				stock = attachmentinfo[3],
				grip = attachmentinfo[4],
				barrel = attachmentinfo[5],
				side = attachmentinfo[6],
				guard = attachmentinfo[7],
				magnifier = attachmentinfo[8],
			}

			if attachmentinfo[5] == "barrel1" then dw=dw-1 brl=30 elseif attachmentinfo[5] == "barrel2" then dw=dw+1 brl=-15 end
	
		elseif id == "gun-scarlg" then

			attlist = {
				toprail = attachmentinfo[1],
				muzzle = attachmentinfo[2],
				stock = attachmentinfo[3],
				grip = attachmentinfo[4],
				barrel = attachmentinfo[5],
				side = attachmentinfo[6],
				guard = attachmentinfo[7],
				magnifier = attachmentinfo[8],
			}

			if attachmentinfo[5] == "barrel1" then dw=dw-1 brl=30 elseif attachmentinfo[5] == "barrel2" then dw=dw+1 brl=-15 end

		elseif id == "gun-scarh" then

			attlist = {
				toprail = attachmentinfo[1],
				muzzle = attachmentinfo[2],
				stock = attachmentinfo[3],
				grip = attachmentinfo[4],
				barrel = attachmentinfo[5],
				side = attachmentinfo[6],
				guard = attachmentinfo[7],
				magnifier = attachmentinfo[8],
			}

			if attachmentinfo[5] == "barrel1" then dw=dw-1 brl=30 elseif attachmentinfo[5] == "barrel2" then dw=dw+1 brl=-15 end

		elseif id == "gun-scarhg" then

			attlist = {
				toprail = attachmentinfo[1],
				muzzle = attachmentinfo[2],
				stock = attachmentinfo[3],
				grip = attachmentinfo[4],
				barrel = attachmentinfo[5],
				side = attachmentinfo[6],
				guard = attachmentinfo[7],
				magnifier = attachmentinfo[8],
			}

			if attachmentinfo[5] == "barrel1" then dw=dw-1 brl=30 elseif attachmentinfo[5] == "barrel2" then dw=dw+1 brl=-15 end

		elseif id == "gun-mosin" then
		elseif id == "gun-mosinm" then
		elseif id == "gun-sks" then
		elseif id == "gun-mp43" then
		elseif id == "gun-m870" then
		elseif id == "gun-ks23" then
		
			attlist = {
				toprail = attachmentinfo[1],
				muzzle = attachmentinfo[2],
				stock = attachmentinfo[3],
				grip = attachmentinfo[4],
				side = attachmentinfo[5],
				handle = attachmentinfo[6],
			}
			
			if attachmentinfo[3] == "removed" then dw=dw-1 dx=25 end
		elseif id == "gun-rpg" then
		elseif id == "gun-ppsh41" then
		
		elseif id == "gun-g17" then
		
			attlist = {
				toprail = attachmentinfo[1],
				muzzle = attachmentinfo[2],
				stock = attachmentinfo[3],
				side = attachmentinfo[4],
				camo = attachmentinfo[5],	
			}
			
		elseif id == "gun-deagle" then
		elseif id == "gun-g18" then
		
			attlist = {
				toprail = attachmentinfo[1],
				muzzle = attachmentinfo[2],
				stock = attachmentinfo[3],
				side = attachmentinfo[4],
				camo = attachmentinfo[5],	
			}
			
		elseif id == "gun-tt33" then
			
			attlist = {
				toprail = attachmentinfo[1],
				muzzle = attachmentinfo[2],
				stock = attachmentinfo[3],
				side = attachmentinfo[4],
				camo = attachmentinfo[5],	
			}
			
		elseif id == "gun-sawedoff" then
		elseif id == "gun-cz1012" then
		elseif id == "gun-mp443" then
		elseif id == "gun-mgl" then
		elseif id == "gun-vector" then

			attlist = {
				toprail = attachmentinfo[1],
				muzzle = attachmentinfo[2],
				stock = attachmentinfo[3],
				grip = attachmentinfo[4],
				barrel = attachmentinfo[5],
				side = attachmentinfo[6],
				guard = attachmentinfo[7],
			}

			brl=-20
			if attachmentinfo[5] == "barrel1" then dw=dw-1 brl=-18 dx=-10 elseif attachmentinfo[5] == "barrel2" then dw=dw+1 brl=-30 end
			if attachmentinfo[3] == "removed" then dw=dw-1 end
			if attachmentinfo[2] == "muzzle1" then dw=dw+1 end

		elseif id == "gun-svd" then

			attlist = {
				toprail = attachmentinfo[1],
				toprail2 = attachmentinfo[2],
				muzzle = attachmentinfo[3],
				stock = attachmentinfo[4],
				grip = attachmentinfo[5],
				barrel = attachmentinfo[6],
				side = attachmentinfo[7],
				guard = attachmentinfo[8],
				modernguard = attachmentinfo[9],
				dustcover = attachmentinfo[10],
			}
			
			if attachmentinfo[6] == "barrel1" then dw=dw-2 end
			if attachmentinfo[4] == "removed" then dw=dw-2 dx=-10 end

		elseif id == "gun-g36k" then

			attlist = {
				toprail = attachmentinfo[1],
				muzzle = attachmentinfo[2],
				stock = attachmentinfo[3],
				grip = attachmentinfo[4],
				barrel = attachmentinfo[5],
				side = attachmentinfo[6],
				guard = attachmentinfo[7],
				magnifier = attachmentinfo[8],
			}

		if attachmentinfo[5] == "barrel1" then dw=dw-1 brl=25 elseif attachmentinfo[5] == "barrel2" then dw=dw+1 end

		elseif id == "gun-sg553" then
		elseif id == "gun-g3" then

			attlist = {
				toprail = attachmentinfo[1],
				muzzle = attachmentinfo[2],
				stock = attachmentinfo[3],
				grip = attachmentinfo[4],
				barrel = attachmentinfo[5],
				side = attachmentinfo[6],
				guard = attachmentinfo[7],
			}

		if attachmentinfo[5] == "barrel1" then dw=dw-2 brl=25 end
		
		elseif id == "gun-mp5" then
		elseif id == "gun-ak50" then
		elseif id == "gun-p90" then

			attlist = {
				toprail = attachmentinfo[1],
				muzzle = attachmentinfo[2],
				stock = attachmentinfo[3],
				grip = attachmentinfo[4],
				barrel = attachmentinfo[5],
				side = attachmentinfo[6],
				guard = attachmentinfo[7],
				magnifier = attachmentinfo[8],
			}

			-- if attachmentinfo[2] == "muzzle1" then dw=dw+1 end
		end
	end
	return attlist, dw, dh, brl, dx
end

function calIDtoDisplayCal(calID)
	if calID == "12ga" then return "12ga"
	elseif calID == "4ga" then return "4ga"
	elseif calID == "9x19" then return "9x19"
	elseif calID == "57x28" then return "5.7x28"
	elseif calID == "545" then return "5.45"
	elseif calID == "556" then return "5.56"
	elseif calID == "762x25" then return "7.62x25"
	elseif calID == "762x39" then return "7.62x39"
	elseif calID == "762x51" then return "7.62x51"
	elseif calID == "762x54" then return "7.62x54R"
	elseif calID == "127x99" then return ".50BMG"
	elseif calID == "127x33" then return ".50AE"
	end
	return calID
end
function calIDtoShortDisplayCal(calID)
	if calID == "12ga" then return "12ga"
	elseif calID == "4ga" then return "4ga"
	elseif calID == "9x19" then return "9x19"
	elseif calID == "57x28" then return "5.7x28"
	elseif calID == "545" then return "5.45"
	elseif calID == "556" then return "5.56"
	elseif calID == "762x25" then return "7.62"
	elseif calID == "762x39" then return "7.62"
	elseif calID == "762x51" then return "7.62"
	elseif calID == "762x54" then return "7.62"
	elseif calID == "127x99" then return ".50BMG"
	elseif calID == "127x33" then return ".50AE"
	end
	return calID
end
function displayCaltoCalID(displayCal)
	if displayCal == "12ga" then return "12ga"
	elseif displayCal == "4ga" then return "4ga"
	elseif displayCal == "9x19" then return "9x19"
	elseif displayCal == "5.7x28" then return "57x28"
	elseif displayCal == "5.45" then return "545"
	elseif displayCal == "5.56" then return "556"
	elseif displayCal == "7.62x25" then return "762x25"
	elseif displayCal == "7.62x39" then return "762x39"
	elseif displayCal == "7.62x51" then return "762x51"
	elseif displayCal == "7.62x54R" then return "762x54"
	elseif displayCal == ".50BMG" then return "127x99"
	elseif displayCal == ".50AE" then return "127x33"
	end
	return displayCal
end

function getItemType(id)
	if id:sub(1, 3) == "gun" then
		return "gun"
	elseif id:sub(1, 3) == "mag" then
		return "mag"
	elseif id:sub(1, 4) == "food" then
		return "food"
	elseif id:sub(1, 4) == "meds" then
		return "meds"
	elseif id:sub(1, 4) == "vest" then
		return "vest"
	elseif id:sub(1, 5) == "melee" then
		return "melee"
	elseif id:sub(1, 6) == "helmet" then
		return "helmet"
	elseif id:sub(1, 6) == "rocket" then
		return "ammo"
	elseif id:sub(1, 7) == "general" then
		return "general"
	elseif id:sub(1, 10) == "attachment" then
		return "attachment"
	elseif id:sub(1, 7) == "bullets" then
		return "ammo"
	elseif id:sub(1, 7) == "eyewear" then
		return "eyewear"
	elseif id:sub(1, 8) == "material" then
		return "material"
	end
	return "other"
end

function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else
        copy = orig
    end
    return copy
end

function spawnItem(item,t)
	t=t or GetPlayerTransform() -- defaults to player transform if no specific transform is given, 
	local itemInfos = Split(item, "_")
	local id = itemInfos[1]
	local idInfos = Split(id, "-")
	local displayName = itemInfos[2]
	local spawnXML = "MOD/Loots/"..id..".xml"
	local customXML = false
	if idInfos[1] == "gun" then
		customXML, spawnXML = gunXMLBuilder(item)
	end
	if HasFile(spawnXML) or customXML then
		local entities = Spawn(spawnXML, t)
		SetTag(entities[1], "Loot", item)
		SetTag(entities[1], "interact", displayName)
		return entities
	else
		DebugPrint(id .. " does not exist in: " .. spawnXML)
		DebugPrint("please screenshot this error message and report this in MORS LONGA discord #bugs channel.")
		print(id .. " does not exist in: " .. spawnXML)
		print("please screenshot this error message and report this in MORS LONGA discord #bugs channel.")
		local entities = Spawn("MOD/Loots/unknownitem.xml", t)
		SetTag(entities[1], "Loot", item)
		SetTag(entities[1], "interact", displayName)
		return entities
	end
end
function IDBuilder(t)
	return table.concat(t, "_")
end

function displayInfo()
	local item = HoverDesc.invTable[HoverDesc.cord[1]][HoverDesc.cord[2]][1]
	if item == "" then return end
	UiPush()
		local itemInfos = Split(item, "_")

		local itemID = itemInfos[1]
		if Split(itemID, "-")[1] == "bullets" then
			itemID = ""..Split(itemID, "-")[1].."-"..Split(itemID, "-")[2]..""
		end
		--DebugPrint(itemID)
		local itemDisplayName = itemInfos[2]

		-- if you are greated with a "attempt to index field '?' (a nil value)" it is likely that theres a missing itemType entry in the inv-desc or getItemType function
		local itemType = getItemType(itemID)
		local descriptions = deepcopy(DESCRIPTION[itemType][itemID] or DESCRIPTION[itemType]["default_DESC"] or {"UNKNOWNITEMID"})

		-- local mx, my = UiGetMousePos()
		-- UiTranslate(mx, my)
		UiTranslate(1200, -270)
		UiFont("regular.ttf", 20)
		UiWordWrap(500)
		UiAlign("top left")

		local maxwidth = 0
		local totHeight = 40
		UiPush()
			UiFont("bold.ttf", 30)
			maxwidth = UiGetTextSize(itemDisplayName)
			maxwidth = maxwidth * 1.1
		UiPop()
		for i = 1, #descriptions do
			description=descriptions[i]

			if description=="UNKNOWNITEMID"then
				descriptions[i] = "Unknown item: "..itemID

			elseif description=="MATERIALSTACK"then
				local materialStack = itemInfos[3]
				local materialMaxStack = itemInfos[4] or 4
				descriptions[i] = "Stack: "..materialStack.."/"..materialMaxStack

			elseif description=="DURRABILITY"then
				local curDurability = itemInfos[3] or 0
				local maxDurability = itemInfos[4] or 0
				descriptions[i] = string.format("Durability: %.2f/%d",curDurability, maxDurability)

			elseif description=="FOODHUNGERTHIRST"then
				local foodHunger = itemInfos[3] or 0
				local foodThirst = itemInfos[4] or 0
				descriptions[i] = "Hunger/Thirst: "..foodHunger.." / "..foodThirst
			elseif description=="FOODHUNGER"then
				local foodHunger = itemInfos[3] or 0
				descriptions[i] = "Hunger: "..foodHunger
			elseif description=="FOODTHIRST"then
				local foodThirst = itemInfos[4] or 0
				descriptions[i] = "Thirst: "..foodThirst

			elseif description=="AMMOCOUNT"then
				local magCount=tonumber(itemInfos[3]) or 1
				local magMax=tonumber(itemInfos[4])
				if magMax~=nil then
					descriptions[i] = "Ammo: "..magCount.."/"..magMax
				else
					descriptions[i] = "Ammo: "..magCount
				end

			elseif description=="GUNFEED"then
				local magID=itemInfos[3]
				local magDisplayName=itemInfos[4]
				local magCount=tonumber(itemInfos[5])
				local magMax=tonumber(itemInfos[6])
				local magCalibre=itemInfos[7]
				descriptions[i] = "Current feed: "..magCalibre.." "..magDisplayName.." "..magCount.."/"..magMax
			end

			local w, h = UiGetTextSize(descriptions[i])
			totHeight = totHeight + h + 5
			maxwidth = math.max(maxwidth,w)
		end
		totHeight = totHeight - 5

		local displayPercentage = math.min(HoverDesc.timer-.3,.1)/.1
		UiScale(1,displayPercentage)
		UiColorFilter(1,1,1,displayPercentage*uiopacity)

		UiColor(0,0,0,.7)
		if _invState~="" then
			UiColor(0,0,0,1)
		end
		UiImageBox("ui/common/box-solid-6.png", maxwidth+12, totHeight + (#descriptions-1)*1 + 12, 6, 6)
		UiColor(1,1,1)
		UiTranslate(6, 6)

		UiPush()
			UiScale(1.1,1)
			UiFont("bold.ttf", 30)
			UiText(itemDisplayName)
		UiPop()
		UiTranslate(0, 40)

		for i = 1, #descriptions do
			local w,h=UiText(descriptions[i])
			UiTranslate(0, h+5)
		end
	UiPop()
end
perkPickupQue={
	--[[ {perkName, perkLevel, timer

	} ]]
}
function perkUpgrade(perkID)
	local perkLevel = GetInt("savegame.mod.perks."..perkID.."")
	perkPickupQue[#perkPickupQue+1]={
		perkID = perkID,
		perkLevel = perkLevel,
		timer = 0,
	}
	if perkLevel < (PERKTABLE[perkID].perkMaxLevel or 10) then
		SetInt("savegame.mod.perks."..perkID.."", perkLevel+1)
	else
		SetInt("savegame.mod.player.money", GetInt("savegame.mod.player.money") + 500)
	end
	
end
function displayQueedPerkInfos()
	if #perkPickupQue==0 then return end
	UiPush()
		local perkQueRemoveQue = {}
		UiTranslate(UiCenter(),UiMiddle())
		UiPush()
			UiTranslate(0,-25 - 12.5)
			local minTimer = 5
			local totY = 0
			for i=1,#perkPickupQue do
				local perkMsgInfos = perkPickupQue[i]
				local dY = NumberLerp(50, 0, SmoothTransition(math.max(perkMsgInfos.timer-4, 0)))
				totY = totY + dY
				minTimer = math.min(minTimer, perkMsgInfos.timer)
			end
			local alpha = SmoothTransition(math.min(5 - minTimer, 1))
			UiColor(0,0,0,alpha)
			UiAlign("right top")
			UiImageBox("ui/common/hgradient-right-64.png", UiCenter(), totY+25)
			UiAlign("left top")
			UiImageBox("ui/common/hgradient-left-64.png", UiCenter(), totY+25)
		UiPop()
		UiTranslate(0,-20)
		UiAlign("center top")
		UiFont("bold.ttf", 50)
		for i=1,#perkPickupQue do
			local perkMsgInfos = perkPickupQue[i]
			if perkMsgInfos.timer<5 then
				UiColor(1,0.5,0,1-(perkMsgInfos.timer/5))
				local perkNotification
				if perkMsgInfos.perkLevel < (PERKTABLE[perkMsgInfos.perkID].perkMaxLevel or 10) then
					local strHead = PERKTABLE[perkMsgInfos.perkID].perkNotificationStart or perkMsgInfos.perkID .. " level: "
					local strEnd = PERKTABLE[perkMsgInfos.perkID].perkNotificationEnd or ""
					local strMiddle = (PERKTABLE[perkMsgInfos.perkID].perkLevelNames or {[perkMsgInfos.perkLevel+1] = perkMsgInfos.perkLevel+1})[perkMsgInfos.perkLevel+1]
					perkNotification = strHead .. strMiddle .. strEnd
				else
					perkNotification = PERKTABLE[perkMsgInfos.perkID].perkMaxNotification or "Perk have reached max level, money refunded."
				end
				UiPush()
					UiScale(1,SmoothTransition(math.min(5 - perkMsgInfos.timer, 1)))
					UiText(perkNotification)
				UiPop()
				UiTranslate(0,NumberLerp(50, 0, SmoothTransition(math.max(perkMsgInfos.timer-4, 0))))

				perkMsgInfos.timer = perkMsgInfos.timer + GetTimeStep()
			else
				perkQueRemoveQue[#perkQueRemoveQue+1]=i
			end
			
		end
		for i=1,#perkQueRemoveQue do
			table.remove(perkPickupQue,perkQueRemoveQue[i])
		end
	UiPop()
end

function CountAmmo()
	local allCountedItems = {
		"bullets-12ga",
		"bullets-4ga",
		"bullets-762x39",
		"bullets-762x54",
	}

	local amount762x54 = 0
	local table762x54 = {}
	local amount762x39 = 0
	local table762x39 = {}
	local amount12ga = 0
	local table12ga = {}
	local amount4ga = 0
	local table4ga = {}
	local amountrocket = 0
	local amountgrenade = 0
	local amountgrenade1 = 0
	local amountrubber, amountsteel, amountkevlar, amountscrap, amountdriftwood, amountexplosive = 0,0,0,0,0,0
	for i = 1, #backpack do
		for j = 1, #backpack[i] do
			local item = backpack[i][j][1]
			local itemInfos = Split(item, "_")
			local idInfos = Split(itemInfos[1], "-")
			if idInfos[2] == "762x54" then
				local ammo = tonumber(itemInfos[3])
				table.insert(table762x54, idInfos[3])
				amount762x54 = amount762x54 + ammo
			elseif idInfos[2] == "762x39" then
				local ammo = tonumber(itemInfos[3])
				table.insert(table762x39, idInfos[3])
				amount762x39 = amount762x39 + ammo
			elseif idInfos[2] == "12ga" then
				local ammo = tonumber(itemInfos[3])
				table.insert(table12ga, idInfos[3])
				amount12ga = amount12ga + ammo
			elseif idInfos[2] == "4ga" then
				local ammo = tonumber(itemInfos[3])
				table.insert(table4ga, idInfos[3])
				amount4ga = amount4ga + ammo
			elseif string.sub(itemInfos[1],1,6) == "rocket" then
				amountrocket = amountrocket + 1
			elseif itemInfos[1] == "grenade" then
				amountgrenade = amountgrenade + 1
			elseif itemInfos[1] == "grenade1" then
				amountgrenade1 = amountgrenade1 + 1
			elseif idInfos[1] == "material" then
				local itemType = idInfos[2]
				local amount = tonumber(itemInfos[3])
				if itemType == "rubber" then
					amountrubber = amountrubber + amount
				elseif itemType == "steel" then
					amountsteel = amountsteel + amount
				elseif itemType == "kevlar" then
					amountkevlar = amountkevlar + amount
				elseif itemType == "scrap" then
					amountscrap = amountscrap + amount
				elseif itemType == "driftwood" then
					amountdriftwood = amountdriftwood + amount
				elseif itemType == "explosive" then
					amountexplosive = amountexplosive + amount
				end
			end
		end
	end
	SetInt("inventory.ammocount_762x54", amount762x54)
	SetString("inventory.ammocount.table_762x54", table.concat(table762x54,"-"))
	SetInt("inventory.ammocount_762x39", amount762x39)
	SetString("inventory.ammocount.table_762x39", table.concat(table762x39,"-"))
	SetInt("inventory.ammocount_12ga", amount12ga)
	SetString("inventory.ammocount.table_12ga", table.concat(table12ga,"-"))
	SetInt("inventory.ammocount_4ga", amount4ga)
	SetString("inventory.ammocount.table_4ga", table.concat(table4ga,"-"))
	SetInt("inventory.ammocount_rocket", amountrocket)
	SetInt("inventory.ammocount_grenade", amountgrenade)
	SetInt("inventory.ammocount_grenade1", amountgrenade1)
	SetInt("inventory.count_rubber", amountrubber)
	SetInt("inventory.count_steel", amountsteel)
	SetInt("inventory.count_kevlar", amountkevlar)
	SetInt("inventory.count_scrap", amountscrap)
	SetInt("inventory.count_driftwood", amountdriftwood)
	SetInt("inventory.count_explosive", amountexplosive)
end

function UiProgressBar(val, max, w, h, r,g,b,critical)
	UiPush()
		local w = w or 300
		local h = h or 30
		local pad = 6
		local borderWidth = 6
		local borderHeight = 6
		local r = r or 1
		local g = g or 1
		local b = b or 1
		local critical = critical or 1

		local t = val/max
		UiAlign("left top")
		UiColor(0, 0, 0, 0.5)
		UiImageBox("ui/common/box-solid-10.png", w, h, borderWidth, borderHeight)
		if t > 0 then
			UiTranslate(pad/2, pad/2)
			w = (w-pad)*t
			if w<12 then borderWidth=w/2 end
			h = h-pad
			local critPercent = math.min(t/critical,1)
			UiColor(r,g*critPercent,b*critPercent,1)
			UiImageBox("ui/common/box-solid-6.png", w, h, borderWidth, borderHeight)
		end
	UiPop()
end

function UiProgressBarTitled(title, val, max, w, h, r, g, b, critical)
    UiPush()

        local pad = 6
        local borderWidth = 6
        local borderHeight = 6
        local r = r or 1
        local g = g or 1
        local b = b or 1
        local critical = critical or 1

        UiPush()
            local t = val / max
            UiAlign("left top")
            UiColor(0, 0, 0, 0.75)
            -- UiImageBox("ui/common/box-solid-10.png", w, h, borderWidth, borderHeight)
            UiRect(w,h)
            if t > 0 then
                UiTranslate(pad / 2, pad / 2)
                local w = (w - pad) * t
                local h = h - pad
                borderWidth = math.min(w / 2, 6)
                local critPercent = math.min(t / critical, 1)
                UiColor(1 - (1 - r) * critPercent, g * critPercent, b * critPercent, 0.5 + t/2)
                -- UiImageBox("ui/common/box-solid-6.png", w, h, borderWidth, borderHeight)
                UiRect(w,h)
            end
        UiPop()


        UiPush()
            UiTranslate(w/2 + pad/2, h/2)
            UiAlign("center middle")
            UiColor(1,1,1,1)
            UiFont("bold.ttf", h * .75)
            for i = 1, 2 do
                UiTextShadow(0,0,0, 1, 0.4, 0.4)
                UiText(title)
                UiTextShadow(0,0,0, 1, -0.4, 0.4)
                UiText(title)
            end
        UiPop()

    UiPop()
end

function ColorGradient(percentage)
	return 1-percentage^2, percentage, (percentage^2)*0.4
end

function math.clamp(n, low, high) return math.min(math.max(n, low), high) end

function Split(s, delimiter)
    local result = {}
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match)
    end
    return result
end
function sfn(numberToFormat, dec)
    local s = (tostring(dec or 2))
    return string.format("%."..s.."f", numberToFormat)
end

function NumberLerp(a,b,f)
	return a*(1-f)+b*f
end
function SmoothTransition(f)
	return .5-math.cos(f*math.pi)/2
end
function handleCommand(cmd) HandleQuickload(cmd) end
function HandleQuickload(cmd)
	for _, word in ipairs(splitString(cmd, " ")) do
		if word == "quickload" then
			Init_Settings()
		end
		break
	end
end
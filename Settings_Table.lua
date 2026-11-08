#include "scripts/TDSU/tdsu.lua"


--idea create unique id for each setting so it can always be referenced if the ui or registry functions change.
--idea You would essentially have a pointer to the address in registry.


function Init_Settings_Table()

	Settings_Table = {

		game = {
			blood_and_gore            = st_object_checkbox("Blood and Gore", true), -- Do not spawn blood voxels or gorey prefabs
			killcam                   = st_object_checkbox("Killcam", true), -- focus on dead enemy when they ded
			enable_tools              = st_object_checkbox("Enable Other Mod Weapons", false),
			hitmarker                 = st_object_checkbox("Show Hitmarkers", true),
			draw_loot_outlines        = st_object_checkbox("Show Loot Outlines", true),
			forced_1st_person_driving = st_object_checkbox("Force first person camera when driving", false),
			combat_music              = st_object_checkbox("In-game music that is triggered by specific events", true),
			enemy_helicopter          = st_object_checkbox("Allow random enemy helicopters to be spawned", true),
			a10_brt                   = st_object_checkbox("Allow random Air Strike to be spawned", true),
		},


		keybinds = {

			player = {
				reload           = st_object_keybind("Reload",             MakeKeybind("r")),
				select_fire      = st_object_keybind("Select Fire",        MakeKeybind("v")),
				clear_jam        = st_object_keybind("Clear Gun Jam",      MakeKeybind("r")),
				side_toggle      = st_object_keybind("Side Toggle",        MakeKeybind("b")),
				gun_inspect      = st_object_keybind("Inspect Gun",        MakeKeybind("y")),
				mag_check        = st_object_keybind("Check Gun Mag",      MakeKeybind("h")),
				gun_attachment   = st_object_keybind("Use Gun Attachment", MakeKeybind("t")),
				--lean             = st_object_keybind(                                      ),-- (no idea how to deal with interact key conflict)
				--gun_melee        = st_object_keybind("Gun Melee",          MakeKeybind("x")),

				throw_grenade    = st_object_keybind("Throwables",         MakeKeybind("g")),
				night_vision     = st_object_keybind("Night Vision",       MakeKeybind("n")),
				sprint           = st_object_keybind("Sprint",             MakeKeybind("shift")),
				weapon_wheel     = st_object_keybind("Weapon Wheel",       MakeKeybind("mmb")),
				healthUI_toggle  = st_object_keybind("Toggle Health UI",   MakeKeybind("h")),
				placetool_Scroll = st_object_keybind("Placetool Scroll",   MakeKeybind("r")),
				canted_sight     = st_object_keybind("Canted aimming",     MakeKeybind("c")),
				alt_sight        = st_object_keybind("Alternative Sight",  MakeKeybind("alt")),
			},

			other ={
				spawn_menu_     = st_object_keybind("Open Loot Spawn Menu", MakeKeybind("c", "alt")),
				spawn_menu_undo = st_object_keybind("Undo Last Spawn",      MakeKeybind("z", "ctrl")),
			},

			inventory = {
				toggle_inv    = st_object_keybind("Toggle Inventory",    MakeKeybind("tab")),
				drop_item     = st_object_keybind("Drop Inventory Item", MakeKeybind("q")),
				rotate_item     = st_object_keybind("Rotate Inventory Item", MakeKeybind("r")),
				--transfer_item = st_object_keybind(), --(for stash, airdrop, etc, will work like drop item) #not a thing yet?
			},

			vehicles = {
				drive_by_shooting = st_object_keybind("Drive By Shooting", MakeKeybind("grab")),
				siphon_fuel       = st_object_keybind("Siphon Fuel",       MakeKeybind("q")),
			},

		},

		performance = {

			visual = {
				no_shadow              = st_object_checkbox("Disable Shadows", false), -- Don’t teleport everything back to shadow volume
				reduce_render_distance = st_object_checkbox("Reduce Render Distance", false), --* Connected in Gamerule.lua -- Cull all shapes
				foliage_percentage     = st_object_range("Foliage Density", 0.2, 0, 1, 0.01),
			},

			physical = {

				spawn_less_objects = st_object_checkbox("Reduce Number of Objects" , false), --* Connected in RandomBuilding.lua
				debri_cleaner      = st_object_checkbox("Remove Small Objects",      false), -- Built-in autocleaner, Based on min shape size.

			},

			--structure_spawns	= { -- (in question)
			--	simple_structures = st_object_checkbox("Spawn Simple Structures", false), -- (small buildings & no special buildings)
			--	large_buildings   = st_object_checkbox("Spawn Large Buildings",   true),
			--	medium_buildings  = st_object_checkbox("Spawn Medium Buildings",  true),
			--	small_buildings   = st_object_checkbox("Spawn Small Buildings",   true),
			--	checkpoints       = st_object_checkbox("Spawn Checkpoints",       true),
			--	special_buildings = st_object_checkbox("Spawn Special Buildings", true),
			--	bridges           = st_object_checkbox("Spawn Bridges",           false),
			--	villages          = st_object_checkbox("Spawn Villages",          false),
			--	wall              = st_object_checkbox("Spawn Walls",             true)     -- (giant border wall)
			--},

			-- misc = {
			-- 	reset_progress = st_object_confirmation(
			-- 		"Reset All Progress",
			-- 		"Are you sure you want to reset all progress? This cannot be undone."
			-- 	),

			-- 	reset_options = st_object_confirmation(
			-- 		"Reset All Options",
			-- 		"Are you sure you want to reset all options? This cannot be undone."
			-- 	),

			-- 	reset_mod = st_object_confirmation(
			-- 		"Reset Mod",
			-- 		"Are you sure you want to completely reset the mod? This cannot be undone."
			-- 	),
			-- },

		}


	}

	-- PrintTable(Settings_Table)
	-- PrintTable(st_table(Settings_Table))

end


--todo character validation
function MakeKeybind(k1, k2, k3)
	return { k1 = k1 or "none", k2 = k2 or "none", k3 = k3 or "none" }
end

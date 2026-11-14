# Folder layout (reorganized 2026-11-14 with `tools/relocate/`, map in `tools/relocate/moves.txt`)

| Folder | What is in it |
|---|---|
| (root) | Files the engine looks for: `info.txt`, `id.txt`, `preview.jpg`, `options.lua` (mod manager Options screen), `spawn.txt` (spawn menu), `main.xml` (main menu level) + `main.lua` |
| `main/` | `main.xml`'s LEVEL folder (`LEVEL/x` = `main/x`): terrain, building components, abandoned places, stores, gas station, general props, small level scripts. Files named by a `LEVEL/` path must stay here |
| `levels/` | The game levels: `level.xml` / `level_no_shadow.xml` → `level_instance.xml`, `level_scripts*.xml` (the level scripts list), tutorial, horde, Christmas menu |
| `lib/` | Shared libraries: `Config.lua` (debug menu), `Settings*.lua`, `ModConfig.lua`, `Automatic.lua`, `TDSU/` (with `compat.lua`), `masterScriptRemover*`, `missing_script_stub.lua`, `savegamePatchHandler.lua`, `DevShortcuts.lua`, `utility.lua` |
| `ui/` | Main menu (`MainMenu/`), spawn menu, debug/config menu, pause menu, book, frame player, menu scene rotation, update log |
| `game/` | Game rules and economy: `MLSandbox.lua` (the engine's sandbox.lua minus MP tool enabling), game rules, new-level hand-over / new run, perks, perk machine, parking garage, safe zone, shop, tool manager, radio, loot outlines, tutorial scripts (`Tutorial/`) |
| `world/` | Road generation and spawners (`generation/`, was `Procedural/`), day/night (`daynight/`), weather, doors and windows, trees, warehouse scripts, debris, lore documents, supply drops (parachute, AC130) |
| `player/` | Health (`HealthSystem/`), inventory (`inventory.lua` + item descriptions, weapon wheel, meds), hitboxes, lean, player id, view tweaks |
| `weapons/` | Guns (`guns/`: one script per gun, `gunfunctions.lua`, `gunnet.lua`, gun stats/perks, `Weapons/` tool prefabs), melee (`melee/`), grenades, mines, the place tool |
| `items/` | Loot prefabs (`Loots/`), loot crates (`randomloot.lua`), loot chance |
| `npcs/` | GoreNPCs (AI, `npcs/GoreNPCs/`), GoreRagdolls2 (ragdolls, crew sitters), cultist spawner, blood |
| `vehicles/` | Cars (`cars/`, was `Vehicles/`), AVF armed vehicles and configs (`avf/`), the AVF shell port (`avf_port/`), mounted guns, steering wheel, enemy / convoy drivers (`operators/`), aircraft (`aircraft/`: AS350, CH-47, Hind, UH-1H, CRJ-200), fuel, car alarm |
| `prefabs/` | Spawnable prefabs (road segments, buildings, enemies, vehicles, loot, bosses, perks, supply drops). Moves only as a whole: spawn code builds `"MOD/prefabs/" .. name` |
| `assets/` | Shared assets: `vox/`, `snd/`, `img/`, `brush/`, `skybox/`, props. `snd/` and `img/` move only as a whole (paths built at run time) |
| `dev/` | Test levels (`dev/levels/`), dev tools and scripts; left out of the release |
| `docs/`, `tools/` | Documentation; porting tools, mock tests, relocation tool |

Moving files later: add lines to `tools/relocate/moves.txt` (or a new moves file) and run
`python tools/relocate/relocate.py plan <moves>`, review `tools/relocate/out/plan.txt`, then `apply` with Teardown
closed (README in `tools/relocate/`).

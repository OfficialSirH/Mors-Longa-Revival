# Mors Longa Revival – start here (handoff for new sessions)

Goal: port the abandoned Teardown mod **Mors Longa** (Workshop 2906369984, by Overdrive Studios;
assets free to use with credit) to **Teardown 2.x co-op multiplayer (up to 4 players)**.
The user is a software engineer with no Lua experience; explain Lua/Teardown specifics, not basics.

Read next, in this order:
1. `docs/TECHNICAL_REFERENCE.md` – everything learned so far: sources, v2 rules, in-game error →
   cause table, server/client-only functions, tool/gun internals, vehicles, project map, status log.
2. `docs/PORTING.md` – the short rule list.
3. `tools/porting/README.md` – tool usage.

## Agreed decisions

* Co-op only, ≤4 players. Client is trusted with its own gun/inventory state (no anti-cheat).
* Phase 2 (2026-11-06): **health and inventory both run on each player's client** (client-trusted). Each player
  gets their own hitbox triggers placed by the server, so NPC damage code (`QueriedDamage` tags) works unchanged;
  the server forwards a player's hitbox damage to that client. The server only does world ops: pickups (it
  arbitrates, so two players can't take the same item), drops, tool enabling, SetPlayerHealth/walking speed.
* Procedural highway: the furthest player drives generation; **stragglers are teleported**; the
  world-shift in `Procedural/GenerateRoad.lua` must move all players.
* AVF (Armed Vehicles Framework) has no MP update and TABS is not a fit: write our own v2 mounted-gun
  script that reads the existing AVF tags in the vehicle XML.
* Plan phases: 1) v2 in single-player, 2) per-player state (inventory, health, weapons),
  3) world gen / NPC targeting / vehicle seats, 4) vehicles + mounted guns, helicopters last, 5) publish.
  MP only loads **published Workshop** mods, so final testing needs a (private) Workshop upload.

## Working with the user

* The user tests in-game and sends screenshots of red error text. Keep rounds small, say exactly what
  to test, and use the in-game gun names (list in TECHNICAL_REFERENCE §5 / last status entry).
* **Don't claim causes you haven't verified.** Once I blamed own bullets for damaged guns when the
  user hadn't fired; ask, or gather data first (Ctrl+O / Ctrl+L overlays, offline renders).
* Work happens on git branch `main` (`original` = untouched Workshop copy). The user said git
  identity is unnecessary; **changes are left uncommitted** for the user to commit/push (SSH remote).
* Never delete files in the user's folder without asking (device shell can't delete by default).

## Environment and file transfer (gotchas)

* Repo on the user's PC: `C:\Projects\Mors Longa` (device shell: `$HOME/mnt/Mors Longa`). Also
  connected: Teardown install (`$HOME/mnt/Teardown`) and Workshop mods (`$HOME/mnt/1167630`).
* Device shell has python3/node but **no Lua** and no package registry access. If the container has no network either, `texlua`
  (TeX Live, Lua 5.3) runs `check`-style syntax checks and `toplevel.lua`. The cloud container
  builds Lua 5.1 from GitHub (`git clone https://github.com/lua/lua; git checkout v5.1.1;
  gcc -O1 -w -DLUA_USE_POSIX -o lua51 $(ls *.c | grep -vE '^(luac|print)\.c$') -lm`).
* PC → container: tar into `.git/claude-xfer/` (never committed), then `device_stage_files`.
* Container → PC: `device_commit_files` **from a fresh directory** (`/mnt/user-data/outputs/xfer-<ts>/`)
  and **compare md5 on both sides** afterwards – re-committing a reused path delivered stale files twice.
* Repo Lua files are CRLF: edit via python (bytes, normalise `\n`, assert replacement counts, write `\r\n`).
* The online API page truncates in WebFetch; use `Teardown/data/script_defs.lua` (757 functions) and
  the official example mods `Teardown/mods/minigun`, `lasergun` instead.

## Current state (2026-11-06)

* **Phase 1 done** for all 55 level scripts (`level_scripts.xml`); every step verified in-game. Guns: all work except
  PKM, M9, Bauer-553 (SG553), shelved as unfinished by the original devs (not loaded).
* **Phase 2 first pass done and verified in-game** (single-player): health + inventory per player on the client
  (`HealthSystem/AdvancedHealthScript.lua`, `script/inventory.lua`), per-player hit triggers on the server
  (`scripts/PlayerHitboxes.lua`), static gun scripts (group `GunScripts` in the 4 level xmls), per-player tool
  enabling in inventory's server.tick (ToolManager is a no-op). Details + pitfalls: TECHNICAL_REFERENCE status log.
* Original-mod bugs fixed along the way (all logged): Split(nil) crash, empty-mag HUD, military truck never
  spawning, missing 4GA ammo / broken loot-table entries, PKM script lookup, material removal, pause button
  ("main_bottom" is never drawn by data/ui/hud.lua), Cultist ambushes never firing (now on), thermals only
  highlighting heads, own grenades not hurting the player (now they do - new behaviour).
* Spawn menu category **Weapons → Testing** (`debugTest` in Procedural/SpawnRefrenceTable.lua) holds items that were
  only in test.xml (PKM, Bauer, M9, melee, Type-67, PVS-14, PNV-10T, all ammo types, missing mags).
* Still v1 (111 scripts referenced from xml, ~21k lines + includes): GoreNPCs (12k lines incl. includes), boss AIs,
  chase/convoy operators, vehicles/AVF (42), helicopters, ~20 small prefab scripts, tutorial scripts.

## Open items / next steps

1. **Phase 3 - GoreNPCs → v2** (decided: keep GoreNPCs, not GYMP; targeting = nearest visible player; effects may
   stay on the server - official v2 scripts call PlaySound/SpawnParticle/PointLight from server callbacks).
   Shape: `goreai_main.lua` = one manager script for all NPCs (tick/update = AI → server; draw = UI → client;
   v1 `handleCommand` explosions → `GetEventCount("explosion")`); each of 152 NPC prefabs has
   `goreai_initializer.lua` (per-NPC pathfinding via registry `level.goreai.nav_api.<id>`). Client-only parts to
   split: killcam camera, controller (possession) UI/input, music, hitmarkers, sounds that use the camera.
   `PlayerPos` (host) → per-NPC target player; `init_player_hitboxes` must map each player's set
   (`hitbox_player=<id>`, see PlayerHitboxes.lua). `tick()` spawns "MOD/Config.lua" if `level.configScriptSpawned`
   is unset - should be scripts/ConfigMenu.lua.
2. Phase 3 rest: generation player = furthest player + straggler teleport (`GetGenerationPlayerPos` in
   GenerateRoad.lua); chase/convoy operators (DriveVehicle server); seat models for other players; small prefab
   scripts (doors, parachute, debris, tutorial).
3. Known gaps: money from selling fuel is written on the server (host registry); saves are per machine (MP
   behaviour unverified); camo variants of LoadTool guns not registered; scope zoom tweak disabled in some rifles.
4. Phase 4 vehicles + own mounted-gun script (AVF tags), helicopters last; Phase 5 private Workshop upload for MP.
5. MP test list (needs Phase 5 upload): pause button primary slot, server-side effects visible on clients,
   per-player tools/hitboxes, client savegame.

## Tool inventory (`tools/porting/`, details in its README)

| Tool | Purpose |
|---|---|
| `check.lua` | Lua 5.1 syntax check (ignores `#include`/`#version`) |
| `toplevel.lua` | load a script + include chain on a mock engine; lists API calls at load time (forbidden in v2) |
| `sides.py` | per-function server-only / client-only / UI / registry call report (how to split a script) |
| `patches/convert_gun.py` | v1 gun → v2 converter; asserts on template deviations; per-gun FIXUPS table |
| `patches/gunfunctions.py` | the projectile world/fx split as applied to gunfunctions.lua (history) |
| `patches/convert_melee.py`, `patches/convert_server.py` | melee / world-script v1 → v2 converters |
| `make_tool_prefab.py` | builds `<GUN> Tool.xml` tool prefabs (reverse part order, tags, missing `file=`, lane grid) |
| `vox.py`, `render_gun.py` | MagicaVoxel reader + offline labelled render of a gun model (matplotlib) |
| `tests/test_compat.lua`, `tests/test_gunnet.lua` | mock-engine tests (run from repo root) |

In-game debug: hold a v2 gun, **Ctrl+O** = part index labels, **Ctrl+L** = part table (local pos,
voxel size, rotation). Compare sizes with the vox file (`vox.py` bbox) to spot build problems.

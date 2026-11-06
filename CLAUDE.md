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
* Device shell has python3/node but **no Lua** and no package registry access. The cloud container
  builds Lua 5.1 from GitHub (`git clone https://github.com/lua/lua; git checkout v5.1.1;
  gcc -O1 -w -DLUA_USE_POSIX -o lua51 $(ls *.c | grep -vE '^(luac|print)\.c$') -lm`).
* PC → container: tar into `.git/claude-xfer/` (never committed), then `device_stage_files`.
* Container → PC: `device_commit_files` **from a fresh directory** (`/mnt/user-data/outputs/xfer-<ts>/`)
  and **compare md5 on both sides** afterwards – re-committing a reused path delivered stale files twice.
* Repo Lua files are CRLF: edit via python (bytes, normalise `\n`, assert replacement counts, write `\r\n`).
* The online API page truncates in WebFetch; use `Teardown/data/script_defs.lua` (757 functions) and
  the official example mods `Teardown/mods/minigun`, `lasergun` instead.

## Current state (2026-11-04)

* UMF removed (`scripts/TDSU/compat.lua`). `script/gunfunctions.lua` has the world/fx projectile split,
  lazy sounds, `GunRaycast` (skips `ml_toolpart`). `script/gunnet.lua` = gun networking + debug overlays
  (Ctrl+O part labels, Ctrl+L part table) + `GunNet_FixToolParts` (24 m grid lanes, per part).
* **All 38 gun scripts are v2.** AK74 ("Simonov-545") verified in-game (model, fire, reload). The other
  37 are converted but **untested**; the user has the test list (TT-33 fix of the lane guard + missing
  `file=` attributes is the latest change, awaiting test).
* 18 generated tool prefabs `script/Weapons/<GUN> Tool[-camo].xml` for the 8 LoadTool guns + AK74.
* Original-mod bugs fixed: empty-mag HUD concat (32 guns), inventory `invSlot.rotation` nil (3 places),
  Sawed Off checking MP43's enabled flag.
* Everything else (inventory, health, NPCs/Gore AI, procedural gen, vehicles, UI, ~180 scripts) is still v1.

## Open items / next steps

1. Process the user's gun test results (fix per gun; Ctrl+L tables are the best evidence).
2. Unverified: can gun melee / first bullet raycast damage engine-built **vox** guns (not tagged
   unbreakable)? If yes, tag their shapes or skip them in `GunRaycast`.
3. Disabled for now: scope look tweak (`SetPlayerTransform(ppos2,true)`) in several rifles → re-do with
   `SetToolAllowedZoom`. Camo variants are generated but not registered (tool model is global per id).
4. Remote players: gun parts are only animated for the local player; inventory still toggles tools via v1
   registry keys (`game.tool.<id>.enabled`, `game.player.tool`) and spawns gun scripts dynamically – both
   belong to the Phase 2 inventory redesign (all gun scripts static, per-player tool enabling on the server).
5. RPG rocket prefab runs `script/grenade.lua` (still v1).
6. Continue Phase 1 with the non-gun scripts: map them with `tools/porting/sides.py` (list of reachable
   scripts: see TECHNICAL_REFERENCE §7), fix the 91 `Get/SetPlayerTransform(…, true)` pitch calls.

## Tool inventory (`tools/porting/`, details in its README)

| Tool | Purpose |
|---|---|
| `check.lua` | Lua 5.1 syntax check (ignores `#include`/`#version`) |
| `toplevel.lua` | load a script + include chain on a mock engine; lists API calls at load time (forbidden in v2) |
| `sides.py` | per-function server-only / client-only / UI / registry call report (how to split a script) |
| `patches/convert_gun.py` | v1 gun → v2 converter; asserts on template deviations; per-gun FIXUPS table |
| `patches/gunfunctions.py` | the projectile world/fx split as applied to gunfunctions.lua (history) |
| `make_tool_prefab.py` | builds `<GUN> Tool.xml` tool prefabs (reverse part order, tags, missing `file=`, lane grid) |
| `vox.py`, `render_gun.py` | MagicaVoxel reader + offline labelled render of a gun model (matplotlib) |
| `tests/test_compat.lua`, `tests/test_gunnet.lua` | mock-engine tests (run from repo root) |

In-game debug: hold a v2 gun, **Ctrl+O** = part index labels, **Ctrl+L** = part table (local pos,
voxel size, rotation). Compare sizes with the vox file (`vox.py` bbox) to spot build problems.

# Porting tools

Helpers for converting Mors Longa scripts to Teardown 2.x (`#version 2`). Rules: `docs/PORTING.md`; context and
engine facts: `docs/ENGINE.md` (index: `docs/TECHNICAL_REFERENCE.md`). Run everything from the repo root.

## Setup (per session, user's PC)

* Lua 5.1: clone `https://github.com/lua/lua`, `git checkout v5.1.1`, then (Git Bash, LLVM installed)
  `clang -O1 -w -o lua51.exe $(ls *.c | grep -vE '^(luac|print|ltests)\.c$')`.  No Lua at all: `texlua` (TeX Live, Lua 5.3) runs `check.lua` and `toplevel.lua`.
* Python: `python` (3.13) is installed on the user's PC (`python3` is not on PATH).

## Analysis

* `check.lua` – Lua 5.1 syntax check, `#include`/`#version` lines ignored: `lua5.1 tools/porting/check.lua f.lua`.
  Lines starting with `#` are treated as directives, so don't start a code line with `#x`.
* `toplevel.lua` – loads a script + its quoted `#include` chain on a mock engine and lists API calls made at load
  time (forbidden in v2): `lua5.1 tools/porting/toplevel.lua . weapons/guns/AK74.lua`. Unquoted includes
  (`#include x.lua`) are not followed: run it on those files directly.
* `sides.py` – per-function report of server-only / client-only / UI / registry calls (how to split a script).

## Vehicle seats

`add_seats.py [--dry-run] [--replace]` (idempotent; still in use for new vehicles): details in the table row below.
Its `EMPLACEMENTS` (Kornet / AGS-30 tripods) are rebuilt from git `cfa00f1` on `--replace`.

## Converters (`history/`, frozen 2026-11-14)

The conversion is done: the converters are **no longer run** and the files they produced are ordinary source, edited
directly. They stay in `history/` as a record of what each conversion changed (see `history/README.md`; running a
rebuild converter now would overwrite every edit made since). **Rebuild** converters regenerated their files from a
git base; **in-place** converters converted a v1 file once.

| Converter | Kind | Files |
|---|---|---|
| `convert_gun.py <file>` | in place | one gun script; asserts on template deviations; per-gun FIXUPS + all-gun fixes (camo nil, `GunPerkFor`) |
| `convert_melee.py` | in place | 8 melee weapons (world effects via `Melee_Functions.lua` → `server.meleeOps`) |
| `convert_server.py` | in place | world scripts; `convert(path, edits, note, realms)` is imported by the others (`realms` maps v1 callbacks to `server`/`client`, default all server) |
| `convert_goreai.py [file]` | rebuild (base 6c28435) | GoreNPCs components/initializer, plus gunfunctions.lua, Melee_Functions.lua, AdvancedHealthScript.lua edits. Hand-written: goreai_main, systems/goreai_killcam, _players, _netview, _controller, _sitting |
| `convert_operators.py` | rebuild (base 6c28435) | enemy/convoy car scripts (server only) |
| `convert_props.py [file]` | in place | small prefab scripts (batches A, D), RPG rocket `weapons/guns/grenade.lua` (restore v1 with `git show 6c28435:<f> > <f>` before re-running) |
| `convert_shop.py [file]` | in place | shop segment scripts (batch B) |
| `convert_menu.py` | rebuild (base 6c28435) | main menu scripts, RotateScene; edits lib/Config.lua once |
| `convert_horde.py` | rebuild (base 6c28435) | WaveHandler, HordePlaceTool (horde shelved) |
| `add_seats.py [--dry-run] [--replace]` | idempotent | seat rigs per vehicle (VEHICLES table) into the prefab and its embedded copies (`instance=` groups, or a `path=MOD/...` tag on the `<vehicle>`; key `file#name` = that file's `<vehicle name="name">`); skips vehicles with rigs unless `--replace`. Layouts: `driver(...)`, `driver_standing(stand, wheel, radius)`, `passenger(..., yaw=, legroom=, floor=, head=)`, `gunner_seated(seat, feet_y, legroom=, yaw=)` (seated gunner place, ZU-23 mount / BMP / tank turrets), `gunner(sort, stand, grip, yaw=)` (standing mounted-gun place, rig tags `gunner relative_parent sort=99`, written under the vehicle's first `<body>`; the engine still counts it as the last seat; vehicles/MountedGun.lua) (`head`: ik_head offset, default 0.8 up; low cabs as official pickup_red: (0, 0.55, 0.25), tilt 70-80), `shifted(layout, dy=)`, `official(prefab, shift=, seat=, move=, keep=)` (copies an official 2.x vehicle's rigs; `seat`/`move` move single locations, `keep` filters rigs), `heli_pilot(seat, feet_y, legroom)` (AS350 pilot facing +z). `WRAP_VEHICLE` (script marker → `<vehicle>` tag): first wraps those scripts' content in a `<vehicle>` (AS350, which had none), idempotent |
| `port_immersive.py` | rebuild (base git 9dde6dd) | `vehicles/avf/scripts/Immersive_Tank.lua`: logic on the server, effects on the clients (one event each), test `test_immersive_tank.lua` |
| `port_avf.py` | rebuild (base `tools/porting/history/avf_base/`, AVF V-3.0.2, credited) | `vehicles/avf_port/AVF_Shells.lua`: AVF's shell code split server (simulation, world effects, damage) / client (visuals from events); glue by hand in `vehicles/avf_port/AVF_Glue.lua`; test `test_avf_cannon.lua`; cost profile `tests/profile_avf_foliage.lua` (real quaternion maths, counts engine calls per shell) |
| `heli_variants.py` | rebuild (base: the current `vehicles/aircraft/AS350/AS350_{MILITARY,INSURGENT}.xml`, run after `add_seats.py`) | `AS350_*_PARKED.xml`: spawn-menu copies tagged `parked` (no enemy AI) |
| `convert_steering.py [--dry-run]` | idempotent | fake-wheel steering wheels (UAZ-452 ×5) → `steer`-tagged body part + `<script file="MOD/vehicles/SteeringWheel.lua">` around the vehicle |
| `gunfunctions.py` | history | the projectile world/fx split as applied to gunfunctions.lua |

All converters wrote LF (the repo is LF since 2026-11-08); inputs read from old commits may be CRLF. `add_seats.py`
is the only one of this table still run (from `tools/porting/`).

## Mock tests (`tests/`)

* `mockengine.lua` – stubs every API function from `script_defs.lua` (records calls, returns 0 / {} / Vec /
  Transform), flags client-only calls on the server and server-only calls on the client, fake registry, players
  (`PLAYERS`, `ORDER`, `LOCAL`, `ADDED`, `REMOVED`), `ServerCall`/`ClientCall` into `env.sent`, `shared`.
  `MockEngine.load(path, {preload = MockEngine.includes(path)})` runs a script with its include chain.
  `env.def(name, fn)` overrides a stub but still records it. Stubs return 0, which is truthy in Lua: def
  `HasTag`/`IsHandleValid`/`InputPressed` etc. to false where a test depends on it.
* Tests: `test_compat`, `test_gunnet`, `test_goreai`, `test_npcview`, `test_generateroad`, `test_removeroad`,
  `test_travel`, `test_operators`, `test_vehicleevents`, `test_props`, `test_shop`, `test_tutorial`, `test_menu`,
  `test_horde`, `test_sitting`, `test_steeringwheel`, `test_door`, `test_vehiclescripts`, `test_evf`, `test_jet`, `test_mountedgun`, `test_avf_cannon`, `test_immersive_tank`, `test_heli`, `test_sitter`, `test_newlevel` (MP new run), `test_invtools` (per-player tools vs sandbox.lua), `test_gunparts` (other players' guns), `test_gun3p` (third-person gun copy), `test_infinitemag` (fake Infinite magazine), `test_slot4` (key 4 cycles slot 4), `test_mpleads` (host perks, fuel money, ambush target, server gravity), `test_decor` (segment pieces queue, spawn slot), `test_npcperf` (NPC per-tick cuts: bones, nav registry, path state, heli search; call profiler), `test_invsave` (inventory save cache), `test_shiftprobe` (debug shift probe: what a machine sees at a world shift), `test_kitseed` (starter kit seed), `test_meleenet` (other players' melee weapons: pose, swing, sounds), `test_npcprobe` (debug NPC sync readout, server sound test), `test_buildprobe` (debug building sync readout). Run all after every change:
  `for t in tools/porting/tests/test_*.lua; do lua5.1 $t || echo "FAIL $t"; done`.

## Other tools

* `lighten_terrain.py [--dry-run]` – road segments' hidden unbreakable floors -> 40 cm plates, MorsLongaHill /
  MorsLongaDunes -> cropped tiles (`assets/vox/terrainpieces/tiles/`); checks placement and cover; re-runnable.
* Segment heavy content, in this order (re-run all three after editing a segment, a part or a terrain model):
  * `split_heavy.py [--dry-run]` – each child of a segment's `terrain` / `Background` groups and every rock / hill
    reference -> its own prefab in `prefabs/spawnables/roadsegments/parts/` (the source for the next step, not
    spawned as files); checked like split_decor; re-runnable.
  * `vox_pieces.py` – rock1 / rock1_low / hill1 / hill1r / hill2 -> one file per placed model
    (`assets/vox/terrainpieces/pieces/`, same scene transform), checked by reading back.
  * `segment_pieces.py` – the parts cut into ~2200 pieces (groups into children, rocks / hills into their model
    pieces, rock pieces with a low-detail version) with a box-cell cost -> `world/generation/SegmentPieces.lua`;
    GenerateRoad spawns them under a per-frame budget. Checked (every element of every part once, with its chain).
* `tick_audit.py [--top N] [--file path]` – lists scripts with per-frame callbacks and the costly calls in them and
  in the same-file functions they call (level searches, ListKeys, queries, Spawn, string splits, registry
  reads / writes, loops), times the number of XMLs that reference the script. A reading list; real times come
  from Teardown's profiler (SHIFT+ALT+F3). Debug call profiles in game: `lib/CallProfiler.lua`.
* `rock_variant.py hollow|half [src] [out]` – hollow / half-resolution copies of a TDCZ .vox; `half` made
  `rock1_low.vox` (option "Low Detail Rocks"; even-grid blocks, checked against the reduced whole rock).
* `perf_pieces.py [Segment]` – dev: cuts a segment into its content groups (`dev/perftest/`) for the debug menu's
  "piece by piece" test.
* Joints and the splits (2026-11-20): a joint / rope only attaches to shapes of its own Spawn call. Check with the
  debug hook `level.debug.perftest_request = "jointcheck:<path>|<path>..."` (ui/ConfigMenu.lua; spawn order like
  GenerateRoad, prints loose joints by index) against the segment file + parts + decor in one prefab.
  * `joint_anchors.py list <Segment>` / `apply joint_anchors.json` – hidden 1-voxel static anchors at joints whose
    static partner was moved out (joint positions from the XML transforms, Teardown's Euler order checked in game).
  * `merge_joint_parts.py <spec.json>` – puts parts back into the segment where a moving partner (door, plank,
    pipe) was moved out; merged parts are listed in `parts_merged.txt` and skipped by `segment_pieces.py`.
  * `chunk_segments.py` keeps groups holding joints (and their subgroups) together.
  Re-check after re-running split_heavy / segment_pieces / chunk_segments.
* `split_decor.py [--dry-run]` – moves each road segment's roadside decor (bushes, rocks: most of its shapes) into
  `prefabs/spawnables/roadsegments/decor/` and writes `world/generation/DecorParts.lua`; proves every element keeps
  its parent chain (placement, group defaults); re-runnable (split segments are skipped).

* `../relocate/relocate.py` – the Phase 5 reorganization: moves files and rewrites every path reference,
  provably (README in `tools/relocate/`).

* `make_release.py [--dry-run] [--dest <folder>]` – Phase 5: copies only the files the game loads (no .git,
  tools, docs, dev files, root test levels) into `Documents/Teardown/mods/Mors Longa Revival (Release)`, the folder to
  upload (the dev mod folder is a junction to the repo). Refuses while `info.txt` says AUTHOR_NAME; keeps the
  release's own `id.txt` (its Workshop item after the first upload); empties only a folder it made itself.
* `make_tool_prefab.py <GUN> [camo...]` – builds `weapons/guns/Weapons/<GUN> Tool.xml` for LoadTool guns (reverse part
  order, one lane per part, tags, missing `file=` filled in).
* `vox.py` + `render_gun.py` – MagicaVoxel reader and an offline labelled render of a gun model (matplotlib):
  `python render_gun.py assets/vox/ak74.vox "weapons/guns/Weapons/AK74 Base.xml" out.png`.
* `blender_vehicle.py` – runs inside Blender (Blender MCP, server registered in the repo's `.mcp.json`; in Blender
  press N → "MCP for Blender" → Start MCP Server). Loads a vehicle/prefab XML (MOD/ and BUILT-IN/ paths, instances)
  into scene "Teardown": vox parts as coloured meshes, locations/lights/joints as named markers, XML attributes as
  `td_*` properties; local coordinates under the `TD:<name>` root are Teardown coordinates. `report(root)` /
  `td_pos(ob, part)` print marker positions relative to their part, ready to paste into the XML. Usage in its header.
  Checked: official seat markers land exactly on the seat cushions. Applies `.vox` node rotations (the UAZ body
  is stored turned 180°) and drops empty voxel layers around a shape like the engine (`crop_model`; found on the
  Jeep and ZIL-131, docs/VEHICLES.md). Group `prop0="file=..."` defaults are applied
  to child assets/vox/voxbox (Volga). Measuring: `show_only`, `cutaway(root, y)`, `heightmap(...)`, `ray(...)`,
  `vehicle_markers`. `mannequin(root, "driver sort=0")` / `mannequins(root)`: the official player character
  (`data/prefab/player/player_sven_lagom.xml`) as an armature, pelvis on the seat point, Blender IK to the rig's
  hand/foot points. Calibrated on the verified UAZ: reach, backrest and legroom match the game; the head is
  ~0.15 m higher than in-game (upright spine; the game's sitting pose is lower). Seat tilt follows the engine
  (eased toward upright by cos^2: rot x 50 -> ~29 deg, 55 -> ~37, 60 -> ~45). Hide mannequins before `ray`. Knees bend up/forward (leg IK pole +90; -90 bent them backward before 2026-11-08). The spine is IK'd so the head
  reaches the rig's `ik_head`, as the engine does (reclined official seats look nearly upright in-game).
  `merc(root, rig)`: the Friendly Merc ragdoll in the game's NPC sit pose on a rig (same math as goreai_sitting.lua,
  checked against it by test_sitting), to compare with the player mannequin.
* `fix_missing_scripts.py [--dry-run]` – repoints XML `<script file>` references to files that exist nowhere to
  `MOD/lib/missing_script_stub.lua`; re-run after adding prefabs.

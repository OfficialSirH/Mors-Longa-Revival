# Mors Longa Revival – start here (handoff for new sessions)

Goal: port the abandoned Teardown mod **Mors Longa** (Workshop 2906369984, by Overdrive Studios; assets free to use
with credit) to **Teardown 2.x co-op multiplayer (up to 4 players)**. The user is a software engineer with no Lua
experience: explain Lua/Teardown specifics, not basics.

Read next:
1. `docs/LAYOUT.md` – which folder holds what (reorganized 2026-11-14).
2. `docs/TECHNICAL_REFERENCE.md` – index of the technical reference (split 2026-11-15): `ENGINE.md` (sources,
   workflow gotchas, v2 engine rules, error → cause table, server/client-only API), `GUNS.md`, `VEHICLES.md`,
   `SYSTEMS.md` (how each system works now), `PERFORMANCE.md`, `CHANGES.md` (bugs fixed, behaviour changes),
   `STATUS.md` (shelved content, open questions, history).
3. `docs/PORTING.md` – checklist for converting one v1 script.
4. `tools/porting/README.md` – converters, mock tests, helper tools.

## Agreed decisions

* Co-op only, ≤4 players. Clients are trusted with their own state (guns, inventory, health, money; no anti-cheat).
* Health and inventory run on each player's client; the server does world ops (pickups it arbitrates, drops, tool
  enabling, SetPlayerHealth, walking speed) and forwards each player's hitbox damage to that client.
* Road generation: the furthest player drives it, stragglers are teleported, the world shift moves all players.
* AVF has no MP version: our own v2 mounted-gun script reads the AVF tags in the vehicle XML; AVF's shell code is
  ported (credited).
* AS350: a vehicle with seat rigs (not the original's per-frame teleport); players fly it with a mouse-aim model, the
  enemy AI keeps the original autopilot.
* Only the host starts levels (the game reads the host's savegame for difficulty/rules/perks/garage).
* Phases: 1) v2 in single-player ✔, 2) per-player state ✔, 3) world gen / NPCs / co-op logic ✔,
   4) vehicles: seats, mounted guns, helicopters (AS350) ✔,
   **5) polishing (2026-11-14): housekeeping, full reorganization, MP fixes, performance; then the Workshop
   publish.** MP is tested locally: the in-game mod editor runs a host and a client window on the user's PC.

## Working with the user

* The user tests in-game (SP for now) and sends screenshots of red error text. Keep rounds small, say exactly
  what to test, use in-game names (gun table: docs/GUNS.md).
* **Don't claim causes you haven't verified.** Ask, or gather data first (readouts, mock tests, overlays). Say
  "original-mod bug" only after checking the `original` branch (9dde6dd).
* Ask before changing original behaviour or balance; list such changes in docs/CHANGES.md.
* Git: work on branch **`revival`**; changes are left **uncommitted** – the user commits and pushes (SSH remote).
* Never delete files in the user's folder without asking.

## Environment (gotchas, details in docs/ENGINE.md "Workflow")

* Repo `C:\Projects\Mors Longa`; Teardown install and Workshop mods are added as extra working directories.
* No system Lua: build Lua 5.1 with clang (commands in the tools README). Python 3.13 is installed (`python`).
* Line endings: everything is LF (`.gitattributes`, normalized 2026-11-08); write LF.
* Converters are frozen (2026-11-14, `tools/porting/history/`): their output files are ordinary source, edit them
  directly. Never re-run a rebuild converter (it would overwrite those edits).
* API reference: `Teardown/data/script_defs.lua`, engine scripts in `Teardown/data/script/`, `data/ui/hud.lua`.

## Current state (2026-11-13)

* Phases 1-3 done and verified in SP (MP-only checks: docs/STATUS.md "Open questions"). Engine crash (Constrain* from tick)
  and long-run slowdown fixed; ~30 NPCs at once still cost FPS as in v1.
* Phase 4 (vehicles), all verified in SP unless noted:
  * Seats for every drivable vehicle in use (status table: docs/VEHICLES.md); friendly NPCs ride in them.
    New vehicles: measure in Blender (`tools/porting/blender_vehicle.py`, Blender MCP), add the layout to
    `tools/porting/add_seats.py`, check with the mannequin, then the user tests (rules: docs/VEHICLES.md).
  * Small vehicle scripts v2 (doors, Cadillac / LeBoat joints, semis' toggles, GAZ-24 EVF, JetBus).
  * Mounted guns: own `vehicles/MountedGun.lua` + AVF's shell code ported (`port_avf.py` → `vehicles/avf_port/`, credit
    AVF / elboydo) + `Immersive_Tank.lua`; machine guns, cannons, tanks (gunner place + driver fallback), launchers,
    coax, ATGMs, performance fixes. Converted configs: table in docs/VEHICLES.md "AVF". TABS can't be used (v1, licence).
  * AS350 helicopter: a `<vehicle>` with seats, v2 port with a new mouse-aim player flight model (docs/VEHICLES.md
    "AS350 helicopter"); rockets on RMB shelved (the pilot leans out instead, docs/STATUS.md).
  * v1 survey of normal play (2026-11-13): minivan helper, crew sitters, T-72A, GMG offroad, SPG-9 technical, Kornet /
    AGS-30 tripods converted and verified SP (tripods are gun emplacements now, not vehicles); spawn-menu entries
    added for testing; AVF body pushes capped (froze the game on the AGS-30's ~weightless gun).
* Shelved (docs/STATUS.md): guns PKM / M9 / Bauer-553 / MGL, horde mode, custom difficulty, Refugee Van event behaviour, AS350
  rockets on RMB, AGS-30 aiming up / down.
* Still v1 (dead in MP): CH-47 and Hind helicopters (user: later), `<screen>` scripts (docs/STATUS.md), unreached AVF configs
  and test levels (docs/VEHICLES.md, docs/STATUS.md).

## Next

Phase 5 polishing, in order (each part ends at a commit point, the user commits):
0. Local MP baseline: first test done (2026-11-14) → three bugs, fixed (step 3).
1. Housekeeping ✔ (2026-11-14): converters frozen to `tools/porting/history/`, dead files deleted, `.gitignore`,
   release leaves out the root test levels.
2. Full reorganization ✔ (2026-11-14, applied and verified by `tools/relocate/`: 4252 files moved, 42504
   references rewritten; mock tests, syntax of all game Lua, XML parse, release dry run checked). Folder map:
   `docs/LAYOUT.md`. The release leaves out `dev/`. Verified in-game by the user and committed (2026-11-14).
3. MP fixes (docs/CHANGES.md "MP fixes"): remote players' new run (starter loadout, vitals, perks, bounty, difficulty, money on
   Try Again) and game rules synced: verified. To re-test: vanilla tools (levels load `game/MLSandbox.lua`, the
   engine's sandbox.lua without its MP tool enabling), remote tool bar, other players' guns (gunnet part sync).
   Second round (2026-11-14, user: perks are the host's for everyone, debug menu host-only), to re-test: host
   perks / settings mirrored to every machine, perk pickups, fuel money to the seller, ambush around any player on
   foot, server bullet gravity, permadeath (any player's death ends a Hardcore run). Open: world-shift jank / NPCs /
   stuck car for non-hosts, server-only effects (check in MP), bullet network traffic; then the MP checklist in
   docs/STATUS.md "Open questions". Third round (2026-11-15): starter kit seeded per run / player, Hardcore thirst
   always drains, God Mode blocks bleed / fracture, casings capped at 60, debug "ambush now": to re-test. Shift
   jank measured (shift probe), no fix (a hold of player cars made them flip: never retry). MP crash: no trace yet.
   Verified in MP (2026-11-15 evening): other players' melee weapons (posed, swings, sounds, crouch), vehicle
   events (cleanup grace), ambush NPCs and server-side sounds on a client (NPC sync readout, sound test). Missing
   sound files from the log fixed (pistol / MK36 NPCs audible now, user OK; docs/CHANGES.md). Third-person guns
   (local 0.4-scale copy, engine rifle poses, scopes switch to first person) and scope overlay alignment: verified.
4. Performance (plan agreed 2026-11-14; user: segment spawns freeze 1-several s, shifts hitch a little, many NPCs
   cost a lot): order = generation first, then NPCs, then the world shift (rarer / faded) last.
   Done, to test in-game (docs/PERFORMANCE.md "Segment weight"): debug-menu "Performance tests" (left column)
   pinned the freeze on the segment's hidden bedrock floor > terrain (rocks) > sand, not the decor / spawners /
   RemoveRoad. Fixes: decor split out (`split_decor.py`), hidden floors -> 40 cm plates and hills/dunes -> tiles
   (`lighten_terrain.py`), terrain/background pieces split out (`split_heavy.py`); all spawned one prefab per
   frame after the segment, marker spawners wait (`level.segment.loading`). Rocks still hurt: their cost follows
   box cells (hollow didn't help, half resolution did) → option "Low Detail Rocks" (on by default). Lag stretches
   followed the parts (debug "spawn activity" readout) → rocks / hills cut per model, parts cut into ~2200 pieces
   spawned under a per-frame cell budget (`split_heavy.py` → `vox_pieces.py` → `segment_pieces.py`), spawners one
   spawn per frame (`SpawnSlot.lua`); placement verified by the user. Hidden floors back to 10 cm (40 cm plates let
   players fall through; `lighten_terrain.py --replate`), streamed first as pieces; to re-test. Scripts cannot
   time freezes (frame time capped at 1/30 s; use Teardown's built-in profiler SHIFT+ALT+F3, per-script ms).
   Performance step DONE (2026-11-15, docs/PERFORMANCE.md): generation gradual (all static geometry streamed
   nearest-first as pieces, then the segment file, then decor; queued at 300 m; duplicate-segment bug fixed),
   cleanup a continuous region sweep, NPC rate tiers (damage on hit, ground rays every 2nd step, sight 5x/s,
   voxel recount every 3rd tick; user OK), idle gun scripts exit early, inventory / daynight / sandbox / reject
   loops cut. Measured: no NPCs CPU ~13 ms; 10 NPCs goreai_main ~5 ms (profiler, 1 update / frame).
   User decisions: NO far-NPC rest (immersion), no shift fade, no longer play area. Tools: debug "spawn activity",
   "NPC / inventory call profile" (lib/CallProfiler.lua), tools/porting/tick_audit.py.
   Other candidates: inventory `SaveInventory()` every client tick, gun scripts' per-frame registry reads, Fuel.
5. Docs ✔ (2026-11-15, user OK): TECHNICAL_REFERENCE split into ENGINE / GUNS / VEHICLES / SYSTEMS / PERFORMANCE /
   CHANGES / STATUS (TECHNICAL_REFERENCE.md = index + old § map), folder map updated.
6. Workshop publish: after the MP re-tests. `tools/porting/make_release.py` builds the release copy (dry run
   2026-11-15: 6616 files, 551 MB); the user uploads it from the game's mod manager. Rebuilt 2026-11-15 with the
   third-person guns (6618 files, no dev files, no Workshop id yet: the first upload creates the item).

Later (user): a seat-switch key (players cannot switch seats; docs/STATUS.md), CH-47 / Hind, AS350 rockets on RMB, AGS-30 pitch.

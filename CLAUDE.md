# Mors Longa Revival – start here (handoff for new sessions)

Goal: port the abandoned Teardown mod **Mors Longa** (Workshop 2906369984, by Overdrive Studios; assets free to use
with credit) to **Teardown 2.x co-op multiplayer (up to 4 players)**. The user is a software engineer with no Lua
experience: explain Lua/Teardown specifics, not basics.

Read next:
1. `docs/TECHNICAL_REFERENCE.md` – sources, workflow gotchas, v2 engine rules, error → cause table, guns, vehicles,
   how each system works now, bugs fixed, shelved content, open questions.
2. `docs/PORTING.md` – checklist for converting one v1 script.
3. `tools/porting/README.md` – converters, mock tests, helper tools.

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
   **5) private Workshop upload for MP testing (MP only loads published mods), then publish.**

## Working with the user

* The user tests in-game (SP for now) and sends screenshots of red error text. Keep rounds small, say exactly
  what to test, use in-game names (gun table: TECHNICAL_REFERENCE §5).
* **Don't claim causes you haven't verified.** Ask, or gather data first (readouts, mock tests, overlays). Say
  "original-mod bug" only after checking the `original` branch (9dde6dd).
* Ask before changing original behaviour or balance; list such changes in TECHNICAL_REFERENCE §8.
* Git: work on branch **`revival`**; changes are left **uncommitted** – the user commits and pushes (SSH remote).
* Never delete files in the user's folder without asking.

## Environment (gotchas, details in TECHNICAL_REFERENCE §2)

* Repo `C:\Projects\Mors Longa`; Teardown install and Workshop mods are added as extra working directories.
* No system Lua/Python: build Lua 5.1 with clang, use a scratchpad Python venv (commands in the tools README).
* Line endings: everything is LF (`.gitattributes`, normalized 2026-11-08); write LF.
* Converters rebuild their files from git each run: **never hand-edit a converter-owned file** – put the change in
  the converter, run it fully, compare md5 before/after.
* API reference: `Teardown/data/script_defs.lua`, engine scripts in `Teardown/data/script/`, `data/ui/hud.lua`.

## Current state (2026-11-13)

* Phases 1-3 done and verified in SP (MP-only checks: TECHNICAL_REFERENCE §10). Engine crash (Constrain* from tick)
  and long-run slowdown fixed; ~30 NPCs at once still cost FPS as in v1.
* Phase 4 (vehicles), all verified in SP unless noted:
  * Seats for every drivable vehicle in use (status table: TECHNICAL_REFERENCE §6); friendly NPCs ride in them.
    New vehicles: measure in Blender (`tools/porting/blender_vehicle.py`, Blender MCP), add the layout to
    `tools/porting/patches/add_seats.py`, check with the mannequin, then the user tests (rules: §6).
  * Small vehicle scripts v2 (doors, Cadillac / LeBoat joints, semis' toggles, GAZ-24 EVF, JetBus).
  * Mounted guns: own `scripts/MountedGun.lua` + AVF's shell code ported (`port_avf.py` → `scripts/avf/`, credit
    AVF / elboydo) + `Immersive_Tank.lua`; machine guns, cannons, tanks (gunner place + driver fallback), launchers,
    coax, ATGMs, performance fixes. Converted configs: table in §6 "AVF". TABS can't be used (v1, licence).
  * AS350 helicopter: a `<vehicle>` with seats, v2 port with a new mouse-aim player flight model (§7 "AS350
    helicopter"); rockets on RMB shelved (the pilot leans out instead, §9).
  * v1 survey of normal play (2026-11-13): minivan helper, crew sitters, T-72A, GMG offroad, SPG-9 technical, Kornet /
    AGS-30 tripods converted and verified SP (tripods are gun emplacements now, not vehicles); spawn-menu entries
    added for testing; AVF body pushes capped (froze the game on the AGS-30's ~weightless gun).
* Shelved (§9): guns PKM / M9 / Bauer-553 / MGL, horde mode, custom difficulty, Refugee Van event behaviour, AS350
  rockets on RMB, AGS-30 aiming up / down.
* Still v1 (dead in MP): CH-47 and Hind helicopters (user: later), `<screen>` scripts (§10), unreached AVF configs
  and test levels (§6, §9).

## Next

1. Phase 5: the user puts their author name in `info.txt` (AUTHOR_NAME), runs
   `python tools/porting/make_release.py`, uploads "Mors Longa Revival (Release)" from the game's mod manager as a
   private item, then MP tests (list in TECHNICAL_REFERENCE §10).
2. Later (user): a seat-switch key (players cannot switch seats; §10), CH-47 / Hind, AS350 rockets on RMB, AGS-30 pitch.

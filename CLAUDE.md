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
* AVF has no MP version: write our own v2 mounted-gun script that reads the AVF tags in the vehicle XML.
* Only the host starts levels (the game reads the host's savegame for difficulty/rules/perks/garage).
* Phases: 1) v2 in single-player ✔, 2) per-player state ✔, 3) world gen / NPCs / co-op logic ✔ (except items
   awaiting test), **4) vehicles: passenger seats, mounted guns (own AVF replacement), helicopters last**,
   5) private Workshop upload for MP testing (MP only loads published mods), then publish.

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
* Line endings: match each file (most Lua/XML/docs CRLF, tests and most python tools LF); edit via python on bytes.
* Converters rebuild their files from git each run: **never hand-edit a converter-owned file** – put the change in
  the converter, run it fully, compare md5 before/after.
* API reference: `Teardown/data/script_defs.lua`, engine scripts in `Teardown/data/script/`, `data/ui/hud.lua`.

## Current state (2026-11-07)

* Phases 1-3 done and verified in SP, except **awaiting in-game test**: shop segment scripts (SafeZone,
  PerkMachine, ParkingSpot garage, cultist warehouse, AC130), vehicle/helicopter crew ragdolls (`fakegore.lua`),
  boss health bars (not met yet), some tutorial fixes (TECHNICAL_REFERENCE §10).
* Engine crash (Constrain* from tick) and long-run slowdown fixed; ~30 NPCs at once still cost FPS as in v1.
* Shelved: guns PKM / M9 / Bauer-553 / MGL, horde mode, custom difficulty (§9).
* Still v1: vehicles/AVF (~42 scripts), helicopters, small vehicle scripts (doors, drive/steer), test levels.

## Next: Phase 4 (vehicles)

1. Passenger seats: add `<location name="seat" tags="seat"/>` per vehicle (only 2 of 264 vehicle xmls have one),
   one vehicle at a time with in-game checks; exit locations.
2. Small vehicle scripts (door.lua in 28 xmls, drive/steer/drivetrain, bike, GAZ-24 extras) → v2.
3. Own mounted-gun script for AVF-tagged vehicles (turrets, technicals, tanks), replacing `avf/scripts/*`.
4. Helicopters last.
5. Then Phase 5: MP test list in TECHNICAL_REFERENCE §10.

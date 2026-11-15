# Mors Longa Revival — technical reference (index)

Everything learned while porting Mors Longa to Teardown 2.x co-op (`#version 2`), split by topic (2026-11-15;
until then all of it was in this file as §1-§11). Facts are marked **[verified in-game]**, **[official source]**
(game files / official mods / API docs) or **[unverified]**. `docs/PORTING.md` is the short checklist for
converting one script; these files are the detail. Day-by-day test logs (crash hunt tests A-N, vehicle /
mounted-gun / AVF / AS350 test rounds, readouts, dead ends) are in git history
(`git log -p docs/TECHNICAL_REFERENCE.md` up to the split); [STATUS.md](STATUS.md) "History" keeps a short summary.

| File | What is in it |
|---|---|
| [ENGINE.md](ENGINE.md) | engine rules: sources, workflow, v2 script model and rules, errors → cause, server/client-only API |
| [GUNS.md](GUNS.md) | guns: tool prefab layout, how the guns work, gun scripts → in-game names |
| [VEHICLES.md](VEHICLES.md) | vehicles: engine facts, seats, mounted guns / AVF, other vehicle scripts, AS350 helicopter |
| [SYSTEMS.md](SYSTEMS.md) | how the port works: level entry, world generation, NPCs, player, menus, other systems |
| [PERFORMANCE.md](PERFORMANCE.md) | performance work: road generation / cleanup and NPC cost (measurements, decisions) |
| [CHANGES.md](CHANGES.md) | original-mod bugs fixed and behaviour changes (incl. MP fixes) |
| [STATUS.md](STATUS.md) | shelved and dead content, open questions and known gaps, history |
| [LAYOUT.md](LAYOUT.md) | folder map |
| [PORTING.md](PORTING.md) | checklist for converting one v1 script |

Old section numbers (still used in older comments and in the frozen converters):

| Old | Now |
|---|---|
| §1 Sources | [ENGINE.md](ENGINE.md) "Sources" |
| §2 Workflow | [ENGINE.md](ENGINE.md) "Workflow" |
| §3 v2 engine rules | [ENGINE.md](ENGINE.md) "v2 engine rules" |
| §4 Server-only / client-only API | [ENGINE.md](ENGINE.md) "Server-only / client-only API" |
| §5 Guns | [GUNS.md](GUNS.md) |
| §6 Vehicles | [VEHICLES.md](VEHICLES.md) |
| §7 Systems | [SYSTEMS.md](SYSTEMS.md); its performance notes (segment weight, gradual generation, continuous cleanup, NPC cost / tiers) in [PERFORMANCE.md](PERFORMANCE.md); "AS350 helicopter" in [VEHICLES.md](VEHICLES.md) |
| §8 Original-mod bugs fixed, behaviour changes | [CHANGES.md](CHANGES.md) |
| §9 Shelved and dead content | [STATUS.md](STATUS.md) "Shelved and dead content" |
| §10 Open questions and known gaps | [STATUS.md](STATUS.md) "Open questions and known gaps" |
| §11 History | [STATUS.md](STATUS.md) "History" |

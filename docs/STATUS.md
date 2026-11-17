# Mors Longa Revival — status: shelved, open, history

Part of the technical reference (index and conventions: [TECHNICAL_REFERENCE.md](TECHNICAL_REFERENCE.md)).
Marks: **[verified in-game]**, **[official source]**, **[unverified]**.

## Shelved and dead content
* Refugee Van event (VehicleC3, debug "Refugee Van"; user decision 2026-11-08, revisit later): the van zig-zags
  while the convoy script drives it, and its driver stand-in doesn't behave like the bus's (in-game: the van stopped
  near the player without the driver being shot, so the driver stand-in was already gone; only the passenger got
  out). The full-size stand-ins (~1.1 m hips to head) don't fit the UAZ cab (0.9 m headroom) and clip roof/footwell.
  Causes not found: the steering-wheel script (removed) and the scaled stand-in (undone) didn't help. Leads: the
  convoy script's obstacle raycasts start 1 m above the vehicle origin, inside the cab (stand-in bodies may count as
  obstacles); stand-in parts breaking on contact (fakegore swaps a broken stand-in for a limp sitter, which removes
  the TORSOD driver tag). Spawn-menu spawns of event vehicles also misbehave (user); test through the debug event.
* Guns PKM, M9, Bauer-553 (unfinished: missing mag items, wrong mags, pre-ammo-system code); MGL launcher +
  `MGLgrenade.lua`. Revisit after the port.
* **Horde mode** (user: unfinished; revisit after the main game): unreachable in the original (its character-select
  stop sits in an unused `layer="horde"` of main.xml). The v2 conversion exists (`convert_horde.py`, test_horde.lua:
  WaveHandler → `shared.horde`, per-player HordePlaceTool) but is not exposed.
* Custom difficulty (also an unused menu layer, code commented out).
* **AS350 rockets on RMB** (user decision 2026-11-13, revisit later): in the pilot seat RMB leans the player out of
  the helicopter (the same lean-out as aiming out of a car) instead of firing rockets, also with empty hands (so
  emptying the pilot's hands, kept as in v1, does not stop it). Where the lean-out is implemented was not found
  (not `player/Lean.lua`, not the gun scripts' vehicle checks; the 1.x update log lists "New improved vehicle leaning,
  you can now drive as you lean out"). Options when revisited: find and suppress it for the pilot, or another key.
* **AGS-30 tripod aiming up / down** (user decision 2026-11-13, "Shelve and clean up"): its gun does not pitch, also
  as the unchanged original vehicle under our script (user test with a temporary copy); whether the external AVF of
  v1 could pitch it is unknown. Yaw and firing work. Tried, none moved it (readouts of hinge angle / aim error):
  rays skipping its own parts, the gunner not colliding with it, gun and mount not colliding (script filter),
  dropping its joints' `collide="true"` (the gun rests on the mount, both faces at the hinge line, Blender), driving
  both of its coaxial gun hinges, a speed-command mode, density 0.05 instead of 1e-12 (19 kg: it only sagged to its
  limit). No motor command ever moved its hinge; grabbing the gun by hand does. All reverted except what serves the
  other guns. Its gun weighs ~1e-7 kg (see the freeze in "Open questions and known gaps").
* Test-only levels stay v1: dev/levels/test.xml, dev/levels/lol.xml, test_*.xml, procgen and gore-map test levels, `main.lua`.
  `prefabs/other/Credits.xml` (thiccparticle.lua) is never spawned. `weapons/guns/craftingrecipes.lua` has a syntax
  error and is never loaded. ~478 Lua files existed, ~316 reachable; dead files (`unused/`, `_WORKSHOP/`, the
  Teardown-Totally-Documented dump, `*_old` / `- Copy` leftovers, editor stubs) deleted 2026-11-14 (in git history).

## Open questions and known gaps
MP-only (tested locally since 2026-11-14: the in-game mod editor runs a host and a client window on one PC):
* Found in the first local MP test and fixed, to re-test ([CHANGES](CHANGES.md) "MP fixes"): vanilla tools on for everyone, remote
  players without starter gear and at 0 hunger / thirst: verified fixed in the third test (the second one had run
  the stale release copy). Third test (2026-11-14) → other players' guns as loose parts, remote tool bar
  overlap: fixed, to re-test ([CHANGES](CHANGES.md)). The host runs at about half the client's FPS (21-30 vs 57-60): the host is
  server and client (expected to cost more; part of the performance work).
* World shift in MP (user, 2026-11-14, second local test; causes not verified): for non-hosts everything is thrown
  around for a moment at each shift and then corrects itself; NPCs sometimes struggle to stand for non-hosts while
  driving through generation / shifts; a non-host driving through a generation hitch: the car stopped, after the
  non-host got out the host was in the driver's seat but couldn't drive, and after the host got out nobody could
  get back in. The shift moves every body and trigger 200 m with SetBodyTransform in one server tick
  (`GenerateRoad.lua ReturnToShadowVolume`); there is no API to move bodies without the network smoothing. A host
  readout in the third test (both players in one car): the car moved exactly -200 m and kept driving (+10 m in
  the next second), so the server's car is not put back by a client; the stuck car did not happen that time.
  To measure (2026-11-15): debug menu "shift probe (all players)" (`ui/ShiftProbe.lua`, host toggle mirrored to every
  machine as `level.debug.shiftprobe`): each machine watches up to 80 bodies around its own player (NPC torsos,
  vehicles, dynamic first, then 20 static) and for 1.5 s after a shift shows per frame how many of each kind are at
  the old place / between / the new place, its own player, and how many already-arrived bodies snap (> 1 m beyond
  their velocity in one frame) or are flung (> 10 m/s faster than before). No API teleports a body or player
  without the network path (script_defs.lua: SetBodyTransform has no option; the MP docs say nothing about body
  sync), so the fix depends on what this shows: updates arriving over several frames (old and new mixed), positions
  sliding (between) or corrections after arriving (off). Positions are what scripts read, not render smoothing.
  Result (first probe, client driving, host riding along): host: everything in the shift frame. Client: counter
  +15 ms, its own player and car +37 ms, the ground body +262 ms, the other vehicles +295/+316 ms, the 46 dynamic
  bodies in batches until +429 ms; afterwards its car snapped up to 3.5 m (server corrections). No sliding. So a
  client's own car arrives ~225 ms before its ground (the ~1000 moved bodies reach it in batches) = the "thrown
  around". Tried and reverted (2026-11-15, user): holding a remote driver's car out of the shift until that machine
  reported the new world (moved 200 m later, up to 1.5 s). The car then sat 200 m from its ground in the HOST's
  physics and fell / flipped on both machines (host probe: snaps of 117-200 m). So the server simulates a client-
  driven car; it must move with the world in the shift tick. Don't retry a hold of player cars.
* Code-survey leads (2026-11-14), status: fixed and mock-tested, to re-test in local MP ([CHANGES](CHANGES.md) "MP fixes, second
  round"): perks (now the host's for everyone), debug menu (host-only, its per-machine settings mirrored), fuel-sale
  money (to the seller), cultist ambush (any player on foot), server bullets' gravity, permadeath (any player's
  death ends the run). Open: effects started only on the server (RPG
  rocket, GAZ doors, car radio, JetBus, convoy sirens: check in MP whether remote players see / hear them),
  per-bullet network traffic (measure with 2+ players).
  Code check (2026-11-15): those five use only PlaySound / PlayLoop / SpawnParticle / PointLight / SetLightEnabled in
  server callbacks (no Draw*, UI or camera reads; grenade.lua's second `server.tick` wraps the first on purpose, its
  DrawSprite / camera code belongs to the disabled spalling). The engine's own v2 scripts do the same (`robot.lua`:
  every sound incl. loops on the server, client only outlines; `mp/ammo.lua`: pickup sound in server.tick), so they
  most likely reach every player: one MP test decides it for all of them. Bullets: per shot a client sends
  `server.gunFire` (13 shell fields + sound path) and `server.gunSpawnCasing`; the server broadcasts
  `client.gunRemoteFire` (shotguns: one per pellet). The casing is a dynamic body spawned on the server and kept until
  RemoveRoad reaches it 250 m behind: every shot adds a body that is synced to everyone and moved by every world
  shift (the shift probe: a client's world arrives in batches, longer with more bodies).
  Casings now capped at the newest 60 ([CHANGES](CHANGES.md)).
* Healing doesn't work with God Mode off (user, MP test 2026-11-15; cause not found by reading: the meds write a
  negative `QueriedDamage` on the limb's local hitbox, the health script applies it unless God Mode, limb HP must
  be > 0 and < max). Debug "healing readout (all players)": the inventory's six limb triggers + the last med use
  (target trigger, its HP / bleed / fracture tags) and the health script's triggers + the last heal it received
  (amount, limb HP then / now, god, armored). A mismatch of trigger handles = the inventory writes to old triggers.
  Later the same day the user found healing working again (user's guess: something with toggling God Mode); not
  reproduced, cause unknown. The readout stays in the debug menu in case it comes back.
* Ambush NPCs on a non-host (user, MP test 2026-11-15, night ambush = cultists): the client saw them piled on the
  ground as if dead and didn't hear their guns; on the host they stood and shot. Causes not known. NPC gunshots are
  PlaySound calls in server code (`goreai_combat.lua`), like the open "server-only effects". Debug menu (host):
  "NPC sync readout (all players)" (`ui/NpcProbe.lua`: the 6 torsos nearest the host, server height vs this
  machine's, apart, speed, handle known here) and "server sound test (all players)" (a sound loaded and played by
  server code at every player, as the engine's robot.lua does). Test: `test_npcprobe.lua`.
  More from the user (same day): NPCs along the road look fine on the client; 10 spawned at once bounced on the
  client for a while, then settled. So only the ambush NPCs stay down. Ambush spawns differ in place (20-90 m from
  the target along and across the road, dropped from a 100 m raycast); same prefabs as road enemies. Not verified.
  Re-test (user, 2026-11-15 evening): "ambush now" + readout OK on both machines (10 torsos on each, server vs
  client height within 0.2 m, all standing, same handles) **[verified in-game]**; server sound test heard on the
  client, so server-side PlaySound reaches clients **[verified in-game]**. Not reproduced since; cause of the first
  report unknown. The readout and sound test stay in the debug menu.
* Buildings missing for non-hosts (user, post-release MP test with a friend 2026-11-16: "some cases where other
  players may not see a building the host sees"). Causes not known: buildings and roadblocks are spawned by server
  code only (`world/generation/RandomBuilding.lua`, synced like every server spawn), their prefabs have no scripts,
  and nothing else deletes them per machine. Lead, not verified: the spawner puts their bodies to sleep
  (`SetSpawnedEntitiesBodyNotActive`) and the world shift moves them with SetBodyTransform; whether a sleeping
  body's move reaches clients is unknown. Debug menu (host): "building sync readout (all players)"
  (`ui/BuildingProbe.lua`, test_buildprobe.lua): the last 8 buildings / roadblocks spawned, per machine: handle
  known here, apart from the server's place, voxels, body shapes, asleep. To test: when a building is missing for
  the non-host, both players read the line for it.
  First use (user screenshot 2026-11-16, ~2.85 km driven): a stretch of the road ahead missing for the non-host
  (flat ground there), the host had it. The listed buildings were all behind (deleted on the server), so the list
  couldn't say. Added the aim check: Ctrl+J on any machine (readout on) casts the camera ray there and on the
  server and compares the hits (NOT HERE / apart). Next test: the non-host aims at the gap and presses Ctrl+J.
  **Cause found (2026-11-17, MCP bridge two-window test, level scan):** pieces spawned around a world shift end up
  200 m off on the client (world body race); fixed by the shift re-sync, see [CHANGES](CHANGES.md) "Buildings / road
  missing for non-hosts". Still open after the fix: one 13,692-voxel static piece near x -107 sits ~40 m apart in z on
  the client, the same in two runs (not along the shift axis; not looked into).
* Local two-window MP test (MCP bridge, 2026-11-16/17): with default options the test windows closed 4 times in a
  row around 1 km of travel (no dump, no Windows event; host log just stops; free RAM down to ~300 MB at times). User:
  most likely the single PC's resources (never crashed with a friend on the published version). With "Reduce Number
  of Objects" on and "Segment Loading Pace" 3, two full 2 km runs (10 shifts each) ran without a crash.
* MP crash (user, 2026-11-15): "quite early" (~13 min into a session), a game window just closes; no Teardown
  crash dump (newest 02:45, the SP driving crash), both logs simply stop, no Windows application error / display
  reset at that time. Unknown. Two more the same evening (18:2x, testing NPCs / vehicle events, ~7 min in): the
  host window closed (client log: "Disconnect from host"), again no dump, no log error, no Windows event.
* Log errors seen in that session (not crashes): all files that never existed in the original mod (checked against
  9dde6dd), not reorganization misses. Fixed 2026-11-15 ([CHANGES](CHANGES.md) "Sounds pointing at files that never
  existed"; pistol and MK36 NPCs now audible). "Script not found:" (empty) follows the engine's "Single player script
  disabled: main.lua" in MP: the engine's own message. A static scan finds ~300 more broken literal `MOD/` paths,
  almost all in content that is never loaded (unused vehicles, boss scripts, dev levels); not fixed.
* Pause button primary slot shared with other mods; main menu for non-hosts; straggler teleport.
* Server-side particles/tracers reaching remote clients (sounds: verified 2026-11-15, see the ambush entry); `shared` nested tables on remote clients; entity
  handles sent client→server referring to the same entity (melee, PlaceTool, Weld, NPC controller).
* Per-player tools/hitboxes; a client's savegame (money, bounty) in MP; host player id (0 vs 1; routing works
  either way via `GoreAI_IsMe`).
* Vehicles: players in passenger seats and `floor` positions (and `stand`, unused so far); SteeringWheel.lua shape
  transforms reaching remote clients; NPC seat icons for non-hosts.
* AS350: a remote pilot's flight (aim sent every tick, server reads the pilot's keys), `SetBodyAngularVelocity` on a
  body jointed to the spinning rotor seen by remote clients, bullets/tracers per client, "Take a ride" commanded by a
  non-host, rocket homing on a non-host.

Known gaps:
* Camo variants of LoadTool guns not registered; scope zoom tweak disabled.
* Leftover scripts from non-segment spawns (NPC initializers, vehicles) accumulate ~20/km (no measured cost).
* KS23/N870 start a reload with 0 reserve ammo (v1 behaviour).
* Unverified for vox guns: whether gun melee (MakeHole at the stock) or a first bullet raycast can damage the
  engine-built tool body (only LoadTool parts are tagged `ml_toolpart unbreakable`).
* Seen once, cause unknown: Simonov-545 ADS tilted left after RPG use (fixed by re-equipping).
* AS350 windows stop bullets (user, 2026-11-13): the cabin glass is palette index 81 (MagicaVoxel glass look); by the
  engine's palette-index materials that is likely not glass. Same .vox as the original; not verified which material
  the engine reports. Not changed (would alter the original).
* Screens in MP (user, 2026-11-09; later, nice to have): `<screen>` scripts must be v1 ([ENGINE](ENGINE.md) "v2 engine rules") and the engine disables v1
  scripts in multiplayer, so all screens are dead in MP: Cadillac speedometer (`dash.lua`), tutorial TV (`tutMedTV.lua`),
  helicopter instruments (`vehicles/aircraft/AS350/screens/*`, `vehicles/aircraft/Boeing_CH47-C/screens/*`), `terrain/eastereggs/binge.lua`.
  To find: a v2 form for screen scripts (other callback names? a plain `draw` under `#version 2`?) or drawing them
  from a normal client script (UiGetScreen is screen-only).
* T-72 (user, 2026-11-09; to look at later, cause not investigated): heavy frame drops while it is driven (reported
  while its scripts were still v1). Candidates, none verified: Immersive_Tank.lua / MountedGun.lua (now v2), the many
  small body parts (wheels, ERA bricks, cage armour), track physics. Compare with the other tanks and with 9dde6dd.
* Players cannot switch seats in a vehicle (user, 2026-11-09). Which seat an entering player gets is the engine's
  choice (not investigated); rear seats, floor spots and tank deck riders may be reachable only that way. Mounted guns
  have their own way in (interact on the gun). A seat-switch control (e.g. a key cycling the free rigs with
  `SetPlayerRig`) would be our own addition: wanted later (user, 2026-11-09).
* Enemy AI driving (user, 2026-11-09; to improve later, cause not investigated): some vehicles are driven much worse
  than others: the AAF Jeep (VehicleAAF2) keeps driving in circles while it slowly closes in, the BRDM (VehicleD7)
  drives very long zig-zags; both take a long time to reach the player. Likely the driving code (`chaseOperator*.lua`,
  `ConvoyOperatorTransport.lua`: steering toward the target / obstacle rays) rather than the vehicles themselves.
  Not yet compared with v1 (original branch 9dde6dd). The refugee van's zig-zag ("Shelved and dead content") may be the same problem.

## History (summary)
* 2026-11-03: plan agreed; UMF replaced by `lib/TDSU/compat.lua`; tools started.
* 2026-11-04/05: guns (AK74 tool-prefab design after three attempts; all 38 converted, all verified except shelved
  ones), melee. Phase 1 (55 level scripts) done and verified 2026-11-06.
* 2026-11-06: Phase 2 (per-player health/inventory/hitboxes) verified. Phase 3: GoreNPCs, co-op road generation,
  enemy cars, props batch A, debug vehicle events.
* 2026-11-07, crash hunt: native engine crashes (worker-thread access violation) appeared with the GoreNPCs v2
  conversion. Ruled out by tests: missing script files, other mods, synced lists, server-side effects and sounds,
  co-op extras, path queries, tag churn, the whole update. Bisected to the NPC gun constraints in tick (tests A-N);
  moving Constrain* to server.update fixed it (no crash in any 5-20 km run since). The same runs found the long-run
  slowdown (NPC/table leaks, RemoveRoad pulse) and showed that many NPCs cost FPS exactly as in v1.
* 2026-11-07: tutorial, RPG rocket, main menu, NPC client view + controller, crew ragdolls, unlimited-ammo fix
  (all verified unless listed in "Open questions and known gaps"); horde converted then shelved; PlayerVehicleSeat retired; passenger seats
  moved to Phase 4.
* 2026-11-08: repo normalized to LF (separate commit before "phase 4"); Blender MCP + vehicle importer and seat
  mannequin; Phase 4 seats: Humvee, UAZ-452 (5), GAZ-24 (3); friendly NPCs ride in the seat rigs; scripted UAZ
  steering wheel; original-mod fixes (ambulance spawn entry, GAZ `vehicle` tag).
* 2026-11-09: seats for every drivable vehicle in use ([VEHICLES](VEHICLES.md) table); small vehicle scripts v2 (doors, Cadillac / LeBoat
  joints, semis' toggles, GAZ-24 EVF, JetBus).
* 2026-11-12: `vehicles/MountedGun.lua` (machine guns: DShK, M2, PKM); AVF's shell code ported (`port_avf.py`):
  ZU-23-2, BMP-1/1P/2/3; playtest fixes (sandstorms, Simonov-9 mags, loot table, med rotation).
* 2026-11-13: tanks (gunner place + driver fallback), launchers (Katyusha, WMIK MILAN), coax MGs and BMP ATGMs,
  Immersive_Tank.lua, AVF performance fixes; AS350 helicopter (vehicle with seats, v2 port, mouse-aim flight;
  rockets on RMB shelved); v1 survey of normal play → minivan helper, crew sitters, T-72A, GMG offroad, SPG-9
  technical, Kornet / AGS-30 tripods converted and verified SP (tripods as gun emplacements; AGS-30
  pitch shelved), AVF body pushes capped (freeze); docs tidied (dated logs → this summary and git).

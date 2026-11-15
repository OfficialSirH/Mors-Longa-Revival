# Mors Longa Revival — systems (how the port works)

Part of the technical reference (index and conventions: [TECHNICAL_REFERENCE.md](TECHNICAL_REFERENCE.md)).
Marks: **[verified in-game]**, **[official source]**, **[unverified]**.

Level entry points: `main.xml` (menu) → `levels/level.xml` / `levels/level_no_shadow.xml` → `levels/level_instance.xml`; scripts in
`levels/level_scripts.xml` (also `levels/level_scripts_spawn.xml`, `levels/level_tutorial.xml`, `levels/level_horde.xml`: keep the four in sync).
Libraries: `lib/TDSU/tdsu.lua` (+ `compat.lua`, which replaced UMF), `lib/Settings.lua`/`lib/Settings_Table.lua`
(`savegame.mod.settings` via `util.structured_table`, reads the registry live), `lib/Config.lua` (debug menu library;
level script `ui/ConfigMenu.lua`), `lib/Automatic.lua`.

## World generation (`world/generation/`)
* `GenerateRoad.lua` (server): the **furthest living player** drives generation, the world shift (~every 200 m,
  moves all players; vehicles by body) and the distance counter (`savegame.mod.distanceProgressed`, never decreases,
  not updated for 2 frames after a shift). `TeleportStragglers`: a living player > 150 m behind the leader for 3 s is
  put 8 m behind the leader (MP only). Each spawned segment's scripts are kept with its objects
  (`RegisterSegmentScripts` / `TickSegmentScripts`) and deleted once all those objects are gone.
* `RemoveRoad.lua` (server): deletes what is > 250 m behind the **rearmost** player, never a vehicle a player is in;
  latches the `level.roadgen` pulse, 4 passes/s, forgets deleted vehicles; no deletion when no player is found
  (v1-port bug that once deleted the whole start area).
* Spawners: RandomEnemy, RandomVehicleEnemy (+ debug "Vehicle Events"), RandomVehicle/Building/Loot/RoadSign,
  WaterMover (nearest player), randomloot (crate prompt per player). Enemy/convoy cars: `chaseOperator*.lua`,
  `ConvoyOperatorTransport.lua` (server, target = nearest living player; helpers `vehicles/operators/vehicleOperatorCoop.lua`).
* Playable world is ~400 m long (shadow volume 400x25x200), which is why the shift and the straggler limits exist.
  No API moves the world origin, boundary or shadow volume (`GetBoundaryBounds` / `IsPointInBoundaries` only read;
  both are fixed in the level XML), so the shift stays; official maps use shadow volumes up to ~4.2 M m³ (ours 2 M).
  Mods have no threads (every script runs on the main thread; coroutines only spread work), and `Spawn()` builds a
  prefab in one frame.
* Debug-menu spawning switches (original-mod bug, same in 9dde6dd; rewired 2026-11-14, user OK): "spawn loot" was
  read by nothing, and "spawn roadblocks" switched off the loot spawner (`RandomLoot.lua`) and the timed enemy
  vehicle events (`RandomVehicleEnemy.lua`); the roadblock spawner it was named after (`RandomRoadBLock.lua`) is
  still v1 and only in the dev test levels. Now "spawn loot" = RandomLoot, "spawn enemy vehicle events" =
  RandomVehicleEnemy (key `spawn_vehicle_events`). All switches are read every frame (no restart needed).
* Cleanup now deletes triggers 250 m behind the rearmost player (2026-11-15). v1's RemoveRoad read a trigger's
  position with GetShapeWorldTransform (a shape call), so triggers were never deleted, and the scripts of deleted
  segments that own a trigger stayed alive (GenerateRoad removes a segment's scripts once none of its objects is
  left). Only things far behind are affected.
* `fix_missing_scripts.py` repointed 76 XML references to never-existing scripts to `missing_script_stub.lua`.
  Leftover log noise: `<instance file="MOD"/>` (empty) in RoadSegment1237/4/5.xml ("Could not find prefab");
  "Script not found: data" (source unknown).
* Operators' v1 `queueRemoval()` (pause-menu-button trick to find its own script) cannot work on the server: those
  scripts set a finished flag and idle instead (`OpFinished`, initializers, heli smoke; Immersive_Tank's port
  dropped it).

Performance work on generation, cleanup and NPCs: [PERFORMANCE.md](PERFORMANCE.md).

## NPCs (GoreNPCs)
* One manager script `npcs/GoreNPCs/scripts/goreai_main.lua` (spawned once by the first of 152 NPC prefabs'
  `goreai_initializer.lua`, tagged `nodelete`). AI on the **server**; Constrain* (gun pointing/holding) in
  server.update. Each NPC's target = nearest living player it can see (`systems/goreai_players.lua`: `GoreP`,
  `PlayerPos` set per NPC; NPC bullets check every player's hitboxes).
* Shooter routing: hitmarkers (`client.goreHit`, hidden on hardcore by design), killcam (`client.goreKillcam`, slow
  motion only with one player), bounty board (`client.goreBounty`, killer's savegame), punch shock
  (`client.goreAddShock`) go to that player only (`GoreAI_ClientCall`, never 0).
* Client view (`systems/goreai_netview.lua`): the server publishes `shared.goreNpcs[id]` (≤10 Hz, on change):
  bosses + controlled NPCs always, all NPCs + debug fields while the host's Debug Mode (`config.db`) is on. Each
  client rebuilds `NPCs` as proxies, so the v1 draw code (boss health bars, debug overlays) runs unchanged.
  `level.goreai.api.npcs.alive/dead` (synced) feeds Thermals.
* "Control an NPC" (`systems/goreai_controller.lua`, debug menu): any player, one per NPC; client picks/aims/sends
  keys (`server.goreControlStart/Input/Stop`), server drives the NPC, freezes + hides the player; Ctrl+X exits.
* Explosion damage: engine `explosion` events; shield absorbs first, the rest hurts health ([CHANGES](CHANGES.md)).
* Riding along (`systems/goreai_sitting.lua`, hand-written, test_sitting.lua): friendly NPCs sit in the passenger
  seat rigs of their player's vehicle (driver rig never). Players come first: NPCs skip seats in `GetPlayerRig`;
  an NPC whose seat a player takes moves to the next free seat or gets out; `floor` rigs are skipped. The sit pose
  copies the player's (2026-11-08, user's idea; Blender with both models): `get_seat_body_transform` is the engine's
  seated-player frame (pelvis on the seat point, seat rotation eased toward upright by up.y^2 about a pivot 0.8 m
  above the animator root, player_locomotion.lua); the head goes 0.65 m above and 0.1 m behind the pelvis in that
  frame. On every seat checked in-game as good (Humvee, UAZ, GAZ rear, SUV: all upright) the old upright rule
  equals this, i.e. merc hips = player pelvis + (0, 0.05, 0.1) in the player's frame. With an `ik_head` location
  the engine IKs the player's spine (`SetAnimatorTransformIK(animator, "stomach", "head", ik_head)`) so the head
  reaches it: on official reclined seats (rot x 70-80) the player looks nearly upright in-game. The merc then leans
  about its hips toward ik_head + (0, -0.15, -0.05) (rig frame; maps our layouts' ik_head 0.8 up / 0.15 back onto
  the checked upright pose): upright on our layouts (GAZ front too), ~7 deg saloon, ~27 deg sports car (player
  spine in Blender: 19 / 31 deg; the merc stays ~10 deg more upright, as on the checked seats). No ik_head: the
  whole body leans with the eased seat rotation like the player's. `npc_sitting_pose`: head, torso and arms lean;
  the legs keep the sit pose from the same hip, upright with the vehicle, tilted up just enough to point the feet
  at the rig's ik_foot points (max 60 deg; sports car ~56, hips at floor level). Upright: plain sit pose. Rejected
  (in-game 2026-11-08): upright on the official seat point (merc in the footwell), the full seat tilt (GAZ 55:
  too far back), the engine's eased root lean without the head IK (78/62 deg in sports car/saloon: far too far
  back, the player barely leans). Server publishes `shared.goreSeats[tostring(rig)]` (NPC
  seats) and `shared.goreSeatsShow` (a friendly NPC exists); clients draw the seat icons from that. Verified in SP
  (Humvee, UAZ, GAZ, SUV, saloon, sports car).
* Not ported: projectile-impact debug dots (server hit list), gore test map spectator cameras, debug `n`
  (navigate to crosshair).
* Leak fixes: dead NPCs leave the table, NPCS_TO_DELETE emptied, spall shells emptied (`tick_cleanup_leaks`),
  initializers stop when their torso is gone.
* Performance: ~30 NPCs at once ≈ 18 FPS (512 active bodies), same as v1; possible later optimization.
* Other NPC scripts: SleepingRagdoll (wakes for any player), StandingRagdoll (shop trader; looks at the nearest
  player; killing it halves the nearest player's money), `fakegore.lua` crew stand-ins in vehicles / helicopters and
  the limp sitters they turn into (`vehicles/aircraft/AS350/Gore Ragdolls 2/scripts/gorefunctions.lua`, v2 2026-11-13,
  test_sitter.lua: ragdoll logic on the server, bleeding particles from `shared.bl<body>` on the clients; P and the
  kill-all key for any player; verified SP).
* Converted by `tools/porting/history/convert_goreai.py` (base 6c28435, frozen; also gunfunctions.lua,
  Melee_Functions.lua and AdvancedHealthScript.lua edits); hand-written: goreai_main, killcam, players, netview,
  controller, sitting.

## Player: health, inventory, hitboxes (Phase 2 design, verified)
* Health (`player/HealthSystem/AdvancedHealthScript.lua`) and inventory (`player/inventory.lua`) run on each player's
  **client**. The server does world ops only: pickups (`server.invTake`, first request wins), drops, tool enabling
  (per player: enable-all setting OR always-allowed list OR wanted by that player's inventory; covers ListKeys ∪
  requested ids, since melee ids are not in ListKeys), `SetPlayerHealth`, walking speed (re-applied every tick).
* `player/PlayerHitboxes.lua` (server): the host keeps the level's six `hitbox` triggers, other players get a
  spawned set (`hitbox_player=<id>`); `QueriedDamage` → `client.hitboxDamage`; health uses local `localhitbox`
  triggers. Death: one death request + one ragdoll (`server.healthDied`), death camera `launchragdoll.lua` (client).
  Because SetPlayerHealth is a ServerCall, the client keeps a "dying" state (no reheal until the engine health
  reached 0 and came back; resend after 2 s) — without it a ragdoll spawned every tick.
* Gun scripts are static; ToolManager.lua is a no-op (tool enabling is in inventory's server.tick).
* Money and the bounty board are per player (client savegame); perks, garage, difficulty and the debug-menu
  settings are the host's (perks and settings copied to every machine by `game/newLeveltoLEVEL.lua`).

## Menu, tutorial, debug menu
* Main menu (`main.xml`, `patches/convert_menu.py`): client UI; level starts are host-only through
  `MenuStartLevel` → `server.startLevel` (`ui/MainMenu/menu_host.lua`); others see greyed buttons.
  `menu_main.lua` is a library (entry `main_menu.lua`; also included by `ingame_settings.lua`). Character select
  camera is per client; `RotateScene.lua` hides all players. Tab on the main menu = dev level list.
* Tutorial (`game/Tutorial/`): per-player tips/hurt warning/inventory reset on the client; triggers, holes and
  the ending on the server (`shared.ending`). `tutMedTV.lua` (screen script) stays v1.
* Debug menu (Backspace; `lib/Config.lua`): Debug Mode, Gore NPCs debug overlays, NPC Controller, Vehicle Events
  (Hostile Car, Military, Refugees, "Refugee Van" = the refugee event with VehicleC3, added 2026-11-08 for the
  shelved van work, [STATUS](STATUS.md) "Shelved and dead content", Helicopter),
  Auto Travel (1/5/10/20 km at 40 m/s, `server.configTravel`), Infinite Ammo, spawn menu (`Weapons → Testing`
  holds items only dev/levels/test.xml had). Pause menu: one primary button "MorsLonga Menu".
* Spawn menu (`ui/SpawnMenu.lua`) lists only what is in the loot tables `world/generation/SpawnRefrenceTable.lua`
  (`spawnables.loots`; menu-only category `debugTest`); spawns go through `server.spawnMenuSpawn` with a per-player
  undo history. Debug-menu spawns: `ConfigSpawn` → `server.configSpawn`.

## Other converted systems (all v2, verified unless noted)
* Shop segment: SafeZone, PerkMachine (client pays, `server.perkBuy`, refunds), ParkingSpot garage (one shared garage
  in the host's savegame, `shared.garage`), WarehouseScript_Cultist, AC130 supply plane.
* RPG rocket `weapons/guns/grenade.lua` (server): impact ray from the previous position (close-range hits), explodes at
  the hit point, proximity fuse for any player, loaded rocket type via `server.rpgNextRocket` (sizes: PG-7V 0.6,
  OG-7V 1.0, PG-7VT 1.0, PG-7VA 2.0).
* World props (convert_props.py): debris, parachute, warehouse collapse, Binge shrine, heli crash smoke, crew
  ragdolls (batch D). Grenades, PlaceTool, Weld, meds, Airstrike, daynight/sandstorm, Fuel,
  ShootFromCar, CarAlarm, Thermals/NVGs, mines, doors, Book, SpawnMenu: Phase 1.

# Mors Longa Revival — vehicles

Part of the technical reference (index and conventions: [TECHNICAL_REFERENCE.md](TECHNICAL_REFERENCE.md)).
Marks: **[verified in-game]**, **[official source]**, **[unverified]**.

## Engine facts
* [official source] Seats are `<rig>` blocks (92 of 96 official vehicles), children of `<vehicle>` (or of a body), in
  that parent's coordinates. A rig may have `pos` and `rot` (turns the whole seat).
  ```xml
  <rig name="driver" tags="driver sort=0">
      <location name="seat" tags="seat" pos="-0.65 1.5 -2.85"/>   <!-- pelvis point, ~5 cm above the cushion -->
      <location name="steeringwheel" tags="steeringwheel" .../> <location tags="ik_hand_l" .../> (ik_hand_r, ik_foot_l/r, ik_head)
  </rig>
  <rig name="passenger" tags="sort=1" pos="1.3 0 0">              <!-- up to sort=4 -->
      <location name="seat" tags="seat" pos="-0.65 1.5 -2.85"/>
  </rig>
  ```
  The old `<location tags="player"/>` stays (fallback without rigs: the AVF tripods seat the player there).
  `<location tags="exit">` in the main body = where a player leaving is put (combine harvester, gelato truck,
  boats; most official vehicles have none; AS350: without one the player came out on top of the rotor).
* [official source: `data/script/player_locomotion.lua`] Posing a seated player: `GetPlayerRig(p)` is the rig the
  player sits in (`HasTag(rig, "driver")`). Pelvis on the `seat` location, body rotated by its `rot`; a tilted seat
  (rot x) is eased back toward upright by weight cos²(tilt) about a point 0.8 m above the animator root: rot x 50 →
  ~29° recline, 55 → ~37°, 60 → ~45° [verified in-game: Humvee at 60 leaned through the backrest, GAZ at 55 fits].
  A `stand` location instead of `seat` = standing, feet there (official vehicles: drivers only; passengers
  [unverified]). Hands follow `ik_hand_*`; while steering they turn by `-GetVehicleSteering(v) × 180°` about the
  `steeringwheel` location's local z.
* [verified in-game] Rigs are entities: `GetEntityChildren(vehicle, "", true, "rig")`,
  `GetRigLocationWorldTransform(rig, name)` (nil if missing).
* [verified in-game, UAZ] Teardown applies a `.vox` scene node's rotation (MagicaVoxel nTRN `_r`) to
  `object="..."` models, including in a shape's local transform. The UAZ body and steering wheel are turned inside
  their .vox; official vehicle vox files have no node rotations, the Humvee only on its wheels.
* API: `GetVehicleAvailableSeatPos`, `GetVehiclePassengerCount(v)` → `count, seats, hasDriver`,
  `IsPlayerVehicleDriver/Passenger(v, p)`, `SetPlayerVehicle(v, p)` / `DriveVehicle` (server), `GetVehicleSteering(v)`
  (-1..1). `SetVehicleHealth` needs the `customhealth` tag.

## Seat placement rules (learned in-game)
* Seat point ~5 cm above the cushion and ~0.25 m in front of an upright backrest, rot 0 (Humvee: 0.05 m with rot 60
  put the back through the backrest). Centre it on the cushion, not on the steering wheel (5 cm off was visible).
* Driver hands at 9 and 3 o'clock on the wheel rim, ~0.2-0.3 m ahead of and ~0.25-0.3 m above the seat point; at
  0.43 m ahead (UAZ test 1) the arms fell short.
* Low cars: tilt the seat so the head clears the roof (GAZ front 55); reclining moves the head back, so it does not
  help under a roof that slopes down behind the seat (GAZ rear: upright, head ~0.1 m through, user: keep).
* Seatless vehicles (user decision 2026-11-08, "sit cab, stand cargo"): cab seats at normal height on no visible
  seat; cargo players stand where the headroom allows, otherwise sit on the floor facing inward (rig tag `floor`,
  rig `rot` = facing). UAZ cargo: 1.3 m headroom → floor.
* NPC riders use the same rigs except `floor` ones and sit like the player: the engine's seated pose (pelvis on the
  seat point) plus a fixed offset, leaning toward the rig's `ik_head` (where the engine IKs the player's head),
  legs toward the rig's foot points ([SYSTEMS](SYSTEMS.md) "NPCs (GoreNPCs)"). Nothing per seat for NPCs; every rig needs `ik_head` for a natural pose.
* Copies of Teardown 1.x vehicles take the official 2.x rigs (below); other mod vehicles are measured. Variants usually share the layout, sometimes shifted (UAZ modified +0.2 m, white +0.6/+0.2,
  emergency +0.1/+0.1).

## Workflow and tools
* Blender ([ENGINE](ENGINE.md) "Workflow") + `tools/porting/blender_vehicle.py`: import (vox node rotations applied), `show_only`,
  `cutaway(root, y)`, `heightmap(...)`, `ray(...)`, `mannequins(root)` (the official player character seated on each
  rig, arms/legs by IK, spine IK to `ik_head` like the engine, engine tilt rule). Mannequin calibration on the verified UAZ: reach, backrest and legroom
  match the game; its head is ~0.15 m higher than in-game. Its knees bent backward until 2026-11-08 (leg IK pole
  angle; fixed, toes now follow the feet): seat layouts didn't depend on it (backrest, head, hands, feet). `merc(root, rig)`: the Friendly Merc ragdoll
  (Ragdollsecurity2.xml) posed exactly as goreai_sitting.lua + npc_pose_ragdoll do (Python copies `npc_head`,
  `npc_pose`, `player_seat`), to compare merc and player on the same seat.
* Measure → layout in `tools/porting/add_seats.py` (`driver`, `passenger(yaw, legroom, floor)`,
  `shifted`) → `add_seats.py --replace` (patches the prefab and every embedded `instance=` copy) → mannequin check →
  user test.
* Copies of Teardown 1.x vehicles (sportscar, SUV, saloon, boxtruck, dumptruck, crane, tractor, ...): the
  official 2.x prefab in `data/built-in/prefab/vehicle/land/` uses a reworked version of the same model and has rigs
  (children of `<body>`, body space). `official("<prefab>.xml", shift=...)` in add_seats.py copies them, placed by
  the mod vehicle's own `<body pos>`. Finding the pair and shift: compare the body model's voxels in body space
  (voxel overlap 0.6-0.99; best shift 0-0.1 m). Check: rays from each seat point (cushion, backrest, roof, dash,
  walls) and mannequin head height in the mod vehicle vs the official one; sportscar, SUV and saloon came out equal
  within one voxel. Official seat points of reclined seats (rot x 70-80) lie in front of the cushion or even on the
  floor (the engine lays the player back from there): an upright merc there sat in the footwell (in-game 2026-11-08:
  sports car far forward, saloon a bit), which led to NPCs copying the player's pose ([SYSTEMS](SYSTEMS.md) "NPCs (GoreNPCs)").
  Also added: box truck (`boxtruck_white`; mod cushion 0.1 lower and backrest 0.1 further back, so `seat=(0, -0.2,
  0.1)` moves only the seat point to the official cushion/backrest relation), dump truck (`dumptruck_yellow`, shift z
  +0.1, identical seat rays), mobile crane (`crane_medium_yellow`, driver only, identical), Blue/Red tractor
  (`tractor_teal`, driver only; seat area one voxel different). Official rigs may be children of `<vehicle>`
  (vehicle space) instead of `<body>`; `official()` handles both. Tractor From Hell: different body (overlap 0.25),
  measure. Yellow Van (`van_yellow`, overlap 0.48, same cab/backrest/roof; cushion 0.2 higher: `seat=(0, 0.2, 0)`;
  Van Modified: PKM stand instead of the passenger seat, `keep=` driver only until the mounted-gun work). Weak matches
  (overlap ≤0.5: measure instead): cement truck, microcar, military truck, small excavator, pink sportscar.
  Station wagon: `generic_stationwagon_blue_dark` (overlap 0.68; the yellow one is a different model), seat rays
  and NPC head-to-roof distance identical; damaged: same rigs (looked 0.1 m off before the importer cropped).
  No official counterpart (best overlap ≤0.41, measured by hand): bus, semitrucks, minivan, Cadillacs, Mini,
  Beetle, Plymouth, Dodge Monaco. Hand-measured upright seats follow the UAZ rule: seat point 0.05 above the
  cushion, 0.25 in front of the backrest face; low cars with a roof at ~1.35 (GAZ-24, Cadillacs, Mini, Beetle, Plymouth, Dodge) use tilt 55; NPC heads still poke through
  the roof a little (user: acceptable in small cars, 2026-11-08). Stripped "Modified"/abandoned variants: driver
  where a seat is left, others on the floor.
  `on_body(layout, body_pos)` reuses a layout on variants with the same model at another `<body pos>`.
  Standing drivers (`driver_standing`): a rig with a `stand` location instead of `seat` gets the engine's standing
  pose (data/script/player_locomotion.lua; official boats use it); used for LeBoat's helm.
  Event crews (all events, v1 design): the riders are `fakegore.lua` stand-ins (posed sitting ragdolls, heads turn);
  when the vehicle stops within 10 m of a player the operator script deletes them one by one and spawns live NPCs at
  `locationspawn` (refugees: `enemies/refugees/Ragdollrefugee1.xml`, path fixed [CHANGES](CHANGES.md)); shot stand-ins become limp sitters.
  Triggers differ (v1 design, kept by user decision 2026-11-08): ambushes (`chaseOperatorTransport.lua`) unload within
  25 m of a player or once the driver is gone; refugee vehicles (`ConvoyOperatorTransport.lua`, debug "Refugees") drive
  along the road past the player and only unload after the driver stand-in is shot, the vehicle has slowed below
  2 m/s and a player on foot is within 10 m.
  Enemy and event vehicles (`prefabs/spawnables/enemy vehicles/`) get seats too: once their crew is dead the operator
  scripts remove `nodrive` and players can drive them (first skipped as "NPC vehicles", corrected 2026-11-08). Their
  crews are voxel ragdolls sitting in the seats: hide them before ray checks. VehicleC3 (refugee UAZ event) asks
  an older `uaz452.vox` (objects `body`, `door fl`...): its van was invisible in-game; rebuilt and seated ([CHANGES](CHANGES.md)).
  Scan prop parts too, not just the body: the Pursuit Special's passenger seat is part of its left door model
  (user spotted it in-game; the body-only scan had missed it).
  Cadillac Eldorado (`cadillace80`, `abandonedeldorado`): .vox paths don't exist, used nowhere: skipped.
  Also skipped, referenced nowhere outside their own folder (no spawn menu entry, spawner or level; found 2026-11-08):
  ambulance-eu/-us, steamroller, sportcar_pink, zapper `8x8 dumptruck`/`tanker`, Terminator (4), MethLab Enemy;
  only in the test level `dev/levels/test_vehicle.xml`: backhoe, bulldozer, skid-loader, small_excavator. Dirt bikes (`vehicles/cars/Bike`): only
  in dev/levels/test.xml. Volga black/blue/taxi
  (`vehicles/cars/Gaz24`) and `k-cl-e-car1-w`: referenced nowhere either; also `Based vehicles/cars/wheelchair.xml`.
  Insurgent chase cars (`vehicles/cars/Enemy Car`): Coupe, Sadan, Sport2 and "Pickup Enemy With Crew" referenced nowhere.
  Empty voxel layers (2026-11-08): the engine drops empty voxel layers on every side of a shape; x and depth are
  then centred on the cropped size. Found on the Jeep (3 empty layers underneath: seats measured on the full model
  sat 0.3 m too high in-game, 0.3 lower was right; its v1 eye point fits only then) and the ZIL-131 (38 empty layers
  at one end: only cropped does the cab line up with its own steering wheel and v1 eye point, 1.9 m off otherwise).
  blender_vehicle.py crops (`crop_model`). Corrections that followed: Mini and Dodge 0.1 lower; Highway Police
  Dodge = civilian seats (its "0.1 further back" backrests were an empty layer); abandoned sedan 0.1 forward; sports
  car `shift` -0.1 → 0 (its official body has an empty layer at the back, the mod's doesn't); damaged station wagon
  `shift` 0.1 → 0. Unchanged: tractors (same layers as the official model), Ural, fire truck, all others.
  Buses (2026-11-08): only 4 of the many seats get rigs (≤4 players); the front rows, so NPC passengers sit near the
  driver. Bus: the left front passenger's knees touch the driver's partition (0.45 m ahead); PAZ: a grab pole
  between the right-hand places, so that passenger takes the window place.

## Status (passenger seats)
| Vehicle | Files | Players | Status |
|---|---|---|---|
| Humvee (plain, open) | `vehicles/avf/prefabs/humvee/umhummer.xml`, `umhummeropen.xml` + embedded copies in Vehiclewg30, RoadSegmentM7, level_tutorial | 4 | verified SP |
| "Hummer UM" (spawn menu) | `vehicles/cars/humvee/hummer.xml` (other `vehicles/cars/humvee` files point at a missing `vehicles/cars/AvertCars/` folder, unused) | 4 | Humvee layout 0.05 higher (identical seat rays); verified SP |
| UAZ-452 (normal, damaged, lifted, white, emergency) | `vehicles/cars/Soviet Vehicles/uaz452*.xml` | 4; emergency 3 (stretcher) | verified SP |
| GAZ-24 (sedan, VIP, MP) | `vehicles/cars/GAZ-24 (1968)/gaz24unreleased*.xml` | 4 | verified SP |
| Sports car (green, damaged, offroad, RampCar) | `vehicles/cars/sportscar/sportcar_green*.xml`, `RampCar.xml` + copy in constructionCivillian12 | 2 | official rigs (`sportscar_green`); verified SP; shift -0.1 → 0 afterwards (cropping) |
| Yellow SUV (normal, damaged) | `vehicles/cars/SUV/suv_yellow*.xml` | 4 | official rigs (`generic_blue_light`); verified SP |
| Saloon (red, taxi, damaged) | `vehicles/cars/saloon/salooncar_*.xml` | 4 | official rigs (`generic_sedan_red`); verified SP |
| Box/Ramp Truck (+ damaged) | `vehicles/cars/truck/truck_{white,ramp}*.xml` | 2 | official rigs (`boxtruck_white`, seat point moved); verified SP |
| Yellow Dump Truck (+ damaged) | `vehicles/cars/dumptruck/Dump_truck*.xml` | 2 | official rigs (`dumptruck_yellow`); verified SP |
| Mobile crane | `vehicles/cars/Constuction vehicles/mobile_crane.xml` (spawn menu entry added, [CHANGES](CHANGES.md)) | 1 | official rig (`crane_medium_yellow`); verified SP |
| Blue/Red Tractor | `vehicles/cars/Constuction vehicles/{Blue,Red}tractor.xml` | 1 | official rig (`tractor_teal`); verified SP |
| Yellow Van (+ damaged, Modified) | `vehicles/cars/van1_yellow/Van*.xml` | 2; Modified 1 (gun stand) | official rigs (`van_yellow`, seat point raised 0.2); verified SP |
| Station wagon (+ damaged) | `vehicles/cars/stationwagon/station_wagon_brown*.xml` (Destroyed: static wreck) | 4 | official rigs (`generic_stationwagon_blue_dark`); verified SP; damaged shift 0.1 → 0 afterwards (cropping) |
| Minivan | `vehicles/cars/minivan1/minivan1.xml` | 4 | measured (front seats + rear bench, upright); verified SP |
| Cadillac sedan (+ damaged, abandoned) | `vehicles/cars/cadillacsd80/*.xml` | 4 (abandoned: 2 + 2 floor; 0.1 forward afterwards, cropping) | measured, tilt 55; verified SP (heads poke through the roof a little, accepted) |
| Cadillac limo (+ damaged, abandoned) | `vehicles/cars/cadillacfbl80/*.xml` | 4: front + rear bench (abandoned: rear floor) | measured, tilt 55; verified SP (heads poke through the roof a little, accepted) |
| Mini (+ damaged, Modified) | `vehicles/cars/1969 Mini Cooper S/Mini*.xml` | 4 (Modified: driver + 3 floor) | measured, right-hand drive, tilt 55; verified SP; lowered 0.1 afterwards (empty layer) |
| VW Beetle (+ damaged, Modified) | `vehicles/cars/1963 VW Beetle/*.xml` | 4 (Modified: driver + 2 floor) | measured, tilt 55; verified SP |
| Plymouth Fury (+ damaged, Modified) | `vehicles/cars/Plymouth Fury/*.xml` | 4 | measured, tilt 55; verified SP |
| Dodge Monaco + Highway Police (+ damaged) | `vehicles/cars/1974 Dodge Moncaco/*.xml` | 4 | measured, tilt 55; verified SP; afterwards 0.1 lower and police = civilian seats (cropping) |
| Jeep Wrangler ("Officer's Jeep", + damaged) | `vehicles/cars/Jeep Wrangler/*.xml` (Willys Jeep folder: static wreck only) | 4 | measured, upright (open top), 0.3 lower for the empty layers (test 1: far above the seats); verified SP |
| Ural ("SU Transport Truck", + damaged) | `vehicles/cars/ural/ural*.xml` | 4: cab 2 + cargo side benches 2 (facing inward) | measured, upright; verified SP |
| ZIL-131 fire truck ("Firetruck") | `vehicles/cars/Soviet Vehicles/zil131fire.xml` | 4: crew cab, 2 rows | measured, upright; verified SP |
| ZIL-131 transport ("AAF Transport truck") | `vehicles/cars/Soviet Vehicles/ZIL131.xml` (+ Vehiclewg33, roadblock9) | 4: cab 2 + cargo side benches 2 | measured, upright; paths fixed ([CHANGES](CHANGES.md)); verified SP |
| ZIL-131 ZU-23 ("AAF Truck Technical") | `vehicles/cars/Soviet Vehicles/ZIL131_ZSU23.xml` | 2 (cab; gunner with the mounted-gun work) | as ZIL131; verified SP |
| Bus (+ damaged, Modified, JetBus) | `vehicles/cars/bus/bus*.xml`, `jetbus.xml` (Destroyed: static wreck) | 4: driver + front rows (one rear-facing); Modified: driver + 3 floor; JetBus: driver + 2 on the wheel arches (engine fills the cabin) | measured, upright; verified SP |
| PAZ-3205 ("Soviet Bus", + damaged) | `vehicles/cars/Soviet Vehicles/paz 3205*.xml` (+ event copy VehicleC2, see the enemy row) | 4 | measured, upright; verified SP |
| American semi (+ damaged, Modified, Special) | `vehicles/cars/semitruck-us/Semi*.xml` (Destroyed: static wreck) | 4: cab 2 + 2 on the lower sleeper bunk (facing the middle) | measured, upright; verified SP |
| Flathead semi (+ damaged, Mod) | `vehicles/cars/semitruck-flathead/Semi*.xml` (spawn menu "Semi Flathead" added, [CHANGES](CHANGES.md)) | 2 (no room for more: engine hump, bunks 0.7 m apart) | measured, upright; verified SP |
| SportsCar offroad | `vehicles/cars/sportscar/sportsoffroad.xml` + copy in constructionCivillian12 | 2 | official rigs (`sportscar_green`, overlap 0.78); verified SP |
| Cement truck | `vehicles/cars/Constuction vehicles/cement_truck.xml` (road spawner Vehiclewg42; spawn menu "Cement Truck" added, [CHANGES](CHANGES.md)) | 2 | measured, upright; verified SP |
| Tractor From Hell ("TRACTOR") | `vehicles/cars/Constuction vehicles/tractorFromHell.xml` | 1 (like the official tractor) | measured, upright; verified SP |
| Volga (white) | `vehicles/cars/Gaz24/volgawhite.xml` (road spawner Vehiclewg18; spawn menu "Volga" added, [CHANGES](CHANGES.md); Destroyed: wrecks) | 4 | measured, tilt 55; verified SP |
| Microcar (+ damaged) | `vehicles/cars/microcar/microcar*.xml` (road spawners Vehiclewg38, wb30; spawn menu "Microcar" added, [CHANGES](CHANGES.md)) | 2 | measured, tilt 55; verified SP |
| Monster Compact | `vehicles/cars/microcar/monstercompact.xml` | 4 (rear cramped) | measured, tilt 55; verified SP |
| Ford Falcon XB GT (+ damaged) | `vehicles/cars/MadMax2/1973 Ford Falcon XB GT*.xml` (road spawners Vehiclewg21, wb19; spawn menu "Ford Falcon" added, [CHANGES](CHANGES.md); Destroyed: wreck) | 4 (right-hand drive; rear cramped) | measured, tilt 55; verified SP |
| Pursuit Special | `vehicles/cars/MadMax2/Pursuit Special.xml` | 4: driver, a sideways seat on the left door (ledge + door panel, faces the driver; user spotted it in-game), 2 on the rear floor | measured; verified SP |
| Military truck (UM Damaged; plain, Damaged) | `vehicles/cars/military_truck/Milltary_Truck*.xml` (UM Damaged in roadblocks 8/9; plain one now spawn menu "Military Truck", [CHANGES](CHANGES.md); Destroyed: wrecks) | 4: cab 2 + 2 on the cargo bed floor (no benches) | measured, upright; verified SP |
| RV MethLab ("Bad RV") | `vehicles/cars/RVMethLab/MethLab.xml` (road spawner Vehiclewg26; spawn menu path fixed, [CHANGES](CHANGES.md); MethLab Enemy: unused) | 4: cab 2 + 2 on the rear bench (facing the aisle) | measured, upright; verified SP |
| BugZilla ("Monster Bug") | `vehicles/cars/1963 VW Beetle BugZilla/BugZilla.xml` (Destroyed: wreck) | 3: driver + 2 floor (stripped; engine/fuel tank in the back) | measured, tilt 55; verified SP |
| Golf cart + "Nuclear Golfcart" | `vehicles/cars/Based Vehicles/golf_cart*.xml` (road spawner Vehiclewg45; Bomb in the spawn menu) | 2 | measured, upright (wheel far ahead: arms stretched); verified SP |
| Small red boat | `vehicles/cars/Based Vehicles/smallboat_red.xml` (road spawner vehicleS13; spawn menu "Small Boat" added, [CHANGES](CHANGES.md)) | 4: stern (driver, no steering wheel), middle seat 2, bow 1 facing back | measured, upright; verified SP |
| "Shed?" + Garage | `vehicles/cars/Based Vehicles/SHED.xml`, `GARAGE.xml` (vehicleS11/S12; Garage copy in dev/levels/test.xml) | 4: driver on the chair + 3 on the floor | measured, upright; verified SP |
| Wheeled Cockpit | `vehicles/cars/Based Vehicles/wheeledcockpit.xml` (spawn menu; vehicleS10) | 2 (pilot + copilot; no yoke in the model) | measured, upright; verified SP |
| AS350 helicopter: AAF Attack Heli (MILITARY), Insurgent Attack Heli, parked copies, CIV (gore map), VIP | `vehicles/aircraft/AS350/AS350_*.xml` (+ 2 copies in dev/levels/test_misc.xml). Not a vehicle in the original (Heli.lua teleported the pilot every frame): add_seats.py `WRAP_VEHICLE` wraps the Heli.lua `<script>` content in `<vehicle name="AS350" tags="player_nogears player_nosteeringwheel" sound="0" topspeed="0" acceleration="0">` (no car sounds or driving animations) and `VEHICLE_EXITS` adds an `exit` location beside the pilot door | 4: pilot left front (the AI pilot ragdoll sits right) + 3 on the rear bench; Insurgent: no left front cushion (open door-gun side), third bench place 0.1 lower | measured, upright, nose at body +z (rigs turned 180); verified SP 2026-11-13 |
| LeBoat (sailboat) | `vehicles/cars/Based Vehicles/sailboat.xml` (spawn menu; vehicleS14) | 4: driver standing at the left ship's wheel (user request; first version sat between the two wheels) + 3 on the side benches | measured; verified SP |
| Enemy/event copies: AAF Truck (VehicleAAF1, ZIL-131), Civillian Jeep (VehicleC1, Jeep), Civillian Bus (VehicleC2, PAZ), Insurgent Ambush 8 (VehicleD8, Ural) | `prefabs/spawnables/enemy vehicles/Vehicle{AAF1,C1,C2,D8}.xml` (inline copies) | as their models | those models' layouts (AAF1, C1 shifted 0.05-0.1 m); seat rays identical with the crew hidden; awaiting test |
| Insurgent chase cars: pickup, SUV, sport ("Insurgent chase vehicle 1/2/3") | `vehicles/cars/Enemy Car/{Pickup,SUV,Sport} Enemy.xml` (one `Car.vox`, several bodies; SUV copy in level_tutorial; overturned SUV in roadblock8 is a wreck without `<vehicle>`) | back places where the enemy crews of the copies sit (user request 2026-11-09), all normal seats so friendly NPCs use them: pickup 4: cab 2 + 2 behind the cab facing back (toolbox, low reclined place on the left; as VehicleD5); SUV 6: front 2 + rear bench 2 + one on each cargo wheel arch facing inward (as D3/D6; knees on the crate edge); sport 3: 2 + one low in the tray facing back (as D1/D4) | measured, upright (low back places tilt 55); verified SP |
| Chase/ambush copies: VehicleD2/D5/DD3 (pickup), D3/D6/DD1 (SUV, + copy in dev/levels/test.xml), D1/D4/DD2/DF1 (sport) | `prefabs/spawnables/enemy vehicles/Vehicle{D*,DD*,DF1}.xml` | as above | the chase cars' layouts shifted (whole car moved inside the `<vehicle>`: pickup 0.7/-0.8/1.9, SUV 0.9/-0.9/2.2, sport 0.5/-0.8/2.4; body voxels identical after the shift); verified SP |
| BRDM-2 (Insurgent Ambush 7) | `prefabs/spawnables/enemy vehicles/VehicleD7.xml` (in play), `vehicles/cars/BRDM/brdm.xml` (was dev/levels/test_vehicle.xml only; spawn menu "BRDM-2" added, [CHANGES](CHANGES.md); same body placement; its stray civilian spawn point removed, [CHANGES](CHANGES.md); `brdmwrecked.xml`: wreck without `<vehicle>`) | 6: driver + commander on the front bench, 4 on the troop compartment's side benches facing inward (the D7 crew's places) | measured, upright (driver's knees just under the wheel rim, tight cab); verified SP |
| AVF offroad: "Offroad Technical" (+ Open), AAF Jeep (VehicleAAF2), "GMG Offroad" (VehicleM22), "WMIK Technical" (MILAN; VehicleM23) | `vehicles/avf/prefabs/technicals/offroad{,-open,_GMG,_WMIK_MILAN}.xml`, `prefabs/spawnables/enemy vehicles/VehicleAAF2.xml`; inline copies in roadblock3 and dev/levels/test.xml (marked by a `path=` tag on the `<vehicle>`, not an `instance=` group: add_seats.py now finds those too; identical to their sources) | 4: front 2 + rear bench 2 (the AAF2 crew's places); WMIK 2 (right-hand drive; weapons bed). GMG / WMIK: + standing gunner place (mounted guns) | measured, upright; rear seats 0.2 from the backrest (knees clear the front seats); verified SP |
| AVF technical pickup: "Pickup Truck", "Pickup Truck Lifted", Pickup Damaged (wb34), "AAF Pickup Truck technical" (DShK), SPG-9 (M4), ZU-23 (M24) | `vehicles/avf/prefabs/technicals/{Pickup Truck,Pickup Lifted,Pickup Damaged,technical_DSHK,technical_SPG9,technical_ZU_23}.xml` (DShK copies in roadblock3, dev/levels/test.xml) | pickups 4: cab bench 2 + 2 sitting on the bed side rails facing inward; technicals 2 (cab) + standing gunner place (ZU-23: seated) | measured (model = modified official pickup_red, overlap 0.89; its bench sits 0.3 further forward and 0.1 higher, so the official rigs don't fit as they are). Cab smaller than the player (0.7 m cushion to roof): test 1 with the official reclined pose (seat rot 70, low head point, `head=` argument): head still out, looked silly; now upright, head through the roof accepted (user 2026-11-09); verified SP |
| ZIS-151 (road spawners Vehiclewg28; Damaged wb26; Katyusha VehicleM2; spawn menu entries added, [CHANGES](CHANGES.md)) | `vehicles/avf/prefabs/ZIS-151/{ZIS-151,ZIS-151 Damaged,ZIS-151_Katyusha}.xml` (Katyusha: the launcher is a second `<vehicle>` "bm-14" in the same file; the two Destoryed files: wrecks; Cabin, ZIS-150, Katyusha Damaged: referenced nowhere) | ZIS-151 4: bench 2 + 2 on the bed floor; Damaged 4: bench 2 + 2 on the cargo box floor; Katyusha 2 (cab; launcher with the mounted-gun work) | measured, upright (heads ~0.1 through the cab roof, as the Cadillacs); steering wheel = top of a tilted column voxbox; verified SP |
| Humvee .50 cal ("Hummer With 50 Cal", VehicleM1) | `vehicles/avf/prefabs/humvee/umhummer With 50 Cal.xml` | 4 (Humvee layout, same body placement; gunner with the mounted-gun work) | as the Humvee; turret clear of the seats; verified SP |
| Willys Jeep (tutorial; spawn menu entry added, [CHANGES](CHANGES.md)) | `vehicles/avf/prefabs/Weaponised vehicles/Willys Jeep.xml` + drivable copy in levels/level_tutorial.xml (same placement; `Willy's Destroyed.xml` there is a wreck) | 4: front 2 + rear bench 2 | measured, upright; undersized model (v1 eye 0.5 above the seat, tiny wheel): knees into the dashboard, accepted; verified SP |
| BMP-1, BMP-1P, BMP-2 (military spawners VehicleM18/M19/M20; spawn menu entries added, [CHANGES](CHANGES.md)) | `vehicles/avf/prefabs/bmp/{BMP-1 d,BMP-1P d,BMP-2 D}.xml` (three hull models, same interior at the same place) | 5: driver (front left, levers) + 4 troops on the rear central bench, back to back facing the hull sides; commander/gunner in the turret with the mounted-gun work | measured, upright; vehicle origin high (interior y negative). Driver: hips ~0.1 into the small cushion (higher puts the head in the hatch); troops: heads at the roof, knees near the wall racks; verified SP |
| BMP-3 (spawn menu; military spawner VehicleM21) | `vehicles/avf/prefabs/bmp/BMP-3 d.xml` | 5: driver in the middle of the front row (controls there, as in a real BMP-3; the v1 eye point `player` was on the left seat, moved to the middle, [CHANGES](CHANGES.md)) + the two front-row side seats + 2 on the rear bench; the two seats behind the turret left out (narrow tubs with a raised lip); turret crew with the mounted-gun work | measured, upright; heads at the roof; verified SP |
| T-72 ("T-72" = T72B3 mod 2016, "T-72A"; T72B, T72B3 obj 1989, T72BA from military spawners VehicleM3, M14-M17) | `vehicles/avf/prefabs/t72_desert/*.xml` (hull identical in all five) | 5: driver, reclined as in the official military_tank_green (seat rot 80, head point 0.45 up / 0.25 back; the hull is 0.8 m high inside) + 4 riders on the engine deck edges facing outward, legs over the side (user request 2026-11-09; `tank_riders()`, NPCs ride too); gunner place in the turret (mod 2016, T-72A) | measured; head under the roof, right forearm at the controls; verified SP (heavy frame drops while driving, [STATUS](STATUS.md) "Open questions and known gaps") |
| T-54 / T-55 ("T-54 AAF", "T-55A AAF" = Alashya; Desert versions from military spawners VehicleM10-M13) | `vehicles/avf/prefabs/T-54 55/{T-54-3,T-55A} {Alashya,Desert}.xml` | 5: reclined driver (front left, T-72 pose) + 4 riders facing outward with legs over the side, on the fender fuel tanks / stowage boxes / fender (each spot measured) | measured; turret crew with the mounted-gun work; a rider's head can meet the gun barrel when the turret turns sideways; verified SP |
| T-34-85 ("T-34"; military spawner VehicleM9) | `vehicles/avf/prefabs/T-34/T-34-85.xml` | 5: reclined driver (front left, under the sloped front plate) + 4 riders on the engine deck side ledges facing outward, feet on the fenders, thighs over the external fuel tanks | measured; turret crew with the mounted-gun work; verified SP |
| M-51 Super Sherman ("M-51 Sherman"; military spawner VehicleM8) | `vehicles/avf/prefabs/M-51 Super Sherman/M-51 Super Sherman.xml` | 5: upright driver (room to sit up) + 4 riders on the rear deck edges facing outward (the big turret sweeps the hull top) | measured; turret crew with the mounted-gun work; verified SP |
| Refugee UAZ (VehicleC3, debug "Refugee Van") | `prefabs/spawnables/enemy vehicles/VehicleC3.xml` | 4 (UAZ layout) | body rebuilt ([CHANGES](CHANGES.md)), seated; event behaviour shelved ([STATUS](STATUS.md) "Shelved and dead content") |

Inline copies done last (2026-11-09): Willys in the spawners Vehiclewg9 / VehicleM7 (the jeep 0.05 left / 0.3 up),
roadblock3's ZIL-131 (its `path=` tag is cut at the space in "Soviet Vehicles"; add_seats.py key `file#vehicle name`).
**All drivable vehicles in use have seats** (checked 2026-11-09: every `<vehicle>` reachable from the spawners,
roadblocks, road segments, levels and the spawn menu, test levels and `unused/` excluded). Gun positions are
gunner places ("AVF"); the Kornet / AGS-30 tripods are no longer vehicles (gun emplacements with a gunner place,
"AVF"). Player passengers and floor positions need the MP test (Phase 5).

## Steering wheels
* UAZ-452 (5 files): the original built the wheel as a fifth `<wheel>` (turned with steering but spun freely after
  crashes). Now a `steer`-tagged body part turned by `vehicles/SteeringWheel.lua` (server, `SetShapeLocalTransform`,
  steering × 180°; axis = the shape's thinnest voxel dimension, pivot = its bounding-box centre;
  `convert_steering.py`, test_steeringwheel.lua) [verified in-game]. Other vehicles: tag the wheel part `steer` and
  wrap the `<vehicle>` in the script.
* GAZ-24 (3): hinged body + joint motor driven by `EVF.lua`; finds its car by the tag `vehicle`. v1 swung it to ±130°
  from the keys; the driver's hands turn by GetVehicleSteering × 180°, less (user saw ~90°), so since 2026-11-09 the
  joint follows GetVehicleSteering × 180° too (sign for "left" learned the first time the driver holds left, v1 turned
  it positive for left). Kept as a joint (not SteeringWheel.lua).

## Other vehicle content
* `vehicles/PlayerVehicleSeat/` (fake driver model for the v1 invisible player) is no longer loaded: v2 draws
  the driver itself (user saw two bodies). Still referenced by dev/levels/test.xml / dev/levels/test_vehicle.xml only.
* AVF vehicles (mounted guns, cannons, launchers, tanks: `vehicles/avf/`). In v1 each vehicle's XML tags its gun parts and a
  config `.lua` describes the gun (`vehicleParts.guns.mainCannon` = name, magazines, RPM, reload, dispersion,
  sounds); `vehicles/avf/scripts/avf_custom.lua` copied that onto tags and the external AVF mod (Workshop 2400346027, no MP
  version; "ERROR: AVF MOD NOT ENABLED" without it) did everything else. Frameworks considered (2026-11-12): **TABS
  Vehicle Framework** (3148138736) cannot be used (all ~125 scripts v1; its README forbids copying or modifying it);
  **AVF** (elboydo) allows reuse with credit ("no copyright but please give credit", main.lua) → its shell code is
  ported, credited (also in the mod's credits at publish).
  * **`vehicles/MountedGun.lua`** (own, v2; design user-approved 2026-11-09): a library each vehicle config includes
    instead of avf_custom.lua. Config = `#version 2` + player.lua + MountedGun.lua + optional hooks:
    `MountedGunConfig` (own gun table instead of `vehicleParts.guns.mainCannon`), `MountedGunGunTag` /
    `MountedGunEmitterTag` (default `mainCannon` / `mainCannon_emitter`), `MountedGunSound` (else the weapon's AVF
    `soundFile`), `MountedGunCalibre` (machine guns: a gunperks.lua calibre), `MountedGunSightAt`,
    `MountedGunDriverFires`.
  * Parts (AVF tags): turret shape `component=turret` on joint `component=turretJoint` (yaw), gun `component=gun` +
    the gun tag on `component=gunJoint` (pitch; no shape with both → the first with the gun tag: the GMG offroad's gun
    has no `component=gun`, in-game 2026-11-13 the gun was not found and AVF's "mountedGun" prompt stayed); the joints attached to the gun's own shapes count (the BMP-2's
    launcher is also `component=gun`); no `component=turret` (BMP-3: `compnent=turret`, original typo) → the shape the
    turret joint turns. Joint signs are learned from the barrel's own heading / elevation while nudging
    (`MG_BarrelAngles`); motor targets are clamped to the joint limits.
  * Barrel: over all shapes of the gun's body, the longest non-upright axis, signed toward the emitter (none: the
    vehicle's front); muzzle = the front-most point of all the gun's shapes (thin barrel pieces reach past the gun
    model: BMP-1 hit itself). Several emitters = barrels fired in turn (two: sideways offsets; three or more, the
    Katyusha's 33 rails: everything across the barrel line). Shells skip the vehicle's own gun, turret and launcher
    bodies (`MG_OwnBodies`). AVF's `barrels` / `sight` offsets are copy-pasted between configs: not used.
  * Weapons: machine guns (config type customMG or none) fire gunfunctions.lua rounds through gunnet.lua
    (`GunNet_Fire`; calibre stats from gunperks.lua); cannon / rocket / atgm / GMGun types fire AVF shells (below).
    On X: 1 main gun, 2 coax (gun tag `coax=`, `mainCannon_coax_emitter`, fired along the main barrel), 3+ launchers
    (other `vehicleParts.guns` keys tagging a shape of their own; from the launcher's front along the main gun's line,
    its own elevation joint held). F = next ammo type within the weapon (AVF's key; also the flashlight, as in v1 with AVF), R = reload (machine guns);
    cannons reload by themselves when empty (a one-round magazine within the rest of the firing cycle, 60 / RPM);
    F / X work during a reload. Magazines = AVF's loadShells: each starts from the first shell type of the gun tag's
    AVF weapon type with the config's values on top; a config without magazines uses the weapon type's own. HUD ammo
    name: `displayName`, else a designation-like config name ("3UBR8 APDS"), else "<calibre> mm <payload>" ([CHANGES](CHANGES.md)).
  * Gunner place = rig tagged `gunner relative_parent sort=99` under the vehicle's first `<body>` (add_seats.py
    `gunner()` standing / `gunner_seated()`; positions in vehicle space, but a group offset around that body is not
    added: compensate, as for the GMG offroad). Not a vehicle seat (user 2026-11-12: as a passenger rig "Use mounted
    gun" ended in the driver seat): as the game's turret.lua, the player stays on foot and the server calls
    `SetPlayerRig(rig, p)` every tick (`shared.mgGunner`). `sort=99` keeps the engine's "Enter vehicle" prompt off
    the gun; a player the engine seats there anyway (real seats full) mans the gun from that seat (`onGunSeat`, never
    taken out: that made the engine reseat them every tick; `MG.noRemount` after stepping off). The pose turns with
    the turret (`MG_MeasureRig` / `MG_PoseGunner`, `SetRigLocationWorldTransform`; MP sync unverified). Getting on:
    interact on the gun ("Use mounted gun"; seated places: on the turret / mount, `MG.useShape`); again = off, back
    where they stood; dying or entering a vehicle frees it; the hand tool is put away meanwhile.
  * Gun emplacements without a vehicle (Kornet / AGS-30 tripods; user 2026-11-13: one prompt only; verified SP). As
    vehicles the game drew its own "Enter vehicle" on every part without an `interact` tag, at that part's own place
    (hud.lua; an `interact` tag on each body gave three prompts in-game), and no API makes a vehicle unenterable.
    add_seats.py `EMPLACEMENTS` rebuilds both from git, inserts the gunner place and turns the `<vehicle>` into a
    `<group>`; with no vehicle MountedGun.lua uses the chassis shape's body (`MG_BaseBody` / `MG_BaseT`), rays skip
    the base, gun, turret and launchers (`MG_QueryRejectOwn`), seat / driver checks need a vehicle.
    `MountedGunKeepGrip` (simple_avf_tank.lua): hands as laid out, not moved onto the model's box centre (the AGS-30's
    ammo box put that 0.2 m beside the tube, in-game). The AGS-30 does not aim up / down (shelved, [STATUS](STATUS.md) "Shelved and dead content").
  * `MountedGunHoldGunner` (GMG offroad, tripods; verified SP 2026-11-13): while on the gun the vehicle's / tripod's
    shapes go to collision layer 128 (also left out of their own mask: they do not collide with each other meanwhile)
    and the gunner's `CollisionMask` leaves it out (other players unchanged); the gunner is set to the place every
    tick; both restored on stepping off (`MG_HoldCollision`). Why: the GMG offroad's gunner bobbed up and down, pulled
    back 33 times (readout); its roof has a crossbar at the gunner's waist 0.1 m in front of the place, the
    hole behind it 0.3 m deep (vox data). The AGS-30's gunner, right behind the gun, was pushed 0.25 m off the place.
  * Driver fallback (`MountedGunDriverFires`: tanks, Katyusha, tripods): while the gunner place is empty (or there is
    none) the driver works the gun (`MG_UpdateDriver` / `MG_Operator`, `shared.mgDriver`), WASD still drives. Views:
    "vehicle" (the game's driving camera, turret holds, no firing) and "gun"; V switches (hint only for a lone
    driver), RMB from the vehicle view aims while held; the gun view starts along the barrel (`MG_LookAlongBarrel`).
  * Camera (gunner / gun view): the client's own look from the mouse (`camerax` / `cameray`; using the player's look
    fed back when the body turned with the gun), 2.2 m behind and 0.7 m above the barrel's centre, at least 0.5 m
    above the gun's tallest part (`shared.mgTopUp`: Sherman scope, BMP-2 launcher), pulled in at walls. RMB = sight:
    eye above the barrel at `MountedGunSightAt` (0 rear .. 1 front, default 0.25; van: 1), FOV 70 / wheel zoom 1-4,
    moved in front of anything but the gun between muzzle and eye. Aim = the point under the crosshair as a direction
    from the current weapon's muzzle (`server.mgAim`); points closer than 8 m or not ahead of the look aim along the
    look's yaw, pitch within ±60° (looking down wobbled). HUD bottom right in a vehicle; in the driving view above
    the game's driving panel (`game.hud.hintH`).
  * Retirement (`MG_GunUnusable`): gun under 25 % of its voxels, a joint broken, gun off its turret or turret off the
    vehicle (distances + 1 m) → `MG_Retire` once: gunner off, the gunner rig deleted, prompt removed (its debug line
    removed 2026-11-13, user). (IsShapeBroken / origin-distance checks retired working guns.)
  * AVF shells: `tools/porting/history/port_avf.py` (rebuild; base `tools/porting/history/avf_base/` = AVF V-3.0.2,
    unmodified) → `vehicles/avf_port/AVF_Shells.lua` (AVF's common, ammo, weapons, globalConfig, handlers; server simulation;
    client visuals); hand-written `vehicles/avf_port/AVF_Glue.lua`. Server: flight, penetration, payloads, spall / shrapnel,
    world effects, NPC damage (AVF's `mors_longa_damage` registry hook), player damage. Clients: shells drawn from
    the spawn event (guided ones resynced every 0.1 s, `client.avfShellSync`), impact / explosion visuals as events
    (`client.avfFx`, `client.avfShell`), rocket exhaust and flight loop. The gunner's client counts rate / ammo and
    calls `server.mgCannonFire(player, type, tracer)` (per-type rounds in flat shared keys: type 1 `mgAmmo` /
    `mgMags`, type n `mgAmmo<n>` / `mgMags<n>`); flash and sound `client.mgFireFx`. AVF asset paths (`MOD/gfx`,
    `MOD/sounds`) map to copies in `avf/assets/` (`AVF_AssetPath`). Player damage: only an amount ≥ 1 counts, as a kill
    through the torso hitbox ([CHANGES](CHANGES.md)).
    Performance (2026-11-13, lag shooting APDS into foliage and rocks; profile `tests/profile_avf_foliage.lua` with
    real quaternion maths): path holes at least 0.5 × radius apart (`AVF_PathHole` / `AVF_PathPaint`; AVF cut one
    every 1 cm), holes with radius ≤ 0 skipped (`AVF_Hole`), the scorch paints at a path's start only for the shell
    itself (`AVF_ShellPaint`), spall only when the path went through metal (`AVF_HARD`; fragments cutting huge rock
    shapes froze the game; user's switch test: holes off stopped the freezes, no spall gave the most). Left as AVF:
    ~46 SpawnFire per HE shell. Port differences ([CHANGES](CHANGES.md)): 256 shell slots per gun (AVF 1050 shared); spall / shrapnel
    not drawn; v1 particle calls approximated (`AVF_LegacyParticle`); drawn shells ignore AVF's per-tick dispersion.
    Kept from AVF: the 2A42's second shell type inherits the first's values (3UOF8 shows as AP).
  * `vehicles/avf/scripts/Immersive_Tank.lua` (tank damage: cook-off, engine failure, fuel fires, blow-outs; outer script of
    ~90 AVF vehicle XMLs): rebuilt by `port_immersive.py` from 9dde6dd (test_immersive_tank.lua); its logic runs on
    the server; the effect functions run on every client from one event each (`ITC_*` on the server → `ITR_*` on a
    client), other visual calls recorded and replayed (`client.itFx`); masterScriptRemoverAPI dropped.
  * Converted configs (tests test_mountedgun.lua, test_avf_cannon.lua; verified SP unless marked):

    | Vehicle (spawn menu; spawner) | Config | Weapon | Who fires |
    |---|---|---|---|
    | AAF Pickup Truck technical (+ roadblock3 / dev/levels/test.xml copies) | `technicals/technical_dshk.lua` | DShK 12.7 mm | gunner standing, rear of the bed |
    | Hummer With 50 Cal (VehicleM1); Willys in VehicleM7 | `Weaponised vehicles/Willys Jeep 50 Cal.lua` | M2 | gunner standing: centre console, head out of the roof ring / behind the rear bench |
    | Van Modified | `Weaponised vehicles/cars/Van PKM.lua` | PKM (`MountedGunSightAt = 1`) | gunner on the cargo floor, facing left |
    | AAF Pickup Truck ZU-23 (VehicleM24; VehicleM25 points at a missing path, original-mod); AAF Truck Technical (ZIL) | `technicals/ZSU-23-2.lua` | ZU-23-2, twin 23 mm | gunner seated on the mount |
    | BMP-1, BMP-1P | `bmp/BMP-1.lua` | 73 mm 2A28; 1P: 9M133 launcher on X | gunner seated in the turret |
    | BMP-2 | `bmp/BMP-2.lua` | 30 mm 2A42, coax, 9M133M-2 launcher on X | gunner seated in the turret |
    | BMP-3 | `bmp/2A70.lua` | 100 mm (incl. 3UBK10-3 gun-launched missile), coax | gunner seated in the turret |
    | T-72 (= T72B3 mod 2016; other desert T-72B variants share the config) | `t72_desert/t72b.lua` | 125 mm, PKTM coax | gunner seated in the turret (mod 2016 only), else / while empty the driver |
    | T-72A (VehicleM14) | `t72_desert/t72A.lua` | 125 mm, PKTM coax | gunner seated in the turret, driver while empty; verified SP |
    | T-34, T-54 AAF, T-55A AAF, M-51 Sherman (+ desert copies) | `T-34/T-34-85.lua`, `T-54 55/T-54.lua`, `T-55.lua`, `M-51 Super Sherman/M-51 SUPER SHERMAN.lua` | tank guns | gunner seated in the turret, driver while empty |
    | Katyusha (+ Damaged; VehicleM2) | `ZIS-151/katyusha.lua` | BM-13, 33 rails | driver |
    | WMIK Technical | `technicals/Offroad_WMIK.lua` | MILAN, own config ([CHANGES](CHANGES.md)) | gunner standing on the weapons bed |
    | GMG Offroad (VehicleM22) | `technicals/Offroad_armed.lua` | AVF MK-19 grenades, own config ([CHANGES](CHANGES.md)) | gunner standing in the roof ring, held there (`MountedGunHoldGunner`); verified SP |
    | AAF Pickup Truck SPG-9 (VehicleM4) | `technicals/technical_spg9.lua` | PG-9 / OG-9 | gunner standing left of the tube; verified SP |
    | Kornet tripod, AGS-30 tripod (RoadSegmentL1) | `vehicles/avf/scripts/simple_avf_tank.lua` | AVF 9M133 / AGS-30 (no config) | gunner standing behind it (user 2026-11-13 "Stand at it"; Kornet: hands raised to the tube, the model is ~2.7 m tall); no longer vehicles (one prompt, on the gun); AGS-30 hands as laid out; verified SP except AGS-30 pitch (shelved, [STATUS](STATUS.md) "Shelved and dead content") |

    Not converted (loaded nowhere): other T-72 / T-90 / TOS-1 / BMD-2 / Cromwell / ZSU-23-4 configs, the offroad
    GPMG / NSV / M2 guns (share Offroad_armed.lua; their gun tags differ: no gun found), the technical UB-16 / BM-14 /
    Type 63 configs and the stand-alone turret configs (`vehicles/avf/prefabs/turrets/*.lua`).
* Small vehicle scripts (all v2, hand-converted, verified SP 2026-11-09 unless noted):
  * `vehicles/cars/!library/scripts/door.lua` (28 xmls; test_door.lua): server, door-tagged joints motored shut while any
    player (driver or passenger) is in the vehicle, free otherwise; hinges without a `door` tag (insurgent chase cars,
    18 of 29 placements) unaffected, as in v1.
  * `drive.lua` (Cadillac sedans' extra drive joints), `steer.lua` (Cadillac / minivan steering wheel joint),
    `drivetrain.lua` (LeBoat propeller): server, from the DRIVER's input (`IsPlayerVehicleDriver` + `InputValue(name,
    p)`); `toggleAction.lua` (semis' "Toggle Action" parts): any player toggles, a player in the truck retracts them
    (test_vehiclescripts.lua). `dash.lua` (Cadillac speedometer) is a `<screen>` script: stays v1 ([ENGINE](ENGINE.md) "v2 engine rules").
  * GAZ-24 (test_evf.lua): `EVF.lua` (server.update: doors / hood / trunk free while ANY player grabs them, latched
    shut when let go; hinged steering wheel from the driver's steering; the door-open beep stays off as in v1: no XML
    sets `doornotification` and its sound never shipped), `lampa.lua` (interior lights), `policelightsF.lua` (militia:
    F toggles the light bar, blinking on the server), `radio_car2.lua` (siren switch); `radio_car.lua` used nowhere.
  * JetBus `vehicles/cars/bus/jet.lua` (test_jet.lua): server = throttle from the driver's Shift (idle 0.1 while driving,
    1 boosting; v1: the host), push in server.update, turbine, smoke, damage / explosion; client = the throttle bar for
    whoever is in the bus (`shared.jetThrottle` / `jetTarget`). `lastJetHealth` now set in init (v1 compared nil).
  * `vehicles/cars/minivan1/autobreakRemover.lua`: server (removes the bodies' `autobreak` tag); verified SP.
  * Left v1: `vehicles/bike.lua` (dirt bikes, dev/levels/test.xml only).
* Helicopters: AS350 v2 ("AS350 helicopter"). CH-47 (spawn menu, road VehicleM5 "FunkyFlight") and Hind (spawn menu) stay v1 for now
  (user, 2026-11-13): dead in MP.

## AS350 helicopter (`vehicles/aircraft/AS350/script/`, v2 2026-11-13, verified SP except rockets on RMB, [STATUS](STATUS.md) "Shelved and dead content")
* Hand-ported (no converter). `Heli.lua` = entry (rewritten from 9dde6dd: server / client callbacks, its own
  functions with `(v2)` notes); the original files are included as libraries (common, Inputs, Control, PointControl,
  Damage, Weapons, AI, Config, AI_Gore, Settings, Blood) and **`HeliV2.lua`** (included after them) replaces the
  functions that assumed one player on one machine (each names its original). Not included: the setup / PID-tuning
  tools (Debug, Graph, UiFunctions, UiSettings; off in the original), Doors.lua (Heli.lua's versions won in v1); the
  tuning values the crash spiral reads (`Val`, `PFactor`...) are set to v1's defaults (0).
* Server: flight, damage, fuel, doors, rotors, AI, bullets (world part), rockets. Clients (`shared.he*` state, events
  `client.heliShot` / `client.heliCrash`): engine / rotor / vibration loops (inside / outside: the camera tested
  against the "internal" box at its XML place, body pos 0 1.1 -0.1, half size 1 0.75 1.3), smoke, alarm, muzzle
  flash, tracers and impacts (each client flies its own copy of every bullet to the first hit), prompts, debug
  outline.
* The helicopter is a `<vehicle>` (seats, "Status (passenger seats)"). Ways in: the cabin doors' prompts (`HeliV2_InitDoorEntry`: front door
  on the body +x side "Fly helicopter", the others "Enter helicopter"; E → `SetPlayerVehicle`, the engine picks the
  seat; the E that got a player out is ignored; detached doors lose the prompt; the game's own "Enter vehicle" prompt
  showed only at an awkward angle). Pilot = the player in the driver seat (`HeliV2_UpdatePilot`: `DriveVehicle(v, 0,
  0, false)` while seated, against the driver's look-back on S; hands emptied, tool given back on leaving, as v1);
  `TakeControl(p)` / `StopControl()`. Parked copies (spawn menu, tag `parked` → not hostile): `heli_variants.py`.
* **`HeliPilot.lua`** = the player flight model (mouse-aim, user decision 2026-11-13 after Kooshing's Dynamic
  Aircraft, Workshop 3729840632; ideas only): nose toward the view heading, pitch = view elevation × 1.2 (-35..+25),
  bank into turns, A / D roll 20, W / S vertical speed +6 / -5 (else hold height); lift along the rotor axis (up to
  2 × weight) at the centre of mass of the body and everything jointed to it; horizontal drag (top ~44 m/s); turn
  rate set with `SetBodyAngularVelocity`, following at 30 /s, plus a slow correction of a lasting pitch / roll offset
  in the body frame; all scaled by rotor spin × rotor health (start-up 15 s as v1; attitude at full strength from half
  power; dead rotor = no control; no tail rotor = no yaw). Constants `HELI_*` at the top; `HELI_DEBUG = true` shows a
  DebugWatch readout (lean / wanted lean, nose, heading, turn rate, rotor %, control %, lift %, correction, ground).
  The pilot's client: own look (camerax / cameray), wheel zoom 0 (cockpit) / 8-20 m, chase camera raised 2 m + 0.2 m
  per metre of zoom (level with the third-person point it sat behind the tail), pulled in at walls; aim (look + point
  under the crosshair) every tick → `server.heliAim`; gun and rockets aim at that point, the player's bullets fly at
  it while the gun points within `HELI_GUN_CONE` (~8.5°; the gun swings on its mount). When the pilot leaves, the
  original autopilot holds the hover (collective set to the hover value) or, on the ground, lands and shuts the engine
  down (collective at the bottom → CheckLanding).
  Tuning history (2026-11-13): test 1 strong left lean / yaw → lift at the combined centre of mass + offset
  correction; test 2 still at first → turn-rate response 6 → 30 /s (10 % per update let any steady push lean it far),
  attitude authority from half power; test 3 with the readout: lean and nose within ~1° of wanted ("way better").
  Cause of the lean not measured.
* Enemy AI and "Take a ride" fly with the original autopilot unchanged. AI target player: nearest living player it
  can see, picked again every second (`TargetPlayer`, `HeliTargetPlayer()`); the ride is commanded by the player who
  used the pilot's head (`Commander`).
* Bullet player damage: every player, through that player's own hitboxes (`HeliV2_Hitboxes`, HEAD first as the
  original indexed). Rockets (`rocket.lua`, also the Hind's rocket.xml): server flight / guidance / detonation (homing
  and proximity on every player's eye), clients the trail and sound.
* Test: `tools/porting/tests/test_heli.lua` (pilot seat, lift, turn and pitch directions, aim, gun convergence, tool
  put away / given back, per-player damage, hand-over, crash spiral, door entry, ride commander, client camera / aim /
  tracers, rocket).

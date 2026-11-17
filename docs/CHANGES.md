# Mors Longa Revival — original-mod bugs fixed, behaviour changes

Part of the technical reference (index and conventions: [TECHNICAL_REFERENCE.md](TECHNICAL_REFERENCE.md)).
Marks: **[verified in-game]**, **[official source]**, **[unverified]**.

Bugs fixed (all present in the original Workshop mod):
* Guns: `Split(nil)` crash in client.init (RPG in sling); empty-mag / empty-tube HUD concat (all guns, N870, Mudafie,
  Qasira); camo nil on gun switch (9 LoadTool guns); round without bullet type after turning on Unlimited Ammo with
  an empty mag (`checkUnlimitedBulletsValid` → `GunPerkFor` falls back to the calibre's default round, all 35 guns);
  Sawed Off gated on the MP43; Bauer-553 never called WeaponInit.
* Inventory: `invSlot.rotation` nil for special slots; partial stack use not recounting; material deficit stored
  under the wrong key; `clearItem` outside the grid when dying mid-heal; PKM missing from the script lookup.
* Loot/spawn tables: 4GA ammo unreachable; broken entries (KS23 #2, .50BMG, P17 Grey); tutorial IFAK id
  (`meds-bleed-general-ifak`).
* ZIL-131 trucks: "AAF Transport truck" (spawn menu), Vehiclewg33, roadblock9 and test_npc pointed at
  `MOD/Vehicles/ZIL131.xml` (it is in `vehicles/cars/Soviet Vehicles/`); ZIL131, ZIL131_ZSU23, VehicleAAF1 (both copies),
  roadblock3, dev/levels/test.xml and the fire truck's steering wheel pointed at `MOD/vehicles/zil131.vox` (same folder). Paths
  fixed 2026-11-08 (user OK); never tested in-game before.
* Sounds pointing at files that never existed (found from MP log errors, 2026-11-15, user OK):
  * NPC gunfire: guns tagged `gun=g17` (pistols, 79 gun prefabs) and `gun=m4` (MK36 rifles, 31) built
    `MOD/assets/snd/g17.ogg` / `m4.ogg`, so those NPCs shot silently. Now `assets/snd/Weapons/g17/g17.ogg` +
    `g17dist.ogg` and `Weapons/m4a1/m4a1_0.ogg` (`GOREAI_GUN_SHOT` / `GOREAI_GUN_DIST` in `goreai_combat.lua`); m4
    has no distant sound, as before. Distant sounds still missing for m870, mp43, vector, vgo (close shot plays).
  * NPC voice / distant-rifle sets trimmed to the files that exist (`goreai_sounds.lua`): English death voices 1-8
    (the list said 12, a third of deaths were silent), `rifle_dist_far_6` dropped (1 in 6 silent).
  * Removed without a change in what you hear (they never played): the player hit sound `hit_0.ogg`
    (AdvancedHealthScript), the difficulty menu's next / back clicks.
  * Left as is (log noise only): the rpg distant-sound slots are `LoadSound("")` (rpg has none), PlaceTool's
    `vox/placer.vox` model, `levels/level_instance.xml` `skybox=" "` (the "DDS error in data/env/"; fixing it would
    change the sky).
* World: RandomVehicleEnemy `whichone` nil (AAF below 5000 m); military truck never spawning (order of distance
  checks); Cultist ambushes never fired (`GetPlayerVehicle == 0`); pause button in an undrawn slot; parachute /
  horde DebugPrint spam; StandingRagdoll undefined `fwd1` on death; heli crew quickload hook calling an undefined
  function; npc_die reading a missing gun loot string (horde); NPC table / to-delete list / spall shell leaks.
* Vehicles: spawn menu "Soviet ambulance" missing (`spawn.txt` entry started with `Mod/` instead of `MOD/`);
  GAZ-24 sedan + VIP steering wheel turned with A/D while on foot and stayed centred while driving (`EVF.lua`
  finds its car by `FindVehicle("vehicle")`; only the MP variant had the `vehicle` tag, so the others got 0 and
  "player vehicle == 0" was true on foot) → tag added. Both verified in SP.
* Spawn menu "Bad RV" (RV MethLab): the entry's path started with `/Vehicles/` instead of `MOD/vehicles/cars/` (same in
  the original 9dde6dd, like the ambulance entry); fixed 2026-11-08.
* Refugee UAZ event (`enemy vehicles/cars/VehicleC3.xml`): built for an older `uaz452.vox` (objects `body`, `door fl`,
  `stearingwheel`...); the shipped file has the newer model (`Body`, `Door_FL`...), so in-game only its lights and
  the two refugees showed (user, 2026-11-08; same XML in 9dde6dd). Its `<body>` was replaced by the working UAZ's
  (`uaz452.xml`, in `uaz452.vox` colours, 0.25 lower / 0.05 back to keep the old cab spot); scripts, vehicle
  settings, refugees, luggage and locations kept (scratchpad fix_c3.py). First also wrapped in SteeringWheel.lua:
  removed again (user test: van zig-zagged, driver stand-in "dead" from the start, only the passenger got out); the
  scripted wheel turns through the driver stand-in's legs (Blender overlap check; the bus driver overlaps only static
  body voxels), likely breaking it. Not confirmed in-game.
  Kept: the rebuilt body, no SteeringWheel.lua (as the bus), seats, refugee path fix, `locationspawn` moved from
  x -1.2 to -2.3 (live refugees spawned 0.3 m from the van side and got stuck; bus 0.95, jeep 0.65), driver stand-in
  `CivillianD` at (-0.3, 0.2, -1.75), passenger `CivillianP` on the rear floor. Tried and undone 2026-11-08: an 80 %
  copy of the driver stand-in (fitted the cab in Blender, but in-game the driver was gone and the van still
  zig-zagged). The event's behaviour is shelved ([STATUS](STATUS.md) "Shelved and dead content").
  Refugee stand-ins re-placed for the new cab (user: "messily shoved" in): driver figure on the driver seat placed
  like the Jeep/Bus drivers but 0.25 lower (these ragdolls sit ~1.3 m tall, the UAZ has 0.9 m headroom: its head still
  pokes ~0.2 m through the roof); passenger figure on the floor in the back by the luggage (front seat would put its
  head 0.45 m through the roof).
* Refugee events (Civillian Jeep / Bus / Van, `vehicles/operators/ConvoyOperatorTransport.lua`): when the vehicle stopped near a
  player the stand-ins were deleted and `enemies/refugee/Ragdollrefugee1.xml` spawned, but the folder is
  `enemies/refugees/` (same in 9dde6dd): no live refugee ever got out. Path fixed in convert_operators.py
  (2026-11-08). Ambushes (`chaseOperatorTransport.lua`, debug "Enemy Vehicle") spawn existing prefabs. Still open:
  both scripts spawn `MOD/prefabs/Debri.xml` on destruction, which doesn't exist (not checked yet).
* NPCs never shot after the split (aim alignment in draw) — port issue, fixed. Killcam missed single-shot kills
  (head mark cleared one tick early).

Behaviour changes decided by the user:
* Own grenades hurt the player (v1: they did not).
* Ordinary NPCs take explosion damage (v1: only boss shields); the RPG fires the loaded rocket type (v1: always PG-7V).
* Enemy cars keep v1 explode rules ("always explode" was tried and reverted).
* Cultist on-foot ambushes on.
* UAZ-452 steering wheel no longer spins after crashes (scripted instead of a fake road wheel; user request).
* Vehicles without modeled seats get seats anyway: cab players sit at normal height, cargo players stand or sit on
  the floor (v1: the invisible driver had no visible pose).
* Friendly NPCs ride in every vehicle with passenger seat rigs (v1: only Vehiclewg30's seat lights); players get
  seats first; seat icons show only while a friendly NPC exists and are correct for every player (v1: always in
  Vehiclewg30, "taken" state host-only).
* Mod metadata (2026-11-13, Phase 5 prep; user: "Revival + credits"): `info.txt` name "Mors Longa Revival (dev)"
  (the release copy drops " (dev)"), author "AUTHOR_NAME (co-op port), Overdrive Studios (original Mors Longa),
  elboydo (AVF shell code)" (AUTHOR_NAME: to be filled in by the user), description prefixed with the co-op note
  (`[noupload]` kept as in the original). `id.txt` no longer holds 2906369984, the original's Workshop item (an
  upload would have tried to update Overdrive Studios' item): no id, so the first upload creates a new item.
* Spawn menu additions (each user-approved; in v1 these were only road / roadside spawns, test levels or nowhere):
  * Vehicles - Civillian: "Mobile Crane" (v1 only in dev/levels/test_vehicle.xml), "Dodge Monaco", "Dodge Monaco Police",
    "Plymouth Fury", "Semi Flathead" (roadside Vehiclewb1/wb15), "Cement Truck" (wg42), "Volga" (wg18), "Microcar"
    (wg38), "Ford Falcon" (wg21), "Small Boat" (`Based vehicles/cars/smallboat_red.xml`, vehicleS13) (2026-11-08).
  * Vehicles - Insurgent: "BRDM-2" (the empty `brdm.xml`, v1 only in dev/levels/test_vehicle.xml; with crew it was already
    VNPCs - Transports / Insurgent Ambush 7; 2026-11-09). Its `<instance file="MOD/prefabs/spawns/enemies/
    EnemyCivSpawnVehicle.xml"/>` (`RandomRagdoll Type=civ chance=100`: a random civilian NPC at the car's centre, under
    the hull; no other drivable vehicle has one) was removed; VehicleD7 keeps its copy (original event content).
    "Insurgent Heli (parked, no AI)" (2026-11-13, below).
  * Vehicles - Military: "Military Truck" (the plain `Milltary_Truck.xml`, v1 only in dev/levels/test_vehicle.xml; the
    roadblocks use the UM Damaged one; 2026-11-08); "ZIS-151", "ZIS-151 Damaged", "Katyusha" (wg28 / wb26 /
    VehicleM2), "Willys Jeep" (tutorial only), "BMP-1", "BMP-1P", "BMP-2" (VehicleM18-M20) (2026-11-09); "AAF Pickup
    Truck ZU-23" (only dev/levels/test_npc.xml placed it; 2026-11-12); "AAF Heli (parked, no AI)", and for testing the
    v1-survey batch "T-72A", "AAF Pickup Truck SPG-9", "GMG Offroad", "Kornet tripod", "AGS-30 tripod" (2026-11-13).
  * Parked helis: `vehicles/aircraft/AS350/AS350_{MILITARY,INSURGENT}_PARKED.xml` (generated by `heli_variants.py`), the enemy
    helis with the tag `parked` on body Heli, which Heli.lua reads as not hostile (the original's friendly mode:
    stays landed, the pilot offers "Take a ride"). For testing seats and player flight.
* Militia GAZ-24 siren (original-mod bug, same in 9dde6dd): `vehicles/cars/GAZ-24 (1968)/radio_car2.lua` loaded
  `MOD/Vehicle/GAZ-24 (1968)/Sounds/Siren.ogg` (the folder is `Vehicles/`), so the "radio" switch never made a sound;
  path fixed (user OK 2026-11-09).
* BMP-3 driver eye point (`location tags="player"` in `vehicles/avf/prefabs/bmp/BMP-3 d.xml`): x -0.9 → -0.1 (the left front
  seat → the middle one, where the controls and the new driver seat are; user request 2026-11-09).
* Van PKM fire sound (original-mod bug): the config named `MOD/assets/snd/ak0.ogg` (missing: silent) → `MOD/assets/snd/Weapons/ak/
  ak_0.ogg`; a missing mounted-gun sound now falls back to the M107 sound with a debug line.
* WMIK Technical weapon (user, 2026-11-13: "MILAN missile"): in the original its AVF config never loaded (commented-out
  includes of a missing file, [ENGINE](ENGINE.md) "Workflow"), so the external AVF mod fired its generic customcannon shell from the XML tags
  (customShell: explosive, size 2). Now a MILAN guided missile. The template the
  config named ("MILAN_02") never existed in the mod, so the numbers are new, built on AVF's Kornet shell: 115 mm,
  velocity 55, no gravity, HEAT, explosion 1.0, maxPenDepth 1.8 (BMP Kornet configs: 2.0), 1 per load, 6 loads,
  RPM 5, reload 5 s, AVF's atgm00 launch sound.
* Cannon ammo names in the HUD (user, 2026-11-12): AVF showed internal names ("B_23mm_AA"); now a config
  magazine's `displayName`, else "<calibre> mm <payload>" (MG_AmmoLabel; kinetic = APFSDS).
* v1 survey batch (2026-11-13; user: "Yes, convert them"):
  * GMG offroad (offroad_GMG.xml, road VehicleM22): its config never loaded in the original (as the WMIK) and the gun
    shape has no AVF gun tags (`component=gun`, weaponType), so what the external AVF made of it is unknown; now an
    AVF grenade machine gun (MK-19 values: 400 RPM, 60-grenade belt, reload 4, 30 mm HE shell). Kornet
    / AGS-30 tripods fire AVF's 9M133 / grenades; SPG-9 technical PG-9 / OG-9; T-72A gun (all needed the external
    AVF mod in v1).
  * Freeze when an AGS-30 tripod was shot (user repro 2026-11-13: the game stalled for a while, then recovered): its
    gun weighs ~1e-7 kg (density 1e-12, as in the original), AVF's body pushes (shell impact, explosion shockwave)
    scale down only for heavy bodies (~1e8 m/s on it). AVF pushes go through `AVF_Impulse` (glue; speed change
    capped at 30 m/s, port_avf.py); verified SP (no freeze). Whether it froze with the external AVF in v1: unknown.
  * Kornet / AGS-30 tripods: a standing gunner place behind the gun ("Use mounted gun"; user 2026-11-13 "Stand at it").
    Only that prompt (user request): the tripods are no longer vehicles (original: AVF vehicles the player could
    enter), so the game's "Enter vehicle" is gone.
    AVF's "mountedGun" prompt tag is removed from every gun without a gunner place (it did nothing without AVF).
  * SPG-9 technical XML: the rear "mainCannon_backblast" location was tagged mainCannon_emitter (AVF: a second
    barrel at the tube's rear end, every other shell from there) → tagged mainCannon_backblast (original-mod bug).
  * Crew sitter ragdolls (gorefunctions.lua, v2): gore pieces / sounds / UI prefabs load from paths that never
    existed (MOD/main/Gore Ragdolls 2/, MOD/prefab/; the files are in main/AS350/Gore Ragdolls 2/): still nothing
    there (original-mod bug, not fixed), the spawns now skipped via HasFile. P (sit / stand) and the kill-all key
    work for every player (v1: the one player).
* AS350 (2026-11-13, [VEHICLES](VEHICLES.md) seats and "AS350 helicopter"), changes against the original:
  * A `<vehicle>` with seats (user decision "Seat rigs"; v1 teleported the pilot every frame): the pilot seat gives
    control (the dashboard "Control" prompt is gone), riders sit on the rear bench; "Fly helicopter" / "Enter
    helicopter" prompts on the cabin doors; exit beside the pilot door. No car behaviour: `sound="0"`, topspeed /
    acceleration 0 (values as Kooshing's MP helicopter), tags `player_nogears player_nosteeringwheel`, drive input held
    at 0 while seated (player_locomotion.lua turns a driver's head back on reverse).
  * Player flight: new mouse-aim model (user decision "Mouse-aim like reference"; the original drove its AI
    autopilot with W/S/A/D speed targets and the camera heading; user: it flew badly). Controls: mouse steers,
    W/S climb/descend, A/D sideways, LMB gun, RMB rockets (shelved: lean-out, [STATUS](STATUS.md) "Shelved and dead content"), wheel zoom, E leaves the seat. The
    pilot can no longer shut the engine off while seated (v1: landing with Ctrl); leaving the seat on the ground
    shuts it down. Hint list is new text.
  * Gun / rockets aim at the point under the crosshair (v1: 4 m along the camera turned 10 degrees down / the camera
    ray turned 3 degrees up); the player's bullets fly at that point while the gun points within ~8.5 degrees of it
    (v1's AI-tuned 0.01-0.03 window, kept for the AI).
  * Enemy AI: targets the nearest player it can see; leads that player's movement (v1 used the one player's speed,
    also while hunting an NPC).
  * Bullet impacts now play sounds: the original's bullet code used the impact sound globals of the player guns but
    never loaded them (silent); same files as `GunFunctions_LoadSounds`.
  * Bug fixes: `QueryRejectVehiclePlus` indexed a nil table when the body under the player had no joints; bullet
    player damage errored without player hitboxes (`math.random(2, 0)`); `InternalVars` / `WorldXcontrol` read the
    helicopter transform / ride state before they were set (nil arguments; v2 sets them first); `Axes[Up]` (undefined
    `Up`) in the unused PointU/PointD; the ride ends with E only for the player riding (v1: E anywhere); "Take a ride"
    on one shape (v1 tagged all `PilotHead` shapes: two prompts on the pilot, original-mod bug).
* AVF spall only from metal (2026-11-13, user asked to cut the lag shooting into foliage, then rocks): AVF threw spall
  fragments at every penetration, whatever the material; now only when the shell went through metal (armour,
  vehicles). No spall from foliage, wood, plastic, glass, dirt, plaster, rock or masonry (their fragments' holes in
  large rock shapes froze the game). Penetration path holes at least half a radius apart.
* Immersive_Tank.lua port (2026-11-13): kill_tank set the cook-off origin to the hull's centre of mass, a bare
  vector, which every later use treats as a transform; in the mock the cook-off then errored every tick inside
  tick()'s pcall (whether the real engine errored or read it as the vehicle origin is not known). Made it a
  transform at that point (`Transform(com)`), as evidently intended. Fire damage near a burning tank: per player,
  only a lethal amount counts (as the original health script; same rule as AVF's shells).
* AVF cannon port (2026-11-12, user chose to port AVF's shell system): behaviour kept as in v1 + AVF where the code
  allowed it; differences listed in [VEHICLES](VEHICLES.md) ("AVF shells"). Player damage: AVF lowered only the local player's
  engine health; the original health script reset that to 1 every tick (9dde6dd AdvancedHealthScript), so only a
  hit worth the whole health at once mattered (it killed). Ported as exactly that, for every player, through the
  torso hitbox (QueriedDamage 10000); no partial damage from shells (as in v1). AVF's apply_impact_impulse read the
  undefined globals point2 / dist1: ported as an impulse at the shell's position.
* Fixes from the 2026-11-12 playtest (each checked against 9dde6dd):
  * Sandstorm countdown (original-mod bug, same lines in 9dde6dd): `sandstorm.lua` rolls `math.random(0, chance)`
    with `chance` one lower each tick; a hit while `savegame.mod.config.daynight.sandstorms` reads false neither
    started a storm nor restarted the countdown, so after 100000 ticks every tick raised "bad argument #2 to
    'random' (interval is empty)". With the option on, a storm starts before that with probability 100000/100001,
    so the error means the option read off in that run. Now a hit restarts the countdown either way and no range
    goes below 1.
  * Sandstorms never started (original-mod bug, same in 9dde6dd): the debug menu's "Sandstorms" button shows the
    `util.structured_table` default (true) while the key was never written, but `sandstorm.lua` read it with
    `GetBool`, which is false for a missing key; storms only came after toggling the button off and on (user's menu
    showed it on, 2026-11-12). Now read as `not HasKey(k) or GetBool(k)`, like the menu. Behaviour change: storms
    happen by default, as the menu says. (Other raw `GetBool` reads of default-true keys, e.g.
    `map.spawnTileContent` in procgen.lua, not checked.)
  * Simonov-9 magazines under two names (original-mod, user chose 2026-11-12): magazines out of the gun
    (`weapons/guns/PP19.lua`, also a `convert_gun.py` FIXUP) and the shop's gun item were `Simonov-9`, loot ones
    `Simonov-9-Mag`, so they did not stack. All are `Simonov-9-Mag` now; magazines already held keep the old name.
  * NPC feet panel (port regression): Ctrl+F with debug mode on opens `npc_debug_feet` (client draw), `FeetData`
    exists only on the server (`init_controls`): "attempt to index global 'FeetData'" every frame. The panel now
    stays closed on the client (it tuned server-side stepping; not rebuilt).
  * Loot table (original-mod bug): `{"Mag MC9 #3.xml", 2}` in `SpawnRefrenceTable.lua` names a prefab that never
    existed; the spawner printed "... Does not exist, loot spawn failed, trying again." and rerolled. Entry removed
    (same outcome as the reroll, no message).
  * Simonov-9 magazine description (original-mod bug): no `mag0-ak-9x19` entry in `inv-desc.lua` / `inv-items.lua`
    ("Unknown item: mag0-ak-9x19"); entry added in the wording of the MC9 one.
  * Rotated med used on a body part (original-mod bug, same six lines in 9dde6dd): `placeItem` put the med back as
    `{item, {origx, origy}, w, h}` without `rotation` and with w/h of the drag rotation: drawn unrotated on rotated
    cells. Now put back with the slot's own rotation and size.
* MP fixes from the first local MP test (user, 2026-11-14; mock tests test_newlevel.lua, test_invtools.lua; to be
  re-tested in local MP):
  * Vanilla tools on for every player in MP: our levels loaded the engine's `sandbox.lua`, whose `server.tick` in
    multiplayer only enables every registered tool for every player each tick; the inventory's server.tick applied
    its per-player list only when it changed (`InvApplied` cache), so after the first tick sandbox won. First fix:
    re-apply every tick against `IsToolEnabled` (worked, but the two fought every tick). Now the game levels load
    `game/MLSandbox.lua` instead: the engine's sandbox.lua with only that SetToolEnabled removed (spawn /
    respawn, name tags, damage indicators, death fade, weather, map markers, unlimited ammo unchanged); the per-tick
    check stays as a guard. (A gamemode would also stop sandbox.lua, `contentgamemodeexample/race.lua`, but takes
    those features with it.)
  * Extinguisher in slot 1 over the primary gun (user's MP screenshots; behaviour change): v1 put it in slot 4 with
    `game.tool.extinguisher.index = 4`, but in 2.x the tool bar's slot is `game.tool.<id>.group` and `.index` only
    orders tools inside a slot (`data/ui/hud.lua`), so neither the sync flag nor a client-side write moved it. Now
    `.group = 4` (with the Place / Welding tools), set on the server and on each machine (inventory client.tick).
    That only moves it on the bar: the engine's own key 4 and mouse wheel use the built-in slot (1), so key 4 never
    reached it (user's test). Key 4 is now handled by the inventory (`InvCycleSlot4`, user's choice): it cycles the
    enabled slot-4 tools in the bar's order (Place Tool → Welding Tool → Extinguisher). The mouse wheel stays the
    engine's (reaches the Extinguisher next to the slot-1 guns). test_slot4.lua.
  * Other players' guns drawn as loose parts (every part in its build lane, arms floating): the gun scripts place,
    animate and hide the parts of the local player's tool body only. `gunnet.lua` now sends the holder's part
    transforms (changed parts, <= 10/s, all every 2 s and on a tool change) and every other machine applies them
    to that player's tool body each frame in `client.render` (as the official `snowball.lua`), first-person arms /
    hands (the gun script's hand1/hand2/arm1/arm2) hidden there. test_gunparts.lua. Verified (user, 2026-11-14):
    other players' guns look whole. Left as it is for now (user): in third person every gun sits offset from the
    hand and is very large next to the character, because the prefabs are built at first-person viewmodel scale
    and position (original mod; resizing would change the first-person look).
    Fixed 2026-11-15 (user: "fix these massive guns", screenshots: ~2.5x size, fake first-person arms visible in
    the holder's own third person): `gunnet.lua` "Third-person guns". Each machine spawns its own small copy of
    the held gun (one shape per tool part at `GUN3P_SCALE` = 0.4 of its voxel size, voxels and colours copied
    from the tool's parts), poses it every frame from the tool parts (positions x 0.4, so reload animations
    carry over), hides the tool and the fake arms, and puts the character's hands on the fake hands' grip points
    with the engine rifle's third-person hand placement (`data/prefab/tool/rifle.xml`). Used for other players
    and for the holder in third person; first person unchanged. The holder also sends which parts are its fake
    hands (`|g=` in the parts message). Test: `test_gun3p.lua`. Unverified in-game: that a client's Spawn stays
    local and that a copied shape keeps its own voxel size (if not, the gun stays big). Not changed: remote
    tracers still start at the holder's first-person muzzle point.
    First test (user): both confirmed (small gun in the other player's hands) **[verified in-game]**. Two fixes: a
    piece floating behind the player (MC308: parts the script never moves stay where the .vox puts them, 22 m
    behind / 5.6 m ahead) -> copy parts outside a box around the gun are hidden (`GUN3P_BOX_MIN` / `_MAX`); the
    copy didn't follow the player (a static body took only its first placement, cause not verified) -> dynamic
    body, gravity off, velocity zeroed every frame.
    Second round (user: "aiming in 3rd person just moves the player's hands to the left"; aim like other games /
    the base game): the pose is now the engine's own third-person rifle animation (`toolanimation.lua`
    tickToolAnimator, poses from `data/prefab/tool/rifle.xml`): low "run" pose when idle, shouldered "action" pose
    while aiming (right mouse, read per player) or for 2 s after a shot (`client.gunRemoteFire`), turned toward what
    the crosshair hits (10 m camera ray, yaw clamped as the engine does), crouch variants, arm pitch about the neck,
    the engine's blend rates. The holder's own third person no longer overrides the tool: the gun script keeps
    placing the hidden tool as in first person (bullets unchanged) and the hands are converted into its frame (the
    aiming offset had dragged them left, because they were given relative to that tool).
    Third round (user: long delay back to idle after aiming; SV-98 scope view not lined up in third person): the
    shouldered pose now ends 0.15 s after aim is released (`GUN3P_AIM_HOLD`) and 1 s after a shot
    (`GUN3P_SHOT_HOLD`), not the engine's 2 s. Scope overlays (reticle + see-through outline, projected from the
    first-person tool) switch the view to first person while they show: the 26 gun scripts that draw
    `reticleoutline.png` call `Gun3P_ScopeOverlay()` there, `GunNet_ClientTick` then calls `RequestFirstPerson(true)`
    (the engine's view-finder pattern); the view returns to third person when the scope is lowered.
    Third-person guns after the third round **[verified in-game]** (user, 2026-11-15: "all good").
* Scope overlay alignment (user 2026-11-15, SV-98, first and third person: "glass and reticle unaligned, sway in
  opposite directions, the glass moves faster when turning"). Original design, same code in 9dde6dd: the reticle
  is drawn where the barrel points (500 m ray), the see-through outline (`reticleoutline.png`) at the mirror image
  of the scope's rear lens about the screen centre (41 draws) or at the rear lens itself (6: CZ-1012, MP43, P90,
  Qasira, PKM, Bauer-553). Any sway or lag of the tool behind the camera moved them apart; the rear lens, close to
  the camera, moved most. Now the outline is centred on the reticle's point in all 47 draws (26 scripts), with
  the original's limits (x within 200 px of the centre, at most 100 px below it); both still sway with the gun.
  **[verified in-game]** (user, 2026-11-15).
  * Hardcore "Try Again" resets the other players' money too (user, 2026-11-14).
* RPG-7 for other players (user, post-release MP test with a friend 2026-11-16: "RPGs don't render for other players
  nor their sounds of shooting"; to re-test). Launch sound and backblast smoke: `RPG.lua` made them only on the
  shooter's machine (the RPG fires no shell, so `GunNet_Fire`'s remote sound never ran); now `server.rpgLaunch` /
  `client.rpgLaunch` play them at the launcher on the other machines (`RpgLaunchEffects`). Launcher: the
  third-person copy's box test read a part's local position, one corner of its voxel grid; the launcher tube's
  corner is its rear end (model file: 40 voxels long; the corner is 0.85-1.7 m behind the grip for 0.05-0.1 m
  voxels), outside the box (z <= 0.5), so the copy left the tube out while the real tool was hidden. The box now
  tests each part's centre (`Gun3P_PartCentre`; test_gun3p.lua). The rocket in flight is a server body (synced);
  its flame trail is server particles, whether those reach clients is still unverified.
  Second round (user screenshot 2026-11-16: launcher now shown; "too small, and should be held over the shoulder
  when aimed"): `GUN3P_TOOL["gun-rpg"]`: the copy is scaled so its longest part (the tube) is 1.0 m (a real RPG-7:
  0.95 m) instead of 0.4 x the model; the RPG's model is a .vox registered directly, not a gun prefab the 0.4 was
  chosen for. While aiming / after a shot the tube's axis rests on the right shoulder beside the head (own action
  pose) instead of the rifle's grip pose; idle it is carried low like the rifles. To test.
  Third round (user 2026-11-16: size, pose and sound good; "the rocket seems to spawn several metres in front of
  the RPG", seen by the other player): cause not verified. Two parts are known: the rocket spawns ~2 m ahead of the
  shooter's first-person launcher (unchanged, v1), and the other machines get the new server body some frames later
  (120 m/s = 2 m per frame). The other machines now draw a smoke trail from just in front of the shooter's eye
  along the shot (`RpgLaunchTrail`), and with the debug building sync readout on they print where the rocket first
  showed up there (`RpgProbeTick`: distance from the shooter's eye, delay, spawn distance; removed after the
  measurement below).
  Readout (user 2026-11-16, 15 shots): spawned 2.4 m from the eye, first seen on the other machine 3.3 m (3 of 15:
  5.3 m) after 0.02-0.05 s: the spawn point is most of the gap, the network 1-3 m. Behaviour change (user OK): the
  rocket now spawns `RPG_SPAWN_DIST` = 1.2 m from the eye on the same line (v1: 2.4 m); the point-blank check
  stays. To test.
* Seat camera (user, MP 2026-11-16: "if a seat gets destroyed while you're in it, the camera goes far off the map;
  exiting puts player and camera back next to the car"; the player is moved to the next free seat, user: keep that,
  no ejecting). `vehicles/ShootFromCar.lua` `DriveByTick` (server, the RMB drive-by script) called
  `SetPlayerVehicle(vehicle)` every tick while the player was in a vehicle and not holding the drive-by key (v1; a
  no-op while seated). Exiting is what ends those calls. Likely cause (not verified): the engine takes the player
  out of the broken seat and this put them back every tick, each re-entry resetting the vehicle camera. Now it
  calls it only to put a drive-by shooter back (repeated for 0.5 s while the engine settles), and once if the player
  is taken out some other way (the engine picks a free seat); taken out again within 2 s = left out. The host's
  screen prints "player N taken out of the vehicle while seated: re-seated once" when that happens. A camera guard
  tried first (client, placing the camera while it was far from the vehicle, three rounds) only covered the
  symptom (user: "it should fix once and be done") and is removed. Test: the line appeared once, the player stayed
  in, the camera was still under the map; the player sits in another, working seat (user). Guess (not verified):
  the re-seat came in the same tick as the engine's ejection, so the client never saw the player leave and kept the
  broken seat for its camera; exiting and entering is a change it does see. Round 2: the player stays out for
  0.3 s before the one re-seat. While the debug sync readout is on, the host prints the server's seat (rig handle)
  before / after, and every machine prints its own player's vehicle and seat when they change (different handles =
  the client kept the old seat). **[verified in-game]** (user, 2026-11-16: "the camera seems to be fine now"; client
  log: seat 11303 (broken) → vehicle 0 → seat 11296; host: taken out of seat 11303, re-seated after 0.3 s).
* Buildings / road missing for non-hosts (user, post-release MP test 2026-11-16; found 2026-11-17 with the MCP
  bridge's two-window test). Static prefabs (no `<body>`) are spawned into the world body, which the world shift moves
  200 m (`SetBodyTransform`). Test with boxes: a box spawned before the move (same tick) sat right on the client;
  boxes spawned after it (same tick, ~1 s later) were off by the move on the client, permanently; the client had the
  move within 3 s. In the travel, pieces were also off the other way (spawned just before a shift, built by the
  client after the move). So the non-host sees a gap (road, building, hill) and a copy one shift away. A changed
  shape local transform is synced (re-setting the same value is not, tested), so `GenerateRoad.lua`
  `ShiftResync_*`: at each shift a job marks the newest world-body shape from 10 s before (recorded every second);
  1, 5 and 10 s after the shift every newer world-body shape is moved 1 mm and set back, which sends the server's
  placement to every client (test_generateroad.lua). Measured: 200-11,000 shapes per pass. In-game (two 2 km runs):
  misplaced pieces seen right after a shift are back in place once its passes ran; 4 of 493 cells still differ at the
  end, all from one piece unrelated to the shift ([STATUS](STATUS.md)). Network cost with a remote player: unmeasured.
  To test with a friend.
  * Cost fix (2026-11-17, measured in SP with the MCP bridge): those passes froze the game 0.5-5 s, 1, 2 and 5 s after
    every shift, in SP too. Each `SetShapeLocalTransform` on a world-body shape costs ~0.28 ms (3000 shapes moved and
    back in one frame: 1.7 s; 100 per frame: ~75 ms every frame; one set each: half). Now: no passes without other
    players; only shapes of 500+ voxels (of 10,000 recent world shapes, 8,900 were bush pieces / bits of ~13 voxels,
    ~1,070 road, rocks, terrain); one set per shape and pass (1 mm up, the next pass back down: never more than 1 mm
    off); a pass is queued and worked off 25 shapes per frame. Behaviour change for non-hosts: small pieces (under 500
    voxels, e.g. bush parts) spawned around a shift are no longer corrected, so a few may still sit 200 m off. SP run at
    25 m/s: frames under 3 FPS 20 in 1.6 km before, 2 in 2.2 km after (both road-segment spawns, ~0.4 s). MP cost
    (estimate, not measured): ~1,000 shapes per pass ≈ 0.3 s of work spread over ~40 frames (~7 ms each). To test with
    a friend: buildings / road in place for the non-host, and no hitch after shifts.
* Debug building sync readout, level scan (2026-11-16): the server publishes per 20 m cell (grid offset 7.3 m) the
  count and voxels of its static shapes (players' held tools left out); every machine lists the cells that differ
  and asks the server which shapes are in the worst one (`ui/BuildingProbe.lua`, test_buildprobe.lua). The readout
  now also switches on from `level.debug.buildprobe_on` (set by a test tool).
* Tent prefabs (2026-11-16): `assets/vox/UMTent1/2/3` (prefabs without a file extension) still pointed at
  `MOD/vox/quarantine.vox`; the reorganization's path rewrite skipped them (log: "File not found .../vox/quarantine.vox").
  Now `MOD/assets/vox/quarantine.vox`. A check of every `MOD/` path in all text files found no other path the
  reorganization broke (403 dead paths, all already dead in 9dde6dd).
* Option "Reduce Number of Objects" (2026-11-17): `RandomBuilding.lua` read `Settings.performance.spawn_less_objects`
  (always nil; same in 9dde6dd: original-mod bug), so the option never removed buildings' detail shapes. Now
  `Settings.performance.physical.spawn_less_objects.value` (default off: no change unless switched on).
* New option "Segment Loading Pace" (Performance > Physical, 1-6, default 1 = as before; user request 2026-11-17):
  the road generation spawns only every Nth frame: segment pieces, segment files and decor (`GenerateRoad.lua`
  `SpawnGap`) and the spawners through `SpawnSlot.lua` (`level.spawn.gap`); above 1 the pieces share the spawners'
  slot. Less data per frame for host and clients; the road appears more slowly (pace 3 at 25 m/s: the traveller
  waited for road 72 ticks in 2 km). test_decor.lua.
  * Change (2026-11-17, after an in-game run at 25 m/s, pace 3: up to 425 entries waiting, the road ahead missing, the
    player fell through the gaps): the pace never holds back the ground in front of the players. When the next waiting
    ground entry's segment starts less than 100 m ahead of the generation player (`GroundUrgent`, `PACE_URGENT_DIST`),
    the ground spawns every frame whatever the pace; spawners and decor keep it. Verified: 2.9 km at pace 3 with the
    world full the whole way. Note: the user's Workshop copy has pace 6 saved, the local dev copy 3.
* Empty prefab instance removed (2026-11-17, original-mod bug, in 9dde6dd): RoadSegment1237 / 4 / 5 each held a bare
  `<instance file="MOD"/>` (an editor leftover) that spawned nothing and logged `Could not find prefab: <mod folder>`
  every time one of these segments spawned. Found by listing every XML `file=` path without `MOD/` / `LEVEL/` (user's
  idea).
* NPC step replay (2026-11-17, performance, user request): below 60 FPS the npc logic (thinking, navigation,
  movement, holds) runs once per frame instead of once per physics step; the frame's extra steps re-apply the holds
  it set, and their time is carried into the next run, so npcs keep their pace. Timing change: npc decisions are
  made once per frame (at 30 FPS: 30 times a second instead of 60). +2 FPS measured with ~20 npcs; npcs stood fully
  upright in the test. Verified in play by the user (2026-11-17): npcs look and act the same.
  Details: [PERFORMANCE](PERFORMANCE.md) "NPC step replay".
* Settled dead NPCs (2026-11-17, performance, user OK): a dead npc stays in the NPC loops until the road cleanup
  deletes its torso; past its 3 s dead window it now takes a light path (`npc_rest_dead_tick` in goreai_manage.lua):
  all body parts and the position read once a second (the torso handle every tick), no target-player pick, light
  written only when day / night changes, its 150 projectile records freed once none is in flight; no aim alignment
  for dead npcs (tick_npc_aim_alignment), no per-step head transform for settled ones (the killcam reads the head
  when it fires). Still listed as dead, killcam and loot tag unchanged. No gameplay change intended. Measured per
  dead npc: garbage ~156 -> ~57 kB/s, heap ~114 -> ~60 kB (tools/porting/tests/test_restdead.lua).
* NPC manager garbage (2026-11-17, performance, user request): unused per-update values removed from the movement,
  turning, gun-holding and gun-pointing code (no effect on behaviour: nothing read them), and the script's Lua
  garbage collector pause raised from 200 to 500 (the heap may grow to ~5x its live size, ~10 MB, before a cycle).
  Measured: ~8% less garbage per living npc; goreai_main ~3.06 -> ~2.32 ms with 6-7 npcs (profiler).
  Details: [PERFORMANCE](PERFORMANCE.md) "NPC manager garbage".
* Idle guns (2026-11-17, performance, user request): every gun script scanned its 200 projectile slots and read the
  inventory 8 times per frame even when nobody held it. Now the scan is skipped while nothing is in flight and no
  new shot was fired, and the inventory check is read once per frame. No behaviour change intended; measured ~2 ms
  per frame with no npcs. Details: [PERFORMANCE](PERFORMANCE.md) "Idle weapons".
* AS350 rockets on RMB (2026-11-17, user request): the pilot no longer leans out of the helicopter on the drive-by
  key (default RMB, the rocket key); ShootFromCar.lua skips the driver of vehicles tagged `nodriveby_driver` (all
  AS350 prefabs). Passengers still lean out. Verified in local MP.
* Finished scripts are removed (2026-11-17, performance, our v2 bug since the port): per-npc initializer scripts and
  enemy / convoy vehicle scripts used to stay loaded (idle) after their npc died or their job ended, piling up over
  a run (38 initializers after 3 km, frame time doubling). They now queue themselves and lib/masterScriptRemover.lua
  deletes them (its v1 bugs fixed: wrong key cleared, a log line per removal). Corpses and vehicles stay as before.
  Measured: standing at ~2.9 km 48.7 ms -> 16.7 ms per frame. Verified in local MP (10 npcs killed: host and client
  both 111 -> 102 scripts, same corpses, no errors). Details: [PERFORMANCE](PERFORMANCE.md) "Long run".
* Loot outlines (2026-11-17, performance): the outline script searched every loot body in the world each frame;
  now it collects the ones within 20 m 4x a second and checks those each frame (outlines still show within 8 m as
  before). ~0.85 ms per frame measured. Details: [PERFORMANCE](PERFORMANCE.md) "Bigger scripts ranked".
* Paths with `MOD//` missed by the reorganization (2026-11-17, our bug since 2026-11-14): `Vehiclewg3.xml` (the
  good-condition VW Beetle) pointed at `MOD//Vehicles/1963 VW Beetle/...` and `VehicleDD4.xml` (the camp) at 13
  `MOD//Vox/...` tents / sleeping bags; the double slash hid them from `tools/relocate`, so the Beetle spawned
  nothing and the camp had no tents. Now `MOD/vehicles/cars/1963 VW Beetle/...` and `MOD/assets/vox/...`. Found in
  the log of a 10 km run. Still missing, original-mod bugs (never existed in 9dde6dd): constructionCivillian8's
  `assets/industrial/lamp-ceiling-fixed.xml` / `lamp-wall-fluorecent-short.xml`, VehicleDD4's
  `loots/military20.xml`.
* Extra SafeZone scripts in the shop's decor (2026-11-17, our bug since 2026-11-14 `split_decor.py`): RoadSegmentH's
  roadside decor sat under its `SafeZone.lua` script, and each decor part copied the full parent chain, script
  included: every shop spawned 2 more SafeZone scripts (22 with the decor chunks). Each raises
  `level.safezoneLoadCount`, which `game/ParkingSpot.lua` reads as "the next shop has loaded" (`STOP_newSafezone`),
  so the shop's own decor most likely switched its parking spot off (inferred from the code, not tested in play).
  Now the decor parts and chunks carry that wrapper as a plain `<group>` (same placement: the script had no pos /
  rot); `split_decor.py` and `chunk_decor.py` turn script wrappers into groups (pos / rot kept). Verified with the
  MCP bridge: spawning an H decor part or chunk leaves the count at 0, the whole RoadSegmentH raises it to 1.
* Screens without a script (2026-11-17, original-mod bug): the gas station's two monitors (RoadSegmentH) and the ones
  in constructionCivillian4 (1), constructionCivillian8 (2) and construction4 (2) pointed at
  `MOD/script/infoscreen.lua`, which never existed (9dde6dd); Phase 3 removed the dead path, and a `<screen>` without
  a script logs `Script not found: data` every time one spawns (the "data" is the empty path resolved in the game's
  data folder). Found by spawning RoadSegmentH's parts one by one with the MCP bridge (the gas station alone gave the
  error twice, one per screen); now `script="MOD/game/BlankScreen.lua"` (a v1 screen script that draws nothing,
  same look). Verified: the same spawn no longer logs it. Also measured: an unprefixed `<script file="fx.lua">` (AVF
  tanks) does find the game's `data/script/fx.lua` (no error).
* Roadside decor in chunks, its own queue (2026-11-17, performance): `tools/porting/chunk_decor.py` cuts each decor
  part (~1600 shapes, ~0.2 s in one frame) into chunks of ~200 shapes (`roadsegments/decor/chunks/`, 316 files;
  every bush keeps its parent chain, the tool checks it; the original part files stay for the horde level, the
  credits and the debug tests). The decor waits in `VegQueue`, served only with what a frame has left after the
  ground and the segment file (two chunks fit in a frame), and the spawners no longer wait for it
  (`level.segment.loading` = ground only): with ~20 entries per segment one shared queue fell behind at driving
  speed. Behaviour change: bushes can appear a little after the road at speed. test_decor.lua.
* Segment files in chunks (2026-11-17, performance): `tools/porting/chunk_segments.py` cuts each segment's own file
  into up to 7 chunks (`roadsegments/chunks/`, 45 files, `SegmentFileChunks.lua`), spawned one per frame; the last
  chunk runs the after-spawn work (enemy spawns, scripts, veg thinning) with every chunk's entities. Lifts the static
  ground left under RoadSegmentH's SafeZone script (~4.6M cells, 0.23 s) into its own chunks; bodies, scripts,
  instances and groups holding joints / ropes stay whole. ENGINE: a prefab spawns only the FIRST child of `<prefab>`
  (measured: a chunk with three root groups lost its PuzzlePiece trigger and the road ended), so every chunk has one
  root. Verified 5.5 km at 25 m/s (every segment, H included). Still one frame each: M6's town, B1's wall, M7's camp.
* MP fixes, second round (2026-11-14, user's decisions; test_mpleads.lua, test_newlevel.lua; to re-test in MP):
  * Perks are the host's for everyone: a pickup (`server.invTake`) raises the perk in the host's savegame (before:
    the picker's own; a maxed perk still gives the picker $500); `game/newLeveltoLEVEL.lua` publishes the host's
    perks (`level.host.perks.*`, synced, -1 = none) and every other machine copies them into its own savegame, so
    the health, fuel and helicopter perk checks and the perk list read the same levels on every machine.
  * Debug menu host-only (`lib/Config.lua`: Backspace and its hint only on the host). Its settings that each
    machine reads (Infinite Ammo, Infinite Placetool Materials, No Hunger, No Thirst, God Mode) are the host's for
    everyone (`level.host.cfg.*`, copied like the perks); Heal / Die / overlays act on the host only.
  * Fuel-sale money goes to the player who sells (`vehicles/Fuel.lua`: summed per player, whole dollars sent with
    `client.fuelMoney`); before, the server wrote it into the host's money whoever sold.
  * Cultist ambush: a random living player on foot (`npcs/Cultist Spawner.lua`); before, only the host, and only
    while the host was on foot. Debug menu "ambush now" (2026-11-15, host; `savegame.mod.debug.ambush_now`) forces it on the next
    tick with a player on foot (normally every 5-27 min).
  * Server bullets fall again (`weapons/guns/gunnet.lua GunNet_ServerInit`): `gravity` was nil in the gun scripts'
    server realm, so the server's copy of each bullet (holes, NPC hits) flew without drop while the tracers fell
    (also in single-player, since the port's gun split). Restores v1.
  * Permadeath (Hardcore) in co-op: the run ends when ANY player dies (user, 2026-11-14; before: only the host's
    death, `GetPlayerHealth()` without an id). `game/Gamerule.lua`: a player counts once seen alive this level (a
    joining player can read health 0), the wipe runs once (host's perks, money, garage; `client.permadeathWipe`
    zeroes every player's own money) and the return to the main menu is latched (a respawn doesn't cancel it).
  * Leftover "Infinite" magazine (original-mod bug, same code in 9dde6dd; found in the MP test, not MP-specific):
    with Infinite Ammo on, an empty gun gets a fake 1-round "Infinite" magazine (`gunfunctions.lua
    checkUnlimitedBulletsValid`, all guns) that kept the old bullet list and is saved with the inventory. With
    Infinite Ammo off later, the first shot left a hole in the list and the gun's write-back (`table.concat`,
    PP19.lua:475) failed every shot before the shot cooldown was set: error spam and very fast, endless fire. Now
    the fake magazine holds exactly one bullet, and a leftover one is emptied while Infinite Ammo is off (the gun
    needs a reload). test_infinitemag.lua.
  * Remote players: no starter loadout and 0 hunger / thirst (starved at once). The main menu's new-game reset
    (`savegame.mod.inventory.init`, perks, bounty board) is written in the host's savegame only. Now the menu also
    writes a new `savegame.mod.runid`; `newLeveltoLEVEL.lua` publishes it (`level.runid`, synced) with the host's
    difficulty (`level.difficulty`); each non-host client that sees a run id it hasn't played does the per-player
    reset in its own savegame (inventory.init -> loadout and full vitals; perks; bounty board; money kept, as the
    host's on New Save) and mirrors the host's difficulty into its savegame every level (health / NPC / hunger rules
    read it on each machine). A save from before run ids gets one at its next level start.
  * `inventory.lua` vitals (original-mod bug, also v1): `GetFloat("savegame.mod.hunger") or 100` never used the
    default (GetFloat returns 0 for a missing key): a savegame without the keys started at 0. Now `HasKey`.
  * Game rules on remote clients: `newLeveltoLEVEL.lua` copied `savegame.mod.newLevel.*` to `level.*` without the
    sync flag, so `level.gamerule.*` (god, armored, helicopter, nhat, keepinv, permadeath) read as off on remote
    machines. Now synced.
  * Other players' melee weapons (2026-11-15, **[verified in-game]** by the user after the fourth round): the swing animation, its sounds and the hit particles
    ran only on the holding player's machine (v1 had one player), so the others heard nothing and saw the weapon
    in the engine's default third-person place: the handle's end at eye height pointing straight ahead, the hands
    reaching for nothing (user screenshot, all melee weapons). `weapons/melee/Melee_Functions.lua`:
    * Every machine poses each other player's melee weapon every tick, as the engine's own tools do
      (`data/script/toolanimation.lua`, `snowball.lua`): `SetToolTransformOverride` + `SetToolHandPoseLocalTransform`
      per player. The grip (`MELEE_GRIPS`, read off the .vox models: handle end at the origin, 0.05 m voxels) goes
      in the right hand at chest height (`MELEE_HAND`), tilted up 60 deg like the first-person view; two-handed
      weapons (Baseball Bat, Fire Axe, Katana, Damned Scythe) put the left hand further up the handle.
    * The holding client also queues "swing" (start, chop or sweep, the script's own time until it lands: Knife
      0.1 s ... Bat / Fire Axe 0.9 s) and "fx" (landed: hit or not, up to 8 hit points, hit colour) with its other
      melee ops; the server forwards them (`client.meleeRemoteOps`). The others play the swing / hit sound at the
      swinger, spawn the same particles, and swing the pose about the right hand (chop: raised to 110 deg, down to
      -20; sweep: right to left near level; the arm follows 0.2 m forward).
    * Each melee script: `MeleeNet_RemoteTick(dt)` at the start of client.tick, `MeleeNet_SwingStart` in Smash(),
      `MeleeNet_SwingFx` after its swing sound. Poses and grip points are first guesses from the model files.
      Second round (user screenshots): the fists sat beside the handle and the sweep led with the flat side; hand
      frames now turned as on the engine's sledgehammer (`data/prefab/tool/sledge.xml`: right (0, 90, -90), left
      (-90, 0, -60); two-handed: left hand at the handle's end, right further up), sweep rolled -90 deg about the handle.
      Third round: the hands still sat one handle-width to the character's right of the handle, and with the axe
      upright at the right side the left arm went through the body. Grips now on the model's centre line (x 0: the
      model is centred sideways, as far as the screenshots show), and two-handed weapons rest across the chest
      (`MELEE_HAND_2H`, rolled `MELEE_REST_ROLL_2H` = -35 deg: head up right, handle end down left).
      Fourth round: the weapon stayed at standing height when the player crouched (the override frame is fixed at
      standing eye height). The pose now adds the animated right shoulder's offset, as the engine's own tools do
      (`MeleeNet_ShoulderOffset`, from toolanimation.lua); it also carries the walk bob.
      Test: `test_meleenet.lua`.
* Spent casings capped (user decision 2026-11-15): only the newest 60 player-gun casings stay in the world, older
  ones are deleted (v1 kept every casing until RemoveRoad reached it 250 m behind). Each was a dynamic body synced to
  every player and moved by every world shift. `weapons/guns/gunnet.lua` `server.gunSpawnCasing` tags casing bodies
  `ml_casing` = spawn time (shared across the gun scripts) and `GunNet_CapCasings` deletes the oldest; prefabs not
  ending in `casing.xml` (RPG rockets) are not counted. Test: `test_gunnet.lua`.
* Starter kit seeded (MP test 2026-11-15: "the host gets the RPG kit every time"; original code, unseeded
  math.random): `player/inventory.lua InvSeedRandom` seeds the kit pick from the run id (host's own and published),
  the player id and the time. Test: `test_kitseed.lua`.
* Hardcore thirst (user OK 2026-11-15; original-mod bug, same in 9dde6dd): `inventory.lua client.update` set
  `SprintMultiplier = 0` when not sprinting, and Hardcore thirst is multiplied by it, so it drained only while
  sprinting. Now 1 (always), 2.5 while sprinting: 100 -> 0 in ~5.5 min standing, ~2 min sprinting. Other
  difficulties unchanged (they ignore the multiplier).
* God Mode blocks bleeding and fractures too (user OK 2026-11-15; v1 blocked only damage and healing):
  `AdvancedHealthScript.lua` clears both tags on the local hitboxes every tick in God Mode and doesn't set them
  (hits, falls; no bone-snap sound). Healing stays blocked in God Mode as in v1.

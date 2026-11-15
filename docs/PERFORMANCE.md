# Mors Longa Revival — performance

Part of the technical reference (index and conventions: [TECHNICAL_REFERENCE.md](TECHNICAL_REFERENCE.md)).
Marks: **[verified in-game]**, **[official source]**, **[unverified]**.

Phase 5 step 4 (2026-11-14/15). How generation and NPCs work otherwise: [SYSTEMS.md](SYSTEMS.md).

## Road generation and cleanup
* Roadside decor (2026-11-14, performance): in 16 of 20 road segments 73-98% of the ~3400 shapes were the `decor`
  group (about 42 bushes per segment, each 60-90 small rotated pieces), all built in the segment's one Spawn: the
  1-several-second freeze at each new segment. `tools/porting/split_decor.py` moved the decor into
  `prefabs/spawnables/roadsegments/decor/<Segment>_left/right.xml` (same parent chain as text, so every shape keeps
  its placement and the group defaults `collide=false`, `tags=veg`; the tool proves it, and is re-runnable), with
  the list in the generated `world/generation/DecorParts.lua`. GenerateRoad spawns the parts one per frame from the
  frame after the segment (`server.tick`, not the 60 Hz update that can run several times in one frame), shifts
  waiting parts with the world, thins them with the foliage setting as before, and skips them on Nightmare (it
  deletes all veg) or with the debug switch "spawn roadside decor" off. M8's animated derricks (script + joints)
  stay in the segment. The horde level and the credits prefab place the decor parts next to RoadSegment1.
  test_decor.lua. In-game tests then showed the decor was NOT the main cost (debug menu "Performance tests", left
  column: test spawns 40 m above the host; "piece by piece" spawns RoadSegment1 cut into its content groups by
  `tools/porting/perf_pieces.py` into `dev/perftest/`). User's ranking: hidden bedrock floor > terrain > sand; a
  1.6M-cell sand box, 1600 bush shapes, RemoveRoad's scan and deletes felt instant. A shape seems to cost by its
  whole (cropped) box, empty air included (engine not readable; reading of the tests).
* Segment weight (2026-11-14, user OK for all three):
  * `tools/porting/lighten_terrain.py`: the hidden unbreakable floors under the sand ("bedrock" voxagons, 4-8M
    cells; "unbreakable ground" voxboxes, up to 4M) became unbreakable plates of 40 cm voxels (scale 4, same top
    height, colour of the brush object): ~30x fewer cells. Behaviour change: only visible if someone digs
    through the sand. MorsLongaHill / MorsLongaDunes (cropped boxes 0.6M / 2.1M cells, 0.5-3.4% filled) are cut
    into cropped tiles (`assets/vox/terrainpieces/tiles/`, identical voxels). Placement rule from
    `blender_vehicle.py` (vox origin = bottom centre of the cropped model, x/depth centred by floor(size/2));
    voxagon vertex (a, b) = local (x, z), extruded up (checked against the sand boxes' edges). The tool checks
    every voxel's placement and the plates' cover before writing.
  * `tools/porting/split_heavy.py`: each child of a segment's `terrain` / `Background` groups (rocks: rock1.vox is 8
    solid rocks of ~1M cells per reference, up to 25 references per segment; tiled hills) became its own prefab in
    `prefabs/spawnables/roadsegments/parts/` (`HeavyParts.lua`), spawned one per frame after the segment, before
    its decor. Nothing under a script / vehicle / body moves (RoadSegmentH's shop script owns a Background group).
    The marker spawners (buildings, enemies, loot, vehicles, road signs, burnt bodies) wait while
    `level.segment.loading` is set. Horde level / credits prefab place the parts next to RoadSegment1.
  * Rocks still hitch after that (user: ~5 s of low FPS while a segment's rocks come in). Debug-menu tests with 10
    rock1.vox references in one frame (`tools/porting/rock_variant.py`, `dev/perftest/`): hollow (same boxes,
    filled 1.47M -> 0.51M) about the same; half resolution at twice the scale (box cells 7.4M -> 0.94M) much
    less. So box cells cost, filled voxels don't. Tiling barely helps rocks (compact: 32-voxel tiles 7.4M -> 3.3M
    cells, 8 -> 239 shapes). Fix (user: all rocks, as a graphics option like Disable Shadows): option
    "Low Detail Rocks" (Performance > Visual, `low_detail_rocks`, on by default; the host's, read at each spawn).
    `tools/porting/low_rocks.py` writes `assets/vox/terrainpieces/rock1_low.vox` (half resolution, node offsets
    halved; placed at twice the scale, within one original voxel) and, for each road-segment file using rock1.vox
    (129 split parts + RoadSegmentM4, whose rocks sit in its `ground` group / voxagon-holding background groups),
    a copy under `prefabs/spawnables/roadsegments/lowrocks/` with only those tags changed;
    `world/generation/LowRocks.lua` maps original -> copy, `GenerateRoad.lua` `RockVariant` swaps at Spawn. Re-run
    the tool after editing a segment or part (the mock test `test_decor` fails on a missing copy).
    rock1.vox is ONE rock cut into 8 octant models meeting at 0 (a model's centre voxel, size // 2, sits at its
    node `_t`). The first rock1_low reduced each model from its own (odd) edge: blocks straddled the cuts and left
    1-voxel gaps (user screenshot, big rocks). Now blocks follow the file's even coordinates and `rock_variant.py`
    checks that the pieces reproduce the reduced whole rock exactly (fails on the old file).
  * Debug menu "spawn activity" (Performance tests, host): on-screen list of what was spawned in the last seconds
    (segment, its parts / decor, buildings, roadblocks, enemies, vehicles, vehicle events, loot, road signs, burnt
    bodies, RemoveRoad's cleanup pass), segment parts waiting, NPC bodies (`Torso`). Each spawn writes
    `level.debug.spawned.<name>`; `ui/ConfigMenu.lua` TickActivity / DrawActivity. User (after Low Detail Rocks):
    hitches shorter, but big hitches turn into long stretches of lag: to match with this readout.
    Readout result (user screenshots): most lag stretches = a segment's parts spawning (segment < 1 s ago, part
    now, 4-8 parts waiting); two with nothing spawned for ~12 s (world shift added to the readout since); the
    spawners all fire in one frame when the parts are done.
  * Offline estimate of box cells (scratch script, low rocks; voxbox = its size, vox = cropped models): parts
    155.6M in all, a low rock part 0.92M; RoadSegment1's own file 5.9M (felt 0.5-1 s in the debug test). Segment
    files spawned in ONE frame: S1 84M (12 refs of hill1.vox / hill1r.vox: 22 thin terrace models, 5.85M per
    ref, 40-90% filled, tiling saves only ~25%), L1 37M (border wall voxboxes), B1 31M (+ part B1_002 19M: 4
    hills), F 30M, M4 28.5M (16 low rocks in its `ground` group, never split), M1/M2 17M (overpass voxboxes).
    Voxboxes may cost less than vox per cell (a 1.6M sand voxbox felt instant): not measured.
  * Pieces under a per-frame budget (user OK 2026-11-14; replaces one part per frame and the lowrocks copies):
    `split_heavy.py` also moved every rock1 / hill1 / hill1r / hill2 reference out of the segment files (M4's 16
    rocks, S1's 12 hills, B1's 2) into parts; `vox_pieces.py` wrote each placed model of those files as its own
    .vox with the same scene transform node (`assets/vox/terrainpieces/pieces/`: rock octants up to 1.27M cells,
    low 0.16M, hill layers up to 0.66M); `segment_pieces.py` cut every part into pieces (groups / compounds into
    children above 100k cells, model references into their pieces; rock pieces carry their low-detail element) ->
    `world/generation/SegmentPieces.lua` (2187 pieces, shared ancestor heads). GenerateRoad's queue spawns pieces
    from the frame after the segment, as many per frame as fit in the budget (250k box cells by default, debug menu
    "piece budget" 100k / 250k / 500k / 1M; at least one per frame), then the decor one per frame. Low Detail
    Rocks is now chosen per piece at spawn. A hill reference sits alone in a `<compound>`: each piece keeps a copy
    of it. To verify in-game: debug menu "rock: whole | pieces" / "hill: whole | pieces" (the cut copy +x of the
    whole: it relies on the engine placing a one-model file by its scene node like the full file).
  * Spawners one spawn per frame (`world/generation/SpawnSlot.lua`): RandomBuilding / Enemy / Loot / Vehicle /
    RoadSign / DeceasedBurnt stop for the frame when another spawn happened (`level.spawn.slot` vs GenerateRoad's
    `level.frame`); RandomBuilding's "big roadblock suppresses buildings" flag is global now (the loops may run in
    different frames).
  * Readout after the pieces (user screenshots, 2026-11-14): freezes at several moments: 0.5-1 s after a segment
    (segment file + RemoveRoad's cleanup pass, pieces still waiting), during the spawners (vehicle / enemy / loot),
    and 1 s after a world shift. The readout cannot time frames, so it got a slow-frame log: `GetTimeStep()` in a
    server tick (real time since the last frame per the API doc; a cap, if any, is unknown) > 50 ms -> logged with
    everything stamped since the previous tick and what it was (`level.debug.what.<name>`: file, piece cells).
    Result: the list stayed EMPTY during visible lag: the server tick's GetTimeStep() is capped / fixed. Moved to
    the host's client (client.tick GetTimeStep(), spawns of the last 0.35 s from `shared.activity`), with the
    current / 5 s max frame time and the server dt on screen to learn what each reports.
  * Scripts cannot time a freeze: GetTimeStep() is capped at 1/30 s on server AND client (readout: 33 ms, max 33
    ms, while the game's counter showed 4 FPS). The slow-frame log was removed again.
  * BUG FIXED (user 2026-11-14): "no collision on the bottom layer, once the top layer is broken off you and
    everything else fall through" (later segments; the starting segment's floor is the level's own). Debug menu
    "probe ground (aim)" (every shape along the line of sight + a 1 m box under the first hit: material, palette
    entry, size, voxel size, collision layer/mask, static/dynamic, tags) on that layer: the 40 cm plate
    (250x250x1 @0.4 m, coll 1/255, unbreakable) was hit by the raycast, but GetShapeMaterialAtPosition found NO
    voxel there (material "", palette 0). One-voxel 40 cm (scale 4) shapes are not reliable floors. Fix:
    `lighten_terrain.py --replate` rebuilt every coarse:* group from its original in git HEAD at 10 cm with the
    original thickness (voxagon extrude / voxbox height, top at the same height): 447 plate files, 4125 plates,
    1.7-7.9M cells per segment, so `split_heavy.py` moves the coarse:* groups into parts and they stream as
    pieces, FIRST in each segment's queue. `segment_pieces.py` bundles small siblings into one piece up to 100k
    cells (RoadSegment3 / M8: 1325 thin plates from diagonal outlines). Lesson: don't use scaled one-voxel shapes
    for anything that must hold the player. User verified: the floor holds (2026-11-14). Deleted with the user's
    OK: the 209 old 40 cm plate files, `HeavyParts.lua`, `LowRocks.lua`, the `lowrocks/` copies and
    `low_rocks.py` (all superseded; never committed). 27 floor groups moved into parts (2837 pieces now, SegmentPieces.lua 960 KB);
    RoadSegmentH's floor stays in its segment (under the shop `<script>`, which owns it). Horde level and credits
    prefab also place RoadSegment1_006 / _007 (its floors).
* Continuous cleanup (2026-11-15, user: "everything should be gradual and continuous", also for cheaper shifts; no
  fade on shifts: the user prefers to see them). `world/generation/RemoveRoad.lua` was one pass deleting
  everything 250 m behind the rearmost player after each new segment (a segment's shapes in one frame). Now a
  sweep in server.tick: per frame it checks up to 600 objects of the current phase (shapes, bodies, triggers,
  joints, vehicles; each phase listed once with Find*) and deletes at most 120, with v1's per-object rules; it waits
  3 frames after each world shift (positions half-updated: near objects would look 200 m further behind).
  Test `test_removeroad` (rules, gradual, shift wait, no players). User: smooth.
  Regression found 2026-11-15 (user: debug vehicle events "just don't appear"): the convoy / chase events spawn at
  x -300 and drive in; players live between x ~-107 and 93 (shift past 93, pointOreturn at 292.9), so the event is
  past the deletion line whenever the rearmost player is past x ~-45, and the every-frame sweep deleted it within a
  second (v1 checked only after each new segment, giving it time to drive in). Fix: every event spawn
  (`RandomVehicleEnemy.lua addSpawnedVehicleXMLToRegistry`) tags its bodies / triggers `ml_grace` = spawn time, and
  the sweep skips them for `CLEANUP_GRACE` = 90 s (`InGrace`). Test: test_removeroad.lua. Vehicle events drive in
  again **[verified in-game]** (user, MP, 2026-11-15).
* Gradual generation (2026-11-15, same request). `split_heavy.py` now also moves ALL static geometry out of the
  segment files (highest subtrees made only of group / vox / voxbox / voxagon / vertex / compound / light, outside
  scripts / vehicles / bodies; one part per parent): 347 more parts. What stays in a segment file: markers,
  triggers, scripts, joints / ropes, vehicles, dynamic bodies, and buildings with dynamic parts attached (M6 mosque,
  M7 quarantine buildings: up to 5.6M cells). `segment_pieces.py` orders each segment's pieces by their position
  along the road (pos / rot of the chain composed; QuatEuler order Y, Z, X), nearest first: 4376 pieces,
  SegmentPieces.lua 3.4 MB. GenerateRoad `QueueSegment`: pieces, then the segment FILE (dynamic objects after the
  ground under them; `SpawnSegmentFile` does v1's after-spawn work: veg thinning, scripts, enemy spawn count incl.
  M6 / town override, shop refresh, the level.roadgen pulse, raised by the next server.update as in v1), then the
  decor; a segment is queued at 300 m (v1: 200). Foliage thinning (ManageVegDeleting) applies to every piece (veg
  shapes of the segment files are pieces now). Bug fixed: Nightmare queued no pieces (floors / rocks missing since
  the pieces). RoadSegmentF refers to 226 never-shipped `Voxel/probs/...` files (original; the engine skips them).
  User (2026-11-15): far fewer big hitches; some hitches remain (one right after a segment file + its spawners);
  large parts deleted in sight. Fixes: RemoveRoad judges shapes / triggers by their bounds' far end (v1: origin,
  a 200 m road / sand box with its origin at its back corner went while its front end was ~50 m behind); and
  `segment_pieces.py` cuts voxboxes over 200k cells into tiles whose starts are whole multiples of the brush repeat
  (brush model size: MagicaVoxel x / y / z -> local x / z / y; sand 256 x 256, highway road 162 x 100), positions
  rotated with the box, all other attributes kept: sand boxes -> 25.6 m tiles, roads -> 30 m lengths; 5766 pieces.
  User next: steady FPS while driving feels low (22-29 shown), ground visible beyond the boundary wall. Not
  measured yet whether more content is alive now (look-ahead 300 m, long objects kept until their far end passes).
  Readout shows alive shapes / bodies and the leader's x; debug "generate ahead" 200 / 250 / 300 m to compare.
* User observation (2026-11-15, after the segment / spawner timing changes): more starter-vehicle variety, enemy
  events not seen before near the start, a double-rotor helicopter falling. Checked: spawn lists, chances and
  event timers are unchanged (diff vs HEAD: only the loading wait, one spawn per frame, readout stamps, the
  renamed vehicle-events switch). No event spawns a flying CH-47 (the heli event is AS350 only); in normal play
  the CH-47 appears as the rare special building constructionSpecial2.xml (3%: a crash site with loose dynamic
  parts placed above ground) or from the spawn menu (its flight script is still v1). Not verified: the mod never
  seeds math.random, so picks follow the order of random draws; the new spawn timing changes that order per run,
  which would explain the variety (the old timing may have repeated the same draws every run). The readout's
  vehicle_event line names the event file since.
* BUG FIXED (introduced by gradual generation, 2026-11-15; user screenshot: a pile of identical roadblock
  checkpoints on one spot). A deleted PuzzlePiece trigger is still returned by FindTriggers until the end of the
  frame, and server.update runs 2-3 times per frame below 60 FPS. v1 raised level.roadgen at once, which skipped
  the extra updates; with queued segments the pulse comes when the file spawns, so the extra updates queued the
  SAME segment again: overlapping duplicate segments (roadblock markers on one spot, double enemies / vehicles /
  pieces), also inflating the performance readings of that period. Fix: GenerateRoad `UnusedPuzzlePieces()` skips
  triggers already used until they are really gone (handles can be reused later); test in test_decor.
* Hidden floors under the sand of every road segment: rectangles of 10 cm plates with the original thickness
  instead of the polygon voxagons (performance, user OK 2026-11-14; `tools/porting/lighten_terrain.py`; the 40 cm
  plates of the first version let players fall through and were replaced). They appear in the frames after the
  road (before the rocks); diagonal outline edges are covered by small steps (up to one 10 cm cell of overhang). A segment's rocks,
  hills and roadside decor appear over the frames after the road (one prefab per frame), and the segment's cars,
  buildings, enemies and loot right after that.
* New option "Low Detail Rocks" (Performance > Visual, on by default, user decision 2026-11-14): the road segments'
  rocks at half resolution (20 / 60 cm / 1.2 m voxels instead of 10 / 30 / 60 cm), blockier and breaking in
  coarser chunks; off = the original rocks. The host's setting decides for everyone (the server spawns the world).

## NPCs
* NPC cost (Phase 5 step after generation, 2026-11-15). Survey of the per-tick Lua work (server, per NPC):
  `tick_npcs` recomputes mass and voxel count of every body/shape of every NPC (alive or dead) each tick;
  `npc_find_random_enemy` calls FindBodies("Heli") per call ("todo optimize" in v1) and loops all NPCs;
  `npc_navigation_update` serializes two positions into the registry per NPC at 60 Hz (util.serialize) and each
  NPC's goreai_initializer.lua reads/writes its nav state through a registry-backed structured table every tick;
  `tick_bones` re-sets bone tags every tick; `update_npcs` runs the robot movement (raycasts) and the gun / head
  constraints at 60 Hz. Engine-side: ragdoll physics and constraints. Scripts cannot time any of it (frame time
  capped), so the measurement is the game's FPS: debug menu "10 NPCs ahead" (Performance tests) places 10
  RandomRagdoll markers 25-35 m ahead (RandomEnemy spawns them; v1 cap: 14 living NPCs), then the Gore NPCs
  switches turn parts off: Thinking enabled, Run and Navigate, Script enabled (limp ragdolls = physics only),
  Delete All NPCs (baseline). Cuts follow the numbers.
  User result (10 NPCs): none 40 FPS, 10 NPCs 25, Thinking off ~25, Run and Navigate off 25, Script enabled off
  40-45, deleted 40-45. So the cost is the always-on per-NPC work or the physics of ragdolls kept standing (limp
  ragdolls sleep), not thinking / navigation. Test-only skip switches (Performance tests, `npccost.*`):
  bookkeeping (mass/voxel recount), health, standing/walking (npc_robot_update: feet/hover raycasts and forces),
  head/jaw/gun holds (constraints), per-NPC path scripts (goreai_initializer.lua).
  User result: each of those five alone ~25 FPS (no change). Tested one at a time, so the ragdolls stayed awake
  (standing off still left the holds on). Added: "other server systems" (every goreai_main server system except
  tick_npcs / update_npcs / tick_spawning) and "NPC client side" (goreai_main client.tick + client.draw). Next
  round: all switches together, standing + holds together (physics asleep), the two new ones alone.
  User result (10 NPCs, 25 FPS = 40 ms/frame vs 25 ms without NPCs): all skips 40 FPS; standing + holds 30
  (~7 ms); other server systems 27 (~3 ms); NPC client side 28 (~4 ms). BUT the user's save had the mod's
  "Debug Mode" (config.db, default off) ON: then GoreAI_PublishNPCs sends a FULL record of every NPC (path, debug
  fields) every 0.1 s and each client rebuilds them and draws per-NPC debug UI each frame, which is what the
  "systems" and "client" switches skipped. To re-measure with Debug Mode off before cutting.
  Debug Mode off (user): no NPCs 40 FPS (25 ms), 10 NPCs 30 (33 ms: ~8 ms), all skips 38-40, standing + holds
  only 35 (~5 ms). So ~5 ms = keeping ragdolls upright (Constrain* solver work, feet / hover / ground raycasts,
  awake physics; server.update runs 2-3 times per frame when a frame is slower than 1/60 s), ~3 ms = the rest.
  Cuts (same results, test_npcperf): no mass recount (read nowhere after init); voxels counted for living npcs
  only (only their health reads them); FindBodies("Heli") once per tick (GoreHelisTick); robot_pos written after
  0.5 m of movement or a world shift, startPos no more (the path script computes it from robot_pos); bone tags
  set once per npc / setting change; path script writes its state only on change. The constraint work is how
  these npcs stand (same in v1): reducing it means a behaviour change (e.g. lighter work for far npcs).
* NPC research (2026-11-15, user: "better research into optimizing these AI scripts", look at GYMP).
  GYMP = "[GLaD] GYMP Ragdoll Framework" (Workshop 3668043935, installed): v2 ragdoll / gore / medical framework
  (server-side per-ragdoll `lua/gore.lua`, ragdoll pool, client UI). Its walking soldier example is the official
  robot script adapted (v1 `update`: hover raycasts + Constrain* on limbs, like our robot / feet / hover code). Its
  performance pattern: tiered update rates per ragdoll: motor control (standing / walking constraints) every
  update; physical stats (mass / voxels), falling, bleeding, state machine, registry sync every 10th update; tags,
  special states, drowning, blood paint every 100th; idle ("still") ragdolls apply no forces; disabled ones delete
  their own script; avoids global FindBodies (registers its parts in the registry). Ours runs most bookkeeping
  every tick / update. Measurement tool: debug "NPC call profile" (`systems/goreai_profiler.lua`, names from
  `lib/EngineApiNames.lua`, generated from script_defs.lua): counts every engine call and npc_* / tick_* / robot /
  feet / hover function of goreai_main per frame and per living NPC, top 26 on screen (host).
  TEARDOWN HAS A BUILT-IN PROFILER (user, 2026-11-15): SHIFT+ALT+F3 (F3 hides it): CPU ms per engine part and per
  Lua script; pause the game and click a script for per-function detail. It runs one update per frame, capped at
  60 FPS. First reading (2 NPCs): CPU 9.9 ms; physics 0.36, rendering 0.67, scripts 2.95 (server) + 5.11; top
  scripts inventory.lua 1.30, goreai_main 0.95, RemoveRoad 0.57, AdvancedHealthScript 0.37, ConfigMenu 0.26
  (debug readout), MLSandbox 0.26, daynight_main 0.21. Call profile (10 NPCs): 16k engine calls per frame, of
  which QueryRejectBody 8242 (1030 per NPC): TDSU RejectAllBodies looped QueryRejectBody per handle and was
  called before most npc raycasts with NPC_Bodies = every body of every npc ever spawned (never pruned).
  Fixes (same results): RejectAllBodies / RejectAllShapes use QueryRejectBodies / QueryRejectShapes (one call);
  NPC_Bodies pruned to live bodies once a second (tick_cleanup_leaks); inventory.lua SaveInventory, which runs
  every frame (original: updateCounter stays 0) rewriting ~240 slots, now writes only changed slots plus a full
  rewrite once a second (test_invsave); RemoveRoad sweep 600 -> 200 objects per frame.
  Second reading (10 NPCs): CPU 29.5 ms: scripts 15.1 (server) + 10.4 (client), physics 1.6, rendering 1.1;
  goreai_main 5.8 (tick 4.2 + update 3.6 avg, peaks 15-18), inventory 1.85, AdvancedHealthScript tick 0.35 avg
  with random peaks to 1.8 (likely Lua garbage collection; it also searched the level for two hitbox triggers
  every tick: now kept while valid). The script detail view only splits by callback, so the call profiler is now
  `lib/CallProfiler.lua` (any script): it attributes each engine call to the innermost wrapped script function;
  used by goreai_main (debug "NPC call profile") and inventory.lua (debug "inventory call profile", client).
  Profiles after the reject fix (8 npcs alive): goreai_main 6353 engine calls / frame (was ~16k). By function:
  npc_point_gun 542, npc_constrain_head_towards_pos 495, npc_process_shield 441 (the damage intake of EVERY npc:
  2 registry floats per body part per tick), feetUpdate 429, npc_check_if_can_see_target 418, npc_get_voxels 296,
  robotUpdate 294, hoverUpdate 248, npc_is_valid 240, npc_turn_towards 232, npc_projectile_operations 226,
  npc_process_thinking 176, npc_run_assist 155, npc_get_mass 155 (robotUpdate summed the mass every update).
  Top engine functions: Vec 531, VecLength 466, HasKey 462 (registry-backed tables: config, nav state),
  GetBodyTransform 397. inventory.lua: only 180 engine calls / frame, so its 1.85 ms is Lua work: Split 261 /
  frame (GetDimensions 127 / frame from the weight total, 2 splits each), getItemType 127, InvToolEnable 100.
  Cuts (same results): GetDimensions cached per item string (pure: constant table + attList of the string);
  robotUpdate recomputes mass when npc.voxels changes (or once a second); `config` in goreai_main wrapped by
  MemoConfig (each field read from the registry once per frame, writes through). Next candidates (behaviour /
  timing questions): shield damage reads only when damage is pending, line-of-sight raycasts at a lower rate,
  voxel recount every few ticks (GYMP: every 10th update).
  Third reading: inventory.lua 1.85 -> ~0.5 ms. goreai_main 8.7 ms with 10 npcs, but probably taken with the
  call profile ON (every engine call wrapped): re-measure with it off. WITHOUT npcs: CPU 16.3 ms, scripts 3.8
  (server) + 8.7 (client): many scripts at 0.2-0.5 ms each (MLSandbox 0.55, AdvancedHealthScript 0.51,
  creativemode 0.35, RPG 0.27, Offroad_WMIK 0.27, playerbody 0.21, ...; the list is not sorted by cost and was
  cut off). MLSandbox (the engine sandbox copy) listed every tool and set its ammo for every player each tick:
  now every 0.5 s. Each of the 52 gun scripts runs GunNet_ClientTick, checkUnlimitedBulletsValid and an
  inventory check every frame even when not held (~10 engine calls each): a candidate once the full list shows
  what the 8.7 ms is made of.
  Fourth reading (call profiles off). 10 npcs: CPU 26.8, scripts 15.2 (server) + 6.1 (client), physics 3.0,
  goreai_main tick 4.5 + update 4.4 avg (peaks 16); the enemy prefabs hold only goreai_initializer (0.55 ms for
  10), so the +11 ms of server scripts with npcs is essentially goreai_main. No npcs: CPU 18.0, scripts 4.2 +
  10.6 (client); the user: unrelated weapon scripts take 0.2-0.5 ms each. Fix: the 36 gun scripts with an
  inventory check return from client.tick right after GunNet_ClientTick + WeaponBackgroundTick when the gun is
  not in the player's inventory (GunIdleNote in gunfunctions.lua). `weapons/guns/craftingrecipes.lua` is loaded
  by nothing and does not compile (original, unchanged).
  Fifth reading (no npcs): client scripts 10.6 -> 6.5 ms after the idle-gun exit; spikes: RemoveRoad 2.27 (its
  FindShapes of ~10k shapes each pass), daynight_main 1.85. Fixes: RemoveRoad's shapes phase uses
  QueryAabbShapes for the region behind the line, a full FindShapes only every 30 s (non-colliding shapes might
  not be returned by queries); inventory: the held tool read once per frame (was ~50 GetPlayerTool), weapon-wheel
  keys written on change; daynight_main: FindLights("Campfire") once a second (server and client), its four
  SYNCED registry keys (sent to every client) written on change instead of every tick. creativemode.lua and
  playerbody.lua are the engine's (added to every 2.x level). Audit tool `tools/porting/tick_audit.py`: per-frame
  callbacks and the same-file functions they call, costly-call counts x XML references (a reading list; the
  engine's profiler gives real times). Its top items checked: fakegore (only on breakage), the heli crews' Gore
  Ragdolls 2 scripts (scoped searches every update, small subtrees).
* Result of the NPC tiers (user, 10 npcs): "they seem to work the exact same", ~10 FPS more; goreai_main ~5 ms
  (tick 3.2 + update 4.0 avg in the profiler's one-update-per-frame mode; in play below 60 FPS the update runs
  2-3 times per frame). Physics 3.6 ms with 1086 bodies in that fight (debris, ragdoll parts). Declined by the
  user: far-NPC rest (immersion). The remaining NPC cost is the AI's real work (thinking, standing, aiming joints).
* NPC rate tiers (2026-11-15, all four approved by the user; GYMP-style):
  1. Damage only when hit: npc_process_shield reads / resets the per-body-part damage values only when
     level.goreai.damage_pending is set; all 7 writers of level.goreai.body_damage_* set it (gunfunctions, melee,
     npc bullets in goreai_combat, AS350 HeliV2 / Weapons, Hind Weapons, AVF shells; test_npcperf checks every
     SetFloat(path_damage) has the flag); tick_npcs takes and clears it before the npcs (a hit written later in the
     tick is read on the next one). Without a pending hit: no damage flags, the kill-credit timer still advanced
     once per body part as in v1.
  2. Ground raycasts every 2nd physics update per npc (hoverUpdate / feetUpdate): between them the hover distance
     = last distance + the torso's movement along its up axis, foot step candidates kept; forces every update.
  3. Line of sight 5x per second (SEE_INTERVAL 0.2 s, staggered start). Original-mod bug: the interval was read
     with GetFloat("savegame.mod.config.goreai.see_timer"), a key never written (the 0.5 default exists only in the
     config table), so it was 0: every npc raycast every tick. v1 meant 0.5 s in attack range, 2.5 s in hunt range.
  4. Voxel recount every 3rd tick per npc (staggered): voxel loss is applied at the next count (<= 2 ticks later).
* NPC timing (2026-11-15, user OK, performance): NPCs check their line of sight 5 times per second (v1: every tick
  because of the unset see_timer key; v1's intent was 0.5 s / 2.5 s), damage from lost voxels registers up to 2
  ticks later, standing ground raycasts every 2nd physics step, body-part damage read only after a reported hit.

# Mors Longa Revival — technical reference

Everything learned while porting Mors Longa to Teardown 2.x co-op (`#version 2`), grouped by topic.
Facts are marked **[verified in-game]**, **[official source]** (game files / official mods / API docs) or
**[unverified]**. `docs/PORTING.md` is the short checklist for converting one script; this file is the detail.
The day-by-day test log that used to be here (crash hunt tests A-N, readouts, dead ends) is in git history
(`git log -p docs/TECHNICAL_REFERENCE.md`, commits up to "phase 3"); §11 keeps a short summary.

Contents: 1 Sources · 2 Workflow · 3 v2 engine rules · 4 Server/client-only API · 5 Guns · 6 Vehicles ·
7 Systems (how the port works) · 8 Original-mod bugs fixed / behaviour changes · 9 Shelved and dead content ·
10 Open questions · 11 History

---

## 1. Sources

| What | Windows path |
|---|---|
| Repo (branch `revival` = the port; `original` = untouched Workshop copy; `main`) | `C:\Projects\Mors Longa` |
| Teardown install | `C:\Program Files (x86)\Steam\steamapps\common\Teardown` |
| Subscribed Workshop mods | `C:\Program Files (x86)\Steam\steamapps\workshop\content\1167630` |
| Local mods the game loads | `%USERPROFILE%\Documents\Teardown\mods` (repo linked in as "Mors Longa Revival") |
| Crash dumps / live log | `%LOCALAPPDATA%\Teardown\crash\`, `%LOCALAPPDATA%\Teardown\log.txt` |

* Teardown 2.2.0 on the user's PC (API docs 2.1.0). The original v1 mod (Workshop 2906369984) is installed too.
* Remote: `git@github.com:OfficialSirH/Mors-Longa-Revival.git` (SSH; the user commits and pushes).

Best primary sources, in order:
1. **`Teardown/data/script_defs.lua`** [official source]: every API function with signatures, docs, examples
   (`grep -n -B25 '^function Name(' data/script_defs.lua`). It does not mark server/client-only (§4).
2. **Engine scripts** `Teardown/data/script/` and `data/ui/hud.lua` [official source]: `include/player.lua`,
   `toolanimation.lua`, `robot.lua` (v2 AI: Constrain*, QueryPath, explosion events from server callbacks),
   `spawn.lua` / `creativemode.lua` (DisablePlayerInput, SetPlayerHidden per tick). For UI behaviour read
   `hud.lua`, not only the API docs (§3 PauseMenuButton).
3. **Official vehicles** `data/built-in/prefab/vehicle/` (passenger `seat` locations) and the official example mods
   in `Teardown/mods/`: `minigun` (prefab tool, the gun template), `lasergun` (vox tool), `vehiclepack`.
4. Workshop MP mods: 3621598329 Multiplayer C4 (prefab tool, `invisible` tag), 3662075963 Tripmine (minimal tool
   prefab), 3625899189 Zombiedown (mplib survival, NPCs), 3668043935 GYMP Ragdoll Framework (v2 ragdolls; no AI).
5. mplib: https://github.com/tuxedolabsorg/mplib. The API web page truncates in WebFetch; use script_defs.lua.

---

## 2. Workflow

* The user tests in-game (single-player until Phase 5) and sends screenshots of red error text. Rounds are small,
  with exact steps and in-game names (§5 table).
* Agent runs on the user's PC: Git Bash + PowerShell, no system Lua or Python. Per session:
  * Lua 5.1: build from `https://github.com/lua/lua` (`git checkout v5.1.1`;
    `clang -O1 -w -o lua51.exe $(ls *.c | grep -vE '^(luac|print|ltests)\.c$')`, LLVM is installed).
  * Python: a venv in the session scratchpad (`python -m venv`); `python3` is not on PATH.
  * In a cloud container instead: Lua 5.1 via `gcc -O1 -w -DLUA_USE_POSIX -o lua51 ... -lm`; `texlua` (Lua 5.3)
    can run `check.lua` / `toplevel.lua` when nothing else is available.
* **Line endings**: most repo Lua/XML files are CRLF, some are LF (e.g. `script/gunperks.lua`, the tests, most
  python tools). Edit via python on bytes: detect the file's ending, normalise to `\n`, assert replacement counts,
  write back in the original ending. git-bash `sed -i` turns CRLF into LF.
* **Shell gotchas**: in Git Bash heredocs, `\n` inside python string literals can arrive as real newlines → write
  python edit scripts with the Write tool or edit with the Edit tool. `md5sum $VAR` with an empty variable waits on
  stdin forever → add `< /dev/null`.
* Converters (`tools/porting/patches/convert_*.py`) rebuild their files from a git base each run and assert every
  edit. **Hand edits to a converter-owned file are lost on the next full run**: put every change into the converter
  (happened twice: sprint fix in AdvancedHealthScript, infinite-ammo note in gunfunctions). After changing a
  converter, run it fully and compare md5 of all its files before/after.
* Tools and mock tests: `tools/porting/README.md`. Run all tests from the repo root after every change.
* Converter traps seen: a v1 callback with leading whitespace (` function init()` in AC130) escapes the rename
  regex and silently never runs in v2; a loose grep for includers matched `ModConfig.lua` as `Config.lua` (use
  `#include "([^"]*/)?Config\.lua"`).
* Older sessions ran in a cloud container with a device shell on the PC: files went PC → container via
  `.git/claude-xfer/` + `device_stage_files`, back via `device_commit_files` from a fresh directory (re-using a path
  delivered stale files), with md5 compared on both sides.

---

## 3. v2 engine rules

### Script model [official source unless marked]
* `#version 2` must be the first line; without it a script is silently disabled in MP (still runs in SP).
  `info.txt` needs `version = 2`. v1 and v2 scripts coexist in SP [verified in-game].
* Callbacks: `server.init/tick(dt)/update(dt)/postUpdate/destroy`, `client.init/tick(dt)/update(dt)/postUpdate/
  draw/render(dt)/destroy`. Plain `init/tick/update/draw` globals are not called. `server.handleCommand(cmd)` and
  `client.handleCommand` exist (data/script/main.lua, spawn.lua).
* No engine API calls while a file loads (top-level code, including `#include`d files): "Calling the LoadSound API
  function before init is not supported". Pure math (`Vec`, `Quat`) at top level is fine. `tools/porting/toplevel.lua`
  finds them.
* An `#include`d file has no `#version` line of its own (only the entry script). A v1 library included by v2 scripts
  must not define `init/tick/draw` that leak into includers: rename them (Config.lua → `ConfigMenu_*`,
  menu_main.lua → `MainMenu_*`).
* **The host's server and client halves do NOT share Lua globals** [verified in-game]. Client code gets server data
  only via `shared`, synced registry keys or `ClientCall`, also on the host. (SP testing used to hide this.)
* **v1 `draw()` can contain game logic** (GoreNPCs aim alignment, which gated NPC shooting). Scan draw functions
  for state writes when splitting.
* `shared`: server writes, clients read (synced). Nested tables with string keys + `pairs` on clients are used
  (CarAlarm, goreai_netview, horde) and work in SP [verified in-game]; MP unverified. Write whole sub-records,
  only on change.
* `ServerCall("server.fn", ...)` / `ClientCall(playerId, "client.fn", ...)` (0 = everyone); the function must be in
  the same script. A ClientCall from a script that is deleted in the same tick is lost [verified in-game: rocket].
  A client has no caller id on the server: pass `GetLocalPlayer()` as an argument (client-trusted). Table
  arguments are used by `gunnet.lua` and work in SP; plain numbers are the safe choice.
* Registry: `SetX(key, value, true)` syncs to clients. `savegame.mod.*` is per machine; the host's client and
  server share it [verified in-game: main menu writes difficulty on the client, Gamerule reads it on the server].
* `#include "script/include/player.lua"`: `Players()`, `PlayersAdded()`, `PlayersRemoved()`. playerId arguments:
  on a client omitted/0 = local player; on the server omitted/0 = host.
* Entity handles: test `~= 0`, never `> 0`. Events: `playerhurt`, `playerdied`, `explosion` (`pos, strength`, as
  robot.lua), `projectilehit` (server).
* Effects from server callbacks (PlaySound, SpawnParticle, PointLight, Draw*) are the engine's own pattern
  (ammo.lua, lightning.lua, tank.lua; GYMP). Whether remote clients see/hear them: MP unverified.

### Hard-won rules [verified in-game]
* **`Constrain*` only in `server.update`.** From tick (v1 tolerated it) it crashes the v2 engine on a worker thread
  within minutes (teardown.exe +0x60966F / +0x6092F1 / +0x60E604). This was the long crash hunt (§11).
* **Scripts are not linked to their objects**: `GetEntityChildren(script, ...)`, `GetEntityParent(e, "", "script")`
  and `GetProperty(script, "file")` return nothing. `Spawn` returns the script handles too and `Delete(script)`
  works, so keep Spawn's result to clean up a prefab's scripts (GenerateRoad segment groups).
* The engine resets the walking speed every frame: set `SetPlayerWalkingSpeed` every server.tick (sprint fix).
* Clients cannot delete/re-parent/move entities the server created ("invalid attempt to access server authored
  entity from client script"); world changes (Spawn of persistent things, SetBodyTransform of shared bodies,
  MakeHole, damage) go through the server.
* `DisablePlayerInput(p)` + `SetPlayerHidden(p)` every server.tick freeze and hide a player (NPC controller, menu
  scene); the client can still read that player's InputDown/Pressed for its own use.
* v2 players have a visible body (in the world and in vehicle seats); v1 scripts that faked a player model
  (PlayerVehicleSeat) or let the player walk unseen now show doubles.
* `PauseMenuButton(title, true)` = the one primary mod button below "Main menu" (per game, all mods share it);
  `"main_top"` adds above it; `"main_bottom"` is documented but never drawn by hud.lua.
* `level.roadgen` (set by GenerateRoad after a segment spawn) is a one-frame pulse: throttled readers must latch it.

### Errors seen in-game → cause

| Message | Cause | Fix |
|---|---|---|
| `Calling the <X> API function before init is not supported` | API call at load time (top level / include) | move into init or load lazily |
| `invalid attempt to access server authored entity from client script` | client touched a server-created entity | let the engine build it (tool prefab) or do it on the server |
| tool invisible, bullets from the wrong place | RegisterTool prefab without `tool_space` + `<body>` | tool prefab layout (§5) |
| engine "General crash", empty Lua stack, worker-thread access violation | Constrain* called from tick | call from server.update |
| `attempt to index local 'perktable'` in a gun | round with no bullet type (unlimited ammo on an empty gun) | `GunPerkFor` fallback (§8) |

### Signature traps from v1
* `GetPlayerTransform(true)` → `GetPlayerTransformWithPitch()`; `SetPlayerTransform(t, true)` →
  `SetPlayerTransformWithPitch(t)` (the extra argument is now a playerId).
* `Ui*` (incl. `UiMakeInteractive`) only inside `client.draw()`.
* `Shoot(origin, dir, [type], [strength], [maxDist], [playerId])`; `QueryShot(origin, dir, maxDist, [radius],
  [playerId])` → `hit, dist, shape, playerId, damageFactor, normal`; `GetPlayerAimInfo(pos, [maxDist], [playerId])`.
* `Quat(x, y, z, w)` builds a quaternion from 4 numbers (used to pass rotations through ServerCall).

---

## 4. Server-only / client-only API [official source: API 2.1.0 headings]

**Server only:** SetVehicleParam DriveVehicle SetVehicleHealth SetPlayerTransform SetPlayerTransformWithPitch
SetPlayerGroundVelocity SetPlayerSpawnTransform SetPlayerSpawnHealth SetPlayerSpawnTool SetPlayerVehicle
SetPlayerVelocity ReleasePlayerGrab SetPlayerScreen SetPlayerHealth SetPlayerRegenerationState SetPlayerTool
RespawnPlayer RespawnPlayerAtTransform SetPlayerWalkingSpeed SetPlayerCrouchSpeedScale SetPlayerHurtSpeedScale
SetPlayerParam RegisterTool SetToolAmmoPickupAmount SetToolAmmo SetToolEnabled ApplyPlayerDamage DisablePlayerInput
DisablePlayer DisablePlayerDamage Shoot Paint PaintRGBA MakeHole Explosion SpawnFire RemoveAabbFires SetTimeScale
SetEnvironmentDefault SetEnvironmentProperty AddHeat SetGravity, **StartLevel** (official server.startLevel pattern;
verified with the pause button and main menu).

**Client only:** InputClear InputResetOnTransition SetPlayerCharacter SetPlayerCameraOffsetTransform
SetToolHandPoseLocalTransform SetToolTransform SetToolAllowedZoom SetToolTransformOverride SetToolOffset
SetPlayerRigTags SetSoundLoopUser PlaySoundForUser AddMapMarker SelectedMapMarker GetCameraTransform
SetCameraTransform RequestFirstPerson RequestThirdPerson SetCameraOffsetTransform AttachCameraTo SetPivotClipBody
ShakeCamera SetCameraFov SetCameraDof DisableMotionBlur SetLowHealthBlurThreshold, haptics, all `Ui*`.

Everything else (queries, Find*, Get*, Spawn, Delete, sounds, particles, body/shape setters) works on both sides,
subject to the authority rule in §3. The mock engine (`tools/porting/tests/mockengine.lua`) flags wrong-side calls
from these lists.

---

## 5. Guns

### Tool prefab layout [official source: minigun, Tripmine, C4]
```xml
<prefab version="2.0.0">
  <group name="instance=MOD/prefab/mytool.xml">
    <group name="eye_space"> <!-- optional ToolAnimator poses: fp_action, tp_action, tp_run, ... --> </group>
    <group name="tool_space">
      <body dynamic="false">
        <vox file="MOD/vox/mytool.vox" scale="0.4"/>   <!-- one <vox> per shape, in index order -->
      </body>
      <location name="muzzle" tags="name=muzzle" pos="..."/>
      <location name="tp_action_rh" tags="name=tp_action_rh ik_hand" pos="..." rot="..."/>
    </group>
  </group>
</prefab>
```
* `RegisterTool(id, name, file, [group])` on the server; tools start disabled: `SetToolEnabled(id, true, p)` per
  player (`PlayersAdded()`). The engine builds the tool body on every machine; a client may animate those shapes
  (`GetToolBody`, `GetBodyShapes`, `SetShapeLocalTransform`); shape order = `<vox>` order; re-read when the body
  changes. Viewmodel: `SetToolTransform` (client).

### How Mors Longa guns work (v1, kept in v2)
* 38 gun scripts in `script/` (2-3.7k lines, ~95% one template): own `FireRound(Type)` (was `Shoot`), `Reload`,
  `ShootGrenade`, huge tick (controls + viewmodel by part index) and draw (HUD, attachment/mag UI).
  Shared: `gunfunctions.lua` (projectile sim, grenades, ADS, LoadTool, `checkUnlimitedBulletsValid`),
  `gunperks.lua` (ammo stats per calibre/type, `GunPerkFor`), `gunstats.lua`.
* Inventory ↔ gun via registry: `inventory.guns.<n>.item` = `_`-joined: `[1]` tool id, `[3]` mag id, `[4]` mag name,
  `[5]` ammo, `[6]` max, `[7]` display calibre, `[8]` attachments, `[10]` per-round bullet types `-`-joined; plus
  `inventory.curprimary`, `inventory.update_guns<n>`. The inventory fills missing bullet types with
  `GunDefaultBulletType` on pickup.

### v2 gun design (current)
* All gun logic runs on the holding player's client as in v1 (client-trusted). Projectiles are simulated twice by
  `ProjectileOperations`/`GrenadeOperations`: the server for world effects (`doWorld`), every client for visuals
  (`doFx`). `script/gunnet.lua` carries shots, melee holes, casings, the shooter id (`projectile.owner` →
  `level.goreai.body_damage_player_owner`).
* Gun scripts are **static** level scripts (group `GunScripts` in the level xmls; v1 spawned them per equip);
  each checks `GunInInventory(id)` before acting.
* Two model kinds: **vox guns** (27, multi-object `.vox`, engine-built) and **LoadTool guns** (AK74, FiveSeven,
  G17, G18 [G17 model], M107, M4A1 [M4 model], M870, MP5, TT33): registered with a generated
  `script/Weapons/<GUN> Tool.xml` (`tools/porting/make_tool_prefab.py`):
  * parts in **reverse** Base.xml order (v1 index i = i-th part from the end: GetBodyShapes lists the last attached
    first);
  * each part built in its own lane (24 m grid, 10 columns) because **overlapping parts lose voxels** in an
    engine-built tool [verified in-game]; `GunNet_FixToolParts()` moves them back on the client (per part, only while
    `|x - lane_x| < 12`);
  * parts tagged `ml_toolpart unbreakable`, skipped by `GunRaycast`; Base.xml parts without `file=` get the
    wrapper's vox filled in.
  * Camo variants are generated but not registered (known gap).
* Debug overlay (any v2 gun): **Ctrl+O** part index labels, **Ctrl+L** part table (local pos, voxel size, rot).
  Offline render: `tools/porting/render_gun.py`.
* RPG-7: hand-converted `script/RPG.lua`; the rocket (`script/grenade.lua`) is spawned by the server (§7).
* Scope look tweak (`SetPlayerTransform(ppos2, true)` in some rifles) disabled; TODO via `SetToolAllowedZoom`.
* Original quirks kept as-is: PKM's own projectile sim has no NPC damage; FiveSeven hand indices 18-29 exceed its 26
  parts; Jalaad init matches `ak-762x54` mags but its tick `m107-127x99`; no MC9 mag #3 item exists.

### Gun scripts → in-game names (HUD shows the RegisterTool name)

| Script | Tool id | Name | Model | | Script | Tool id | Name | Model |
|---|---|---|---|---|---|---|---|---|
| AK101 | gun-ak101 | Simonov-556 | vox | | MP43 | gun-mp43 | Mudafie | vox |
| AK50 | gun-ak50 | Jalaad | vox | | MP5 | gun-mp5 | MC9 | LoadTool |
| AK74 | gun-ak74 | Simonov-545 | LoadTool | | MosinNagant | gun-mosin | Medvedev | vox |
| AK74M | gun-ak74m | Simonov-106 | vox | | MosinNagantM | gun-mosinm | Medvedev Military | vox |
| AKM | gun-akm | Simonov-762 | vox | | P90 | gun-p90 | TMP-90 | vox |
| CZ-1012 | gun-cz1012 | CZ-1012 | vox | | PKM | gun-pkm | PKM (shelved) | vox |
| Dessert Eagle | gun-deagle | Deagle | vox | | PP19 | gun-pp19 | Simonov-9 | vox |
| FiveSeven | gun-fiveseven | TCP-57 | LoadTool | | PPSh | gun-ppsh41 | PPSh-41 | vox |
| G17 | gun-g17 | P17 | LoadTool | | RPG | gun-rpg | RPG-7 | vox |
| G18 | gun-g18 | P17A | LoadTool | | SCAR-H / -Hg | gun-scarh / -hg | TCR-308 | vox |
| G3 | gun-g3 | MC308 | vox | | SCAR-L / -Lg | gun-scarl / -lg | TCR-556 | vox |
| G36 | gun-g36k | MK36 | vox | | SG553 | gun-sg553 | Bauer-553 (shelved) | vox |
| KS23 | gun-ks23 | KS23 | vox | | SKS | gun-sks | SKS | vox |
| M107 | gun-m107 | N107 | LoadTool | | SV98 | gun-sv98 | SV-98 | vox |
| M16 | gun-m16 | N16 | vox | | SVD | gun-svd | Drozdov | vox |
| M4A1 | gun-ar15 | N4A1 | LoadTool | | Sawed Off | gun-sawedoff | Qasira | vox |
| M870 | gun-m870 | N870 | LoadTool | | TT33 | gun-tt33 | TT-33 | LoadTool |
| M9 | gun-m9 | M9 (shelved) | vox | | VECTOR | gun-vector | SCALAR | vox |

Melee (8, `scripts/Weapons/Melee/`, `convert_melee.py`): client = input/animation/raycasts/fx; world effects
queued in `Melee_Functions.lua` and sent once per frame to `server.meleeOps(ops, playerId)`.

---

## 6. Vehicles (Phase 4)

* [official source] Driver: `<location name="player" tags="player"/>` (+ `player_steeringwheel`); passengers: one
  `<location name="seat" tags="seat"/>` per seat; exits: `<location tags="exit"/>`. Seats are hand-placed inside the
  vehicle's parts (not a mirror of the driver position). API: `GetVehicleAvailableSeatPos`,
  `GetVehiclePassengerCount(v)` → `count, seats, hasDriver`, `IsPlayerVehicleDriver/Passenger(v, p)`,
  `SetPlayerVehicle(v, p)` / `DriveVehicle` (server). `SetVehicleHealth` needs the `customhealth` tag.
* Mors Longa: 264 vehicle xmls have a driver location; only `prefabs/spawnables/vehicles/Vehiclewg30.xml` and the
  Hind have a seat → **other players cannot ride along yet; seats are added per vehicle in Phase 4** (user decision).
* `scripts/Game/PlayerVehicleSeat/` (fake driver model for the v1 invisible player) is no longer loaded: v2 draws
  the driver itself (user saw two bodies). Still referenced by test.xml / test_vehicle.xml only.
* GoreNPCs has its own NPC sitting system: lights tagged `seat` (`goreai_sitting.lua`), separate from engine seats.
* AVF (mounted guns, tanks, technicals: `avf/`, ~42 scripts + `avf/scripts/Immersive_Tank.lua`) is still v1 and
  needs the external AVF mod, which has no MP version ("ERROR: AVF MOD NOT ENABLED" popup when entering such a
  vehicle without it). Plan: own v2 mounted-gun script reading the existing AVF tags
  (`mainCannon component=gun weaponType=... interact=mountedGun`).
* Helicopters (`main/AS350`, `main/Boeing_CH47-C`, `main/Mil-Mi-35P-Hind`, incl. their `gorefunctions.lua` sitters)
  last. Small vehicle scripts still v1: `Vehicles/!library/scripts/door.lua` (28 xmls), drive/steer/drivetrain,
  `scripts/bike.lua`, GAZ-24 lights/radio, jetbus.

---

## 7. Systems (how the port works)

Level entry points: `main.xml` (menu) → `level.xml` / `level_no_shadow.xml` → `level_instance.xml`; scripts in
`level_scripts.xml` (also `level_scripts_spawn.xml`, `level_tutorial.xml`, `level_horde.xml`: keep the four in sync).
Libraries: `scripts/TDSU/tdsu.lua` (+ `compat.lua`, which replaced UMF), `Settings.lua`/`Settings_Table.lua`
(`savegame.mod.settings` via `util.structured_table`, reads the registry live), `Config.lua` (debug menu library;
level script `scripts/ConfigMenu.lua`), `Automatic.lua`.

### World generation (`Procedural/`)
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
  `ConvoyOperatorTransport.lua` (server, target = nearest living player; helpers `scripts/vehicleOperatorCoop.lua`).
* Playable world is ~400 m long (shadow volume 400x25x200), which is why the shift and the straggler limits exist.
* `fix_missing_scripts.py` repointed 76 XML references to never-existing scripts to `missing_script_stub.lua`.
  Leftover log noise: `<instance file="MOD"/>` (empty) in RoadSegment1237/4/5.xml ("Could not find prefab");
  "Script not found: data" (source unknown).
* Operators' v1 `queueRemoval()` (pause-menu-button trick to find its own script) cannot work on the server: those
  scripts set a finished flag and idle instead (`OpFinished`, initializers, heli smoke). Still used by v1
  `avf/scripts/Immersive_Tank.lua`.

### NPCs (GoreNPCs)
* One manager script `GoreNPCs/scripts/goreai_main.lua` (spawned once by the first of 152 NPC prefabs'
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
* Explosion damage: engine `explosion` events; shield absorbs first, the rest hurts health (§8).
* Not ported: projectile-impact debug dots (server hit list), gore test map spectator cameras, debug `n`
  (navigate to crosshair).
* Leak fixes: dead NPCs leave the table, NPCS_TO_DELETE emptied, spall shells emptied (`tick_cleanup_leaks`),
  initializers stop when their torso is gone.
* Performance: ~30 NPCs at once ≈ 18 FPS (512 active bodies), same as v1; possible later optimization.
* Other NPC scripts: SleepingRagdoll (wakes for any player), StandingRagdoll (shop trader; looks at the nearest
  player; killing it halves the nearest player's money), `fakegore.lua` crew ragdolls in vehicles/helicopters.
* Edits live in `patches/convert_goreai.py` (base 6c28435); hand-written: goreai_main, killcam, players, netview,
  controller. The converter also owns gunfunctions.lua, Melee_Functions.lua and AdvancedHealthScript.lua edits.

### Player: health, inventory, hitboxes (Phase 2 design, verified)
* Health (`HealthSystem/AdvancedHealthScript.lua`) and inventory (`script/inventory.lua`) run on each player's
  **client**. The server does world ops only: pickups (`server.invTake`, first request wins), drops, tool enabling
  (per player: enable-all setting OR always-allowed list OR wanted by that player's inventory; covers ListKeys ∪
  requested ids, since melee ids are not in ListKeys), `SetPlayerHealth`, walking speed (re-applied every tick).
* `scripts/PlayerHitboxes.lua` (server): the host keeps the level's six `hitbox` triggers, other players get a
  spawned set (`hitbox_player=<id>`); `QueriedDamage` → `client.hitboxDamage`; health uses local `localhitbox`
  triggers. Death: one death request + one ragdoll (`server.healthDied`), death camera `launchragdoll.lua` (client).
  Because SetPlayerHealth is a ServerCall, the client keeps a "dying" state (no reheal until the engine health
  reached 0 and came back; resend after 2 s) — without it a ragdoll spawned every tick.
* Gun scripts are static; ToolManager.lua is a no-op (tool enabling is in inventory's server.tick).
* Money and the bounty board are per player (client savegame); perks/garage/difficulty are the host's savegame.

### Menu, tutorial, debug menu
* Main menu (`main.xml`, `patches/convert_menu.py`): client UI; level starts are host-only through
  `MenuStartLevel` → `server.startLevel` (`scripts/UI/MainMenu/menu_host.lua`); others see greyed buttons.
  `menu_main.lua` is a library (entry `main_menu.lua`; also included by `ingame_settings.lua`). Character select
  camera is per client; `RotateScene.lua` hides all players. Tab on the main menu = dev level list.
* Tutorial (`scripts/Tutorial/`): per-player tips/hurt warning/inventory reset on the client; triggers, holes and
  the ending on the server (`shared.ending`). `tutMedTV.lua` (screen script) stays v1.
* Debug menu (Backspace; `Config.lua`): Debug Mode, Gore NPCs debug overlays, NPC Controller, Vehicle Events,
  Auto Travel (1/5/10/20 km at 40 m/s, `server.configTravel`), Infinite Ammo, spawn menu (`Weapons → Testing`
  holds items only test.xml had). Pause menu: one primary button "MorsLonga Menu".
* Spawn menu (`scripts/UI/SpawnMenu.lua`) lists only what is in the loot tables `Procedural/SpawnRefrenceTable.lua`
  (`spawnables.loots`; menu-only category `debugTest`); spawns go through `server.spawnMenuSpawn` with a per-player
  undo history. Debug-menu spawns: `ConfigSpawn` → `server.configSpawn`.

### Other converted systems (all v2, verified unless noted)
* Shop segment: SafeZone, PerkMachine (client pays, `server.perkBuy`, refunds), ParkingSpot garage (one shared garage
  in the host's savegame, `shared.garage`), WarehouseScript_Cultist, AC130 supply plane — **awaiting test**.
* RPG rocket `script/grenade.lua` (server): impact ray from the previous position (close-range hits), explodes at
  the hit point, proximity fuse for any player, loaded rocket type via `server.rpgNextRocket` (sizes: PG-7V 0.6,
  OG-7V 1.0, PG-7VT 1.0, PG-7VA 2.0).
* World props (convert_props.py): debris, parachute, warehouse collapse, Binge shrine, heli crash smoke, crew
  ragdolls (batch D — **awaiting test**). Grenades, PlaceTool, Weld, meds, Airstrike, daynight/sandstorm, Fuel,
  ShootFromCar, CarAlarm, Thermals/NVGs, mines, doors, Book, SpawnMenu: Phase 1.

---

## 8. Original-mod bugs fixed, behaviour changes

Bugs fixed (all present in the original Workshop mod):
* Guns: `Split(nil)` crash in client.init (RPG in sling); empty-mag / empty-tube HUD concat (all guns, N870, Mudafie,
  Qasira); camo nil on gun switch (9 LoadTool guns); round without bullet type after turning on Unlimited Ammo with
  an empty mag (`checkUnlimitedBulletsValid` → `GunPerkFor` falls back to the calibre's default round, all 35 guns);
  Sawed Off gated on the MP43; Bauer-553 never called WeaponInit.
* Inventory: `invSlot.rotation` nil for special slots; partial stack use not recounting; material deficit stored
  under the wrong key; `clearItem` outside the grid when dying mid-heal; PKM missing from the script lookup.
* Loot/spawn tables: 4GA ammo unreachable; broken entries (KS23 #2, .50BMG, P17 Grey); tutorial IFAK id
  (`meds-bleed-general-ifak`).
* World: RandomVehicleEnemy `whichone` nil (AAF below 5000 m); military truck never spawning (order of distance
  checks); Cultist ambushes never fired (`GetPlayerVehicle == 0`); pause button in an undrawn slot; parachute /
  horde DebugPrint spam; StandingRagdoll undefined `fwd1` on death; heli crew quickload hook calling an undefined
  function; npc_die reading a missing gun loot string (horde); NPC table / to-delete list / spall shell leaks.
* NPCs never shot after the split (aim alignment in draw) — port issue, fixed. Killcam missed single-shot kills
  (head mark cleared one tick early).

Behaviour changes decided by the user:
* Own grenades hurt the player (v1: they did not).
* Ordinary NPCs take explosion damage (v1: only boss shields); the RPG fires the loaded rocket type (v1: always PG-7V).
* Enemy cars keep v1 explode rules ("always explode" was tried and reverted).
* Cultist on-foot ambushes on.

---

## 9. Shelved and dead content

* Guns PKM, M9, Bauer-553 (unfinished: missing mag items, wrong mags, pre-ammo-system code); MGL launcher +
  `MGLgrenade.lua`. Revisit after the port.
* **Horde mode** (user: unfinished; revisit after the main game): unreachable in the original (its character-select
  stop sits in an unused `layer="horde"` of main.xml). The v2 conversion exists (`convert_horde.py`, test_horde.lua:
  WaveHandler → `shared.horde`, per-player HordePlaceTool) but is not exposed.
* Custom difficulty (also an unused menu layer, code commented out).
* Test-only levels stay v1: test.xml, lol.xml, test_*.xml, procgen and gore-map test levels, `main.lua`.
  `prefabs/other/Credits.xml` (thiccparticle.lua) is never spawned. `script/craftingrecipes.lua` has a syntax
  error and is never loaded. ~478 Lua files exist, ~316 reachable; `unused/` is dead.

---

## 10. Open questions and known gaps

MP-only (need the Phase 5 private Workshop upload):
* Pause button primary slot shared with other mods; main menu for non-hosts; straggler teleport.
* Server-side sounds/particles/tracers reaching remote clients; `shared` nested tables on remote clients; entity
  handles sent client→server referring to the same entity (melee, PlaceTool, Weld, NPC controller).
* Per-player tools/hitboxes; a client's savegame (money, bounty) in MP; host player id (0 vs 1; routing works
  either way via `GoreAI_IsMe`).

Known gaps:
* Money from selling fuel is written on the server (host's registry).
* Camo variants of LoadTool guns not registered; scope zoom tweak disabled.
* Remote players don't see/hear other players' melee swings.
* Leftover scripts from non-segment spawns (NPC initializers, vehicles) accumulate ~20/km (no measured cost).
* Unconfirmed in-game: tutorial sprint, gun switching, the two-line tip, the IFAK death drop, tutMedTV; batch B
  shop scripts; crew ragdolls; boss health bars.
* KS23/N870 start a reload with 0 reserve ammo (v1 behaviour).
* Unverified for vox guns: whether gun melee (MakeHole at the stock) or a first bullet raycast can damage the
  engine-built tool body (only LoadTool parts are tagged `ml_toolpart unbreakable`).
* Seen once, cause unknown: Simonov-545 ADS tilted left after RPG use (fixed by re-equipping).

---

## 11. History (summary)

* 2026-11-03: plan agreed; UMF replaced by `scripts/TDSU/compat.lua`; tools started.
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
  (all verified unless listed in §10); horde converted then shelved; PlayerVehicleSeat retired; passenger seats
  moved to Phase 4.

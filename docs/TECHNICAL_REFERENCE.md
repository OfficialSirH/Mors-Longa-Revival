# Mors Longa Revival — technical reference

Everything learned while porting Mors Longa to Teardown 2.x co-op (`#version 2`), grouped by topic.
Facts are marked **[verified in-game]**, **[official source]** (game files / official mods / API docs) or
**[unverified]**. `docs/PORTING.md` is the short checklist for converting one script; this file is the detail.
Day-by-day test logs (crash hunt tests A-N, vehicle / mounted-gun / AVF / AS350 test rounds, readouts, dead ends)
are in git history (`git log -p docs/TECHNICAL_REFERENCE.md`); §11 keeps a short summary.

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
3. **Official vehicles** `data/built-in/prefab/vehicle/` (seat rigs), the player characters `data/prefab/player/`
   (used by the Blender mannequin) and the official example mods in `Teardown/mods/`: `minigun` (prefab tool, the
   gun template), `lasergun` (vox tool), `vehiclepack`.
4. Workshop MP mods: 3621598329 Multiplayer C4 (prefab tool, `invisible` tag), 3662075963 Tripmine (minimal tool
   prefab), 3625899189 Zombiedown (mplib survival, NPCs), 3668043935 GYMP Ragdoll Framework (v2 ragdolls; no AI).
   Suggested by the user 2026-11-14: 3813115423 Halo: Firefight (2-4 player co-op with AI and vehicles; its notes:
   each machine keeps its own `savegame.mod`, the server's registry is the host's, server writes clients read go
   out with the sync flag, per-player settings are sent by that player's client); 3406671087 Metal Softball Bat
   (client-side objects simulated in Lua without server authority, the server only forwards messages; clock sync
   by Cristian's algorithm, RTT, fast-forwarding; `GetTime()` is not synced between machines; its notes say that
   since patch 21900075 `ServerCall` must name its function as a string literal in the call itself, so a
   reassigned ServerCall or a variable name fails; ours all use literals); 3775653892 Castdown (a global gamemode:
   `gamemodes.txt` with `path = castdown.lua`; the official `mods/contentgamemodeexample` shows a content gamemode,
   `layers = race`, and notes that sandbox.lua disables itself while a gamemode runs). Official docs:
   teardowngame.com/modding, /modding-mp (registry, savegame and tools in MP are not covered there).
5. mplib: https://github.com/tuxedolabsorg/mplib. The API web page truncates in WebFetch; use script_defs.lua.

---

## 2. Workflow

* Agent runs on the user's PC: Git Bash + PowerShell, no system Lua. Per session:
  * Lua 5.1: build from `https://github.com/lua/lua` (`git checkout v5.1.1`;
    `clang -O1 -w -o lua51.exe $(ls *.c | grep -vE '^(luac|print|ltests)\.c$')`, LLVM is installed).
  * Python 3.13 is installed (`python`; `python3` is not on PATH).
  * Blender 5.2 with Blender MCP (`mcp-for-blender`, server registered in the repo's `.mcp.json`, telemetry off):
    the user starts it in Blender (N panel → "MCP for Blender" → Start MCP Server). Used for vehicle seats (§6).
* **Line endings**: the repo is **LF** since 2026-11-08 (`.gitattributes`: `* text=auto eol=lf`, assets binary; one
  normalizing commit, history before it is CRLF). Git stores any stray CRLF as LF on commit, so editors/tools can't
  cause whole-file diffs any more. Converters read old commits (CRLF) and always write LF. Teardown's own files are
  CRLF; LF mod files load fine (in-game smoke test 2026-11-08: menu, run, vehicles, guns).
* **Shell gotchas**: in Git Bash heredocs, backslash escapes inside python string literals get mangled → write
  python edit scripts to a file with the Write tool, or use the Edit tool. `md5sum $VAR` with an empty variable waits
  on stdin forever → add `< /dev/null`. A python `open(..., 'wb')` on a file the user has open can fail with
  "Invalid argument" (the file stays intact): retry with the Edit tool.
* Converters (`tools/porting/history/`) are **frozen since 2026-11-14**: during Phases 1-4 the rebuild converters
  regenerated their files from a git base each run (hand edits were lost on the next run); now their output files
  are ordinary source and edited directly. Never re-run a rebuild converter. `add_seats.py` is still used.
* Tools and mock tests: `tools/porting/README.md`. Run all tests from the repo root after every change.
* `#include` lines are handled by Teardown before Lua parses the file: an include inside a `--[[ ]]` comment still
  loads, and one naming a missing file keeps the whole script from loading (the WMIK and GMG offroad configs never
  loaded in v1). The mock engine drops includes, so test_avf_cannon.lua checks that every include line of the converted
  configs resolves.
* Converter traps seen: a v1 callback with leading whitespace (` function init()` in AC130) escapes the rename
  regex and silently never runs in v2; a loose grep for includers matched `lib/ModConfig.lua` as `lib/Config.lua` (use
  `#include "([^"]*/)?Config\.lua"`).

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
  must not define `init/tick/draw` that leak into includers: rename them (lib/Config.lua → `ConfigMenu_*`,
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
* **`<screen script="...">` scripts run as v1**: with `#version 2` the `client`/`server` tables don't exist
  ("attempt to index global 'client'", Cadillac dashboard `dash.lua`, 2026-11-09). Kept v1 for now (`dash.lua`,
  `tutMedTV.lua`, the helicopter screens). The engine disables v1 scripts in multiplayer (user, 2026-11-09), so these
  screens are blank in MP: open item in §10.
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
| `attempt to index global 'client' (a nil value)` in a `<screen>` script | screen scripts run as v1, no `client` table | keep the screen script v1 |
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
        <vox file="MOD/assets/vox/mytool.vox" scale="0.4"/>   <!-- one <vox> per shape, in index order -->
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
  (`doFx`). `weapons/guns/gunnet.lua` carries shots, melee holes, casings, the shooter id (`projectile.owner` →
  `level.goreai.body_damage_player_owner`).
* Gun scripts are **static** level scripts (group `GunScripts` in the level xmls; v1 spawned them per equip);
  each checks `GunInInventory(id)` before acting.
* Two model kinds: **vox guns** (27, multi-object `.vox`, engine-built) and **LoadTool guns** (AK74, FiveSeven,
  G17, G18 [G17 model], M107, M4A1 [M4 model], M870, MP5, TT33): registered with a generated
  `weapons/guns/Weapons/<GUN> Tool.xml` (`tools/porting/make_tool_prefab.py`):
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
* RPG-7: hand-converted `weapons/guns/RPG.lua`; the rocket (`weapons/guns/grenade.lua`) is spawned by the server (§7).
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

Melee (8, `weapons/melee/`, `convert_melee.py`): client = input/animation/raycasts/fx; world effects
queued in `Melee_Functions.lua` and sent once per frame to `server.meleeOps(ops, playerId)`.

---

## 6. Vehicles (Phase 4)

### Engine facts
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

### Seat placement rules (learned in-game)
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
  legs toward the rig's foot points (§7). Nothing per seat for NPCs; every rig needs `ik_head` for a natural pose.
* Copies of Teardown 1.x vehicles take the official 2.x rigs (below); other mod vehicles are measured. Variants usually share the layout, sometimes shifted (UAZ modified +0.2 m, white +0.6/+0.2,
  emergency +0.1/+0.1).

### Workflow and tools
* Blender (§2) + `tools/porting/blender_vehicle.py`: import (vox node rotations applied), `show_only`,
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
  sports car far forward, saloon a bit), which led to NPCs copying the player's pose (§7).
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
  `locationspawn` (refugees: `enemies/refugees/Ragdollrefugee1.xml`, path fixed §8); shot stand-ins become limp sitters.
  Triggers differ (v1 design, kept by user decision 2026-11-08): ambushes (`chaseOperatorTransport.lua`) unload within
  25 m of a player or once the driver is gone; refugee vehicles (`ConvoyOperatorTransport.lua`, debug "Refugees") drive
  along the road past the player and only unload after the driver stand-in is shot, the vehicle has slowed below
  2 m/s and a player on foot is within 10 m.
  Enemy and event vehicles (`prefabs/spawnables/enemy vehicles/`) get seats too: once their crew is dead the operator
  scripts remove `nodrive` and players can drive them (first skipped as "NPC vehicles", corrected 2026-11-08). Their
  crews are voxel ragdolls sitting in the seats: hide them before ray checks. VehicleC3 (refugee UAZ event) asks
  an older `uaz452.vox` (objects `body`, `door fl`...): its van was invisible in-game; rebuilt and seated (§8).
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

### Status (passenger seats)
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
| Mobile crane | `vehicles/cars/Constuction vehicles/mobile_crane.xml` (spawn menu entry added, §8) | 1 | official rig (`crane_medium_yellow`); verified SP |
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
| ZIL-131 transport ("AAF Transport truck") | `vehicles/cars/Soviet Vehicles/ZIL131.xml` (+ Vehiclewg33, roadblock9) | 4: cab 2 + cargo side benches 2 | measured, upright; paths fixed (§8); verified SP |
| ZIL-131 ZU-23 ("AAF Truck Technical") | `vehicles/cars/Soviet Vehicles/ZIL131_ZSU23.xml` | 2 (cab; gunner with the mounted-gun work) | as ZIL131; verified SP |
| Bus (+ damaged, Modified, JetBus) | `vehicles/cars/bus/bus*.xml`, `jetbus.xml` (Destroyed: static wreck) | 4: driver + front rows (one rear-facing); Modified: driver + 3 floor; JetBus: driver + 2 on the wheel arches (engine fills the cabin) | measured, upright; verified SP |
| PAZ-3205 ("Soviet Bus", + damaged) | `vehicles/cars/Soviet Vehicles/paz 3205*.xml` (+ event copy VehicleC2, see the enemy row) | 4 | measured, upright; verified SP |
| American semi (+ damaged, Modified, Special) | `vehicles/cars/semitruck-us/Semi*.xml` (Destroyed: static wreck) | 4: cab 2 + 2 on the lower sleeper bunk (facing the middle) | measured, upright; verified SP |
| Flathead semi (+ damaged, Mod) | `vehicles/cars/semitruck-flathead/Semi*.xml` (spawn menu "Semi Flathead" added, §8) | 2 (no room for more: engine hump, bunks 0.7 m apart) | measured, upright; verified SP |
| SportsCar offroad | `vehicles/cars/sportscar/sportsoffroad.xml` + copy in constructionCivillian12 | 2 | official rigs (`sportscar_green`, overlap 0.78); verified SP |
| Cement truck | `vehicles/cars/Constuction vehicles/cement_truck.xml` (road spawner Vehiclewg42; spawn menu "Cement Truck" added, §8) | 2 | measured, upright; verified SP |
| Tractor From Hell ("TRACTOR") | `vehicles/cars/Constuction vehicles/tractorFromHell.xml` | 1 (like the official tractor) | measured, upright; verified SP |
| Volga (white) | `vehicles/cars/Gaz24/volgawhite.xml` (road spawner Vehiclewg18; spawn menu "Volga" added, §8; Destroyed: wrecks) | 4 | measured, tilt 55; verified SP |
| Microcar (+ damaged) | `vehicles/cars/microcar/microcar*.xml` (road spawners Vehiclewg38, wb30; spawn menu "Microcar" added, §8) | 2 | measured, tilt 55; verified SP |
| Monster Compact | `vehicles/cars/microcar/monstercompact.xml` | 4 (rear cramped) | measured, tilt 55; verified SP |
| Ford Falcon XB GT (+ damaged) | `vehicles/cars/MadMax2/1973 Ford Falcon XB GT*.xml` (road spawners Vehiclewg21, wb19; spawn menu "Ford Falcon" added, §8; Destroyed: wreck) | 4 (right-hand drive; rear cramped) | measured, tilt 55; verified SP |
| Pursuit Special | `vehicles/cars/MadMax2/Pursuit Special.xml` | 4: driver, a sideways seat on the left door (ledge + door panel, faces the driver; user spotted it in-game), 2 on the rear floor | measured; verified SP |
| Military truck (UM Damaged; plain, Damaged) | `vehicles/cars/military_truck/Milltary_Truck*.xml` (UM Damaged in roadblocks 8/9; plain one now spawn menu "Military Truck", §8; Destroyed: wrecks) | 4: cab 2 + 2 on the cargo bed floor (no benches) | measured, upright; verified SP |
| RV MethLab ("Bad RV") | `vehicles/cars/RVMethLab/MethLab.xml` (road spawner Vehiclewg26; spawn menu path fixed, §8; MethLab Enemy: unused) | 4: cab 2 + 2 on the rear bench (facing the aisle) | measured, upright; verified SP |
| BugZilla ("Monster Bug") | `vehicles/cars/1963 VW Beetle BugZilla/BugZilla.xml` (Destroyed: wreck) | 3: driver + 2 floor (stripped; engine/fuel tank in the back) | measured, tilt 55; verified SP |
| Golf cart + "Nuclear Golfcart" | `vehicles/cars/Based Vehicles/golf_cart*.xml` (road spawner Vehiclewg45; Bomb in the spawn menu) | 2 | measured, upright (wheel far ahead: arms stretched); verified SP |
| Small red boat | `vehicles/cars/Based Vehicles/smallboat_red.xml` (road spawner vehicleS13; spawn menu "Small Boat" added, §8) | 4: stern (driver, no steering wheel), middle seat 2, bow 1 facing back | measured, upright; verified SP |
| "Shed?" + Garage | `vehicles/cars/Based Vehicles/SHED.xml`, `GARAGE.xml` (vehicleS11/S12; Garage copy in dev/levels/test.xml) | 4: driver on the chair + 3 on the floor | measured, upright; verified SP |
| Wheeled Cockpit | `vehicles/cars/Based Vehicles/wheeledcockpit.xml` (spawn menu; vehicleS10) | 2 (pilot + copilot; no yoke in the model) | measured, upright; verified SP |
| AS350 helicopter: AAF Attack Heli (MILITARY), Insurgent Attack Heli, parked copies, CIV (gore map), VIP | `vehicles/aircraft/AS350/AS350_*.xml` (+ 2 copies in dev/levels/test_misc.xml). Not a vehicle in the original (Heli.lua teleported the pilot every frame): add_seats.py `WRAP_VEHICLE` wraps the Heli.lua `<script>` content in `<vehicle name="AS350" tags="player_nogears player_nosteeringwheel" sound="0" topspeed="0" acceleration="0">` (no car sounds or driving animations) and `VEHICLE_EXITS` adds an `exit` location beside the pilot door | 4: pilot left front (the AI pilot ragdoll sits right) + 3 on the rear bench; Insurgent: no left front cushion (open door-gun side), third bench place 0.1 lower | measured, upright, nose at body +z (rigs turned 180); verified SP 2026-11-13 |
| LeBoat (sailboat) | `vehicles/cars/Based Vehicles/sailboat.xml` (spawn menu; vehicleS14) | 4: driver standing at the left ship's wheel (user request; first version sat between the two wheels) + 3 on the side benches | measured; verified SP |
| Enemy/event copies: AAF Truck (VehicleAAF1, ZIL-131), Civillian Jeep (VehicleC1, Jeep), Civillian Bus (VehicleC2, PAZ), Insurgent Ambush 8 (VehicleD8, Ural) | `prefabs/spawnables/enemy vehicles/Vehicle{AAF1,C1,C2,D8}.xml` (inline copies) | as their models | those models' layouts (AAF1, C1 shifted 0.05-0.1 m); seat rays identical with the crew hidden; awaiting test |
| Insurgent chase cars: pickup, SUV, sport ("Insurgent chase vehicle 1/2/3") | `vehicles/cars/Enemy Car/{Pickup,SUV,Sport} Enemy.xml` (one `Car.vox`, several bodies; SUV copy in level_tutorial; overturned SUV in roadblock8 is a wreck without `<vehicle>`) | back places where the enemy crews of the copies sit (user request 2026-11-09), all normal seats so friendly NPCs use them: pickup 4: cab 2 + 2 behind the cab facing back (toolbox, low reclined place on the left; as VehicleD5); SUV 6: front 2 + rear bench 2 + one on each cargo wheel arch facing inward (as D3/D6; knees on the crate edge); sport 3: 2 + one low in the tray facing back (as D1/D4) | measured, upright (low back places tilt 55); verified SP |
| Chase/ambush copies: VehicleD2/D5/DD3 (pickup), D3/D6/DD1 (SUV, + copy in dev/levels/test.xml), D1/D4/DD2/DF1 (sport) | `prefabs/spawnables/enemy vehicles/Vehicle{D*,DD*,DF1}.xml` | as above | the chase cars' layouts shifted (whole car moved inside the `<vehicle>`: pickup 0.7/-0.8/1.9, SUV 0.9/-0.9/2.2, sport 0.5/-0.8/2.4; body voxels identical after the shift); verified SP |
| BRDM-2 (Insurgent Ambush 7) | `prefabs/spawnables/enemy vehicles/VehicleD7.xml` (in play), `vehicles/cars/BRDM/brdm.xml` (was dev/levels/test_vehicle.xml only; spawn menu "BRDM-2" added, §8; same body placement; its stray civilian spawn point removed, §8; `brdmwrecked.xml`: wreck without `<vehicle>`) | 6: driver + commander on the front bench, 4 on the troop compartment's side benches facing inward (the D7 crew's places) | measured, upright (driver's knees just under the wheel rim, tight cab); verified SP |
| AVF offroad: "Offroad Technical" (+ Open), AAF Jeep (VehicleAAF2), "GMG Offroad" (VehicleM22), "WMIK Technical" (MILAN; VehicleM23) | `vehicles/avf/prefabs/technicals/offroad{,-open,_GMG,_WMIK_MILAN}.xml`, `prefabs/spawnables/enemy vehicles/VehicleAAF2.xml`; inline copies in roadblock3 and dev/levels/test.xml (marked by a `path=` tag on the `<vehicle>`, not an `instance=` group: add_seats.py now finds those too; identical to their sources) | 4: front 2 + rear bench 2 (the AAF2 crew's places); WMIK 2 (right-hand drive; weapons bed). GMG / WMIK: + standing gunner place (mounted guns) | measured, upright; rear seats 0.2 from the backrest (knees clear the front seats); verified SP |
| AVF technical pickup: "Pickup Truck", "Pickup Truck Lifted", Pickup Damaged (wb34), "AAF Pickup Truck technical" (DShK), SPG-9 (M4), ZU-23 (M24) | `vehicles/avf/prefabs/technicals/{Pickup Truck,Pickup Lifted,Pickup Damaged,technical_DSHK,technical_SPG9,technical_ZU_23}.xml` (DShK copies in roadblock3, dev/levels/test.xml) | pickups 4: cab bench 2 + 2 sitting on the bed side rails facing inward; technicals 2 (cab) + standing gunner place (ZU-23: seated) | measured (model = modified official pickup_red, overlap 0.89; its bench sits 0.3 further forward and 0.1 higher, so the official rigs don't fit as they are). Cab smaller than the player (0.7 m cushion to roof): test 1 with the official reclined pose (seat rot 70, low head point, `head=` argument): head still out, looked silly; now upright, head through the roof accepted (user 2026-11-09); verified SP |
| ZIS-151 (road spawners Vehiclewg28; Damaged wb26; Katyusha VehicleM2; spawn menu entries added, §8) | `vehicles/avf/prefabs/ZIS-151/{ZIS-151,ZIS-151 Damaged,ZIS-151_Katyusha}.xml` (Katyusha: the launcher is a second `<vehicle>` "bm-14" in the same file; the two Destoryed files: wrecks; Cabin, ZIS-150, Katyusha Damaged: referenced nowhere) | ZIS-151 4: bench 2 + 2 on the bed floor; Damaged 4: bench 2 + 2 on the cargo box floor; Katyusha 2 (cab; launcher with the mounted-gun work) | measured, upright (heads ~0.1 through the cab roof, as the Cadillacs); steering wheel = top of a tilted column voxbox; verified SP |
| Humvee .50 cal ("Hummer With 50 Cal", VehicleM1) | `vehicles/avf/prefabs/humvee/umhummer With 50 Cal.xml` | 4 (Humvee layout, same body placement; gunner with the mounted-gun work) | as the Humvee; turret clear of the seats; verified SP |
| Willys Jeep (tutorial; spawn menu entry added, §8) | `vehicles/avf/prefabs/Weaponised vehicles/Willys Jeep.xml` + drivable copy in levels/level_tutorial.xml (same placement; `Willy's Destroyed.xml` there is a wreck) | 4: front 2 + rear bench 2 | measured, upright; undersized model (v1 eye 0.5 above the seat, tiny wheel): knees into the dashboard, accepted; verified SP |
| BMP-1, BMP-1P, BMP-2 (military spawners VehicleM18/M19/M20; spawn menu entries added, §8) | `vehicles/avf/prefabs/bmp/{BMP-1 d,BMP-1P d,BMP-2 D}.xml` (three hull models, same interior at the same place) | 5: driver (front left, levers) + 4 troops on the rear central bench, back to back facing the hull sides; commander/gunner in the turret with the mounted-gun work | measured, upright; vehicle origin high (interior y negative). Driver: hips ~0.1 into the small cushion (higher puts the head in the hatch); troops: heads at the roof, knees near the wall racks; verified SP |
| BMP-3 (spawn menu; military spawner VehicleM21) | `vehicles/avf/prefabs/bmp/BMP-3 d.xml` | 5: driver in the middle of the front row (controls there, as in a real BMP-3; the v1 eye point `player` was on the left seat, moved to the middle, §8) + the two front-row side seats + 2 on the rear bench; the two seats behind the turret left out (narrow tubs with a raised lip); turret crew with the mounted-gun work | measured, upright; heads at the roof; verified SP |
| T-72 ("T-72" = T72B3 mod 2016, "T-72A"; T72B, T72B3 obj 1989, T72BA from military spawners VehicleM3, M14-M17) | `vehicles/avf/prefabs/t72_desert/*.xml` (hull identical in all five) | 5: driver, reclined as in the official military_tank_green (seat rot 80, head point 0.45 up / 0.25 back; the hull is 0.8 m high inside) + 4 riders on the engine deck edges facing outward, legs over the side (user request 2026-11-09; `tank_riders()`, NPCs ride too); gunner place in the turret (mod 2016, T-72A) | measured; head under the roof, right forearm at the controls; verified SP (heavy frame drops while driving, §10) |
| T-54 / T-55 ("T-54 AAF", "T-55A AAF" = Alashya; Desert versions from military spawners VehicleM10-M13) | `vehicles/avf/prefabs/T-54 55/{T-54-3,T-55A} {Alashya,Desert}.xml` | 5: reclined driver (front left, T-72 pose) + 4 riders facing outward with legs over the side, on the fender fuel tanks / stowage boxes / fender (each spot measured) | measured; turret crew with the mounted-gun work; a rider's head can meet the gun barrel when the turret turns sideways; verified SP |
| T-34-85 ("T-34"; military spawner VehicleM9) | `vehicles/avf/prefabs/T-34/T-34-85.xml` | 5: reclined driver (front left, under the sloped front plate) + 4 riders on the engine deck side ledges facing outward, feet on the fenders, thighs over the external fuel tanks | measured; turret crew with the mounted-gun work; verified SP |
| M-51 Super Sherman ("M-51 Sherman"; military spawner VehicleM8) | `vehicles/avf/prefabs/M-51 Super Sherman/M-51 Super Sherman.xml` | 5: upright driver (room to sit up) + 4 riders on the rear deck edges facing outward (the big turret sweeps the hull top) | measured; turret crew with the mounted-gun work; verified SP |
| Refugee UAZ (VehicleC3, debug "Refugee Van") | `prefabs/spawnables/enemy vehicles/VehicleC3.xml` | 4 (UAZ layout) | body rebuilt (§8), seated; event behaviour shelved (§9) |

Inline copies done last (2026-11-09): Willys in the spawners Vehiclewg9 / VehicleM7 (the jeep 0.05 left / 0.3 up),
roadblock3's ZIL-131 (its `path=` tag is cut at the space in "Soviet Vehicles"; add_seats.py key `file#vehicle name`).
**All drivable vehicles in use have seats** (checked 2026-11-09: every `<vehicle>` reachable from the spawners,
roadblocks, road segments, levels and the spawn menu, test levels and `unused/` excluded). Gun positions are
gunner places (§6 "AVF"); the Kornet / AGS-30 tripods are no longer vehicles (gun emplacements with a gunner place,
§6 "AVF"). Player passengers and floor positions need the MP test (Phase 5).

### Steering wheels
* UAZ-452 (5 files): the original built the wheel as a fifth `<wheel>` (turned with steering but spun freely after
  crashes). Now a `steer`-tagged body part turned by `vehicles/SteeringWheel.lua` (server, `SetShapeLocalTransform`,
  steering × 180°; axis = the shape's thinnest voxel dimension, pivot = its bounding-box centre;
  `convert_steering.py`, test_steeringwheel.lua) [verified in-game]. Other vehicles: tag the wheel part `steer` and
  wrap the `<vehicle>` in the script.
* GAZ-24 (3): hinged body + joint motor driven by `EVF.lua`; finds its car by the tag `vehicle`. v1 swung it to ±130°
  from the keys; the driver's hands turn by GetVehicleSteering × 180°, less (user saw ~90°), so since 2026-11-09 the
  joint follows GetVehicleSteering × 180° too (sign for "left" learned the first time the driver holds left, v1 turned
  it positive for left). Kept as a joint (not SteeringWheel.lua).

### Other vehicle content
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
    name: `displayName`, else a designation-like config name ("3UBR8 APDS"), else "<calibre> mm <payload>" (§8).
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
    ammo box put that 0.2 m beside the tube, in-game). The AGS-30 does not aim up / down (shelved, §9).
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
    through the torso hitbox (§8).
    Performance (2026-11-13, lag shooting APDS into foliage and rocks; profile `tests/profile_avf_foliage.lua` with
    real quaternion maths): path holes at least 0.5 × radius apart (`AVF_PathHole` / `AVF_PathPaint`; AVF cut one
    every 1 cm), holes with radius ≤ 0 skipped (`AVF_Hole`), the scorch paints at a path's start only for the shell
    itself (`AVF_ShellPaint`), spall only when the path went through metal (`AVF_HARD`; fragments cutting huge rock
    shapes froze the game; user's switch test: holes off stopped the freezes, no spall gave the most). Left as AVF:
    ~46 SpawnFire per HE shell. Port differences (§8): 256 shell slots per gun (AVF 1050 shared); spall / shrapnel
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
    | WMIK Technical | `technicals/Offroad_WMIK.lua` | MILAN, own config (§8) | gunner standing on the weapons bed |
    | GMG Offroad (VehicleM22) | `technicals/Offroad_armed.lua` | AVF MK-19 grenades, own config (§8) | gunner standing in the roof ring, held there (`MountedGunHoldGunner`); verified SP |
    | AAF Pickup Truck SPG-9 (VehicleM4) | `technicals/technical_spg9.lua` | PG-9 / OG-9 | gunner standing left of the tube; verified SP |
    | Kornet tripod, AGS-30 tripod (RoadSegmentL1) | `vehicles/avf/scripts/simple_avf_tank.lua` | AVF 9M133 / AGS-30 (no config) | gunner standing behind it (user 2026-11-13 "Stand at it"; Kornet: hands raised to the tube, the model is ~2.7 m tall); no longer vehicles (one prompt, on the gun); AGS-30 hands as laid out; verified SP except AGS-30 pitch (shelved, §9) |

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
    (test_vehiclescripts.lua). `dash.lua` (Cadillac speedometer) is a `<screen>` script: stays v1 (§3).
  * GAZ-24 (test_evf.lua): `EVF.lua` (server.update: doors / hood / trunk free while ANY player grabs them, latched
    shut when let go; hinged steering wheel from the driver's steering; the door-open beep stays off as in v1: no XML
    sets `doornotification` and its sound never shipped), `lampa.lua` (interior lights), `policelightsF.lua` (militia:
    F toggles the light bar, blinking on the server), `radio_car2.lua` (siren switch); `radio_car.lua` used nowhere.
  * JetBus `vehicles/cars/bus/jet.lua` (test_jet.lua): server = throttle from the driver's Shift (idle 0.1 while driving,
    1 boosting; v1: the host), push in server.update, turbine, smoke, damage / explosion; client = the throttle bar for
    whoever is in the bus (`shared.jetThrottle` / `jetTarget`). `lastJetHealth` now set in init (v1 compared nil).
  * `vehicles/cars/minivan1/autobreakRemover.lua`: server (removes the bodies' `autobreak` tag); verified SP.
  * Left v1: `vehicles/bike.lua` (dirt bikes, dev/levels/test.xml only).
* Helicopters: AS350 v2 (§7). CH-47 (spawn menu, road VehicleM5 "FunkyFlight") and Hind (spawn menu) stay v1 for now
  (user, 2026-11-13): dead in MP.

---

## 7. Systems (how the port works)

Level entry points: `main.xml` (menu) → `levels/level.xml` / `levels/level_no_shadow.xml` → `levels/level_instance.xml`; scripts in
`levels/level_scripts.xml` (also `levels/level_scripts_spawn.xml`, `levels/level_tutorial.xml`, `levels/level_horde.xml`: keep the four in sync).
Libraries: `lib/TDSU/tdsu.lua` (+ `compat.lua`, which replaced UMF), `lib/Settings.lua`/`lib/Settings_Table.lua`
(`savegame.mod.settings` via `util.structured_table`, reads the registry live), `lib/Config.lua` (debug menu library;
level script `ui/ConfigMenu.lua`), `lib/Automatic.lua`.

### World generation (`world/generation/`)
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
* Continuous cleanup (2026-11-15, user: "everything should be gradual and continuous", also for cheaper shifts; no
  fade on shifts: the user prefers to see them). `world/generation/RemoveRoad.lua` was one pass deleting
  everything 250 m behind the rearmost player after each new segment (a segment's shapes in one frame). Now a
  sweep in server.tick: per frame it checks up to 600 objects of the current phase (shapes, bodies, triggers,
  joints, vehicles; each phase listed once with Find*) and deletes at most 120, with v1's per-object rules; it waits
  3 frames after each world shift (positions half-updated: near objects would look 200 m further behind).
  Test `test_removeroad` (rules, gradual, shift wait, no players). User: smooth.
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
* BUG FIXED (introduced by gradual generation, 2026-11-15; user screenshot: a pile of identical roadblock
  checkpoints on one spot). A deleted PuzzlePiece trigger is still returned by FindTriggers until the end of the
  frame, and server.update runs 2-3 times per frame below 60 FPS. v1 raised level.roadgen at once, which skipped
  the extra updates; with queued segments the pulse comes when the file spawns, so the extra updates queued the
  SAME segment again: overlapping duplicate segments (roadblock markers on one spot, double enemies / vehicles /
  pieces), also inflating the performance readings of that period. Fix: GenerateRoad `UnusedPuzzlePieces()` skips
  triggers already used until they are really gone (handles can be reused later); test in test_decor.
* Debug-menu spawning switches (original-mod bug, same in 9dde6dd; rewired 2026-11-14, user OK): "spawn loot" was
  read by nothing, and "spawn roadblocks" switched off the loot spawner (`RandomLoot.lua`) and the timed enemy
  vehicle events (`RandomVehicleEnemy.lua`); the roadblock spawner it was named after (`RandomRoadBLock.lua`) is
  still v1 and only in the dev test levels. Now "spawn loot" = RandomLoot, "spawn enemy vehicle events" =
  RandomVehicleEnemy (key `spawn_vehicle_events`). All switches are read every frame (no restart needed).
* Hidden floors under the sand of every road segment: rectangles of 10 cm plates with the original thickness
  instead of the polygon voxagons (performance, user OK 2026-11-14; `tools/porting/lighten_terrain.py`; the 40 cm
  plates of the first version let players fall through and were replaced). They appear in the frames after the
  road (before the rocks); diagonal outline edges are covered by small steps (up to one 10 cm cell of overhang). A segment's rocks,
  hills and roadside decor appear over the frames after the road (one prefab per frame), and the segment's cars,
  buildings, enemies and loot right after that.
* NPC timing (2026-11-15, user OK, performance): NPCs check their line of sight 5 times per second (v1: every tick
  because of the unset see_timer key; v1's intent was 0.5 s / 2.5 s), damage from lost voxels registers up to 2
  ticks later, standing ground raycasts every 2nd physics step, body-part damage read only after a reported hit.
* Cleanup now deletes triggers 250 m behind the rearmost player (2026-11-15). v1's RemoveRoad read a trigger's
  position with GetShapeWorldTransform (a shape call), so triggers were never deleted, and the scripts of deleted
  segments that own a trigger stayed alive (GenerateRoad removes a segment's scripts once none of its objects is
  left). Only things far behind are affected.
* New option "Low Detail Rocks" (Performance > Visual, on by default, user decision 2026-11-14): the road segments'
  rocks at half resolution (20 / 60 cm / 1.2 m voxels instead of 10 / 30 / 60 cm), blockier and breaking in
  coarser chunks; off = the original rocks. The host's setting decides for everyone (the server spawns the world).
* `fix_missing_scripts.py` repointed 76 XML references to never-existing scripts to `missing_script_stub.lua`.
  Leftover log noise: `<instance file="MOD"/>` (empty) in RoadSegment1237/4/5.xml ("Could not find prefab");
  "Script not found: data" (source unknown).
* Operators' v1 `queueRemoval()` (pause-menu-button trick to find its own script) cannot work on the server: those
  scripts set a finished flag and idle instead (`OpFinished`, initializers, heli smoke; Immersive_Tank's port
  dropped it).

### NPCs (GoreNPCs)
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
* Explosion damage: engine `explosion` events; shield absorbs first, the rest hurts health (§8).
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

### Player: health, inventory, hitboxes (Phase 2 design, verified)
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

### Menu, tutorial, debug menu
* Main menu (`main.xml`, `patches/convert_menu.py`): client UI; level starts are host-only through
  `MenuStartLevel` → `server.startLevel` (`ui/MainMenu/menu_host.lua`); others see greyed buttons.
  `menu_main.lua` is a library (entry `main_menu.lua`; also included by `ingame_settings.lua`). Character select
  camera is per client; `RotateScene.lua` hides all players. Tab on the main menu = dev level list.
* Tutorial (`game/Tutorial/`): per-player tips/hurt warning/inventory reset on the client; triggers, holes and
  the ending on the server (`shared.ending`). `tutMedTV.lua` (screen script) stays v1.
* Debug menu (Backspace; `lib/Config.lua`): Debug Mode, Gore NPCs debug overlays, NPC Controller, Vehicle Events
  (Hostile Car, Military, Refugees, "Refugee Van" = the refugee event with VehicleC3, added 2026-11-08 for the
  shelved van work, §9, Helicopter),
  Auto Travel (1/5/10/20 km at 40 m/s, `server.configTravel`), Infinite Ammo, spawn menu (`Weapons → Testing`
  holds items only dev/levels/test.xml had). Pause menu: one primary button "MorsLonga Menu".
* Spawn menu (`ui/SpawnMenu.lua`) lists only what is in the loot tables `world/generation/SpawnRefrenceTable.lua`
  (`spawnables.loots`; menu-only category `debugTest`); spawns go through `server.spawnMenuSpawn` with a per-player
  undo history. Debug-menu spawns: `ConfigSpawn` → `server.configSpawn`.

### Other converted systems (all v2, verified unless noted)
* Shop segment: SafeZone, PerkMachine (client pays, `server.perkBuy`, refunds), ParkingSpot garage (one shared garage
  in the host's savegame, `shared.garage`), WarehouseScript_Cultist, AC130 supply plane.
* RPG rocket `weapons/guns/grenade.lua` (server): impact ray from the previous position (close-range hits), explodes at
  the hit point, proximity fuse for any player, loaded rocket type via `server.rpgNextRocket` (sizes: PG-7V 0.6,
  OG-7V 1.0, PG-7VT 1.0, PG-7VA 2.0).
* World props (convert_props.py): debris, parachute, warehouse collapse, Binge shrine, heli crash smoke, crew
  ragdolls (batch D). Grenades, PlaceTool, Weld, meds, Airstrike, daynight/sandstorm, Fuel,
  ShootFromCar, CarAlarm, Thermals/NVGs, mines, doors, Book, SpawnMenu: Phase 1.

### AS350 helicopter (`vehicles/aircraft/AS350/script/`, v2 2026-11-13, verified SP except rockets on RMB, §9)
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
* The helicopter is a `<vehicle>` (seats, §6). Ways in: the cabin doors' prompts (`HeliV2_InitDoorEntry`: front door
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
* ZIL-131 trucks: "AAF Transport truck" (spawn menu), Vehiclewg33, roadblock9 and test_npc pointed at
  `MOD/Vehicles/ZIL131.xml` (it is in `vehicles/cars/Soviet Vehicles/`); ZIL131, ZIL131_ZSU23, VehicleAAF1 (both copies),
  roadblock3, dev/levels/test.xml and the fire truck's steering wheel pointed at `MOD/vehicles/zil131.vox` (same folder). Paths
  fixed 2026-11-08 (user OK); never tested in-game before.
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
  zig-zagged). The event's behaviour is shelved (§9).
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
  includes of a missing file, §2), so the external AVF mod fired its generic customcannon shell from the XML tags
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
* AS350 (2026-11-13, §6 seats, §7 "AS350 helicopter"), changes against the original:
  * A `<vehicle>` with seats (user decision "Seat rigs"; v1 teleported the pilot every frame): the pilot seat gives
    control (the dashboard "Control" prompt is gone), riders sit on the rear bench; "Fly helicopter" / "Enter
    helicopter" prompts on the cabin doors; exit beside the pilot door. No car behaviour: `sound="0"`, topspeed /
    acceleration 0 (values as Kooshing's MP helicopter), tags `player_nogears player_nosteeringwheel`, drive input held
    at 0 while seated (player_locomotion.lua turns a driver's head back on reverse).
  * Player flight: new mouse-aim model (user decision "Mouse-aim like reference"; the original drove its AI
    autopilot with W/S/A/D speed targets and the camera heading; user: it flew badly). Controls: mouse steers,
    W/S climb/descend, A/D sideways, LMB gun, RMB rockets (shelved: lean-out, §9), wheel zoom, E leaves the seat. The
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
  allowed it; differences listed in §6 ("AVF shells"). Player damage: AVF lowered only the local player's
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
  * Hardcore "Try Again" resets the other players' money too (user, 2026-11-14).
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
    while the host was on foot.
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

---

## 9. Shelved and dead content

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
  other guns. Its gun weighs ~1e-7 kg (see the freeze in §10).
* Test-only levels stay v1: dev/levels/test.xml, dev/levels/lol.xml, test_*.xml, procgen and gore-map test levels, `main.lua`.
  `prefabs/other/Credits.xml` (thiccparticle.lua) is never spawned. `weapons/guns/craftingrecipes.lua` has a syntax
  error and is never loaded. ~478 Lua files existed, ~316 reachable; dead files (`unused/`, `_WORKSHOP/`, the
  Teardown-Totally-Documented dump, `*_old` / `- Copy` leftovers, editor stubs) deleted 2026-11-14 (in git history).

---

## 10. Open questions and known gaps

MP-only (tested locally since 2026-11-14: the in-game mod editor runs a host and a client window on one PC):
* Found in the first local MP test and fixed, to re-test (§8 "MP fixes"): vanilla tools on for everyone, remote
  players without starter gear and at 0 hunger / thirst: verified fixed in the third test (the second one had run
  the stale release copy). Third test (2026-11-14) → other players' guns as loose parts, remote tool bar
  overlap: fixed, to re-test (§8). The host runs at about half the client's FPS (21-30 vs 57-60): the host is
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
* Code-survey leads (2026-11-14), status: fixed and mock-tested, to re-test in local MP (§8 "MP fixes, second
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
* Pause button primary slot shared with other mods; main menu for non-hosts; straggler teleport.
* Server-side sounds/particles/tracers reaching remote clients; `shared` nested tables on remote clients; entity
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
* Remote players don't see/hear other players' melee swings.
* Leftover scripts from non-segment spawns (NPC initializers, vehicles) accumulate ~20/km (no measured cost).
* KS23/N870 start a reload with 0 reserve ammo (v1 behaviour).
* Unverified for vox guns: whether gun melee (MakeHole at the stock) or a first bullet raycast can damage the
  engine-built tool body (only LoadTool parts are tagged `ml_toolpart unbreakable`).
* Seen once, cause unknown: Simonov-545 ADS tilted left after RPG use (fixed by re-equipping).
* AS350 windows stop bullets (user, 2026-11-13): the cabin glass is palette index 81 (MagicaVoxel glass look); by the
  engine's palette-index materials that is likely not glass. Same .vox as the original; not verified which material
  the engine reports. Not changed (would alter the original).
* Screens in MP (user, 2026-11-09; later, nice to have): `<screen>` scripts must be v1 (§3) and the engine disables v1
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
  Not yet compared with v1 (original branch 9dde6dd). The refugee van's zig-zag (§9) may be the same problem.

---

## 11. History (summary)

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
  (all verified unless listed in §10); horde converted then shelved; PlayerVehicleSeat retired; passenger seats
  moved to Phase 4.
* 2026-11-08: repo normalized to LF (separate commit before "phase 4"); Blender MCP + vehicle importer and seat
  mannequin; Phase 4 seats: Humvee, UAZ-452 (5), GAZ-24 (3); friendly NPCs ride in the seat rigs; scripted UAZ
  steering wheel; original-mod fixes (ambulance spawn entry, GAZ `vehicle` tag).
* 2026-11-09: seats for every drivable vehicle in use (§6 table); small vehicle scripts v2 (doors, Cadillac / LeBoat
  joints, semis' toggles, GAZ-24 EVF, JetBus).
* 2026-11-12: `vehicles/MountedGun.lua` (machine guns: DShK, M2, PKM); AVF's shell code ported (`port_avf.py`):
  ZU-23-2, BMP-1/1P/2/3; playtest fixes (sandstorms, Simonov-9 mags, loot table, med rotation).
* 2026-11-13: tanks (gunner place + driver fallback), launchers (Katyusha, WMIK MILAN), coax MGs and BMP ATGMs,
  Immersive_Tank.lua, AVF performance fixes; AS350 helicopter (vehicle with seats, v2 port, mouse-aim flight;
  rockets on RMB shelved); v1 survey of normal play → minivan helper, crew sitters, T-72A, GMG offroad, SPG-9
  technical, Kornet / AGS-30 tripods converted and verified SP (tripods as gun emplacements; AGS-30
  pitch shelved), AVF body pushes capped (freeze); docs tidied (dated logs → this summary and git).

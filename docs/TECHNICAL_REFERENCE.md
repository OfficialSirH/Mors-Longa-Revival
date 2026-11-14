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
  regex and silently never runs in v2; a loose grep for includers matched `ModConfig.lua` as `Config.lua` (use
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
  only in the test level `test_vehicle.xml`: backhoe, bulldozer, skid-loader, small_excavator. Dirt bikes (`Vehicles/Bike`): only
  in test.xml. Volga black/blue/taxi
  (`Vehicles/Gaz24`) and `k-cl-e-car1-w`: referenced nowhere either; also `Based Vehicles/wheelchair.xml`.
  Insurgent chase cars (`Vehicles/Enemy Car`): Coupe, Sadan, Sport2 and "Pickup Enemy With Crew" referenced nowhere.
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
| Humvee (plain, open) | `avf/prefabs/humvee/umhummer.xml`, `umhummeropen.xml` + embedded copies in Vehiclewg30, RoadSegmentM7, level_tutorial | 4 | verified SP |
| "Hummer UM" (spawn menu) | `Vehicles/humvee/hummer.xml` (other `Vehicles/humvee` files point at a missing `Vehicles/AvertCars/` folder, unused) | 4 | Humvee layout 0.05 higher (identical seat rays); verified SP |
| UAZ-452 (normal, damaged, lifted, white, emergency) | `Vehicles/Soviet Vehicles/uaz452*.xml` | 4; emergency 3 (stretcher) | verified SP |
| GAZ-24 (sedan, VIP, MP) | `Vehicles/GAZ-24 (1968)/gaz24unreleased*.xml` | 4 | verified SP |
| Sports car (green, damaged, offroad, RampCar) | `Vehicles/sportscar/sportcar_green*.xml`, `RampCar.xml` + copy in constructionCivillian12 | 2 | official rigs (`sportscar_green`); verified SP; shift -0.1 → 0 afterwards (cropping) |
| Yellow SUV (normal, damaged) | `Vehicles/SUV/suv_yellow*.xml` | 4 | official rigs (`generic_blue_light`); verified SP |
| Saloon (red, taxi, damaged) | `Vehicles/saloon/salooncar_*.xml` | 4 | official rigs (`generic_sedan_red`); verified SP |
| Box/Ramp Truck (+ damaged) | `Vehicles/truck/truck_{white,ramp}*.xml` | 2 | official rigs (`boxtruck_white`, seat point moved); verified SP |
| Yellow Dump Truck (+ damaged) | `Vehicles/dumptruck/Dump_truck*.xml` | 2 | official rigs (`dumptruck_yellow`); verified SP |
| Mobile crane | `Vehicles/Constuction vehicles/mobile_crane.xml` (spawn menu entry added, §8) | 1 | official rig (`crane_medium_yellow`); verified SP |
| Blue/Red Tractor | `Vehicles/Constuction vehicles/{Blue,Red}tractor.xml` | 1 | official rig (`tractor_teal`); verified SP |
| Yellow Van (+ damaged, Modified) | `Vehicles/van1_yellow/Van*.xml` | 2; Modified 1 (gun stand) | official rigs (`van_yellow`, seat point raised 0.2); verified SP |
| Station wagon (+ damaged) | `Vehicles/stationwagon/station_wagon_brown*.xml` (Destroyed: static wreck) | 4 | official rigs (`generic_stationwagon_blue_dark`); verified SP; damaged shift 0.1 → 0 afterwards (cropping) |
| Minivan | `Vehicles/minivan1/minivan1.xml` | 4 | measured (front seats + rear bench, upright); verified SP |
| Cadillac sedan (+ damaged, abandoned) | `Vehicles/cadillacsd80/*.xml` | 4 (abandoned: 2 + 2 floor; 0.1 forward afterwards, cropping) | measured, tilt 55; verified SP (heads poke through the roof a little, accepted) |
| Cadillac limo (+ damaged, abandoned) | `Vehicles/cadillacfbl80/*.xml` | 4: front + rear bench (abandoned: rear floor) | measured, tilt 55; verified SP (heads poke through the roof a little, accepted) |
| Mini (+ damaged, Modified) | `Vehicles/1969 Mini Cooper S/Mini*.xml` | 4 (Modified: driver + 3 floor) | measured, right-hand drive, tilt 55; verified SP; lowered 0.1 afterwards (empty layer) |
| VW Beetle (+ damaged, Modified) | `Vehicles/1963 VW Beetle/*.xml` | 4 (Modified: driver + 2 floor) | measured, tilt 55; verified SP |
| Plymouth Fury (+ damaged, Modified) | `Vehicles/Plymouth Fury/*.xml` | 4 | measured, tilt 55; verified SP |
| Dodge Monaco + Highway Police (+ damaged) | `Vehicles/1974 Dodge Moncaco/*.xml` | 4 | measured, tilt 55; verified SP; afterwards 0.1 lower and police = civilian seats (cropping) |
| Jeep Wrangler ("Officer's Jeep", + damaged) | `Vehicles/Jeep Wrangler/*.xml` (Willys Jeep folder: static wreck only) | 4 | measured, upright (open top), 0.3 lower for the empty layers (test 1: far above the seats); verified SP |
| Ural ("SU Transport Truck", + damaged) | `Vehicles/ural/ural*.xml` | 4: cab 2 + cargo side benches 2 (facing inward) | measured, upright; verified SP |
| ZIL-131 fire truck ("Firetruck") | `Vehicles/Soviet Vehicles/zil131fire.xml` | 4: crew cab, 2 rows | measured, upright; verified SP |
| ZIL-131 transport ("AAF Transport truck") | `Vehicles/Soviet Vehicles/ZIL131.xml` (+ Vehiclewg33, roadblock9) | 4: cab 2 + cargo side benches 2 | measured, upright; paths fixed (§8); verified SP |
| ZIL-131 ZU-23 ("AAF Truck Technical") | `Vehicles/Soviet Vehicles/ZIL131_ZSU23.xml` | 2 (cab; gunner with the mounted-gun work) | as ZIL131; verified SP |
| Bus (+ damaged, Modified, JetBus) | `Vehicles/bus/bus*.xml`, `jetbus.xml` (Destroyed: static wreck) | 4: driver + front rows (one rear-facing); Modified: driver + 3 floor; JetBus: driver + 2 on the wheel arches (engine fills the cabin) | measured, upright; verified SP |
| PAZ-3205 ("Soviet Bus", + damaged) | `Vehicles/Soviet Vehicles/paz 3205*.xml` (+ event copy VehicleC2, see the enemy row) | 4 | measured, upright; verified SP |
| American semi (+ damaged, Modified, Special) | `Vehicles/semitruck-us/Semi*.xml` (Destroyed: static wreck) | 4: cab 2 + 2 on the lower sleeper bunk (facing the middle) | measured, upright; verified SP |
| Flathead semi (+ damaged, Mod) | `Vehicles/semitruck-flathead/Semi*.xml` (spawn menu "Semi Flathead" added, §8) | 2 (no room for more: engine hump, bunks 0.7 m apart) | measured, upright; verified SP |
| SportsCar offroad | `Vehicles/sportscar/sportsoffroad.xml` + copy in constructionCivillian12 | 2 | official rigs (`sportscar_green`, overlap 0.78); verified SP |
| Cement truck | `Vehicles/Constuction vehicles/cement_truck.xml` (road spawner Vehiclewg42; spawn menu "Cement Truck" added, §8) | 2 | measured, upright; verified SP |
| Tractor From Hell ("TRACTOR") | `Vehicles/Constuction vehicles/tractorFromHell.xml` | 1 (like the official tractor) | measured, upright; verified SP |
| Volga (white) | `Vehicles/Gaz24/volgawhite.xml` (road spawner Vehiclewg18; spawn menu "Volga" added, §8; Destroyed: wrecks) | 4 | measured, tilt 55; verified SP |
| Microcar (+ damaged) | `Vehicles/microcar/microcar*.xml` (road spawners Vehiclewg38, wb30; spawn menu "Microcar" added, §8) | 2 | measured, tilt 55; verified SP |
| Monster Compact | `Vehicles/microcar/monstercompact.xml` | 4 (rear cramped) | measured, tilt 55; verified SP |
| Ford Falcon XB GT (+ damaged) | `Vehicles/MadMax2/1973 Ford Falcon XB GT*.xml` (road spawners Vehiclewg21, wb19; spawn menu "Ford Falcon" added, §8; Destroyed: wreck) | 4 (right-hand drive; rear cramped) | measured, tilt 55; verified SP |
| Pursuit Special | `Vehicles/MadMax2/Pursuit Special.xml` | 4: driver, a sideways seat on the left door (ledge + door panel, faces the driver; user spotted it in-game), 2 on the rear floor | measured; verified SP |
| Military truck (UM Damaged; plain, Damaged) | `Vehicles/military_truck/Milltary_Truck*.xml` (UM Damaged in roadblocks 8/9; plain one now spawn menu "Military Truck", §8; Destroyed: wrecks) | 4: cab 2 + 2 on the cargo bed floor (no benches) | measured, upright; verified SP |
| RV MethLab ("Bad RV") | `Vehicles/RVMethLab/MethLab.xml` (road spawner Vehiclewg26; spawn menu path fixed, §8; MethLab Enemy: unused) | 4: cab 2 + 2 on the rear bench (facing the aisle) | measured, upright; verified SP |
| BugZilla ("Monster Bug") | `Vehicles/1963 VW Beetle BugZilla/BugZilla.xml` (Destroyed: wreck) | 3: driver + 2 floor (stripped; engine/fuel tank in the back) | measured, tilt 55; verified SP |
| Golf cart + "Nuclear Golfcart" | `Vehicles/Based Vehicles/golf_cart*.xml` (road spawner Vehiclewg45; Bomb in the spawn menu) | 2 | measured, upright (wheel far ahead: arms stretched); verified SP |
| Small red boat | `Vehicles/Based Vehicles/smallboat_red.xml` (road spawner vehicleS13; spawn menu "Small Boat" added, §8) | 4: stern (driver, no steering wheel), middle seat 2, bow 1 facing back | measured, upright; verified SP |
| "Shed?" + Garage | `Vehicles/Based Vehicles/SHED.xml`, `GARAGE.xml` (vehicleS11/S12; Garage copy in test.xml) | 4: driver on the chair + 3 on the floor | measured, upright; verified SP |
| Wheeled Cockpit | `Vehicles/Based Vehicles/wheeledcockpit.xml` (spawn menu; vehicleS10) | 2 (pilot + copilot; no yoke in the model) | measured, upright; verified SP |
| AS350 helicopter: AAF Attack Heli (MILITARY), Insurgent Attack Heli, parked copies, CIV (gore map), VIP | `main/AS350/AS350_*.xml` (+ 2 copies in test_misc.xml). Not a vehicle in the original (Heli.lua teleported the pilot every frame): add_seats.py `WRAP_VEHICLE` wraps the Heli.lua `<script>` content in `<vehicle name="AS350" tags="player_nogears player_nosteeringwheel" sound="0" topspeed="0" acceleration="0">` (no car sounds or driving animations) and `VEHICLE_EXITS` adds an `exit` location beside the pilot door | 4: pilot left front (the AI pilot ragdoll sits right) + 3 on the rear bench; Insurgent: no left front cushion (open door-gun side), third bench place 0.1 lower | measured, upright, nose at body +z (rigs turned 180); verified SP 2026-11-13 |
| LeBoat (sailboat) | `Vehicles/Based Vehicles/sailboat.xml` (spawn menu; vehicleS14) | 4: driver standing at the left ship's wheel (user request; first version sat between the two wheels) + 3 on the side benches | measured; verified SP |
| Enemy/event copies: AAF Truck (VehicleAAF1, ZIL-131), Civillian Jeep (VehicleC1, Jeep), Civillian Bus (VehicleC2, PAZ), Insurgent Ambush 8 (VehicleD8, Ural) | `prefabs/spawnables/enemy vehicles/Vehicle{AAF1,C1,C2,D8}.xml` (inline copies) | as their models | those models' layouts (AAF1, C1 shifted 0.05-0.1 m); seat rays identical with the crew hidden; awaiting test |
| Insurgent chase cars: pickup, SUV, sport ("Insurgent chase vehicle 1/2/3") | `Vehicles/Enemy Car/{Pickup,SUV,Sport} Enemy.xml` (one `Car.vox`, several bodies; SUV copy in level_tutorial; overturned SUV in roadblock8 is a wreck without `<vehicle>`) | back places where the enemy crews of the copies sit (user request 2026-11-09), all normal seats so friendly NPCs use them: pickup 4: cab 2 + 2 behind the cab facing back (toolbox, low reclined place on the left; as VehicleD5); SUV 6: front 2 + rear bench 2 + one on each cargo wheel arch facing inward (as D3/D6; knees on the crate edge); sport 3: 2 + one low in the tray facing back (as D1/D4) | measured, upright (low back places tilt 55); verified SP |
| Chase/ambush copies: VehicleD2/D5/DD3 (pickup), D3/D6/DD1 (SUV, + copy in test.xml), D1/D4/DD2/DF1 (sport) | `prefabs/spawnables/enemy vehicles/Vehicle{D*,DD*,DF1}.xml` | as above | the chase cars' layouts shifted (whole car moved inside the `<vehicle>`: pickup 0.7/-0.8/1.9, SUV 0.9/-0.9/2.2, sport 0.5/-0.8/2.4; body voxels identical after the shift); verified SP |
| BRDM-2 (Insurgent Ambush 7) | `prefabs/spawnables/enemy vehicles/VehicleD7.xml` (in play), `Vehicles/BRDM/brdm.xml` (was test_vehicle.xml only; spawn menu "BRDM-2" added, §8; same body placement; its stray civilian spawn point removed, §8; `brdmwrecked.xml`: wreck without `<vehicle>`) | 6: driver + commander on the front bench, 4 on the troop compartment's side benches facing inward (the D7 crew's places) | measured, upright (driver's knees just under the wheel rim, tight cab); verified SP |
| AVF offroad: "Offroad Technical" (+ Open), AAF Jeep (VehicleAAF2), "GMG Offroad" (VehicleM22), "WMIK Technical" (MILAN; VehicleM23) | `avf/prefabs/technicals/offroad{,-open,_GMG,_WMIK_MILAN}.xml`, `prefabs/spawnables/enemy vehicles/VehicleAAF2.xml`; inline copies in roadblock3 and test.xml (marked by a `path=` tag on the `<vehicle>`, not an `instance=` group: add_seats.py now finds those too; identical to their sources) | 4: front 2 + rear bench 2 (the AAF2 crew's places); WMIK 2 (right-hand drive; weapons bed). GMG / WMIK: + standing gunner place (mounted guns) | measured, upright; rear seats 0.2 from the backrest (knees clear the front seats); verified SP |
| AVF technical pickup: "Pickup Truck", "Pickup Truck Lifted", Pickup Damaged (wb34), "AAF Pickup Truck technical" (DShK), SPG-9 (M4), ZU-23 (M24) | `avf/prefabs/technicals/{Pickup Truck,Pickup Lifted,Pickup Damaged,technical_DSHK,technical_SPG9,technical_ZU_23}.xml` (DShK copies in roadblock3, test.xml) | pickups 4: cab bench 2 + 2 sitting on the bed side rails facing inward; technicals 2 (cab) + standing gunner place (ZU-23: seated) | measured (model = modified official pickup_red, overlap 0.89; its bench sits 0.3 further forward and 0.1 higher, so the official rigs don't fit as they are). Cab smaller than the player (0.7 m cushion to roof): test 1 with the official reclined pose (seat rot 70, low head point, `head=` argument): head still out, looked silly; now upright, head through the roof accepted (user 2026-11-09); verified SP |
| ZIS-151 (road spawners Vehiclewg28; Damaged wb26; Katyusha VehicleM2; spawn menu entries added, §8) | `avf/prefabs/ZIS-151/{ZIS-151,ZIS-151 Damaged,ZIS-151_Katyusha}.xml` (Katyusha: the launcher is a second `<vehicle>` "bm-14" in the same file; the two Destoryed files: wrecks; Cabin, ZIS-150, Katyusha Damaged: referenced nowhere) | ZIS-151 4: bench 2 + 2 on the bed floor; Damaged 4: bench 2 + 2 on the cargo box floor; Katyusha 2 (cab; launcher with the mounted-gun work) | measured, upright (heads ~0.1 through the cab roof, as the Cadillacs); steering wheel = top of a tilted column voxbox; verified SP |
| Humvee .50 cal ("Hummer With 50 Cal", VehicleM1) | `avf/prefabs/humvee/umhummer With 50 Cal.xml` | 4 (Humvee layout, same body placement; gunner with the mounted-gun work) | as the Humvee; turret clear of the seats; verified SP |
| Willys Jeep (tutorial; spawn menu entry added, §8) | `avf/prefabs/Weaponised vehicles/Willys Jeep.xml` + drivable copy in level_tutorial.xml (same placement; `Willy's Destroyed.xml` there is a wreck) | 4: front 2 + rear bench 2 | measured, upright; undersized model (v1 eye 0.5 above the seat, tiny wheel): knees into the dashboard, accepted; verified SP |
| BMP-1, BMP-1P, BMP-2 (military spawners VehicleM18/M19/M20; spawn menu entries added, §8) | `avf/prefabs/bmp/{BMP-1 d,BMP-1P d,BMP-2 D}.xml` (three hull models, same interior at the same place) | 5: driver (front left, levers) + 4 troops on the rear central bench, back to back facing the hull sides; commander/gunner in the turret with the mounted-gun work | measured, upright; vehicle origin high (interior y negative). Driver: hips ~0.1 into the small cushion (higher puts the head in the hatch); troops: heads at the roof, knees near the wall racks; verified SP |
| BMP-3 (spawn menu; military spawner VehicleM21) | `avf/prefabs/bmp/BMP-3 d.xml` | 5: driver in the middle of the front row (controls there, as in a real BMP-3; the v1 eye point `player` was on the left seat, moved to the middle, §8) + the two front-row side seats + 2 on the rear bench; the two seats behind the turret left out (narrow tubs with a raised lip); turret crew with the mounted-gun work | measured, upright; heads at the roof; verified SP |
| T-72 ("T-72" = T72B3 mod 2016, "T-72A"; T72B, T72B3 obj 1989, T72BA from military spawners VehicleM3, M14-M17) | `avf/prefabs/t72_desert/*.xml` (hull identical in all five) | 5: driver, reclined as in the official military_tank_green (seat rot 80, head point 0.45 up / 0.25 back; the hull is 0.8 m high inside) + 4 riders on the engine deck edges facing outward, legs over the side (user request 2026-11-09; `tank_riders()`, NPCs ride too); gunner place in the turret (mod 2016, T-72A) | measured; head under the roof, right forearm at the controls; verified SP (heavy frame drops while driving, §10) |
| T-54 / T-55 ("T-54 AAF", "T-55A AAF" = Alashya; Desert versions from military spawners VehicleM10-M13) | `avf/prefabs/T-54 55/{T-54-3,T-55A} {Alashya,Desert}.xml` | 5: reclined driver (front left, T-72 pose) + 4 riders facing outward with legs over the side, on the fender fuel tanks / stowage boxes / fender (each spot measured) | measured; turret crew with the mounted-gun work; a rider's head can meet the gun barrel when the turret turns sideways; verified SP |
| T-34-85 ("T-34"; military spawner VehicleM9) | `avf/prefabs/T-34/T-34-85.xml` | 5: reclined driver (front left, under the sloped front plate) + 4 riders on the engine deck side ledges facing outward, feet on the fenders, thighs over the external fuel tanks | measured; turret crew with the mounted-gun work; verified SP |
| M-51 Super Sherman ("M-51 Sherman"; military spawner VehicleM8) | `avf/prefabs/M-51 Super Sherman/M-51 Super Sherman.xml` | 5: upright driver (room to sit up) + 4 riders on the rear deck edges facing outward (the big turret sweeps the hull top) | measured; turret crew with the mounted-gun work; verified SP |
| Refugee UAZ (VehicleC3, debug "Refugee Van") | `prefabs/spawnables/enemy vehicles/VehicleC3.xml` | 4 (UAZ layout) | body rebuilt (§8), seated; event behaviour shelved (§9) |

Inline copies done last (2026-11-09): Willys in the spawners Vehiclewg9 / VehicleM7 (the jeep 0.05 left / 0.3 up),
roadblock3's ZIL-131 (its `path=` tag is cut at the space in "Soviet Vehicles"; add_seats.py key `file#vehicle name`).
**All drivable vehicles in use have seats** (checked 2026-11-09: every `<vehicle>` reachable from the spawners,
roadblocks, road segments, levels and the spawn menu, test levels and `unused/` excluded). Gun positions are
gunner places (§6 "AVF"); the Kornet / AGS-30 tripods are no longer vehicles (gun emplacements with a gunner place,
§6 "AVF"). Player passengers and floor positions need the MP test (Phase 5).

### Steering wheels
* UAZ-452 (5 files): the original built the wheel as a fifth `<wheel>` (turned with steering but spun freely after
  crashes). Now a `steer`-tagged body part turned by `scripts/SteeringWheel.lua` (server, `SetShapeLocalTransform`,
  steering × 180°; axis = the shape's thinnest voxel dimension, pivot = its bounding-box centre;
  `convert_steering.py`, test_steeringwheel.lua) [verified in-game]. Other vehicles: tag the wheel part `steer` and
  wrap the `<vehicle>` in the script.
* GAZ-24 (3): hinged body + joint motor driven by `EVF.lua`; finds its car by the tag `vehicle`. v1 swung it to ±130°
  from the keys; the driver's hands turn by GetVehicleSteering × 180°, less (user saw ~90°), so since 2026-11-09 the
  joint follows GetVehicleSteering × 180° too (sign for "left" learned the first time the driver holds left, v1 turned
  it positive for left). Kept as a joint (not SteeringWheel.lua).

### Other vehicle content
* `scripts/Game/PlayerVehicleSeat/` (fake driver model for the v1 invisible player) is no longer loaded: v2 draws
  the driver itself (user saw two bodies). Still referenced by test.xml / test_vehicle.xml only.
* AVF vehicles (mounted guns, cannons, launchers, tanks: `avf/`). In v1 each vehicle's XML tags its gun parts and a
  config `.lua` describes the gun (`vehicleParts.guns.mainCannon` = name, magazines, RPM, reload, dispersion,
  sounds); `avf/scripts/avf_custom.lua` copied that onto tags and the external AVF mod (Workshop 2400346027, no MP
  version; "ERROR: AVF MOD NOT ENABLED" without it) did everything else. Frameworks considered (2026-11-12): **TABS
  Vehicle Framework** (3148138736) cannot be used (all ~125 scripts v1; its README forbids copying or modifying it);
  **AVF** (elboydo) allows reuse with credit ("no copyright but please give credit", main.lua) → its shell code is
  ported, credited (also in the mod's credits at publish).
  * **`scripts/MountedGun.lua`** (own, v2; design user-approved 2026-11-09): a library each vehicle config includes
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
    unmodified) → `scripts/avf/AVF_Shells.lua` (AVF's common, ammo, weapons, globalConfig, handlers; server simulation;
    client visuals); hand-written `scripts/avf/AVF_Glue.lua`. Server: flight, penetration, payloads, spall / shrapnel,
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
  * `avf/scripts/Immersive_Tank.lua` (tank damage: cook-off, engine failure, fuel fires, blow-outs; outer script of
    ~90 AVF vehicle XMLs): rebuilt by `port_immersive.py` from 9dde6dd (test_immersive_tank.lua); its logic runs on
    the server; the effect functions run on every client from one event each (`ITC_*` on the server → `ITR_*` on a
    client), other visual calls recorded and replayed (`client.itFx`); masterScriptRemoverAPI dropped.
  * Converted configs (tests test_mountedgun.lua, test_avf_cannon.lua; verified SP unless marked):

    | Vehicle (spawn menu; spawner) | Config | Weapon | Who fires |
    |---|---|---|---|
    | AAF Pickup Truck technical (+ roadblock3 / test.xml copies) | `technicals/technical_dshk.lua` | DShK 12.7 mm | gunner standing, rear of the bed |
    | Hummer With 50 Cal (VehicleM1); Willys in VehicleM7 | `Weaponised vehicles/Willys Jeep 50 Cal.lua` | M2 | gunner standing: centre console, head out of the roof ring / behind the rear bench |
    | Van Modified | `Weaponised vehicles/Van PKM.lua` | PKM (`MountedGunSightAt = 1`) | gunner on the cargo floor, facing left |
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
    | Kornet tripod, AGS-30 tripod (RoadSegmentL1) | `avf/scripts/simple_avf_tank.lua` | AVF 9M133 / AGS-30 (no config) | gunner standing behind it (user 2026-11-13 "Stand at it"; Kornet: hands raised to the tube, the model is ~2.7 m tall); no longer vehicles (one prompt, on the gun); AGS-30 hands as laid out; verified SP except AGS-30 pitch (shelved, §9) |

    Not converted (loaded nowhere): other T-72 / T-90 / TOS-1 / BMD-2 / Cromwell / ZSU-23-4 configs, the offroad
    GPMG / NSV / M2 guns (share Offroad_armed.lua; their gun tags differ: no gun found), the technical UB-16 / BM-14 /
    Type 63 configs and the stand-alone turret configs (`avf/prefabs/turrets/*.lua`).
* Small vehicle scripts (all v2, hand-converted, verified SP 2026-11-09 unless noted):
  * `Vehicles/!library/scripts/door.lua` (28 xmls; test_door.lua): server, door-tagged joints motored shut while any
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
  * JetBus `Vehicles/bus/jet.lua` (test_jet.lua): server = throttle from the driver's Shift (idle 0.1 while driving,
    1 boosting; v1: the host), push in server.update, turbine, smoke, damage / explosion; client = the throttle bar for
    whoever is in the bus (`shared.jetThrottle` / `jetTarget`). `lastJetHealth` now set in init (v1 compared nil).
  * `Vehicles/minivan1/autobreakRemover.lua`: server (removes the bodies' `autobreak` tag); verified SP.
  * Left v1: `scripts/bike.lua` (dirt bikes, test.xml only).
* Helicopters: AS350 v2 (§7). CH-47 (spawn menu, road VehicleM5 "FunkyFlight") and Hind (spawn menu) stay v1 for now
  (user, 2026-11-13): dead in MP.

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
  scripts set a finished flag and idle instead (`OpFinished`, initializers, heli smoke; Immersive_Tank's port
  dropped it).

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
  the limp sitters they turn into (`main/AS350/Gore Ragdolls 2/scripts/gorefunctions.lua`, v2 2026-11-13,
  test_sitter.lua: ragdoll logic on the server, bleeding particles from `shared.bl<body>` on the clients; P and the
  kill-all key for any player; verified SP).
* Converted by `tools/porting/history/convert_goreai.py` (base 6c28435, frozen; also gunfunctions.lua,
  Melee_Functions.lua and AdvancedHealthScript.lua edits); hand-written: goreai_main, killcam, players, netview,
  controller, sitting.

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
* Debug menu (Backspace; `Config.lua`): Debug Mode, Gore NPCs debug overlays, NPC Controller, Vehicle Events
  (Hostile Car, Military, Refugees, "Refugee Van" = the refugee event with VehicleC3, added 2026-11-08 for the
  shelved van work, §9, Helicopter),
  Auto Travel (1/5/10/20 km at 40 m/s, `server.configTravel`), Infinite Ammo, spawn menu (`Weapons → Testing`
  holds items only test.xml had). Pause menu: one primary button "MorsLonga Menu".
* Spawn menu (`scripts/UI/SpawnMenu.lua`) lists only what is in the loot tables `Procedural/SpawnRefrenceTable.lua`
  (`spawnables.loots`; menu-only category `debugTest`); spawns go through `server.spawnMenuSpawn` with a per-player
  undo history. Debug-menu spawns: `ConfigSpawn` → `server.configSpawn`.

### Other converted systems (all v2, verified unless noted)
* Shop segment: SafeZone, PerkMachine (client pays, `server.perkBuy`, refunds), ParkingSpot garage (one shared garage
  in the host's savegame, `shared.garage`), WarehouseScript_Cultist, AC130 supply plane.
* RPG rocket `script/grenade.lua` (server): impact ray from the previous position (close-range hits), explodes at
  the hit point, proximity fuse for any player, loaded rocket type via `server.rpgNextRocket` (sizes: PG-7V 0.6,
  OG-7V 1.0, PG-7VT 1.0, PG-7VA 2.0).
* World props (convert_props.py): debris, parachute, warehouse collapse, Binge shrine, heli crash smoke, crew
  ragdolls (batch D). Grenades, PlaceTool, Weld, meds, Airstrike, daynight/sandstorm, Fuel,
  ShootFromCar, CarAlarm, Thermals/NVGs, mines, doors, Book, SpawnMenu: Phase 1.

### AS350 helicopter (`main/AS350/script/`, v2 2026-11-13, verified SP except rockets on RMB, §9)
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
  `MOD/Vehicles/ZIL131.xml` (it is in `Vehicles/Soviet Vehicles/`); ZIL131, ZIL131_ZSU23, VehicleAAF1 (both copies),
  roadblock3, test.xml and the fire truck's steering wheel pointed at `MOD/vehicles/zil131.vox` (same folder). Paths
  fixed 2026-11-08 (user OK); never tested in-game before.
* World: RandomVehicleEnemy `whichone` nil (AAF below 5000 m); military truck never spawning (order of distance
  checks); Cultist ambushes never fired (`GetPlayerVehicle == 0`); pause button in an undrawn slot; parachute /
  horde DebugPrint spam; StandingRagdoll undefined `fwd1` on death; heli crew quickload hook calling an undefined
  function; npc_die reading a missing gun loot string (horde); NPC table / to-delete list / spall shell leaks.
* Vehicles: spawn menu "Soviet ambulance" missing (`spawn.txt` entry started with `Mod/` instead of `MOD/`);
  GAZ-24 sedan + VIP steering wheel turned with A/D while on foot and stayed centred while driving (`EVF.lua`
  finds its car by `FindVehicle("vehicle")`; only the MP variant had the `vehicle` tag, so the others got 0 and
  "player vehicle == 0" was true on foot) → tag added. Both verified in SP.
* Spawn menu "Bad RV" (RV MethLab): the entry's path started with `/Vehicles/` instead of `MOD/Vehicles/` (same in
  the original 9dde6dd, like the ambulance entry); fixed 2026-11-08.
* Refugee UAZ event (`enemy vehicles/VehicleC3.xml`): built for an older `uaz452.vox` (objects `body`, `door fl`,
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
* Refugee events (Civillian Jeep / Bus / Van, `scripts/ConvoyOperatorTransport.lua`): when the vehicle stopped near a
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
  * Vehicles - Civillian: "Mobile Crane" (v1 only in test_vehicle.xml), "Dodge Monaco", "Dodge Monaco Police",
    "Plymouth Fury", "Semi Flathead" (roadside Vehiclewb1/wb15), "Cement Truck" (wg42), "Volga" (wg18), "Microcar"
    (wg38), "Ford Falcon" (wg21), "Small Boat" (`Based Vehicles/smallboat_red.xml`, vehicleS13) (2026-11-08).
  * Vehicles - Insurgent: "BRDM-2" (the empty `brdm.xml`, v1 only in test_vehicle.xml; with crew it was already
    VNPCs - Transports / Insurgent Ambush 7; 2026-11-09). Its `<instance file="MOD/prefabs/spawns/enemies/
    EnemyCivSpawnVehicle.xml"/>` (`RandomRagdoll Type=civ chance=100`: a random civilian NPC at the car's centre, under
    the hull; no other drivable vehicle has one) was removed; VehicleD7 keeps its copy (original event content).
    "Insurgent Heli (parked, no AI)" (2026-11-13, below).
  * Vehicles - Military: "Military Truck" (the plain `Milltary_Truck.xml`, v1 only in test_vehicle.xml; the
    roadblocks use the UM Damaged one; 2026-11-08); "ZIS-151", "ZIS-151 Damaged", "Katyusha" (wg28 / wb26 /
    VehicleM2), "Willys Jeep" (tutorial only), "BMP-1", "BMP-1P", "BMP-2" (VehicleM18-M20) (2026-11-09); "AAF Pickup
    Truck ZU-23" (only test_npc.xml placed it; 2026-11-12); "AAF Heli (parked, no AI)", and for testing the
    v1-survey batch "T-72A", "AAF Pickup Truck SPG-9", "GMG Offroad", "Kornet tripod", "AGS-30 tripod" (2026-11-13).
  * Parked helis: `main/AS350/AS350_{MILITARY,INSURGENT}_PARKED.xml` (generated by `heli_variants.py`), the enemy
    helis with the tag `parked` on body Heli, which Heli.lua reads as not hostile (the original's friendly mode:
    stays landed, the pilot offers "Take a ride"). For testing seats and player flight.
* Militia GAZ-24 siren (original-mod bug, same in 9dde6dd): `Vehicles/GAZ-24 (1968)/radio_car2.lua` loaded
  `MOD/Vehicle/GAZ-24 (1968)/Sounds/Siren.ogg` (the folder is `Vehicles/`), so the "radio" switch never made a sound;
  path fixed (user OK 2026-11-09).
* BMP-3 driver eye point (`location tags="player"` in `avf/prefabs/bmp/BMP-3 d.xml`): x -0.9 → -0.1 (the left front
  seat → the middle one, where the controls and the new driver seat are; user request 2026-11-09).
* Van PKM fire sound (original-mod bug): the config named `MOD/snd/ak0.ogg` (missing: silent) → `MOD/snd/Weapons/ak/
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
    (`script/PP19.lua`, also a `convert_gun.py` FIXUP) and the shop's gun item were `Simonov-9`, loot ones
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
    `scripts/MLSandbox.lua` instead: the engine's sandbox.lua with only that SetToolEnabled removed (spawn /
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
  (not `script/Lean.lua`, not the gun scripts' vehicle checks; the 1.x update log lists "New improved vehicle leaning,
  you can now drive as you lean out"). Options when revisited: find and suppress it for the pilot, or another key.
* **AGS-30 tripod aiming up / down** (user decision 2026-11-13, "Shelve and clean up"): its gun does not pitch, also
  as the unchanged original vehicle under our script (user test with a temporary copy); whether the external AVF of
  v1 could pitch it is unknown. Yaw and firing work. Tried, none moved it (readouts of hinge angle / aim error):
  rays skipping its own parts, the gunner not colliding with it, gun and mount not colliding (script filter),
  dropping its joints' `collide="true"` (the gun rests on the mount, both faces at the hinge line, Blender), driving
  both of its coaxial gun hinges, a speed-command mode, density 0.05 instead of 1e-12 (19 kg: it only sagged to its
  limit). No motor command ever moved its hinge; grabbing the gun by hand does. All reverted except what serves the
  other guns. Its gun weighs ~1e-7 kg (see the freeze in §10).
* Test-only levels stay v1: test.xml, lol.xml, test_*.xml, procgen and gore-map test levels, `main.lua`.
  `prefabs/other/Credits.xml` (thiccparticle.lua) is never spawned. `script/craftingrecipes.lua` has a syntax
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
  the next second), so the server's car is not put back by a client; the stuck car did not happen that time. Leads from a code survey, not yet seen in-game: permadeath
  watches only the host (`Gamerule.lua`), fuel perks / fuel money on the host's savegame (`Fuel.lua`), debug-menu
  toggles read on the server (do nothing from a non-host), cultist ambush only around the host, effects started
  only on the server (RPG rocket, GAZ doors, car radio, JetBus, convoy sirens), server bullets without gravity
  (`gravity` nil in the gun server realm), per-bullet network traffic. On Hardcore "Try Again" the host's money is
  reset, the other players' is not (open: reset theirs too?).
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
* Money from selling fuel is written on the server (host's registry).
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
  helicopter instruments (`main/AS350/screens/*`, `main/Boeing_CH47-C/screens/*`), `terrain/eastereggs/binge.lua`.
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
* 2026-11-08: repo normalized to LF (separate commit before "phase 4"); Blender MCP + vehicle importer and seat
  mannequin; Phase 4 seats: Humvee, UAZ-452 (5), GAZ-24 (3); friendly NPCs ride in the seat rigs; scripted UAZ
  steering wheel; original-mod fixes (ambulance spawn entry, GAZ `vehicle` tag).
* 2026-11-09: seats for every drivable vehicle in use (§6 table); small vehicle scripts v2 (doors, Cadillac / LeBoat
  joints, semis' toggles, GAZ-24 EVF, JetBus).
* 2026-11-12: `scripts/MountedGun.lua` (machine guns: DShK, M2, PKM); AVF's shell code ported (`port_avf.py`):
  ZU-23-2, BMP-1/1P/2/3; playtest fixes (sandstorms, Simonov-9 mags, loot table, med rotation).
* 2026-11-13: tanks (gunner place + driver fallback), launchers (Katyusha, WMIK MILAN), coax MGs and BMP ATGMs,
  Immersive_Tank.lua, AVF performance fixes; AS350 helicopter (vehicle with seats, v2 port, mouse-aim flight;
  rockets on RMB shelved); v1 survey of normal play → minivan helper, crew sitters, T-72A, GMG offroad, SPG-9
  technical, Kornet / AGS-30 tripods converted and verified SP (tripods as gun emplacements; AGS-30
  pitch shelved), AVF body pushes capped (freeze); docs tidied (dated logs → this summary and git).

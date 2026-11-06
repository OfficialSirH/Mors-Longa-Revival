# Mors Longa Revival — technical reference

Working reference for porting Mors Longa to Teardown 2.x multiplayer (`#version 2`).
Read this first in any new session. Facts are marked **[verified in-game]**,
**[official source]** (game files / official mods / API docs) or **[unverified]**.
`docs/PORTING.md` holds the short rule list; this file holds the detail.

---

## 1. Where things are

### On the user's PC (device "micah-pc")

| What | Windows path | In device shell |
|---|---|---|
| Repo (git, work on `main`, `original` = untouched Workshop copy) | `C:\Projects\Mors Longa` | `$HOME/mnt/Mors Longa` |
| Teardown install | `C:\Program Files (x86)\Steam\steamapps\common\Teardown` | `$HOME/mnt/Teardown` |
| Subscribed Workshop mods | `C:\Program Files (x86)\Steam\steamapps\workshop\content\1167630` | `$HOME/mnt/1167630` |
| Local mods the game loads | `%USERPROFILE%\Documents\Teardown\mods` (user links the repo in as "Mors Longa Revival") | – |

* Game version on the user's PC: 2.x, API doc 2.1.0. Single-player works with the original v1 mod.
* Remote: `git@github.com:OfficialSirH/Mors-Longa-Revival.git` (SSH; the user pushes). No git identity is
  configured in the device shell, and committing needs delete permission (git lock files), so changes
  are left uncommitted for the user unless asked otherwise.

### Best primary sources (in order)

1. **`Teardown/data/script_defs.lua`** [official source] – LuaLS definitions for every API function
   (757 functions, signatures + param docs + examples). Also `voxscript_defs.lua`, and
   `td_vscode_plugin.lua` (editor plugin, see `.luarc.json` in the repo).
   Search it with: `grep -n -B25 '^function Name(' data/script_defs.lua`.
   It does **not** mark server/client-only; for that use the list in §4.
2. **Official example mods** in `Teardown/mods/` [official source]:
   * `minigun/` – custom tool with a prefab model, server fires with `Shoot`, client mirrors effects
     and animates a tool shape. **The template for guns.**
   * `lasergun/` – plain `.vox` tool, server damage (`QueryShot`, `ApplyPlayerDamage`, `MakeHole`),
     client draws beam and animates two shapes per player.
   * `smokegun/`, `jetpack/`, `mpclassics/` (game modes + mplib), `contentgamemodeexample/`
     (`gamemodes.txt`), `vehiclepack/` (vehicle XML with passenger seats).
3. **Engine scripts** `Teardown/data/script/` [official source]: `include/player.lua` (`Players()` etc.),
   `toolanimation.lua` (`ToolAnimator`, `tickToolAnimator`), `toolutilities.lua`, `sandbox.lua` and
   `fx.lua` (both already `#version 2`; Mors Longa's level XML uses them), `mp/` (mp lib, ammo).
4. **Workshop MP mods** (`1167630/<id>`), useful patterns:
   * `3621598329` Multiplayer C4 – prefab tool, client `SetShapeLocalTransform`, hides a shape with tag `invisible`.
   * `3662075963` [MP] Tripmine – minimal tool prefab (copied as template below).
   * `3625899189` Zombiedown – MP survival game mode using mplib, NPC zombies (`script/*Zombie.lua`).
   * `3623069506` [MP BETA] Physics Gun – still uses UMF in v2 (UMF can be made to work, we chose not to).
5. **mplib** – https://github.com/tuxedolabsorg/mplib (also bundled in mpclassics/Zombiedown).
6. **API web page** https://teardowngame.com/modding/api.html – WebFetch truncates it at ~97k chars
   (cuts off before Player/Tool sections). Read it in the built-in browser with JS instead, or just use
   `script_defs.lua`.

---

## 2. Workflow and tooling (this agent)

* **Work locally in the device shell** for reading/searching/small edits (python3 + node exist there;
  no Lua, no npm/pip access).
* **Heavy work in the cloud container**: it has Lua 5.1 built from source at `/home/claude/tools/lua51`
  (rebuild: `git clone https://github.com/lua/lua`, `git checkout v5.1.1`,
  `gcc -O1 -w -DLUA_USE_POSIX -o lua51 $(ls *.c | grep -vE '^(luac|print)\.c$') -lm`).
  The container is ephemeral; the copies of the tools that matter live in `tools/porting/` in the repo.
* **Moving files PC → container**: tar into `.git/claude-xfer/` on the PC (inside `.git`, so never
  committed), then `device_stage_files`. Example:
  `git ls-files -z -- '*.lua' | tar --null -czf .git/claude-xfer/lua.tgz -T -`.
* **Moving files container → PC**: `device_commit_files` from `/mnt/user-data/outputs/...`.
  **Gotcha [verified]:** re-committing a path that was committed before can deliver a *stale* earlier
  version. Always copy to a **fresh directory name** (`outputs/xfer-<timestamp>/…`) and then
  **compare `md5sum` on both sides** after every commit.
* Line endings: repo Lua files are **CRLF**. Edit with python reading bytes, normalise to `\n`, write back
  with `\r\n`. Assert on replacement counts.
* Tools in `tools/porting/` (run from repo root):
  * `check.lua` – syntax check (`#include`/`#version` lines blanked).
  * `toplevel.lua` – loads a script + its `#include` chain against a mock engine and lists API calls made
    at load time (forbidden in v2).
  * `sides.py` – per-function list of server-only / client-only / UI / registry calls (how to split a script).
  * `patches/convert_gun.py` – v1 gun → v2 converter (asserts on template deviations).
  * `tests/test_compat.lua`, `tests/test_gunnet.lua` – mock-engine tests.
* Testing loop: user runs the game and sends screenshots of red error text. Keep each round small,
  and say exactly what to test.

---

## 3. v2 script model

* `#version 2` must be the first line [official source]. Without it the script is silently disabled in
  MP. `info.txt` needs `version = 2`. v1 and v2 scripts coexist in single-player [verified in-game].
* Callbacks: `server.init/tick(dt)/update(dt)/postUpdate/destroy`, `client.init/tick(dt)/update(dt)/postUpdate/draw/render(dt)/destroy`.
  `init/tick/draw` globals and `handleCommand` are not called in v2.
* `server`, `client`, `shared` tables exist at load time everywhere (script_defs declares them, and
  official mods assign `server.x = …` at top level). The host runs both halves in **one Lua state**, so
  client code reading server variables works on the host and breaks for remote clients. SP tests cannot
  catch that.
* `shared`: server writes, clients read (synced). `ClientCall(playerId, "client.fn", …)` (0 = everyone),
  `ServerCall("server.fn", …)`. Target functions must exist in the same script. Table arguments are used by `gunnet.lua` [unverified].
* Registry: `SetBool/Int/Float/String(key, value, [sync])`; `sync=true` pushes to clients. v1 tool keys
  still work on the server: the lasergun does `SetBool("game.tool.lasergun.enabled", true)` in
  `server.init` [official source]. `savegame.mod.*` is per machine.
* `#include "script/include/player.lua"` defines the iterators [official source]:
  `Players()` = `GetAllPlayers()`, `PlayersAdded()` = `GetAddedPlayers()`, `PlayersRemoved()` = `GetRemovedPlayers()`.
  The usual pattern is to create per-player state in `PlayersAdded()` on **both** server and client.
* playerId arguments: on a client, omitted/0 = local player; on the server, omitted/0 = host.
* Entity handles: compare with `~= 0`, never `> 0` [official source: FAQ].
* Events (`GetEventCount/GetEvent`): `playerhurt`, `playerdied` (server + client), `explosion`,
  `projectilehit` (server only).

### Errors seen in-game → cause **[verified in-game]**

| Message | Cause | Fix |
|---|---|---|
| `Calling the LoadSound API function before init is not supported` | engine API called while the file loads (top-level code, including `#include`d files) | move into `init`, or load lazily; check with `toplevel.lua`. Pure math (`Vec`) at top level loads fine |
| `invalid attempt to access server authored entity from client script` | client called `Delete`/`SetShapeBody`/`SetShapeLocalTransform` on shapes the **server** created (e.g. spawned and attached by the server) | let the engine create the parts (tool prefab, §5) or do it on the server |
| tool invisible, bullets from the wrong place | `RegisterTool` with a prefab that has no `tool_space` + `<body>` (loose `<vox>`) | use the tool prefab layout, §5 |
| `attempt to concatenate … bullettable[ammo]` | original-mod bug (empty mag in realistic HUD) | fixed in all 32 guns |

### Signature traps from v1

* `GetPlayerTransform(true)` → `GetPlayerTransformWithPitch()`; `SetPlayerTransform(t, true)` →
  `SetPlayerTransformWithPitch(t)` (the extra arg is now a playerId). 91 occurrences in the mod.
* `Ui*` (including `UiMakeInteractive`) only inside `client.draw()`.
* `Shoot(origin, dir, [type], [strength], [maxDist], [playerId])`; the minigun passes a 7th arg (tool id)
  that is not in the defs.
* `QueryShot(origin, dir, maxDist, [radius], [playerId])` → `hit, dist, shape, playerId, damageFactor, normal`
  (the bullet query that also hits players).
* `GetPlayerAimInfo(pos, [maxDist], [playerId])` → `hit, startPos, endPos, dir, hitNormal, hitDist, hitEntity, hitMaterial`.

---

## 4. Server-only / client-only functions [official source: API 2.1.0 headings]

**Server only:** SetVehicleParam DriveVehicle SetVehicleHealth SetPlayerTransform
SetPlayerTransformWithPitch SetPlayerGroundVelocity SetPlayerSpawnTransform SetPlayerSpawnHealth
SetPlayerSpawnTool SetPlayerVehicle SetPlayerVelocity ReleasePlayerGrab SetPlayerScreen SetPlayerHealth
SetPlayerRegenerationState SetPlayerTool RespawnPlayer RespawnPlayerAtTransform SetPlayerWalkingSpeed
SetPlayerCrouchSpeedScale SetPlayerHurtSpeedScale SetPlayerParam RegisterTool SetToolAmmoPickupAmount
SetToolAmmo SetToolEnabled ApplyPlayerDamage DisablePlayerInput DisablePlayer DisablePlayerDamage Shoot
Paint PaintRGBA MakeHole Explosion SpawnFire RemoveAabbFires SetTimeScale SetEnvironmentDefault
SetEnvironmentProperty AddHeat SetGravity

**Client only:** InputClear InputResetOnTransition SetPlayerCharacter SetPlayerCameraOffsetTransform
SetToolHandPoseLocalTransform SetToolTransform SetToolAllowedZoom SetToolTransformOverride SetToolOffset
SetPlayerRigTags SetSoundLoopUser PlaySoundForUser AddMapMarker SelectedMapMarker GetCameraTransform
SetCameraTransform RequestFirstPerson RequestThirdPerson SetCameraOffsetTransform AttachCameraTo
SetPivotClipBody ShakeCamera SetCameraFov SetCameraDof DisableMotionBlur SetLowHealthBlurThreshold, the
haptics functions, all `Ui*`.

Unmarked (usable on both, but note the authority rules above): queries, Find*, Get*, Spawn, Delete,
PlaySound/PlayLoop, particles, PointLight, DrawLine, body/shape setters.

---

## 5. Custom tools (guns) in v2

### Tool prefab layout [official source: minigun, Tripmine, C4]

```xml
<prefab version="2.0.0">
  <group name="instance=MOD/prefab/mytool.xml">
    <group name="eye_space">              <!-- optional: poses used by ToolAnimator -->
      <location name="fp_action" tags="name=fp_action" pos="0.1 -0.3 0.0"/>
      <location name="tp_action" tags="name=tp_action" pos="0.1 -0.5 -0.1"/>
      <!-- also fp_run, tp_run, tp_crouch, tp_jump, tp_swim, *_crouch ... -->
    </group>
    <group name="tool_space">
      <body dynamic="false">
        <vox file="MOD/vox/mytool.vox" scale="0.4"/>   <!-- one <vox> per shape, in index order -->
      </body>
      <location name="muzzle" tags="name=muzzle" pos="0.025 0.02 -1.05"/>
      <location name="tp_action_rh" tags="name=tp_action_rh ik_hand" pos="..." rot="..."/>  <!-- third-person hands -->
      <location name="tp_action_lh" tags="name=tp_action_lh ik_hand" pos="..." rot="..."/>
    </group>
  </group>
</prefab>
```

* `RegisterTool(id, name, file, [group 1-6])` on the server; `file` is a `.vox` or a prefab like the one
  above. Tools start disabled: `SetToolEnabled(id, true, p)` and `SetToolAmmo(id, n, p)` for each player in
  `PlayersAdded()`.
* The engine builds the tool body **on every machine**. A client may animate *those* shapes:
  `GetToolBody(p)`, `GetBodyShapes(b)`, `SetShapeLocalTransform(shape, t)`, `SetShapeEmissiveScale`
  [official source: minigun/lasergun; not yet verified with Mors Longa's 66-part guns]. Shape order = `<vox>` order. Re-read the
  shapes whenever `GetToolBody(p)` changes. Tag a shape `invisible` to hide it (C4 mod).
* Viewmodel placement is client-only: `SetToolTransform(t, sway, p)` for the first person,
  `SetToolTransformOverride(t, p)` for third person, `SetToolHandPoseLocalTransform(right, left, p)`.
  `script/toolanimation.lua` (`ToolAnimator()` + `tickToolAnimator(anim, dt, nil, p)`) does all of that
  from the prefab locations.
* Muzzle etc.: `GetToolLocationWorldTransform("muzzle", p)` (nil if the tool body is not ready).
* The official pattern for firing: the **server** reads `InputDown("usetool", p)`, does
  `Shoot`/`QueryShot`/`MakeHole`/`SetToolAmmo`, and keeps a cooldown. The **client** runs the same timer
  for every player `p` and plays sound/light/particles and recoil. Effects for remote players come from
  the client loop over `Players()`, not from RPC.

### Mors Longa guns (v1) – how they work

* 32 gun scripts in `script/` (2–3.7k lines each, ~95% the same template). Each defines `init/tick/draw`,
  its own `Shoot(Type)` (shadows the engine `Shoot`), `Reload`, `ShootGrenade`, `SpentCasing`, and a huge
  `tick` (controls + viewmodel animation) and `draw` (HUD + attachment/mag UIs).
* Shared code: `gunfunctions.lua` (projectile sim `ProjectileOperations`, grenades, ADS, UI helpers,
  `LoadTool`), `gunperks.lua` (ammo types), `gunstats.lua` (recoil stats).
* Gun scripts are **spawned on demand** by `script/inventory.lua` (`Spawn('<script file="MOD/script/X.lua"/>')`,
  `gunScriptLookUp`) and deleted when unequipped. The inventory talks to guns through `inventory.*`
  registry keys (`inventory.guns.<n>.item` = `_`-joined string: `[1]` tool id, `[3]` mag id, `[5]` ammo,
  `[6]` max, `[8]` attachments `-`-joined, `[10]` bullet types `-`-joined), plus `inventory.curprimary`,
  `inventory.backpack.<i>_<j>.item`, `inventory.reloading`, `inventory.update_guns1`.
  The inventory enables/selects tools via the v1 keys `game.tool.<id>.enabled` / `game.player.tool`.
* Model: v1 registers `MOD/vox/base-weapon.vox`, then `LoadTool` (client) deletes its shape, spawns
  `script/Weapons/<GUN>-<camo>.xml` (wrapper that instances `<GUN> Base.xml` with a camo vox override) and
  re-parents all 66 parts onto the tool body. The script then animates parts **by index** every frame
  (e.g. AK74: `shapes[2]`=mag0, `[3]` bolt, `[4]` selector, `[5]` suppressor, … `[50..61]` hand/arm
  variants chosen by difficulty). `AK74 Base.xml` = 66 loose `<vox>` with no `<body>`.
* Projectiles are simulated in Lua (`projectileHandler.shells`), with damage via `MakeHole`, NPC damage via
  registry `level.goreai.body_damage_player.<bodyHandle>` (+ `_x/_y/_z`, `_vel_x/_y/_z`), blood via
  `Blood_Pop` → `PaintRGBA`.

### Current v2 gun design (repo state)

* `gunfunctions.lua`: `ProjectileOperations`/`GrenadeOperations` honour `projectile.doWorld` /
  `projectile.doFx` (unset = v1 behaviour). Impact sounds load lazily (`GunFunctions_LoadSounds`).
  `LoadTool(body, prefab)` attaches to the given body.
* `gunnet.lua`: shot replication (client sim for fx, server sim for world), melee holes, casings,
  `GunNet_SetTool`, `server.gunLoadTool` (server-side LoadTool; **does not work**, since the client then
  can't animate the parts).
* Tool prefabs: `tools/porting/make_tool_prefab.py <GUN> [camo…]` writes `script/Weapons/<GUN> Tool.xml`
  (+ `<GUN> Tool-<camo>.xml`): the `<vox>` lines of `<GUN> Base.xml` copied verbatim, **in reverse order**, into
  `tool_space` → `<body dynamic="false">`, camo vox swapped in. Valid because the `<GUN>-<camo>.xml`
  wrapper offsets cancel (AK74: `0.5 -1.5 0.1` + `-0.5 1.5 -0.1`), so v1 `LoadTool` put each part at its
  Base.xml position; the generator asserts that.
* **Overlapping parts lose voxels [verified in-game 2026-11-04]:** in the engine-built AK74 tool, every part
  that overlaps another part in Base.xml came out cut down (handguard 3×16×7 → 1×3×3; scope/holo/rail → 0×0×0)
  without firing a shot; parts that overlap nothing are intact. (An earlier note blamed own bullets — wrong; the
  user had not fired.) Fix (confirmed: handguard 30 now 3×12×6, rail 9 2×16×2, gun complete): the generator
  builds part i shifted +i m on x (no overlaps) and
  `GunNet_FixToolParts()` moves them back on the client before the gun reads transforms. Parts are also tagged
  `ml_toolpart unbreakable` (tool body is a real world body; melee MakeHole at the stock would hit it) and
  `GunRaycast()` skips `ml_toolpart` shapes.
* Lanes (2026-11-04, after TT33 test): 24 m grid, 10 columns (`lane_x = ((i-1)%10+1)*24`, `lane_y = floor((i-1)/10)*24`);
  `GunNet_FixToolParts` decides **per part** (moves a part back only while `|x - lane_x| < 12`). The earlier
  'check the last part only' guard failed on the TT-33 (its last part is a hand the gun code repositions every
  frame). Base.xml parts without `file=` inherit the vox from the wrapper's `prop0="file=…"`; the generator now
  fills it in (TT33, G17, M107, M4, FiveSeven had such parts).
* Debug overlay (any v2 gun): Ctrl+O = part index labels, Ctrl+L = table of local pos / voxel size / rotation
  per part (`GunNet_DebugParts` / `GunNet_DebugTable` in gunnet.lua). Offline render of a gun model:
  `tools/porting/render_gun.py` (container) / vox parser `vox.py`.
* **Part order:** v1 index `i` = the i-th part counted from the **end** of Base.xml (GetBodyShapes lists the
  most recently attached shape first). AK74 (file lists objects 65..1): `[2]` mag = "2" [verified in-game];
  FiveSeven (file lists 1, 1-1..1-25): `[2]` mag = "1-24", `[5]` suppressor = "1-21" (from the code). An
  engine-built tool numbers parts in file order, so the generator writes them reversed.
* `AK74.lua` is v2 again (2026-11-04, 3rd attempt): registers `AK74 Tool.xml`; client waits until the
  tool body has its parts (`#GetBodyShapes(b) > 8`) and then animates them by index as in v1.
  [unverified in-game] Open questions: default tool placement for a prefab without `eye_space`
  (could shift the viewmodel vs. v1's vox tool), and camo (only the default is registered).


### All guns converted (2026-11-04)

* 38/38 gun scripts are v2 (`convert_gun.py`; RPG converted by hand with the same helpers). Two kinds:
  * **LoadTool guns** (AK74, FiveSeven, G17, G18 [uses G17 model], M107, M4A1 [M4 model], M870, MP5, TT33):
    registered with a generated `script/Weapons/<GUN> Tool.xml` (+ camo variants generated, not yet used).
  * **vox guns** (the other 27): registered with their multi-object `.vox` as before; the engine builds them
    (same path v1 used on 2.x, e.g. PP19 renders fine).
* Converter rules added: RegisterTool anywhere in `init()` (last call wins); init ammo
  `SetFloat("game.tool.<id>.ammo", n)` → `SetToolAmmo` per player; all unqualified `Shoot(` → `FireRound(`
  (the gun's own Shoot overrides the engine global script-wide); fire hook matches the last spread line
  (rifles `accuracyFactor`, shotguns `pelletSpread` in a per-pellet loop); `update(dt)` → `client.update`;
  scope look tweak (`SetPlayerTransform(ppos2, true)` + `SetPlayerVelocity`) disabled, TODO via
  `SetToolAllowedZoom`; local copies of `ProjectileOperations`/`GrenadeOperations` (PKM, SG553) get the
  same world/fx prologue + `GunRaycast`.
* Original-mod bugs: Sawed Off gated its inventory update on `game.tool.gun-mp43.enabled` (fixed to itself);
  PKM's own projectile sim has no NPC damage (kept as-is); FiveSeven hand indices 18–29 exceed its 26 parts
  (kept as-is).
* RPG rocket: spawned on the server via `GunNet_SpawnCasing`; the rocket prefab runs `script/grenade.lua`
  (still v1: fine in SP, must be ported for MP).
* Unverified for vox guns: whether gun melee (`MakeHole` at the stock) or the bullets' first raycast can
  damage an engine-built vox tool (they are not tagged `ml_toolpart unbreakable`).


### Gun scripts → in-game names (HUD shows the RegisterTool name)

| Script | Tool id | In-game name | Model |
|---|---|---|---|
| `AK101.lua` | `gun-ak101` | **Simonov-556** | vox |
| `AK50.lua` | `gun-ak50` | **Jalaad** | vox |
| `AK74.lua` | `gun-ak74` | **Simonov-545** | LoadTool |
| `AK74M.lua` | `gun-ak74m` | **Simonov-106** | vox |
| `AKM.lua` | `gun-akm` | **Simonov-762** | vox |
| `CZ-1012.lua` | `gun-cz1012` | **CZ-1012** | vox |
| `Dessert Eagle.lua` | `gun-deagle` | **Deagle** | vox |
| `FiveSeven.lua` | `gun-fiveseven` | **TCP-57** | LoadTool |
| `G17.lua` | `gun-g17` | **P17** | LoadTool |
| `G18.lua` | `gun-g18` | **P17A** | LoadTool |
| `G3.lua` | `gun-g3` | **MC308** | vox |
| `G36.lua` | `gun-g36k` | **MK36** | vox |
| `KS23.lua` | `gun-ks23` | **KS23** | vox |
| `M107.lua` | `gun-m107` | **N107** | LoadTool |
| `M16.lua` | `gun-m16` | **N16** | vox |
| `M4A1.lua` | `gun-ar15` | **N4A1** | LoadTool |
| `M870.lua` | `gun-m870` | **N870** | LoadTool |
| `M9.lua` | `gun-m9` | **M9** | vox |
| `MP43.lua` | `gun-mp43` | **Mudafie** | vox |
| `MP5.lua` | `gun-mp5` | **MC9** | LoadTool |
| `MosinNagant.lua` | `gun-mosin` | **Medvedev** | vox |
| `MosinNagantM.lua` | `gun-mosinm` | **Medvedev Military** | vox |
| `P90.lua` | `gun-p90` | **TMP-90** | vox |
| `PKM.lua` | `gun-pkm` | **PKM** | vox |
| `PP19.lua` | `gun-pp19` | **Simonov-9** | vox |
| `PPSh.lua` | `gun-ppsh41` | **PPSh-41** | vox |
| `RPG.lua` | `gun-rpg` | **RPG-7** | vox |
| `SCAR-H.lua` | `gun-scarh` | **TCR-308** | vox |
| `SCAR-Hg.lua` | `gun-scarhg` | **TCR-308** | vox |
| `SCAR-L.lua` | `gun-scarl` | **TCR-556** | vox |
| `SCAR-Lg.lua` | `gun-scarlg` | **TCR-556** | vox |
| `SG553.lua` | `gun-sg553` | **Bauer-553** | vox |
| `SKS.lua` | `gun-sks` | **SKS** | vox |
| `SV98.lua` | `gun-sv98` | **SV-98** | vox |
| `SVD.lua` | `gun-svd` | **Drozdov** | vox |
| `Sawed Off.lua` | `gun-sawedoff` | **Qasira** | vox |
| `TT33.lua` | `gun-tt33` | **TT-33** | LoadTool |
| `VECTOR.lua` | `gun-vector` | **SCALAR** | vox |

---

## 6. Vehicles [official source: vehiclepack]

* Driver position: `<location name="player" tags="player" .../>` (+ `player_steeringwheel`).
* Passenger seats (2.x multi-occupant): one `<location name="seat" tags="seat" .../>` per seat
  (vehiclepack has 107). Exit points: `<location tags="exit" .../>`.
* Mors Longa vehicle XML: 279 `player` locations, only 3 `seat` locations, so seats need adding for co-op.
  The mod also has its own fake passenger system (`scripts/Game/PlayerVehicleSeat/`) to replace.
* API: `GetVehicleAvailableSeatPos`, `GetVehiclePassengerCount(v)` → `count, seats, hasDriver`,
  `IsPlayerVehicleDriver/Passenger(v, p)`, `SetPlayerVehicle(v, p)` (server), `DriveVehicle` (server).
  `SetVehicleHealth` only with the `customhealth` tag.

---

## 7. Mors Longa architecture map

* Size: ~478 Lua files / ~220k lines; **~316 files / ~108k lines reachable** from XML entry points
  (181 entry scripts) + 32 guns spawned at runtime. The rest is dead code (copies, `unused/`).
* Level: `main.xml` / `level.xml` → `level_instance.xml`; scripts attached in `level_scripts.xml`
  (groups: MorsLonga, ToolsAndWeapons, ProceduralGeneration, PlayerBody, InventoryMod, NPCs).
* Libraries: `scripts/TDSU/tdsu.lua` (Cheejins utils; now includes `compat.lua` instead of UMF),
  `Settings.lua` + `Settings_Table.lua` (settings in `savegame.mod.settings` via `util.structured_table`),
  `Config.lua` (`savegame.mod.config`), `Automatic.lua`.
* World generation: `Procedural/GenerateRoad.lua` builds road ahead of the player and **shifts the whole
  world back and teleports the player** (~lines 216–260). Co-op plan: furthest player drives
  generation, stragglers get teleported, shift applies to all players.
* NPCs: `GoreNPCs/scripts/goreai_main.lua` (+ components), spawned by `Procedural/RandomEnemy.lua` /
  `RandomVehicleEnemy.lua`; enemy cars driven by `scripts/chaseOperator.lua`, `ConvoyOperations.lua`
  (`DriveVehicle`, server-only in v2).
* Health: `HealthSystem/AdvancedHealthScript.lua` with hitbox triggers that follow the single player.
* AVF: vehicle files in `avf/` are local; the runtime (mounted guns) is the external AVF mod (not MP).
  Plan: own mounted-gun script reading the same tags (`mainCannon component=gun weaponType=… interact=mountedGun`).
* Original-mod bugs found: empty-mag HUD concat (fixed in all guns); inventory `invSlot.rotation` nil when
  dropping an item from a gun slot (fixed); `script/craftingrecipes.lua` has a
  syntax error (never loaded).

---

## 8. Status log

* 2026-11-03: plan agreed (co-op ≤4, stragglers teleported, replace AVF with own gun-mount script,
  assets free to use with credit). UMF replaced by `scripts/TDSU/compat.lua`. Porting tools added.
* 2026-11-04: AK74 v2 attempts. Learned: no API calls at load time; clients cannot touch
  server-created entities; a tool prefab must use the `tool_space`/`<body>` layout. AK74 reverted to v1.
  Folders for the Teardown install + Workshop mods were connected, and this reference was written.
  AK74 v2 with generated tool prefab: renders correctly, fires, reloads [verified in-game] after the
  overlap fix (build parts in separate lanes, move back on client). Earlier: parts were misplaced
  (file order) → prefab regenerated in reverse order, awaiting test. Fixed original-mod bug in
  `inventory.lua` (`invSlot.rotation` nil for special slots, 3 places).
* 2026-11-05: TT-33 Ctrl+L table checked against `TT33 Base.xml`: all visible parts at the expected place; y=-200 parts are script-hidden (unused attachments, alt mags, other-difficulty arms). User suspects a missing chunk, unconfirmed. Simonov-545 bug [repro by user]: RPG in sling + Simonov on back → `client.init` crashed at `Split(guninfo[10])` (it reads the *current primary* slot's item, RPG has 7 fields) → `projectileHandler`/`bullettable` nil every frame, parts left in build lanes. Original-mod code; fixed by making `Split(nil)` return {} in `gunfunctions.lua` (covers all guns).
* 2026-11-05: Split fix verified in-game (RPG sling + Simonov back works). Open: after RPG use, Simonov ADS tilted left once (fixed by re-equip) - cause unknown; only tilt in AK74 is canted aim `q` (key C / NVG on), never reset on equip. GoreNPCs `Automatic.lua:308` (AutoVecSubsituteY(nil)) while NPCs shoot: guarded the only lookPos caller in `goreai_combat.lua` draw_combat_details (dead debug computation); unverified that it was the caller.
* 2026-11-05: N870 empty-tube HUD error (`M870.lua:1700` concat nil) = same original bug as the 32-gun fix, other form `..bullettable[#bullettable]`; fixed in M870, MP43 (Mudafie), Sawed Off (Qasira). Guard also skips "" (empty tube = `Split("","-")` = {""} in N870/Mudafie). No unguarded `..bullettable[...]` concatenations left in `script/`.
* 2026-11-05: `Procedural/RandomVehicleEnemy.lua:128` concat nil `whichone` = original bug: AAF timer below 5000 m leaves global `whichone` unset (crash; after a civ spawn it re-spawned that civ car instead). Fixed: local, no AAF spawn below 5000 m. Also reordered (user OK'd balance change): `> 8000` now tested before `> 5000` / `> 4000` so the AAF1 truck can spawn (both AAF timer and `SpawnRandomEnemyVehicle`).
* 2026-11-05: Debug spawn menu (`scripts/UI/SpawnMenu.lua`) lists only what is in the loot tables `Procedural/SpawnRefrenceTable.lua` (`spawnables.loots`); only one ammo variant per caliber is there (mostly FMJ). 4GA ammo was in no table (only NPC drops) → added `Ammo 4GA BS.xml` to civWeapon next to the KS23. Fixed table entries pointing at missing files: `Gun KS23 #2`→`Gun KS2 #2`, `Ammo .50BMG FMJ`→`Ammo 127x99 FMJ` (x2), `Gun P17 Grey1`→`Gun P17 Grey` (x2). Left: `Mag MC9 #3.xml` (no MC9 mag3 exists at all). KS23/N870 reload starts (animation) even with 0 reserve ammo: `Reload()` only checks `ammo < magsize + 1`, not reserve; original behaviour, not changed yet.
* 2026-11-05: Spawn-menu audit of all gun/mag/ammo prefabs vs loot tables. Not reachable before: guns PKM, Bauer-553, M9; mags TMP90, TCR 7.62 (Spawn table only, which the menu ignores: nested groups, no title), TCP-57, Simonov 5.56 (only `Loots/mag0-ak-556.xml`, no spawnable wrapper → added `Mag Simonov 5.56 #0.xml`); every non-FMJ ammo type + .50AE. Added menu-only category `debugTest` ("Weapons → Testing") with all of them. No mag item exists at all for M9 (`mag0-m9-9x19`) or PKM (`mag0-pkm-762x54`); PKM script reloads from **ak-545** mags (original copy-paste, `PKM.lua:140/1580`); Jalaad init matches `ak-762x54` but tick `m107-127x99` mags.
* 2026-11-05: PKM pickup crashed `inventory.lua:3191` (`gunScriptLookUp` had no `gun-pkm`) → added; both script-spawn loops now skip ids without a script (`gun-mgl` [MGL.lua is v1, not converted], `gun-ak12`, `gun-mp443`).
* 2026-11-05: **PKM and M9 shelved as unfinished by the original devs** (user agreed): PKM only placed in `test.xml`, not in loot tables / script lookup, no mag item, reloads from ak-545 mags, never calls `WeaponInit` (TimeSinceShoot nil, gunfunctions.lua:42), model parts misplaced; M9 has no mag item and no description. Bauer-553 (SG553) also only in `test.xml` and also never called `WeaponInit` → added the call; otherwise complete (description, uses MK36 mags). Revisit PKM/M9 after the port (Phase 5 or later).
* 2026-11-05: Bauer-553: `SG553.lua:1131` perktable nil - script predates the per-round ammo system (`gunperks[perk][Cpkl+1]` perk *levels*, `FireRound()` without a round type, no `bullettable`), so it is unfinished too; proposed shelving with PKM/M9. Correction: the messy PKM/Bauer models are NOT evidence of a broken model - both scripts crash early in the tick, before they place the parts each frame.
* 2026-11-05: **Gun testing done** - all guns work except PKM, M9, Bauer-553 (shelved, unfinished). Phase 1 continues with the 55 level scripts (`level_scripts.xml`, all v1). Melee weapons (8) converted to v2 with `tools/porting/patches/convert_melee.py`: client = input/animation/raycasts/sound/particles; world effects queued in `Melee_Functions.lua` (`MeleeNet_MakeHole` merged per pos, `MeleeNet_Impulse` summed per body, NPC damage) and sent once per frame from `client.postUpdate` → `server.meleeOps`. The v1 `game.tool.<Name>.enabled/ammo` lines used the wrong key (no-ops) and were dropped; the inventory still enables `game.tool.melee-*`. Remote players don't hear/see other players' swings yet. Syntax + mock swing checked with `texlua` (Lua 5.3 from TeX Live; no network for building Lua 5.1 this session). Awaiting in-game test. Only FireAxe/Tomahawk/CombatKnife were spawnable: added `Melee <Name>.xml` wrappers for BaseballBat, Crowbar, DamnedScythe (Loots items existed, only used in `test.xml`) and new pickup items `Loots/melee-Katana.xml`, `melee-Pipe.xml` (tool vox as model) to Weapons → Testing; Crowbar added to the inventory `meleelist` (could never be equipped).
* 2026-11-05: Melee (all 8) verified in-game.
* 2026-11-05: Phase 1 step 2 converted (awaiting test): `script/meds.lua` (AI2/CMS animation only; healing is in the inventory), `scripts/Grenades.lua` (client: input/inventory/aim arc/explosion fx+sounds via `client.grenadeExplode`; server: `server.throwGrenade` spawns, timers, holes, shrapnel `Shoot`, throw-back by any player; dropped the unused `goreai_grenades.lua` include - its top-level do-block calls LoadSprite at load; the Glare/Shockwave branch was already unreachable in v1), `scripts/Game/PlaceTool/PlaceTool.lua` (client-spawned local preview body; `server.placeAt` spawns + attaches; `ReleasePlayerGrab` per player in server.tick; UiMakeInteractive/UiSound moved to draw via flags), `script/Weld.lua` (`server.weld` joint spawn, `server.weldTakeFuel`). Assumption to verify in MP: entity handles (shape/body) sent client→server refer to the same entity (used by melee, PlaceTool, Weld). `toplevel.lua` now also runs under `texlua` (Lua 5.3).
* 2026-11-05: Meds/Weld verified in-game. Original inventory bugs (material/ammo removal, `inventory.lua` ~3310): partial stack use never set `invChanged` → `CountAmmo()` not rerun → stale `inventory.count_*` (Place Tool built with materials already spent, UI lagged); material deficit stored under the backpack column `[i]` instead of the material → every stack lost the full amount. Both fixed. Grenade shrapnel: `Shoot` got a non-unit direction `RSV(0.01)` → normalized (unverified that this was why shrapnel did nothing). Type-67 grenade (`grenade1`) only existed in `test.xml` → added to Weapons → Testing, so T (switch grenade type) can be tested.
* 2026-11-05: Phase 1 step 2 (meds, grenades incl. Type-67 + shrapnel, Place Tool, Weld) verified in-game.
* 2026-11-05: Phase 1 step 3a converted (awaiting test): newLeveltoLEVEL (server), Radio (client), pauseMenu (official PauseMenuButton pattern: host only, `main_bottom`, `server.startLevel`), window (all commented out; marker only), door_global (server, per player), mine (server, any player within 1 m; sounds via ClientCall), randomdelete (server), bloodpool (server; PaintRGBA), CarAlarm (server triggers + `shared.carAlarms`; clients play loop/light; v1 `handleCommand("explosion ...")` replaced by `GetEventCount/GetEvent("explosion")` as in the official robot.lua; `server.handleCommand(cmd)` still exists in v2, see data/script/main.lua), Cultist Spawner (server; original bug `GetPlayerVehicle == 0` → ambushes never happen, kept, ask user), Lean (client), ingame_settings (client UI). **Thermals deferred**: palette edits of world shapes for a per-player view - needs a client-only redesign (e.g. DrawBodyHighlight/DrawShapeHighlight). Left for step 3b: Airstrike, Game/script.lua + ToolManager, daynight_main, Die, Fuel, Gamerule, PlayerVehicleSeat, ShootFromCar, Config.lua (entry script).
* 2026-11-05: Step 3a verified except the pause button: `PauseMenuButton("MorsLonga Menu", "main_bottom")` guarded by `IsPlayerHost(GetLocalPlayer())` did not appear in SP → now default bottom bar + `IsPlayerHost()` (the pattern the engine scripts use; which of the two was the cause is unknown). Cultist Spawner bug fixed (`GetPlayerVehicle()`), user wants on-foot ambushes on.
* 2026-11-05: **PauseMenuButton placement [verified from engine source `data/ui/hud.lua` ~3410-3600]:** the main pause menu shows `game.pausemenu.mainmenu.main_top.*` buttons above "Main menu" and one primary mod button (`game.pausemenu.primary`, the v1 `PauseMenuButton(title, true)`) below it. `"main_bottom"` is documented in script_defs.lua but **never drawn** by this hud.lua. pauseMenu.lua now uses the v1 `true` form (awaiting test; fallback `"main_top"`). Lesson: for UI behaviour check `data/ui/hud.lua`, not only the API docs.
* 2026-11-05: Pause button with `PauseMenuButton(title, true)` verified in SP (below "Main menu"). **MP test list:** check it in MP; fallback `"main_top"` (only one primary slot across all mods).
* 2026-11-05: Phase 1 step 3b converted (awaiting test): Die, Gamerule, ToolManager (server; still v1 `game.tool.*.enabled` registry, per-player in Phase 2), Game/script.lua (client; dropped unused ToolManager include), PlayerVehicleSeat (client-local seat model; others' models = Phase 3), Airstrike (server flies A-10 + world-only rounds `doFx=false`; clients get each round via `client.a10Round` + sound events, smoke while `shared.a10Plane`), daynight_main + sandstorm.lua (server: clock/env/storm/campfire+bed skip for any player; `level.daynight.*`, `level.dayphase`, `level.IsSandstorm`, `level.InfiniteFuel` written with the registry **sync flag**; client: storm sound, campfire particles, bed clock), Fuel (server per player incl. running dry `SetPlayerVehicle(0,p)`; client outlines/line/sound/bars; the engine interact prompt now shows the can text - v1 cleared it from draw), ShootFromCar (server per player, client reports its drive-by keybind via `server.setDriveBy`; `shared.driveByVehicle[p]`). **Config.lua split**: it is a library included by many scripts and its v1 init/tick/draw leaked into includers without their own (v1 drew the debug UI several times); callbacks renamed `ConfigMenu_Init/Tick/Draw`, new level script `scripts/ConfigMenu.lua` (4 level xmls repointed), debug-menu spawns via `ConfigSpawn` → `server.configSpawn`; (Correction: `main.lua` does NOT include Config.lua - a loose grep matched `ModConfig.lua`; the `init` added to it crashed at start/on kills and was reverted. Use `#include "([^"]*/)?Config\.lua"` to find includers.) `client.handleCommand` exists in v2 (data/script/spawn.lua). Thermals still deferred.
* 2026-11-05: Step 3b verified in-game (user: "all good").
* 2026-11-05: Thermals converted (client only; awaiting test). v1 EditPalette was undefined in its include chain and no prefab has "Bleedable" shapes → the palette part never ran; replaced by DrawShapeHighlight. Enemy "blood" fade kept locally instead of rewriting the tag.
* 2026-11-05: Phase 1 step 4 (UI) converted (awaiting test): Book (client), SpawnMenu (client UI; `server.spawnMenuSpawn` / `server.spawnMenuUndo` with a per-player spawn history). Next: step 5 procedural generation + NPC spawners, then health/inventory with Phase 2.
* 2026-11-05: PVS-14 / PNV-10T eyewear only existed in `test.xml` (Loots items, no spawnable wrapper) → added `PVS-14.xml`, `PNV-10T.xml` to Weapons → Testing.
* 2026-11-05: Thermals/PNV-10T highlighted nothing visible: `FindBodies("bodypart")` only finds ragdoll heads (the tag is on shapes, `prefabs/assets/ragdoll components/Standard Ragdoll.xml`). Now highlights every NPC from `level.goreai.api.npcs.alive/dead` + `GetJointedBodies(torso)`, skipping vehicle bodies.
* 2026-11-06: Thermals (whole-NPC highlight), PVS-14/PNV-10T, Book, SpawnMenu verified in-game. Phase 1 steps 1-4 done. Starting step 5 (procedural + NPC spawners).
* 2026-11-06: Phase 1 step 5 converted (awaiting test). New tool `tools/porting/patches/convert_server.py` (init/tick/update/handleCommand → server.*, per-file asserted edits). Server: GenerateRoad (generation/shift/distance follow `GetGenerationPlayerPos()` = host for now, Phase 3: furthest player; **world shift moves all players** not in a vehicle with `SetPlayerTransformWithPitch(t,p)`; `level.map_moved`, `level.map_move_vec.*`, `level.distancetraveled`, `level.difficultycoef`, `savegame.mod.distanceProgressed`, `inventory.refreshshop` synced), RemoveRoad (rearmost player; never a car any player is in), WaterMover (nearest player), RandomVehicle/Building/DeceasedBurnt/Loot/RoadSign, BuildingGrassRemover, script/randomloot (crate prompt per player), RandomEnemy, RandomVehicleEnemy, masterScriptRemover. Client: PlayerID, RegistryWatcher reg.lua (moved `GetIntParam` + registry tree build from load time into client.init). ReturnToShadowVolume.lua: commented out, marker only. All 55 level scripts are now v2 except AdvancedHealthScript + inventory (Phase 2).

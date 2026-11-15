# Mors Longa Revival — engine rules and workflow

Part of the technical reference (index and conventions: [TECHNICAL_REFERENCE.md](TECHNICAL_REFERENCE.md)).
Marks: **[verified in-game]**, **[official source]**, **[unverified]**.

## Sources
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
   (`grep -n -B25 '^function Name(' data/script_defs.lua`). It does not mark server/client-only ("Server-only / client-only API").
2. **Engine scripts** `Teardown/data/script/` and `data/ui/hud.lua` [official source]: `include/player.lua`,
   `toolanimation.lua`, `robot.lua` (v2 AI: Constrain*, QueryPath, explosion events from server callbacks),
   `spawn.lua` / `creativemode.lua` (DisablePlayerInput, SetPlayerHidden per tick). For UI behaviour read
   `hud.lua`, not only the API docs ("v2 engine rules" PauseMenuButton).
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

## Workflow
* Agent runs on the user's PC: Git Bash + PowerShell, no system Lua. Per session:
  * Lua 5.1: build from `https://github.com/lua/lua` (`git checkout v5.1.1`;
    `clang -O1 -w -o lua51.exe $(ls *.c | grep -vE '^(luac|print|ltests)\.c$')`, LLVM is installed).
  * Python 3.13 is installed (`python`; `python3` is not on PATH).
  * Blender 5.2 with Blender MCP (`mcp-for-blender`, server registered in the repo's `.mcp.json`, telemetry off):
    the user starts it in Blender (N panel → "MCP for Blender" → Start MCP Server). Used for vehicle seats ([VEHICLES](VEHICLES.md)).
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

## v2 engine rules
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
  within minutes (teardown.exe +0x60966F / +0x6092F1 / +0x60E604). This was the long crash hunt ([STATUS](STATUS.md) "History").
* **Scripts are not linked to their objects**: `GetEntityChildren(script, ...)`, `GetEntityParent(e, "", "script")`
  and `GetProperty(script, "file")` return nothing. `Spawn` returns the script handles too and `Delete(script)`
  works, so keep Spawn's result to clean up a prefab's scripts (GenerateRoad segment groups).
* **`<screen script="...">` scripts run as v1**: with `#version 2` the `client`/`server` tables don't exist
  ("attempt to index global 'client'", Cadillac dashboard `dash.lua`, 2026-11-09). Kept v1 for now (`dash.lua`,
  `tutMedTV.lua`, the helicopter screens). The engine disables v1 scripts in multiplayer (user, 2026-11-09), so these
  screens are blank in MP: open item in [STATUS](STATUS.md) "Open questions and known gaps".
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
| tool invisible, bullets from the wrong place | RegisterTool prefab without `tool_space` + `<body>` | tool prefab layout ([GUNS](GUNS.md)) |
| engine "General crash", empty Lua stack, worker-thread access violation | Constrain* called from tick | call from server.update |
| `attempt to index global 'client' (a nil value)` in a `<screen>` script | screen scripts run as v1, no `client` table | keep the screen script v1 |
| `attempt to index local 'perktable'` in a gun | round with no bullet type (unlimited ammo on an empty gun) | `GunPerkFor` fallback ([CHANGES](CHANGES.md)) |

### Signature traps from v1
* `GetPlayerTransform(true)` → `GetPlayerTransformWithPitch()`; `SetPlayerTransform(t, true)` →
  `SetPlayerTransformWithPitch(t)` (the extra argument is now a playerId).
* `Ui*` (incl. `UiMakeInteractive`) only inside `client.draw()`.
* `Shoot(origin, dir, [type], [strength], [maxDist], [playerId])`; `QueryShot(origin, dir, maxDist, [radius],
  [playerId])` → `hit, dist, shape, playerId, damageFactor, normal`; `GetPlayerAimInfo(pos, [maxDist], [playerId])`.
* `Quat(x, y, z, w)` builds a quaternion from 4 numbers (used to pass rotations through ServerCall).

## Server-only / client-only API [official source: API 2.1.0 headings]
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
subject to the authority rule in "v2 engine rules". The mock engine (`tools/porting/tests/mockengine.lua`) flags wrong-side calls
from these lists.

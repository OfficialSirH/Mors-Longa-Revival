# Mors Longa Revival – porting notes (v1 → Teardown 2.x multiplayer)

Short rule list. Full detail, sources and project map: `docs/TECHNICAL_REFERENCE.md`.

Reference: Teardown scripting API 2.1.0 (https://teardowngame.com/modding/api.html),
official mplib (https://github.com/tuxedolabsorg/mplib).

## How v2 scripts work

* A script opts in with `#version 2` on its first line. Scripts without it are
  **silently disabled in multiplayer** (they still run in single-player).
  `info.txt` needs `version = 2` before the mod is offered in multiplayer.
* v1 and v2 scripts can coexist in single-player. That is how this port is
  done: one script at a time, tested in single-player after each step.
* The same file runs on the server (host) and on every client. Callbacks:
  * server: `server.init()`, `server.tick(dt)`, `server.update(dt)`,
    `server.postUpdate()`, `server.destroy()`
  * client: `client.init()`, `client.tick(dt)`, `client.update(dt)`,
    `client.postUpdate()`, `client.draw()`, `client.render(dt)`, `client.destroy()`
  * The v1 globals `init/tick/update/draw` and `handleCommand` are not called.
* The host is both server and a client. **Bugs where the client reads server
  state still work on the host**, so single-player testing will not catch them.
  Rule: client code only reads `shared.*`, the registry, and engine queries.
* `shared` table: written by the server, read-only on clients, synced
  automatically. Keep it small and change it rarely (bandwidth).
* `ServerCall("server.fn", args...)` from a client; `ClientCall(playerId,
  "client.fn", args...)` from the server (`playerId` 0 = all players).
  The function must exist in the same script.
* Registry setters take an optional `sync` flag: `SetBool(key, v, true)`
  synchronizes the key to clients.
* `#include "script/include/player.lua"` gives the `Players()`,
  `PlayersAdded()`, `PlayersRemoved()` iterators.
* Entity handles are no longer guaranteed positive: test `h ~= 0`, never `h > 0`.
* v1 pitch flags are gone: `GetPlayerTransform(true)` → `GetPlayerTransformWithPitch()`,
  `SetPlayerTransform(t, true)` → `SetPlayerTransformWithPitch(t)` (in v2 the
  extra argument is a playerId, so the old call silently means something else).
* `Ui*` calls (including `UiMakeInteractive`) only work inside `client.draw()`.
* Entities created by the server (including each player's tool body) cannot
  be deleted or re-parented from client code ("invalid attempt to access server
  authored entity from client script"), and a client may not move shapes the
  server created either. Gun models are therefore registered as the tool's
  prefab (`RegisterTool(id, name, "MOD/script/Weapons/<GUN> Base.xml")`) so every
  machine builds the parts itself, and the client animates them as before.
  Camo variants are not applied yet.
* Engine functions may not be called while a file loads (top-level code,
  including in `#include`d files) – e.g. `LoadSound` there errors with
  "Calling the LoadSound API function before init is not supported". Move such
  calls into `init` or load lazily. `tools/porting/toplevel.lua` lists them.

## Player arguments

Almost every player function takes an optional trailing `playerId`.
On a client, omitted/0 = the local player. On the server, omitted/0 = the host.
Examples: `GetPlayerTransform([p])`, `SetPlayerHealth(h, [p])`,
`InputPressed(input, [p])`, `GetPlayerTool([p])`, `SetToolEnabled(id, on, [p])`.

## Server-only functions (must be called from server.*)

SetVehicleParam DriveVehicle SetVehicleHealth SetPlayerTransform
SetPlayerTransformWithPitch SetPlayerGroundVelocity SetPlayerSpawnTransform
SetPlayerSpawnHealth SetPlayerSpawnTool SetPlayerVehicle SetPlayerVelocity
ReleasePlayerGrab SetPlayerScreen SetPlayerHealth SetPlayerRegenerationState
SetPlayerTool RespawnPlayer RespawnPlayerAtTransform SetPlayerWalkingSpeed
SetPlayerCrouchSpeedScale SetPlayerHurtSpeedScale SetPlayerParam RegisterTool
SetToolAmmoPickupAmount SetToolAmmo SetToolEnabled ApplyPlayerDamage
DisablePlayerInput DisablePlayer DisablePlayerDamage Shoot Paint PaintRGBA
MakeHole Explosion SpawnFire RemoveAabbFires SetTimeScale SetEnvironmentDefault
SetEnvironmentProperty AddHeat SetGravity

## Client-only functions (must be called from client.*)

InputClear InputResetOnTransition SetPlayerCharacter
SetPlayerCameraOffsetTransform SetToolHandPoseLocalTransform SetToolTransform
SetToolAllowedZoom SetToolTransformOverride SetToolOffset SetPlayerRigTags
SetSoundLoopUser PlaySoundForUser AddMapMarker SelectedMapMarker
GetCameraTransform SetCameraTransform RequestFirstPerson RequestThirdPerson
SetCameraOffsetTransform AttachCameraTo SetPivotClipBody ShakeCamera
SetCameraFov SetCameraDof DisableMotionBlur SetLowHealthBlurThreshold
haptics (LoadHaptic … StopHaptic), and all `Ui*` functions (only valid in client.draw).

Everything else (queries, Find*, Get*, Spawn, Delete, PlaySound, particles,
body/shape functions) is callable from either side.

## v1 registry keys that became functions

| v1 | v2 |
|---|---|
| `GetString("game.player.tool")` | `GetPlayerTool(p)` |
| `SetString("game.player.tool", id)` | `SetPlayerTool(id, p)` (server) |
| `SetBool("game.tool.<id>.enabled", b)` | `SetToolEnabled(id, b, p)` (server) |
| `GetBool("game.tool.<id>.enabled")` | `IsToolEnabled(id, p)` |
| `Get/SetInt("game.tool.<id>.ammo")` | `GetToolAmmo(id, p)` / `SetToolAmmo(id, n, p)` (server) |
| `GetBool("game.player.canusetool")` | `GetPlayerCanUseTool(p)` |
| `GetFloat("game.player.health")` | `GetPlayerHealth(p)` |

`RegisterTool` tools start **disabled for every player**; enable per player
with `SetToolEnabled` (e.g. in a `PlayersAdded()` loop).

## Splitting a v1 script

1. `#version 2` first line; `#include "script/include/player.lua"` if it loops players.
2. Move world-changing logic (Shoot, MakeHole, Explosion, SetPlayer*, spawning
   persistent entities, DriveVehicle, damage) to `server.*`.
3. Move camera, tool transform/viewmodel animation, UI, local sounds and
   particles to `client.*`. UI goes in `client.draw()`.
4. Input: the client reads input for feel (recoil animation, sounds);
   the server reads `InputPressed(x, p)` for the authoritative action.
5. State the client needs → `shared.*` (or a synced registry key).
6. `handleCommand`/quickload handling has no v2 callback; drop it.

## Guns

* Co-op model: the client holding a gun runs all of the gun logic (input,
  ammo, recoil, ADS, reload, viewmodel, HUD) exactly as in v1.
* Bullets/grenades are simulated twice by `ProjectileOperations` /
  `GrenadeOperations` (`script/gunfunctions.lua`): on the server for world
  effects only and on every client for visuals/sound only. v1 guns leave the
  flags unset and behave as before.
* `script/gunnet.lua` carries shots, melee holes, spent casings and forced tool
  selection between client and server, and plays other players' shots.
* `tools/porting/patches/convert_gun.py` converts a gun script.

## Project status

* UMF removed: `scripts/TDSU/compat.lua` provides `util.structured_table`,
  `util.serialize`, `util.unserialize`, `IsPlayerInVehicle`.
* All 38 gun scripts are v2 (AK74 verified in-game; the rest awaiting test). See TECHNICAL_REFERENCE §5.

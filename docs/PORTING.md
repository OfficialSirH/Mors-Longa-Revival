# Mors Longa Revival – porting checklist (v1 → Teardown 2.x co-op)

Short checklist for converting one script. Why and the details: `docs/TECHNICAL_REFERENCE.md` (§3 engine rules,
§4 server/client-only API lists). Tools: `tools/porting/README.md`.

## Before

1. Find every place the script is loaded (`grep -rn "<file>" --include=*.xml --include=*.lua`) and whether other
   scripts `#include` it (then it is a library: no `#version`, rename its init/tick/draw).
2. `python sides.py <file>` – which functions touch server-only, client-only, UI, registry.
3. Read its draw function for hidden game logic (state writes).
4. Check the `original` branch before calling anything an original-mod bug.

## Convert

1. First line `#version 2`; `#include "script/include/player.lua"` if it loops over players.
2. Callbacks: `init/tick/update` → `server.*` or `client.*`; `draw` → `client.draw`; a plain `handleCommand`
   (quickload) is dropped unless it does something needed.
3. Server: world changes (Spawn of persistent things, Delete, SetBodyTransform of shared bodies, MakeHole,
   Explosion, Shoot, damage, SetPlayer*, DriveVehicle, StartLevel, RegisterTool/SetToolEnabled).
   **Constrain* only in `server.update`.**
4. Client: camera, UI (`Ui*` only in `client.draw`), tool transform / viewmodel, local sounds and particles,
   per-player savegame (money, bounty, settings), input for feel.
5. "The player" → decide per use: any player, nearest, furthest, rearmost, or a specific one passed along.
   On the server, `GetPlayer*()` without an id means the host.
6. Client → server: `ServerCall("server.fn", GetLocalPlayer(), ...)`. Server → client: `ClientCall(p, "client.fn",
   ...)` (0 = everyone) or `shared.*` / a synced registry key for state. Both functions in the same script.
   Client code never reads server Lua globals (not even on the host).
7. No API calls at load time (move into init); handles: `~= 0`, never `> 0`.
8. v1 signature traps: `GetPlayerTransform(true)` → `GetPlayerTransformWithPitch()`, `SetPlayerTransform(t, true)` →
   `SetPlayerTransformWithPitch(t)`.

| v1 registry key | v2 |
|---|---|
| `GetString("game.player.tool")` | `GetPlayerTool(p)` |
| `SetString("game.player.tool", id)` | `SetPlayerTool(id, p)` (server) |
| `Set/GetBool("game.tool.<id>.enabled")` | `SetToolEnabled(id, b, p)` (server) / `IsToolEnabled(id, p)` |
| `Get/SetInt("game.tool.<id>.ammo")` | `GetToolAmmo(id, p)` / `SetToolAmmo(id, n, p)` (server) |
| `GetBool("game.player.canusetool")` | `GetPlayerCanUseTool(p)` |
| `GetFloat("game.player.health")` | `GetPlayerHealth(p)` |

## After

1. `check.lua` and `toplevel.lua` on the file; a mock test in `tools/porting/tests/` (two players, the
   non-host player doing the thing, no wrong-side calls); run all tests.
2. Log the change in TECHNICAL_REFERENCE (§7 system, §8 if it fixes an original bug or changes behaviour). The
   converters are frozen (`tools/porting/history/`): edit files directly.
3. Tell the user exactly what to test in-game, with in-game names.

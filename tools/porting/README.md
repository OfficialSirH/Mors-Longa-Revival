# Porting tools

Helpers used to convert Mors Longa scripts to Teardown 2.x (`#version 2`).
See `docs/PORTING.md` for the rules they implement and `CLAUDE.md` / `docs/TECHNICAL_REFERENCE.md` for context.

* `check.lua` – syntax-checks Lua files with a stock Lua 5.1 interpreter
  (Teardown `#include` / `#version` lines are ignored):
  `lua5.1 tools/porting/check.lua path/to/*.lua`
* `sides.py` – per-function report of server-only / client-only / UI / registry
  calls, to see how a v1 script has to be split: `python3 tools/porting/sides.py file.lua`
* `toplevel.lua` – loads a script with its `#include` chain against a mock engine and
  lists engine calls made at load time (not allowed in v2):
  `lua5.1 tools/porting/toplevel.lua . script/AK74.lua`
* `make_tool_prefab.py` – builds `script/Weapons/<GUN> Tool.xml` (v2 tool prefab) from the gun's Base/camo
  prefabs: `python3 tools/porting/make_tool_prefab.py AK74 avertnus`
* `vox.py` + `render_gun.py` – MagicaVoxel `.vox` reader and an offline labelled side/top render of a gun model
  (needs matplotlib): `python3 tools/porting/render_gun.py vox/ak74.vox "script/Weapons/AK74 Base.xml" out.png`
* `patches/convert_gun.py` – converts a gun script in `script/` to v2 (in place).
  It stops with an error if a gun deviates from the template.
* `patches/gunfunctions.py` – the world/fx split applied to `script/gunfunctions.lua` (already applied).
* `tests/` – mock-engine tests, run from the repo root with Lua 5.1:
  `lua5.1 tools/porting/tests/test_compat.lua`, `lua5.1 tools/porting/tests/test_gunnet.lua`
* `patches/convert_melee.py` – converts the melee weapons in `scripts/Weapons/Melee/` to v2 (in place; world
  effects go through `Melee_Functions.lua`'s `MeleeNet_*` queue → `server.meleeOps`).
* No Lua 5.1 and no network? `texlua` (TeX Live's Lua 5.3) runs `toplevel.lua` and syntax checks: `texlua tools/porting/toplevel.lua . scripts/Grenades.lua`.
* `patches/convert_server.py` – mechanical v1 → v2 for world/server-only scripts (callbacks → `server.*`,
  plus per-file asserted edits in its EDITS table); importable: `from convert_server import convert`.
* `toplevel.lua` only follows quoted includes (`#include "x.lua"`). Teardown also accepts unquoted ones
  (`#include x.lua`, e.g. RegistryWatcher's reg.lua) - run `toplevel.lua` on those files directly.

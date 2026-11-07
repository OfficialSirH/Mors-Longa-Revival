# Porting tools

Helpers for converting Mors Longa scripts to Teardown 2.x (`#version 2`). Rules: `docs/PORTING.md`; context and
engine facts: `docs/TECHNICAL_REFERENCE.md`. Run everything from the repo root.

## Setup (per session, user's PC)

* Lua 5.1: clone `https://github.com/lua/lua`, `git checkout v5.1.1`, then (Git Bash, LLVM installed)
  `clang -O1 -w -o lua51.exe $(ls *.c | grep -vE '^(luac|print|ltests)\.c$')`.
  Cloud container: `gcc -O1 -w -DLUA_USE_POSIX -o lua51 $(ls *.c | grep -vE '^(luac|print)\.c$') -lm`.
  No Lua at all: `texlua` (TeX Live, Lua 5.3) runs `check.lua` and `toplevel.lua`.
* Python: a venv in the session scratchpad (`python -m venv venv`); `python3` is not on PATH on the user's PC.

## Analysis

* `check.lua` – Lua 5.1 syntax check, `#include`/`#version` lines ignored: `lua5.1 tools/porting/check.lua f.lua`.
  Lines starting with `#` are treated as directives, so don't start a code line with `#x`.
* `toplevel.lua` – loads a script + its quoted `#include` chain on a mock engine and lists API calls made at load
  time (forbidden in v2): `lua5.1 tools/porting/toplevel.lua . script/AK74.lua`. Unquoted includes
  (`#include x.lua`) are not followed: run it on those files directly.
* `sides.py` – per-function report of server-only / client-only / UI / registry calls (how to split a script).

## Converters (`patches/`)

Two kinds. **Rebuild** converters regenerate their files from a git base on every run (re-runnable; never hand-edit
those files, put changes in the converter). **In-place** converters convert a v1 file once (they assert v1).

| Converter | Kind | Files |
|---|---|---|
| `convert_gun.py <file>` | in place | one gun script; asserts on template deviations; per-gun FIXUPS + all-gun fixes (camo nil, `GunPerkFor`) |
| `convert_melee.py` | in place | 8 melee weapons (world effects via `Melee_Functions.lua` → `server.meleeOps`) |
| `convert_server.py` | in place | world scripts; `convert(path, edits, note, realms)` is imported by the others (`realms` maps v1 callbacks to `server`/`client`, default all server) |
| `convert_goreai.py [file]` | rebuild (base 6c28435) | GoreNPCs components/initializer, plus gunfunctions.lua, Melee_Functions.lua, AdvancedHealthScript.lua edits. Hand-written: goreai_main, systems/goreai_killcam, _players, _netview, _controller |
| `convert_operators.py` | rebuild (base 6c28435) | enemy/convoy car scripts (server only) |
| `convert_props.py [file]` | in place | small prefab scripts (batches A, D), RPG rocket `script/grenade.lua` (restore v1 with `git show 6c28435:<f> > <f>` before re-running) |
| `convert_shop.py [file]` | in place | shop segment scripts (batch B) |
| `convert_menu.py` | rebuild (HEAD) | main menu scripts, RotateScene; edits Config.lua once |
| `convert_horde.py` | rebuild (HEAD) | WaveHandler, HordePlaceTool (horde shelved) |
| `gunfunctions.py` | history | the projectile world/fx split as applied to gunfunctions.lua |

## Mock tests (`tests/`)

* `mockengine.lua` – stubs every API function from `script_defs.lua` (records calls, returns 0 / {} / Vec /
  Transform), flags client-only calls on the server and server-only calls on the client, fake registry, players
  (`PLAYERS`, `ORDER`, `LOCAL`, `ADDED`, `REMOVED`), `ServerCall`/`ClientCall` into `env.sent`, `shared`.
  `MockEngine.load(path, {preload = MockEngine.includes(path)})` runs a script with its include chain.
  `env.def(name, fn)` overrides a stub but still records it. Stubs return 0, which is truthy in Lua: def
  `HasTag`/`IsHandleValid`/`InputPressed` etc. to false where a test depends on it.
* Tests: `test_compat`, `test_gunnet`, `test_goreai`, `test_npcview`, `test_generateroad`, `test_removeroad`,
  `test_travel`, `test_operators`, `test_vehicleevents`, `test_props`, `test_shop`, `test_tutorial`, `test_menu`,
  `test_horde`. Run all after every change:
  `for t in tools/porting/tests/test_*.lua; do lua5.1 $t || echo "FAIL $t"; done`.

## Other tools

* `make_tool_prefab.py <GUN> [camo...]` – builds `script/Weapons/<GUN> Tool.xml` for LoadTool guns (reverse part
  order, one lane per part, tags, missing `file=` filled in).
* `vox.py` + `render_gun.py` – MagicaVoxel reader and an offline labelled render of a gun model (matplotlib):
  `python render_gun.py vox/ak74.vox "script/Weapons/AK74 Base.xml" out.png`.
* `fix_missing_scripts.py [--dry-run]` – repoints XML `<script file>` references to files that exist nowhere to
  `MOD/scripts/missing_script_stub.lua`; re-run after adding prefabs.

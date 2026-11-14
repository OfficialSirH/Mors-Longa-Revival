# Relocation tool (Phase 5 reorganization)

`relocate.py` moves files and folders of the mod and rewrites every path reference to them, then proves the result.
Run from the repo root (Python 3.13):

```
python tools/relocate/relocate.py scan                          # index all references -> out/scan.txt
python tools/relocate/relocate.py plan  tools/relocate/moves.txt  # what would change -> out/plan.txt
python tools/relocate/relocate.py apply tools/relocate/moves.txt  # move + rewrite + verify (rolls back on failure)
python tools/relocate/tests/test_relocate.py                    # the tool's own fixture tests
```

`moves.txt`: `old -> new` per line (repo paths, files or whole folders; the most specific line wins), `#` comments,
and `ack <file>:<literal>` for a run-time path prefix checked by hand (see below). `out/` holds the reports and,
after `apply`, `manifest.json` (every file move and every rewritten span).

## What counts as a reference (how the engine reads paths)

| Form | Meaning | Handling |
|---|---|---|
| `MOD/x` anywhere (XML, Lua, txt, docs) | the mod root; case-insensitive, `\` = `/`, `&amp;` etc. in XML | rewritten to the new path |
| `#include "x"` / `#include x` at the start of a line | relative to the including file, else the engine's `data/` (`script/include/player.lua`) | recomputed from both new locations; engine includes never touched |
| `LEVEL/x` | the folder named after the level being played (`main.xml` -> `main/`) | every file it could mean is **pinned**; a level with such a folder may not move |
| bare XML path (`file="fx.lua"`) | the engine's `data/` folder | never rewritten; if it also matches a mod file, that file is pinned |
| `"MOD/snd/" .. name` (literal ends in a quote, names no whole file) | a run-time prefix | allowed only if every file under the prefix moves by the same prefix change, then rewritten exactly; otherwise refused unless acked |
| plain repo path (`scripts/MountedGun.lua`) | docs, tools, tests (tests load scripts by repo path) and game-script comments | rewritten; a bare path in a game-script *string* is an engine path (`LoadLoop("tools/blowtorch-hit-loop.ogg")`), never ours |

Paths that name no file are reported as dangling and left exactly as they are.

## Checks on `apply` (any failure undoes all moves and writes)

1. Round trip: every rewritten file, with its new spans replaced by the recorded old ones, is byte-identical to
   the old file (only path spans changed).
2. Re-scan: per file, the same references as before, each resolving to the moved target; dangling ones still
   dangling; no include newly ambiguous.
3. File set: every old file exists at its new path; unrewritten files and all binary files have the same content.

Then run the mock tests, `check.lua` on touched Lua files and `make_release.py --dry-run` by hand.

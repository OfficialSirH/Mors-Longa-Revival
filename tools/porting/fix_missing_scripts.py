#!/usr/bin/env python3
"""Repoint XML <script file="..."> references to files that do not exist to MOD/lib/missing_script_stub.lua.

Why: three engine crashes (2026-11-06/07) each happened 0-1 s after the log said "Script not found" while a road
segment with such a reference spawned. The scripts never existed (also missing in the original Workshop mod).
A reference counts as missing only if the file is found nowhere the game might look: MOD/ (repo root), next to the
XML, LEVEL/ (repo root or main/), or the engine's data/script/ (e.g. fx.lua, sandbox.lua). Test-only levels are
skipped. Only the file attribute changes; the <script> element and its children stay.
Usage (repo root): python3 tools/porting/fix_missing_scripts.py [--dry-run]
"""
import os, re, sys

STUB = "MOD/lib/missing_script_stub.lua"
ENGINE = r"C:\Program Files (x86)\Steam\steamapps\common\Teardown\data"
SKIP = {"dev/levels/lol.xml", "dev/levels/test.xml", "dev/levels/test_vehicle.xml"}
SKIP_PREFIX = ("world/generation/procgen/test_",)

def exists_anywhere(fn, xml_path):
    cands = []
    if fn.startswith("MOD/"):
        cands.append(fn[4:])
    elif fn.startswith("LEVEL/"):
        cands += [fn[6:], os.path.join("main", fn[6:]), os.path.join(os.path.dirname(xml_path), fn[6:])]
    else:
        cands += [os.path.join(os.path.dirname(xml_path), fn), fn, os.path.join(ENGINE, fn), os.path.join(ENGINE, "script", fn)]
    return any(os.path.isfile(os.path.normpath(c)) for c in cands)

SCRIPT_FILE = re.compile(rb'(<script\b[^>]*?\bfile=")([^"]*)(")')

def main(dry):
    total = 0
    for root, dirs, files in os.walk("."):
        if ".git" in root or "unused" in root.lower():
            continue
        for f in files:
            if not f.endswith(".xml"):
                continue
            p = os.path.join(root, f).replace("\\", "/")[2:]
            if p in SKIP or p.startswith(SKIP_PREFIX):
                continue
            b = open(p, "rb").read()
            changed = []
            def repl(m):
                fn = m.group(2).decode("utf-8", "replace")
                if fn and not exists_anywhere(fn.replace("&amp;", "&"), p):
                    changed.append(fn)
                    return m.group(1) + STUB.encode() + m.group(3)
                return m.group(0)
            nb = SCRIPT_FILE.sub(repl, b)
            if changed:
                total += len(changed)
                print(f"{p}: {len(changed)} -> stub  ({', '.join(sorted(set(changed)))})")
                if not dry:
                    open(p, "wb").write(nb)
    print("total references repointed:", total, "(dry run)" if dry else "")

if __name__ == "__main__":
    main("--dry-run" in sys.argv)

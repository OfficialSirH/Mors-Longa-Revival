"""Add the crash-breadcrumb deletion log (lib/DeleteLog.lua) to every game script that deletes entities
(2026-11-20, user: "Yes, add the log").

Usage (repo root): python tools/porting/add_delete_log.py [--dry-run] [--remove]
Re-runnable: a script that already has the include is left alone. --remove takes the two lines out again.

Which scripts: entry scripts (first non-empty line "#version 2") outside tools/ and dev/ whose own text or any file
they #include (recursively) calls Delete( or another call lib/DeleteLog.lua logs (2026-11-21). Inserted right after "#version 2", or after a lib/GcProbe.lua include if
the script has one (DeleteLog chains onto GcProbe's metatable; GcProbe would not install below DeleteLog):
    DL_LABEL = "<script file name>"  -- crash breadcrumbs (lib/DeleteLog.lua)
    #include "<relative path>/lib/DeleteLog.lua"
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SKIP_DIRS = {".git", "tools", "dev", "docs"}
# (2026-11-21) also the other structure-changing calls lib/DeleteLog.lua logs
DELETE = re.compile(r"(^|[^A-Za-z0-9_.:])(Delete|Spawn|MakeHole|Explosion|SetBodyDynamic|SetBodyActive|SetShapeBody|"
                    r"DetachJointFromShape|CreateShape|ClearShape|ResizeShape|MergeShape|SplitShape|TrimShape|"
                    r"SetShapeLocalTransform|Paint|PaintRGBA|Shoot|SpawnFire|SetShapeDensity|SetShapeCollisionFilter)\s*\(")
INCLUDE = re.compile(r'^\s*#include\s+"([^"]+)"', re.M)
MARK = "-- crash breadcrumbs (lib/DeleteLog.lua)"
LIB = os.path.join(ROOT, "lib", "DeleteLog.lua")


def read(p):
    with open(p, encoding="utf-8", errors="surrogateescape", newline="") as f:
        return f.read()


def deletes(path, seen):
    if path in seen or not os.path.isfile(path):
        return False
    seen.add(path)
    text = read(path)
    code = "\n".join(l.split("--", 1)[0] for l in text.split("\n"))
    if DELETE.search(code):
        return True
    for inc in INCLUDE.findall(text):
        if deletes(os.path.normpath(os.path.join(os.path.dirname(path), inc)), seen):
            return True
    return False


def main():
    dry, remove = "--dry-run" in sys.argv, "--remove" in sys.argv
    changed = []
    for d, ds, fs in os.walk(ROOT):
        rel = os.path.relpath(d, ROOT)
        ds[:] = sorted(x for x in ds if not (rel == "." and x in SKIP_DIRS))
        for f in sorted(fs):
            if not f.endswith(".lua"):
                continue
            p = os.path.join(d, f)
            if os.path.samefile(p, LIB):
                continue
            text = read(p)
            lines = text.split("\n")
            first = next((i for i, l in enumerate(lines) if l.strip()), None)
            if first is None or lines[first].strip() != "#version 2":
                continue
            if remove:
                kept = [l for l in lines if MARK not in l and not (l.lstrip().startswith("#include") and "DeleteLog.lua" in l)]
                if len(kept) != len(lines):
                    changed.append(p)
                    if not dry:
                        open(p, "w", encoding="utf-8", errors="surrogateescape", newline="").write("\n".join(kept))
                continue
            if "DeleteLog.lua" in text or not deletes(p, set()):
                continue
            at = first + 1
            for i, l in enumerate(lines):
                if l.lstrip().startswith("#include") and "GcProbe.lua" in l:
                    at = i + 1
            eol = "\r" if lines[first].endswith("\r") else ""
            inc = os.path.relpath(LIB, os.path.dirname(p)).replace("\\", "/")
            label = os.path.splitext(f)[0]
            lines[at:at] = ['DL_LABEL = "%s"  %s%s' % (label, MARK, eol), '#include "%s"%s' % (inc, eol)]
            changed.append(p)
            if not dry:
                open(p, "w", encoding="utf-8", errors="surrogateescape", newline="").write("\n".join(lines))
    for p in changed:
        print(os.path.relpath(p, ROOT))
    print("%d scripts %s" % (len(changed), "would change" if dry else ("cleaned" if remove else "changed")))


if __name__ == "__main__":
    main()

"""Split each road segment's heavy terrain into small prefabs spawned one per frame (Phase 5 performance, 2026-11-14).

Usage (repo root): python tools/porting/split_heavy.py [--dry-run]

Why: after lighten_terrain.py (coarse hidden floors, tiled hills/dunes) the remaining segment-spawn cost is mostly
the rock models (assets/vox/terrainpieces/rock1.vox: 8 solid rocks of ~1M cells each per reference, 153 references,
up to 25 per segment) in the segments' `terrain` / `Background` groups. Spawn() builds a prefab in one frame, so each
direct child of those groups (a rock, a tiled dune group, ...) becomes its own prefab under
prefabs/spawnables/roadsegments/parts/, wrapped in the SAME chain of parent elements as text (placement and group
defaults kept), and world/generation/GenerateRoad.lua spawns them one per frame after the segment (the spawners wait
until a segment's parts are in: level.segment.loading). Only children made of groups and shapes move (anything with
a script, joint, light, location stays). Same check as split_decor.py: every element of the original appears once
in the cut segment or in a part, with its full ancestor chain.
(2026-11-14) Also moves every reference to MODELS (rock1, hill1, hill1r, hill2) wherever it is (outside scripts /
vehicles / bodies), appended as new parts. The parts are the SOURCE for tools/porting/segment_pieces.py, which
writes the spawned pieces (world/generation/SegmentPieces.lua); run it after this tool. The game spawns the part
files themselves only in the horde level and the credits prefab (RoadSegment1's parts as <instance>s).
Also moves the hidden floors (coarse:* groups, lighten_terrain.py) out of the segments.
Re-runnable: a split segment has no movable children left in those groups.
"""
import os, re, sys, glob
import xml.etree.ElementTree as ET

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from split_decor import parse_spans, line_start, line_end, chains, REPO

SEG_DIR = "prefabs/spawnables/roadsegments"
PART_DIR = SEG_DIR + "/parts"
GROUPS = ("terrain", "background")      # group names (any case) whose children are spread over frames
# (2026-11-14) also any reference to these terrain models, wherever it is (RoadSegmentM4's rocks in its `ground` group
# and in background groups that hold voxagons, RoadSegmentS1 / B1's hills): tools/porting/vox_pieces.py cuts them
MODELS = ("rock1.vox", "hill1.vox", "hill1r.vox", "hill2.vox")


def pure(n):
    return n.name in ("group", "vox", "voxbox") and all(pure(c) for c in n.children)


OWNERS = ("script", "vehicle", "body", "wheel")
STATIC = ("group", "vox", "voxbox", "voxagon", "vertex", "compound", "light")   # a light on a static shape goes with it


def static(n):
    """(2026-11-15) only static geometry below: no marker, trigger, light, joint, water, script, body, vehicle"""
    return n.name in STATIC and all(static(c) for c in n.children)


def is_model(n):
    """a terrain model reference, or (2026-11-14) a hidden floor rebuilt at 10 cm by lighten_terrain.py --replate
    (group coarse:*: 1.7-7.9M cells per segment, spawned as pieces after the segment)"""
    if n.name == "group" and (n.get("name") or "").startswith("coarse:") and pure(n):
        return True
    return n.name == "vox" and os.path.basename(n.get("file") or "") in MODELS and not n.get("object") and pure(n)


def split_text(text, seg):
    tree = parse_spans(text)
    targets = []

    def walk(n):
        for c in n.children:
            if c.name in ("script", "vehicle", "body", "wheel"):
                continue   # owned by a script / vehicle / body (RoadSegmentH's shop script holds a Background group)
            if c.name == "group" and (c.get("name") or "").lower() in GROUPS:
                movable = [ch for ch in c.children if pure(ch)]
                if movable:
                    targets.append((c, movable))
                for ch in c.children:
                    if ch not in movable:
                        walk_models(ch)
                continue
            if is_model(c):
                targets.append((c.parent, [c]))
                continue
            walk(c)

    def walk_models(n):
        if is_model(n):
            targets.append((n.parent, [n]))
            return
        if n.name in ("script", "vehicle", "body", "wheel"):
            return
        for c in n.children:
            walk_models(c)
    walk(tree)

    # (2026-11-15, gradual generation) then ALL remaining static geometry (road, sand, walls, signs, ...): the
    # highest static subtrees outside scripts / vehicles / bodies, one part per parent. The segment file keeps
    # markers, triggers, lights, scripts, vehicles and dynamic bodies, spawned after its pieces (GenerateRoad).
    moved = set(id(c) for _, cs in targets for c in cs)
    groups = {}

    def walk_static(n):
        for c in n.children:
            if c.name in OWNERS or id(c) in moved:
                continue
            if static(c):
                groups.setdefault(id(n), (n, []))[1].append(c)
                continue
            walk_static(c)
    walk_static(tree)
    for n, cs in groups.values():
        if n.name == "#doc":
            continue
        targets.append((n, cs, True))
    if not targets:
        return None
    parts, cuts = [], []
    for t in targets:
        g, movable, together = t[0], t[1], len(t) > 2
        chain = []
        p = g
        while p is not None and p.name != "#doc":
            chain.insert(0, p)
            p = p.parent
        head = "".join(text[line_start(text, a.start):a.open_end] + "\n" for a in chain)
        tail = "".join("</%s>\n" % a.name for a in chain[::-1])
        if together:   # static siblings: one part (segment_pieces.py cuts it into pieces)
            parts.append(head + "".join(text[line_start(text, ch.start):line_end(text, ch.end)] for ch in movable) + tail)
            cuts += movable
            continue
        for ch in movable:
            body = text[line_start(text, ch.start):line_end(text, ch.end)]
            parts.append(head + body + tail)
            cuts.append(ch)
    out, pos = [], 0
    for ch in sorted(cuts, key=lambda n: n.start):
        a, b = line_start(text, ch.start), line_end(text, ch.end)
        out.append(text[pos:a])
        pos = b
    out.append(text[pos:])
    return "".join(out), parts


def check(original, new_seg, parts):
    """Every element of the original (with its full ancestor chain) appears in the cut segment or a part; the only
    additions are repeated wrappers: chains that exist in the original and are ancestors of other elements."""
    a = chains(original)
    b = chains(new_seg)
    for t in parts:
        b += chains(t)
    missing = a - b
    extra = b - a
    ancestors = set()
    for k in a:
        for i in range(1, len(k)):
            ancestors.add(k[:i])
    bad = [k for k in extra if k not in a or k not in ancestors]
    if missing or bad:
        raise SystemExit("check failed: %d missing, %d unexpected" % (sum(missing.values()), len(bad)))


def main():
    dry = "--dry-run" in sys.argv
    os.chdir(REPO)
    table = {}
    total = 0
    for path in sorted(glob.glob(SEG_DIR + "/RoadSegment*.xml")):
        seg = os.path.splitext(os.path.basename(path))[0]
        text = open(path, encoding="utf-8").read()
        res = split_text(text, seg)
        existing = sorted(p.replace("\\", "/") for p in glob.glob(PART_DIR + "/%s_*.xml" % seg))
        if res is None:
            if existing:
                table[seg] = ["MOD/" + p for p in existing]
                print("%-22s already split (%d parts)" % (seg, len(existing)))
            continue
        new_seg, parts = res
        check(text, new_seg, parts)
        first = max([int(p[-7:-4]) for p in existing] + [0]) + 1   # appended after earlier parts
        names = ["%s/%s_%03d.xml" % (PART_DIR, seg, first + i) for i in range(len(parts))]
        table[seg] = ["MOD/" + p for p in existing] + ["MOD/" + n for n in names]
        total += len(parts)
        rocks = sum(p.count("rock1.vox") for p in parts)
        print("%-22s %3d parts (%d rock references)" % (seg, len(parts), rocks))
        if not dry:
            # the segment first: if it cannot be written (Teardown holds the files of a loaded level: Errno 22),
            # stop before any part exists, or a re-run would move the same elements into parts again
            try:
                with open(path, "w", encoding="utf-8", newline="\n") as f:
                    f.write(new_seg)
            except OSError as e:
                raise SystemExit("cannot write %s (%s): is Teardown running a level? Nothing written for it." % (path, e))
            os.makedirs(PART_DIR, exist_ok=True)
            for n, t in zip(names, parts):
                with open(n, "w", encoding="utf-8", newline="\n") as f:
                    f.write(t)
    # (2026-11-14) the parts are no longer spawned as files: tools/porting/segment_pieces.py reads them and writes
    # world/generation/SegmentPieces.lua (run it after this tool)
    print("%d segments, %d new parts%s; now run tools/porting/segment_pieces.py" % (len(table), total, " (dry run)" if dry else ""))


if __name__ == "__main__":
    main()

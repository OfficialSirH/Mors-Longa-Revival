"""Stream a road segment's own file over several frames (2026-11-17, performance).

Usage (repo root): python tools/porting/chunk_segments.py [--dry-run]     (re-runnable: reads the segment files only)

Why (measured with the MCP bridge, docs/PERFORMANCE.md): after segment_pieces.py the segment file still spawned in
one frame and cost 0.2-0.5 s on some segments: RoadSegmentH keeps ~4.6M voxbox cells of ground under its SafeZone
script (segment_pieces.py moves nothing under a script), RoadSegmentM6's town is 2354 shapes, M7's toll+base 752,
M3 / M5 carry a train.

What it writes: prefabs/spawnables/roadsegments/chunks/<segment>_<n>.xml and world/generation/SegmentFileChunks.lua,
SEGMENT_FILE_CHUNKS[segment] = { path, ... }. (The first version spawned XML strings with several root groups: only
the first root spawns, so a PuzzlePiece trigger was lost and the road ended; see build().) GenerateRoad.lua
spawns them one per frame in place of the file; the last one is the "file"
(its after-spawn work gets the entities of all chunks). The segment files themselves are not changed (the horde
level, the credits prefab and the debug performance tests spawn them whole).

How a file is cut (every piece keeps its ancestor chain with all attributes, so placement and group defaults stay):
1. Static shapes are lifted out first: a vox / voxbox / voxagon with no child elements and no tags of its own, whose
   ancestors below the segment's group are only <group> / <script> elements without tags props other than "veg".
   A <script> ancestor becomes a <group> with the script's pos / rot in the lifted copy (the script itself stays in
   the rest of the file). These go into chunks of at most STATIC_CELLS box cells / STATIC_SHAPES shapes, spawned
   first. Nothing is lifted out of a group / script that holds a joint or rope: a joint only attaches to shapes of
   its own Spawn call (2026-11-20: the gas station's tank cover came loose; the first version assumed otherwise).
2. The rest is cut into whole subtrees: a <group> heavier than REST_WEIGHT is opened into its children unless it
   holds a joint or a rope (those attach to whatever touches them at spawn, so they stay with their neighbours);
   bodies, vehicles, scripts, instances and everything else stay whole. Document order is kept; the last chunk is
   the "file". Markers need not come last: the spawners wait while level.segment.loading is set (until the whole
   queue, decor included, has spawned).
Check: for every leaf-level element (lifted shape or whole subtree) its chain (ancestor tags + attributes, script ->
group for lifted shapes) is the same multiset before and after.
"""
import os
import sys
import xml.etree.ElementTree as ET
from collections import Counter

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SEG_DIR = os.path.join(ROOT, "prefabs", "spawnables", "roadsegments")
OUT_LUA = os.path.join(ROOT, "world", "generation", "SegmentFileChunks.lua")
OUT_DIR = os.path.join(SEG_DIR, "chunks")

STATIC_CELLS = 1_000_000
STATIC_SHAPES = 150
REST_WEIGHT = 250
SHAPES = ("vox", "voxbox", "voxagon")
OPENABLE = ("group",)


def voxbox_cells(el):
    s = [float(x) for x in el.get("size", "0 0 0").split()]
    return int(s[0] * s[1] * s[2]) if len(s) == 3 else 0


def voxagon_cells(el):
    pts = [[float(x) for x in v.get("pos", "0 0").split()] for v in el.iter("vertex")]
    if not pts:
        return 0
    xs = [p[0] for p in pts]
    zs = [p[1] for p in pts if len(p) > 1]
    h = float(el.get("height", "1") or 1)
    return int((max(xs) - min(xs) + 1) * (max(zs) - min(zs) + 1) * max(1, h) * 100)


def cells(el):
    if el.tag == "voxbox":
        return voxbox_cells(el)
    if el.tag == "voxagon":
        return voxagon_cells(el)
    return 0


def tags_ok(el):
    """No tags on the element and no tags props other than veg."""
    if el.get("tags"):
        return False
    for k, v in el.attrib.items():
        if k.startswith("prop") and v.startswith("tags=") and v != "tags=veg":
            return False
    return True


def weight(el):
    w = 0
    for e in el.iter():
        if e.tag in SHAPES:
            w += 1 + cells(e) // 20000
        elif e.tag == "instance":
            w += 5
    return w


def has(el, tags):
    return any(e.tag in tags for e in el.iter())


def as_group(el):
    """A lifted shape's script ancestor becomes a plain group with its transform."""
    if el.tag == "script":
        return "group", {k: v for k, v in el.attrib.items() if k in ("pos", "rot")}
    return el.tag, dict(el.attrib)


def chain_key(chain, leaf, lifted):
    parts = []
    for a in chain:
        t, at = as_group(a) if lifted else (a.tag, dict(a.attrib))
        parts.append((t, tuple(sorted(at.items()))))
    return (tuple(parts), ET.tostring(leaf, encoding="unicode"))


def build(root_attrib, items):
    """A prefab holding each (chain, leaf, lifted), the chains merged into ONE tree: the engine spawns only the first
    child of <prefab> (measured 2026-11-17: a chunk with three root groups spawned the first one only, so a segment's
    PuzzlePiece trigger in the second was lost and the road ended). An ancestor is shared by every leaf below it
    (a script turned group for lifted shapes is a separate copy)."""
    prefab = ET.Element("prefab", dict(root_attrib))
    made = {}
    for chain, leaf, lifted in items:
        parent = prefab
        for a in chain:
            key = (id(a), lifted and a.tag == "script")
            if key not in made:
                t, at = as_group(a) if lifted else (a.tag, dict(a.attrib))
                made[key] = ET.SubElement(parent, t, at)
            parent = made[key]
        parent.append(leaf)
    assert len(list(prefab)) == 1, "one root group"
    return prefab


def cut(path):
    root = ET.parse(path).getroot()
    tops = list(root)
    before = Counter()
    # 1. lift static shapes
    lifted = []

    # (2026-11-20 fix) a joint / rope attaches only to shapes spawned in the SAME Spawn call: the gas station's tank
    # cover (RoadSegmentH, hinge on a static shape in its group) came loose when that static shape was lifted into an
    # earlier chunk. A group / script holding a joint or rope anywhere below keeps its static shapes (no lifting in
    # it); step 2 keeps such groups whole as before.
    def joint_scope(el):
        """A joint / rope in el itself or inside its non-group children (bodies, shapes, ...), not in a nested group /
        script: el is the group that holds the jointed object and the shapes it is meant to attach to."""
        stack = list(el)
        while stack:
            e = stack.pop()
            if e.tag in ("joint", "rope"):
                return True
            if e.tag not in ("group", "script"):
                stack.extend(list(e))
        return False

    def joints_only(g):
        """a group holding nothing but joints / ropes (RoadSegmentF's pipes: "lower joints" next to the pipe groups)"""
        kids = list(g)
        return g.tag == "group" and kids and all(
            k.tag in ("joint", "rope") or "joint_anchor" in (k.get("tags") or "") for k in kids)   # anchors: joint_anchors.py

    def walk(el, chain, liftable):
        liftable_here = liftable and not joint_scope(el) and not any(joints_only(c) for c in el)
        for c in list(el):
            if c.tag in SHAPES and liftable_here and len(list(c)) == 0 and tags_ok(c):
                lifted.append((chain + [el], c))
                el.remove(c)
            elif c.tag in ("group", "script"):
                # below a group holding a joint nothing is lifted either (a door's hinge attaches to the frame in
                # its "doorframe" subgroup)
                walk(c, chain + [el], liftable_here and tags_ok(c))

    for top in tops:
        walk(top, [], True)
    # 2. cut the rest into whole subtrees
    rest = []

    def split(el, chain):
        for c in list(el):
            if c.tag in OPENABLE and weight(c) > REST_WEIGHT and not has(c, ("joint", "rope")) and len(list(c)) > 1:
                split(c, chain + [el])
            else:
                rest.append((chain + [el], c))

    for top in tops:
        split(top, [])
    # the check: the original file's leaf chains, recomputed from a fresh parse with the same cut
    fresh = ET.parse(path).getroot()
    for chain, leaf in lifted:
        before[chain_key(chain, leaf, True)] += 1
    for chain, leaf in rest:
        before[chain_key(chain, leaf, False)] += 1
    # chunks
    static_chunks, cur, n, cc = [], [], 0, 0
    for chain, leaf in lifted:
        c = cells(leaf)
        if cur and (n + 1 > STATIC_SHAPES or cc + c > STATIC_CELLS):
            static_chunks.append(cur)
            cur, n, cc = [], 0, 0
        cur.append((chain, leaf, True))
        n += 1
        cc += c
    if cur:
        static_chunks.append(cur)
    rest_chunks, cur, w = [], [], 0
    for chain, leaf in rest:
        lw = weight(leaf)
        if cur and w + lw > REST_WEIGHT:
            rest_chunks.append(cur)
            cur, w = [], 0
        cur.append((chain, leaf, False))
        w += lw
    if cur:
        rest_chunks.append(cur)
    chunks = static_chunks + rest_chunks
    after = Counter()
    for ch in chunks:
        for chain, leaf, lf in ch:
            after[chain_key(chain, leaf, lf)] += 1
    assert before == after, path
    # every element of the original is in exactly one leaf (count elements)
    total = sum(1 for _ in fresh.iter()) - 1 - len(list(fresh))  # minus prefab and the top groups
    covered = sum(sum(1 for _ in leaf.iter()) for ch in chunks for _, leaf, _ in ch)
    opened = total - covered
    return root.attrib, chunks, len(static_chunks), opened


def main():
    dry = "--dry-run" in sys.argv
    out = {}
    for f in sorted(os.listdir(SEG_DIR)):
        if not (f.startswith("RoadSegment") and f.endswith(".xml")):
            continue
        attrib, chunks, nstatic, opened = cut(os.path.join(SEG_DIR, f))
        xmls = []
        seg = f[:-4]
        paths = []
        for i, ch in enumerate(chunks, 1):
            p = build(attrib, ch)
            xmls.append(ET.tostring(p, encoding="unicode"))
            name = "%s_%d.xml" % (seg, i)
            paths.append("MOD/prefabs/spawnables/roadsegments/chunks/" + name)
            if not dry:
                os.makedirs(OUT_DIR, exist_ok=True)
                with open(os.path.join(OUT_DIR, name), "w", encoding="utf-8", newline="\n") as o:
                    o.write(xmls[-1] + "\n")
        out[seg] = paths
        lifted = sum(len(c) for c in chunks[:nstatic])
        print("%s: %d chunks (%d static, %d shapes lifted), %d group wrappers opened, largest %d chars" % (
            seg, len(xmls), nstatic, lifted, opened, max(len(x) for x in xmls)))
    if dry:
        return
    with open(OUT_LUA, "w", encoding="utf-8", newline="\n") as o:
        o.write("-- GENERATED by tools/porting/chunk_segments.py (2026-11-17): each road segment's own file as chunks,\n")
        o.write("-- spawned by GenerateRoad.lua one per frame after its static pieces; the last chunk is the \"file\".\n")
        o.write("SEGMENT_FILE_CHUNKS = {}\n")
        for seg in sorted(out):
            o.write('SEGMENT_FILE_CHUNKS["%s"] = { %s }\n' % (seg, ", ".join('"%s"' % x for x in out[seg])))


if __name__ == "__main__":
    main()

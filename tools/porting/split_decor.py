"""Split each road segment's roadside decor into separate prefabs (Phase 5 performance, 2026-11-14).

Usage (repo root): python tools/porting/split_decor.py [--dry-run]

Why: in most road segments 73-98% of all shapes are the `decor` group (about 42 bushes, each built from 60-90 small
rotated pieces: ~3300 shapes), and `Spawn()` builds a whole prefab in one frame: the segment spawn froze the game
for seconds. The decor now lives in its own prefabs, which world/generation/GenerateRoad.lua spawns on the ticks
after the segment.

What it does, per prefabs/spawnables/roadsegments/RoadSegment*.xml that still has a `<group name="decor">`:
  * each direct child of the decor group (left / right) becomes prefabs/spawnables/roadsegments/decor/<Segment>_<child>.xml,
    wrapped in the SAME chain of parent elements (root, the instance group, the decor group with its prop0..propN
    defaults: collide=false, tags=veg, texture), copied as text, so every shape keeps its placement and defaults
    when spawned at the segment's transform;
  * the decor group is cut out of the segment file (text-level: all other bytes unchanged);
  * world/generation/DecorParts.lua (generated) lists the parts per segment for GenerateRoad.
Check (before anything is written; it refuses otherwise): every element of the original file, identified by its
full chain of ancestor tags and attributes, appears exactly once in the cut segment or in one of the parts, and
nothing else does. Re-running on split segments only regenerates DecorParts.lua.
"""
import os, re, sys, glob
import xml.etree.ElementTree as ET
from collections import Counter

REPO = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
SEG_DIR = "prefabs/spawnables/roadsegments"
DECOR_DIR = SEG_DIR + "/decor"
OUT_LUA = "world/generation/DecorParts.lua"
TAG_RE = re.compile(r"<!--.*?-->|<\?.*?\?>|<(/?)([A-Za-z_][\w:.-]*)((?:\"[^\"]*\"|'[^']*'|[^>\"'])*?)(/?)>", re.S)


class Node:
    def __init__(self, name, attrs, start, parent):
        self.name, self.attrs, self.start, self.parent = name, attrs, start, parent
        self.open_end = None   # end of the start tag
        self.end = None        # end of the element (after the closing tag)
        self.children = []

    def get(self, key):
        m = re.search(r'\b%s="([^"]*)"' % re.escape(key), self.attrs)
        return m.group(1) if m else None


def parse_spans(text):
    """Element tree with text spans (start of `<`, end of start tag, end of closing tag)."""
    root = Node("#doc", "", 0, None)
    stack = [root]
    for m in TAG_RE.finditer(text):
        if m.group(2) is None:      # comment / declaration
            continue
        closing, name, attrs, selfclose = m.group(1), m.group(2), m.group(3), m.group(4)
        if closing:
            node = stack.pop()
            assert node.name == name, "mismatched </%s> at %d (open <%s>)" % (name, m.start(), node.name)
            node.end = m.end()
            continue
        node = Node(name, attrs, m.start(), stack[-1])
        node.open_end = m.end()
        stack[-1].children.append(node)
        if selfclose:
            node.end = m.end()
        else:
            stack.append(node)
    assert len(stack) == 1, "unclosed <%s>" % stack[-1].name
    return root


def find_decor(node):
    for c in node.children:
        if c.name == "group" and c.get("name") == "decor":
            return c
        found = find_decor(c)
        if found:
            return found
    return None


def line_start(text, i):
    j = text.rfind("\n", 0, i)
    return j + 1


def line_end(text, i):
    j = text.find("\n", i)
    return len(text) if j < 0 else j + 1


def chains(xml_text):
    """Multiset of every element's identity: the (tag, sorted attributes) of it and all its ancestors."""
    root = ET.fromstring(xml_text)
    out = Counter()

    def walk(e, prefix):
        me = prefix + (ident(e),)
        out[me] += 1
        for c in e:
            walk(c, me)
    walk(root, ())
    return out


def ident(e):
    """An element's identity for the placement check. A <script> counts as a group with its pos / rot: parts carry
    script ancestors as plain groups (wrapper_open), which places their children the same way."""
    if e.tag == "script":
        return ("group", tuple(sorted((k, v) for k, v in e.attrib.items() if k in ("pos", "rot"))))
    return (e.tag, tuple(sorted(e.attrib.items())))


def wrapper_open(text, a):
    """An ancestor's opening tag for a part. A <script> becomes a <group> with only its pos / rot (2026-11-17):
    RoadSegmentH's decor sat under its SafeZone script, and each part spawned another SafeZone script, which raised
    level.safezoneLoadCount and stopped the shop's parking spot (game/ParkingSpot.lua STOP_newSafezone)."""
    line = text[line_start(text, a.start):a.open_end]
    if a.name != "script":
        return line
    indent = line[:len(line) - len(line.lstrip())]
    attrs = "".join(' %s="%s"' % (k, a.get(k)) for k in ("pos", "rot") if a.get(k) is not None)
    return "%s<group%s>" % (indent, attrs)


def split_text(text, seg_name):
    """(new segment text, {part name: part text}) or None if the segment has no decor group."""
    tree = parse_spans(text)
    decor = find_decor(tree)
    if decor is None:
        return None
    ancestors = []
    p = decor.parent
    while p is not None and p.name != "#doc":
        ancestors.insert(0, p)
        p = p.parent
    # only children made of groups and shapes move (bushes, rocks); anything with a script, joint, light, location
    # (RoadSegmentM8's animated oil derricks) stays in the segment, which registers its scripts
    def pure(n):
        return n.name in ("group", "vox", "voxbox") and all(pure(c) for c in n.children)
    movable = [c for c in decor.children if pure(c)]
    if not movable:
        return None
    parts = {}
    for i, child in enumerate(movable):
        key = re.sub(r"[^A-Za-z0-9_-]", "_", child.get("name") or str(i + 1))
        while key in parts:
            key += "_"
        head = "".join(wrapper_open(text, a) + "\n" for a in ancestors)
        head += text[line_start(text, decor.start):decor.open_end] + "\n"
        body = text[line_start(text, child.start):line_end(text, child.end)]
        tail = "".join("</%s>\n" % ("group" if a.name == "script" else a.name) for a in [decor] + ancestors[::-1])
        parts[key] = head + body + tail
    # cut the moved children out of the segment (the decor group stays: the derricks, or empty)
    new_text, pos = [], 0
    for child in movable:
        a, b = line_start(text, child.start), line_end(text, child.end)
        new_text.append(text[pos:a])
        pos = b
    new_text.append(text[pos:])
    return "".join(new_text), parts


def check(original, new_seg, parts):
    a = chains(original)
    b = chains(new_seg)
    for t in parts.values():
        b += chains(t)
    # the decor group itself and its ancestors are repeated once per part (wrappers): count them separately
    extra = b - a
    missing = a - b
    tree = ET.fromstring(original)
    decor_paths = set()

    def walk(e, prefix):
        me = prefix + (ident(e),)
        if e.tag == "group" and e.attrib.get("name") == "decor":
            p = ()
            for step in me:
                p = p + (step,)
                decor_paths.add(p)
            return True
        for c in e:
            if walk(c, me):
                return True
        return False
    walk(tree, ())
    bad_extra = [k for k in extra if k not in decor_paths]
    if missing or bad_extra:
        raise SystemExit("check failed: %d elements missing, %d unexpected" % (sum(missing.values()), len(bad_extra)))


def main():
    dry = "--dry-run" in sys.argv
    os.chdir(REPO)
    table = {}
    total_parts = 0
    for path in sorted(glob.glob(SEG_DIR + "/RoadSegment*.xml")):
        seg = os.path.splitext(os.path.basename(path))[0]
        with open(path, "rb") as f:
            raw = f.read()
        text = raw.decode("utf-8")
        res = split_text(text, seg)
        if res is None:
            existing = sorted(glob.glob(DECOR_DIR + "/%s_*.xml" % seg))
            if existing:
                table[seg] = ["MOD/" + p.replace("\\", "/") for p in existing]
                print("%-22s already split (%d parts)" % (seg, len(existing)))
            else:
                print("%-22s no decor group" % seg)
            continue
        new_seg, parts = res
        check(text, new_seg, parts)
        before = sum(1 for _ in ET.fromstring(text).iter())
        shapes = lambda t: sum(1 for e in ET.fromstring(t).iter() if e.tag in ("vox", "voxbox"))
        print("%-22s shapes %5d -> segment %4d + parts %s" % (seg, shapes(text), shapes(new_seg),
              " + ".join("%s %d" % (k, shapes(v)) for k, v in parts.items())))
        table[seg] = ["MOD/%s/%s_%s.xml" % (DECOR_DIR, seg, k) for k in parts]
        total_parts += len(parts)
        if not dry:
            os.makedirs(DECOR_DIR, exist_ok=True)
            for k, t in parts.items():
                with open("%s/%s_%s.xml" % (DECOR_DIR, seg, k), "wb") as f:
                    f.write(t.encode("utf-8"))
            with open(path, "wb") as f:
                f.write(new_seg.encode("utf-8"))
    lines = ["-- GENERATED by tools/porting/split_decor.py: roadside decor prefabs per road segment, spawned by",
             "-- GenerateRoad.lua on the ticks after the segment (spreads the segment's spawn cost over frames).",
             "DECOR_PARTS = {"]
    for seg in sorted(table):
        lines.append('\t["%s"] = { %s },' % (seg, ", ".join('"%s"' % p for p in table[seg])))
    lines.append("}")
    if not dry:
        with open(OUT_LUA, "w", encoding="utf-8", newline="\n") as f:
            f.write("\n".join(lines) + "\n")
    print("%d segments with decor, %d new parts%s" % (len(table), total_parts, " (dry run)" if dry else ""))


if __name__ == "__main__":
    main()

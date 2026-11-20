"""Joint anchors for road segments (2026-11-20, fix of the 2026-11-15 performance splits).

Usage (repo root):
  python tools/porting/joint_anchors.py list <Segment>          joints in spawn order: index, type, owner, position
  python tools/porting/joint_anchors.py apply <anchors.json> [--dry-run]

Why: a joint / rope only attaches to shapes of its OWN Spawn call (measured in game 2026-11-20 with the debug hook
"jointcheck:", ui/ConfigMenu.lua). split_heavy.py / split_decor.py (2026-11-14/15) moved static terrain, rocks,
background and hidden floors out of the segment files into separately spawned pieces, and chunk_segments.py
(2026-11-17) lifted static shapes into earlier chunks; joints whose static partner moved spawn loose (the gas
station's tank cover in RoadSegmentH could be carried away; doors, fences, cables in B1, F, L1, L2, M5, M6, M7).
Fix: a 1-voxel static anchor (tags "invisible unbreakable", no children) at the joint position, as a sibling in the
joint's nearest group / script, so it spawns with the joint and gives it a static partner as the moved ground did.
chunk_segments.py keeps tagged shapes and groups holding joints together, so the anchor stays with its joint.

Positions: every element's pos / rot is relative to its parent; rot "x y z" = QuatEuler(x, y, z) ("NASA standard
aeroplane": yaw Y, then pitch Z, then roll X; checked against the game's QuatEuler in apply's self-test values).
Joint order: document order, <instance file="MOD/..."> files expanded in place (their joints spawn there too).
anchors.json: { "<Segment>": { "joints": [index, ...], "rope_ends": { "<index>": [0 or 1 or both] } } }
(indices 1-based as the in-game check prints them; rope ends: 0 = first <location>, 1 = last).
"""
import json
import re
import math
import os
import sys
import xml.etree.ElementTree as ET

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SEG_DIR = os.path.join(ROOT, "prefabs", "spawnables", "roadsegments")
ANCHOR_TAGS = "invisible unbreakable joint_anchor"


# ---------------------------------------------------------------- math (quaternions as x, y, z, w like Teardown)
def q_axis(axis, deg):
    a = math.radians(deg) / 2
    s = math.sin(a)
    return [axis[0] * s, axis[1] * s, axis[2] * s, math.cos(a)]


def q_mul(a, b):
    ax, ay, az, aw = a
    bx, by, bz, bw = b
    return [aw * bx + ax * bw + ay * bz - az * by,
            aw * by - ax * bz + ay * bw + az * bx,
            aw * bz + ax * by - ay * bx + az * bw,
            aw * bw - ax * bx - ay * by - az * bz]


def q_euler(x, y, z):
    """Teardown QuatEuler: rotation about Y, then Z, then X (applied to the vector in X, Z, Y order)."""
    return q_mul(q_mul(q_axis((0, 1, 0), y), q_axis((0, 0, 1), z)), q_axis((1, 0, 0), x))


def q_rot(q, v):
    x, y, z, w = q
    # v' = q v q*
    ix = w * v[0] + y * v[2] - z * v[1]
    iy = w * v[1] + z * v[0] - x * v[2]
    iz = w * v[2] + x * v[1] - y * v[0]
    iw = -x * v[0] - y * v[1] - z * v[2]
    return [ix * w + iw * -x + iy * -z - iz * -y,
            iy * w + iw * -y + iz * -x - ix * -z,
            iz * w + iw * -z + ix * -y - iy * -x]


def local_tf(el):
    p = [float(v) for v in (el.get("pos") or "0 0 0").split()]
    while len(p) < 3:
        p.append(0.0)
    r = [float(v) for v in (el.get("rot") or "0 0 0").split()]
    while len(r) < 3:
        r.append(0.0)
    return p, q_euler(r[0], r[1], r[2])


def compose(parent, child):
    pp, pq = parent
    cp, cq = child
    rp = q_rot(pq, cp)
    return [pp[0] + rp[0], pp[1] + rp[1], pp[2] + rp[2]], q_mul(pq, cq)


IDENT = ([0.0, 0.0, 0.0], [0.0, 0.0, 0.0, 1.0])


# ---------------------------------------------------------------- joints in spawn order
def mod_path(p):
    return os.path.join(ROOT, p[len("MOD/"):]) if p.startswith("MOD/") else None


def joints_in(el, chain, out, depth=0):
    """Document order; instances expanded (their joints are counted but never anchored)."""
    for c in list(el):
        if c.tag in ("joint", "rope"):
            out.append((c, chain + [el], False))
        if c.tag == "instance":
            f = mod_path(c.get("file") or "")
            if f and os.path.isfile(f) and depth < 6:
                sub = ET.parse(f).getroot()
                tmp = []
                joints_in(sub, [], tmp, depth + 1)
                out.extend((j, None, True) for j, _, _ in tmp)
            continue
        joints_in(c, chain + [el], out, depth)


def segment_joints(seg):
    path = os.path.join(SEG_DIR, seg + ".xml")
    tree = ET.parse(path)
    out = []
    joints_in(tree.getroot(), [], out)
    return tree, path, out


def nearest_group(chain):
    for i in range(len(chain) - 1, -1, -1):
        if chain[i].tag in ("group", "script"):
            return i
    return None


def pos_in(chain, gi, el):
    """el's transform in the frame of chain[gi] (the group the anchor goes into)."""
    tf = IDENT
    for a in chain[gi + 1:]:
        tf = compose(tf, local_tf(a))
    return compose(tf, local_tf(el))


def jtype(j):
    return "rope" if j.tag == "rope" else (j.get("type") or "ball")


def cmd_list(seg):
    _, _, js = segment_joints(seg)
    for i, (j, chain, inst) in enumerate(js, 1):
        owner = "instance" if inst else "/".join("%s%s" % (a.tag, ("[" + a.get("name") + "]") if a.get("name") else "")
                                                for a in chain[1:])
        print("%3d %-9s %s" % (i, jtype(j), owner))


def anchor_el(p):
    # a 1-voxel box centred on p (voxbox pos is its corner)
    return ET.Element("voxbox", {"tags": ANCHOR_TAGS, "pos": "%.4f %.4f %.4f" % (p[0] - 0.05, p[1] - 0.05, p[2] - 0.05),
                                 "size": "1 1 1", "color": "0.3 0.3 0.3"})


GROUP_TAG = re.compile(r"<(group|script)[\s>/]")   # also <group/>: counted, never a target


def cmd_apply(spec_path, dry):
    """The anchors are inserted as text lines right after the target group's opening tag (the file is not
    re-serialized: its formatting stays). The target group is found as the n-th <group / <script start tag, the same
    document order ElementTree iterates in."""
    spec = json.load(open(spec_path, encoding="utf-8"))
    for seg, s in spec.items():
        tree, path, js = segment_joints(seg)
        root = tree.getroot()
        text = open(path, encoding="utf-8").read()
        if "joint_anchor" in text:
            print("%s: already has joint anchors, skipped" % seg)
            continue
        order = {id(e): n for n, e in enumerate(e for e in root.iter() if e.tag in ("group", "script"))}
        inserts = {}   # group order index -> [anchor xml]
        ends = {int(k): v for k, v in s.get("rope_ends", {}).items()}
        for idx in s.get("joints", []) + list(ends):
            j, chain, inst = js[idx - 1]
            assert not inst, "%s #%d is inside an instance" % (seg, idx)
            gi = nearest_group(chain)
            assert gi is not None, "%s #%d has no group ancestor" % (seg, idx)
            if j.tag == "rope":
                # a rope's locations are its children: frame chain[gi] -> ... -> rope -> location
                locs = [c for c in j if c.tag == "location"]
                pts = [pos_in(chain + [j], gi, locs[e])[0] for e in ends.get(idx, [])]
            else:
                pts = [pos_in(chain, gi, j)[0]]
            for p in pts:
                inserts.setdefault(order[id(chain[gi])], []).append(ET.tostring(anchor_el(p), encoding="unicode"))
        starts = [m for m in GROUP_TAG.finditer(text)]
        assert len(starts) == len(order), "%s: %d group tags in the text, %d elements" % (seg, len(starts), len(order))
        out, last = [], 0
        for n in sorted(inserts):
            gt = text.index(">", starts[n].start()) + 1        # end of the group's opening tag
            line_end = text.find("\n", gt)
            line_end = len(text) if line_end < 0 else line_end + 1
            indent = re.match(r"[ \t]*", text[line_end:]).group(0)
            out.append(text[last:line_end])
            out.append("".join(indent + a + "\n" for a in inserts[n]))
            last = line_end
        out.append(text[last:])
        new = "".join(out)
        ET.fromstring(new)   # still well-formed
        print("%s: %d anchors in %d groups" % (seg, sum(len(v) for v in inserts.values()), len(inserts)))
        if not dry:
            open(path, "w", encoding="utf-8", newline="\n").write(new)


if __name__ == "__main__":
    if len(sys.argv) >= 3 and sys.argv[1] == "list":
        cmd_list(sys.argv[2])
    elif len(sys.argv) >= 3 and sys.argv[1] == "apply":
        cmd_apply(sys.argv[2], "--dry-run" in sys.argv)
    elif len(sys.argv) >= 2 and sys.argv[1] == "euler":
        print(["%.6f" % v for v in q_euler(10, 20, 30)], ["%.6f" % v for v in q_euler(70, -40, 115)])
    else:
        print(__doc__)

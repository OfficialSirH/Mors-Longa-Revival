"""Put split-out parts back into a road segment where its joints need them (2026-11-20).

Usage (repo root): python tools/porting/merge_joint_parts.py <spec.json> [--dry-run]
  spec.json: { "<Segment>": [joint index, ...] }   (1-based spawn order, as the in-game "jointcheck:" prints them)

Why: split_heavy.py (2026-11-14/15) moved children of a segment's groups into prefabs/spawnables/roadsegments/parts/
when the child itself held no joint, but a joint that is a SIBLING of the child (a door's hinge next to the door
and its frame, a bridge's joint group next to its planks) stayed in the segment file; segment_pieces.py then cut the
parts into separately spawned pieces. A joint only attaches to shapes of its own Spawn call, so those joints spawn
loose (measured in game, ui/ConfigMenu.lua "jointcheck:"). Static partners are given back by joint_anchors.py; this
tool is for moving partners (doors, planks, pipes): for each listed joint, the nearest ancestor group out of which
parts were moved gets their content back (as text, the rest of the file unchanged), and the merged part files are
listed in tools/porting/parts_merged.txt, which segment_pieces.py skips (the files stay; nothing is deleted).
Re-run segment_pieces.py and chunk_segments.py afterwards.
"""
import glob
import os
import re
import sys
import json
import xml.etree.ElementTree as ET

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import joint_anchors as J

ROOT = J.ROOT
SEG_DIR = J.SEG_DIR
PART_DIR = os.path.join(SEG_DIR, "parts")
MERGED = os.path.join(ROOT, "tools", "porting", "parts_merged.txt")


def key(e):
    return (e.tag, tuple(sorted(e.attrib.items())))


def part_chain(pf):
    """The part's chain of group / script elements (keys) and the element holding the moved content."""
    el = ET.parse(pf).getroot()
    path = []
    while True:
        kids = list(el)
        if len(kids) != 1 or kids[0].tag not in ("group", "script"):
            return path, el
        el = kids[0]
        path.append(key(el))


def merged_list():
    if not os.path.exists(MERGED):
        return []
    return [l.strip() for l in open(MERGED, encoding="utf-8") if l.strip() and not l.startswith("#")]


def main(spec_path, dry):
    spec = json.load(open(spec_path, encoding="utf-8"))
    already = set(merged_list())
    new_merged = []
    for seg, idxs in spec.items():
        tree, path, js = J.segment_joints(seg)
        root = tree.getroot()
        # key path of every group / script in the segment -> element, and its document order
        paths, order = {}, {}

        def walk(el, p):
            for c in el:
                q = p + (key(c),)
                if c.tag in ("group", "script"):
                    paths.setdefault(q, c)
                    order[id(c)] = len(order)
                walk(c, q)
        walk(root, ())
        parts = {}
        for pf in sorted(glob.glob(os.path.join(PART_DIR, seg + "_*.xml"))):
            if os.path.basename(pf) in already:
                continue
            chain, holder = part_chain(pf)
            parts[pf] = (tuple(chain), holder)
        # each joint: nearest ancestor group (below the segment's two wrapper levels) that parts came out of
        chosen = {}
        for idx in idxs:
            j, chain, inst = js[idx - 1]
            assert not inst
            groups = [a for a in chain if a.tag in ("group", "script")]
            kp = []
            el_paths = []
            for a in chain[1:]:
                kp.append(key(a))
                if a.tag in ("group", "script"):
                    el_paths.append((tuple(kp), a))
            for gpath, g in reversed(el_paths[2:]):
                hits = [pf for pf, (pc, _) in parts.items() if pc[:len(gpath)] == gpath]
                if hits:
                    for pf in hits:
                        chosen[pf] = parts[pf]
                    break
        # merge: the holder's children go into the deepest group of the part's chain that exists in the segment
        inserts = {}
        for pf, (pc, holder) in chosen.items():
            target = None
            for n in range(len(pc), 0, -1):
                if pc[:n] in paths:
                    target = paths[pc[:n]]
                    rest = pc[n:]
                    break
            assert target is not None, pf
            # rebuild the chain below the target (groups the split removed), then the moved content
            frag_root = ET.Element("x")
            cur = frag_root
            for t, at in rest:
                cur = ET.SubElement(cur, t, dict(at))
            for c in list(holder):
                cur.append(c)
            xml = "".join(ET.tostring(c, encoding="unicode") for c in frag_root)
            inserts.setdefault(order[id(target)], []).append(xml)
            new_merged.append(os.path.basename(pf))
        text = open(path, encoding="utf-8").read()
        starts = list(J.GROUP_TAG.finditer(text))
        assert len(starts) == len(order), "%s: %d group tags in the text, %d elements" % (seg, len(starts), len(order))
        out, last = [], 0
        for n in sorted(inserts):
            gt = text.index(">", starts[n].start()) + 1
            assert text[gt - 2] != "/", "%s: target group #%d is self-closing" % (seg, n)
            line_end = text.find("\n", gt)
            line_end = len(text) if line_end < 0 else line_end + 1
            indent = re.match(r"[ \t]*", text[line_end:]).group(0)
            out.append(text[last:line_end])
            out.append("".join(indent + x + "\n" for x in inserts[n]))
            last = line_end
        out.append(text[last:])
        new = "".join(out)
        ET.fromstring(new)
        print("%s: %d parts merged back into %d groups" % (seg, len(chosen), len(inserts)))
        for pf in sorted(chosen):
            names = [a[1] for a in chosen[pf][0]]
            label = "/".join(dict(at).get("name", "-") for _, at in chosen[pf][0][2:])
            print("   %s  %6d bytes  %s" % (os.path.basename(pf), os.path.getsize(pf), label))
        if not dry:
            open(path, "w", encoding="utf-8", newline="\n").write(new)
    if not dry and new_merged:
        with open(MERGED, "a", encoding="utf-8", newline="\n") as f:
            if not os.path.exists(MERGED) or os.path.getsize(MERGED) == 0:
                f.write("# parts put back into their segment by merge_joint_parts.py; segment_pieces.py skips them\n")
            for n in new_merged:
                f.write(n + "\n")


if __name__ == "__main__":
    main(sys.argv[1], "--dry-run" in sys.argv)

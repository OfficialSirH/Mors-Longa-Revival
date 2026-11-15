"""Dev tool (2026-11-14, performance): cut one road segment into test prefabs, one per content group, so the debug
menu's "segment piece by piece" test (ui/ConfigMenu.lua server.perfTest) can spawn them one at a time and the
freeze can be pinned on one group (the API has no wall clock to time spawns).

Usage (repo root): python tools/porting/perf_pieces.py [Segment]      (default RoadSegment1)
Writes dev/perftest/<Segment>_<group>.xml (left out of the release) and prints the Lua list for ConfigMenu.lua.
Each piece keeps its chain of parent elements as text (same method as split_decor.py), so it spawns in place.
"""
import os, re, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from split_decor import parse_spans, line_start, line_end, REPO

OUT = "dev/perftest"


def main():
    seg = sys.argv[1] if len(sys.argv) > 1 else "RoadSegment1"
    os.chdir(REPO)
    path = "prefabs/spawnables/roadsegments/%s.xml" % seg
    text = open(path, encoding="utf-8").read()
    tree = parse_spans(text)
    prefab = tree.children[0]
    inst = prefab.children[0]
    # the content groups: children of the instance group's first unnamed group, plus the instance group's other
    # children (trigger, Spawns; decor is in its own prefabs already)
    pieces = []
    for child in inst.children:
        if child.name == "group" and child.get("name") is None:
            for c in child.children:
                if c.name == "group" and c.get("name") == "ground":
                    # the ground group holds most of the segment: one piece per kind of child
                    kinds = {}
                    for g in c.children:
                        k = "ground " + (g.get("name") or g.name).split(":")[0]
                        if g.name == "trigger":
                            k = "ground water"
                        kinds.setdefault(k, []).append(g)
                    for k, nodes in kinds.items():
                        pieces.append((nodes, [prefab, inst, child, c], k))
                else:
                    pieces.append((c, [prefab, inst, child]))
        elif not (child.name == "group" and child.get("name") == "decor"):
            pieces.append((child, [prefab, inst]))
    os.makedirs(OUT, exist_ok=True)
    names = []
    for i, piece in enumerate(pieces):
        node, chain = piece[0], piece[1]
        nodes = node if isinstance(node, list) else [node]
        label = piece[2] if len(piece) > 2 else (node.get("name") or node.name)
        key = "%02d_%s" % (i + 1, re.sub(r"[^A-Za-z0-9]+", "_", label).strip("_"))
        head = "".join(text[line_start(text, a.start):a.open_end] + "\n" for a in chain)
        body = "".join(text[line_start(text, n.start):line_end(text, n.end)] for n in nodes)
        tail = "".join("</%s>\n" % a.name for a in chain[::-1])
        out = "%s/%s_%s.xml" % (OUT, seg, key)
        with open(out, "w", encoding="utf-8", newline="\n") as f:
            f.write(head + body + tail)
        tags = {}
        for m in re.finditer(r"<(vox|voxbox|voxagon|water|light|body|joint|trigger|instance)\b", body):
            tags[m.group(1)] = tags.get(m.group(1), 0) + 1
        names.append((label, "MOD/" + out))
        print("%-28s %s" % (key, tags))
    print("\nPERFTEST_PIECES = {")
    for label, p in names:
        print('    { "%s", "%s" },' % (label, p))
    print("}")


if __name__ == "__main__":
    main()

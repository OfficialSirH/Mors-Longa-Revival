"""Road segments' heavy content as small pieces with a cost, spawned under a per-frame budget (2026-11-14).

Usage (repo root): python tools/porting/segment_pieces.py        (re-run after split_heavy.py / vox_pieces.py or
                                                                  after editing a part; re-runnable)

Why: spawn cost follows box cells (TECHNICAL_REFERENCE §7) and Spawn() builds a prefab in one frame. One part per
frame (split_heavy.py) still gave long stretches of slow frames: a low-detail rock part is ~0.9M cells, a hill
5.85M. This cuts each part (prefabs/spawnables/roadsegments/parts/, the source; split_heavy.py writes them) into
pieces of at most SPLIT cells where possible: a group (or a <compound>: the hills sit alone in one each, and each
piece keeps a copy of the wrapper) into its children, a reference to a model of
vox_pieces.PIECE_MODELS into one element per placed model (rock1.vox -> 8 octants, hills -> their layers;
assets/vox/terrainpieces/pieces/). Each piece is XML text: its chain of ancestor start tags + the element + closing
tags, so placement and group defaults are kept. A rock piece also has its low-detail version (rock1_low piece,
twice the scale: option "Low Detail Rocks"). world/generation/GenerateRoad.lua spawns pieces after the segment, as
many per frame as fit in its cell budget.
Cost = box cells: voxbox = its size; vox = cropped model(s) (object= picks one; else every placed model);
voxagon = vertex bounding box x extrude (all in 10 cm voxels, scale ignored: the voxel count does not change).
Check: per part, the chains (tag + attributes of an element and its ancestors) of the pieces before model
substitution = the part's chains, wrappers repeated only as ancestors (same rule as split_heavy.check).
Writes world/generation/SegmentPieces.lua.
"""
import os, re, sys, glob, struct, math
from collections import Counter

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from split_decor import parse_spans, chains, REPO
from rock_variant import read_dict
import vox_pieces

PART_DIR = "prefabs/spawnables/roadsegments/parts"
OUT_LUA = "world/generation/SegmentPieces.lua"
SPLIT = 100000          # box cells: a group above this is cut into its children
LOW = {"assets/vox/terrainpieces/rock1.vox": "assets/vox/terrainpieces/rock1_low.vox"}
OWNERS = ("script", "vehicle", "body", "wheel")

_vox_cache = {}


def vox_info(path):
    """(cells per model index, {object name: model index}, [model index per placed shape])"""
    if path in _vox_cache:
        return _vox_cache[path]
    _, chunks = vox_pieces.read_chunks(path)
    cells, trn, shp = [], {}, {}
    for i, (cid, c, ch) in enumerate(chunks):
        if cid == b"SIZE":
            nxt = chunks[i + 1]
            cells.append(vox_pieces.model_cells(struct.unpack_from("<iii", c), nxt[0], nxt[1]))
        elif cid == b"nTRN":
            t = vox_pieces.parse_trn(c)
            trn[t[0]] = t
        elif cid == b"nSHP":
            s = vox_pieces.parse_shp(c)
            shp[s[0]] = [m for m, _ in s[2]]
    names, placed = {}, []
    for t in trn.values():
        if t[2] in shp:
            placed += shp[t[2]]
            name = dict(t[1]).get(b"_name")
            if name:
                names[name.decode("latin-1")] = shp[t[2]][0]
    if not placed:
        placed = list(range(len(cells)))
    _vox_cache[path] = (cells, names, placed)
    return _vox_cache[path]


def cells(n):
    if n.name == "voxbox":
        s = [float(v) for v in (n.get("size") or "10 10 10").split()] + [1, 1]
        return int(s[0] * s[1] * s[2])
    if n.name == "voxagon":
        vs = [[float(x) for x in (v.get("pos") or "0 0").split()] for v in n.children if v.name == "vertex"]
        if not vs:
            return 0
        w = (max(v[0] for v in vs) - min(v[0] for v in vs)) * 10 + 1
        d = (max(v[1] for v in vs) - min(v[1] for v in vs)) * 10 + 1
        return int(w * d * float(n.get("extrude") or 1))
    if n.name == "vox":
        f = n.get("file") or ""
        own = sum(cells(c) for c in n.children)
        if not f.startswith("MOD/") or not os.path.exists(f[4:]):
            return own
        mc, names, placed = vox_info(f[4:])
        obj = n.get("object")
        if obj:
            return own + (mc[names[obj]] if obj in names else 0)
        return own + sum(mc[m] for m in placed)
    return sum(cells(c) for c in n.children)


# ---- approximate position of a piece along the road (x), for nearest-first spawning (2026-11-15) ----------------
# Teardown: an element's transform is relative to its parent; rot = Euler degrees applied as QuatEuler: Y, Z, X.

def _qmul(a, b):
    ax, ay, az, aw = a
    bx, by, bz, bw = b
    return (aw * bx + ax * bw + ay * bz - az * by, aw * by - ax * bz + ay * bw + az * bx,
            aw * bz + ax * by - ay * bx + az * bw, aw * bw - ax * bx - ay * by - az * bz)


def _qeuler(x, y, z):
    def axis(i, deg):
        h = math.radians(deg) / 2
        v = [0.0, 0.0, 0.0]
        v[i] = math.sin(h)
        return (v[0], v[1], v[2], math.cos(h))
    return _qmul(_qmul(axis(1, y), axis(2, z)), axis(0, x))


def _qrot(q, v):
    x, y, z, w = q
    p = (v[0], v[1], v[2], 0.0)
    r = _qmul(_qmul(q, p), (-x, -y, -z, w))
    return r[:3]


def _vec(s, n=3):
    vals = [float(t) for t in (s or "").split()] if s else []
    return (vals + [0.0] * n)[:n]


def piece_x(chain, nodes):
    """x (along the road, segment frame) of the first of `nodes` under `chain` (pos / rot composed)"""
    pos, rot = (0.0, 0.0, 0.0), (0.0, 0.0, 0.0, 1.0)
    xs = []
    for i, n in enumerate(list(chain) + [None]):
        if n is None:
            for m in nodes:
                p = _qrot(rot, _vec(m.get("pos")))
                xs.append(pos[0] + p[0])
            break
        p = _qrot(rot, _vec(n.get("pos")))
        pos = (pos[0] + p[0], pos[1] + p[1], pos[2] + p[2])
        rot = _qmul(rot, _qeuler(*_vec(n.get("rot"))))
    return min(xs) if xs else 0.0


# ---- large voxboxes -> brush-aligned tiles (2026-11-15) ------------------------------------------------------------
# A voxbox spans pos -> pos + size * 0.1 along its own +x / +y / +z and is painted from its brush object, which
# repeats with the brush model's size (MagicaVoxel x -> local x, y -> local z, z -> local y). Tiles whose starts are
# whole multiples of that period sample the brush exactly like the whole box; each keeps every other attribute
# (offset, tags, material). A 200 m road / sand box becomes 20-30 m tiles: generated nearest-first and deleted
# piece by piece (user: large parts deleted in sight, "split apart more ... more easily chunkable").
TILE_CELLS = 200000

_brush_cache = {}


def brush_period(brush, obj):
    """(x, y, z) repeat of a voxbox brush in local voxels; (1, 1, 1) when unknown / no brush"""
    key = (brush, obj)
    if key in _brush_cache:
        return _brush_cache[key]
    period = (1, 1, 1)
    path = (brush or "")[4:] if (brush or "").startswith("MOD/") else None
    if path and os.path.exists(path):
        _, chunks = vox_pieces.read_chunks(path)
        sizes = [struct.unpack_from("<iii", c) for cid, c, ch in chunks if cid == b"SIZE"]
        trn, shp = {}, {}
        for cid, c, ch in chunks:
            if cid == b"nTRN":
                t = vox_pieces.parse_trn(c)
                trn[t[0]] = t
            elif cid == b"nSHP":
                s = vox_pieces.parse_shp(c)
                shp[s[0]] = s[2][0][0]
        idx = None
        if obj:
            for t in trn.values():
                if dict(t[1]).get(b"_name") == obj.encode("latin-1") and t[2] in shp:
                    idx = shp[t[2]]
        elif len(sizes) == 1:
            idx = 0
        if idx is not None:
            sx, sy, sz = sizes[idx]
            period = (sx, sz, sy)
    _brush_cache[key] = period
    return period


def _axis_tiles(n, period, want):
    """cut n voxels into runs whose starts are multiples of `period`, about `want` long"""
    step = max(period, (int(want) // period) * period)
    return [(s, min(step, n - s)) for s in range(0, n, step)]


def voxbox_tiles(node):
    """[(tile start tag text, local start (vx, vz))] or None when the box is small / not cut"""
    size = [int(round(float(v))) for v in (node.get("size") or "10 10 10").split()] + [1, 1]
    sx, sy, sz = size[:3]
    if sx * sy * sz <= TILE_CELLS or node.children:
        return None
    px, py, pz = brush_period(node.get("brush"), node.get("object"))
    side = math.sqrt(TILE_CELLS / max(1, sy))       # about square tiles of TILE_CELLS
    xs, zs = _axis_tiles(sx, px, side), _axis_tiles(sz, pz, side)
    if len(xs) * len(zs) <= 1:
        return None
    assert sum(l for _, l in xs) == sx and sum(l for _, l in zs) == sz
    pos = _vec(node.get("pos"))
    rot = _qeuler(*_vec(node.get("rot")))
    out = []
    for x0, lx in xs:
        for z0, lz in zs:
            d = _qrot(rot, (x0 * 0.1, 0.0, z0 * 0.1))
            p = (pos[0] + d[0], pos[1] + d[1], pos[2] + d[2])
            out.append(((x0, z0), (lx, sy, lz), p))
    return out


def low_tag(tag, low_file):
    m = re.search(r'\bscale="([^"]*)"', tag)
    out = re.sub(r'\bfile="[^"]*"', 'file="MOD/%s"' % low_file, tag)
    if m:
        s = ("%.4f" % (float(m.group(1)) * 2)).rstrip("0").rstrip(".")
        return out.replace(m.group(0), 'scale="%s"' % s)
    end = "/>" if out.endswith("/>") else ">"
    return out[:-len(end)].rstrip() + ' scale="2"' + end


def pieces_of_part(text, pieces_by_model):
    """[(chain nodes, element text, cells, low text or None, low cells)] and the check's piece texts."""
    tree = parse_spans(text)
    out, check_texts = [], []

    def emit(node, chain):
        head = "".join(text[a.start:a.open_end] + "\n" for a in chain)
        tail = "".join("</%s>\n" % a.name for a in chain[::-1])
        body = text[node.start:node.end]
        check_texts.append(head + body + "\n" + tail)
        if node.name == "voxbox":
            tiles = voxbox_tiles(node)
            if tiles:
                class _At:   # a tile's position for piece_x
                    def __init__(self, p): self.p = p
                    def get(self, k): return "%f %f %f" % self.p if k == "pos" else None
                for (x0, z0), (lx, ly, lz), p in tiles:
                    el = re.sub(r'\bsize="[^"]*"', 'size="%d %d %d"' % (lx, ly, lz), body)
                    ptxt = 'pos="%s %s %s"' % tuple(("%.4f" % v).rstrip("0").rstrip(".") for v in p)
                    el = re.sub(r'\bpos="[^"]*"', ptxt, el) if re.search(r'\bpos="', el) else el.replace("<voxbox", "<voxbox " + ptxt, 1)
                    out.append((chain, el, lx * ly * lz, None, 0, piece_x(chain, [_At(p)])))
                return
        f = (node.get("file") or "")[4:]
        if node.name == "vox" and f in pieces_by_model and not node.get("object") and not node.children:
            lows = pieces_by_model.get(LOW.get(f))
            x = piece_x(chain, [node])
            for k, (piece, c) in enumerate(pieces_by_model[f]):
                el = re.sub(r'\bfile="[^"]*"', 'file="MOD/%s"' % piece, body)
                low = (low_tag(body, lows[k][0]), lows[k][1]) if lows else (None, 0)
                out.append((chain, el, c, low[0], low[1], x))
            return
        out.append((chain, body, cells(node), None, 0, piece_x(chain, [node])))

    def is_model_ref(node):
        f = (node.get("file") or "")[4:]
        return node.name == "vox" and f in pieces_by_model and not node.get("object") and not node.children

    def splits(node):
        return node.name in ("group", "compound") and node.children and cells(node) > SPLIT and \
            not any(c.name in OWNERS for c in node.children)

    def emit_batch(nodes, chain):
        # (2026-11-14) small siblings share one piece up to SPLIT cells (a floor of 1325 thin plates: 1 Spawn per
        # ~100k cells instead of per plate)
        if len(nodes) == 1:
            return emit(nodes[0], chain)
        head = "".join(text[a.start:a.open_end] + "\n" for a in chain)
        tail = "".join("</%s>\n" % a.name for a in chain[::-1])
        body = "\n".join(text[n.start:n.end] for n in nodes)
        check_texts.append(head + body + "\n" + tail)
        out.append((chain, body, sum(cells(n) for n in nodes), None, 0, piece_x(chain, nodes)))

    def walk(node, chain):
        if is_model_ref(node):
            emit(node, chain)
        elif splits(node):
            batch, used = [], 0
            for c in node.children:
                if is_model_ref(c) or splits(c):
                    if batch:
                        emit_batch(batch, chain + [node])
                    batch, used = [], 0
                    walk(c, chain + [node])
                    continue
                cc = cells(c)
                if batch and used + cc > SPLIT:
                    emit_batch(batch, chain + [node])
                    batch, used = [], 0
                batch.append(c)
                used += cc
            if batch:
                emit_batch(batch, chain + [node])
        else:
            emit(node, chain)

    root = [c for c in tree.children if c.name == "prefab"]
    assert len(root) == 1
    for c in root[0].children:
        walk(c, [root[0]])
    # check (before model substitution): same rule as split_heavy.check
    a = chains(text)
    b = Counter()
    for t in check_texts:
        b += chains(t)
    missing, extra = a - b, b - a
    ancestors = {k[:i] for k in a for i in range(1, len(k))}
    bad = [k for k in extra if k not in a or k not in ancestors]
    assert not missing and not bad, "piece check failed: %d missing, %d unexpected" % (sum(missing.values()), len(bad))
    return out, text


def lua_str(s):
    assert "]==]" not in s
    return "[==[" + s + "]==]"


def main():
    os.chdir(REPO)
    pieces_by_model = {m: vox_pieces.split(m) for m in vox_pieces.PIECE_MODELS}
    heads, head_index = [], {}
    table = {}
    stats = Counter()
    for path in sorted(p.replace("\\", "/") for p in glob.glob(PART_DIR + "/*.xml")):
        seg = re.match(r".*/(RoadSegment\w+?)_\d{3}\.xml$", path).group(1)
        text = open(path, encoding="utf-8").read()
        out, _ = pieces_of_part(text, pieces_by_model)
        for chain, el, c, low, lc, x in out:
            head = "".join(text[a.start:a.open_end] + "\n" for a in chain)
            tail = "".join("</%s>\n" % a.name for a in chain[::-1])
            key = (head, tail)
            if key not in head_index:
                head_index[key] = len(heads) + 1
                heads.append(key)
            table.setdefault(seg, []).append((head_index[key], el, c, low, lc, x))
            stats["pieces"] += 1
            stats["cells"] += c
            stats["low_cells"] += lc if low else c
            stats["max"] = max(stats["max"], c)
            stats["max_low"] = max(stats["max_low"], lc if low else c)
    # (2026-11-15) nearest-first: players come from -x, so pieces spawn in order of their position along the road
    # (the segment file with its dynamic objects comes after all of them: GenerateRoad)
    for seg in table:
        table[seg].sort(key=lambda p: p[5])
    lines = ["-- GENERATED by tools/porting/segment_pieces.py from prefabs/spawnables/roadsegments/parts/: each road",
             "-- segment's heavy content (rocks, hills, terrain) as small pieces { head index, element, box cells,",
             "-- low-detail element, its cells }. Spawn xml = SEGMENT_PIECE_HEADS[i] .. element .. SEGMENT_PIECE_TAILS[i].",
             "-- GenerateRoad.lua spawns them after the segment within a per-frame cell budget.",
             "SEGMENT_PIECE_HEADS = {}", "SEGMENT_PIECE_TAILS = {}"]
    for i, (h, t) in enumerate(heads):
        lines.append("SEGMENT_PIECE_HEADS[%d] = %s" % (i + 1, lua_str(h)))
        lines.append("SEGMENT_PIECE_TAILS[%d] = %s" % (i + 1, lua_str(t)))
    lines.append("SEGMENT_PIECES = {}")
    for seg in sorted(table):
        lines.append('SEGMENT_PIECES["%s"] = {' % seg)
        for h, el, c, low, lc, x in table[seg]:
            if low:
                lines.append("\t{ %d, %s, %d, %s, %d }," % (h, lua_str(el), c, lua_str(low), lc))
            else:
                lines.append("\t{ %d, %s, %d }," % (h, lua_str(el), c))
        lines.append("}")
    data = "\n".join(lines) + "\n"
    with open(OUT_LUA, "w", encoding="utf-8", newline="\n") as f:
        f.write(data)
    print("%d segments, %d pieces, %d heads; %.1fM cells (low rocks %.1fM); largest piece %.2fM (low %.2fM); %s %d KB"
          % (len(table), stats["pieces"], len(heads), stats["cells"] / 1e6, stats["low_cells"] / 1e6,
             stats["max"] / 1e6, stats["max_low"] / 1e6, OUT_LUA, len(data) // 1024))


if __name__ == "__main__":
    main()

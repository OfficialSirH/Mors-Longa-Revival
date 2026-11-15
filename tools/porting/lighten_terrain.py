"""Make road segments cheaper to spawn (Phase 5 performance, 2026-11-14, user decision: tiles + coarse floors).

Usage (repo root): python tools/porting/lighten_terrain.py [--dry-run]

Why: in-game tests (debug menu "piece by piece") pinned the segment-spawn freeze on three pieces: the hidden
unbreakable floor ("bedrock" voxagons, "unbreakable ground" voxboxes: 4-8 M voxel cells each, at 10 cm), the terrain
models (MorsLongaHill.vox / MorsLongaDunes.vox: 256x256x256 boxes 0.5-3.4% filled), then the sand. A shape seems to
cost by its whole box, empty air included.

1. Terrain models (TILE_MODELS) are cut into tiles (TILE x TILE voxel columns), each cropped to its own voxels and
   written as its own .vox (palette and materials copied) under assets/vox/terrainpieces/tiles/. Each `<vox file=...>`
   of the model becomes `<group pos rot (the element's)>` + one `<vox>` per tile, offset so every voxel lands where
   it was. Placement rule (tools/porting/blender_vehicle.py, checked in-game on vehicles): a vox shape's origin is
   the bottom centre of its cropped model; voxel (x, y, z) -> ((x - floor(sx/2)) s, z s, -(y - floor(sy/2)) s),
   s = 0.1 m * scale. Check: every voxel of the model maps to the same point and colour through exactly one tile.
2. Hidden floors (name "bedrock" voxagons, "unbreakable ground" voxboxes, both under the 10 cm sand layer) become
   unbreakable plates of 40 cm voxels (scale 4, one voxel thick, top at the same height, colour = the brush object's
   most common colour, palette + materials copied): about 30x fewer cells. A voxagon's outline must be rectilinear
   (it is split into rectangles); vertex (a, b) is local (x, z) (checked: the outlines meet the sand boxes' edges).
   Check: a 0.5 m grid of points inside each original floor is covered by its plates.
Text-level edits (other bytes unchanged); already converted elements are left alone (re-runnable).
"""
import os, re, sys, glob, math, struct
from collections import Counter

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from split_decor import parse_spans, line_start, line_end, REPO

SEG_GLOB = "prefabs/spawnables/roadsegments/RoadSegment*.xml"
TILE_MODELS = ["assets/vox/terrainpieces/MorsLongaHill.vox", "assets/vox/terrainpieces/MorsLongaDunes.vox"]
TILE = 32
TILE_DIR = "assets/vox/terrainpieces/tiles"
PLATE_SCALE = 1                 # (2026-11-14) was 4 (40 cm, one voxel thick): in-game those plates let players and
                                # objects fall through, and the engine found no voxel material where its raycast hit
                                # them (debug "probe ground"). Now 10 cm and the original thickness, streamed as
                                # pieces (split_heavy.py moves the coarse:* groups); --replate rebuilds them.
PLATE_MAX = 250                 # voxels per plate side (MagicaVoxel models stay < 256)
BRUSH = "main/terrain/ground_building_assets_highway.vox"


# ------------------------------------------------------------------------------------------------ .vox files

def read_vox(path):
    """{'models': [(size, voxels)], 'names': {name: model index}, 'palette': raw RGBA/IMAP/MATL chunks}"""
    b = open(path, "rb").read()
    assert b[:4] == b"VOX ", path
    o = 8
    n, m = struct.unpack_from("<ii", b, o + 4)
    o += 12 + n
    sizes, models, trn, shp, palette = [], [], {}, {}, b""
    while o < len(b):
        cid = b[o:o + 4]
        n, m = struct.unpack_from("<ii", b, o + 4)
        c = b[o + 12:o + 12 + n]
        if cid == b"SIZE":
            sizes.append(struct.unpack_from("<iii", c))
        elif cid == b"XYZI":
            k = struct.unpack_from("<i", c)[0]
            models.append([struct.unpack_from("<BBBB", c, 4 + 4 * i) for i in range(k)])
        elif cid == b"nTRN":
            nid = struct.unpack_from("<i", c)[0]
            p, attrs = 4, {}
            na = struct.unpack_from("<i", c, p)[0]; p += 4
            for _ in range(na):
                l = struct.unpack_from("<i", c, p)[0]; p += 4; key = c[p:p + l].decode("latin-1"); p += l
                l = struct.unpack_from("<i", c, p)[0]; p += 4; val = c[p:p + l].decode("latin-1"); p += l
                attrs[key] = val
            trn[nid] = (attrs.get("_name"), struct.unpack_from("<i", c, p)[0])
        elif cid == b"nSHP":
            nid = struct.unpack_from("<i", c)[0]
            p = 4
            na = struct.unpack_from("<i", c, p)[0]; p += 4
            for _ in range(na):
                l = struct.unpack_from("<i", c, p)[0]; p += 4 + l
                l = struct.unpack_from("<i", c, p)[0]; p += 4 + l
            p += 4
            shp[nid] = struct.unpack_from("<i", c, p)[0]
        elif cid in (b"RGBA", b"IMAP", b"MATL"):
            palette += b[o:o + 12 + n + m]
        o += 12 + n + m
    names = {name: shp[child] for name, child in trn.values() if name and child in shp}
    return {"models": list(zip(sizes, models)), "names": names, "palette": palette}


def write_vox(path, size, voxels, palette):
    def chunk(cid, content, children=b""):
        return cid + struct.pack("<ii", len(content), len(children)) + content + children
    assert all(0 <= v[i] < 256 for v in voxels for i in range(3)), path
    body = chunk(b"SIZE", struct.pack("<iii", *size))
    body += chunk(b"XYZI", struct.pack("<i", len(voxels)) + b"".join(struct.pack("<BBBB", *v) for v in voxels))
    body += palette
    data = b"VOX " + struct.pack("<i", 150) + chunk(b"MAIN", b"", body)
    with open(path, "wb") as f:
        f.write(data)


def crop(voxels):
    lo = [min(v[i] for v in voxels) for i in range(3)]
    hi = [max(v[i] for v in voxels) for i in range(3)]
    return tuple(hi[i] - lo[i] + 1 for i in range(3)), [(v[0] - lo[0], v[1] - lo[1], v[2] - lo[2], v[3]) for v in voxels]


def placed(size, voxels, off=(0, 0, 0)):
    """Multiset of (local point in voxel units, colour) by the engine's placement rule (see module doc)."""
    cx, cy = size[0] // 2, size[1] // 2
    return Counter(((off[0] + x - cx, off[1] + z, off[2] - (y - cy)), ci) for x, y, z, ci in voxels)


# ------------------------------------------------------------------------------------------------ 1. tiles

def make_tiles(model_path):
    """[(tile file, offset in voxel units)], cells before, cells after; writes nothing (see write_tiles)."""
    vox = read_vox(model_path)
    assert len(vox["models"]) == 1, model_path
    size, voxels = crop(vox["models"][0][1])
    groups = {}
    for v in voxels:
        groups.setdefault((v[0] // TILE, v[1] // TILE), []).append(v)
    base = os.path.splitext(os.path.basename(model_path))[0]
    tiles, original, total = [], placed(size, voxels), Counter()
    cx, cy = size[0] // 2, size[1] // 2
    for (ix, iy), vs in sorted(groups.items()):
        lo = [min(v[i] for v in vs) for i in range(3)]
        tsize, tvox = crop(vs)
        tcx, tcy = tsize[0] // 2, tsize[1] // 2
        off = (lo[0] - cx + tcx, lo[2], -(lo[1] - cy + tcy))
        total += placed(tsize, tvox, off)
        path = "%s/%s_%02d_%02d.vox" % (TILE_DIR, base, ix, iy)
        tiles.append((path, off, tsize, tvox))
    assert total == original, "tiling check failed for " + model_path
    before = size[0] * size[1] * size[2]
    after = sum(t[2][0] * t[2][1] * t[2][2] for t in tiles)
    return tiles, vox["palette"], before, after


def fmt(v):
    s = ("%.4f" % v).rstrip("0").rstrip(".")
    return "0" if s in ("-0", "") else s


def attr(text, name):
    m = re.search(r'\b%s="([^"]*)"' % name, text)
    return m.group(1) if m else None


def tile_element(start_tag, model_file, tiles):
    pos = attr(start_tag, "pos") or "0 0 0"
    rot = attr(start_tag, "rot") or "0 0 0"
    scale = float(attr(start_tag, "scale") or 1)
    s = 0.1 * scale
    rest = re.sub(r'\s(pos|rot|file|object)="[^"]*"', "", start_tag[len("<vox"):].rstrip("/>").rstrip())
    out = ['<group name="tiled:%s" pos="%s" rot="%s">' % (os.path.basename(model_file), pos, rot)]
    for path, off, _, _ in tiles:
        out.append('<vox pos="%s %s %s" file="MOD/%s"%s/>' % (fmt(off[0] * s), fmt(off[1] * s), fmt(off[2] * s), path, rest))
    out.append("</group>")
    return out


# ------------------------------------------------------------------------------------------------ 2. plates

def rectangles(verts):
    """Split a rectilinear polygon (list of (a, b) in metres) into axis-aligned rectangles (a0, b0, a1, b1)."""
    snap = lambda v: round(v * 10) / 10.0
    pts = [(snap(a), snap(b)) for a, b in verts]
    edges = list(zip(pts, pts[1:] + pts[:1]))
    for (a0, b0), (a1, b1) in edges:
        if abs(a0 - a1) > 0.15 and abs(b0 - b1) > 0.15:
            return raster_rectangles(verts)   # a diagonal edge: cover it cell by cell
    bs = sorted(set(b for _, b in pts))
    strips = []
    for b0, b1 in zip(bs, bs[1:]):
        mid = (b0 + b1) / 2
        xs = sorted(a0 for (a0, e0), (a1, e1) in edges
                    if abs(a0 - a1) <= 0.15 and min(e0, e1) < mid < max(e0, e1))
        strips.append((b0, b1, [(xs[i], xs[i + 1]) for i in range(0, len(xs) - 1, 2)]))
    rects, open_ = [], {}
    for b0, b1, ivs in strips:
        nxt = {}
        for iv in ivs:
            nxt[iv] = open_.pop(iv, b0)
        for iv, start in open_.items():
            rects.append((iv[0], start, iv[1], b0))
        open_ = nxt
        last = b1
    for iv, start in open_.items():
        rects.append((iv[0], start, iv[1], last))
    return rects


def raster_rectangles(verts):
    """Outline with diagonal edges: every plate-sized cell the outline touches (5x5 samples per cell), merged into
    rectangles (row runs, then equal runs of consecutive rows). Covers the outline, overhangs up to one cell."""
    s = 0.1 * PLATE_SCALE
    a_lo, b_lo = min(a for a, _ in verts), min(b for _, b in verts)
    na = int(math.ceil((max(a for a, _ in verts) - a_lo) / s)) + 1
    nb = int(math.ceil((max(b for _, b in verts) - b_lo) / s)) + 1
    rows = []
    for k in range(nb):
        run, runs = None, []
        for i in range(na):
            hit = any(inside(verts, a_lo + (i + u / 4.0) * s, b_lo + (k + w / 4.0) * s)
                      for u in range(5) for w in range(5))
            if hit and run is None:
                run = i
            if not hit and run is not None:
                runs.append((run, i))
                run = None
        if run is not None:
            runs.append((run, na))
        rows.append(runs)
    rects, open_ = [], {}
    for k, runs in enumerate(rows + [[]]):
        nxt = {}
        for r in runs:
            nxt[r] = open_.pop(r, k)
        for (i0, i1), k0 in open_.items():
            rects.append((a_lo + i0 * s, b_lo + k0 * s, a_lo + i1 * s, b_lo + k * s))
        open_ = nxt
    return rects


def inside(verts, x, z):
    c = False
    for (a0, b0), (a1, b1) in zip(verts, verts[1:] + verts[:1]):
        if (b0 > z) != (b1 > z) and x < a0 + (z - b0) * (a1 - a0) / (b1 - b0):
            c = not c
    return c


def plates_for(rects, top, colour, palette, written, thick=1):
    """Plate <vox> elements (local frame) covering the rectangles, `thick` voxels thick with their top at `top`;
    plate files written on demand."""
    s = 0.1 * PLATE_SCALE
    out = []
    for a0, b0, a1, b1 in rects:
        nx_total = int(math.ceil((a1 - a0) / s - 1e-6))
        nz_total = int(math.ceil((b1 - b0) / s - 1e-6))
        for i0 in range(0, nx_total, PLATE_MAX):
            for k0 in range(0, nz_total, PLATE_MAX):
                nx, nz = min(PLATE_MAX, nx_total - i0), min(PLATE_MAX, nz_total - k0)
                if thick == 1 and PLATE_SCALE == 4:
                    path = "%s/plate_%d_%dx%d.vox" % (TILE_DIR, colour, nx, nz)   # the old 40 cm names
                else:
                    path = "%s/plate_%d_%dx%dx%d.vox" % (TILE_DIR, colour, nx, nz, thick)
                written[path] = ((nx, nz, thick), [(x, y, z, colour) for x in range(nx) for y in range(nz)
                                                   for z in range(thick)], palette)
                x0, z0 = a0 + i0 * s, b0 + k0 * s
                px = x0 + (nx // 2) * s
                pz = z0 + (nz - nz // 2) * s
                scale = ' scale="%d"' % PLATE_SCALE if PLATE_SCALE != 1 else ""
                out.append(((x0, z0, x0 + nx * s, z0 + nz * s),
                            '<vox pos="%s %s %s" file="MOD/%s"%s tags="unbreakable"/>'
                            % (fmt(px), fmt(top - thick * s), fmt(pz), path, scale)))
    return out


def floor_plates(tag, text, c, brush, plate_files, where):
    """(name, plate elements) for an original hidden floor element (bedrock voxagon / unbreakable ground voxbox)."""
    name = attr(tag, "name")
    colour = brush_colour(brush, attr(tag, "object"))
    if c.name == "voxagon":
        verts = [(float(a), float(b)) for a, b in re.findall(r'<vertex pos="([-\d.]+) ([-\d.]+)"', text[c.start:c.end])]
        thick = int(round(float(attr(tag, "extrude") or 1)))
        plates = plates_for(rectangles(verts), thick * 0.1, colour, brush["palette"], plate_files, thick)
        check_cover(verts, [p[0] for p in plates], where)
    else:
        sx, sy, sz = [float(v) for v in attr(tag, "size").split()]
        rect = (0.0, 0.0, sx * 0.1, sz * 0.1)
        thick = int(round(sy))
        plates = plates_for([rect], sy * 0.1, colour, brush["palette"], plate_files, thick)
        check_cover([(0, 0), (rect[2], 0), (rect[2], rect[3]), (0, rect[3])], [p[0] for p in plates], where)
    return name, plates


def replate(dry):
    """Rebuild every coarse:* group from its original element in git HEAD (same name, pos, rot) with the current
    PLATE_SCALE and the original thickness."""
    import subprocess
    brush = read_vox(BRUSH)
    plate_files = {}
    for path in sorted(glob.glob(SEG_GLOB) + glob.glob("prefabs/spawnables/roadsegments/parts/*.xml")):
        path = path.replace("\\", "/")
        text = open(path, encoding="utf-8").read()
        if 'name="coarse:' not in text:
            continue
        seg = re.sub(r"/parts/(RoadSegment\w+?)_\d{3}\.xml$", r"/\1.xml", path)
        head = subprocess.run(["git", "show", "HEAD:" + seg], capture_output=True).stdout.decode("utf-8")
        assert head, "no HEAD version of " + seg
        htree = parse_spans(head)
        originals = {}

        def find(node):
            for c in node.children:
                tag = head[c.start:c.open_end]
                if (c.name == "voxagon" and attr(tag, "name") == "bedrock") or \
                        (c.name == "voxbox" and attr(tag, "name") == "unbreakable ground" and tag.rstrip().endswith("/>")):
                    key = (attr(tag, "name"), attr(tag, "pos") or "0 0 0", attr(tag, "rot") or "0 0 0")
                    originals.setdefault(key, []).append(c)
                else:
                    find(c)
        find(htree)
        tree = parse_spans(text)
        edits = []

        def walk(node):
            for c in node.children:
                tag = text[c.start:c.open_end]
                name = attr(tag, "name") or ""
                if c.name == "group" and name.startswith("coarse:"):
                    key = (name[len("coarse:"):], attr(tag, "pos"), attr(tag, "rot"))
                    assert originals.get(key), "no original for %s in %s" % (key, seg)
                    o = originals[key].pop(0)
                    otag = head[o.start:o.open_end]
                    oname, plates = floor_plates(otag, head, o, brush, plate_files, path)
                    edits.append((c, wrap_plates(otag, oname, plates)))
                else:
                    walk(c)
        walk(tree)
        out, pos = [], 0
        for node, lines in sorted(edits, key=lambda e: e[0].start):
            a, b = line_start(text, node.start), line_end(text, node.end)
            indent = re.match(r"[ \t]*", text[a:]).group(0)
            out.append(text[pos:a])
            out.append("".join(indent + ("\t" if 0 < i < len(lines) - 1 else "") + l + "\n" for i, l in enumerate(lines)))
            pos = b
        out.append(text[pos:])
        print("%-55s %d floor groups rebuilt" % (path, len(edits)))
        if not dry:
            with open(path, "w", encoding="utf-8", newline="\n") as f:
                f.write("".join(out))
    if not dry:
        for ppath, (size, voxels, pal) in plate_files.items():
            write_vox(ppath, size, voxels, pal)
    cells = sum(sz[0] * sz[1] * sz[2] for sz, _, _ in plate_files.values())
    print("%d plate files (%.1fM cells across distinct files)%s" % (len(plate_files), cells / 1e6, " (dry run)" if dry else ""))


def brush_colour(brush, obj):
    m = brush["models"][brush["names"][obj]][1]
    return Counter(v[3] for v in m).most_common(1)[0][0]


# ------------------------------------------------------------------------------------------------ main

def main():
    dry = "--dry-run" in sys.argv
    os.chdir(REPO)
    if "--replate" in sys.argv:
        replate(dry)
        return
    tiled = {}
    for model in TILE_MODELS:
        tiles, pal, before, after = make_tiles(model)
        tiled["MOD/" + model] = (tiles, pal)
        print("%-40s %d tiles, cells %.1fM -> %.2fM (check ok)" % (model, len(tiles), before / 1e6, after / 1e6))
    brush = read_vox(BRUSH)
    plate_files = {}
    for path in sorted(glob.glob(SEG_GLOB)):
        text = open(path, encoding="utf-8").read()
        tree = parse_spans(text)
        edits = []   # (start, end, replacement lines, indent)
        stats = Counter()

        def walk(node):
            for c in node.children:
                tag = text[c.start:c.open_end]
                if c.name == "vox" and attr(tag, "file") in tiled and tag.rstrip().endswith("/>"):
                    tiles = tiled[attr(tag, "file")][0]
                    edits.append((c, tile_element(tag, attr(tag, "file"), tiles)))
                    stats["model tiled"] += 1
                elif c.name == "voxagon" and attr(tag, "name") == "bedrock":
                    verts = [(float(a), float(b)) for a, b in
                             re.findall(r'<vertex pos="([-\d.]+) ([-\d.]+)"', text[c.start:c.end])]
                    rects = rectangles(verts)
                    top = float(attr(tag, "extrude") or 1) * 0.1
                    colour = brush_colour(brush, attr(tag, "object"))
                    plates = plates_for(rects, top, colour, brush["palette"], plate_files)
                    check_cover(verts, [p[0] for p in plates], path)
                    edits.append((c, wrap_plates(tag, "bedrock", plates)))
                    stats["bedrock voxagon"] += 1
                elif c.name == "voxbox" and attr(tag, "name") == "unbreakable ground" and tag.rstrip().endswith("/>"):
                    sx, sy, sz = [float(v) for v in attr(tag, "size").split()]
                    rect = (0.0, 0.0, sx * 0.1, sz * 0.1)
                    colour = brush_colour(brush, attr(tag, "object"))
                    plates = plates_for([rect], sy * 0.1, colour, brush["palette"], plate_files)
                    box = [(0, 0), (rect[2], 0), (rect[2], rect[3]), (0, rect[3])]
                    check_cover(box, [p[0] for p in plates], path)
                    edits.append((c, wrap_plates(tag, "unbreakable ground", plates)))
                    stats["ground voxbox"] += 1
                else:
                    walk(c)
        walk(tree)
        if not edits:
            continue
        out, pos = [], 0
        for node, lines in sorted(edits, key=lambda e: e[0].start):
            a, b = line_start(text, node.start), line_end(text, node.end)
            indent = re.match(r"[ \t]*", text[a:]).group(0)
            out.append(text[pos:a])
            out.append("".join(indent + ("\t" if 0 < i < len(lines) - 1 else "") + l + "\n" for i, l in enumerate(lines)))
            pos = b
        out.append(text[pos:])
        print("%-55s %s" % (path, dict(stats)))
        if not dry:
            with open(path, "w", encoding="utf-8", newline="\n") as f:
                f.write("".join(out))
    if not dry:
        os.makedirs(TILE_DIR, exist_ok=True)
        for model, (tiles, pal) in tiled.items():
            for tpath, off, tsize, tvox in tiles:
                write_vox(tpath, tsize, tvox, pal)
        for ppath, (size, voxels, pal) in plate_files.items():
            write_vox(ppath, size, voxels, pal)
    print("%d plate files%s" % (len(plate_files), " (dry run)" if dry else ""))


def wrap_plates(tag, name, plates):
    pos = attr(tag, "pos") or "0 0 0"
    rot = attr(tag, "rot") or "0 0 0"
    return ['<group name="coarse:%s" pos="%s" rot="%s">' % (name, pos, rot)] + [p[1] for p in plates] + ["</group>"]


def check_cover(outline, rects, where):
    a_lo, a_hi = min(a for a, _ in outline), max(a for a, _ in outline)
    b_lo, b_hi = min(b for _, b in outline), max(b for _, b in outline)
    a = a_lo + 0.25
    while a < a_hi:
        b = b_lo + 0.25
        while b < b_hi:
            if inside(outline, a, b) and not any(r[0] <= a <= r[2] and r[1] <= b <= r[3] for r in rects):
                raise SystemExit("plate cover check failed in %s at (%.2f, %.2f)" % (where, a, b))
            b += 0.5
        a += 0.5


if __name__ == "__main__":
    main()

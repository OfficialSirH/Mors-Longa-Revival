"""Cut a multi-model .vox into one file per placed model (Phase 5 performance, 2026-11-14).

Usage (repo root): python tools/porting/vox_pieces.py        (writes PIECE_MODELS, re-runnable)

Why: a shape's spawn cost follows its box cells (docs/PERFORMANCE.md) and Spawn() builds a whole prefab in one
frame. The terrain models below are several models placed by the file's scene graph (rock1.vox: one rock cut into
8 octants; hill1/hill1r: 22 terrace layers; hill2: 7 layers placed twice, once mirrored). Each placed model
(nTRN -> nSHP) becomes its own file under assets/vox/terrainpieces/pieces/ holding that model and a one-node scene
graph with the SAME transform node (offset _t, rotation/mirror _r, attributes), so a <vox file=piece> with the
original element's attributes puts its voxels where the whole file put them (tools/porting/segment_pieces.py
spawns them a few per frame). Palette, materials and other chunks are copied byte for byte. Check: each piece read
back has the original model bytes and transform; together the pieces hold every placed model once.
"""
import os, struct, sys, zlib

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rock_variant import read_dict, write_dict, REPO

PIECE_MODELS = ["assets/vox/terrainpieces/rock1.vox", "assets/vox/terrainpieces/rock1_low.vox",
                "assets/vox/terrainpieces/hill1.vox", "assets/vox/terrainpieces/hill1r.vox",
                "assets/vox/terrainpieces/hill2.vox"]
OUT_DIR = "assets/vox/terrainpieces/pieces"
SCENE = (b"nTRN", b"nGRP", b"nSHP")


def chunk(cid, content, children=b""):
    return cid + struct.pack("<ii", len(content), len(children)) + content + children


def read_chunks(path):
    b = open(path, "rb").read()
    assert b[:4] == b"VOX ", path
    n, m = struct.unpack_from("<ii", b, 12)
    o = 20 + n
    out = []
    while o < len(b):
        cid = b[o:o + 4]
        n, m = struct.unpack_from("<ii", b, o + 4)
        out.append((cid, b[o + 12:o + 12 + n], b[o + 12 + n:o + 12 + n + m]))
        o += 12 + n + m
    return b[:8], out


def parse_trn(c):
    nid = struct.unpack_from("<i", c)[0]
    attrs, p = read_dict(c, 4)
    child, reserved, layer, nf = struct.unpack_from("<iiii", c, p)
    p += 16
    frames = []
    for _ in range(nf):
        d, p = read_dict(c, p)
        frames.append(d)
    return nid, attrs, child, reserved, layer, frames


def trn(nid, attrs, child, reserved, layer, frames):
    return chunk(b"nTRN", struct.pack("<i", nid) + write_dict(attrs) + struct.pack("<iiii", child, reserved, layer, len(frames))
                 + b"".join(write_dict(f) for f in frames))


def parse_grp(c):
    nid = struct.unpack_from("<i", c)[0]
    attrs, p = read_dict(c, 4)
    k = struct.unpack_from("<i", c, p)[0]
    return nid, attrs, list(struct.unpack_from("<%di" % k, c, p + 4))


def parse_shp(c):
    nid = struct.unpack_from("<i", c)[0]
    attrs, p = read_dict(c, 4)
    k = struct.unpack_from("<i", c, p)[0]
    p += 4
    models = []
    for _ in range(k):
        mid = struct.unpack_from("<i", c, p)[0]
        d, p = read_dict(c, p + 4)
        models.append((mid, d))
    return nid, attrs, models


def model_cells(size, data_cid, data):
    """Cropped box cells of one model (the engine crops empty layers)."""
    if data_cid == b"XYZI":
        k = struct.unpack_from("<i", data)[0]
        if not k:
            return 0
        lo, hi = [255] * 3, [0] * 3
        for i in range(k):
            v = data[4 + 4 * i:7 + 4 * i]
            for a in range(3):
                lo[a] = min(lo[a], v[a]); hi[a] = max(hi[a], v[a])
        return (hi[0] - lo[0] + 1) * (hi[1] - lo[1] + 1) * (hi[2] - lo[2] + 1)
    import numpy as np
    sx, sy, sz = struct.unpack_from("<iii", data)
    a = np.frombuffer(zlib.decompressobj().decompress(data[12:]), np.uint8).reshape(sz, sy, sx)
    nz = np.nonzero(a)
    if not len(nz[0]):
        return 0
    return int(np.prod([int(v.max()) - int(v.min()) + 1 for v in nz]))


def scene(chunks):
    """models [(SIZE content, data cid, data content)], root nTRN, root group, [(instance nTRN, nSHP)]"""
    models, trns, grps, shps = [], {}, {}, {}
    for i, (cid, c, ch) in enumerate(chunks):
        if cid == b"SIZE":
            nxt = chunks[i + 1]
            assert nxt[0] in (b"XYZI", b"TDCZ")
            models.append((c, nxt[0], nxt[1]))
        elif cid == b"nTRN":
            t = parse_trn(c); trns[t[0]] = t
        elif cid == b"nGRP":
            g = parse_grp(c); grps[g[0]] = g
        elif cid == b"nSHP":
            s = parse_shp(c); shps[s[0]] = s
    root = trns[0]
    group = grps[root[2]]
    for f in root[5]:
        assert not any(k in (b"_t", b"_r") and v not in (b"0 0 0",) for k, v in f), "root transform not supported"
    instances = []
    for nid in group[2]:
        t = trns[nid]
        assert t[2] in shps, "nested groups not supported"
        instances.append((t, shps[t[2]]))
    return models, root, group, instances


def split(path):
    """[(piece path, cells)] for every placed model of path, in the file's group order."""
    head, chunks = read_chunks(path)
    models, root, group, instances = scene(chunks)
    other = [chunk(cid, c, ch) for cid, c, ch in chunks if cid not in SCENE + (b"SIZE", b"XYZI", b"TDCZ")]
    base = os.path.splitext(os.path.basename(path))[0]
    out = []
    for i, (t, s) in enumerate(instances):
        assert len(s[2]) == 1, "one model per shape node expected"
        mid, mattrs = s[2][0]
        size, dcid, data = models[mid]
        body = chunk(b"SIZE", size) + chunk(dcid, data)
        body += trn(0, root[1], 1, root[3], root[4], root[5])
        body += chunk(b"nGRP", struct.pack("<i", 1) + write_dict(group[1]) + struct.pack("<ii", 1, 2))
        body += trn(2, t[1], 3, t[3], t[4], t[5])
        body += chunk(b"nSHP", struct.pack("<i", 3) + write_dict(s[1]) + struct.pack("<ii", 1, 0) + write_dict(mattrs))
        body += b"".join(other)
        data_out = head + chunk(b"MAIN", b"", body)
        piece = "%s/%s_%02d.vox" % (OUT_DIR, base, i)
        # check: read back -> same model bytes, same transform
        _, pc = read_chunks_bytes(data_out)
        pm, _, _, pi = scene(pc)
        assert len(pm) == 1 and pm[0] == models[mid] and len(pi) == 1 and pi[0][0][5] == t[5] and pi[0][0][1] == t[1]
        os.makedirs(OUT_DIR, exist_ok=True)
        if not (os.path.exists(piece) and open(piece, "rb").read() == data_out):
            with open(piece, "wb") as f:
                f.write(data_out)
        out.append((piece, model_cells(struct.unpack_from("<iii", size), dcid, data)))
    return out


def read_chunks_bytes(b):
    n, m = struct.unpack_from("<ii", b, 12)
    o = 20 + n
    out = []
    while o < len(b):
        cid = b[o:o + 4]
        n, m = struct.unpack_from("<ii", b, o + 4)
        out.append((cid, b[o + 12:o + 12 + n], b[o + 12 + n:o + 12 + n + m]))
        o += 12 + n + m
    return b[:8], out


def main():
    os.chdir(REPO)
    for p in PIECE_MODELS:
        pieces = split(p)
        print("%-40s -> %2d pieces, %.2fM cells (largest %.2fM)" % (p, len(pieces), sum(c for _, c in pieces) / 1e6,
                                                                    max(c for _, c in pieces) / 1e6))


if __name__ == "__main__":
    main()

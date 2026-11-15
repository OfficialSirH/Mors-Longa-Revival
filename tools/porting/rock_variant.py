"""Dev tool (2026-11-14, performance): variants of a Teardown .vox to compare spawn cost in the debug menu's
Performance tests. Teardown stores each model as TDCZ: 12-byte size header + zlib of a dense x-fastest byte array of
palette indices, ended by a sync flush with no checksum (a finished zlib stream loads as an empty model).

Usage (repo root): python tools/porting/rock_variant.py hollow|half [src.vox] [out.vox]
  default src assets/vox/terrainpieces/rock1.vox, out dev/perftest/rock1_<mode>.vox
  hollow  keeps every voxel within 2 voxels (6-neighbour steps) of the outside; removes the hidden interior
          (same boxes). Result (rock1): 1.47M -> 0.51M filled; in-game hitch about the same.
  half    half resolution: each 2x2x2 block -> one voxel (filled when >= 4 of 8 are, its most common colour),
          blocks on the file's even scene coordinates, node offsets recomputed; spawn it at twice the scale. 8x fewer box cells, same number of shapes.
          In-game: much shorter hitch; the game's "Low Detail Rocks" option uses it (vox_pieces.py cuts it into
          pieces, segment_pieces.py gives each rock piece its low-detail version).
Other chunks (palette, materials, scene graph) are copied byte for byte, except the nTRN offsets in `half`.
"""
import os, struct, sys, zlib
from collections import deque

REPO = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
STEPS = ((1, 0, 0), (-1, 0, 0), (0, 1, 0), (0, -1, 0), (0, 0, 1), (0, 0, -1))


def hollow(dense, sx, sy, sz, shell=2):
    n = sx * sy * sz
    dist = [-1] * n
    q = deque()
    # distance (in steps) from empty space / the box edge, for filled voxels
    for i in range(n):
        if dense[i]:
            x = i % sx; y = (i // sx) % sy; z = i // (sx * sy)
            for dx, dy, dz in STEPS:
                X, Y, Z = x + dx, y + dy, z + dz
                if not (0 <= X < sx and 0 <= Y < sy and 0 <= Z < sz) or not dense[X + sx * (Y + sy * Z)]:
                    dist[i] = 1
                    q.append(i)
                    break
    while q:
        i = q.popleft()
        if dist[i] >= shell:
            continue
        x = i % sx; y = (i // sx) % sy; z = i // (sx * sy)
        for dx, dy, dz in STEPS:
            X, Y, Z = x + dx, y + dy, z + dz
            if 0 <= X < sx and 0 <= Y < sy and 0 <= Z < sz:
                j = X + sx * (Y + sy * Z)
                if dense[j] and dist[j] < 0:
                    dist[j] = dist[i] + 1
                    q.append(j)
    return (sx, sy, sz), bytes(dense[i] if 0 < dist[i] <= shell else 0 for i in range(n))


def half(dense, sx, sy, sz, lo=(0, 0, 0)):
    """lo: the model's first voxel in the file's scene coordinates. Blocks are aligned to EVEN scene coordinates, so
    the models of one object cut into pieces (rock1.vox: one rock in 8 octants meeting at 0) stay seamless: blocks
    aligned to each model's own odd edge straddled the cuts, came out half empty and left 1-voxel gaps (in-game)."""
    import numpy as np
    a = np.frombuffer(dense, np.uint8).reshape(sz, sy, sx)
    px, py, pz = lo[0] % 2, lo[1] % 2, lo[2] % 2
    hz, hy, hx = (sz + pz + 1) // 2, (sy + py + 1) // 2, (sx + px + 1) // 2
    p = np.zeros((hz * 2, hy * 2, hx * 2), np.uint8)
    p[pz:pz + sz, py:py + sy, px:px + sx] = a
    blocks = p.reshape(hz, 2, hy, 2, hx, 2).transpose(0, 2, 4, 1, 3, 5).reshape(hz, hy, hx, 8)
    filled = (blocks > 0).sum(axis=3) >= 4
    out = np.zeros((hz, hy, hx), np.uint8)
    for c in np.unique(blocks[blocks > 0]):
        cnt = (blocks == c).sum(axis=3)
        best = (blocks == out[..., None]).sum(axis=3) * (out > 0)
        out = np.where(cnt > best, c, out).astype(np.uint8)
    out = np.where(filled, out, 0).astype(np.uint8)
    return (hx, hy, hz), out.tobytes()


def check_half(orig, out):
    """orig / out: [(dense bytes, size, first voxel in scene coordinates)]. The half-res models, put together at
    their offsets, must be exactly the 2x2x2 reduction (>= 4 of 8 filled) of the whole original: no gap, no overlap."""
    import numpy as np
    def compose(models, scale):
        lo = [min(m[2][i] for m in models) for i in range(3)]
        lo = [v - v % 2 for v in lo] if scale == 1 else lo
        hi = [max(m[2][i] + m[1][i] for m in models) for i in range(3)]
        shape = [hi[i] - lo[i] for i in range(3)]
        if scale == 1:
            shape = [s + s % 2 for s in shape]
        g = np.zeros(shape[::-1], np.uint8)
        owner = np.zeros(shape[::-1], bool)
        for dense, size, first in models:
            a = np.frombuffer(dense, np.uint8).reshape(size[2], size[1], size[0])
            o = [first[i] - lo[i] for i in range(3)]
            sl = (slice(o[2], o[2] + size[2]), slice(o[1], o[1] + size[1]), slice(o[0], o[0] + size[0]))
            assert not owner[sl].any(), "half-res check: model boxes overlap"
            owner[sl] = True
            g[sl] = a
        return g, lo
    full, flo = compose(orig, 1)
    got, glo = compose(out, 2)
    fz, fy, fx = full.shape
    want = (full.reshape(fz // 2, 2, fy // 2, 2, fx // 2, 2) > 0).sum(axis=(1, 3, 5)) >= 4
    o = [glo[i] - flo[i] // 2 for i in range(3)]
    sub = want[o[2]:o[2] + got.shape[0], o[1]:o[1] + got.shape[1], o[0]:o[0] + got.shape[2]]
    assert sub.shape == got.shape and (sub == (got > 0)).all() and sub.sum() == want.sum(), \
        "half-res check: the pieces don't reproduce the whole object"


def read_dict(c, p):
    na = struct.unpack_from("<i", c, p)[0]; p += 4
    d = []
    for _ in range(na):
        l = struct.unpack_from("<i", c, p)[0]; p += 4; k = c[p:p + l]; p += l
        l = struct.unpack_from("<i", c, p)[0]; p += 4; v = c[p:p + l]; p += l
        d.append([k, v])
    return d, p


def write_dict(d):
    return struct.pack("<i", len(d)) + b"".join(struct.pack("<i", len(k)) + k + struct.pack("<i", len(v)) + v for k, v in d)


def trn_frames(c):
    """nTRN: node id, attributes, child, reserved, layer, frame count, frames (dicts with _t "x y z").
    -> (child id, prefix bytes, frame dicts)"""
    attrs, p = read_dict(c, 4)
    child, _, _, nf = struct.unpack_from("<iiii", c, p)
    prefix = c[:p + 16]
    p += 16
    frames = []
    for _ in range(nf):
        d, p = read_dict(c, p)
        frames.append(d)
    return child, prefix, frames


def get_t(frames):
    for kv in frames[0] if frames else []:
        if kv[0] == b"_t":
            return [int(v) for v in kv[1].split()]
    return [0, 0, 0]


def set_t(c, t):
    child, prefix, frames = trn_frames(c)
    for d in frames:
        found = False
        for kv in d:
            if kv[0] == b"_t":
                kv[1] = ("%d %d %d" % tuple(t)).encode()
                found = True
        if not found:
            d.append([b"_t", ("%d %d %d" % tuple(t)).encode()])
    return prefix + b"".join(write_dict(d) for d in frames)


def main():
    mode = sys.argv[1] if len(sys.argv) > 1 else "hollow"
    src = sys.argv[2] if len(sys.argv) > 2 else "assets/vox/terrainpieces/rock1.vox"
    out = sys.argv[3] if len(sys.argv) > 3 else "dev/perftest/rock1_%s.vox" % mode
    os.chdir(REPO)
    make_variant(mode, src, out)


def make_variant(mode, src, out):
    """Writes the variant (paths relative to the current directory)."""
    assert mode in ("hollow", "half"), mode
    b = open(src, "rb").read()
    assert b[:4] == b"VOX "
    n, m = struct.unpack_from("<ii", b, 12)
    o = 20 + n
    chunks = []          # [cid, content, children]
    while o < len(b):
        cid = b[o:o + 4]
        n, m = struct.unpack_from("<ii", b, o + 4)
        chunks.append([cid, b[o + 12:o + 12 + n], b[o + 12 + n:o + 12 + n + m]])
        o += 12 + n + m
    # model index -> its nTRN chunk (nTRN -> nSHP -> model); a model's centre voxel (size // 2 per axis) sits at _t
    shp_model = {}
    for cid, c, ch in chunks:
        if cid == b"nSHP":
            nid = struct.unpack_from("<i", c)[0]
            attrs, p = read_dict(c, 4)
            shp_model[nid] = struct.unpack_from("<i", c, p + 4)[0]
    model_trn = {}
    for k, (cid, c, ch) in enumerate(chunks):
        if cid == b"nTRN":
            child = trn_frames(c)[0]
            if child in shp_model:
                model_trn[shp_model[child]] = k
    filled_in = filled_out = cells_in = cells_out = 0
    model = -1
    orig, out_models = [], []
    for k, (cid, c, ch) in enumerate(chunks):
        if cid == b"TDCZ":
            model += 1
            sx, sy, sz = struct.unpack_from("<iii", c)
            dense = zlib.decompressobj().decompress(c[12:])
            assert len(dense) == sx * sy * sz and chunks[k - 1][0] == b"SIZE"
            if mode == "hollow":
                size, new = hollow(dense, sx, sy, sz)
            else:
                ti = model_trn[model]
                t = get_t(trn_frames(chunks[ti][1])[2])
                lo = [t[i] - (sx, sy, sz)[i] // 2 for i in range(3)]
                size, new = half(dense, sx, sy, sz, lo)
                # half-res first voxel = floor(lo / 2); its centre voxel goes to _t
                chunks[ti][1] = set_t(chunks[ti][1], [lo[i] // 2 + size[i] // 2 for i in range(3)])
                orig.append((dense, (sx, sy, sz), lo))
                out_models.append((new, size, [lo[i] // 2 for i in range(3)]))
            filled_in += sum(1 for v in dense if v)
            filled_out += sum(1 for v in new if v)
            cells_in += sx * sy * sz
            cells_out += size[0] * size[1] * size[2]
            z = zlib.compressobj(9)
            chunks[k][1] = struct.pack("<iii", *size) + z.compress(new) + z.flush(zlib.Z_SYNC_FLUSH)
            chunks[k - 1][1] = struct.pack("<iii", *size)
    if mode == "half":
        check_half(orig, out_models)
    children = b"".join(cid + struct.pack("<ii", len(c), len(ch)) + c + ch for cid, c, ch in chunks)
    data = b[:8] + b"MAIN" + struct.pack("<ii", 0, len(children)) + children
    os.makedirs(os.path.dirname(out), exist_ok=True)
    if os.path.exists(out) and open(out, "rb").read() == data:
        print("%s unchanged" % out)
        return
    open(out, "wb").write(data)
    print("%s -> %s (%s): filled voxels %.2fM -> %.2fM, box cells %.2fM -> %.2fM"
          % (src, out, mode, filled_in / 1e6, filled_out / 1e6, cells_in / 1e6, cells_out / 1e6))


if __name__ == "__main__":
    main()

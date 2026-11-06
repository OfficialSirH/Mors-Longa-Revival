"""Minimal MagicaVoxel .vox reader: returns {object_name: (size, voxels[(x,y,z,colorIndex)], translation)}, palette."""
import struct
def read_vox(path):
    d = open(path,'rb').read()
    assert d[:4] == b'VOX '
    pos = 8
    models, palette, nodes = [], None, {}
    def rstr(b, o):
        n = struct.unpack_from('<i', b, o)[0]; return b[o+4:o+4+n].decode('latin-1'), o+4+n
    def rdict(b, o):
        n = struct.unpack_from('<i', b, o)[0]; o += 4; r = {}
        for _ in range(n):
            k, o = rstr(b, o); v, o = rstr(b, o); r[k] = v
        return r, o
    # walk chunks (MAIN contains children)
    pos = 8 + 12  # skip MAIN header
    size = None
    while pos < len(d):
        cid = d[pos:pos+4]; n, m = struct.unpack_from('<ii', d, pos+4); c = d[pos+12:pos+12+n]; pos += 12+n+m
        if cid == b'SIZE': size = struct.unpack('<iii', c[:12])
        elif cid == b'XYZI':
            k = struct.unpack_from('<i', c, 0)[0]
            vox = [tuple(c[4+4*i:8+4*i]) for i in range(k)]
            models.append((size, vox))
        elif cid == b'RGBA': palette = [tuple(c[4*i:4*i+4]) for i in range(256)]
        elif cid == b'nTRN':
            nid = struct.unpack_from('<i', c, 0)[0]; attr, o = rdict(c, 4)
            child, _res, _layer, nf = struct.unpack_from('<iiii', c, o); o += 16
            fr, o = rdict(c, o)
            nodes[nid] = ('T', attr.get('_name'), child, fr.get('_t'), fr.get('_r'))
        elif cid == b'nSHP':
            nid = struct.unpack_from('<i', c, 0)[0]; attr, o = rdict(c, 4)
            nm = struct.unpack_from('<i', c, o)[0]; o += 4
            mid = struct.unpack_from('<i', c, o)[0]
            nodes[nid] = ('S', mid)
        elif cid == b'nGRP':
            nid = struct.unpack_from('<i', c, 0)[0]; attr, o = rdict(c, 4)
            k = struct.unpack_from('<i', c, o)[0]; nodes[nid] = ('G', list(struct.unpack_from('<%di' % k, c, o+4)))
    objs = {}
    for nid, nd in nodes.items():
        if nd[0] == 'T' and nd[1] is not None and nodes.get(nd[2], (None,))[0] == 'S':
            objs[nd[1]] = (models[nodes[nd[2]][1]], nd[3], nd[4])
    return objs, palette

"""Load a Teardown prefab/vehicle XML into Blender (run inside Blender, e.g. through Blender MCP).

    ns = {}; exec(open(r"C:/Projects/Mors Longa/tools/porting/blender_vehicle.py").read(), ns)
    root = ns["import_vehicle"](r"C:/Projects/Mors Longa/avf/prefabs/humvee/umhummeropen.xml")
    ns["report"](root)                      # every marker's pos relative to its parent part (XML coords)

Everything goes into scene "Teardown", one collection per XML. The XML hierarchy is mirrored as parenting:
group/vehicle/body/wheel/instance -> empties, assets/vox/voxbox -> meshes (exposed faces only, palette colours),
location/light/joint/... -> small empties named "<tag>:<tags or name>". The root empty is rotated +90 deg
about X, so local coordinates under it are Teardown coordinates (x right, y up, -z forward); Blender's Z is up.
Each object keeps the XML attributes as custom properties (prefix "td_").

Assumptions (not checked against the engine): voxel size 0.1 * scale; a vox shape's origin is the bottom
centre of the model, x/z centred with floor(size/2); XML rot = Euler degrees applied Y, then Z, then X
(QuatEuler's documented order).
"""
import math, os, re, struct
import xml.etree.ElementTree as ET
import bpy
from mathutils import Matrix, Quaternion, Vector

REPO = r"C:/Projects/Mors Longa"
TEARDOWN_DATA = r"C:/Program Files (x86)/Steam/steamapps/common/Teardown/data"
MARKERS = {"location", "light", "joint", "rope", "screen", "trigger", "sound", "script", "spawnpoint"}
GROUPS = {"group", "vehicle", "body", "wheel", "compound", "prefab", "instance", "rig"}
_vox_cache = {}


# ---------- MagicaVoxel reader (same format as tools/porting/vox.py, plus scene objects by name) ----------
def rotate_model(size, voxels, r):
    """Apply a scene node's rotation (MagicaVoxel nTRN "_r", a packed 3x3 permutation/sign matrix) to a model,
    as Teardown does for object="...". Without it the UAZ-452 body came out turned 180 degrees and its steering
    wheel lying flat (in-game check 2026-11-08); official vehicle vox files have no node rotations."""
    if not r:
        return size, voxels
    b = int(r)
    i0, i1 = b & 3, (b >> 2) & 3
    i2 = 3 - i0 - i1
    rows = [(i0, -1 if b & 16 else 1), (i1, -1 if b & 32 else 1), (i2, -1 if b & 64 else 1)]
    if [(i, s) for i, s in rows] == [(0, 1), (1, 1), (2, 1)]:
        return size, voxels
    new_size = tuple(size[i] for i, s in rows)
    out = []
    for v in voxels:
        p = []
        for (i, s), n in zip(rows, new_size):
            q = s * (v[i] + 0.5 - size[i] / 2.0) + n / 2.0 - 0.5  # rotate about the model centre
            p.append(int(round(q)))
        out.append((p[0], p[1], p[2], v[3]))
    return new_size, out



def crop_model(size, voxels):
    """Drop empty voxel layers around a model, as the engine does (x and depth centres then follow the cropped size).
    Found 2026-11-08: the Jeep Wrangler body has 3 empty layers underneath, seats measured on the full model sat
    0.3 m too high in-game and 0.3 lower was right; the ZIL-131 body has 38 empty layers at one end, and only
    cropped does its cab line up with its own steering wheel and v1 eye point (the full model puts it 1.9 m off)."""
    if not voxels:
        return size, voxels
    lo = [min(v[i] for v in voxels) for i in range(3)]
    hi = [max(v[i] for v in voxels) for i in range(3)]
    return tuple(hi[i] - lo[i] + 1 for i in range(3)), [(v[0] - lo[0], v[1] - lo[1], v[2] - lo[2], v[3]) for v in voxels]


CROP_EMPTY = True


def read_vox(path):
    if path in _vox_cache:
        return _vox_cache[path]
    d = open(path, "rb").read()
    assert d[:4] == b"VOX ", path

    def rstr(b, o):
        n = struct.unpack_from("<i", b, o)[0]
        return b[o + 4:o + 4 + n].decode("latin-1"), o + 4 + n

    def rdict(b, o):
        n = struct.unpack_from("<i", b, o)[0]; o += 4; r = {}
        for _ in range(n):
            k, o = rstr(b, o); v, o = rstr(b, o); r[k] = v
        return r, o

    models, palette, nodes, size, pos = [], None, {}, None, 20
    while pos < len(d):
        cid = d[pos:pos + 4]; n, m = struct.unpack_from("<ii", d, pos + 4); c = d[pos + 12:pos + 12 + n]
        pos += 12 + n + m
        if cid == b"SIZE":
            size = struct.unpack("<iii", c[:12])
        elif cid == b"XYZI":
            k = struct.unpack_from("<i", c, 0)[0]
            models.append((size, [tuple(c[4 + 4 * i:8 + 4 * i]) for i in range(k)]))
        elif cid == b"RGBA":
            palette = [tuple(c[4 * i:4 * i + 4]) for i in range(256)]
        elif cid == b"nTRN":
            nid = struct.unpack_from("<i", c, 0)[0]; attr, o = rdict(c, 4)
            child, _res, _layer, _nf = struct.unpack_from("<iiii", c, o); o += 16
            frame, o = rdict(c, o)
            nodes[nid] = ("T", attr.get("_name"), child, frame.get("_r"))
        elif cid == b"nSHP":
            nid = struct.unpack_from("<i", c, 0)[0]; attr, o = rdict(c, 4)
            nodes[nid] = ("S", struct.unpack_from("<i", c, o + 4)[0])
    named = {}
    for nd in nodes.values():
        if nd[0] == "T" and nd[1] is not None and nodes.get(nd[2], ("",))[0] == "S":
            size, vox = models[nodes[nd[2]][1]]
            named[nd[1]] = rotate_model(size, vox, nd[3])
            if CROP_EMPTY:
                named[nd[1]] = crop_model(*named[nd[1]])
    if CROP_EMPTY:
        models = [crop_model(sz, vs) for sz, vs in models]
    if palette is None:
        palette = [(200, 200, 200, 255)] * 256
    _vox_cache[path] = (models, named, palette)
    return _vox_cache[path]


# ---------- helpers ----------
def resolve(path, base_dir):
    if path.startswith("MOD/"):
        return os.path.join(REPO, path[4:])
    if path.startswith("BUILT-IN/"):
        return os.path.join(TEARDOWN_DATA, "built-in", path[9:])
    if path.startswith("LEVEL/"):
        return None
    p = os.path.join(base_dir, path)
    if not os.path.exists(p):  # engine prefabs (e.g. data/prefab/player) name vox files relative to data/vox
        p = os.path.join(TEARDOWN_DATA, "vox", path)
    return p


def _num(x):
    """Leading number of x, like C atof (the GAZ-24 XML has rot="0.0 0.0 3a.0")."""
    m = re.match(r"[+-]?(\d+\.?\d*|\.\d+)([eE][+-]?\d+)?", x)
    return float(m.group(0)) if m else 0.0


def floats(s, n, default=0.0):
    v = [_num(x) for x in (s or "").split()] if s else []
    return (v + [default] * n)[:n]


def local_matrix(el):
    x, y, z = floats(el.get("pos"), 3)
    rx, ry, rz = (math.radians(a) for a in floats(el.get("rot"), 3))
    rot = Matrix.Rotation(ry, 4, "Y") @ Matrix.Rotation(rz, 4, "Z") @ Matrix.Rotation(rx, 4, "X")
    return Matrix.Translation((x, y, z)) @ rot


def new_obj(name, data, parent, coll, el=None):
    ob = bpy.data.objects.new(name[:63], data)
    coll.objects.link(ob)
    if parent is not None:
        ob.parent = parent
    if el is not None:
        ob.matrix_parent_inverse = Matrix.Identity(4)
        ob.matrix_basis = local_matrix(el)
        ob["td_element"] = el.tag
        for k, v in el.attrib.items():
            ob["td_" + k] = v
    return ob


def color_material():
    mat = bpy.data.materials.get("td_voxel")
    if mat is None:
        mat = bpy.data.materials.new("td_voxel")
        mat.use_nodes = True
        nt = mat.node_tree
        bsdf = next(n for n in nt.nodes if n.type == "BSDF_PRINCIPLED")
        attr = nt.nodes.new("ShaderNodeAttribute"); attr.attribute_name = "td_color"
        nt.links.new(attr.outputs[0], bsdf.inputs[0])
    return mat


FACES = [  # (neighbour offset in voxel space, 4 corner offsets)
    ((1, 0, 0), [(1, 0, 0), (1, 1, 0), (1, 1, 1), (1, 0, 1)]),
    ((-1, 0, 0), [(0, 0, 0), (0, 0, 1), (0, 1, 1), (0, 1, 0)]),
    ((0, 1, 0), [(0, 1, 0), (0, 1, 1), (1, 1, 1), (1, 1, 0)]),
    ((0, -1, 0), [(0, 0, 0), (1, 0, 0), (1, 0, 1), (0, 0, 1)]),
    ((0, 0, 1), [(0, 0, 1), (1, 0, 1), (1, 1, 1), (0, 1, 1)]),
    ((0, 0, -1), [(0, 0, 0), (0, 1, 0), (1, 1, 0), (1, 0, 0)]),
]


def voxel_mesh(name, size, voxels, palette, scale):
    """voxels: (x, y, z, colour index) in MagicaVoxel space (z up). Output in Teardown shape space."""
    filled = {(v[0], v[1], v[2]): v[3] for v in voxels}
    cx, cy, s = size[0] // 2, size[1] // 2, 0.1 * scale
    verts, vidx, faces, cols = [], {}, [], []
    for (x, y, z), ci in filled.items():
        for (dx, dy, dz), corners in FACES:
            if (x + dx, y + dy, z + dz) in filled:
                continue
            f = []
            for ox, oy, oz in corners:
                key = (x + ox, y + oy, z + oz)
                if key not in vidx:
                    vidx[key] = len(verts)
                    # MagicaVoxel (x, y, z-up) -> Teardown (x, y-up, -z forward)
                    verts.append(((key[0] - cx) * s, key[2] * s, -(key[1] - cy) * s))
                f.append(vidx[key])
            faces.append(f[::-1])  # winding flips with the y/z swap
            c = palette[ci - 1]
            cols.append((c[0] / 255, c[1] / 255, c[2] / 255, 1.0))
    me = bpy.data.meshes.new(name[:63])
    me.from_pydata(verts, [], faces)
    attr = me.color_attributes.new("td_color", "FLOAT_COLOR", "CORNER")
    for poly, c in zip(me.polygons, cols):
        for li in poly.loop_indices:
            attr.data[li].color = c
    me.materials.append(color_material())
    me.update()
    return me


def marker_name(el):
    label = el.get("tags") or el.get("name") or ""
    return "%s:%s" % (el.tag, label.split()[0] if label else "")


def build(el, parent, coll, base_dir, depth=0, inherit=None):
    """inherit: default attributes from ancestor <group prop0="file=..." prop1="brush=...">, which Teardown applies
    to descendants that don't set them (the Volga/GAZ-24 road cars name their .vox file only there)."""
    tag = el.tag
    inherit = dict(inherit or {})
    for k, v in el.attrib.items():
        if re.fullmatch(r"prop\d+", k) and "=" in v:
            key, val = v.split("=", 1)
            inherit[key.strip()] = val.strip()
    for k, v in inherit.items():
        if k not in el.attrib and tag in ("vox", "voxbox"):
            el.set(k, v)
    if tag == "vox":
        f = resolve(el.get("file", ""), base_dir)
        if f is None or not os.path.exists(f):
            print("missing vox", el.get("file"))
            ob = new_obj("vox:missing", None, parent, coll, el)
        else:
            models, named, pal = read_vox(f)
            objname = el.get("object")
            model = named.get(objname) if objname else models[0]
            if model is None:
                print("missing object", objname, "in", el.get("file"))
                ob = new_obj("vox:missing " + str(objname), None, parent, coll, el)
            else:
                label = "vox:" + (objname or os.path.basename(f))
                sc = floats(el.get("scale"), 1, 1.0)[0]
                ob = new_obj(label, voxel_mesh(label, model[0], model[1], pal, sc), parent, coll, el)
    elif tag == "voxbox":
        sx, sy, sz = floats(el.get("size"), 3, 1.0)
        me = bpy.data.meshes.new("voxbox")
        s = 0.1
        v = [(x * sx * s, y * sy * s, z * sz * s) for x in (0, 1) for y in (0, 1) for z in (0, 1)]
        me.from_pydata(v, [], [(0, 1, 3, 2), (4, 6, 7, 5), (0, 4, 5, 1), (2, 3, 7, 6), (0, 2, 6, 4), (1, 5, 7, 3)])
        me.materials.append(color_material())
        ob = new_obj("voxbox", me, parent, coll, el)
    elif tag in MARKERS:
        ob = new_obj(marker_name(el), None, parent, coll, el)
        ob.empty_display_type = "ARROWS" if tag in ("location", "light") else "SPHERE"
        ob.empty_display_size = 0.25
        ob.show_name = tag == "location" or "seat" in (el.get("tags") or "")
    else:
        label = tag + (":" + el.get("name") if el.get("name") else "")
        ob = new_obj(label, None, parent, coll, el)
        ob.empty_display_size = 0.1
    if tag == "instance" and depth < 8:
        f = resolve(el.get("file", ""), base_dir)
        if f and os.path.exists(f):
            sub = ET.parse(f).getroot()
            build(sub, ob, coll, os.path.dirname(f), depth + 1)
        else:
            print("missing instance", el.get("file"))
    for child in el:
        build(child, ob, coll, base_dir, depth, inherit)
    return ob


def import_vehicle(xml_path, clear=True, name=None):
    xml_path = os.path.normpath(xml_path)
    scene = bpy.data.scenes.get("Teardown") or bpy.data.scenes.new("Teardown")
    bpy.context.window.scene = scene
    cname = (name or os.path.splitext(os.path.basename(xml_path))[0])[:63]
    coll = bpy.data.collections.get(cname)
    if coll and clear:
        for ob in list(coll.objects):
            bpy.data.objects.remove(ob, do_unlink=True)
    if coll is None:
        coll = bpy.data.collections.new(cname)
        scene.collection.children.link(coll)
    root = new_obj("TD:" + cname, None, None, coll)
    root.rotation_euler = (math.radians(90), 0, 0)  # Teardown y-up -> Blender z-up
    root["td_file"] = xml_path
    build(ET.parse(xml_path).getroot(), root, coll, os.path.dirname(xml_path))
    bpy.context.view_layer.update()
    for area in bpy.context.screen.areas:
        if area.type == "VIEW_3D":
            for ct in ("ATTRIBUTE", "VERTEX"):  # the name differs between Blender versions
                try:
                    area.spaces[0].shading.color_type = ct
                    break
                except TypeError:
                    pass
    return root


def td_part(ob):
    """Nearest ancestor that is a assets/vox/body/wheel/vehicle (what an XML child's pos is relative to)."""
    p = ob.parent
    while p is not None and p.get("td_element") not in ("vox", "voxbox", "body", "wheel", "vehicle", "group"):
        p = p.parent
    return p


def td_pos(ob, relative_to=None):
    """Position of ob in relative_to's local frame (Teardown XML coordinates), rounded to 1 cm."""
    rel = relative_to or td_part(ob)
    m = rel.matrix_world.inverted() @ ob.matrix_world
    return tuple(round(c, 2) for c in m.translation)


def report(root):
    for ob in sorted(root.children_recursive, key=lambda o: o.name):
        if ob.get("td_element") in MARKERS:
            part = td_part(ob)
            print("%-28s in %-22s pos %s" % (ob.name, part.name if part else "-", td_pos(ob, part)))


# ---------- seat measuring (all positions in vehicle coordinates = the <vehicle> element's frame) ----------
def vehicle_of(root):
    return next(o for o in root.children_recursive if o.get("td_element") == "vehicle")


def show_only(root):
    """Hide every other imported vehicle: ray casts and pictures then see only this one."""
    keep = root.users_collection[0]
    for c in bpy.context.scene.collection.children:
        if c.name == "rig_preview":
            continue
        c.hide_viewport = c != keep
        for o in c.objects:
            o.hide_set(c != keep or o.name.startswith("TD_cut:"))  # cutaway boxes always stay hidden
    bpy.context.view_layer.update()


def vehicle_markers(root):
    """Print every location/light in vehicle coordinates."""
    veh = vehicle_of(root)
    for ob in sorted(root.children_recursive, key=lambda o: o.name):
        if ob.get("td_element") in ("location", "light"):
            print("%-24s %s" % (ob.name, td_pos(ob, veh)))


def ray(root, origin, direction):
    """Distance from origin (vehicle coords) to the first surface along direction, or None."""
    veh = vehicle_of(root)
    m = veh.matrix_world
    dg = bpy.context.evaluated_depsgraph_get()
    hit, loc, n, i, ob, mm = bpy.context.scene.ray_cast(
        dg, m @ Vector(origin), (m.to_3x3() @ Vector(direction)).normalized())
    if not hit:
        return None
    return round(((m.inverted() @ loc) - Vector(origin)).length, 3)


def heightmap(root, top, x0, x1, z0, z1, step=0.1):
    """Surface height below `top` on a grid (rows z, front = negative z first; columns x). '.' = nothing below.
    Sample at voxel centres: pass x0/z0 like -0.95 (half-voxel offsets) so rays don't run along voxel edges."""
    xs = [round(x0 + step * i, 3) for i in range(int(round((x1 - x0) / step)) + 1)]
    print("  z / x " + " ".join("%5.2f" % x for x in xs))
    z = z0
    while z <= z1 + 1e-6:
        row = []
        for x in xs:
            d = ray(root, (x, top, z), (0, -1, 0))
            row.append("%5.2f" % (top - d) if d is not None else "    .")
        print("%7.2f " % z + " ".join(row))
        z = round(z + step, 3)


def cutaway(root, y=None):
    """Cut away everything above height y (vehicle coords) so the cabin can be seen from above; y=None removes it."""
    coll = root.users_collection[0]
    name = "TD_cut:" + coll.name
    cutter = bpy.data.objects.get(name)
    for ob in coll.objects:
        if ob.type == "MESH":
            for md in [m for m in ob.modifiers if m.name == "td_cut"]:
                ob.modifiers.remove(md)
    if y is None:
        if cutter:
            bpy.data.objects.remove(cutter, do_unlink=True)
        return
    if cutter is None:
        me = bpy.data.meshes.new(name)
        s = 20.0
        v = [(a * s, b * s, c * s) for a in (-1, 1) for b in (0, 2) for c in (-1, 1)]
        me.from_pydata(v, [], [(0, 1, 3, 2), (4, 6, 7, 5), (0, 4, 5, 1), (2, 3, 7, 6), (0, 2, 6, 4), (1, 5, 7, 3)])
        cutter = bpy.data.objects.new(name, me)
        coll.objects.link(cutter)
    cutter.parent = vehicle_of(root)
    cutter.matrix_parent_inverse = Matrix.Identity(4)
    cutter.matrix_basis = Matrix.Translation((0, y, 0))
    cutter.hide_set(True)
    for ob in coll.objects:
        if ob.type == "MESH" and ob != cutter:
            md = ob.modifiers.new("td_cut", "BOOLEAN")
            md.operation = "DIFFERENCE"
            md.object = cutter
    bpy.context.view_layer.update()


# ---------- seat mannequin: the official player character posed on a seat rig ----------
# Approximation of the engine's pose (data/script/player_locomotion.lua): pelvis on the rig's "seat" location,
# body turned by the seat's rotation, facing the vehicle's forward (-z); arms and legs bent by Blender IK toward
# the rig's ik_hand_* / ik_foot_* points (elbows down, knees up). The game's animation and IK differ in detail: use it
# to catch clear misses (back through a backrest, head through the roof, hands that cannot reach), not centimetres.
CHARACTER = TEARDOWN_DATA + "/prefab/player/player_sven_lagom.xml"
BONES = [  # (bone, child bone for the tail or a tail offset, parent)
    ("pelvis", "stomach", None), ("stomach", "chest", "pelvis"), ("chest", "neck", "stomach"),
    ("neck", "head", "chest"), ("head", (0, 0.25, 0), "neck"),
    ("shoulder_l", "arm_upper_l", "chest"), ("arm_upper_l", "arm_lower_l", "shoulder_l"),
    ("arm_lower_l", "hand_l", "arm_upper_l"), ("hand_l", (0.12, 0, 0), "arm_lower_l"),
    ("shoulder_r", "arm_upper_r", "chest"), ("arm_upper_r", "arm_lower_r", "shoulder_r"),
    ("arm_lower_r", "hand_r", "arm_upper_r"), ("hand_r", (-0.12, 0, 0), "arm_lower_r"),
    ("leg_upper_l", "leg_lower_l", "pelvis"), ("leg_lower_l", "foot_l", "leg_upper_l"),
    ("foot_l", "toes_l", "leg_lower_l"),
    ("leg_upper_r", "leg_lower_r", "pelvis"), ("leg_lower_r", "foot_r", "leg_upper_r"),
    ("foot_r", "toes_r", "leg_lower_r"),
]


def chain(ob, upto=None):
    """ob's matrix relative to ancestor `upto` (world if None), from the objects' own transforms: valid right after
    import, unlike matrix_world (which Blender only fills in when the scene is evaluated)."""
    m = Matrix.Identity(4)
    while ob is not None and ob != upto:
        m = ob.matrix_parent_inverse @ ob.matrix_basis @ m
        ob = ob.parent
    return m


def mannequin(root, rig_name_or_obj, character=CHARACTER):
    """Seat the official player character on one rig of an imported vehicle. rig: the rig object or its tags
    (e.g. "driver sort=0", "sort=1"). Returns the armature. Re-running replaces that rig's mannequin."""
    coll = root.users_collection[0]
    veh = vehicle_of(root)
    rig = rig_name_or_obj if not isinstance(rig_name_or_obj, str) else next(
        o for o in root.children_recursive if o.get("td_element") == "rig" and o.get("td_tags") == rig_name_or_obj)
    key = "MQ:%s:%s" % (coll.name, rig.get("td_tags"))
    for ob in [o for o in bpy.data.objects if o.get("td_mq") == key]:
        bpy.data.objects.remove(ob, do_unlink=True)

    # 1. import the character (standing bind pose), read bone positions in its prefab frame (Teardown coords)
    croot = import_vehicle(character, name="_mq_tmp")
    tmp = croot.users_collection[0]
    bodies = {o.get("td_name"): o for o in croot.children_recursive if o.get("td_element") == "body"}
    pos = {n: chain(o, croot).translation.copy() for n, o in bodies.items()}

    # 2. place: seat transform (vehicle coords) * turn 180 (the model faces +z, vehicles face -z) * pelvis at origin
    seat = next(c for c in rig.children if c.get("td_name") == "seat")
    veh_w = chain(veh)
    seat_m = chain(seat, veh)
    # engine (player_locomotion.lua): animator root = seat - R * pelvis offset; then, if the seat is tilted, the body
    # is eased toward upright by weight cos^2(tilt) about a pivot 0.8 m above the root (rot x 50 -> ~29 deg recline)
    turn = Matrix.Rotation(math.pi, 3, "Y")  # the prefab faces +z, the engine's animator faces -z
    R = seat_m.to_quaternion()
    root_p = seat_m.translation - R @ (turn @ pos["pelvis"])
    up = R @ Vector((0, 1, 0))
    if up.y > 0:
        pivot = root_p + R @ Vector((0, 0.8, 0))
        R2 = R.slerp(up.rotation_difference(Vector((0, 1, 0))) @ R, up.y * up.y)
        root_p = pivot - R2 @ Vector((0, 0.8, 0))
        R = R2
    place = veh_w @ Matrix.Translation(root_p) @ (R.to_matrix() @ turn).to_4x4()

    # 3. armature in the prefab frame
    arm_data = bpy.data.armatures.new(key)
    arm = bpy.data.objects.new(key, arm_data)
    coll.objects.link(arm)
    arm["td_mq"] = key
    arm.matrix_world = place
    arm.show_in_front = True
    bpy.context.view_layer.objects.active = arm
    for o in bpy.context.selected_objects:
        o.select_set(False)
    arm.hide_set(False)
    arm.select_set(True)
    bpy.ops.object.mode_set(mode="EDIT")
    eb = arm_data.edit_bones
    for name, tail, parent in BONES:
        b = eb.new(name)
        b.head = pos[name]
        b.tail = pos[tail] if isinstance(tail, str) else pos[name] + Vector(tail)
        if parent:
            b.parent = eb[parent]
            b.use_connect = False
    bpy.ops.object.mode_set(mode="OBJECT")

    # 4. move the character's voxel parts onto the bones (rest pose), into the vehicle's collection
    bone_of = {}
    for ob in croot.children_recursive:
        if ob.type != "MESH":
            continue
        p = ob.parent
        while p is not None and p.get("td_element") != "body":
            p = p.parent
        name = p.get("td_name") if p else None
        if name not in {b[0] for b in BONES}:  # toes have no bone: they ride on the foot; anything else on the pelvis
            name = {"toes_l": "foot_l", "toes_r": "foot_r"}.get(name, "pelvis")
        bone_of[ob] = (name, chain(ob, croot))
    bpy.context.view_layer.update()
    for ob, (bone, local) in bone_of.items():
        world = place @ local
        ob.parent = arm
        ob.parent_type = "BONE"
        ob.parent_bone = bone
        ob.matrix_world = world
        ob["td_mq"] = key
        for c in list(ob.users_collection):
            c.objects.unlink(ob)
        coll.objects.link(ob)
    for ob in list(tmp.objects):
        bpy.data.objects.remove(ob, do_unlink=True)
    bpy.data.collections.remove(tmp)

    # 5. IK: hands and feet to the rig's points, poles for elbows (down/back) and knees (up/forward)
    def target(name):
        return next((c for c in rig.children if c.get("td_name") == name), None)

    def pole(name, offset):
        e = bpy.data.objects.new("%s:%s" % (key, name), None)
        coll.objects.link(e)
        e["td_mq"] = key
        e.matrix_world = veh_w @ seat_m @ Matrix.Translation(offset)
        e.hide_set(True)
        return e

    pb = arm.pose.bones
    for side, sx in (("l", -1), ("r", 1)):
        # pole angles checked by the knee/elbow position against the hip-foot / shoulder-hand line: -90 bent the
        # knees backward (seen in the 2026-11-08 screenshots); +90 bends them up and forward. Elbows: -90 (down, out).
        for bone, tname, pole_off, chain_len, pole_angle in (
                ("arm_lower_" + side, "ik_hand_" + side, (sx * 0.6, 0.1, 0.6), 2, -90),
                ("leg_lower_" + side, "ik_foot_" + side, (sx * 0.15, 1.0, -1.5), 2, 90)):
            t = target(tname)
            if t is None:
                continue
            c = pb[bone].constraints.new("IK")
            c.target = t
            c.pole_target = pole(bone + "_pole", Vector(pole_off))
            c.pole_angle = math.radians(pole_angle)
            c.chain_count = chain_len
    # head: the engine bends the spine so the head reaches the rig's ik_head (SetAnimatorTransformIK "stomach" to
    # "head"); without it a reclined seat (official rot x 70-80) lays the whole mannequin back, unlike in-game
    t = target("ik_head")
    if t is not None:
        c = pb["neck"].constraints.new("IK")
        c.target = t
        c.chain_count = 3  # neck, chest, stomach
        c.use_tail = True  # neck tail = head bone's root, the point the engine places
    bpy.context.view_layer.update()
    return arm


def mannequins(root):
    """A mannequin on every rig of the vehicle."""
    rigs = [o for o in root.children_recursive if o.get("td_element") == "rig"]
    return [mannequin(root, r) for r in sorted(rigs, key=lambda o: o.get("td_tags"))]


# ---------- NPC mannequin: the Friendly Merc ragdoll in GoreNPCs' sit pose ----------
MERC = REPO + "/prefabs/spawnables/enemies/security/Ragdollsecurity2.xml"
# RagdollPoses.sit (npcs/GoreNPCs/scripts/other/RagdollPoseReader.lua): body transforms relative to the Head body,
# (pos, quat x y z w). npc_pose_ragdoll pins each ragdoll body there, relative to the head transform it is given.
SIT_POSE = {
    "Torso": ((0, -0.7, 0), (0, 0, 0, 1)),
    "Head": ((0, 0, 0), (0, 0, 0, 1)),
    "LARM": ((-0.25, -0.1, 0), (0.41616, -0.31021, -0.07309, 0.85161)),
    "LLARM": ((-0.28958, -0.25461, -0.273), (0.41616, -0.31021, -0.07309, 0.85161)),
    "RARM": ((0.25, -0.1, 0), (0.41616, 0.31021, 0.07309, 0.85161)),
    "RRARM": ((0.28958, -0.25461, -0.273), (0.41616, 0.31021, 0.07309, 0.85161)),
    "LLLEG": ((-0.15, -1.05, -0.35), (0, 0, 0, 1)),
    "LLEG": ((-0.15, -0.6, 0), (0.76604, 0, 0, 0.64279)),
    "RRLEG": ((0.15, -1.05, -0.35), (0, 0, 0, 1)),
    "RLEG": ((0.15, -0.6, 0), (0.76604, 0, 0, 0.64279)),
}


def td_transform(pos, quat):
    x, y, z, w = quat
    return Matrix.Translation(pos) @ Quaternion((w, x, y, z)).to_matrix().to_4x4()


def ragdoll_bodies(xml_path):
    """Bodies of a GoreNPCs ragdoll prefab: [(pose key, body matrix in prefab space, [(vox element, file, matrix
    relative to the body)])]. Follows <instance> files (their own top group's transform is not applied: the
    ragdoll parts store their placement both on the <instance> and on that group) and prefab parameters
    (propN="file=..." on a group gives the vox file to the parts below it)."""
    out = []

    def walk(el, M, base, params, cur, top=False):
        params = dict(params)
        for k, v in el.attrib.items():
            if re.fullmatch(r"prop\d+", k) and "=" in v:
                a, b = v.split("=", 1)
                params[a] = b
        M2 = M if top else M @ local_matrix(el)
        if el.tag == "body":
            words = (el.get("tags") or "").split()
            key = el.get("name") if el.get("name") == "Torso" else next((w for w in words if w in SIT_POSE), None)
            cur = (key, M2, [])
            out.append(cur)
        elif el.tag == "vox" and cur is not None:
            f = el.get("file") or params.get("file")
            cur[2].append((el, resolve(f, base) if f else None, cur[1].inverted() @ M2))
        if el.tag == "instance":
            f = resolve(el.get("file", ""), base)
            sub = ET.parse(f).getroot()
            for g in sub:
                walk(g, M2, os.path.dirname(f), params, cur, top=True)
        for c in el:
            walk(c, M2, base, params, cur)

    root = ET.parse(xml_path).getroot()
    for g in root:
        walk(g, Matrix.Identity(4), os.path.dirname(xml_path), {}, None, top=True)
    return [b for b in out if b[0]]


def merc(root, rig_name_or_obj, head=None, xml_path=MERC):
    """Pose the Friendly Merc on one rig the way the game does (npc_pose_ragdoll + RagdollPoses.sit). head: the
    head transform in vehicle coords (a Matrix); default: npc_head(rig), the Python copy of goreai_sitting.lua."""
    coll = root.users_collection[0]
    veh = vehicle_of(root)
    rig = rig_name_or_obj if not isinstance(rig_name_or_obj, str) else next(
        o for o in root.children_recursive if o.get("td_element") == "rig" and o.get("td_tags") == rig_name_or_obj)
    key = "NPC:%s:%s" % (coll.name, rig.get("td_tags"))
    for ob in [o for o in bpy.data.objects if o.get("td_npc") == key]:
        bpy.data.objects.remove(ob, do_unlink=True)
    H = head if head is not None else npc_head(rig, veh)
    pose = npc_pose(rig, veh, H)
    veh_w = chain(veh)
    for k, _M, parts in ragdoll_bodies(xml_path):
        body_w = veh_w @ H @ pose[k]
        for el, f, local in parts:
            if not f or not os.path.exists(f):
                continue
            models, named, pal = read_vox(f)
            model = named.get(el.get("object")) if el.get("object") else models[0]
            if model is None:
                continue
            ob = bpy.data.objects.new("%s:%s" % (key, k), voxel_mesh(key + k, model[0], model[1], pal, 1.0))
            coll.objects.link(ob)
            ob.matrix_world = body_w @ local
            ob["td_npc"] = key
    bpy.context.view_layer.update()
    return key


def player_seat(rig, veh):
    """(pelvis point, body rotation) of a seated player, vehicle coords: the engine rule (player_locomotion.lua),
    same as mannequin(). The pelvis is the seat point; the rotation is the seat's, eased toward upright."""
    seat = next(c for c in rig.children if c.get("td_name") == "seat")
    seat_m = chain(seat, veh)
    R = seat_m.to_quaternion()
    pelvis = seat_m.translation.copy()
    up = R @ Vector((0, 1, 0))
    if up.y > 0:
        R2 = R.slerp(up.rotation_difference(Vector((0, 1, 0))) @ R, up.y * up.y)
        # the engine rotates about a pivot 0.8 m above the animator root (root = pelvis - R * pelvis offset)
        pelvis_off = Vector(PELVIS)
        root_p = pelvis - R @ pelvis_off
        pivot = root_p + R @ Vector((0, 0.8, 0))
        root_p = pivot - R2 @ Vector((0, 0.8, 0))
        pelvis = root_p + R2 @ pelvis_off
        R = R2
    return pelvis, R


PELVIS = (0, 0.875, 0.05)  # player prefab pelvis (player_pelvis_y()), turned 180 like mannequin()


def player_pelvis_y(character=CHARACTER):
    croot = import_vehicle(character, name="_mq_tmp")
    tmp = croot.users_collection[0]
    p = next(o for o in croot.children_recursive if o.get("td_element") == "body" and o.get("td_name") == "pelvis")
    v = chain(p, croot).translation.copy()
    for ob in list(tmp.objects):
        bpy.data.objects.remove(ob, do_unlink=True)
    bpy.data.collections.remove(tmp)
    return v


def npc_head(rig, veh):
    """Python copy of get_seat_head_transform (npcs/GoreNPCs/scripts/systems/goreai_sitting.lua): the NPC sits like the
    player (player_seat: pelvis point and eased lean), head placed NPC_HEAD_OFFSET from the pelvis in that frame."""
    pel, R = player_seat(rig, veh)
    ik = next((c for c in rig.children if c.get("td_name") == "ik_head"), None)
    if ik is not None:  # lean about the hips toward ik_head + NPC_HEAD_AIM (the engine IKs the player's head there)
        rt = chain(rig, veh).to_quaternion()
        hip = pel + rt @ Vector((0, NPC_HEAD_OFFSET[1] - 0.6, NPC_HEAD_OFFSET[2]))
        aim = chain(ik, veh).translation + rt @ Vector(NPC_HEAD_AIM)
        d = rt.inverted() @ (aim - hip)
        lean = max(0.0, math.atan2(d.z, d.y))
        rot = rt @ Quaternion((1, 0, 0), lean)
        return Matrix.Translation(hip + rot @ Vector((0, 0.6, 0))) @ rot.to_matrix().to_4x4()
    return Matrix.Translation(pel) @ R.to_matrix().to_4x4() @ Matrix.Translation(NPC_HEAD_OFFSET)


NPC_HEAD_AIM = (0, -0.15, -0.05)  # SeatHeadAim in goreai_sitting.lua


NPC_HEAD_OFFSET = (0, 0.65, 0.1)  # SeatHeadOffset in goreai_sitting.lua


def npc_pose(rig, veh, H):
    """Python copy of npc_sitting_pose (goreai_sitting.lua): {key: body matrix relative to the head}. The legs keep
    the sit pose from the same hip, upright with the vehicle, tilted up toward the rig's ik_foot points (at most 60
    deg)."""
    pose = {k: td_transform(*v) for k, v in SIT_POSE.items()}
    rt = chain(rig, veh).to_quaternion()
    hr = H.to_quaternion()
    lean = math.degrees((hr @ Vector((0, 1, 0))).angle(rt @ Vector((0, 1, 0))))
    if lean < 1:
        return pose
    hip = H @ Vector((0, -0.6, 0))
    feet = [chain(c, veh).translation for c in rig.children if c.get("td_name") in ("ik_foot_l", "ik_foot_r")]
    tilt = 0.0
    if feet:
        d = rt.inverted() @ (sum(feet, Vector()) / len(feet) - hip)
        tilt = math.degrees(math.atan2(0.45, 0.35) - math.atan2(-d.y, -d.z))
        tilt = max(0.0, min(60.0, tilt))
    leg_rot = rt @ Quaternion((1, 0, 0), math.radians(tilt))
    leg_head = Matrix.Translation(hip + leg_rot @ Vector((0, 0.6, 0))) @ leg_rot.to_matrix().to_4x4()
    for k in ("LLEG", "LLLEG", "RLEG", "RRLEG"):
        pose[k] = H.inverted() @ leg_head @ td_transform(*SIT_POSE[k])
    return pose

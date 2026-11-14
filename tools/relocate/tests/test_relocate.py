"""Fixture tests for tools/relocate/relocate.py. Run: python tools/relocate/tests/test_relocate.py"""
import hashlib, os, shutil, sys, tempfile

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
import relocate as R

FILES = {
    # engine-known level with a LEVEL folder, and one without
    "main.xml": '<scene version="1.6.0">\n<vox file="LEVEL/terrain.vox"/>\n<script file="fx.lua"/>\n</scene>\n',
    "main/terrain.vox": None,
    "level.xml": '<scene version="1.6.0">\n<instance file="MOD/prefabs/car.xml"/>\n</scene>\n',
    "lib.lua": "-- library\nfunction Lib() end\n",
    "scripts/a/b.lua": ('#version 2\n#include "../../lib.lua"\n#include "script/include/player.lua"\n'
                        '#include "c.lua"\n#include ../../lib.lua\n'
                        'local s = LoadSound("MOD/snd/x.ogg")\n'
                        'local d = LoadSound("MOD/snd/" .. name .. ".ogg")\n'
                        'local e = LoadSound("snd/x.ogg") -- engine path: data/snd/x.ogg\n'
                        '-- see scripts/a/c.lua and vox/\n'
                        'local m = "MOD/vox/missing.vox"\n'),
    "scripts/a/c.lua": "function C() end\n",
    "snd/x.ogg": None,
    "snd/sub/y.ogg": None,
    "vox/a.vox": None,
    "vox/a&b.vox": None,
    "vehicles/car one.xml": '<prefab><vehicle/></prefab>\n',
    "prefabs/car.xml": ('<prefab>\n<vox file="MOD/vox/a.vox"/>\n<vox file="MOD/VOX/A.VOX"/>\n'
                        '<vox file="MOD\\vox\\a.vox"/>\n<vox file="MOD/vox/a&amp;b.vox"/>\n'
                        '<group name="instance=MOD/vehicles/car one.xml" prop0="file=MOD/vox/a.vox"/>\n'
                        '<body tags="path=MOD/vehicles/car one.xml other"/>\n</prefab>\n'),
    "docs/readme.md": "See `scripts/a/b.lua` and the `snd/` folder, MOD/vox/a.vox.\n",
    "tools/t.lua": 'MockEngine.load("scripts/a/b.lua")\n',
}
DATA = {"script/include/player.lua": "", "script/fx.lua": "", "snd/x.ogg": ""}

EXPECT_AFTER = {   # moves below
    "code/scripts/a/b.lua": ('#version 2\n#include "../../../lib/lib.lua"\n#include "script/include/player.lua"\n'
                             '#include "c.lua"\n#include ../../../lib/lib.lua\n'
                             'local s = LoadSound("MOD/assets/snd/x.ogg")\n'
                             'local d = LoadSound("MOD/assets/snd/" .. name .. ".ogg")\n'
                             'local e = LoadSound("snd/x.ogg") -- engine path: data/snd/x.ogg\n'
                             '-- see code/scripts/a/c.lua and assets/vox/\n'
                             'local m = "MOD/vox/missing.vox"\n'),
    "prefabs/car.xml": ('<prefab>\n<vox file="MOD/assets/vox/a.vox"/>\n<vox file="MOD/assets/vox/a.vox"/>\n'
                        '<vox file="MOD\\assets/vox/a.vox"/>\n<vox file="MOD/assets/vox/a&amp;b.vox"/>\n'
                        '<group name="instance=MOD/vehicles/car one.xml" prop0="file=MOD/assets/vox/a.vox"/>\n'
                        '<body tags="path=MOD/vehicles/car one.xml other"/>\n</prefab>\n'),
    "docs/readme.md": "See `code/scripts/a/b.lua` and the `assets/snd/` folder, MOD/assets/vox/a.vox.\n",
    "tools/t.lua": 'MockEngine.load("code/scripts/a/b.lua")\n',
    "main.xml": FILES["main.xml"],
    "lib/lib.lua": FILES["lib.lua"],
}
MOVES = "snd -> assets/snd\nscripts -> code/scripts\nlib.lua -> lib/lib.lua\nvox -> assets/vox\n"


def build(base):
    root, data = os.path.join(base, "mod"), os.path.join(base, "data")
    for tree, files in ((root, FILES), (data, DATA)):
        for rel, content in files.items():
            p = os.path.join(tree, rel)
            os.makedirs(os.path.dirname(p), exist_ok=True)
            with open(p, "wb") as f:
                f.write((content if content is not None else "binary " + rel).encode("latin-1"))
    return root, data


def snapshot(root):
    out = {}
    for d, ds, fs in os.walk(root):
        for f in fs:
            p = os.path.join(d, f)
            with open(p, "rb") as h:
                out[os.path.relpath(p, root).replace("\\", "/")] = hashlib.md5(h.read()).hexdigest()
    return out


def plan_for(root, data, moves_text, base):
    mp = os.path.join(base, "moves.txt")
    with open(mp, "w") as f:
        f.write(moves_text)
    scan = R.make_scan(root, data)
    moves, acks = R.read_moves(mp)
    return scan, R.Plan(scan, moves, acks)


def test_scan_kinds():
    with tempfile.TemporaryDirectory() as base:
        root, data = build(base)
        scan = R.make_scan(root, data)
        kinds = scan.summary()
        assert kinds.get("include") == 3, kinds          # ../../lib.lua twice (quoted, unquoted), c.lua
        assert kinds.get("engine") == 2, kinds           # player.lua include, fx.lua script
        assert kinds.get("prefix") == 1, kinds           # "MOD/snd/" .. name
        assert kinds.get("level") == 1 and kinds.get("dangling") == 1, kinds
        mods = [r.target for r in scan.refs if r.kind == "mod"]
        assert mods.count("vox/a.vox") == 5, mods         # case, backslash, prop0 variants + docs
        assert "vox/a&b.vox" in mods and mods.count("vehicles/car one.xml") == 2, mods
        assert scan.pinned_targets().keys() == {"main/terrain.vox"}
        # the engine path "snd/x.ogg" in a game string is not ours
        assert not [r for r in scan.refs if r.text == "snd/x.ogg"], "engine path taken as a repo path"


def test_apply_rewrites_and_verifies():
    with tempfile.TemporaryDirectory() as base:
        root, data = build(base)
        scan, plan = plan_for(root, data, MOVES, base)
        assert not plan.errors, plan.errors
        assert R.do_apply(scan, plan, os.path.join(base, "out")) == 0
        for rel, want in EXPECT_AFTER.items():
            with open(os.path.join(root, rel), "rb") as f:
                got = f.read().decode("latin-1")
            assert got == want, "%s:\n%s\n!=\n%s" % (rel, got, want)
        assert not os.path.exists(os.path.join(root, "snd")) and not os.path.exists(os.path.join(root, "scripts"))
        assert os.path.exists(os.path.join(root, "assets/snd/sub/y.ogg"))


def test_split_prefix_refused_then_acked():
    with tempfile.TemporaryDirectory() as base:
        root, data = build(base)
        scan, plan = plan_for(root, data, "snd/sub -> other/sub\n", base)
        assert any("run-time path prefix 'MOD/snd/'" in e for e in plan.errors), plan.errors
        scan, plan = plan_for(root, data, "snd/sub -> other/sub\nack scripts/a/b.lua:MOD/snd/\n", base)
        assert not plan.errors and any("acknowledged" in w for w in plan.warnings), (plan.errors, plan.warnings)


def test_pinned_and_collisions_refused():
    with tempfile.TemporaryDirectory() as base:
        root, data = build(base)
        scan, plan = plan_for(root, data, "main -> world/main\n", base)
        assert any("PINNED" in e for e in plan.errors), plan.errors
        scan, plan = plan_for(root, data, "vox/a.vox -> x.vox\nlib.lua -> X.VOX\n", base)
        assert any("collision" in e for e in plan.errors), plan.errors
        scan, plan = plan_for(root, data, "nothere -> x\n", base)
        assert any("does not exist" in e for e in plan.errors), plan.errors


def test_new_include_ambiguity_and_dangling_change_refused():
    with tempfile.TemporaryDirectory() as base:
        root, data = build(base)
        # moving c.lua away leaves b.lua's `#include "c.lua"` rewritten; moving lib.lua next to an engine path
        # name would make an engine include resolve to ours: refused by the re-scan
        os.makedirs(os.path.join(root, "scripts/a/script/include"))
        scan, plan = plan_for(root, data, "lib.lua -> scripts/a/script/include/player.lua\n", base)
        before = snapshot(root)
        rc = R.do_apply(scan, plan, os.path.join(base, "out"))
        assert rc == 1, "verify should have refused an include that now resolves to a mod file"
        os.rmdir(os.path.join(root, "scripts/a/script/include"))
        os.rmdir(os.path.join(root, "scripts/a/script"))
        assert snapshot(root) == {k: v for k, v in before.items()}, "rollback incomplete"


def test_wrong_rewrite_caught_by_verify():
    """Sabotage: one reference rewritten to the wrong (existing) file must fail the re-scan and roll back."""
    with tempfile.TemporaryDirectory() as base:
        root, data = build(base)
        before = snapshot(root)
        scan, plan = plan_for(root, data, MOVES, base)
        edits = plan.edits["prefabs/car.xml"]
        s, e, old, new = edits[0]
        edits[0] = (s, e, old, new.replace("a.vox", "a&amp;b.vox"))   # still a real file, but the wrong one
        assert R.do_apply(scan, plan, os.path.join(base, "out")) == 1, "a wrong target passed verification"
        assert snapshot(root) == before


def test_rollback_restores_everything():
    with tempfile.TemporaryDirectory() as base:
        root, data = build(base)
        before = snapshot(root)
        scan, plan = plan_for(root, data, MOVES, base)
        real_verify = R.verify
        R.verify = lambda s, p: ["forced failure"]
        try:
            assert R.do_apply(scan, plan, os.path.join(base, "out")) == 1
        finally:
            R.verify = real_verify
        assert snapshot(root) == before, "rollback did not restore the tree"
        assert not os.path.exists(os.path.join(root, "assets")), "empty new folders left behind"


if __name__ == "__main__":
    fails = 0
    for name, fn in sorted(globals().items()):
        if name.startswith("test_") and callable(fn):
            try:
                fn()
                print("ok  ", name)
            except Exception as ex:
                fails += 1
                print("FAIL", name, "-", ex)
    sys.exit(1 if fails else 0)

"""Rebuild converter: parked (no enemy AI) copies of the AS350 helicopters for the spawn menu (user request
2026-11-13, for testing seats and player flight without the AI taking off).

    python tools/porting/patches/heli_variants.py

Base: the current main/AS350/AS350_<X>.xml (after add_seats.py, so the copies carry the <vehicle> wrapper and
seat rigs). Output: main/AS350/AS350_<X>_PARKED.xml = the same prefab with its instance name changed and the tag
"parked" on body "Heli" (Heli.lua: not hostile, no take-off). Never hand-edit the outputs; re-run after changing
the base files (add_seats.py first)."""
import os, re

REPO = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
VARIANTS = ["MILITARY", "INSURGENT"]


def make(text, name):
    old = 'name="instance=MOD/main/AS350/AS350_%s.xml"' % name
    assert text.count(old) == 1, name
    text = text.replace(old, 'name="instance=MOD/main/AS350/AS350_%s_PARKED.xml"' % name)
    pat = re.compile(r'(<body name="Heli" tags=")([^"]*)(")')
    assert len(pat.findall(text)) == 1, name
    return pat.sub(lambda m: m.group(1) + m.group(2) + " parked" + m.group(3), text)


def main():
    for name in VARIANTS:
        src = os.path.join(REPO, "main", "AS350", "AS350_%s.xml" % name)
        dst = os.path.join(REPO, "main", "AS350", "AS350_%s_PARKED.xml" % name)
        text = open(src, "rb").read().decode("latin-1").replace("\r\n", "\n")
        open(dst, "wb").write(make(text, name).encode("latin-1"))
        print("wrote", os.path.relpath(dst, REPO))


if __name__ == "__main__":
    main()

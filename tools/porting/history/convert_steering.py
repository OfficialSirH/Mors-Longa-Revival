"""Phase 4: fake-wheel steering wheels -> scripted steering wheels (scripts/SteeringWheel.lua).

Usage (repo root): python tools/porting/patches/convert_steering.py [--dry-run]

The original UAZ-452 files build the steering wheel as a fifth road wheel
    <wheel name="Steering_Wheel" pos=P rot=R steer="10"><vox ... object="Steering_Wheel"/></wheel>
which turns with steering but also spins freely after crashes (physics). This turns it into a plain part of the
vehicle body at the same place, tagged "steer":
    <vox name="Steering_Wheel" tags="nocull steer" pos=P rot=R ... object="Steering_Wheel"/>
and wraps the <vehicle> in <script file="MOD/scripts/SteeringWheel.lua">, which turns "steer" shapes about their
local y axis (the old wheel's steering axis) with the vehicle's steering. Files already converted are skipped.
"""
import os, re, sys

REPO = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
SCRIPT = "MOD/scripts/SteeringWheel.lua"
FILES = [
    "Vehicles/Soviet Vehicles/uaz452.xml",
    "Vehicles/Soviet Vehicles/uaz452 Damaged.xml",
    "Vehicles/Soviet Vehicles/uaz452 Modified.xml",
    "Vehicles/Soviet Vehicles/uaz452C_white.xml",
    "Vehicles/Soviet Vehicles/uaz452_emergency.xml",
]

FAKE = re.compile(
    r'(?P<ind>[ \t]*)<wheel name="Steering_Wheel" pos="(?P<pos>[^"]*)" rot="(?P<rot>[^"]*)" steer="[^"]*">\n'
    r'[ \t]*<vox tags="(?P<tags>[^"]*)" (?P<attrs>[^>]*?)/>\n'
    r'[ \t]*</wheel>\n')


def convert(text):
    m = FAKE.search(text)
    assert m, "fake steering wheel not found"
    assert " pos=" not in " " + m.group("attrs") and " rot=" not in " " + m.group("attrs"), "inner vox is offset"
    part = '%s<vox name="Steering_Wheel" tags="%s steer" pos="%s" rot="%s" %s/>\n' % (
        m.group("ind"), m.group("tags"), m.group("pos"), m.group("rot"), m.group("attrs"))
    text = text[:m.start()] + part + text[m.end():]

    # wrap the <vehicle> element (and indent it one more tab)
    v = re.search(r'(?m)^([ \t]*)<vehicle\b', text)
    end = text.index("</vehicle>", v.start())
    end = text.index("\n", end) + 1
    ind = v.group(1)
    block = "".join("\t" + line if line.strip() else line for line in text[v.start():end].splitlines(True))
    text = (text[:v.start()] + '%s<script file="%s">\n' % (ind, SCRIPT) + block + "%s</script>\n" % ind
            + text[end:])
    return text


def main():
    dry = "--dry-run" in sys.argv
    for rel in FILES:
        p = os.path.join(REPO, rel)
        t = open(p, "rb").read().decode("latin-1").replace("\r\n", "\n")
        if SCRIPT in t:
            print("already converted", rel)
            continue
        new = convert(t)
        print("converted", rel)
        if not dry:
            open(p, "wb").write(new.encode("latin-1"))


if __name__ == "__main__":
    main()

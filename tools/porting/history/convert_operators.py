#!/usr/bin/env python3
"""Enemy / convoy car scripts v1 -> v2 (Phase 3): chaseOperator, chaseOperatorTransport, ConvoyOperations,
ConvoyOperatorTransport. All four become SERVER-only scripts; helpers in scripts/vehicleOperatorCoop.lua.

Common steps (asserted): #version 2 header + includes, init -> server.init, tick/update/draw renamed to
OperatorTick/OperatorUpdate/OperatorDraw and called from server.tick / server.update (draw only did siren sound,
light blinking and debug lines - no game logic hidden there; it runs at the end of server.tick, as v1 drew after
tick), stop when OpFinished (queueRemoval). Then per-file player edits (EDITS).
Each file is rebuilt from the phase 2 commit (BASE, still v1). Usage (repo root): python3 tools/porting/patches/convert_operators.py
"""
import re, subprocess, sys

BASE = "6c28435"  # "phase 2" commit = last v1 state of these files (HEAD has been converted since)

MARK = "(v2 operator)"

HEADER = ('#version 2\n#include "script/include/player.lua"\n'
          '-- (v2 operator) SERVER only: AI driving (DriveVehicle), damage, explosions, sounds, siren/lights. Targets the\n'
          '-- nearest living player; helpers in vehicleOperatorCoop.lua. Converted by tools/porting/patches/convert_operators.py.\n')

WRAPPERS = """

-- (v2 operator) v1 callbacks, run on the server. draw() only played the siren, blinked lights and drew debug lines.
function server.tick(dt)
	if OpFinished then return end
	OperatorTick(dt)
	OpTicked = true
	if not OpFinished then OperatorDraw() end
end

-- update reads values the first tick sets (health, VehicleSpeed); wait for it in case v2 orders them differently
function server.update(dt)
	if OpFinished or not OpTicked then return end
	OperatorUpdate(dt)
end
"""

CRASH_SOUND = re.compile(
    r'(\t*)disttoplayer = VecLength\(VecSub\(GetVehicleTransform\(vehicle\)\.pos, GetPlayerCameraTransform\(\)\.pos\)\)\n'
    r'\t*PlaySound\(CBD, GetPlayerCameraTransform\(\)\.pos, disttoplayer ?/ ?10\)\n')

def git_head(path):
    return subprocess.run(["git", "show", BASE + ":" + path], capture_output=True, check=True).stdout.decode("utf-8")

def rep(t, old, new, count=1, path=""):
    n = t.count(old)
    assert n == count, f"{path}: expected {count}x {old[:80]!r}, found {n}"
    return t.replace(old, new)

def convert(path, edits):
    b = git_head(path)
    crlf = False  # (2026-11-08) the repo is LF (.gitattributes); old commits read as input may still be CRLF
    t = b.replace("\r\n", "\n")
    assert MARK not in t and not t.startswith("#version"), path + ": HEAD already converted"
    # include the co-op helpers right after masterScriptRemoverAPI.lua (its queueRemoval is replaced)
    t = rep(t, '#include "masterScriptRemoverAPI.lua"\n',
            '#include "masterScriptRemoverAPI.lua"\n#include "vehicleOperatorCoop.lua"\n', path=path)
    t = HEADER + t
    for name, new in (("init", "server.init"), ("tick", "OperatorTick"), ("update", "OperatorUpdate"), ("draw", "OperatorDraw")):
        t, n = re.subn(rf'\nfunction {name}\((dt)?\)\n', rf'\nfunction {new}(dt)\n', t)
        assert n == 1, f"{path}: {n}x function {name}"
    t, n = CRASH_SOUND.subn(r'\1OpPlayDistantSound(CBD, GetVehicleTransform(vehicle).pos) -- (v2 operator) for every player\n', t)
    assert n == 1, f"{path}: crash sound pattern found {n}x"
    for e in edits:
        t = rep(t, e[0], e[1], e[2] if len(e) > 2 else 1, path)
    t = t.rstrip("\n") + "\n" + WRAPPERS
    assert re.search(r'\nfunction (init|tick|update|draw)\(', t) is None, path
    if crlf:
        t = t.replace("\n", "\r\n")
    open(path, "wb").write(t.encode("utf-8"))
    print("converted", path)

S = "scripts/"
EDITS = {
S + "chaseOperator.lua": [
    ("\t\t\tpT = GetPlayerTransform()\n", "\t\t\tpT = OpTargetTransform(vBT.pos) -- (v2 operator) nearest living player\n"),
    ("\t\t\tgoalPos = VecAdd(GetPlayerTransform().pos, Vec(0,1,0))\n",
     "\t\t\tgoalPos = VecAdd(OpTargetTransform(GetVehicleTransform(vehicle).pos).pos, Vec(0,1,0))\n"),
    # lookatcarnage: its only call is commented out in v1; converted anyway so re-enabling it is safe
    ("""	PPos = GetPlayerTransform().pos
	VPos = GetVehicleTransform(vehicle).pos
	DistToTarget = VecLength(VecSub(VPos, PPos))
	if DistToTarget < 45 then
		rot = QuatLookAt(PPos, Vec(VPos[1], VPos[2] - 1, VPos[3]))
		--SetCameraTransform(Transform(Vec(PPos[1], PPos[2] + 3, PPos[3]), rot))
		--SetCameraFov(120 - DistToTarget*1.4)
		SetCameraDof(DistToTarget)
		SetTimeScale(0.3)
	end
""", """	-- (v2 operator) depth of field on each player within 45 m (client), slow motion only alone
	OpCarnage(GetVehicleTransform(vehicle).pos)
"""),
],
S + "chaseOperatorTransport.lua": [
    ("\t\t\tlocal pT = GetPlayerTransform()\n", "\t\t\tlocal pT = OpTargetTransform(vT.pos) -- (v2 operator) nearest living player\n"),
    ("GetPlayerVehicle() == vehicle", "OpAnyPlayerInVehicle(vehicle)", 2),
    ("\t\t\tgoalPos = VecAdd(GetPlayerTransform().pos, Vec(0, 1, 0))\n",
     "\t\t\tgoalPos = VecAdd(OpTargetTransform(GetVehicleTransform(vehicle).pos).pos, Vec(0, 1, 0))\n"),
],
S + "ConvoyOperations.lua": [
    ("\t\t\tpT = GetPlayerTransform()\n", "\t\t\tpT = OpTargetTransform(vBT.pos) -- (v2 operator) nearest living player\n"),
    ("""	PPos = GetPlayerTransform().pos
	VPos = GetVehicleTransform(vehicle).pos
	DistToTarget = VecLength(VecSub(VPos, PPos))
	if DistToTarget < 45 then
		rot = QuatLookAt(PPos, Vec(VPos[1], VPos[2] - 1, VPos[3]))
		--SetCameraTransform(Transform(Vec(PPos[1], PPos[2] + 3, PPos[3]), rot))
		--SetCameraFov(120 - DistToTarget*1.4)
		SetCameraDof(DistToTarget)
		SetTimeScale(0.3)
	end
""", """	-- (v2 operator) depth of field on each player within 45 m (client), slow motion only alone
	OpCarnage(GetVehicleTransform(vehicle).pos)
"""),
],
S + "ConvoyOperatorTransport.lua": [
    ("\t\t\tlocal pT = GetPlayerTransform()\n", "\t\t\tlocal pT = OpTargetTransform(vT.pos) -- (v2 operator) nearest living player\n"),
    ("if disttoplayer < 10 and not underControl and GetPlayerVehicle() == 0 then",
     "if disttoplayer < 10 and not underControl and GetPlayerVehicle(OpTargetPlayer(vT.pos)) == 0 then"),
    ("GetPlayerVehicle() == vehicle", "OpAnyPlayerInVehicle(vehicle)", 3),
    # (2026-11-08) original-mod bug: the folder is enemies/refugees/ (same path in 9dde6dd), so no live refugee ever
    # spawned when a refugee vehicle stopped; the stand-ins were deleted with nothing in their place
    ('"MOD/prefabs/spawnables/enemies/refugee/Ragdollrefugee1.xml"',
     '"MOD/prefabs/spawnables/enemies/refugees/Ragdollrefugee1.xml" -- (v2) v1 path had "refugee/"'),
],
}

if __name__ == "__main__":
    for f in sys.argv[1:] or list(EDITS):
        convert(f, EDITS[f])

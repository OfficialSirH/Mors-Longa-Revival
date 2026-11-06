#!/usr/bin/env python3
"""Mechanical v1 -> v2 conversion for world/server-only scripts (in place).

init/tick/update/handleCommand -> server.*, adds the v2 header, then applies the per-file
replacements given in EDITS (each must match exactly once). Asserts on everything.
Usage: python3 tools/porting/patches/convert_server.py   (converts the files listed in EDITS)
"""
import re, sys

HEADER = '#version 2\n#include "script/include/player.lua"\n'

def convert(path, edits, note):
    b = open(path, "rb").read().decode("utf-8")
    crlf = "\r\n" in b
    t = b.replace("\r\n", "\n")
    assert not t.lstrip().startswith("#version"), path + ": already v2"
    for old, new in edits:
        n = t.count(old)
        assert n == 1, f"{path}: expected 1x {old[:70]!r}, found {n}"
        t = t.replace(old, new)
    for name in ("init", "tick", "update", "handleCommand"):
        t, n = re.subn(rf'(^|\n)function {name}\(', rf'\1function server.{name}(', t)
        assert n <= 1, f"{path}: {n}x function {name}"
    assert not re.search(r'(^|\n)function (init|tick|update|draw|handleCommand)\(', t), path
    t = HEADER + "-- (v2) " + note + "\n" + t
    if crlf:
        t = t.replace("\n", "\r\n")
    open(path, "wb").write(t.encode("utf-8"))
    print("converted", path)

MIN_X = "PlayersMinX()"
EDITS = {
"Procedural/RemoveRoad.lua": ("server: deletes what is far behind the REARMOST player (nothing near any player), never a car a player is in.", [
    ("		local playerPos = GetPlayerTransform().pos\n",
     "		local playerPos = Vec(RearmostPlayerX(), 0, 0) -- (v2) rearmost player, x only is used below\n"),
    ("					if GetPlayerVehicle()~=vehicle then\n",
     "					if not IsAnyPlayerVehicle(vehicle) then\n"),
    ("function isBodyValid(b)",
     """function RearmostPlayerX()
	local x = math.huge
	for p in Players() do x = math.min(x, GetPlayerTransform(p).pos[1]) end
	return x
end

function IsAnyPlayerVehicle(vehicle)
	for p in Players() do if GetPlayerVehicle(p) == vehicle then return true end end
	return false
end

function isBodyValid(b)"""),
]),
"Procedural/WaterMover.lua": ("server: water volumes follow their sources; removed when far from the NEAREST player.", [
    ("	local playerTransform = GetPlayerTransform()\n", ""),
    ("			if VecDist(waterSourceTransform.pos, playerTransform.pos) > deletionDist then\n",
     "			if NearestPlayerDist(waterSourceTransform.pos) > deletionDist then\n"),
    ("function VecDist(a,b) return VecLength(VecSub(a,b))end",
     """function VecDist(a,b) return VecLength(VecSub(a,b))end
function NearestPlayerDist(pos)
	local d = math.huge
	for p in Players() do d = math.min(d, VecDist(pos, GetPlayerTransform(p).pos)) end
	return d
end"""),
]),
"Procedural/RandomVehicle.lua": ("server: spawns random vehicles at generated road locations.", []),
"Procedural/BuildingGrassRemover.lua": ("server: removes grass inside buildings.", []),
"Procedural/RandomBuilding.lua": ("server: spawns random buildings at generated road locations.", []),
"Procedural/RandomDeceasedBurnt.lua": ("server: spawns random corpses.", []),
"Procedural/RandomLoot.lua": ("server: spawns random loot at generated locations.", []),
"Procedural/RandomRoadSign.lua": ("server: spawns random road signs.", []),
"script/randomloot.lua": ("server: crate loot types; any player interacting with a crate removes its prompt.", [
    ('		if GetPlayerInteractBody() == Crates[i] and InputPressed("interact") then\n				RemoveTag(Crates[i], "interact")\n			end\n',
     '		for p in Players() do\n			if GetPlayerInteractBody(p) == Crates[i] and InputPressed("interact", p) then\n				RemoveTag(Crates[i], "interact")\n			end\n		end\n'),
]),
}

if __name__ == "__main__":
    files = sys.argv[1:] or list(EDITS)
    for f in files:
        note, edits = EDITS[f]
        convert(f, edits, note)

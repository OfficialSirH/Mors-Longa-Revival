#!/usr/bin/env python3
"""Build scripts/avf/AVF_Shells.lua (v2) from AVF's own shell code in tools/porting/avf_base/.

AVF (Armed Vehicles Framework, Workshop 2400346027, V-3.0.2) is by elboydo: "no copyright but please give credit
if this code is re-used in part or whole". Rebuild converter: the output is regenerated from the base on every run,
never hand-edit it. Every edit asserts its match count, so a changed base fails loudly.

Split (TECHNICAL_REFERENCE §6, cannon port plan):
  server  shell flight, penetration, payloads, spall / shrapnel, world effects, NPC damage (AVF's own
          mors_longa_damage registry hook), player damage per player;
  client  visual-only functions (impactEffect, impact_Debris, explosive_penetrator_effect, explosionController
          visuals, legacy particles, explosion sounds) run from events the server sends (client.avfFx), and each
          client draws the shells in flight from the spawn event (AVF_ClientTick).
Not ported yet (phase 3, launchers): guided / homing missiles, cluster bomblets, artillery shells, smoke projectors.

Usage (repo root): python tools/porting/patches/port_avf.py
"""
import os, re, sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
BASE = os.path.join(ROOT, "tools", "porting", "avf_base")
OUT = os.path.join(ROOT, "scripts", "avf", "AVF_Shells.lua")


def read(name):
    return open(os.path.join(BASE, name), encoding="latin-1").read().replace("\r\n", "\n")


SRC = {n: read(n) for n in ("kinetic_effects.lua", "main.lua", "ammo.lua", "explosionController.lua",
                            "common.lua", "vehicle_setup.lua", "weapons.lua")}


def func(file, name):
    """A top-level function (from 'function name(' at column 0 to the next 'end' at column 0)."""
    s = SRC[file]
    hits = [m.start() for m in re.finditer(r"^function " + re.escape(name) + r"\s*\(", s, re.M)]
    assert len(hits) >= 1, f"{file}: function {name} not found"
    start = hits[-1]  # main.lua defines rndVec twice: the later one wins in Lua, take it
    m = re.compile(r"^end\b[^\n]*(?:\n|\Z)", re.M).search(s, start)
    assert m, f"{file}: function {name} has no closing end at column 0"
    return s[start:m.end()]


def table(file, name):
    """A top-level table 'name = {' (possibly '=\\n{') up to its matching '}' (braces counted, strings and
    '--' comments skipped), plus the rest of that line."""
    s = SRC[file]
    m = re.search(r"^" + re.escape(name) + r"\s*=\s*\n?\s*\{", s, re.M)
    assert m, f"{file}: table {name} not found"
    depth, i = 1, m.end()
    while depth and i < len(s):
        c = s[i]
        if s.startswith("--", i):
            i = s.find("\n", i)
            continue
        if c in "\"'":
            j = i + 1
            while s[j] != c:
                j += 2 if s[j] == "\\" else 1
            i = j + 1
            continue
        depth += (c == "{") - (c == "}")
        i += 1
    assert depth == 0, f"{file}: table {name} not closed"
    e = s.find("\n", i)
    return s[m.start():(e + 1 if e >= 0 else len(s))]


def sub(text, old, new, count=1, regex=False, what=""):
    if regex:
        out, n = re.subn(old, new, text)
    else:
        n = text.count(old)
        out = text.replace(old, new)
    assert (n == count) if count is not None else n >= 1, f"{what or old!r}: expected {count}, got {n}"
    return out


def sub_block(text, old, new, count=1):
    """Like sub, but trailing spaces at line ends are ignored (AVF's source has many)."""
    pattern = r"[ \t]*\n".join(re.escape(line.rstrip()) for line in old.split("\n"))
    out, n = re.subn(pattern, lambda _: new, text)
    assert n == count, f"block {old[:60]!r}...: expected {count}, got {n}"
    return out


def calls(text, name, new, count=None):
    """Replace calls to a global function (not methods / fields)."""
    return sub(text, r"(?<![\w.:])" + re.escape(name) + r"\s*\(", new + "(", count, regex=True, what=name)


ASSET = [("MOD/gfx/", "MOD/avf/assets/gfx/"), ("MOD/sounds/explosion/", "MOD/avf/assets/sounds/explosion/")]


def assets(text):
    for a, b in ASSET:
        text = text.replace(a, b)
    return text


# ------------------------------------------------------------------ shared (both sides)
common = SRC["common.lua"]
ammo = assets(SRC["ammo.lua"])
# AVF's weapon types (the gun XML tag weaponType=..., e.g. customcannon): their defaults, and the first magazine's
# shell type is the base of every config magazine (AVF addGun / loadShells)
weapon_types = assets(table("weapons.lua", "weapons"))
global_config = table("main.lua", "globalConfig")
handlers = "\n".join(table("main.lua", n) for n in ("projectileHandler", "spallHandler"))
helpers = func("main.lua", "rndVec") + "\n" + func("main.lua", "rnd") + "\n" + \
    func("vehicle_setup.lua", "is_rocket") + "\n" + func("vehicle_setup.lua", "is_chemical_warhead")

# ------------------------------------------------------------------ server: simulation
SERVER_FUNCS = [
    ("kinetic_effects.lua", "projectileOperations"),
    ("kinetic_effects.lua", "payload_tank_he"),
    ("kinetic_effects.lua", "popProjectile"),
    ("kinetic_effects.lua", "shell_passthrough_penetration"),
    ("kinetic_effects.lua", "projectileShrapnel"),
    ("kinetic_effects.lua", "pushSpalling"),
    ("kinetic_effects.lua", "get_heat_jet"),
    ("kinetic_effects.lua", "popSpalling"),
    ("kinetic_effects.lua", "spallingOperations"),
    ("kinetic_effects.lua", "pushshrapnel"),
    ("kinetic_effects.lua", "shrapnelOperations"),
    ("kinetic_effects.lua", "spallingTick"),
    ("kinetic_effects.lua", "rectifyPenetrationVal"),
    ("main.lua", "projectileTick"),
    ("main.lua", "getProjectilePenetration"),
    ("main.lua", "calculate_pen_value"),
    ("main.lua", "get_penetration_table"),
    ("main.lua", "get_penetration_table_by_payload"),
    ("main.lua", "checkArmor"),
    ("main.lua", "mors_longa_damage"),
    ("main.lua", "getRefDir"),
    ("main.lua", "apply_impact_impulse"),
]
server = {name: func(f, name) for f, name in SERVER_FUNCS}

# player damage: AVF hurt only the local player (SetPlayerHealth). Original Mors Longa reset the engine health
# to 1 every tick (AdvancedHealthScript, 9dde6dd), so only a hit worth >= the whole health in one go mattered (it
# killed). Ported as that: AVF_HurtPlayer(p, amount) kills through the player's torso hitbox when amount >= 1.
server["payload_tank_he"] = sub_block(server["payload_tank_he"], """	local hurt_dist = explosion_size*2.1
	local toPlayer = VecSub(GetPlayerCameraTransform().pos, hitPos)
	local distToPlayer = VecLength(toPlayer)
	local distScale = clamp(1.0 - distToPlayer / hurt_dist, 0.0, 1.0)
	if distScale > 0 then
		local hit = QueryRaycast(hitPos, toPlayer, distToPlayer)
		if(not hit) then
			local regular_damage = explosion_size*100
			local expected_damage = math.random((regular_damage*.75),regular_damage*1.25)/100
			local player_damage =
				SetPlayerHealth(GetPlayerHealth() - expected_damage*distScale)
			end
	end
""", """	-- (v2) every player, not only the local one (AVF_HurtPlayer)
	local hurt_dist = explosion_size*2.1
	for p in Players() do
		local toPlayer = VecSub(GetPlayerCameraTransform(p).pos, hitPos)
		local distToPlayer = VecLength(toPlayer)
		local distScale = clamp(1.0 - distToPlayer / hurt_dist, 0.0, 1.0)
		if distScale > 0 then
			local hit = QueryRaycast(hitPos, toPlayer, distToPlayer)
			if(not hit) then
				local regular_damage = explosion_size*100
				local expected_damage = math.random((regular_damage*.75),regular_damage*1.25)/100
				AVF_HurtPlayer(p, expected_damage*distScale)
			end
		end
	end
""")

# NPC damage: also tell goreai who fired (hitmarkers / kill credit), as gunfunctions.lua does
server["mors_longa_damage"] = sub_block(server["mors_longa_damage"],
    '		    SetFloat(path_damage, damage) -- Specific damage to each body by handle.\n',
    '		    SetFloat(path_damage, damage) -- Specific damage to each body by handle.\n'
    '		    SetInt("level.goreai.body_damage_player_owner", projectile.ownerPlayer or 0) -- (v2) who fired\n')

# AVF's apply_impact_impulse reads point2 / dist1, which are never globals (nil): the impulse lands at
# projectile.point1 (AVF's HE shells exploded in the original, so this call cannot have aborted popProjectile)
server["apply_impact_impulse"] = sub_block(server["apply_impact_impulse"],
    "	local pos = VecAdd(projectile.point1, VecScale(VecNormalize(VecSub(point2,projectile.point1)),dist1))\n",
    "	local pos = VecCopy(projectile.point1) -- (v2) AVF read the undefined globals point2 / dist1 here\n")

# shells also skip the gun's and the turret's own bodies (AVF skipped only the gun's main shape: the BMP-1's barrel
# pieces are other shapes, and its first shell hit them, 2026-11-12 in-game)
server["projectileOperations"] = sub_block(server["projectileOperations"],
    "		QueryRejectShape(projectile.originGun)\n",
    "		QueryRejectShape(projectile.originGun)\n"
    "		for _, b in ipairs(projectile.rejectBodies or {}) do QueryRejectBody(b) end -- (v2)\n")

# rocket / missile exhaust: visual only, every tick per rocket (a Katyusha salvo would send hundreds of events a
# second); each client draws it for its drawn shells (AVF_Glue AVF_ClientTick). The block also used the undefined
# global exaustCoef. Cut from "--- EXAUST" to "--- test for impact".
po = server["projectileOperations"]
a = po.index("\t\t--- EXAUST")
b = po.index("\t\t--- test for impact")
assert 0 < a < b and po[a:b].count("SpawnParticle(") == 4  # 3 live, 1 commented out
server["projectileOperations"] = po[:a] + "\t\t-- (v2) exhaust: drawn by the clients (AVF_ClientTick)\n\n" + po[b:]

# penetration path holes (2026-11-13, in-game: lag firing the BMP-2's 3UBR8 APDS): AVF punches a hole (~0.46 m radius
# for 30 mm) at every penetration step (7.5 cm apart on a non-penetrating hit, 1 cm when penetrating), so dozens of
# almost identical overlapping holes per round (mock: 55). Holes along the path now go through AVF_PathHole /
# AVF_PathPaint (AVF_Glue.lua), which skip a spot closer than half the current radius to the last hole made.
gp = server["getProjectilePenetration"]
gp = sub(gp, "	for i=1,#damagePoints,iteration_coef do \n",
         "	AVF_PathReset() -- (v2) holes along the path at least half a radius apart\n"
         "	for i=1,#damagePoints,iteration_coef do \n")
gp = sub(gp, "			MakeHole(damagePoints[i],", "			AVF_PathHole(damagePoints[i],", count=2)
gp = sub(gp, "		Paint(damagePoints[i], shell.shellType.bulletdamage[2]*(1.6+holeModifier), \"explosion\")",
         "		AVF_PathPaint(damagePoints[i], shell.shellType.bulletdamage[2]*(1.6+holeModifier), \"explosion\")")
# spall only from hard material (2026-11-13, still lag shooting into foliage): AVF throws at least 3-9 fragments at
# every penetration (its floor math.max(spall_num, 1)), also from each leaf layer of a bush, and every fragment runs
# its own penetration path through further layers (mock, APDS into a 20-layer bush: 8115 holes, 6462 of them from
# fragments' paths, 1613 from their impacts). Now pushSpalling only runs when the path went through a hard material
# (AVF_HARD in the glue: metal, stone, masonry); soft ones (foliage, wood, plastic, glass, dirt, plaster) throw none.
gp = sub(gp, "function getProjectilePenetration(shell,hitTarget)\n",
         "function getProjectilePenetration(shell,hitTarget)\n\tAVF_PATH_HARD = false -- (v2) see pushSpalling\n")
# rocks (2026-11-13, still frame drops shooting rocks): an HE shell's ~47 shrapnel fragments each ran this function,
# whose two tiny scorch paints (0.1 m) at its start made ~94 Paint calls per shell on the rock (mock; Paint updates
# the whole painted shape, large on rock formations). Those two paints are now only for the shell itself
# (AVF_ShellPaint: fragments skip them; their holes and other effects stay).
gp = sub(gp, 'Paint(test.pos, 0.1, "explosion")\n', 'AVF_ShellPaint(shell, test.pos)\n', count=2)
server["getProjectilePenetration"] = gp
server["calculate_pen_value"] = sub(server["calculate_pen_value"],
    "	local mat,r,g,b = GetShapeMaterialAtPosition(hitTarget,test.pos)\n",
    "	local mat,r,g,b = GetShapeMaterialAtPosition(hitTarget,test.pos)\n"
    "	if AVF_HARD[mat] then AVF_PATH_HARD = true end -- (v2) spall only from hard material\n")
server["pushSpalling"] = sub(server["pushSpalling"],
    "function pushSpalling(spallingLoc,spallShell,test,spallValue)\n",
    "function pushSpalling(spallingLoc,spallShell,test,spallValue)\n"
    "\tif not AVF_SpallAllowed() then return end -- (v2) no spall from soft material (foliage, wood, plastic, ...)\n")

server["projectileOperations"] = sub(server["projectileOperations"], "GetWindVelocity()",
                                     "GetWindVelocity(projectile.point1)")

# sprite drawing of shells / spall in flight: clients draw shells themselves (AVF_ClientTick), spall fragments are
# not drawn (too many to send); drop the lines (altloc = the sprite transform, only used for drawing)
for name in ("projectileOperations", "spallingOperations", "shrapnelOperations"):
    before = server[name]
    server[name] = re.sub(r"^[ \t]*(?:local )?altloc\b[^\n]*\n|^[ \t]*DrawSprite\([^\n]*\n", "", before, flags=re.M)
    code_lines = [l for l in server[name].split("\n") if not l.strip().startswith("--")]
    assert not any("altloc" in l or "DrawSprite" in l for l in code_lines), name
    assert before.count("DrawSprite(") == 3, f"{name}: expected 3 DrawSprite lines"

server_code = "\n".join(server[n] for _, n in SERVER_FUNCS)
# visuals inside the simulation -> events / nothing (each client draws shells and spall itself)
server_code = sub(server_code,
    r"PlaySound\(explosion_sounds\[math\.random\(1,#explosion_sounds\)\],\s*", "AVF_FxExplosionSound(",
    count=None, regex=True, what="explosion sounds")
for name in ("PlayLoop", "PointLight"):
    if re.search(r"(?<![\w.:])" + name + r"\s*\(", server_code):  # PointLight was only in the exhaust block
        server_code = calls(server_code, name, "AVF_NoFx")
server_code = calls(server_code, "SpawnParticle", "AVF_FxParticle")
# MakeHole with a radius <= 0 carves nothing (AVF calls it so a lot, e.g. 47 per HE shell on rock): AVF_Hole skips it
server_code = calls(server_code, "MakeHole", "AVF_Hole")
# every paint through AVF_Paint (glue): one place for the temporary "No Shell Paint" test switch (debug menu)
server_code = calls(server_code, "Paint", "AVF_Paint")
server_code = calls(server_code, "impactEffect", "AVF_FxImpact")
server_code = calls(server_code, "explosive_penetrator_effect", "AVF_FxPenetrator")
server_code = calls(server_code, "inflict_player_damage", "AVF_InflictPlayerDamage")
server_code = sub(server_code, "explosionController:pushExplosion(", "AVF_FxExplosion(", count=None)
server_code = sub(server_code, "utils.printStr(", "AVF_Log(", count=None)
# body pushes through AVF_Impulse (glue): the velocity change is capped (2026-11-13: the AGS-30's gun weighs ~1e-7
# kg, a shell's push sent it to absurd speeds; in-game the game froze for a while when its tripod was shot)
server_code = calls(server_code, "ApplyBodyImpulse", "AVF_Impulse", count=1)
assert "PlaySound(" not in server_code, "a PlaySound left in the server code"
assert "SetPlayerHealth" not in server_code and "GetPlayerHealth" not in server_code
assert "vehicle.id" not in server_code and "vehicle.body" not in server_code
for left in ("homing_missile_computations", "initClusterBomblets"):
    # only reached by guided / cluster shells (phase 3): stubbed below
    pass

# ------------------------------------------------------------------ client: visuals
CLIENT_FUNCS = [("main.lua", "impactEffect"), ("main.lua", "impact_Debris"),
                ("main.lua", "explosive_penetrator_effect")]
client_code = "\n".join(func(f, n) for f, n in CLIENT_FUNCS)
ec = SRC["explosionController.lua"]
# shockwave pushes bodies (world effect): the server runs it (AVF_FxExplosion); clients only draw
ec = sub(ec, "	self:shockwave(pos,strength)\n", "	-- (v2) shockwave: on the server (AVF_FxExplosion)\n")
ec = calls(ec, "ApplyBodyImpulse", "AVF_Impulse", count=1)  # shockwave (runs on the server): capped as above
client_code += "\n" + ec

HEADER = """-- GENERATED by tools/porting/patches/port_avf.py from tools/porting/avf_base/ - DO NOT EDIT.
-- AVF (Armed Vehicles Framework, Steam Workshop 2400346027, V-3.0.2) by elboydo: "no copyright but please give
-- credit if this code is re-used in part or whole". Ported to Teardown 2.x co-op for Mors Longa Revival.
-- Server: shell flight / penetration / payloads / spall / world effects / NPC + player damage.
-- Clients: visuals from events (client.avfFx) and the shells in flight (AVF_ClientTick / AVF_ClientDraw).
-- Glue (hand-written): scripts/avf/AVF_Glue.lua.
"""

out = "\n".join([
    HEADER,
    "-- ======================================================== common.lua (AVF)", common,
    "-- ======================================================== ammo.lua (AVF)", ammo,
    "-- ======================================================== weapons.lua: weapons (AVF)", weapon_types,
    "-- ======================================================== main.lua: globalConfig, handlers, helpers (AVF)",
    global_config, handlers, helpers,
    "-- ======================================================== server: simulation (AVF kinetic_effects / main)",
    server_code,
    "-- ======================================================== client: visuals (AVF main / explosionController)",
    client_code,
])
os.makedirs(os.path.dirname(OUT), exist_ok=True)
open(OUT, "w", encoding="latin-1", newline="\n").write(out)
print(f"wrote {os.path.relpath(OUT, ROOT)} ({out.count(chr(10))} lines)")

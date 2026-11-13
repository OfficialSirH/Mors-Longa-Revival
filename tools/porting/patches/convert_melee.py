#!/usr/bin/env python3
"""v1 melee weapon -> v2 (scripts/Weapons/Melee/*.lua, in place).

Client: input, animation, raycasts, sounds, particles (as before).
Server: world effects, sent by Melee_Functions.lua (MeleeNet_*, server.meleeOps).
Asserts on every pattern so a script that deviates from the template stops the run.
Usage: python3 tools/porting/patches/convert_melee.py scripts/Weapons/Melee/BaseballBat.lua ...
"""
import re, sys

def convert(path):
    b = open(path, "rb").read().decode("utf-8")
    crlf = False  # (2026-11-08) the repo is LF (.gitattributes); old commits read as input may still be CRLF
    t = b.replace("\r\n", "\n")
    assert not t.lstrip().startswith("#version 2"), path + ": already v2"

    def sub(old, new, count=1, regex=False):
        nonlocal t
        n = len(re.findall(old, t)) if regex else t.count(old)
        assert n == count, f"{path}: expected {count}x {old!r}, found {n}"
        t = re.sub(old, new, t) if regex else t.replace(old, new)

    sub('#include "Melee_Functions.lua"\n',
        '#version 2\n#include "script/include/player.lua"\n#include "Melee_Functions.lua"\n')

    m = re.search(r'\tRegisterTool\(Tool_Id, ("[^"]+"), ("[^"]+"), (\d+)\)\n', t)
    assert m, path + ": RegisterTool line"
    tool_id = re.search(r'\tTool_Id = ("melee-[^"]+")\n', t)
    assert tool_id, path + ": Tool_Id line"
    sub(m.group(0), "\t-- (v2) RegisterTool moved to server.init()\n")
    # v1 used the wrong registry key (game.tool.<Name> instead of game.tool.melee-<Name>), so these were
    # no-ops; enabling stays with the inventory (game.tool.melee-*.enabled) as before.
    sub(r'\tSetBool\("game\.tool\.[^"]+\.enabled", true\)\n', "", regex=True)
    sub(r'\tSetFloat\("game\.tool\.[^"]+\.ammo", 101\)\n', "", regex=True)

    server_init = (f"function server.init()\n"
                   f"\tRegisterTool({tool_id.group(1)}, {m.group(1)}, {m.group(2)}, {m.group(3)})\n"
                   f"end\n\n")
    sub("\nfunction init()\n", "\n" + server_init + "function client.init()\n")
    sub("\nfunction tick(dt)\n", "\nfunction client.tick(dt)\n")
    sub('GetBool("game.player.canusetool") == true', "GetPlayerCanUseTool()")
    sub('GetBool("game.player.canusetool")', "GetPlayerCanUseTool()")
    sub('GetString("game.player.tool")', "GetPlayerTool()")
    # World effects -> server (queued, see Melee_Functions.lua). Includes commented-out code.
    t = re.sub(r'(?<![\w.])MakeHole\(', "MeleeNet_MakeHole(", t)
    sub("    ApplyBodyImpulse(body, GetPlayerCameraTransform().pos, Vel)",
        "    MeleeNet_Impulse(body, GetPlayerCameraTransform().pos, Vel)")
    # Boost() is never called; SetPlayerVelocity is server-only in v2.
    sub("\nfunction Boost()\n", "\n-- (v2) unused; SetPlayerVelocity is server-only, needs a ServerCall if this is ever used\nfunction Boost()\n")

    for bad in ("game.player.", "function init(", "function tick("):
        assert bad not in t, f"{path}: leftover {bad}"
    if crlf:
        t = t.replace("\n", "\r\n")
    open(path, "wb").write(t.encode("utf-8"))
    print("converted", path, tool_id.group(1))

for p in sys.argv[1:]:
    convert(p)

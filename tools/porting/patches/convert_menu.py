#!/usr/bin/env python3
"""Phase 3: the mod's main menu (main.xml) v1 -> v2 (client UI; levels are started by the host's server).

* scripts/UI/MainMenu/menu_main.lua stays a LIBRARY (no #version): ingame_settings.lua includes it. Its v1
  callbacks become MainMenu_Init/Tick/Draw, called by the new entry script scripts/UI/MainMenu/main_menu.lua.
* menu_select_difficulty.lua: client script; the camera path is kept per client instead of moving the "cam" body.
* RotateScene.lua: the turntable body turns on the server, the menu camera is set on each client.
* StartLevel (server-only) -> MenuStartLevel (scripts/UI/MainMenu/menu_host.lua): host only, via ServerCall.
* Config.lua CheejinsShortcuts (dev level shortcuts, only drawn by the menu): same.

Usage (repo root): python3 tools/porting/patches/convert_menu.py
Rebuilds the three menu scripts from git HEAD each run (they are v1 there); Config.lua is edited in place once.
All four files are CRLF.
"""
import os, subprocess, sys
sys.path.insert(0, os.path.dirname(__file__))
from convert_server import convert

MAIN = "scripts/UI/MainMenu/menu_main.lua"
DIFF = "scripts/UI/MainMenu/menu_select_difficulty.lua"
ROT = "scripts/RotateScene.lua"
CONFIG = "Config.lua"

HOST = "(v2) only the host starts the game"

MAIN_EDITS = [
    ('#include "../../perkTable.lua"\n', '#include "../../perkTable.lua"\n#include "menu_host.lua"\n', 1),
    ("function init()\n", "function MainMenu_Init() -- (v2) called by main_menu.lua client.init\n", 1),
    ("function tick()\n", "function MainMenu_Tick() -- (v2) called by main_menu.lua client.tick\n", 1),
    ("function draw(dt)\n", "function MainMenu_Draw(dt) -- (v2) called by main_menu.lua client.draw\n", 1),
    # v1 quickload hook; nothing calls it in v2 (the menu has no quicksave)
    ("function handleCommand(cmd) handle_quickload(cmd) end\n",
     "function MainMenu_HandleCommand(cmd) handle_quickload(cmd) end -- (v2) unused\n", 1),
    ("StartLevel(", "MenuStartLevel(", 4),
    ('\t\t\tif GetBool("savegame.mod.continue") then\n',
     '\t\t\tif GetBool("savegame.mod.continue") and MenuIsHost() then -- ' + HOST + '\n', 1),
    ("if UiTextButton(string.upper('New Save'), btn_width, btn_height) then",
     "if MenuHostButton(string.upper('New Save'), btn_width, btn_height) then -- " + HOST, 1),
    ("if UiTextButton(string.upper('Tutorial'), btn_width, btn_height) then",
     "if MenuHostButton(string.upper('Tutorial'), btn_width, btn_height) then -- " + HOST, 1),
    ("if UiTextButton(string.upper('Try Again?'), btn_width, btn_height) then",
     "if MenuHostButton(string.upper('Try Again?'), btn_width, btn_height) then -- " + HOST, 1),
    ("\t\t\tDrawCenterImage(-btn_width / 2, 0, btn_height, btn_height, Button_Icons.exit)\n\t\t\tUiTranslate(0, font_size * 3)\n",
     "\t\t\tDrawCenterImage(-btn_width / 2, 0, btn_height, btn_height, Button_Icons.exit)\n\t\t\tUiTranslate(0, font_size * 3)\n"
     "\n\t\t\tif not MenuIsHost() then -- (v2)\n\t\t\t\tUiText(\"THE HOST STARTS THE GAME\")\n\t\t\tend\n", 1),
]

DIFF_EDITS = [
    ('#include "../../perkTable.lua"\n', '#include "../../perkTable.lua"\n#include "menu_host.lua"\n'),
    ('sndnext = LoadSound("MOD/snd/ui_button_next.ogg")\nsndback = LoadSound("MOD/snd/ui_button_back.ogg")\n', ""),
    ("function init()\n\n\tInit_Settings()\n",
     "function init()\n\n\t-- (v2) moved from load time (API calls are not allowed there)\n"
     '\tsndnext = LoadSound("MOD/snd/ui_button_next.ogg")\n\tsndback = LoadSound("MOD/snd/ui_button_back.ogg")\n\n'
     "\tInit_Settings()\n"),
    ('\tcam = FindBody("cam")\n',
     '\tcam = FindBody("cam")\n'
     '\t-- (v2) camera path kept per client; v1 moved the static "cam" body itself (a world change, server-only)\n'
     "\tCamT = GetBodyTransform(cam)\n"),
    ("\tSetCameraTransform(GetBodyTransform(cam))\n", "\tSetCameraTransform(CamT)\n"),
    ("\tlocal camTrans = GetBodyTransform(cam)\n", "\tlocal camTrans = CamT\n"),
    ("\tSetBodyTransform(cam, Transform(VecLerp(camTrans.pos,locPos,.1), rot))\n",
     "\tCamT = Transform(VecLerp(camTrans.pos,locPos,.1), rot)\n"),
    ("function playCharacter(char)\n",
     "function playCharacter(char)\n\tif not MenuIsHost() then return end -- " + HOST + "\n"),
]
DIFF_STARTLEVEL = 5  # 4 live + 1 in the commented-out custom difficulty

ROT_EDITS = [
    ("function init()\n", "function FindSceneHandles()\n"),
]
ROT_APPEND = """
-- (v2) the turntable turns on the server (synced); each client sets its own menu camera
function server.init()
	FindSceneHandles()
end

function client.init()
	FindSceneHandles()
end

-- (v2) v2 players have a visible character, which stood in the middle of the menu scene: hide every player
-- (per tick, as the official creativemode.lua does on the server)
function server.tick(dt)
	for p in Players() do
		SetPlayerHidden(p)
	end
end
"""

CONFIG_EDITS = [
    ('            StartLevel("", "MOD/GoreNPCs/map/gore_map.xml", "")\n',
     '            MenuStartLevel("", "MOD/GoreNPCs/map/gore_map.xml", "") -- (v2) host only, menu_host.lua\n'),
    ('            StartLevel("", "MOD/GoreNPCs/map/blankahmap.xml", "")\n',
     '            MenuStartLevel("", "MOD/GoreNPCs/map/blankahmap.xml", "")\n'),
    ('                    StartLevel("", path, "")\n', '                    MenuStartLevel("", path, "")\n'),
]


def head(path):
    return subprocess.run(["git", "show", "HEAD:" + path], capture_output=True, check=True).stdout.decode("utf-8")


def write(path, text):
    """text with LF line endings; the repo's Lua files are CRLF"""
    open(path, "wb").write(text.replace("\r\n", "\n").replace("\n", "\r\n").encode("utf-8"))


def replace(path, text, old, new, count=1):
    n = text.count(old)
    assert n == count, f"{path}: expected {count}x {old[:70]!r}, found {n}"
    return text.replace(old, new)


def main():
    # menu_main.lua: library, no #version header
    t = head(MAIN).replace("\r\n", "\n")
    assert "#version" not in t, MAIN + ": HEAD is not v1"
    for old, new, count in MAIN_EDITS:
        t = replace(MAIN, t, old, new, count)
    t = "-- (v2) main menu UI (client); library: entry script main_menu.lua, also included by ingame_settings.lua\n" + t
    write(MAIN, t)
    print("converted", MAIN)

    t = head(DIFF).replace("\r\n", "\n")
    t = replace(DIFF, t, "StartLevel(", "MenuStartLevel(", DIFF_STARTLEVEL)
    write(DIFF, t)
    convert(DIFF, DIFF_EDITS, "client: New Save -> difficulty / character select (host only); camera moves per client.",
            {"init": "client", "tick": "client", "draw": "client"})

    write(ROT, head(ROT))
    convert(ROT, ROT_EDITS, "menu turntable (server) and menu camera with mouse depth of field (client).",
            {"update": "server", "draw": "client"})
    t = open(ROT, "rb").read().decode("utf-8").replace("\r\n", "\n")
    write(ROT, t.rstrip("\n") + "\n" + ROT_APPEND)

    t = open(CONFIG, "rb").read().decode("utf-8").replace("\r\n", "\n")
    if "MenuStartLevel(" in t:
        print("already edited", CONFIG)
    else:
        for old, new in CONFIG_EDITS:
            t = replace(CONFIG, t, old, new)
        write(CONFIG, t)
        print("edited", CONFIG)


if __name__ == "__main__":
    main()

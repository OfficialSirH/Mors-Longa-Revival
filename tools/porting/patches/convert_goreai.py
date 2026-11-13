#!/usr/bin/env python3
"""GoreNPCs v1 -> v2 (Phase 3): per-file asserted replacements, applied in place.

goreai_main.lua, systems/goreai_players.lua, systems/goreai_netview.lua, systems/goreai_controller.lua and
systems/goreai_sitting.lua are (re)written by hand; this script holds every
edit made to the other files. Each (old, new) must match exactly `count` times (default 1).
Each file is rebuilt from the phase 2 commit (BASE, still v1), so the script can be re-run
after changing an edit. Usage (repo root): python3 tools/porting/patches/convert_goreai.py [file ...]
"""
import subprocess, sys

BASE = "6c28435"  # "phase 2" commit = last v1 state of these files (HEAD has been converted since)

MARK = "(v2 goreai)"   # every patched file gets at least one comment containing this

def apply(path, edits):
    b = subprocess.run(["git", "show", BASE + ":" + path], capture_output=True, check=True).stdout.decode("utf-8")
    crlf = False  # (2026-11-08) the repo is LF (.gitattributes); old commits read as input may still be CRLF
    t = b.replace("\r\n", "\n")
    assert MARK not in t, path + ": HEAD version is already patched"
    for e in edits:
        old, new = e[0], e[1]
        count = e[2] if len(e) > 2 else 1
        n = t.count(old)
        assert n == count, f"{path}: expected {count}x {old[:80]!r}, found {n}"
        t = t.replace(old, new)
    assert MARK in t, path + ": no marker comment added"
    if crlf:
        t = t.replace("\n", "\r\n")
    open(path, "wb").write(t.encode("utf-8"))
    print("patched", path)

G = "GoreNPCs/scripts/"
EDITS = {}

# ---------------------------------------------------------------- initializer (one per NPC prefab)
EDITS[G + "goreai_initializer.lua"] = [
    ('--[[\n#include "../../scripts/TDSU/tdsu.lua"', '#version 2\n--[[\n#include "../../scripts/TDSU/tdsu.lua"'),
    ("-- This script initializes the tags for the goreai constructor to find and create the gore npc.\n"
     "--================================================================================================================================\n",
     "-- This script initializes the tags for the goreai constructor to find and create the gore npc.\n"
     "--================================================================================================================================\n"
     "-- (v2 goreai) Server only: tags, collision filter, shape merging, spawning the manager script (goreai_main.lua)\n"
     "-- once, and this npc's path queries (QueryPath), exchanged with goreai_main through the registry\n"
     "-- (level.goreai.nav_api.<id>, level.nav_api_tables.<id>*). Nothing runs on clients.\n"),
    ("function init()\n", "function server.init()\n"),
    ("function tick(dt)\n", "function server.tick(dt)\n"),
    ('\tif GetBool("level.goreai.api.npcs.dead_id." .. ID) then\n\t\tqueueRemoval()\n\tend\n',
     "\t-- (v2) v1 queueRemoval() registered a pause menu button to find its own script handle; that does not work\n"
     "\t-- on the server, so the script just stops working once its npc is dead.\n"
     "\tif Finished then return end\n"
     '\tif GetBool("level.goreai.api.npcs.dead_id." .. ID) then\n\t\tFinished = true\n\t\treturn\n\tend\n'
     "\t-- (v2 perf 2026-11-07) also stop once the npc's torso is gone (RemoveRoad deleted it behind the players);\n"
     "\t-- v1 kept these scripts reading/writing the registry every tick for the rest of the run.\n"
     "\tif MyTorso ~= 0 and not IsHandleValid(MyTorso) then\n\t\tFinished = true\n\t\treturn\n\tend\n"),
    ("\tisDead = false\n", '\tisDead = false\n\tMyTorso = FindBody("Torso") -- (v2 perf) see server.tick\n'),
    ("\t\tSpawn(xml, Transform(), true)\n",
     '\t\t-- (v2) tag the manager "nodelete" (never removed by cleanup code)\n'
     "\t\tfor _, e in ipairs(Spawn(xml, Transform(), true) or {}) do\n"
     '\t\t\tif GetEntityType(e) == "script" then SetTag(e, "nodelete") end\n'
     "\t\tend\n"),
    ("\n\nfunction handleCommand(cmd)\n\thandle_quickload(cmd)\nend\n", "\n\n-- (v2) no handleCommand/quickload in v2; handle_quickload below is unused.\n"),
    ("\t\t\tinit()\n", "\t\t\tserver.init()\n"),
]

# ---------------------------------------------------------------- per-npc loops: switch the context player
EDITS[G + "goreai_manage.lua"] = [
    ("            npc.disttoplayer = VecDist(npc.torsoPos, npc.ai.aimPos)\n",
     "            GoreAI_SetContext(npc) -- (v2 goreai) GoreP / PlayerPos = this npc's target player\n"
     "            npc.disttoplayer = VecDist(npc.torsoPos, npc.ai.aimPos)\n"),
    ('        if config.db then\n            if InputPressed("n") then\n',
     '        if config.db and false then -- (v2) debug: GetCrosshairWorldPos needs the camera (client only)\n            if InputPressed("n") then\n'),
    ("        if npc.isValid then\n\n            if not npc.dead then\n\n                npc.HT",
     "        if npc.isValid then\n\n            GoreAI_SetContext(npc)\n\n            if not npc.dead then\n\n                npc.HT"),
    ("\t\t\t\tif Settings.game.killcam.value then\n                    set_lock_cam(npc)\n                end\n",
     "                set_lock_cam(npc) -- (v2) the killer's client checks its own killcam setting\n"),
    # (2026-11-07) crash fix: Constrain* only from the update callback (script_defs.lua: "should only be used from the
    # update callback"). v1 pointed/held the gun in tick; in v2 that crashed the engine on a worker thread
    # (bisected with tests H-N, see TECHNICAL_REFERENCE status log).
    ("                if npc.Gun then\n                    npc_point_gun(npc)\n                    npc_hold_gun(npc)\n                end\n",
     "                -- (v2 goreai) npc_point_gun / npc_hold_gun (constraints) run in update_npcs: Constrain* in tick\n"
     "                -- crashed the v2 engine.\n"),
    ("                npc_melee_hold_weapons(npc)\n",
     "                npc_melee_hold_weapons(npc)\n\n"
     "                if npc.Gun and IsHandleValid(npc.Gun.body) then -- (v2 goreai) moved here from tick_npcs\n"
     "                    npc_point_gun(npc)\n"
     "                    npc_hold_gun(npc)\n"
     "                end\n"),
    # (Phase 4, 2026-11-08) NPCs sit in the vehicles' passenger seat rigs (systems/goreai_sitting.lua)
    ("npc_pose_ragdoll(npc, GetLightTransform(npc.ai.sitting.sitLight), RagdollPoses.sit, npc.ai.sitting.sitBody)",
     "npc_pose_ragdoll(npc, npc_sitting_head_transform(npc), npc_sitting_pose(npc), npc.ai.sitting.sitBody) -- (v2 goreai) seat rig"),
]

EDITS[G + "components/goreai_targetting.lua"] = [
    ("VecDist(GetPlayerTransform().pos, npc.torsoPos)", "VecDist(GetPlayerTransform(GoreP).pos, npc.torsoPos)", 2),
    ("npc.ai.targeting.target.isAlive = GetPlayerHealth() > 0",
     "npc.ai.targeting.target.isAlive = GetPlayerHealth(GoreP) > 0 -- (v2 goreai) GoreP = this npc's target player"),
    ("npc.ai.shootPos = GetPlayerTrackingPos(PlayerPos, GetBodyTransform(npc.Gun.body).pos, npc.velocity)",
     "npc.ai.shootPos = GoreAI_PlayerTrackingPos(PlayerPos, GetBodyTransform(npc.Gun.body).pos, npc.velocity)"),
    ("--- Used for targetting other npc torsos.\n",
     "--- (v2) TDSU GetPlayerTrackingPos with the context player's velocity (it used the host's).\n"
     "function GoreAI_PlayerTrackingPos(playerPos, source_pos, vel_len)\n"
     "    local scale = VecDist(source_pos, playerPos) / vel_len\n"
     "    return VecAdd(playerPos, VecScale(GetPlayerVelocity(GoreP), scale))\n"
     "end\n\n"
     "--- Used for targetting other npc torsos.\n"),
]

EDITS[G + "components/goreai_combat.lua"] = [
    ('local isPlayerInAvf = HasTag(GetPlayerVehicle(), "cfg")',
     'local isPlayerInAvf = HasTag(GetPlayerVehicle(GoreP), "cfg")'),
    ("                if GetPlayerVehicle() == 0 then\n                    -- player velocity offset\n"
     "                    local velScale = AutoMap(VecLength(GetPlayerVelocity()), 0, 4, 1, 1.2)\n",
     "                if GetPlayerVehicle(GoreP) == 0 then\n                    -- player velocity offset\n"
     "                    local velScale = AutoMap(VecLength(GetPlayerVelocity(GoreP)), 0, 4, 1, 1.2)\n"),
    ('            if GetFloat("level.player.health") < 175 then\n',
     '            if GoreAI_PlayerHealth(GoreP) < 175 then -- (v2 goreai) target player\'s limb health (v1: level.player.health)\n'),
    # gunshot sounds: v1 played the distant layer at the one player's position
    ("""        local camPos = GetPlayerTransform().pos
        local disttoplayer = VecDist(camPos, gunTr.pos) + 1

        PlaySound(npc.sounds.gunshot, gunTr.pos, 3)
        PlaySound(npc.sounds.DistGunShot, GetPlayerTransform().pos, AutoMap(disttoplayer, 10, 30, 0, 40))
""", """        -- (v2 goreai) the distant-shot layer plays at every player's position (v1: the one player);
        -- the medium/far layers use the nearest player's distance.
        local disttoplayer = math.huge
        for _, p in ipairs(GorePlayerIds) do
            local camPos = GorePlayers[p].pos
            local d = VecDist(camPos, gunTr.pos) + 1
            disttoplayer = math.min(disttoplayer, d)
            PlaySound(npc.sounds.DistGunShot, camPos, AutoMap(d, 10, 30, 0, 40))
        end
        if disttoplayer == math.huge then disttoplayer = 1 end

        PlaySound(npc.sounds.gunshot, gunTr.pos, 3)
"""),
    # near miss / fly-by: per player
    ("""    local Player
    if GetPlayerVehicle() == 0 then
        Player = VecAdd(GetPlayerTransform().pos, Vec(0, 1, 0))
    else
        Player = VecCopy(GetPlayerTransform().pos)
    end
    local Relative = VecSub(Player, point2)
    local Lookback = VecScale(VecNormalize(VecSub(point2,projectile.pos)), VecDot(Relative, VecNormalize(VecSub(point2,projectile.pos))))
    local Range = VecSub(Player, VecAdd(point2, Lookback))
""", """    -- (v2 goreai) v1 measured the miss distance to the one player; now to every player (Ranges[p]).
    local Ranges = {}
    for _, p in ipairs(GorePlayerIds) do
        local pl = GorePlayers[p]
        local Player = pl.vehicle == 0 and VecAdd(pl.pos, Vec(0, 1, 0)) or VecCopy(pl.pos)
        local Relative = VecSub(Player, point2)
        local Lookback = VecScale(VecNormalize(VecSub(point2,projectile.pos)), VecDot(Relative, VecNormalize(VecSub(point2,projectile.pos))))
        Ranges[p] = VecLength(VecSub(Player, VecAdd(point2, Lookback)))
    end
"""),
    ("""    if not npc.rpg and VecLength(Range) < (GetPlayerVehicle() == 0 and .5 or .3) and projectile.momentum ~= 0 then
        projectile.momentum = 0
        PlaySound(npc.sounds.rpgGunshot, GetPlayerTransform().pos, npc.disttoplayer / 10)
    end
""", """    for _, p in ipairs(GorePlayerIds) do
        if not npc.rpg and Ranges[p] < (GorePlayers[p].vehicle == 0 and .5 or .3) and projectile.momentum ~= 0 then
            projectile.momentum = 0
            PlaySound(npc.sounds.rpgGunshot, GorePlayers[p].pos, npc.disttoplayer / 10)
        end
    end
"""),
    ("""    if not projectile.playedb and not npc.rpg and projectile.momentum ~= 0 then
        if VecLength(Range) < crackrange/2 then
            PlaySound(LoadSound("MOD/snd/Projectiles/Flybys/"..passtype.."0.ogg"), GetPlayerTransform().pos, (crackrange/2-VecLength(Range))*2/crackrange)
            projectile.playedb = true
        end
        if VecLength(Range) < crackrange and npc.roundsize>1 then
            PlaySound(LoadSound("MOD/snd/Projectiles/Flybys/pistol_0.ogg"), GetPlayerTransform().pos, (crackrange-VecLength(Range))/crackrange)
            projectile.playedb = true
        end
    end

    if npc.BulletsShot > npc.oldbulletsshot then
        PlaySound(npc.sounds.DistGunShot, GetPlayerTransform().pos, 10/npc.disttoplayer)
        npc.oldbulletsshot = npc.BulletsShot
        projectile.playedb = false
    end
""", """    projectile.playedb_p = projectile.playedb_p or {} -- (v2 goreai) fly-by played, per player
    for _, p in ipairs(GorePlayerIds) do
        local Range, ppos = Ranges[p], GorePlayers[p].pos
        if not projectile.playedb_p[p] and not npc.rpg and projectile.momentum ~= 0 then
            if Range < crackrange/2 then
                PlaySound(LoadSound("MOD/snd/Projectiles/Flybys/"..passtype.."0.ogg"), ppos, (crackrange/2-Range)*2/crackrange)
                projectile.playedb_p[p] = true
            end
            if Range < crackrange and npc.roundsize>1 then
                PlaySound(LoadSound("MOD/snd/Projectiles/Flybys/pistol_0.ogg"), ppos, (crackrange-Range)/crackrange)
                projectile.playedb_p[p] = true
            end
        end
    end

    if npc.BulletsShot > npc.oldbulletsshot then
        for _, p in ipairs(GorePlayerIds) do
            local pl = GorePlayers[p]
            PlaySound(npc.sounds.DistGunShot, pl.pos, 10/(VecDist(npc.torsoPos or pl.aimPos, pl.aimPos) + 1))
        end
        npc.oldbulletsshot = npc.BulletsShot
        projectile.playedb_p = {}
    end
"""),
    ("""                distfromhittoplayer = VecLength(VecSub(GetPlayerCameraTransform().pos, hitPos))
                PlaySound(npc.sounds.rpghitdist, GetPlayerCameraTransform().pos, distfromhittoplayer / 10)
""", """                for _, p in ipairs(GorePlayerIds) do -- (v2 goreai) distant blast layer for every player
                    local camPos = GetPlayerCameraTransform(p).pos
                    distfromhittoplayer = VecLength(VecSub(camPos, hitPos))
                    PlaySound(npc.sounds.rpghitdist, camPos, distfromhittoplayer / 10)
                end
"""),
    # bullet vs player hitboxes: every player (v1: the one player's six triggers)
    ("    elseif not hit and projectile.active and not projectile.hitPlayer and VecDot(dir, DirLookAt(projectile.pos, PlayerPos)) > 0.5 then  -- Check is projectile hit player.\n",
     "    elseif not hit and projectile.active and not projectile.hitPlayer then  -- Check is projectile hit player.\n"
     "      -- (v2 goreai) every player whose aim point is ahead of the bullet (v1: the one player)\n"
     "      for _, hitP in ipairs(GorePlayerIds) do\n"
     "        if not projectile.hitPlayer and VecDot(dir, DirLookAt(projectile.pos, GorePlayers[hitP].aimPos)) > 0.5 then\n"),
    ("            for _, trigger in pairs(PlayerHitboxes) do -- Check each hitbox when projectile close enough\n",
     "            for _, trigger in pairs(GoreAI_Hitboxes(hitP)) do -- Check each hitbox when projectile close enough\n"),
    ("SetPlayerHealth(GetPlayerHealth() - (npc.pdamage/100))", "SetPlayerHealth(GetPlayerHealth(hitP) - (npc.pdamage/100), hitP)"),
    ("                    break -- Only hit one hitbox.\n\n                end\n\n            end\n        -- end\n",
     "                    break -- Only hit one hitbox.\n\n                end\n\n            end\n        -- end\n        end\n      end\n"),
    ("                if GetPlayerVehicle() ~= 0 then\n                    velScaled = VecLength(GetBodyVelocity(GetVehicleBody(GetPlayerVehicle())))\n",
     "                if GetPlayerVehicle(GoreP) ~= 0 then\n                    velScaled = VecLength(GetBodyVelocity(GetVehicleBody(GetPlayerVehicle(GoreP))))\n"),
    # v1 updated npc.aim.torso/gun (shooting needs aim.torso > NPC_AIM_MIN_ALIGN) inside draw_combat_details, a draw
    # function. In v2 draw runs on the client in its own Lua state, so the server's npcs never shot
    # [verified in-game 2026-11-06: align stayed 0.00]. Moved to the server (tick_npc_aim_alignment).
    ("                local dec = 0.2\n                local inc = 0.008\n"
     "                npc.aim.torso = lerp(npc.aim.torso, torso_align, ternary(npc.aim.torso < torso_align, inc, dec))\n"
     "                npc.aim.gun = lerp(npc.aim.gun, gun_align, ternary(npc.aim.gun < gun_align, inc, dec))\n",
     "                -- (v2 goreai) the npc.aim update moved to tick_npc_aim_alignment (server); draw runs on the client\n"),
    ("function draw_combat()\n", """--- (v2 goreai) Server, once per tick (v1 did this in draw_combat_details, once per frame): how well each npc's torso
--- and gun face their target. npc_manage_shooting only fires when npc.aim.torso > NPC_AIM_MIN_ALIGN.
--- Also clears the debug hit list, which v1 cleared in debug_npcs (draw).
function tick_npc_aim_alignment()
    for key, npc in pairs(NPCs) do
        if npc.Gun and npc.aim and npc.torsoTr and npc.ai.targeting.target and npc.ai.lookPos and npc.ai.shootPos then
            local gun_tr = GetBodyTransform(npc.Gun.body)
            local torso_align = 100 - QuatDiff(npc.torsoTr.rot, QuatLookAt(npc.torsoTr.pos, AutoVecSubsituteY(npc.ai.lookPos, npc.torsoTr.pos[2])))
            torso_align = torso_align/100
            local gun_align = QuatDiff(gun_tr.rot, QuatLookAt(gun_tr.pos, npc.ai.shootPos))
            gun_align = gun_align/100
            local dec = 0.2
            local inc = 0.008
            npc.aim.torso = lerp(npc.aim.torso, torso_align, ternary(npc.aim.torso < torso_align, inc, dec))
            npc.aim.gun = lerp(npc.aim.gun, gun_align, ternary(npc.aim.gun < gun_align, inc, dec))
        end
    end
    if not config.goreai.draw_projectile_impacts or #Debug_hitPositions_shapes > 200 then
        Debug_hitPositions_shapes = {}
    end
end

function draw_combat()
"""),
]

EDITS[G + "components/goreai_functions.lua"] = [
    ("if GetPlayerVehicle() ~= 0 then QueryRejectVehicle(GetPlayerVehicle()) end",
     "if GetPlayerVehicle(GoreP) ~= 0 then QueryRejectVehicle(GetPlayerVehicle(GoreP)) end"),
    ("if npc.ai.sitting.isSitting then QueryRejectVehicle(GetPlayerVehicle()) end",
     "if npc.ai.sitting.isSitting then QueryRejectVehicle(GetPlayerVehicle(GoreP)) end"),
    ("    QueryRejectBody(GetPlayerGrabBody())\n    QueryRejectBody(GetToolBody())\n",
     "    for _, p in ipairs(GorePlayerIds) do -- (v2 goreai) every player's grabbed body and tool\n"
     "        QueryRejectBody(GetPlayerGrabBody(p))\n        QueryRejectBody(GetToolBody(p))\n    end\n"),
]

EDITS[G + "components/goreai_melee.lua"] = [
    ("""                SetTag(GetRandomPairsValue(PlayerHitboxes), "QueriedDamage", RandomSpreadPercent25(npc.melee.punch_damage))
                SetFloat("level.advhealth.addShock", tonumber(GetString("level.advhealth.addShock")) + 1)
                SetPlayerVelocity(VecAdd(GetPlayerVelocity(), """,
     """                -- (v2 goreai) the target player's hitbox; shock goes to that player's client (health runs there)
                local hitbox = GetRandomPairsValue(GoreAI_Hitboxes(GoreP))
                if hitbox then SetTag(hitbox, "QueriedDamage", RandomSpreadPercent25(npc.melee.punch_damage)) end
                GoreAI_ClientCall(GoreP, "client.goreAddShock", 1)
                SetPlayerVelocity(VecAdd(GetPlayerVelocity(GoreP), """),
    ("RandomSpreadPercent25(math.random(5,8)))))\n", "RandomSpreadPercent25(math.random(5,8)))), GoreP)\n"),
]

EDITS[G + "components/goreai_robot_movement.lua"] = [
    ("npc.robot.playerPos = GetPlayerCameraTransform().pos",
     "npc.robot.playerPos = GetPlayerCameraTransform(GoreP).pos -- (v2 goreai) target player"),
    ("local pp = VecAdd(GetPlayerTransform().pos, Vec(0, 1, 0))", "local pp = VecAdd(GetPlayerTransform(GoreP).pos, Vec(0, 1, 0))"),
]

EDITS[G + "components/goreai_robot_navigation.lua"] = [
    ("\tQueryRejectVehicle(GetPlayerVehicle())\n", "\tQueryRejectVehicle(GetPlayerVehicle(GoreP)) -- (v2 goreai) target player\n"),
]

EDITS[G + "components/goreai_thinking.lua"] = [
    ("            if IsPlayerInVehicle() then\n",
     "            if GetPlayerVehicle(GoreP) ~= 0 then -- (v2 goreai) the target player (friendlies follow the nearest)\n"),
]

# systems/goreai_sitting.lua: hand-written since Phase 4 (NPCs use the vehicles' passenger seat rigs).

EDITS[G + "systems/goreai_grenades.lua"] = [
    ("\tif GetPlayerVehicle() ~= 0 then\n\t\tthrowTargetPos = VecAdd(throwTargetPos, GetBodyVelocity(GetVehicleBody(GetPlayerVehicle())))\n",
     "\tif GetPlayerVehicle(GoreP) ~= 0 then -- (v2 goreai) target player\n\t\tthrowTargetPos = VecAdd(throwTargetPos, GetBodyVelocity(GetVehicleBody(GetPlayerVehicle(GoreP))))\n"),
    ("""				if GetPlayerInteractBody() == grenade.body and InputPressed("interact") then
					local throwVel = VecScale(VecNormalize(VecSub(grenadePos,GetPlayerTransform().pos)), 15)
					SetBodyVelocity(grenade.body, throwVel)
				end
""", """				for _, p in ipairs(GorePlayerIds) do -- (v2) any player can throw it back
					if GetPlayerInteractBody(p) == grenade.body and InputPressed("interact", p) then
						local throwVel = VecScale(VecNormalize(VecSub(grenadePos,GetPlayerTransform(p).pos)), 15)
						SetBodyVelocity(grenade.body, throwVel)
					end
				end
"""),
    ('  spalling_sprite =  LoadSprite("MOD/img/spalling.png")\n',
     '  spalling_sprite = nil -- (v2) no API calls at load time; loaded in spalling_shrapnel_operations\n'),
    ("function spalling_shrapnel_operations(projectile,dt)\n",
     'function spalling_shrapnel_operations(projectile,dt)\n  spalling_sprite = spalling_sprite or LoadSprite("MOD/img/spalling.png")\n'),
    ("  local player_cam_pos = GetPlayerCameraTransform().pos\n  local player_pos = GetPlayerTransform().pos\n",
     "  local player_cam_pos = GetPlayerCameraTransform(GoreP).pos\n  local player_pos = GetPlayerTransform(GoreP).pos\n"),
]

EDITS[G + "systems/goreai_spawner.lua"] = [
    ('        if InputPressed("v") then\n            ViewCam = not ViewCam\n',
     '        if false and InputPressed("v") then -- (v2 goreai) spectator cameras (gore test map) need the client; disabled\n            ViewCam = not ViewCam\n'),
]

EDITS[G + "systems/goreai_API.lua"] = [
    ("""function API_npcs_alive(npcs)
    ClearKey(NPCS_API.npcs_alive)
    for index, npc in ipairs(npcs) do
        SetInt(NPCS_API.npcs_alive .. "." .. index, npc.Torso)
    end
end

function API_npcs_dead(npcs)
    ClearKey(NPCS_API.npcs_dead)
    for index, npc in ipairs(npcs) do
        SetInt(NPCS_API.npcs_dead .. "." .. index, npc.Torso)
        SetBool(NPCS_API.npcs_dead_id .. "." .. npc.id, true)
    end
end""", """-- (v2 goreai) The torso lists are read by clients too (script/Thermals.lua), so they are written with the
-- registry sync flag, and only when they change. Entries past the new end are set to 0 (clients may keep
-- keys the server cleared; readers skip 0) and then cleared.
local API_written = {}

local function API_write_torsos(base, npcs)
    local torsos = {}
    for index, npc in ipairs(npcs) do torsos[index] = npc.Torso end
    local sig = table.concat(torsos, ",")
    local last = API_written[base]
    if last and last.sig == sig then return end
    if not last then ClearKey(base) end
    for index, torso in ipairs(torsos) do
        SetInt(base .. "." .. index, torso, true)
    end
    for index = #torsos + 1, (last and last.count or 0) do
        SetInt(base .. "." .. index, 0, true)
        ClearKey(base .. "." .. index)
    end
    API_written[base] = { sig = sig, count = #torsos }
end

function API_npcs_alive(npcs)
    API_write_torsos(NPCS_API.npcs_alive, npcs)
end

function API_npcs_dead(npcs)
    API_write_torsos(NPCS_API.npcs_dead, npcs)
    for index, npc in ipairs(npcs) do
        SetBool(NPCS_API.npcs_dead_id .. "." .. npc.id, true)
    end
end"""),
]

# ---------------------------------------------------------------- hits, kills, bounty → the shooter's client
EDITS[G + "components/goreai_health.lua"] = [
    # (2026-11-07, in-game in horde: "goreai_health.lua:301 bad argument #2 to 'random'") original-mod bug: the dead
    # npc's gun loot string is read without a check; horde's WaveHandler strips every "Loot" tag, so it is empty
    ("""		local Gun = GetTagValue(npc.Gun.body, "Loot")
		DebugPrint(gun)
		GunInfos = Split(Gun, "_")
		GunInfos[5] = math.random(0,GunInfos[6])
		SetTag(npc.Gun.body, "Loot", table.concat(GunInfos,"_"))
""", """		local Gun = GetTagValue(npc.Gun.body, "Loot")
		-- (v2 goreai fix) no loot info (horde strips "Loot" tags) -> leave the gun as it is; v1 errored here.
		-- Also removed v1 leftover DebugPrint(gun) (undefined variable).
		GunInfos = Split(Gun, "_")
		if tonumber(GunInfos[6]) then
			GunInfos[5] = math.random(0, tonumber(GunInfos[6]))
			SetTag(npc.Gun.body, "Loot", table.concat(GunInfos,"_"))
		end
"""),
    # (2026-11-07, user decision) v1: blasts only drained the "shield" (bosses only; ordinary npcs have 0), so ordinary
    # npcs took no explosion damage at all - only physical gibbing. Now the rest goes to health like a bullet hit.
    ("                local damage = -HEALTH_EXPLOSION_DAMAGE * e.strength / (dist + 1)\n"
     "                npc_add_shield_amount(npc, damage)\n",
     "                local damage = HEALTH_EXPLOSION_DAMAGE * e.strength / (dist + 1)\n"
     "                -- (v2 goreai) the shield (bosses) absorbs first, the rest hurts health (v1: shield only)\n"
     "                local absorbed = math.min(npc.shield.value, damage)\n"
     "                npc_add_shield_amount(npc, -absorbed)\n"
     "                npc.health_damage_taken = npc.health_damage_taken + (damage - absorbed)\n"),
    ("    -- Check body part damage.\n    for _, body in ipairs(npc.bodyparts) do\n",
     "    -- (v2 goreai) who shot (gunfunctions / melee write the shooter's id; unknown = host)\n"
     '    local hitOwner = GoreAI_ResolvePlayer(GetInt("level.goreai.body_damage_player_owner"))\n\n'
     "    -- Check body part damage.\n    for _, body in ipairs(npc.bodyparts) do\n"),
    ("            mark_body_damaged_by_player(body)\n", "            mark_body_damaged_by_player(body, hitOwner)\n"),
    ("            if dmgs.player > 0 then\n\n                -- Hitmarker sound.\n",
     "            if dmgs.player > 0 then -- (v2 goreai) hitmarker icon + sound on the shooter's client\n"
     "                npc.lastHitPlayer = hitOwner\n"
     "                npc.lastHitTime = GetTime()\n"
     '                GoreAI_ClientCall(hitOwner, "client.goreHit", headshot and "headshot" or "hit", Hitmarker_Last_Pos)\n'
     "            end\n"
     "            if false then -- (v2) v1 local hitmarker code below, now hitmarker_receive (client)\n\n"
     "                -- Hitmarker sound.\n"),
    ("    --> Death hitmarkers.\n    if GetTableSize(Hitmarker_Icons) >= 1 then\n",
     "    --> Death hitmarkers. (v2 goreai: if a player hit it in the last 2/3 s, the hitmarker display time)\n"
     "    if npc.lastHitPlayer and GetTime() - (npc.lastHitTime or -10) < 2/3 then\n"),
    ("            add_hitmarker(Icons.headshot_dead)\n",
     '            GoreAI_ClientCall(npc.lastHitPlayer, "client.goreHit", "headshot_kill", GetBodyTransform(npc.Head).pos)\n'),
    ("            add_hitmarker(Icons.hitmarker_dead)\n",
     '            GoreAI_ClientCall(npc.lastHitPlayer, "client.goreHit", "kill", GetBodyTransform(npc.Torso).pos)\n'),
    ("        SetInt(reg, GetInt(reg) + 1)\n",
     '        GoreAI_ClientCall(npc.lastHitPlayer, "client.goreBounty", reg) -- (v2 goreai) the killer\'s savegame\n'),
]

EDITS[G + "systems/goreai_hitmarkers.lua"] = [
    ("function mark_body_damaged_by_player(b)\n\tKillcam_Data._player_damaged[b] = true\nend",
     """--- (v2 goreai) server: remember which player damaged body b this tick (for the killcam).
--- Also kept for 0.3 s of game time in _player_damaged_recent: the hit is processed one tick before the npc counts
--- as dead, and _player_damaged is cleared every tick, so v1's same-tick check missed every single-shot kill
--- [verified in-game 2026-11-06: 6 deaths, 0 killcams].
function mark_body_damaged_by_player(b, p)
	Killcam_Data._player_damaged[b] = p or GoreHost
	Killcam_Data._player_damaged_recent[b] = { p = p or GoreHost, t = GetTime() }
end

--- (v2 goreai) client: the server says the local player hit an npc (client.goreHit in goreai_main.lua).
--- kind = "hit" | "headshot" | "kill" | "headshot_kill". This is v1's code from npc_process_shield / npc_die.
function hitmarker_receive(kind, pos)
	if GetString("savegame.mod.difficulty") == "hardcore" then return end -- no hitmarkers on hardcore (v1 draw rule)
	if pos then Hitmarker_Last_Pos = VecCopy(pos) end
	if kind == "hit" or kind == "headshot" then
		if TimerConsumed(Sound_Timers.hitmarker) then
			TimerResetTime(Sound_Timers.hitmarker)
			table.insert(Hitmarker_Sounds, { sound = Sounds.hitmarker, vol = 2 })
			if kind == "headshot" then
				table.insert(Hitmarker_Sounds, { sound = Sounds.hitmarker_headshot1, vol = 0.25 })
				table.insert(Hitmarker_Sounds, { sound = Sounds.hitmarker_headshot2, vol = 0.55 })
			end
		end
		add_hitmarker(Icons.hitmarker) -- New/latest hitmarker resets total hitmarker display time.
		if kind == "headshot" then add_hitmarker(Icons.headshot) end
	elseif GetTableSize(Hitmarker_Icons) >= 1 then -- v1: death markers only while a hit marker shows
		add_hitmarker(kind == "headshot_kill" and Icons.headshot_dead or Icons.hitmarker_dead)
	end
end"""),
]

# systems/goreai_controller.lua: rewritten by hand 2026-11-07 (any player can control an npc), see the file.

# ---------------------------------------------------------------- outside GoreNPCs
EDITS["script/gunfunctions.lua"] = [
    # (2026-11-07, not goreai: kept here because this script rebuilds gunfunctions.lua) explains the infinite-ammo fix
    ("function checkUnlimitedBulletsValid()\n",
     "-- (v2 note 2026-11-07) Original-mod behaviour: an EMPTY gun with unlimited ammo turned on gets 1 round in a 1-round\n"
     "-- \"Infinite\" mag, but no bullet type for it (bullettable / item field 10 stay empty). FireRound then looked up type\n"
     "-- \"nil\" and errored on every shot; GunPerkFor (gunperks.lua) now fires such a round as the calibre's default.\n"
     "function checkUnlimitedBulletsValid()\n"),
    ('\t\t\tSetFloat("level.goreai.body_damage_player_vel_z", projectile.predictedBulletVelocity[3])\n',
     '\t\t\tSetFloat("level.goreai.body_damage_player_vel_z", projectile.predictedBulletVelocity[3])\n'
     '\t\t\tif doWorld then SetInt("level.goreai.body_damage_player_owner", projectile.owner or 0) end -- (v2 goreai) shooter, for hitmarkers/kills\n'),
]

EDITS["scripts/Weapons/Melee/Melee_Functions.lua"] = [
    ('ServerCall("server.meleeOps", MeleeNet.ops)', 'ServerCall("server.meleeOps", MeleeNet.ops, GetLocalPlayer())'),
    ("function server.meleeOps(ops)\n", "function server.meleeOps(ops, playerId)\n"),
    ('            SetFloat("level.goreai.body_damage_player_z", op.pos[3])\n',
     '            SetFloat("level.goreai.body_damage_player_z", op.pos[3])\n'
     '            SetInt("level.goreai.body_damage_player_owner", playerId or 0) -- (v2 goreai) who hit, for hitmarkers/kills\n'),
]

EDITS["HealthSystem/AdvancedHealthScript.lua"] = [
    ('\tSetFloat("level.player.health_max", TotalHealth)\n',
     '\tSetFloat("level.player.health_max", TotalHealth)\n'
     '\tHealthNet_ReportTotal(TotalHealth) -- (v2 goreai) NPCs aim worse at hurt players (was level.player.health)\n'),
    ("function server.healthSetPlayerHealth(p, h)\n",
     """-- (v2 goreai) Total limb health → server registry level.goreai.player_health.<p> (GoreAI_PlayerHealth).
local healthNetReported, healthNetReportTime = nil, -10
function HealthNet_ReportTotal(h)
	if healthNetReported ~= nil and h == healthNetReported then return end
	if healthNetReported ~= nil and math.abs(h - healthNetReported) < 5 and GetTime() - healthNetReportTime < 1 then return end
	healthNetReported, healthNetReportTime = h, GetTime()
	ServerCall("server.healthReport", GetLocalPlayer(), h)
end

function server.healthReport(p, h)
	SetFloat("level.goreai.player_health." .. p, h)
end

function server.healthSetPlayerHealth(p, h)
"""),
    # (Phase 3 batch A, 2026-11-06) death ragdoll velocity moved here from HealthSystem/launchragdoll.lua
    ('	Spawn("MOD/HealthSystem/prefab/" .. GetString("savegame.mod.difficulty") .. ".xml", pltrans)\n',
     '	local entities = Spawn("MOD/HealthSystem/prefab/" .. GetString("savegame.mod.difficulty") .. ".xml", pltrans)\n'
     '	-- (v2) the ragdoll keeps the player\'s momentum (v1 launchragdoll.lua did this on its first tick; that script is\n'
     '	-- now the client-side death camera only)\n'
     '	local vel = GetPlayerVelocity(p)\n'
     '	for _, e in ipairs(entities) do\n'
     '		if GetEntityType(e) == "body" and HasTag(e, "bodypart") then SetBodyVelocity(e, vel) end\n'
     '	end\n'),
    # (2026-11-07, tutorial round: sprint never worked) was a hand edit; kept here so a full re-run keeps it
    ("""function server.healthSetWalkingSpeed(p, s)
	SetPlayerWalkingSpeed(s, p)
end
""", """-- (v2 fix 2026-11-07) the engine resets the walking speed every frame (the official example sets it in every
-- server.tick), so a speed sent once was lost: sprint never worked. Remember each player's speed, apply every tick.
WalkingSpeeds = {}
function server.healthSetWalkingSpeed(p, s)
	WalkingSpeeds[p] = s
end

function server.tick(dt)
	for p, s in pairs(WalkingSpeeds) do
		if IsPlayerValid(p) then SetPlayerWalkingSpeed(s, p) else WalkingSpeeds[p] = nil end
	end
end
"""),
]

# script/Thermals.lua needs no change: its add() already skips torso 0 (stale synced list entries).


if __name__ == "__main__":
    files = sys.argv[1:] or list(EDITS)
    for f in files:
        apply(f, EDITS[f])

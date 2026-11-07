#version 2
--[[
#include "../../Config.lua"
#include "../../scripts/Game/Blood/Blood.lua"
#include "../../scripts/TDSU/tdsu.lua"
#include "../../Settings.lua"
#include "./goreai_manage.lua"
#include "Automatic.lua"
#include "components/goreai_bosses.lua"
#include "components/goreai_combat.lua"
#include "components/goreai_constructor.lua"
#include "components/goreai_controls.lua"
#include "components/goreai_friendlies.lua"
#include "components/goreai_functions.lua"
#include "components/goreai_health.lua"
#include "components/goreai_init.lua"
#include "components/goreai_instancing.lua"
#include "components/goreai_limbs.lua"
#include "components/goreai_melee.lua"
#include "components/goreai_movement.lua"
#include "components/goreai_navigation.lua"
#include "components/goreai_robot_movement.lua"
#include "components/goreai_robot_navigation.lua"
#include "components/goreai_targetting.lua"
#include "components/goreai_teams.lua"
#include "components/goreai_thinking.lua"
#include "components/goreai_ui.lua"
#include "debug/goreai_debug.lua"
#include "debug/goreai_prefab_tester.lua"
#include "other/RagdollPoseReader.lua"
#include "script/common.lua"
#include "script/include/player.lua"
#include "systems/goreai_API_nav.lua"
#include "systems/goreai_API.lua"
#include "systems/goreai_blood.lua"
#include "systems/goreai_controller.lua"
#include "systems/goreai_netview.lua"
#include "systems/goreai_grenades.lua"
#include "systems/goreai_hitmarkers.lua"
#include "systems/goreai_sitting.lua"
#include "systems/goreai_killcam.lua"
#include "systems/goreai_music.lua"
#include "systems/goreai_players.lua"
#include "systems/goreai_prefabs.lua"
#include "systems/goreai_ragdoll_poser.lua"
#include "systems/goreai_sounds.lua"
#include "systems/goreai_spawner.lua"
]]



--================================================================
-- Gore NPCs
-- By: Cheejins and SnakeyWakey
--================================================================
-- npc.ai.aimPos       = The position of the npc's target.
-- npc.ai.navPos       = The next nav point of the npc.
-- npc.nav.target      = Where the npc desires to navigate.
-- npc.ai.lookPos      = Where the npc desires to face towards.
-- npc.ai.shootPos     = Where the npc desires to point their gun.
-- npc.nav.path = Path nodes of the npc.
------------------------------------------------------------------
-- Most of the ai decision making is done in npc_Process_Thinking().
-- This code is kind of a mess and will be reworked later.
--================================================================
-- (v2, Mors Longa Revival) One manager script for all NPCs, spawned once by the first
-- goreai_initializer.lua. The AI (tick/update) runs on the SERVER; each NPC targets the nearest player
-- it can see (systems/goreai_players.lua: GoreP / PlayerPos are switched per NPC). Effects (sounds,
-- particles, lights) stay where v1 had them, i.e. on the server, as in the official v2 scripts.
-- The CLIENT does what needs a camera, UI or the local player: hitmarkers + their sounds, killcam,
-- combat music, debug/controller UI. Server → client messages: client.goreHit, client.goreKillcam,
-- client.goreBounty, client.goreAddShock (only to the player concerned, see GoreAI_ClientCall).
-- Boss health bars, the NPC debug overlays and "control an NPC" work on every client: the server publishes npc
-- records in shared.goreNpcs and each client rebuilds its own NPCs table from them (systems/goreai_netview.lua,
-- systems/goreai_controller.lua). Host server/client do not share Lua globals, so client NPCs ≠ server NPCs.
-- Constrain* calls must stay in server.update (update_npcs): v1 pointed/held the gun from tick, which crashed the
-- v2 engine on a worker thread (2026-11-07, see docs/TECHNICAL_REFERENCE.md).
--================================================================



NPCs = {} -- NPC objects created with npc_Create(id). Keys table.
NPC_Torsos = {} -- Find enemies by torsos
NPC_Bodies = {}

NPCS_TO_DELETE = {} -- Delete these npcs at the end of each tick when all npcs have been processed.
NPCS_TO_REMOVE = {} -- Delete these npcs at the end of each tick when all npcs have been processed.
REMOVE_DEAD_NPCS = false

UPDATE_INTERVAL = 1 -- Run every interval (3 = every 3 update calls). Used mainly for constant raycasting.
TICK_INTERVAL = 1
MAX_HIGH_REACTION_NPCS = 5 -- The npcs closest to their targets check if they can see their targets more frequently.

Explosions = {} -- Array of all explosions positions and their size per tick.

PlayerPos = Vec() -- (v2) set per npc by GoreAI_SetContext



------------------------------------------------------------------
-- Server
------------------------------------------------------------------

function server.init()

    SetBool("level.goreai_script_exists", true)

    IsHardcore = GetString("savegame.mod.difficulty") == "hardcore"

    Init_Settings()
    GoreAI_UpdatePlayers() -- also maps the players' hitbox triggers (v1 init_player_hitboxes)
    init_controls()
    init_config()
    init_sounds()
    init_bosses()
    init_gun_prefabs()

    UPDATE = 1
    TICK = 1

    SitLight = FindLight("seat", true)

    shared.goreNpcs = {}    -- (v2) npc records for the clients (goreai_netview.lua)
    shared.goreControl = {} -- (v2) [player] = key of the npc that player controls (goreai_controller.lua)

end

function server.tick(dt)

    -- (v2) v1 spawned MOD/Config.lua and the health script here when a level lacked them. Both are
    -- level scripts now (scripts/ConfigMenu.lua; HealthSystem + scripts/PlayerHitboxes.lua, which sets
    -- level.healthScriptSpawned), and the health script is per player on the client.

    if not config.goreai.isEnabled then
        return
    end

    GoreAI_UpdatePlayers()

    -- (v2) Explosions of this tick from engine events (v1: handleCommand "explosion <strength> x y z").
    Explosions = {}
    for i = 1, GetEventCount("explosion") do
        local pos, strength = GetEvent("explosion", i)
        table.insert(Explosions, { pos = VecCopy(pos), strength = strength })
    end

    Killcam_Data._player_damaged = {} -- (v1 reset this in tick_lockcam) [head body] = player who hit it

    DebugMode               = config.db
    AllExplosiveShapes      = {} -- FindShapes("explosive", true)
    ShouldDrawDebug         = config.goreai.draw_debug
    PlacetoolBodies         = AutoSplit(GetString("level.placetool.preview_bodies"), "_")
    NpcTeamsEnabled         = config.goreai.teams_enabled
    IsSandstorm             = GetBool("level.IsSandstorm")
    IsHardcore              = GetString("savegame.mod.difficulty") == "hardcore"
    IsGoreMap               = GetBool("level.goreai.gore_map")
    IncludePlayer           = config.goreai.teamsIncludePlayer
    DistanceProgressed      = GetFloat("savegame.mod.distanceProgressed")
    DayPhase                = GetString("level.dayphase")
    PlaceToolPreviewBody    = GetInt("level.placetool.preview_body")
    FriendliesCount         = 0
    SelectingControllerNPC  = GetBool("level.npcs.selectingControllerNPC")

    MapMoved              = GetBool("level.map_moved")
    MapMoveVec            = Vec(GetFloat("level.map_move_vec.1"), GetFloat("level.map_move_vec.2"), GetFloat("level.map_move_vec.3"))


    -- Mod level functions (No matter how tempted you are, don't sort by funciton name. It doesn't end well.)
    tick_combat()
    tick_teams()
    tick_grenades()
    tick_blood()
    tick_gun_class_unlocking()
    tick_lockcam_server()
    tick_spawners()
    tick_controller(dt)

    tick_deleting()
    tick_spawning()

    if not GetBool("level.deleteNPCs") then
        tick_npcs_info()
        tick_npcs(dt) -- Run functions for each npc.
        tick_npc_aim_alignment() -- (v2) was in draw_combat_details (draw)
    end

    GoreAI_SetPlayer(GoreHost)

    tick_bones()
    tick_sitting()
    tick_cleanup_leaks()
    GoreAI_PublishNPCs(dt)

    TICK = TICK + 1


end

function server.update(dt)

    if not config or not config.goreai.isEnabled then
        return
    end

    UPDATE = UPDATE + 1
    UPDATE_INTERVAL = 6
    -- UPDATE_INTERVAL = clamp(math.ceil(GetTableSize(NPCs)/2), 1, 6) -- Put npc thinking on a timed interval.
    IsUpdateInterval = UPDATE % UPDATE_INTERVAL == 1

    if not GetBool("level.deleteNPCs") then
        update_npcs(dt)
    end

    GoreAI_SetPlayer(GoreHost)

end



------------------------------------------------------------------
-- Client
------------------------------------------------------------------

function client.init()
    Init_Settings()
    init_config()
    init_sounds()
    init_hitmarkers()
    init_music()
end

function client.tick(dt)

    if not config.goreai.isEnabled then
        return
    end

    tick_timers()
    tick_sounds()
    tick_lockcam()
    tick_music()

    -- (v2) this client's view of the server's npcs (boss bars, debug overlays, controller)
    DebugMode = config.db
    NpcTeamsEnabled = config.goreai.teams_enabled
    IsGoreMap = GetBool("level.goreai.gore_map")
    GoreAI_RefreshClientNPCs()
    tick_controller_client(dt)

end

function client.draw()

    if not config.goreai.isEnabled then
        return
    end

    draw_npc_controller()
    draw_npcs()
    debug_npcs()
    draw_combat_details()
    if Settings.game.hitmarker.value then draw_hitmarkers() end
    -- if IsGoreMap then draw_combat() end


    if IsPlayerInVehicle() and IsSeatingEnabled then
        draw_vehicle_empty_seats(GetPlayerVehicle())
    end

    -- if config.db and GetTableSize(NPCs) >= 1 then
    --     local npc1 = NPCs[GetTableKeys(NPCs)[1]]
    --     npc_draw_debug_nav_api(npc1)
    -- end

end

--- (v2) A player's shot (gun or melee) hit an npc. kind = "hit" | "headshot" | "kill" | "headshot_kill".
function client.goreHit(target, kind, pos)
    if not GoreAI_IsMe(target) then return end
    hitmarker_receive(kind, pos)
end

--- (v2) An npc the local player shot in the head died this tick.
function client.goreKillcam(target, head, camPos, bodyparts)
    if not GoreAI_IsMe(target) then return end
    killcam_receive(head, camPos, bodyparts)
end

--- (v2) The local player killed an npc: count it on the local bounty board (savegame, per machine).
function client.goreBounty(target, reg)
    if not GoreAI_IsMe(target) then return end
    SetInt(reg, GetInt(reg) + 1)
end

--- (v2) An npc punched the local player (AdvancedHealthScript reads level.advhealth.addShock locally).
function client.goreAddShock(target, amount)
    if not GoreAI_IsMe(target) then return end
    SetFloat("level.advhealth.addShock", (tonumber(GetString("level.advhealth.addShock")) or 0) + amount)
end



---Spawn in a script node in the game world.
---@param path td_path
---@param ... string|number?
---@return script_handle
function AutoSpawnScript(path, ...)
	local f = [[<script file="%s" param0="%s" param1="%s" param2="%s" param3="%s"/>]]
	local param = { arg[1] or '', arg[2] or '', arg[3] or '', arg[4] or '' }
	return Spawn((f):format(path, unpack(param)), Transform())[1]
end

--- (v2) v1 mapped the single player's six hitbox triggers here; now per player in goreai_players.lua.
function init_player_hitboxes()
    GoreAI_ScanHitboxes()
end


--- (v2 perf 2026-11-07) Leaks from the original mod that only mattered on long runs (found with debug auto-travel:
--- 9 FPS at 10 km before, 22+ after):
---  1. npcs whose torso was deleted (RemoveRoad, behind the players) stayed in NPCs forever: drop them.
---  2. tick_deleting only empties NPCS_TO_DELETE when level.deleteNPCs is set, so every dead npc was appended again
---     each tick. Nothing else reads the list (level.deleteNPCs deletes all npcs anyway).
---  3. AVF spall shells are appended per grenade explosion but never processed (tick_spalling is never called).
function tick_cleanup_leaks()
    for id, npc in pairs(NPCs) do
        if not IsHandleValid(npc.Torso) then
            NPCs[id] = nil
            NPC_Torsos[npc.Torso] = nil
        end
    end
    NPCS_TO_DELETE = {}
    if spallHandler then spallHandler.shells = {} end
end

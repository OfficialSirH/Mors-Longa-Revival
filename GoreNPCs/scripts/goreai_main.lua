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
#include "systems/goreai_API_nav.lua"
#include "systems/goreai_API.lua"
#include "systems/goreai_blood.lua"
#include "systems/goreai_controller.lua"
#include "systems/goreai_grenades.lua"
#include "systems/goreai_hitmarkers.lua"
#include "systems/goreai_sitting.lua"
#include "systems/goreai_killcam.lua"
#include "systems/goreai_music.lua"
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



function init()

    SetBool("level.goreai_script_exists", true)

    IsHardcore = GetString("savegame.mod.difficulty") == "hardcore"

    Init_Settings()
    init_player_hitboxes()
    init_controls()
    init_config()
    init_sounds()
    init_bosses()
    init_gun_prefabs()
    init_hitmarkers()
    init_music()

    UPDATE = 1
    TICK = 1

    SitLight = FindLight("seat", true)

end

function tick(dt)

    if not GetBool("level.configScriptSpawned") then
        AutoSpawnScript("MOD/Config.lua")
        init_config()
        SetBool("level.configScriptSpawned", true)
        print("NPC script - manually spawned Config.lua")
    end

    if not GetBool("level.healthScriptSpawned") then
        Spawn(HealthScriptXML, Transform(), false, false)
        init_player_hitboxes()
        SetBool("level.healthScriptSpawned", true)
        print("NPC script - manually spawned health script")
    end

    if not config.goreai.isEnabled then
        return
    end

    DebugMode               = config.db
    AllExplosiveShapes      = {} -- FindShapes("explosive", true)
    ShouldDrawDebug         = config.goreai.draw_debug
    PlayerPos               = VecAdd(GetPlayerTransform().pos, Vec(0, 1, 0)) -- Adjusted player pos for npcs to aim at.
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
    tick_timers()
    tick_combat()
    tick_teams()
    tick_sounds()
    tick_grenades()
    tick_blood()
    tick_gun_class_unlocking()
    tick_lockcam()
    tick_spawners()
    tick_music()
    tick_controller(dt)

    tick_deleting()
    tick_spawning()

    if not GetBool("level.deleteNPCs") then
        tick_npcs_info()
        tick_npcs(dt) -- Run functions for each npc.
    end

    tick_bones()
    tick_sitting()

    TICK = TICK + 1

    -- if InputPressed(KeyInputs.lmb) then
    --     beep()
    --     npc_move_to_pos(GetRandomPairsValue(NPCs), GetCrosshairWorldPos(), true)
    -- end

end

function update(dt)

    if not config.goreai.isEnabled then
        return
    end

    UPDATE = UPDATE + 1
    UPDATE_INTERVAL = 6
    -- UPDATE_INTERVAL = clamp(math.ceil(GetTableSize(NPCs)/2), 1, 6) -- Put npc thinking on a timed interval.
    IsUpdateInterval = UPDATE % UPDATE_INTERVAL == 1

    if not GetBool("level.deleteNPCs") then
        update_npcs(dt)
    end

end

function draw()

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

    Explosions = {}


    -- if config.db and GetTableSize(NPCs) >= 1 then
    --     local npc1 = NPCs[GetTableKeys(NPCs)[1]]
    --     npc_draw_debug_nav_api(npc1)
    -- end

end



function handleCommand(cmd)
    check_explosions(cmd)
    handle_quickload(cmd)
end

function handle_quickload(cmd)
	for _, word in ipairs(splitString(cmd, " ")) do
		if word == "quickload" then
			init()
		end
		break
	end
end

function check_explosions(cmd)
    local words = splitString(cmd, " ")
    if #words == 5 then
        if words[1] == "explosion" then

            Explosions = {}

            table.insert(Explosions,
            {
                pos = Vec(
                    tonumber(words[3]),
                    tonumber(words[4]),
                    tonumber(words[5])),
                strength = tonumber(words[2])
            })

        end
	end
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

function init_player_hitboxes()
    Hitboxes = FindTriggers("hitbox", true)
    PlayerHitboxes = {}
    for _, hitbox in ipairs(Hitboxes) do
        PlayerHitboxes[GetTagValue(hitbox, "hitbox")] = hitbox
    end
end

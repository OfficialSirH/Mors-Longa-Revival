----------------------------------------------------------------
-- This script allows you to play as an npc.
----------------------------------------------------------------
-- (v2 goreai, rewritten by hand 2026-11-07) Debug feature "control an NPC" (debug menu → Select NPC to Control),
-- now for ANY player. The npc lives in the server's NPC table; the controlling client never sees it, so:
--   client (tick_controller_client): picks the npc (Torso body under the crosshair), runs the camera at the npc's head,
--     aims with a raycast and sends aim + keys every tick (server.goreControlInput). Ctrl+X stops.
--   server (tick_controller): drives the npc with those inputs; stops when the npc has been dead 3 s or the player left.
--   shared.goreControl[tostring(player)] = npc key: which npc a player controls. The client reads that npc's data
--     (team, gun, ammo) from shared.goreNpcs (systems/goreai_netview.lua) for the on-screen info.
-- v1 shared ControllerNPC between draw and tick in one script; on the host server and client do not share Lua globals.

ControllerNPC = nil   -- client: proxy of the npc the local player controls (goreai_netview.lua)
Controllers = {}      -- server: [player] = { npc, aim, move, shoot, reload }


function npc_controller_init(npc)

    -- The root camera which decides the npc's desired look direction while spectating or controlling.
    npc.controller = {
        camera = camera_create(nil, nil, 2, -1, 15)
    }

end

------------------------------------------------------------------ server

function server.goreControlStart(player, torso)
    local npc = NPC_Torsos[torso]
    if not npc or npc.dead then return end
    for p, c in pairs(Controllers) do
        if c.npc == npc and p ~= player then return end -- someone else controls it
    end
    Controllers[player] = { npc = npc, move = "", shoot = false, reload = false }
    shared.goreControl[tostring(player)] = tostring(npc.id)
end

function server.goreControlInput(player, x, y, z, move, shoot, reload)
    local c = Controllers[player]
    if not c then return end
    c.aim = Vec(x, y, z)
    c.move = move or ""
    c.shoot = shoot and true or false
    c.reload = c.reload or (reload and true or false) -- a press; consumed by the next server tick
end

function server.goreControlStop(player)
    local c = Controllers[player]
    if not c then return end
    if c.npc.torsoTr then
        SetPlayerTransform(TransformToParentTransform(c.npc.torsoTr, Transform(Vec(0,2,0))), player)
    end
    GoreAI_ControllerClear(player)
end

function GoreAI_ControllerClear(player)
    Controllers[player] = nil
    shared.goreControl[tostring(player)] = nil
end

function tick_controller(dt)

    local present = {}
    for p in Players() do present[p] = true end

    for player, c in pairs(Controllers) do
        local npc = c.npc
        if not present[player] or not IsHandleValid(npc.Torso) or npc.deadTime >= 3 then
            GoreAI_ControllerClear(player)
        else
            npc_controller_control(npc, dt, c, player)
        end
    end

end

function npc_controller_spectate(npc)
end

function npc_controller_control(npc, dt, c, player)

    SetPlayerTool("physgun", player) -- (v1: SetString("game.player.tool", "physgun")) keep the player's gun quiet
    -- (v2) v1 players had no visible model and walked along with the movement keys unseen; now the player is frozen
    -- and hidden while controlling (per tick, as the official spawn.lua / creativemode.lua do on the server)
    DisablePlayerInput(player)
    SetPlayerHidden(player)

    local p = c.aim
    if not p then return end

    npc.ai.aimPos = VecCopy(p)
    npc.ai.lookPos = VecCopy(p)
    npc.ai.shootPos = VecCopy(p)
    npc.ai.shootPosOffset = VecCopy(p)

    npc.nav.path = {}
    npc.nav.target = VecCopy(p)
    setRegTable(npc.nav.reg.tb_target, npc.nav.target)


    npc.running = false
    if c.move == "up" then
        hoverMove(npc, 3)
    elseif c.move == "down" then
        hoverMove(npc, -3)
    elseif c.move == "left" then
        hoverMove(npc, 3, "left")
    elseif c.move == "right" then
        hoverMove(npc, 3, "right")
    else
        npc.robot.speed = 0
        hoverMove(npc, 0)
    end

    if c.reload then
        npc.reloading = true
        c.reload = false
    end

    npc_stop_attacking(npc)
    npc_manage_shooting(npc, dt, c.shoot)

end

function IsControllerNPC(npc)
    for _, c in pairs(Controllers) do
        if c.npc == npc then return true end
    end
    return false
end

------------------------------------------------------------------ client

function tick_controller_client(dt)

    local me = GetLocalPlayer()

    if GetBool("level.npcs.selectingControllerNPC") then

        if InputPressed("rmb") then
            SetBool("level.npcs.selectingControllerNPC", false)
            return
        end

        local h, _, _, b = RaycastFromTransform(GetCameraTransform())
        local isTorso = h and HasTag(b, "Torso")
        if isTorso then DrawBodyOutline(b, 1, 1, 1, 1) DrawBodyHighlight(b, 1) end
        if (InputPressed("shoot") or InputPressed("lmb")) and isTorso then
            ServerCall("server.goreControlStart", me, b)
            SetBool("level.npcs.selectingControllerNPC", false)
        end
    end

    local npc = ControllerNPC
    if not npc or npc.key == ControllerStopSent then
        if not npc then ControllerStopSent = nil end
        ControllerCamera = nil
        return
    end

    if InputDown("ctrl") and InputPressed("x") then
        ServerCall("server.goreControlStop", me)
        ControllerStopSent = npc.key -- ignore this npc until the server's answer arrives
        SetBool("level.npcs.selectingControllerNPC", false)
        return
    end

    if ControllerCameraKey ~= npc.key then
        ControllerCamera = nil
    end
    ControllerCamera = ControllerCamera or camera_create(nil, nil, 2, -1, 15)
    ControllerCameraKey = npc.key

    local viewPos = AabbGetBodyCenterTopPos(npc.Head)
    camera_manage(ControllerCamera, viewPos, 0.5)

    local h, p = RaycastFromTransform(GetCameraTransform(), 500, nil, npc.AllBodies, nil, false)
    DrawDot(p, 0.2, 0.2, 1,0,0, 1)

    local move = ""
    if InputDown("up") then move = "up"
    elseif InputDown("down") then move = "down"
    elseif InputDown("left") then move = "left"
    elseif InputDown("right") then move = "right" end

    ServerCall("server.goreControlInput", me, p[1], p[2], p[3], move, InputDown("usetool"),
        KeybindPressed(Settings.keybinds.player.reload))

end

function draw_npc_controller()
    UiPush()
        if not ControllerNPC then

            if GetBool("level.npcs.selectingControllerNPC") then
                UiPush()
                    UiTranslate(UiCenter(), UiMiddle() + 100)
                    uiSetFont(32)
                    UiAlign("center middle")
                    UiText("Left click on an NPC to control it")
                    UiTranslate(0, 32)
                    UiText("Right click to cancel")
                UiPop()
            end

        else

            UiColor(1,1,1,1)
            UiAlign("center middle")

            UiPush()
                UiTranslate(UiCenter(), 100)
                uiSetFont(32)
                UiAlign("center middle")
                UiText('Press "ctrl" + "x" to stop controlling this npc.')
            UiPop()

            UiPush()
                UiTranslate(UiCenter(), UiMiddle())
                UiImageBox("MOD/img/icon_crosshair.png", 48, 48)
            UiPop()

            UiPush()

                UiTranslate(UiCenter() + 200, UiMiddle())
                uiSetFont(30)
                UiAlign("left top")

                local npc = ControllerNPC
                local team = NPC_TEAMS[npc.ai.teams.team] or NPC_TEAMS.none
                local npc_name = team.name
                if npc.boss.isBoss then npc_name = "BOSS: " .. npc_name end

                UiText(npc_name)
                UiTranslate(0, 40)

                if npc.Gun then
                    UiText(npc.Gun.gun_path or "")
                    UiTranslate(0, 40)
                end

                UiText((npc.MagSize or 1) - (npc.BulletsShot or 1) .. "/" ..  (npc.MagSize or 1) .. ternary(npc.reloading, " (Reloading)", ""))

            UiPop()

        end
    UiPop()
end

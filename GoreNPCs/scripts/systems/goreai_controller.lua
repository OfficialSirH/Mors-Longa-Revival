----------------------------------------------------------------
-- This script allows you to play as an npc.
----------------------------------------------------------------

ControllerNPC = nil


function npc_controller_init(npc)

    -- The root camera which decides the npc's desired look direction while spectating or controlling.
    npc.controller = {
        camera = camera_create(nil, nil, 2, -1, 15)
    }

end

function tick_controller(dt)

    if SelectingControllerNPC then

        if InputPressed("rmb") then
            SetBool("level.npcs.selectingControllerNPC", false)
            return
        end

        local h, _, _, b = RaycastFromTransform(GetCameraTransform())
        if HasTag(b, "Torso") then DrawBodyOutline(b, 1, 1, 1, 1) DrawBodyHighlight(b, 1) end
        if InputPressed("shoot") or InputPressed("lmb") then --##
            if h then
                if NPC_Torsos[b] then
                    ControllerNPC = NPC_Torsos[b]
                    SetBool("level.npcs.selectingControllerNPC", false)
                    -- print("ControllerNPC torso found: ", ControllerNPC.id, sfnTime()) --##
                -- else
                    -- print("ControllerNPC torso not found.", sfnTime()) --##
                end
            end
        end
    end

    if ControllerNPC and InputDown("ctrl") and InputPressed("x") then --##

        local npc = ControllerNPC
        SetPlayerTransform(TransformToParentTransform(npc.torsoTr, Transform(Vec(0,2,0))))

        ControllerNPC = nil
        SetBool("level.npcs.selectingControllerNPC", false)

    end

    if ControllerNPC then
        local npc = ControllerNPC
        if npc.deadTime < 3 then
            npc_controller_control(npc, dt)
        else
            ControllerNPC = nil
        end
    end

end

function draw_npc_controller()
    UiPush()
        if not ControllerNPC then

            if SelectingControllerNPC then
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
                local npc_name =  NPC_TEAMS[npc.ai.teams.team].name
                if npc.boss.isBoss then npc_name = "BOSS: " .. npc_name end

                UiText(npc_name)
                UiTranslate(0, 40)

                if npc.Gun then
                    UiText(npc.Gun.gun_path)
                    UiTranslate(0, 40)
                end

                UiText((npc.MagSize or 1) - (npc.BulletsShot or 1) .. "/" ..  (npc.MagSize or 1) .. ternary(npc.reloading, " (Reloading)", ""))

            UiPop()

        end
    UiPop()
end



function npc_controller_spectate(npc)
end

function npc_controller_control(npc, dt)

    SetString("game.player.tool", "physgun")

    local viewPos = AabbGetBodyCenterTopPos(npc.Head)
    camera_manage(npc.controller.camera, viewPos, 0.5)

    local h, p = RaycastFromTransform(GetCameraTransform(), 500, nil, npc.AllBodies, nil, false)
    DrawDot(p, 0.2, 0.2, 1,0,0, 1)

    npc.ai.aimPos = VecCopy(p)
    npc.ai.lookPos = VecCopy(p)
    npc.ai.shootPos = VecCopy(p)
    npc.ai.shootPosOffset = VecCopy(p)

    npc.nav.path = {}
    npc.nav.target = VecCopy(p)
    setRegTable(npc.nav.reg.tb_target, npc.nav.target)


    npc.running = false
    if InputDown("up") then
        hoverMove(npc, 3)
    elseif InputDown("down") then
        hoverMove(npc, -3)
    elseif InputDown("left") then
        hoverMove(npc, 3, "left")
    elseif InputDown("right") then
        hoverMove(npc, 3, "right")
    else
        npc.robot.speed = 0
        hoverMove(npc, 0)
    end

    if KeybindPressed(Settings.keybinds.player.reload) then
        npc.reloading = true
    end

    npc_stop_attacking(npc)
    npc_manage_shooting(npc, dt, InputDown("usetool"))

    -- DebugWatchNPC(npc, "Health", sfn(npc.health))
    -- DebugWatchNPC(npc, "Speed", sfn(GetBodySpeed(npc.Torso)))

end

function IsControllerNPC(npc)
    return npc == ControllerNPC
end
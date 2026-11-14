#version 2
#include "script/include/player.lua"

-- (v2) client: fuel, aim dots, sparks, sound, HUD. server: spawns the weld joints, deletes picked-up fuel.

WELD_RADIUS = 0.25
grabbing = false
gmod = false
HIDE_TEXT = false

function server.init()
    RegisterTool("welder", "Welding Tool", "MOD/assets/vox/Weld.vox", 4)
    for p in Players() do SetToolEnabled("welder", true, p) end
end

function server.tick(dt)
    for p in PlayersAdded() do SetToolEnabled("welder", true, p) end
end

function server.weld(pos)
    local xml = '<joint size="0.25" rotstrength="999" rotspring="0.8" collide="true"/>'
    Spawn(xml, Transform(pos), false, true)
end

function server.weldTakeFuel(body)
    if body ~= 0 and IsHandleValid(body) and HasTag(body, "weldfuel") then Delete(body) end
end

function client.init()

    WELD_RADIUS = GetInt("savegame.mod.weld_radius")
    if WELD_RADIUS == 0 then
        WELD_RADIUS = 0.25
    end
    grabbing = GetBool("savegame.mod.grabbing")
    gmod = GetBool("savegame.mod.gmod")
    HIDE_TEXT = GetBool("savegame.mod.hide_text")


    -- (v2) RegisterTool + enabling moved to server.init()
    loop = LoadLoop("tools/blowtorch-hit-loop.ogg", 1)
    maxfuel = 200
    fuel = maxfuel/4
end

function contains(table, val)
    for i = 1, #table do
        if table[i] == val then
            return true
        end
    end
    return false
end

function round(number)
    return math.floor(number + 0.5)
end

last_placed = 0
drawText = ""
drawText_b = 0
e = nil
grabbing = false
new_equip = false
gmod = false
gmod_o = nil

freeze_anim_body = nil
freeze_anim_time = 0

frozen_shapes = {}

function client.tick(dt)

    unlimitedammo = GetBool("savegame.mod.unlimitedammo")


    if HasTag(GetPlayerInteractBody(), "weldfuel") and InputPressed("interact") and fuel < maxfuel then
        fuel = math.min(fuel+math.random(maxfuel/8,maxfuel/4),maxfuel)
        ServerCall("server.weldTakeFuel", GetPlayerInteractBody())
    end

    if GetPlayerTool() == "welder" and not menuOpen and GetPlayerVehicle() == 0 then
        -- if fuel < 0 or fuel == 0 then
        --     if GetInt("inventory.count_slag") >= 1 then
        --         fuel = maxfuel
        --     end
        -- end

        local offset = Transform(Vec(0.5, -1.1, -0.8))
        SetToolTransform(offset)


        local hit, pos, shape, body, dist = _RaycastFromTransform(GetCameraTransform(), 10)

        if hit then
            DrawDot(pos, WELD_RADIUS, WELD_RADIUS, 1,1,1, 1/2, true, Vec(0, 0, 0))
            DrawDot(pos, WELD_RADIUS, WELD_RADIUS, 1,1,1, 1/2, true, Vec(0, 45, 0))
            DrawDot(pos, WELD_RADIUS, WELD_RADIUS, 1,1,1, 1/2, true, Vec(0, -45, 0))
            DrawDot(pos, WELD_RADIUS, WELD_RADIUS, 1,1,1, 1/2, true, Vec(0, 90, 0))
            -- PointLight(pos, 1,1,1, WELD_RADIUS)
        end

        if InputDown("usetool") and (fuel > 0 or unlimitedammo) then
            if hit then
                PlayLoop(loop, GetPlayerPos(), 1)

                ParticleReset()
                ParticleColor(1, 0.6, 0.4, 1, 0.3, 0.2)
                ParticleAlpha(1, 0)
                ParticleRadius(0.01)
                ParticleGravity(math.random(-10, -1))
                ParticleDrag(0)
                ParticleEmissive(math.random(2, 5), 0, "easeout")
                ParticleTile(3)
                for i = 1, 20 do
                    local v = Vec(math.random(-5, 5), math.random(-5, 5), math.random(-5, 5))
                    SpawnParticle(pos, v, 10)
                end

                if last_placed <= 0 then
                    last_placed = 0.1
                    ServerCall("server.weld", pos)

                    -- for _, entity in ipairs(entities) do
                    --     if GetEntityType(entity) == "joint" then

                    --         local joint = entity
                    --         local joint_body = GetShapeBody(GetJointOtherShape(joint))

                    --         Joint

                    --         DrawBodyHighlight(body)

                    --         local jointed_bodies = GetJointedBodies(joint_body)

                    --         for index, value in ipairs(jointed_bodies) do
                    --             if joint_body == value then
                    --                 DrawBodyHighlight(value)
                    --                 print("joint")
                    --             end
                    --         end

                    --     end
                    -- end

                end

            else
                PlayLoop(loop, GetPlayerPos(), 0.25)
            end
            if not unlimitedammo then
                fuel = fuel - dt*10
            end
            last_placed = last_placed - dt
        else
            last_placed = 0
        end

    else
        new_equip = true
    end
end

function client.draw()

    if GetPlayerTool() == "welder" and not menuOpen and GetPlayerVehicle() == 0 then

        UiTranslate(UiCenter(), UiHeight() - 60)
        UiFont("bold.ttf", 32)
        UiColor(1,1,1, 1)
        UiAlign("center middle")

        if unlimitedammo then
            UiText("Fuel: Infinite")
        else
            UiText("Fuel: " .. sfn(fuel) .. " / " .. maxfuel)
        end

    end

end

function DrawDot(pos, l, w, r, g, b, a, dt, rot)
    local dot = LoadSprite("ui/hud/dot-small.png")
    local spriteRot = QuatLookAt(pos, GetCameraTransform().pos)
    spriteRot = QuatRotateQuat(spriteRot, QuatEuler(rot or Vec(0,0,0)))
    local spriteTr = Transform(pos, spriteRot)
    if dt == nil then dt = true end
    DrawSprite(dot, spriteTr, l or 0.2, w or 0.2, r or 1, g or 1, b or 1, a or 1, dt and true)
end

--todo Use TDSU version
function _RaycastFromTransform(tr, distance, rad, rejectBodies, rejectShapes, returnNil)

    if distance == nil then distance = 300 end

    if rejectBodies ~= nil then for i = 1, #rejectBodies do QueryRejectBody(rejectBodies[i]) end end
    if rejectShapes ~= nil then for i = 1, #rejectShapes do QueryRejectShape(rejectShapes[i]) end end

    returnNil = returnNil or false

    local direction = QuatToDir(tr.rot)
    local h, d, n, s = QueryRaycast(tr.pos, direction, distance, rad)
    local p = TransformToParentPoint(tr, Vec(0, 0, d * -1))
    local b = GetShapeBody(s)

    return h, p, s, b, d, n

end

-- Quat to normalized dir.
function QuatToDir(quat) return VecNormalize(TransformToParentPoint(Transform(Vec(0,0,0), quat), Vec(0,0,-1))) end

function sfn(numberToFormat, dec)
    local s = (tostring(dec or 2))
    return string.format("%."..s.."f", numberToFormat)
end
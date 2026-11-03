function npc_is_in_position(npc)

    -- local navPosOffest = AutoVecSubsituteY(npc.ai.navPos, npc.hover.torsoPos[2]) -- Ignore height
    -- local navPosOffest = AutoVecSubsituteY(npc.ai.navPos or npc.hover.torsoPos, npc.hover.torsoPos[2])
    -- return VecDist(npc.hover.torsoPos, navPosOffest) < npc.ai.thinking.positioning.minDist

    return VecDist(npc.robot.transform.pos, npc.ai.navPos) < npc.ai.thinking.positioning.minDist

end

-- Set exact navigation position.
function npc_set_navigation_point(npc, pos)
    npc.ai.navPos = pos
    npc.navigation.hasNewTarget = true
    local groundPos = truncateToGround(pos, npc.AllBodies)
    npc_navigationSetTarget(npc, groundPos, npc.navigation.timeout)
    -- print("New navpoint set") --##
end

function npc_is_finished_navigating(npc)
    return #npc.nav.path <= 0 and npc_is_in_position(npc)
end

function npc_clear_navigation(npc)

    if config.goreai.dont_clear_nav then
        return
    end

    npc.navigation.hasNewTarget = true
    npc_navigationSetTarget(npc, VecAdd(npc.robot.transform.pos, VecScale(GetBodyVelocity(npc.Torso), 0.5)), npc.navigation.timeout)

end



function npc_check_if_should_reposition(npc)

    if GetBool("savegame.mod.goreai.reposition") then
        if TimerConsumed(npc.ai.timers.reposition) then -- Start reposition
            TimerResetTime(npc.ai.timers.reposition) -- Reset timer and wait until next reposition

            npc_reposition_normal(npc, npc.ai.aimPos, 10)
        end
    end

end

--Move near halfway pos to player
function npc_reposition_normal(npc, pos, spread)

    -- print("Repos normal") --##

    if spread then
        spread = spread or 15
        pos = VecAdd(VecAvg(pos, npc.torsoTr.pos), Vec(Random(-spread, spread), 0, Random(-spread, spread)))
    end

    npc_set_navigation_point(npc, pos)

end

--Move near halfway pos to player
function npc_reposition_aggressive(npc, pos, spread)

    -- print("Repos agg") --##

    local spread = 20
    local newpos = VecAdd(VecAvg(pos, npc.torsoTr.pos), Vec(Random(-spread, spread), 0, Random(-spread, spread)))

    npc_set_navigation_point(npc, newpos)

end

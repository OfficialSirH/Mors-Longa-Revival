HEALTH_DAMAGE_MULT            = 2
HEALTH_HEADSHOT_DAMAGE_MULT   = 3
HEALTH_HEADSHOT_STUN_MULT     = 1/20
HEALTH_IMPULSE_KNOCKBACK_MULT = 10


HEALTH_FIRE_DAMAGE        = 1 / 10 -- Damage per tick. Normal shield max amount is 100.
HEALTH_EXPLOSION_DAMAGE   = 200 -- Base damage multiplier for explosion strength, scaled down by distance from explosion.
HEALTH_EXPLOSION_MAX_DIST = 15 -- Linear progression to max damage (when dist closest 0).


function npc_init_health(npc, value, max)

    npc.health_percent            = 1
    npc.health_max                = 100
    npc.health_damage_taken       = 0
    npc.health_damage_taken_total = 0
    npc.health_damage_taken_timer = TimerCreateSeconds(0.3, true)


    npc.shield = {
        max   = value or 0,
        value = max or 0,
        tags  = {
            pdamage      = "level.goreai.body_damage_player.", -- From player
            pdamage_npc  = "level.goreai.body_damage_npc.",
        },
        took_damage = false,
        took_damage_player = false,
    }


    for index, body in ipairs(npc.bodyparts) do
        SetFloat(npc.shield.tags.pdamage .. body, 0)
        SetFloat(npc.shield.tags.pdamage_npc .. body, 0)
    end

    if npc.ai.teams.team == NPC_TEAMS.mil.title
	or npc.ai.teams.team == NPC_TEAMS.um.title
    then
		npc.health_max = 125
    elseif npc.isJuggernaut then
        npc.health_max = 500
	end

    npc.health = npc.health_max

end


function npc_process_health(npc)

    npc.took_damage = false

    -- DebugWatch("npc.health_percent", npc.health_percent)
    -- DebugWatch("npc.health_max", npc.health_max)
    -- DebugWatch("npc.health_damage_taken", npc.health_damage_taken)
    -- DebugWatch("npc.health_damage_taken_total", npc.health_damage_taken_total)
    -- DebugWatch("npc.health_damage_taken_timer", npc.health_damage_taken_timer)

    npc_calculate_proficiency(npc)

    npc_set_unbreakable(npc, npc.shield.value > 0 or config.goreai.invincible) -- Invincible

    -- Check for broken joints.
    for i = 1, #npc.AllJoints do
        if IsJointBroken(npc.AllJoints[i]) then
            npc.dead = true
        end
    end


    if not config.goreai.invincible then

        -- Health from 0 to 100.
        local healthPreprocessing   = npc.health or 100
        local health_percent_start  = 1 - npc.voxels_death
        local health_percent        = (npc.voxels / npc.voxels_start) - npc.voxels_death

        npc.health                  = health_percent / health_percent_start * 100
        npc.health_percent          = health_percent - npc.health_damage_taken_total

        npc.health                  = npc.health_max - npc.health_damage_taken_total -- Reduce health.


        if npc.health <= 0 then npc.dead = true end -- Check if npc died from low health.

        --todo npc.health.hp, npc.health.shield
        npc.took_damage = npc.voxels < npc.voxels_last or healthPreprocessing > npc.health
        if npc.took_damage then -- Check if npc took damage

            local drops_count = math.floor(npc.voxels_last - npc.voxels) -- Mass lost = number of drops.
            if Settings.game.blood_and_gore.value then
                local tr = GetBodyTransform(npc.Torso)
                tr.pos = npc.last_hit_pos
                blood_emitter_create(npc.Torso, tr, 2, 1, 0.15, drops_count, true)
            end

            npc_find_random_enemy(npc, config.goreai.teamsIncludePlayer)

        end

    end


end

--todo Invincible npcs do not process stun. Move stun out of health processing.
function npc_process_shield(npc)

    if not config.goreai.invincible then

        -- Process fire damage
        local fire_hit = QueryClosestFire(AabbGetBodyCenterBottomPos(npc.Torso), 2.5)
        if fire_hit then npc_add_shield_amount(npc, -HEALTH_FIRE_DAMAGE) end

        -- Process explosion damage.
        for index, e in ipairs(Explosions) do

            local dist = VecDist(AabbGetBodyCenterPos(npc.Torso), e.pos)
            if dist < HEALTH_EXPLOSION_MAX_DIST then

                local damage = HEALTH_EXPLOSION_DAMAGE * e.strength / (dist + 1)
                -- (v2 goreai) the shield (bosses) absorbs first, the rest hurts health (v1: shield only)
                local absorbed = math.min(npc.shield.value, damage)
                npc_add_shield_amount(npc, -absorbed)
                npc.health_damage_taken = npc.health_damage_taken + (damage - absorbed)

            end

        end

    end


    -- (v2 goreai) who shot (gunfunctions / melee write the shooter's id; unknown = host)
    local hitOwner = GoreAI_ResolvePlayer(GetInt("level.goreai.body_damage_player_owner"))

    -- Check body part damage.
    for _, body in ipairs(npc.bodyparts) do

        local dmgs = {
            player = tonumber(GetFloat(npc.shield.tags.pdamage .. body)) * HEALTH_DAMAGE_MULT,
            npc = tonumber(GetFloat(npc.shield.tags.pdamage_npc .. body)) * HEALTH_DAMAGE_MULT,
        }

        local damage_total = 0
        for key, dmg in pairs(dmgs) do
            damage_total = damage_total + dmg
        end

        if npc.shield.value <= 0 then
            npc.health_damage_taken = npc.health_damage_taken + ((RandomSpreadPercent25(damage_total * ternary(IsHardcore, 0.7, 0.9))) * 2)
        else
            npc_add_shield_amount(npc, -damage_total)
        end

        if config.goreai.invincible then
            dmgs.player = 0
            dmgs.npc = 0
        end

        if dmgs.player > 0 then
            mark_body_damaged_by_player(body, hitOwner)
        end

        local headshot = body == npc.Head or body == npc.Jaw or TableContainsValue(npc.Eyes, body)
        npc.shield.took_damage = dmgs.player > 0 or dmgs.npc > 0 -- Check npc took damage.
        npc.shield.took_damage_player = dmgs.player > 0
        if npc.shield.took_damage then -- npc was shot

            Hitmarker_Last_Pos = Vec(
                GetFloat("level.goreai.body_damage_player_x"),
                GetFloat("level.goreai.body_damage_player_y"),
                GetFloat("level.goreai.body_damage_player_z"))

            Hitmarker_Last_Vel = Vec(
                GetFloat("level.goreai.body_damage_player_vel_x"),
                GetFloat("level.goreai.body_damage_player_vel_y"),
                GetFloat("level.goreai.body_damage_player_vel_z"))


            if headshot and math.random() < 0.7 then

                damage_total = damage_total * RandomSpreadPercent25(HEALTH_HEADSHOT_DAMAGE_MULT)

                local stunMult = ternary(npc.isJuggernaut, 0.25, 1)

                npc.ai.stun.duration = clamp(
                    npc.ai.stun.duration + (damage_total * stunMult * RandomSpreadPercent25(HEALTH_HEADSHOT_STUN_MULT)),
                    math.random(),
                    2.5 + RandomSpreadPercent50(math.random()))

                npc.headshot = true

                npc_voice_play_timed(npc, npc.voice.sounds.hard, npc.torsoPos, 1)

            else

                npc_voice_play_timed(npc, npc.voice.sounds.hit, npc.torsoPos, 1)

            end

            local impulse_scale = damage_total * RandomSpreadPercent25(HEALTH_IMPULSE_KNOCKBACK_MULT)
            local impulse = VecScale(VecNormalize(Hitmarker_Last_Vel), impulse_scale)
            ApplyBodyImpulse(body, Hitmarker_Last_Pos, impulse)

            if dmgs.player > 0 then -- (v2 goreai) hitmarker icon + sound on the shooter's client
                npc.lastHitPlayer = hitOwner
                npc.lastHitTime = GetTime()
                GoreAI_ClientCall(hitOwner, "client.goreHit", headshot and "headshot" or "hit", Hitmarker_Last_Pos)
            end
            if false then -- (v2) v1 local hitmarker code below, now hitmarker_receive (client)

                -- Hitmarker sound.
                if TimerConsumed(Sound_Timers.hitmarker) then
                    TimerResetTime(Sound_Timers.hitmarker)

                    table.insert(Hitmarker_Sounds, { sound = Sounds.hitmarker, vol = 2 })

                    if dmgs.player and headshot then
                        table.insert(Hitmarker_Sounds, { sound = Sounds.hitmarker_headshot1, vol = 0.25 })
                        table.insert(Hitmarker_Sounds, { sound = Sounds.hitmarker_headshot2, vol = 0.55 })
                    end

                end

                -- New/latest hitmarker resets total hitmarker display time.
                add_hitmarker(Icons.hitmarker)

                -- Select icons to be displayed.
                -- if npc.shield.value > 0 then
                    -- AddHitmarker(Icons.shield)
                -- end

                if headshot then
                    add_hitmarker(Icons.headshot)
                end

            end

        end


        -- > Time between last player damage to npc and death for more lenient bounty board kill tracking.
        if dmgs.player > 0 then
			npc.health_damage_taken_timer = TimerCreateSeconds(1) -- Time between valid hits to count as kills.
		end
		TimerRunTime(npc.health_damage_taken_timer)

    end


    -- Reset registry damage scanner.
    for _, body in ipairs(npc.bodyparts) do
        for _, tag in pairs(npc.shield.tags) do
            SetFloat(tag .. body, 0)
        end
    end

    npc.health_damage_taken_total = npc.health_damage_taken_total or 0
    npc.health_damage_taken_total = npc.health_damage_taken_total + npc.health_damage_taken

end

function Split(s, delimiter)
    local result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result;
end

function npc_die(npc)

    --> Torso dead tag.
    SetTag(npc.Torso, "dead")

    --> Death hitmarkers. (v2 goreai: if a player hit it in the last 2/3 s, the hitmarker display time)
    if npc.lastHitPlayer and GetTime() - (npc.lastHitTime or -10) < 2/3 then

        if npc.headshot then

            GoreAI_ClientCall(npc.lastHitPlayer, "client.goreHit", "headshot_kill", GetBodyTransform(npc.Head).pos)

            local tr = Transform(GetBodyTransform(npc.Head).pos, GetBodyTransform(npc.Torso).rot)
            if Settings.game.blood_and_gore.value then
                blood_emitter_create(npc.Head, Transform(), 10, 1, 0.005, math.random(15, 20), true)
            end

        else

            GoreAI_ClientCall(npc.lastHitPlayer, "client.goreHit", "kill", GetBodyTransform(npc.Torso).pos)

        end
    end
	if npc.Gun then
		local Gun = GetTagValue(npc.Gun.body, "Loot")
		-- (v2 goreai fix) no loot info (horde strips "Loot" tags) -> leave the gun as it is; v1 errored here.
		-- Also removed v1 leftover DebugPrint(gun) (undefined variable).
		GunInfos = Split(Gun, "_")
		if tonumber(GunInfos[6]) then
			GunInfos[5] = math.random(0, tonumber(GunInfos[6]))
			SetTag(npc.Gun.body, "Loot", table.concat(GunInfos,"_"))
		end
        RemoveTag(npc.Gun.body, "gore_id")
	end
	if math.random() < .15 then
		for i=1,math.random(1,5) do
			local tr = Transform(GetBodyTransform(npc.Torso).pos, GetBodyTransform(npc.Torso).rot)
			Spawn("MOD/prefabs/moneydrop.xml", tr)
		end
	elseif math.random() < .05 then
			local tr = Transform(GetBodyTransform(npc.Torso).pos, GetBodyTransform(npc.Torso).rot)
			Spawn("MOD/loots/grenade.xml", tr)
	end
	if math.random() < .015 then
		local number = math.random(1,2)
		if number == 1 then
			Spawn("MOD/loots/food5.xml", Transform(GetBodyTransform(npc.Torso).pos, GetBodyTransform(npc.Torso).rot))
		elseif number == 2 then
			local foodtable = {"food1","food4","food9","food10","food21","food22","food23","food25","food26","food27","food28"}
			Spawn("MOD/loots/" .. foodtable[math.random(1,#foodtable)].. ".xml", Transform(GetBodyTransform(npc.Torso).pos, GetBodyTransform(npc.Torso).rot))
		
		end
	end

	if GetString("savegame.mod.difficulty") == "hardcore" then
		Multiplier = 3
	else
		Multiplier = 1
	end

    --> Death sound.
    if math.random() < 0.75 and GetTime() < npc.voice.playTimestamp then
        -- PlaySound(
        --     LoadSound("MOD/main/GoreRagdolls2/snd/death" .. math.random(2, 5) .. ".ogg"),
        --     GetBodyTransform(npc.Head).pos)
        PlaySound(GetRandomArrayValue(npc.voice.sounds.death), npc.torsoPos, 1)
    end

    --> Killcam
    if IsBodyBroken(npc.head) or IsShapeBroken(npc.jaw) then
        npc.showkill = true
    end

    --> Create blood emitter
    if Settings.game.blood_and_gore.value then
        blood_emitter_create(npc.Torso, GetBodyTransform(npc.Torso), 5, 0.5, 0.05, math.random(25, 40), true)
    end

    --> Spawn loot
    if npc.Gun and math.random() < 0.75/Multiplier then
        --todo make a spawned entities tagger and remove extra unneeded tags.
        local entities = Spawn(LootsPath .. npc.Gun.ammo_path, Transform(TransformToParentPoint(GetBodyTransform(npc.Torso),Vec(0,0,.3))))
        for index, e in ipairs(entities) do
            SetTag(e, "unbreakable")
        end
    end

    --> Increment Bounty Board
    if not npc.bounty_complete and not TimerConsumed(npc.health_damage_taken_timer) then
        local reg = BountyBoardPaths[npc.ai.teams.team]
        if npc.boss.isBoss then reg = BountyBoardPaths["boss_" .. npc.ai.teams.team] end
        GoreAI_ClientCall(npc.lastHitPlayer, "client.goreBounty", reg) -- (v2 goreai) the killer's savegame
        npc.bounty_complete = true
    end

    --todo find reason why shape body stays nondynamic
    for _, body in ipairs(npc.AllBodies) do
        for _, shape in ipairs(GetBodyShapes(body)) do
            if HasTag(shape, "HEAD_EXTRAS") or HasTag(shape, "TORSO_EXTRAS") then
                -- DrawShapeOutline(shape, 1,0,0, 1)
                if not IsBodyDynamic(body) then
                --     SetBodyDynamic(body, true)
                --     DebugWatch(GetShapeBody(shape), "active:"..tostring(IsBodyActive(body)) .. ", " .. "dynamic:"..tostring(IsBodyDynamic(body)))
                    Delete(shape)
                end
            end
        end
    end

    for _, s in ipairs(GetBodyShapes(npc.Head)) do
        SetShapeEmissiveScale(s, 0)
    end

    TableRemoveUniqueValue(SeatsTaken, npc.ai.sitting.sitLight)
    npc.ai.sitting.sitLight = 0

end

function npc_add_shield_amount(npc, amount)
    npc.shield.value = clamp(npc.shield.value + amount, 0, npc.shield.max)
end

--todo Apply to guns that npcs pick up and drop.
-- Makes all of an npc's bodies (except its gun) unbreakable.
function npc_set_unbreakable(npc, state)

    if npc.unbreakable == state then -- Change state only when needed.
        return
    end

    -- Choose tag function.
    local func = ternary(state, SetTag, RemoveTag)

    -- Make all bodies unbreakable.
    for _, body in ipairs(npc.AllBodies) do func(body, "unbreakable") end

    -- Guns should always be unbreakable.
    if npc.Gun then SetTag(npc.Gun, "unbreakable") end

    npc.unbreakable = state

end

#version 2
DL_LABEL = "PlayerHitboxes"  -- crash breadcrumbs (lib/DeleteLog.lua)
#include "../lib/DeleteLog.lua"
#include "script/include/player.lua"

-- (v2, Phase 2) Server: one set of six hitbox triggers per player.
--
-- NPC / helicopter / boss scripts find the player by FindTriggers("hitbox") and write the damage of a hit into
-- the trigger's "QueriedDamage" tag. Those scripts stay unchanged. This script:
--   * gives the host the level's own six triggers (children of the health script in level_scripts.xml),
--     so single-player behaves as before, and spawns a set for every other player;
--   * keeps each set on its player every tick (same offsets as AdvancedHealthScript's SetHitboxes);
--   * forwards any QueriedDamage to the owning player's client and resets the tag. ClientCall only reaches this
--     script, so client.hitboxDamage below adds it to the client's local registry key
--     "health.incoming.<PART>", which AdvancedHealthScript.lua (per player, on the client) reads and clears.
--   * relays engine explosion events to every client (v1 used handleCommand("explosion ...")), queued in the
--     client's local registry "health.explosions" as "strength x y z;" entries.
-- GoreNPCs maps one hitbox per limb name (init_player_hitboxes), so NPCs only target the host's set until
-- Phase 3 (NPC targeting per player).

local PARTS = { "HEAD", "TORSO", "LARM", "RARM", "LLEG", "RLEG" }

local TRIGGER_XML = [[
<prefab version="1.5.0">
	<group>
		<trigger tags="hitbox=HEAD QueriedDamage=0 hitbox_player=%d" pos="0.0 1.4 0.05" type="box" size=".3 .3 .3"/>
		<trigger tags="hitbox=LARM QueriedDamage=0 hitbox_player=%d" pos="0.35 0.6 0.0" type="box" size=".2 .7 .2"/>
		<trigger tags="hitbox=LLEG QueriedDamage=0 LLEG hitbox_player=%d" pos="0.15 0.0 0.0" type="box" size=".2 .7 .2"/>
		<trigger tags="hitbox=RARM QueriedDamage=0 hitbox_player=%d" pos="-0.35 0.6 0.0" type="box" size=".2 .7 .2"/>
		<trigger tags="hitbox=RLEG QueriedDamage=0 RLEG hitbox_player=%d" pos="-0.15 0.0 0.0" type="box" size=".2 .7 .2"/>
		<trigger tags="hitbox=TORSO QueriedDamage=0 TORSO hitbox_player=%d" pos="0.0 0.8 0.0" type="box" size=".5 .6 .3"/>
	</group>
</prefab>
]]

-- Offsets from AdvancedHealthScript.lua SetHitboxes (relative to camera position + player rotation).
local MINUSED = 2.3
local OFFSET_ON_FOOT = {
	HEAD  = Vec(0, 2.2 - MINUSED, 0),
	TORSO = Vec(0, 1.8 - MINUSED, 0),
	LARM  = Vec(-0.4, 1.6 - MINUSED, 0),
	RARM  = Vec(0.4, 1.6 - MINUSED, 0),
	LLEG  = Vec(-0.2, 1 - MINUSED, 0),
	RLEG  = Vec(0.2, 1 - MINUSED, 0),
}
local OFFSET_IN_VEHICLE = {
	HEAD  = Vec(0, 2.2 - MINUSED, 0),
	TORSO = Vec(0, 1.8 - MINUSED, 0),
	LARM  = Vec(0, 1.6 - MINUSED, 0),
	RARM  = Vec(0, 1.6 - MINUSED, 0),
	LLEG  = Vec(0, 1.6 - MINUSED, 0),
	RLEG  = Vec(0, 1.6 - MINUSED, 0),
}

function server.init()
	SetBool("level.healthScriptSpawned", true, true) -- NPCs write hitbox damage only when this is set
	HitboxSets = {}     -- [player] = { spawned = bool, triggers = { [part] = handle } }
	LevelSet = {}       -- the level's own triggers (no hitbox_player tag), given to the host
	for _, t in ipairs(FindTriggers("hitbox", true)) do
		if not HasTag(t, "hitbox_player") then LevelSet[GetTagValue(t, "hitbox")] = t end
	end
	for p in Players() do AssignHitboxes(p) end
end

function AssignHitboxes(p)
	if HitboxSets[p] then return end
	if IsPlayerHost(p) and LevelSet.HEAD then
		HitboxSets[p] = { spawned = false, triggers = LevelSet }
		return
	end
	local xml = string.format(TRIGGER_XML, p, p, p, p, p, p)
	local set = { spawned = true, triggers = {} }
	for _, e in ipairs(Spawn(xml, GetPlayerTransform(p))) do
		if GetEntityType(e) == "trigger" then set.triggers[GetTagValue(e, "hitbox")] = e end
	end
	HitboxSets[p] = set
end

function server.tick(dt)
	for p in PlayersAdded() do AssignHitboxes(p) end
	for p in PlayersRemoved() do
		local set = HitboxSets[p]
		if set and set.spawned then
			for _, t in pairs(set.triggers) do if IsHandleValid(t) then Delete(t) end end
		end
		HitboxSets[p] = nil
	end

	local count = GetEventCount("explosion")
	for i = 1, count do
		local pos, strength = GetEvent("explosion", i)
		ClientCall(0, "client.explosionEvent", strength, pos)
	end

	for p in Players() do
		local set = HitboxSets[p]
		if set then
			local vehicle = GetPlayerVehicle(p)
			local offsets = vehicle ~= 0 and OFFSET_IN_VEHICLE or OFFSET_ON_FOOT
			local pct = Transform(GetPlayerCameraTransform(p).pos, GetPlayerTransform(p).rot)
			local carry = vehicle ~= 0 and VecScale(GetBodyVelocity(GetVehicleBody(vehicle)), 1/30) or nil
			for _, part in ipairs(PARTS) do
				local t = set.triggers[part]
				if t and IsHandleValid(t) then
					local tr = TransformToParentTransform(pct, Transform(offsets[part]))
					if carry then tr.pos = VecAdd(tr.pos, carry) end
					SetTriggerTransform(t, tr)

					local damage = tonumber(GetTagValue(t, "QueriedDamage")) or 0
					if damage ~= 0 then
						SetTag(t, "QueriedDamage", 0)
						ClientCall(p, "client.hitboxDamage", part, damage)
					end
				end
			end
		end
	end
end

-- Runs on the damaged player's machine only (local registry, not synced).
function client.hitboxDamage(part, damage)
	local key = "health.incoming." .. part
	SetFloat(key, GetFloat(key) + damage)
end

function client.explosionEvent(strength, pos)
	SetString("health.explosions", GetString("health.explosions") ..
		string.format("%f %f %f %f;", strength or 0, pos[1], pos[2], pos[3]))
end

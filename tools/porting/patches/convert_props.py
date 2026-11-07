#!/usr/bin/env python3
"""Phase 3 batch A: small world-prop scripts v1 -> v2 (server), via convert_server.convert (in place, asserted).

Player-dependent bits become "any player" / "nearest player"; client-only work goes through ClientCall.
HealthSystem/launchragdoll.lua (death camera) is client-only and written by hand (see the file).
Usage (repo root): python3 tools/porting/patches/convert_props.py [file ...]   (each file only once: asserts v1)
"""
import os, sys
sys.path.insert(0, os.path.dirname(__file__))
from convert_server import convert

NEAREST = """
-- (v2) nearest player to pos (0 = host if there are none)
function NearestPlayer(pos)
	local best, bestD = 0, math.huge
	for p in Players() do
		local d = VecLength(VecSub(GetPlayerTransform(p).pos, pos))
		if d < bestD then best, bestD = p, d end
	end
	return best, bestD
end
"""

HELI_CREW = [
    ("function handleCommand(cmd) handle_quickload(cmd) end\n",
     "-- (v2) v1 quickload hook removed: it called Init_Settings, which this script never defines (error on quickload)\n"),
]

EDITS = {
"script/grenade.lua": ("server: RPG-7 rocket (player RPG and NPC RPGs): thrust, fuse, explosion, fire; proximity fuse for ANY player.", [
    ("     if VecLength(VecSub(VecAdd(GetPlayerTransform().pos, Vec(0, 0.5, 0)), GetShapeWorldTransform(munition).pos)) < 1.2 and primed then\n",
     "     if NearestPlayerDist(GetShapeWorldTransform(munition).pos, 0.5) < 1.2 and primed then -- (v2) any player\n"),
    ("  elseif VecLength(VecSub(GetPlayerTransform().pos, GetShapeWorldTransform(munition).pos)) < 1.2 then\n",
     "  elseif NearestPlayerDist(GetShapeWorldTransform(munition).pos, 0) < 1.2 then -- (v2) any player\n"),
    # (2026-11-07, user decision) the loaded rocket type: script/RPG.lua sends it right before the spawn
    ("""     --SetString("savegame.mod.rpg_type",rpg_type)
  end
""", """     --SetString("savegame.mod.rpg_type",rpg_type)
  end
  -- (v2 fix) v1 never set rpg_type, so every rocket was the PG-7V; the player's RPG now reports the loaded rocket
  -- just before spawning it (server.rpgNextRocket). Read once and cleared, so NPC rockets keep the default.
  if GetString("level.rpg.next_rocket") ~= "" then
     rpg_type = GetString("level.rpg.next_rocket")
     SetString("level.rpg.next_rocket", "")
  end
"""),
    # (2026-11-07) impact detected by RocketImpactTick (appended below) also detonates
    ("""          VecLength(GetBodyVelocity(body)) * GetTimeStep(),
          0.2)
""", """          VecLength(GetBodyVelocity(body)) * GetTimeStep(),
          0.2)
        if ForceImpact then hit = true end -- (v2 fix) see RocketImpactTick
"""),
    ("""           local explode_pos = TransformToParentPoint(GetShapeWorldTransform(munition), Vec(0, weapon.explosionSize * .7,
           0.3))
""", """           local explode_pos = TransformToParentPoint(GetShapeWorldTransform(munition), Vec(0, weapon.explosionSize * .7,
           0.3))
           -- (v2 fix) found by the impact ray: explode where it hit (the rocket may have bounced / turned since)
           if ForceImpact and ImpactPos then explode_pos = ImpactPos end
"""),
    ("function clamp(val, lower, upper)\n", """-- (v2) distance from pos to the nearest player (feet + up metres)
function NearestPlayerDist(pos, up)
  local d = math.huge
  for p in Players() do
    d = math.min(d, VecLength(VecSub(VecAdd(GetPlayerTransform(p).pos, Vec(0, up or 0, 0)), pos)))
  end
  return d
end

function clamp(val, lower, upper)
"""),
]),
"scripts/Debri.lua": ("server: burning debris thrown from wrecked cars, explodes after a while.", []),
"scripts/parachute.lua": ("server: supply-drop parachute drag; removed near the ground.", [
    ("\tDebugPrint(height)\n", "\t-- (v2) removed v1 leftover DebugPrint(height) (printed nil on screen every frame)\n"),
]),
"scripts/engineprops.lua": ("server: spins the supply plane's propeller joint.", []),
"scripts/simplerotate.lua": ("server: rotating joint prop.", []),
"scripts/WarehouseCollapse.lua": ("server: warehouse roof may collapse when ANY player enters the trigger.", [
    ("""	local PlayerPos = GetPlayerTransform().pos
	if IsPointInTrigger(RCollapse, PlayerPos) and not Triggered then
""", """	local inside = false -- (v2) any player
	for p in Players() do
		if IsPointInTrigger(RCollapse, GetPlayerTransform(p).pos) then inside = true end
	end
	if inside and not Triggered then
"""),
]),
"scripts/Binge.lua": ("server: shrine; any player can pray (interact); its 2D sounds play on every client.", [
    ("\t\t\tPlaySound(AUGH)\n", '\t\t\tClientCall(0, "client.bingeSound", "MOD/snd/Enemies/Boss/Binge.ogg") -- (v2) 2D sound for everyone\n'),
    ("""	if InputPressed("Interact") and GetPlayerInteractShape() == Shrine and not prayed then
		PlaySound(Gurenya)
""", """	local prayer = nil -- (v2) any player
	for p in Players() do
		if InputPressed("interact", p) and GetPlayerInteractShape(p) == Shrine then prayer = p end
	end
	if prayer and not prayed then
		ClientCall(0, "client.bingeSound", "MOD/snd/Enemies/Boss/NecoArc.ogg")
"""),
]),
"scripts/heliCrashSmoke.lua": ("server: heli wreck smoke, scorch paint and fire loop.", [
    ("""	if not IsHandleValid(CrashLight) then
		queueRemoval()
	end
""", """	if not IsHandleValid(CrashLight) then
		-- (v2) v1 queueRemoval() (pause-menu handle trick) does not work on the server: just stop.
		Finished = true
	end
	if Finished then return end
"""),
    ("function update()\n\n\tlocal pos = VecAdd(GetLightTransform(CrashLight).pos, Vec(0, -0.3, 0))\n",
     "function update()\n\n\tif Finished then return end\n\tlocal pos = VecAdd(GetLightTransform(CrashLight).pos, Vec(0, -0.3, 0))\n"),
]),
"GoreNPCs/scripts/other/SleepingRagdoll.lua": ("server: sleeping NPC wakes when ANY player is near, standing still-ish and not crouching.", [
    ("""		if not InputDown("crouch") and GetDist(GetPlayerTransform().pos, GetBodyTransform(Body).pos) <= sleeptypetypes[sleeptype].dist and GetPlayerVelocity()[1] < 3 and GetPlayerVelocity()[2] and GetPlayerVelocity()[3] then
""", """		local waker, nearest = nil, math.huge -- (v2) any player (v1 conditions per player)
		for p in Players() do
			local d = GetDist(GetPlayerTransform(p).pos, GetBodyTransform(Body).pos)
			nearest = math.min(nearest, d)
			if not InputDown("crouch", p) and d <= sleeptypetypes[sleeptype].dist and GetPlayerVelocity(p)[1] < 3 then waker = p end
		end
		if waker then
"""),
    ("""			if GetDist(GetPlayerTransform().pos, GetBodyTransform(Body).pos) > sleeptypetypes[sleeptype].dist then
""", """			if nearest > sleeptypetypes[sleeptype].dist then
"""),
]),
"GoreNPCs/scripts/other/StandingRagdoll.lua": ("server: shop trader; looks at the nearest player; killing it halves the NEAREST player's money (their savegame, via ClientCall).", [
    ("""		local playerPos = GetPlayerTransform().pos
		local NPCPos = GetBodyTransform(Torso).pos
		local dist = VecLength(VecSub(playerPos, NPCPos))

		if dist < 7 then
			ConstrainOrientation(
				Head,
				GetWorldBody(),
				GetBodyTransform(Head).rot,
				QuatLookAt(GetBodyTransform(Head).pos, GetCameraTransform().pos))
		end
""", """		local NPCPos = GetBodyTransform(Torso).pos
		local nearestP, dist = NearestPlayer(NPCPos) -- (v2) nearest player (v1: the camera)

		-- (v2) the head constraint is applied in server.update: Constrain* in tick crashed the v2 engine
		LookAtPos = nil
		if dist < 7 then
			LookAtPos = GetPlayerCameraTransform(nearestP).pos
		end
"""),
    ("""		Money = GetInt("savegame.mod.player.money")
		SetInt("savegame.mod.player.money", Money / 2)
""", """		-- (v2) money is per player (client savegame): the nearest player (most likely the killer) loses half
		local killer = NearestPlayer(GetBodyTransform(Torso).pos)
		ClientCall(killer, "client.halveMoney", killer)
"""),
    ("		ApplyBodyImpulse(Torso, t.pos, VecScale(fwd1, force1))\n",
     "		ApplyBodyImpulse(Torso, t.pos, VecScale(fwd2, force1)) -- (v2 fix) v1 used undefined fwd1 (error on death)\n"),
]),
# (Phase 3 batch D, 2026-11-07) crew ragdolls sitting in enemy vehicles / helicopters: look around (neck motor) and
# become a full ragdoll when a body part breaks. Server only (joint motor, collision filter, Delete, Spawn).
"main/GoreRagdolls2/scripts/fakegore.lua": ("server: vehicle crew ragdoll (neck motor; full ragdoll spawned when a body part breaks).", []),
"main/AS350/Gore Ragdolls 2/scripts/fakegore.lua": ("server: helicopter crew ragdoll (full ragdoll spawned when a body part breaks).", HELI_CREW),
"main/Mil-Mi-35P-Hind/Gore Ragdolls 2/scripts/fakegore.lua": ("server: helicopter crew ragdoll (full ragdoll spawned when a body part breaks).", HELI_CREW),
}

APPEND = {
"scripts/Binge.lua": """
function client.bingeSound(path)
	PlaySound(LoadSound(path))
end
""",
"script/grenade.lua": """
-- (v2 fix 2026-11-07) Close-range / low-FPS impacts. v1 started all rocket logic 0.05 s after spawn (~6 m at
-- 120 m/s) and then only looked one physics step ahead of the rocket, once per frame. A target closer than that was
-- hit and the rocket had bounced off before any check ran; at low FPS it could also skip past thin targets. Here,
-- every tick, a ray from the previous position along the previous flight direction (as far as the rocket could have
-- flown) finds what it ran into, even if physics already bounced it back; that arms the warhead and detonates.
local RocketTickV1 = server.tick
function server.tick(dt)
  if not exploded and body and IsHandleValid(body) then
    if RocketLastPos and RocketLastSpeed > 10 then
      for index, shape in ipairs(shapes) do QueryRejectShape(shape) end
      QueryRejectBody(body)
      local hit, dist, normal, shape = QueryRaycast(RocketLastPos, RocketLastDir,
        RocketLastSpeed * math.max(dt, GetTimeStep()) * 1.2 + 0.3, 0.2)
      if hit then
        ForceImpact = true
        primed = true
        warhead_primed = true
        ImpactPos = VecAdd(RocketLastPos, VecScale(RocketLastDir, dist))
        ImpactShape = shape
      end
    end
  end
  RocketTickV1(dt)
  if not exploded and body and IsHandleValid(body) then
    local v = GetBodyVelocity(body)
    RocketLastPos, RocketLastSpeed = GetBodyTransform(body).pos, VecLength(v)
    RocketLastDir = RocketLastSpeed > 0 and VecScale(v, 1 / RocketLastSpeed) or Vec(0, 0, 1)
  end
end
""",
"GoreNPCs/scripts/other/StandingRagdoll.lua": """
-- (v2) head look-at constraint (target chosen in server.tick); Constrain* belongs in update
function server.update(dt)
	if not dead and LookAtPos and IsHandleValid(Head) then
		ConstrainOrientation(Head, GetWorldBody(), GetBodyTransform(Head).rot,
			QuatLookAt(GetBodyTransform(Head).pos, LookAtPos))
	end
end
""" + NEAREST + """
function client.halveMoney(target)
	local me = GetLocalPlayer()
	if target ~= me and not (target == 0 and IsPlayerHost(me)) then return end
	SetInt("savegame.mod.player.money", GetInt("savegame.mod.player.money") / 2)
end
""",
}

if __name__ == "__main__":
    for f in sys.argv[1:] or list(EDITS):
        note, edits = EDITS[f]
        convert(f, edits, note)
        if f in APPEND:
            b = open(f, "rb").read().decode("utf-8")
            nl = "\r\n" if "\r\n" in b else "\n"
            b = b.rstrip("\r\n") + nl + APPEND[f].replace("\n", nl)
            open(f, "wb").write(b.encode("utf-8"))

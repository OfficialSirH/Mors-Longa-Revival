#!/usr/bin/env python3
"""Build avf/scripts/Immersive_Tank.lua (v2) from the original in git (9dde6dd).

Immersive_Tank.lua is AVF's tank damage script by elboydo (ammo cook-off, engine failure, fuel fires, blow-outs;
credit as AVF: tools/porting/avf_base/README.md). Rebuild converter: the output is regenerated from the base every
run, never hand-edit it; every edit asserts its match count.

v2 split (2026-11-13): the whole v1 logic runs on the server (it decides and does the world changes: Explosion,
MakeHole, SpawnFire, Spawn, Delete, DriveVehicle, impulses, tags). Its visual calls (Particle*, SpawnParticle,
PointLight, PlaySound, PlayLoop, ShakeCamera) are renamed to IT_<name>, which on the server only record the call;
once per server tick / update the recorded calls go to every client (client.itFx), which replays them with the real
functions. Sounds travel as file paths (IT_LoadSound / IT_LoadLoop return the path on the server; clients load and
cache their own handles). Player damage per player (v1: the local player only; as the original health script reset
the engine health every tick, only a lethal amount counts: kill through the torso hitbox, as AVF_HurtPlayer).
The v1 self-removal (masterScriptRemoverAPI: a pause-menu trick) is dropped.

Usage (repo root): python tools/porting/patches/port_immersive.py
"""
import os, re, subprocess

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
REL = "avf/scripts/Immersive_Tank.lua"
BASE = "9dde6dd"
src = subprocess.run(["git", "show", f"{BASE}:{REL}"], cwd=ROOT, capture_output=True, check=True).stdout
s = src.decode("latin-1").replace("\r\n", "\n")


def sub(old, new, count=1, regex=False):
    global s
    if regex:
        s, n = re.subn(old, new, s)
    else:
        n = s.count(old)
        s = s.replace(old, new)
    assert (n == count) if count is not None else n >= 1, f"{old!r}: expected {count}, got {n}"
    return n


def sub_block(old, new, count=1):
    """sub for multi-line blocks, trailing spaces at line ends ignored (the original has many)."""
    global s
    pattern = r"[ \t]*\n".join(re.escape(line.rstrip()) for line in old.split("\n"))
    s, n = re.subn(pattern, lambda _: new, s)
    assert n == count, f"block {old[:60]!r}...: expected {count}, got {n}"


assert not s.startswith("#version 2")
# hidden includes (Teardown handles include lines even inside comments): keep the engine helpers, drop the remover
sub('--[[\n#include "script/common.lua"\n#include "../../scripts/masterScriptRemoverAPI.lua"\n]]\n',
    '#include "script/common.lua"\n-- (v2) the v1 self-removal include (masterScriptRemoverAPI) is dropped\n')

# EmitFire (every tick while a tank burns) mixes its flames (5 particles, a light, the fire loop per call) with the
# logic (SpawnFire, player damage): the flames become the effect EmitFireFx (one event; ITR_EmitFireFx in the glue)
sub_block('''	for i=1,5 do

		ParticleReset()
		ParticleTile(5)
		ParticleColor(1, 1, 0.5, 1, 0, 0)
		ParticleRadius(0.05*amount, 1*amount)
		ParticleEmissive(10, 0)
		ParticleDrag(0.1)
		ParticleGravity(math.random()*20)
		PointLight(p, 1, 0.8, 0.2, 2*amount)
		PlayLoop(fireLoop, t.pos, (amount*burn_off_sound_vol )*force)
		SpawnParticle(p, VecScale(d, 12*force), 0.5 * (amount*3))
	end
''', '''	ITC_EmitFireFx(p, d, t.pos, amount, force, fireLoop, burn_off_sound_vol) -- (v2) flames: an effect on every client
''')

# visual calls -> recorders
VISUAL = ["ParticleReset", "ParticleType", "ParticleTile", "ParticleColor", "ParticleRadius", "ParticleAlpha",
          "ParticleGravity", "ParticleDrag", "ParticleEmissive", "ParticleRotation", "ParticleStretch", "ParticleSticky",
          "ParticleCollide", "ParticleFlags", "SpawnParticle", "PointLight", "PlaySound", "PlayLoop", "ShakeCamera"]
for name in VISUAL:
    if re.search(r"(?<![\w.:])" + name + r"\s*\(", s):  # (ParticleFlags / ShakeCamera may not occur)
        sub(r"(?<![\w.:])" + name + r"\s*\(", "IT_" + name + "(", count=None, regex=True)
for name in ("LoadSound", "LoadLoop"):
    sub(r"(?<![\w.:])" + name + r"\s*\(", "IT_" + name + "(", count=None, regex=True)

# kill_tank set the cook-off origin to the hull's centre of mass, a plain vector, which every later use treats as a
# transform (TransformToParentTransform(vehicle transform, origin)): in the mock the cook-off then errored every tick
# inside tick()'s pcall (whether the real engine errored too or read it as the origin is not known). Made the
# transform it was meant to be (original-mod bug, as far as can be told; TECHNICAL_REFERENCE §8).
sub_block("\ttank.cook_off_origin = com\n",
          "\ttank.cook_off_origin = Transform(com) -- (v2) was the bare vector, used as a transform below\n")

# player damage (EmitFire): every player, only a lethal amount counts (see header)
sub('''		local toPlayer = VecSub(GetPlayerCameraTransform().pos, t.pos)''',
    '''		for p in Players() do -- (v2) every player
		local toPlayer = VecSub(GetPlayerCameraTransform(p).pos, t.pos)''')
sub_block('''					SetPlayerHealth(GetPlayerHealth() - 0.015 * strength * amount * distScale)
				end
			end
		end''', '''					IT_HurtPlayer(p, 0.015 * strength * amount * distScale)
				end
			end
		end
		end -- (v2) players''')

# pure visual effect functions (their own state: explosionPos, smoke, fire, flash, light, trails): run on every
# client from one short event each, instead of recording their ~10 calls per particle (mock: a cook-off sent
# ~178000 recorded calls in 600 batches). Definitions become ITR_<name> (real), all calls go through ITC_<name>:
# on a client it runs ITR_<name>, on the server it records one event. Their continuous updates run on the clients.
CLIENT_FX = ["trailsAdd", "trailsUpdate", "smokeUpdate", "fireUpdate", "flashTick", "lightTick", "explosionSparks",
             "explosionDebris", "explosionSmall", "explosionMedium", "explosionLarge", "engine_sparks",
             "animated_fuel_leak"]
for name in CLIENT_FX:
    sub("\nfunction " + name + "(", "\nfunction ITR_" + name + "(", count=1)
    sub(r"(?<![\w.:])" + name + r"\s*\(", "ITC_" + name + "(", count=None, regex=True)

# callbacks: the logic is the server's
sub("\nfunction init()\n", "\nfunction server.init()\n")
sub_block('''function tick()
	if IsHandleValid(tank.id)then
		local status,retVal = pcall(tick_behaviors)
		if(not status) then
			DebugWatch("[ERROR] ",retVal)
		end
	else
		queueRemoval()
	end
end''', '''function server.tick(dt)
	if IsHandleValid(tank.id)then
		local status,retVal = pcall(tick_behaviors)
		if(not status) then
			DebugWatch("[ERROR] ",retVal)
		end
	end
	IT_Flush() -- (v2) this tick's visuals to every client; v1 removed the script once the tank was gone
end''')
sub_block('''function update(dt)
	ITC_trailsUpdate(dt)
	ITC_fireUpdate(explosionPos, dt)
	ITC_smokeUpdate(explosionPos, dt)
end''', '''function client.update(dt) -- (v2) the effects' continuous updates run on every client
	ITC_trailsUpdate(dt)
	ITC_fireUpdate(explosionPos, dt)
	ITC_smokeUpdate(explosionPos, dt)
end''')
assert not re.search(r"^function (init|tick|update|draw)\(", s, re.M), "v1 callback left"
assert "SetPlayerHealth" not in s and "GetPlayerHealth()" not in s
for name in VISUAL:
    assert not re.search(r"(?<![\w.:_])" + name + r"\s*\(", s), f"{name} left"

GLUE = r'''#version 2
#include "script/include/player.lua"
-- GENERATED by tools/porting/patches/port_immersive.py from the original (git 9dde6dd) - DO NOT EDIT.
-- AVF's Immersive Tanks script (elboydo; credit: tools/porting/avf_base/README.md), ported to Teardown 2.x co-op:
-- the logic and world changes run on the server; visual calls are recorded and replayed by every client (client.itFx).

-- ---------------------------------------------------------------- (v2) visual recorder (server) / replay (client)
IT_BUF = {}
local function rec(name) return function(...) IT_BUF[#IT_BUF + 1] = { name, ... } end end
'''
for name in VISUAL:
    GLUE += f'IT_{name} = rec("{name}")\n'
GLUE += "\n-- effect functions: real on a client (IT_CLIENT), one recorded event on the server\n"
for name in CLIENT_FX + ["EmitFireFx"]:
    GLUE += (f"function ITC_{name}(...) if IT_CLIENT then return ITR_{name}(...) end "
             f"IT_BUF[#IT_BUF + 1] = {{ \"@{name}\", ... }} end\n")
GLUE += r'''--- EmitFire's flames (the original's loop, unchanged; split off as an effect, see the converter).
function ITR_EmitFireFx(p, d, pos, amount, force, loop, vol)
	for i=1,5 do
		IT_ParticleReset()
		IT_ParticleTile(5)
		IT_ParticleColor(1, 1, 0.5, 1, 0, 0)
		IT_ParticleRadius(0.05*amount, 1*amount)
		IT_ParticleEmissive(10, 0)
		IT_ParticleDrag(0.1)
		IT_ParticleGravity(math.random()*20)
		IT_PointLight(p, 1, 0.8, 0.2, 2*amount)
		IT_PlayLoop(loop, pos, (amount*vol)*force)
		IT_SpawnParticle(p, VecScale(d, 12*force), 0.5 * (amount*3))
	end
end

--- Sounds travel as paths: the server keeps the path, each client loads its own handle.
function IT_LoadSound(path) return path end
function IT_LoadLoop(path) return { loop = path } end

function IT_Flush()
	if #IT_BUF > 0 then
		ClientCall(0, "client.itFx", IT_BUF)
		IT_BUF = {}
	end
end

--- The torso hitbox of player p (scripts/PlayerHitboxes.lua sets) - as AVF_Glue.lua.
local function torsoHitbox(p)
	for _, t in ipairs(FindTriggers("hitbox", true)) do
		if GetTagValue(t, "hitbox") == "TORSO" then
			if HasTag(t, "hitbox_player") then
				if tonumber(GetTagValue(t, "hitbox_player")) == p then return t end
			elseif IsPlayerHost(p) then
				return t
			end
		end
	end
	return 0
end

--- v1 lowered the local player's engine health; the original health script reset it to 1 every tick, so only an
--- amount >= 1 at once mattered (it killed). Same, for every player, through the torso hitbox.
function IT_HurtPlayer(p, amount)
	if amount < 1 or GetPlayerHealth(p) <= 0 then return end
	local t = torsoHitbox(p)
	if t ~= 0 then SetTag(t, "QueriedDamage", 10000) end
end

local REAL, SND = nil, {}
local function sound(path, loop)
	local key = (loop and "L:" or "S:") .. path
	if SND[key] == nil then
		if HasFile(path) or path:find("^tools/") or path:find("^snd/") then
			SND[key] = loop and LoadLoop(path) or LoadSound(path)
		else
			SND[key] = false
		end
	end
	return SND[key] or nil
end

function client.init()
	IT_CLIENT = true
	-- the effect functions run here: their particle / light / sound calls are the real ones on a client
	IT_ParticleReset, IT_ParticleType, IT_ParticleTile, IT_ParticleColor = ParticleReset, ParticleType, ParticleTile, ParticleColor
	IT_ParticleRadius, IT_ParticleAlpha, IT_ParticleGravity, IT_ParticleDrag = ParticleRadius, ParticleAlpha, ParticleGravity, ParticleDrag
	IT_ParticleEmissive, IT_ParticleRotation, IT_ParticleStretch = ParticleEmissive, ParticleRotation, ParticleStretch
	IT_ParticleSticky, IT_ParticleCollide, IT_ParticleFlags = ParticleSticky, ParticleCollide, ParticleFlags
	IT_SpawnParticle, IT_PointLight, IT_ShakeCamera = SpawnParticle, PointLight, ShakeCamera
	IT_PlaySound = function(h, pos, vol) local x = type(h) == "string" and sound(h, false) if x then PlaySound(x, pos, vol) end end
	IT_PlayLoop = function(h, pos, vol) local x = type(h) == "table" and h.loop and sound(h.loop, true) if x then PlayLoop(x, pos, vol) end end
	REAL = { ParticleReset = ParticleReset, ParticleType = ParticleType, ParticleTile = ParticleTile,
		ParticleColor = ParticleColor, ParticleRadius = ParticleRadius, ParticleAlpha = ParticleAlpha,
		ParticleGravity = ParticleGravity, ParticleDrag = ParticleDrag, ParticleEmissive = ParticleEmissive,
		ParticleRotation = ParticleRotation, ParticleStretch = ParticleStretch, ParticleSticky = ParticleSticky,
		ParticleCollide = ParticleCollide, ParticleFlags = ParticleFlags, SpawnParticle = SpawnParticle,
		PointLight = PointLight, ShakeCamera = ShakeCamera }
end

function client.itFx(ops)
	for _, op in ipairs(ops or {}) do
		local name = op[1]
		if name == "PlaySound" then
			local h = type(op[2]) == "string" and sound(op[2], false)
			if h then PlaySound(h, op[3], op[4]) end
		elseif name == "PlayLoop" then
			local h = type(op[2]) == "table" and op[2].loop and sound(op[2].loop, true)
			if h then PlayLoop(h, op[3], op[4]) end
		elseif name:sub(1, 1) == "@" then
			-- an effect function: positions may arrive as transforms (the original passed shape transforms to
			-- explosionSmall in two places)
			local args = { unpack(op, 2) }
			if type(args[1]) == "table" and args[1].pos then args[1] = args[1].pos end
			local fn = ITR_FX[name:sub(2)]
			if fn then fn(unpack(args)) end
		elseif REAL and REAL[name] then
			REAL[name](unpack(op, 2))
		end
	end
end

-- ---------------------------------------------------------------- the original (v1 logic, on the server)
'''
out = GLUE + s + "\n-- (v2) effect functions by name, for client.itFx\nITR_FX = { " + ", ".join(f"{n} = ITR_{n}" for n in CLIENT_FX + ["EmitFireFx"]) + " }\n"
dst = os.path.join(ROOT, REL)
open(dst, "w", encoding="latin-1", newline="\n").write(out)
print(f"wrote {REL} ({out.count(chr(10))} lines)")

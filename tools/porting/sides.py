#!/usr/bin/env python3
"""Per-function report of server-only / client-only / UI / registry calls in Teardown Lua files."""
import re, sys
SERVER = set("""SetVehicleParam DriveVehicle SetVehicleHealth SetPlayerTransform SetPlayerTransformWithPitch SetPlayerGroundVelocity SetPlayerSpawnTransform SetPlayerSpawnHealth SetPlayerSpawnTool SetPlayerVehicle SetPlayerVelocity ReleasePlayerGrab SetPlayerScreen SetPlayerHealth SetPlayerRegenerationState SetPlayerTool RespawnPlayer RespawnPlayerAtTransform SetPlayerWalkingSpeed SetPlayerCrouchSpeedScale SetPlayerHurtSpeedScale SetPlayerParam RegisterTool SetToolAmmoPickupAmount SetToolAmmo SetToolEnabled ApplyPlayerDamage DisablePlayerInput DisablePlayer DisablePlayerDamage Shoot Paint PaintRGBA MakeHole Explosion SpawnFire RemoveAabbFires SetTimeScale SetEnvironmentDefault SetEnvironmentProperty AddHeat SetGravity""".split())
CLIENT = set("""InputClear InputResetOnTransition SetPlayerCharacter SetPlayerCameraOffsetTransform SetToolHandPoseLocalTransform SetToolTransform SetToolAllowedZoom SetToolTransformOverride SetToolOffset SetPlayerRigTags SetSoundLoopUser PlaySoundForUser AddMapMarker SelectedMapMarker GetCameraTransform SetCameraTransform RequestFirstPerson RequestThirdPerson SetCameraOffsetTransform AttachCameraTo SetPivotClipBody ShakeCamera SetCameraFov SetCameraDof DisableMotionBlur SetLowHealthBlurThreshold LoadHaptic CreateHaptic PlayHaptic PlayHapticDirectional HapticIsPlaying SetToolHaptic StopHaptic""".split())
OTHER = set("PlaySound PlayLoop SpawnParticle Spawn Delete PointLight DrawSprite DebugWatch DebugPrint".split())
fn_re = re.compile(r'^\s*(?:local\s+)?function\s+([A-Za-z_][\w.:]*)\s*\(', re.M)
call_re = re.compile(r'(?<![\w.:])([A-Z]\w*)\s*\(')
reg_re = re.compile(r'(Get|Set)(Bool|Int|Float|String)\s*\(\s*"([a-z]+)\.')
def strip_comments(s):
    s = re.sub(r'--\[(=*)\[.*?\]\1\]', lambda m: '\n'*m.group(0).count('\n'), s, flags=re.S)
    return re.sub(r'--[^\n]*', '', s)
for path in sys.argv[1:]:
    raw = open(path, encoding='utf-8', errors='ignore').read()
    src = strip_comments(raw)
    starts = [(m.start(), m.group(1)) for m in fn_re.finditer(src)]
    print(f"=== {path}")
    bounds = starts + [(len(src), None)]
    chunks = [("<top-level>", src[:starts[0][0]] if starts else src)]
    chunks += [(bounds[i][1], src[bounds[i][0]:bounds[i+1][0]]) for i in range(len(starts))]
    for name, body in chunks:
        line = src[:src.find(body)].count('\n') + 1 if body else 0
        calls = call_re.findall(body)
        s = sorted({c for c in calls if c in SERVER}); c = sorted({c for c in calls if c in CLIENT})
        ui = sum(1 for x in calls if x.startswith('Ui')); o = sorted({x for x in calls if x in OTHER})
        regs = sorted({f"{a}:{k}" for a,_,k in reg_re.findall(body)})
        n = body.count('\n')
        if s or c or ui or regs or o:
            print(f"  {name} (L{line}, {n} lines)  S={s} C={c} UI={ui} other={o} reg={regs}")

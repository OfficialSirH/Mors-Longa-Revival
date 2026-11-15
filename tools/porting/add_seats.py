"""Phase 4: add official-style seat rigs (<rig name="driver"> / <rig name="passenger">) to vehicles.

Usage (repo root): python tools/porting/add_seats.py [--dry-run] [--replace]

Each entry in VEHICLES names a vehicle prefab and its seat layout. The rigs are inserted as the last children of
the <vehicle> element (vehicle coordinates) in the prefab file itself and in every embedded copy of it
(<group name="instance=MOD/...prefab.xml"> in spawn prefabs, road segments, levels). A vehicle that already has a
<rig> is left alone, so the script can be re-run. Seat positions were measured in Blender with
tools/porting/blender_vehicle.py; the body-pose points (feet, hands, head, steering wheel) are copied from the
official suv_silver.xml, relative to the seat (format: docs/VEHICLES.md).
"""
import os, re, sys

REPO = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))

# --- body-pose templates (point layout from official suv_silver.xml / boxtruck) ---
# All arguments are vehicle coordinates; the rig is placed at the seat and its points are stored relative to it.
# tilt = seat rot x: 0 = the engine's default upright pose (boxtruck, military ATV), 60-90 = reclined car seats.
def rel(p, seat):
    return tuple(a - b for a, b in zip(p, seat))


def driver(seat, wheel, wheel_radius, feet_z, tilt=0, feet_y=None, head=(0, 0.8, 0.1)):
    """feet_y: absolute foot height (default 0.1 below the seat point). head: ik_head relative to the seat (official
    low cabs, e.g. pickup_red / sportscar_green: about (0, 0.55, 0.25) with seat rot 80)."""
    x, y, z = seat
    wx, wy, wz = wheel
    fy = y - 0.1 if feet_y is None else feet_y
    return ("driver", "driver sort=0", seat, [
        ("ik_foot_l", rel((x - 0.15, fy, feet_z), seat), (0, 90, 50)),
        ("ik_foot_r", rel((x + 0.15, fy, feet_z), seat), (0, 90, 50)),
        ("seat", (0, 0, 0), (tilt, 0, 0)),
        ("ik_hand_l", rel((wx - wheel_radius, wy, wz), seat), (0, 90, 0)),
        ("ik_hand_r", rel((wx + wheel_radius, wy, wz), seat), (0, 90, 0)),
        ("ik_head", head, (0, 90, 0)),
        ("steeringwheel", rel(wheel, seat), (0, -180, 0)),
    ], (0, 0, 0))


def driver_standing(stand, wheel, wheel_radius):
    """Standing driver (official boats, e.g. fishingboat_medium_white_blue.xml): a "stand" location on the floor
    instead of "seat" (data/script/player_locomotion.lua then uses the standing pose), feet beside it, hands on the
    upper sides of the wheel rim. stand = the floor point between the feet. NPCs never use driver rigs."""
    wx, wy, wz = wheel
    h = wheel_radius * 0.7  # 45 degrees up the rim
    return ("driver", "driver sort=0", stand, [
        ("ik_foot_l", (-0.2, 0, -0.05), (0, 100, 0)),
        ("ik_foot_r", (0.2, 0, -0.05), (0, 80, 0)),  # official: z 0.15; level here so both fit a narrow footwell
        ("stand", (0, 0, 0), (0, 0, 0)),
        ("ik_hand_l", rel((wx - h, wy + h, wz), stand), (0, 90, 0)),
        ("ik_hand_r", rel((wx + h, wy + h, wz), stand), (0, 90, 0)),
        ("steeringwheel", rel(wheel, stand), (0, -180, 0)),
    ], (0, 0, 0))


def gunner(sort, stand, grip, yaw=0):
    """Mounted-gun place (vehicles/MountedGun.lua finds the rig tagged "gunner"): standing ("stand" location, the
    standing pose as in driver_standing) at stand, facing yaw (0 = -z, 90 = -x, -90 = +x), hands on the gun's grips
    (grip = the point between them, at the gun's rest pose; they don't follow the gun yet). stand is in vehicle space.
    NOT a vehicle seat (user, 2026-11-12): patch_text puts it under the vehicle's first <body> (as the game's own
    turret: tags "gunner relative_parent"), so the player stays on foot; the script holds the player
    there with SetPlayerRig every tick. sort is unused (kept for the layout tables).
    In-game 2026-11-12: the engine still counts a rig under the vehicle body as a seat; without a sort tag it came
    first, so the "Enter vehicle" prompt (hud.lua: GetVehicleAvailableSeatPos) moved to the gun. sort=99 puts it
    after every real seat; MountedGun.lua takes anyone the engine seats on it off again."""
    import math
    a = math.radians(yaw)
    def local(p):  # world offset from stand -> rig frame (rig rotated by yaw about y)
        x, y, z = (p[0] - stand[0], p[1] - stand[1], p[2] - stand[2])
        return (round(x * math.cos(a) - z * math.sin(a), 3), round(y, 3), round(x * math.sin(a) + z * math.cos(a), 3))
    gx, gy, gz = local(grip)
    return ("gunner", "gunner relative_parent sort=99", stand, [
        ("ik_foot_l", (-0.2, 0, -0.05), (0, 100, 0)),
        ("ik_foot_r", (0.2, 0, -0.05), (0, 80, 0)),
        ("stand", (0, 0, 0), (0, 0, 0)),
        ("ik_hand_l", (gx - 0.12, gy, gz), (0, 90, 0)),
        ("ik_hand_r", (gx + 0.12, gy, gz), (0, 90, 0)),
    ], (0, yaw, 0))


def gunner_seated(seat, feet_y, legroom=0.5, yaw=0):
    """Mounted-gun place on a seat of the gun's mount (ZU-23-2, 2026-11-12): a passenger-style seated pose ("seat"
    location: a rig without a vehicle uses it, player_locomotion.lua), facing yaw (as passenger), feet legroom in
    front at height feet_y, hands on the knees. Same rig tags / placement as gunner(); MountedGun.lua turns the
    place with the turret (the seat is on the mount)."""
    name, _, pos, locs, rot = passenger(0, seat, feet_y=feet_y, yaw=yaw, legroom=legroom)
    return ("gunner", "gunner relative_parent sort=99", pos, locs, rot)


def passenger(sort, seat, feet_z=None, tilt=0, feet_y=None, yaw=0, legroom=None, floor=False, head=(0, 0.8, 0.15)):
    """Facing forward (-z): give feet_z (absolute). Facing elsewhere: yaw (degrees about y; -90 = facing +x,
    90 = facing -x) and legroom (feet distance in front of the seat). The rig is rotated by yaw, so its points
    are stored in the rig's own frame. floor=True: sitting on the floor (rig tag "floor"; NPCs skip these)."""
    x, y, z = seat
    fy = (y - 0.1 if feet_y is None else feet_y) - y
    fz = -legroom if legroom is not None else feet_z - z
    return ("passenger", "sort=%d%s" % (sort, " floor" if floor else ""), seat, [
        ("ik_foot_l", (-0.15, fy, fz), (0, 90, 50)),
        ("ik_foot_r", (0.15, fy, fz), (0, 90, 50)),
        ("seat", (0, 0, 0), (tilt, 0, 0)),
        ("ik_hand_l", (-0.25, 0, -0.05), (0, 90, -30)),   # hands on the knees
        ("ik_hand_r", (0.25, 0, -0.05), (0, 90, -30)),
        ("ik_head", head, (0, 90, 0)),
    ], (0, yaw, 0))


# Humvee (umhumvee.vox): cushions at y 1.15, x 0.5-0.9 each side (centre 0.7); front backrest face z -0.2,
# rear backrest face z 0.6; steering wheel ring centred (-0.65, 1.5, -0.65), radius 0.2; front footwell
# z -0.95, rear footwell ends at the front seat backs (z -0.1).
# Test 1 (seat 0.05 m from backrest, tilt 60, driver x -0.65): hands perfect, back through the backrest,
# body 5 cm right of the cushion. Test 2: boxtruck-style seat 0.25 m from the backrest, tilt 0, x centred.
HUMVEE = [
    driver((-0.7, 1.2, -0.45), wheel=(-0.65, 1.5, -0.65), wheel_radius=0.2, feet_z=-0.95),
    passenger(1, (0.7, 1.2, -0.45), feet_z=-0.95),
    passenger(2, (0.7, 1.2, 0.35), feet_z=0.05),
    passenger(3, (-0.7, 1.2, 0.35), feet_z=0.05),
]

# UAZ-452 van (uaz452.xml, Damaged, Modified: same body placement). Measured with node rotations applied (the
# body model is turned 180 degrees inside the .vox; before blender_vehicle.py handled that, the seats looked like a
# rear bench and the steering wheel lay flat). Front seat cushions y 1.2, z -1.85..-1.55, driver x -0.65..-0.25,
# passenger x 0.25..0.75; backrest front face z -1.5; upright steering wheel centred (-0.45, 1.46, -2.06), radius
# ~0.22; cargo floor 0.8, roof 2.1 (1.3 m headroom: no standing), walls x -0.7 / 0.8. User decision 2026-11-08
# "sit cab, stand cargo": standing does not fit, so the cargo players sit on the floor against the right wall.
# Tests 1-2 used the unrotated model (seat on the wrong spot, hands short of the wheel). Test 3: real cushions.
UAZ452 = [
    driver((-0.45, 1.25, -1.75), wheel=(-0.45, 1.46, -2.06), wheel_radius=0.2, feet_z=-2.15, feet_y=0.9),
    passenger(1, (0.5, 1.25, -1.75), feet_z=-2.0, feet_y=0.9),
    passenger(2, (0.55, 0.85, -0.25), feet_y=0.8, yaw=90, legroom=0.6, floor=True),
    passenger(3, (0.55, 0.85, 0.65), feet_y=0.8, yaw=90, legroom=0.6, floor=True),
]

# uaz452 Damaged: the floor has holes around x 0.45-0.55, z -0.25..-0.05 (and no passenger cushion; that seat
# stays at normal height): floor position 2 moved to z -0.6.
UAZ452_DAMAGED = UAZ452[:2] + [
    passenger(2, (0.55, 0.85, -0.6), feet_y=0.8, yaw=90, legroom=0.6, floor=True),
    UAZ452[3],
]


def shifted(rigs, dx=0.0, dy=0.0, dz=0.0):
    """Same layout moved (rig points are relative to the rig, so only the rig positions move)."""
    return [(n, t, (p[0] + dx, p[1] + dy, p[2] + dz), locs, rot) for n, t, p, locs, rot in rigs]


# uaz452 Modified: body model "BodyM" is lifted 0.2 m (steering wheel centre y 1.7, cargo floor 1.0)
UAZ452_MODIFIED = shifted(UAZ452, dy=0.2)

# uaz452C_white ("Cover"): same cab 0.6 m higher and 0.2 m further back (steering wheel centre (-0.45, 2.06, -1.86));
# raised cargo floor 1.7 under a raised roof 3.0, walls x -0.8 / 0.9.
UAZ452_WHITE = shifted(UAZ452[:2], dy=0.6, dz=0.2) + [
    passenger(2, (0.65, 1.75, -0.25), feet_y=1.7, yaw=90, legroom=0.6, floor=True),
    passenger(3, (0.65, 1.75, 0.65), feet_y=1.7, yaw=90, legroom=0.6, floor=True),
]

# uaz452_emergency: same cab 0.1 m higher and 0.1 m further back (wheel centre (-0.45, 1.56, -1.96)). Cargo: a
# stretcher down the middle (top 1.5, z -0.35..2.05), cabinet on the left; only a 0.3 m aisle on the right
# (x 0.5..0.8, floor 0.9, z -0.35..0.85): one floor position facing forward. Sitting on the stretcher edge would put
# the head ~0.2 m into the 2.2 roof. 3 players.
UAZ452_EMERGENCY = shifted(UAZ452[:2], dy=0.1, dz=0.1) + [
    passenger(2, (0.65, 0.95, 0.7), feet_y=0.9, feet_z=0.1, floor=True),
]

# GAZ-24 (sedan, VIP "khb", MP "milicia": identical layout). Low car: floor 0.35, roof 1.34. Front cushions 0.54
# (driver x -0.59..-0.09, passenger 0.28..0.78), backrests reclined ~27 deg (face z -0.04 at hip height; separate
# "Seat_Back" parts tagged door, folded by EVF.lua); rear bench 0.63, upright backrest face z 0.84. Steering wheel
# centre (-0.35, 0.84, -0.57), radius ~0.25, tilted 15 deg. Mannequin: tilt 50 (~29 deg after the engine's
# straightening) left the head at the roof (front): front 55 (~37 deg). Rear: the roof is 1.34 only over z 0.35..0.7
# and drops to the rear window behind; reclining moves the head back under the low part (0.3+ m through it), so
# the rear sits upright, hips sunk 0.08 into the cushion: head ~0.1 m through the roof in-game (best found).
GAZ24 = [
    driver((-0.34, 0.59, -0.29), wheel=(-0.35, 0.84, -0.57), wheel_radius=0.22, feet_z=-0.75, feet_y=0.4, tilt=55),
    passenger(1, (0.53, 0.59, -0.29), feet_z=-0.75, feet_y=0.4, tilt=55),
    passenger(2, (-0.35, 0.6, 0.59), feet_z=0.2, feet_y=0.4),
    passenger(3, (0.45, 0.6, 0.59), feet_z=0.2, feet_y=0.4),
]

# Minivan (minivan1.xml, PentaRhombus.vox; no official counterpart): separate seat parts tilted 10 deg. Front
# cushions y 0.75, z -0.65..-0.35 (driver x -0.55..-0.25, passenger 0.25..0.55), backrest face z -0.3; rear bench
# cushion 0.75, z 0.35..0.65, x -0.65..0.55, backrest face z 0.7. Floor 0.55 (front footwell to z -0.95). Steering
# wheel ring centre (-0.4, 1.07, -0.86), radius ~0.2, tilted 20 deg. Seat points like the UAZ: 0.05 above the
# cushion, 0.25 in front of the backrest, upright.
MINIVAN = [
    driver((-0.4, 0.8, -0.55), wheel=(-0.4, 1.07, -0.86), wheel_radius=0.2, feet_z=-0.9, feet_y=0.6),
    passenger(1, (0.4, 0.8, -0.55), feet_z=-0.9, feet_y=0.6),
    passenger(2, (0.35, 0.8, 0.45), feet_z=0.05, feet_y=0.6),
    passenger(3, (-0.35, 0.8, 0.45), feet_z=0.05, feet_y=0.6),
]

def on_body(rigs, body_pos):
    """A layout measured on a vehicle whose <body pos> was body_pos, for variants (damaged, abandoned) that use the
    same body model at a different <body pos>: patch_text calls the result with each vehicle's own <body pos>."""
    return lambda bp: shifted(rigs, *(bp[i] - body_pos[i] for i in range(3)))


# Cadillac Sedan (cadillacsd80.vox, body pos y 0.2): GAZ-24-like interior. Front bench cushion 0.55, z -0.35..-0.05,
# backrest face z 0.0 (slightly reclined); rear cushion 0.65, z 0.6..0.95, reclined backrest (face z 1.0 at y 0.75,
# 1.2 at 1.05). Floor 0.35 (front z -0.65..-0.45, rear 0.35..0.55), roof 1.35 (1.25 at the windscreen). Steering
# wheel ring centre ~(-0.45, 0.82, -0.42), radius ~0.22. GAZ rule: tilt 55, seat 0.05 above the cushion and 0.25 in
# front of the backrest at hip height.
CADILLAC_SEDAN = [
    driver((-0.45, 0.6, -0.25), wheel=(-0.45, 0.82, -0.42), wheel_radius=0.22, feet_z=-0.65, feet_y=0.4, tilt=55),
    passenger(1, (0.45, 0.6, -0.25), feet_z=-0.65, feet_y=0.4, tilt=55),
    passenger(2, (0.45, 0.7, 0.75), feet_z=0.4, feet_y=0.4, tilt=55),
    passenger(3, (-0.45, 0.7, 0.75), feet_z=0.4, feet_y=0.4, tilt=55),
]

# abandonedsedan (own model, body pos y 0.325, road wreck Vehiclewb9): stripped. Front bench cushion 0.67,
# z -0.15..0.05, backrest face z 0.1; no steering wheel (hands where the sedan's wheel would be); no rear seat:
# floor 0.47 (z 0.35..0.75, raised 0.57 behind), roof 1.48. Rear players sit on the floor.
CADILLAC_SEDAN_ABANDONED_MEASURED = [
    driver((-0.45, 0.72, -0.15), wheel=(-0.45, 0.95, -0.42), wheel_radius=0.22, feet_z=-0.6, feet_y=0.5, tilt=55),
    passenger(1, (0.45, 0.72, -0.15), feet_z=-0.6, feet_y=0.5, tilt=55),
    passenger(2, (0.45, 0.62, 0.95), feet_z=0.4, feet_y=0.5, floor=True),
    passenger(3, (-0.45, 0.62, 0.95), feet_z=0.4, feet_y=0.5, floor=True),
]
# measured on the uncropped model; its body has an empty layer at the back: 0.1 forward (crop_model)
CADILLAC_SEDAN_ABANDONED = shifted(CADILLAC_SEDAN_ABANDONED_MEASURED, dz=-0.1)

# Cadillac Limousine (cadillacfbl80.vox, body pos y 0.2): front bench cushion 0.55, z -0.95..-0.65, backrest face
# z -0.6 (reclined); steering wheel ~(-0.45, 0.8, -1.05), radius ~0.2; floor 0.35; two rear-facing jump seats
# (cushion 0.55, z 0.05..0.25) and the rear bench (cushion 0.65, z 1.05..1.35, backrest face 1.4); roof 1.35.
# 4 players: front bench and rear bench (jump seats unused). Same rule as the sedan.
CADILLAC_LIMO = [
    driver((-0.45, 0.6, -0.85), wheel=(-0.45, 0.8, -1.05), wheel_radius=0.2, feet_z=-1.2, feet_y=0.4, tilt=55),
    passenger(1, (0.45, 0.6, -0.85), feet_z=-1.2, feet_y=0.4, tilt=55),
    passenger(2, (0.45, 0.7, 1.15), feet_z=0.6, feet_y=0.4, tilt=55),
    passenger(3, (-0.45, 0.7, 1.15), feet_z=0.6, feet_y=0.4, tilt=55),
]

# abandonedlimousine (body3 of the same .vox, body pos y 0.25, road wreck Vehiclewb7): same front and jump seats,
# no rear bench (floor 0.4 up to z 1.35, roof 1.4): rear players sit on the floor facing the jump seats.
CADILLAC_LIMO_ABANDONED = shifted(CADILLAC_LIMO[:2], dy=0.05) + [
    passenger(2, (0.45, 0.45, 1.2), feet_z=0.6, feet_y=0.4, floor=True),
    passenger(3, (-0.45, 0.45, 1.2), feet_z=0.6, feet_y=0.4, floor=True),
]

# 1969 Mini Cooper S (normal, Damaged body2, Modified body3; same body pos): right-hand drive. Very low: front
# cushions 0.5, z -0.25..0.05, backrest face z 0.1; footwell floor 0.4 to the bulkhead at z -0.6; steering wheel
# ring centre (0.25, 0.85, -0.3), radius 0.2; rear cushion 0.5, z 0.45..0.75, backrest face 0.8, footwell 0.4 at
# z 0.25..0.35; roof 1.25 (1.0 at the rear window). Tilt 55 like the GAZ-24.
MINI_MEASURED = [
    driver((0.25, 0.55, -0.15), wheel=(0.25, 0.85, -0.3), wheel_radius=0.2, feet_z=-0.5, feet_y=0.4, tilt=55),
    passenger(1, (-0.25, 0.55, -0.15), feet_z=-0.45, feet_y=0.45, tilt=55),
    passenger(2, (-0.3, 0.55, 0.55), feet_z=0.3, feet_y=0.4, tilt=55),
    passenger(3, (0.3, 0.55, 0.55), feet_z=0.3, feet_y=0.4, tilt=55),
]
# measured before blender_vehicle.py dropped empty layers: the body has 1 empty layer underneath (see JEEP)
MINI = shifted(MINI_MEASURED, dy=-0.1)

# Mini Modified (body3, road wreck Vehiclewb6): stripped. Only the driver seat is left (cushion 0.5, z -0.05..0.15,
# backrest face 0.2: 0.1 further back than the normal Mini); floor 0.4 everywhere else (roof 1.3). The others sit
# on the floor.
MINI_MODIFIED = [
    driver((0.25, 0.55, -0.05), wheel=(0.25, 0.85, -0.3), wheel_radius=0.2, feet_z=-0.5, feet_y=0.4, tilt=55),
    passenger(1, (-0.3, 0.45, 0.05), feet_z=-0.3, feet_y=0.4, floor=True),
    passenger(2, (-0.3, 0.45, 0.75), feet_z=0.35, feet_y=0.4, floor=True),
    passenger(3, (0.3, 0.45, 0.85), feet_z=0.45, feet_y=0.4, floor=True),
]

# 1963 VW Beetle (normal, Damaged body2 at the same body pos, Modified body3 at body pos y 0.55): front cushions 0.5,
# z -0.15..0.15, backrest face z 0.2; footwell 0.4 at z -0.35..-0.25; steering wheel centre (-0.3, 0.85, -0.3),
# radius ~0.18; rear footwell 0.4 at z 0.35, cushion 0.5 z 0.45..0.75, backrest face 0.8; roof 1.3 (1.0 at the
# windscreen header). Tilt 55.
BEETLE = [
    driver((-0.3, 0.55, -0.05), wheel=(-0.3, 0.85, -0.3), wheel_radius=0.18, feet_z=-0.4, feet_y=0.45, tilt=55),
    passenger(1, (0.3, 0.55, -0.05), feet_z=-0.4, feet_y=0.45, tilt=55),
    passenger(2, (0.3, 0.55, 0.55), feet_z=0.35, feet_y=0.45, tilt=55),
    passenger(3, (-0.3, 0.55, 0.55), feet_z=0.35, feet_y=0.45, tilt=55),
]

# VW Beetle Modified (body3, body pos y 0.55, road wreck Vehiclewb5): raised driver seat (cushion 0.75, z -0.05..0.25,
# backrest face 0.3) under an open roof, wheel ~(-0.3, 0.85, -0.4), floor 0.35; a box fills the front right
# (x 0.15..0.45, z -0.35..-0.15). 3 players: driver upright, two on the floor (one facing +x in the back).
BEETLE_MODIFIED = [
    driver((-0.3, 0.8, 0.05), wheel=(-0.3, 0.85, -0.4), wheel_radius=0.18, feet_z=-0.25, feet_y=0.4),
    passenger(1, (0.3, 0.4, 0.45), feet_z=-0.05, feet_y=0.35, floor=True),
    passenger(2, (-0.45, 0.4, 0.55), feet_y=0.35, yaw=-90, legroom=0.5, floor=True),
]

# Plymouth Fury (2-door; normal, Damaged body2, Modified body3, same body pos): front cushions 0.55, z -0.35..-0.05,
# backrest face z 0.05; front floor 0.45, z -0.75..-0.45; steering wheel ring centre (-0.45, 0.9, -0.45), radius 0.2;
# rear floor 0.45, z 0.15..0.35, cushion 0.55, z 0.45..0.75, backrest face 0.85; roof 1.35. Tilt 55.
PLYMOUTH = [
    driver((-0.4, 0.6, -0.2), wheel=(-0.45, 0.9, -0.45), wheel_radius=0.2, feet_z=-0.65, feet_y=0.5, tilt=55),
    passenger(1, (0.4, 0.6, -0.2), feet_z=-0.65, feet_y=0.5, tilt=55),
    passenger(2, (0.4, 0.6, 0.6), feet_z=0.25, feet_y=0.5, tilt=55),
    passenger(3, (-0.4, 0.6, 0.6), feet_z=0.25, feet_y=0.5, tilt=55),
]

# 1974 Dodge Monaco (civilian and Highway Police, normal and Damaged body2, same body pos): front bench cushion 0.5,
# z -0.25..-0.05, backrest face z 0.0; front floor 0.4 at z -0.45; steering wheel ring centre (-0.45, 0.85, -0.3),
# radius ~0.22; rear floor 0.4, z 0.15..0.35, cushion 0.5, z 0.45..0.75, backrest face 0.8; roof 1.3. Tilt 55.
DODGE_MONACO_MEASURED = [
    driver((-0.45, 0.55, -0.25), wheel=(-0.45, 0.85, -0.3), wheel_radius=0.22, feet_z=-0.45, feet_y=0.45, tilt=55),
    passenger(1, (0.45, 0.55, -0.25), feet_z=-0.45, feet_y=0.45, tilt=55),
    passenger(2, (0.45, 0.55, 0.55), feet_z=0.25, feet_y=0.45, tilt=55),
    passenger(3, (-0.45, 0.55, 0.55), feet_z=0.25, feet_y=0.45, tilt=55),
]
DODGE_MONACO = shifted(DODGE_MONACO_MEASURED, dy=-0.1)  # 1 empty layer under the body (see JEEP)

# Highway Police Monaco: same seats as the civilian one. (Measured on the uncropped model its backrests looked 0.1
# further back: its body has an empty layer at the front.)

# 1992 Jeep Wrangler (normal, Damaged body2, same body pos; open top, roll bars): front cushions 1.0, z 0.15..0.45,
# backrest face z 0.5; floor 0.8 (front footwell to the dash at z -0.4); dash face z -0.1..-0.2 at hand height (the
# wheel isn't separable from it: hands just in front); narrow rear bench between the wheel arches (x -0.35..0.25,
# cushion 1.0, z 0.85..1.15, backrest face 1.2). Upright (no roof), seat points like the UAZ.
# In-game test 1 (2026-11-08): everyone sat far above the seats. The body object has 3 empty voxel layers under its
# lowest voxel; the v1 eye point ("player" location) sits only 0.45 above the cushion as measured (0.55-0.7 in cars
# without empty layers). Test 2, whole layout 0.3 lower: right. The engine drops empty layers under a shape;
# blender_vehicle.py does too since (crop_model). JEEP_MEASURED keeps the numbers measured before that.
JEEP_MEASURED = [
    driver((-0.4, 1.05, 0.25), wheel=(-0.4, 1.3, -0.15), wheel_radius=0.18, feet_z=-0.3, feet_y=0.85),
    passenger(1, (0.4, 1.05, 0.25), feet_z=-0.3, feet_y=0.85),
    passenger(2, (0.15, 1.05, 0.95), feet_z=0.65, feet_y=0.85),
    passenger(3, (-0.25, 1.05, 0.95), feet_z=0.65, feet_y=0.85),
]
JEEP = shifted(JEEP_MEASURED, dy=-0.3)

# Ural (ural.xml, uraldamaged.xml "bodywrecked", same body pos): cab cushions 1.35, z -1.05..-0.75 (driver
# x -0.55..-0.15, passenger 0.15..0.65, centre tunnel between), backrest face z -0.7, floor 1.15 (footwell to the
# dash at z -1.55), roof 2.35; steering wheel ring centre ~(-0.35, 1.75, -1.45), radius ~0.2. Open cargo bed: floor
# 1.35, side walls to 2.05 (inner faces x -1.15 / 1.15), long side benches 1.65 high (x -1.05..-0.85 and
# 0.75..0.95, z 0.35..2.95). Cab upright; cargo players sit on the benches facing inward (NPCs too).
URAL = [
    driver((-0.35, 1.4, -0.95), wheel=(-0.35, 1.75, -1.45), wheel_radius=0.2, feet_z=-1.3, feet_y=1.2),
    passenger(1, (0.4, 1.4, -0.95), feet_z=-1.3, feet_y=1.2),
    passenger(2, (-0.9, 1.7, 1.0), feet_y=1.4, yaw=-90, legroom=0.45),
    passenger(3, (0.85, 1.7, 1.8), feet_y=1.4, yaw=90, legroom=0.45),
]

# ZIL-131 fire truck (zil131fire.xml; crew cab, closed equipment body behind): front cushions 1.5, z -1.35..-1.05
# (driver x -0.55..-0.15, passenger 0.15..0.65), backrest face z -1.0, floor 1.2 (footwell z -1.65..-1.45), roof 2.4;
# near-upright steering wheel ("stearing") ring centre ~(-0.4, 1.85, -1.45), radius ~0.22. Rear crew bench cushions
# 1.5, z -0.25..-0.05 (x -0.55..-0.25 and 0.35..0.65), backrest face z 0.0, floor 1.2 (z -0.75..-0.35). Upright.
ZIL_FIRE = [
    driver((-0.4, 1.55, -1.25), wheel=(-0.4, 1.85, -1.45), wheel_radius=0.22, feet_z=-1.6, feet_y=1.25),
    passenger(1, (0.4, 1.55, -1.25), feet_z=-1.6, feet_y=1.25),
    passenger(2, (0.5, 1.55, -0.25), feet_z=-0.6, feet_y=1.25),
    passenger(3, (-0.4, 1.55, -0.25), feet_z=-0.6, feet_y=1.25),
]

# ZIL-131 transport ("AAF Transport truck", ZIL131.xml; paths fixed 2026-11-08, see docs/CHANGES.md):
# same cab as the fire truck's front row (driver cushion x -0.65..-0.15, passenger 0.05..0.55; cushions 1.5, backrest
# face z -1.0, floor 1.2, same steering wheel). Open cargo bed: floor 1.3, long side benches 1.7 high (x -1.05..-0.85
# and 0.75..0.95, z 0.05..3.05). Cargo players on the benches facing inward, like the Ural.
ZIL131 = [
    driver((-0.4, 1.55, -1.25), wheel=(-0.4, 1.85, -1.45), wheel_radius=0.22, feet_z=-1.6, feet_y=1.25),
    passenger(1, (0.3, 1.55, -1.25), feet_z=-1.6, feet_y=1.25),
    passenger(2, (-0.95, 1.75, 1.0), feet_y=1.35, yaw=-90, legroom=0.45),
    passenger(3, (0.85, 1.75, 2.0), feet_y=1.35, yaw=90, legroom=0.45),
]
# ZIL131_ZSU23 ("AAF Truck Technical", VehicleM25): same truck with a ZU-23 gun on the bed (AVF tags): cab + the
# gunner on the mount's left bucket seat (Blender 2026-11-12: same mount model as technical_ZU_23, 0.3 higher, XML
# x -0.05 / z -0.1 from it; vehicle pos z -1.0 -> cushion (-0.5, 2.1, 2.3) in vehicle space, footrest 2.0), facing +z.
ZIL131_ZSU23 = ZIL131[:2] + [gunner_seated((-0.5, 2.1, 2.3), feet_y=2.0, yaw=180)]

# Bus (bus.xml, Damaged body2 identical; no official counterpart): floor 0.6, ceiling 2.8. Driver front left: cushion
# 1.1, z -4.45..-4.25, backrest face z -4.2, pedals at z -4.95; vertical steering wheel ring centre (-0.7, 1.1, -4.75),
# radius 0.2 (low, at cushion height: that's the model). Double seats both sides of the aisle (x -1.05..-0.45 and
# 0.45..1.05), cushions 1.1 over the front wheel arches: forward-facing row z -3.55..-3.25 (backrest face -3.2), back
# to back with a rear-facing row z -2.75..-2.45 (backrest face -2.8, legroom to z -2.15). Further back: low facing
# pairs (cushion 0.9), side benches and a rear bench on a raised floor (1.1). Upright; 4 players use the front rows.
BUS = [
    driver((-0.7, 1.15, -4.45), wheel=(-0.7, 1.1, -4.75), wheel_radius=0.2, feet_z=-4.9, feet_y=0.65),
    passenger(1, (-0.75, 1.15, -3.45), feet_z=-3.8, feet_y=0.65),
    passenger(2, (0.75, 1.15, -3.45), feet_z=-3.8, feet_y=0.65),
    passenger(3, (-0.75, 1.15, -2.55), feet_y=0.65, yaw=180, legroom=0.4),
]
# Bus Modified (body3, same net model position): passenger seats stripped, driver seat kept. Open floor 0.6 from
# z -1.85 to 1.15 (partitions at -2.05 and 1.35): the others sit on the floor.
BUS_MODIFIED = BUS[:1] + [
    passenger(1, (-0.6, 0.65, -1.2), feet_z=-1.65, feet_y=0.6, floor=True),
    passenger(2, (0.6, 0.65, -1.2), feet_z=-1.65, feet_y=0.6, floor=True),
    passenger(3, (-0.6, 0.65, 0.0), feet_z=-0.45, feet_y=0.6, floor=True),
]
# JetBus (bodyjet, same net model position): driver seat kept, a jet engine fills the cabin from z -2.45 back. The
# bare front wheel arches (top 1.1, z -3.05..-2.85, x -1.05..-0.45 / 0.45..1.05) are the only other seats: one
# passenger on each, facing the aisle (floor 0.6, x -0.25..0.15).
JETBUS = BUS[:1] + [
    passenger(1, (0.55, 1.15, -3.05), feet_y=0.65, yaw=90, legroom=0.5),
    passenger(2, (-0.55, 1.15, -2.85), feet_y=0.65, yaw=-90, legroom=0.5),
]

# PAZ-3205 ("Soviet Bus"; body stored turned 180 deg, Damaged body2 identical): floor 0.7, ceiling 2.6. Driver front
# left: cushion 1.2, x -0.8..-0.5, z -2.45..-2.15, backrest face z -2.1, floor 0.7 at the pedals (z -2.95); flat bus
# wheel ("steer", tilted 10 deg) ring centre (-0.65, 1.53, -2.74), radius 0.2. Double seats x -1.05..-0.25 and
# 0.25..1.05 in face-to-face pairs: rear-facing row z -1.65..-1.35 (cushion 1.1), forward-facing row z -0.35..-0.05
# (cushion 1.1, backrest face 0.0); next pair: forward row z 0.75..1.05 (cushion 1.2, backrest face 1.1). A grab pole
# stands at x 0.62, z -0.5, between the two right-hand places of the forward row: that passenger takes the window
# place (x 0.85). Upright.
PAZ = [
    driver((-0.65, 1.25, -2.35), wheel=(-0.65, 1.53, -2.74), wheel_radius=0.2, feet_z=-2.95, feet_y=0.75),
    passenger(1, (-0.65, 1.15, -0.25), feet_z=-0.6, feet_y=0.75),
    passenger(2, (0.85, 1.15, -0.25), feet_z=-0.6, feet_y=0.75),
    passenger(3, (-0.65, 1.25, 0.85), feet_z=0.45, feet_y=0.75),
]

# American semi (semitruck-us; Semi, Damaged body2, Modified body3, Special body4: same net model position, same
# seat rays): cab floor 1.3, roof ~3.1. Single seats between armrests: cushion 1.7, x -0.65..-0.45 / 0.45..0.65,
# z -2.55..-2.15, backrest face z -2.1; footwell 1.3 at z -2.85..-2.65; vertical steering wheel ring centre
# (-0.55, 2.05, -2.95), radius 0.2. Sleeper behind: lower bunk on the left (top 1.7, x -0.75..-0.15,
# z -1.85..-0.05) under an upper bunk (bottom 2.7), cabinet on the right (top 2.0), floor 1.3 between. Two more
# players sit on the lower bunk edge facing the floor. Upright.
SEMI_US = [
    driver((-0.55, 1.75, -2.35), wheel=(-0.55, 2.05, -2.95), wheel_radius=0.2, feet_z=-2.8, feet_y=1.35),
    passenger(1, (0.55, 1.75, -2.35), feet_z=-2.8, feet_y=1.35),
    passenger(2, (-0.35, 1.75, -1.4), feet_y=1.35, yaw=-90, legroom=0.4),
    passenger(3, (-0.35, 1.75, -0.6), feet_y=1.35, yaw=-90, legroom=0.4),
]

# Flathead semi (cab-over; Semi, Damaged body2, Mod body3: same seat rays): floor 1.5, roof ~3.5. Seats between
# armrests: cushion 1.9, x -0.85..-0.65 / 0.65..0.85, z -1.45..-1.05, backrest face z -1.0. Nearly flat steering
# wheel around (-0.75, 2.3, -1.75), radius 0.2, over the engine cover (top 2.3 from z -1.65 forward). Between the
# seats only a 0.1 m engine hump that runs into the engine cover; the bunks behind are 0.7 m apart: 2 players.
SEMI_FLATHEAD = [
    driver((-0.75, 1.95, -1.25), wheel=(-0.75, 2.3, -1.75), wheel_radius=0.2, feet_z=-1.6, feet_y=1.55),
    passenger(1, (0.75, 1.95, -1.25), feet_z=-1.6, feet_y=1.55),
]

# Cement truck (cement_truck.xml; road spawner Vehiclewg42; official cementtruck_gray_light: overlap 0.30, measured):
# cab floor 0.8, roof 2.3; two seats, cushion 1.2, x -0.9..-0.2 / 0.2..0.9, z -2.55..-2.25, backrest face z -2.2,
# mixer right behind the cab. Vertical steering wheel ring centre (-0.5, 1.55, -2.85), radius 0.2. Upright.
CEMENT_TRUCK = [
    driver((-0.5, 1.25, -2.45), wheel=(-0.5, 1.55, -2.85), wheel_radius=0.2, feet_z=-2.85, feet_y=0.85),
    passenger(1, (0.55, 1.25, -2.45), feet_z=-2.85, feet_y=0.85),
]

# Volga (vehicles/cars/Gaz24/volgawhite.xml, road spawner Vehiclewg18; a different model from the GAZ-24 (1968) set; the
# .vox is named by <group prop0="file=...">; black/blue/taxi are referenced nowhere): front bench cushion 0.6,
# x -0.55..0.65, z -0.45..-0.15, backrest face z -0.1; rear bench cushion 0.6, z 0.35..0.65, backrest face z 0.7, rear
# floor 0.4 at z 0.15..0.25; front floor 0.4 at z -0.65 under the dash; roof 1.4. Vertical steering wheel ring centre
# (-0.4, 0.85, -0.55), radius 0.2. Low car: tilt 55 (GAZ-24 rule).
VOLGA = [
    driver((-0.4, 0.65, -0.35), wheel=(-0.4, 0.85, -0.55), wheel_radius=0.2, feet_z=-0.7, feet_y=0.45, tilt=55),
    passenger(1, (0.45, 0.65, -0.35), feet_z=-0.7, feet_y=0.45, tilt=55),
    passenger(2, (0.45, 0.65, 0.45), feet_z=0.2, feet_y=0.45, tilt=55),
    passenger(3, (-0.4, 0.65, 0.45), feet_z=0.2, feet_y=0.45, tilt=55),
]

# Microcar (microcar.xml, road spawner Vehiclewg38; Damaged "bodyD" Vehiclewb30, same net model position and seat
# rays; official generic_small overlap 0.47, measured): two-seat bench, cushion 0.6, x -0.45..0.45, z -0.05..0.35,
# backrest face z 0.4; floor 0.4 (footwell 0.3 under the dash, dash face z -0.4); roof 1.4; behind the seats only a
# 0.3 m deep shelf. Vertical steering wheel ring centre (-0.3, 0.75, -0.25), radius 0.2. Low car: tilt 55.
MICROCAR = [
    driver((-0.25, 0.65, 0.15), wheel=(-0.3, 0.75, -0.25), wheel_radius=0.2, feet_z=-0.35, feet_y=0.45, tilt=55),
    passenger(1, (0.25, 0.65, 0.15), feet_z=-0.35, feet_y=0.45, tilt=55),
]
# Monster compact ("MonsterCompact", monstercompact.xml, own .vox): 4 low seats, cushion 1.5 over floor 1.3, roof 2.3.
# Front x -0.4..-0.1 / 0.1..0.4, cushion z -0.15..0.15, backrest face z 0.2; rear cushion z 0.55..0.85, backrest face
# z 0.9, rear knees 0.25 from the front seat backs (cramped like the Beetle). Vertical steering wheel ring centre
# (-0.3, 1.65, -0.45), radius 0.2; front floor 1.3 at z -0.35. Tilt 55.
MONSTERCOMPACT = [
    driver((-0.25, 1.55, -0.05), wheel=(-0.3, 1.65, -0.45), wheel_radius=0.2, feet_z=-0.4, feet_y=1.35, tilt=55),
    passenger(1, (0.25, 1.55, -0.05), feet_z=-0.4, feet_y=1.35, tilt=55),
    passenger(2, (0.25, 1.55, 0.65), feet_z=0.4, feet_y=1.35, tilt=55),
    passenger(3, (-0.25, 1.55, 0.65), feet_z=0.4, feet_y=1.35, tilt=55),
]

# 1973 Ford Falcon XB GT (MadMax2; normal + damaged body2, road spawners Vehiclewg21 / wb19; the <vehicle> is turned
# 180 deg in its XML, positions here are in its own frame; official racingcar overlap 0.33, measured). Right-hand
# drive. Floor 0.5, roof 1.3. Front seats cushion 0.6, z 0.05..0.35, backrest face z 0.4; rear bench cushion 0.6,
# z 0.65..0.95, backrest face z 1.0 (rear knees 0.25 from the front seat backs, cramped). Vertical steering wheel ring
# centre (0.4, 0.85, -0.15), radius 0.2; front floor 0.5 at z -0.3. Low car: tilt 55.
FALCON = [
    driver((0.4, 0.65, 0.15), wheel=(0.4, 0.85, -0.15), wheel_radius=0.2, feet_z=-0.3, feet_y=0.55, tilt=55),
    passenger(1, (-0.4, 0.65, 0.15), feet_z=-0.3, feet_y=0.55, tilt=55),
    passenger(2, (-0.4, 0.65, 0.75), feet_z=0.55, feet_y=0.55, tilt=55),
    passenger(3, (0.4, 0.65, 0.75), feet_z=0.55, feet_y=0.55, tilt=55),
]
# Pursuit Special (the Mad Max 2 interceptor, own .vox at the same net position): same driver seat (same seat rays);
# no passenger bench or rear seats. The left door model ("door_l", a prop on hinges) carries a sideways seat: a ledge
# (top 0.7, x -0.7..-0.35, z -0.05..0.35) with the door panel as backrest (inner face x -0.65), facing the driver;
# roof 1.3 above it (head through the roof a little, as in the small cars); feet on the floor (0.5) by the tunnel.
# Bare floor 0.5 behind the front seats (z 0.45..0.85): 2 players on the floor. The rig is fixed to the car, so if
# the door is knocked open the passenger stays where the ledge was.
PURSUIT_SPECIAL = FALCON[:1] + [
    passenger(1, (-0.4, 0.75, 0.15), feet_y=0.55, yaw=-90, legroom=0.25, tilt=55),
    passenger(2, (-0.4, 0.55, 0.7), feet_z=0.45, feet_y=0.55, floor=True),
    passenger(3, (0.4, 0.55, 0.7), feet_z=0.45, feet_y=0.55, floor=True),
]

# Military truck (military_truck / _um .vox; "UM Damaged" is the one in use: roadblocks 8 and 9; plain and Damaged
# only in dev/levels/test_vehicle.xml; all three same net model position and seat rays; official military_truck_green overlap
# 0.49, measured): cab floor 1.2, roof 2.7; two seats, cushion 1.7, x -1.0..-0.5 / 0.5..1.0, z -2.35..-2.05, backrest
# face z -2.0; a 0.3 m wide engine cover between them (top 1.8); flat steering wheel ring centre (-0.6, 2.05, -2.75),
# radius 0.2. Open cargo bed: floor 1.4, side walls inner faces x -1.15 / 1.15, front wall z -0.9, no benches: two
# players on the floor, backs to the side walls, facing inward. Upright.
MILITARY_TRUCK = [
    driver((-0.65, 1.75, -2.25), wheel=(-0.6, 2.05, -2.75), wheel_radius=0.2, feet_z=-2.7, feet_y=1.25),
    passenger(1, (0.75, 1.75, -2.25), feet_z=-2.7, feet_y=1.25),
    passenger(2, (-0.9, 1.45, 0.6), feet_y=1.45, yaw=-90, legroom=0.45, floor=True),
    passenger(3, (0.9, 1.45, 1.6), feet_y=1.45, yaw=90, legroom=0.45, floor=True),
]

# RV MethLab ("Bad RV", MethLab.xml; road spawner Vehiclewg26): cab floor 0.75, two seats x -0.45 / 0.45, cushion
# 1.15, z -3.25..-2.95, backrest face z -2.9, roof sloping to ~2.3 over them; vertical steering wheel ring centre
# (-0.45, 1.4, -3.55), radius 0.2. Living area: aisle floor 0.75, roof 2.65; left wall counters (1.55) and cabinets;
# right wall bench (top 1.15, x 0.55..0.95, z 2.0..3.65) with a backrest panel (face x 0.9 at hip height): two
# seats facing the aisle. Upright.
RV_METHLAB = [
    driver((-0.45, 1.2, -3.15), wheel=(-0.45, 1.4, -3.55), wheel_radius=0.2, feet_z=-3.45, feet_y=0.8),
    passenger(1, (0.45, 1.2, -3.15), feet_z=-3.45, feet_y=0.8),
    passenger(2, (0.65, 1.2, 2.4), feet_y=0.8, yaw=90, legroom=0.45),
    passenger(3, (0.65, 1.2, 3.2), feet_y=0.8, yaw=90, legroom=0.45),
]

# BugZilla ("Monster Bug", own .vox): stripped Beetle. Only the driver seat (cushion 1.0, x -0.5..-0.1, z -0.15..0.15,
# backrest face z 0.2); floor 0.8 (footwell under the dash to z -0.55); roof 1.75; vertical steering wheel ring
# centre (-0.3, 1.15, -0.35), radius 0.2. Engine and fuel tank fill the back from z 0.75; doors checked (no seats).
# Like the Beetle Modified: two players on the floor (front right; sideways behind the seats). Tilt 55 (low roof).
BUGZILLA = [
    driver((-0.3, 1.05, -0.05), wheel=(-0.3, 1.15, -0.35), wheel_radius=0.2, feet_z=-0.5, feet_y=0.85, tilt=55),
    passenger(1, (0.3, 0.85, -0.05), feet_z=-0.5, feet_y=0.85, floor=True),
    passenger(2, (-0.35, 0.85, 0.5), feet_y=0.85, yaw=-90, legroom=0.5, floor=True),
]

# Golf cart (golf_cart.xml road spawner Vehiclewg45; golf_cartBomb.xml "Nuclear Golfcart": same body and seat rays,
# bomb on the roof): bench cushion 0.6, x -0.35..0.35, backrest face z 0.6 at hip height, floor 0.2 (z -0.45..0.05),
# roof 1.7. Separate "steer" part, ring centre (-0.35, 0.83, -0.39), radius 0.2, tilted ~50 deg; it is 0.75 m ahead
# of the seat point, so the driver's arms stretch. Upright, 2 players (the space behind the bench is 0.3 m deep).
GOLF_CART = [
    driver((-0.3, 0.65, 0.35), wheel=(-0.35, 0.83, -0.39), wheel_radius=0.2, feet_z=-0.3, feet_y=0.25),
    passenger(1, (0.3, 0.65, 0.35), feet_z=-0.3, feet_y=0.25),
]

# Small red boat (smallboat_red.xml, spawner vehicleS13): open boat, floor 1.35, gunwale 2.05, seats without backrests
# at 1.75: stern seat (z 2.55..2.75, the v1 player spot), a wide middle seat (z -0.65..1.15; a hole at x -0.35,
# z -0.45) and a bow seat (z -2.45..-1.85); footwells 1.35 between. No steering wheel (outboard motor; its hidden
# road wheels are named "wheel"): the driver's hands rest in front of the lap. Upright.
SMALLBOAT = [
    driver((0.0, 1.8, 2.65), wheel=(0.0, 1.95, 2.3), wheel_radius=0.15, feet_z=2.25, feet_y=1.4),
    passenger(1, (-0.5, 1.8, -0.45), feet_z=-0.95, feet_y=1.4),
    passenger(2, (0.4, 1.8, -0.45), feet_z=-0.95, feet_y=1.4),
    passenger(3, (0.0, 1.8, -2.15), feet_y=1.4, yaw=180, legroom=0.5),
]

# Shed / Garage ("Shed?" spawn menu, vehicleS11; GARAGE vehicleS12): a mud-brick building on wheels, same room in
# both: floor 0.4, roof 2.7, walls x -1.5 / 1.5. A chair (seat top 0.8, x -0.25..0.25, z -0.65..-0.25, backrest face
# z -0.2) faces a small control column (top 1.2 at z -1.15); the v1 eye point is above the chair. Driver on the chair,
# hands on the column; three players on the floor, backs to the side walls. Upright.
SHED = [
    driver((0.0, 0.85, -0.45), wheel=(0.0, 1.1, -1.15), wheel_radius=0.1, feet_z=-0.85, feet_y=0.45),
    passenger(1, (-1.25, 0.45, 0.4), feet_y=0.45, yaw=-90, legroom=0.5, floor=True),
    passenger(2, (1.25, 0.45, 0.9), feet_y=0.45, yaw=90, legroom=0.5, floor=True),
    passenger(3, (-1.25, 0.45, -0.8), feet_y=0.45, yaw=-90, legroom=0.5, floor=True),
]

# Wheeled Cockpit (wheeledcockpit.xml, spawn menu; vehicleS10): an open aircraft cockpit on a trailer. Two seats with
# headrests: cushion 3.9, x -1.25..-0.65 / 0.65..1.25, z -2.55..-2.05, backrest face z -1.9; floor 3.3; no yoke or
# wheel in the model (hands rest in front). Upright, 2 players.
WHEELED_COCKPIT = [
    driver((-0.95, 3.95, -2.15), wheel=(-0.95, 4.25, -2.55), wheel_radius=0.15, feet_z=-2.75, feet_y=3.35),
    passenger(1, (0.95, 3.95, -2.15), feet_z=-2.75, feet_y=3.35),
]

# LeBoat (sailboat.xml, spawn menu; vehicleS14): stern cockpit, footwells 2.0, side benches 2.4 with the coaming as a
# low backrest (x -1.5 / 1.5), a stern seat across (2.4, z 5.55..5.75). Two ship's wheels in the body model, vertical
# rings ~0.8 m across at z 5.15, centres (-1.0, 2.55) and (1.0, 2.55), with a small aft footwell (floor 1.9,
# z 5.25..5.45) behind them. Driver stands at the left wheel (the v1 eye point's side; user request 2026-11-08, the
# first version sat between the wheels); three players on the side benches facing inward. Upright.
SAILBOAT = [
    driver_standing((-1.0, 1.9, 5.4), wheel=(-1.0, 2.55, 5.15), wheel_radius=0.4),
    passenger(1, (-1.25, 2.45, 3.9), feet_y=2.05, yaw=-90, legroom=0.45),
    passenger(2, (1.25, 2.45, 3.9), feet_y=2.05, yaw=90, legroom=0.45),
    passenger(3, (-1.25, 2.45, 4.6), feet_y=2.05, yaw=-90, legroom=0.45),
]

# Tractor From Hell (tractorFromHell.xml, "bodyflames"; official tractor overlap 0.25, measured): open seat, cushion
# 1.4, x -0.15..0.15, z 0.55..0.85, backrest face z 0.9; flat steering wheel ring around (-0.05, 1.65, 0.25), radius
# 0.2; footplate 1.2 under it. Driver only, like the official tractor (Blue/Red Tractor).
TRACTOR_FROM_HELL = [
    driver((-0.05, 1.45, 0.65), wheel=(-0.05, 1.65, 0.25), wheel_radius=0.2, feet_z=0.25, feet_y=1.25),
]

# Insurgent chase cars ("vehicles/cars/Enemy Car/Car.vox", one model file with several bodies on the same chassis; the
# chassis vox is turned 180 deg, positions here are vehicle coordinates). Pickup ("Utebody") and SUV ("SUVbody")
# share the cab: front cushions top 0.9, x -0.75..-0.35 (driver) and 0.15..0.55, z -0.45..0.15, backrest face z 0.0;
# vertical steering wheel ring centre (-0.55, 1.35, -0.55), radius 0.2; front floor 0.6 back from the firewall at
# z -1.1; roof 2.05 (1.05 m above the seat point: upright). SUV rear bench: cushion top 0.9, x -0.75..0.55,
# z 0.65..1.15, backrest face z 1.0, floor 0.7. SUV cargo: floor 0.7, wheel arches as low benches (top 1.0, left
# x -0.95..-0.75, right 0.55..0.75, z 1.15..1.75), a crate between them (x -0.4..0.2, top 1.1). Pickup bed: floor 0.7,
# z 0.45..2.6, side wall inner faces x -1.0 / 0.8, cab back wall face z 0.6, open-topped toolbox on the right by the
# cab (x 0.15..0.75, z 0.65..0.95, rim 1.1), wheel arches z 1.05..1.85 (left top 1.2). Sport ("Sportbody"): same
# seats 0.3 further back, floor 0.7 (firewall z -0.8); behind the cab (wall face z 1.0) a small open tray, floor 0.7,
# tailgate z 2.0.
# User request 2026-11-09: the back places match where the enemy crews sit in the copies (fakegore stand-ins in
# VehicleD*), as normal seats so friendly NPCs use them too (no "floor" rigs): pickup like VehicleD5 (two behind
# the cab facing back: one on the toolbox, one low on the left; the D5 stand-in there floats, nothing under it),
# SUV like VehicleD3/D6 (rear bench + one on each cargo wheel arch facing inward: 6 seats), sport like VehicleD1/D4
# (one in the tray facing back). Low places are reclined (tilt 55): the NPC sit pose then raises its legs toward
# the foot points, as on the official sports car's floor-level seats.
PICKUP_ENEMY = [
    driver((-0.55, 0.95, -0.25), wheel=(-0.55, 1.35, -0.55), wheel_radius=0.2, feet_z=-0.85, feet_y=0.65),
    passenger(1, (0.35, 0.95, -0.25), feet_z=-0.85, feet_y=0.65),
    passenger(2, (0.3, 1.15, 0.85), feet_y=0.75, yaw=180, legroom=0.45),
    passenger(3, (-0.25, 0.8, 0.85), feet_y=0.75, yaw=180, legroom=0.5, tilt=55),
]
SUV_ENEMY = PICKUP_ENEMY[:2] + [
    passenger(2, (0.25, 0.95, 0.75), feet_z=0.4, feet_y=0.75),
    passenger(3, (-0.45, 0.95, 0.75), feet_z=0.4, feet_y=0.75),
    passenger(4, (-0.75, 1.05, 1.5), feet_y=0.75, yaw=-90, legroom=0.2),
    passenger(5, (0.55, 1.05, 1.6), feet_y=0.75, yaw=90, legroom=0.25),
]
SPORT_ENEMY = [
    driver((-0.55, 0.95, 0.05), wheel=(-0.55, 1.35, -0.25), wheel_radius=0.2, feet_z=-0.55, feet_y=0.75),
    passenger(1, (0.35, 0.95, 0.05), feet_z=-0.55, feet_y=0.75),
    passenger(2, (-0.1, 0.8, 1.4), feet_y=0.75, yaw=180, legroom=0.45, tilt=55),
]

# BRDM-2 (brdm.xml, only in dev/levels/test_vehicle.xml; in play as VehicleD7 "Insurgent Ambush 7", same body placement): floor
# 1.1, walls inner faces x -0.65 / 0.65 (troop compartment), roof 2.4. Front bench cushion top 1.4, x -0.5..0.5,
# z -1.75..-1.45, backrest face z -1.5; vertical steering wheel ring centre (-0.3, 1.75, -2.05), radius 0.2; front
# footwell to the nose armour at z -2.25, a column at x 0 between the feet. Troop compartment: side benches along both
# walls, top 1.4, reaching x -0.4 / 0.4, z -1.15..1.25. Upright. Places as the VehicleD7 crew (driver + 4 on the side
# benches facing inward at z -0.6 / 0.7) plus the commander's place on the front bench, which the crew leaves empty.
BRDM = [
    driver((-0.3, 1.45, -1.75), wheel=(-0.3, 1.75, -2.05), wheel_radius=0.2, feet_z=-2.1, feet_y=1.15),  # knees just under the wheel rim (tight cab)
    passenger(1, (0.3, 1.45, -1.75), feet_z=-2.1, feet_y=1.15),
    passenger(2, (-0.45, 1.45, -0.6), feet_y=1.15, yaw=-90, legroom=0.35),
    passenger(3, (0.45, 1.45, -0.6), feet_y=1.15, yaw=90, legroom=0.35),
    passenger(4, (-0.45, 1.45, 0.7), feet_y=1.15, yaw=-90, legroom=0.35),
    passenger(5, (0.45, 1.45, 0.7), feet_y=1.15, yaw=90, legroom=0.35),
]

# AVF offroad (vehicles/avf/prefabs/technicals/offroad.vox; plain "body" with roof, "body__scaffoled" open, GMG
# "body_enclosed_turret_ring", all at the same position; VehicleAAF2 "AAF Jeep" = the open one): front cushions top
# 1.0, x -0.55..-0.15 / 0.05..0.45, z -0.25..0.15, backrest face z 0.1; rear bench x -0.65..0.55, z 0.45..0.85,
# backrest face z 0.8; floor 0.7, pedals 0.75 at z -0.9; vertical steering wheel ring centre (-0.35, 1.25, -0.75),
# radius 0.2; roof (plain/GMG) 2.0, roll bar (open). Upright. The VehicleAAF2 crew sits on the same four places
# (driver + rear bench). GMG: the gunner's place comes with the mounted-gun work.
OFFROAD = [
    driver((-0.35, 1.05, -0.15), wheel=(-0.35, 1.25, -0.75), wheel_radius=0.2, feet_z=-0.85, feet_y=0.8),
    passenger(1, (0.25, 1.05, -0.15), feet_z=-0.85, feet_y=0.75),
    passenger(2, (0.25, 1.05, 0.6), feet_z=0.35, feet_y=0.75),  # 0.2 from the backrest: knees clear the front seats
    passenger(3, (-0.35, 1.05, 0.6), feet_z=0.35, feet_y=0.75),
]
# WMIK ("body_scaffoled_military", 0.05 to the right): right-hand drive, wheel ring centre (0.4, 1.25, -0.75);
# front cushions x -0.5..-0.1 / 0.1..0.5; open weapons bed behind the cab (no rear seats; gunner with the
# mounted-gun work).
OFFROAD_WMIK = [
    driver((0.35, 1.05, -0.15), wheel=(0.4, 1.25, -0.75), wheel_radius=0.2, feet_z=-0.85, feet_y=0.8),
    passenger(1, (-0.3, 1.05, -0.15), feet_z=-0.85, feet_y=0.75),
]

# AVF technical pickup (vehicles/avf/prefabs/technicals/technical.vox; "Pickup Truck" bodyturret, "Pickup Lifted" bodyturret3
# with the same cab, "Pickup Damaged" bodyturret2 = same cab 0.05 left / 0.1 back, no steering wheel ring): bench
# seat, cushion top 1.2, x -0.75..-0.15 / 0.15..0.75, z -0.25..0.15, backrest face z 0.0; roof 1.9 (0.65 m above the
# seat point: tilt 55); footwell floor 0.9 up to the dash at z -0.6; vertical steering wheel ring centre
# (-0.5, 1.35, -0.55), radius 0.2. Open bed: floor 1.0, z 0.75..2.45, side rails at x -0.75 / 0.75 with their top
# 1.45 (chair height above the bed floor): two places sitting on the rails facing inward, staggered. The cab is
# smaller than the player (0.7 m cushion to roof): heads stick out of the roof whatever the pose. In-game test
# 2026-11-09 with the official pickup_red pose (seat rot 70, head point 0.55 up / 0.25 back): the head still stuck
# out and the lean looked silly; user decision: upright, head through the roof accepted.
# Technicals (DShK, SPG-9: same body 0.1 back; ZU-23: 0.05 left, 0.1 back): the gun stands in the bed: cab only,
# gunner with the mounted-gun work.
PICKUP_TRUCK = [
    driver((-0.5, 1.25, -0.25), wheel=(-0.5, 1.35, -0.55), wheel_radius=0.2, feet_z=-0.6, feet_y=0.95),
    passenger(1, (0.45, 1.25, -0.25), feet_z=-0.6, feet_y=0.95),
    passenger(2, (-0.75, 1.5, 1.3), feet_y=1.05, yaw=-90, legroom=0.45),
    passenger(3, (0.75, 1.5, 1.9), feet_y=1.05, yaw=90, legroom=0.45),
]

# ZIS-151 (vehicles/avf/prefabs/ZIS-151; ZIS-151 "body3" road spawner Vehiclewg28, Damaged "body2" + cargo box wb26,
# Katyusha "body" VehicleM2; Damaged and Katyusha cabs = the plain one 0.05 further back): bench cushion top 1.5,
# x -0.6..0.6, z -1.3..-0.95, backrest face z -0.95; cab floor 1.2 back from the dash at z -1.9; roof underside 2.3
# (0.75 m above the seat point: heads ~0.1 through it in-game, kept upright as in the pickup); steering:
# a voxbox column tilted 40 deg rising from the floor toward the driver, top end (-0.3, 1.9, -1.42) = the (near-flat)
# wheel; doors are separate bodies. Plain: open bed, floor 1.4, slatted side walls inner faces x -1.05 / 1.05, no
# benches. Damaged: closed cargo box, floor 1.3, walls inner faces x -1.05 / 1.05, roof 3.35. Bed/box: two players on
# the floor, backs to the side walls (as the military truck). Katyusha: the launcher fills the bed (its own
# operated <vehicle> "bm-14" in the same file, mounted-gun work): cab only. Upright.
ZIS151_CAB = [
    driver((-0.3, 1.55, -1.2), wheel=(-0.3, 1.9, -1.45), wheel_radius=0.2, feet_z=-1.65, feet_y=1.25),
    passenger(1, (0.3, 1.55, -1.2), feet_z=-1.65, feet_y=1.25),
]
ZIS151 = ZIS151_CAB + [
    passenger(2, (-0.8, 1.45, 1.0), feet_y=1.45, yaw=-90, legroom=0.45, floor=True),
    passenger(3, (0.8, 1.45, 2.0), feet_y=1.45, yaw=90, legroom=0.45, floor=True),
]
ZIS151_DAMAGED = shifted(ZIS151_CAB, dz=0.05) + [
    passenger(2, (-0.8, 1.35, 1.0), feet_y=1.35, yaw=-90, legroom=0.45, floor=True),
    passenger(3, (0.8, 1.35, 2.0), feet_y=1.35, yaw=90, legroom=0.45, floor=True),
]

# Willys Jeep (vehicles/avf/prefabs/Weaponised vehicles/Willys Jeep.xml; only the drivable copy in levels/level_tutorial.xml, same
# placement): an undersized model (v1 eye point 0.5 above the seat). Floor 0.2; front seats cushion top 0.5,
# x -0.45..-0.15 / 0.25..0.55, z 0.15..0.45, backrest face z 0.4; rear bench x -0.45..0.55, cushion top 0.5,
# backrest face z 1.2; tiny tilted steering wheel ring ~(-0.25, 0.9, 0.0), radius ~0.12; firewall z -0.35. Open
# top: upright. The player is too big for it: knees into the dashboard (accepted, tutorial only).
WILLYS = [
    driver((-0.3, 0.55, 0.15), wheel=(-0.25, 0.9, 0.0), wheel_radius=0.12, feet_z=-0.25, feet_y=0.25),
    passenger(1, (0.4, 0.55, 0.15), feet_z=-0.25, feet_y=0.25),
    passenger(2, (0.4, 0.55, 0.95), feet_z=0.6, feet_y=0.25),
    passenger(3, (-0.3, 0.55, 0.95), feet_z=0.6, feet_y=0.25),
]

# BMP-1 / BMP-1P / BMP-2 (vehicles/avf/prefabs/bmp; hulls "bmp-1 body", "bodybmp-1 3", "bodybmp-2": same interior at the same
# place, overlap 0.94-0.99; military spawners VehicleM18/M19/M20). Vehicle origin high (pos y 2.48): interior
# coordinates are negative. Hull floor -1.9, roof underside -0.8. Driver front left: small cushion top -1.5
# (z -1.55..-1.45; the -1.8 layer is its base), backrest face z -1.2, steering levers ahead at ~z -2.0 / y -1.4 (hands on them), feet on the floor. Rear troop
# compartment: a central bench (cushion top -1.6, x -0.45..0.55, z 1.85..3.35) with a centre backrest (faces x -0.2 /
# 0.3): troops sit back to back facing the hull sides, ~0.35 m to the wall racks. Commander/gunner places are in the
# turret: with the mounted-gun work. Upright; heads ~at the roof in the troop compartment.
BMP12 = [
    driver((-0.45, -1.6, -1.45), wheel=(-0.45, -1.4, -2.0), wheel_radius=0.2, feet_z=-1.95, feet_y=-1.85),  # -1.45: head in the hatch; -1.75: hips in the cushion
    passenger(1, (-0.4, -1.55, 2.2), feet_y=-1.85, yaw=90, legroom=0.3),
    passenger(2, (0.5, -1.55, 2.2), feet_y=-1.85, yaw=-90, legroom=0.3),
    passenger(3, (-0.4, -1.55, 3.0), feet_y=-1.85, yaw=90, legroom=0.3),
    passenger(4, (0.5, -1.55, 3.0), feet_y=-1.85, yaw=-90, legroom=0.3),
]

# BMP-3 (vehicles/avf/prefabs/bmp/BMP-3 d.xml; spawn menu, military spawner VehicleM21; hull "bmp-3 boby" + front roof
# "bmp-3 boby r1"): floor 0.7 (0.8 in the front row), roof underside 2.0. Front row of three seats (cushion top 1.0,
# z -1.55..-1.25, backrest face z -1.3) at x -0.9 / -0.1 / 0.8; controls ahead of the middle one (z -2.5..-2.0): the
# driver sits in the middle as in a real BMP-3 (the v1 eye point was on the left seat). Behind the turret basket
# (x -0.25..0.15) one forward-facing seat per side (cushion top 1.0, x -1.25..-0.85 / 0.65..1.05, z 0.65..1.15,
# backrest face z 1.1); rear bench of seat pads across the hull (top 1.0, z 1.65..2.25, backrest face z 2.0), over
# it the stern access corridor. Upright. The two seats behind the turret are narrow tubs with a raised front lip and
# armrests (mannequin arms and thighs through them): left out.
BMP3 = [
    driver((-0.1, 1.05, -1.55), wheel=(-0.1, 1.4, -1.95), wheel_radius=0.2, feet_z=-1.85, feet_y=0.85),
    passenger(1, (-0.9, 1.05, -1.55), feet_z=-1.85, feet_y=0.85),
    passenger(2, (0.8, 1.05, -1.55), feet_z=-1.85, feet_y=0.85),
    passenger(3, (-0.5, 1.05, 1.75), feet_z=1.4, feet_y=0.75),
    passenger(4, (0.5, 1.05, 1.75), feet_z=1.4, feet_y=0.75),
]

# Tanks: the hulls are too low to sit upright; drivers recline as in the official military_tank_green (seat rot 80,
# ik_head 0.45 up / 0.25 back, legs stretched forward). Turret crews come with the mounted-gun work.
TANK_HEAD = (0, 0.45, 0.25)
# T-72 (vehicles/avf/prefabs/t72_desert: T72A, T72B, T72B3 mod 2016 = spawn menu "T-72", T72B3 obj 1989, T72BA; military
# spawners VehicleM14-M17 / M3; hull "t72body" + "hull_roof" identical in all five): driver compartment front centre,
# x -0.45..0.45, floor 0.9, roof underside 1.7 (0.8 m), backrest face z -1.8, no cushion; front plate / controls from
# z -2.55 up from 1.25. v1 eye point (0.05, 1.47, -2.1). Riders (user request 2026-11-09): engine deck flat at 1.9
# from behind the turret (z 1.65, turret rear 1.55) to z 3.3, edges x -1.9 / 1.9: two per side sitting on the edge
# facing outward, legs over the side, as tank riders do (normal seats, NPCs ride too).
def tank_riders(deck_y, edge_x, zs):
    return [passenger(1 + 2 * i + j, (s * (edge_x - 0.3), deck_y + 0.05, z), feet_y=deck_y - 0.4, yaw=-90 * s,
                      legroom=0.45)
            for i, z in enumerate(zs) for j, s in enumerate((-1, 1))]
T72 = [
    driver((0.05, 0.95, -2.2), wheel=(0.05, 1.25, -2.45), wheel_radius=0.2, feet_z=-2.85, feet_y=0.95, tilt=80,
           head=TANK_HEAD),
] + tank_riders(1.9, 1.9, (2.1, 2.9))

# T-54 / T-55 (vehicles/avf/prefabs/T-54 55: T-54-3 / T-55A, Alashya + Desert; spawn menu "T-54 AAF", "T-55A AAF"; military
# spawners VehicleM10-M13; hulls "hull T-54 (1951)" / "hull T-55A" + "front", same driver compartment): floor 0.1, hull
# top ~1.1; driver front left under his hatch: low cushion top 0.3, z -1.95..-1.65, short backrest face z -1.6;
# controls ahead (~z -2.2). Reclined like the T-72. Engine deck behind the turret (turret rear z 1.15): raised centre
# 1.1, fenders 0.9 out to x -1.75 / 1.75; external fuel tanks on the right fender (top 1.1, z 0.5..1.4 and 1.5..2.4);
# left fender: T-55 stowage boxes (top 1.1, z 1.65..2.65), T-54 one small tank (z 1.9..2.3). Riders sit on these flat
# tops / the fender edge facing outward, legs over the side, each spot measured (shoulders >= 0.45 apart).
def side_rider(sort, side, top_y, z, x=1.45, feet_y=None):
    """A tank rider sitting on a flat top at the deck side, facing outward (side -1 left, 1 right), legs over the side."""
    return passenger(sort, (side * x, top_y + 0.05, z), feet_y=top_y - 0.4 if feet_y is None else feet_y, yaw=-90 * side,
                     legroom=0.45)
T54_DRIVER = [
    driver((-0.75, 0.35, -2.0), wheel=(-0.75, 0.55, -2.25), wheel_radius=0.2, feet_z=-2.6, feet_y=0.15, tilt=80,
           head=TANK_HEAD),
]
T54 = T54_DRIVER + [side_rider(1, -1, 1.0, 1.55), side_rider(2, 1, 1.1, 1.0), side_rider(3, -1, 0.9, 2.65),
                    side_rider(4, 1, 1.1, 1.95)]
T55 = T54_DRIVER + [side_rider(1, -1, 1.1, 2.0), side_rider(2, 1, 1.1, 1.0), side_rider(3, -1, 1.0, 1.05),
                    side_rider(4, 1, 1.1, 1.95)]

# T-34-85 (vehicles/avf/prefabs/T-34/T-34-85.xml; spawn menu "T-34", military spawner VehicleM9; hull "hull T-34-85" + "front" +
# "rear"): floor 0.5; driver front left (v1 eye (-0.35, 1.48, -1.7)): low cushion top 0.7, z -1.95..-1.75, backrest face
# z -1.7, the sloped front plate over him: reclined like the T-72. Engine deck behind the turret (turret rear z 0.55):
# centre 1.8, side ledges top 1.7 at x -1.2 / 1.2 stepping down to the fenders (top 1.25): riders on the ledges facing
# outward, feet on the fenders; external fuel tanks along the ledges (top ~1.8): seats at 1.8.
T34 = [
    driver((-0.35, 0.75, -2.1), wheel=(-0.35, 1.0, -2.4), wheel_radius=0.2, feet_z=-2.6, feet_y=0.65, tilt=80,
           head=TANK_HEAD),
    side_rider(1, -1, 1.8, 0.9, x=1.15, feet_y=1.3), side_rider(2, 1, 1.8, 0.9, x=1.15, feet_y=1.3),
    side_rider(3, -1, 1.8, 1.5, x=1.15, feet_y=1.3), side_rider(4, 1, 1.8, 1.5, x=1.15, feet_y=1.3),
]
# M-51 Super Sherman (vehicles/avf/prefabs/M-51 Super Sherman; spawn menu "M-51 Sherman", military spawner VehicleM8; hull
# "body" + "front"): floor 0.5, hull roof underside 1.9; driver front left (v1 eye (-0.5, 1.7, -0.55)): cushion top 1.0,
# z -0.75..-0.45, levers ahead; room to sit upright. The big turret (z -0.35..2.65, sweeps ~1.75 m around its ring)
# covers the hull top: riders on the rear deck (top 1.75, z 2.6..3.4) side edges at x -1.15 / 1.15, facing outward,
# feet on the fenders (top 1.3).
SHERMAN = [
    driver((-0.5, 1.05, -0.6), wheel=(-0.5, 1.25, -1.15), wheel_radius=0.2, feet_z=-1.1, feet_y=0.55),
    side_rider(1, -1, 1.75, 2.85, x=1.15, feet_y=1.35), side_rider(2, 1, 1.75, 2.85, x=1.15, feet_y=1.35),
    side_rider(3, -1, 1.75, 3.35, x=1.15, feet_y=1.35), side_rider(4, 1, 1.75, 3.35, x=1.15, feet_y=1.35),
]

TEARDOWN_LAND = r"C:/Program Files (x86)/Steam/steamapps/common/Teardown/data/built-in/prefab/vehicle/land"


def official(prefab, shift=(0.0, 0.0, 0.0), seat=None, move=None, keep=None):
    """Seat rigs copied from an official Teardown 2.x vehicle that uses the same model as the mod vehicle (most
    Mors Longa cars are copies of Teardown 1.x vehicles). Official rigs are children of <body> (body space); the
    result is a function of the mod vehicle's <body pos>, called by patch_text, that returns them in vehicle space.
    shift: body-space offset between the two models (the official models were reworked for 2.x; found by voxel
    overlap, scratchpad match2.py approach, documented in docs/VEHICLES.md). Friendly NPCs sit on
    these like the player does (goreai_sitting.lua copies the engine's seated pose), so nothing NPC-specific.
    seat: (dx, dy, dz) moves only the "seat" location (rig frame), where the mod's cushion differs from the official
    model but the cab (steering wheel, pedals) matches. move: {location name: (dx, dy, dz)} for several locations.
    keep: rig tags to keep (others dropped), e.g. ("driver sort=0",) where the mod vehicle lacks a seat."""
    import xml.etree.ElementTree as ET
    root = ET.parse(os.path.join(TEARDOWN_LAND, prefab)).getroot()
    vehicle = root.find(".//vehicle")
    body = vehicle.find("body")  # the main body (first)
    nums = lambda s: tuple(float(x) for x in (s or "0 0 0").split())
    assert not any(nums(body.get("rot"))), prefab
    bp = nums(body.get("pos"))
    rigs = []
    # rigs under <body> are in body space; under <vehicle> (boxtruck, dumptruck, crane, tractor) in vehicle space
    for parent, off in ((body, (0, 0, 0)), (vehicle, bp)):
        for r in parent.findall("rig"):
            locs = [(l.get("name") or l.get("tags"), nums(l.get("pos")), nums(l.get("rot"))) for l in r.findall("location")]
            mv = dict(move or {})
            if seat:
                mv["seat"] = seat
            locs = [(n, tuple(lp[i] + mv[n][i] for i in range(3)) if n in mv else lp, lr) for n, lp, lr in locs]
            p = nums(r.get("pos"))
            rigs.append((r.get("name"), r.get("tags"), tuple(p[i] - off[i] for i in range(3)), locs, nums(r.get("rot"))))
    if keep is not None:
        rigs = [r for r in rigs if r[1] in keep]
    assert rigs, prefab

    def place(body_pos):
        return [(n, t, tuple(body_pos[i] + p[i] + shift[i] for i in range(3)), locs, rot)
                for n, t, p, locs, rot in rigs]
    return place


SALOON = official("generic_sedan_red.xml")
# shift 0: the -0.1 found first came from comparing uncropped models (the official body has an empty layer at the
# back; see crop_model in blender_vehicle.py). Cropped, shift 0 matches the seat rays.
SPORTSCAR = official("sportscar_green.xml")
# Box truck: same cab, but the mod's seat cushion is 0.1 lower and its backrest 0.1 further back (voxel slices): the
# official seat point sits 0.1 into the cushion, 0.25 m in front of the backrest (rays): moved 0.2 down, 0.1 back.
BOXTRUCK = official("boxtruck_white.xml", seat=(0, -0.2, 0.1))
# Yellow Van (old Teardown van): same cab and backrest as van_yellow, cushion 0.2 higher (rays): seat point up 0.2.
# Van Modified: armed (PKM on a stand where the passenger seat was, AVF tags): driver only until the mounted-gun work.
VAN = official("van_yellow.xml", seat=(0, 0.2, 0))
VAN_MODIFIED = official("van_yellow.xml", seat=(0, 0.2, 0), keep=("driver sort=0",))

def heli_pilot(seat, feet_y, legroom):
    """Seated pilot facing +z (the AS350 flies along its body +z: Heli.lua's Axes[Forward]). Points in the rig frame
    (rig turned 180 about y): left hand on the collective lever at the outer (+x body) side, right hand forward
    on the cyclic between the knees."""
    x, y, z = seat
    fy = feet_y - y
    return ("driver", "driver sort=0", seat, [
        ("ik_foot_l", (-0.15, fy, -legroom), (0, 90, 50)),
        ("ik_foot_r", (0.15, fy, -legroom), (0, 90, 50)),
        ("seat", (0, 0, 0), (0, 0, 0)),
        ("ik_hand_l", (-0.3, 0.1, -0.2), (0, 90, 0)),
        ("ik_hand_r", (0.1, 0.05, -0.35), (0, 90, 0)),
        ("ik_head", (0, 0.8, 0.1), (0, 90, 0)),
    ], (0, 180, 0))


# AS350 helicopters (vehicles/aircraft/AS350, 2026-11-13). Not vehicles in the original (the script teleported the pilot every
# frame); the port wraps the whole helicopter in a <vehicle> (no pos: vehicle space = the Heli.lua <script> space,
# body "Heli" at 0.1 0.1 3.7). Measured in body space, nose at +z: cabin floor 1.2; front seats cushion 1.6,
# backrest face z 0.1, roof 2.7; the AI pilot ragdoll sits on the right seat (x -0.5), so the player pilot takes the
# left seat (x 0.45, where the original's first-person camera Pilot_View_1p sits: 2.4 = seat + 0.75); rear bench
# cushion 1.6 across x -0.85..0.85, backrest face z -1.1, roof 2.5, front seat backs z ~0.0 (feet at z -0.45).
# CIV and VIP use the same cabin. INSURGENT ("vip cabin segment", door gun on the left): the left (+x) half of the
# cabin is open: no left front seat (the pilot place stays where the original put the player, on no cushion) and the
# bench stops at x 0.15, with a block 0.1 lower at x 0.25..0.65.
AS350_BODY = [
    heli_pilot((0.45, 1.65, 0.35), feet_y=1.2, legroom=0.5),
    passenger(1, (-0.55, 1.65, -0.85), feet_y=1.2, yaw=180, legroom=0.4),
    passenger(2, (0.0, 1.65, -0.85), feet_y=1.2, yaw=180, legroom=0.4),
    passenger(3, (0.55, 1.65, -0.85), feet_y=1.2, yaw=180, legroom=0.4),
]
AS350 = shifted(AS350_BODY, 0.1, 0.1, 3.7)
AS350_INSURGENT = shifted(AS350_BODY[:3] + [
    passenger(3, (0.5, 1.55, -0.85), feet_y=1.2, yaw=180, legroom=0.4),
], 0.1, 0.1, 3.7)


VEHICLES = {
    "vehicles/avf/prefabs/humvee/umhummer.xml": HUMVEE,
    "vehicles/avf/prefabs/humvee/umhummeropen.xml": HUMVEE,
    "vehicles/cars/Soviet Vehicles/uaz452.xml": UAZ452,
    "vehicles/cars/Soviet Vehicles/uaz452 Damaged.xml": UAZ452_DAMAGED,
    "vehicles/cars/Soviet Vehicles/uaz452 Modified.xml": UAZ452_MODIFIED,
    "vehicles/cars/Soviet Vehicles/uaz452C_white.xml": UAZ452_WHITE,
    "vehicles/cars/Soviet Vehicles/uaz452_emergency.xml": UAZ452_EMERGENCY,
    "vehicles/cars/GAZ-24 (1968)/gaz24unreleased.xml": GAZ24,
    "vehicles/cars/GAZ-24 (1968)/gaz24unreleased_khb.xml": GAZ24,
    "vehicles/cars/GAZ-24 (1968)/gaz24unreleased_milicia.xml": GAZ24,
    # copies of Teardown 1.x vehicles: official 2.x rigs (voxel overlap 0.6-0.8 after the shift)
    "vehicles/cars/sportscar/sportcar_green.xml": SPORTSCAR,
    "vehicles/cars/sportscar/sportcar_greenDamged.xml": SPORTSCAR,
    "vehicles/cars/sportscar/sportcar_greenOffroad.xml": SPORTSCAR,
    "vehicles/cars/sportscar/RampCar.xml": SPORTSCAR,
    "vehicles/cars/sportscar/sportsoffroad.xml": SPORTSCAR,  # "SportsCar offroad": overlap 0.78, seat rays within 1 voxel
    "vehicles/cars/SUV/suv_yellow.xml": official("generic_blue_light.xml"),
    "vehicles/cars/SUV/suv_yellowdamaged.xml": official("generic_blue_light.xml"),
    "vehicles/cars/saloon/salooncar_red.xml": SALOON,
    "vehicles/cars/saloon/salooncar_red damaged.xml": SALOON,
    "vehicles/cars/saloon/salooncar_taxi.xml": SALOON,
    "vehicles/cars/saloon/salooncar_taxi damaged.xml": SALOON,
    # official 2.x: driver + 1 passenger (box truck, dump truck), driver only (crane, tractor)
    "vehicles/cars/truck/truck_white.xml": BOXTRUCK,
    "vehicles/cars/truck/truck_whitedamaged.xml": BOXTRUCK,
    "vehicles/cars/truck/truck_ramp.xml": BOXTRUCK,
    "vehicles/cars/truck/truck_rampdamaged.xml": BOXTRUCK,
    "vehicles/cars/dumptruck/Dump_truck.xml": official("dumptruck_yellow.xml", shift=(0, 0, 0.1)),
    "vehicles/cars/dumptruck/Dump_truck Damaged.xml": official("dumptruck_yellow.xml", shift=(0, 0, 0.1)),
    "vehicles/cars/Constuction vehicles/mobile_crane.xml": official("crane_medium_yellow.xml"),
    "vehicles/cars/Constuction vehicles/Bluetractor.xml": official("tractor_teal.xml"),
    "vehicles/cars/Constuction vehicles/Redtractor.xml": official("tractor_teal.xml"),
    "vehicles/cars/van1_yellow/Van (Yellow).xml": VAN,
    "vehicles/cars/van1_yellow/Van (Yellow) Damaged.xml": VAN,
    # Van Modified: official driver rig + the PKM gunner on the cargo floor behind the gun, facing out the left side
    "vehicles/cars/van1_yellow/Van Modified.xml": lambda bp: VAN_MODIFIED(bp) + [gunner(1, (0.35, 0.7, 0.25), (0.05, 1.9, 0.25), yaw=90)],
    # station wagon = official generic_stationwagon_blue_dark (overlap 0.68; the yellow one is a different model).
    # Damaged: same seats (its body2 has 2 empty layers on one side; uncropped it looked 0.1 off). Destroyed: wreck.
    "vehicles/cars/minivan1/minivan1.xml": MINIVAN,
    "vehicles/cars/Soviet Vehicles/zil131fire.xml": ZIL_FIRE,
    "vehicles/cars/Soviet Vehicles/ZIL131.xml": ZIL131,
    "vehicles/cars/Soviet Vehicles/ZIL131_ZSU23.xml": ZIL131_ZSU23,
    "vehicles/cars/bus/bus.xml": BUS,
    "vehicles/cars/bus/bus Damaged.xml": BUS,
    "vehicles/cars/bus/bus Modified.xml": BUS_MODIFIED,
    "vehicles/cars/bus/jetbus.xml": JETBUS,
    "vehicles/cars/Soviet Vehicles/paz 3205.xml": PAZ,
    "vehicles/cars/Soviet Vehicles/paz 3205 Damaged.xml": PAZ,
    "vehicles/cars/semitruck-us/Semi.xml": SEMI_US,
    "vehicles/cars/semitruck-us/Semi Damaged.xml": SEMI_US,
    "vehicles/cars/semitruck-us/Semi Modified.xml": SEMI_US,
    "vehicles/cars/semitruck-us/Semi Special.xml": SEMI_US,
    "vehicles/cars/semitruck-flathead/Semi.xml": SEMI_FLATHEAD,
    "vehicles/cars/semitruck-flathead/Semi Damaged.xml": SEMI_FLATHEAD,
    "vehicles/cars/semitruck-flathead/Semi Mod.xml": SEMI_FLATHEAD,
    # "Hummer UM" (spawn menu; humvee.vox, same model as the AVF Humvee, body 0.05 higher: all seat rays identical
    # after the shift). The other vehicles/cars/humvee files point at MOD/vehicles/cars/AvertCars/, which doesn't exist; unused.
    "vehicles/cars/humvee/hummer.xml": shifted(HUMVEE, dy=0.05),
    "vehicles/cars/Gaz24/volgawhite.xml": VOLGA,
    "vehicles/cars/RVMethLab/MethLab.xml": RV_METHLAB,
    "vehicles/cars/1963 VW Beetle BugZilla/BugZilla.xml": BUGZILLA,
    "vehicles/cars/Based Vehicles/golf_cart.xml": GOLF_CART,
    "vehicles/cars/Based Vehicles/golf_cartBomb.xml": GOLF_CART,
    "vehicles/cars/Based Vehicles/smallboat_red.xml": SMALLBOAT,
    "vehicles/cars/Based Vehicles/SHED.xml": SHED,
    "vehicles/cars/Based Vehicles/GARAGE.xml": SHED,
    "vehicles/cars/Based Vehicles/wheeledcockpit.xml": WHEELED_COCKPIT,
    "vehicles/cars/Based Vehicles/sailboat.xml": SAILBOAT,
    "vehicles/cars/military_truck/Milltary_Truck_UM Damaged.xml": MILITARY_TRUCK,
    "vehicles/cars/military_truck/Milltary_Truck.xml": MILITARY_TRUCK,
    "vehicles/cars/military_truck/Milltary_Truck Damaged.xml": MILITARY_TRUCK,
    "vehicles/cars/MadMax2/1973 Ford Falcon XB GT.xml": FALCON,
    "vehicles/cars/MadMax2/1973 Ford Falcon XB GT damaged.xml": FALCON,
    "vehicles/cars/MadMax2/Pursuit Special.xml": PURSUIT_SPECIAL,
    "vehicles/cars/microcar/microcar.xml": MICROCAR,
    "vehicles/cars/microcar/microcarDamged.xml": MICROCAR,
    "vehicles/cars/microcar/monstercompact.xml": MONSTERCOMPACT,
    "vehicles/cars/Constuction vehicles/cement_truck.xml": CEMENT_TRUCK,
    "vehicles/cars/Constuction vehicles/tractorFromHell.xml": TRACTOR_FROM_HELL,
    # Enemy / event vehicles (prefabs/spawnables/enemy vehicles): inline copies of seated models. Players can take
    # them over once the crew is dead (the operator scripts remove the "nodrive" tag). Checked 2026-11-08 with the
    # crew ragdolls hidden: all seat rays identical after the shift (net body + vox position difference).
    "prefabs/spawnables/enemy vehicles/VehicleAAF1.xml": shifted(ZIL131, dx=-0.05, dy=-0.1, dz=-0.1),
    "prefabs/spawnables/enemy vehicles/VehicleC1.xml": shifted(JEEP, dx=0.05, dy=0.1, dz=-0.1),
    "prefabs/spawnables/enemy vehicles/VehicleC2.xml": PAZ,
    "prefabs/spawnables/enemy vehicles/VehicleD8.xml": URAL,
    # VehicleC3 (refugee UAZ event): its body was rebuilt from uaz452.xml on 2026-11-08 (docs/CHANGES.md),
    # placed 0.25 lower and 0.05 back to keep the old cab position: the UAZ layout moved the same way (rays identical).
    "prefabs/spawnables/enemy vehicles/VehicleC3.xml": shifted(UAZ452, dy=-0.25, dz=0.05),
    # Chase / ambush cars (chaseOperator*): copies of the spawn-menu chase cars, the whole car moved inside the
    # <vehicle> (body voxels identical after these shifts, checked 2026-11-09).
    # BMP gunners on the turret basket's left seat (Blender 2026-11-12, mapped to vehicle space through the driver rig;
    # cushion tops / basket floors: BMP-2 1.2 / 0.8 (roof inside 2.2), BMP-1 1.1 / 0.7 (roof 2.0), BMP-1P = BMP-1 with
    # its turret 0.2 lower), facing forward
    "vehicles/avf/prefabs/bmp/BMP-1 d.xml": BMP12 + [gunner_seated((-0.15, -1.28, 0.76), feet_y=-1.68)],
    "vehicles/avf/prefabs/bmp/BMP-1P d.xml": BMP12 + [gunner_seated((-0.15, -1.48, 0.76), feet_y=-1.88)],
    "vehicles/avf/prefabs/bmp/BMP-2 D.xml": BMP12 + [gunner_seated((-0.45, -1.28, 0.96), feet_y=-1.68)],
    # BMP-3: gunner on the turret's left seat (Blender 2026-11-12: cushion top 1.4, floor 1.1, roof inside 2.4; vehicle
    # space through the driver rig), facing forward
    "vehicles/avf/prefabs/bmp/BMP-3 d.xml": BMP3 + [gunner_seated((-0.3, 1.4, 0.1), feet_y=1.1)],
    # Tank gunners (2026-11-13): seated left of the gun breech inside the turret. The turrets are solid shells
    # without modelled seats (Blender, vehicle space via the vehicle's own transform), so: hips 1.1 below the turret
    # roof (head stays inside), feet 0.5 lower, facing forward; the player is hidden, the gun camera is outside.
    # Turret roof / centre z: T-34 2.75 / -0.8; T-54, T-55 2.1 / -0.25 (Desert copies: same model); Sherman ~3.0
    # (cupola 3.7) beside the breech z 0.6; T-72B3 ~2.8 / -0.1. Other T-72 variants: no gunner place (driver fires).
    "vehicles/avf/prefabs/T-34/T-34-85.xml": T34 + [gunner_seated((-0.4, 1.65, -0.8), feet_y=1.15)],
    "vehicles/avf/prefabs/M-51 Super Sherman/M-51 Super Sherman.xml": SHERMAN + [gunner_seated((-0.45, 1.9, 0.6), feet_y=1.4)],
    "vehicles/avf/prefabs/T-54 55/T-54-3 Alashya.xml": T54 + [gunner_seated((-0.45, 1.0, -0.25), feet_y=0.5)],
    "vehicles/avf/prefabs/T-54 55/T-54-3 Desert.xml": T54 + [gunner_seated((-0.45, 1.0, -0.25), feet_y=0.5)],
    "vehicles/avf/prefabs/T-54 55/T-55A Alashya.xml": T55 + [gunner_seated((-0.45, 1.0, -0.25), feet_y=0.5)],
    "vehicles/avf/prefabs/T-54 55/T-55A Desert.xml": T55 + [gunner_seated((-0.45, 1.0, -0.25), feet_y=0.5)],
    **{"vehicles/avf/prefabs/t72_desert/%s.xml" % n: T72 for n in ("T72B", "T72B3_obj_1989", "T72BA")},
    # T-72A (road spawn VehicleM14, mounted gun 2026-11-13): same hull / turret placement as the mod 2016
    "vehicles/avf/prefabs/t72_desert/T72A.xml": T72 + [gunner_seated((-0.5, 1.7, -0.1), feet_y=1.2)],
    "vehicles/avf/prefabs/t72_desert/T72B3_mod_2016.xml": T72 + [gunner_seated((-0.5, 1.7, -0.1), feet_y=1.2)],
    # Humvee .50 cal: gunner standing on the centre console, head out of the roof ring, hands on the gun's rear
    "vehicles/avf/prefabs/humvee/umhummer With 50 Cal.xml": HUMVEE + [gunner(4, (0.0, 1.25, 0.3), (-0.1, 2.7, 0.05))],
    "vehicles/avf/prefabs/Weaponised vehicles/Willys Jeep.xml": WILLYS,
    # inline Willys copies in spawners (Vehiclewg9 plain, VehicleM7 .50 cal, gunner with the mounted-gun work): the same
    # jeep 0.05 left / 0.3 up in vehicle coordinates (body voxels identical after the shift, 2026-11-09)
    "prefabs/spawnables/vehicles/Vehiclewg9.xml": shifted(WILLYS, dx=-0.05, dy=0.3),
    # VehicleM7 = the .50 cal Willys: gunner standing behind the rear bench, hands on the receiver's rear (z 1.3)
    "prefabs/spawnables/vehicles/VehicleM7.xml": shifted(WILLYS, dx=-0.05, dy=0.3) + [gunner(4, (0.0, 0.6, 1.5), (-0.1, 1.65, 1.3))],
    # roadblock3's inline ZIL-131: its path= tag is cut at the space in "Soviet Vehicles"; same placement as ZIL131.xml
    "prefabs/spawnables/roadblocks/roadblock3.xml#ZIL 131": ZIL131,
    "vehicles/avf/prefabs/ZIS-151/ZIS-151.xml": ZIS151,
    "vehicles/avf/prefabs/ZIS-151/ZIS-151 Damaged.xml": ZIS151_DAMAGED,
    "vehicles/avf/prefabs/ZIS-151/ZIS-151_Katyusha.xml": shifted(ZIS151_CAB, dz=0.05),  # first <vehicle> = the truck
    "vehicles/avf/prefabs/technicals/Pickup Truck.xml": PICKUP_TRUCK,
    "vehicles/avf/prefabs/technicals/Pickup Lifted.xml": PICKUP_TRUCK,
    "vehicles/avf/prefabs/technicals/Pickup Damaged.xml": shifted(PICKUP_TRUCK, dx=-0.05, dz=0.1),
    # DShK technical: gunner standing at the rear of the bed behind the gun (grips z ~2.35, height ~2.55)
    "vehicles/avf/prefabs/technicals/technical_DSHK.xml": shifted(PICKUP_TRUCK[:2], dz=0.1) + [gunner(2, (0.05, 1.0, 2.5), (0.05, 2.55, 2.3))],
    # SPG-9 (road spawn VehicleM4; mounted gun 2026-11-13): DShK's mount (+0.06 z), tube z -0.38..3.62 at y 2.13-2.73
    # (its rear overhangs the bed), sight on the left at (-0.21, 2.69, 1.36): the gunner stands left of the tube
    "vehicles/avf/prefabs/technicals/technical_SPG9.xml": shifted(PICKUP_TRUCK[:2], dz=0.1) + [gunner(2, (-0.6, 1.0, 1.7), (-0.45, 2.45, 1.5))],
    # ZU-23-2 technical (not in the spawn menu or road spawns: only dev/levels/test_npc.xml via VehicleM24): gunner on the mount's left bucket seat (Blender 2026-11-12: cushion top y 1.8,
    # x -0.6..-0.3 / z 1.2..1.6 in XML space, backrest at z 1.0-1.1, footrest y 1.7 in front; vehicle pos x 0.1),
    # facing the gun (+z)
    "vehicles/avf/prefabs/technicals/technical_ZU_23.xml": shifted(PICKUP_TRUCK[:2], dx=-0.05, dz=0.1) +
        [gunner_seated((-0.55, 1.8, 1.4), feet_y=1.7, yaw=180)],
    "vehicles/avf/prefabs/technicals/offroad.xml": OFFROAD,
    "vehicles/avf/prefabs/technicals/offroad-open.xml": OFFROAD,
    # GMG offroad (road spawn VehicleM22; mounted gun 2026-11-13): roof turret ring x -0.6..0.5, z -0.18..1.32, top
    # y 2.51, gun pivot (-0.1, 2.51, -0.07), AVF sight (eye) y 3.23: the gunner stands between the rear seats, head
    # and shoulders through the ring, hands on the rear of the launcher
    # (written under the body, whose group is shifted -0.1 in x: +0.1 here puts the place at x -0.05)
    "vehicles/avf/prefabs/technicals/offroad_GMG.xml": OFFROAD + [gunner(4, (0.05, 1.3, 0.75), (0.05, 2.7, 0.45))],
    # WMIK MILAN gunner (2026-11-13, Blender in the vehicle's frame): standing on the weapons bed (floor 0.8) behind
    # the launcher (MILAN_launcher z -0.56..0.94, y 2.32..3.12; turret ring y 2.0-2.4), hands at the firing post's rear
    "vehicles/avf/prefabs/technicals/offroad_WMIK_MILAN.xml": OFFROAD_WMIK + [gunner(3, (-0.15, 0.8, 1.35), (-0.15, 2.35, 1.0))],
    # Kornet / AGS-30 tripods (road segment RoadSegmentL1; user 2026-11-13: "Stand at it"). Measured from the vox files
    # (vehicle frame, node rotations applied; Blender not running): ground y 0.4 (lowest voxel). Kornet: tripod up to
    # y 1.85, launcher tube y 2.65-3.15, z -1.05..1.55 (the model is far taller than the real 9P163): standing behind
    # the rear leg (z <= 0.85) under the tube's rear, hands raised to its underside. AGS-30: tripod up to y 1.25,
    # gun y 1.55-2.05, rear end z 0.75: standing behind it, hands at the rear (chest height). (In-game 2026-11-13 the
    # hands sat right of the tube: MountedGun.lua moved them onto the model's box centre; simple_avf_tank.lua now keeps
    # them as laid, MountedGunKeepGrip.) Both are rebuilt from git and turned into plain objects: EMPLACEMENTS below.
    "prefabs/spawnables/enemy vehicles/VehicleAAF2.xml": OFFROAD,  # same body placement as offroad-open
    "vehicles/cars/BRDM/brdm.xml": BRDM,
    "prefabs/spawnables/enemy vehicles/VehicleD7.xml": BRDM,  # same body placement (voxels identical)
    "vehicles/cars/Enemy Car/Pickup Enemy.xml": PICKUP_ENEMY,
    "vehicles/cars/Enemy Car/SUV Enemy.xml": SUV_ENEMY,
    "vehicles/cars/Enemy Car/Sport Enemy.xml": SPORT_ENEMY,
    **{"prefabs/spawnables/enemy vehicles/Vehicle%s.xml" % k: shifted(PICKUP_ENEMY, dx=0.7, dy=-0.8, dz=1.9)
       for k in ("D2", "D5", "DD3")},
    **{"prefabs/spawnables/enemy vehicles/Vehicle%s.xml" % k: shifted(SUV_ENEMY, dx=0.9, dy=-0.9, dz=2.2)
       for k in ("D3", "D6", "DD1")},
    **{"prefabs/spawnables/enemy vehicles/Vehicle%s.xml" % k: shifted(SPORT_ENEMY, dx=0.5, dy=-0.8, dz=2.4)
       for k in ("D1", "D4", "DD2", "DF1")},
    "vehicles/cars/ural/ural.xml": URAL,
    "vehicles/cars/ural/uraldamaged.xml": URAL,
    "vehicles/cars/Jeep Wrangler/1992 Jeep Wrangler YJ Sahara.xml": JEEP,
    "vehicles/cars/Jeep Wrangler/1992 Jeep Wrangler YJ Sahara Damaged.xml": JEEP,
    "vehicles/cars/Plymouth Fury/Plymouth Fury.xml": PLYMOUTH,
    "vehicles/cars/Plymouth Fury/Plymouth Damaged.xml": PLYMOUTH,
    "vehicles/cars/Plymouth Fury/Plymouth Modified.xml": PLYMOUTH,
    "vehicles/cars/1974 Dodge Moncaco/1974 Dodge Monaco.xml": DODGE_MONACO,
    "vehicles/cars/1974 Dodge Moncaco/1974 Dodge Monaco Damaged.xml": DODGE_MONACO,
    "vehicles/cars/1974 Dodge Moncaco/1974 DM Highway Police.xml": DODGE_MONACO,
    "vehicles/cars/1974 Dodge Moncaco/1974 DM Highway Police Damaged.xml": DODGE_MONACO,
    "vehicles/cars/1969 Mini Cooper S/Mini Cooper.xml": MINI,
    "vehicles/cars/1969 Mini Cooper S/Mini Damaged.xml": MINI,
    "vehicles/cars/1969 Mini Cooper S/Mini Modified.xml": MINI_MODIFIED,
    "vehicles/cars/1963 VW Beetle/1963 VW Beetle.xml": on_body(BEETLE, (0, 0.5, -0.15)),
    "vehicles/cars/1963 VW Beetle/VW Beetle Damaged.xml": on_body(BEETLE, (0, 0.5, -0.15)),
    "vehicles/cars/1963 VW Beetle/VW Beetle Modified.xml": BEETLE_MODIFIED,
    # Cadillacs (no official counterpart). cadillace80 / abandonedeldorado point at .vox files that don't exist and
    # are used nowhere: skipped. Destroyed variants are static wrecks.
    "vehicles/cars/cadillacsd80/cadillacsd80.xml": on_body(CADILLAC_SEDAN, (0, 0.2, -0.15)),
    "vehicles/cars/cadillacsd80/cadillacsd80 Damaged.xml": on_body(CADILLAC_SEDAN, (0, 0.2, -0.15)),
    "vehicles/cars/cadillacsd80/abandonedsedan.xml": CADILLAC_SEDAN_ABANDONED,
    "vehicles/cars/cadillacfbl80/cadillacfbl80.xml": on_body(CADILLAC_LIMO, (0, 0.2, -0.15)),
    "vehicles/cars/cadillacfbl80/cadillacfbl80Damaged.xml": on_body(CADILLAC_LIMO, (0, 0.2, -0.15)),
    "vehicles/cars/cadillacfbl80/abandonedlimousine.xml": CADILLAC_LIMO_ABANDONED,
    "vehicles/cars/stationwagon/station_wagon_brown.xml": official("generic_stationwagon_blue_dark.xml"),
    "vehicles/cars/stationwagon/station_wagon_brown damaged.xml": official("generic_stationwagon_blue_dark.xml"),
    "vehicles/aircraft/AS350/AS350_MILITARY.xml": AS350,
    "vehicles/aircraft/AS350/AS350_CIV.xml": AS350,
    "vehicles/aircraft/AS350/AS350_VIP.xml": AS350,
    "vehicles/aircraft/AS350/AS350_INSURGENT.xml": AS350_INSURGENT,
}


def fmt(v):
    return " ".join(("%g" % round(x, 3)) if x else "0.0" for x in v)


def rig_xml(rigs, indent, nl):
    out = []
    for name, tags, pos, locs, rot in rigs:
        rot_attr = ' rot="%s"' % fmt(rot) if any(rot) else ""
        out.append('%s<rig name="%s" tags="%s" pos="%s"%s>' % (indent, name, tags, fmt(pos), rot_attr))
        for lname, lpos, lrot in locs:
            out.append('%s\t<location name="%s" tags="%s" pos="%s" rot="%s"/>' % (indent, lname, lname, fmt(lpos), fmt(lrot)))
        out.append("%s</rig>" % indent)
    return nl.join(out) + nl


RIG_BLOCK = re.compile(r"[ \t]*<rig\b.*?</rig>[ \t]*\r?\n", re.S)


def patch_text(text, prefab, rigs, embedded, replace=False, vehicle_name=None):
    """Insert rigs into each matching <vehicle>. embedded: look inside <group name="instance=MOD/<prefab>">.
    replace: remove the vehicle's existing <rig> blocks first. vehicle_name: patch the <vehicle name="..."> of this
    file instead of its first one (inline copies with no usable marker; VEHICLES key "file#name")."""
    nl = "\n"  # (2026-11-08) the repo is LF (.gitattributes); old commits read as input may still be CRLF
    starts = []
    if vehicle_name:
        starts = [m.start() for m in re.finditer(r'<vehicle name="%s"' % re.escape(vehicle_name), text)]
        assert len(starts) == 1, (prefab, vehicle_name, len(starts))
    elif embedded:
        for m in re.finditer(r'<group name="instance=MOD/%s"' % re.escape(prefab), text):
            starts.append(m.end())
        # copies marked by a tag instead (roadblock3 / dev/levels/test.xml offroads: <vehicle tags="... path=MOD/<prefab>">)
        for m in re.finditer(r'<vehicle\b[^>]*\btags="[^"]*\bpath=MOD/%s[" ]' % re.escape(prefab), text):
            starts.append(m.start())
        starts.sort()
    else:
        starts.append(0)
    done = 0
    seen = set()
    for start in reversed(starts):  # back to front so earlier offsets stay valid
        v = text.find("<vehicle", start)
        end = text.find("</vehicle>", v)
        if v < 0 or end < 0 or v in seen:  # a copy with both an instance= group and a path= tag
            continue
        seen.add(v)
        if "<rig" in text[v:end]:
            if not replace:
                print("  already has rigs (use --replace to redo)")
                continue
            body = RIG_BLOCK.sub("", text[v:end])
            text = text[:v] + body + text[end:]
            end = v + len(body)
        if callable(rigs):  # official(): needs this vehicle's <body pos>
            bm = re.search(r'<body\b[^>]*?\bpos="([^"]*)"', text[v:end])
            body_pos = tuple(float(x) for x in bm.group(1).split()) if bm else (0.0, 0.0, 0.0)
            vehicle_rigs = rigs(body_pos)
        else:
            vehicle_rigs = rigs
        gun_rigs = [r for r in vehicle_rigs if r[1].startswith("gunner")]
        vehicle_rigs = [r for r in vehicle_rigs if not r[1].startswith("gunner")]
        line_start = text.rfind("\n", 0, v) + 1
        indent = re.match(r"[ \t]*", text[line_start:v]).group(0)
        close_line = text.rfind("\n", 0, end) + 1
        if vehicle_rigs:  # (2026-11-13: a gunner-only layout, the tripods, wrote an empty line here every run)
            text = text[:close_line] + rig_xml(vehicle_rigs, indent + "\t", nl) + text[close_line:]
        if gun_rigs:  # under the vehicle's first <body> (earlier in the text: the offsets above stay valid)
            bm = re.search(r"<body\b[^>]*>", text[v:end])
            assert bm and not bm.group(0).endswith("/>"), prefab
            # a body turned about y (T-34-85: rot "0 180 0", 2026-11-13) is handled: positions and the rig's yaw
            # are taken into the body's frame; other body rotations are not supported
            rm = re.search(r'\brot="([^"]*)"', bm.group(0))
            br = tuple(float(x) for x in rm.group(1).split()) if rm else (0.0, 0.0, 0.0)
            assert br[0] == 0 and br[2] == 0, (prefab, "body rotated about x / z")
            pm = re.search(r'\bpos="([^"]*)"', bm.group(0))
            bp = tuple(float(x) for x in pm.group(1).split()) if pm else (0.0, 0.0, 0.0)
            import math
            a = math.radians(-br[1])  # inverse of the body's yaw
            def to_body(pos):
                x, y, z = (pos[0] - bp[0], pos[1] - bp[1], pos[2] - bp[2])
                return (round(x * math.cos(a) + z * math.sin(a), 3), round(y, 3), round(-x * math.sin(a) + z * math.cos(a), 3))
            moved = [(n, t, to_body(pos), locs, (rot[0], round(((rot[1] - br[1]) + 180) % 360 - 180, 3), rot[2]))
                     for n, t, pos, locs, rot in gun_rigs]
            at = text.find("\n", v + bm.end()) + 1
            text = text[:at] + rig_xml(moved, indent + "\t\t", nl) + text[at:]
        done += 1
    return text, done


# Scripts whose whole content becomes one <vehicle> (2026-11-13): the AS350 was a plain scripted body; seats need a
# vehicle. The <vehicle> has no pos (vehicle space = the script's space) and goes right inside the <script>.
# No car behaviour (user test 2026-11-13: car engine start/drive sounds, gear-shift hand, looking back on S):
# sound="0", topspeed/acceleration 0 (as the v2 MP helicopter of Kooshing's Dynamic Aircraft, Workshop 3729840632,
# shown by the user as a reference), tags player_nogears / player_nosteeringwheel (data/script/player_locomotion.lua).
# The look-back comes from the drive input (GetVehicleDrive < -0.5): Heli.lua holds DriveVehicle at 0 while piloted.
WRAP_VEHICLE = {
    'file="MOD/vehicles/aircraft/AS350/script/Heli.lua"':
        '<vehicle name="AS350" tags="player_nogears player_nosteeringwheel" sound="0" topspeed="0" acceleration="0">',
}


def wrap_text(text):
    """Wrap the content of each WRAP_VEHICLE script element in a <vehicle> (skipped where already wrapped)."""
    done = 0
    for marker, open_tag in WRAP_VEHICLE.items():
        pos = 0
        while True:
            s = text.find(marker, pos)
            if s < 0:
                break
            tag_start = text.rfind("<script", 0, s)
            line_end = text.find("\n", s) + 1
            pos = line_end
            if text[line_end:].lstrip().startswith("<vehicle"):  # wrapped before: bring the tag up to date
                v = text.find("<vehicle", line_end)
                v_end = text.find(">", v) + 1
                if text[v:v_end] != open_tag:
                    text = text[:v] + open_tag + text[v_end:]
                    done += 1
                continue
            depth, i = 1, line_end  # find the matching </script>
            while depth:
                m = re.compile(r"<script\b[^>]*?(/?)>|</script>").search(text, i)
                if m.group(0) == "</script>":
                    depth -= 1
                elif not m.group(1):
                    depth += 1
                i = m.end()
            close = text.rfind("\n", 0, m.start()) + 1
            indent = re.match(r"[ \t]*", text[text.rfind("\n", 0, tag_start) + 1:]).group(0) + "\t"
            text = (text[:line_end] + indent + open_tag + "\n" + text[line_end:close] + indent + "</vehicle>\n"
                    + text[close:])
            done += 1
    return exit_text(text, done)


# Where a player leaving the vehicle is put: <location tags="exit"> in the main body, as official vehicles do
# (combine harvester, gelato truck, boats). AS350 (user test 2026-11-13: getting out put the player on top of the
# rotor): beside the pilot door, ~1 m outside the left skid (body +x), near the ground; clear of the AAF gun (left
# pylon, behind the door) and the Insurgent door gun (ahead of it). Body coordinates, nose at +z.
VEHICLE_EXITS = {
    'file="MOD/vehicles/aircraft/AS350/script/Heli.lua"':
        ('<body name="Heli"', '<location name="exit" tags="exit" pos="1.9 0.4 0.4" rot="0.0 -90.0 0.0"/>'),
}


def exit_text(text, done=0):
    """Put (or update) the exit location as the first child of each listed main body."""
    for marker, (body_start, loc) in VEHICLE_EXITS.items():
        pos = 0
        while True:
            s = text.find(marker, pos)
            if s < 0:
                break
            b = text.find(body_start, s)
            if b < 0:
                break
            line_end = text.find("\n", b) + 1
            pos = line_end
            next_end = text.find("\n", line_end) + 1
            next_line = text[line_end:next_end]
            indent = re.match(r"[ \t]*", text[text.rfind("\n", 0, b) + 1:]).group(0) + "\t"
            if 'tags="exit"' in next_line:
                if next_line.strip() != loc:
                    text = text[:line_end] + indent + loc + "\n" + text[next_end:]
                    done += 1
                continue
            text = text[:line_end] + indent + loc + "\n" + text[line_end:]
            done += 1
    return text, done


# Gun emplacements (2026-11-13, user: only the "Use mounted gun" prompt on the Kornet / AGS-30 tripods). As vehicles
# the game showed its own "Enter vehicle" prompt on every part without an interact tag, at each part's own place
# (hud.lua): the <vehicle> becomes a <group> with the same name / tags / pos / rot, so they are plain objects and
# vehicles/MountedGun.lua uses the chassis body instead of a vehicle. Rebuilt from git each run (gunner place
# inserted while it is still a vehicle, then converted).
EMPLACEMENT_BASE = "cfa00f1"  # "phase 4": both files as in the original mod (normalized to LF)
EMPLACEMENTS = {
    "vehicles/avf/prefabs/turrets/Kornet.xml": [gunner(1, (-0.05, 0.4, 1.25), (-0.05, 2.6, 0.8))],
    "vehicles/avf/prefabs/turrets/ags30.xml": [gunner(1, (-0.05, 0.4, 1.2), (-0.05, 1.85, 0.7))],
}


def emplacement_text(text, prefab, rigs):
    text, n = patch_text(text, prefab, rigs, embedded=False)
    assert n == 1, prefab
    m = re.search(r"<vehicle\b([^>]*)>", text)
    keep = []
    for attr in ("name", "tags", "pos", "rot"):
        a = re.search(r'\b%s="([^"]*)"' % attr, m.group(1))
        if a:
            keep.append('%s="%s"' % (attr, a.group(1)))
    text = text[:m.start()] + "<group %s>" % " ".join(keep) + text[m.end():]
    assert text.count("</vehicle>") == 1, prefab
    return text.replace("</vehicle>", "</group>")


def main():
    dry = "--dry-run" in sys.argv
    replace = "--replace" in sys.argv
    import subprocess
    for prefab, rigs in EMPLACEMENTS.items():
        src = subprocess.run(["git", "show", EMPLACEMENT_BASE + ":" + prefab], cwd=REPO, capture_output=True,
                             check=True).stdout.decode("latin-1").replace("\r\n", "\n")
        print("emplacement (plain object, gunner place):", prefab)
        if not dry:
            open(os.path.join(REPO, prefab), "wb").write(emplacement_text(src, prefab, rigs).encode("latin-1"))
    xmls = []
    for root, dirs, files in os.walk(REPO):
        dirs[:] = [d for d in dirs if d not in (".git", "unused")]
        xmls += [os.path.join(root, f) for f in files if f.endswith(".xml")]
    for path in xmls:
        data = open(path, "rb").read().decode("latin-1")
        if not any(k in data for k in WRAP_VEHICLE):
            continue
        new, n = wrap_text(data.replace("\r\n", "\n"))
        if n:
            print("wrapped %d script(s) in a <vehicle>: %s" % (n, os.path.relpath(path, REPO)))
            if not dry:
                open(path, "wb").write(new.encode("latin-1"))
    for prefab, rigs in VEHICLES.items():
        print(prefab)
        if "#" in prefab:  # one named <vehicle> of one file
            relpath, name = prefab.split("#", 1)
            path = os.path.join(REPO, relpath)
            data = open(path, "rb").read().decode("latin-1").replace("\r\n", "\n")
            new, n = patch_text(data, relpath, rigs, embedded=False, replace=replace, vehicle_name=name)
            print("  %-60s %d vehicle(s) patched" % (relpath, n))
            if n and not dry:
                open(path, "wb").write(new.encode("latin-1"))
            continue
        for path in xmls:
            relpath = os.path.relpath(path, REPO).replace("\\", "/")
            data = open(path, "rb").read().decode("latin-1").replace("\r\n", "\n")
            own = relpath == prefab
            if not own and ('name="instance=MOD/%s"' % prefab) not in data and ("path=MOD/%s" % prefab) not in data:
                continue
            new, n = patch_text(data, prefab, rigs, embedded=not own, replace=replace)
            print("  %-60s %d vehicle(s) patched" % (relpath, n))
            if n and not dry:
                open(path, "wb").write(new.encode("latin-1"))


if __name__ == "__main__":
    main()

# Mors Longa Revival — guns

Part of the technical reference (index and conventions: [TECHNICAL_REFERENCE.md](TECHNICAL_REFERENCE.md)).
Marks: **[verified in-game]**, **[official source]**, **[unverified]**.

## Tool prefab layout [official source: minigun, Tripmine, C4]
```xml
<prefab version="2.0.0">
  <group name="instance=MOD/prefab/mytool.xml">
    <group name="eye_space"> <!-- optional ToolAnimator poses: fp_action, tp_action, tp_run, ... --> </group>
    <group name="tool_space">
      <body dynamic="false">
        <vox file="MOD/assets/vox/mytool.vox" scale="0.4"/>   <!-- one <vox> per shape, in index order -->
      </body>
      <location name="muzzle" tags="name=muzzle" pos="..."/>
      <location name="tp_action_rh" tags="name=tp_action_rh ik_hand" pos="..." rot="..."/>
    </group>
  </group>
</prefab>
```
* `RegisterTool(id, name, file, [group])` on the server; tools start disabled: `SetToolEnabled(id, true, p)` per
  player (`PlayersAdded()`). The engine builds the tool body on every machine; a client may animate those shapes
  (`GetToolBody`, `GetBodyShapes`, `SetShapeLocalTransform`); shape order = `<vox>` order; re-read when the body
  changes. Viewmodel: `SetToolTransform` (client).

## How Mors Longa guns work (v1, kept in v2)
* 38 gun scripts in `script/` (2-3.7k lines, ~95% one template): own `FireRound(Type)` (was `Shoot`), `Reload`,
  `ShootGrenade`, huge tick (controls + viewmodel by part index) and draw (HUD, attachment/mag UI).
  Shared: `gunfunctions.lua` (projectile sim, grenades, ADS, LoadTool, `checkUnlimitedBulletsValid`),
  `gunperks.lua` (ammo stats per calibre/type, `GunPerkFor`), `gunstats.lua`.
* Inventory ↔ gun via registry: `inventory.guns.<n>.item` = `_`-joined: `[1]` tool id, `[3]` mag id, `[4]` mag name,
  `[5]` ammo, `[6]` max, `[7]` display calibre, `[8]` attachments, `[10]` per-round bullet types `-`-joined; plus
  `inventory.curprimary`, `inventory.update_guns<n>`. The inventory fills missing bullet types with
  `GunDefaultBulletType` on pickup.

## v2 gun design (current)
* All gun logic runs on the holding player's client as in v1 (client-trusted). Projectiles are simulated twice by
  `ProjectileOperations`/`GrenadeOperations`: the server for world effects (`doWorld`), every client for visuals
  (`doFx`). `weapons/guns/gunnet.lua` carries shots, melee holes, casings, the shooter id (`projectile.owner` →
  `level.goreai.body_damage_player_owner`).
* Gun scripts are **static** level scripts (group `GunScripts` in the level xmls; v1 spawned them per equip);
  each checks `GunInInventory(id)` before acting.
* Two model kinds: **vox guns** (27, multi-object `.vox`, engine-built) and **LoadTool guns** (AK74, FiveSeven,
  G17, G18 [G17 model], M107, M4A1 [M4 model], M870, MP5, TT33): registered with a generated
  `weapons/guns/Weapons/<GUN> Tool.xml` (`tools/porting/make_tool_prefab.py`):
  * parts in **reverse** Base.xml order (v1 index i = i-th part from the end: GetBodyShapes lists the last attached
    first);
  * each part built in its own lane (24 m grid, 10 columns) because **overlapping parts lose voxels** in an
    engine-built tool [verified in-game]; `GunNet_FixToolParts()` moves them back on the client (per part, only while
    `|x - lane_x| < 12`);
  * parts tagged `ml_toolpart unbreakable`, skipped by `GunRaycast`; Base.xml parts without `file=` get the
    wrapper's vox filled in.
  * Camo variants are generated but not registered (known gap).
* Third person (other players, or the holder in third person; 2026-11-15): the tool is hidden and a local copy at
  0.4 scale is posed in the character's hands (`gunnet.lua` "Third-person guns", `Gun3P_*`; [CHANGES](CHANGES.md)).
  Tuning: `GUN3P_SCALE`, `GUN3P_HAND` (right hand in the override frame), `GUN3P_HAND_R` / `_L` (hand rotations).
* Debug overlay (any v2 gun): **Ctrl+O** part index labels, **Ctrl+L** part table (local pos, voxel size, rot).
  Offline render: `tools/porting/render_gun.py`.
* RPG-7: hand-converted `weapons/guns/RPG.lua`; the rocket (`weapons/guns/grenade.lua`) is spawned by the server ([SYSTEMS](SYSTEMS.md) "Other converted systems").
* Scope look tweak (`SetPlayerTransform(ppos2, true)` in some rifles) disabled; TODO via `SetToolAllowedZoom`.
* Original quirks kept as-is: PKM's own projectile sim has no NPC damage; FiveSeven hand indices 18-29 exceed its 26
  parts; Jalaad init matches `ak-762x54` mags but its tick `m107-127x99`; no MC9 mag #3 item exists.

## Gun scripts → in-game names (HUD shows the RegisterTool name)

| Script | Tool id | Name | Model | | Script | Tool id | Name | Model |
|---|---|---|---|---|---|---|---|---|
| AK101 | gun-ak101 | Simonov-556 | vox | | MP43 | gun-mp43 | Mudafie | vox |
| AK50 | gun-ak50 | Jalaad | vox | | MP5 | gun-mp5 | MC9 | LoadTool |
| AK74 | gun-ak74 | Simonov-545 | LoadTool | | MosinNagant | gun-mosin | Medvedev | vox |
| AK74M | gun-ak74m | Simonov-106 | vox | | MosinNagantM | gun-mosinm | Medvedev Military | vox |
| AKM | gun-akm | Simonov-762 | vox | | P90 | gun-p90 | TMP-90 | vox |
| CZ-1012 | gun-cz1012 | CZ-1012 | vox | | PKM | gun-pkm | PKM (shelved) | vox |
| Dessert Eagle | gun-deagle | Deagle | vox | | PP19 | gun-pp19 | Simonov-9 | vox |
| FiveSeven | gun-fiveseven | TCP-57 | LoadTool | | PPSh | gun-ppsh41 | PPSh-41 | vox |
| G17 | gun-g17 | P17 | LoadTool | | RPG | gun-rpg | RPG-7 | vox |
| G18 | gun-g18 | P17A | LoadTool | | SCAR-H / -Hg | gun-scarh / -hg | TCR-308 | vox |
| G3 | gun-g3 | MC308 | vox | | SCAR-L / -Lg | gun-scarl / -lg | TCR-556 | vox |
| G36 | gun-g36k | MK36 | vox | | SG553 | gun-sg553 | Bauer-553 (shelved) | vox |
| KS23 | gun-ks23 | KS23 | vox | | SKS | gun-sks | SKS | vox |
| M107 | gun-m107 | N107 | LoadTool | | SV98 | gun-sv98 | SV-98 | vox |
| M16 | gun-m16 | N16 | vox | | SVD | gun-svd | Drozdov | vox |
| M4A1 | gun-ar15 | N4A1 | LoadTool | | Sawed Off | gun-sawedoff | Qasira | vox |
| M870 | gun-m870 | N870 | LoadTool | | TT33 | gun-tt33 | TT-33 | LoadTool |
| M9 | gun-m9 | M9 (shelved) | vox | | VECTOR | gun-vector | SCALAR | vox |

Melee (8, `weapons/melee/`, `convert_melee.py`): client = input/animation/raycasts/fx; world effects
queued in `Melee_Functions.lua` and sent once per frame to `server.meleeOps(ops, playerId)`, which forwards the
swing start and landing to the other clients (`client.meleeRemoteOps`: sounds, particles, swing); every machine
poses the other players' melee weapons itself (`MeleeNet_RemoteTick`, 2026-11-15).

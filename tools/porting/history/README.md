# Converters (history, frozen 2026-11-14)

These scripts converted the v1 mod to Teardown 2.x during Phases 1-4. They are **no longer run**: the files they
produced are now ordinary source and are edited directly. They are kept as a record of what was changed and why
(each edit is asserted and commented in the converter), next to `git log -p` on the converted files.

* Rebuild converters regenerated their files from a git base on every run: `convert_goreai.py`,
  `convert_operators.py`, `convert_menu.py`, `convert_horde.py` (base 6c28435), `port_immersive.py` (base 9dde6dd),
  `port_avf.py` (base `avf_base/`), `heli_variants.py`. Running one now would overwrite every hand edit made since
  the freeze: don't.
* In-place converters converted a v1 file once: `convert_gun.py`, `convert_melee.py`, `convert_server.py`,
  `convert_props.py`, `convert_shop.py`; `convert_steering.py` (idempotent) and `gunfunctions.py` (history only).
* They compute the repo root from their old folder (`tools/porting/patches/`), so their paths are off by one level
  here.

`avf_base/` is AVF V-3.0.2's own code (Armed Vehicles Framework by elboydo, Workshop 2400346027), the source the
shell port in `scripts/avf/AVF_Shells.lua` and `avf/scripts/Immersive_Tank.lua` was made from; its `README.md`
holds the credit.

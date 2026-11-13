#version 2
-- (v2) Stand-in for script files that never existed (inherited from the original mod). Prefabs pointed at missing
-- scripts; three engine crashes happened 0-1 s after "Script not found" while such prefabs spawned (2026-11-07).
-- References are repointed here by tools/porting/fix_missing_scripts.py. Intentionally does nothing.

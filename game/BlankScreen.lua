-- (2026-11-17) A screen script that draws nothing. The gas station's and two buildings' monitors pointed at
-- MOD/script/infoscreen.lua, which never existed (original mod, 9dde6dd); the port removed the dead path, and a
-- <screen> without a script logs "Script not found: data" each time one spawns (found with the MCP bridge: spawning the
-- shop's gas station alone gave it twice, one per screen). Screen scripts run as v1 (docs/ENGINE.md), so no #version.
function draw()
end

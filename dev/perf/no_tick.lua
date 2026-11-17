#version 2
-- (2026-11-17, DEBUG perf test) a script with no callbacks after init: compared with empty_tick.lua.
function server.init() end
function client.init() end

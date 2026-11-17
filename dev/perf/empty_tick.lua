#version 2
-- (2026-11-17, DEBUG perf test) a script with empty tick callbacks on both halves: the engine's fixed cost of
-- calling a script, measured with 50 copies (docs/PERFORMANCE.md "Many small scripts").
function server.tick(dt) end
function client.tick(dt) end

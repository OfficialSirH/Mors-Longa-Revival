-- (2026-11-17, performance) A finished spawned script has its own script entity removed (SERVER only: a client may
-- not delete server-authored entities). v1 found its handle with a pause-menu button trick (masterScriptRemoverAPI),
-- which does not work on the v2 server, so finished scripts stayed loaded and kept being called every frame for the
-- rest of the run (long run 2026-11-17: 114 -> 171 scripts in 3 km, 38 goreai_initializer instances, ~34 MB of Lua
-- memory). GetScriptId() (undocumented in script_defs.lua, checked in game: returns this script's entity handle)
-- gives the handle.
-- The script must NOT delete itself: Delete(GetScriptId()) inside its own tick crashed the game (2026-11-17, crash in
-- a lock on a worker thread right after 11 npcs died). The handle is queued instead and the level script
-- lib/masterScriptRemover.lua deletes it in its own tick (deleting another script's entity was safe: 31 robot
-- scripts removed from the bridge). Deleting a script entity leaves the bodies it spawned in place (checked with the
-- robots), so corpses / vehicles stay until RemoveRoad clears them.
function ScriptSelfDelete()
	if not GetScriptId or ScriptSelfDeleted then return end
	local id = GetScriptId()
	if not id or id == 0 then return end
	ScriptSelfDeleted = true
	local n = GetInt("level.script_remover.queue.count") + 1
	SetInt("level.script_remover.queue." .. n, id)
	-- (2026-11-20) crash breadcrumb: who asked (lib/masterScriptRemover.lua logs it with lib/DeleteLog.lua)
	SetString("level.script_remover.queue." .. n .. ".label", DL_LABEL or GCP_LABEL or SSD_LABEL or "script")
	SetInt("level.script_remover.queue.count", n)
end

-- (2026-11-17, performance research, DEBUG; no effect unless the keys below are set) Garbage collector probe for any
-- script that includes this file BEFORE it defines its tick functions: server.tick / client.tick are wrapped when
-- the script assigns them (metatable on the server / client tables), and once a second the wrapper:
--   * applies level.debug.gc_pause (int, 0 = Lua's default 200) as this Lua state's collector pause;
--   * while level.debug.gc_probe is set: stops the collector every other second and writes the allocation rate and
--     the live heap of this Lua state to level.debug.gc.<label>.<side><id> = "<kB/s> <live kB>" (label: GCP_LABEL, set
--     by the includer before the #include, default "script").
-- Each script half is its own Lua state with its own collector; the sum over all keys is the mod's script garbage.
-- Found with goreai_main (docs/PERFORMANCE.md "NPC manager garbage"): many small tables per frame + a small live
-- heap = many full collector cycles per second.

if not GcProbeInstalled and collectgarbage then
	GcProbeInstalled = true
	local id = tostring(math.random(100000, 999999))
	local P = { next = 0, pause = 0 }

	local function probe(side)
		local now = GetTime()
		if now < P.next then return end
		P.next = now + 1
		local pause = GetInt("level.debug.gc_pause")
		if pause ~= P.pause then
			P.pause = pause
			collectgarbage("setpause", pause > 0 and pause or 200)
		end
		local on = GetBool("level.debug.gc_probe")
		if P.stopped then
			local kb = collectgarbage("count") - P.start
			collectgarbage("restart")
			P.stopped = false
			SetString("level.debug.gc." .. (GCP_LABEL or "script") .. "." .. side .. id,
				string.format("%.0f %.0f", kb / math.max(0.001, now - P.t0), P.start))
		elseif on then
			collectgarbage("collect")
			collectgarbage("stop")
			P.stopped, P.start, P.t0 = true, collectgarbage("count"), now
		end
	end

	-- level.debug.skip_scripts (debug, read once a second): a list of labels ("gun,melee"); scripts with a listed label
	-- skip all their per-frame callbacks (to measure their total cost in the profiler; breaks them while set)
	local CALLBACKS = { tick = true, update = true, render = true, draw = true, postUpdate = true }
	local function skipped()
		local now = GetTime()
		if now >= (P.skipAt or 0) then
			P.skipAt = now + 1
			GcProbeOld = GetBool("level.debug.gun_old") -- (debug) gunfunctions.lua: the 2026-11-16 idle path, for A/B
			local list = GetString("level.debug.skip_scripts")
			P.skip = list ~= "" and string.find("," .. list .. ",", "," .. (GCP_LABEL or "script") .. ",", 1, true) ~= nil
		end
		return P.skip
	end

	local function hook(tbl, side)
		if type(tbl) ~= "table" or getmetatable(tbl) then return end
		setmetatable(tbl, { __newindex = function(t, k, v)
			if CALLBACKS[k] and type(v) == "function" then
				local f = v
				if k == "tick" then
					v = function(...) probe(side) if skipped() then return end return f(...) end
				else
					v = function(...) if P.skip then return end return f(...) end
				end
			end
			rawset(t, k, v)
		end })
	end
	hook(server, "s")
	hook(client, "c")
end

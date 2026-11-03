function get_npc_api_nav_table()

    local t = {

        state               = { "string", "done" },
        hasNewTarget        = { "boolean", false },
        resultRetrieved     = { "boolean", true },
        deviation           = { "number", 0},
        blocked             = { "number", 0},
        unblockTimer        = { "number", 0},
        unblock             = { "number", 0},
        vertical            = { "number", 0},
        thinkTime           = { "number", 0},
        timeout             = { "number", 6},
        lastQueryTime       = { "number", 0},
        timeSinceProgress   = { "number", 0},
        pathType            = { "string", "standard" },
        lastNavigationTime  = { "number", 0},

        targetRadius        = { "number", 1 },
        pathSpacing         = { "number", 1.5 },
        minDistToPath       = { "number", 6 },
        PATH_NODE_TOLERANCE = { "number", 1.5 / 2 },

        -- Output
        GetPathState    = { "string", "done" },
        GetPathLength   = { "number", 0 },
        newPath         = { "boolean", false },

        -- Controls
        input_AbortPath        = { "boolean", false },
        input_clear_navigation = { "boolean", false },

    }

    return t

end

---
---@param path string
---@param table table
function setRegTable(path, table)
    SetString(path, util.serialize(table))
end

---
---@param path string
---@return table table
function getRegTable(path)
    return util.unserialize(GetString(path))
end
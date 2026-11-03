function create_node(key)
    local n = {}
    n.key = key
    n.value = GetString(key)
    n.non_empty_value = n.value
    n.read_time = GetTime()
    n.parent_node = false
    n.children = {}

    return n
end

function resolve_node(key)
    local path = AutoSplit(key, '.')
    local last_step = false
    local step = REGISTRY

    for i, child in ipairs(path) do
        local stepped_key = AutoKey(unpack(path, 1, i))
        local next_step = step.children[child]

        if next_step then
            last_step, step = step, next_step
        else
            local new = create_node(stepped_key)
            new.parent_node = step
            step.children[child] = new
            last_step, step = step, new
        end
    end

    return step, last_step
end

function scan(node, depth)
    node.value = GetString(node.key)
    node.non_empty_value = node.value ~= '' and node.value or node.non_empty_value
    node.read_time = GetTime()

    if depth > 0 then
        for _, child in pairs(ListKeys(node.key)) do
            local formatted = AutoKey(node.key, child)
            local child_node = resolve_node(formatted)

            node.children[child] = child_node
            scan(child_node, depth - 1)
        end
    end
end

function keys_with_prefix(t, prefix)
    local result = {}

    for key, _ in pairs(t) do
        if string.find(key, prefix, 1, true) == 1 then
            table.insert(result, key)
        end
    end

    return result
end

function end_of_key(key)
    return key:sub(key:find("[^.]*$"))
end

---@param list table
---@return table
---@return integer count
function sorted_indexes(list)
    local sorted = {}
    for k in pairs(list) do
        sorted[#sorted + 1] = k
    end

    table.sort(sorted)

    return sorted, #sorted
end

--------------------------------------------------------------------------------------------------------------------------------

local style = {
    window_padding = 4,
    inner_padding = 8,
    indent = 32,
    font_size = 22,
    color_keys = {
        border = 'overlay0',
        key = {
            fresh = {
                bg = 'base',
                fg = 'text'
            },
            stale = {
                bg = 'red',
                fg = 'base'
            },
        },
        value = {
            fresh = {
                bg = 'surface0',
                fg = 'text'
            },
            stale = {
                bg = 'maroon',
                fg = 'base'
            },
        },
        depth = {
            bg = 'peach',
            fg = 'base'
        }
    }
}

---@param key string
---@return integer height
function tree(key)
    local node, parent_node = resolve_node(key)
    if not node then return 0 end
    
    local height = 0
    
    local color = GetTime() == node.read_time and 'fresh' or 'stale'

    local key_end = end_of_key(key)
    local tb_data = util_textbox(key_end, style.color_keys.key[color].bg, style.color_keys.key[color].fg)
    height = height + tb_data.size[2]

    if tb_data.lmb then
        local current = WATCHING[node.key]
        WATCHING[node.key] = (current or 0) + 1

    elseif tb_data.rmb then
        local current = WATCHING[node.key]
        
        if current then
            WATCHING[node.key] = math.max(0, current - 1)
            
            if current == 1 then
                if AutoTableContains(Base_Keys, node.key) then
                    for ck, _ in pairs(node.children) do
                        node.children[ck] = nil
                    end
                else
                    for _, k in pairs(keys_with_prefix(WATCHING, node.key)) do
                        WATCHING[k] = nil
                        node.parent_node.children[key_end] = nil
                    end

                    return height
                end
            end
        end
    end
    
    UiPush()
    UiTranslate(tb_data.size[1])
    
    local watched = WATCHING[node.key]
    if watched then
        UiTranslate(util_textbox(watched, style.color_keys.depth.bg, style.color_keys.depth.fg, style.font_size).size[1])
    end

    UiTranslate(style.window_padding)

    if node.value ~= '' then
        UiTranslate(util_textbox(node.value, style.color_keys.value[color].bg, style.color_keys.value[color].fg).size[1] + style.window_padding)
    elseif node.non_empty_value ~= '' then
        UiTranslate(util_textbox(node.non_empty_value, style.color_keys.value.stale.bg, style.color_keys.value.stale.fg).size[1] + style.window_padding)
    end
    

    UiPop()

    if node.children and next(node.children) then
        local sorted, count = sorted_indexes(node.children)

        UiPush()

        UiTranslate(style.indent)
        height = height + style.window_padding

        for i, k in pairs(sorted) do
            UiPush()

            UiTranslate(0, height)

            height = height + tree(node.children[k].key)
            if i < count then height = height + style.window_padding end

            UiPop()
        end

        UiPop()
    end
    
    return height
end

function util_textbox(text, window_color, text_color, font_size)
    UiFont('bold.ttf', font_size or style.font_size)
    
    local text_size = { UiGetTextSize(text) }
    local font_height = UiFontHeight()
    local padding = style.inner_padding
    local rect_size = { text_size[1] + padding, font_height + padding }
    
    UiPush()

    UiWindow(unpack(rect_size))
    local bounds = {AutoUiBounds()}
    local hover = UiIsMouseInRect(bounds[1], bounds[2])
    local lmb = hover and InputPressed('usetool')
    local rmb = hover and InputPressed('grab')

    UiColor(unpack(AutoPalette.catppuccin[window_color]))
    UiRect(bounds[1], bounds[2])

    UiColor(1, 1, 1, 0.8)
    UiImageBox('../assets/bevel.png', bounds[1], bounds[2], 12, 12)

    UiTranslate(UiCenter(), UiMiddle() + font_height / 4)
    UiAlign('center')
    UiColor(unpack(AutoPalette.catppuccin[text_color]))
    UiText(text)
    
    UiPop()

    return { size = rect_size, hover = hover, lmb = lmb, rmb = rmb }
end
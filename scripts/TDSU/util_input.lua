keyTitles = {
    leftarrow   = 'left',
    rightarrow  = 'right',
    uparrow     = 'up',
    downarrow   = 'down',
}

validKeys = {
    'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z',
    '1', '2', '3', '4', '5', '6', '7', '8', '9', '0',
    'f1', 'f2', 'f3', 'f4', 'f5', 'f6', 'f7', 'f8', 'f9', 'f10', 'f11', 'f12',
    'tab', 'uparrow', 'downarrow', 'leftarrow', 'rightarrow',
    'backspace', 'alt', 'delete', 'home', 'end',
    'pgup', 'pgdown', 'insert', 'space', 'shift', 'ctrl', 'return', 'rmb', 'mmb',
}

validChars = {
    'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z',
    '1', '2', '3', '4', '5', '6', '7', '8', '9', '0',
    'space',
}

comboKeys = {'-', 'ctrl', 'shift', 'alt'}


--- Convert a input string to the appropriate display string.
function convertKeyTitle(str)
    for key, value in pairs(keyTitles) do
        if key == str then
            return value
        end
    end
    return str
end

--- Check if a string is a valid keyboard input.
function isKeyValid(str)
    for index, value in ipairs(validKeys) do
        if str == value then
            return true
        end
    end
    return false
end

--- Check if a string is a valid text input.
function isCharValid(str)
    for index, value in ipairs(validChars) do
        if str == value then
            return true
        end
    end
    return false
end

-- Manages user input.
function ManageInput()

    -- if InputDown(KEYS.pinPanel.key1) and InputPressed(KEYS.pinPanel.key2) then
    --     togglePinControlPanel()
    -- end

    if not shouldDisableControlPanel() then

        for i = 1, #UiControls do

            local control = UiControls[i]

            local noComboKey = KEYS[control.name].key1 == '-'


            if noComboKey then

                if InputPressed(KEYS[control.name].key2) then
                    _G[control.func]()
                end

            else

                if InputDown(KEYS[control.name].key1) and InputPressed(KEYS[control.name].key2) then
                    _G[control.func]()
                end

            end

        end

    end

    -- if InputPressed('rmb') and isUsingTool then
    --     UI_SHOW_OPTIONS = not UI_SHOW_OPTIONS
    -- end

end


LogInputs = {
    up = "up", ---Move forward / Accelerate
    down = "down", ---Move backward / Brake
    left = "left", ---Move left
    right = "right", ---Move right
    interact = "interact", ---Interact
    flashlight = "flashlight", ---Flashlight
    jump = "jump", ---Jump
    crouch = "crouch", ---Crouch
    usetool = "usetool", ---Use tool
    grab = "grab", ---Grab
    handbrake = "handbrake", ---Handbrake
    map = "map", ---Map
    pause = "pause", ---Pause game (escape)
    vehicleraise = "vehicleraise", ---Raise vehicle parts
    vehiclelower = "vehiclelower", ---Lower vehicle parts
    vehicleaction = "vehicleaction", ---Vehicle action
    camerax = "camerax", ---Camera x movement, scaled by sensitivity. Only valid in InputValue.
    cameray = "cameray", ---Camera y movement, scaled by sensitivity. Only valid in InputValue.
    tool_group_prev = "tool_group_prev", ---Switch to previous tool group
    tool_group_next = "tool_group_next", ---Switch to next tool group
    extra0 = "extra0", ---Extra action 0
    extra1 = "extra1", ---Extra action 1
    extra2 = "extra2", ---Extra action 2
    extra3 = "extra3", ---Extra action 3
    extra4 = "extra4", ---Extra action 4
    extra5 = "extra5", ---Extra action 5
    extra6 = "extra6", ---Extra action 6
    photomode = "photomode", ---Photomode
    zoom = "zoom", ---Zoom
    menu_left = "menu_left", ---Menu left
    menu_right = "menu_right", ---Menu right
    menu_up = "menu_up", ---Menu up
    menu_down = "menu_down", ---Menu down
    menu_next = "menu_next", ---Menu next
    menu_prev = "menu_prev", ---Menu prev
    menu_accept = "menu_accept", ---Menu accept
    menu_cancel = "menu_cancel", ---Menu cancel
}

KeyInputs = {

    _az = { ---Latin, alphabetical keys a through z
        a = 'a',
        b = 'b',
        c = 'c',
        d = 'd',
        e = 'e',
        f = 'f',
        g = 'g',
        h = 'h',
        i = 'i',
        j = 'j',
        k = 'k',
        l = 'l',
        m = 'm',
        n = 'n',
        o = 'o',
        p = 'p',
        q = 'q',
        r = 'r',
        s = 's',
        t = 't',
        u = 'u',
        v = 'v',
        w = 'w',
        x = 'x',
        y = 'y',
        z = 'z',
    },
    _num = { ---Digits, zero to nine
        ["1"] = '1',
        ["2"] = '2',
        ["3"] = '3',
        ["4"] = '4',
        ["5"] = '5',
        ["6"] = '6',
        ["7"] = '7',
        ["8"] = '8',
        ["9"] = '9',
        ["0"] = '0'
    },
    _f = {
        f1 = "f1",          ---Function keys
        f2 = "f2",
        f3 = "f3",
        f4 = "f4",
        f5 = "f5",
        f6 = "f6",
        f7 = "f7",
        f8 = "f8",
        f9 = "f9",
        f10 = "f10",
        f11 = "f11",
        f12 = "f12",
    },

    esc = "esc",         ---Escape key
    tab = "tab",         ---Tab key
    lmb = "lmb",         ---Left mouse button
    rmb = "rmb",         ---Right mouse button
    mmb = "mmb",         ---Middle mouse button

    uparrow = "uparrow",     ---Up arrow key
    downarrow = "downarrow",   ---Down arrow key
    leftarrow = "leftarrow",   ---Left arrow key
    rightarrow = "rightarrow",  ---Right arrow key

    backspace = "backspace", ---Backspace key
    alt = "alt",             ---Alt key
    delete = "delete",       ---Delete key

    home = "home",           ---Home key
    end_ = "end",            ---End key
    pgup = "pgup",           ---Pgup key
    pgdown = "pgdown",       ---Pgdown key
    insert = "insert",       ---Insert key
    space = "space",         ---Space bar
    shift = "shift",         ---Shift key
    ctrl = "ctrl",           ---Ctrl key
    return_ = "return",      ---Return key
    any = "any",             ---Any key or button
}

InputValues = {
    mousedx = "mousedx",        ---Mouse horizontal diff. Only valid in InputValue.
    mousedy = "mousedy",	    ---Mouse vertical diff. Only valid in InputValue.
    mousewheel = "mousewheel",  ---Mouse wheel. Only valid in InputValue.
}


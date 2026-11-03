function tick_dev_shortcuts()
    tick_profiler()
end

function draw_dev_shortcuts()
    if UiInteractive then UiMakeInteractive() end
end

function tick_profiler()
    UiInteractive = UiInteractive or false
    if InputDown("alt") and InputDown("shift") and InputPressed("f3") then
        UiInteractive = true
    elseif InputPressed("f3") then
        UiInteractive = false
    end
end

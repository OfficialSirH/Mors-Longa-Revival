function init()
    file = GetStringParam('file','')    
end

function tick(dt)
    if InputPressed('l')then
        Spawn(file,Transform(),true,true)
    end
end
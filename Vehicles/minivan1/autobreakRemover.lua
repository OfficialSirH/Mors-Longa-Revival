function init()
    bodies=FindBodies()
end
function tick(dt)
    for _,body in pairs(bodies)do
        RemoveTag(body,'autobreak')
    end
end
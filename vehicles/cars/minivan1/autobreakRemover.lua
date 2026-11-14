#version 2
-- (v2) server: removes the "autobreak" tag from the minivan's bodies (world state; v1 init/tick unchanged otherwise)
function server.init()
    bodies=FindBodies()
end
function server.tick(dt)
    for _,body in pairs(bodies)do
        RemoveTag(body,'autobreak')
    end
end

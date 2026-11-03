function ReadRagdollPose()
    PrintRagdollPose()
end

RagdollPoses = {
    sit = {
        Torso    =      Transform(Vec(0, -0.69999998807907, 0), Quat(0, 0, 0, 1)),
        Head     =      Transform(Vec(0, 0, 0), Quat(0, 0, 0, 1)),
        LARM     =      Transform(Vec(-0.25, -0.10000002384186, 0), Quat(0.4161581993103, -0.31020647287369, -0.07309290766716, 0.85161119699478)),
        LLARM    =      Transform(Vec(-0.2895770072937, -0.2546135187149, -0.27299878001213), Quat(0.4161581993103, -0.31020647287369, -0.07309290766716, 0.85161119699478)),
        RARM     =      Transform(Vec(0.25, -0.10000002384186, 0), Quat(0.4161581993103, 0.31020647287369, 0.07309290766716, 0.85161119699478)),
        RRARM    =      Transform(Vec(0.2895770072937, -0.2546135187149, -0.27299878001213), Quat(0.4161581993103, 0.31020647287369, 0.07309290766716, 0.85161119699478)),
        LLLEG    =      Transform(Vec(-0.15000009536743, -1.0499999523163, -0.34999999403954), Quat(0, 0, 0, 1)),
        LLEG     =      Transform(Vec(-0.15000009536743, -0.60000002384186, 0), Quat(0.76604443788528, 0, 0, 0.64278763532639)),
        RRLEG    =      Transform(Vec(0.15000009536743, -1.0499999523163, -0.34999999403954), Quat(0, 0, 0, 1)),
        RLEG     =      Transform(Vec(0.15000009536743, -0.60000002384186, 0), Quat(0.76604443788528, 0, 0, 0.64278763532639)),
    }
}

local part_tags = {
    "Head",
    "Torso",
    "LARM",
    "LLARM",
    "LLEG",
    "LLLEG",
    "RARM",
    "RLEG",
    "RRARM",
    "RRLEG",
}


function PrintRagdollPose()

    -- Everything stays relative to the head. Head stays at vehicle driver pos.
    local head = FindBody("Head", true)
    if IsHandleValid(head) and head ~= 0 then
        print("Head: found")
    end

    local head_tr = GetBodyTransform(head)
    local min, max = GetBodyBounds(head)
    local head_center_pos = VecLerp(min, max, 0.5)
    local head_center_tr = Transform(head_center_pos, head_tr.rot)

    for _, body in ipairs(FindBodies("", true)) do
        if body ~= GetWorldBody() then
            for _, part_tag in ipairs(part_tags) do
    
                SetBodyDynamic(body, false)
    
                if HasTag(body, part_tag) then
    
                    local bodyTr = TransformToLocalTransform(head_tr, GetBodyTransform(body))
                    local p = bodyTr.pos
                    local r = bodyTr.rot
    
                    local pos_string = "Vec(" .. Sub(p[1]) .. ", " .. Sub(p[2]) .. ", " .. Sub(p[3]) .. ")"
                    local quat_string = "Quat(" .. Sub(r[1]) .. ", " .. Sub(r[2]) .. ", " .. Sub(r[3]) .. ", " .. Sub(r[4]) .. ")"
                    local transform_string = "Transform(" .. pos_string .. ", " .. quat_string .. ")"
    
                    print(part_tag, " = ",  transform_string .. ",")
    
                    break
    
                end
            end
        end
    end

end

function Sub(s)
    return s
end
--- The root of the npc object construction. Finds the entities with the relevant tag and builds all tables and data for the npc.
function npc_create(id)

    local npc = {}

    npc.id = id
    local tag_id = "gore_id"


    -- Search for all entities with the tag "gore_id", then find the correct ids.
    local AllEntities = {
        AllBodies    = FindBodies(tag_id, true),
        AllShapes    = FindShapes(tag_id, true),
        AllLights    = FindLights(tag_id, true),
        AllJoints    = FindJoints(tag_id, true),
        AllLocations = FindLocations(tag_id, true),
        AllTriggers  = FindTriggers(tag_id, true),
    }
    for entity_name, entity_category in pairs(AllEntities) do
        npc[entity_name] = MatchEntityIds(entity_category, tag_id, id) -- Keep same key as AllEntities sub-tables.
    end


    -- Absolutely horrid, I know.
    if not npc.AllBodies
    or not npc.AllShapes
    or not npc.AllJoints
    then
        print("ERROR", "NPC SPAWN CANCELLED: MISSING GROUPS OF ENTITIES.", sfnTime())
        return
    end

	npc.Head  = ExtractEntityByTag(npc.AllBodies, "Head")
	npc.Torso = ExtractEntityByTag(npc.AllBodies, "Torso")
	npc.L_ARM = ExtractEntityByTag(npc.AllBodies, "LLARM")
	npc.R_ARM = ExtractEntityByTag(npc.AllBodies, "RRARM")
	npc.RRLEG = ExtractEntityByTag(npc.AllBodies, "RRLEG")
	npc.LLLEG = ExtractEntityByTag(npc.AllBodies, "LLLEG")
	npc.RLEG  = ExtractEntityByTag(npc.AllBodies, "RLEG")
	npc.LLEG  = ExtractEntityByTag(npc.AllBodies, "LLEG")
	npc.Jaw   = GetShapeBody(ExtractEntityByTag(npc.AllShapes, "jaw"))


	npc.bodyparts      = ExtractAllEntitiesByTag(npc.AllBodies, "bodypart")
	npc.bones          = ExtractAllEntitiesByTag(npc.AllShapes, "bone")
	npc.ShoulderJoints = ExtractAllEntitiesByTag(npc.AllJoints, "shoulder")
	npc.ArmJoints      = ExtractAllEntitiesByTag(npc.AllJoints, "hand1")
	npc.HipJoints      = ExtractAllEntitiesByTag(npc.AllJoints, "hip")
	npc.KneeJoints     = ExtractAllEntitiesByTag(npc.AllJoints, "knee")
    npc.headJoint      = ExtractEntityByTag(npc.AllJoints, "head")

    npc.Eyes = {}
    npc_init_eyes(npc)


    npc.limbInitTransforms = {
        LLLEG   = TransformToLocalTransform(GetBodyTransform(npc.Torso), GetBodyTransform(npc.LLLEG)),
        RRLEG   = TransformToLocalTransform(GetBodyTransform(npc.Torso), GetBodyTransform(npc.RRLEG)),
        Jaw     = ternary(npc.Jaw, TransformToLocalTransform(GetBodyTransform(npc.Head), GetBodyTransform(npc.Jaw)), nil)
    }


    -- Absolutely horrid, I know.
    if not npc.AllBodies
    or not npc.AllShapes
    or not npc.AllJoints
    -- or not npc.Head
    -- or not npc.Jaw
    or not npc.Torso
    or not npc.L_ARM
    or not npc.R_ARM
    or not npc.RRLEG
    or not npc.LLLEG
    or not npc.bodyparts
    or not npc.ShoulderJoints
    or not npc.ArmJoints
    or not npc.HipJoints
    or not npc.KneeJoints
    then
        print("ERROR", "NPC SPAWN CANCELLED: MISSING SPECIFIC ENTITIES.", sfnTime())
        return
    end

    -- Add any potential loose shape's bodies into npc.AllBodies
    for _, shape in ipairs(npc.AllShapes) do

        local body = GetShapeBody(shape)
        if body ~= GetWorldBody() then
            TableInsertUnique(npc.AllBodies, body)
        end

    end


    npc_init(npc)

    for index, body in ipairs(npc.AllBodies) do
        table.insert(NPC_Bodies, body)
    end


    npc.helmet = {}

    return npc

end

-- Place turret xml entities inside of this script.
-- Apply id tags to turrets.

function init()

    -- Let's have the for loop start at 1, cool?
    if GetInt('level.turretCount') == 0 then
        SetInt('level.turretCount', 1)
    end

    local turretId = GetInt('level.turretCount')

    -- Each part of the turret.
    local entities = {
        turret = FindBody('turretGun'),
        turretBase = FindBody('turretBase'),
        turretArm = FindBody('turretArm'),

        gunH = FindJoint('gunH'),
        gunV = FindJoint('gunV'),

        shootLocation = FindLocation('shootLocation'),
        headLocation = FindLocation('headLocation'),
    }

    -- Apply id to all parts of the turret.
    for key, entity in pairs(entities) do
        SetTag(entity, 'turret_id', turretId)
        SetDescription(entity, turretId)
    end

    -- Increment the id for the next turret to use.
    SetInt('level.turretCount', GetInt('level.turretCount') + 1)

end
#include "../../scripts/TDSU/tdsu.lua"


function init()

    -- print("hi")

    SetBool("level.goreai.gore_map", true)

    local width = 30
    local inc = 15

    for x = (-width/2) - inc, width, inc do
        for z = (-width/2) - inc, width, inc do

            -- if math.random() > 0.25 then

                local vehicle_xml = AllVehicles[GetRandomIndex(AllVehicles)]

                local pos = Vec(x, 0, z)
                pos = VecAdd(VecRandom(inc/3), pos)
                pos[2] = 0

                local rot = QuatEuler(0, math.random(-180, 180), 0)

                Spawn(vehicle_xml, Transform(pos, rot))

            -- end

        end
    end

end


function draw()
end


AllVehicles = {

    -- "MOD/prefabs/spawnables/vehicles/Vehiclef1.xml",
    -- "MOD/prefabs/spawnables/vehicles/Vehiclef2.xml",
    -- "MOD/prefabs/spawnables/vehicles/Vehiclef3.xml",
    -- "MOD/prefabs/spawnables/vehicles/Vehiclef4.xml",
    -- "MOD/prefabs/spawnables/vehicles/Vehiclef5.xml",
    -- "MOD/prefabs/spawnables/vehicles/Vehiclef6.xml",
    -- "MOD/prefabs/spawnables/vehicles/Vehiclef7.xml",
    -- "MOD/prefabs/spawnables/vehicles/Vehiclef8.xml",
    -- "MOD/prefabs/spawnables/vehicles/Vehiclef9.xml",
    -- "MOD/prefabs/spawnables/vehicles/Vehiclef10.xml",
    -- "MOD/prefabs/spawnables/vehicles/Vehiclef11.xml",
    -- "MOD/prefabs/spawnables/vehicles/Vehiclef12.xml",
    -- "MOD/prefabs/spawnables/vehicles/Vehiclef13.xml",
    -- "MOD/prefabs/spawnables/vehicles/Vehiclef14.xml",
    "MOD/prefabs/spawnables/vehicles/Vehiclef15.xml", -- yellow van
    -- "MOD/prefabs/spawnables/vehicles/Vehiclef16.xml",
    -- "MOD/prefabs/spawnables/vehicles/Vehiclef17.xml",
    -- "MOD/prefabs/spawnables/vehicles/Vehiclef18.xml",
    -- "MOD/prefabs/spawnables/vehicles/Vehiclef19.xml", -- semi trailer
    -- "MOD/prefabs/spawnables/vehicles/Vehiclef20.xml",
    -- "MOD/prefabs/spawnables/vehicles/Vehiclef21.xml",
    -- "MOD/prefabs/spawnables/vehicles/Vehiclef22.xml",
    -- "MOD/prefabs/spawnables/vehicles/Vehiclef23.xml",
    -- "MOD/prefabs/spawnables/vehicles/Vehiclef24.xml",
    -- "MOD/prefabs/spawnables/vehicles/Vehiclef25.xml",
    -- "MOD/prefabs/spawnables/vehicles/Vehiclef26.xml",
    -- "MOD/prefabs/spawnables/vehicles/Vehiclef27.xml",
    -- "MOD/prefabs/spawnables/vehicles/Vehiclef28.xml",
    -- "MOD/prefabs/spawnables/vehicles/Vehiclef29.xml",
    -- "MOD/prefabs/spawnables/vehicles/Vehiclef30.xml",
    -- "MOD/prefabs/spawnables/vehicles/Vehiclef31.xml",
    -- "MOD/prefabs/spawnables/vehicles/Vehiclef32.xml",
    -- "MOD/prefabs/spawnables/vehicles/Vehiclef33.xml",
    -- "MOD/prefabs/spawnables/vehicles/Vehiclef34.xml",
    -- "MOD/prefabs/spawnables/vehicles/Vehiclef35.xml",
    -- "MOD/prefabs/spawnables/vehicles/VehicleF36.xml",
    -- "MOD/prefabs/spawnables/vehicles/VehicleF37.xml",

}
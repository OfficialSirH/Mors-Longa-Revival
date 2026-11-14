#include "../lib/TDSU/tdsu.lua"

function init()
    AllVehicles = FindVehicles("", true)

    Vehicle = 1
    --SetPlayerVehicle(Vehicles[Vehicle])

    for i, v in pairs(AllVehicles) do
        SetBodyDynamic(GetVehicleBody(v), false)
    end
    lastPlayerV=0
end

function tick()
    if GetPlayerVehicle()~= lastPlayerV then
        if GetPlayerVehicle()~=0 then
            SetBodyDynamic(GetVehicleBody(GetPlayerVehicle()), true)
        else
            SetBodyDynamic(GetVehicleBody(lastPlayerV), false)
            SetBodyAngularVelocity(GetVehicleBody(lastPlayerV),Vec())
            SetBodyVelocity(GetVehicleBody(lastPlayerV),Vec())
        end
        lastPlayerV = GetPlayerVehicle()
    end

    if InputPressed("n") then
        NextVehicle()
    end
end

function NextVehicle()
    Vehicle = GetTableNextIndex(AllVehicles, Vehicle)
    SetPlayerVehicle(AllVehicles[Vehicle])
end
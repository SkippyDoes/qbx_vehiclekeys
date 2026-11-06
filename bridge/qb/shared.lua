if GetConvar('qbx_vehiclekeys:enableBridge', 'true') ~= 'true' then return end

function CreateQbExport(name, cb)
    AddEventHandler(('__cfx_export_qb-vehiclekeys_%s'):format(name), function(setCB)
        setCB(cb)
    end)
end

---@param text string?
---@return string
local function trimPlate(text)
    return ((text or ''):gsub('^%s+', ''):gsub('%s+$', ''))
end

---Finds the vehicles that carry the given plate.
---The original check accepted every vehicle in the world (`or GetVehicleNumberPlateText(vehicle)` is always truthy),
---which would now create a key item for each of them, so it has to compare the plate for real.
function GetVehiclesFromPlate(plate)
    Wait(500) -- delay needed to give client spawned vehicles time to be known to the server
    local vehicles = IsDuplicityVersion() and GetAllVehicles() or GetGamePool('CVehicle')
    local vehEntityFromPlate = {}
    local wantedPlate = trimPlate(plate)

    for i = 1, #vehicles do
        local vehicle = vehicles[i]
        local vehPlate = trimPlate(qbx.getVehiclePlate(vehicle))
        if wantedPlate == vehPlate or wantedPlate == trimPlate(GetVehicleNumberPlateText(vehicle)) then
            vehEntityFromPlate[#vehEntityFromPlate + 1] = vehicle
        end
    end

    return vehEntityFromPlate
end

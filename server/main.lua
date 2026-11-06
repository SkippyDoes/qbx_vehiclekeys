local config = require 'config.server'

---True if the event came from a connected player (client), false for server-side triggers
---@param src any
---@return boolean
local function isPlayer(src)
    return type(src) == 'number' and src > 0 and GetPlayerName(src) ~= nil
end

---@param src number
---@param vehicle number
---@param distance number
---@return boolean
local function isNearVehicle(src, vehicle, distance)
    local pedCoords = GetEntityCoords(GetPlayerPed(src))
    return #(pedCoords - GetEntityCoords(vehicle)) <= distance
end

---Sets the door lock state of a vehicle. Callers must already have checked permission.
---@param vehicle number
---@param state number 1 = unlocked, 2 = locked
---@return boolean success
function SetLockState(vehicle, state)
    if type(state) ~= 'number' or not DoesEntityExist(vehicle) then return false end
    local vehicleConfig = GetVehicleConfig(vehicle)
    if vehicleConfig.noLock or vehicleConfig.shared then return false end
    Entity(vehicle).state:set('doorslockstate', state, true)
    return true
end

lib.callback.register('qbx_vehiclekeys:server:findKeys', function(source, netId)
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    if math.random() <= GetVehicleConfig(vehicle).findKeysChance then
        GiveKeys(source, vehicle)
        return true
    end
end)

lib.callback.register('qbx_vehiclekeys:server:carjack', function(source, netId, weaponTypeGroup)
    local chance = config.carjackChance[weaponTypeGroup] or 0.5
    if math.random() <= chance then
        local vehicle = NetworkGetEntityFromNetworkId(netId)
        GiveKeys(source, vehicle)
        SetLockState(vehicle, 1)
        return true
    end
end)

---Key fob / lock bind. Only a player who holds the key item for this exact vehicle
---(or whose job shares it) can lock or unlock it, whatever seat they are in.
---@return number? newLockState nil if the player is not allowed to
lib.callback.register('qbx_vehiclekeys:server:toggleLock', function(source, netId)
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then return end
    if not isNearVehicle(source, vehicle, config.maxLockDistance) then return end

    local vehicleConfig = GetVehicleConfig(vehicle)
    if vehicleConfig.noLock or vehicleConfig.shared then return end
    if not CanControlVehicle(source, vehicle) then return end

    local state = Entity(vehicle).state
    local current = state.doorslockstate or GetVehicleDoorLockStatus(vehicle)
    local newState = (current % 2) + 1
    state:set('doorslockstate', newState, true)
    return newState
end)

RegisterNetEvent('qbx_vehiclekeys:server:playerEnteredVehicleWithEngineOn', function(netId)
    local src = source
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    if not GetIsVehicleEngineRunning(vehicle) then return end
    GiveKeys(src, vehicle)
end)

---TODO: secure this event
RegisterNetEvent('qbx_vehiclekeys:server:tookKeys', function(netId)
    GiveKeys(source, NetworkGetEntityFromNetworkId(netId))
end)

---TODO: secure this event
RegisterNetEvent('qbx_vehiclekeys:server:hotwiredVehicle', function(netId)
    GiveKeys(source, NetworkGetEntityFromNetworkId(netId))
end)

RegisterNetEvent('qb-vehiclekeys:server:breakLockpick', function(itemName)
    if not (itemName == 'lockpick' or itemName == 'advancedlockpick') then return end
    exports.ox_inventory:RemoveItem(source, itemName, 1)
end)

---Used by lockpicking, taking keys from a dead driver, NPC spawn lock rolls and job autolock.
---Locking a vehicle whose lock state is already initialised requires its key (or a shared job),
---and players must be near the vehicle. Server-side triggers from other resources are trusted.
RegisterNetEvent('qb-vehiclekeys:server:setVehLockState', function(vehNetId, state)
    local src = source
    local vehicleEntity = NetworkGetEntityFromNetworkId(vehNetId)
    if type(state) ~= 'number' or not DoesEntityExist(vehicleEntity) then return end

    if isPlayer(src) then
        if not isNearVehicle(src, vehicleEntity, config.maxLockDistance) then return end
        local isInitialised = Entity(vehicleEntity).state.doorslockstate ~= nil
        if state == 2 and isInitialised and not CanControlVehicle(src, vehicleEntity) then return end
    end

    SetLockState(vehicleEntity, state)
end)

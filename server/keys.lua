local config = require 'config.server'
local sharedConfig = require 'config.shared'
local clientConfig = require 'config.client' -- only read for the job-shared vehicle list (sharedKeys)

local keyItem = sharedConfig.keyItem

---Gets Citizen Id based on source
---@param source number ID of the player
---@return string? citizenid The player CitizenID, nil otherwise.
local function getCitizenId(source)
    local player = exports.qbx_core:GetPlayer(source)
    if not player then return end

    return player.PlayerData.citizenid
end

---@param text string?
---@return string
local function trim(text)
    return ((text or ''):gsub('^%s+', ''):gsub('%s+$', ''))
end

---@param vehicle number?
---@return boolean
local function isValidVehicle(vehicle)
    return vehicle ~= nil and vehicle ~= 0 and DoesEntityExist(vehicle)
end

---Creates an id for vehicles that are not stored in the database (NPC cars, admin spawns...)
---@return string
local function generateKeyId()
    return ('K%X-%06X'):format(os.time(), math.random(0, 0xFFFFFF))
end

---Gets the unique key id of a vehicle. Every key item for this vehicle carries the same id,
---and no other vehicle shares it.
---Player owned vehicles use their database id, so the id survives garage storage and respawns.
---Other vehicles get a random id the first time keys are created (`create` = true).
---@param vehicle number
---@param create? boolean
---@return string?
function GetKeyId(vehicle, create)
    local state = Entity(vehicle).state
    if state.keyId then return state.keyId end

    local keyId
    if state.vehicleid then
        keyId = ('V%s'):format(state.vehicleid)
    elseif create then
        keyId = generateKeyId()
    end

    if keyId then
        state:set('keyId', keyId, true) -- replicated, clients compare it to the key items they hold
    end
    return keyId
end

exports('GetKeyId', GetKeyId)

---The plate written on the key item
---@param vehicle number
---@return string
local function getKeyPlate(vehicle)
    local vehicleId = Entity(vehicle).state.vehicleid
    if vehicleId then
        local data = exports.qbx_vehicles:GetPlayerVehicle(vehicleId)
        if data and data.plate then
            return trim(data.plate)
        end
    end

    return trim(qbx.getVehiclePlate(vehicle) or GetVehicleNumberPlateText(vehicle))
end

---@param source number
---@param keyId string
---@return number
local function countKeys(source, keyId)
    return exports.ox_inventory:Search(source, 'count', keyItem, { keyId = keyId }) or 0
end

--- Removing the vehicle keys from the user
---@param source number ID of the player
---@param vehicle number
---@param skipNotification? boolean
function RemoveKeys(source, vehicle, skipNotification)
    if not getCitizenId(source) or not isValidVehicle(vehicle) then return end

    local keyId = GetKeyId(vehicle, false)
    if not keyId then return end

    local slots = exports.ox_inventory:Search(source, 'slots', keyItem, { keyId = keyId })
    if not slots or #slots == 0 then return end

    for i = 1, #slots do
        exports.ox_inventory:RemoveItem(source, keyItem, slots[i].count, nil, slots[i].slot)
    end

    TriggerClientEvent('qbx_vehiclekeys:client:OnLostKeys', source)
    if not skipNotification then
        exports.qbx_core:Notify(source, locale('notify.keys_removed'))
    end

    return true
end

exports('RemoveKeys', RemoveKeys)

---Gives the player a key item for the vehicle. Does nothing if they already hold one.
---@param source number
---@param vehicle number
---@param skipNotification? boolean
---@return boolean? success true when a new key item was added
function GiveKeys(source, vehicle, skipNotification)
    if not getCitizenId(source) or not isValidVehicle(vehicle) then return end

    local keyId = GetKeyId(vehicle, true)
    if not keyId or countKeys(source, keyId) > 0 then return end

    local plate = getKeyPlate(vehicle)
    local added, reason = exports.ox_inventory:AddItem(source, keyItem, 1, {
        keyId = keyId,
        plate = plate,
        label = config.keyItem.labelFormat:format(plate),
        description = config.keyItem.descriptionFormat:format(plate),
    })

    if not added then
        if reason == 'invalid_item' then
            lib.print.error(("item '%s' does not exist in ox_inventory. Add it to ox_inventory/data/items.lua"):format(keyItem))
        end
        if not skipNotification then
            exports.qbx_core:Notify(source, locale('notify.keys_no_room'), 'error')
        end
        return
    end

    if not skipNotification then
        exports.qbx_core:Notify(source, locale('notify.keys_taken'))
    end
    return true
end

exports('GiveKeys', GiveKeys)

---@param src number
---@param vehicle number
---@return boolean
function HasKeys(src, vehicle)
    if not isValidVehicle(vehicle) then return false end

    local keyId = GetKeyId(vehicle, false)
    if keyId and countKeys(src, keyId) > 0 then
        return true
    end

    return false
end

exports('HasKeys', HasKeys)

---Checks whether the player's job shares this vehicle (mirrors AreKeysJobShared on the client)
---@param src number
---@param vehicle number
---@return boolean
function IsVehicleJobShared(src, vehicle)
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return false end

    local job = player.PlayerData.job
    local jobInfo = clientConfig.sharedKeys[job.name]
    if not jobInfo or (jobInfo.requireOnDuty and not job.onduty) then return false end

    local model = GetEntityModel(vehicle)
    local class = exports.qbx_core:GetVehicleClass(model)
    return (jobInfo.vehicles and jobInfo.vehicles[model])
        or (jobInfo.classes and jobInfo.classes[class])
        or false
end

---True if the player may lock, unlock or start the vehicle: they hold its key item, or their job shares it
---@param src number
---@param vehicle number
---@return boolean
function CanControlVehicle(src, vehicle)
    return HasKeys(src, vehicle) or IsVehicleJobShared(src, vehicle)
end

---Owned vehicles get their owner and key id as soon as they spawn with a database id,
---and the owner (if online) is handed the key item. This covers taking a vehicle out of
---a garage and buying one from a dealer, whichever resource spawns it.
AddStateBagChangeHandler('vehicleid', '', function(bagName, _, vehicleId)
    local vehicle = GetEntityFromStateBagName(bagName)
    if not vehicle or vehicle == 0 or not vehicleId then return end

    local data = exports.qbx_vehicles:GetPlayerVehicle(vehicleId)
    local owner = data and data.citizenid
    if not owner then return end

    local state = Entity(vehicle).state
    state:set('owner', owner, true)
    state:set('keyId', ('V%s'):format(vehicleId), true)

    if not config.giveKeysToOwnerOnSpawn then return end

    local player = exports.qbx_core:GetPlayerByCitizenId(owner)
    if player then
        GiveKeys(player.PlayerData.source, vehicle)
    end
end)

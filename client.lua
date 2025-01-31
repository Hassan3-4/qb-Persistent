local QBCore = exports['qb-core']:GetCoreObject()
local lastVehicle = nil
local spawnedVehicles = {}
local checkInterval = 2000
local spawnDistance = 250.0

-- Save vehicle state including lock status and ownership
CreateThread(function()
    while true do
        Wait(500)
        local ped = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(ped, false)

        if vehicle ~= 0 and DoesEntityExist(vehicle) then
            lastVehicle = vehicle
        else
            if lastVehicle and DoesEntityExist(lastVehicle) then
                local plate = QBCore.Functions.GetPlate(lastVehicle)
                local model = GetDisplayNameFromVehicleModel(GetEntityModel(lastVehicle)):lower()
                local coords = GetEntityCoords(lastVehicle)
                local heading = GetEntityHeading(lastVehicle)
                local locked = GetVehicleDoorLockStatus(lastVehicle) >= 2

                QBCore.Functions.TriggerCallback('persistent-vehicles:isPlayerVehicle', function(isOwned, ownerCitizenID)
                    if isOwned then
                        TriggerServerEvent('persistent-vehicles:savePosition', plate, model, {
                            x = coords.x,
                            y = coords.y,
                            z = coords.z
                        }, heading, locked, ownerCitizenID)
                    end
                end, plate)
                
                lastVehicle = nil
            end
        end
    end
end)

-- Proximity spawning with full state management
CreateThread(function()
    while true do
        Wait(checkInterval)
        local playerCoords = GetEntityCoords(PlayerPedId())
        
        -- Cleanup
        for plate, veh in pairs(spawnedVehicles) do
            if not DoesEntityExist(veh) then
                spawnedVehicles[plate] = nil
            end
        end

        QBCore.Functions.TriggerCallback('persistent-vehicles:getNearbyVehicles', function(vehicles)
            for _, data in pairs(vehicles) do
                local vehicleCoords = vector3(data.coords.x, data.coords.y, data.coords.z)
                local distance = #(playerCoords - vehicleCoords)

                if distance <= spawnDistance then
                    if not spawnedVehicles[data.plate] then
                        local existingVeh = GetVehicleByPlate(data.plate)
                        
                        if not existingVeh then
                            spawnVehicle(data.plate, data.model, vehicleCoords, data.heading, data.locked, data.citizenid)
                        else
                            spawnedVehicles[data.plate] = existingVeh
                            syncVehicleState(existingVeh, data.locked, data.citizenid)
                        end
                    end
                else
                    if spawnedVehicles[data.plate] then
                        DeleteEntity(spawnedVehicles[data.plate])
                        spawnedVehicles[data.plate] = nil
                    end
                end
            end
        end, playerCoords, spawnDistance)
    end
end)

function spawnVehicle(plate, modelName, coords, heading, locked, citizenid)
    local modelHash = GetHashKey(modelName)
    
    if not IsModelInCdimage(modelHash) then return end

    RequestModel(modelHash)
    while not HasModelLoaded(modelHash) do
        Wait(10)
    end

    local veh = CreateVehicle(modelHash, coords.x, coords.y, coords.z, heading, false, false)
    if DoesEntityExist(veh) then
        spawnedVehicles[plate] = veh
        SetVehicleNumberPlateText(veh, plate)
        SetEntityAsMissionEntity(veh, true, true)
        FreezeEntityPosition(veh, false)
        
        -- Set persistent vehicle state
        SetVehicleDoorsLocked(veh, locked and 2 or 1)
        SetVehicleDoorsLockedForAllPlayers(veh, locked)
        Entity(veh).state:set('owner', citizenid, true)

        -- Key management
        QBCore.Functions.TriggerCallback('persistent-vehicles:getPlayerCitizenID', function(cid)
            if cid == citizenid then
                TriggerEvent('qb-vehiclekeys:client:AddKeys', plate)
                exports['qb-vehiclekeys']:SetVehicleKey(plate, true)
            else
                exports['qb-vehiclekeys']:RemoveKey(plate)
            end
        end)
    end
    SetModelAsNoLongerNeeded(modelHash)
end

-- Vehicle state synchronization
function syncVehicleState(vehicle, locked, citizenid)
    SetVehicleDoorsLocked(vehicle, locked and 2 or 1)
    SetVehicleDoorsLockedForAllPlayers(vehicle, locked)
    Entity(vehicle).state:set('owner', citizenid, true)
end

-- Prevent unauthorized vehicle entry
CreateThread(function()
    while true do
        Wait(1000)
        local ped = PlayerPedId()
        local vehicle = GetVehiclePedIsTryingToEnter(ped)
        
        if DoesEntityExist(vehicle) and not IsPedInVehicle(ped, vehicle) then
            local plate = QBCore.Functions.GetPlate(vehicle)
            local owner = Entity(vehicle).state.owner

            QBCore.Functions.TriggerCallback('persistent-vehicles:getPlayerCitizenID', function(citizenid)
                if owner ~= citizenid then
                    ClearPedTasks(ped)
                    QBCore.Functions.Notify('You don\'t have access to this vehicle!', 'error')
                end
            end)
        end
    end
end)

-- Existing vehicle check
function GetVehicleByPlate(plate)
    local vehicles = GetGamePool('CVehicle')
    for _, vehicle in pairs(vehicles) do
        if QBCore.Functions.GetPlate(vehicle) == plate then
            return vehicle
        end
    end
    return nil
end
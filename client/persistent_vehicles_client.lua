local QBCore = exports['qb-core']:GetCoreObject()
local spawnedVehicles = {} -- Tracks spawned vehicles to prevent duplicates
local Config = Config -- Directly use the shared Config table

-- Function to calculate distance between two coordinates
local function GetDistance(coords1, coords2)
    return #(vector3(coords1.x, coords1.y, coords1.z) - vector3(coords2.x, coords2.y, coords2.z))
end

-- Function to check if a vehicle with the same plate already exists
local function IsVehicleAlreadySpawned(plate)
    local vehicles = GetGamePool('CVehicle') -- Get all vehicles in the game world
    for _, vehicle in pairs(vehicles) do
        if DoesEntityExist(vehicle) then
            local vehiclePlate = GetVehicleNumberPlateText(vehicle)
            if vehiclePlate == plate then
                return true
            end
        end
    end
    return false
end

-- Main loop to handle vehicle spawning and despawning
CreateThread(function()
    while true do
        Wait(Config.SpawnInterval)

        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)

        -- Fetch all saved vehicles from the server
        QBCore.Functions.TriggerCallback('persistent-vehicles:getAllVehicles', function(vehicles)
            for _, vehicleData in pairs(vehicles) do
                local vehicleCoords = vector3(vehicleData.coords.x, vehicleData.coords.y, vehicleData.coords.z)
                local distance = GetDistance(playerCoords, vehicleCoords)

                -- Check if the vehicle should spawn
                if distance <= Config.SpawnDistance then
                    if not IsVehicleAlreadySpawned(vehicleData.plate) then
                        -- Spawn the vehicle if it's not already spawned
                        TriggerServerEvent('persistent-vehicles:spawnVehicle', vehicleData)
                    end
                elseif distance > Config.DespawnDistance then
                    -- Despawn the vehicle if no players are nearby or inside it
                    local vehicles = GetGamePool('CVehicle')
                    for _, vehicle in pairs(vehicles) do
                        if DoesEntityExist(vehicle) then
                            local vehiclePlate = GetVehicleNumberPlateText(vehicle)
                            if vehiclePlate == vehicleData.plate then
                                local passengers = GetVehicleNumberOfPassengers(vehicle)
                                if passengers == 0 then
                                    DeleteEntity(vehicle)
                                end
                            end
                        end
                    end
                end
            end
        end)
    end
end)

-- Event to handle vehicle spawning on the client side
RegisterNetEvent('persistent-vehicles:spawnVehicleClient', function(vehicleData)
    local modelHash = GetHashKey(vehicleData.model)
    RequestModel(modelHash)
    while not HasModelLoaded(modelHash) do
        Wait(100)
    end

    local vehicle = CreateVehicle(
        modelHash,
        vehicleData.coords.x,
        vehicleData.coords.y,
        vehicleData.coords.z,
        vehicleData.heading,
        true,
        false
    )

    SetVehicleNumberPlateText(vehicle, vehicleData.plate) -- Ensure the plate is set correctly
    SetVehicleColours(vehicle, vehicleData.primaryColor, vehicleData.secondaryColor)
    SetVehicleExtraColours(vehicle, vehicleData.pearlescentColor, vehicleData.wheelColor)
    SetVehicleLivery(vehicle, vehicleData.livery)

    SetEntityAsMissionEntity(vehicle, true, true)
    SetVehicleHasBeenOwnedByPlayer(vehicle, true)
end)

-- Continuously save vehicle position while driving
CreateThread(function()
    while true do
        Wait(1500) -- Save position every 5 seconds

        local ped = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(ped, false)

        if DoesEntityExist(vehicle) and GetPedInVehicleSeat(vehicle, -1) == ped then
            local plate = QBCore.Functions.GetPlate(vehicle)
            if plate then
                local coords = GetEntityCoords(vehicle)
                local heading = GetEntityHeading(vehicle)

                -- Trigger server event to save the vehicle's position
                TriggerServerEvent('persistent-vehicles:updatePosition', plate, {
                    x = math.floor(coords.x * 100) / 100,
                    y = math.floor(coords.y * 100) / 100,
                    z = math.floor(coords.z * 100) / 100
                }, math.floor(heading * 100) / 100)
            end
        end
    end
end)
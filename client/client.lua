local QBCore = exports['qb-core']:GetCoreObject()
local lastVehicle = nil

-- Continuously check and save vehicle details when the player leaves a vehicle
CreateThread(function()
    while true do
        Wait(500)
        local ped = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(ped, false)
        if DoesEntityExist(vehicle) then
            lastVehicle = vehicle
        else
            if lastVehicle and DoesEntityExist(lastVehicle) then
                local plate = QBCore.Functions.GetPlate(lastVehicle)
                local modelHash = GetEntityModel(lastVehicle)
                local modelName = GetDisplayNameFromVehicleModel(modelHash):lower() -- e.g., "police"
                local coords = GetEntityCoords(lastVehicle)
                local heading = GetEntityHeading(lastVehicle)

                -- Get additional vehicle details: primary/secondary colors, extra colors and livery
                local primaryColor, secondaryColor = GetVehicleColours(lastVehicle)
                local pearlescentColor, wheelColor = GetVehicleExtraColours(lastVehicle)
                local livery = GetVehicleLivery(lastVehicle)

                if plate and modelName then
                    -- Check if the vehicle is owned by the player before saving
                    QBCore.Functions.TriggerCallback('persistent-vehicles:isPlayerVehicle', function(isPlayerVehicle)
                        if isPlayerVehicle then
                            TriggerServerEvent(
                                'persistent-vehicles:savePosition',
                                plate,
                                modelName,
                                {
                                    x = math.floor(coords.x * 100) / 100,
                                    y = math.floor(coords.y * 100) / 100,
                                    z = math.floor(coords.z * 100) / 100
                                },
                                math.floor(heading * 100) / 100,
                                primaryColor,
                                secondaryColor,
                                pearlescentColor,
                                wheelColor,
                                livery
                            )
                            QBCore.Functions.Notify('Vehicle position and details saved!', 'success')
                        end
                    end, plate)
                end
                lastVehicle = nil
            end
        end
    end
end)

-- Delete the saved vehicle details when the player enters a vehicle
RegisterNetEvent('QBCore:Client:OnPlayerEnteredVehicle', function(vehicle)
    local plate = QBCore.Functions.GetPlate(vehicle)
    if plate then
        TriggerServerEvent('persistent-vehicles:deletePosition', plate)
    end
end)
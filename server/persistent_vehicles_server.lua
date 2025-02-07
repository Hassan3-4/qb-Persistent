local QBCore = exports['qb-core']:GetCoreObject()

-- Fetch all saved vehicles from the database
QBCore.Functions.CreateCallback('persistent-vehicles:getAllVehicles', function(source, cb)
    MySQL.Async.fetchAll('SELECT * FROM persistent_vehicles', {}, function(result)
        local vehicles = {}
        for _, row in ipairs(result) do
            local coords = json.decode(row.coords)
            table.insert(vehicles, {
                plate = row.plate,
                model = row.model,
                coords = coords,
                heading = row.heading,
                primaryColor = row.primaryColor,
                secondaryColor = row.secondaryColor,
                pearlescentColor = row.pearlescentColor,
                wheelColor = row.wheelColor,
                livery = row.livery
            })
        end
        cb(vehicles)
    end)
end)

-- Spawn a vehicle on the client side
RegisterNetEvent('persistent-vehicles:spawnVehicle', function(vehicleData)
    TriggerClientEvent('persistent-vehicles:spawnVehicleClient', -1, vehicleData)
end)

-- Print messages to the server console
RegisterNetEvent('persistent-vehicles:printToConsole', function(message)
    print(string.format("[qb-Persistent] %s", message))
end)
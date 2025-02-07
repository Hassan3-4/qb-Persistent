local QBCore = exports['qb-core']:GetCoreObject()

-- Initialize the database table for persistent vehicles
MySQL.ready(function()
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS persistent_vehicles (
            plate VARCHAR(50) NOT NULL,
            model VARCHAR(50) NOT NULL,
            coords LONGTEXT NOT NULL,
            heading FLOAT NOT NULL,
            primaryColor INT NOT NULL,
            secondaryColor INT NOT NULL,
            pearlescentColor INT NOT NULL,
            wheelColor INT NOT NULL,
            livery INT NOT NULL,
            PRIMARY KEY (plate)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]], {}, function() end)
end)

-- Check if the vehicle belongs to the player
QBCore.Functions.CreateCallback('persistent-vehicles:isPlayerVehicle', function(source, cb, plate)
    MySQL.Async.fetchScalar('SELECT 1 FROM player_vehicles WHERE plate = ?', { plate }, function(result)
        cb(result ~= nil)
    end)
end)

-- Save vehicle details to the database
RegisterNetEvent('persistent-vehicles:savePosition', function(plate, modelName, coords, heading, primaryColor, secondaryColor, pearlescentColor, wheelColor, livery)
    MySQL.Async.execute(
        'INSERT INTO persistent_vehicles (plate, model, coords, heading, primaryColor, secondaryColor, pearlescentColor, wheelColor, livery) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?) ON DUPLICATE KEY UPDATE model = ?, coords = ?, heading = ?, primaryColor = ?, secondaryColor = ?, pearlescentColor = ?, wheelColor = ?, livery = ?',
        {
            plate, modelName, json.encode(coords), heading, primaryColor, secondaryColor, pearlescentColor, wheelColor, livery,
            modelName, json.encode(coords), heading, primaryColor, secondaryColor, pearlescentColor, wheelColor, livery
        },
        function(rowsChanged)
            -- Optionally handle success/failure
        end
    )
end)

-- Update vehicle position in the database
RegisterNetEvent('persistent-vehicles:updatePosition', function(plate, coords, heading)
    MySQL.Async.execute(
        'UPDATE persistent_vehicles SET coords = ?, heading = ? WHERE plate = ?',
        { json.encode(coords), heading, plate },
        function(rowsChanged)
            -- Optionally handle success/failure
        end
    )
end)

-- Delete saved vehicle details when the player enters a vehicle
RegisterNetEvent('persistent-vehicles:deletePosition', function(plate)
    MySQL.Async.execute('DELETE FROM persistent_vehicles WHERE plate = ?', { plate }, function(rowsChanged)
        -- Optionally handle success/failure
    end)
end)

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
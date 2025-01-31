local QBCore = exports['qb-core']:GetCoreObject()
local vehicles = {}

-- Updated table with owner information
MySQL.ready(function()
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `persistent_vehicles` (
            `plate` VARCHAR(50) NOT NULL,
            `model` VARCHAR(50) NOT NULL,
            `coords` LONGTEXT NOT NULL,
            `heading` FLOAT NOT NULL,
            `locked` TINYINT(1) NOT NULL DEFAULT 0,
            `citizenid` VARCHAR(50) NOT NULL,
            PRIMARY KEY (`plate`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]], {}, function()
        loadAllVehicles()
    end)
end)

function loadAllVehicles()
    MySQL.Async.fetchAll('SELECT * FROM persistent_vehicles', {}, function(results)
        vehicles = {}
        for _, v in ipairs(results) do
            if v.plate and v.model and v.coords and v.heading and v.citizenid then
                vehicles[#vehicles+1] = {
                    plate = v.plate,
                    model = v.model,
                    coords = json.decode(v.coords),
                    heading = v.heading,
                    locked = v.locked == 1,
                    citizenid = v.citizenid
                }
            end
        end
        TriggerClientEvent('persistent-vehicles:updateVehicleList', -1, vehicles)
    end)
end

-- Save position with owner information
RegisterNetEvent('persistent-vehicles:savePosition', function(plate, model, coords, heading, locked, citizenid)
    MySQL.Async.execute(
        'INSERT INTO persistent_vehicles (plate, model, coords, heading, locked, citizenid) '..
        'VALUES (?, ?, ?, ?, ?, ?) '..
        'ON DUPLICATE KEY UPDATE model = VALUES(model), coords = VALUES(coords), '..
        'heading = VALUES(heading), locked = VALUES(locked), citizenid = VALUES(citizenid)',
        {plate, model, json.encode(coords), heading, locked and 1 or 0, citizenid},
        function()
            loadAllVehicles()
        end
    )
end)

-- Get player's citizenid
QBCore.Functions.CreateCallback('persistent-vehicles:getPlayerCitizenID', function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    cb(Player.PlayerData.citizenid)
end)

-- Ownership check with citizenid validation
QBCore.Functions.CreateCallback('persistent-vehicles:isPlayerVehicle', function(source, cb, plate)
    local Player = QBCore.Functions.GetPlayer(source)
    MySQL.Async.fetchScalar(
        'SELECT citizenid FROM player_vehicles WHERE plate = ?', 
        {plate},
        function(result)
            cb(result == Player.PlayerData.citizenid, result)
        end
    )
end)

-- Nearby vehicles query
QBCore.Functions.CreateCallback('persistent-vehicles:getNearbyVehicles', function(source, cb, coords, distance)
    local nearbyVehicles = {}
    for _, vehicle in pairs(vehicles) do
        if vehicle.coords and vehicle.coords.x then
            local vehCoords = vector3(vehicle.coords.x, vehicle.coords.y, vehicle.coords.z)
            if #(coords - vehCoords) <= distance then
                nearbyVehicles[#nearbyVehicles+1] = vehicle
            end
        end
    end
    cb(nearbyVehicles)
end)
fx_version 'cerulean'
game 'gta5'

author 'YourName'
description 'Persistent Vehicle System with Vehicle Keys'
version '3.0.0'

shared_scripts {
    'config.lua' -- Shared configuration
}

client_scripts {
    'client/client.lua', -- Your original client script
    'client/persistent_vehicles_client.lua' -- Persistent vehicle logic
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/server.lua', -- Your original server script
    'server/persistent_vehicles_server.lua' -- Persistent vehicle logic
}

dependencies {
    'qb-core',
    'oxmysql',
    'qb-vehiclekeys'
}
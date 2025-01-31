fx_version 'cerulean'
game 'gta5'

author 'YourName'
description 'Persistent Vehicle System'
version '3.0.0'

client_scripts {
    'client.lua'
}


server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server.lua'
}

dependencies {
    'qb-core',
    'oxmysql'
}
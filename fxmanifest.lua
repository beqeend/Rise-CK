fx_version 'cerulean'
game 'gta5'

author 'beqeend'
description 'Gelişmiş Karakter Silme Sistemi'
version '1.0.0'

shared_script 'config.lua'

client_scripts {
    'client.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server_config.lua',
    'server.lua'
}

ui_page 'index.html'

files {
    'index.html',
    'style.css',
    'script.js'
}

lua54 'yes' 

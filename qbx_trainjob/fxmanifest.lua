fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author "ParisRP"
description "qbx_trainjob metro and freight job Qbox"
version '1.0.1'

lua54 'yes'

ui_page 'web/dist/index.html'

client_scripts {
    "config.lua",
    "client/*.lua", 
}

server_scripts {
    "@oxmysql/lib/MySQL.lua", 
    "config.lua",
    "server/utils.lua",
    "server/framework.lua",
    "server/main.lua"
}

escrow_ignore {
    "config.lua",
    "client/utils.lua",
    "server/*.lua",
}

data_file 'TRAINCONFIGS_FILE' 'data/trains.xml'

files {'web/dist/index.09f4070a.css', 'web/dist/index.324bf286.js', 'web/dist/index.html', 'data/trains.xml'}

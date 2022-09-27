-- [[ Metadata ]] --
fx_version 'cerulean'
games { 'gta5' }

-- [[ Author ]] --
author 'AnnaLou#1509'
description 'FiveM stancer by AnnaLou'

-- [[ Version ]] --
version '1.1.0'

-- [[ Dependencies ]] --
dependencies {
    'PolyZone',
}

-- [[ Files ]] --
ui_page 'html/index.html'

shared_scripts {
    'config.lua',
}

server_scripts {
	-- SQL Import
	'@mysql-async/lib/MySQL.lua',	
	-- Server
	'server.lua',
}

client_scripts {
    -- Polyzone
    '@PolyZone/client.lua',
    '@PolyZone/BoxZone.lua',
    '@PolyZone/EntityZone.lua',
    '@PolyZone/CircleZone.lua',
    '@PolyZone/ComboZone.lua',
    -- Client Events
    'client.lua',
}

files {
	'html/index.html',
	'html/script.js',
	'html/style.css',
	'html/audio/*.ogg'
}

-- client_script "@Badger-Anticheat/acloader.lua"

-- [[ Tebex ]] --
lua54 'yes'
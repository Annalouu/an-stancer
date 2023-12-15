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
    'ox_lib',
}

-- [[ Files ]] --
ui_page 'html/index.html'

shared_scripts {
    '@ox_lib/init.lua',
}

client_scripts {
    'client/*.lua',
}

server_scripts {
	-- SQL Import
	'@mysql-async/lib/MySQL.lua',
	'server.lua',
}

files {
	'html/index.html',
	'html/script.js',
	'html/style.css',
	'html/audio/*.ogg',
    'config.lua',
}

-- [[ Tebex ]] --
lua54 'yes'
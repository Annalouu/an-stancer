fx_version 'cerulean'
game 'gta5'
ui_page 'html/index.html'
lua54 'on'

shared_scripts {
	"config.lua"
}

server_scripts {
	'@mysql-async/lib/MySQL.lua',	
	"server.lua"
}
client_scripts {
	"client.lua",
	'@PolyZone/client.lua',
	'@PolyZone/BoxZone.lua',
	'@PolyZone/EntityZone.lua',
	'@PolyZone/CircleZone.lua',
	'@PolyZone/ComboZone.lua',
}

files {
	'html/index.html',
	'html/script.js',
	'html/style.css',
	'html/audio/*.ogg'
}
client_script "@Badger-Anticheat/acloader.lua"
fx_version 'cerulean'
games { 'rdr3', 'gta5' }
lua54 'yes'

author 'ME'
description 'Alles wichtige fürs Geile Wholeplay'
version '1.0.0'

client_scripts {
	'client/*.lua'
}

server_scripts {
	'server/*.lua'
}

shared_scripts {
	'utils.lua'
}

ui_page 'ui/index.html'

files {
	'characters/*.json',
	'vehicles/*.json',
	'ui/index.html',
	'ui/script.js',
	'ui/style.css',
	'ui/images/*',
}

fx_version 'cerulean'
games { 'rdr3', 'gta5' }
lua54 'yes'

author 'ME'
description 'Alles wichtige fürs Geile Wholeplay'
version '1.2.0'

-- Optionale QBox-Integration: Wenn qbx_vehiclekeys läuft,
-- bekommen Spieler automatisch Fahrzeugschlüssel beim Spawnen.
-- Das Skript funktioniert auch ohne QBox (Standalone).

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
	'client/blips.json',
	'ui/index.html',
	'ui/script.js',
	'ui/constants.js',
	'ui/api.js',
	'ui/utils.js',
	'ui/dom.js',
	'ui/search.js',
	'ui/menu.js',
	'ui/tabs.js',
	'ui/overlay.js',
	'ui/optionsSubmenu.js',
	'ui/driversSubmenu.js',
	'ui/style.css',
	'ui/images/*',
	'kusskultlogo.png'
}

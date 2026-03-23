CHARACTER_SPAWN_OFFSET_Y = 3.0


---Speichert den Charakter des Spielers als Datei ab (WIP)
--[[
RegisterCommand("gwsaveentity", function(source)
	local model = GetEntityModel(GetPlayerPed(source))
	local netId = GetNetworkIDPlayerFromSource(source)
	local information = { model = model, name = Players[netId].name, age = 17, coolness = 1000, size = { height = 175, weight = 70 } }

	SaveResourceFile(GetCurrentResourceName(), "server/Super.json", json.encode(information), -1)
end, false)
]] --
RegisterCommand("gwspawnplayer", function(source, args)
	if args[1] ~= nil then
		local vector4 = GetEntityCoordsAndHeading(GetPlayerPed(source))
		CheckIfEntityIsKussKult(source, args[1], PLAYER_VARIANT, true, vector4, args[1])
	else
		TriggerClientEvent("CEv_ShowNotificationEvent", source, "Da fehlt was!")
	end
end, false)

RegisterCommand("gwspawnvehicle", function(source, args)
	if args[1] ~= nil then
		local vector4 = GetEntityCoordsAndHeading(GetPlayerPed(source))
		CheckIfEntityIsKussKult(source, args[1], VEHICLE_VARIANT, nil, vector4, nil)
	else
		TriggerClientEvent("CEv_ShowNotificationEvent", source, "Da fehlt was!")
	end
end, false)

--Befehlerstellung und -definition für den Neutralen
RegisterCommand("gwspawnneutral", function(source, args, raw)
	if args[1] ~= nil then
		local netID = source
		--local vector4 = GetPlayerCoordsAndHeading(netID, CHARACTER_SPAWN_OFFSET_Y)
		local vector4 = nil
		if (args[2] == "true") then
			CheckIfEntityIsKussKult(source, args[1], NEUTRAL_VARIANT, true, vector4, args[1])
		else
			CheckIfEntityIsKussKult(source, args[1], NEUTRAL_VARIANT, false, vector4, args[1])
		end
	else
		TriggerClientEvent("CEv_ShowNotificationEvent", source, "Da fehlt was!")
	end
end, false)

--Befehlerstellung und -definition für den Bodyguard
RegisterCommand("gwspawnbuddy", function(source, args, raw)
	if args[1] ~= nil then
		local netID = source
		--local vector4 = GetPlayerCoordsAndHeading(netID, CHARACTER_SPAWN_OFFSET_Y)
		local vector4 = nil
		if (args[2] == "true") then
			CheckIfEntityIsKussKult(source, args[1], FRIENDLY_VARIANT, true, vector4, GetPlayerFactionFromSource(source))
		else
			CheckIfEntityIsKussKult(source, args[1], FRIENDLY_VARIANT, false, vector4, GetPlayerFactionFromSource(source))
		end
	else
		TriggerClientEvent("CEv_ShowNotificationEvent", source, "Da fehlt was!")
	end
end, false)

--Befehlerstellung und -definition für den Gegner
RegisterCommand("gwspawngegner", function(source, args, raw)
	if args[1] ~= nil then
		local netID = source
		--local vector4 = GetPlayerCoordsAndHeading(netID, CHARACTER_SPAWN_OFFSET_Y)
		local vector4 = nil
		if (args[2] == "true") then
			CheckIfEntityIsKussKult(source, args[1], AGGRESSIVE_VARIANT, true, vector4, args[1])
		else
			CheckIfEntityIsKussKult(source, args[1], AGGRESSIVE_VARIANT, false, vector4, args[1])
		end
	else
		TriggerClientEvent("CEv_ShowNotificationEvent", source, "Da fehlt was!")
	end
end, false)

---Befehlerstellung und -definition für eine Fraktion
RegisterCommand("gwspawngruppe", function(source, args)
	local index = NetworkGetNetworkIdFromEntity(GetPlayerPed(source))
	local exceptionTarget = Players[index].name
	if args[1] == nil then
		TriggerClientEvent("CEv_ShowNotificationEvent", source, "Da fehlt der Gruppenname!")
	end
	if (args[2] ~= nil) then
		if (args[3] == "true") then
			CheckIfFactionIsKussKult(source, args[1], args[2], true, nil, exceptionTarget)
		else
			CheckIfFactionIsKussKult(source, args[1], args[2], false, nil, exceptionTarget)
		end
	else
		TriggerClientEvent("CEv_ShowNotificationEvent", source, "Die Gesinnung der Gruppe fehlt!")
	end
end, false)

---Spawnt das eigene Fahrzeug vom Kuss Kult Charakters des Spielers
RegisterCommand("gwspawnmycar", function(source, args)
	local index = NetworkGetNetworkIdFromEntity(GetPlayerPed(source))
	local characterName = Players[index].name
	characterName = ReplaceUmlaute(characterName)
	characterName = string.lower(characterName)
	local ownerString = Owners[characterName]
	if ownerString ~= nil then
		local vehicleString = ownerString[1]
		TriggerClientEvent("CEv_SpawnVehicleForDriver", source, vehicleString, index);
	else
		TriggerClientEvent("CEv_ShowNotificationEvent", source, "Dieser Charakter besitzt kein Fahrzeug!")
	end
end, false)

---Ändert die Gesinnung eines Charakters zu neutral
RegisterCommand("gwgesinnungneutral", function(source, args)
	if args[1] ~= nil then
		TurnVariantToNeutral(args[1], source)
	else
		TriggerClientEvent("CEv_ShowNotificationEvent", source, "Da fehlt was!")
	end
end, false)

---Ändert die Gesinnung eines Charakters zu buddy und er tritt der Gruppe des Spielers bei
RegisterCommand("gwgesinnungbuddy", function(source, args)
	if args[1] ~= nil then
		TurnVariantToFriendly(args[1], source)
	else
		TriggerClientEvent("CEv_ShowNotificationEvent", source, "Da fehlt was!")
	end
end, false)

---Ändert die Gesinnung eines Charakters zu gegner
RegisterCommand("gwgesinnunggegner", function(source, args)
	if args[1] ~= nil then
		TurnVariantToAggressive(args[1], source)
	else
		TriggerClientEvent("CEv_ShowNotificationEvent", source, "Da fehlt was!")
	end
end, false)

---Löscht einen einzelnen aktiven Entity anhand des Namens
RegisterCommand("gwdropsingle", function(source, args)
	if (args[1] ~= nil) then
		DropSpecificEntityByName(args[1], source)
	else
		TriggerClientEvent("CEv_ShowNotificationEvent", source, "Da fehlt was!")
	end
end, false)

---Löscht alle aktiven Charaktere
RegisterCommand("gwdropallpeds", function(source, args)
	DropAllCharacters()
end, false)

---Löscht alle aktiven Fahrzeuge
RegisterCommand("gwdropallcars", function(source, args)
	DropAllVehicles()
end, false)

---Löscht alle Aktives
RegisterCommand("gwdropeverything", function(source, args)
	DropAllAndEverything()
	--DropAllCharacters()
end, false)

---Löscht alle Charaktere die tot sind und alle Fahrzeuge, die kaputt sind
RegisterCommand("gwdropdead", function(source)
	DeadGarbageCleanerCheck(source, true)
end, false)

---Listet alle Aktiven in der Konsole des Spielers auf
RegisterCommand("gwlistall", function(source)
	ListAllActiveForClient(source)
end, false)

---Lässt alle aktiven Charakteren ihren Skin neuladen
RegisterCommand("gwreskin", function(source)
	TriggerClientEvent("CEv_ReskinAll", source, Players, Characters)
end, false)

---Der Spieler lädt seinen aktuellen Kuss Kult Charakter neu
RegisterCommand("gwr", function(source)
	local networkID = GetNetworkIDPlayerFromSource(source)
	local player = Players[networkID]
	if IsKussKultCharacter(player.name) then
		TriggerClientEvent("CEv_SpawnCharacter", source, PLAYER_VARIANT, player.skin, true, nil, player.faction)
		TriggerClientEvent("CEv_ShowNotificationEvent", source, "Charakter wurde neu geladen!")
		Citizen.Wait(NETWORK_ID_SYNC_DELAY)
	end
end, false)

---Alle Charaktere werden sofort zum Stillstand gebracht
RegisterCommand("gwstopall", function(source)
	StopAllCharacters(source)
end, false)

---Wechselt durch die Kostüme des Spieler Charakters durch
RegisterCommand("gwchangeskin", function(source, args)
	local networkID = GetNetworkIDPlayerFromSource(source)
	local name = Players[networkID].name
	local skinTable = TableOfAllCharacterSkins[name]
	local offset = args[1]
	if skinTable ~= nil and type(skinTable) == "table" then
		local length = #skinTable
		if length > 0 then
			if offset ~= nil and type(offset) == "number" then
				if offset < 1 then
					offset = 1
				end
				if offset > length then
					FullModelSwitchOrJustCosmetics(networkID, name, CHARFOLDER, source, Players[networkID].faction)
				else
					FullModelSwitchOrJustCosmetics(networkID, skinTable[offset], CHARFOLDER, source,
						Players[networkID].faction)
				end
			else
				offset = GetCurrentSkinIndex(TableOfAllCharacterSkins, name, Players[networkID].skin)
				if offset == -1 then
					offset = 1
				else
					offset = offset + 1
				end
				if offset > length then
					FullModelSwitchOrJustCosmetics(networkID, name, CHARFOLDER, source, Players[networkID].faction)
				else
					FullModelSwitchOrJustCosmetics(networkID, skinTable[offset], CHARFOLDER, source,
						Players[networkID].faction)
				end
			end
		else
			TriggerClientEvent("CEv_ShowNotificationEvent", source, "~r~" .. name .. " hat keine Verkleidungen!")
		end
	else
		TriggerClientEvent("CEv_ShowNotificationEvent", source, "~r~" .. name .. " hat keine Verkleidungen!")
	end
end, false)

---Belebt einen Charakter wieder (WIP)
RegisterCommand("gwrevievesingle", function(source, args)
	if (args[1] ~= nil) then
		local exists, char = CheckIfCharacterExistsByName(args[1])
		if exists then
			TriggerClientEvent("CEv_RevieveDeadPed", source, char)
		else
			TriggerClientEvent("CEv_ShowNotificationEvent", source, "Den Namen gibt es nicht!")
		end
	else
		TriggerClientEvent("CEv_ShowNotificationEvent", source, "Da fehlt was!")
	end
end, false)

---Spawnt alle Kuss Kult Charaktere in einem großen Kreis um den Spieler herum für den Jahresabschluss
RegisterCommand("gwjahresabschluss", function(source, args)
	local variant = NEUTRAL_VARIANT
	local hasWeapon = true
	local vector4 = nil
	local factionName = "CHAOS"

	local Group = GetAllCharacterNames()
	if (args[1] ~= nil) then
		variant = GetVariantFromInput(args[1])
	end

	TriggerClientEvent("CEv_SpawnMultipleCharacters", source, Group, variant, hasWeapon, vector4, factionName)
end, false)

---Spawnt einen zufälligen Kuss Kult Charakter
RegisterCommand("gwrandomped", function(source)
	BecomeRandomKussKultCharacter(source)
end, false)

---Spawnt ein zufälliges Kuss Kult Fahrzeug
RegisterCommand("gwrandomcar", function(source)
	SpawnRandomKussKultVehicle(source)
end, false)

---Bereitet eine Runde Kuss Kult Knockout vor
RegisterCommand("gwkusskultknockout", function(source)
	ExecuteCommand("gwdropallcars", source)
	local playerServerID = GetPlayers()
	for _, serverID in ipairs(playerServerID) do
		BecomeRandomKussKultCharacter(serverID)
		Citizen.Wait(NETWORK_ID_SYNC_DELAY)
		SpawnRandomKussKultVehicle(serverID)
		Citizen.Wait(NETWORK_ID_SYNC_DELAY)
	end
end, false)

---Schaltet bei jedem Spieler die Unbesiegbarkeit um
RegisterCommand("gwtoggleeveryinvincibility", function(source)
	for _, serverID in ipairs(GetPlayers()) do
		TriggerClientEvent("CEv_SetClientOption", serverID, "unbesiegbar")
		Citizen.Wait(NETWORK_ID_SYNC_DELAY)
		local networkID = GetNetworkIDPlayerFromSource(serverID)
		local player = Players[networkID]
		if IsKussKultCharacter(player.name) then
			TriggerClientEvent("CEv_SpawnCharacter", serverID, PLAYER_VARIANT, player.skin, true, nil, player.faction)
			TriggerClientEvent("CEv_ShowNotificationEvent", serverID, "Charakter wurde neu geladen!")
			Citizen.Wait(NETWORK_ID_SYNC_DELAY)
		end
	end
end, false)

---Macht alle Spieler untereinander zu Freunden
RegisterCommand("gwfreunde", function()
	TriggerClientEvent("CEv_ChangePlayerToPlayerRelationship", -1, 1, FactionLeaders)
	TriggerClientEvent("CEv_ShowNotificationEvent", -1, "Alle Spieler sind von nun an Freunde!")
end, false)

---Macht alle Spieler untereinander zu Feinden
RegisterCommand("gwfeinde", function()
	TriggerClientEvent("CEv_ChangePlayerToPlayerRelationship", -1, 5, FactionLeaders)
	TriggerClientEvent("CEv_ShowNotificationEvent", -1, "Alle Spieler sind von nun an Feinde!")
end, false)

---Startet bei allen Spielern einen Countdown
RegisterCommand("gwcountdown", function(soure, args)
	TriggerClientEvent("CEv_ShowCountdown", -1, args[1] or 300000)
end, false)

---Beendet bei allen Spielern einen aktuellen Countdown
RegisterCommand("gwcancelcountdown", function()
	TriggerClientEvent("CEv_CancelCountdown", -1)
end, false)

---Speichert alle aktiven Charaktere und Fahrzeuge mit ihren Koordinaten in einem Diorama-File ab
RegisterCommand("gwsavediorama", function(source, args)
	if args[1] ~= nil then
		local characters = {}
		local vehicles = {}
		for networkid, character in pairs(Characters) do
			local handle = NetworkGetEntityFromNetworkId(networkid)
			local vector4 = { coords = GetEntityCoords(handle), heading = GetEntityHeading(handle) - 180.0 }
			local entity = { name = character.skin, faction = character.faction, vector4 = vector4, weapon = true }
			table.insert(characters, entity)
		end
		for networkid, vehicle in pairs(Vehicles) do
			local handle = NetworkGetEntityFromNetworkId(networkid)
			local vector4 = { coords = GetEntityCoords(handle), heading = GetEntityHeading(handle) }
			local entity = { name = vehicle.skin, vector4 = vector4 }
			table.insert(vehicles, entity)
		end
		local session = { characters = characters, vehicles = vehicles }
		SaveResourceFile(GetCurrentResourceName(), "dioramas/" .. args[1] .. ".json", json.encode(session), -1)
		Citizen.Wait(NETWORK_ID_SYNC_DELAY)
		TableOfAllDioramas = ListAllEntriesInFolder("dioramas")
		TriggerClientEvent("CEv_ShowNotificationEvent", source, "Diorama " .. args[1] .. " wurde gespeichert")
	else
		TriggerClientEvent("CEv_ShowNotificationEvent", source, "Diorama wurde nicht gespeichert")
	end
end, false)

---Plaziert alle Charaktere und Fahrzeuge eines Diorama-Files in der Spielwelt
RegisterCommand("gwplacediorama", function(source, args)
	if args[1] ~= nil then
		local diorama = Looker(args[1], "dioramas")
		if diorama ~= nil then
			local charactergroup, charactervectors, vehiclegroup, vehiclevectors, faction, weaponPossession =
				ExtractTablesOfDiorama(diorama)
			if args[2] ~= nil then
				TriggerClientEvent("CEv_SpawnMultipleCharactersDiorama", source, charactergroup,
					GetVariantFromInput(args[2]),
					weaponPossession,
					charactervectors, faction)
			else
				TriggerClientEvent("CEv_SpawnMultipleCharactersDiorama", source, charactergroup, NEUTRAL_VARIANT,
					weaponPossession,
					charactervectors, faction)
			end
			TriggerClientEvent("CEv_SpawnMultipleVehicles", source, vehiclegroup, vehiclevectors)
			TriggerClientEvent("CEv_ShowNotificationEvent", source, "Diorama " .. args[1] .. " erfolgreich platziert")
		else
			TriggerClientEvent("CEv_ShowNotificationEvent", source, args[1] .. " ist kein Diorama!")
		end
	end
end, false)

---Startet eine Runde Twouble in Kuss Kult
RegisterCommand("gwtwoubleinkusskult", function(source)
	local playercount = #GetPlayers()
	local terroristCount = 1
	if playercount > 1 then
		if terroristCount < playercount then
			StartTwoubleInKussKult(terroristCount)
		else
			TriggerClientEvent("CEv_ShowNotificationEvent", source, "Zu viele Widerkussler angegeben!")
		end
	else
		TriggerClientEvent("CEv_ShowNotificationEvent", source,
			"Für Twouble In Kuss Kult sind mindestens 2 Spieler notwendig")
	end
end, false)

---Stoppt das aktive Kuss Kult Spiel und entfernt die Event-Handler davon
RegisterCommand("gwstopkusskultgame", function()
	StopCallback = {
		[KUSS_KULT_GAMES.TWOUBLE_IN_KUSS_KULT] = function()
			TriggerClientEvent("CEv_ShowNotificationEvent", -1, "~g~Twouble in Kuss Kult wurde vorzeitig beendet")
			TriggerClientEvent("CEv_RemoveKussKultGamesHandler", -1)
			RemoveEventHandler(TwoubleManager)
		end
	}
	if RunningKussKultGame then
		StopCallback[RunningKussKultGame]()
		RunningKussKultGame = nil
	else
		TriggerClientEvent("CEv_ShowNotificationEvent", -1, "~r~Kein aktives Spiel gefunden")
	end
end, false)

---Wechselt die Spielfigur des Spielers mit einem existierenden Kuss Kult Charakter
RegisterCommand("gwswitch", function(source, args)
	local networkID = GetNetworkIDPlayerFromSource(source)
	local player = Players[networkID]
	if IsKussKultCharacter(player.name) then
		if args[1] ~= nil then
			local found, toSwitchToCharacter = CheckIfCharacterExistsByName(args[1])
			if found then
				TriggerClientEvent("CEv_SwitchCharactersIsDeadCheck", source, source, toSwitchToCharacter, player,
					GetDriversInfo())
			else
				TriggerClientEvent("CEv_ShowNotificationEvent", source,
					args[1] .. " wurde nicht als aktiver Charakter gefunden.")
			end
		end
	end
end, false)

---Erstellt eine Drivers Fahrgemeinschaft mit dem eingebenen Fahrzeug und Charakteren.
---Diese müssen in der Spielwelt existieren
RegisterCommand("gwdrivers", function(source, args)
	DriversCreateFromArgs(source, args)
end, false)

---Ändert die Zusammensetzung einer bestehenden Fahrgemeinschaft zu der der definierten Charaktere
RegisterCommand("gwdriversupdate", function(source, args)
	if args[1] ~= nil then
		local isfound, vehicle = CheckIfVehicleExistsByName(args[1])
		if isfound and args[2] ~= nil then
			local isfounddriver, driver = CheckIfCharacterExistsByName(args[2])
			local passengers = {}
			table.insert(passengers, driver.networkID)
			if isfounddriver then
				for i = 3, #args, 1 do
					local isfoundpassenger, passenger = CheckIfCharacterExistsByName(args[i])
					if isfoundpassenger then
						table.insert(passengers, passenger.networkID)
					end
				end
				DriversUpdateCarpool(vehicle.networkID, passengers, source)
			end
		else
			TriggerClientEvent("CEv_ShowNotificationEvent", -1, "Bitte gültiges Fahrzeug und Fahrer angeben!")
		end
	end
end, false)

---Setzt das Verhalten der Fahrgemeinschaft
---@param args table [VehNet, DriverNet, ?TargetNet]
RegisterCommand("gwdriverstask", function(source, args)
	DriversSetTaskFromArgs(source, args)
end, false)

---Spawnt ein Fahrzeug samt Charakteren. Diese werden automatisch zu einer Fahrgemeinschaft hinzugefügt
---Entweder mit einem extra definierten Fahrzeug oder mit dem Fahrzeug des ersten Charakters
RegisterCommand("gwspawndrivers", function(source, args)
	if args[1] ~= nil then
		local isfound = IsKussKultVehicle(args[1])
		local isfounddriver
		if isfound and args[2] ~= nil then
			SpawnDriversWithVehicle(args, source)
		else
			isfounddriver = IsKussKultCharacter(args[1])
			if isfounddriver then
				SpawnDriversWithMyCar(args, source)
			else
				TriggerClientEvent("CEv_ShowNotificationEvent", source, "Bitte gültiges Fahrzeug oder Fahrer angeben!")
			end
		end
	end
end, false)

---Test Command fürs Drivers Feature. Spawnt DunbysCruiser, welcher den Spieler eskortiert
RegisterCommand("gwspawntestdunby", function(source, args)
	local vector4 = GetEntityCoordsAndHeading(GetPlayerPed(source))
	CheckIfEntityIsKussKult(source, "OmaRoswita", PLAYER_VARIANT, true, vector4, "OmaRoswita")
	TriggerClientEvent("CEv_SpawnVehicle", source, "DunbysCruiser", vector4)
	CheckIfEntityIsKussKult(source, "MarionDunby", NEUTRAL_VARIANT, true, vector4, "MarionDunby")
	CheckIfEntityIsKussKult(source, "HudsonHudson", NEUTRAL_VARIANT, true, vector4, "MarionDunby")
	CheckIfEntityIsKussKult(source, "VladimirSmirnov", NEUTRAL_VARIANT, true, vector4, "MarionDunby")
	Wait(4000)
	local nowargs = {}
	nowargs[1] = "DunbysCruiser"
	nowargs[2] = "MarionDunby"
	nowargs[3] = "HudsonHudson"
	nowargs[4] = "VladimirSmirnov"
	DriversCreateFromArgs(source, nowargs)
	Wait(4000)
	nowargs[2] = "ESCORT"
	nowargs[3] = "OmaRoswita"
	DriversSetTaskFromArgs(source, nowargs)
end, false)

---Gibt dem Spieler die Schlüssel für das Fahrzeug in dem er sitzt
RegisterCommand("gwkeys", function(source, args)
	if GetResourceState('qbx_vehiclekeys') ~= 'started' then
		TriggerClientEvent("CEv_ShowNotificationEvent", source, "qbx_vehiclekeys ist nicht aktiv!")
		return
	end
	local ped = GetPlayerPed(source)
	local vehicle = GetVehiclePedIsIn(ped, false)
	if vehicle and vehicle ~= 0 then
		exports.qbx_vehiclekeys:GiveKeys(source, vehicle)
		TriggerClientEvent("CEv_ShowNotificationEvent", source, "~g~Fahrzeugschlüssel erhalten!")
	else
		TriggerClientEvent("CEv_ShowNotificationEvent", source, "~r~Du sitzt in keinem Fahrzeug!")
	end
end, false)

---Test Command fürs Drivers Feature. Spawnt ParkersPolicebike, welches Dunby in der Spielwelt eskortiert
RegisterCommand("gwspawntestparkers", function(source, args)
	local vector4 = GetEntityCoordsAndHeading(GetPlayerPed(source))
	TriggerClientEvent("CEv_SpawnVehicle", source, "ParkersPolicebike", vector4)
	CheckIfEntityIsKussKult(source, "MelanieParkers", NEUTRAL_VARIANT, true, vector4, "MelanieParkers")
	Wait(4000)
	local nowargs = {}
	nowargs[1] = "ParkersPolicebike"
	nowargs[2] = "MelanieParkers"
	DriversCreateFromArgs(source, nowargs)
	Wait(4000)
	nowargs[2] = "ESCORT"
	nowargs[3] = "MarionDunby"
	DriversSetTaskFromArgs(source, nowargs)
end, false)

ENTITYFOLDERRELATIVE = "./../"
CHARFOLDER = "characters"
VEHFOLDER = "vehicles"
VEHICLE_VARIANT = -1
PLAYER_VARIANT = 0
NEUTRAL_VARIANT = 1
FRIENDLY_VARIANT = 2
AGGRESSIVE_VARIANT = 3

NETWORK_ID_SYNC_DELAY = 1000
THRESHOLD_SPAWNING = 10

---Auflistung von allen Charakteren, Fahrzeugen und Unterteilung nach Skins
TableOfAllCharacters, TableOfAllCharactersLower = ListAllEntriesInFolder(CHARFOLDER)
TableOfAllVehicles, TableOfAllVehiclesLower = ListAllEntriesInFolder(VEHFOLDER)
TableOfAllCharacterSkins = CreateTableOfSkins(TableOfAllCharacters, CHARFOLDER)
TableOfAllVehicleSkins = CreateTableOfSkins(TableOfAllVehicles, VEHFOLDER)

TableOfAllDioramas = ListAllEntriesInFolder("dioramas")

---Index Tables und Tables mit Ziffernummerierung
TableOfAllCharactersIndexes = CreateIndexTable(TableOfAllCharacters)
TableOfAllVehiclesIndexes = CreateIndexTable(TableOfAllVehicles)
TableOfAllCharactersNumbered = CreateNumberedTable(TableOfAllCharacters)
TableOfAllVehiclesNumbered = CreateNumberedTable(TableOfAllVehicles)

---Alle aktiven Spieler
Players = {}
---Alle aktiven Charaktere
Characters = {}
---Alle aktiven Fahrzeuge
Vehicles = {}
---Fraktionen mit ihren Mitgliedern
FactionsAndMembers = {}
---Fraktionen und ihr jeweiliger Spieleranführer
FactionLeaders = {}

--SERVER EVENTS

---Zum Start der Resource werden alle Spieler mit Defaultwerten in die Player Gruppe mit aufgenommen
AddEventHandler("onServerResourceStart", function(resourceName)
    if resourceName == GetCurrentResourceName() then
        Citizen.Wait(NETWORK_ID_SYNC_DELAY)
        local onlinePlayers = GetPlayers()
        for _, serverID in ipairs(onlinePlayers) do
            local pedHandle = GetPlayerPed(serverID)
            local networkID = NetworkGetNetworkIdFromEntity(pedHandle)
            RegisterEntity(PLAYER_VARIANT, networkID, GetPlayerName(serverID), GetPlayerName(serverID),
                GetPlayerName(serverID))
        end
        TriggerClientEvent("CEvUI_InitialGWInfos", -1, TableOfAllCharacterSkins, TableOfAllVehicleSkins, AllFactions,
            Owners)
    end
end)

---Beim Beenden der Resource werden alle Charaktere und Fahrzeuge gelöscht
AddEventHandler("onResourceStop", function(resourceName)
    if resourceName == GetCurrentResourceName() then
        Citizen.Wait(NETWORK_ID_SYNC_DELAY)
        DropAllVehicles()
        DropAllCharacters()
    end
end)

---Beim Spawnen eines neuen Spielers wird dieser in die Player Gruppe mitaufgenommen und bekommt einen zufälligen Kuss Kult Charakter 
RegisterNetEvent("SEv_PlayerSpawned", function(source)
    print("Player spawned: " .. GetPlayerName(source))
    Citizen.Wait(NETWORK_ID_SYNC_DELAY)
    local pedHandle = GetPlayerPed(source)
    local networkID = NetworkGetNetworkIdFromEntity(pedHandle)
    RegisterEntity(PLAYER_VARIANT, networkID, GetPlayerName(source), GetPlayerName(source), GetPlayerName(source))
    OrganizeTableOfFactions()
    TriggerClientEvent("CEv_ShowNotificationEvent", -1 , "Ein neuer Spieler hat das Spiel betreten. Lade deinen Charakter mit /gwr neu, falls es Probleme gibt")
    TriggerClientEvent("CEvUI_InitialGWInfos", source, TableOfAllCharacterSkins, TableOfAllVehicleSkins, AllFactions)
    Citizen.Wait(NETWORK_ID_SYNC_DELAY)
    BecomeRandomKussKultCharacter(source)
end)

---Beim Verlassen eines Spielers wird dieser aus der Liste der Player gelöscht
AddEventHandler("playerDropped", function(source)
    PlayersGroupRemaking()
    OrganizeTableOfFactions()
end)

---Listet für den Spieler alle Aktiven auf
RegisterNetEvent("SEv_ListAll", function(source)
    ListAllActiveForClient(source)
end)

---Event zum prüfen, ob ein String zum Namen eines Kuss Kult Entities passt
RegisterNetEvent("SEv_CheckIfEntityIsKussKult", function(input, variant, hasWeapon, vector4, faction)
    if faction == "PLAYER" then
        faction = GetPlayerFactionFromSource(source)
    end
    CheckIfEntityIsKussKult(source, input, variant, hasWeapon, vector4, faction)
end)

---Event zum Prüfen ob ein String eine valide Fraktion ist
RegisterNetEvent("SEv_CheckIfFactionIsKussKult",
    function(source, factionName, factionVariant, hasWeapon, vector4, exceptionTarget)
        CheckIfFactionIsKussKult(source, factionName, factionVariant, hasWeapon, vector4, exceptionTarget)
    end)

---Event um einem Charakter dessen Skin und Fraktion zu geben
RegisterNetEvent("SEv_GiveCharacterSkinAndFaction", function(variant, name, hasWeapon, faction, networkID, source)
    local skin = GetStandardSpellingOfName(name, TableOfAllCharactersLower, TableOfAllCharacters,
        TableOfAllCharactersIndexes)
    name = LookforRootNameOfSkin(TableOfAllCharacterSkins, skin)
    if string.lower(faction) == string.lower(skin) then
        faction = name
    end
    if variant == PLAYER_VARIANT then
        ChangePlayerFaction(networkID, variant, name, skin, faction)
    else
        RegisterEntity(variant, networkID, name, skin, faction)
    end
    OrganizeTableOfFactions()
    Citizen.Wait(NETWORK_ID_SYNC_DELAY)
    TriggerClientEvent("CEv_GiveCharacterSkinAndRole", -1, networkID, skin, hasWeapon, source, variant,
        FactionsAndMembers, FactionLeaders, Players)
end)

---Event um mehreren Charakteren ihren Skin und Fraktion zu geben
RegisterNetEvent("SEv_GiveMultipleCharactersSkinAndFaction", function(GroupNetwork, variant, hasWeapon, faction, source)
    local skin = nil
    local name = nil
    for _, character in pairs(GroupNetwork) do
        skin = GetStandardSpellingOfName(character.name, TableOfAllCharactersLower, TableOfAllCharacters,
            TableOfAllCharactersIndexes)
        name = LookforRootNameOfSkin(TableOfAllCharacterSkins, skin)
        RegisterEntity(variant, character.networkID, name, skin, faction)
    end
    OrganizeTableOfFactions()
    Citizen.Wait(NETWORK_ID_SYNC_DELAY)
    TriggerClientEvent("CEv_GiveMultipleCharactersSkinAndRole", -1, GroupNetwork, hasWeapon, source, variant,
        FactionsAndMembers, FactionLeaders, Players)
end)

---Event um mehreren Charakten in einem Diorama ihren Skin und ihre entsprechende Fraktion zu geben
RegisterNetEvent("SEv_GiveMultipleCharactersSkinAndFactionDiorama",
    function(GroupNetwork, variant, hasWeapon, faction, source)
        local skin = nil
        local name = nil
        local tableOffset = 1
        for _, character in pairs(GroupNetwork) do
            skin = GetStandardSpellingOfName(character.name, TableOfAllCharactersLower, TableOfAllCharacters,
                TableOfAllCharactersIndexes)
            name = LookforRootNameOfSkin(TableOfAllCharacterSkins, skin)
            if variant == FRIENDLY_VARIANT then
                RegisterEntity(variant, character.networkID, name, skin, GetPlayerFactionFromSource(source))
            else
                RegisterEntity(variant, character.networkID, name, skin, faction[character.name])
            end
            tableOffset = tableOffset + 1
        end
        OrganizeTableOfFactions()
        Citizen.Wait(NETWORK_ID_SYNC_DELAY)
        TriggerClientEvent("CEv_GiveMultipleCharactersSkinAndRole", -1, GroupNetwork, hasWeapon, source, variant,
            FactionsAndMembers, FactionLeaders, Players)
    end)

---Registriert ein Kuss Kult Fahrzeug in der Fahrzeug Gruppe
RegisterNetEvent("SEv_RegisterVehicle", function(name, networkID)
    local skin = GetStandardSpellingOfName(name, TableOfAllVehiclesLower, TableOfAllVehicles, TableOfAllVehiclesIndexes)
    name = LookforRootNameOfSkin(TableOfAllVehicleSkins, skin)
    RegisterEntity(VEHICLE_VARIANT, networkID, name, skin, nil)
end)

---Registriert mehrere Kuss Kult Fahrzeuge in der Fahrzeug Gruppe
RegisterNetEvent("SEv_RegisterMultipleVehicles", function(GroupNetwork)
    for _, vehicle in pairs(GroupNetwork) do
        local skin = GetStandardSpellingOfName(vehicle.name, TableOfAllVehiclesLower, TableOfAllVehicles,
            TableOfAllVehiclesIndexes)
        local name = LookforRootNameOfSkin(TableOfAllVehicleSkins, skin)
        RegisterEntity(VEHICLE_VARIANT, vehicle.networkID, name, skin, nil)
    end
end)

---Stoppt alle aktiven Kuss Kult Charaktere
RegisterNetEvent("SEv_StopAllCharacters", function(source)
    StopAllCharacters(source)
end)

---Event um bei einem Client das Geile Wholeplay Skript Menü mit den aktiven Daten zu öffnen
RegisterNetEvent("SEv_OpenMenu", function(source)
    TriggerClientEvent("CEvUI_OpenMenu", source, Players, Characters, Vehicles,
        Players[GetNetworkIDPlayerFromSource(source)].name, TableOfAllDioramas)
end)

---Event um die aktiven Server Daten erneut an den Client zu schicken
RegisterNetEvent("SEv_RequestMenuData", function(source)
    TriggerClientEvent("CEvUI_InitialGWInfos", source, TableOfAllCharacterSkins, TableOfAllVehicleSkins, AllFactions, Owners)
end)

---Event um einem Spieler das Fahrzeug seines Kuss Kult Charakters zu spawnen
RegisterNetEvent("SEv_SpawnMyCar", function(source)
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
end)

---Event um den Spieler mit seiner eventuellen vorhandenen Fraktion zu teleportieren
RegisterNetEvent("SEv_TeleportPlayer", function(source, coords, heading)
    local networkID = GetNetworkIDPlayerFromSource(source)
    Group = FactionsAndMembers[Players[networkID].faction]
    TriggerClientEvent("CEv_TeleportThePlayer", source, source, Group, coords, heading)
    TeleportMultiple(Group, coords, heading)
end)

---Event um die Fraktion eines Spielers zu ändern und die aller Fraktionsangehörigen
RegisterNetEvent("SEv_UpdatePlayerFaction", function(source, newFaction)
    local networkId = GetNetworkIDPlayerFromSource(source)
    local name = Players[networkId].name
    local skin = Players[networkId].skin
    if newFaction == "DEFAULT" then
        newFaction = name
    end
    ChangePlayerFaction(networkId, PLAYER_VARIANT, name, skin, newFaction)
    OrganizeTableOfFactions()
    TriggerClientEvent("CEv_Regroup", -1, FactionsAndMembers, FactionLeaders, Players)
end)

---Event zum Löschen eines Kuss Kult Entities
RegisterNetEvent("SEv_DeleteEntity", function(source, entity)
    DropSpecificEntityByName(entity, source)
end)

---Event zum Löschen eines Kuss Kult Entities anhand der NetworkID
RegisterNetEvent("SEv_DeleteEntityByNetworkID", function(source, entity, variant)
    DropSpecificEntityByNetworkID(entity, variant)
end)

---Event um den Garbage Cleaner Check durchzuführen
RegisterNetEvent("SEv_DeadGarbageCleaner", function(deadCharacters, deadVehicles)
    DeadGarbageCleanerCleaning(deadCharacters, deadVehicles)
end)

---Speichert den Kuss Kult Charakter in einer Datei ab
RegisterNetEvent("SEv_SaveEntityInFile", function(fileName, fileData)
    if TableOfAllCharactersLower[string.lower(fileName)] == nil then
        SaveResourceFile(GetCurrentResourceName(), "server/" .. fileName .. ".json", json.encode(fileData), -1)
    else
        TriggerClientEvent("CEv_ShowNotificationEvent", source, "~r~Diesen Charakter gibt es schon!")
    end
end)

---Event um die Gesinnung eines Kuss Kult Charakters zum Spieler zu ändern
RegisterNetEvent("SEv_ChangeCharacterAttitude", function(source, variant, name)
    if variant == NEUTRAL_VARIANT then
        TurnVariantToNeutral(name, source)
    elseif variant == FRIENDLY_VARIANT then
        TurnVariantToFriendly(name, source)
    elseif variant == AGGRESSIVE_VARIANT then
        TurnVariantToAggressive(name, source)
    end
end)

---Event um mehrere Kuss Kult Charaktere zu teleportieren
RegisterNetEvent("SEv_RelocateCharacter", function(source, Group, coords, heading)
    TeleportMultiple(Group, coords, heading)
end)

---Event um ein Diorama zu platzieren
RegisterNetEvent("SEv_PlaceDiorama", function (name, source)
    if name ~= nil then
		local diorama = Looker(name, "dioramas")
		if diorama ~= nil then
			local charactergroup, charactervectors, vehiclegroup, vehiclevectors, faction, weaponPossession = ExtractTablesOfDiorama(diorama)
			if nil ~= nil then
				TriggerClientEvent("CEv_SpawnMultipleCharactersDiorama", source, charactergroup, GetVariantFromInput(args[2]),
				weaponPossession,
				charactervectors, faction)
			else
				TriggerClientEvent("CEv_SpawnMultipleCharactersDiorama", source, charactergroup, NEUTRAL_VARIANT,
				weaponPossession,
				charactervectors, faction)
			end
			TriggerClientEvent("CEv_SpawnMultipleVehicles", source, vehiclegroup, vehiclevectors)
			TriggerClientEvent("CEv_ShowNotificationEvent", source, "Diorama " .. name .. " erfolgreich platziert")
		else
			TriggerClientEvent("CEv_ShowNotificationEvent", source, name .. " ist kein Diorama!")
		end
	end

end)
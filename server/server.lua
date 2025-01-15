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
BPS = 65536

KUSS_KULT_GAMES = {
    KUSS_KULT_KNOCKOUT = 0,
    TWOUBLE_IN_KUSS_KULT = 1
}
RunningKussKultGame = nil

RespondToDriversInforms = true

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
--Zuordnungen von Fahrzeugen und ihren NPC-Fahrern und -Passagieren
Drivers = {}
--Die Handlungen von den Fahrgemeinschaften, die sie in der Spielwelt ausüben sollen
DriversTask = {}
--Driversliste sortiert nach den Passagieren
DriversByPassengers = {}
--Zuordnungen der Spieler wer welchen DriversTask hostet
DriversTaskHost = {}

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
        TriggerLatentClientEvent("CEvUI_InitialGWInfos", -1, BPS, TableOfAllCharacterSkins, TableOfAllVehicleSkins,
            AllFactions,
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
    --TriggerClientEvent("CEv_ShowNotificationEvent", -1 , "Ein neuer Spieler ist beigetreten. Lade deinen Charakter mit /gwr neu, falls es Probleme gibt")
    TriggerLatentClientEvent("CEvUI_InitialGWInfos", source, BPS, TableOfAllCharacterSkins, TableOfAllVehicleSkins,
        AllFactions)
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
        local driversTargets = DriversWhereIsPedNetTarget(networkID)
        for _, vehNet in pairs(driversTargets) do
            local tempDriversTask = DriversTask[vehNet]
            tempDriversTask.targetNet = networkID
            DriversTask[vehNet] = nil
            DriversTask[vehNet] = tempDriversTask
        end
    else
        RegisterEntity(variant, networkID, name, skin, faction)
    end
    OrganizeTableOfFactions()
    Citizen.Wait(NETWORK_ID_SYNC_DELAY)
    TriggerClientEvent("CEv_GiveCharacterSkinAndRole", -1, networkID, skin, hasWeapon, source, variant,
        FactionsAndMembers, FactionLeaders, Players, GetDriversInfo())
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
    TriggerLatentClientEvent("CEv_GiveMultipleCharactersSkinAndRole", -1, BPS, GroupNetwork, hasWeapon, source, variant,
        FactionsAndMembers, FactionLeaders, Players, GetDriversInfo())
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
        TriggerLatentClientEvent("CEv_GiveMultipleCharactersSkinAndRole", -1, BPS, GroupNetwork, hasWeapon, source,
            variant,
            FactionsAndMembers, FactionLeaders, Players, GetDriversInfo())
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
    TriggerLatentClientEvent("CEvUI_OpenMenu", source, BPS, Players, Characters, Vehicles,
        Players[GetNetworkIDPlayerFromSource(source)].name, TableOfAllDioramas)
end)

---Event um die aktiven Server Daten erneut an den Client zu schicken
RegisterNetEvent("SEv_RequestMenuData", function(source)
    TriggerLatentClientEvent("CEvUI_InitialGWInfos", source, BPS, TableOfAllCharacterSkins, TableOfAllVehicleSkins,
        AllFactions, Owners)
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
    TriggerClientEvent("CEv_Regroup", -1, FactionsAndMembers, FactionLeaders, Players, GetDriversInfo())
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
RegisterNetEvent("SEv_PlaceDiorama", function(name, source)
    if name ~= nil then
        local diorama = Looker(name, "dioramas")
        if diorama ~= nil then
            local charactergroup, charactervectors, vehiclegroup, vehiclevectors, faction, weaponPossession =
                ExtractTablesOfDiorama(diorama)
            if nil ~= nil then
                TriggerLatentClientEvent("CEv_SpawnMultipleCharactersDiorama", source, BPS, charactergroup,
                    GetVariantFromInput(args[2]),
                    weaponPossession,
                    charactervectors, faction)
            else
                TriggerLatentClientEvent("CEv_SpawnMultipleCharactersDiorama", source, BPS, charactergroup,
                    NEUTRAL_VARIANT,
                    weaponPossession,
                    charactervectors, faction)
            end
            TriggerLatentClientEvent("CEv_SpawnMultipleVehicles", source, BPS, vehiclegroup, vehiclevectors)
            TriggerClientEvent("CEv_ShowNotificationEvent", source, "Diorama " .. name .. " erfolgreich platziert")
        else
            TriggerClientEvent("CEv_ShowNotificationEvent", source, name .. " ist kein Diorama!")
        end
    end
end)

RegisterNetEvent("SEv_TwoubleDeathHandler")

---Event um die die Kontrolle von einem Spieler auf einen NPC in der Welt zu wechseln
RegisterNetEvent("SEv_SwitchCharacters",
	function(source, targetCharacter, sourceCharacter, targetFeatures, sourceFeatures, newTargetNet)
		if TryForNetworkIDAvailabilityServer(newTargetNet) then
			local sourceHandle = NetworkGetEntityFromNetworkId(sourceCharacter.networkID)
			local targetHandle = NetworkGetEntityFromNetworkId(newTargetNet)
			RespondToDriversInforms = false
			DeleteEntity(NetworkGetEntityFromNetworkId(targetCharacter.networkID))
			local sourceCoords = targetFeatures["vector4"]["coords"]
			--Source ins eventuelle Fahrzeug des alten targetCharacter setzen oder andernfalls an die Position von diesem
			if targetFeatures["vehicle"] ~= nil then
					TaskWarpPedIntoVehicle(sourceHandle, NetworkGetEntityFromNetworkId(targetFeatures["vehicle"]), targetFeatures["seatIndex"])
				--	Citizen.Await(AwaitUntilPedEnteredVehicle(sourceHandle, NetworkGetEntityFromNetworkId(targetFeatures["vehicle"])))
			else
				SetEntityCoords(sourceHandle, sourceCoords.x, sourceCoords.y, sourceCoords.z, true, false, false, false)
				SetEntityHeading(sourceHandle, targetFeatures["vector4"]["heading"])
			end
			--Neuen TargetCharakter in das eventuelle Fahrzeug der Source setzen
			if sourceFeatures["vehicle"] ~= nil then
				TaskWarpPedIntoVehicle(targetHandle, NetworkGetEntityFromNetworkId(sourceFeatures["vehicle"]),
					sourceFeatures["seatIndex"])
				Citizen.Await(AwaitUntilPedEnteredVehicle(targetHandle,
					NetworkGetEntityFromNetworkId(sourceFeatures["vehicle"])))
			end
			Characters[targetCharacter.networkID] = nil
			RegisterEntity(NEUTRAL_VARIANT, newTargetNet, sourceCharacter.name, sourceCharacter.skin,
				sourceCharacter.faction)
			RegisterEntity(PLAYER_VARIANT, sourceCharacter.networkID, targetCharacter.name, targetCharacter.skin,
				targetCharacter.faction)
			--Anführer der Source Fraktion wird entfernt
			if FactionLeaders[sourceCharacter.faction] == sourceCharacter.networkID then
				FactionLeaders[sourceCharacter.faction] = nil
			end
			--Anführer der Target Fraktion wird auf den Source gesetzt
			FactionLeaders[targetCharacter.faction] = sourceCharacter.networkID
			local driversTargetsWhereSourceChar = DriversWhereIsPedNetTarget(sourceCharacter.networkID)
			local driversTargetsWhereTargetChar = DriversWhereIsPedNetTarget(targetCharacter.networkID)
			for _, vehNet in pairs(driversTargetsWhereSourceChar) do
				local tempDriversTask = DriversTask[vehNet]
				tempDriversTask.targetNet = newTargetNet
				DriversTask[vehNet] = nil
				DriversTask[vehNet] = tempDriversTask
			end
			for _, vehNet in pairs(driversTargetsWhereTargetChar) do
				local tempDriversTask = DriversTask[vehNet]
				tempDriversTask.targetNet = sourceCharacter.networkID
				DriversTask[vehNet] = nil
				DriversTask[vehNet] = tempDriversTask
			end
			--Drivers Fahrgemeinschaft im ehemaligen Fahrzeug der Source erzeugen
			if sourceFeatures["vehicle"] then
				local passengersUpdatedIndexes = {}
				for i = -1, sourceFeatures["vehicleCapacity"], 1 do
					if Characters[sourceFeatures["vehiclePassengers"][i]] then
						passengersUpdatedIndexes[i + 2] = sourceFeatures["vehiclePassengers"][i]
					end
				end
				passengersUpdatedIndexes[sourceFeatures["seatIndex"] + 2] = newTargetNet
				DriversCreateCarpool(sourceFeatures["vehicle"], passengersUpdatedIndexes,
					sourceFeatures["vehicleCapacity"], source)
			end
			--Fahrgemeinschaft des Targets auflösen (Falls Fahrer war) oder aus Fahrgemeinschaft entfernen (Wenn Mitfahrer war)
			if targetFeatures["vehicle"] then
				if targetFeatures["seatIndex"] == -1 then
					DriversDropCheckVehicle(targetFeatures["vehicle"])
				else
					local tempPassengers = ExcludeEntryOfTable(Drivers[targetFeatures["vehicle"]],
						targetCharacter.networkID)
						local tempPassengersUpdatedIndexes = {}
						for i = -1, targetFeatures["vehicleCapacity"], 1 do
							if Characters[tempPassengers[i]] then
								tempPassengersUpdatedIndexes[i + 2] = tempPassengers[i]
							end
						end
					DriversUpdateCarpool(targetFeatures["vehicle"], tempPassengersUpdatedIndexes, source)
				end
			end
			OrganizeTableOfFactions()
			RespondToDriversInforms = true
			TriggerLatentClientEvent("CEv_GiveCharacterSkinAndRole", -1, BPS, newTargetNet, sourceCharacter.skin, true,
				source, PLAYER_VARIANT, FactionsAndMembers, FactionLeaders, Players, GetDriversInfo())
			TriggerClientEvent("CEv_ApplySwitchFeatures", -1, targetFeatures, sourceFeatures, newTargetNet,
				sourceCharacter.networkID)
		end
	end)

---Event um über den Fahrzeugverlust einer Fahrgemeinschaft informiert zu werden
RegisterNetEvent("SEv_InformThatDriversCarIsGone", function(vehNet, source)
    if RespondToDriversInforms then
        DriversDropCheckVehicle(vehNet)
        TriggerClientEvent("CEv_Regroup", source, FactionsAndMembers, FactionLeaders, Players, GetDriversInfo())
    end
end)

---Event um über den Passagierverlust einer Fahrgemeinschaft informiert zu werden
RegisterNetEvent("SEv_InformThatDriversPedIsGone", function(pedNet, source)
    if RespondToDriversInforms then
        DriversDropCheckPed(pedNet)
        TriggerClientEvent("CEv_Regroup", source, FactionsAndMembers, FactionLeaders, Players, GetDriversInfo())
    end
end)

---Event um über den Zielverfolgungscharakterverlust einer Fahrgemeinschaft informiert zu werden
RegisterNetEvent("SEv_InformThatDriversTargetIsGone", function(vehNet, source, targetNet)
    if not Players[targetNet] then
        DriversTask[vehNet] = DRIVERS_TASK.NONE
        TriggerClientEvent("CEv_Regroup", source, FactionsAndMembers, FactionLeaders, Players, GetDriversInfo())
    else
        Wait(NETWORK_ID_SYNC_DELAY)
    end
end)

---Event um direkt ein Fahrzeug mitsamt Charakteren für eine Fahrgemeinschaft zu registrieren
RegisterNetEvent("SEv_RegisterVehicleAndCharactersForDrivers", function(vehicle, GroupNetwork, capacity, source)
    local vehSkin = GetStandardSpellingOfName(vehicle.name, TableOfAllVehiclesLower, TableOfAllVehicles,
        TableOfAllVehiclesIndexes)
    local vehName = LookforRootNameOfSkin(TableOfAllVehicleSkins, vehSkin)
    RegisterEntity(VEHICLE_VARIANT, vehicle.networkID, vehName, vehSkin, nil)
    local characterSkin
    local characterName
    local carpoolGroup = {}
    for seatIndex, character in pairs(GroupNetwork) do
        characterSkin = GetStandardSpellingOfName(character.name, TableOfAllCharactersLower, TableOfAllCharacters,
            TableOfAllCharactersIndexes)
        characterName = LookforRootNameOfSkin(TableOfAllCharacterSkins, characterSkin)
        RegisterEntity(NEUTRAL_VARIANT, character.networkID, characterName, characterSkin, character.faction)
        carpoolGroup[seatIndex+2] = character.networkID
    end
    OrganizeTableOfFactions()
    Citizen.Wait(NETWORK_ID_SYNC_DELAY)
    DriversCreateCarpool(vehicle.networkID, carpoolGroup, capacity, source)
    TriggerLatentClientEvent("CEv_GiveMultipleCharactersSkinAndRole", -1, BPS, GroupNetwork, true, source,
        NEUTRAL_VARIANT,
        FactionsAndMembers, FactionLeaders, Players, GetDriversInfo())
end)
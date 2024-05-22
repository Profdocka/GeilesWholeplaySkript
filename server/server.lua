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

TableOfAllCharacters, TableOfAllCharactersLower = ListAllEntriesInFolder(CHARFOLDER)
TableOfAllVehicles, TableOfAllVehiclesLower = ListAllEntriesInFolder(VEHFOLDER)
TableOfAllCharacterSkins = CreateTableOfSkins(TableOfAllCharacters, CHARFOLDER)
TableOfAllVehicleSkins = CreateTableOfSkins(TableOfAllVehicles, VEHFOLDER)

--PrintAllMembersOfTable(TableOfAllCharacterSkins)

TableOfAllCharactersIndexes = CreateIndexTable(TableOfAllCharacters)
TableOfAllVehiclesIndexes = CreateIndexTable(TableOfAllVehicles)
TableOfAllCharactersNumbered = CreateNumberedTable(TableOfAllCharacters)
TableOfAllVehiclesNumbered = CreateNumberedTable(TableOfAllVehicles)

Players = {}
Characters = {}
Vehicles = {}
FactionsAndMembers = {}
FactionLeaders = {}

--SERVER EVENTS

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

AddEventHandler("onResourceStop", function(resourceName)
    if resourceName == GetCurrentResourceName() then
        Citizen.Wait(NETWORK_ID_SYNC_DELAY)
        DropAllVehicles()
        DropAllCharacters()
    end
end)

RegisterNetEvent("SEv_PlayerSpawned", function(source)
    print("Player spawned: " .. GetPlayerName(source))
    Citizen.Wait(NETWORK_ID_SYNC_DELAY)
    local pedHandle = GetPlayerPed(source)

    local networkID = NetworkGetNetworkIdFromEntity(pedHandle)

    RegisterEntity(PLAYER_VARIANT, networkID, GetPlayerName(source), GetPlayerName(source), GetPlayerName(source))

    OrganizeTableOfFactions()
    --ReapplyPlayerCharacters wird VORERST entfernt!!!
    --ReapplyPlayerCharacters("Neuer Spieler betritt das Spiel. Dein Charakter wird neu geladen.")
    TriggerClientEvent("CEvUI_InitialGWInfos", source, TableOfAllCharacterSkins, TableOfAllVehicleSkins, AllFactions)
    
    Citizen.Wait(NETWORK_ID_SYNC_DELAY)
    BecomeRandomKussKultCharacter(source)
    --TriggerClientEvent("CEv_Regroup", -1, FactionsAndMembers, FactionLeaders, Players)
end)

AddEventHandler("playerDropped", function(source)
    --local _source = source
    --local playerHandle = GetPlayerPed(_source)
    --local networkID = GetNetworkIDPlayerFromSource(_source)

    PlayersGroupRemaking()
    --print("Die zu löschende Eintragung: ", networkID)
    --Players[networkID] = nil
    --Players[networkID] = Players[networkID]
    --table.remove(Players, networkID)

    OrganizeTableOfFactions()
    --ReapplyPlayerCharacters("Ein Spieler hat das Spiel verlassen. Dein Charakter wird neu geladen.")
    --TriggerClientEvent("CEv_Regroup", -1, FactionsAndMembers, FactionLeaders, Players)
end)

RegisterNetEvent("SEv_ListAll", function(source)
    ListAllActiveForClient(source)
end)

RegisterNetEvent("SEv_CheckIfEntityIsKussKult", function(input, variant, hasWeapon, vector4, faction)
    --print("Neues Objekt. Variante: ", variant, " Faction: ", faction)
    if faction == "PLAYER" then
        faction = GetPlayerFactionFromSource(source)
        --print("Neue Faction: ", faction)
    end
    CheckIfEntityIsKussKult(source, input, variant, hasWeapon, vector4, faction)
end)

RegisterNetEvent("SEv_CheckIfFactionIsKussKult",
    function(source, factionName, factionVariant, hasWeapon, vector4, exceptionTarget)
        CheckIfFactionIsKussKult(source, factionName, factionVariant, hasWeapon, vector4, exceptionTarget)
    end)

RegisterNetEvent("SEv_GiveCharacterSkinAndFaction", function(variant, name, hasWeapon, faction, networkID, source)
    local skin = GetStandardSpellingOfName(name, TableOfAllCharactersLower, TableOfAllCharacters,
        TableOfAllCharactersIndexes)
    --print("Der Skin richtig geschrieben: " .. skin)
    --print(TableOfAllCharacterSkins)
    name = LookforRootNameOfSkin(TableOfAllCharacterSkins, skin)
    if string.lower(faction) == string.lower(skin) then
        faction = name
    end
    if variant == PLAYER_VARIANT then
        local oldFaction = Players[networkID].faction
        RegisterEntity(variant, networkID, name, skin, faction)
        FactionLeaders[oldFaction] = nil
        FactionLeaders[faction] = networkID
        UpdateFaction(networkID, oldFaction, faction)
    else
        RegisterEntity(variant, networkID, name, skin, faction)
    end
    OrganizeTableOfFactions()
    Citizen.Wait(NETWORK_ID_SYNC_DELAY)
    TriggerClientEvent("CEv_GiveCharacterSkinAndRole", -1, networkID, skin, hasWeapon, source, variant,
        FactionsAndMembers, FactionLeaders, Players)
end)

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

RegisterNetEvent("SEv_RegisterVehicle", function(name, networkID)
    local skin = GetStandardSpellingOfName(name, TableOfAllVehiclesLower, TableOfAllVehicles, TableOfAllVehiclesIndexes)
    name = LookforRootNameOfSkin(TableOfAllVehicleSkins, skin)
    RegisterEntity(VEHICLE_VARIANT, networkID, name, skin, nil)
end)

RegisterNetEvent("SEv_StopAllCharacters", function(source)
    StopAllCharacters(source)
end)

RegisterNetEvent("SEv_OpenMenu", function(source)
    TriggerClientEvent("CEvUI_OpenMenu", source, Players, Characters, Vehicles,
        Players[GetNetworkIDPlayerFromSource(source)].name)
end)

RegisterNetEvent("SEv_RequestMenuData", function(source)
    TriggerClientEvent("CEvUI_InitialGWInfos", -1, TableOfAllCharacterSkins, TableOfAllVehicleSkins, AllFactions, Owners)
end)

RegisterNetEvent("SEv_SpawnMyCar", function(source)
    local index = NetworkGetNetworkIdFromEntity(GetPlayerPed(source))
    local characterName = Players[index].name
    characterName = ReplaceUmlaute(characterName)
    characterName = string.lower(characterName)
    local ownerString = Owners[characterName]
    if ownerString ~= nil then
        local vehicleString = ownerString[1]
        TriggerClientEvent("CEv_SpawnVehicle", source, vehicleString, index);
    else
        TriggerClientEvent("CEv_ShowNotificationEvent", source, "Dieser Charakter besitzt kein Fahrzeug!")
    end
end)

RegisterNetEvent("SEv_TeleportPlayer", function (source, coords, heading)
    local networkID = GetNetworkIDPlayerFromSource(source)
    Group = FactionsAndMembers[Players[networkID].faction]
    TriggerClientEvent("CEv_TeleportThePlayer", source, source, Group, coords, heading)
    TeleportMultiple(Group, coords, heading)
end)

RegisterNetEvent("SEv_ReapplyFactionRequestedByClient", function (source)
    OrganizeTableOfFactions()
    TriggerClientEvent("CEv_Regroup", -1, FactionsAndMembers, FactionLeaders, Players)
end)

RegisterNetEvent("SEv_DeleteEntity", function (source, entity)
    DropSpecificEntityByName(entity, source)
end)

RegisterNetEvent("SEv_DeadGarbageCleaner", function (deadCharacters, deadVehicles)
    DeadGarbageCleanerCleaning(deadCharacters, deadVehicles)
end)

RegisterNetEvent("SEv_SaveEntityInFile", function (fileName, fileData)
    if TableOfAllCharactersLower[string.lower(fileName)] == nil then
        SaveResourceFile(GetCurrentResourceName(), "server/" .. fileName .. ".json", json.encode(fileData), -1)
    else
        TriggerClientEvent("CEv_ShowNotificationEvent", source, "~r~Diesen Charakter gibt es schon!")
    end
end)

RegisterNetEvent("SEv_ChangeCharacterAttitude", function (source, variant, name)
    if variant == NEUTRAL_VARIANT then
        TurnVariantToNeutral(name, source)
    elseif variant == FRIENDLY_VARIANT then
        TurnVariantToFriendly(name, source)
    elseif variant == AGGRESSIVE_VARIANT then
        TurnVariantToAggressive(name, source)
    end
end)

RegisterNetEvent("SEv_RelocateCharacter", function (source, Group, coords, heading)
    TeleportMultiple(Group, coords, heading)
end)
ENTITYFOLDERRELATIVE = "./../"
CHARFOLDER = "characters"
VEHFOLDER = "vehicles"
VEHICLE_VARIANT = -1
PLAYER_VARIANT = 0
NEUTRAL_VARIANT = 1
FRIENDLY_VARIANT = 2
AGGRESSIVE_VARIANT = 3

NETWORK_ID_SYNC_DELAY = 1000

TableOfAllCharacters, TableOfAllCharactersLower = ListAllEntriesInFolder(CHARFOLDER)
TableOfAllVehicles, TableOfAllVehiclesLower = ListAllEntriesInFolder(VEHFOLDER)
TableOfAllCharacterSkins = CreateTableOfSkins(TableOfAllCharacters, CHARFOLDER)
TableOfAllVehicleSkins = CreateTableOfSkins(TableOfAllVehicles, VEHFOLDER)

TableOfAllCharactersIndexes = CreateIndexTable(TableOfAllCharactersLower)
TableOfAllVehiclesIndexes = CreateIndexTable(TableOfAllVehiclesLower)

Players = {}
Characters = {}
Vehicles = {}
FactionsAndMembers = {}
FactionLeaders = {}

--SERVER EVENTS

RegisterNetEvent("SEv_CheckIfEntityIsKussKult", function(source, input, variant, hasWeapon, vector4, faction)
    CheckIfEntityIsKussKult(source, input, variant, hasWeapon, vector4, faction)
end)

RegisterNetEvent("SEv_GiveCharacterSkinAndFaction", function(variant, name, hasWeapon, faction, networkID)
    local skin = GetStandardSpellingOfName(name, TableOfAllCharactersIndexes, TableOfAllCharacters)
    name = LookforRootNameOfSkin(TableOfAllCharacterSkins, skin)
    if variant == PLAYER_VARIANT then
        local oldFaction = Players[networkID].faction
        RegisterEntity(variant, networkID, name, skin, faction)
        FactionLeaders[oldFaction] = nil
        FactionLeaders[faction] = networkID
        UpdateFaction(oldFaction, faction)
    else
        RegisterEntity(variant, networkID, name, skin, faction)
    end
    OrganizeTableOfFactions()
    Citizen.Wait(NETWORK_ID_SYNC_DELAY)
    TriggerClientEvent("CEv_GiveCharacterSkinAndRole", -1, networkID, skin, hasWeapon, source, variant,
        FactionsAndMembers, FactionLeaders)
end)

RegisterNetEvent("SEv_GiveMultipleCharactersSkinAndFaction", function (GroupNetwork, variant, hasWeapon, faction)
    local skin = nil
    local name = nil
    for _, character in ipairs(GroupNetwork) do
        skin = GetStandardSpellingOfName(character.name, TableOfAllCharactersIndexes, TableOfAllCharacters)
        name = LookforRootNameOfSkin(TableOfAllCharacterSkins, skin)
        RegisterEntity(variant, character.networkID, name, skin, faction)
    end
    OrganizeTableOfFactions()
    Citizen.Wait(NETWORK_ID_SYNC_DELAY)
    TriggerClientEvent("CEv_GiveMultipleCharactersSkinAndRole", -1, GroupNetwork, hasWeapon, source, variant, FactionsAndMembers, FactionLeaders)
end)

RegisterNetEvent("SEv_RegisterVehicle", function(name, networkID)
    local skin = GetStandardSpellingOfName(name, TableOfAllVehiclesIndexes, TableOfAllVehicles)
    name = LookforRootNameOfSkin(TableOfAllVehicleSkins, skin)
    RegisterEntity(VEHICLE_VARIANT, networkID, name, skin, nil)
end)

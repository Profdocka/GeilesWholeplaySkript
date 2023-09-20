CHARFOLDER = "./../characters"
VEHFOLDER = "./../vehicles"
VEHICLE_VARIANT = -1
PLAYER_VARIANT = 0
NEUTRAL_VARIANT = 1

NETWORK_ID_SYNC_DELAY = 1000

Charakter = { networkID = 0, name = "JohnDoe", skin = "JohnDoe", faction = "Citizen" }
Vehikel = { networkID = 1, name = "Sedan", skin = "blackSedan" }


TableOfAllCharacters, TableOfAllCharactersLower = ListAllEntriesInFolder("characters")
TableOfAllVehicles, TableOfAllVehiclesLower = ListAllEntriesInFolder("vehicles")
TableOfAllCharacterSkins = CreateTableOfSkins(TableOfAllCharacters, "characters")
TableOfAllVehicleSkins = CreateTableOfSkins(TableOfAllVehicles, "vehicles")

Players = {}
Characters = {}
Vehicles = {}
FactionsAndMembers = {}
FactionLeaders = {}

--CheckIfCharacterExists
--CheckIfVehicleExists
--DecideWhatToSpawn

RegisterNetEvent("SEv_CheckIfEntityIsKussKult", CheckIfEntityIsKussKult(source, input, variant, hasWeapon, vector4, faction))

CheckIfEntityIsKussKult = function(source, input, variant, hasWeapon, vector4, faction)
    if IsKussKultCharacter(input) then
        TriggerClientEvent("CEv_SpawnCharacter", source, variant, input, hasWeapon, vector4, faction)
    elseif IsKussKultVehicle(input) then
        return true
    else
        TriggerClientEvent("CEv_ShowNotificationEvent", source,
            "~r~" + input + " existiert nicht im Kuss Kult Universum!")
    end
end

IsKussKultCharacter = function(input)
    input = string.lower(input)
    if TableOfAllCharactersLower[input] ~= nil then
        return true
    else
        return false
    end
end

IsKussKultVehicle = function(input)
    input = string.lower(input)
    if TableOfAllVehiclesLower[input] ~= nil then
        return true
    else
        return false
    end
end

Checker = function(input, folder)
    --local path = folder .. "/" .. input .. ".json"
    local entityName = TableOfAllCharacters[input]
    if entityName ~= nil then
        return entityName
    else
        entityName = TableOfAllVehicles[input]
        if entityName ~= nil then
            return entityName
        end
    end

    return nil
end

ListAllEntriesInFolder = function(folder)
    local resourcePath = GetResourcePath(GetCurrentResourceName()) + "/" + folder + "/"
    local filenames = {}
    local filesnamesLower = {}

    for filename in io.popen('dir "' .. resourcePath .. '" /b'):lines() do
        if filename:match("%.json$") then
            filename = filename:gsub("%.json$", "")
            table.insert(filenames, filename)
            local filenameLower = string.lower(filename)
            table.insert(filesnamesLower, filenameLower)
        end
    end

    return filenames, filesnamesLower
end

CreateTableOfSkins = function(tableOfAll, folder)
    local allSkins = {}
    for _, filename in ipairs(tableOfAll) do
        local fileContent = Looker(filename, folder)

        if fileContent then
            local rootEntity = fileContent.OutfitPedData.IsSkinOf
            if rootEntity ~= nil then
                table.insert(allSkins[rootEntity], filename)
            else
                table.insert(allSkins, filename)
            end
        else
            print("Fehler beim Laden der Datei: " .. filename)
        end
    end

    return allSkins
end

LookforRootNameOfSkin = function(skinTable, skinName)
    for nameKey, nameValue in ipairs(skinTable) do
        if nameKey == skinName then
            return nameKey
        end
        for skinKey, skinValue in ipairs(nameValue) do
            if skinValue == skinName then
                return nameKey
            end
        end
    end
end

OrganizeTableOfFactions = function()
    --local oldFactionLeaders = FactionLeaders
    table.remove(FactionsAndMembers)
    table.remove(FactionLeaders)
    FactionsAndMembers = {}
    --FactionLeaders = {}
    for _, player in ipairs(Players) do
        if FactionsAndMembers[player.faction] == nil then
            FactionsAndMembers[player.faction] = {}
        end
        table.insert(FactionsAndMembers[player.faction], player.networkID)
        --[[if FactionLeaders[player.faction] == nil then
            FactionLeaders[player.faction] = player.networkID
        end]]--
    end
    for _, character in ipairs(Characters) do
        if FactionsAndMembers[character.faction] == nil then
            FactionsAndMembers[character.faction] = {}
        end
        table.insert(FactionsAndMembers[character.faction], character.networkID)
    end
end

RegisterNetEvent("SEv_GiveCharacterSkinAndFaction", function(variant, name, hasWeapon, faction, networkID)
    local skin = LookforRootNameOfSkin(TableOfAllCharacterSkins, name)
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
    TriggerClientEvent("CEv_GiveCharacterSkinAndRole", -1, networkID, skin, faction, FactionsAndMembers, FactionLeaders)
end)

RegisterEntity = function(variant, networkID, name, skin, faction)
    if variant == VEHICLE_VARIANT then
        --vehicles
        local vehicle = { networkID = networkID, name = name, skin = skin}
        Vehicles[networkID] = vehicle
    elseif variant == PLAYER_VARIANT then
        --player
        local player = { networkID = networkID, name = name, skin = skin, faction = faction }
        Players[networkID] = player
    else
        --npc
        local character = { networkID = networkID, name = name, skin = skin, faction = faction }
        Characters[networkID] = character
    end
end

UpdateFaction = function (oldFaction, newFaction)
    for _, player in ipairs(Players) do
        if player.faction == oldFaction then
            player.faction = newFaction
        end
    end
    for _, character in ipairs(Characters) do
        if character.faction == oldFaction then
            character.faction = newFaction
        end
    end
end
--[[
    Character = {networkID, name, skin, faction}
    Characters[networkID] = Character

    TriggerClientEvent("CEv_GiveCharacterSkinAndRole", -1, networkID, skin, faction)
]]

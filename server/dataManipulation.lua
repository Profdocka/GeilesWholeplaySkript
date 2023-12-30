RegisterEntity = function(variant, networkID, name, skin, faction)
    print("Es wird etwas registriert: " .. networkID .. ", " .. name .. ", " .. skin)
    if variant == VEHICLE_VARIANT then
        --vehicle
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

ListAllEntriesInFolder = function(folder)
    local resourcePath = GetResourcePath(GetCurrentResourceName()) .. "/" .. folder .. "/"
    local filenames = {}
    local filesnamesLower = {}

    for filename in io.popen('dir "' .. resourcePath .. '" /b'):lines() do
        if filename:match("%.json$") then
            filename = filename:gsub("%.json$", "")
            --table.insert(filenames, filename)
            filenames[filename] = filename
            --print("Name: " .. filename)
            local filenameLower = string.lower(filename)
            --table.insert(filesnamesLower, filenameLower)
            filesnamesLower[filenameLower] = filenameLower
        end
    end

    return filenames, filesnamesLower
end

CreateTableOfSkins = function(tableOfAll, folder)
    local allSkins = {}
    --print("Hi")
    --print(tableOfAll["WernerWrack"])
    for _, filename in pairs(tableOfAll) do
        local fileContent = Looker(filename, folder)
        --print("Mein Filecontent")
        if fileContent then
            local rootEntity
            if folder == CHARFOLDER then
                rootEntity = fileContent.OutfitPedData.IsSkinOf
            else
                rootEntity = fileContent.Vehicle.IsSkinOf
            end
            if rootEntity ~= nil then
                --print("Der Hinzugefügte Skin: " .. filename)
                if allSkins[rootEntity] == nil then
                    allSkins[rootEntity] = {}
                end
                table.insert(allSkins[rootEntity], filename)
            else
                --print("Der rootEntity Name: " .. filename)
                --table.insert(allSkins, filename)
                if allSkins[filename] == nil then
                    allSkins[filename] = {}
                end
            end
        else
            print("Fehler beim Laden der Datei: " .. filename)
        end
    end

    return allSkins
end

LookforRootNameOfSkin = function(skinTable, skinName)
    --print("Der Name des Skins: " .. skinName)
    for nameKey, nameValue in pairs(skinTable) do
        --print("Name Key: " .. nameKey)
        if nameKey == skinName then
            return nameKey
        end
        for skinKey, skinValue in pairs(nameValue) do
            if skinValue == skinName then
                return nameKey
            end
        end
    end
end

CheckIfEntityIsKussKult = function(source, input, variant, hasWeapon, vector4, faction)
    if IsKussKultCharacter(input) then
        TriggerClientEvent("CEv_SpawnCharacter", source, variant, input, hasWeapon, vector4, faction)
    elseif IsKussKultVehicle(input) then
        local networkIDDriver = GetNetworkIDPlayerFromSource(source)
        TriggerClientEvent("CEv_SpawnVehicle", source, input, networkIDDriver)
    else
        TriggerClientEvent("CEv_ShowNotificationEvent", source,
            "~r~" .. input .. " existiert nicht im Kuss Kult Universum!")
    end
    DeadGarbageCleanerCheck(source, false)
end

CheckIfFactionIsKussKult = function (source, input, variantInput, hasWeapon, vector4, exceptionTarget)
    local inputLower = string.lower(input)
    local Group = AllFactions[inputLower]
    if Group ~= nil then
        local variant = GetVariantFromInput(variantInput)
        local factionName = nil
        if variant == FRIENDLY_VARIANT then
            factionName = GetPlayerFactionFromSource(source)
        else
            factionName = inputLower
        end
        if exceptionTarget == "PLAYER" then
            exceptionTarget = Players[GetNetworkIDPlayerFromSource(source)].name
        end
        for i, name in pairs(Group) do
            --print("Mitglieder der Gruppe: " .. name)
            if name == exceptionTarget then
                table.remove(Group, i)
            end
        end
        TriggerClientEvent("CEv_SpawnMultipleCharacters", source, Group, variant, hasWeapon, vector4, factionName)
        DeadGarbageCleanerCheck(source, false)
    else
        TriggerClientEvent("CEv_ShowNotificationEvent", source, "~r~" .. input .. " existiert nicht als Fraktion im Kuss Kult Universum!")
    end
end

DropSpecificEntityByName = function(name, source)
    local isFound, entity = CheckIfCharacterExistsByName(name)
    if isFound then
        Characters[entity.networkID] = nil
        OrganizeTableOfFactions()
        TriggerClientEvent("CEv_DropEntity", -1, NEUTRAL_VARIANT, entity.networkID, FactionsAndMembers, FactionLeaders, Players)
    else
        isFound, entity = CheckIfVehicleExistsByName(name)
        if isFound then
            Vehicles[entity.networkID] = nil
            TriggerClientEvent("CEv_DropEntity", -1, VEHICLE_VARIANT, entity.networkID)
        else
            TriggerClientEvent("CEv_ShowNotificationEvent", source, "Kein aktiver Charakter/aktives Fahrzeug gefunden!")
        end
    end
end

DropMultipleCharacters = function (characterGroup)
    local tempCharacters = {}
    for _, character in pairs(Characters) do
        if not characterGroup[character.networkID] then
            tempCharacters[character.networkID] = Characters[character.networkID]
        end
    end
    Characters = nil
    Characters = tempCharacters
    OrganizeTableOfFactions()
    TriggerClientEvent("CEv_DropMultipleEntitys", -1, NEUTRAL_VARIANT, characterGroup, FactionsAndMembers, FactionLeaders, Players)
end

DropMultipleVehicles = function (vehicleGroup)
    local tempVehicles = {}
    for _, vehicle in pairs(Vehicles) do
        if not vehicleGroup[vehicle.networkID] then
            tempVehicles[vehicle.networkID] = Vehicles[vehicle.networkID]
        end
    end
    Vehicles = nil
    Vehicles = tempVehicles
    TriggerClientEvent("CEv_DropMultipleEntitys", -1, VEHICLE_VARIANT, vehicleGroup)
end

DropAllCharacters = function ()
    local tempCharacters = Characters
    Characters = nil
    Characters = {}
    OrganizeTableOfFactions()
    TriggerClientEvent("CEv_DropAllCharacters", -1, tempCharacters, FactionsAndMembers, FactionLeaders, Players)
end

DropAllVehicles = function()
    local tempVehicles = Vehicles
    Vehicles = nil
    Vehicles = {}
    TriggerClientEvent("CEv_DropAllCars", -1, tempVehicles)
end

CheckIfPlayerExistsByName = function (input)
    if TableOfAllCharactersLower[string.lower(input)] == nil then
        return false
    end
    for _, player in pairs(Players) do
        if string.lower(player.name) == string.lower(input) then
            return true, player
        end
    end
    return false
end

CheckIfCharacterExistsByName = function (input)
    if TableOfAllCharactersLower[string.lower(input)] == nil then
        return false
    end
    for _, character in pairs(Characters) do
        if string.lower(character.name) == string.lower(input) then
            return true, character
        end
    end
    return false
end

CheckIfVehicleExistsByName = function (input)
    if TableOfAllVehiclesLower[string.lower(input)] == nil then
        return false
    end
    for _, vehicle in pairs(Vehicles) do
        if string.lower(vehicle.name) == string.lower(input) then
            return true, vehicle
        end
    end
    return false
end

ListAllActiveForClient = function (source)
    TriggerClientEvent("CEv_ListAll", source, Players, Characters, Vehicles)
end

DeadGarbageCleanerCheck = function (source, skipThresholdCheck)
    if TableLength(Characters) >= THRESHOLD_SPAWNING or TableLength(Vehicles) >= THRESHOLD_SPAWNING or skipThresholdCheck then
        TriggerClientEvent("CEv_DeadGarbageCleanerCheck", source, Characters, Vehicles)
    end
end

function TableLength(T)
    local count = 0
    for _ in pairs(T) do count = count + 1 end
    return count
end

DeadGarbageCleanerCleaning = function (deadCharacters, deadVehicles)
    if next(deadCharacters) ~= nil then
        DropMultipleCharacters(deadCharacters)
    end
    if next(deadVehicles) ~= nil then
        DropMultipleVehicles(deadVehicles)
    end
end
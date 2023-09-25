RegisterEntity = function(variant, networkID, name, skin, faction)
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

CheckIfEntityIsKussKult = function(source, input, variant, hasWeapon, vector4, faction)
    if IsKussKultCharacter(input) then
        TriggerClientEvent("CEv_SpawnCharacter", source, variant, input, hasWeapon, vector4, faction)
    elseif IsKussKultVehicle(input) then
        local networkIDDriver = GetNetworkIDPlayerFromSource(source)
        TriggerClientEvent("CEv_SpawnVehicle", source, input, networkIDDriver)
    else
        TriggerClientEvent("CEv_ShowNotificationEvent", source,
            "~r~" + input + " existiert nicht im Kuss Kult Universum!")
    end
end

DropSpecificEntityByName = function(name, source)
    local isFound, entity = CheckIfCharacterExistsByName(name)
    if isFound then
        Characters[entity.networkID] = nil
        OrganizeTableOfFactions()
        TriggerClientEvent("CEv_DropEntity", -1, NEUTRAL_VARIANT, entity.networkID, FactionsAndMembers, FactionLeaders)
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

CheckIfPlayerExistsByName = function (input)
    if TableOfAllCharactersLower[string.lower(input)] == nil then
        return false
    end
    for _, player in ipairs(Players) do
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
    for _, character in ipairs(Characters) do
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
    for _, vehicle in ipairs(Vehicles) do
        if string.lower(vehicle.name) == string.lower(input) then
            return true, vehicle
        end
    end
    return false
end
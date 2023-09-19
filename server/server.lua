CHARFOLDER = "./../characters"
VEHFOLDER = "./../vehicles"

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

--CheckIfCharacterExists
--CheckIfVehicleExists
--DecideWhatToSpawn

RegisterNetEvent("SEv_CheckIfEntityIsKussKult", CheckIfEntityIsKussKult(source, input, variant, hasWeapon, vector4))

CheckIfEntityIsKussKult = function(source, input, variant)
    if IsKussKultCharacter(input) then
        TriggerClientEvent("CEv_SpawnCharacter", source, variant, input, hasWeapon, vector4)
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

LookforRootNameOfSkin = function (skinTable, skinName)
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

OrganizeTableOfFactions = function ()
    local oldFactionAndMembers = FactionsAndMembers
    for index, value in ipairs(Players) do
        if FactionsAndMembers[value.faction] == nil then
            table.insert(FactionsAndMembers[value.faction], value.name)
        end
        
    end
end

RegisterNetEvent("SEv_GiveCharacterSkinAndFaction", function (variant, name, hasWeapon, faction)
    local skin = LookforRootNameOfSkin(TableOfAllCharacterSkins, name)
end)

RegisterEntity = function (variant, networkID, name, skin, faction)
    if variant == -1 then
        --vehicle
    elseif variant == 0 then
        --player
    else
        --npc

        

        local character = {networkID = networkID, name = name, skin = skin, faction = faction}
        Characters[networkID] = character
    end
end
--[[
    Character = {networkID, name, skin, faction}
    Characters[networkID] = Character

    TriggerClientEvent("CEv_GiveCharacterSkinAndRole", -1, networkID, skin, faction)
]]
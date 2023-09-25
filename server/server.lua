CHARFOLDER = "./../characters"
VEHFOLDER = "./../vehicles"
VEHICLE_VARIANT = -1
PLAYER_VARIANT = 0
NEUTRAL_VARIANT = 1
FRIENDLY_VARIANT = 2
AGGRESSIVE_VARIANT = 3

NETWORK_ID_SYNC_DELAY = 1000

Charakter = { networkID = 0, name = "JohnDoe", skin = "JohnDoe", faction = "Citizen" }
Vehikel = { networkID = 1, name = "Sedan", skin = "blackSedan" }


TableOfAllCharacters, TableOfAllCharactersLower = ListAllEntriesInFolder("characters")
TableOfAllVehicles, TableOfAllVehiclesLower = ListAllEntriesInFolder("vehicles")
TableOfAllCharacterSkins = CreateTableOfSkins(TableOfAllCharacters, "characters")
TableOfAllVehicleSkins = CreateTableOfSkins(TableOfAllVehicles, "vehicles")

TableOfAllCharactersIndexes = CreateIndexTable(TableOfAllCharactersLower)
TableOfAllVehiclesIndexes = CreateIndexTable(TableOfAllVehiclesLower)

Players = {}
Characters = {}
Vehicles = {}
FactionsAndMembers = {}
FactionLeaders = {}

--CheckIfCharacterExists
--CheckIfVehicleExists
--DecideWhatToSpawn

RegisterNetEvent("SEv_CheckIfEntityIsKussKult", function (source, input, variant, hasWeapon, vector4, faction)
    CheckIfEntityIsKussKult(source, input, variant, hasWeapon, vector4, faction)
end)

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

TurnVariantToNeutral = function (name, source)
	local networkIDSource = GetNetworkIDPlayerFromSource(source)
	--local IsFound, character = CheckIfPlayerExistsByName(name)
	--if (IsFound) then
        --MUSS NOCH ÜBERPRÜFT WERDEN. LASS ICH VIELLEICHT WEG. Anderung wird auf einen selber gemacht
      --  if character.networkID ~= networkIDSource and character.faction == Players[networkIDSource].faction then
        --    local key = character.networkID
          --  local newCharacter = {networkID = character.networkID, name = character.name, skin = character.skin, faction = character.name}
            --Players[key] = newCharacter
      --  end
		--return
	--end
	local isFound, character = CheckIfCharacterExistsByName(name)
	if (isFound) then
		local key = character.networkID
        if character.faction == Players[networkIDSource].faction then
            local newCharacter = {networkID = character.networkID, name = character.name, skin = character.skin, faction = character.name}
            Characters[key] = newCharacter
            OrganizeTableOfFactions()
        end
        TriggerClientEvent("CEv_GiveRoles", -1, FactionsAndMembers, FactionLeaders, networkIDSource, key, NEUTRAL_VARIANT)
	end
end

TurnVariantToFriendly = function (name, source)
    local networkIDSource = GetNetworkIDPlayerFromSource(source)
    local isFound, character = CheckIfCharacterExistsByName(name)
    if (isFound) then
		local key = character.networkID
        if character.faction ~= Players[networkIDSource].faction then
            local newCharacter = {networkID = character.networkID, name = character.name, skin = character.skin, faction = Players[networkIDSource].faction}
            Characters[key] = newCharacter
            OrganizeTableOfFactions()
            TriggerClientEvent("CEv_GiveRoles", -1, FactionsAndMembers, FactionLeaders, networkIDSource, key, FRIENDLY_VARIANT)
        end
	end
end

TurnVariantToAggressive = function (name, source)
	local networkIDSource = GetNetworkIDPlayerFromSource(source)
	local isFound, character = CheckIfCharacterExistsByName(name)
	if (isFound) then
		local key = character.networkID
        if character.faction == Players[networkIDSource].faction then
            local newCharacter = {networkID = character.networkID, name = character.name, skin = character.skin, faction = character.name}
            Characters[key] = newCharacter
            OrganizeTableOfFactions()
        end
        --Aggressivität?
        TriggerClientEvent("CEv_GiveRoles", -1, FactionsAndMembers, FactionLeaders, networkIDSource, key, AGGRESSIVE_VARIANT)
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
    TriggerClientEvent("CEv_GiveCharacterSkinAndRole", -1, networkID, skin, hasWeapon, source, variant, FactionsAndMembers, FactionLeaders)
end)

RegisterNetEvent("SEv_RegisterVehicle", function (name, networkID)
    local skin = GetStandardSpellingOfName(name, TableOfAllVehiclesIndexes, TableOfAllVehicles)
    name = LookforRootNameOfSkin(TableOfAllVehicleSkins, skin)
    RegisterEntity(VEHICLE_VARIANT, networkID, name, skin, nil)
end)

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

GetPlayerFactionFromSource = function (source)
    local networkID = GetNetworkIDPlayerFromSource(source)
    return Players[networkID].faction
end

GetNetworkIDPlayerFromSource = function (source)
    return NetworkGetNetworkIdFromEntity(GetPlayerPed(GetPlayerFromServerId(source)))
end

CreateIndexTable = function (toBeIndexTable)
    local index = {}
    for k,v in pairs(toBeIndexTable) do
        index[v]=k
    end
    return index
end

GetStandardSpellingOfName = function (name, usedTableLower, usedTable)
    local tempName = string.lower(name)
    local index = usedTableLower[tempName]
    return usedTable[index]
end

DropSpecificEntityByName = function (name, source)
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
GetInputWindowOutput = function()
    DisplayOnscreenKeyboard(1, "FMMC_MPM_NA", "", "", "", "", "", 30)

    while UpdateOnscreenKeyboard() == 0 do
        DisableAllControlActions(0)
        Wait(0)
    end

    if GetOnscreenKeyboardResult() then
        return GetOnscreenKeyboardResult()
    end
end

--Sucht den Entity aus den Resourcen und gibt die JSON zurück, findet er ihn nicht,
-- gibt er nil zurück
Looker = function(input, folder)
    if (input ~= nil) then
        local path = folder .. "/" .. input .. ".json"
        print(path)
        local file = LoadResourceFile(GetCurrentResourceName(), path)
        local content = {}
        content = json.decode(file)
        return content
    else
        return nil
    end
end

--Lädt den gewünschten Hash aus dem Spielverzeichnis
SearchHash = function(hash)
    if (IsModelInCdimage(hash)) then
        RequestModel(hash)
        while not HasModelLoaded(hash) do
            Citizen.Wait(5)
        end
        return true
    else
        return false
    end
end

GetCurrentVehicleAndSeatNumber = function(pedHandle)
    local vehHandle = GetVehiclePedIsIn(pedHandle, false)
    if vehHandle ~= 0 then
        local seatOfPlayer = GetVehicleSeatOfPed(vehHandle, pedHandle)
        return vehHandle, seatOfPlayer
    end
    return nil
end

TryForNetworkIDAvailability = function(networkID)
    local tries = 5
    for i = 1, tries, 1 do
        if NetworkDoesNetworkIdExist(networkID) then
            return true
        else
            Citizen.Wait(1000)
        end
    end
    return false
end

ShowNotification = function(msg)
    SetNotificationTextEntry('STRING')
    AddTextComponentSubstringPlayerName(msg)
    DrawNotification(false, true)
end

GetPlayerCoordsAndHeading = function(serverID, offset)
    local playerPed = GetPlayerPed(serverID)
    local positionData = {}
    local coords = GetOffsetFromEntityInWorldCoords(playerPed, 0.0, (0.0 + offset), 0.0)
    local heading = GetEntityHeading(playerPed)
    table.insert(positionData, coords)
    table.insert(positionData, heading)
    return positionData
end

---SERVER---

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

GetPlayerFactionFromSource = function(source)
    local networkID = GetNetworkIDPlayerFromSource(source)
    return Players[networkID].faction
end

GetNetworkIDPlayerFromSource = function(source)
    return NetworkGetNetworkIdFromEntity(GetPlayerPed(GetPlayerFromServerId(source)))
end

CreateIndexTable = function(toBeIndexTable)
    local index = {}
    for k, v in pairs(toBeIndexTable) do
        index[v] = k
    end
    return index
end

GetStandardSpellingOfName = function(name, usedTableLower, usedTable)
    local tempName = string.lower(name)
    local index = usedTableLower[tempName]
    return usedTable[index]
end

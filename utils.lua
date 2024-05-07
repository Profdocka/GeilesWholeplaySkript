BlacklistedNames = {Projekt45Dave = "Projekt45Dave", BrillanterBuckelwal = "BrillanterBuckelwal"}

GetInputWindowOutput = function(title)
    AddTextEntry("CH_INPUT", title)
    DisplayOnscreenKeyboard(1, "CH_INPUT", "", "", "", "", "", 30)

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
        --print(path)
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
            Citizen.Wait(0)
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

GetVehicleSeatOfPed = function (vehicleHandle, pedHandle)
	local passengerAmount = GetVehicleModelNumberOfSeats(GetEntityModel(vehicleHandle))
	for i = -1, passengerAmount, 1 do
		local occupantOfSeat = GetPedInVehicleSeat(vehicleHandle, i)
		if occupantOfSeat == pedHandle then
			return i
		end
	end
end

TryForNetworkIDAvailability = function(networkID)
    local tries = 5
    for i = 1, tries, 1 do
        if NetworkDoesNetworkIdExist(networkID) then
            --print("Die Network ID die geprüft wird: " .. networkID)
            if NetworkDoesEntityExistWithNetworkId(networkID) then
              --print("gefunden!")
                return true
            else
                --print("Ich warte...")
                Wait(1000)
            end
        else
            Wait(1000)
        end
    end
    return false
end

ShowNotification = function(msg)
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(msg)
    EndTextCommandThefeedPostMessagetextTu("CHAR_KUSS", "CHAR_KUSS", false, 8, "Das Geile Wholeplay Skript", "von Profdocka", 1.0)
    --DrawNotification(false, true)
end

ShowHelpNotification = function (msg, duration)
    AddTextEntry("ALERT", msg)
    BeginTextCommandDisplayHelp("ALERT")
    EndTextCommandDisplayHelp(0, false, true, duration)
end

GetPlayerCoordsAndHeading = function(serverID, offset)
    local playerPed = GetPlayerPed(serverID)
    local positionData = {}
    local coords = GetOffsetFromEntityInWorldCoords(playerPed, 0.0, (0.0 + offset), 0.0)
    local heading = GetEntityHeading(playerPed)
    --table.insert(positionData, coords)
    positionData["coords"] = coords
    --table.insert(positionData, heading)
    positionData["heading"] = heading
    return positionData
end

ListAllOnClient = function(_Players, _Characters, _Vehicles)
    print("-------------------------")
    print("SPIELER: ")
    PrintEveryMemberOfSet(_Players)
    print("-------------------------")
    print("ALL CHARACTERS: ")
    PrintEveryMemberOfSet(_Characters)
    print("-------------------------")
    print("ALL VEHICLES: ")
    PrintEveryMemberOfSet(_Vehicles)
    print("-------------------------")
end

PrintEveryMemberOfSet = function(set)
    for i, member in pairs(set) do
        local handle = 0
        print("Network-ID: " .. i)
        if TryForNetworkIDAvailability(member.networkID) then
            handle = NetworkGetEntityFromNetworkId(member.networkID)
        end
        print("Handle: " .. handle)
        print("Name: " .. member.name)
        print("Skin: " .. member.skin)
        if (member.faction ~= nil) then
            print("Faction: " .. member.faction)
        end
        print("--------")
    end
end

PrintAllMembersOfTable = function (tabl)
	--print(tabl)
	for key, value in pairs(tabl) do
		print("Key: ", key)
		print("Value: ", value)
		if type(value) == "table" then
			PrintAllMembersOfTable(value)
		end
        print("\t")
	end
end

function GetPlayerFromNetworkID(networkID)
    if TryForNetworkIDAvailability(networkID) then
        return NetworkGetPlayerIndexFromPed(NetworkGetEntityFromNetworkId(networkID))
    end
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
    return NetworkGetNetworkIdFromEntity(GetPlayerPed(source))
end

CreateIndexTable = function(toBeIndexTable)
    local index = {}
    for k, v in pairs(toBeIndexTable) do
        index[string.lower(v)] = k
    end
    return index
end

CreateNumberedTable = function(toBeNumberedTable)
    local numbered = {}
    for k, v in pairs(toBeNumberedTable) do
        if BlacklistedNames[k] == nil then
            table.insert(numbered, k)
        end
    end
    return numbered
end

GetStandardSpellingOfName = function(name, usedTableLower, usedTable, usedTableIndex)
    local tempName = string.lower(name)

    local index = usedTableIndex[usedTableLower[tempName]]
    --print("usedTableLower: " .. usedTableLower[tempName])
    --print("usedTableIndex: " .. index)
    --print("usedTable: " .. usedTable[index])
    return usedTable[index]
end

GetVariantFromInput = function(variantInput)
    if (variantInput == "buddy") then
        return FRIENDLY_VARIANT
    elseif (variantInput == "gegner") then
        return AGGRESSIVE_VARIANT
    else
        return NEUTRAL_VARIANT
    end
end

GetAllCharacterNames = function ()
    local charactersTable = {}
    for characterKey, _ in pairs(TableOfAllCharacterSkins) do
        table.insert(charactersTable, characterKey)
        print(characterKey)
        --Citizen.Wait(10)
    end
    return charactersTable
end

PlayersGroupRemaking = function ()
    local tempPlayers = {}
    local playerServerID = GetPlayers()
    for _, serverID in ipairs(playerServerID) do
        local networkId = GetNetworkIDPlayerFromSource(serverID)
        if Players[networkId] then
            tempPlayers[networkId] = Players[networkId]
        end
    end
    Players = nil
    Players = tempPlayers
end
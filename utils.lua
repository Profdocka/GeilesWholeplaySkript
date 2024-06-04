---Namen die für die zufällige Charakterwahl ausgeschlossen sind
BlacklistedNames = { Projekt45Dave = "Projekt45Dave", BrillanterBuckelwal = "BrillanterBuckelwal" }

---Ruft das Eingabefeld von GTA mit einem eigenem Titel auf
---und gibt dem Spieler die Möglichkeit einen Text einzugeben
---@param title string
---@return string OutputString
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

---Sucht den Entity aus den Resourcen und gibt die JSON zurück, findet er ihn nicht,
---gibt er nil zurück
---@param input string
---@param folder string
---@return table json
Looker = function(input, folder)
    if (input ~= nil) then
        local path = folder .. "/" .. input .. ".json"
        local file = LoadResourceFile(GetCurrentResourceName(), path)
        local content = {}
        content = json.decode(file)
        return content
    else
        return nil
    end
end

---Lädt den gewünschten Hash aus dem Spielverzeichnis
---@param hash integer
---@return boolean
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

---Gibt einem das aktuelle Fahrzeug und den Sitz des Charakters
---@param pedHandle integer
---@return integer vehHandle
---@return integer seatIndex
GetCurrentVehicleAndSeatNumber = function(pedHandle)
    local vehHandle = GetVehiclePedIsIn(pedHandle, false)
    if vehHandle ~= 0 then
        local seatOfPlayer = GetVehicleSeatOfPed(vehHandle, pedHandle)
        return vehHandle, seatOfPlayer
    end
    return nil
end

---Gibt einem das aktuelle Fahrzeug und den Sitz des Charakters
---@param vehicleHandle integer
---@param pedHandle integer
---@return integer seatIndex
GetVehicleSeatOfPed = function(vehicleHandle, pedHandle)
    local passengerAmount = GetVehicleModelNumberOfSeats(GetEntityModel(vehicleHandle))
    for i = -1, passengerAmount, 1 do
        local occupantOfSeat = GetPedInVehicleSeat(vehicleHandle, i)
        if occupantOfSeat == pedHandle then
            return i
        end
    end
end

---Prüft ob für die Network-ID auf dem Client ein Handle vorhanden ist
---@param networkID integer
---@return boolean networkIDIsAvailable
TryForNetworkIDAvailability = function(networkID)
    local tries = 5
    for i = 1, tries, 1 do
        if NetworkDoesNetworkIdExist(networkID) then
            if NetworkDoesEntityExistWithNetworkId(networkID) then
                return true
            else
                Wait(1000)
            end
        else
            Wait(1000)
        end
    end
    return false
end

---Erzeugt eine Nachricht mit Kuss Kult Logo im GTA Message Feed
---@param msg string
ShowNotification = function(msg)
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(msg)
    EndTextCommandThefeedPostMessagetextTu("CHAR_KUSS", "CHAR_KUSS", false, 8, "Das Geile Wholeplay Skript",
        "von Profdocka", 1.0)
end

ShowHelpNotification = function(msg, duration)
    AddTextEntry("ALERT", msg)
    BeginTextCommandDisplayHelp("ALERT")
    EndTextCommandDisplayHelp(0, false, true, duration)
end

---Gibt einem die Koordinaten und die Blickrichtung des Spielers
---@param serverID integer
---@param offset integer
---@return table vector4 Vector3 und heading
GetPlayerCoordsAndHeading = function(serverID, offset)
    local playerPed = GetPlayerPed(serverID)
    local positionData = {}
    local coords = GetOffsetFromEntityInWorldCoords(playerPed, 0.0, (0.0 + offset), 0.0)
    local heading = GetEntityHeading(playerPed)
    positionData["coords"] = coords
    positionData["heading"] = heading
    return positionData
end

---Schreibt alle aktiven Kuss Kult Entities in die Konsole
---@param _Players table
---@param _Characters table
---@param _Vehicles table
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

---Schreibt jeden einzelnen Eintrag der Kuss Kult Entity
---Gruppen in die Konsole
---@param set table
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

---Rekursive Methode um alle Inhalte eines Tables
---in die Konsole zu schreiben
---@param tabl table
PrintAllMembersOfTable = function(tabl)
    for key, value in pairs(tabl) do
        print("Key: ", key)
        print("Value: ", value)
        if type(value) == "table" then
            PrintAllMembersOfTable(value)
        end
        print("\t")
    end
end

---Gibt einem die ID des Spielers anhand der NetworkID
---@param networkID integer
---@return integer PlayerId
function GetPlayerFromNetworkID(networkID)
    if TryForNetworkIDAvailability(networkID) then
        return NetworkGetPlayerIndexFromPed(NetworkGetEntityFromNetworkId(networkID))
    end
end

---Wandelt eine boolische Eingabe in einen String um
---@param bool boolean
---@return string
BoolToString = function(bool)
    if bool == true then
        return "true"
    else
        return "false"
    end
end

--- Funktion zum Anzeigen einer Nachricht mit einer Zeitangabe
---@param duration integer Dauer in Millisekunden
function ShowTimeMessage(duration)
    local endTime = GetGameTimer() + duration

    while GetGameTimer() < endTime and DoCountDown do
        local remainingTime = endTime - GetGameTimer()
        --BeginTextCommandDisplayText("STRING")
        BeginTextCommandPrint("STRING")

        -- Füge die Zeitkomponente hinzu
        AddTextComponentSubstringTime(remainingTime, 6) -- '6' steht für 'HH:MM:SS'

        -- Ende die Textkomponente und zeige die Nachricht an
        --EndTextCommandDisplayText(0.5, 0.5)  -- Positioniere den Text in der Mitte des Bildschirms
        EndTextCommandPrint(1000, true)
        Citizen.Wait(1000)
    end
    ShowNotification("Zeit ist abgelaufen")
    PlaySoundFrontend(-1, "3_2_1", "HUD_MINI_GAME_SOUNDSET", true);
end

---Funktion um den akutellen Countdown zu beenden
function CancelCountdown()
    DoCountDown = false
    Citizen.Wait(1000)
    DoCountDown = true
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

GetAllCharacterNames = function()
    local charactersTable = {}
    for characterKey, _ in pairs(TableOfAllCharacterSkins) do
        table.insert(charactersTable, characterKey)
        print(characterKey)
        --Citizen.Wait(10)
    end
    return charactersTable
end

PlayersGroupRemaking = function()
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

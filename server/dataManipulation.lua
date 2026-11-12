---Registriert einen Entity in seiner entsprechenden Server-Gruppe
---@param variant integer
---@param networkID integer
---@param name string
---@param skin string
---@param faction string
RegisterEntity = function(variant, networkID, name, skin, faction)
    print("Es wird etwas registriert: " .. networkID .. ", " .. name .. ", " .. skin)
    if variant == VEHICLE_VARIANT then
        local vehicle = { networkID = networkID, name = name, skin = skin }
        Vehicles[networkID] = vehicle
    elseif variant == PLAYER_VARIANT then
        local player = { networkID = networkID, name = name, skin = skin, faction = faction }
        Players[networkID] = player
    else
        local character = { networkID = networkID, name = name, skin = skin, faction = faction }
        Characters[networkID] = character
    end
end

---Listet alle Dateinamen in einem Verzeichnis auf
---@param folder string
---@return table filenames
---@return table filesnamesLower
ListAllEntriesInFolder = function(folder)
    local resourcePath = GetResourcePath(GetCurrentResourceName()) .. "/" .. folder .. "/"
    local filenames = {}
    local filesnamesLower = {}

    -- Plattformerkennung ohne package (FiveM-Sandbox stellt package nicht bereit)
    local isWindows = resourcePath:sub(2, 2) == ":"
    local command
    if isWindows then
        command = 'dir "' .. resourcePath .. '" /b'
    else
        command = 'ls "' .. resourcePath .. '"'
    end

    for filename in io.popen(command):lines() do
        if filename:match("%.json$") then
            filename = filename:gsub("%.json$", "")
            filenames[filename] = filename
            local filenameLower = string.lower(filename)
            filesnamesLower[filenameLower] = filenameLower
        end
    end
    return filenames, filesnamesLower
end

---Erstellt einen Table von jedem Entity hinter dem ein Sub-Table steckt, welcher dessen Kostüme enthält
---@param tableOfAll table
---@param folder any
---@return table tableWithNamesAndTheirSkins
CreateTableOfSkins = function(tableOfAll, folder)
    local allSkins = {}
    for _, filename in pairs(tableOfAll) do
        local fileContent = Looker(filename, folder)
        if fileContent then
            local rootEntity
            if folder == CHARFOLDER then
                rootEntity = fileContent.OutfitPedData.IsSkinOf
            else
                rootEntity = fileContent.Vehicle.IsSkinOf
            end
            if rootEntity ~= nil then
                if allSkins[rootEntity] == nil then
                    allSkins[rootEntity] = {}
                end
                table.insert(allSkins[rootEntity], filename)
            else
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

---Gibt einem den Hauptentitynamen von einem Skin
---@param skinTable table
---@param skinName string
---@return string rootName
LookforRootNameOfSkin = function(skinTable, skinName)
    if skinTable[skinName] ~= nil then
        return skinName
    end
    for nameKey, nameValue in pairs(skinTable) do
        for skinKey, skinValue in pairs(nameValue) do
            if skinValue == skinName then
                return nameKey
            end
        end
    end
end

---Prüft ob ein String dem Namen eines Kuss Kult Entities entspricht und triggert die nachfolgende Erzeugung von diesem
---@param source integer
---@param input string
---@param variant integer
---@param hasWeapon boolean
---@param vector4 table
---@param faction string
CheckIfEntityIsKussKult = function(source, input, variant, hasWeapon, vector4, faction)
    if IsKussKultCharacter(input) then
        TriggerClientEvent("CEv_SpawnCharacter", source, variant, input, hasWeapon, vector4, faction)
    elseif IsKussKultVehicle(input) then
        local networkIDDriver = GetNetworkIDPlayerFromSource(source)
        TriggerClientEvent("CEv_SpawnVehicleForDriver", source, input, networkIDDriver)
    else
        TriggerClientEvent("CEv_ShowNotificationEvent", source,
            "~r~" .. input .. " existiert nicht im Kuss Kult Universum!")
    end
    DeadGarbageCleanerCheck(source, false)
end

---Prüft ob ein String einer vordefinierten Kuss Kult Fraktion entspricht und triggert die Erzeugung von dieser
---@param source integer
---@param input string
---@param variantInput string
---@param hasWeapon boolean
---@param vector4 table
---@param exceptionTarget string
CheckIfFactionIsKussKult = function(source, input, variantInput, hasWeapon, vector4, exceptionTarget)
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
            if name == exceptionTarget then
                table.remove(Group, i)
            end
        end
        TriggerClientEvent("CEv_SpawnMultipleCharacters", source, Group, variant, hasWeapon, vector4, factionName)
        DeadGarbageCleanerCheck(source, false)
    else
        TriggerClientEvent("CEv_ShowNotificationEvent", source,
            "~r~" .. input .. " existiert nicht als Fraktion im Kuss Kult Universum!")
    end
end

---Löscht einen Kuss Kult Entity anhand des eingebenen Namens
---@param name string
---@param source integer
DropSpecificEntityByName = function(name, source)
    local isFound, entity = CheckIfCharacterExistsByName(name)
    if isFound then
        Characters[entity.networkID] = nil
        OrganizeTableOfFactions()
        DriversDropCheckPed(entity.networkID)
        TriggerClientEvent("CEv_DropEntity", -1, NEUTRAL_VARIANT, entity.networkID, FactionsAndMembers, FactionLeaders,
            Players, GetDriversInfo())
    else
        isFound, entity = CheckIfVehicleExistsByName(name)
        if isFound then
            Vehicles[entity.networkID] = nil
            DriversDropCheckVehicle(entity.networkID)
            TriggerClientEvent("CEv_DropEntity", -1, VEHICLE_VARIANT, entity.networkID, nil, nil, nil, GetDriversInfo())
        else
            TriggerClientEvent("CEv_ShowNotificationEvent", source, "Kein aktiver Charakter/aktives Fahrzeug gefunden!")
        end
    end
end

---Löscht einen Kuss Kult Entity anhand der Network ID
---@param networkID integer
---@param variant integer
DropSpecificEntityByNetworkID = function(networkID, variant)
    if variant == VEHICLE_VARIANT then
        Vehicles[networkID] = nil
        DriversDropCheckVehicle(networkID)
        TriggerClientEvent("CEv_DropEntity", -1, VEHICLE_VARIANT, networkID, nil, nil, nil, GetDriversInfo())
    else
        Characters[networkID] = nil
        OrganizeTableOfFactions()
        DriversDropCheckPed(networkID)
        TriggerClientEvent("CEv_DropEntity", -1, NEUTRAL_VARIANT, networkID, FactionsAndMembers, FactionLeaders,
            Players, GetDriversInfo())
    end
end

---Löscht eine Sammlung von Charakteren
---@param characterGroup table
DropMultipleCharacters = function(characterGroup)
    local tempCharacters = {}
    for _, character in pairs(Characters) do
        if not characterGroup[character.networkID] then
            tempCharacters[character.networkID] = Characters[character.networkID]
        else
            DriversDropCheckPed(character.networkID)
        end
    end
    Characters = nil
    Characters = tempCharacters
    OrganizeTableOfFactions()
    TriggerClientEvent("CEv_DropMultipleEntitys", -1, NEUTRAL_VARIANT, characterGroup, FactionsAndMembers, FactionLeaders,
        Players, GetDriversInfo())
end

---Löscht eine Sammlung von Fahrzeugen
---@param vehicleGroup table
DropMultipleVehicles = function(vehicleGroup)
    local tempVehicles = {}
    for _, vehicle in pairs(Vehicles) do
        if not vehicleGroup[vehicle.networkID] then
            tempVehicles[vehicle.networkID] = Vehicles[vehicle.networkID]
        else
            DriversDropCheckVehicle(vehicle.networkID)
        end
    end
    Vehicles = nil
    Vehicles = tempVehicles
    TriggerClientEvent("CEv_DropMultipleEntitys", -1, VEHICLE_VARIANT, vehicleGroup, nil, nil, nil, GetDriversInfo())
end

DropCharacterThroughFaction = function(factionName)
    local faction = FactionsAndMembers[factionName]
    local filteredFaction = {}
    for _, networkid in pairs(faction) do
        if Players[networkid] == nil then
            filteredFaction[networkid] = networkid
        end
    end
    DropMultipleCharacters(filteredFaction)
end

---Löscht alle aktiven Charaktere
DropAllCharacters = function()
    local tempCharacters = Characters
    Characters = nil
    Characters = {}
    Drivers = nil
    DriversByPassengers = nil
    DriversTask = nil
    DriversTaskHost = nil
    Drivers = {}
    DriversByPassengers = {}
    DriversTask = {}
    DriversTaskHost = {}
    OrganizeTableOfFactions()
    TriggerClientEvent("CEv_DropAllCharacters", -1, tempCharacters, FactionsAndMembers, FactionLeaders, Players,
        GetDriversInfo())
end

---Löscht alle aktiven Fahrzeuge
DropAllVehicles = function()
    local tempVehicles = Vehicles
    Vehicles = nil
    Vehicles = {}
    Drivers = nil
    DriversByPassengers = nil
    DriversTask = nil
    DriversTaskHost = nil
    Drivers = {}
    DriversByPassengers = {}
    DriversTask = {}
    DriversTaskHost = {}
    TriggerClientEvent("CEv_DropAllCars", -1, tempVehicles, GetDriversInfo())
end

DropAllAndEverything = function()
    local tempCharacters = Characters
    Characters = nil
    Characters = {}
    local tempVehicles = Vehicles
    Vehicles = nil
    Vehicles = {}
    Drivers = nil
    DriversByPassengers = nil
    DriversTask = nil
    DriversTaskHost = nil
    Drivers = {}
    DriversByPassengers = {}
    DriversTask = {}
    DriversTaskHost = {}
    OrganizeTableOfFactions()
    TriggerClientEvent("CEv_DropEverything", -1, tempCharacters, FactionsAndMembers, FactionLeaders, Players,
        GetDriversInfo(), tempVehicles)
end

---Prüft ob einen Spieler mit dem Kuss Kult Charakter gibt und gibt beim Finden zurück
---@param input string
---@return boolean
---@return table player Nur wenn es einen Spieler mit diesem Charakternamen gibt
CheckIfPlayerExistsByName = function(input)
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

---Prüft ob es diesen Kuss Kult Charakter aktiv gibt und gibt beim Finden zurück
---@param input string
---@return boolean
---@return table character Nur wenn es diesen Charakter aktiv gibt
CheckIfCharacterExistsByName = function(input)
    if TableOfAllCharactersLower[string.lower(input)] == nil then
        return false
    end
    for _, character in pairs(Characters) do
        if string.lower(character.name) == string.lower(input) or string.lower(character.skin) == string.lower(input) then
            return true, character
        end
    end
    return false
end

---Prüft ob es dieses Kuss Kult Fahrzeug aktiv gibt und gibt beim Finden zurück
---@param input string
---@return boolean
---@return table vehicle Nur wenn es dieses Fahrzeug aktiv gibt
CheckIfVehicleExistsByName = function(input)
    if TableOfAllVehiclesLower[string.lower(input)] == nil then
        return false
    end
    for _, vehicle in pairs(Vehicles) do
        if string.lower(vehicle.name) == string.lower(input) or string.lower(vehicle.skin) == string.lower(input) then
            return true, vehicle
        end
    end
    return false
end

---Listet alle Aktiven auf für den entsprechenden Spieler
---@param source integer Der entsprechende Spieler
ListAllActiveForClient = function(source)
    TriggerClientEvent("CEv_ListAll", source, Players, Characters, Vehicles, GetDriversInfo())
end

---Löscht alle Charakterleichen und Fahrzeugwracks sofort oder sobald ein Schwellwert überschritten wird
---@param source integer
---@param skipThresholdCheck boolean
DeadGarbageCleanerCheck = function(source, skipThresholdCheck)
    if TableLength(Characters) >= THRESHOLD_SPAWNING or TableLength(Vehicles) >= THRESHOLD_SPAWNING or skipThresholdCheck then
        TriggerClientEvent("CEv_DeadGarbageCleanerCheck", source, Characters, Vehicles)
    end
end

---Gibt einem die Anzahl an Elementen in einem Table
---@param T table
---@return integer count
function TableLength(T)
    local count = 0
    for _ in pairs(T) do count = count + 1 end
    return count
end

---Löscht die Sammlung an Leichen und Wracks
---@param deadCharacters table
---@param deadVehicles table
DeadGarbageCleanerCleaning      = function(deadCharacters, deadVehicles)
    if next(deadCharacters) ~= nil then
        DropMultipleCharacters(deadCharacters)
    end
    if next(deadVehicles) ~= nil then
        DropMultipleVehicles(deadVehicles)
    end
end

---Gibt einen Table zurück mit alle Aktiven Namen als Keys. Wird benutzt um Ausnahmen festzustellen
---@return table existing
GetNamesListOfExisting          = function()
    local existing = {}
    for _, player in pairs(Players) do
        existing[LookforRootNameOfSkin(TableOfAllCharacterSkins, player.name)] = player.name
    end
    for _, character in pairs(Characters) do
        existing[LookforRootNameOfSkin(TableOfAllCharacterSkins, character.name)] = character.name
    end
    for _, vehicle in pairs(Vehicles) do
        existing[LookforRootNameOfSkin(TableOfAllVehicleSkins, vehicle.name)] = vehicle.name
    end
    return existing
end

---Extrahiert alle Inhalte des Diorama in einzelne Tables
---@param diorama table
---@return table charactergroup Sammlung der Charakternamen
---@return table charactervectors Vector4 Sammlung der Charaktere
---@return table vehiclegroup Sammlung der Fahrzeugnamen
---@return table vehiclevectors Vector4 Sammlung der Fahrzeuge
---@return table faction Fraktionszugehörigkeit nach Charaktername
---@return table weaponPossession Wer bewaffnet sein soll und wer nicht
ExtractTablesOfDiorama          = function(diorama)
    local charactergroup = {}
    local charactervectors = {}
    local vehiclegroup = {}
    local vehiclevectors = {}
    local faction = {}
    local weaponPossession = {}
    local exeptions = GetNamesListOfExisting()
    for _, entity in pairs(diorama.characters) do
        if exeptions[LookforRootNameOfSkin(TableOfAllCharacterSkins, entity.name)] == nil then
            table.insert(charactergroup, entity.name)
            table.insert(charactervectors, entity.vector4)
            faction[entity.name] = entity.faction
            table.insert(weaponPossession, true)
        end
    end
    for _, entity in pairs(diorama.vehicles) do
        if exeptions[LookforRootNameOfSkin(TableOfAllVehicleSkins, entity.name)] == nil then
            table.insert(vehiclegroup, entity.name)
            table.insert(vehiclevectors, entity.vector4)
        end
    end
    return charactergroup, charactervectors, vehiclegroup, vehiclevectors, faction, weaponPossession
end

---Der Spieler wird ein zufälliger Kuss Kult Charakter
---@param source any
BecomeRandomKussKultCharacter   = function(source)
    local randomKey = GetRandomKeyOfTable(TableOfAllCharactersNumbered)
    local characterName = TableOfAllCharacters[randomKey]
    TriggerClientEvent("CEv_SpawnCharacter", source, PLAYER_VARIANT, characterName, true, nil, characterName)
end

---Ein zufälliges Kuss Kult Fahrzeug wird gespawnt
SpawnRandomKussKultVehicle      = function(source)
    local randomKey = GetRandomKeyOfTable(TableOfAllVehiclesNumbered)
    local vehicleName = TableOfAllVehicles[randomKey]
    local networkIDDriver = GetNetworkIDPlayerFromSource(source)
    TriggerClientEvent("CEv_SpawnVehicleForDriver", source, vehicleName, networkIDDriver)
end

---Entscheidet ob nur der Skin eines Charakters geändert wird oder ob das komplette Model geändert wird
---@param networkID integer
---@param skin string
---@param folder string
---@param source integer
---@param faction string
FullModelSwitchOrJustCosmetics  = function(networkID, skin, folder, source, faction)
    local pedHandle = NetworkGetEntityFromNetworkId(networkID)
    local hash = GetEntityModel(pedHandle)
    local pedJson = Looker(skin, folder)
    local newModelHash = pedJson.OutfitPedData.ModelHash
    newModelHash = tonumber(newModelHash)
    if hash == newModelHash then
        --JustCosmetics
        TriggerEvent("SEv_GiveCharacterSkinAndFaction", PLAYER_VARIANT, skin, true, faction, networkID)
        TriggerClientEvent("CEv_ShowNotificationEvent", source, "~g~Deine neue Verkleidung: " .. skin)
    else
        --FullModelSwitch
        local vector4 = {}
        vector4["coords"] = GetEntityCoords(pedHandle)
        vector4["heading"] = GetEntityHeading(pedHandle)
        TriggerClientEvent("CEv_SpawnCharacter", source, PLAYER_VARIANT, skin, true, vector4, faction)
        TriggerClientEvent("CEv_ShowNotificationEvent", source, "~g~Deine neue Verkleidung: " .. skin)
    end
end

---Nimmt die Koordinaten eines Dioramas und spawnt an diesen zufällige NPCs
---@param source integer
---@param dioramaName string
---@param factionName string
SpawnRandomGroupDiorama         = function(source, dioramaName, factionName)
    local diorama = Looker(dioramaName, "dioramas")
    if diorama ~= nil then
        local charactergroup, charactervectors, vehiclegroup, vehiclevectors, faction, weaponPossession =
            ExtractTablesOfDiorama(diorama)
        local randomGroup = {}
        local index = 1
        for _, _ in pairs(charactervectors) do
            local randomName = GetRandomKeyOfTable(TableOfAllCharacters)
            randomGroup[index] = randomName
            faction[randomName] = factionName
            index = index + 1
        end
        TriggerClientEvent("CEv_SpawnMultipleCharactersDiorama", source, randomGroup, variant, true, charactervectors,
            faction)
    end
end

---Spawnt an den Koordinaten des Dioramas eine Kuss Kult Fraktion
---@param source integer
---@param dioramaName string
---@param factionName string
SpawnFactionGroupDiorama        = function(source, dioramaName, factionName)
    local diorama = Looker(dioramaName, "dioramas")
    if diorama ~= nil then
        local charactergroup, charactervectors, vehiclegroup, vehiclevectors, faction, weaponPossession =
            ExtractTablesOfDiorama(diorama)
        local FactionGroup = AllFactions[factionName]
        local finalGroup = {}
        local index = 1
        for _, _ in pairs(charactervectors) do
            if FactionGroup[index] then
                local characterName = FactionGroup[index]
                finalGroup[index] = characterName
                faction[characterName] = factionName
                index = index + 1
            else
                break
            end
        end
        TriggerClientEvent("CEv_SpawnMultipleCharactersDiorama", source, finalGroup, variant, true, charactervectors,
            faction)
    end
end

---Startet eine Runde Twouble in Kuss Kult. Weist allen Spielern die Rollen zu, informiert diese, gibt ihnen die entsprechenden Waffen und richtet die Handler ein
---@param terroristCount integer
StartTwoubleInKussKult          = function(terroristCount)
    RunningKussKultGame = KUSS_KULT_GAMES.TWOUBLE_IN_KUSS_KULT
    local onlinePlayers = GetPlayers()
    local playercount = #onlinePlayers
    local terrorists = {}
    local dectectiveID
    local playersWithoutDetective
    local innocents = {}
    dectectiveID = GetRandomKeyOfTable(onlinePlayers)
    playersWithoutDetective = RenumberTable(ExcludeEntryOfTable(onlinePlayers, dectectiveID))
    for i = 1, terroristCount, 1 do
        terrorists[i] = GetRandomKeyOfTable(playersWithoutDetective)
        playersWithoutDetective = RenumberTable(ExcludeEntryOfTable(playersWithoutDetective, terrorists[i]))
    end
    innocents = playersWithoutDetective
    for _, serverid in pairs(terrorists) do
        TriggerClientEvent("CEv_EquipLoadout", serverid, "terrorist", true)
        TriggerClientEvent("CEv_EquipLoadout", serverid, "innocent", false)
        TriggerClientEvent("CEv_ShowNotificationEvent", serverid, "~r~Du bist Gegenkussler")
    end
    if dectectiveID then
        TriggerClientEvent("CEv_ShowNotificationEvent", dectectiveID, "~b~Du bist Kussleiter")
        TriggerClientEvent("CEv_EquipLoadout", dectectiveID, "detective", true)
        TriggerClientEvent("CEv_EquipLoadout", dectectiveID, "innocent", false)
    end
    for _, serverid in pairs(innocents) do
        TriggerClientEvent("CEv_EquipLoadout", serverid, "innocent", true)
        TriggerClientEvent("CEv_ShowNotificationEvent", serverid, "~g~Du bist Kuss Kultler")
    end
    local actors = { dectective = dectectiveID, terrorists = terrorists, innocents = innocents }
    TwoubleManager = nil
    local twoubleCallback = function(source)
        local isTerrorist = function(id)
            for key, terrorist in pairs(terrorists) do
                if tonumber(terrorist) == (id) then
                    terrorists[key] = nil
                    RenumberTable(terrorists)
                    return true
                end
            end
            return false
        end
        if isTerrorist(source) then
            if #terrorists == 0 then
                TriggerClientEvent("CEv_ShowNotificationEvent", -1, "~g~Die Kuss Kultler haben gewonnen")
                TriggerClientEvent("CEv_RemoveKussKultGamesHandler", -1)
                RemoveEventHandler(TwoubleManager)
                RunningKussKultGame = nil
            end
        else
            if tonumber(source) == tonumber(dectectiveID) then
                dectectiveID = nil
            else
                for key, innocent in pairs(innocents) do
                    if tonumber(innocent) == tonumber(source) then
                        innocents[key] = nil
                    end
                end
            end
            if dectectiveID == nil and #innocents == 0 then
                TriggerClientEvent("CEv_ShowNotificationEvent", -1, "~r~Der Kuss Kult wurde vernichtet")
                TriggerClientEvent("CEv_RemoveKussKultGamesHandler", -1)
                RemoveEventHandler(TwoubleManager)
                RunningKussKultGame = nil
            end
        end
    end
    TwoubleManager = AddEventHandler("SEv_TwoubleDeathHandler", function(source)
        twoubleCallback(source)
    end)
    TriggerLatentClientEvent("CEv_SetUpTwoubleHandler", -1, BPS, actors)
end

---Erstellt eine Drivers Fahrgemeinschaft mit dem eingebenen Fahrzeug und Charakteren.
---Diese müssen in der Spielwelt existieren.
---Der Host Player ist für die clientseitige Logik zuständig
---@param vehNet number
---@param passengerTable table {[1] = passengerNet1, [2] = passengerNet2, ...}
---@param vehicleCapacity number
---@param hostPlayer number source
DriversCreateCarpool            = function(vehNet, passengerTable, vehicleCapacity, hostPlayer)
    local passengerPlacement = {}
    for i = -1, (vehicleCapacity - 2), 1 do
        passengerPlacement[i] = passengerTable[i + 2]
        if passengerPlacement[i] ~= nil then
            DriversByPassengers[passengerPlacement[i]] = vehNet
        end
    end
    Drivers[vehNet] = passengerPlacement
    DriversTask[vehNet] = DRIVERS_TASK.NONE
    DriversTaskHost[vehNet] = hostPlayer
end

---Erstellt eine Drivers Fahrgemeinschaft mit dem eingebenen Fahrzeug und Charakteren.
---Diese müssen in der Spielwelt existieren
---@param source number
---@param args table {[1] = vehName, [2] = driverName, ?[3] = passengerName ...}
DriversCreateFromArgs           = function(source, args)
    if args[1] ~= nil then
        local isfound, vehicle = CheckIfVehicleExistsByName(args[1])
        if isfound and args[2] ~= nil then
            local isfounddriver, driver = CheckIfCharacterExistsByName(args[2])
            local passengers = {}
            table.insert(passengers, driver.networkID)
            if isfounddriver then
                for i = 3, #args, 1 do
                    local isfoundpassenger, passenger = CheckIfCharacterExistsByName(args[i])
                    if isfoundpassenger then
                        table.insert(passengers, passenger.networkID)
                    end
                end
                DriversCreateCarpool(vehicle.networkID, passengers, 8, source)
            end
        else
            TriggerClientEvent("CEv_ShowNotificationEvent", -1, "Bitte gültiges Fahrzeug und Fahrer angeben!")
        end
    end
end

---Fahrgemeinschaft erzeugt basierend auf den NPCs, die in dem Kuss Kult Fahrzeug sitzen.
---Unused
---@param vehNet number
---@param vehicleCapacity number
---@param source number
DriversCreateCarpoolFromVehicle = function(vehNet, vehicleCapacity, source)
    if Vehicles[vehNet] ~= nil then
        local passengers = {}
        local vehHandle = NetworkGetEntityFromNetworkId(vehNet)
        for i = 1, vehicleCapacity + 1, 1 do
            local tempPassenger = GetPedInVehicleSeat(vehHandle, i - 2)
            local tempPassengerNet = NetworkGetNetworkIdFromEntity(tempPassenger)
            if Characters[tempPassengerNet] ~= nil then
                passengers[i] = tempPassengerNet
            end
        end
        if passengers[1] ~= nil then
            DriversCreateCarpool(vehNet, passengers, vehicleCapacity, source)
        end
    end
end

---Setzt das Verhalten der Fahrgemeinschaft
---@param source number
---@param args table [VehNet, TaskActionString, ?TargetNet]
DriversSetTaskFromArgs          = function(source, args)
    if args[1] ~= nil then
        local isfound, vehicle = CheckIfVehicleExistsByName(args[1])
        if isfound and Drivers[vehicle.networkID] ~= nil and args[2] ~= nil then
            local tempTask = DriversTask[vehicle.networkID]
            local taskoptions = {
                ["NONE"] = function()
                    tempTask = DRIVERS_TASK.NONE
                end,
                ["GETINVEHICLE"] = function()
                    tempTask = DRIVERS_TASK.GETINVEHICLE
                end,
                ["GETOUTOFVEHICLE"] = function()
                    tempTask = DRIVERS_TASK.GETOUTOFVEHICLE
                end,
                ["DRIVETOCOORDS"] = function()
                    tempTask = table.clone(DRIVERS_TASK.DRIVETOCOORDS)
                    local coords = GetEntityCoords(NetworkGetEntityFromNetworkId(Players
                        [GetNetworkIDPlayerFromSource(source)].networkID))
                    if args[3] then
                        local corrName, target_ = CheckIfCharacterExistsByName(args[3])
                        if corrName then
                            coords = GetEntityCoords(NetworkGetEntityFromNetworkId(target_.networkID))
                        end
                    end
                    tempTask.x = coords.x
                    tempTask.y = coords.y
                    tempTask.z = coords.z
                end,
                ["ESCORT"] = function()
                    tempTask = table.clone(DRIVERS_TASK.ESCORT)
                    tempTask.targetNet = GetNetworkIDPlayerFromSource(source)
                    if args[3] then
                        local corrName, target_ = CheckIfCharacterExistsByName(args[3])
                        if corrName then
                            tempTask.targetNet = target_.networkID
                        end
                    end
                end,
                ["CHASE"] = function()
                    tempTask = table.clone(DRIVERS_TASK.CHASE)
                    tempTask.targetNet = GetNetworkIDPlayerFromSource(source)
                    if args[3] then
                        local corrName, target_ = CheckIfCharacterExistsByName(args[3])
                        if corrName then
                            tempTask.targetNet = target_.networkID
                        end
                    end
                end
            }
            taskoptions[string.upper(args[2])]()
            DriversTask[vehicle.networkID] = nil
            DriversTask[vehicle.networkID] = tempTask
            --DriversTaskHost[vehicle.networkID] = source
            tempTask = nil
            TriggerLatentClientEvent("CEv_GiveRoles", -1, BPS, FactionsAndMembers, FactionLeaders, 0, 0,
                NEUTRAL_VARIANT,
                Players, GetDriversInfo())
        else
            TriggerClientEvent("CEv_ShowNotificationEvent", -1, "Bitte gültiges Fahrzeug und Task angeben!")
        end
    end
end

---Spawnt ein Fahrzeug samt Charakteren. Diese werden automatisch zu einer Fahrgemeinschaft hinzugefügt.
---Hier mit einem extra definierten Fahrzeug
---@param args table {[1] = vehicleName, [2] = driverName, [3] = passengerName ...}
---@param source number
SpawnDriversWithVehicle         = function(args, source)
    local vehicle = args[1]
    local isfounddriver = IsKussKultCharacter(args[2])
    local passengers = {}
    if isfounddriver then
        passengers[-1] = args[2]
        for i = 3, #args, 1 do
            local isfoundpassenger = IsKussKultCharacter(args[i])
            if isfoundpassenger then
                passengers[i - 3] = args[i]
            end
        end
        TriggerLatentClientEvent("CEv_SpawnVehicleWithCharacters", source, BPS, vehicle,
            GetEntityCoordsAndHeading(GetPlayerPed(source)), passengers)
    else
        TriggerClientEvent("CEv_ShowNotificationEvent", source, "Bitte gültiges Fahrzeug und Fahrer angeben!")
    end
end

---Spawnt ein Fahrzeug samt Charakteren. Diese werden automatisch zu einer Fahrgemeinschaft hinzugefügt.
---Hier mit dem Fahrzeug des ersten Charakters
---@param args table {[1] = driverName, [2] = passengerName ...}
---@param source number
SpawnDriversWithMyCar           = function(args, source)
    local lowerSkin = GetStandardSpellingOfName(args[1], TableOfAllCharactersLower, TableOfAllCharacters,
        TableOfAllCharactersIndexes)
    local lowerName = LookforRootNameOfSkin(TableOfAllCharacterSkins, lowerSkin)
    local myvehicleTable = Owners[string.lower(lowerName)]
    local myvehicle
    local passengers = {}
    passengers[-1] = lowerSkin
    if myvehicleTable ~= nil and myvehicleTable[1] ~= nil then
        myvehicle = myvehicleTable[1]
        for i = 2, #args, 1 do
            local isfoundpassenger = IsKussKultCharacter(args[i])
            if isfoundpassenger then
                passengers[i - 2] = args[i]
            end
        end
        TriggerLatentClientEvent("CEv_SpawnVehicleWithCharacters", source, BPS, myvehicle,
            GetEntityCoordsAndHeading(GetPlayerPed(source)), passengers)
    else
        TriggerClientEvent("CEv_ShowNotificationEvent", source, "Fahrer besitzt kein Fahrzeug!")
    end
end

---Ändert die Zusammensetzung einer bestehenden Fahrgemeinschaft zu der der definierten Charaktere
---@param vehNet number
---@param passengerTable table {[1] = passengerNet1, ?[2] = passengerNet2, ?[3] = passengerNet3 ...}
---@param hostPlayer number
DriversUpdateCarpool            = function(vehNet, passengerTable, hostPlayer)
    if Drivers[vehNet] then
        local passengerPlacement = Drivers[vehNet]
        for i = -1, 10, 1 do
            local passenger = passengerPlacement[i]
            local seatIndex = i
            if passenger then
                DriversByPassengers[passenger] = nil
            end
            passengerPlacement[seatIndex] = passengerTable[seatIndex + 2]
            if passenger and passengerPlacement[seatIndex] then
                DriversByPassengers[passengerPlacement[seatIndex]] = vehNet
            end
        end
        Drivers[vehNet] = nil
        Drivers[vehNet] = passengerPlacement
        DriversTaskHost[vehNet] = hostPlayer
    else
        TriggerClientEvent("CEv_ShowNotificationEvent", source, "Fahrgemeinschaft existiert nicht!")
    end
end

---Entfernt das Fahrzeug aus der Fahrgemeinschaftsliste und somit auch die gesamte Fahrgemeinschaft
---@param vehNet number
DriversDropCheckVehicle         = function(vehNet)
    local passengers = Drivers[vehNet]
    if passengers then
        Drivers[vehNet] = nil
        for seatIndex, passengerNet in pairs(passengers) do
            DriversByPassengers[passengerNet] = nil
        end
        DriversTask[vehNet] = nil
        DriversTaskHost[vehNet] = nil
        DriversTaskHost[vehNet] = nil
    end
end

---Entfernt den jeweiligen Passagier aus seiner Fahrgemeinschaft. Ist dies der Fahrer, so rückt der nächte Passagier zum Fahrer auf.
---Ist keiner verfügbar, wird die Fahrgemeinschaft entfernt
---@param pedNet number
DriversDropCheckPed             = function(pedNet)
    local vehNet = DriversByPassengers[pedNet]
    if vehNet then
        local passengers = Drivers[vehNet]
        local currentPedSeatIndex
        local nextAvailablePassenger
        for i = -1, 10, 1 do
            local seatIndex = i
            local passengerNet = passengers[i]
            if passengerNet then
                if currentPedSeatIndex == -1 then
                    if passengerNet then
                        nextAvailablePassenger = passengerNet
                        passengers[seatIndex] = nil
                        passengers[currentPedSeatIndex] = nextAvailablePassenger
                        currentPedSeatIndex = seatIndex
                    end
                end
                if passengerNet == pedNet then
                    currentPedSeatIndex = seatIndex
                    passengers[seatIndex] = nil
                    DriversByPassengers[passengerNet] = nil
                end
            end
        end
        if currentPedSeatIndex ~= -1 or nextAvailablePassenger then
            Drivers[vehNet] = nil
            Drivers[vehNet] = passengers
        else
            DriversDropCheckVehicle(vehNet)
        end
    end
end

---Alle Tabellen zu dem Drivers Feature in einem
---@return table
GetDriversInfo                  = function()
    -- Namenszuordnung: networkID → Name (für Fahrzeuge und Charaktere)
    local nameMap = {}
    for netID, veh in pairs(Vehicles) do
        nameMap[tostring(netID)] = veh.skin or veh.name or tostring(netID)
    end
    for netID, char in pairs(Characters) do
        nameMap[tostring(netID)] = char.skin or char.name or tostring(netID)
    end
    for netID, plr in pairs(Players) do
        nameMap[tostring(netID)] = plr.skin or plr.name or tostring(netID)
    end
    return {
        drivers = Drivers,
        driversbypassengers = DriversByPassengers,
        driverstask = DriversTask,
        driverstaskhost = DriversTaskHost,
        nameMap = nameMap
    }
end

---Erstellt eine Liste, in welchen Fahrgemeinschaften der besagte Charakter ein Ziel ist
---@param pedNet number
---@return table trefferliste
DriversWhereIsPedNetTarget      = function(pedNet)
    local hits = {}
    for vehNet, task in pairs(DriversTask) do
        if task.targetNet ~= nil and task.targetNet == pedNet then
            table.insert(hits, vehNet)
        end
    end
    return hits
end

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
    for filename in io.popen('dir "' .. resourcePath .. '" /b'):lines() do
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
        TriggerClientEvent("CEv_DropEntity", -1, NEUTRAL_VARIANT, entity.networkID, FactionsAndMembers, FactionLeaders,
            Players)
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

---Löscht einen Kuss Kult Entity anhand der Network ID
---@param networkID integer
---@param variant integer
DropSpecificEntityByNetworkID = function(networkID, variant)
    if variant == VEHICLE_VARIANT then
        Vehicles[networkID] = nil
        TriggerClientEvent("CEv_DropEntity", -1, VEHICLE_VARIANT, networkID)
    else
        Characters[networkID] = nil
        OrganizeTableOfFactions()
        TriggerClientEvent("CEv_DropEntity", -1, NEUTRAL_VARIANT, networkID, FactionsAndMembers, FactionLeaders,
            Players)
    end
end

---Löscht eine Sammlung von Charakteren
---@param characterGroup table
DropMultipleCharacters = function(characterGroup)
    local tempCharacters = {}
    for _, character in pairs(Characters) do
        if not characterGroup[character.networkID] then
            tempCharacters[character.networkID] = Characters[character.networkID]
        end
    end
    Characters = nil
    Characters = tempCharacters
    OrganizeTableOfFactions()
    TriggerClientEvent("CEv_DropMultipleEntitys", -1, NEUTRAL_VARIANT, characterGroup, FactionsAndMembers, FactionLeaders,
        Players)
end

---Löscht eine Sammlung von Fahrzeugen
---@param vehicleGroup table
DropMultipleVehicles = function(vehicleGroup)
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

DropCharacterThroughFaction = function (factionName)
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
    OrganizeTableOfFactions()
    TriggerClientEvent("CEv_DropAllCharacters", -1, tempCharacters, FactionsAndMembers, FactionLeaders, Players)
end

---Löscht alle aktiven Fahrzeuge
DropAllVehicles = function()
    local tempVehicles = Vehicles
    Vehicles = nil
    Vehicles = {}
    TriggerClientEvent("CEv_DropAllCars", -1, tempVehicles)
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
        if string.lower(character.name) == string.lower(input) then
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
        if string.lower(vehicle.name) == string.lower(input) then
            return true, vehicle
        end
    end
    return false
end

---Listet alle Aktiven auf für den entsprechenden Spieler
---@param source integer Der entsprechende Spieler
ListAllActiveForClient = function(source)
    TriggerClientEvent("CEv_ListAll", source, Players, Characters, Vehicles)
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
DeadGarbageCleanerCleaning = function(deadCharacters, deadVehicles)
    if next(deadCharacters) ~= nil then
        DropMultipleCharacters(deadCharacters)
    end
    if next(deadVehicles) ~= nil then
        DropMultipleVehicles(deadVehicles)
    end
end

---Gibt einen Table zurück mit alle Aktiven Namen als Keys. Wird benutzt um Ausnahmen festzustellen
---@return table existing
GetNamesListOfExisting = function()
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
ExtractTablesOfDiorama = function(diorama)
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
BecomeRandomKussKultCharacter = function(source)
    local randomKey = GetRandomKeyOfTable(TableOfAllCharactersNumbered)
    local characterName = TableOfAllCharacters[randomKey]
    TriggerClientEvent("CEv_SpawnCharacter", source, PLAYER_VARIANT, characterName, true, nil, characterName)
end

---Ein zufälliges Kuss Kult Fahrzeug wird gespawnt
SpawnRandomKussKultVehicle = function(source)
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
FullModelSwitchOrJustCosmetics = function(networkID, skin, folder, source, faction)
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
SpawnRandomGroupDiorama = function(source, dioramaName, factionName)
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
SpawnFactionGroupDiorama = function(source, dioramaName, factionName)
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
StartTwoubleInKussKult = function(terroristCount)
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
		TriggerClientEvent("CEv_ShowNotificationEvent", serverid, "~r~Du bist Widerkussler")
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
				TriggerClientEvent("CEv_ShowNotificationEvent", -1,"~r~Der Kuss Kult wurde vernichtet")
				TriggerClientEvent("CEv_RemoveKussKultGamesHandler", -1)
				RemoveEventHandler(TwoubleManager)
			end
		end
	end
	TwoubleManager = AddEventHandler("SEv_TwoubleDeathHandler", function(source)
		twoubleCallback(source)
	end)
	TriggerLatentClientEvent("CEv_SetUpTwoubleHandler", -1, BPS, actors)
end

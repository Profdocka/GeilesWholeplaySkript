-- networkID
-- pedHandle
-- vehHandle
-- serverID / netID
CHARFOLDER = "characters"
VEHFOLDER = "vehicles"
VEHICLE_VARIANT = -1
PLAYER_VARIANT = 0
NEUTRAL_VARIANT = 1
FRIENDLY_VARIANT = 2
AGGRESSIVE_VARIANT = 3

IsInvincible = true
WantsFormationSpawn = true
CHARACTER_SPAWN_OFFSET_Y = 3.0

KussBildDic = CreateRuntimeTxd('CHAR_KUSS')
KussBild = CreateRuntimeTextureFromImage(KussBildDic, 'CHAR_KUSS', "kusskultlogo.png")

Citizen.CreateThread(function()
    local sleepThread = 5
    while true do
        if IsControlJustPressed(0, 168) then
            local OutputString = GetInputWindowOutput("Name des Kuss Kult Charakters/Fahrzeugs");
            if OutputString ~= nil then
                Citizen.Wait(sleepThread)
                TriggerServerEvent("SEv_CheckIfEntityIsKussKult", OutputString, PLAYER_VARIANT, true,
                    GetPlayerCoordsAndHeading(PlayerId(), 0.0), OutputString)
                Citizen.Wait(1000)
            end
        end
        Citizen.Wait(sleepThread)
    end
end)

---DebugThread
Citizen.CreateThread(function()
    while true do
        local sleepThread = 5
        if IsControlJustPressed(0, 214) then
            --TriggerServerEvent("SEv_ListAll", GetPlayerServerId(PlayerId()))
            TriggerServerEvent("SEv_StopAllCharacters", GetPlayerServerId(PlayerId()))
            ShowNotification("Alle Charaktere gestoppt!")
            Citizen.Wait(2000)
        end
        Citizen.Wait(sleepThread)
    end
end)

AddEventHandler("playerSpawned", function()
    if GetPedType(PlayerPedId() == 28) then
        SearchHash(GetHashKey("player_zero"))
        SetPlayerModel(PlayerId(), GetHashKey("player_zero"))
    end
    Citizen.Wait(2000)
    TriggerServerEvent("SEv_PlayerSpawned", GetPlayerServerId(PlayerId()))
end)

RegisterNetEvent("CEv_ListAll", function(_Players, _Characters, _Vehicles)
    ListAllOnClient(_Players, _Characters, _Vehicles)
end)

RegisterNetEvent("CEv_ShowNotificationEvent", function(msg)
    ShowNotification(msg)
end)

RegisterNetEvent("CEv_SpawnCharacter", function(variant, name, hasWeapon, vector4, faction)
    if vector4 == nil then
        vector4 = GetPlayerCoordsAndHeading(PlayerId(), 3.0)
    end
    local pedHandle = SpawnCharacter(variant, name, hasWeapon, vector4)

    local networkID = NetworkGetNetworkIdFromEntity(pedHandle)
    SetNetworkIdExistsOnAllMachines(networkID, true)
    SetNetworkIdCanMigrate(networkID, true)

    TriggerServerEvent("SEv_GiveCharacterSkinAndFaction", variant, name, hasWeapon, faction, networkID)
end)

RegisterNetEvent("CEv_SpawnMultipleCharacters", function(Group, variant, hasWeapon, vector4, faction)
    --print("MOin")
    local shouldVector4Update = nil
    local GroupNetwork = {}
    local angleStep = 360.0 / #Group
    if vector4 == nil then
        shouldVector4Update = true
    else
        shouldVector4Update = false
    end
    if WantsFormationSpawn then
        FreezeEntityPosition(PlayerPedId(), true)
    end
    if faction == "CHAOS" then
        CHARACTER_SPAWN_OFFSET_Y = 20.0
    end
    --print("Es geht los wow!")
    for _, characterName in pairs(Group) do
        if shouldVector4Update then
            vector4 = GetPlayerCoordsAndHeading(PlayerId(), CHARACTER_SPAWN_OFFSET_Y)
            local heading = vector4["heading"]
            if WantsFormationSpawn then
                SetEntityHeading(PlayerPedId(), heading + angleStep)
            end
            --print("Heading: ", vector4["heading"], "Gruppenanzahl: ", #Group, "Step: ", angleStep)
        end
        local pedHandle = SpawnCharacter(variant, characterName, hasWeapon, vector4)

        local networkID = NetworkGetNetworkIdFromEntity(pedHandle)
        SetNetworkIdExistsOnAllMachines(networkID, true)
        SetNetworkIdCanMigrate(networkID, true)

        local characterNetwork = { networkID = networkID, name = characterName }
        GroupNetwork[networkID] = characterNetwork
        --print("Mitglied der Gruppe: " ..
        --GroupNetwork[networkID].networkID .. " mit Name " .. GroupNetwork[networkID].name)
        --print(characterName)
        if faction == "CHAOS" then
            Citizen.Wait(500)
        end
    end
    print("Anzahl gespawnter Charaktere: ", #Group)
    if WantsFormationSpawn then
        FreezeEntityPosition(PlayerPedId(), false)
    end
    if faction == "CHAOS" then
        CHARACTER_SPAWN_OFFSET_Y = 3.0
    end
    TriggerServerEvent("SEv_GiveMultipleCharactersSkinAndFaction", GroupNetwork, variant, hasWeapon, faction)
end)

RegisterNetEvent("CEv_SpawnVehicle", function(name, networkIDDriver)
    if TryForNetworkIDAvailability(networkIDDriver) then
        --print("Die untersuchte NetworkID: " .. networkIDDriver)
        local driverHandle = NetworkGetEntityFromNetworkId(networkIDDriver)
        --print("Das Ergebnis " .. driverHandle)
        local vehHandle = SpawnVehicle(name, driverHandle)

        local networkID = NetworkGetNetworkIdFromEntity(vehHandle)
        SetNetworkIdExistsOnAllMachines(networkID, true)
        SetNetworkIdCanMigrate(networkID, true)

        ShowNotification("Dein gespawntes Fahrzeug: " .. name)

        TriggerServerEvent("SEv_RegisterVehicle", name, networkID)
    end
end)

RegisterNetEvent("CEv_GiveCharacterSkinAndRole",
    function(networkID, skin, hasWeapon, source, variant, FactionsAndMembersFromServer, FactionLeadersFromServer,
             PlayersFromServer)
        if TryForNetworkIDAvailability(networkID) then
            local pedHandle = NetworkGetEntityFromNetworkId(networkID)
            --print("NetworkID: " .. networkID)
            --print("Mein Skin: " .. skin)
            local pedJson = Looker(skin, CHARFOLDER)
            Cosmetics(pedHandle, pedJson, hasWeapon)
            ApplyFactions(FactionsAndMembersFromServer, FactionLeadersFromServer, PlayersFromServer)
            if variant == PLAYER_VARIANT then
                --print("Hier wollen Freunde entstehen!")
                AutomaticlyApplyRelationshipBetweenAllPlayers(FactionLeadersFromServer)
            elseif variant == AGGRESSIVE_VARIANT then
                local playerHandle = GetPlayerPed(GetPlayerFromServerId(source))
                TaskCombatPed(pedHandle, playerHandle, 0, 16)
                if PlayersFromServer[networkID] == nil then
                    SetBlipAsFriendly(GetBlipFromEntity(pedHandle), false)
                    SetBlipColour(GetBlipFromEntity(pedHandle), 49)
                end
            end
        end
    end)

RegisterNetEvent("CEv_GiveMultipleCharactersSkinAndRole",
    function(GroupNetwork, hasWeapon, source, variant, FactionsAndMembersFromServer, FactionLeadersFromServer,
             PlayersFromServer)
        local pedHandle = nil
        local pedJson = nil
        for _, character in pairs(GroupNetwork) do
            if TryForNetworkIDAvailability(character.networkID) then
                pedHandle = NetworkGetEntityFromNetworkId(character.networkID)
                pedJson = Looker(character.name, CHARFOLDER)
                Cosmetics(pedHandle, pedJson, hasWeapon)
                Citizen.Wait(100)
            end
        end
        ApplyFactions(FactionsAndMembersFromServer, FactionLeadersFromServer, PlayersFromServer)
        if variant == AGGRESSIVE_VARIANT then
            local playerHandle = GetPlayerPed(GetPlayerFromServerId(source))
            TaskCombatPed(pedHandle, playerHandle, 0, 16)
            if PlayersFromServer[NetworkGetNetworkIdFromEntity(pedHandle)] == nil then
                SetBlipAsFriendly(GetBlipFromEntity(pedHandle), false)
                SetBlipColour(GetBlipFromEntity(pedHandle), 49)
            end
        end
    end)

RegisterNetEvent("CEv_GiveRoles",
    function(FactionsAndMembersFromServer, FactionLeadersFromServer, networkIDEmitter, networkIDReciever, variant,
             PlayersFromServer)
        ApplyFactions(FactionsAndMembersFromServer, FactionLeadersFromServer, PlayersFromServer)
        if variant == AGGRESSIVE_VARIANT and TryForNetworkIDAvailability(networkIDEmitter) and TryForNetworkIDAvailability(networkIDReciever) then
            local recieverHandle = NetworkGetEntityFromNetworkId(networkIDReciever)
            local emitterHandle = NetworkGetEntityFromNetworkId(networkIDEmitter)
            --ClearPedTasks(recieverHandle)
            TaskCombatPed(recieverHandle, emitterHandle, 0, 16)
            --print("playerHandle: " .. emitterHandle)
            --print("PlayerPedId: " .. PlayerPedId())
            if PlayersFromServer[networkIDReciever] == nil then
                --print("Bekommt einen Bösen Blip: " .. networkIDReciever)
                SetBlipColour(GetBlipFromEntity(recieverHandle), 59)
                SetBlipAsFriendly(GetBlipFromEntity(recieverHandle), false)
            end
        end
    end)

RegisterNetEvent("CEv_DropEntity",
    function(variant, networkID, FactionsAndMembersFromServer, FactionLeadersFromServer, PlayersFromServer)
        if TryForNetworkIDAvailability(networkID) then
            local handle = NetworkGetEntityFromNetworkId(networkID)
            if variant == NEUTRAL_VARIANT then
                DeletePed(handle)
                ApplyFactions(FactionsAndMembersFromServer, FactionLeadersFromServer, PlayersFromServer)
            else
                DeleteVehicle(handle)
            end
        end
    end)

RegisterNetEvent("CEv_DropMultipleEntitys",
    function(variant, networkIDs, FactionsAndMembersFromServer, FactionLeadersFromServer, PlayersFromServer)
        local charsCounter = 0
        local vehCounter = 0
        for _, networkID in pairs(networkIDs) do
            if TryForNetworkIDAvailability(networkID) then
                local handle = NetworkGetEntityFromNetworkId(networkID)
                if variant == NEUTRAL_VARIANT then
                    DeletePed(handle)
                    charsCounter = charsCounter + 1
                else
                    DeleteVehicle(handle)
                    vehCounter = vehCounter + 1
                end
            end
        end
        print("Deleted " .. charsCounter .. " Character(s)")
        print("Deleted " .. vehCounter .. " Vehicle(s)")
        if variant == NEUTRAL_VARIANT then
            ApplyFactions(FactionsAndMembersFromServer, FactionLeadersFromServer, PlayersFromServer)
        end
    end)

RegisterNetEvent("CEv_DropAllCharacters",
    function(Characters, FactionsAndMembersFromServer, FactionLeadersFromServer, PlayersFromServer)
        local handle = nil
        local counter = 0
        for _, character in pairs(Characters) do
            if TryForNetworkIDAvailability(character.networkID) then
                handle = NetworkGetEntityFromNetworkId(character.networkID)
                DeletePed(handle)
                counter = counter + 1
            end
        end
        print("Deleted " .. counter .. " Character(s)")
        ApplyFactions(FactionsAndMembersFromServer, FactionLeadersFromServer, PlayersFromServer)
    end)

RegisterNetEvent("CEv_DropAllCars", function(Vehicles)
    local handle = nil
    local counter = 0
    for _, vehicle in pairs(Vehicles) do
        if TryForNetworkIDAvailability(vehicle.networkID) then
            handle = NetworkGetEntityFromNetworkId(vehicle.networkID)
            DeleteVehicle(handle)
            counter = counter + 1
        end
    end
    print("Deleted " .. counter .. " Vehicle(s)")
end)

RegisterNetEvent("CEv_Regroup", function(FactionsAndMembersFromServer, FactionLeadersFromServer, PlayersFromServer)
    ApplyFactions(FactionsAndMembersFromServer, FactionLeadersFromServer, PlayersFromServer)
end)

RegisterNetEvent("CEv_ReskinAll", function(PlayersFromServer, Characters)
    for _, player in pairs(PlayersFromServer) do
        if TryForNetworkIDAvailability(player.networkID) then
            local pedHandle = NetworkGetEntityFromNetworkId(player.networkID)
            local pedJson = Looker(player.skin, CHARFOLDER)
            Cosmetics(pedHandle, pedJson, false)
        end
    end
    for _, character in pairs(Characters) do
        if TryForNetworkIDAvailability(character.networkID) then
            local pedHandle = NetworkGetEntityFromNetworkId(character.networkID)
            local pedJson = Looker(character.skin, CHARFOLDER)
            Cosmetics(pedHandle, pedJson, false)
        end
    end
end)

RegisterNetEvent("CEv_StopAllCharacters", function(Characters)
    for _, character in pairs(Characters) do
        if TryForNetworkIDAvailability(character.networkID) then
            local pedHandle = NetworkGetEntityFromNetworkId(character.networkID)
            ClearPedTasksImmediately(pedHandle)
        end
    end
end)

RegisterNetEvent("CEv_RevieveDeadPed", function(character)
    local pedHandle = NetworkGetEntityFromNetworkId(character.networkID)
    if IsEntityDead(pedHandle) then
        ResurrectPed(pedHandle)
        ClearPedTasksImmediately(pedHandle)
    end
end)

RegisterNetEvent("CEv_DeadGarbageCleanerCheck", function(Characters, Vehicles)
    local deadCharacters, deadVehicles = {}, {}
    for _, character in pairs(Characters) do
        local pedHandle = NetworkGetEntityFromNetworkId(character.networkID)
        if IsEntityDead(pedHandle) then
            deadCharacters[character.networkID] = character.networkID
        end
    end
    for _, vehicle in pairs(Vehicles) do
        local vehHandle = NetworkGetEntityFromNetworkId(vehicle.networkID)
        if GetVehicleEngineHealth(vehHandle) < 0  then
            deadVehicles[vehicle.networkID] = vehicle.networkID
        end
    end
    if next(deadCharacters) ~= nil or next(deadVehicles) ~= nil then
        TriggerServerEvent("SEv_DeadGarbageCleaner", deadCharacters, deadVehicles)
    end
end)

RegisterNetEvent("CEvUI_InitialGWInfos", function(CharacterSkins, VehicleSkins, allFactions, ownersOfVehicles)
    SendNUIMessage({
        type = "GW_InitialInfos",
        characterSkins = CharacterSkins,
        vehicleSkins = VehicleSkins,
        allFactions = allFactions,
        myVehicles = ownersOfVehicles,
        locations = MapMarkers
    })
end)

RegisterNetEvent("CEvUI_OpenMenu", function(Players, Characters, Vehicles, playerName)
    for networkID, player in pairs(Players) do
        local localPlayerID = GetPlayerFromNetworkID(networkID)
        local playername = GetPlayerName(localPlayerID)
        Players[networkID].playerName = playername
    end
    SendNUIMessage({
        type = "GW_OpenMenu",
        players = Players,
        characters = Characters,
        vehicles = Vehicles,
        playerName = playerName
    })
    SetNuiFocus(true, true)
    TriggerScreenblurFadeIn(3000)
end)

function GetPlayerFromNetworkID(networkID)
    if TryForNetworkIDAvailability(networkID) then
        return NetworkGetPlayerIndexFromPed(NetworkGetEntityFromNetworkId(networkID))
    end
end
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
    local shouldVector4Update = nil
    local GroupNetwork = {}
    if vector4 == nil then
        shouldVector4Update = true
    else
        shouldVector4Update = false
    end
    for _, characterName in ipairs(Group) do
        if shouldVector4Update then
            vector4 = GetPlayerCoordsAndHeading(PlayerId(), 3.0)
        end
        local pedHandle = SpawnCharacter(variant, characterName, hasWeapon, vector4)

        local networkID = NetworkGetNetworkIdFromEntity(pedHandle)
        SetNetworkIdExistsOnAllMachines(networkID, true)
        SetNetworkIdCanMigrate(networkID, true)

        local characterNetwork = { networkID = networkID, name = characterName }
        GroupNetwork[networkID] = characterNetwork
        --print("Mitglied der Gruppe: " ..
        --GroupNetwork[networkID].networkID .. " mit Name " .. GroupNetwork[networkID].name)
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

RegisterNetEvent("CEvUI_InitialGWInfos", function(CharacterSkins, VehicleSkins, allFactions)
    SendNUIMessage({
        type = "GW_InitialInfos",
        characterSkins = CharacterSkins,
        vehicleSkins = VehicleSkins,
        allFactions = allFactions
    })
end)

RegisterNetEvent("CEvUI_OpenMenu", function (Players, Characters, Vehicles)
    SendNUIMessage({
        type = "GW_OpenMenu",
        players = Players,
        characters = Characters,
        vehicles = Vehicles
    })
    SetNuiFocus(true, true)
    TriggerScreenblurFadeIn(3000)
end)

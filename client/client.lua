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
            local OutputString = GetInputWindowOutput();
            if OutputString ~= nil then
                Citizen.Wait(sleepThread)
                TriggerServerEvent("SEv_CheckIfEntityIsKussKult", OutputString, PLAYER_VARIANT, true,
                    GetPlayerCoordsAndHeading(PlayerId(), 0.0), OutputString)
                Citizen.Wait(1000)
            end
        end
    end
end)

RegisterNetEvent("CEv_ShowNotificationEvent", function(msg)
    ShowNotification(msg)
end)

RegisterNetEvent("CEv_SpawnCharacter", function(variant, name, hasWeapon, vector4, faction)
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
    end
    --TriggerServerEvent("SEv_GiveMultipleCharactersSkinAndFaction", GroupNetwork, variant, hasWeapon, faction)
end)

RegisterNetEvent("CEv_SpawnVehicle", function(name, networkIDDriver)
    if TryForNetworkIDAvailability(networkIDDriver) then
        local driverHandle = NetworkGetNetworkIdFromEntity(networkIDDriver)
        local vehHandle = SpawnVehicle(name, driverHandle)

        local networkID = NetworkGetNetworkIdFromEntity(vehHandle)
        SetNetworkIdExistsOnAllMachines(networkID, true)
        SetNetworkIdCanMigrate(networkID, true)

        TriggerServerEvent("SEv_RegisterVehicle", name, networkID)
    end
end)

RegisterNetEvent("CEv_GiveCharacterSkinAndRole",
    function(networkID, skin, hasWeapon, source, variant, FactionsAndMembersFromServer, FactionLeadersFromServer)
        if TryForNetworkIDAvailability(networkID) then
            local pedHandle = NetworkGetEntityFromNetworkId(networkID)
            local pedJson = Looker(skin, "characters")
            Cosmetics(pedHandle, pedJson, hasWeapon)
            ApplyFactions(FactionsAndMembersFromServer, FactionLeadersFromServer)
            if variant == PLAYER_VARIANT then
                AutomaticlyApplyRelationshipBetweenAllPlayers(FactionLeadersFromServer)
            elseif variant == AGGRESSIVE_VARIANT then
                local playerHandle = GetPlayerPed(GetPlayerFromServerId(source))
                TaskCombatPed(pedHandle, playerHandle, 0, 16)
            end
        end
    end)

RegisterNetEvent("CEv_GiveMultipleCharactersSkinAndRole",
    function(GroupNetwork, hasWeapon, source, variant, FactionsAndMembersFromServer, FactionLeadersFromServer)
        local pedHandle = nil
        local pedJson = nil
        for _, character in ipairs(GroupNetwork) do
            if TryForNetworkIDAvailability(character.networkID) then
                pedHandle = NetworkGetEntityFromNetworkId(character.networkID)
                pedJson = Looker(skin, CHARFOLDER)
                Cosmetics(pedHandle, pedJson, hasWeapon)
            end
        end
        ApplyFactions(FactionsAndMembersFromServer, FactionLeadersFromServer)
        if variant == AGGRESSIVE_VARIANT then
            local playerHandle = GetPlayerPed(GetPlayerFromServerId(source))
            TaskCombatPed(pedHandle, playerHandle, 0, 16)
        end
    end)

RegisterNetEvent("CEv_GiveRoles",
    function(FactionsAndMembersFromServer, FactionLeadersFromServer, networkIDEmitter, networkIDReciever, variant)
        ApplyFactions(FactionsAndMembersFromServer, FactionLeadersFromServer)
        if variant == AGGRESSIVE_VARIANT and TryForNetworkIDAvailability(networkIDEmitter) and TryForNetworkIDAvailability(networkIDReciever) then
            local recieverHandle = NetworkGetEntityFromNetworkId(networkIDReciever)
            local emitterHandle = NetworkGetEntityFromNetworkId(networkIDEmitter)
            --ClearPedTasks(recieverHandle)
            TaskCombatPed(recieverHandle, emitterHandle, 0, 16)
        end
    end)

RegisterNetEvent("CEv_DropEntity", function(variant, networkID, FactionsAndMembersFromServer, FactionLeadersFromServer)
    if TryForNetworkIDAvailability(networkID) then
        local handle = NetworkGetEntityFromNetworkId(networkID)
        if variant == NEUTRAL_VARIANT then
            DeletePed(handle)
            ApplyFactions(FactionsAndMembersFromServer, FactionLeadersFromServer)
        else
            DeleteVehicle(handle)
        end
    end
end)

RegisterNetEvent("CEv_DropAllCharacters", function (Characters, FactionsAndMembersFromServer, FactionLeadersFromServer)
    local handle = nil
    for _, character in ipairs(Characters) do
        if TryForNetworkIDAvailability(character.networkID) then
            handle = NetworkGetEntityFromNetworkId(character.networkID)
            DeletePed(handle)
        end
    end
    ApplyFactions(FactionsAndMembersFromServer, FactionLeadersFromServer)
end)

RegisterNetEvent("CEv_DropAllCars", function (Vehicles)
    local handle = nil
    for _, vehicle in ipairs(Vehicles) do
        if TryForNetworkIDAvailability(vehicle.networkID) then
            handle = NetworkGetEntityFromNetworkId(vehicle.networkID)
            DeleteVehicle(handle)
        end
    end
end)


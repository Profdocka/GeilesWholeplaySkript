-- networkID
-- pedHandle
-- vehHandle
-- serverID / netID

VEHICLE_VARIANT = -1
PLAYER_VARIANT = 0
NEUTRAL_VARIANT = 1
FRIENDLY_VARIANT = 2
AGGRESSIVE_VARIANT = 3

IsInvincible = true

Citizen.CreateThread(function ()
    local sleepThread = 5
    while true do
        if IsControlJustPressed(0, 168) then
            local OutputString = GetInputWindowOutput();
            if OutputString ~= nil then
                Citizen.Wait(sleepThread)
                TriggerServerEvent("SEv_CheckIfEntityIsKussKult", OutputString, PLAYER_VARIANT, true, GetPlayerCoordsAndHeading(PlayerID(), 0.0), OutputString)
                Citizen.Wait(1000)
            end
        end
    end
end)

RegisterNetEvent("CEv_SpawnCharacter", function (variant, name, hasWeapon, vector4, faction)
    local pedHandle = SpawnCharacter(variant, name, hasWeapon, vector4)

    local networkID = NetworkGetNetworkIdFromEntity(pedHandle)
    SetNetworkIdExistsOnAllMachines(networkID, true)
	SetNetworkIdCanMigrate(networkID, true)

    TriggerServerEvent("SEv_GiveCharacterSkinAndFaction", variant, name, hasWeapon, faction, networkID)
end)

RegisterNetEvent("CEv_GiveCharacterSkinAndRole", function(networkID, skin, hasWeapon, source, variant, FactionsAndMembersFromServer, FactionLeadersFromServer)
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

RegisterNetEvent("CEv_GiveRoles", function (FactionsAndMembersFromServer, FactionLeadersFromServer, networkIDEmitter, networkIDReciever, variant)
    ApplyFactions(FactionsAndMembersFromServer, FactionLeadersFromServer)
    if variant == AGGRESSIVE_VARIANT and TryForNetworkIDAvailability(networkIDEmitter) and TryForNetworkIDAvailability(networkIDReciever) then
        local recieverHandle = NetworkGetEntityFromNetworkId(networkIDReciever)
        local emitterHandle = NetworkGetEntityFromNetworkId(networkIDEmitter)
        --ClearPedTasks(recieverHandle)
        TaskCombatPed(recieverHandle, emitterHandle, 0, 16)
    end
end)

RegisterNetEvent("CEv_ShowNotificationEvent", function(msg)
	ShowNotification(msg)
end)

ApplyFactions = function (FactionsAndMembersFromServer, FactionLeadersFromServer)
    for faction, factionMembers in ipairs(FactionsAndMembersFromServer) do
        local u,factionHash = AddRelationshipGroup(faction)
        local factionLeader = FactionLeadersFromServer[faction]
        local squad = nil
        if factionLeader ~= nil then
            if TryForNetworkIDAvailability(factionLeader) then
                local pedHandleLeader = NetworkGetEntityFromNetworkId(factionLeader)
                if IsPedInGroup(pedHandleLeader) then
                    RemoveGroup(GetPedGroupIndex(pedHandleLeader))
                end
                squad = CreateGroup()
                SetPedAsGroupMember(pedHandleLeader, squad)
                SetPedAsGroupLeader(pedHandleLeader, squad)
            end
        end
        for _, factionMember in ipairs(factionMembers) do
            if TryForNetworkIDAvailability(factionMember) then
                local pedHandle = NetworkGetEntityFromNetworkId(factionMember)
                SetPedRelationshipGroupHash(pedHandle, factionHash)
                --if IsPedInGroup(pedHandle) then
                --    RemoveGroup(GetPedGroupIndex(pedHandle))
                --end
                if squad ~= nil and factionMember ~= factionLeader then
                    SetPedAsGroupMember(pedHandle, squad)
                end
            end
        end
    end
end

RemoveFactions = function (FactionsTable)
    for factionKey, _ in ipairs(FactionsTable) do
        local factionHash = AddRelationshipGroup(factionKey)
        RemoveRelationshipGroup(factionHash)
    end
end

AutomaticlyApplyRelationshipBetweenAllPlayers = function (FactionLeadersFromServer)
    for _, networkID in ipairs(FactionLeadersFromServer) do
        if TryForNetworkIDAvailability(networkID) then
            local player1Handle = NetworkGetEntityFromNetworkId(networkID)
            for _, otherPnetworkID in ipairs(FactionLeadersFromServer) do
                if networkID ~= otherPnetworkID and TryForNetworkIDAvailability(otherPnetworkID) then
                    local player2Handle = NetworkGetEntityFromNetworkId(otherPnetworkID)
                    SetRelationshipBetweenGroups(3, GetPedRelationshipGroupHash(player1Handle), GetPedRelationshipGroupHash(player2Handle))
                end
            end
        end
    end
end

TryForNetworkIDAvailability = function (networkID)
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

GetPlayerCoordsAndHeading = function (serverID, offset)
    local playerPed = GetPlayerPed(serverID)
    local positionData = {}
    local coords = GetOffsetFromEntityInWorldCoords(playerPed, 0.0, (0.0 + offset), 0.0)
    local heading = GetEntityHeading(playerPed)
    table.insert(positionData, coords)
    table.insert(positionData, heading)
    return positionData
end
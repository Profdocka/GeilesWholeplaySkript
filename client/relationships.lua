RegisterNetEvent("CEv_ChangePlayerToPlayerRelationship", function(relationshipNumber, FactionLeadersFromServer)
    PlayerToPlayerRelationship = relationshipNumber
    AutomaticlyApplyRelationshipBetweenAllPlayers(FactionLeadersFromServer)
end)

ApplyFactions = function(FactionsAndMembersFromServer, FactionLeadersFromServer, PlayersFromServer)
    for faction, factionMembers in pairs(FactionsAndMembersFromServer) do
        local u, factionHash = AddRelationshipGroup(faction)
        local factionLeader = FactionLeadersFromServer[faction]
        local squad = nil
        if factionLeader ~= nil then
            --print("Der Gruppenanführer von " .. faction .. ": " .. FactionLeadersFromServer[faction])
            if TryForNetworkIDAvailability(factionLeader) then
                local pedHandleLeader = NetworkGetEntityFromNetworkId(factionLeader)
                if IsPedInGroup(pedHandleLeader) then
                    RemoveGroup(GetPedGroupIndex(pedHandleLeader))
                end
                squad = GetPedGroupIndex(pedHandleLeader)
                if squad == -1 then
                    squad = CreateGroup()
                end

                SetPedAsGroupMember(pedHandleLeader, squad)
                SetPedAsGroupLeader(pedHandleLeader, squad)
                --print("Anführer: " .. factionLeader)
            end
        end
        --print("Mitglieder der Gruppe " .. faction .. " (" .. factionHash .. ")" .. ": ")
        for _, factionMember in pairs(factionMembers) do
            --print("Nummer: " .. factionMember)
            if TryForNetworkIDAvailability(factionMember) then
                local pedHandle = NetworkGetEntityFromNetworkId(factionMember)
                local pedBlip = GetBlipFromEntity(pedHandle)
                SetPedRelationshipGroupHash(pedHandle, factionHash)
                if pedBlip and PlayersFromServer[factionMember] == nil then
                    RemoveBlip(pedBlip)
                    pedBlip = AddBlipForEntity(pedHandle)
                    SetBlipColour(pedBlip, 0)
                    --BeginTextCommandSetBlipName("STRING")
                    --AddTextComponentString(factionMember.title)
                    --EndTextCommandSetBlipName(pedBlip)
                end
                if squad ~= nil and factionMember ~= factionLeader and not IsPedAPlayer(pedHandle) then
                    if factionHash == GetPedRelationshipGroupHash(PlayerPedId()) then
                        SetBlipAsFriendly(pedBlip, true)
                        SetBlipColour(GetBlipFromEntity(pedHandle), 57)
                        if NetworkGetNetworkIdFromEntity(PlayerPedId()) == factionLeader then
                            TakeOwnershipOfNetworkID(pedHandle, factionMember)
                        end
                    end
                    SetPedAsGroupMember(pedHandle, squad)
                end
            end
        end
    end
end

RemoveFactions = function(FactionsTable)
    for factionKey, _ in ipairs(FactionsTable) do
        local factionHash = AddRelationshipGroup(factionKey)
        RemoveRelationshipGroup(factionHash)
    end
end

AutomaticlyApplyRelationshipBetweenAllPlayers = function(FactionLeadersFromServer)
    for _, networkID in pairs(FactionLeadersFromServer) do
        if TryForNetworkIDAvailability(networkID) then
            local player1Handle = NetworkGetEntityFromNetworkId(networkID)
            for _, otherPnetworkID in pairs(FactionLeadersFromServer) do
                if networkID ~= otherPnetworkID and TryForNetworkIDAvailability(otherPnetworkID) then
                    local player2Handle = NetworkGetEntityFromNetworkId(otherPnetworkID)
                    SetRelationshipBetweenGroups(PlayerToPlayerRelationship, GetPedRelationshipGroupHash(player1Handle),
                        GetPedRelationshipGroupHash(player2Handle))
                    SetRelationshipBetweenGroups(PlayerToPlayerRelationship, GetPedRelationshipGroupHash(player2Handle),
                        GetPedRelationshipGroupHash(player1Handle))
                    --print(networkID .. " und " .. otherPnetworkID .. " sind jetzt Freunde")
                end
            end
        end
    end
end

TakeOwnershipOfNetworkID = function(pedHandle, networkID)
    if NetworkGetEntityOwner(pedHandle) ~= PlayerId() then
        NetworkRequestControlOfNetworkId(networkID)
    end
end

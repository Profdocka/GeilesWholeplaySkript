ApplyFactions = function(FactionsAndMembersFromServer, FactionLeadersFromServer)
    for faction, factionMembers in ipairs(FactionsAndMembersFromServer) do
        local u, factionHash = AddRelationshipGroup(faction)
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

RemoveFactions = function(FactionsTable)
    for factionKey, _ in ipairs(FactionsTable) do
        local factionHash = AddRelationshipGroup(factionKey)
        RemoveRelationshipGroup(factionHash)
    end
end

AutomaticlyApplyRelationshipBetweenAllPlayers = function(FactionLeadersFromServer)
    for _, networkID in ipairs(FactionLeadersFromServer) do
        if TryForNetworkIDAvailability(networkID) then
            local player1Handle = NetworkGetEntityFromNetworkId(networkID)
            for _, otherPnetworkID in ipairs(FactionLeadersFromServer) do
                if networkID ~= otherPnetworkID and TryForNetworkIDAvailability(otherPnetworkID) then
                    local player2Handle = NetworkGetEntityFromNetworkId(otherPnetworkID)
                    SetRelationshipBetweenGroups(3, GetPedRelationshipGroupHash(player1Handle),
                        GetPedRelationshipGroupHash(player2Handle))
                end
            end
        end
    end
end
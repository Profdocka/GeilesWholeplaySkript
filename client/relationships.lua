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
                --print("Gruppe des Anführes: " .. GetPedGroupIndex(pedHandleLeader))
            end
        end
        --print("Mitglieder der Gruppe " .. faction .. " (" .. factionHash .. ")" .. ": ")
        for _, factionMember in pairs(factionMembers) do
            --print("Nummer: " .. factionMember)
            if TryForNetworkIDAvailability(factionMember) then
                local pedHandle = NetworkGetEntityFromNetworkId(factionMember)
                local pedBlip = GetBlipFromEntity(pedHandle)
                SetPedRelationshipGroupHash(pedHandle, factionHash)
                --if IsPedInGroup(pedHandle) then
                --    RemoveGroup(GetPedGroupIndex(pedHandle))
                --end
                if pedBlip and PlayersFromServer[factionMember] == nil then
                    RemoveBlip(pedBlip)
                    pedBlip = AddBlipForEntity(pedHandle)
                    SetBlipColour(pedBlip, 0)
                end
                if squad ~= nil and factionMember ~= factionLeader then
                    --print("Meine Gruppe! " .. squad)
                    if factionHash == GetPedRelationshipGroupHash(PlayerPedId()) and PlayersFromServer[factionMember] == nil then
                        SetBlipAsFriendly(pedBlip, true)
                        SetBlipColour(GetBlipFromEntity(pedHandle), 57)
                        if NetworkGetNetworkIdFromEntity(PlayerPedId()) == factionLeader then
                            if NetworkGetEntityOwner(pedHandle) ~= PlayerId() then
                                NetworkRequestControlOfNetworkId(factionMember)
                               --print("Er wird konvertiert: " .. factionMember)
                            end
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
                    SetRelationshipBetweenGroups(1, GetPedRelationshipGroupHash(player1Handle),
                        GetPedRelationshipGroupHash(player2Handle))
                    --print(networkID .. " und " .. otherPnetworkID .. " sind jetzt Freunde")
                end
            end
        end
    end
end
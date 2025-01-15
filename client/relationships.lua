---Ändert das Beziehungslevel zwischen allen Spielern
---@param relationshipNumber integer
---@param FactionLeadersFromServer table
RegisterNetEvent("CEv_ChangePlayerToPlayerRelationship", function(relationshipNumber, FactionLeadersFromServer)
    PlayerToPlayerRelationship = relationshipNumber
    AutomaticlyApplyRelationshipBetweenAllPlayers(FactionLeadersFromServer)
end)

RegisterCommand("gwsetownfaction", function (source, args)
    if args[1] ~= nil then
        OwnFaction = args[1]
        TriggerServerEvent("SEv_UpdatePlayerFaction", GetPlayerServerId(PlayerId()), OwnFaction)
        ShowNotification("Du bist jetzt Teil der Fraktion " .. OwnFaction)
    else
        OwnFaction = ""
        TriggerServerEvent("SEv_UpdatePlayerFaction", GetPlayerServerId(PlayerId()), "DEFAULT")
        ShowNotification("Deine Fraktion wurde zurückgesetzt")
    end
end, false)

---Setzt die Beziehungen für jeden aktiven Kuss Kult Charakter anhand der Fraktionen.
---Bildet Bodyguardgruppen, wenn mehrere in der gleichen Fraktion sind und es einen Anführer gibt.
---@param FactionsAndMembersFromServer table
---@param FactionLeadersFromServer table
---@param PlayersFromServer table
ApplyFactions = function(FactionsAndMembersFromServer, FactionLeadersFromServer, PlayersFromServer)
    for faction, factionMembers in pairs(FactionsAndMembersFromServer) do
        local u, factionHash = AddRelationshipGroup(faction)
        local factionLeader = FactionLeadersFromServer[faction]
        local squad = nil
        PlayerGroupID = 0
        PlayerGroupHandles = {}
        if factionLeader ~= nil then
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
            end
        end
        for _, factionMember in pairs(factionMembers) do
            if TryForNetworkIDAvailability(factionMember) then
                local pedHandle = NetworkGetEntityFromNetworkId(factionMember)
                local pedBlip = GetBlipFromEntity(pedHandle)
                RemoveBlip(pedBlip)
                pedBlip = 0
                SetPedRelationshipGroupHash(pedHandle, factionHash)
                if WantsBlips and PlayersFromServer[factionMember] == nil then
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
                            PlayerGroupID = GetPedGroupIndex(PlayerPedId())
                            table.insert(PlayerGroupHandles, pedHandle)
                        end
                    end
                    SetPedAsGroupMember(pedHandle, squad)
                end
            end
        end
    end
end

---Entfernt alle lokal angelegten Kuss Kult Fraktionen
---@param FactionsTable table
RemoveFactions = function(FactionsTable)
    for factionKey, _ in ipairs(FactionsTable) do
        local factionHash = AddRelationshipGroup(factionKey)
        RemoveRelationshipGroup(factionHash)
    end
end

---Setzt die Gesinnung zwischen allen Kuss Kult Spielern, die Fraktionsanführer sind
---@param FactionLeadersFromServer table
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
                end
            end
        end
    end
end

---Sorgt dafür, dass der eigene Client die Network-ID des Entities besitzt 
---@param pedHandle integer
---@param networkID integer
TakeOwnershipOfNetworkID = function(pedHandle, networkID)
    if NetworkGetEntityOwner(pedHandle) ~= PlayerId() then
        NetworkRequestControlOfNetworkId(networkID)
    end
end

---Liefert entweder eine selbstgesetzte Fraktion zurück
---oder den Standard, wenn keine festgelegt wurde
---@param defaultString string
---@return string faction
CustomFactionOrDefaultFaction =function (defaultString)
    if OwnFaction == "" then
        return defaultString
    else
        return OwnFaction
    end
end
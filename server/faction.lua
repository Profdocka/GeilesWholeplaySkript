UpdateFaction = function(leader, oldFaction, newFaction)
    --[[
    for _, player in pairs(Players) do
        if player.faction == oldFaction then
            player.faction = newFaction
        end
    end
    ]]-- 
    Players[leader].faction = newFaction
    for _, character in pairs(Characters) do
        if character.faction == oldFaction then
            character.faction = newFaction
        end
    end
end

OrganizeTableOfFactions = function()
    --local oldFactionLeaders = FactionLeaders
    table.remove(FactionsAndMembers)
    table.remove(FactionLeaders)
    FactionsAndMembers = {}
    --FactionLeaders = {}
    for _, player in pairs(Players) do
        if FactionsAndMembers[player.faction] == nil then
            FactionsAndMembers[player.faction] = {}
        end
        table.insert(FactionsAndMembers[player.faction], player.networkID)
        --[[if FactionLeaders[player.faction] == nil then
            FactionLeaders[player.faction] = player.networkID
        end]]
              --
    end
    for _, character in pairs(Characters) do
        if FactionsAndMembers[character.faction] == nil then
            FactionsAndMembers[character.faction] = {}
        end
        table.insert(FactionsAndMembers[character.faction], character.networkID)
    end
end

TurnVariantToNeutral = function(name, source)
    local networkIDSource = GetNetworkIDPlayerFromSource(source)
    --local IsFound, character = CheckIfPlayerExistsByName(name)
    --if (IsFound) then
    --MUSS NOCH ÜBERPRÜFT WERDEN. LASS ICH VIELLEICHT WEG. Anderung wird auf einen selber gemacht
    --  if character.networkID ~= networkIDSource and character.faction == Players[networkIDSource].faction then
    --    local key = character.networkID
    --  local newCharacter = {networkID = character.networkID, name = character.name, skin = character.skin, faction = character.name}
    --Players[key] = newCharacter
    --  end
    --return
    --end
    local isFound, character = CheckIfCharacterExistsByName(name)
    if (isFound) then
        local key = character.networkID
        if character.faction == Players[networkIDSource].faction then
            local newCharacter = { networkID = character.networkID, name = character.name, skin = character.skin, faction =
            character.name }
            Characters[key] = newCharacter
            OrganizeTableOfFactions()
        end
        TriggerClientEvent("CEv_GiveRoles", -1, FactionsAndMembers, FactionLeaders, networkIDSource, key, NEUTRAL_VARIANT,
            Players)
    end
end

TurnVariantToFriendly = function(name, source)
    local networkIDSource = GetNetworkIDPlayerFromSource(source)
    local isFound, character = CheckIfCharacterExistsByName(name)
    if (isFound) then
        local key = character.networkID
        if character.faction ~= Players[networkIDSource].faction then
            local newCharacter = { networkID = character.networkID, name = character.name, skin = character.skin, faction =
            Players[networkIDSource].faction }
            Characters[key] = newCharacter
            OrganizeTableOfFactions()
            TriggerClientEvent("CEv_GiveRoles", -1, FactionsAndMembers, FactionLeaders, networkIDSource, key,
                FRIENDLY_VARIANT, Players)
        end
    end
end

TurnVariantToAggressive = function(name, source)
    local networkIDSource = GetNetworkIDPlayerFromSource(source)
    local isFound, character = CheckIfCharacterExistsByName(name)
    if (isFound) then
        local key = character.networkID
        if character.faction == Players[networkIDSource].faction then
            local newCharacter = { networkID = character.networkID, name = character.name, skin = character.skin, faction =
            character.name }
            Characters[key] = newCharacter
            OrganizeTableOfFactions()
        end
        --Aggressivität?
        TriggerClientEvent("CEv_GiveRoles", -1, FactionsAndMembers, FactionLeaders, networkIDSource, key,
            AGGRESSIVE_VARIANT, Players)
    end
end

ReapplyPlayerCharacters = function(message)
    for _, serverID in pairs(GetPlayers()) do
        local networkID = GetNetworkIDPlayerFromSource(serverID)
        local player = Players[networkID]
        if IsKussKultCharacter(player.name) then
            TriggerClientEvent("CEv_SpawnCharacter", serverID, PLAYER_VARIANT, player.skin, true, nil, player.faction)
            TriggerClientEvent("CEv_ShowNotificationEvent", serverID, message)
            Citizen.Wait(NETWORK_ID_SYNC_DELAY)
        end
    end
end

TeleportMultiple = function(GroupNet, coords, heading)
    if GroupNet ~= nil then
        for _, networkID in pairs(GroupNet) do
            --print("NetId ", networkID)
            local pedHandle = NetworkGetEntityFromNetworkId(networkID)
            if not IsPedAPlayer(pedHandle) then
                SetEntityCoords(pedHandle, coords.x, coords.y, coords.z, false, false, false, false)
            end
            Citizen.Wait(10)
        end
    end
end
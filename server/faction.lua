---Ändert die Fraktion eines Spielers und aller angehörigen Charaktere
---@param leader integer Network-ID
---@param oldFaction string
---@param newFaction string
UpdateFaction = function(leader, oldFaction, newFaction)
    Players[leader].faction = newFaction
    for _, character in pairs(Characters) do
        if character.faction == oldFaction then
            character.faction = newFaction
        end
    end
end

---Erstellt einen Table zu jeder Fraktion mit einem Sub-Table in der jedes Mitglied der Fraktion gelistet ist
OrganizeTableOfFactions = function()
    table.remove(FactionsAndMembers)
    table.remove(FactionLeaders)
    FactionsAndMembers = {}
    for _, player in pairs(Players) do
        if FactionsAndMembers[player.faction] == nil then
            FactionsAndMembers[player.faction] = {}
        end
        table.insert(FactionsAndMembers[player.faction], player.networkID)
    end
    for _, character in pairs(Characters) do
        if FactionsAndMembers[character.faction] == nil then
            FactionsAndMembers[character.faction] = {}
        end
        table.insert(FactionsAndMembers[character.faction], character.networkID)
    end
end

---Löscht die alte Fraktion des Spielers und registriert ihn mit einer neuen Fraktion, zu dessen Anführer er wird
---@param networkID integer
---@param variant integer
---@param name string
---@param skin string
---@param newFaction string
ChangePlayerFaction = function(networkID, variant, name, skin, newFaction)
    local oldFaction = Players[networkID].faction
    RegisterEntity(variant, networkID, name, skin, newFaction)
    FactionLeaders[oldFaction] = nil
    FactionLeaders[newFaction] = networkID
    UpdateFaction(networkID, oldFaction, newFaction)
end

---Macht einen Charakter neutral
---@param name string
---@param source integer
TurnVariantToNeutral = function(name, source)
    local networkIDSource = GetNetworkIDPlayerFromSource(source)
    local isFound, character = CheckIfCharacterExistsByName(name)
    if (isFound) then
        local key = character.networkID
        local newCharacter = {
            networkID = character.networkID,
            name = character.name,
            skin = character.skin,
            faction = character.name
        }
        Characters[key] = newCharacter
        OrganizeTableOfFactions()
        TriggerClientEvent("CEv_GiveRoles", -1, FactionsAndMembers, FactionLeaders, networkIDSource, key, NEUTRAL_VARIANT,
            Players)
    end
end

---Macht einen Charakter zum Bodyguard
---@param name string
---@param source integer
TurnVariantToFriendly = function(name, source)
    local networkIDSource = GetNetworkIDPlayerFromSource(source)
    local isFound, character = CheckIfCharacterExistsByName(name)
    if (isFound) then
        local key = character.networkID
        if character.faction ~= Players[networkIDSource].faction then
            local newCharacter = {
                networkID = character.networkID,
                name = character.name,
                skin = character.skin,
                faction = Players[networkIDSource].faction
            }
            Characters[key] = newCharacter
            OrganizeTableOfFactions()
            TriggerClientEvent("CEv_GiveRoles", -1, FactionsAndMembers, FactionLeaders, networkIDSource, key,
                FRIENDLY_VARIANT, Players)
        end
    end
end

---Macht einen Charakter aggressiv gegenüber dem Quellspieler
---@param name string
---@param source integer
TurnVariantToAggressive = function(name, source)
    local networkIDSource = GetNetworkIDPlayerFromSource(source)
    local isFound, character = CheckIfCharacterExistsByName(name)
    if (isFound) then
        local key = character.networkID
        local newCharacter = {
            networkID = character.networkID,
            name = character.name,
            skin = character.skin,
            faction = character.name
        }
        Characters[key] = newCharacter
        OrganizeTableOfFactions()
        TriggerClientEvent("CEv_GiveRoles", -1, FactionsAndMembers, FactionLeaders, networkIDSource, key,
            AGGRESSIVE_VARIANT, Players)
    end
end

---Lädt bei allen Spielern die einen Kuss Kult Charakter haben diesen neu
---@param message string
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

---Teleportiert eine Gruppe an Charakteren zu einem bestimmten Punkt
---@param GroupNet table
---@param coords vector3
---@param heading integer
TeleportMultiple = function(GroupNet, coords, heading)
    if GroupNet ~= nil then
        for _, networkID in pairs(GroupNet) do
            local pedHandle = NetworkGetEntityFromNetworkId(networkID)
            if not IsPedAPlayer(pedHandle) then
                SetEntityCoords(pedHandle, coords.x, coords.y, coords.z, false, false, false, false)
                SetEntityHeading(pedHandle, heading)
            end
            Citizen.Wait(10)
        end
    end
end

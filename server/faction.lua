UpdateFaction = function (oldFaction, newFaction)
    for _, player in ipairs(Players) do
        if player.faction == oldFaction then
            player.faction = newFaction
        end
    end
    for _, character in ipairs(Characters) do
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
    for _, player in ipairs(Players) do
        if FactionsAndMembers[player.faction] == nil then
            FactionsAndMembers[player.faction] = {}
        end
        table.insert(FactionsAndMembers[player.faction], player.networkID)
        --[[if FactionLeaders[player.faction] == nil then
            FactionLeaders[player.faction] = player.networkID
        end]]--
    end
    for _, character in ipairs(Characters) do
        if FactionsAndMembers[character.faction] == nil then
            FactionsAndMembers[character.faction] = {}
        end
        table.insert(FactionsAndMembers[character.faction], character.networkID)
    end
end

TurnVariantToNeutral = function (name, source)
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
            local newCharacter = {networkID = character.networkID, name = character.name, skin = character.skin, faction = character.name}
            Characters[key] = newCharacter
            OrganizeTableOfFactions()
        end
        TriggerClientEvent("CEv_GiveRoles", -1, FactionsAndMembers, FactionLeaders, networkIDSource, key, NEUTRAL_VARIANT)
	end
end

TurnVariantToFriendly = function (name, source)
    local networkIDSource = GetNetworkIDPlayerFromSource(source)
    local isFound, character = CheckIfCharacterExistsByName(name)
    if (isFound) then
		local key = character.networkID
        if character.faction ~= Players[networkIDSource].faction then
            local newCharacter = {networkID = character.networkID, name = character.name, skin = character.skin, faction = Players[networkIDSource].faction}
            Characters[key] = newCharacter
            OrganizeTableOfFactions()
            TriggerClientEvent("CEv_GiveRoles", -1, FactionsAndMembers, FactionLeaders, networkIDSource, key, FRIENDLY_VARIANT)
        end
	end
end

TurnVariantToAggressive = function (name, source)
	local networkIDSource = GetNetworkIDPlayerFromSource(source)
	local isFound, character = CheckIfCharacterExistsByName(name)
	if (isFound) then
		local key = character.networkID
        if character.faction == Players[networkIDSource].faction then
            local newCharacter = {networkID = character.networkID, name = character.name, skin = character.skin, faction = character.name}
            Characters[key] = newCharacter
            OrganizeTableOfFactions()
        end
        --Aggressivität?
        TriggerClientEvent("CEv_GiveRoles", -1, FactionsAndMembers, FactionLeaders, networkIDSource, key, AGGRESSIVE_VARIANT)
	end
end
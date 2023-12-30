CHARACTER_SPAWN_OFFSET_Y = 3.0

--Befehlerstellung und -definition für den Neutralen
RegisterCommand("gwspawnneutral", function(source, args, raw)
	if args[1] ~= nil then
		local netID = source
		--local vector4 = GetPlayerCoordsAndHeading(netID, CHARACTER_SPAWN_OFFSET_Y)
		local vector4 = nil
		if (args[2] == "true") then
			CheckIfEntityIsKussKult(source, args[1], NEUTRAL_VARIANT, true, vector4, args[1])
		else
			CheckIfEntityIsKussKult(source, args[1], NEUTRAL_VARIANT, false, vector4, args[1])
		end
	else
		TriggerClientEvent("CEv_ShowNotificationEvent", source, "Da fehlt was!")
	end
end)

--Befehlerstellung und -definition für den Bodyguard
RegisterCommand("gwspawnbuddy", function(source, args, raw)
	if args[1] ~= nil then
		local netID = source
		--local vector4 = GetPlayerCoordsAndHeading(netID, CHARACTER_SPAWN_OFFSET_Y)
		local vector4 = nil
		if (args[2] == "true") then
			CheckIfEntityIsKussKult(source, args[1], FRIENDLY_VARIANT, true, vector4, GetPlayerFactionFromSource(source))
		else
			CheckIfEntityIsKussKult(source, args[1], FRIENDLY_VARIANT, false, vector4, GetPlayerFactionFromSource(source))
		end
	else
		TriggerClientEvent("CEv_ShowNotificationEvent", source, "Da fehlt was!")
	end
end)

--Befehlerstellung und -definition für den Gegner
RegisterCommand("gwspawngegner", function(source, args, raw)
	if args[1] ~= nil then
		local netID = source
		--local vector4 = GetPlayerCoordsAndHeading(netID, CHARACTER_SPAWN_OFFSET_Y)
		local vector4 = nil
		if (args[2] == "true") then
			CheckIfEntityIsKussKult(source, args[1], AGGRESSIVE_VARIANT, true, vector4, args[1])
		else
			CheckIfEntityIsKussKult(source, args[1], AGGRESSIVE_VARIANT, false, vector4, args[1])
		end
	else
		TriggerClientEvent("CEv_ShowNotificationEvent", source, "Da fehlt was!")
	end
end)

RegisterCommand("gwspawngruppe", function(source, args)
	local index = NetworkGetNetworkIdFromEntity(GetPlayerPed(source))
	local exceptionTarget = Players[index].name
	if args[1] == nil then
		TriggerClientEvent("CEv_ShowNotificationEvent", source, "Da fehlt der Gruppenname!")
	end
	if (args[2] ~= nil) then
		if (args[3] == "true") then
			CheckIfFactionIsKussKult(source, args[1], args[2], true, nil, exceptionTarget)
		else
			CheckIfFactionIsKussKult(source, args[1], args[2], false, nil, exceptionTarget)
		end
	else
		TriggerClientEvent("CEv_ShowNotificationEvent", source, "Die Gesinnung der Gruppe fehlt!")
	end
end)

RegisterCommand("gwspawnmycar", function(source, args)
	local index = NetworkGetNetworkIdFromEntity(GetPlayerPed(source))
	local characterName = Players[index].name
	characterName = ReplaceUmlaute(characterName)
	characterName = string.lower(characterName)
	local ownerString = Owners[characterName]
	if ownerString ~= nil then
		local vehicleString = ownerString[1]
		--print("Das gewünschte Fahrzeug: " .. vehicleString)
		TriggerClientEvent("CEv_SpawnVehicle", source, vehicleString, index);
	else
		TriggerClientEvent("CEv_ShowNotificationEvent", source, "Dieser Charakter besitzt kein Fahrzeug!")
	end
end)

RegisterCommand("gwgesinnungneutral", function(source, args)
	if args[1] ~= nil then
		TurnVariantToNeutral(args[1], source)
	else
		TriggerClientEvent("CEv_ShowNotificationEvent", source, "Da fehlt was!")
	end
end)

RegisterCommand("gwgesinnungbuddy", function(source, args)
	if args[1] ~= nil then
		TurnVariantToFriendly(args[1], source)
	else
		TriggerClientEvent("CEv_ShowNotificationEvent", source, "Da fehlt was!")
	end
end)

RegisterCommand("gwgesinnunggegner", function(source, args)
	if args[1] ~= nil then
		TurnVariantToAggressive(args[1], source)
	else
		TriggerClientEvent("CEv_ShowNotificationEvent", source, "Da fehlt was!")
	end
end)

RegisterCommand("gwdropsingle", function(source, args)
	if (args[1] ~= nil) then
		DropSpecificEntityByName(args[1], source)
	else
		TriggerClientEvent("CEv_ShowNotificationEvent", source, "Da fehlt was!")
	end
end)

RegisterCommand("gwdropallpeds", function(source, args)
	DropAllCharacters()
end)

RegisterCommand("gwdropallcars", function(source, args)
	DropAllVehicles()
end)

RegisterCommand("gwdropeverything", function(source, args)
	DropAllVehicles()
	DropAllCharacters()
end)

RegisterCommand("gwdropdead", function (source)
	DeadGarbageCleanerCheck(source, true)
end)

RegisterCommand("gwlistall", function(source)
	ListAllActiveForClient(source)
end)

RegisterCommand("gwreskin", function(source)
	TriggerClientEvent("CEv_ReskinAll", source, Players, Characters)
end)

RegisterCommand("gwstopall", function(source)
	StopAllCharacters(source)
end)

StopAllCharacters = function(source)
	TriggerClientEvent("CEv_StopAllCharacters", source, Characters)
end

RegisterCommand("gwchangeskin", function(source, args)
	local networkID = GetNetworkIDPlayerFromSource(source)
	local name = Players[networkID].name
	local skinTable = TableOfAllCharacterSkins[name]
	local offset = args[1]
	if skinTable ~= nil and type(skinTable) == "table" then
		local length = #skinTable
		if length > 0 then
			if offset ~= nil and type(offset) == "number" then
				if offset < 1 then
					offset = 1
				end
				if offset > length then
					--RegisterEntity(PLAYER_VARIANT, networkID, name, name, Players[networkID].faction)
					FullModelSwitchOrJustCosmetics(networkID, name, CHARFOLDER, source, Players[networkID].faction)
				else
					FullModelSwitchOrJustCosmetics(networkID, skinTable[offset], CHARFOLDER, source, Players[networkID].faction)
				end
			else
				offset = GetCurrentSkinIndex(TableOfAllCharacterSkins, name, Players[networkID].skin)
				if offset == -1 then
					offset = 1
				else
					offset = offset + 1
				end
				if offset > length then
					--RegisterEntity(PLAYER_VARIANT, networkID, name, name, Players[networkID].faction)
					FullModelSwitchOrJustCosmetics(networkID, name, CHARFOLDER, source, Players[networkID].faction)
				else
					--RegisterEntity(PLAYER_VARIANT, networkID, name, skinTable[offset], Players[networkID].faction)
					FullModelSwitchOrJustCosmetics(networkID, skinTable[offset], CHARFOLDER, source, Players[networkID].faction)
				end
			end
		else
			TriggerClientEvent("CEv_ShowNotificationEvent", source, "~r~" .. name .. " hat keine Verkleidungen!")
		end
	else
		TriggerClientEvent("CEv_ShowNotificationEvent", source, "~r~" .. name .. " hat keine Verkleidungen!")
	end
end)

RegisterCommand("gwrevievesingle", function (source, args)
	if (args[1] ~= nil) then
		local exists, char = CheckIfCharacterExistsByName(args[1])
		if exists then
			TriggerClientEvent("CEv_RevieveDeadPed", source, char)
		else
			TriggerClientEvent("CEv_ShowNotificationEvent", source, "Den Namen gibt es nicht!")
		end
	else
		TriggerClientEvent("CEv_ShowNotificationEvent", source, "Da fehlt was!")
	end
end)

GetCurrentSkinIndex = function(tabl, name, skin)
	if skin == name then
		return -1
	end
	for index, value in ipairs(tabl[name]) do
		if value == skin then
			return index
		end
	end
end

FullModelSwitchOrJustCosmetics = function(networkID, skin, folder, source, faction)
	local pedHandle = NetworkGetEntityFromNetworkId(networkID)
	local hash = GetEntityModel(pedHandle)
	local pedJson = Looker(skin, folder)
	--print(skin)
	local newModelHash = pedJson.OutfitPedData.ModelHash
	newModelHash = tonumber(newModelHash)
	if hash == newModelHash then
		--JustCosmetics
		TriggerEvent("SEv_GiveCharacterSkinAndFaction", PLAYER_VARIANT, skin, true, faction, networkID)
		TriggerClientEvent("CEv_ShowNotificationEvent", source, "~g~Deine neue Verkleidung: " .. skin)
	else
		--FullModelSwitch
		local vector4 = {}
		vector4["coords"] = GetEntityCoords(pedHandle)
		vector4["heading"] = GetEntityHeading(pedHandle)
		TriggerClientEvent("CEv_SpawnCharacter", source, PLAYER_VARIANT, skin, true, vector4, faction)
		TriggerClientEvent("CEv_ShowNotificationEvent", source, "~g~Deine neue Verkleidung: " .. skin)
	end
end

RegisterCommand("gwjahresabschluss", function(source, args)
	local variant = NEUTRAL_VARIANT
	local hasWeapon = true
	local vector4 = nil
	local factionName = "CHAOS"

	local Group = GetAllCharacterNames()
	if (args[1] ~= nil) then
		variant = GetVariantFromInput(args[1])
	end

	print("Alle Namen sind fertig")

	TriggerClientEvent("CEv_SpawnMultipleCharacters", source, Group, variant, hasWeapon, vector4, factionName)
end)
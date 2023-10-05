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

RegisterCommand("gwlistall", function(source)
	ListAllActiveForClient(source)
end)

RegisterCommand("gwreskin", function (source)
	TriggerClientEvent("CEv_ReskinAll", source, Players, Characters)
end)

RegisterCommand("gwstopall", function (source)
	StopAllCharacters(source)
end)

StopAllCharacters = function (source)
	TriggerClientEvent("CEv_StopAllCharacters", source, Characters)
end
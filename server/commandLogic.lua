CHARACTER_SPAWN_OFFSET_Y = 3.0

--Befehlerstellung und -definition für den Neutralen
RegisterCommand("SpawnNeutral", function(source, args, raw)
	if args[1] ~= nil then
        local netID = GetPlayerFromServerId(source)
        local vector4 = GetPlayerCoordsAndHeading(netID, CHARACTER_SPAWN_OFFSET_Y)
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
RegisterCommand("SpawnBuddy", function(source, args, raw)
	if args[1] ~= nil then
        local netID = GetPlayerFromServerId(source)
        local vector4 = GetPlayerCoordsAndHeading(netID, CHARACTER_SPAWN_OFFSET_Y)
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
RegisterCommand("SpawnGegner", function(source, args, raw)
	if args[1] ~= nil then
        local netID = GetPlayerFromServerId(source)
        local vector4 = GetPlayerCoordsAndHeading(netID, CHARACTER_SPAWN_OFFSET_Y)
		if (args[2] == "true") then
            CheckIfEntityIsKussKult(source, args[1], AGGRESSIVE_VARIANT, true, vector4, args[1])
		else
            CheckIfEntityIsKussKult(source, args[1], AGGRESSIVE_VARIANT, false, vector4, args[1])
		end
	else
		TriggerClientEvent("CEv_ShowNotificationEvent", source, "Da fehlt was!")
	end
end)

RegisterCommand("SpawnGroup", function (source, args)
	if args[1] == nil then
		TriggerClientEvent("CEv_ShowNotificationEvent", source, "Da fehlt der Gruppenname!")
	end
	if (args[2] ~= nil) then
		if (args[3] == "true") then
			CheckIfFactionIsKussKult(source, args[1], args[2], true, nil)
		else
			CheckIfFactionIsKussKult(source, args[1], args[2], false, nil)

		end
	else
		TriggerClientEvent("CEv_ShowNotificationEvent", source, "Die Gesinnung der Gruppe fehlt!")
	end
end)

RegisterCommand("VariantNeutral", function (source, args)
	if args[1] ~= nil then
		TurnVariantToNeutral(args[1], source)
	else
		TriggerClientEvent("CEv_ShowNotificationEvent", source, "Da fehlt was!")
	end
end)

RegisterCommand("VariantFriendly", function (source, args)
	if args[1] ~= nil then
		TurnVariantToFriendly(args[1], source)
	else
		TriggerClientEvent("CEv_ShowNotificationEvent", source, "Da fehlt was!")
	end
end)

RegisterCommand("VariantAggressive", function (source, args)
	if args[1] ~= nil then
		TurnVariantToAggressive(args[1], source)
	else
		TriggerClientEvent("CEv_ShowNotificationEvent", source, "Da fehlt was!")
	end
end)

RegisterCommand("DropSingle", function (source, args)
	if (args[1] ~= nil) then
		DropSpecificEntityByName(args[1])
	else
		TriggerClientEvent("CEv_ShowNotificationEvent", source, "Da fehlt was!")
	end
end)

RegisterCommand("DropAllPeds", function (source, args)
	DropAllCharacters()
end)

RegisterCommand("DropAllCars", function (source, args)
	DropAllVehicles()
end)

RegisterCommand("DropEverything", function (source, args)
	DropAllVehicles()
	DropAllCharacters()
end)
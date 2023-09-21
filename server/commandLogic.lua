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
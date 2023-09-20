-- networkID
-- pedHandle
-- vehHandle
-- serverID / netID

VEHICLE_VARIANT = -1
PLAYER_VARIANT = 0
NEUTRAL_VARIANT = 1

IsInvincible = true

Citizen.CreateThread(function ()
    local sleepThread = 5
    while true do
        if IsControlJustPressed(0, 168) then
            local OutputString = GetInputWindowOutput();
            if OutputString ~= nil then
                Citizen.Wait(sleepThread)
                TriggerServerEvent("SEv_CheckIfEntityIsKussKult", OutputString, PLAYER_VARIANT, true, GetPlayerCoordsAndHeading(), OutputString)
                Citizen.Wait(1000)
            end
        end
    end
end)

RegisterNetEvent("CEv_SpawnCharacter", function (variant, name, hasWeapon, vector4, faction)
    local pedHandle = SpawnCharacter(variant, name, hasWeapon, vector4)

    local networkID = NetworkGetNetworkIdFromEntity(pedHandle)
    SetNetworkIdExistsOnAllMachines(networkID, true)
	SetNetworkIdCanMigrate(networkID, true)

    TriggerServerEvent("SEv_GiveCharacterSkinAndFaction", variant, name, hasWeapon, faction, networkID)
end)

RegisterNetEvent("CEv_ShowNotificationEvent", function(msg)
	ShowNotification(msg)
end)

ShowNotification = function(msg)
	SetNotificationTextEntry('STRING')
	AddTextComponentSubstringPlayerName(msg)
	DrawNotification(false, true)
end

GetPlayerCoordsAndHeading = function ()
    local playerPed = GetPlayerPed(PlayerId())
    local positionData = {}
    local coords = GetEntityCoords(playerPed)
    local heading = GetEntityHeading(playerPed)
    table.insert(positionData, coords)
    table.insert(positionData, heading)
    return positionData
end
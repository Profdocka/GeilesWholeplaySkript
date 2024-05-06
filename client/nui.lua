RegisterCommand("UI_RequestOpenMenu", function ()
    TriggerServerEvent("SEv_OpenMenu", GetPlayerServerId(PlayerId()))
end)

RegisterKeyMapping("UI_RequestOpenMenu", "", "keyboard", "F6")

--RegisterKeyMapping("gwspawnmycar", "", "keyboard", "F4")
--[[]
RegisterNUICallback("UI_PlayerModelSwitch", function (data, cb)
    cb({})

    TriggerServerEvent("SEv_CheckIfEntityIsKussKult", data.characterName, PLAYER_VARIANT, true,
    GetPlayerCoordsAndHeading(PlayerId(), 0.0), data.characterName)
end)
]]--

RegisterNUICallback("UI_CloseMenu", function (data, cb)
    cb({})

    SetNuiFocus(false, false)
    TriggerScreenblurFadeOut(3000)
end)

RegisterNUICallback("UI_RequestMenuData", function (data, cb)
    cb({})

    TriggerServerEvent("SEv_RequestMenuData", GetPlayerServerId(PlayerId()))
end)

RegisterNUICallback("UI_SpawnCharacterOrVehicle", function (data, cb)
    cb({})

    --print("Der erhaltene Name: ", data.name)
    --print("Die Variante: ", data.variant)

    local faction = data.name
    if data.variant == FRIENDLY_VARIANT then
        faction = "PLAYER"
    end

    TriggerServerEvent("SEv_CheckIfEntityIsKussKult", data.name, tonumber(data.variant), true,
    GetPlayerCoordsAndHeading(PlayerId(), 3.0), faction)
end)

RegisterNUICallback("UI_SpawnGroup", function (data, cb)
    cb({})

    --print("Der erhaltene Name: ", data.name)
    --print("Die Variante: ", data.variant)

    local exceptionTarget = "PLAYER"

    --[[
    local faction = data.name
    if data.variant == FRIENDLY_VARIANT then
        faction = "PLAYER"
    end
    --]]

    local vector4 = GetPlayerCoordsAndHeading(PlayerId(), 3.0)
    vector4 = nil

    TriggerServerEvent("SEv_CheckIfFactionIsKussKult", GetPlayerServerId(PlayerId()), data.name, VariantNumberToString(data.variant), true,
    vector4, exceptionTarget)
end)

VariantNumberToString = function (variant)
    if variant == PLAYER_VARIANT then
        return "player"
    elseif variant == VEHICLE_VARIANT then
        return "vehicle"
    elseif variant == NEUTRAL_VARIANT then
        return "neutral"
    elseif variant == FRIENDLY_VARIANT then
        return "buddy"
    elseif variant == AGGRESSIVE_VARIANT then
        return "gegner"
    end
end

RegisterNUICallback("UI_SpawnMyCar", function (data, cb)
    cb({})

    TriggerServerEvent("SEv_SpawnMyCar", GetPlayerServerId(PlayerId()))
end)

RegisterNUICallback("UI_Teleport", function (data, cb)
    cb({})

    TeleportToLocationByCommand(data.name)
end)

RegisterNUICallback("UI_DeleteEntity", function (data, cb)
    cb({})
    TriggerServerEvent("SEv_DeleteEntity", GetPlayerServerId(PlayerId()), data.name)
end)

RegisterNUICallback("UI_ChangeAttitude", function (data, cb)
    cb({})
    TriggerServerEvent("SEv_ChangeCharacterAttitude", GetPlayerServerId(PlayerId()), data.variant, data.name)
end)

RegisterNUICallback("UI_RelocateCharacter", function (data, cb)
    cb({})
    local Group = {}
    --print("NetID " .. data.networkID)
    Group[tonumber(data.networkID)] = tonumber(data.networkID)
    local coords = GetOffsetFromEntityInWorldCoords(PlayerPedId(), 0.0, (0.0), 0.0)
    local heading = GetEntityHeading(PlayerPedId())
    TriggerServerEvent("SEv_RelocateCharacter", GetPlayerServerId(PlayerId()), Group, coords, heading)
end)

RegisterNUICallback("UI_RelocateVehicle", function (data, cb)
    cb({})
    local Group = {}
    Group[tonumber(data.networkID)] = tonumber(data.networkID)
    local coords = GetOffsetFromEntityInWorldCoords(PlayerPedId(), 0.0, (0.0), 0.0)
    local heading = GetEntityHeading(PlayerPedId())
    local vehHandle = NetworkGetEntityFromNetworkId(data.networkID)
    local isEmpty = IsVehicleSeatFree(vehHandle, -1)
    if isEmpty then
        if not IsPedInAnyVehicle(PlayerPedId(), false) then
            TriggerServerEvent("SEv_RelocateCharacter", GetPlayerServerId(PlayerId()), Group, coords, heading)
            Citizen.Wait(250)
        end
        TaskWarpPedIntoVehicle(PlayerPedId(), vehHandle, -1)
    else
        for i = -1, GetVehicleMaxNumberOfPassengers(vehHandle), 1 do
            if IsVehicleSeatFree(vehHandle, i) then
                TaskWarpPedIntoVehicle(PlayerPedId(), vehHandle, i)
            end
        end
    end
end)
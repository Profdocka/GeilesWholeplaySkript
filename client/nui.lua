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

RegisterNUICallback("UI_SpawnCharacterOrVehicle", function (data, cb)
    cb({})

    print("Der erhaltene Name: ", data.name)
    print("Die Variante: ", data.variant)

    local faction = data.name
    if data.variant == FRIENDLY_VARIANT then
        faction = "PLAYER"
    end

    TriggerServerEvent("SEv_CheckIfEntityIsKussKult", data.name, tonumber(data.variant), true,
    GetPlayerCoordsAndHeading(PlayerId(), 3.0), faction)
end)
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

    TriggerServerEvent("SEv_CheckIfEntityIsKussKult", data.name, PLAYER_VARIANT, true,
    GetPlayerCoordsAndHeading(PlayerId(), 0.0), data.name)
end)
---Command, der das Geile Wholeplay Script Menü öffnet und per Mapping auf
---F6 legt
RegisterCommand("UI_RequestOpenMenu", function()
    TriggerServerEvent("SEv_OpenMenu", GetPlayerServerId(PlayerId()))
end, false)
RegisterKeyMapping("UI_RequestOpenMenu", "", "keyboard", "F6")

---Schließt das Geile Wholeplay Script Menü
RegisterNUICallback("UI_CloseMenu", function(data, cb)
    cb({})
    SetNuiFocus(false, false)
    TriggerScreenblurFadeOut(3000)
end)

---Besorgt sich die dynamischen Daten vom Server, falls es im ersten Versuch nicht
---geklappt hat
RegisterNUICallback("UI_RequestMenuData", function(data, cb)
    cb({})
    TriggerServerEvent("SEv_RequestMenuData", GetPlayerServerId(PlayerId()))
end)

---Ereignis um ein Fahrzeug oder Charakter von der UI aus zu spawnen
RegisterNUICallback("UI_SpawnCharacterOrVehicle", function(data, cb)
    cb({})
    local faction = data.name
    if data.variant == PLAYER_VARIANT then
        faction = CustomFactionOrDefaultFaction(data.name)
        Citizen.Await(StopAllDriversRunningTasks())
    elseif data.variant == FRIENDLY_VARIANT then
        faction = "PLAYER"
    end
    TriggerServerEvent("SEv_CheckIfEntityIsKussKult", data.name, tonumber(data.variant), true,
        GetPlayerCoordsAndHeading(PlayerId(), 3.0), faction)
end)

---Ereignis um eine Fraktion von der UI aus zu spawnen
RegisterNUICallback("UI_SpawnGroup", function(data, cb)
    cb({})
    local exceptionTarget = "PLAYER"
    local vector4 = GetPlayerCoordsAndHeading(PlayerId(), 3.0)
    vector4 = nil
    TriggerServerEvent("SEv_CheckIfFactionIsKussKult", GetPlayerServerId(PlayerId()), data.name,
        VariantNumberToString(data.variant), true,
        vector4, exceptionTarget)
end)

---Ereignis um das Fahrzeug des Kuss Kult Charakters zu spawnen
RegisterNUICallback("UI_SpawnMyCar", function(data, cb)
    cb({})
    TriggerServerEvent("SEv_SpawnMyCar", GetPlayerServerId(PlayerId()))
end)

---Ereignis um sich zur Location zu teleportieren
RegisterNUICallback("UI_Teleport", function(data, cb)
    cb({})
    TeleportToLocationByCommand(data.name)
end)

---Ereignis um ein Diorama zu platzieren
RegisterNUICallback("UI_Diorama", function(data, cb)
    cb({})
    TriggerServerEvent("SEv_PlaceDiorama", data.name, GetPlayerServerId(PlayerId()))
end)

---Ereignis um einen Entity zu löschen
RegisterNUICallback("UI_DeleteEntity", function(data, cb)
    cb({})
    TriggerServerEvent("SEv_DeleteEntityByNetworkID", GetPlayerServerId(PlayerId()), data.networkID, data.variant)
end)

---Ereignis um die Gesinnung eines Charakters zu ändern
RegisterNUICallback("UI_ChangeAttitude", function(data, cb)
    cb({})
    TriggerServerEvent("SEv_ChangeCharacterAttitude", GetPlayerServerId(PlayerId()), data.variant, data.name)
end)

---Teleportiert einen Charakter zum Spieler
RegisterNUICallback("UI_RelocateCharacter", function(data, cb)
    cb({})
    local Group = {}
    Group[tonumber(data.networkID)] = tonumber(data.networkID)
    local coords = GetOffsetFromEntityInWorldCoords(PlayerPedId(), 0.0, (0.0), 0.0)
    local heading = GetEntityHeading(PlayerPedId())
    TriggerServerEvent("SEv_RelocateCharacter", GetPlayerServerId(PlayerId()), Group, coords, heading)
end)

---Teleportiert ein Fahrzeug zum Spieler oder den Spieler in dieses sollte es schon jemand fahren
RegisterNUICallback("UI_RelocateVehicle", function(data, cb)
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

-- ═══════════════════════════════════════════════════════════════
-- Neue NUI Callbacks für Submenüs (Optionen & Drivers)
-- ═══════════════════════════════════════════════════════════════

---Schaltet eine clientseitige Option um und gibt den neuen State an die UI zurück
RegisterNUICallback("UI_SetOption", function(data, cb)
    if data.option then
        EnableOption(data.option)
        local newState = false
        if data.option == "unbesiegbar" then
            newState = IsInvincible
        elseif data.option == "formation" then
            newState = WantsFormationSpawn
        elseif data.option == "blips" then
            newState = WantsBlips
        end
        cb({ newState = newState })
    else
        cb({})
    end
end)

---Spawnt eine Fahrgemeinschaft über die UI (entspricht gwspawndrivers)
RegisterNUICallback("UI_SpawnDrivers", function(data, cb)
    cb({})
    if data.vehicle then
        local args = { data.vehicle }
        if data.passengers then
            for _, name in ipairs(data.passengers) do
                table.insert(args, name)
            end
        end
        TriggerServerEvent("SEv_SpawnDriversFromUI", args)
    end
end)

---Setzt den Task einer Fahrgemeinschaft über die UI (entspricht gwdriverstask)
RegisterNUICallback("UI_DriversTask", function(data, cb)
    cb({})
    if data.vehicle and data.task then
        local args = { data.vehicle, data.task }
        if data.target then
            table.insert(args, data.target)
        end
        TriggerServerEvent("SEv_DriversTaskFromUI", args)
    end
end)

---Erstellt eine Fahrgemeinschaft aus bestehenden Aktiven (entspricht gwdrivers)
RegisterNUICallback("UI_DriversCreate", function(data, cb)
    cb({})
    if data.vehicle and data.members then
        local args = { data.vehicle }
        for _, name in ipairs(data.members) do
            table.insert(args, name)
        end
        TriggerServerEvent("SEv_DriversCreateFromUI", args)
    end
end)

---Aktualisiert die Passagiere einer Fahrgemeinschaft (entspricht gwdriversupdate)
RegisterNUICallback("UI_DriversUpdate", function(data, cb)
    cb({})
    if data.vehicle and data.driver then
        local args = { data.vehicle, data.driver }
        if data.passengers then
            for _, name in ipairs(data.passengers) do
                table.insert(args, name)
            end
        end
        TriggerServerEvent("SEv_DriversUpdateFromUI", args)
    end
end)

---Aktualisiert die Passagiere sitzplatzgenau über das Bearbeitungs-Panel
RegisterNUICallback("UI_DriversUpdateSeated", function(data, cb)
    cb({})
    if data.vehicle and data.seatMap then
        TriggerServerEvent("SEv_DriversUpdateSeatedFromUI", data.vehicle, data.seatMap)
    end
end)

MapMarkers = {}
Interiors = {}
FADEOUT_TIME = 300

RespawnCoords = { x = 0.0, y = 0.0, z = 0.0, heading = 0.0 }

RegisterCommand("gwtp", function(source, args, raw)
    if (args[1] ~= nil) then
        TeleportToLocationByCommand(args[1])
    else
        ShowNotification("Location vergessen")
    end
end, false)

RegisterCommand("gwspawnpoint", function(source)
    local vector4 = GetPlayerCoordsAndHeading(PlayerId(), 0.0)
    RespawnCoords = nil
    RespawnCoords = {}
    RespawnCoords = { x = vector4["coords"].x, y = vector4["coords"].y, z = vector4["coords"].z, heading = (vector4["heading"]) }
    ShowNotification("Dein Spawnpoint wurde gesetzt!~n~X: " ..
    vector4["coords"].x .. "~n~Y: " .. vector4["coords"].y .. "~n~Z: " .. vector4["coords"].z)
end, false)

RegisterCommand("gwclearspawnpoint", function(source)
    RespawnCoords = nil
    RespawnCoords = {}
    RespawnCoords = { x = 0.0, y = 0.0, z = 0.0, heading = 0.0 }
    ShowNotification("Dein Spawnpoint wurde entfernt!")
end, false)

---Ist ein Spawnpoint vorhanden, wird der Spieler und seine Gruppe dorthin teleportiert
TeleportToSetSpawnpoint = function()
    if RespawnCoords.x ~= 0.0 and RespawnCoords.y ~= 0.0 and RespawnCoords.z ~= 0.0 then
        local coords = { x = RespawnCoords.x, y = RespawnCoords.y, z = RespawnCoords.z }
        TriggerServerEvent("SEv_TeleportPlayer", GetPlayerServerId(PlayerId()), coords, RespawnCoords.heading)
    end
end

---Teleportiert den Spieler zu den Koordinaten ohne sein Fahrzeug
---@param source integer Server-ID
---@param Group table Network-IDs
---@param coords table
---@param heading integer
RegisterNetEvent("CEv_TeleportThePlayer", function(source, Group, coords, heading)
    if (source == GetPlayerServerId(PlayerId())) then
        TeleportThePlayer(coords, heading, false)
    end
end)

---Setzt alle Blips von Locations und Interiors mit Farbe, Symbol und Name auf die Karte des Spielers.
---Für jedes Interior wird ein Ausgang und Eingang in die Ingame-Welt platziert,
---über welchen man sich in das Interior rein und raus teleportieren kann.
Citizen.CreateThread(function()
    MapMarkers = Looker("blips", "client")
    for key, info in pairs(MapMarkers) do
        if info.isInterior == true then
            info.handle = AddBlipForCoord(info.extCoords.x, info.extCoords.y, info.extCoords.z)
            Interiors[key] = info
            SetBlipSprite(info.handle, info.blipId)
            SetBlipDisplay(info.handle, 4)
            SetBlipScale(info.handle, 0.8)
            SetBlipColour(info.handle, info.colour)
            SetBlipAsShortRange(info.handle, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(info.title)
            EndTextCommandSetBlipName(info.handle)
        else
            info.handle = AddBlipForCoord(info.x, info.y, info.z)
            SetBlipSprite(info.handle, info.blipId)
            SetBlipDisplay(info.handle, 4)
            SetBlipScale(info.handle, 1.0)
            SetBlipColour(info.handle, info.colour)
            SetBlipAsShortRange(info.handle, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(info.title)
            EndTextCommandSetBlipName(info.handle)
        end
    end
    while true do
        Citizen.Wait(10)
        for interiorKey, interiorValue in pairs(Interiors) do
            DrawMarker(1, interiorValue.intCoords.x, interiorValue.intCoords.y, interiorValue.intCoords.z - 1.0, 0.0, 0.0,
                0.0,
                0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0, 0, 255, 50, false, false, 2, false, nil, nil, false)
            DrawMarker(1, interiorValue.extCoords.x, interiorValue.extCoords.y, interiorValue.extCoords.z - 1.0, 0.0, 0.0,
                0.0,
                0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0, 0, 255, 50, false, false, 2, false, nil, nil, false)
            local vector4 = GetPlayerCoordsAndHeading(PlayerId(), 0.0)
            local isNear, isEntrance = IsPlayerNearMarker(vector4["coords"], interiorValue)
            while isNear do
                if isEntrance then
                    DrawMarker(1, interiorValue.extCoords.x, interiorValue.extCoords.y, interiorValue.extCoords.z - 1.0,
                        0.0,
                        0.0, 0.0,
                        0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0, 0, 255, 50, true, false, 2, false, nil, nil, false)
                    ShowHelpNotification("Drücke ~INPUT_PICKUP~ um " .. interiorValue.title .. " zu betreten", -1)
                    TeleportOnKeyPress(interiorValue.intCoords, vector4["heading"])
                else
                    DrawMarker(1, interiorValue.intCoords.x, interiorValue.intCoords.y, interiorValue.intCoords.z - 1.0,
                        0.0,
                        0.0, 0.0,
                        0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0, 0, 255, 50, true, false, 2, false, nil, nil, false)
                    ShowHelpNotification("Drücke ~INPUT_PICKUP~ um " .. interiorValue.title .. " zu verlassen", -1)
                    TeleportOnKeyPress(interiorValue.extCoords, vector4["heading"])
                end
                vector4 = GetPlayerCoordsAndHeading(PlayerId(), 0.0)
                isNear, isEntrance = IsPlayerNearMarker(vector4["coords"], interiorValue)
                Citizen.Wait(10)
            end
        end
    end
end)

---Prüft ob der Spieler sich im Radius eines Interior-Markers befindet.
---@param pCoords table Weltkoordinaten des Spielers
---@param interior table Informationen zum Interior
---@return boolean IstImRadius
---@return boolean IstDerEingangsMarker
function IsPlayerNearMarker(pCoords, interior)
    if Vdist2(pCoords.x, pCoords.y, pCoords.z, interior.intCoords.x, interior.intCoords.y, interior.intCoords.z) < 1.0 then
        return true, false
    elseif Vdist2(pCoords.x, pCoords.y, pCoords.z, interior.extCoords.x, interior.extCoords.y, interior.extCoords.z) < 1.0 then
        return true, true
    else
        return false
    end
end

---Wenn die Interaktionstaste gedrückt wird, so wird der Spieler zu den Koordinaten teleportiert.
---@param tpCoords table
---@param heading integer
function TeleportOnKeyPress(tpCoords, heading)
    if IsControlJustPressed(0, 38) then
        TriggerServerEvent("SEv_TeleportPlayer", GetPlayerServerId(PlayerId()), tpCoords, heading)
        Citizen.Wait(3000)
    end
end

---Sucht die Location und teleportiert den Spieler dorthin. Unter Umständen mit dessen Fahrzeug
---@param location string
TeleportToLocationByCommand = function(location)
    local found_location = nil
    found_location = MapMarkers[location]
    if (found_location ~= nil) then
        local coords = nil
        if found_location.isInterior then
            coords = found_location.intCoords
        else
            coords = { x = found_location.x, y = found_location.y, z = found_location.z }
        end
        local veh = GetVehiclePedIsIn(PlayerPedId(), false)
        if veh ~= 0 then
            if GetVehicleSeatOfPed(veh, PlayerPedId()) == -1 then
                TeleportThePlayer(coords, 0.0, true)
                return
            end
        end
        TriggerServerEvent("SEv_TeleportPlayer", GetPlayerServerId(PlayerId()), coords, 0.0)
    else
        ShowNotification("~r~Die Location gibt es nicht")
    end
end

---Teleportiert nur den Spieler.
---@param tpCoords table
---@param heading integer
---@param withVehicle boolean
TeleportThePlayer = function(tpCoords, heading, withVehicle)
    DoScreenFadeOut(FADEOUT_TIME)
    StartPlayerTeleport(PlayerId(), tpCoords.x, tpCoords.y, tpCoords.z, heading, withVehicle, true, true)
    Citizen.Wait(FADEOUT_TIME + 500)
    DoScreenFadeIn(FADEOUT_TIME)
end

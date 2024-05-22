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
end)

RegisterCommand("gwspawnpoint", function(source)
    local vector4 = GetPlayerCoordsAndHeading(PlayerId(), 0.0)
    RespawnCoords = nil
    RespawnCoords = {}
    RespawnCoords = { x = vector4["coords"].x, y = vector4["coords"].y, z = vector4["coords"].z, heading = (vector4["heading"]) }
    ShowNotification("Dein Spawnpoint wurde gesetzt!~n~X: " .. vector4["coords"].x .. "~n~Y: " .. vector4["coords"].y .. "~n~Z: " .. vector4["coords"].z)
end)

RegisterCommand("gwclearspawnpoint", function(source)
    RespawnCoords = nil
    RespawnCoords = {}
    RespawnCoords = { x = 0.0, y = 0.0, z = 0.0, heading = 0.0 }
    ShowNotification("Dein Spawnpoint wurde entfernt!")
end)

TeleportToSetSpawnpoint = function()
    if RespawnCoords.x ~= 0.0 and RespawnCoords.y ~= 0.0 and RespawnCoords.z ~= 0.0 then
        local coords = { x = RespawnCoords.x, y = RespawnCoords.y, z = RespawnCoords.z }
        TriggerServerEvent("SEv_TeleportPlayer", GetPlayerServerId(PlayerId()), coords, RespawnCoords.heading)
    end
end

RegisterNetEvent("CEv_TeleportThePlayer", function(source, Group, coords, heading)
    if (source == GetPlayerServerId(PlayerId())) then
        TeleportThePlayer(coords, heading, false)
    end
    --TeleportMultiple(Group, coords, heading)
end)

Citizen.CreateThread(function()
    --print("dupa")
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
            --print(key)
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
            --print("Der zu drawende Kram: ", interiorValue.title)
            DrawMarker(1, interiorValue.intCoords.x, interiorValue.intCoords.y, interiorValue.intCoords.z - 1.0, 0.0, 0.0,
                0.0,
                0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0, 0, 255, 50, false, false, 2, nil, nil, false)
            DrawMarker(1, interiorValue.extCoords.x, interiorValue.extCoords.y, interiorValue.extCoords.z - 1.0, 0.0, 0.0,
                0.0,
                0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0, 0, 255, 50, false, false, 2, nil, nil, false)
            local vector4 = GetPlayerCoordsAndHeading(PlayerId(), 0.0)
            local isNear, isEntrance = IsPlayerNearMarker(vector4["coords"], interiorValue)
            while isNear do
                if isEntrance then
                    DrawMarker(1, interiorValue.extCoords.x, interiorValue.extCoords.y, interiorValue.extCoords.z - 1.0,
                        0.0,
                        0.0, 0.0,
                        0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0, 0, 255, 50, true, false, 2, nil, nil, false)
                    ShowHelpNotification("Drücke ~INPUT_PICKUP~ um " .. interiorValue.title .. " zu betreten", -1)
                    TeleportOnKeyPress(interiorValue.intCoords, vector4["heading"])
                else
                    DrawMarker(1, interiorValue.intCoords.x, interiorValue.intCoords.y, interiorValue.intCoords.z - 1.0,
                        0.0,
                        0.0, 0.0,
                        0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0, 0, 255, 50, true, false, 2, nil, nil, false)
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

function IsPlayerNearMarker(pCoords, interior)
    if Vdist2(pCoords.x, pCoords.y, pCoords.z, interior.intCoords.x, interior.intCoords.y, interior.intCoords.z) < 1.0 then
        return true, false
    elseif Vdist2(pCoords.x, pCoords.y, pCoords.z, interior.extCoords.x, interior.extCoords.y, interior.extCoords.z) < 1.0 then
        return true, true
    else
        return false
    end
end

function TeleportOnKeyPress(tpCoords, heading)
    if IsControlJustPressed(0, 38) then
        TriggerServerEvent("SEv_TeleportPlayer", GetPlayerServerId(PlayerId()), tpCoords, heading)
        Citizen.Wait(3000)
    end
end

TeleportToLocationByCommand = function(location)
    local found_location = nil
    --[[
	for k, v in pairs(blips) do
		local leerloses_v = string.gsub(v.title, "%s", "")
		if string.lower(leerloses_v) == string.lower(location) then
			found_location = v
			break
		end
	end
    ]]
    --
    found_location = MapMarkers[location]
    if (found_location ~= nil) then
        local coords = nil
        if found_location.isInterior then
            coords = found_location.intCoords
        else
            coords = { x = found_location.x, y = found_location.y, z = found_location.z }
        end
        local veh = GetVehiclePedIsIn(PlayerPedId())
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

TeleportThePlayer = function(tpCoords, heading, withVehicle)
    DoScreenFadeOut(FADEOUT_TIME)
    StartPlayerTeleport(PlayerId(), tpCoords.x, tpCoords.y, tpCoords.z, heading, withVehicle, true, true)
    Citizen.Wait(FADEOUT_TIME + 500)
    DoScreenFadeIn(FADEOUT_TIME)
end
--[[
TeleportMultiple = function(GroupNet, coords, heading)
    for _, networkID in pairs(GroupNet) do
        local pedHandle = NetworkGetEntityFromNetworkId(networkID)
        print("NetId ", networkID)
        if not IsPedAPlayer(pedHandle) then
            SetEntityCoords(pedHandle, coords.x, coords.y, coords.z, false, false, false, false)
        end
        Citizen.Wait(10)
    end
end
]]
--

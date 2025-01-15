-- networkID
-- pedHandle
-- vehHandle
-- serverID / netID
CHARFOLDER = "characters"
VEHFOLDER = "vehicles"
VEHICLE_VARIANT = -1
PLAYER_VARIANT = 0
NEUTRAL_VARIANT = 1
FRIENDLY_VARIANT = 2
AGGRESSIVE_VARIANT = 3

HasJustJoined = true
IsInvincible = true
WantsFormationSpawn = true
WantsBlips = true
CHARACTER_SPAWN_OFFSET_Y = 3.0
PlayerToPlayerRelationship = 1
OwnFaction = ""
DoCountDown = true
LastWeaponsAndAmmoOfPlayer = {}
LastHealthAndArmorOfPlayer = {}

ActiveKussKultGamesHandler = {}
DriversTaskHandler = {}
DriversRunningTasks = {}
PlayerGroupID = 0
PlayerGroupHandles = {}
ThreadPriority = 0

KussBildDic = CreateRuntimeTxd('CHAR_KUSS')
KussBild = CreateRuntimeTextureFromImage(KussBildDic, 'CHAR_KUSS', "kusskultlogo.png")

---Thread der auf F7 das einfache Kuss Kult Spawn Textfeld für Spieleravatare
---und Fahrzeuge öffnet
Citizen.CreateThread(function()
    local sleepThread = 5
    while true do
        if IsControlJustPressed(0, 168) then
            local OutputString = GetInputWindowOutput("Name des Kuss Kult Charakters/Fahrzeugs");
            if OutputString ~= nil then
                Citizen.Wait(sleepThread)
                TriggerServerEvent("SEv_CheckIfEntityIsKussKult", OutputString, PLAYER_VARIANT, true,
                    GetPlayerCoordsAndHeading(PlayerId(), 0.0), CustomFactionOrDefaultFaction(OutputString))
                Citizen.Wait(1000)
            end
        end
        Citizen.Wait(sleepThread)
    end
end)

---DebugThread, der auf `Entf` alle Charaktere sofort zum Stillstand bringt
Citizen.CreateThread(function()
    while true do
        local sleepThread = 5
        if IsControlJustPressed(0, 214) then
            --TriggerServerEvent("SEv_ListAll", GetPlayerServerId(PlayerId()))
            TriggerServerEvent("SEv_StopAllCharacters", GetPlayerServerId(PlayerId()))
            ShowNotification("Alle Charaktere gestoppt!")
            Citizen.Wait(2000)
        end
        Citizen.Wait(sleepThread)
    end
end)

---Was mit dem Spieler passiert, sobald er in der Spielwelt gespawnt ist
---und sich bewegen kann
AddEventHandler("playerSpawned", function()
    Citizen.Wait(10)
    --Macht den Spieler nach dem Respawn zu Michael, sollte er ein Tier sein und gestorben sein
    if GetPedType(PlayerPedId()) == 28 then
        SearchHash(GetHashKey("player_zero"))
        SetPlayerModel(PlayerId(), GetHashKey("player_zero"))
    end
    Citizen.Wait(2000)
    --Veränderung der Schadensmultiplikatoren für KI Gegner
    SetAiWeaponDamageModifier(0.3)
    SetAiMeleeWeaponDamageModifier(0.3)
    --Gerade auf den Server gejoint => zufälliger Charakter
    --Sonst wenn er gestorben ist => eventuell zum Spawnpoint teleportiert und Charakter neugeladen
    if HasJustJoined then
        HasJustJoined = false
        TriggerServerEvent("SEv_PlayerSpawned", GetPlayerServerId(PlayerId()))
    else
        TeleportToSetSpawnpoint()
        Citizen.Wait(2000)
        ExecuteCommand("gwr", GetPlayerServerId(PlayerId()))
    end
end)

---Bekommt vom Server die Informationen zu den Fahrzeugen und Charakteren und
---schreibt sie in die Konsole
---@param _Players table
---@param _Characters table
---@param _Vehicles table
RegisterNetEvent("CEv_ListAll", function(_Players, _Characters, _Vehicles, _DriversInfo)
    ListAllOnClient(_Players, _Characters, _Vehicles, _DriversInfo)
end)

---Wenn eine Nachricht vom Server auf dem Client angezeigt werden soll
---@param msg any
RegisterNetEvent("CEv_ShowNotificationEvent", function(msg)
    ShowNotification(msg)
end)

---Ereignis um einen Charakter an den Koordinaten zu spawnen
---@param variant integer
---@param name string
---@param hasWeapon boolean
---@param vector4 table Ist nil dann wird ein Offset vom Spieler als Koordinate genommen
---@param faction string
RegisterNetEvent("CEv_SpawnCharacter", function(variant, name, hasWeapon, vector4, faction)
    if vector4 == nil then
        vector4 = GetPlayerCoordsAndHeading(PlayerId(), CHARACTER_SPAWN_OFFSET_Y)
    end
    if variant == PLAYER_VARIANT then
        Citizen.Await(StopAllDriversRunningTasks())
    end
    local pedHandle = SpawnCharacter(variant, name, hasWeapon, vector4)
    local networkID = NetworkGetNetworkIdFromEntity(pedHandle)
    SetNetworkIdExistsOnAllMachines(networkID, true)
    SetNetworkIdCanMigrate(networkID, true)
    TriggerServerEvent("SEv_GiveCharacterSkinAndFaction", variant, name, hasWeapon, faction, networkID,
        GetPlayerServerId(PlayerId()))
end)

---Ereignis um eine Gruppe von Charakteren an den Koordinaten zu spawnen
---Sonderfall: Wenn alle Charaktere zum Jahresabschluss "CHAOS" gespawnt werden,
---werden
---@param Group table
---@param variant integer
---@param hasWeapon boolean
---@param vector4 table
---@param faction string
RegisterNetEvent("CEv_SpawnMultipleCharacters", function(Group, variant, hasWeapon, vector4, faction)
    local shouldVector4Update = nil
    local includesMultipleVector4s = false
    local vector4List = nil
    local vector4offset = 1
    local GroupNetwork = {}
    local angleStep = 360.0 / #Group
    if vector4 == nil then
        shouldVector4Update = true
    else
        shouldVector4Update = false
        if vector4[2] ~= nil then
            includesMultipleVector4s = true
            vector4List = vector4
            vector4 = nil
        end
    end
    if WantsFormationSpawn then
        FreezeEntityPosition(PlayerPedId(), true)
    end
    if faction == "CHAOS" then
        CHARACTER_SPAWN_OFFSET_Y = 20.0
    end
    for _, characterName in pairs(Group) do
        if shouldVector4Update then
            vector4 = GetPlayerCoordsAndHeading(PlayerId(), CHARACTER_SPAWN_OFFSET_Y)
            local heading = vector4["heading"]
            if WantsFormationSpawn then
                SetEntityHeading(PlayerPedId(), heading + angleStep)
            end
        elseif includesMultipleVector4s then
            vector4 = vector4List[vector4offset]
            vector4offset = vector4offset + 1
        end
        local pedHandle = SpawnCharacter(variant, characterName, hasWeapon, vector4)
        local networkID = NetworkGetNetworkIdFromEntity(pedHandle)
        SetNetworkIdExistsOnAllMachines(networkID, true)
        SetNetworkIdCanMigrate(networkID, true)
        local characterNetwork = { networkID = networkID, name = characterName }
        GroupNetwork[networkID] = characterNetwork
        if faction == "CHAOS" then
            Citizen.Wait(500)
        end
    end
    print("Anzahl gespawnter Charaktere: ", #Group)
    if WantsFormationSpawn then
        FreezeEntityPosition(PlayerPedId(), false)
    end
    if faction == "CHAOS" then
        CHARACTER_SPAWN_OFFSET_Y = 3.0
    end
    TriggerServerEvent("SEv_GiveMultipleCharactersSkinAndFaction", GroupNetwork, variant, hasWeapon, faction,
        GetPlayerServerId(PlayerId()))
end)

RegisterNetEvent("CEv_SpawnMultipleCharactersDiorama", function(Group, variant, hasWeapon, vector4, faction)
    local tableOffset = 1
    local vector4List = vector4
    vector4 = nil
    local GroupNetwork = {}
    for _, characterName in pairs(Group) do
        vector4 = vector4List[tableOffset]
        local pedHandle = SpawnCharacter(variant, characterName, hasWeapon, vector4)
        local networkID = NetworkGetNetworkIdFromEntity(pedHandle)
        SetNetworkIdExistsOnAllMachines(networkID, true)
        SetNetworkIdCanMigrate(networkID, true)
        local characterNetwork = { networkID = networkID, name = characterName }
        GroupNetwork[networkID] = characterNetwork
        tableOffset = tableOffset + 1
    end
    print("Anzahl gespawnter Charaktere: ", #Group)
    TriggerServerEvent("SEv_GiveMultipleCharactersSkinAndFactionDiorama", GroupNetwork, variant, hasWeapon, faction,
        GetPlayerServerId(PlayerId()))
end)

---Ereignis um ein Fahrzeug an den Koordinaten zu spawnen
---@param name string Name des Fahrzeuges
---@param vector4 table
RegisterNetEvent("CEv_SpawnVehicle", function(name, vector4)
    local vehHandle = SpawnVehicle(name, vector4)
    local networkID = NetworkGetNetworkIdFromEntity(vehHandle)
    SetNetworkIdExistsOnAllMachines(networkID, true)
    SetNetworkIdCanMigrate(networkID, true)
    ShowNotification("Dein gespawntes Fahrzeug: " .. name)
    TriggerServerEvent("SEv_RegisterVehicle", name, networkID)
end)

---Ereignis um ein Fahrzeug an den Koordinaten eines Fahrers zu spawnen
---@param name string Name des Fahrzeuges
---@param networkIDDriver integer
RegisterNetEvent("CEv_SpawnVehicleForDriver", function(name, networkIDDriver)
    if TryForNetworkIDAvailability(networkIDDriver) then
        local driverHandle = NetworkGetEntityFromNetworkId(networkIDDriver)
        local coords = GetEntityCoords(driverHandle)
        local heading = GetEntityHeading(driverHandle)
        local vector4 = { coords = coords, heading = heading }
        local vehHandle = SpawnVehicle(name, vector4)
        TaskWarpPedIntoVehicle(driverHandle, vehHandle, -1)
        local networkID = NetworkGetNetworkIdFromEntity(vehHandle)
        SetNetworkIdExistsOnAllMachines(networkID, true)
        SetNetworkIdCanMigrate(networkID, true)
        ShowNotification("Dein gespawntes Fahrzeug: " .. name)
        TriggerServerEvent("SEv_RegisterVehicle", name, networkID)
    end
end)

RegisterNetEvent("CEv_SpawnMultipleVehicles", function(Group, vector4)
    local tableOffset = 1
    local vector4List = vector4
    vector4 = nil
    local GroupNetwork = {}
    for _, vehicleName in pairs(Group) do
        vector4 = vector4List[tableOffset]
        local vehHandle = SpawnVehicle(vehicleName, vector4)
        local networkID = NetworkGetNetworkIdFromEntity(vehHandle)
        SetNetworkIdExistsOnAllMachines(networkID, true)
        SetNetworkIdCanMigrate(networkID, true)
        local vehicleNetwork = { networkID = networkID, name = vehicleName }
        GroupNetwork[networkID] = vehicleNetwork
        ShowNotification("Dein gespawntes Fahrzeug: " .. vehicleName)
        tableOffset = tableOffset + 1
    end
    TriggerServerEvent("SEv_RegisterMultipleVehicles", GroupNetwork, networkID)
end)

---Ereignis um einen Charakter seine Kleidung und Rolle zu geben
---@param networkID integer
---@param skin string
---@param hasWeapon boolean
---@param source integer Server-ID
---@param variant integer
---@param FactionsAndMembersFromServer table
---@param FactionLeadersFromServer table
---@param PlayersFromServer table
RegisterNetEvent("CEv_GiveCharacterSkinAndRole",
    function(networkID, skin, hasWeapon, source, variant, FactionsAndMembersFromServer, FactionLeadersFromServer,
             PlayersFromServer, DriversInfoFromServer)
        if TryForNetworkIDAvailability(networkID) then
            local pedHandle = NetworkGetEntityFromNetworkId(networkID)
            local playerHandle = GetPlayerPed(GetPlayerFromServerId(source))
            local pedJson = Looker(skin, CHARFOLDER)
            Cosmetics(pedHandle, pedJson, hasWeapon)
            ApplyFactions(FactionsAndMembersFromServer, FactionLeadersFromServer, PlayersFromServer)
            if variant == PLAYER_VARIANT then
                AutomaticlyApplyRelationshipBetweenAllPlayers(FactionLeadersFromServer)
            elseif variant == AGGRESSIVE_VARIANT and playerHandle == PlayerPedId() then
                TakeOwnershipOfNetworkID(pedHandle, networkID)
                TaskCombatPed(pedHandle, playerHandle, 0, 16)
                if PlayersFromServer[networkID] == nil then
                    SetBlipAsFriendly(GetBlipFromEntity(pedHandle), false)
                    SetBlipColour(GetBlipFromEntity(pedHandle), 49)
                end
            end
            ApplyDrivers(DriversInfoFromServer)
        end
    end)

---Ereignis um mehreren Charakteren ihre Kleidung und Rolle zu geben
---@param GroupNetwork table
---@param hasWeapon boolean|table
---@param source integer
---@param variant integer
---@param FactionsAndMembersFromServer table
---@param FactionLeadersFromServer table
---@param PlayersFromServer table
RegisterNetEvent("CEv_GiveMultipleCharactersSkinAndRole",
    function(GroupNetwork, hasWeapon, source, variant, FactionsAndMembersFromServer, FactionLeadersFromServer,
             PlayersFromServer, DriversInfoFromServer)
        local pedHandle = nil
        local pedJson = nil
        local playerHandle = GetPlayerPed(GetPlayerFromServerId(source))
        local tableOffset = 1
        ApplyFactions(FactionsAndMembersFromServer, FactionLeadersFromServer, PlayersFromServer)
        for _, character in pairs(GroupNetwork) do
            if TryForNetworkIDAvailability(character.networkID) then
                pedHandle = NetworkGetEntityFromNetworkId(character.networkID)
                pedJson = Looker(character.name, CHARFOLDER)
                if hasWeapon == true or hasWeapon == false then
                    Cosmetics(pedHandle, pedJson, hasWeapon)
                else
                    Cosmetics(pedHandle, pedJson, hasWeapon[tableOffset])
                end
                if variant == AGGRESSIVE_VARIANT and playerHandle == PlayerPedId() then
                    TakeOwnershipOfNetworkID(pedHandle, character.networkID)
                    if not IsPedAPlayer(pedHandle) then
                        SetBlipAsFriendly(GetBlipFromEntity(pedHandle), false)
                        SetBlipColour(GetBlipFromEntity(pedHandle), 49)
                    end
                end
                tableOffset = tableOffset + 1
                Citizen.Wait(100)
            end
        end
        if variant == AGGRESSIVE_VARIANT and playerHandle == PlayerPedId() then
            TaskCombatPed(pedHandle, playerHandle, 0, 16)
        end
        ApplyDrivers(DriversInfoFromServer)
    end)

---Ereignis damit der Client die Rollen, nach NPC Rollenänderung, lokal bei sich zuweist
---@param FactionsAndMembersFromServer table
---@param FactionLeadersFromServer table
---@param networkIDEmitter integer
---@param networkIDReciever integer
---@param variant integer
---@param PlayersFromServer table
RegisterNetEvent("CEv_GiveRoles",
    function(FactionsAndMembersFromServer, FactionLeadersFromServer, networkIDEmitter, networkIDReciever, variant,
             PlayersFromServer, DriversInfoFromServer)
        ApplyFactions(FactionsAndMembersFromServer, FactionLeadersFromServer, PlayersFromServer)
        local recieverHandle = NetworkGetEntityFromNetworkId(networkIDReciever)
        local emitterHandle = NetworkGetEntityFromNetworkId(networkIDEmitter)
        if variant == AGGRESSIVE_VARIANT and emitterHandle == PlayerPedId() and TryForNetworkIDAvailability(networkIDEmitter) and TryForNetworkIDAvailability(networkIDReciever) then
            TakeOwnershipOfNetworkID(recieverHandle, networkIDReciever)
            TaskCombatPed(recieverHandle, emitterHandle, 0, 16)
            if PlayersFromServer[networkIDReciever] == nil then
                SetBlipAsFriendly(GetBlipFromEntity(recieverHandle), false)
                SetBlipColour(GetBlipFromEntity(recieverHandle), 49)
            end
        end
        ApplyDrivers(DriversInfoFromServer)
    end)

---Löscht einen Entity aus der Spielwelt
---@param variant integer
---@param networkID integer
---@param FactionsAndMembersFromServer table
---@param FactionLeadersFromServer table
---@param PlayersFromServer table
RegisterNetEvent("CEv_DropEntity",
    function(variant, networkID, FactionsAndMembersFromServer, FactionLeadersFromServer, PlayersFromServer,
             DriversInfoFromServer)
        Citizen.Await(StopAllDriversRunningTasks())
        if TryForNetworkIDAvailability(networkID) then
            local handle = NetworkGetEntityFromNetworkId(networkID)
            if variant == NEUTRAL_VARIANT then
                ClearPedTasksImmediately(handle)
                -- SetEntityAsMissionEntity(handle, false, false)
                RemoveBlip(GetBlipFromEntity(handle))
                DeletePed(handle)
                ApplyFactions(FactionsAndMembersFromServer, FactionLeadersFromServer, PlayersFromServer)
            else
                DeleteVehicle(handle)
            end
            ApplyDrivers(DriversInfoFromServer)
        end
    end)

---Löscht mehrere Entities aus der Spielwelt
---@param variant integer
---@param networkIDs integer
---@param FactionsAndMembersFromServer table
---@param FactionLeadersFromServer table
---@param PlayersFromServer table
RegisterNetEvent("CEv_DropMultipleEntitys",
    function(variant, networkIDs, FactionsAndMembersFromServer, FactionLeadersFromServer, PlayersFromServer,
             DriversInfoFromServer)
        local charsCounter = 0
        local vehCounter = 0
        Citizen.Await(StopAllDriversRunningTasks())
        for _, networkID in pairs(networkIDs) do
            if TryForNetworkIDAvailability(networkID) then
                local handle = NetworkGetEntityFromNetworkId(networkID)
                if variant == NEUTRAL_VARIANT then
                    ClearPedTasksImmediately(handle)
                    --SetEntityAsMissionEntity(handle, false, false)
                    RemoveBlip(GetBlipFromEntity(handle))
                    DeletePed(handle)
                    charsCounter = charsCounter + 1
                else
                    --SetEntityAsMissionEntity(handle, false, false)
                    DeleteVehicle(handle)
                    vehCounter = vehCounter + 1
                end
            end
        end
        print("Deleted " .. charsCounter .. " Character(s)")
        print("Deleted " .. vehCounter .. " Vehicle(s)")
        if variant == NEUTRAL_VARIANT then
            ApplyFactions(FactionsAndMembersFromServer, FactionLeadersFromServer, PlayersFromServer)
        end
        ApplyDrivers(DriversInfoFromServer)
    end)

---Löscht alle aktiven Kuss Kult Charaktere
---@param Characters table
---@param FactionsAndMembersFromServer table
---@param FactionLeadersFromServer table
---@param PlayersFromServer table
RegisterNetEvent("CEv_DropAllCharacters", function(Characters, FactionsAndMembersFromServer, FactionLeadersFromServer, PlayersFromServer, DriversInfoFromServer)
        local handle = nil
        local counter = 0
        Citizen.Await(StopAllDriversRunningTasks())
        for _, character in pairs(Characters) do
            if TryForNetworkIDAvailability(character.networkID) then
                handle = NetworkGetEntityFromNetworkId(character.networkID)
                ClearPedTasksImmediately(handle)
                --SetEntityAsMissionEntity(handle, false, false)
                RemoveBlip(GetBlipFromEntity(handle))
                DeletePed(handle)
                counter = counter + 1
            end
        end
        print("Deleted " .. counter .. " Character(s)")
        ApplyFactions(FactionsAndMembersFromServer, FactionLeadersFromServer, PlayersFromServer)
        ApplyDrivers(DriversInfoFromServer)
    end)

---Löscht alle aktiven Fahrzeuge
---@param Vehicles table
RegisterNetEvent("CEv_DropAllCars", function(Vehicles, DriversInfoFromServer)
    local handle = nil
    local counter = 0
    Citizen.Await(StopAllDriversRunningTasks())
    for _, vehicle in pairs(Vehicles) do
        if TryForNetworkIDAvailability(vehicle.networkID) then
            handle = NetworkGetEntityFromNetworkId(vehicle.networkID)
            --SetEntityAsMissionEntity(handle, false, false)
            DeleteVehicle(handle)
            counter = counter + 1
        end
    end
    print("Deleted " .. counter .. " Vehicle(s)")
end)

RegisterNetEvent("CEv_DropEverything",
    function(Characters, FactionsAndMembersFromServer, FactionLeadersFromServer, PlayersFromServer, DriversInfoFromServer,
             Vehicles)
        local handle = nil
        local pedCounter = 0
        Citizen.Await(StopAllDriversRunningTasks())
        for _, character in pairs(Characters) do
            if TryForNetworkIDAvailability(character.networkID) then
                handle = NetworkGetEntityFromNetworkId(character.networkID)
                ClearPedTasksImmediately(handle)
                SetEntityAsMissionEntity(handle, false, false)
                RemoveBlip(GetBlipFromEntity(handle))
                DeletePed(handle)
                pedCounter = pedCounter + 1
            end
        end
        local VehCounter = 0
        handle = nil
        for _, vehicle in pairs(Vehicles) do
            if TryForNetworkIDAvailability(vehicle.networkID) then
                handle = NetworkGetEntityFromNetworkId(vehicle.networkID)
                SetEntityAsMissionEntity(handle, false, false)
                DeleteVehicle(handle)
                VehCounter = VehCounter + 1
            end
        end
        ApplyFactions(FactionsAndMembersFromServer, FactionLeadersFromServer, PlayersFromServer)
        ApplyDrivers(DriversInfoFromServer)
        print("Deleted " .. pedCounter .. " Character(s)")
        print("Deleted " .. VehCounter .. " Vehicle(s)")
    end)

---Wendet alle Rollen clientseitig wieder an nach Spielerrollenänderung
---@param FactionsAndMembersFromServer table
---@param FactionLeadersFromServer table
---@param PlayersFromServer table
RegisterNetEvent("CEv_Regroup",
    function(FactionsAndMembersFromServer, FactionLeadersFromServer, PlayersFromServer, DriversInfoFromServer)
        ApplyFactions(FactionsAndMembersFromServer, FactionLeadersFromServer, PlayersFromServer)
        ApplyDrivers(DriversInfoFromServer)
    end)

---Wendet alle Verkleidungen der Charaktere und Spieler erneut. FÜR DIE GRÜNEN WILLIHAM HAARE
---@param PlayersFromServer table
---@param Characters table
RegisterNetEvent("CEv_ReskinAll", function(PlayersFromServer, Characters)
    for _, player in pairs(PlayersFromServer) do
        if TryForNetworkIDAvailability(player.networkID) then
            local pedHandle = NetworkGetEntityFromNetworkId(player.networkID)
            local pedJson = Looker(player.skin, CHARFOLDER)
            Cosmetics(pedHandle, pedJson, false)
        end
    end
    for _, character in pairs(Characters) do
        if TryForNetworkIDAvailability(character.networkID) then
            local pedHandle = NetworkGetEntityFromNetworkId(character.networkID)
            local pedJson = Looker(character.skin, CHARFOLDER)
            Cosmetics(pedHandle, pedJson, false)
        end
    end
end)

---Ereignis um alle Charaktere sofort zum Stillstand zu bringen
---@param Characters table
RegisterNetEvent("CEv_StopAllCharacters", function(Characters)
    for _, character in pairs(Characters) do
        if TryForNetworkIDAvailability(character.networkID) then
            local pedHandle = NetworkGetEntityFromNetworkId(character.networkID)
            ClearPedTasksImmediately(pedHandle)
        end
    end
end)

---Ereignis um einen toten Charakter wieder zum Leben zu erwecken
---@param character table
RegisterNetEvent("CEv_RevieveDeadPed", function(character)
    local pedHandle = NetworkGetEntityFromNetworkId(character.networkID)
    if IsEntityDead(pedHandle) then
        ResurrectPed(pedHandle)
        ClearPedTasksImmediately(pedHandle)
    end
end)

---Prüft alle Fahrzeuge und Charaktere durch, ob sie kaputt oder tot sind
---und sendet die Liste an den Server, damit dieser die löschen kann
---@param Characters table
---@param Vehicles table
RegisterNetEvent("CEv_DeadGarbageCleanerCheck", function(Characters, Vehicles)
    local deadCharacters, deadVehicles = {}, {}
    for _, character in pairs(Characters) do
        local pedHandle = NetworkGetEntityFromNetworkId(character.networkID)
        if IsEntityDead(pedHandle) then
            deadCharacters[character.networkID] = character.networkID
        end
    end
    for _, vehicle in pairs(Vehicles) do
        local vehHandle = NetworkGetEntityFromNetworkId(vehicle.networkID)
        if GetVehicleEngineHealth(vehHandle) < 0 then
            deadVehicles[vehicle.networkID] = vehicle.networkID
        end
    end
    if next(deadCharacters) ~= nil or next(deadVehicles) ~= nil then
        TriggerServerEvent("SEv_DeadGarbageCleaner", deadCharacters, deadVehicles)
    end
end)

---Event um einen Countdown zu starten
---@param duration integer Dauer in Millisekunden
RegisterNetEvent("CEv_ShowCountdown", function(duration)
    CancelCountdown()
    ShowTimeMessage(duration)
end)

---Event um den aktuellen Countdown zu beenden
RegisterNetEvent("CEv_CancelCountdown", function()
    CancelCountdown()
end)

---Event um einen Loadout beim Spieler auszurüsten
---@param loadoutname string
---@param removeWeapons boolean
RegisterNetEvent("CEv_EquipLoadout", function(loadoutname, removeWeapons)
    EquipWeaponLoadout(loadoutname, removeWeapons)
end)

---Event das geworfen wird, wenn ein Kuss Kult Charakter mit den Cosmetics fertig ist
RegisterNetEvent("CEv_SetKussKultCosmeticsFinished")

---Event um die Event-Handler für Twouble in Kuss Kult anzubringen
---@param actors table serverIds der Spieler sortiert nach Rollen
RegisterNetEvent("CEv_SetUpTwoubleHandler", function(actors)
    IsInvincible = false
    local playerRole = GetTwoubleRoleOfPlayer(actors)
    ActiveKussKultGamesHandler.TwoubleHandlerDeath = AddEventHandler("baseevents:onPlayerKilled", function()
        TriggerServerEvent("SEv_TwoubleDeathHandler", GetPlayerServerId(PlayerId()))
    end)
    ActiveKussKultGamesHandler.TwoubleHandlerSuicide = AddEventHandler("baseevents:onPlayerDied", function()
        TriggerServerEvent("SEv_TwoubleDeathHandler", GetPlayerServerId(PlayerId()))
    end)
    ActiveKussKultGamesHandler.TwoubleLoadOutHandler = AddEventHandler("CEv_SetKussKultCosmeticsFinished",
        function(pedHandle)
            if IsPedAPlayer(pedHandle) and GetPlayerPed(-1) == pedHandle then
                SetEntityHealth(GetPlayerPed(-1), LastHealthAndArmorOfPlayer.health)
                SetPedArmour(GetPlayerPed(-1), LastHealthAndArmorOfPlayer.armor)
                RemoveAllPedWeapons(GetPlayerPed(-1), false)
                for _, weapon in pairs(LastWeaponsAndAmmoOfPlayer) do
                    GiveDelayedWeaponToPed(pedHandle, weapon.weapon, weapon.ammo, false)
                    Citizen.Wait(5)
                end
            end
        end)
    SetPlayerInvincibleKeepRagdollEnabled(PlayerId(), IsInvincible)
end)

---Event um alle Client-Event-Handler eines Kuss Kult Spiels zu entfernen
RegisterNetEvent("CEv_RemoveKussKultGamesHandler", function()
    for _, handler in pairs(ActiveKussKultGamesHandler) do
        RemoveEventHandler(handler)
    end
    IsInvincible = true
    SetPlayerInvincibleKeepRagdollEnabled(PlayerId(), IsInvincible)
end)

--Unused
RegisterNetEvent("CEv_SwitchCharacters",
    function(hostPlayer, targetNet, FactionsAndMembersFromServer, FactionLeadersFromServer, PlayersFromServer)
        if GetPlayerFromServerId(hostPlayer) ~= -1 and TryForNetworkIDAvailability(targetNet) then
            local hostPed = GetPlayerPed(GetPlayerFromServerId(hostPlayer))
            local hostPlayerLocal = GetPlayerFromServerId(hostPlayer)
            local targetPed = NetworkGetEntityFromNetworkId(targetNet)
            print("Der Player: " .. hostPlayerLocal)
            print("Das Ziel: " .. targetPed)
            print("Switch beginnt!")
            SetPlayerInvincibleKeepRagdollEnabled(hostPlayerLocal, false)
            TakeOwnershipOfNetworkID(targetPed, targetNet)
            NetworkRequestControlOfEntity(targetPed)
            Citizen.Wait(NETWORK_ID_SYNC_DELAY)
            ChangePlayerPed(hostPlayerLocal, targetPed, true, true)
            SetEntityAsMissionEntity(hostPed, true, true)
            SetPlayerInvincibleKeepRagdollEnabled(hostPlayerLocal, IsInvincible)
            ApplyCharacterModifiers(targetPed, false)
            ApplyCharacterModifiers(hostPed, true)
            print("Switch fertig!")
            ApplyFactions(FactionsAndMembersFromServer, FactionLeadersFromServer, PlayersFromServer)
        end
    end)

---Event für den Charakterwechsel auf Clientseite
---@param source number
---@param targetCharacter table
---@param sourceCharacter table
---@param DriversInfoFromServer table
RegisterNetEvent("CEv_SwitchCharactersIsDeadCheck", function(source, targetCharacter, sourceCharacter, DriversInfoFromServer)
        if TryForNetworkIDAvailability(targetCharacter.networkID) and TryForNetworkIDAvailability(sourceCharacter.networkID) then
            local targetPed = NetworkGetEntityFromNetworkId(targetCharacter.networkID)
            local sourcePed = NetworkGetEntityFromNetworkId(sourceCharacter.networkID)
            if IsEntityDead(targetPed) == false then
                local sourceFeatures = GetFeaturesOfPed(sourcePed)
                local targetFeatures = GetFeaturesOfPed(targetPed)
                sourceFeatures["vector4"]["heading"] = sourceFeatures["vector4"]["heading"] - 180
                if sourceFeatures["vehicle"] ~= nil then
                    ClearPedTasksImmediately(sourcePed)
                    targetPed = SpawnCharacter(NEUTRAL_VARIANT, sourceCharacter.skin, false, sourceFeatures["vector4"])
                else
                    targetPed = SpawnCharacter(NEUTRAL_VARIANT, sourceCharacter.skin, true, sourceFeatures["vector4"])
                end
                Citizen.Await(AwaitEntityExists(targetPed))
                local newTargetNet = NetworkGetNetworkIdFromEntity(targetPed)
                SetNetworkIdExistsOnAllMachines(newTargetNet, true)
                SetNetworkIdCanMigrate(newTargetNet, true)
                sourcePed = SpawnCharacter(PLAYER_VARIANT, targetCharacter.skin, true, targetFeatures["vector4"])
                Citizen.Await(AwaitEntityExists(sourcePed))
                local sourceJson = Looker(targetCharacter.skin, CHARFOLDER)
                Cosmetics(sourcePed, sourceJson, true)
                Citizen.Await(AwaitUntilPedLeftVehicle(sourcePed, GetVehiclePedIsIn(sourcePed, false)))
                TriggerServerEvent("SEv_SwitchCharacters", source, targetCharacter, sourceCharacter, targetFeatures,
                    sourceFeatures, newTargetNet)
            else
                ShowNotification("~r~Das Ziel " .. targetCharacter.name .. " ist tot!")
            end
        end
    end)

---Event um die abschließenden Charakterwechseländerungen (Switch) anzuwenden
---@param toFeatures table
---@param fromFeatures table
---@param targetNet number
---@param sourceNet number
RegisterNetEvent("CEv_ApplySwitchFeatures", function(toFeatures, fromFeatures, targetNet, sourceNet)
    if TryForNetworkIDAvailability(targetNet) and TryForNetworkIDAvailability(sourceNet) then
        local targetPed = NetworkGetEntityFromNetworkId(targetNet)
        local sourcePed = NetworkGetEntityFromNetworkId(sourceNet)
        SetEntityHealth(targetPed, fromFeatures["health"])
        SetPedArmour(targetPed, fromFeatures["armor"])
        if toFeatures["vehicle"] ~= nil then
            if TryForNetworkIDAvailability(toFeatures["vehicle"]) then
                local vehicleHandle =  NetworkGetEntityFromNetworkId(toFeatures["vehicle"])
                while not IsVehicleSeatFree(vehicleHandle, toFeatures["seatIndex"]) do
                    Wait(500)
                end
                TaskWarpPedIntoVehicle(sourcePed, vehicleHandle,
                    toFeatures["seatIndex"])
                --Citizen.Await(AwaitUntilPedEnteredVehicle(sourceHandle, NetworkGetEntityFromNetworkId(targetFeatures["vehicle"])))    
            end
        end
        SetEntityHealth(sourcePed, toFeatures["health"])
        SetPedArmour(sourcePed, toFeatures["armor"])
    end
end)

---Event um ein Fahrzeug direkt mit Charakteren drin zu spawnen
---@param vehicleName string
---@param vector4 table
---@param characterGroup table
RegisterNetEvent("CEv_SpawnVehicleWithCharacters", function(vehicleName, vector4, characterGroup)
        SpawnVehicleWithCharacters(vehicleName, vector4, characterGroup)
    end)

---Sendet alle statischen Informationen an die UI
---@param CharacterSkins table
---@param VehicleSkins table
---@param allFactions table
---@param ownersOfVehicles table
RegisterNetEvent("CEvUI_InitialGWInfos", function(CharacterSkins, VehicleSkins, allFactions, ownersOfVehicles)
    SendNUIMessage({
        type = "GW_InitialInfos",
        characterSkins = CharacterSkins,
        vehicleSkins = VehicleSkins,
        allFactions = allFactions,
        myVehicles = ownersOfVehicles,
        locations = MapMarkers
    })
end)

---Öffnet das Geile Wholeplay Menü und schickt die dynamischen Informationen an die UI
---@param Players table
---@param Characters table
---@param Vehicles table
---@param playerName string
RegisterNetEvent("CEvUI_OpenMenu", function(Players, Characters, Vehicles, playerName, dioramas)
    for _, playerid in pairs(GetActivePlayers()) do
        local networkid = GetNetworkIDPlayerFromSource(playerid)
        local playername = GetPlayerName(playerid)
        Players[networkid].playerName = playername
    end
    SendNUIMessage({
        type = "GW_OpenMenu",
        players = Players,
        characters = Characters,
        vehicles = Vehicles,
        playerName = playerName,
        dioramas = dioramas
    })
    SetNuiFocus(true, true)
    TriggerScreenblurFadeIn(3000)
end)

---Distanz zwischen zwei Punkten im 3D Raum
---@param v1 any
---@param v2 any
---@return number
VectDist = function(v1, v2)
    local sum = 0
    for axis, value in pairs(v1) do
        sum = sum + (v1[axis] - v2[axis]) ^ 2
    end
    return math.sqrt(sum)
end

---Sucht anhand von `name` das Kuss Kult Fahrzeug
---und spawnt das Fahrzeugmodell in der Spielwelt
---@param name string Name des Kuss Kult Fahrzeuges
---@param vector4 table
---@return integer vehHandle
SpawnVehicle = function(name, vector4)
	local vehicleJson = Looker(name, VEHFOLDER)
	local modelHash = vehicleJson.Vehicle.ModelHash
	modelHash = tonumber(modelHash)
	if SearchHash(modelHash) then
		local vehHandle = BuildVehicle(modelHash, vehicleJson, vector4)
		SetModelAsNoLongerNeeded(modelHash)
		return vehHandle
	end
end

---Ein Fahrzeug mit dem `modelHash` wird
---an den Koordinaten des Fahrers gespawnt
---@param modelHash integer
---@param vehicleJson table
---@param vector4 table
---@return integer vehHandle
BuildVehicle = function(modelHash, vehicleJson, vector4)
	local carMis = vehicleJson.Vehicle.VehicleProperties
	local carColors = vehicleJson.Vehicle.VehicleProperties.Colours
	local carNeon = vehicleJson.Vehicle.VehicleProperties.Neons
	local carExtras = vehicleJson.Vehicle.VehicleProperties.ModExtras
	local carMods = vehicleJson.Vehicle.VehicleProperties.Mods
	local coords = vector4["coords"]
	local heading = vector4["heading"]
	local vehHandle = CreateVehicle(modelHash, coords.x, coords.y, coords.z, heading, true, false)
	SetEntityAsMissionEntity(vehHandle, true, true)
	SetVehicleOnGroundProperly(vehHandle)
	SetVehicleDirtLevel(vehHandle, 0.0)
	VehicleAddons(vehHandle, carMis, carColors, carNeon, carExtras, carMods)
	return vehHandle
end

---Äußerliche Modifikationen werden am Fahrzeug vorgenommen
---@param vehHandle integer
---@param carMis table
---@param carColors table
---@param carNeon table
---@param carExtras table
---@param carMods table
VehicleAddons = function(vehHandle, carMis, carColors, carNeon, carExtras, carMods)
	Colors(vehHandle, carColors)
	Mis(vehHandle, carMis)
	Neons(vehHandle, carNeon)
	Extras(vehHandle, carExtras)
	Mods(vehHandle, carMods)
	--Speed(vehHandle, carMis)
end

---Spawnt ein Fahrzeug an der besagten Position mit den Charakteren als Fahrzeuginsassen
---@param vehicleName string
---@param vector4 table
---@param characterGroup table {[-1] = passengerName1, [0] = passengerName2}
SpawnVehicleWithCharacters = function(vehicleName, vector4, characterGroup)
    local GroupNetwork = {}
    local vehHandle = SpawnVehicle(vehicleName, vector4)
    local VehNetworkID = NetworkGetNetworkIdFromEntity(vehHandle)
    SetNetworkIdExistsOnAllMachines(VehNetworkID, true)
    SetNetworkIdCanMigrate(VehNetworkID, true)
    local vehicle = { networkID = VehNetworkID, name = vehicleName }
    local capacity = GetVehicleModelNumberOfSeats(GetEntityModel(vehHandle))
    ShowNotification("Dein gespawntes Fahrzeug: " .. vehicleName)
    for seatIndex, character in pairs(characterGroup) do
        if seatIndex < capacity then
            local pedHandle = SpawnCharacterInVehicle(NEUTRAL_VARIANT, character, true, vehHandle,
                seatIndex)
            local pedNetworkID = NetworkGetNetworkIdFromEntity(pedHandle)
            SetNetworkIdExistsOnAllMachines(pedNetworkID, true)
            SetNetworkIdCanMigrate(pedNetworkID, true)
            local characterNetwork = {
                networkID = pedNetworkID,
                name = character,
                faction = characterGroup[-1],
                variant = NEUTRAL_VARIANT
            }
            GroupNetwork[seatIndex] = characterNetwork
        end
    end
    TriggerServerEvent("SEv_RegisterVehicleAndCharactersForDrivers", vehicle, GroupNetwork, capacity,
        GetPlayerServerId(PlayerId()))
end
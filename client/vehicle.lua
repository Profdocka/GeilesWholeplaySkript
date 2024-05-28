---Sucht anhand von `name` das Kuss Kult Fahrzeug
---und spawnt das Fahrzeugmodell in der Spielwelt
---@param name string Name des Kuss Kult Fahrzeuges
---@param driver integer
---@return integer vehHandle
SpawnVehicle = function(name, driver)
	local vehicleJson = Looker(name, VEHFOLDER)
	local modelHash = vehicleJson.Vehicle.ModelHash
	modelHash = tonumber(modelHash)
	if SearchHash(modelHash) then
		local vehHandle = BuildVehicle(modelHash, vehicleJson, driver)
		SetModelAsNoLongerNeeded(modelHash)
		return vehHandle
	end
end

---Ein Fahrzeug mit dem `modelHash` wird
---an den Koordinaten des Fahrers gespawnt
---@param modelHash integer
---@param vehicleJson table
---@param driver integer
---@return integer vehHandle
BuildVehicle = function(modelHash, vehicleJson, driver)
	local carMis = vehicleJson.Vehicle.VehicleProperties
	local carColors = vehicleJson.Vehicle.VehicleProperties.Colours
	local carNeon = vehicleJson.Vehicle.VehicleProperties.Neons
	local carExtras = vehicleJson.Vehicle.VehicleProperties.ModExtras
	local carMods = vehicleJson.Vehicle.VehicleProperties.Mods
	local coords = GetEntityCoords(driver)
	local heading = GetEntityHeading(driver)
	local vehHandle = CreateVehicle(modelHash, coords.x, coords.y, coords.z, heading, true, true)
	Citizen.Wait(800)
	SetVehicleOnGroundProperly(vehHandle)
	SetVehicleDirtLevel(vehHandle, 0.0)
	TaskWarpPedIntoVehicle(driver, vehHandle, -1)
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
	Speed(vehHandle, carMis)
end

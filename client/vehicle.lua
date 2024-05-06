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

BuildVehicle = function(modelHash, vehicleJson, driver)
	local carMis = vehicleJson.Vehicle.VehicleProperties
	local carColors = vehicleJson.Vehicle.VehicleProperties.Colours
	local carNeon = vehicleJson.Vehicle.VehicleProperties.Neons
	local carExtras = vehicleJson.Vehicle.VehicleProperties.ModExtras
	local carMods = vehicleJson.Vehicle.VehicleProperties.Mods

	local coords = GetEntityCoords(driver)
	local heading = GetEntityHeading(driver)
	local vehHandle = CreateVehicle(modelHash, coords.x, coords.y, coords.z, heading, true, true)
	SetVehicleOnGroundProperly(vehHandle)
	SetVehicleDirtLevel(vehHandle, 0.0)
	TaskWarpPedIntoVehicle(driver, vehHandle, -1)

	VehicleAddons(vehHandle, carMis, carColors, carNeon, carExtras, carMods)
	return vehHandle
end

VehicleAddons = function(vehHandle, carMis, carColors, carNeon, carExtras, carMods)
	--Colors
	Colors(vehHandle, carColors)

	--Sonstiges
	Mis(vehHandle, carMis)

	--Neonlichter
	Neons(vehHandle, carNeon)

	--Extras
	Extras(vehHandle, carExtras)

	--Modifikationen
	Mods(vehHandle, carMods)

	--Speed
	Speed(vehHandle, carMis)
end

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

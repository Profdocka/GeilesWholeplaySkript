---Ändert am Fahrzeug die Farbe von Lakierung, Lichtern und Reifenqualm
---@param vehicle integer
---@param carColors table
Colors = function(vehicle, carColors)
	SetVehicleColours(vehicle, tonumber(carColors.Primary), tonumber(carColors.Secondary))
	SetVehicleExtraColours(vehicle, tonumber(carColors.Pearl), tonumber(carColors.Rim))
	SetVehicleTyreSmokeColor(vehicle, tonumber(carColors.tyreSmoke_R), tonumber(carColors.tyreSmoke_G),
		tonumber(carColors.tyreSmoke_B))
	SetVehicleInteriorColor(vehicle, tonumber(carColors.LrInterior))
	SetVehicleDashboardColor(vehicle, tonumber(carColors.LrDashboard))
	SetVehicleXenonLightsColor(vehicle, tonumber(carColors.LrXenonHeadlights))
end

---Ändert am Fahrzeug verschiedene Dinge wie das Kennzeichen und die Reifenart
---@param vehicle any
---@param carMis any
Mis = function(vehicle, carMis)
	SetVehicleLivery(vehicle, tonumber(carMis.Livery))
	SetVehicleNumberPlateText(vehicle, carMis.NumberPlateText)
	SetVehicleNumberPlateTextIndex(vehicle, tonumber(carMis.NumberPlateIndex))
	SetVehicleWheelType(vehicle, tonumber(carMis.WheelType))
	SetVehicleWindowTint(vehicle, tonumber(carMis.WindowTint))
	SetVehicleTyresCanBurst(vehicle, carMis.BulletProofTyres)
end

---Ändert die Neon Unterbodenbeleuchtung
---@param vehicle integer
---@param carNeon table
Neons = function(vehicle, carNeon)
	local left = TrueFalseInverter(carNeon.Left)
	local right = TrueFalseInverter(carNeon.Right)
	local front = TrueFalseInverter(carNeon.Front)
	local back = TrueFalseInverter(carNeon.Back)
	SetVehicleNeonLightEnabled(vehicle, 0, left)
	SetVehicleNeonLightEnabled(vehicle, 1, right)
	SetVehicleNeonLightEnabled(vehicle, 2, front)
	SetVehicleNeonLightEnabled(vehicle, 3, back)
	SetVehicleNeonLightsColour(vehicle, tonumber(carNeon.R), tonumber(carNeon.G), tonumber(carNeon.B))
end

---Schaltet fahrzeugspezifische visuelle Extras ein
---@param vehicle integer
---@param carExtras table
Extras = function(vehicle, carExtras)
	if (carExtras ~= nil) then
		for i = 0, 13 do
			local node = carExtras["_" .. i]
			if (node ~= nil) then
				local booli = nil
				if (node == "true") then
					booli = false
				else
					booli = true
				end
				SetVehicleExtra(vehicle, i, booli)
			end
		end
	end
end

---Ändert die verschidenen Komponenten des Fahrzeugs, wie Kühlergrill, Spoiler und Auspuff
---@param vehicle integer
---@param carMods table
Mods = function(vehicle, carMods)
	SetVehicleModKit(vehicle, 0)
	for i = 0, 48 do
		local whole = carMods["_" .. i]
		local mod = nil
		local texture = nil

		if (whole == "false") then
			mod = false
			ToggleVehicleMod(vehicle, i, mod)
		elseif (whole == "true") then
			mod = true
			ToggleVehicleMod(vehicle, i, mod)
		else
			mod, texture = string.match(whole, "(-?%d+),(%d+)")
			mod = tonumber(mod)
			SetVehicleMod(vehicle, i, mod, false)
		end
	end
end

---Ändert die Maximalgeschwindigkeit des Fahrzeuges
---Unsicher ob das überhaupt etwas ändert
---@param vehicle integer
---@param carMis table
Speed = function(vehicle, carMis)
	local torque = carMis.TorqueMultiplier
	local speed = carMis.MaxSpeed
	if (torque ~= nil) then
		SetVehicleCheatPowerIncrease(vehicle, torque)
	end
	if (speed ~= nil) then
		SetVehicleMaxSpeed(vehicle, speed)
	end
end

---Gibt bei True False zurück.
---Eine Sache funktionierte so komisch und brauchte das.
---Deswegen ist das hier
---@param input string
---@return boolean
TrueFalseInverter = function(input)
	local out = false
	if (input == "true") then
		out = true
	else
		out = false
	end
	return out
end

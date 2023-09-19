GetInputWindowOutput = function()
	DisplayOnscreenKeyboard(1, "FMMC_MPM_NA", "", "", "", "", "", 30)

	while UpdateOnscreenKeyboard() == 0 do
		DisableAllControlActions(0)
		Wait(0)
	end

	if GetOnscreenKeyboardResult() then
		return GetOnscreenKeyboardResult()
	end
end

--Sucht den Entity aus den Resourcen und gibt die JSON zurück, findet er ihn nicht,
-- gibt er nil zurück
Looker = function(input, folder)
	if (input ~= nil) then
		local path = folder .. "/" .. input .. ".json"
		print(path)
		local file = LoadResourceFile(GetCurrentResourceName(), path)
		local content = {}
		content = json.decode(file)
		return content
	else
		return nil
	end
end

--Lädt den gewünschten Hash aus dem Spielverzeichnis
SearchHash = function(hash)
	if (IsModelInCdimage(hash)) then
		RequestModel(hash)
		while not HasModelLoaded(hash) do
			Citizen.Wait(5)
		end
		return true
	else
		return false
	end
end

GetCurrentVehicleAndSeatNumber = function(pedHandle)
    local vehHandle = GetVehiclePedIsIn(pedHandle, false)
    if vehHandle ~= 0 then
        local seatOfPlayer = GetVehicleSeatOfPed(vehHandle, pedHandle)
        return vehHandle, seatOfPlayer
    end
    return nil
end
---Alle kosmetischen Veränderungen am Charaktermodell
---@param pedHandle integer
---@param pedJson table
---@param ShouldHaveWeapon boolean
Cosmetics = function(pedHandle, pedJson, ShouldHaveWeapon)
	local pedHash = pedJson.OutfitPedData.ModelHash
	local pedComps = pedJson.OutfitPedData.PedProperties.PedComps
	local pedProps = pedJson.OutfitPedData.PedProperties.PedProps
	local pedWalk = pedJson.OutfitPedData.PedProperties.WalkStyle
	local pedWeapon = pedJson.OutfitPedData.PedProperties.Weapon
	local pedVoice = pedJson.OutfitPedData.PedProperties.Voice

	local pedDecals = pedJson.OutfitPedData.PedProperties.TattooLogoDecals
	if pedDecals ~= nil then
		pedDecals = pedDecals[":anonymous"]
	end

	pedHash = tonumber(pedHash)

	ClearAllPedProps(pedHandle)
	SetEntityMaxHealth(pedHandle, 200)
	SetEntityHealth(pedHandle, 200)
	SetPedArmour(pedHandle, 100)
	Components(pedHandle, pedComps)
	Props(pedHandle, pedProps, pedHash)

	if (pedHash == 1885233650 or pedHash == -1667301416) then
		local headFeatures = pedJson.OutfitPedData.PedProperties.HeadFeatures
		Freemode(pedHandle, headFeatures)
	end
	if pedDecals ~= nil then
		Decals(pedHandle, pedDecals)
	end
	ResetPedMovementClipset(pedHandle, 0.5)
	if (pedWalk ~= nil) then
		Walkstyle(pedHandle, pedWalk)
	end
	if (pedWeapon ~= nil and ShouldHaveWeapon == true) then
		Weapon(pedHandle, pedWeapon)
	end
	if pedVoice ~= nil then
		Voice(pedHandle, pedVoice)
	end
	TriggerEvent("CEv_SetKussKultCosmeticsFinished", pedHandle)
end

---Körpergruppen des Charakters wie Kopf, Oberteil und Hosen
---@param pedHandle integer
---@param pedComps table Die Komponenten-IDs mit ihrer Textur-ID
Components = function(pedHandle, pedComps)
	for i = 0, 11 do
		local whole = pedComps["_" .. i]
		local prop, texture = string.match(whole, "(-?%d+),(-?%d+)")
		SetPedComponentVariation(pedHandle, i, tonumber(prop), tonumber(texture), 2)
	end
end

---Accessoires des Charakters wie Hut, Brille und Armbanduhr
---@param pedHandle integer
---@param pedProps table Die Prop-IDs mit ihrer Textur-ID
---@param pedHash integer
Props = function(pedHandle, pedProps, pedHash)
	local findex = { 0, 1, 2, 6, 7 }
	for i = 1, #findex do
		local whole = pedProps["_" .. findex[i]]
		local prop, texture = string.match(whole, "(-?%d+),(-?%d+)")
		if (prop ~= "-1") then
			SetPedPropIndex(pedHandle, findex[i], tonumber(prop), tonumber(texture), false)
		else
			if pedHash == 1885233650 then
				CorrectionPropFreemodeMale[findex[i]](pedHandle)
			else
				CorrectionProp[findex[i]](pedHandle)
			end
		end
	end
end

---Setter für die Laufanimation des Charakters
---@param pedHandle integer
---@param pedWalk string Name des GTA Walkstyles
Walkstyle = function(pedHandle, pedWalk)
	local timeout = false
	SetTimeout(5000, function() timeout = true end)

	repeat
		RequestAnimSet(pedWalk)
		Wait(5)
	until HasAnimSetLoaded(pedWalk) or timeout

	SetPedMovementClipset(pedHandle, pedWalk, 0.5)
	RemoveAnimSet(pedWalk)
end

---Spezielle detaillierte Veränderungen für die Freemode Charaktermodelle
---@param pedHandle integer
---@param headFeatures table Informationen über die Kopfform, Haar- und Augenfarbe
Freemode = function(pedHandle, headFeatures)
	local blend = headFeatures.ShapeAndSkinTone
	SetPedHeadBlendData(pedHandle, tonumber(blend.ShapeFatherId), tonumber(blend.ShapeMotherId), tonumber(blend.ShapeOverrideId), tonumber(blend.ToneFatherId), tonumber(blend.ToneMotherId), tonumber(blend.ToneOverrideId), tonumber(CheckAndConvertToFloat(blend.ShapeVal)), tonumber(CheckAndConvertToFloat(blend.ToneVal)), tonumber(CheckAndConvertToFloat(blend.OverrideVal)), OneAndZeroToBoolean(blend.IsP))
	SetPedHairColor(pedHandle, tonumber(headFeatures.HairColour), tonumber(headFeatures.HairColourStreaks))
	SetPedEyeColor(pedHandle, tonumber(headFeatures.EyeColour))

	local face = headFeatures.FacialFeatures
	if face ~= nil then
		for i = 0, 19 do
			SetPedFaceFeature(pedHandle, i, tonumber(face["_" .. i]))
		end
	end

	local over = headFeatures.Overlays
	if over ~= nil then
		for i = 0, 12 do
			local pos = "_" .. i
			SetPedHeadOverlay(pedHandle, i, tonumber(over[pos].index), (tonumber(over[pos].opacity) / 1.0))
			local clrtype = ColorType(i)
			SetPedHeadOverlayColor(pedHandle, i, clrtype, tonumber(over[pos].colour), tonumber(over[pos].colourSecondary))
		end
	end
end

---Der Standard einer jeden Propgruppe für Freemode Männer (Der der unsichtbar ist)
CorrectionPropFreemodeMale = {
	[0] = function(ped) SetPedPropIndex(ped, 0, 8, 0, false) end,
	[1] = function(ped) SetPedPropIndex(ped, 1, 6, 0, false) end,
	[2] = function(ped) SetPedPropIndex(ped, 2, 33, 0, false) end,
	[6] = function(ped) SetPedPropIndex(ped, 6, -1, 0, false) end,
	[7] = function(ped) SetPedPropIndex(ped, 7, -1, 0, false) end,
}

---Der Standard einer jeden Propgruppe für Freemode Frauen (Der der unsichtbar ist)
CorrectionProp = {
	[0] = function(ped) SetPedPropIndex(ped, 0, 120, 0, false) end,
	[1] = function(ped) SetPedPropIndex(ped, 1, -1, 0, false) end,
	[2] = function(ped) SetPedPropIndex(ped, 2, -1, 0, false) end,
	[6] = function(ped) SetPedPropIndex(ped, 6, -1, 0, false) end,
	[7] = function(ped) SetPedPropIndex(ped, 7, -1, 0, false) end,
}

---Farbtyp für Charakter Overlays
---@param i integer
---@return integer colorType
ColorType = function(i)
	if (i == 1) or (i == 2) or (i == 10) then
		return 1
	elseif (i == 5) or (i == 8) then
		return 2
	else
		return 0
	end
end

--- Gibt dem Charakter die Waffe
--- @param pedHandle integer
--- @param weaponName string
Weapon = function(pedHandle, weaponName)
	local weaponHash = GetHashKey(weaponName)
	GiveDelayedWeaponToPed(pedHandle, weaponHash, 9999, false)
end

---Gibt dem Charakter Tattoos und visuelle Wunden
---@param pedHandle integer
---@param pedDecals table
Decals = function(pedHandle, pedDecals)
	if pedDecals.collection ~= nil then
		local collection = pedDecals.collection
		local val = pedDecals.value
		AddPedDecorationFromHashes(pedHandle, tonumber(collection), tonumber(val))
	else
		for _, entry in pairs(pedDecals) do
			local collection = entry.collection
			local val = entry.value
			AddPedDecorationFromHashes(pedHandle, tonumber(collection), tonumber(val))
		end
	end
end

---Stimme des Charakters wird auf die vorgebene Stimmbibliothek gesetzt
---@param pedHandle integer
---@param pedVoice string
Voice = function (pedHandle, pedVoice)
	SetAmbientVoiceName(pedHandle, pedVoice)
end

---Gibt für 1 True zurück.
---Für alle anderen Werte False.
---@param inputString string
---@return boolean
OneAndZeroToBoolean = function(inputString)
	local input = tonumber(inputString)
	if input == 1 then
		return true
	else
		return false
	end
end

---Gibt die eingebene Zahl als Kommazahl zurück
---@param number integer | string
---@return string
CheckAndConvertToFloat = function (number)
	number = tonumber(number)
    if number == math.floor(number) then
        return number .. ".0" -- Wenn ja, ".0" hinzufügen
    else
        return number
    end
end
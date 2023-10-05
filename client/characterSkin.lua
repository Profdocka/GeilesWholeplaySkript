--Alle kosmetischen Veränderungen am Charakter
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

	Components(pedHandle, pedComps)
	Props(pedHandle, pedProps)

	if (pedHash == 1885233650 or pedHash == -1667301416) then
		--print("Ist Freemode Charakter")
		local headFeatures = pedJson.OutfitPedData.PedProperties.HeadFeatures
		Freemode(pedHandle, headFeatures)
	end
	if pedDecals ~= nil then
		--print("cool")
		Decals(pedHandle, pedDecals)
	end
	if (pedWalk ~= nil) then
		Walkstyle(pedHandle, pedWalk)
	end
	if (pedWeapon ~= nil and ShouldHaveWeapon == true) then
		Weapon(pedHandle, pedWeapon)
	end
	if pedVoice ~= nil then
		Voice(pedHandle, pedVoice)
	end
end

Components = function(pedHandle, pedComps)
	for i = 0, 11 do
		local whole = pedComps["_" .. i]
		local prop, texture = string.match(whole, "(-?%d+),(-?%d+)")
		SetPedComponentVariation(pedHandle, i, tonumber(prop), tonumber(texture), 2)
	end
end

Props = function(pedHandle, pedProps)
	local findex = { 0, 1, 2, 6, 7 }
	--local findex = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9}
	for i = 1, #findex do
		local whole = pedProps["_" .. findex[i]]
		local prop, texture = string.match(whole, "(-?%d+),(-?%d+)")
		--print("index " .. findex[i] .. " und der prop " .. prop)
		if (prop ~= "-1") then
			SetPedPropIndex(pedHandle, findex[i], tonumber(prop), tonumber(texture), false)
		else
			CorrectionProp[findex[i]](pedHandle)
		end
	end
end

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

Freemode = function(pedHandle, headFeatures)
	local blend = headFeatures.ShapeAndSkinTone
	--SetPedHeadBlendData(pedHandle, 41, 3, 0, 41, 3, 0, 0.300000012, 1.0, 0.0, false)
	SetPedHeadBlendData(pedHandle, tonumber(blend.ShapeFatherId), tonumber(blend.ShapeMotherId), tonumber(blend.ShapeOverrideId), tonumber(blend.ToneFatherId), tonumber(blend.ToneMotherId), tonumber(blend.ToneOverrideId), tonumber(CheckAndConvertToFloat(blend.ShapeVal)), tonumber(CheckAndConvertToFloat(blend.ToneVal)), tonumber(CheckAndConvertToFloat(blend.OverrideVal)), OneAndZeroToBoolean(blend.IsP))
	--PrintAllMembersOfTable(blend)
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

--Der Standard einer jeden Propgruppe (Der ist unsichtbar)
CorrectionProp = {
	[0] = function(ped) SetPedPropIndex(ped, 0, 8, 0, false) end,
	[1] = function(ped) SetPedPropIndex(ped, 1, 6, 0, false) end,
	[2] = function(ped) SetPedPropIndex(ped, 2, 33, 0, false) end,
	[6] = function(ped) SetPedPropIndex(ped, 6, -1, 0, false) end,
	[7] = function(ped) SetPedPropIndex(ped, 7, -1, 0, false) end,
}

ColorType = function(i)
	if (i == 1) or (i == 2) or (i == 10) then
		return 1
	elseif (i == 5) or (i == 8) then
		return 2
	else
		return 0
	end
end

Weapon = function(pedHandle, weaponName)
	local weaponHash = GetHashKey(weaponName)
	GiveDelayedWeaponToPed(pedHandle, weaponHash, 9999, false)
end

Decals = function(pedHandle, pedDecals)
	if pedDecals.collection ~= nil then
		local collection = pedDecals.collection
		local val = pedDecals.value
		--print("Collection:", collection)
		--print("Value:", val)
		AddPedDecorationFromHashes(pedHandle, tonumber(collection), tonumber(val))
	else
		for _, entry in pairs(pedDecals) do
			local collection = entry.collection
			local val = entry.value
			AddPedDecorationFromHashes(pedHandle, tonumber(collection), tonumber(val))
		end
	end
end

Voice = function (pedHandle, pedVoice)
	SetAmbientVoiceName(pedHandle, pedVoice)
end

OneAndZeroToBoolean = function(inputString)
	local input = tonumber(inputString)
	if input == 1 then
		return true
	else
		return false
	end
end

CheckAndConvertToFloat = function (number)
    -- Überprüfen, ob die Zahl eine Ganzzahl ist
	number = tonumber(number)
    if number == math.floor(number) then
        return number .. ".0" -- Wenn ja, ".0" hinzufügen
    else
        return number -- Andernfalls die Zahl unverändert zurückgeben
    end
end
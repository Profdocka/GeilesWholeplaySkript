--Alle kosmetischen Veränderungen am Charakter
Cosmetics = function(pedHandle, pedJson, ShouldHaveWeapon)

	local pedHash = pedJson.OutfitPedData.ModelHash
	local pedComps = pedJson.OutfitPedData.PedProperties.PedComps
	local pedProps = pedJson.OutfitPedData.PedProperties.PedProps
	local pedWalk = pedJson.OutfitPedData.PedProperties.WalkStyle
	local pedWeapon = pedJson.OutfitPedData.PedProperties.Weapon

	Components(pedHandle, pedComps)
	Props(pedHandle, pedProps)

	if (pedHash == 1885233650 or pedHash == -1667301416) then
		local headFeatures = pedJson.OutfitPedData.PedProperties.HeadFeatures
		Freemode(pedHandle, headFeatures)
	end
	if (pedWalk ~= nil) then
		Walkstyle(pedHandle, pedWalk)
	end
	if (pedWeapon ~= nil and ShouldHaveWeapon == true) then
		Weapon(pedHandle, pedWeapon)
	end
	--Voice
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
	for i = 1, #findex do
		local whole = pedProps["_" .. findex[i]]
		local prop, texture = string.match(whole, "(-?%d+),(-?%d+)")
		if (prop ~= nil) then
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
	SetPedHeadBlendData(pedHandle, tonumber(blend.ShapeFatherId), tonumber(blend.ShapeMotherId),
		tonumber(blend.ShapeOverrideId), tonumber(blend.ToneFatherId), tonumber(blend.ToneMotherId),
		tonumber(blend.ToneOverrideId), tonumber(blend.ShapeVal), tonumber(blend.ToneVal), tonumber(blend.OverrideVal),
		false)
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
	[0] = function(ped) SetPedPropIndex(ped, 0, -1, 0, false) end,
	[1] = function(ped) SetPedPropIndex(ped, 1, 0, 0, false) end,
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

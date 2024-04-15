RegisterCommand("gwsaveentity", function(source, args)
    local information = SkinOfCharacter(PlayerPedId())
    local name = args[1]
    TriggerServerEvent("SEv_SaveEntityInFile", name, information)
    --SaveResourceFile(GetCurrentResourceName(), "server/Super.json", json.encode(information), -1)
end)

SkinOfCharacter = function(pedHandle)
    local pedHash = GetEntityModel(pedHandle)

    local u1, primaryGun = GetCurrentPedWeapon(pedHandle, true)

    local walkstyle = GetPedMovementClipset(pedHandle)

    local voice = GetAmbientVoiceNameHash(pedHandle)

    local decals = GetPedDecorations(pedHandle)

    local components = SkinOfComponents(pedHandle)

    local props = SkinOfProps(pedHandle)

    local PedProperties = {}

    PedProperties["PedComps"] = components
    PedProperties["PedProps"] = props
    PedProperties["TattooLogoDecals"] = {}

    if primaryGun then
        PedProperties["Weapon"] = primaryGun
    end

    if walkstyle then
        PedProperties["WalkStyle"] = walkstyle
    end

    if voice then
        PedProperties["Voice"] = voice
    end

    if decals then
        PedProperties["TattooLogoDecals"][":anonymous"] = decals
    end

    if pedHash == GetHashKey("mp_m_freemode_01") or pedHash == GetHashKey("mp_f_freemode_01") then
        local headFeatures = SkinOfFacialFeatures(pedHandle)
        PedProperties["HeadFeatures"] = headFeatures
        --skin = {Hash = pedHash, PrimaryGun = primaryGun, SecondaryGun = secondaryGun, ShoulderRifle = shoulderRifle, BackRifle = backRifle, Lantern = lantern, Knife = knife, Lasso = lasso, Thrower = thrower, Components = components, Walkstyle = walkstyle, FacialFeatures = facialFeatures}
    end

    local OutfitPedData = {}
    OutfitPedData["PedProperties"] = PedProperties
    OutfitPedData["ModelHash"] = pedHash

    --local entJson = OutfitPedData

    return OutfitPedData
end

SkinOfFacialFeatures = function(pedHandle)
    local headFeatures = {}
    local blend = {}
    local faceFeatures = {}
    local overlays = {}

    local u, blendData = GetPedHeadBlendData(pedHandle)

    blend["ShapeFatherId"] = blendData.shapeFirst
    blend["ShapeMotherId"] = blendData.shapeSecond
    blend["ShapeOverrideId"] = blendData.shapeThird
    blend["ToneFatherId"] = blendData.skinFirst
    blend["ToneMotherId"] = blendData.skinSecond
    blend["ToneOverrideId"] = blendData.skinThird
    blend["ShapeVal"] = blendData.shapeMix
    blend["ToneVal"] = blendData.skinMix
    blend["OverrideVal"] = blendData.thirdMix
    blend["IsP"] = 1

    headFeatures["ShapeAndSkinTone"] = blend

    local hairPrimary, hairSecondary = GetPedHairColor(pedHandle), GetPedHairHighlightColor(pedHandle)

    headFeatures["HairColour"] = hairPrimary
    headFeatures["HairColourStreaks"] = hairSecondary
    headFeatures["EyeColour"] = GetPedEyeColor(pedHandle)

    for i = 0, 19, 1 do
        faceFeatures["_" .. i] = GetPedFaceFeature(pedHandle, i)
    end

    headFeatures["FacialFeatures"] = faceFeatures

    for i = 0, 12, 1 do
        local u1, overlayValue, colourType, firstColour, secondColour, overlayOpacity = GetPedHeadOverlayData(pedHandle,
            i)
        overlays["_" .. i] = { index = overlayValue, colour = firstColour, colourSecondary = secondColour, opacity =
        overlayOpacity }
    end

    headFeatures["Overlays"] = overlays

    return headFeatures
end
--SetPedBrawlingStyle(pedHandle, 0x78BAEF07)

SkinOfComponents = function(pedHandle)
    local components = {}
    for i = 0, 11, 1 do
        local comp = GetPedDrawableVariation(pedHandle, i)
        local texture = GetPedTextureVariation(pedHandle, i)
        components["_" .. i] = comp .. "," .. texture
    end
    return components
end

SkinOfProps = function(pedHandle)
    local props = {}
    local findex = { 0, 1, 2, 6, 7 }
    for i = 0, 9 do
        local prop = GetPedPropIndex(pedHandle, i)
        local texture = GetPedPropTextureIndex(pedHandle, i)
        props["_" .. i] = prop .. "," .. texture
    end
    return props
end

SkinOfDecals = function(pedHandle)

end

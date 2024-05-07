SpawnCharacter = function (variant, name, hasWeapon, vector4)
    local characterJson = Looker(name, CHARFOLDER)

    local modelHash = characterJson.OutfitPedData.ModelHash
    modelHash = tonumber(modelHash)

    if SearchHash(modelHash) then
        local pedHandle = ChooseCharacterSpawnVariant(variant, modelHash, name, hasWeapon, vector4)
        SetModelAsNoLongerNeeded(modelHash)
        ShowNotification("Dein gespawnter Charakter: " .. name)
        return pedHandle
    end
end

ChooseCharacterSpawnVariant = function (variant, modelHash, name, hasWeapon, vector4)
    if variant == PLAYER_VARIANT then
        return SpawnCharacterAsPlayer(modelHash, name, hasWeapon, vector4)
    elseif variant == NEUTRAL_VARIANT then
        return SpawnCharacterAsNPC(modelHash, vector4)
    else
        return SpawnCharacterAsNPC(modelHash, vector4)
    end
end

SpawnCharacterAsPlayer = function (modelHash, name, hasWeapon, vector4)
    local previousPlayerPed = GetPlayerPed(PlayerId())
    local lastVehicle, lastSeat = GetCurrentVehicleAndSeatNumber(previousPlayerPed)

    SetPlayerModel(PlayerId(), modelHash)
    SetPlayerHealthRechargeMultiplier(PlayerId(), 1.0)
    SetPlayerHealthRechargeLimit(PlayerId(), 1.0)
    local newPlayerPed = GetPlayerPed(PlayerId())

    if lastVehicle ~= nil then
        TaskWarpPedIntoVehicle(newPlayerPed, lastVehicle, lastSeat)
    end

    if IsInvincible then
        SetPlayerInvincibleKeepRagdollEnabled(PlayerId(), true)
    end

    return newPlayerPed
end

SpawnCharacterAsNPC = function (modelHash, vector4)
    local pedHandle = CreatePed(26, modelHash, vector4["coords"].x, vector4["coords"].y, vector4["coords"].z, (vector4["heading"] - 180.0), true, true)
	ApplyCharacterModifiers(pedHandle)
    return pedHandle
end

ApplyCharacterModifiers = function (pedHandle)
    SetRagdollBlockingFlags(pedHandle, 1)
end
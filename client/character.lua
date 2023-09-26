SpawnCharacter = function (variant, name, hasWeapon, vector4)
    local characterJson = Looker(name, CHARFOLDER)

    local modelHash = characterJson.OutfitPedData.ModelHash
    modelHash = tonumber(modelHash)

    if SearchHash(modelHash) then
        local pedHandle = ChooseCharacterSpawnVariant[variant](modelHash, name, hasWeapon, vector4)
        SetModelAsNoLongerNeeded(modelHash)
        return pedHandle
    end
end

ChooseCharacterSpawnVariant = {
    [PLAYER_VARIANT] = function (modelHash, name, hasWeapon, vector4) return SpawnCharacterAsPlayer(modelHash, name, hasWeapon, vector4) end,
    [NEUTRAL_VARIANT] = function (modelHash, vector4) return SpawnCharacterAsNPC(modelHash, vector4) end,
    [FRIENDLY_VARIANT] = function (modelHash, vector4) return SpawnCharacterAsNPC(modelHash, vector4) end,
    [AGGRESSIVE_VARIANT] = function (modelHash, vector4) return SpawnCharacterAsNPC(modelHash, vector4) end,
}

SpawnCharacterAsPlayer = function (modelHash, name, hasWeapon, vector4)
    local previousPlayerPed = GetPlayerPed(PlayerId())
    local lastVehicle, lastSeat = GetCurrentVehicleAndSeatNumber(previousPlayerPed)

    SetPlayerModel(PlayerId(), modelHash)
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
    local pedHandle = CreatePed(26, modelHash, vector4.x, vector4.y, vector4.z, (vector4[3] - 180.0), true, true)
	ApplyCharacterModifiers(pedHandle)
    return pedHandle
end

ApplyCharacterModifiers = function (pedHandle)
    SetRagdollBlockingFlags(pedHandle, 1)
end
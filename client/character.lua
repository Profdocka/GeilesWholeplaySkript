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
    [NEUTRAL_VARIANT] = function () 
    end
}

SpawnCharacterAsPlayer = function (modelHash, name, hasWeapon, vector4)
    local previousPlayerPed = GetPlayerPed(PlayerID())
    local lastVehicle, lastSeat = GetCurrentVehicleAndSeatNumber(previousPlayerPed)

    SetPlayerModel(PlayerID(), modelHash)
    local newPlayerPed = GetPlayerPed(PlayerID())

    if lastVehicle ~= nil then
        TaskWarpPedIntoVehicle(newPlayerPed, vehiclePlayerIsIn, seatOfPlayer)
    end

    if IsInvincible then
        SetPlayerInvincibleKeepRagdollEnabled(PlayerID(), true)
    end

    return newPlayerPed
end
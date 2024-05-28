---Sucht anhand von `name` den Kuss Kult Charakter
---und spawnt das Charaktermodell in der Spielwelt
--- 
---@param variant integer Konstante die für das Charakterverhalten steht
---@param name string Name für die entsprechende Charakter Datei
---@param hasWeapon boolean Soll die eigene Waffe bekommen?
---@param vector4 table Koordinaten X, Y, Z und die Blickrichtung
---@return integer pedHandle Ingame-Handle des Peds
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

---Wählt anhand von `variant` aus, ob das Charaktermodell des Spielers geändert wird 
---oder ein NPC in die Welt gespawnt wird.
---@param variant integer
---@param modelHash integer
---@param name string
---@param hasWeapon boolean
---@param vector4 table
---@return integer pedHandle
ChooseCharacterSpawnVariant = function (variant, modelHash, name, hasWeapon, vector4)
    if variant == PLAYER_VARIANT then
        return SpawnCharacterAsPlayer(modelHash, name, hasWeapon, vector4)
    elseif variant == NEUTRAL_VARIANT then
        return SpawnCharacterAsNPC(modelHash, vector4)
    else
        return SpawnCharacterAsNPC(modelHash, vector4)
    end
end

---Ändert das Charaktermodell des eigenen Spielers.
---Setzt es bei Bedarf in das letzte Fahrzeug und macht es unsterblich
---@param modelHash integer
---@param name string
---@param hasWeapon boolean
---@param vector4 table
---@return integer pedHandle
SpawnCharacterAsPlayer = function (modelHash, name, hasWeapon, vector4)
    local previousPlayerPed = GetPlayerPed(PlayerId())
    local lastVehicle, lastSeat = GetCurrentVehicleAndSeatNumber(previousPlayerPed)

    SetPlayerModel(PlayerId(), modelHash)
    SetPlayerHealthRechargeMultiplier(PlayerId(), 1.0)
    SetPlayerHealthRechargeLimit(PlayerId(), 1.0)
    --SetPlayerWeaponDamageModifier(PlayerId(), 0.1)
    --SetPlayerMeleeWeaponDamageModifier(PlayerId(), 0.1)
    local newPlayerPed = GetPlayerPed(PlayerId())

    if lastVehicle ~= nil then
        TaskWarpPedIntoVehicle(newPlayerPed, lastVehicle, lastSeat)
    end

    if IsInvincible then
        SetPlayerInvincibleKeepRagdollEnabled(PlayerId(), true)
    end

    return newPlayerPed
end

---Ein NPC mit dem `modelHash` wird an den gegebenen Koordinaten gespawnt 
---@param modelHash integer
---@param vector4 table
---@return integer pedHandle
SpawnCharacterAsNPC = function (modelHash, vector4)
    local pedHandle = CreatePed(26, modelHash, vector4["coords"].x, vector4["coords"].y, vector4["coords"].z, (vector4["heading"] - 180.0), true, true)
	ApplyCharacterModifiers(pedHandle)
    return pedHandle
end

---Eigenschaften und Flags des Charakters werden geändert
---@param pedHandle integer
ApplyCharacterModifiers = function (pedHandle)
    SetRagdollBlockingFlags(pedHandle, 1)
    SetPedConfigFlag(pedHandle, 294, true)
    SetPedFleeAttributes(pedHandle, 0, false)
    SetPedCombatAttributes(pedHandle, 5, true)
    SetPedCombatAttributes(pedHandle, 17, false)
    SetPedCombatAttributes(pedHandle, 46, true)
    SetPedCombatAttributes(pedHandle, 58, true)
    SetPedDiesInWater(pedHandle, false)
end
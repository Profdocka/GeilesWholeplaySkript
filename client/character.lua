---Sucht anhand von `name` den Kuss Kult Charakter
---und spawnt das Charaktermodell in der Spielwelt
---
---@param variant integer Konstante die für das Charakterverhalten steht
---@param name string Name für die entsprechende Charakter Datei
---@param hasWeapon boolean Soll die eigene Waffe bekommen?
---@param vector4 table Koordinaten X, Y, Z und die Blickrichtung
---@return integer pedHandle Ingame-Handle des Peds
SpawnCharacter = function(variant, name, hasWeapon, vector4)
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
ChooseCharacterSpawnVariant = function(variant, modelHash, name, hasWeapon, vector4)
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
SpawnCharacterAsPlayer = function(modelHash, name, hasWeapon, vector4)
    LastWeaponsAndAmmoOfPlayer = GetPedWeaponsAndAmmo(GetPlayerPed(-1))
    LastHealthAndArmorOfPlayer = { health = GetEntityHealth(GetPlayerPed(-1)), armor = GetPedArmour(GetPlayerPed(-1)) }
    local previousPlayerPed = GetPlayerPed(PlayerId())
    local lastVehicle, lastSeat = GetCurrentVehicleAndSeatNumber(previousPlayerPed)

    SetPlayerModel(PlayerId(), modelHash)
    SetPlayerHealthRechargeMultiplier(PlayerId(), 1.0)
    SetPlayerHealthRechargeLimit(PlayerId(), 1.0)
    SetEveryoneIgnorePlayer(PlayerId(), false)
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
SpawnCharacterAsNPC = function(modelHash, vector4)
    local pedHandle = CreatePed(26, modelHash, vector4["coords"].x, vector4["coords"].y, vector4["coords"].z,
        (vector4["heading"] - 180.0), true, true)
    SetEntityAsMissionEntity(pedHandle, true, true)
    ApplyCharacterModifiers(pedHandle, true)
    return pedHandle
end

---Eigenschaften und Flags des Charakters werden geändert
---@param pedHandle integer
---@param enable boolean
ApplyCharacterModifiers = function(pedHandle, enable)
    SetRagdollBlockingFlags(pedHandle, 1)
    SetPedConfigFlag(pedHandle, 294, enable)
    SetPedFleeAttributes(pedHandle, 0, not enable)
    SetPedCombatAttributes(pedHandle, 5, enable)
    SetPedCombatAttributes(pedHandle, 17, not enable)
    SetPedCombatAttributes(pedHandle, 46, enable)
    SetPedCombatAttributes(pedHandle, 58, enable)
    SetPedFiringPattern(pedHandle, -957453492)
    SetPedDiesInWater(pedHandle, not enable)
end

EquipWeaponLoadout = function(loadoutname, removeWeapons)
    if removeWeapons then
        RemoveAllPedWeapons(GetPlayerPed(-1), false)
    end
    local loadout = WeaponLoadouts[loadoutname]
    for key, value in pairs(loadout) do
        Weapon(GetPlayerPed(-1), value)
    end
end

---Sucht anhand von `name` den Kuss Kult Charakter
---und spawnt das Charaktermodell in der Spielwelt
---
---@param variant integer Konstante die für das Charakterverhalten steht
---@param name string Name für die entsprechende Charakter Datei
---@param hasWeapon boolean Soll die eigene Waffe bekommen?
---@param vehicle integer
---@param seat integer
---@return integer pedHandle Ingame-Handle des Peds
SpawnCharacterInVehicle = function(variant, name, hasWeapon, vehicle, seat)
    local characterJson = Looker(name, CHARFOLDER)

    local modelHash = characterJson.OutfitPedData.ModelHash
    modelHash = tonumber(modelHash)

    if SearchHash(modelHash) then
        local pedHandle = CreatePedInsideVehicle(vehicle, 26, modelHash, seat, true, true)
        SetEntityAsMissionEntity(pedHandle, true, true)
        SetModelAsNoLongerNeeded(modelHash)
        ApplyCharacterModifiers(pedHandle, true)
        ShowNotification("Dein gespawnter Charakter: " .. name)
        return pedHandle
    end
end

---Gibt einem eine Liste der Waffen mit der jeweiligen Munitionsanzahl des Charakters
---@param pedHandle number
---@return table weaponsAndMunitionsTable {[1] = {weapon = weaponName, ammo = ammoCount}, ...}
function GetPedWeaponsAndAmmo(pedHandle)
    local weapons = {}
    local weaponList = {
        "weapon_knife",
        "weapon_dagger",
        "weapon_bat",
        "weapon_bottle",
        "weapon_crowbar",
        "weapon_flashlight",
        "weapon_golfclub",
        "weapon_hammer",
        "weapon_hatchet",
        "weapon_knuckle",
        "weapon_machete",
        "weapon_switchblade",
        "weapon_nightstick",
        "weapon_wrench",
        "weapon_battleaxe",
        "weapon_poolcue",
        "weapon_poolcue",
        "weapon_candycane",
        "weapon_pistol",
        "weapon_pistol_mk2",
        "weapon_combatpistol",
        "weapon_appistol",
        "weapon_stungun",
        "weapon_pistol50",
        "weapon_snspistol",
        "weapon_snspistol_mk2",
        "weapon_heavypistol",
        "weapon_vintagepistol",
        "weapon_flaregun",
        "weapon_marksmanpistol",
        "weapon_revolver",
        "weapon_revolver_mk2",
        "weapon_doubleaction",
        "weapon_raypistol",
        "weapon_ceramicpistol",
        "weapon_navyrevolver",
        "weapon_gadgetpistol",
        "weapon_stungun_mp",
        "weapon_pistolxm3",
        "weapon_microsmg",
        "weapon_smg",
        "weapon_smg_mk2",
        "weapon_assaultsmg",
        "weapon_combatpdw",
        "weapon_machinepistol",
        "weapon_minismg",
        "weapon_raycarbine",
        "weapon_tecpistol",
        "weapon_assaultrifle",
        "weapon_assaultrifle_mk2",
        "weapon_carbinerifle",
        "weapon_carbinerifle_mk2",
        "weapon_advancedrifle",
        "weapon_specialcarbine",
        "weapon_specialcarbine_mk2",
        "weapon_bullpuprifle",
        "weapon_bullpuprifle_mk2",
        "weapon_compactrifle",
        "weapon_militaryrifle",
        "weapon_heavyrifle",
        "weapon_tacticalrifle",
        "weapon_mg",
        "weapon_combatmg",
        "weapon_combatmg_mk2",
        "weapon_gusenberg",
        "weapon_pumpshotgun",
        "weapon_pumpshotgun_mk2",
        "weapon_sawnoffshotgun",
        "weapon_assaultshotgun",
        "weapon_bullpupshotgun",
        "weapon_musket",
        "weapon_heavyshotgun",
        "weapon_dbshotgun",
        "weapon_autoshotgun",
        "weapon_combatshotgun",
        "weapon_sniperrifle",
        "weapon_heavysniper",
        "weapon_heavysniper_mk2",
        "weapon_marksmanrifle",
        "weapon_marksmanrifle_mk2",
        "weapon_precisionrifle",
        "weapon_grenadelauncher",
        "weapon_grenadelauncher_smoke",
        "weapon_rpg",
        "weapon_minigun",
        "weapon_firework",
        "weapon_railgun",
        "weapon_hominglauncher",
        "weapon_compactlauncher",
        "weapon_rayminigun",
        "weapon_emplauncher",
        "weapon_railgunxm3",
        "weapon_grenade",
        "weapon_bzgas",
        "weapon_molotov",
        "weapon_stickybomb",
        "weapon_proxmine",
        "weapon_snowball",
        "weapon_pipebomb",
        "weapon_ball",
        "weapon_smokegrenade",
        "weapon_flare",
        "weapon_acidpackage",
        "weapon_petrolcan",
        "weapon_fireextinguisher",
        "weapon_hazardcan",
        "weapon_fertilizercan"
    }
    for _, weaponName in ipairs(weaponList) do
        local weaponHash = GetHashKey(weaponName)
        if HasPedGotWeapon(pedHandle, weaponHash, false) then
            local ammoCount = GetAmmoInPedWeapon(pedHandle, weaponHash)
            table.insert(weapons, { weapon = weaponName, ammo = ammoCount })
        end
    end
    return weapons
end

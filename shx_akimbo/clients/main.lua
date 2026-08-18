local akimboActive     = false
local offhandProp      = nil
local offhandAmmo      = 0
local currentWeaponHash = nil
local currentCategory  = nil
local lastOffhandShot  = 0
local remoteProps      = {} -- [entity] = prop, pour les autres joueurs

-- ============================================================
-- UTILITAIRES
-- ============================================================

local function IsWeaponAllowed(weaponHash)
    return Config.AllowedWeapons[weaponHash]
end

local function GetOffsetForCategory(category)
    return Config.AttachOffsets[category] or Config.AttachOffsets.pistol
end

local function RequestModelSafe(model)
    local hash = type(model) == 'number' and model or GetHashKey(model)
    if not IsModelValid(hash) then return false end
    RequestModel(hash)
    local timeout = GetGameTimer() + 3000
    while not HasModelLoaded(hash) do
        Wait(0)
        if GetGameTimer() > timeout then return false end
    end
    return true
end

function RotationToDirection(rotation)
    local x = math.rad(rotation.x)
    local z = math.rad(rotation.z)
    local num = math.abs(math.cos(x))
    return vector3(-math.sin(z) * num, math.cos(z) * num, math.sin(x))
end

-- Convertit le point visé (centre écran / crosshair) en coordonnées monde + entité touchée
local function ScreenToWorld()
    local camRot = GetGameplayCamRot(2)
    local camPos = GetGameplayCamCoord()
    local camForward = RotationToDirection(camRot)
    local destination = camPos + camForward * Config.MaxShootDistance

    local rayHandle = StartShapeTestRay(
        camPos.x, camPos.y, camPos.z,
        destination.x, destination.y, destination.z,
        -1, PlayerPedId(), 0
    )
    local _, hit, endCoords, _, entityHit = GetShapeTestResult(rayHandle)
    if hit == 0 then
        endCoords = destination
    end
    return endCoords, entityHit
end

-- ============================================================
-- PROP DE LA MAIN SECONDAIRE
-- ============================================================

local function AttachOffhandProp(ped, weaponHash, category)
    local weaponModel = GetWeapontypeModel(weaponHash)
    if not RequestModelSafe(weaponModel) then return nil end

    local prop = CreateObject(weaponModel, GetEntityCoords(ped), true, true, false)
    local offset = GetOffsetForCategory(category)
    local boneIndex = GetPedBoneIndex(ped, offset.bone)

    AttachEntityToEntity(
        prop, ped, boneIndex,
        offset.pos.x, offset.pos.y, offset.pos.z,
        offset.rot.x, offset.rot.y, offset.rot.z,
        true, true, false, false, 2, true
    )
    SetModelAsNoLongerNeeded(weaponModel)
    return prop
end

local function DetachOffhandProp()
    if offhandProp and DoesEntityExist(offhandProp) then
        DeleteEntity(offhandProp)
    end
    offhandProp = nil
end

-- ============================================================
-- ACTIVATION / DÉSACTIVATION
-- ============================================================

local function DisableAkimbo()
    if not akimboActive then return end
    akimboActive = false
    DetachOffhandProp()
    Entity(PlayerPedId()).state:set('akimboProp', nil, true)
end

local function CanActivateAkimbo(ped)
    if Config.DisallowInVehicle and IsPedInAnyVehicle(ped, false) then
        return false, "Impossible en véhicule"
    end
    if Config.DisallowInWater and IsPedSwimming(ped) then
        return false, "Impossible dans l'eau"
    end
    if Config.DisallowRagdoll and IsPedRagdoll(ped) then
        return false, "Impossible au sol"
    end
    return true
end

local function EnableAkimbo()
    local ped = PlayerPedId()
    local weaponHash = GetSelectedPedWeapon(ped)
    local weaponData = IsWeaponAllowed(weaponHash)

    if not weaponData then
        return false, "Cette arme ne supporte pas l'akimbo"
    end

    local ok, reason = CanActivateAkimbo(ped)
    if not ok then return false, reason end

    local prop = AttachOffhandProp(ped, weaponHash, weaponData.category)
    if not prop then return false, "Erreur lors de la création de l'arme secondaire" end

    offhandProp      = prop
    currentWeaponHash = weaponHash
    currentCategory   = weaponData.category


    -- prendre les munitions de la main principale ou utiliser le nombre par défaut
    if Config.OffhandStartAmmo then
        local _, ammo = GetAmmoInClip(ped, weaponHash)
        offhandAmmo = ammo > 0 and ammo or Config.OffhandDefaultAmmo
    else
        offhandAmmo = Config.OffhandDefaultAmmo
    end

    akimboActive = true

    -- Sync visuelle pour les autres joueurs (state bag sur le ped réseauté)
    Entity(ped).state:set('akimboProp', {
        weaponHash = weaponHash,
        category   = weaponData.category
    }, true)

    return true
end

local function ToggleAkimbo()
    if akimboActive then
        DisableAkimbo()
    else
        local ok, reason = EnableAkimbo()
        if not ok then
            -- Remplace par ta lib de notif (ESX/QBCore/ox_lib) selon ton serveur
            print(('[akimbo] %s'):format(reason))
        end
    end
end

RegisterCommand('akimbo', ToggleAkimbo, false)
RegisterKeyMapping('akimbo', Config.KeyMapping.description, 'keyboard', Config.KeyMapping.defaultKey)

-- ============================================================
-- TIR DE LA MAIN SECONDAIRE (scripté, raycast)
-- ============================================================

local function FireOffhand(ped)
    local now = GetGameTimer()
    if now - lastOffhandShot < Config.OffhandFireCooldown then return end
    if offhandAmmo <= 0 then
        DisableAkimbo()
        return
    end
    lastOffhandShot = now
    offhandAmmo = offhandAmmo - 1

    local _, entityHit = ScreenToWorld()
    local damage = Config.FixedOffhandDamage

    if Config.MuzzleFlash and offhandProp and DoesEntityExist(offhandProp) then
        local boneCoords = GetEntityCoords(offhandProp)
        UseParticleFxAsset('core')-- erreur a fix
        StartParticleFxNonLoopedAtCoord('muz_pistol', boneCoords.x, boneCoords.y, boneCoords.z, 0.0, 0.0, 0.0, 1.0, false, false, false)
    end

    if entityHit ~= 0 and entityHit ~= ped then
        local entityType = GetEntityType(entityHit)
        if entityType == 1 then -- ped
            if IsPedAPlayer(entityHit) then
                local targetServerId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(entityHit))
                TriggerServerEvent('akimbo:requestDamage', targetServerId, damage, currentWeaponHash)
            else
                ApplyDamageToPed(entityHit, damage, false)
            end
        elseif entityType == 3 then -- véhicule
            local engineHealth = GetVehicleEngineHealth(entityHit)
            SetVehicleEngineHealth(entityHit, engineHealth - damage)
        end
    end
end

-- Réception d'un dégât infligé par la main secondaire d'un autre joueur
RegisterNetEvent('akimbo:receiveDamage', function(damage)
    local ped = PlayerPedId()
    if IsEntityDead(ped) then return end
    ApplyDamageToPed(ped, damage, false)
end)

-- ============================================================
-- BOUCLE PRINCIPALE (détection de tir, edge sur IsPedShooting)
-- ============================================================

CreateThread(function()
    while true do
        local wait = 250
        if akimboActive then
            wait = 0
            local ped = PlayerPedId()

            if IsPedShooting(ped) then
                FireOffhand(ped)
            end

            if Config.AutoDisableOnWeaponSwitch and GetSelectedPedWeapon(ped) ~= currentWeaponHash then
                DisableAkimbo()
            end

            if IsEntityDead(ped) then
                DisableAkimbo()
            end
        end
        Wait(wait)
    end
end)

-- HUD minimal (munitions main secondaire) - à remplacer par ton propre HUD/NUI
CreateThread(function()
    while true do
        if akimboActive then
            SetTextFont(4)
            SetTextScale(0.35, 0.35)
            SetTextColour(255, 255, 255, 200)
            SetTextOutline()
            SetTextEntry("STRING")
            AddTextComponentString(('Main secondaire: %d'):format(offhandAmmo))
            DrawText(0.85, 0.90)
        end
        Wait(0)
    end
end)

-- ============================================================
-- SYNCHRONISATION VISUELLE POUR LES AUTRES JOUEURS
-- Se base sur un state bag posé sur le ped -> aucun event serveur nécessaire
-- ============================================================

AddStateBagChangeHandler('akimboProp', nil, function(bagName, _key, value)
    local entity = GetEntityFromStateBagName(bagName)
    if not entity or entity == 0 then return end
    if entity == PlayerPedId() then return end -- on gère déjà notre propre prop localement

    if remoteProps[entity] and DoesEntityExist(remoteProps[entity]) then
        DeleteEntity(remoteProps[entity])
        remoteProps[entity] = nil
    end

    if value then
        remoteProps[entity] = AttachOffhandProp(entity, value.weaponHash, value.category)
    end
end)

-- Nettoyage si la resource est arrêtée pendant que l'akimbo est actif
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    DisableAkimbo()
    for _, prop in pairs(remoteProps) do
        if DoesEntityExist(prop) then DeleteEntity(prop) end
    end
end)

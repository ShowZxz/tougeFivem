-- ============================================================
-- RELAI DE DÉGÂTS (tir scripté de la main secondaire)
--
-- ⚠️ SÉCURITÉ : ce relai fait confiance au client tireur (le client dit
-- "j'ai touché tel joueur pour X dégâts"). C'est le même modèle de confiance
-- que le système de dégâts natif de GTA/FiveM par défaut, mais reste
-- exploitable par un client triché.
--
-- Pour durcir en prod, ajoute ici par exemple :
--   - une vérification de distance entre shooterSrc et targetServerId
--   - une vérification de ligne de vue (raycast serveur si tu as les coords)
--   - un système de trust score / détection d'anomalies
-- ============================================================
RegisterNetEvent('akimbo:requestDamage', function(targetServerId, damage, weaponHash)
    local shooterSrc = source

    if type(targetServerId) ~= 'number' then return end
    if type(damage) ~= 'number' or damage <= 0 or damage > 100 then return end -- cap anti-abus basique

    local targetPed = GetPlayerPed(targetServerId)
    if not targetPed or targetPed == 0 then return end

    TriggerClientEvent('akimbo:receiveDamage', targetServerId, damage, weaponHash, shooterSrc)
end)

-- ============================================================
-- HOOK DE PERMISSION (pour intégration ESX / QBCore / autre)
--
-- Exemple d'utilisation depuis un autre script (ex: esx_bridge.lua) :
--
--   exports['akimbo']:SetPermissionCheck(function(source)
--       local xPlayer = ESX.GetPlayerFromId(source)
--       return xPlayer.getInventoryItem('akimbo_kit').count > 0
--   end)
--
-- Sans ça, l'akimbo est utilisable par tout le monde par défaut (standalone).
-- ============================================================
local permissionCheck = nil

exports('SetPermissionCheck', function(cb)
    permissionCheck = cb
end)

exports('CanUseAkimbo', function(source)
    if permissionCheck then
        return permissionCheck(source)
    end
    return true
end)

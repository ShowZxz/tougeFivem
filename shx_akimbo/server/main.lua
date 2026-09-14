
RegisterNetEvent('akimbo:requestDamage', function(targetServerId, damage, weaponHash)
    local shooterSrc = source

    if type(targetServerId) ~= 'number' then return end
    if type(damage) ~= 'number' or damage <= 0 or damage > 100 then return end -- cap anti-abus basique

    local targetPed = GetPlayerPed(targetServerId)
    if not targetPed or targetPed == 0 then return end

    TriggerClientEvent('akimbo:receiveDamage', targetServerId, damage, weaponHash, shooterSrc)
end)

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

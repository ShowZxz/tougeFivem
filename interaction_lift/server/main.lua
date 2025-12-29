local supports = {}
local lastUse = {}
local COOLDOWN = 5000
local MAX_DISTANCE = 1.6

RegisterNetEvent("interaction_lift:setSupport", function(state)
    supports[source] = state
    print(("interaction_lift: support state of %s set to %s"):format(source, tostring(state)))
end)



RegisterNetEvent("interaction_lift:legsup", function(target)
    local src = source

    if src == target then return end -- éviter de se soulever soi-même

    if not target or not GetPlayerName(target) then
        print("[LEGSUP] Target invalide")
        return
    end


    local now = os.time() * 1000
    lastUse[src] = lastUse[src] or 0

    if now - lastUse[src] < COOLDOWN then
        TriggerClientEvent("interaction_lift:denied", src, "⏳ Cooldown actif")
        return
    end

    if not supports[target] then
        TriggerClientEvent("interaction_lift:denied", src, "❌ Le joueur ne soutient pas")
        return
    end

    local srcPed = GetPlayerPed(src)
    local targetPed = GetPlayerPed(target)

    if not DoesEntityExist(srcPed) or not DoesEntityExist(targetPed) then
        return
    end

    local srcCoords = GetEntityCoords(srcPed)
    local targetCoords = GetEntityCoords(targetPed)
    local dist = #(srcCoords - targetCoords)

    if dist > MAX_DISTANCE then
        TriggerClientEvent("interaction_lift:denied", src, "❌ Trop loin du support")
        return
    end

    lastUse[src] = now
    supports[target] = false

    print(("[LEGSUP] %s -> %s (%.2fm)"):format(src, target, dist))

    --TriggerClientEvent("legsup:align", src, target)
    --TriggerClientEvent("legsup:playBoost", target)
    --TriggerClientEvent("legsup:playJump", src)
    --TriggerClientEvent("legsup:applyForce", src)

    --TriggerClientEvent("legsup:clearSupport", src)
    --TriggerClientEvent("legsup:clearSupport", target)
end)

RegisterNetEvent("interaction_lift:pullup", function(target)
    print("Pull Up requested for target server ID:", target)
    -- logique pullup
end)
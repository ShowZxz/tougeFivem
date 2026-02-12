local supports = {} -- serverId -> bool
local lastUse = {}
local COOLDOWN = 5000 -- adjustable cooldown time in milliseconds -- Note : should be in sync with client config
local MAX_LEGSUP_DISTANCE = 1.6 -- adjustable max distance to perform legsup -- Note : should be in sync with client config
local MAX_PULLUP_DISTANCE = 5.0 -- adjustable max distance to perform pullup -- Note : should be in sync with client config

SupportProxies = {} -- netId -> {owner = source, mode = "legsup" | "pullup"}

-- Support state handling
RegisterNetEvent("interaction_lift:setSupport", function(state, mode)
    supports[source] = state

    print(("interaction_lift: support state of %s set to %s | Resquested a %s"):format(source, tostring(state),
        tostring(mode)))
end)


-- Handle legsup interaction request
RegisterNetEvent("interaction_lift:legsup", function(target)
    print("Legs Up requested for target server ID:", target)
    local src = source

    if src == target then return end -- éviter de se soulever soi-même

    if not target or not GetPlayerName(target) then
        print("[LEGSUP] Target invalide")
        return
    end


    local now = os.time() * 1000
    lastUse[src] = lastUse[src] or 0

    if now - lastUse[src] < COOLDOWN then
        TriggerClientEvent("interaction_lift:denied", src, "⏳ Cooldown actif") --Cooldown active
        return
    end

    if not supports[target] then
        TriggerClientEvent("interaction_lift:denied", src, "❌ Le joueur ne soutient pas") -- Player not Supporting
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

    if dist > MAX_LEGSUP_DISTANCE then
        TriggerClientEvent("interaction_lift:denied", src, "❌ Trop loin du support") -- Too far from the support
        return
    end

    lastUse[src] = now
    supports[target] = false

    print(("[LEGSUP] %s -> %s (%.2fm)"):format(src, target, dist))

    TriggerClientEvent("legsup:align", src, target)

    TriggerClientEvent("legsup:playBoost", target)
    TriggerClientEvent("legsup:playJump", src)

    TriggerClientEvent("legsup:applyForce", src)


    TriggerClientEvent("interaction_lift:clearSupport", src)
    TriggerClientEvent("interaction_lift:clearSupport", target)
end)

-- Handle pullup interaction request
RegisterNetEvent("interaction_lift:pullup", function(target)
    print("Pull Up requested for target server ID:", target)
    local src = source

    if src == target then return end -- éviter de se soulever soi-même

    if not target or not GetPlayerName(target) then
        print("[PULLUP] Target invalide")
        return
    end


    local now = os.time() * 1000
    lastUse[src] = lastUse[src] or 0

    if now - lastUse[src] < COOLDOWN then
        TriggerClientEvent("interaction_lift:denied", src, "⏳ Cooldown actif") --Cooldown active
        return
    end

    if not supports[target] then
        TriggerClientEvent("interaction_lift:denied", src, "❌ Le joueur ne soutient pas") -- Player not Supporting
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

    if dist > MAX_PULLUP_DISTANCE then
        TriggerClientEvent("interaction_lift:denied", src, "❌ Trop loin du support") -- Too far from the support
        return
    end

    lastUse[src] = now
    supports[target] = false

    print(("[PULLUP] %s -> %s (%.2fm)"):format(src, target, dist))
    -- logique pullup

    TriggerClientEvent("pullup:align", src, target)

    TriggerClientEvent("pullup:playUpBoost", target)
    TriggerClientEvent("pullup:playJump", src)

    TriggerClientEvent("pullup:pullingUp", src, target)

    TriggerClientEvent("interaction_lift:clearSupport", src)
    TriggerClientEvent("interaction_lift:clearSupport", target)
end)

-- Registering a proxy ped when created by another player and stock by the server
RegisterNetEvent("interaction_lift:registerProxy", function(netId, mode)
    local src = source

    SupportProxies[src] = {
        netId = netId,
        mode = mode
    }

    TriggerClientEvent("interaction_lift:proxyCreated", -1, src, netId, mode)
end)

-- Removing the proxy ped when requested by the owner player
RegisterNetEvent("interaction_lift:removeProxy", function(netId)
    local src = source

    if not SupportProxies[netId] then return end
    if SupportProxies[netId].owner ~= src then return end

    print("[interaction_lift] Suppression proxy netId :", netId)

    SupportProxies[netId] = nil

    TriggerClientEvent("interaction_lift:proxyRemoved", -1, netId)
end)

-- If a player disconnects or crash during a support mode than remove their proxy ped
AddEventHandler("playerDropped", function()
    for netId, data in pairs(SupportProxies) do
        if data.owner == source then
            TriggerClientEvent("interaction_lift:proxyRemoved", -1, netId)
            SupportProxies[netId] = nil
        end
    end
end)
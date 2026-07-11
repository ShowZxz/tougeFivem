local supports = {}             -- serverId -> bool
local lastUse = {}
local COOLDOWN = 5000           -- adjustable cooldown time in milliseconds -- Note : should be in sync with client config
local MAX_LEGSUP_DISTANCE = 2.0 -- adjustable max distance to perform legsup -- Note : should be in sync with client config
local MAX_PULLUP_DISTANCE = 5.0 -- adjustable max distance to perform pullup -- Note : should be in sync with client config

ListSupportPos = {}



local function clearSupportPosition(src, positionSupport)
    if not src then return false end

    local stored = ListSupportPos[src]
    if not stored then return false end

    ListSupportPos[src] = nil
    TriggerClientEvent("interaction_lift:notifyClientRemovePos", -1, src, positionSupport or stored.pos)
    return true
end

-- Support state handling
RegisterNetEvent("interaction_lift:setSupport")
AddEventHandler("interaction_lift:setSupport", function(state, mode)
    supports[source] = state

    print(("interaction_lift: support state of %s set to %s | Resquested a %s"):format(source, tostring(state),
        tostring(mode)))
end)


-- Handle legsup interaction request
RegisterNetEvent("interaction_lift:legsup")
AddEventHandler("interaction_lift:legsup", function(target)
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
        TriggerClientEvent("interaction_lift:denied", src, "⏳ Cooldown active") --Cooldown active
        return
    end

    if not supports[target] then
        TriggerClientEvent("interaction_lift:denied", src, "❌ The player does not support") -- Player not Supporting
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
        TriggerClientEvent("interaction_lift:denied", src, "❌ Too far from the support") -- Too far from the support
        return
    end

    lastUse[src] = now
    supports[target] = false

    print(("[LEGSUP] %s -> %s (%.2fm)"):format(src, target, dist))

    TriggerClientEvent("legsup:align", src, target)

    TriggerClientEvent("legsup:playBoost", target)
    TriggerClientEvent("legsup:playJump", src)

    TriggerClientEvent("legsup:applyForce", src)

    clearSupportPosition(target, ListSupportPos[target] and ListSupportPos[target].pos)

    TriggerClientEvent("interaction_lift:clearSupport", src)
    TriggerClientEvent("interaction_lift:clearSupport", target)
end)

-- Handle pullup interaction request
RegisterNetEvent("interaction_lift:pullup")
AddEventHandler("interaction_lift:pullup", function(target)
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
        TriggerClientEvent("interaction_lift:denied", src, "⏳ Cooldown active") --Cooldown active
        return
    end

    if not supports[target] then
        TriggerClientEvent("interaction_lift:denied", src, "❌ The player does not support") -- Player not Supporting
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
        TriggerClientEvent("interaction_lift:denied", src, "❌ Too far from the support") -- Too far from the support
        return
    end

    lastUse[src] = now
    supports[target] = false

    print(("[PULLUP] %s -> %s (%.2fm)"):format(src, target, dist))

    TriggerClientEvent("pullup:align", src, target)

    TriggerClientEvent("pullup:playUpBoost", target)
    TriggerClientEvent("pullup:playJump", src)

    TriggerClientEvent("pullup:pullingUp", src, target)

    clearSupportPosition(target, ListSupportPos[target] and ListSupportPos[target].pos)

    TriggerClientEvent("interaction_lift:clearSupport", src)
    TriggerClientEvent("interaction_lift:clearSupport", target)
end)

RegisterNetEvent("interaction_lift:addPosition")
AddEventHandler("interaction_lift:addPosition", function(pos, mode)
    if not pos or not mode then
        print("SERVER : Incomplete Data for Marker")
        return
    end


    local src = source

    ListSupportPos[src] = {
        mode = mode,
        pos = pos,
        owner = src
    }

    TriggerClientEvent("interaction_lift:notifyClientPosition", -1, src, pos, mode)
end)

RegisterNetEvent("interaction_lift:removePosition")
AddEventHandler("interaction_lift:removePosition", function(position)
    if not position then
        print("SERVER : Incomplete Data for removing position")
        return
    end

    local src = source
    local positionSupport = position

    if not clearSupportPosition(src, positionSupport) then
        print(("SERVER : No support position found for player %s"):format(src))
    end

end)




-- If a player disconnects or crash during a support mode than remove their proxy ped
AddEventHandler("playerDropped", function()

    clearSupportPosition(source, ListSupportPos[source] and ListSupportPos[source].pos)

end)

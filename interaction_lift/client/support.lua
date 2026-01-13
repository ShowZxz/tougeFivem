Support = {
    active = false,
    mode = nil,
    lastToggle = 0,
    cooldownEnd = 0,
    proxy = nil, 
    netId = nil
}

-- Cooldown management for support toggling
function Support.CanToggle()
    local now = GetGameTimer()
    local elapsed = now - Support.lastToggle
    local cd = Config.SupportToggleCooldown


    if elapsed < cd then
        return false
    end
    Support.lastToggle = now
    Support.lastToggle = GetGameTimer()
    Support.cooldownEnd = Support.lastToggle + Config.SupportToggleCooldown
    return true, 0
end

-- Get support status
function Support.IsActive()
    return Support.active, Support.mode
end

-- Removing the proxy ped
function Support.RemoveProxy()
    if not Config.EnableOxTargetIntegration then return end

    print("[interaction_lift] Suppression du proxy ped")
    if not Support.proxy then return end
    if Support.proxy and DoesEntityExist(Support.proxy) then
        DeleteEntity(Support.proxy)
    end

    TriggerServerEvent("interaction_lift:removeProxy", Support.netId)

    Support.proxy = nil
    Support.netId = nil

end

-- Creating the proxy ped for ox_target
function Support.CreateProxy(mode)
    if not Config.EnableOxTargetIntegration then return end

    print("[interaction_lift] Création du proxy ped en mode :", mode)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)

    RequestModel("mp_m_freemode_01")
    while not HasModelLoaded("mp_m_freemode_01") do
        Wait(10)
    end

    local proxy = CreatePed(
        4,
        "mp_m_freemode_01",
        coords.x, coords.y, coords.z,
        GetEntityHeading(ped),
        true,
        true
    )

    NetworkRegisterEntityAsNetworked(proxy)
    local netId = NetworkGetNetworkIdFromEntity(proxy)
    SetNetworkIdCanMigrate(netId, true)
    print("[interaction_lift] Proxy ped créé avec netId :", netId)

    Support.proxy = proxy
    Support.netId = netId
    Support.mode = mode
    Support.active = true

    configureProxy(proxy)
    --AttachEntityToEntity(proxy, ped, 0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, false, false, true, false, 2, true)

    TriggerServerEvent("interaction_lift:registerProxy", netId, mode)
end

-- Force disable support mode if the get hit/ragdoll/tazed/death/killed -- Note : call this if a miss a RP event
function Support.ForceDisable(reason)
    if not Support.active then return end

    print("[interaction_lift] Support forcé OFF :", reason)

    TriggerEvent("interaction_lift:support:disable")
    if not Config.EnableOxTargetIntegration then return end

    TriggerServerEvent("interaction_lift:removeProxy")
end


-- Enable support mode
RegisterNetEvent("interaction_lift:support:enable", function(mode)
    local ped = PlayerPedId()

    local ok = Support.CanToggle()
    if not ok then
        return
    end


    if Support.active and Support.mode ~= mode then
        errorMsg("❌ Vous êtes déjà en train de soutenir autrement")
        return
    end


    if Support.active and Support.mode == mode then
        TriggerEvent("interaction_lift:support:disable")
        return
    end


    if mode == "legsup" then
        if isNearWall(ped, Config.Distances.MIN_WALL_DISTANCE) then
            errorMsg("❌ Trop proche d'un mur")
            return
        end
        if hasRoofAbove(ped, Config.Distances.MIN_ROOF_HEIGHT) then
            errorMsg("❌ Pas assez de hauteur")
            return
        end
        if not isSupportStateValid(ped) then
            errorMsg("❌ Position invalide")
            return
        end
    end

    if mode == "pullup" then
        if not isSupportStateValid(ped) then
            errorMsg("❌ Position invalide pour un pull-up")
            return
        end
    end

    Support.active = true
    Support.mode = mode
    Support.CreateProxy(mode)

    FreezeEntityPosition(ped, true)

    local anim = Config.Animation[mode:upper()]
    RequestAnimDict(anim.DICTIDLE)
    while not HasAnimDictLoaded(anim.DICTIDLE) do
        Wait(10)
    end

    TaskPlayAnim(
        ped,
        anim.DICTIDLE,
        anim.ANIMIDLE,
        8.0, -8.0, -1,
        1, 0, false, false, false
    )

    TriggerServerEvent("interaction_lift:setSupport", true, mode)
    TriggerServerEvent("interaction_lift:createProxy", Support.mode)

    message(("Support %s activé"):format(mode))
end)

--Disable support mode
RegisterNetEvent("interaction_lift:support:disable", function()
    if not Support.active then return end

    local ped = PlayerPedId()

    Support.active = false
    Support.mode = nil
    Support.RemoveProxy()

    ClearPedTasks(ped)
    FreezeEntityPosition(ped, false)

    TriggerServerEvent("interaction_lift:setSupport", false)

    message("❌ Support désactivé")
end)

AddEventHandler("onResourceStop", function(res)
    if res ~= GetCurrentResourceName() then return end
    Support.RemoveProxy()
end)

AddEventHandler("baseevents:onPlayerDied", function()
    Support.ForceDisable("death")
end)

AddEventHandler("baseevents:onPlayerKilled", function()
    Support.ForceDisable("killed")
end)

-- If a player disconnects or crash, remove their proxy ped
AddEventHandler("playerDropped", function()
    for netId, data in pairs(SupportProxies) do
        if data.owner == source then
            TriggerClientEvent("interaction_lift:proxyRemoved", -1, netId)
            SupportProxies[netId] = nil
        end
    end
end)

-- Display support cooldown on HUD
CreateThread(function()
    while true do
        Wait(0)

        if Support.cooldownEnd == 0 then
            goto continue
        end

        local now = GetGameTimer()
        local remaining = (Support.cooldownEnd - now) / 1000

        if remaining <= 0 then
            Support.cooldownEnd = 0
            goto continue
        end

        DrawHudText(
            ("Support disponible dans ~y~%.1fs"):format(remaining),
            0.5, 0.88
        )

        ::continue::
    end
end)

-- Force disable support on damage
CreateThread(function()
    local ped = PlayerPedId()
    local lastHealth = GetEntityHealth(ped)

    while true do
        Wait(200)

        if not Support.active then
            lastHealth = GetEntityHealth(ped)
            goto continue
        end

        local currentHealth = GetEntityHealth(ped)

        if currentHealth < lastHealth then
            Support.ForceDisable("damage")
        end

        lastHealth = currentHealth

        ::continue::
    end
end)

--Force disable support mode if tazed
CreateThread(function()
    while true do
        Wait(100)

        if Support.active and IsPedBeingStunned(PlayerPedId()) then
            Support.ForceDisable("tazed")
        end
    end
end)

-- Force disable support mode if ragdoll
CreateThread(function()
    while true do
        Wait(150)

        if Support.active and IsPedRagdoll(PlayerPedId()) then
            Support.ForceDisable("ragdoll")
        end
    end
end)
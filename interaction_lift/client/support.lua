Support = {
    active = false,
    mode = nil,
    lastToggle = 0,
    cooldownEnd = 0,
    proxy = nil, 
    netId = nil
}


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

function Support.IsActive()
    return Support.active, Support.mode
end

function Support.CanSupport()
   
end

function Support.RemoveProxy()

    print("[interaction_lift] Suppression du proxy ped")

    if Support.proxy and DoesEntityExist(Support.proxy) then
        DeleteEntity(Support.proxy)
    end

    TriggerServerEvent("interaction_lift:removeProxy", Support.netId)

    Support.proxy = nil
    Support.netId = nil

end

function Support.CreateProxy(mode)

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
    Support.RemoveProxy()
end)

AddEventHandler("playerDropped", function()
    for netId, data in pairs(SupportProxies) do
        if data.owner == source then
            TriggerClientEvent("interaction_lift:proxyRemoved", -1, netId)
            SupportProxies[netId] = nil
        end
    end
end)

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


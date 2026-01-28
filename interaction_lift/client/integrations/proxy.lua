Support.Proxies = {}

-- Registering a proxy ped when created by another player and validated by the server
RegisterNetEvent("interaction_lift:proxyCreated", function(owner, netId, mode)
    print("[interaction_lift] Proxy reçu :", owner, netId, mode)

    CreateThread(function()
        local timeout = GetGameTimer() + 5000

        while not NetworkDoesEntityExistWithNetworkId(netId) and GetGameTimer() < timeout do
            Wait(50)
        end

        if not NetworkDoesEntityExistWithNetworkId(netId) then
            print("❌ Proxy non streamé après timeout :", netId)
            return
        end

        local entity = NetToPed(netId)
        if not entity or not DoesEntityExist(entity) then
            print("❌ NetToPed échoué :", netId)
            return
        end

        Support.Proxies[netId] = {
            owner = owner,
            entity = entity,
            mode = mode
        }

        print("✅ Proxy prêt :", entity)

        if Config.EnableOxIntegration then
            registerProxyTarget(entity, netId)
        end
    end)
end)


-- Removing the proxy ped when notified by the server
RegisterNetEvent("interaction_lift:proxyRemoved", function(netId)
    local data = Support.Proxies[netId]
    if not data then return end

    exports.ox_target:removeEntity(data.entity)

    if data.owner == GetPlayerServerId(PlayerId()) then
        if DoesEntityExist(data.entity) then
            DeleteEntity(data.entity)
        end
    end

    Support.Proxies[netId] = nil
    print("[interaction_lift] Proxy supprimé :", netId)
end)



-- Configure the proxy ped for support mode / like set it invisible, attached to player
function configureProxy(proxy)
    local ped = PlayerPedId()

    SetEntityInvincible(proxy, true)
    SetEntityCollision(proxy, false, false)
    FreezeEntityPosition(proxy, true)
    SetBlockingOfNonTemporaryEvents(proxy, true)

    SetEntityVisible(proxy, false, false)
    SetPedCanRagdoll(proxy, false)


    AttachEntityToEntity(
        proxy,
        ped,
        0,
        0.0, 0.0, 0.0,
        0.0, 0.0, 0.0,
        false, false, true, false, 2, true
    )

    print("[interaction_lift] Proxy ped Configure :", proxy)
end

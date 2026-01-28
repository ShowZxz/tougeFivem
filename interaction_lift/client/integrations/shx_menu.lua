if not GetResourceState("ContextMenu"):find("start") then
    Config.EnableContextMenuIntegration = false
    return
end

Config.EnableContextMenuIntegration = true

print("shx_menu integration loaded")
-- save exports in a variable for easy access
local ECM = exports["ContextMenu"]

-- set up Support Menu Mode : [legs up / pull up]
ECM:Register(function(screenPosition, hitSomething, worldPosition, hitEntity, normalDirection)
    if (not DoesEntityExist(hitEntity) or PlayerPedId() ~= hitEntity) then
        return
    end

    local supportMenu = ECM:AddSubmenu(0, "🤝   Support Menu")

    if Legsup.CanUseWithTarget(PlayerPedId()) and not Support.active and Support.mode ~= "legsup" then
        ECM:AddItem(supportMenu, "🦵 Legs Up Mode", function()
            TriggerEvent("interaction_lift:support:enable", "legsup")
        end)
    end


    if PullUp.CanUseWithTarget(PlayerPedId()) and not Support.active and Support.mode ~= "pullup" then
        ECM:AddItem(supportMenu, "🧗 Pull Up Mode", function()
            TriggerEvent("interaction_lift:support:enable", "pullup")
        end)
    end


    if Support.active and Support.mode == "legsup" or Support.mode == "pullup" then
        ECM:AddItem(supportMenu, "❌ Desactivate Support Mode", function()
            TriggerEvent("interaction_lift:support:disable")
        end)
    end
end)


-- set up Target Menu Mode : [legs up / pull up]
ECM:Register(function(screenPosition, hitSomething, worldPosition, hitEntity, normalDirection)
    if (not DoesEntityExist(hitEntity) or PlayerPedId() == hitEntity) then
        return
    end

    local netId = NetworkGetNetworkIdFromEntity(hitEntity)

    local proxy = Support.Proxies[netId]
    if not proxy then return end

    local targetProxyPed = hitEntity
    local ped            = PlayerPedId()
    local dist           = #(GetEntityCoords(ped) - GetEntityCoords(targetProxyPed))

    local targetMenu     = ECM:AddSubmenu(0, "🎯  Target Support Menu")

    if Legsup.CanUse(ped, targetProxyPed, dist) then
        ECM:AddItem(targetMenu, "🦵 Monter (courte échelle)", function()
            if proxy.mode == "legsup" then
                Legsup.Start(proxy.owner)
            end
        end)
    end

    if PullUp.CanUse(ped, targetProxyPed, dist) then
        ECM:AddItem(targetMenu, "🧗 Se faire hisser", function()
            if proxy.mode == "pullup" then
                PullUp.Start(proxy.owner)
            end
        end)
    end
end)

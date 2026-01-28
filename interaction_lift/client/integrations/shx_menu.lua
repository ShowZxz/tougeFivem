
if not exports["ContextMenu"] then
    return
end

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

    local targetPed = hitEntity
    local ped       = PlayerPedId()
    local dist      = #(GetEntityCoords(ped) - GetEntityCoords(targetPed))

    local targetMenu  = ECM:AddSubmenu(0, "Target Support Menu")

    if Legsup.CanUse(ped, targetPed, dist) then
        ECM:AddItem(targetMenu, "🦵 Monter (courte échelle)", function()
            local targetServerId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(targetPed)) -- a voir si ca marche bien
            --print("[interaction_lift] Triggering legsup for target ped:", targetPed)
            TriggerServerEvent("interaction_lift:legsup", targetServerId)
        end)
    end

    if PullUp.CanUse(ped, targetPed, dist) then
        ECM:AddItem(targetMenu, "🧗 Se faire hisser", function()
            local targetServerId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(targetPed)) -- a voir si ca marche bien
            TriggerServerEvent("interaction_lift:pullup", targetServerId)
        end)
    end

    end)
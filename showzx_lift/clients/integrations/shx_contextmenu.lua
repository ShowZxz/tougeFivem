print("[showzx_lift] ContextMenu detected")
if not GetResourceState("ContextMenu"):find("start") then
    return
end

print("showzx_lift context menu integration loaded")

-- save exports in a variable for easy access
local ECM = exports["ContextMenu"]



ECM:Register(function(screenPosition, hitSomething, worldPosition, hitEntity, normalDirection)

    if (not DoesEntityExist(hitEntity) or PlayerPedId() ~= hitEntity) then
        return
    end

    local supportMenu = ECM:AddSubmenu(0, "Rope Menu")



    if isSupportStateValid(PlayerPedId()) and not Support.active and not Support.isOnRope then -- Support.isOnRope is a useless check i think
        ECM:AddItem(supportMenu, "Déployer une corde", function()
            TriggerEvent("showzx_lift:previewMode")
        end)
    end


    if isSupportStateValid(PlayerPedId()) and Support.active and not Support.isOnRope and next(PlayersOnRope) == nil then -- Support.isOnRope is a useless check i think
        ECM:AddItem(supportMenu, "Retirer la corde", function()
            TriggerServerEvent("showzx_lift:setMode", false)
        end)
    end



end)



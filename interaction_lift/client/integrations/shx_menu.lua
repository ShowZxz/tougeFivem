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

    local supportMenu = ECM:AddSubmenu(0, "Support Menu")



    if not Support.active and Support.mode ~= "legsup" then
        ECM:AddItem(supportMenu, "Legs Up Mode", function()
            TriggerEvent("interaction_lift:support:enable", "legsup")
        end)
    end


    if not Support.active and Support.mode ~= "pullup" then
        ECM:AddItem(supportMenu, "Pull Up Mode", function()
            TriggerEvent("interaction_lift:support:enable", "pullup")
        end)
    end


    -- This is use to stop supporting with Alt + Click but this targeting the player and not the proxyPed attach to it (Press X to stop supporting) 
--[[
    if Support.active and Support.mode == "legsup" or Support.mode == "pullup" then
        ECM:AddItem(supportMenu, "❌ Desactivate Support Mode", function()
            TriggerEvent("interaction_lift:support:disable")
        end)
    end
    ]]

end)


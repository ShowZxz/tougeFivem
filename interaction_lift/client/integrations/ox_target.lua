CreateThread(function()

    -- Check if ox_target is available if not disable the integration 
    if not GetResourceState("ox_target"):find("start") then return end

    print("[interaction_lift] ox_target detected")



    exports.ox_target:addGlobalOption({
         {
            name = "interaction_lift_target_disable_support",
            icon = "fa-solid fa-caret-right",
            label = "❌ Desactivated Support Mode",
            distance = 0,
            

            canInteract = function()
                if Support.active and Support.mode == "legsup" or Support.mode == "pullup" then
                    return true
                end

                return false

            end,

            onSelect = function()
                TriggerEvent("interaction_lift:support:disable")

            end
        },
        {
            name = "interaction_lift_target_legsup",
            icon = "fa-solid fa-caret-right",
            label = "🦵 Legs Up Mode",
            distance = 0,
            

            canInteract = function()
                if not Support.active and Support.mode ~= "legsup" then
                    return true
                end

                return false

            end,

            onSelect = function()
                TriggerEvent("interaction_lift:support:enable", "legsup")

            end
        },

                {
            name = "interaction_lift_target_pullup",
            icon = "fa-solid fa-caret-right",
            label = "🧗 Pull Up Mode",
            distance = 0,

            canInteract = function()
                if not Support.active and Support.mode ~= "pullup" then
                    return true
                end 

                return false

            end,

            onSelect = function()
                TriggerEvent("interaction_lift:support:enable", "pullup")

            end
        },

    })
end)



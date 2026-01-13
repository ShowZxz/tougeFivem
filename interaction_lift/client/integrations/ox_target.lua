CreateThread(function()
    if not GetResourceState("ox_target"):find("start") then Config.EnableOxTargetIntegration = false return end

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
                if Legsup.CanUseWithTarget(PlayerPedId()) and not Support.active and Support.mode ~= "legsup" then
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
                if PullUp.CanUseWithTarget(PlayerPedId()) and not Support.active and Support.mode ~= "pullup" then
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



function registerProxyTarget(entity, netId)
    exports.ox_target:addLocalEntity(entity, {
        {
            name = "interaction_lift_legsup",
            label = "🦵 Monter (courte échelle)",
            icon = "person-arrow-up-from-line",

            canInteract = function()
                local proxy = Support.Proxies[netId]
                if not proxy then return false end
                if proxy.mode ~= "legsup" then return false end

                local ped = PlayerPedId()
                local dist = #(GetEntityCoords(ped) - GetEntityCoords(entity))

                return dist <= Config.Distances.LEGSUP_MAX
            end,

            onSelect = function()
                local proxy = Support.Proxies[netId]
                if not proxy then return end

                print(
                    "[interaction_lift] Legsup selected | support:",
                    proxy.owner,
                    "netId:",
                    netId
                )

                Legsup.Start(proxy.owner)
            end
        },

        {
            name = "interaction_lift_pullup",
            label = "🧗 Se faire hisser",
            icon = "hand",

            canInteract = function()
                local proxy = Support.Proxies[netId]
                if not proxy then return false end
                if proxy.mode ~= "pullup" then return false end

                local ped = PlayerPedId()
                local dist = #(GetEntityCoords(ped) - GetEntityCoords(entity))

                return dist <= Config.Distances.PULLUP_MAX
            end,

            onSelect = function()
                local proxy = Support.Proxies[netId]
                if not proxy then return end

                print(
                    "[interaction_lift] PullUp selected | support:",
                    proxy.owner,
                    "netId:",
                    netId
                )

                PullUp.Start(proxy.owner)
            end
        }
    })
end
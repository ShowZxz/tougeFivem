CreateThread(function()
    if not GetResourceState("ox_target"):find("start") then Config.EnableOxTargetIntegration = false return end

    print("[interaction_lift] ox_target detected")



    exports.ox_target:addGlobalOption({
        {
            name = "interaction_lift_target",
            icon = "person-arrow-up-from-line", --trouver une icône appropriée
            label = "Se mettre en Legs Up",
            distance = 0,

            canInteract = function()


            end,

            onSelect = function(data)

            end
        },

                {
            name = "interaction_lift_target",
            icon = "person-arrow-up-from-line", --trouver une icône appropriée
            label = "Se mettre en Pull Up",
            distance = 0,

            canInteract = function(entity)

            end,

            onSelect = function(data)

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
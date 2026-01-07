CreateThread(function()
    if not GetResourceState("ox_target"):find("start") then return end

    print("[interaction_lift] ox_target detected")

    -- Interactions SUR JOUEUR
    exports.ox_target:addGlobalPlayer({
        {
            name = "interaction_lift_legsup",
            label = "🦵 Courte échelle",
            icon = "person-arrow-up-from-line",
            distance = Config.Distances.LEGSUP_MAX,
            canInteract = function(entity)
                local ped = PlayerPedId()
                local dist = #(GetEntityCoords(ped) - GetEntityCoords(entity))
                return Legsup.CanUse(ped, entity, dist)
            end,
            onSelect = function(data)
                local target = GetPlayerServerId(
                    NetworkGetPlayerIndexFromPed(data.entity)
                )
                Legsup.Start(target)
            end
        },
        {
            name = "interaction_lift_pullup",
            label = "🧗 Aider à grimper",
            icon = "hand",
            distance = Config.Distances.PULLUP_MAX,
            canInteract = function(entity)
                local ped = PlayerPedId()
                local dist = #(GetEntityCoords(ped) - GetEntityCoords(entity))
                return PullUp.CanUse(ped, entity, dist)
            end,
            onSelect = function(data)
                local target = GetPlayerServerId(
                    NetworkGetPlayerIndexFromPed(data.entity)
                )
                PullUp.Start(target)
            end
        }
    })

    -- Interactions SUR SOI-MÊME
    exports.ox_target:addGlobalPlayer({
        {
            name = "interaction_lift_support_legsup",
            label = "🦵 Se mettre en support (LegsUp)",
            icon = "person",
            canInteract = function(entity)
                return entity == PlayerPedId()
            end,
            onSelect = function()
                Support.Toggle("legsup")
            end
        },
        {
            name = "interaction_lift_support_pullup",
            label = "🧗 Se mettre en support (PullUp)",
            icon = "person",
            canInteract = function(entity)
                return entity == PlayerPedId()
            end,
            onSelect = function()
                Support.Toggle("pullup")
            end
        },
        {
            name = "interaction_lift_support_off",
            label = "❌ Désactiver le support",
            icon = "ban",
            canInteract = function(entity)
                return entity == PlayerPedId() and Support.active
            end,
            onSelect = function()
                Support.Toggle(nil)
            end
        }
    })
end)
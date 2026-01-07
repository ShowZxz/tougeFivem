CreateThread(function()
    if not GetResourceState("qb-target"):find("start") then return end

    print("[interaction_lift] qb-target detected")

    exports['qb-target']:AddTargetPlayer({
        options = {
            {
                label = "🦵 Courte échelle",
                icon = "fas fa-arrow-up",
                canInteract = function(entity)
                    local ped = PlayerPedId()
                    local dist = #(GetEntityCoords(ped) - GetEntityCoords(entity))
                    return Legsup.CanUse(ped, entity, dist)
                end,
                action = function(entity)
                    local target = GetPlayerServerId(
                        NetworkGetPlayerIndexFromPed(entity)
                    )
                    Legsup.Start(target)
                end
            },
            {
                label = "🧗 Aider à grimper",
                icon = "fas fa-hand-paper",
                canInteract = function(entity)
                    local ped = PlayerPedId()
                    local dist = #(GetEntityCoords(ped) - GetEntityCoords(entity))
                    return PullUp.CanUse(ped, entity, dist)
                end,
                action = function(entity)
                    local target = GetPlayerServerId(
                        NetworkGetPlayerIndexFromPed(entity)
                    )
                    PullUp.Start(target)
                end
            }
        },
        distance = 5.0
    })

    exports['qb-target']:AddTargetPlayer({
        options = {
            {
                label = "🦵 Support LegsUp",
                action = function()
                    Support.Toggle("legsup")
                end
            },
            {
                label = "🧗 Support PullUp",
                action = function()
                    Support.Toggle("pullup")
                end
            },
            {
                label = "❌ Désactiver support",
                action = function()
                    Support.Toggle(nil)
                end
            }
        },
        distance = 2.0
    })
end)
CreateThread(function()
    if not GetResourceState("ox_target"):find("start") then return end

    print("[interaction_lift] ox_target detected")

    RegisterNetEvent("interaction_lift:registerSupportTarget", function(entity)
    if not entity or not DoesEntityExist(entity) then return end

    exports.ox_target:addLocalEntity(entity, {
        {
            name = "interaction_lift_use",
            label = "Utiliser le support",
            icon = "fa-solid fa-hand",
            distance = 2.0,
            onSelect = function()
                TriggerEvent("interaction_lift:useSupport")
            end
        }
    })
end)

RegisterNetEvent("interaction_lift:registerLegsupTarget", function(entity, targetServerId)
    if not entity or not DoesEntityExist(entity) then return end

    exports.ox_target:addLocalEntity(entity, {
        {
            name = "interaction_lift_legsup",
            label = "Mettre en jambes en l'air",
            icon = "fa-solid fa-person-walking-luggage",
            distance = 2.0,
            onSelect = function()
                TriggerServerEvent("interaction_lift:legsup", targetServerId)
            end
        }
    })
end)

end)
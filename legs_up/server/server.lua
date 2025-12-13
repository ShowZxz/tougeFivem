local supports = {}


RegisterNetEvent("legsup:setSupport", function(state)
    supports[source] = state
end)

RegisterNetEvent("legsup:tryLift", function(target)
    local src = source

    if supports[target] then
        TriggerClientEvent("legsup:align", src, target)
        TriggerClientEvent("legsup:playBoost", target)
        TriggerClientEvent("legsup:playJump", src)
        TriggerClientEvent("legsup:applyForce", src)

        
        supports[target] = false

        TriggerClientEvent("legsup:clearSupport", target)
        TriggerClientEvent("legsup:clearSupport", src)

    else
        -- Notify le joueur qu'il n'y a pas de support
        --TriggerClientEvent("legsup:notifyNoSupport", src)
    end
end)
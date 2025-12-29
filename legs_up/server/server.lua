local supports = {}


RegisterNetEvent("legsup:setSupport", function(state)
    supports[source] = state
    print(("legsup: support state of %s set to %s"):format(source, tostring(state)))
end)


RegisterNetEvent("legsup:tryLift", function(target)
    --print(("legsup: %s is trying to lift %s"):format(source, target))
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
        TriggerClientEvent("legsup:notifyNoSupport", src, "The target is not supporting.")
    end
end)

local supports = {}


RegisterNetEvent("pullup:setSupport", function(state)
    supports[source] = state
    print(("pullup: support state of %s set to %s"):format(source, tostring(state)))
end)


RegisterNetEvent("pullup:tryPullUp", function(target)
    local src = source

    if supports[target] then
        TriggerClientEvent("pullup:align", src, target)
        --TriggerClientEvent("pullup:playBoost", target)
        --TriggerClientEvent("pullup:playJump", src)
        TriggerClientEvent("pullup:pullingUp", src)

        
        supports[target] = false

        TriggerClientEvent("pullup:clearSupport", target)
        TriggerClientEvent("pullup:clearSupport", src)

    else
        TriggerClientEvent("pullup:notifyNoSupport", src, "The target is not supporting.")
    end
end)
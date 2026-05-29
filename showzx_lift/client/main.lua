RegisterCommand("lift", function()
    local playerPed = PlayerPedId()

    triggerEvent("showzx_lift:setMode", playerPed, true)
end)
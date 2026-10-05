AddEventHandler("shx_climb:climb", function()
    climb()
end)


AddEventHandler("onResourceStop", function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    FreezeEntityPosition(PlayerPedId(), false)
    playerState = "IDLE"
end)
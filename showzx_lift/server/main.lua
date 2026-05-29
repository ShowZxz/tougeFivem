local supports = {}

RegisterNetEvent("showzx_lift:setMode", function(playerPed, isLifting)
    if isLifting then
        TriggerClientEvent("showzx_lift:enableLiftMode", playerPed)
    else
        TriggerClientEvent("showzx_lift:disableLiftMode", playerPed)
    end
end)
function message(msg)
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(msg)
    ThefeedSetNextPostBackgroundColor(140)
    EndTextCommandThefeedPostTicker(false, true)

end
RegisterNetEvent("mon_script:client:clientPrint", function()

    local playerName = GetPlayerName(PlayerId())
    message(playerName .. " a utilisé la commande tuto")

end)

RegisterCommand("testserver", function()
    print("Commande testserver utilisée")
    TriggerServerEvent("mon_script:server:serverPrint")
end)


RegisterCommand("testclient", function()
    print("Commande testclient utilisée")
    TriggerClientEvent("mon_script:client:clientPrint", -1)
end)

RegisterNetEvent("mon_script:server:serverPrint", function()
    local playerName = GetPlayerName(PlayerId())
    print(playerName .. " a utilisé la commande testserver")

end)
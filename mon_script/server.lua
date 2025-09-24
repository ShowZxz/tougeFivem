
RegisterServerEvent("arme:donnerPistolet")
RegisterServerEvent("soins:donnerDuSoin")

AddEventHandler("arme:donnerPistolet", function()
    local source = source
    -- vérifications (argent, métier, etc.)
    TriggerClientEvent("arme:donnerAuClient", source)
end)

AddEventHandler("soins:donnerDuSoin", function()
    local source = source
    -- vérifications (argent, métier, etc.)
    TriggerClientEvent("soins:donnerAuClient", source)
end)

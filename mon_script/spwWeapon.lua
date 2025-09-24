function message(msg)
    AddTextEntry('HelpMsg', msg)
    BeginTextCommandDisplayHelp('HelpMsg')
    EndTextCommandDisplayHelp(0, false, true, -1)
end

Citizen.CreateThread(function()
    while true do
        Wait(0)
        local player = PlayerPedId()
        local playerCoords = GetEntityCoords(player)
        local coords = vector3(66.00777, 7203.58, 3.154922)
        local distance = #(playerCoords - coords)

        if distance < 10 then
            message("Appuie sur ~INPUT_CONTEXT~ pour spawn une arme.")
            if IsControlJustPressed(0, 38) then
                TriggerServerEvent("arme:donnerPistolet")
            end
        end
    end
end)

-- reçoit l'instruction du serveur pour donner l'arme
RegisterNetEvent("arme:donnerAuClient")
AddEventHandler("arme:donnerAuClient", function()
    local player = PlayerPedId()
    local pistol = 0xAF3696A1
    if not HasPedGotWeapon(player, pistol, false) then
        GiveWeaponToPed(player, pistol, 100, false, true)
    end
end)

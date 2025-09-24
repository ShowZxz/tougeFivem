function message(msg)
    AddTextEntry('HelpMsg', msg)
    BeginTextCommandDisplayHelp('HelpMsg')
    EndTextCommandDisplayHelp(0, false, true, -1)
end

Citizen.CreateThread(function()

    local blip = AddBlipForCoord(294.4793, -194.2272, 61.57051)
    SetBlipSprite(blip, 61) -- Symbole de croix pour les soins
    SetBlipColour(blip, 2) -- Couleur verte
    SetBlipScale(blip, 0.8)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Centre de Soins")
    EndTextCommandSetBlipName(blip)

    while true do
        Wait(0)
        local coords = nil
        local distance = nil
        local player = PlayerPedId()
        local playerCoords = GetEntityCoords(player)
        local health = GetEntityHealth(player)
        coords = vector3(294.4793, -194.2272, 61.57051)
        distance = #(playerCoords - coords)

        if distance < 10 then
            message("Vous êtes dans la zone de soins")

            if health < 200 then

                print("Vous êtes blessé, vous allez être soigné.")
                while true do
                    Wait(1000)
                    local playerCoords = GetEntityCoords(PlayerPedId())
                    local distance = #(playerCoords - coords)

                    if distance < 10 and GetEntityHealth(PlayerPedId()) < 200 then
                        TriggerEvent("soins:donnerDuSoin")
                    else
                        break
                    end
                end

            else
                print("Vous n'avez pas besoin de soins.")

            end

        end
    end
end)

RegisterNetEvent("soins:donnerDuSoin")
AddEventHandler("soins:donnerDuSoin", function()
    local player = PlayerPedId()
    local health = GetEntityHealth(player)
    local newHealth = health + 1
    SetEntityHealth(player, newHealth) -- Soigner de 1 point de vie, sans dépasser 200

end)

local lastPress = 0

CreateThread(function()
    while true do
        Wait(5)

        local playerPed = PlayerPedId()
        local playerCoord = GetEntityCoords(playerPed)

        for i = 1, #locations do

            local loc = locations[i]
            local locVector = vector3(loc.pos.x, loc.pos.y, loc.pos.z)

            
            DrawMarker(
                loc.marker,
                loc.pos.x,
                loc.pos.y,
                loc.pos.z - 0.75,
                0.0, 0.0, 0.0,
                0.0, 0.0, 0.0,
                loc.scale, loc.scale, loc.scale,
                loc.rgba[1], loc.rgba[2], loc.rgba[3], loc.rgba[4],
                false, true, 2, nil, nil, false
            )

            
            local dist = #(playerCoord - locVector)

            if dist < loc.scale and GetVehiclePedIsIn(playerPed, false) == 0 then

                
                BeginTextCommandDisplayHelp("STRING")
                AddTextComponentSubstringPlayerName(loc.message or "Appuie sur ~INPUT_CONTEXT~ pour interagir")
                EndTextCommandDisplayHelp(0, false, true, -1)



                if IsControlJustPressed(0, 38) and GetGameTimer() - lastPress > 1000 then
                    lastPress = GetGameTimer()

                    if loc.type == "join" then
                        TriggerServerEvent("whoiam:join")

                    elseif loc.type == "leave" then
                        TriggerServerEvent("whoiam:leave")

                    elseif loc.type == "start" then
                        TriggerServerEvent("whoiam:startGame")

                    end

                end
            end

        end
    end
end)
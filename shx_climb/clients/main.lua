playerState = "IDLE"


function DrawText3D(coords, text)
    local camCoords = GetGameplayCamCoords()
    local dist = #(coords - camCoords)

    local scale = (1 / dist) * 2
    local fov = (1 / GetGameplayCamFov()) * 100
    scale = scale * fov

    SetTextScale(0.0 * scale, 0.55 * scale)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextCentre(true)

    SetDrawOrigin(coords.x, coords.y, coords.z, 0)

    BeginTextCommandDisplayText("STRING")
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayText(0.0, 0.0)

    ClearDrawOrigin()
end

function displayHelpText(text)
    BeginTextCommandDisplayHelp("STRING")
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayHelp(0, false, true, -1)
end



CreateThread(function()
    while true do
        Wait(0)

        if playerState ~= "IDLE" then  
            DisableControlAction(0, 22, true) -- Disable the jump control
            DisableControlAction(0, 21, true) -- Disable the sprint control
            DisableControlAction(0, 24, true) -- Disable the attack control
            DisableControlAction(0, 25, true) -- Disable the aim control
            DisableControlAction(0, 30, true)
            DisableControlAction(0, 31, true)
            DisableControlAction(0, 32, true)
            DisableControlAction(0, 33, true)
            DisableControlAction(0, 34, true)
            DisableControlAction(0, 35, true)
        end

        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local textDisplay = "PlayerState : "..playerState
        displayHelpText(textDisplay)

        -- point à 1.5m devant le joueur, sert de cible pour le 1er raycast (détection du mur)
        local forward = GetOffsetFromEntityInWorldCoords(ped, 0.0, 1.5, 0.0)

        -- RAYCAST 1 : horizontal, pour détecter s'il y a un mur devant
        local rayHandle = StartShapeTestRay(coords.x, coords.y, coords.z + 0.5, forward.x, forward.y, coords.z + 0.5, 1,
            ped, 0)
        local _, hit, endCoords, _, _ = GetShapeTestResult(rayHandle)

        if hit == 1 then
            DrawText3D(endCoords, "MUR DÉTECTÉ")

            local direction = endCoords - coords

            local length = #direction

            local dirNormalized = direction / length

            local beyondWall = endCoords + (dirNormalized * 0.3)

            local rayHandle2 = StartShapeTestRay(
                beyondWall.x, beyondWall.y, endCoords.z + 2.5,
                beyondWall.x, beyondWall.y, endCoords.z - 1.0,
                1, ped, 0
            )
            local _, hit2, endCoords2, _, _ = GetShapeTestResult(rayHandle2)

            if hit2 == 1 then
                DrawText3D(endCoords2, "REBORD DÉTECTÉ")
                -- On va mettre des les states pour savoir si on peut HANGING

                -- Calcul de la distance entre le joueur et le rebord

                --local coordsForState = vector3(coords.x, coords.y, coords.z + 0.5)

                local heightDiff = endCoords2.z - coords.z
                if heightDiff > 1.5 and heightDiff < 2.1 then
                    
                    DrawText3D(endCoords2 + vector3(0.0, 0.0, 0.2), "HANGING POSSIBLE")
                    if IsControlJustPressed(0, 22) and playerState == "IDLE" then
                        playerState = "HANGING"
                        FreezeEntityPosition(ped, true)
                        TriggerEvent("shx_climb:hang", endCoords2)
                    end
                else
                    DrawText3D(endCoords2 + vector3(0.0, 0.0, 0.2), "HANGING NOT POSSIBLE")
                end

                if heightDiff > 0.5 and heightDiff < 1.0 then
                    
                    DrawText3D(endCoords2 + vector3(0.0, 0.0, 0.3), "VAULT POSSIBLE")

                    if IsControlJustPressed(0, 22) and playerState == "IDLE" then
                        playerState = "VAULTING"
                        FreezeEntityPosition(ped, true)
                        TriggerEvent("shx_climb:vault", endCoords2)
                    end
                else
                    DrawText3D(endCoords2 + vector3(0.0, 0.0, 0.3), "VAULT NOT POSSIBLE")
                end
            end
        end
    end
end)


-- SUPPRIMER LES ELSE USELESS A L'AVENIR
playerState = "IDLE"
local climbPressStart = nil

CreateThread(function()
    while true do
        Wait(0)

        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        displayHelpText("PlayerState : " .. playerState)

        -- point à 1.5m devant le joueur, sert de cible pour le 1er raycast (détection du mur)
        local forward = GetOffsetFromEntityInWorldCoords(ped, 0.0, 1.5, 0.0)

        -- RAYCAST 1 : horizontal, pour détecter s'il y a un mur devant
        local rayHandle = StartShapeTestRay(coords.x, coords.y, coords.z + 0.5, forward.x, forward.y, coords.z + 0.5, 1,
            ped, 0)
        local _, hit, endCoords, _, _ = GetShapeTestResult(rayHandle)

        -- si aucun mur n'est détecté, on reset le timer de maintien et on arrête là pour cette frame
        if hit ~= 1 then
            climbPressStart = nil
            goto continue
        end

        DrawText3D(endCoords, "MUR DÉTECTÉ")

        local direction = endCoords - coords
        local length = #direction
        local dirNormalized = direction / length
        local beyondWall = endCoords + (dirNormalized * 0.3)

        -- RAYCAST 2 : vertical, pour trouver la hauteur du rebord
        local rayHandle2 = StartShapeTestRay(
            beyondWall.x, beyondWall.y, endCoords.z + 2.5,
            beyondWall.x, beyondWall.y, endCoords.z - 1.0,
            1, ped, 0
        )
        local _, hit2, endCoords2, _, _ = GetShapeTestResult(rayHandle2)

        if hit2 ~= 1 then
            climbPressStart = nil
            goto continue
        end

        DrawText3D(endCoords2, "REBORD DÉTECTÉ")

        local heightDiff = endCoords2.z - coords.z

        if heightDiff <= 0.5 or heightDiff >= 2.1 then
            DrawText3D(endCoords2 + vector3(0.0, 0.0, 0.2), "CLIMBING NOT POSSIBLE")
            climbPressStart = nil
            goto continue
        end

        -- à partir d'ici, le climb est géométriquement possible
        DisableControlAction(0, 22, true)
        DrawText3D(endCoords2 + vector3(0.0, 0.0, 0.2), "CLIMBING POSSIBLE")

        if playerState ~= "IDLE" then
            goto continue
        end

        if IsDisabledControlPressed(0, 22) then
            if climbPressStart == nil then
                climbPressStart = GetGameTimer() -- on note le moment où l'appui a COMMENCÉ
            end

            local heldDuration = GetGameTimer() - climbPressStart
            print("Maintenu depuis : " .. heldDuration .. "ms")

            if heldDuration > 30 then
                print("MAINTIEN DÉTECTÉ")
                playerState = "CLIMBING"
                climbPressStart = nil
                TriggerEvent("shx_climb:climb")
            end
        else
            climbPressStart = nil
        end

        ::continue::
    end
end)

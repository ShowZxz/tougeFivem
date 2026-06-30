Support = {
    active = false,
    activeRope = nil,
    isOnRope = false,
    lastToggle = 0,
    cooldownEnd = 0,
    preview = false,
    canDeploy = false

}




RegisterCommand("lower", function()
    if not Support.active then
        errorMsg("You are not in lift mode.")
        return
    end

    if not isSupportStateValid(PlayerPedId()) then
        errorMsg("You are not in a valid state to retract the rope.")
        return
    end
    if Support.isOnRope then
        errorMsg("You are on the rope, you can't do that.")
        return
    end
    if next(PlayersOnRope) ~= nil then
        errorMsg("There are someone on your rope")
        return
    end

    TriggerServerEvent("showzx_lift:setMode", false)
end)

RegisterNetEvent("showzx_lift:notifyClient", function(isLifting)
    if isLifting then
        TriggerEvent("showzx_lift:enableLiftMode")
        TriggerEvent("showzx_lift:playDeployAnim")
    else
        errorMsg("Lift mode disabled.")
        TriggerEvent("showzx_lift:disableLiftMode")
        TriggerEvent("showzx_lift:playRetractAnim")
    end
end)


-- TEST Prévisualistion de la rope
RegisterCommand("rope", function()
    TriggerEvent("showzx_lift:previewMode")
end)


RegisterNetEvent("showzx_lift:previewMode", function()
    if Support.active then
        errorMsg("You are already deploy a rope.")
        return
    end

    if Support.preview then
        errorMsg("You are already in preview mode.")
        return
    end

    if not isSupportStateValid(PlayerPedId()) then
        errorMsg("You are not in a valid state to deploy the rope.")
        return
    end

    if Support.isOnRope then
        errorMsg("You are already on the rope.")
        return
    end



    local ped = PlayerPedId()
    Support.preview = true

    CreateThread(function()
        while true do
            Wait(0)

            if not isSupportStateValid(ped) then
                errorMsg("You are not in a valid state to deploy the rope.")
                Support.preview = false
                return
            end

            displayHelpText()

            local pos = GetEntityCoords(ped)
            local forward = GetEntityForwardVector(ped)
            local offset = 1.0
            local red = 0
            local green = 0

            local ropeX = pos.x + forward.x * offset
            local ropeY = pos.y + forward.y * offset

            local found, groundZ = GetGroundZFor_3dCoord(
                ropeX,
                ropeY,
                pos.z,
                false
            )


            local ropeLengthCheck = pos.z + 3 - groundZ
            if ropeLengthCheck < 10.0 or ropeLengthCheck > 50.0 then
                red = 255
                green = 0
            else
                red = 0
                green = 255
            end


            DrawLine(
                ropeX,
                ropeY,
                pos.z,

                ropeX,
                ropeY,
                groundZ,

                red,
                green,
                0,
                255
            )

            DrawMarker(
                23,
                ropeX,
                ropeY,
                groundZ,
                0.0, 0.0, 0.0,
                0.0, 0.0, 0.0,
                1.5, 1.5, 1.5, -- Scale
                red, green, 0,
                255,
                false,
                false,
                2,
                false,
                nil,
                nil,
                false
            )
            if green == 255 then
                Support.canDeploy = true
            else
                Support.canDeploy = false
            end
            if IsControlJustPressed(0, 38) then
                if Support.canDeploy then
                    TriggerServerEvent("showzx_lift:setMode", true)
                    Support.preview = false
                    return
                else
                    errorMsg("Tu peux pas deployer la corde ici")
                end
            end

            if IsControlJustPressed(0, 73) then
                message("Preview désactivé")
                Support.preview = false
                return
            end
        end
    end)
end)

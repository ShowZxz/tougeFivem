function ShowZxLift.CanUse(ped, dist)
    return dist <= 2.0
        and isSupportStateValid(ped)
end

function ShowZxLift.GetNearestRopeData(ped, maxDistance)
    local coords = GetEntityCoords(ped)
    local nearestRope = nil
    local nearestDist = maxDistance

    for owner, ropeData in pairs(ListOfRopes) do
        if type(ropeData) == "table" and ropeData.bottomAnchor then
            local bottom = ropeData.bottomAnchor
            local dist = Vdist(
                coords.x,
                coords.y,
                coords.z,
                bottom.x,
                bottom.y,
                bottom.z
            )

            if dist < nearestDist then
                nearestDist = dist
                nearestRope = ropeData
            end
        end
    end

    return nearestRope, nearestDist
end

function ShowZxLift.GetNearestTopRopeData(ped, maxDistance)
    local coords = GetEntityCoords(ped)
    local nearestRope = nil
    local nearestDist = maxDistance

    for owner, ropeData in pairs(ListOfRopes) do
        if type(ropeData) == "table" and ropeData.topAnchor then
            local top = ropeData.topAnchor
            local dist = Vdist(
                coords.x,
                coords.y,
                coords.z,
                top.x,
                top.y,
                top.z
            )

            if dist < nearestDist then
                nearestDist = dist
                nearestRope = ropeData
            end
        end
    end

    return nearestRope, nearestDist
end

function ShowZxLift.IsOnCooldown()
    local now = GetGameTimer()
    return Support.cooldownEnd and now < Support.cooldownEnd
end

function ShowZxLift.Start(data)
    if ShowZxLift.IsOnCooldown() then
        errorMsg("Veuillez attendre avant de relancer l'action.")
        return
    end

    Support.lastToggle = GetGameTimer()
    Support.cooldownEnd = Support.lastToggle + ShowZxLiftConfig.Cooldown -- 3 secondes de cooldown
    TriggerServerEvent("showzx_lift:liftStart", data.owner)
end

function ShowZxLift.StartUnlift(data)
    if ShowZxLift.IsOnCooldown() then
        errorMsg("Veuillez attendre avant de relancer l'action.")
        return
    end

    Support.lastToggle = GetGameTimer()
    Support.cooldownEnd = Support.lastToggle + ShowZxLiftConfig.Cooldown -- 3 secondes de cooldown
    TriggerServerEvent("showzx_lift:unLiftStart", data.owner)
end

--Lift logic
CreateThread(function()
    while true do
        local ped = PlayerPedId()

        CurrentRopeData = nil

        local ropeData, dist = ShowZxLift.GetNearestRopeData(ped, 2.0)

        if ropeData and ShowZxLift.CanUse(ped, dist) then
            CurrentRopeData = ropeData
            Wait(250)
        else
            Wait(1000)
        end
    end
end)

CreateThread(function()
    while true do
        if CurrentRopeData then
            displayHelpTextForRope()

            if IsControlJustPressed(0, 38) then
                if ShowZxLift.IsOnCooldown() then
                    errorMsg("Cooldown actif.")
                else
                    ShowZxLift.Start(CurrentRopeData)
                end
            end

            Wait(0)
        else
            Wait(500)
        end
    end
end)


--Unlift logic
CreateThread(function()
    while true do
        local ped = PlayerPedId()

        CurrentTopRopeData = nil

        local ropeData, dist = ShowZxLift.GetNearestTopRopeData(ped, 2.0)

        if ropeData and ShowZxLift.CanUse(ped, dist) then
            CurrentTopRopeData = ropeData
            Wait(250)
        else
            Wait(1000)
        end
    end
end)

CreateThread(function()
    while true do
        if CurrentTopRopeData then
            displayHelpTextForRope()

            if IsControlJustPressed(0, 38) then
                if ShowZxLift.IsOnCooldown() then
                    errorMsg("Cooldown actif.")
                else
                    ShowZxLift.StartUnlift(CurrentTopRopeData)
                end
            end

            Wait(0)
        else
            Wait(500)
        end
    end
end)
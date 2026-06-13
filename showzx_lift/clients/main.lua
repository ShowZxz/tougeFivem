Support = {
    active = false,
    activeRope = nil,
    lastToggle = 0,
    cooldownEnd = 0,
}

ListOfRopes = {} -- [ownerServerId] = { owner, topAnchor, bottomAnchor, visualRope, topAnchorEntity, bottomAnchorEntity }


ShowZxLift = {}

RegisterCommand("lift", function()
    if Support.active then
        errorMsg("You are already in lift mode.")
        return
    end


    TriggerServerEvent("showzx_lift:setMode", true)
end)

RegisterCommand("lower", function()
    if not Support.active then
        errorMsg("You are not in lift mode.")
        return
    end

    TriggerServerEvent("showzx_lift:setMode", false)
end)

RegisterNetEvent("showzx_lift:enableLiftMode", function()
    local ped = PlayerPedId()
    local pos = GetEntityCoords(ped)
    local forward = GetEntityForwardVector(ped)
    local offset = 1.0

    local ropeX = pos.x + forward.x * offset
    local ropeY = pos.y + forward.y * offset

    local found, groundZ = GetGroundZFor_3dCoord(
        ropeX,
        ropeY,
        pos.z,
        false
    )

    if not found then
        errorMsg("Impossible de trouver le sol.")
        return
    end

    debugMsg("Ground found at Z=" .. tostring(groundZ) .. " for rope position")


    RopeLoadTextures()

    while not RopeAreTexturesLoaded() do
        Wait(0)
    end

    local ropeLength = pos.z + 3 - groundZ

    local rope = AddRope(
        ropeX,
        ropeY,
        pos.z, -- start a bit above the player to avoid z-fighting
        0.0,
        0.0,
        0.0,
        ropeLength,
        1,
        ropeLength,
        0.1,
        0.5,
        false,
        false,
        false,
        1.0,
        false
    )

    print("rope =", rope)
    debugMsg("ropeLength = " .. ropeLength)
    debugMsg("Rope created with id " .. tostring(rope) .. " and length " .. tostring(ropeLength))



    local topAnchorCoords = {
        x = ropeX,
        y = ropeY,
        z = pos.z
    }

    local bottomAnchorCoords = {
        x = ropeX,
        y = ropeY,
        z = groundZ
    }

    local landingPos = vector3(
        pos.x,
        pos.y,
        pos.z
    ) - (forward * 0.5)

    local ropeData = {
        owner = nil,

        topAnchor = topAnchorCoords,
        bottomAnchor = bottomAnchorCoords,

        landingPos = {
            x = landingPos.x,
            y = landingPos.y,
            z = landingPos.z
        },

        landingHeading = GetEntityHeading(ped)
    }

    Support.active = true
    Support.activeRope = rope
    Support.topAnchorEntity = topAnchorCoords       -- A voir
    Support.bottomAnchorEntity = bottomAnchorCoords -- A voir
    Support.ownerId = nil


    debugMsg("Rope data prepared and sending to server")
    -- Envoie au serveur les coordonnées des deux ancres de la corde
    TriggerServerEvent("showzx_lift:addRopeOwner", ropeData)
end)

RegisterNetEvent("showzx_lift:disableLiftMode", function()
    if Support.activeRope then
        DeleteRope(Support.activeRope)
        Support.activeRope = nil
    end

    if Support.topAnchorEntity and DoesEntityExist(Support.topAnchorEntity) then
        DeleteEntity(Support.topAnchorEntity)
        Support.topAnchorEntity = nil
    end

    if Support.bottomAnchorEntity and DoesEntityExist(Support.bottomAnchorEntity) then
        DeleteEntity(Support.bottomAnchorEntity)
        Support.bottomAnchorEntity = nil
    end

    Support.active = false

    if Support.ownerId then
        TriggerServerEvent("showzx_lift:removeRopeOwner", Support.ownerId)
        Support.ownerId = nil
    end
end)

RegisterNetEvent("showzx_lift:notifyClient", function(isLifting)
    if isLifting then
        message("Lift mode enabled.")
        TriggerEvent("showzx_lift:enableLiftMode")
        TriggerEvent("showzx_lift:playDeployAnim")
    else
        errorMsg("Lift mode disabled.")
        TriggerEvent("showzx_lift:disableLiftMode")
    end
end)

RegisterNetEvent("showzx_lift:denied", function(message)
    errorMsg(message)
end)

RegisterNetEvent("showzx_lift:setRopeOwner", function(ropeData)
    if type(ropeData) ~= "table" then
        return
    end

    local owner = ropeData.owner
    local topAnchor = ropeData.topAnchor
    local bottomAnchor = ropeData.bottomAnchor

    if not owner or not topAnchor or not bottomAnchor then
        print("showzx_lift: Incomplete rope data provided.")
        return
    end

    ListOfRopes[owner] = ropeData

    local localServerId = GetPlayerServerId(PlayerId())

    -- Si c'est notre propre corde
    if owner == localServerId then
        Support.ownerId = owner
        print("[showzx_lift DEBUG] Local rope confirmed.")
        return
    end

    print("[showzx_lift DEBUG] Creating remote rope for owner=" .. tostring(owner))

    CreateThread(function()
        RopeLoadTextures()

        while not RopeAreTexturesLoaded() do
            Wait(0)
        end

        local ropeLength = math.abs(topAnchor.z - bottomAnchor.z)

        local visualRope = AddRope(
            topAnchor.x,
            topAnchor.y,
            topAnchor.z,
            0.0,
            0.0,
            0.0,
            ropeLength,
            1,
            ropeLength,
            0.1,
            0.5,
            false,
            false,
            false,
            1.0,
            false
        )

        ropeData.visualRope = visualRope

        print(
            ("[showzx_lift DEBUG] Remote rope created owner=%s rope=%s")
            :format(owner, tostring(visualRope))
        )
    end)

    local player = GetPlayerFromServerId(owner)
    local name = "Unknown"

    if player ~= -1 then
        name = GetPlayerName(player)
    end

    print(("showzx_lift: %s has been added as rope owner"):format(name))
end)

RegisterNetEvent("showzx_lift:deleteRopeForOwner", function(owner)
    if not owner then
        print("showzx_lift: Incomplete rope data provided.")
        return
    end

    print("[showzx_lift DEBUG] deleteRopeForOwner received for owner=" .. tostring(owner))
    local ropeData = ListOfRopes[owner]
    if ropeData then
        if ropeData.visualRope and DoesRopeExist(ropeData.visualRope) then
            print("[showzx_lift DEBUG] deleting visual rope id=" .. tostring(ropeData.visualRope))
            DeleteRope(ropeData.visualRope)
        end
        if ropeData.topAnchorEntity and DoesEntityExist(ropeData.topAnchorEntity) then
            DeleteEntity(ropeData.topAnchorEntity)
        end
        if ropeData.bottomAnchorEntity and DoesEntityExist(ropeData.bottomAnchorEntity) then
            DeleteEntity(ropeData.bottomAnchorEntity)
        end
    end

    ListOfRopes[owner] = nil
    local player = GetPlayerFromServerId(owner)
    local name = "Unknown"
    if player ~= -1 then
        name = GetPlayerName(player)
    end
    print(("showzx_lift: %s has been removed his rope "):format(name))
end)

RegisterNetEvent("showzx_lift:lifting", function(data)
    if type(data) ~= "table" then return end

    if not data.bottomAnchor or not data.topAnchor or not data.owner then
        print("showzx_lift:lifting: Incomplete lift data provided.")
        return
    end

    local ped = PlayerPedId()
    local bottom = data.bottomAnchor
    local top = data.topAnchor

    SetEntityCoordsNoOffset(ped, bottom.x, bottom.y, bottom.z + 0.5, false, false, false)

    local supportPed = nil
    local player = GetPlayerFromServerId(data.owner)

    if player ~= -1 then
        supportPed = GetPlayerPed(player)
    end

    if not supportPed or not DoesEntityExist(supportPed) then
        supportPed = nil
    end

    FreezeEntityPosition(ped, true)
    SetEntityVelocity(ped, 0.0, 0.0, 0.0)

    local riseDuration = 1500
    local startZ = bottom.z + 0.5
    local endZ = top.z - 0.25
    local t0 = GetGameTimer()

    while true do
        local now = GetGameTimer()
        local t = (now - t0) / riseDuration
        if t >= 1.0 then
            SetEntityCoordsNoOffset(ped, bottom.x, bottom.y, endZ, true, false, false)
            break
        end

        local curZ = startZ + (endZ - startZ) * t
        SetEntityCoordsNoOffset(ped, bottom.x, bottom.y, curZ, true, false, false)
        Wait(0)
    end

    Wait(150)

    local fromPos = GetEntityCoords(ped)
    local targetPos = vector3(top.x, top.y, endZ)
    if supportPed and DoesEntityExist(supportPed) then
        local spCoords = GetEntityCoords(supportPed)
        local spForward = GetEntityForwardVector(supportPed)
        targetPos = spCoords + (spForward * 0.5)
        targetPos = vector3(targetPos.x, targetPos.y, endZ)
    end

    local horizDuration = 800
    local t1 = GetGameTimer()

    while true do
        local now = GetGameTimer()
        local t = (now - t1) / horizDuration
        if t >= 1.0 then
            SetEntityCoordsNoOffset(ped, targetPos.x, targetPos.y, targetPos.z, true, false, false)
            break
        end

        local wanted = fromPos + (targetPos - fromPos) * t
        SetEntityCoordsNoOffset(ped, wanted.x, wanted.y, wanted.z, true, false, false)
        Wait(0)
    end

    FreezeEntityPosition(ped, false)
    SetEntityVelocity(ped, 0.0, 0.0, 0.0)
end)

function ShowZxLift.CanUse(ped, dist)
    print("[showzx_lift DEBUG] Checking CanUse: dist=" .. tostring(dist))
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
    Support.cooldownEnd = Support.lastToggle + 1000 -- 1 seconde de cooldown
    TriggerServerEvent("showzx_lift:liftStart", data.owner)
end

CreateThread(function()
    while true do
        Wait(50)
        local ped = PlayerPedId()
        local ropeData, dist = ShowZxLift.GetNearestRopeData(ped, 2.0)

        if ropeData and ShowZxLift.CanUse(ped, dist) then
            BeginTextCommandDisplayHelp("STRING")
            AddTextComponentSubstringPlayerName("~INPUT_CONTEXT~ Utiliser la corde")
            EndTextCommandDisplayHelp(0, false, true, 1)

            if IsControlJustPressed(0, 38) then
                if ShowZxLift.IsOnCooldown() then
                    errorMsg("Cooldown actif. Attendez une seconde.")
                else
                    ShowZxLift.Start(ropeData)
                end
            end
        end
    end
end)

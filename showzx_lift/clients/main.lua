

ListOfRopes = {} -- [ownerServerId] = { owner, topAnchor, bottomAnchor, visualRope, topAnchorEntity, bottomAnchorEntity }


ShowZxLift = {}

PlayersOnRope = {} -- [playerServerId] = true



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

    local ropeLengthCheck = pos.z + 3 - groundZ
    if ropeLengthCheck < 10.0 then
        errorMsg("La corde est trop courte pour être déployée.")
        Support.active = false
        return
    end

    if ropeLengthCheck > 50.0 then
        errorMsg("La corde est trop longue pour être déployée.")
        Support.active = false
        return
    end

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

    debugMsg("rope =", rope)
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
    Support.topAnchorEntity = topAnchorCoords
    Support.bottomAnchorEntity = bottomAnchorCoords
    Support.ownerId = nil


    message("Rope déployé.")
    -- Envoie au serveur les informations de la corde pour qu'il puisse les partager avec les autres joueurs
    TriggerServerEvent("showzx_lift:addRopeOwner", ropeData)
end)

RegisterNetEvent("showzx_lift:disableLiftMode", function()
    if Support.activeRope then
        DeleteRope(Support.activeRope)
        Support.activeRope = nil
    end

    Support.active = false

    if Support.ownerId then
        TriggerServerEvent("showzx_lift:removeRopeOwner", Support.ownerId)
        Support.ownerId = nil
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
    local nameRope = ropeData.name

    if not owner or not topAnchor or not bottomAnchor or not nameRope then
        debugMsg("showzx_lift: Incomplete rope data provided.")
        return
    end

    ListOfRopes[owner] = ropeData

    local localServerId = GetPlayerServerId(PlayerId())

    -- Si c'est notre propre corde
    if owner == localServerId then
        Support.ownerId = owner
        debugMsg("showzx_lift: Local rope confirmed.")
        return
    end

    debugMsg("showzx_lift: Creating remote rope for owner=" .. tostring(owner))

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

    debugMsg(("showzx_lift: %s has been added as rope owner"):format(name))
end)

RegisterNetEvent("showzx_lift:deleteRopeForOwner", function(owner)
    if not owner then
        debugMsg("showzx_lift: Incomplete rope data provided.")
        return
    end

    debugMsg("showzx_lift: deleteRopeForOwner received for owner=" .. tostring(owner))
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

RegisterNetEvent("showzx_lift:lifting", function(data ,owner)
    if type(data) ~= "table" then return end

    if not data.bottomAnchor
        or not data.topAnchor
        or not data.landingPos
        or not data.landingHeading 
        or not owner then
        print("showzx_lift:lifting: Incomplete lift data provided.")
        return
    end

    local ped = PlayerPedId()
    local bottom = data.bottomAnchor
    local top = data.topAnchor
    SetEntityHeading(ped, data.landingHeading + 180.0) -- Rotate the player to face the opposite direction of the landing heading
    SetEntityCoordsNoOffset(ped, bottom.x, bottom.y, bottom.z + 0.5, true, false, false)

    FreezeEntityPosition(ped, true)
    SetEntityVelocity(ped, 0.0, 0.0, 0.0)

    local riseDuration = ShowZxLiftConfig.Lifting.LIFT_DURATION
    local startZ = bottom.z + 0.5
    local endZ = top.z - 0.25
    local t0 = GetGameTimer()
    Support.isOnRope = true
    TriggerServerEvent("showzx_lift:playerOnRope", true , owner) -- Notify the server that the player is now on the rope

    debugMsg("Support.isOnRope net event lifting: ", Support.isOnRope)

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

    local targetPos = vector3(
        data.landingPos.x,
        data.landingPos.y,
        endZ
    )

    local horizDuration = ShowZxLiftConfig.Lifting.HORIZ_DURATION
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
    Support.isOnRope = false
    TriggerServerEvent("showzx_lift:playerOnRope", false , owner) -- Notify the server that the player is no longer on the rope
    SetEntityVelocity(ped, 0.0, 0.0, 0.0)
    ClearPedTasks(ped)
end)

RegisterNetEvent("showzx_lift:UnLifting", function(data, owner)
    if type(data) ~= "table" then return end

    if not data.bottomAnchor
        or not data.topAnchor
        or not data.landingPos
        or not data.landingHeading 
        or not owner then
        print("showzx_lift:lifting: Incomplete lift data provided.")
        return
    end

    local ped = PlayerPedId()



    local fromPos = GetEntityCoords(ped)

    local targetPos = vector3(
        data.topAnchor.x,
        data.topAnchor.y,
        data.topAnchor.z - 0.25
    )

    local horizDuration = ShowZxLiftConfig.Lifting.HORIZ_DURATION
    local t1 = GetGameTimer()

    FreezeEntityPosition(ped, true)
    SetEntityVelocity(ped, 0.0, 0.0, 0.0)
    Support.isOnRope = true

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


    local bottom = data.bottomAnchor
    local top = data.topAnchor
    SetEntityHeading(ped, data.landingHeading + 180.0) -- Rotate the player to face the opposite direction of the landing heading



    local descentDuration = ShowZxLiftConfig.Lifting.DESCENT_DURATION
    local startZ = top.z + 0.5
    local endZ = bottom.z +
    1.25                         -- Adjusted to ensure the player lands slightly above the bottom anchor to avoid clipping into the ground
    local t0 = GetGameTimer()
    TriggerServerEvent("showzx_lift:playerOnRope", true , owner) -- Notify the server that the player is now on the rope
    Wait(150)
    while true do
        local now = GetGameTimer()
        local t = (now - t0) / descentDuration
        if t >= 1.0 then
            SetEntityCoordsNoOffset(ped, bottom.x, bottom.y, endZ, true, false, false)
            break
        end

        local curZ = startZ + (endZ - startZ) * t
        SetEntityCoordsNoOffset(ped, bottom.x, bottom.y, curZ, true, false, false)
        Wait(0)
    end


    FreezeEntityPosition(ped, false)
    SetEntityVelocity(ped, 0.0, 0.0, 0.0)
    ClearPedTasks(ped)
    Support.isOnRope = false
    TriggerServerEvent("showzx_lift:playerOnRope", false , owner) -- Notify the server that the player is now on the rope
end)

RegisterNetEvent("showzx_lift:notifyClientRopeStatus", function(playerServerId, isOnRope)
    if not playerServerId then
        debugMsg("showzx_lift: Invalid playerServerId provided for rope status notification.")
        return
    end
    
    if isOnRope then
        PlayersOnRope[playerServerId] = true
        debugMsg(("showzx_lift: %s is now on your rope."):format(GetPlayerName(GetPlayerFromServerId(playerServerId)) or "Unknown"))
    else
        PlayersOnRope[playerServerId] = nil
        debugMsg(("showzx_lift: %s is no longer on your rope."):format(GetPlayerName(GetPlayerFromServerId(playerServerId)) or "Unknown"))
    end

end)


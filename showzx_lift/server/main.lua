local supports = {}
listOfRopes = {}

RegisterNetEvent("showzx_lift:setMode", function(isLifting)
    supports[source] = isLifting
    local name = GetPlayerName(source) or "Unknown"
    print(("showzx_lift: support state of %s set to %s "):format(name, tostring(isLifting)))
    TriggerClientEvent("showzx_lift:notifyClient", source, isLifting)
end)

RegisterNetEvent("showzx_lift:addRopeOwner", function(ropeData)

    if type(ropeData) ~= "table" then print("showzx_lift: Invalid rope data provided.") return end

    ropeData.owner = source
    local owner = ropeData.owner
    local topAnchor = ropeData.topAnchor
    local bottomAnchor = ropeData.bottomAnchor
    local landingPos = ropeData.landingPos
    local landingHeading = ropeData.landingHeading

    if not owner or not topAnchor or not bottomAnchor or not landingPos or not landingHeading then
        print("showzx_lift: Incomplete rope data provided.")
        return
    end



    local name = GetPlayerName(source) or "Unknown"
    print(("showzx_lift: %s added a rope at top=(%.2f,%.2f,%.2f) bottom=(%.2f,%.2f,%.2f) landing=(%.2f,%.2f,%.2f) heading=(%.2f)"):format(
        name,
        topAnchor.x, topAnchor.y, topAnchor.z,
        bottomAnchor.x, bottomAnchor.y, bottomAnchor.z,
        landingPos.x, landingPos.y, landingPos.z,
        landingHeading
    ))

    listOfRopes[source] = {
        owner = owner,
        topAnchor = topAnchor,
        bottomAnchor = bottomAnchor,
        landingPos = landingPos,
        landingHeading = landingHeading
    }
    TriggerClientEvent("showzx_lift:setRopeOwner", -1, listOfRopes[source])
end)

RegisterNetEvent("showzx_lift:removeRopeOwner", function(owner)
    if not owner then print("showzx_lift: Invalid rope data provided.") return end
    if source ~= owner then print("showzx_lift: Unauthorized attempt to remove rope owner.") return end

    local name = GetPlayerName(source) or "Unknown"

    print(("showzx_lift: %s remove his rope "):format(name))

    TriggerClientEvent("showzx_lift:deleteRopeForOwner", -1, owner)
    listOfRopes[source] = nil
end)

RegisterNetEvent("showzx_lift:liftStart", function(owner)
    local src = source

    if not owner then
        print("showzx_lift: Invalid owner provided for lift start.")
        return
    end


    local ropeData = listOfRopes[owner]
    if not ropeData then
        print("showzx_lift: No rope data found for owner.")
        return
    end

    local srcPed = GetPlayerPed(src)
    local srcCoords = GetEntityCoords(srcPed)

    local dx = srcCoords.x - ropeData.bottomAnchor.x
    local dy = srcCoords.y - ropeData.bottomAnchor.y
    local dz = srcCoords.z - ropeData.bottomAnchor.z
    local dist = math.sqrt(dx * dx + dy * dy + dz * dz)

    if dist > 4 then
        TriggerClientEvent("showzx_lift:denied", src, "❌ Too far from the rope")
        return
    end

    -- Start the lift for the player
    TriggerClientEvent("showzx_lift:lifting", src, ropeData)
    TriggerClientEvent("showzx_lift:playAnimation", src)
end)
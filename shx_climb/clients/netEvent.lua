
AddEventHandler("shx_climb:hang", function(targetCoords)

    
    print("PlayerState : " .. playerState)
    vaultTask(targetCoords)
     -- Unfreeze the player's position

    --[[    local ped = PlayerPedId()
    local playerCoords = GetEntityCoords(ped)

    -- Calculate the direction from the player to the target coordinates
    local direction = targetCoords - playerCoords
    local length = #direction
    local dirNormalized = direction / length

    -- Calculate the position to place the player for hanging
    local hangPosition = targetCoords - (dirNormalized * 0.5) -- Adjust the distance as needed

    -- Set the player's position and heading for hanging
    SetEntityCoords(ped, hangPosition.x, hangPosition.y, hangPosition.z)
    SetEntityHeading(ped, GetHeadingFromVector_2d(dirNormalized.x, dirNormalized.y))

    -- Play the hanging animation (replace with your own animation)
    TaskPlayAnim(ped, "climb", "hang_idle", 8.0, -8.0, -1, 1, 0, false, false, false) ]]

end)


AddEventHandler("shx_climb:vault", function(targetCoords)
    Wait(1000)
    playerState = "IDLE"
    print("PlayerState : " .. playerState)
    FreezeEntityPosition(PlayerPedId(), false) -- Unfreeze the player's position


end)


AddEventHandler("onResourceStop", function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    FreezeEntityPosition(PlayerPedId(), false)
end)